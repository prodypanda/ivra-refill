-- Migration: Allow hotel managers to create rooms from template for their own hotel.

DROP FUNCTION IF EXISTS create_rooms_from_template(uuid, int, int, int, uuid[], boolean);

CREATE OR REPLACE FUNCTION create_rooms_from_template(
  p_hotel_id uuid,
  p_floor_number int,
  p_first_room_number int,
  p_room_count int,
  p_product_ids uuid[],
  p_auto_adjust_inventory boolean default false
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_floor_id uuid;
  v_room_id uuid;
  v_room_number text;
  v_created_count int := 0;
  v_product_id uuid;
  v_room_product_id uuid;
  v_available_bottles int;
  v_needed_adjustment int;
  v_product_name_en text;
BEGIN
  IF NOT (is_ivra_admin() OR (current_user_role() = 'hotel_manager' AND has_hotel_access(p_hotel_id))) THEN
    RAISE EXCEPTION 'Only Ivra admins, managers, and assigned hotel managers can create rooms directly';
  END IF;
  
  IF p_room_count <= 0 OR p_room_count > 500 THEN
    RAISE EXCEPTION 'Room count must be between 1 and 500';
  END IF;

  -- Ensure p_product_ids is not null so FOREACH loops don't crash
  p_product_ids := coalesce(p_product_ids, ARRAY[]::uuid[]);

  -- Check inventory and perform auto-adjustments if requested
  FOREACH v_product_id IN ARRAY p_product_ids LOOP
    -- Find current full bottles
    SELECT coalesce(full_bottles, 0) INTO v_available_bottles
    FROM hotel_inventory
    WHERE hotel_id = p_hotel_id AND product_id = v_product_id;

    IF NOT FOUND THEN
      v_available_bottles := 0;
    END IF;

    IF v_available_bottles < p_room_count THEN
      IF NOT p_auto_adjust_inventory THEN
        SELECT name_en INTO v_product_name_en FROM products WHERE id = v_product_id;
        RAISE EXCEPTION 'Insufficient inventory for product %. Needed: %, Available: %', 
          v_product_name_en, p_room_count, v_available_bottles;
      ELSE
        v_needed_adjustment := p_room_count - v_available_bottles;
        
        -- Upsert inventory
        INSERT INTO hotel_inventory (hotel_id, product_id, full_bottles, empty_bottles)
        VALUES (p_hotel_id, v_product_id, v_needed_adjustment, 0)
        ON CONFLICT (hotel_id, product_id)
        DO UPDATE SET full_bottles = hotel_inventory.full_bottles + excluded.full_bottles,
                      updated_at = now();
                      
        -- Log auto-adjustment
        INSERT INTO inventory_events (hotel_id, product_id, full_bottles_delta, reason, performed_by)
        VALUES (p_hotel_id, v_product_id, v_needed_adjustment, 'Auto-adjusted for room creation template', auth.uid());
      END IF;
    END IF;
  END LOOP;

  -- Create floor
  INSERT INTO floors (hotel_id, floor_number, name)
  VALUES (p_hotel_id, p_floor_number, 'Floor ' || p_floor_number)
  ON CONFLICT (hotel_id, floor_number)
  DO UPDATE SET name = excluded.name
  RETURNING id INTO v_floor_id;

  -- Create rooms and room products
  FOR v_created_count IN 0..(p_room_count - 1) LOOP
    v_room_number := (p_first_room_number + v_created_count)::text;

    INSERT INTO rooms (hotel_id, floor_id, room_number)
    VALUES (p_hotel_id, v_floor_id, v_room_number)
    ON CONFLICT (hotel_id, room_number)
    DO UPDATE SET floor_id = excluded.floor_id
    RETURNING id INTO v_room_id;

    FOREACH v_product_id IN ARRAY p_product_ids LOOP
      v_room_product_id := null;

      INSERT INTO room_products (hotel_id, room_id, product_id, status)
      VALUES (p_hotel_id, v_room_id, v_product_id, 'active'::bottle_status)
      ON CONFLICT (room_id, product_id) DO NOTHING
      RETURNING id INTO v_room_product_id;

      -- Only log placement and decrement inventory if actually created
      IF v_room_product_id IS NOT NULL THEN
        -- Decrement stock from inventory
        UPDATE hotel_inventory
        SET full_bottles = greatest(full_bottles - 1, 0),
            updated_at = now()
        WHERE hotel_id = p_hotel_id and product_id = v_product_id;

        -- Insert refill_event
        INSERT INTO refill_events (
          hotel_id,
          room_product_id,
          event_type,
          previous_refill_count,
          new_refill_count,
          performed_by,
          notes
        )
        VALUES (
          p_hotel_id,
          v_room_product_id,
          'bottle_replaced',
          0,
          0,
          auth.uid(),
          'Initial bottle placement'
        );
      END IF;
    END LOOP;
  END LOOP;

  -- Log audit
  INSERT INTO audit_log (actor_id, hotel_id, entity_table, action, new_data)
  VALUES (
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

  RETURN p_room_count;
END;
$$;
