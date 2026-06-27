-- Migration: Add refill_events entry when bottle status is edited in room_products
-- Redefine approve_change_request to insert a refill_events entry on status change

create or replace function approve_change_request(
  p_request_id uuid,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request approval_requests%rowtype;
  v_correction correction_requests%rowtype;
  v_refill refill_events%rowtype;
  v_floor_id uuid;
begin
  if not is_ivra_admin() then
    raise exception 'Access denied';
  end if;

  select * into v_request
  from approval_requests
  where id = p_request_id and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending approval request not found';
  end if;

  if v_request.target_table = 'correction_requests' then
    select * into v_correction
    from correction_requests
    where id = v_request.target_id and status = 'pending'
    for update;

    if not found then
      raise exception 'Pending correction request not found';
    end if;

    select * into v_refill
    from refill_events
    where id = v_correction.refill_event_id
    for update;

    update correction_requests
    set status = 'approved',
        reviewed_by = auth.uid(),
        reviewed_at = now(),
        review_notes = p_notes
    where id = v_correction.id;

    update room_products
    set refill_count = v_refill.previous_refill_count,
        status = 'active'
    where id = v_refill.room_product_id;

    insert into refill_events (
      hotel_id,
      room_product_id,
      event_type,
      previous_refill_count,
      new_refill_count,
      performed_by,
      correction_request_id,
      notes
    )
    values (
      v_refill.hotel_id,
      v_refill.room_product_id,
      'correction_approved',
      v_refill.new_refill_count,
      v_refill.previous_refill_count,
      auth.uid(),
      v_correction.id,
      p_notes
    );
  elsif v_request.action <> 'update' then
    raise exception 'Unsupported approval action';
  elsif v_request.target_table = 'hotels' then
    update hotels
    set name = coalesce(v_request.new_data->>'name', name),
        legal_name = coalesce(v_request.new_data->>'legal_name', legal_name),
        contact_name = coalesce(v_request.new_data->>'contact_name', contact_name),
        phone = coalesce(v_request.new_data->>'phone', phone),
        email = coalesce(v_request.new_data->>'email', email),
        address = coalesce(v_request.new_data->>'address', address),
        city = coalesce(v_request.new_data->>'city', city),
        country = coalesce(v_request.new_data->>'country', country),
        notes = coalesce(v_request.new_data->>'notes', notes)
    where id = v_request.target_id and id = v_request.hotel_id;
  elsif v_request.target_table = 'floors' then
    update floors
    set floor_number = coalesce((v_request.new_data->>'floor_number')::int, floor_number),
        name = coalesce(v_request.new_data->>'name', name)
    where id = v_request.target_id and hotel_id = v_request.hotel_id;
  elsif v_request.target_table = 'rooms' then
    if v_request.new_data ? 'floor_number' then
      insert into floors (hotel_id, floor_number, name)
      values (
        v_request.hotel_id,
        (v_request.new_data->>'floor_number')::int,
        concat('Floor ', v_request.new_data->>'floor_number')
      )
      on conflict (hotel_id, floor_number)
      do update set floor_number = excluded.floor_number
      returning id into v_floor_id;
    end if;

    update rooms
    set floor_id = coalesce(v_floor_id, (v_request.new_data->>'floor_id')::uuid, floor_id),
        room_number = coalesce(v_request.new_data->>'room_number', room_number),
        room_label = coalesce(v_request.new_data->>'room_label', room_label),
        is_active = coalesce((v_request.new_data->>'is_active')::boolean, is_active)
    where id = v_request.target_id and hotel_id = v_request.hotel_id;

    if v_request.new_data ? 'product_ids' then
      -- Delete products that are no longer in the list
      delete from room_products
      where room_id = v_request.target_id
        and product_id not in (
          select jsonb_array_elements_text(v_request.new_data->'product_ids')::uuid
        );

      -- Loop through products that need to be added
      declare
        v_add_pid uuid;
        v_room_product_id uuid;
        v_available_bottles int;
        v_auto_adjust boolean := coalesce((v_request.new_data->>'auto_adjust_inventory')::boolean, false);
        v_product_name_en text;
      begin
        for v_add_pid in
          select jsonb_array_elements_text(v_request.new_data->'product_ids')::uuid as p_id
          except
          select product_id from room_products where room_id = v_request.target_id
        loop
          -- Check stock for this product
          select coalesce(full_bottles, 0) into v_available_bottles
          from hotel_inventory
          where hotel_id = v_request.hotel_id and product_id = v_add_pid;

          if not found then
            v_available_bottles := 0;
          end if;

          if v_available_bottles = 0 then
            if not v_auto_adjust then
              select name_en into v_product_name_en from products where id = v_add_pid;
              raise exception 'Insufficient inventory for product %. Stock is 0.', v_product_name_en;
            else
              -- Auto-adjust: add 1 full bottle
              insert into hotel_inventory (hotel_id, product_id, full_bottles, empty_bottles)
              values (v_request.hotel_id, v_add_pid, 1, 0)
              on conflict (hotel_id, product_id)
              do update set full_bottles = hotel_inventory.full_bottles + 1,
                            updated_at = now();

              -- Log event
              insert into inventory_events (hotel_id, product_id, full_bottles_delta, reason, performed_by)
              values (v_request.hotel_id, v_add_pid, 1, 'Auto-adjusted for room product addition', auth.uid());
            end if;
          end if;

          -- Add product to room
          v_room_product_id := gen_random_uuid();
          insert into room_products (id, hotel_id, room_id, product_id, status)
          values (v_room_product_id, v_request.hotel_id, v_request.target_id, v_add_pid, 'active'::bottle_status);

          -- Decrement inventory by 1
          update hotel_inventory
          set full_bottles = greatest(full_bottles - 1, 0),
              updated_at = now()
          where hotel_id = v_request.hotel_id and product_id = v_add_pid;

          -- Insert refill_event for initial placement
          insert into refill_events (
            hotel_id,
            room_product_id,
            event_type,
            previous_refill_count,
            new_refill_count,
            performed_by,
            notes
          )
          values (
            v_request.hotel_id,
            v_room_product_id,
            'bottle_replaced',
            0,
            0,
            auth.uid(),
            'Initial bottle placement'
          );
        end loop;
      end;
    end if;
  elsif v_request.target_table = 'room_products' then
    declare
      v_old_status bottle_status;
      v_new_status bottle_status;
    begin
      select status into v_old_status
      from room_products
      where id = v_request.target_id::uuid;

      v_new_status := coalesce((v_request.new_data->>'status')::bottle_status, v_old_status);

      update room_products
      set product_id = coalesce((v_request.new_data->>'product_id')::uuid, product_id),
          bottle_started_at = coalesce((v_request.new_data->>'bottle_started_at')::date, bottle_started_at),
          status = v_new_status,
          is_active = coalesce((v_request.new_data->>'is_active')::boolean, is_active)
      where id = v_request.target_id and hotel_id = v_request.hotel_id;

      if v_old_status is not null and v_new_status is not null and v_old_status <> v_new_status then
        insert into refill_events (
          hotel_id,
          room_product_id,
          event_type,
          previous_refill_count,
          new_refill_count,
          performed_by,
          notes
        )
        select 
          v_request.hotel_id,
          v_request.target_id::uuid,
          'bottle_replaced'::refill_event_type,
          refill_count,
          refill_count,
          coalesce(auth.uid(), v_request.requested_by),
          concat('Status changed from ', v_old_status::text, ' to ', v_new_status::text)
        from room_products
        where id = v_request.target_id::uuid;
      end if;
    end;
  else
    raise exception 'Unsupported target table';
  end if;

  update approval_requests
  set status = 'approved',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      review_notes = p_notes
  where id = p_request_id;

  update alerts
  set is_resolved = true,
      resolved_at = now(),
      resolved_by = auth.uid()
  where hotel_id = v_request.hotel_id
    and alert_type = 'pending_approval'
    and not is_resolved
    and (
      body = v_request.title
      or title = 'Pending approval: ' || v_request.title
    );

  insert into audit_log (actor_id, hotel_id, entity_table, entity_id, action, new_data)
  values (
    auth.uid(),
    v_request.hotel_id,
    v_request.target_table,
    v_request.target_id,
    'approval_approved',
    v_request.new_data
  );
end;
$$;
