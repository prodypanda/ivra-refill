-- Migration: Allow hotel managers to approve change requests for their own hotel.

CREATE OR REPLACE FUNCTION approve_change_request(
  p_request_id uuid,
  p_notes text DEFAULT null
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_request approval_requests%rowtype;
  v_correction correction_requests%rowtype;
  v_refill refill_events%rowtype;
  v_floor_id uuid;
BEGIN
  SELECT * INTO v_request
  FROM approval_requests
  WHERE id = p_request_id AND status = 'pending'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending approval request not found';
  END IF;

  IF NOT (is_ivra_admin() OR (current_user_role() = 'hotel_manager' AND has_hotel_access(v_request.hotel_id))) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  IF v_request.target_table = 'correction_requests' then
    SELECT * INTO v_correction
    FROM correction_requests
    WHERE id = v_request.target_id AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Pending correction request not found';
    END IF;

    SELECT * INTO v_refill
    FROM refill_events
    WHERE id = v_correction.refill_event_id
    FOR UPDATE;

    UPDATE correction_requests
    SET status = 'approved',
        reviewed_by = auth.uid(),
        reviewed_at = now(),
        review_notes = p_notes
    WHERE id = v_correction.id;

    UPDATE room_products
    SET refill_count = v_refill.previous_refill_count,
        status = 'active'
    WHERE id = v_refill.room_product_id;

    INSERT INTO refill_events (
      hotel_id,
      room_product_id,
      event_type,
      previous_refill_count,
      new_refill_count,
      performed_by,
      correction_request_id,
      notes
    )
    VALUES (
      v_refill.hotel_id,
      v_refill.room_product_id,
      'correction_approved',
      v_refill.new_refill_count,
      v_refill.previous_refill_count,
      auth.uid(),
      v_correction.id,
      p_notes
    );
  ELSIF v_request.action <> 'update' then
    RAISE EXCEPTION 'Unsupported approval action';
  ELSIF v_request.target_table = 'hotels' then
    UPDATE hotels
    SET name = coalesce(v_request.new_data->>'name', name),
        legal_name = coalesce(v_request.new_data->>'legal_name', legal_name),
        contact_name = coalesce(v_request.new_data->>'contact_name', contact_name),
        phone = coalesce(v_request.new_data->>'phone', phone),
        email = coalesce(v_request.new_data->>'email', email),
        address = coalesce(v_request.new_data->>'address', address),
        city = coalesce(v_request.new_data->>'city', city),
        country = coalesce(v_request.new_data->>'country', country),
        notes = coalesce(v_request.new_data->>'notes', notes)
    WHERE id = v_request.target_id AND id = v_request.hotel_id;
  ELSIF v_request.target_table = 'floors' then
    UPDATE floors
    SET floor_number = coalesce((v_request.new_data->>'floor_number')::int, floor_number),
        name = coalesce(v_request.new_data->>'name', name)
    WHERE id = v_request.target_id AND hotel_id = v_request.hotel_id;
  ELSIF v_request.target_table = 'rooms' then
    IF v_request.new_data ? 'floor_number' then
      INSERT INTO floors (hotel_id, floor_number, name)
      VALUES (
        v_request.hotel_id,
        (v_request.new_data->>'floor_number')::int,
        concat('Floor ', v_request.new_data->>'floor_number')
      )
      ON CONFLICT (hotel_id, floor_number)
      DO UPDATE SET floor_number = excluded.floor_number
      RETURNING id into v_floor_id;
    END IF;

    UPDATE rooms
    SET floor_id = coalesce(v_floor_id, (v_request.new_data->>'floor_id')::uuid, floor_id),
        room_number = coalesce(v_request.new_data->>'room_number', room_number),
        room_label = coalesce(v_request.new_data->>'room_label', room_label),
        is_active = coalesce((v_request.new_data->>'is_active')::boolean, is_active)
    WHERE id = v_request.target_id AND hotel_id = v_request.hotel_id;

    IF v_request.new_data ? 'product_ids' then
      -- Delete products that are no longer in the list
      DELETE FROM room_products
      WHERE room_id = v_request.target_id
        AND product_id not in (
          SELECT jsonb_array_elements_text(v_request.new_data->'product_ids')::uuid
        );

      -- Add products that are in the list but not in the room yet
      INSERT INTO room_products (hotel_id, room_id, product_id, status)
      SELECT v_request.hotel_id, v_request.target_id, p_id, 'active'::bottle_status
      FROM (
        SELECT jsonb_array_elements_text(v_request.new_data->'product_ids')::uuid as p_id
      ) new_products
      WHERE p_id not in (
        SELECT product_id from room_products where room_id = v_request.target_id
      );
    END IF;
  ELSIF v_request.target_table = 'room_products' then
    UPDATE room_products
    SET product_id = coalesce((v_request.new_data->>'product_id')::uuid, product_id),
        bottle_started_at = coalesce((v_request.new_data->>'bottle_started_at')::date, bottle_started_at),
        status = coalesce((v_request.new_data->>'status')::bottle_status, status),
        is_active = coalesce((v_request.new_data->>'is_active')::boolean, is_active)
    WHERE id = v_request.target_id AND hotel_id = v_request.hotel_id;
  ELSE
    RAISE EXCEPTION 'Unsupported target table';
  END IF;

  UPDATE approval_requests
  SET status = 'approved',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      review_notes = p_notes
  WHERE id = p_request_id;

  UPDATE alerts
  SET is_resolved = true,
      resolved_at = now(),
      resolved_by = auth.uid()
  WHERE hotel_id = v_request.hotel_id
    AND alert_type = 'pending_approval'
    AND not is_resolved
    AND (
      body = v_request.title
      OR title = 'Pending approval: ' || v_request.title
    );

  INSERT INTO audit_log (actor_id, hotel_id, entity_table, entity_id, action, new_data)
  VALUES (
    auth.uid(),
    v_request.hotel_id,
    v_request.target_table,
    v_request.target_id,
    'approval_approved',
    v_request.new_data
  );
END;
$$;
