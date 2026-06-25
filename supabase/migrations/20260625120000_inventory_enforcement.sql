-- Migration: Enforce inventory check on room creation and bottle replacement, with auto-adjustment.

DROP FUNCTION IF EXISTS create_rooms_from_template(uuid, int, int, int, uuid[]);
DROP FUNCTION IF EXISTS replace_bottle(uuid, text, text);
DROP FUNCTION IF EXISTS approve_change_request(uuid, text);

-- 1. create_rooms_from_template
create or replace function create_rooms_from_template(
  p_hotel_id uuid,
  p_floor_number int,
  p_first_room_number int,
  p_room_count int,
  p_product_ids uuid[],
  p_auto_adjust_inventory boolean default false
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_floor_id uuid;
  v_room_id uuid;
  v_room_number text;
  v_created_count int := 0;
  v_product_id uuid;
  v_room_product_id uuid;
  v_available_bottles int;
  v_needed_adjustment int;
  v_product_name_en text;
begin
  if not is_ivra_admin() then
    raise exception 'Only Ivra admins and managers can create rooms directly';
  end if;
  if p_room_count <= 0 or p_room_count > 500 then
    raise exception 'Room count must be between 1 and 500';
  end if;
  if array_length(p_product_ids, 1) is null or array_length(p_product_ids, 1) = 0 then
    raise exception 'At least one product is required';
  end if;

  -- Check inventory and perform auto-adjustments if requested
  foreach v_product_id in array p_product_ids loop
    -- Find current full bottles
    select coalesce(full_bottles, 0) into v_available_bottles
    from hotel_inventory
    where hotel_id = p_hotel_id and product_id = v_product_id;

    if not found then
      v_available_bottles := 0;
    end if;

    if v_available_bottles < p_room_count then
      if not p_auto_adjust_inventory then
        select name_en into v_product_name_en from products where id = v_product_id;
        raise exception 'Insufficient inventory for product %. Needed: %, Available: %', 
          v_product_name_en, p_room_count, v_available_bottles;
      else
        v_needed_adjustment := p_room_count - v_available_bottles;
        
        -- Upsert inventory
        insert into hotel_inventory (hotel_id, product_id, full_bottles, empty_bottles)
        values (p_hotel_id, v_product_id, v_needed_adjustment, 0)
        on conflict (hotel_id, product_id)
        do update set full_bottles = hotel_inventory.full_bottles + excluded.full_bottles,
                      updated_at = now();
                      
        -- Log auto-adjustment
        insert into inventory_events (hotel_id, product_id, full_bottles_delta, reason, performed_by)
        values (p_hotel_id, v_product_id, v_needed_adjustment, 'Auto-adjusted for room creation template', auth.uid());
      end if;
    end if;
  end loop;

  -- Create floor
  insert into floors (hotel_id, floor_number, name)
  values (p_hotel_id, p_floor_number, 'Floor ' || p_floor_number)
  on conflict (hotel_id, floor_number)
  do update set name = excluded.name
  returning id into v_floor_id;

  -- Create rooms and room products
  for v_created_count in 0..(p_room_count - 1) loop
    v_room_number := (p_first_room_number + v_created_count)::text;

    insert into rooms (hotel_id, floor_id, room_number)
    values (p_hotel_id, v_floor_id, v_room_number)
    on conflict (hotel_id, room_number)
    do update set floor_id = excluded.floor_id
    returning id into v_room_id;

    foreach v_product_id in array p_product_ids loop
      v_room_product_id := null;

      insert into room_products (hotel_id, room_id, product_id, status)
      values (p_hotel_id, v_room_id, v_product_id, 'active'::bottle_status)
      on conflict (room_id, product_id) do nothing
      returning id into v_room_product_id;

      -- Only log placement and decrement inventory if actually created
      if v_room_product_id is not null then
        -- Decrement stock from inventory
        update hotel_inventory
        set full_bottles = greatest(full_bottles - 1, 0),
            updated_at = now()
        where hotel_id = p_hotel_id and product_id = v_product_id;

        -- Insert refill_event
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
          p_hotel_id,
          v_room_product_id,
          'bottle_replaced',
          0,
          0,
          auth.uid(),
          'Initial bottle placement'
        );
      end if;
    end loop;
  end loop;

  -- Log audit
  insert into audit_log (actor_id, hotel_id, entity_table, action, new_data)
  values (
    auth.uid(),
    p_hotel_id,
    'rooms',
    'template_created',
    jsonb_build_object(
      'floor_number', p_floor_number,
      'first_room_number', p_first_room_number,
      'room_count', p_room_count,
      'product_ids', p_product_ids
    )
  );

  return p_room_count;
