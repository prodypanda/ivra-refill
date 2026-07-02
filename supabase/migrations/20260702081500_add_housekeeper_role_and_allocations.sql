-- Migration: Add Housekeeper Role and Allocations
-- Date: 2026-07-02

-- 1. Add 'housekeeper' to user_role enum
-- PostgreSQL doesn't allow ALTER TYPE ... ADD VALUE inside a transaction block in some environments,
-- but we can run it safely or conditionally. To make it highly resilient:
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumtypid = 'user_role'::regtype 
      AND enumlabel = 'housekeeper'
  ) THEN
    ALTER TYPE user_role ADD VALUE 'housekeeper';
  END IF;
END
$$;

-- 2. Seed 'housekeeper' role in roles table
INSERT INTO public.roles (name, description)
VALUES ('housekeeper', 'Femme de chambre (Housekeeper) with access to checkout and refill rooms')
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

-- 3. Seed default permissions for housekeeper
INSERT INTO public.role_permissions (role, permission, is_enabled) VALUES
    ('housekeeper', 'manage_hotels', false),
    ('housekeeper', 'manage_rooms', false),
    ('housekeeper', 'manage_products', false),
    ('housekeeper', 'manage_team', false),
    ('housekeeper', 'view_approvals', false),
    ('housekeeper', 'approve_corrections', false),
    ('housekeeper', 'view_reports', false),
    ('housekeeper', 'send_notifications', false),
    ('housekeeper', 'view_audit_logs', false),
    ('housekeeper', 'view_alerts', true),
    ('housekeeper', 'view_rooms', true),
    ('housekeeper', 'view_inventory', true)
ON CONFLICT (role, permission) DO UPDATE SET is_enabled = EXCLUDED.is_enabled;

-- 4. Create housekeeper_allocations table
CREATE TABLE IF NOT EXISTS public.housekeeper_allocations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    housekeeper_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    hotel_id uuid NOT NULL REFERENCES public.hotels(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    full_bottles int NOT NULL DEFAULT 0,
    empty_bottles int NOT NULL DEFAULT 0,
    full_bidons int NOT NULL DEFAULT 0,
    open_bidons int NOT NULL DEFAULT 0,
    empty_bidons int NOT NULL DEFAULT 0,
    open_bidon_volume_left_ml double precision NOT NULL DEFAULT 0.0,
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (housekeeper_id, product_id),
    CONSTRAINT chk_bottles CHECK (full_bottles >= 0 AND empty_bottles >= 0),
    CONSTRAINT chk_bidons CHECK (full_bidons >= 0 AND open_bidons >= 0 AND empty_bidons >= 0)
);

-- Enable RLS
ALTER TABLE public.housekeeper_allocations ENABLE ROW LEVEL SECURITY;

-- Select policy
DROP POLICY IF EXISTS housekeeper_allocations_select ON public.housekeeper_allocations;
CREATE POLICY housekeeper_allocations_select ON public.housekeeper_allocations
    FOR SELECT TO authenticated
    USING (
        auth.uid() = housekeeper_id OR has_hotel_access(hotel_id)
    );

