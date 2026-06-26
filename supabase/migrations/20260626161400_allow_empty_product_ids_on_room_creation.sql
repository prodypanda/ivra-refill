-- Migration: Allow empty product IDs when creating rooms from template.

DROP FUNCTION IF EXISTS create_rooms_from_template(uuid, int, int, int, uuid[], boolean);

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

  -- Ensure p_product_ids is not null so FOREACH loops don't crash
  p_product_ids := coalesce(p_product_ids, ARRAY[]::uuid[]);

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
