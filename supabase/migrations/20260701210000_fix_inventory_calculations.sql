-- Migration: Fix Inventory Calculations for Empty Bidons & Rollback Symmetric Logic
-- Symmetrically fix record_refill and undo_refill calculations

CREATE OR REPLACE FUNCTION record_refill(
  p_room_product_id uuid,
  p_notes text DEFAULT NULL,
  p_client_request_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_room_product room_products%rowtype;
  v_product products%rowtype;
  v_new_count int;
  v_new_status bottle_status;
  v_event_id uuid;
  
  -- Volume calculations
  v_percentage_val int := 100;
  v_percentage_str text;
  v_bottle_volume_ml double precision;
  v_bidon_volume_ml double precision;
  v_volume_added double precision;
  v_current_volume_left double precision;
  v_full_bidons int;
  v_open_bidons int;
  v_empty_bidons int;
BEGIN
  SELECT * INTO v_room_product FROM room_products WHERE id = p_room_product_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Room product not found';
  END IF;
  IF NOT has_hotel_access(v_room_product.hotel_id) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  IF p_client_request_id IS NOT NULL THEN
    SELECT id INTO v_event_id
    FROM refill_events
    WHERE client_request_id = p_client_request_id
      AND hotel_id = v_room_product.hotel_id;

    IF FOUND THEN
      RETURN v_event_id;
    END IF;
  END IF;

  SELECT * INTO v_product FROM products WHERE id = v_room_product.product_id;
  v_new_count := v_room_product.refill_count + 1;

  IF v_new_count >= v_product.max_refill_count THEN
    v_new_status := 'refill_limit_reached';
  ELSIF current_date - v_room_product.bottle_started_at >= v_product.max_bottle_age_days THEN
    v_new_status := 'too_old';
  ELSE
    v_new_status := 'refilled';
  END IF;

  UPDATE room_products
  SET refill_count = v_new_count,
      last_refill_at = now(),
      status = v_new_status
  WHERE id = p_room_product_id;

  INSERT INTO refill_events (
    hotel_id,
    room_product_id,
    event_type,
    previous_refill_count,
    new_refill_count,
    performed_by,
    notes,
    client_request_id
  )
  VALUES (
    v_room_product.hotel_id,
    p_room_product_id,
    'refill',
    v_room_product.refill_count,
    v_new_count,
    auth.uid(),
    p_notes,
    p_client_request_id
  )
  RETURNING id INTO v_event_id;

  IF v_new_status IN ('refill_limit_reached', 'too_old') THEN
    INSERT INTO alerts (hotel_id, room_product_id, product_id, alert_type, severity, title, body)
    VALUES (
      v_room_product.hotel_id,
      p_room_product_id,
      v_room_product.product_id,
      CASE WHEN v_new_status = 'too_old' THEN 'bottle_age_limit'::alert_type ELSE 'refill_limit'::alert_type end,
      3,
      'Bottle replacement needed',
      'A room product bottle reached an Ivra replacement rule.'
    );
  END IF;

  -- Volume calculations and inventory updates
  IF v_product.refill_type = 'refillable' THEN
    IF p_notes IS NOT NULL THEN
      v_percentage_str := substring(p_notes FROM '\[Refill:\s*(\d+)%\]');
      IF v_percentage_str IS NOT NULL THEN
        v_percentage_val := v_percentage_str::int;
      END IF;
    END IF;

    v_bottle_volume_ml := COALESCE(v_product.bottle_volume_ml, 1000)::double precision;
    v_bidon_volume_ml := COALESCE(v_product.bidon_volume_ml, 5000)::double precision;
    v_volume_added := (v_percentage_val::double precision / 100.0) * v_bottle_volume_ml;

    -- Fetch inventory row
    SELECT full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml
    INTO v_full_bidons, v_open_bidons, v_empty_bidons, v_current_volume_left
    FROM hotel_inventory
    WHERE hotel_id = v_room_product.hotel_id AND product_id = v_product.id
    FOR UPDATE;

    IF FOUND THEN
      -- If there is an open bidon but volume left is 0, initialize it to full volume
      IF v_open_bidons > 0 AND v_current_volume_left = 0.0 THEN
        v_current_volume_left := v_bidon_volume_ml;
      END IF;

      v_current_volume_left := v_current_volume_left - v_volume_added;

      WHILE v_current_volume_left <= 0 LOOP
        IF v_full_bidons > 0 THEN
          IF v_open_bidons > 0 THEN
            v_empty_bidons := v_empty_bidons + 1;
          END IF;
          v_full_bidons := v_full_bidons - 1;
          v_open_bidons := 1;
          v_current_volume_left := v_current_volume_left + v_bidon_volume_ml;
        ELSE
          IF v_open_bidons > 0 THEN
            v_empty_bidons := v_empty_bidons + 1;
          END IF;
          v_current_volume_left := 0.0;
          v_open_bidons := 0;
          EXIT; -- Out of stock
        END IF;
      END LOOP;

      UPDATE hotel_inventory
      SET full_bidons = v_full_bidons,
          open_bidons = v_open_bidons,
          empty_bidons = v_empty_bidons,
          open_bidon_volume_left_ml = v_current_volume_left,
          updated_at = now()
      WHERE hotel_id = v_room_product.hotel_id AND product_id = v_product.id;
    END IF;
  END IF;

  RETURN v_event_id;
END;
$$;


CREATE OR REPLACE FUNCTION undo_refill(
  p_refill_event_id uuid,
  p_client_request_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event refill_events%rowtype;
  v_product products%rowtype;
  v_undo_id uuid;
  
  -- Volume restoration
  v_percentage_val int := 100;
  v_percentage_str text;
  v_bottle_volume_ml double precision;
  v_bidon_volume_ml double precision;
  v_volume_to_restore double precision;
  v_current_volume_left double precision;
  v_full_bidons int;
  v_open_bidons int;
  v_empty_bidons int;
BEGIN
  SELECT * INTO v_event FROM refill_events WHERE id = p_refill_event_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Refill event not found';
  END IF;
  IF v_event.event_type <> 'refill' THEN
    RAISE EXCEPTION 'Only refill events can be undone';
  END IF;
  IF v_event.performed_by <> auth.uid() THEN
    RAISE EXCEPTION 'Only the user who recorded the refill can undo it';
  END IF;
  IF now() - v_event.occurred_at > interval '30 minutes' THEN
    RAISE EXCEPTION 'Undo window expired; submit a correction request';
  END IF;
  IF p_client_request_id IS NOT NULL THEN
    SELECT id INTO v_undo_id
    FROM refill_events
    WHERE client_request_id = p_client_request_id
      AND hotel_id = v_event.hotel_id
      AND undone_event_id = v_event.id;

    IF FOUND THEN
      RETURN v_undo_id;
    END IF;
  END IF;
  IF EXISTS (SELECT 1 FROM refill_events WHERE undone_event_id = v_event.id) THEN
    RAISE EXCEPTION 'Refill event was already undone';
  END IF;

  UPDATE room_products
  SET refill_count = v_event.previous_refill_count,
      status = 'active'
  WHERE id = v_event.room_product_id;

  INSERT INTO refill_events (
    hotel_id,
    room_product_id,
    event_type,
    previous_refill_count,
    new_refill_count,
    performed_by,
    undone_event_id,
    client_request_id
  )
  VALUES (
    v_event.hotel_id,
    v_event.room_product_id,
    'undo',
    v_event.new_refill_count,
    v_event.previous_refill_count,
    auth.uid(),
    v_event.id,
    p_client_request_id
  )
  RETURNING id INTO v_undo_id;

  -- Extract the room product and target product for inventory restoration
  SELECT * INTO v_product FROM products 
  WHERE id = (SELECT product_id FROM room_products WHERE id = v_event.room_product_id);

  IF v_product.refill_type = 'refillable' THEN
    IF v_event.notes IS NOT NULL THEN
      v_percentage_str := substring(v_event.notes FROM '\[Refill:\s*(\d+)%\]');
      IF v_percentage_str IS NOT NULL THEN
        v_percentage_val := v_percentage_str::int;
      END IF;
    END IF;

    v_bottle_volume_ml := COALESCE(v_product.bottle_volume_ml, 1000)::double precision;
    v_bidon_volume_ml := COALESCE(v_product.bidon_volume_ml, 5000)::double precision;
    v_volume_to_restore := (v_percentage_val::double precision / 100.0) * v_bottle_volume_ml;

    -- Fetch inventory row
    SELECT full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml
    INTO v_full_bidons, v_open_bidons, v_empty_bidons, v_current_volume_left
    FROM hotel_inventory
    WHERE hotel_id = v_event.hotel_id AND product_id = v_product.id
    FOR UPDATE;

    IF FOUND THEN
      IF v_open_bidons = 0 AND v_empty_bidons > 0 THEN
        v_open_bidons := 1;
        v_empty_bidons := v_empty_bidons - 1;
        v_current_volume_left := 0.0;
      END IF;

      v_current_volume_left := v_current_volume_left + v_volume_to_restore;

      WHILE v_current_volume_left > v_bidon_volume_ml AND v_empty_bidons > 0 LOOP
        v_empty_bidons := v_empty_bidons - 1;
        v_full_bidons := v_full_bidons + 1;
        v_current_volume_left := v_current_volume_left - v_bidon_volume_ml;
      END LOOP;

      IF v_current_volume_left > v_bidon_volume_ml THEN
        v_current_volume_left := v_bidon_volume_ml;
      END IF;

      UPDATE hotel_inventory
      SET full_bidons = v_full_bidons,
          open_bidons = v_open_bidons,
          empty_bidons = v_empty_bidons,
          open_bidon_volume_left_ml = v_current_volume_left,
          updated_at = now()
      WHERE hotel_id = v_event.hotel_id AND product_id = v_product.id;
    END IF;
  END IF;

  RETURN v_undo_id;
END;
$$;
