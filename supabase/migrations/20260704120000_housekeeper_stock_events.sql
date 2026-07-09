-- Housekeeper stock events: full audit trail of every stock movement in a
-- housekeeper's cart, plus fixes:
--   * record_refill no longer silently proceeds when the housekeeper cart
--     has no bidon stock to cover the refill (raises an exception instead).
--   * All 5 housekeeper stock RPCs now log an event row.
-- Deltas are always from the CART's perspective (+ = into cart, - = out of cart).

-- 1. Events table
CREATE TABLE IF NOT EXISTS public.housekeeper_stock_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    hotel_id uuid NOT NULL REFERENCES public.hotels(id) ON DELETE CASCADE,
    housekeeper_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    event_type text NOT NULL CHECK (event_type IN ('checkout', 'return', 'room_placement', 'refill_use', 'replace_use')),
    full_bottles_delta int NOT NULL DEFAULT 0,
    empty_bottles_delta int NOT NULL DEFAULT 0,
    full_bidons_delta int NOT NULL DEFAULT 0,
    open_bidons_delta int NOT NULL DEFAULT 0,
    empty_bidons_delta int NOT NULL DEFAULT 0,
    volume_delta_ml double precision NOT NULL DEFAULT 0.0,
    room_product_id uuid REFERENCES public.room_products(id) ON DELETE SET NULL,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_hk_stock_events_housekeeper
    ON public.housekeeper_stock_events (housekeeper_id, product_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_hk_stock_events_hotel
    ON public.housekeeper_stock_events (hotel_id, created_at DESC);

ALTER TABLE public.housekeeper_stock_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS housekeeper_stock_events_select ON public.housekeeper_stock_events;
CREATE POLICY housekeeper_stock_events_select ON public.housekeeper_stock_events
    FOR SELECT TO authenticated
    USING (
        auth.uid() = housekeeper_id OR has_hotel_access(hotel_id)
    );

-- 2. checkout_housekeeper_stock: log 'checkout' event
CREATE OR REPLACE FUNCTION public.checkout_housekeeper_stock(p_housekeeper_id uuid, p_product_id uuid, p_full_bottles integer, p_full_bidons integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_hotel_id uuid;
  v_avail_bottles int;
  v_avail_bidons int;
BEGIN
  SELECT hotel_id INTO v_hotel_id FROM profiles WHERE id = p_housekeeper_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Housekeeper profile not found';
  END IF;

  IF NOT has_hotel_access(v_hotel_id) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  IF p_full_bottles < 0 OR p_full_bidons < 0 THEN
    RAISE EXCEPTION 'Invalid quantities';
  END IF;

  IF p_full_bottles = 0 AND p_full_bidons = 0 THEN
    RAISE EXCEPTION 'Nothing to checkout';
  END IF;

  SELECT full_bottles, full_bidons INTO v_avail_bottles, v_avail_bidons
  FROM hotel_inventory
  WHERE hotel_id = v_hotel_id AND product_id = p_product_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product inventory not found in this hotel';
  END IF;

  IF v_avail_bottles < p_full_bottles THEN
    RAISE EXCEPTION 'Insufficient full bottles in central inventory';
  END IF;

  IF v_avail_bidons < p_full_bidons THEN
    RAISE EXCEPTION 'Insufficient full bidons in central inventory';
  END IF;

  UPDATE hotel_inventory
  SET full_bottles = full_bottles - p_full_bottles,
      full_bidons = full_bidons - p_full_bidons,
      updated_at = now()
  WHERE hotel_id = v_hotel_id AND product_id = p_product_id;

  INSERT INTO housekeeper_allocations (
    housekeeper_id, hotel_id, product_id, full_bottles, full_bidons, updated_at
  )
  VALUES (
    p_housekeeper_id, v_hotel_id, p_product_id, p_full_bottles, p_full_bidons, now()
  )
  ON CONFLICT (housekeeper_id, product_id) DO UPDATE
  SET full_bottles = housekeeper_allocations.full_bottles + p_full_bottles,
      full_bidons = housekeeper_allocations.full_bidons + p_full_bidons,
      updated_at = now();

  INSERT INTO housekeeper_stock_events (
    hotel_id, housekeeper_id, product_id, event_type,
    full_bottles_delta, full_bidons_delta
  )
  VALUES (
    v_hotel_id, p_housekeeper_id, p_product_id, 'checkout',
    p_full_bottles, p_full_bidons
  );
END;
$function$;

-- 3. return_housekeeper_stock: log 'return' event
CREATE OR REPLACE FUNCTION public.return_housekeeper_stock(p_housekeeper_id uuid, p_product_id uuid, p_full_bottles integer, p_empty_bottles integer, p_full_bidons integer, p_open_bidons integer, p_empty_bidons integer, p_open_bidon_volume_left_ml double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_hotel_id uuid;
  v_alloc_full_bottles int;
  v_alloc_empty_bottles int;
  v_alloc_full_bidons int;
  v_alloc_open_bidons int;
  v_alloc_empty_bidons int;
  v_alloc_volume double precision;

  v_inv_full_bottles int;
  v_inv_empty_bottles int;
  v_inv_full_bidons int;
  v_inv_open_bidons int;
  v_inv_empty_bidons int;
  v_inv_volume double precision;

  v_bidon_volume_ml double precision;
BEGIN
  SELECT hotel_id INTO v_hotel_id FROM profiles WHERE id = p_housekeeper_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Housekeeper profile not found';
  END IF;

  IF NOT has_hotel_access(v_hotel_id) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT full_bottles, empty_bottles, full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml
  INTO v_alloc_full_bottles, v_alloc_empty_bottles, v_alloc_full_bidons, v_alloc_open_bidons, v_alloc_empty_bidons, v_alloc_volume
  FROM housekeeper_allocations
  WHERE housekeeper_id = p_housekeeper_id AND product_id = p_product_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No housekeeper allocation found for this product';
  END IF;

  IF p_full_bottles > v_alloc_full_bottles OR
     p_empty_bottles > v_alloc_empty_bottles OR
     p_full_bidons > v_alloc_full_bidons OR
     p_open_bidons > v_alloc_open_bidons OR
     p_empty_bidons > v_alloc_empty_bidons OR
     p_open_bidon_volume_left_ml > v_alloc_volume THEN
    RAISE EXCEPTION 'Returned quantities exceed housekeeper allocation';
  END IF;

  SELECT COALESCE(bidon_volume_ml, 5000)::double precision INTO v_bidon_volume_ml
  FROM products WHERE id = p_product_id;

  SELECT full_bottles, empty_bottles, full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml
  INTO v_inv_full_bottles, v_inv_empty_bottles, v_inv_full_bidons, v_inv_open_bidons, v_inv_empty_bidons, v_inv_volume
  FROM hotel_inventory
  WHERE hotel_id = v_hotel_id AND product_id = p_product_id
  FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO hotel_inventory (hotel_id, product_id, full_bottles, empty_bottles, full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml, updated_at)
    VALUES (v_hotel_id, p_product_id, 0, 0, 0, 0, 0, 0.0, now())
    RETURNING full_bottles, empty_bottles, full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml
    INTO v_inv_full_bottles, v_inv_empty_bottles, v_inv_full_bidons, v_inv_open_bidons, v_inv_empty_bidons, v_inv_volume;
  END IF;

  v_inv_full_bottles := v_inv_full_bottles + p_full_bottles;
  v_inv_empty_bottles := v_inv_empty_bottles + p_empty_bottles;
  v_inv_full_bidons := v_inv_full_bidons + p_full_bidons;
  v_inv_empty_bidons := v_inv_empty_bidons + p_empty_bidons;

  IF p_open_bidons > 0 OR p_open_bidon_volume_left_ml > 0 THEN
    IF v_inv_open_bidons = 0 THEN
      v_inv_open_bidons := 1;
      v_inv_volume := p_open_bidon_volume_left_ml;
    ELSE
      v_inv_volume := v_inv_volume + p_open_bidon_volume_left_ml;
    END IF;

    WHILE v_inv_volume >= v_bidon_volume_ml LOOP
      v_inv_volume := v_inv_volume - v_bidon_volume_ml;
      v_inv_full_bidons := v_inv_full_bidons + 1;
    END LOOP;

    IF v_inv_volume = 0.0 THEN
      v_inv_open_bidons := 0;
    ELSE
      v_inv_open_bidons := 1;
    END IF;
  END IF;

  UPDATE hotel_inventory
  SET full_bottles = v_inv_full_bottles,
      empty_bottles = v_inv_empty_bottles,
      full_bidons = v_inv_full_bidons,
      open_bidons = v_inv_open_bidons,
      empty_bidons = v_inv_empty_bidons,
      open_bidon_volume_left_ml = v_inv_volume,
      updated_at = now()
  WHERE hotel_id = v_hotel_id AND product_id = p_product_id;

  UPDATE housekeeper_allocations
  SET full_bottles = full_bottles - p_full_bottles,
      empty_bottles = empty_bottles - p_empty_bottles,
      full_bidons = full_bidons - p_full_bidons,
      open_bidons = open_bidons - p_open_bidons,
      empty_bidons = empty_bidons - p_empty_bidons,
      open_bidon_volume_left_ml = open_bidon_volume_left_ml - p_open_bidon_volume_left_ml,
      updated_at = now()
  WHERE housekeeper_id = p_housekeeper_id AND product_id = p_product_id;

  INSERT INTO housekeeper_stock_events (
    hotel_id, housekeeper_id, product_id, event_type,
    full_bottles_delta, empty_bottles_delta, full_bidons_delta,
    open_bidons_delta, empty_bidons_delta, volume_delta_ml
  )
  VALUES (
    v_hotel_id, p_housekeeper_id, p_product_id, 'return',
    -p_full_bottles, -p_empty_bottles, -p_full_bidons,
    -p_open_bidons, -p_empty_bidons, -p_open_bidon_volume_left_ml
  );
END;
$function$;

-- 4. use_housekeeper_stock_for_room: log 'room_placement' event
CREATE OR REPLACE FUNCTION public.use_housekeeper_stock_for_room(
  p_housekeeper_id uuid,
  p_product_id uuid,
  p_full_bottles integer DEFAULT 1,
  p_room_product_id uuid DEFAULT NULL
)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_hotel_id uuid;
  v_alloc_full_bottles int;
BEGIN
  IF p_full_bottles IS NULL OR p_full_bottles <= 0 THEN
    RAISE EXCEPTION 'Invalid quantity';
  END IF;

  SELECT hotel_id INTO v_hotel_id FROM profiles WHERE id = p_housekeeper_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Housekeeper profile not found';
  END IF;

  IF NOT has_hotel_access(v_hotel_id) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT full_bottles INTO v_alloc_full_bottles
  FROM housekeeper_allocations
  WHERE housekeeper_id = p_housekeeper_id AND product_id = p_product_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No housekeeper allocation found for this product';
  END IF;

  IF v_alloc_full_bottles < p_full_bottles THEN
    RAISE EXCEPTION 'Insufficient full bottles in housekeeper allocation';
  END IF;

  UPDATE housekeeper_allocations
  SET full_bottles = full_bottles - p_full_bottles,
      updated_at = now()
  WHERE housekeeper_id = p_housekeeper_id AND product_id = p_product_id;

  INSERT INTO housekeeper_stock_events (
    hotel_id, housekeeper_id, product_id, event_type, full_bottles_delta, room_product_id
  )
  VALUES (
    v_hotel_id, p_housekeeper_id, p_product_id, 'room_placement', -p_full_bottles, p_room_product_id
  );
END;
$function$;

-- 5. record_refill: housekeeper branch now (a) raises when out of bidon
--    stock instead of silently zeroing out, and (b) logs a 'refill_use' event.
CREATE OR REPLACE FUNCTION public.record_refill(p_room_product_id uuid, p_notes text DEFAULT NULL::text, p_client_request_id text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_room_product room_products%rowtype;
  v_product products%rowtype;
  v_new_count int;
  v_new_status bottle_status;
  v_event_id uuid;

  v_percentage_val int := 100;
  v_percentage_str text;
  v_bottle_volume_ml double precision;
  v_bidon_volume_ml double precision;
  v_volume_added double precision;
  v_current_volume_left double precision;
  v_full_bidons int;
  v_open_bidons int;
  v_empty_bidons int;

  -- Before-values for event delta computation
  v_before_full_bidons int;
  v_before_open_bidons int;
  v_before_empty_bidons int;
  v_before_volume double precision;
  v_total_available_volume double precision;

  v_is_housekeeper boolean := false;
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

  SELECT (role = 'housekeeper') INTO v_is_housekeeper
  FROM profiles WHERE id = auth.uid();

  SELECT * INTO v_product FROM products WHERE id = v_room_product.product_id;
  v_new_count := v_room_product.refill_count + 1;

  IF v_new_count >= v_product.max_refill_count THEN
    v_new_status := 'refill_limit_reached';
  ELSIF current_date - v_room_product.bottle_started_at >= v_product.max_bottle_age_days THEN
    v_new_status := 'too_old';
  ELSE
    v_new_status := 'refilled';
  END IF;

  -- Volume calculations and inventory updates happen BEFORE the refill_events
  -- insert so an out-of-stock exception rolls everything back atomically.
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

    IF v_is_housekeeper THEN
      -- Housekeeper path: consume from her cart
      INSERT INTO housekeeper_allocations (
        housekeeper_id, hotel_id, product_id, full_bottles, empty_bottles, full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml, updated_at
      )
      VALUES (
        auth.uid(), v_room_product.hotel_id, v_product.id, 0, 0, 0, 0, 0, 0.0, now()
      )
      ON CONFLICT (housekeeper_id, product_id) DO NOTHING;

      SELECT full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml
      INTO v_full_bidons, v_open_bidons, v_empty_bidons, v_current_volume_left
      FROM housekeeper_allocations
      WHERE housekeeper_id = auth.uid() AND product_id = v_product.id
      FOR UPDATE;

      IF v_open_bidons > 0 AND v_current_volume_left = 0.0 THEN
        v_current_volume_left := v_bidon_volume_ml;
      END IF;

      -- Out-of-stock guard: total available volume in cart must cover the refill
      v_total_available_volume := (v_full_bidons::double precision * v_bidon_volume_ml) +
        (CASE WHEN v_open_bidons > 0 THEN v_current_volume_left ELSE 0.0 END);

      IF v_total_available_volume < v_volume_added THEN
        RAISE EXCEPTION 'Insufficient bidon stock in housekeeper allocation';
      END IF;

      v_before_full_bidons := v_full_bidons;
      v_before_open_bidons := v_open_bidons;
      v_before_empty_bidons := v_empty_bidons;
      v_before_volume := v_current_volume_left;

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
          EXIT;
        END IF;
      END LOOP;

      UPDATE housekeeper_allocations
      SET full_bidons = v_full_bidons,
          open_bidons = v_open_bidons,
          empty_bidons = v_empty_bidons,
          open_bidon_volume_left_ml = v_current_volume_left,
          updated_at = now()
      WHERE housekeeper_id = auth.uid() AND product_id = v_product.id;

      INSERT INTO housekeeper_stock_events (
        hotel_id, housekeeper_id, product_id, event_type,
        full_bidons_delta, open_bidons_delta, empty_bidons_delta,
        volume_delta_ml, room_product_id
      )
      VALUES (
        v_room_product.hotel_id, auth.uid(), v_product.id, 'refill_use',
        v_full_bidons - v_before_full_bidons,
        v_open_bidons - v_before_open_bidons,
        v_empty_bidons - v_before_empty_bidons,
        -v_volume_added,
        p_room_product_id
      );

    ELSE
      -- Standard path: update central hotel_inventory
      SELECT full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml
      INTO v_full_bidons, v_open_bidons, v_empty_bidons, v_current_volume_left
      FROM hotel_inventory
      WHERE hotel_id = v_room_product.hotel_id AND product_id = v_product.id
      FOR UPDATE;

      IF FOUND THEN
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
            EXIT;
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

  RETURN v_event_id;
END;
$function$;

-- 6. replace_bottle: housekeeper branch logs a 'replace_use' event
CREATE OR REPLACE FUNCTION public.replace_bottle(p_room_product_id uuid, p_notes text DEFAULT NULL::text, p_client_request_id text DEFAULT NULL::text, p_auto_adjust_inventory boolean DEFAULT false)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_room_product room_products%rowtype;
  v_event_id uuid;
  v_available_bottles int;
  v_product_name_en text;
  v_auto_adjusted boolean := false;

  v_is_housekeeper boolean := false;
BEGIN
  SELECT * INTO v_room_product
  FROM room_products
  WHERE id = p_room_product_id
  FOR UPDATE;

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

  SELECT (role = 'housekeeper') INTO v_is_housekeeper
  FROM profiles WHERE id = auth.uid();

  IF v_is_housekeeper THEN
    INSERT INTO housekeeper_allocations (
      housekeeper_id, hotel_id, product_id, full_bottles, empty_bottles, full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml, updated_at
    )
    VALUES (
      auth.uid(), v_room_product.hotel_id, v_room_product.product_id, 0, 0, 0, 0, 0, 0.0, now()
    )
    ON CONFLICT (housekeeper_id, product_id) DO NOTHING;

    SELECT coalesce(full_bottles, 0) INTO v_available_bottles
    FROM housekeeper_allocations
    WHERE housekeeper_id = auth.uid() AND product_id = v_room_product.product_id
    FOR UPDATE;

    IF v_available_bottles = 0 THEN
      IF NOT p_auto_adjust_inventory THEN
        SELECT name_en INTO v_product_name_en FROM products WHERE id = v_room_product.product_id;
        RAISE EXCEPTION 'Insufficient checked-out allocation for product %. Stock is 0.', v_product_name_en;
      ELSE
        v_auto_adjusted := true;
        UPDATE housekeeper_allocations
        SET full_bottles = full_bottles + 1,
            updated_at = now()
        WHERE housekeeper_id = auth.uid() AND product_id = v_room_product.product_id;
      END IF;
    END IF;

    UPDATE room_products
    SET refill_count = 0,
        last_refill_at = null,
        bottle_started_at = current_date,
        status = 'active'
    WHERE id = p_room_product_id;

    UPDATE housekeeper_allocations
    SET full_bottles = greatest(full_bottles - 1, 0),
        empty_bottles = empty_bottles + 1,
        updated_at = now()
    WHERE housekeeper_id = auth.uid()
      AND product_id = v_room_product.product_id;

    INSERT INTO housekeeper_stock_events (
      hotel_id, housekeeper_id, product_id, event_type,
      full_bottles_delta, empty_bottles_delta, room_product_id, notes
    )
    VALUES (
      v_room_product.hotel_id, auth.uid(), v_room_product.product_id, 'replace_use',
      -1, 1, p_room_product_id,
      CASE WHEN v_auto_adjusted THEN 'auto-adjusted' ELSE NULL END
    );

  ELSE
    SELECT coalesce(full_bottles, 0) INTO v_available_bottles
    FROM hotel_inventory
    WHERE hotel_id = v_room_product.hotel_id AND product_id = v_room_product.product_id;

    IF NOT FOUND THEN
      v_available_bottles := 0;
    END IF;

    IF v_available_bottles = 0 THEN
      IF NOT p_auto_adjust_inventory THEN
        SELECT name_en INTO v_product_name_en FROM products WHERE id = v_room_product.product_id;
        RAISE EXCEPTION 'Insufficient inventory for product %. Stock is 0.', v_product_name_en;
      ELSE
        INSERT INTO hotel_inventory (hotel_id, product_id, full_bottles, empty_bottles)
        VALUES (v_room_product.hotel_id, v_room_product.product_id, 1, 0)
        ON CONFLICT (hotel_id, product_id)
        DO UPDATE SET full_bottles = hotel_inventory.full_bottles + 1,
                      updated_at = now();

        INSERT INTO inventory_events (hotel_id, product_id, full_bottles_delta, reason, performed_by)
        VALUES (v_room_product.hotel_id, v_room_product.product_id, 1, 'Auto-adjusted for replacement', auth.uid());
      END IF;
    END IF;

    UPDATE room_products
    SET refill_count = 0,
        last_refill_at = null,
        bottle_started_at = current_date,
        status = 'active'
    WHERE id = p_room_product_id;

    UPDATE hotel_inventory
    SET full_bottles = greatest(full_bottles - 1, 0),
        empty_bottles = empty_bottles + 1,
        updated_at = now()
    WHERE hotel_id = v_room_product.hotel_id
      AND product_id = v_room_product.product_id;
  END IF;

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
    'bottle_replaced',
    v_room_product.refill_count,
    0,
    auth.uid(),
    p_notes,
    p_client_request_id
  )
  RETURNING id INTO v_event_id;

  RETURN v_event_id;
END;
$function$;