-- 5. Create checkout_housekeeper_stock function
CREATE OR REPLACE FUNCTION checkout_housekeeper_stock(
  p_housekeeper_id uuid,
  p_product_id uuid,
  p_full_bottles int,
  p_full_bidons int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_hotel_id uuid;
  v_avail_bottles int;
  v_avail_bidons int;
BEGIN
  -- Get hotel_id of the housekeeper
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

  -- Lock and check central hotel inventory
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

  -- Deduct from central inventory
  UPDATE hotel_inventory
  SET full_bottles = full_bottles - p_full_bottles,
      full_bidons = full_bidons - p_full_bidons,
      updated_at = now()
  WHERE hotel_id = v_hotel_id AND product_id = p_product_id;

  -- Add to housekeeper allocations
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
END;
$$;

-- 6. Create return_housekeeper_stock function
CREATE OR REPLACE FUNCTION return_housekeeper_stock(
  p_housekeeper_id uuid,
  p_product_id uuid,
  p_full_bottles int,
  p_empty_bottles int,
  p_full_bidons int,
  p_open_bidons int,
  p_empty_bidons int,
  p_open_bidon_volume_left_ml double precision
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
  -- Get hotel of the housekeeper
  SELECT hotel_id INTO v_hotel_id FROM profiles WHERE id = p_housekeeper_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Housekeeper profile not found';
  END IF;

  IF NOT has_hotel_access(v_hotel_id) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Select and lock housekeeper allocation
  SELECT full_bottles, empty_bottles, full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml
  INTO v_alloc_full_bottles, v_alloc_empty_bottles, v_alloc_full_bidons, v_alloc_open_bidons, v_alloc_empty_bidons, v_alloc_volume
  FROM housekeeper_allocations
  WHERE housekeeper_id = p_housekeeper_id AND product_id = p_product_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No housekeeper allocation found for this product';
  END IF;

  -- Validate quantities
  IF p_full_bottles > v_alloc_full_bottles OR
     p_empty_bottles > v_alloc_empty_bottles OR
     p_full_bidons > v_alloc_full_bidons OR
     p_open_bidons > v_alloc_open_bidons OR
     p_empty_bidons > v_alloc_empty_bidons OR
     p_open_bidon_volume_left_ml > v_alloc_volume THEN
    RAISE EXCEPTION 'Returned quantities exceed housekeeper allocation';
  END IF;

  -- Get product bidon capacity
  SELECT COALESCE(bidon_volume_ml, 5000)::double precision INTO v_bidon_volume_ml
  FROM products WHERE id = p_product_id;

  -- Select and lock hotel inventory
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

  -- Update hotel inventory
  v_inv_full_bottles := v_inv_full_bottles + p_full_bottles;
  v_inv_empty_bottles := v_inv_empty_bottles + p_empty_bottles;
  v_inv_full_bidons := v_inv_full_bidons + p_full_bidons;
  v_inv_empty_bidons := v_inv_empty_bidons + p_empty_bidons;

  -- Merge returned open bidons volume
  IF p_open_bidons > 0 OR p_open_bidon_volume_left_ml > 0 THEN
    IF v_inv_open_bidons = 0 THEN
      v_inv_open_bidons := 1;
      v_inv_volume := p_open_bidon_volume_left_ml;
    ELSE
      v_inv_volume := v_inv_volume + p_open_bidon_volume_left_ml;
    END IF;

    -- If volume exceeds capacity, convert to full bidons
    WHILE v_inv_volume >= v_bidon_volume_ml LOOP
      v_inv_volume := v_inv_volume - v_bidon_volume_ml;
      v_inv_full_bidons := v_inv_full_bidons + 1;
    END LOOP;

    -- If no leftover volume remains, open_bidons is 0
    IF v_inv_volume = 0.0 THEN
      v_inv_open_bidons := 0;
    ELSE
      v_inv_open_bidons := 1;
    END IF;
  END IF;

  -- Update central inventory
  UPDATE hotel_inventory
  SET full_bottles = v_inv_full_bottles,
      empty_bottles = v_inv_empty_bottles,
      full_bidons = v_inv_full_bidons,
      open_bidons = v_inv_open_bidons,
      empty_bidons = v_inv_empty_bidons,
      open_bidon_volume_left_ml = v_inv_volume,
      updated_at = now()
  WHERE hotel_id = v_hotel_id AND product_id = p_product_id;

  -- Update housekeeper allocations (subtract returned)
  UPDATE housekeeper_allocations
  SET full_bottles = full_bottles - p_full_bottles,
      empty_bottles = empty_bottles - p_empty_bottles,
      full_bidons = full_bidons - p_full_bidons,
      open_bidons = open_bidons - p_open_bidons,
      empty_bidons = empty_bidons - p_empty_bidons,
      open_bidon_volume_left_ml = open_bidon_volume_left_ml - p_open_bidon_volume_left_ml,
      updated_at = now()
  WHERE housekeeper_id = p_housekeeper_id AND product_id = p_product_id;
END;
$$;

-- 7. Update record_refill to handle housekeeper allocations
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

  -- Role checks
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

    IF v_is_housekeeper THEN
      -- Housekeeper path: Update housekeeper_allocations
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

      UPDATE housekeeper_allocations
      SET full_bidons = v_full_bidons,
          open_bidons = v_open_bidons,
          empty_bidons = v_empty_bidons,
          open_bidon_volume_left_ml = v_current_volume_left,
          updated_at = now()
      WHERE housekeeper_id = auth.uid() AND product_id = v_product.id;

    ELSE
      -- Standard path: Update central hotel_inventory
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
  END IF;

  RETURN v_event_id;
END;
$$;

-- 8. Update undo_refill to handle housekeeper allocations
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

  -- Role checks
  v_is_housekeeper boolean := false;
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

  SELECT (role = 'housekeeper') INTO v_is_housekeeper
  FROM profiles WHERE id = v_event.performed_by;

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

    IF v_is_housekeeper THEN
      -- Housekeeper path: restore into housekeeper_allocations
      SELECT full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml
      INTO v_full_bidons, v_open_bidons, v_empty_bidons, v_current_volume_left
      FROM housekeeper_allocations
      WHERE housekeeper_id = v_event.performed_by AND product_id = v_product.id
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

        UPDATE housekeeper_allocations
        SET full_bidons = v_full_bidons,
            open_bidons = v_open_bidons,
            empty_bidons = v_empty_bidons,
            open_bidon_volume_left_ml = v_current_volume_left,
            updated_at = now()
        WHERE housekeeper_id = v_event.performed_by AND product_id = v_product.id;
      END IF;

    ELSE
      -- Standard path: restore into hotel_inventory
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
  END IF;

  RETURN v_undo_id;
END;
$$;

-- 9. Update replace_bottle to handle housekeeper allocations
CREATE OR REPLACE FUNCTION replace_bottle(
  p_room_product_id uuid,
  p_notes text DEFAULT NULL,
  p_client_request_id text DEFAULT NULL,
  p_auto_adjust_inventory boolean DEFAULT false
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_room_product room_products%rowtype;
  v_event_id uuid;
  v_available_bottles int;
  v_product_name_en text;

  -- Role checks
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
    -- Housekeeper path: check allocations
    INSERT INTO housekeeper_allocations (
      housekeeper_id, hotel_id, product_id, full_bottles, empty_bottles, full_bidons, open_bidons, empty_bidons, open_bidon_volume_left_ml, updated_at
    )
    VALUES (
      auth.uid(), v_room_product.hotel_id, v_room_product.product_id, 0, 0, 0, 0, 0, 0.0, now()
    )
    ON CONFLICT (housekeeper_id, product_id) DO NOTHING;

    SELECT coalesce(full_bottles, 0) INTO v_available_bottles
    FROM housekeeper_allocations
    WHERE housekeeper_id = auth.uid() AND product_id = v_room_product.product_id;

    IF v_available_bottles = 0 THEN
      IF NOT p_auto_adjust_inventory THEN
        SELECT name_en INTO v_product_name_en FROM products WHERE id = v_room_product.product_id;
        RAISE EXCEPTION 'Insufficient checked-out allocation for product %. Stock is 0.', v_product_name_en;
      ELSE
        -- Auto-adjust allocation
        UPDATE housekeeper_allocations
        SET full_bottles = full_bottles + 1,
            updated_at = now()
        WHERE housekeeper_id = auth.uid() AND product_id = v_room_product.product_id;
      END IF;
    END IF;

    -- Proceed with replacement
    UPDATE room_products
    SET refill_count = 0,
        last_refill_at = null,
        bottle_started_at = current_date,
        status = 'active'
    WHERE id = p_room_product_id;

    -- Deduct full, increment empty in housekeeper cart
    UPDATE housekeeper_allocations
    SET full_bottles = greatest(full_bottles - 1, 0),
        empty_bottles = empty_bottles + 1,
        updated_at = now()
    WHERE housekeeper_id = auth.uid()
      AND product_id = v_room_product.product_id;

  ELSE
    -- Standard path: check central hotel_inventory
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
        -- Auto-adjust central inventory
        INSERT INTO hotel_inventory (hotel_id, product_id, full_bottles, empty_bottles)
        VALUES (v_room_product.hotel_id, v_room_product.product_id, 1, 0)
        ON CONFLICT (hotel_id, product_id)
        DO UPDATE SET full_bottles = hotel_inventory.full_bottles + 1,
                      updated_at = now();

        -- Log event
        INSERT INTO inventory_events (hotel_id, product_id, full_bottles_delta, reason, performed_by)
        VALUES (v_room_product.hotel_id, v_room_product.product_id, 1, 'Auto-adjusted for replacement', auth.uid());
      END IF;
    END IF;

    -- Proceed with replacement
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
$$;
