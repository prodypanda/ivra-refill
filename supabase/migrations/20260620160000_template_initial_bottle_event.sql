-- Record an initial "new bottle placed" history event when rooms (and their
-- products) are first created from a template.
--
-- Previously `create_rooms_from_template` only inserted into `room_products`,
-- so a freshly created room had no `refill_events` and its history appeared
-- empty. The rooms history UI already labels a `bottle_replaced` event whose
-- `previous_refill_count = 0` as the initial placement ("New bottle placed"),
-- so we emit exactly that event for each newly created room product.

create or replace function create_rooms_from_template(
  p_hotel_id uuid,
  p_floor_number int,
  p_first_room_number int,
  p_room_count int,
  p_product_ids uuid[]
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

  insert into floors (hotel_id, floor_number, name)
  values (p_hotel_id, p_floor_number, 'Floor ' || p_floor_number)
  on conflict (hotel_id, floor_number)
  do update set name = excluded.name
  returning id into v_floor_id;

  for v_created_count in 0..(p_room_count - 1) loop
    v_room_number := (p_first_room_number + v_created_count)::text;

    insert into rooms (hotel_id, floor_id, room_number)
    values (p_hotel_id, v_floor_id, v_room_number)
    on conflict (hotel_id, room_number)
    do update set floor_id = excluded.floor_id
    returning id into v_room_id;

    foreach v_product_id in array p_product_ids loop
      v_room_product_id := null;

      insert into room_products (hotel_id, room_id, product_id)
      values (p_hotel_id, v_room_id, v_product_id)
      on conflict (room_id, product_id) do nothing
      returning id into v_room_product_id;

      -- Only log the initial placement for room products that were actually
      -- created by this call (a conflict leaves v_room_product_id null).
      if v_room_product_id is not null then
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