end;
$$;


-- 2. replace_bottle
create or replace function replace_bottle(
  p_room_product_id uuid,
  p_notes text default null,
  p_client_request_id text default null,
  p_auto_adjust_inventory boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_product room_products%rowtype;
  v_event_id uuid;
  v_available_bottles int;
  v_product_name_en text;
begin
  select * into v_room_product
  from room_products
  where id = p_room_product_id
  for update;

  if not found then
    raise exception 'Room product not found';
  end if;

  if not has_hotel_access(v_room_product.hotel_id) then
    raise exception 'Access denied';
  end if;

  if p_client_request_id is not null then
    select id into v_event_id
    from refill_events
    where client_request_id = p_client_request_id
      and hotel_id = v_room_product.hotel_id;

    if found then
      return v_event_id;
    end if;
  end if;

  -- Verify inventory stock
  select coalesce(full_bottles, 0) into v_available_bottles
  from hotel_inventory
  where hotel_id = v_room_product.hotel_id and product_id = v_room_product.product_id;

  if not found then
    v_available_bottles := 0;
  end if;

  if v_available_bottles = 0 then
    if not p_auto_adjust_inventory then
      select name_en into v_product_name_en from products where id = v_room_product.product_id;
      raise exception 'Insufficient inventory for product %. Stock is 0.', v_product_name_en;
    else
      -- Auto-adjust: add 1 full bottle
      insert into hotel_inventory (hotel_id, product_id, full_bottles, empty_bottles)
      values (v_room_product.hotel_id, v_room_product.product_id, 1, 0)
      on conflict (hotel_id, product_id)
      do update set full_bottles = hotel_inventory.full_bottles + 1,
                    updated_at = now();

      -- Log event
      insert into inventory_events (hotel_id, product_id, full_bottles_delta, reason, performed_by)
      values (v_room_product.hotel_id, v_room_product.product_id, 1, 'Auto-adjusted for replacement', auth.uid());
    end if;
  end if;

  -- Proceed with replacement
  update room_products
  set refill_count = 0,
      last_refill_at = null,
      bottle_started_at = current_date,
      status = 'active'
  where id = p_room_product_id;

  update hotel_inventory
  set full_bottles = greatest(full_bottles - 1, 0),
      empty_bottles = empty_bottles + 1,
      updated_at = now()
  where hotel_id = v_room_product.hotel_id
    and product_id = v_room_product.product_id;

  insert into refill_events (
    hotel_id,
    room_product_id,
    event_type,
    previous_refill_count,
    new_refill_count,
    performed_by,
    notes,
    client_request_id
  )
  values (
    v_room_product.hotel_id,
    p_room_product_id,
    'bottle_replaced',
    v_room_product.refill_count,
    0,
    auth.uid(),
    p_notes,
    p_client_request_id
  )
  returning id into v_event_id;

  return v_event_id;
end;
$$;


-- 3. approve_change_request
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
    update room_products
    set product_id = coalesce((v_request.new_data->>'product_id')::uuid, product_id),
        bottle_started_at = coalesce((v_request.new_data->>'bottle_started_at')::date, bottle_started_at),
        status = coalesce((v_request.new_data->>'status')::bottle_status, status),
        is_active = coalesce((v_request.new_data->>'is_active')::boolean, is_active)
    where id = v_request.target_id and hotel_id = v_request.hotel_id;
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
