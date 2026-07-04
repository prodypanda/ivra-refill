-- Fix: housekeeper cart deduction when placing a product into a room.
-- The client previously did a direct UPDATE on housekeeper_allocations,
-- which is silently blocked by RLS (only a SELECT policy exists).
-- This SECURITY DEFINER RPC performs the deduction atomically, server-side.

CREATE OR REPLACE FUNCTION use_housekeeper_stock_for_room(
  p_housekeeper_id uuid,
  p_product_id uuid,
  p_full_bottles int DEFAULT 1
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_hotel_id uuid;
  v_alloc_full_bottles int;
BEGIN
  IF p_full_bottles IS NULL OR p_full_bottles <= 0 THEN
    RAISE EXCEPTION 'Invalid quantity';
  END IF;

  -- Get hotel of the housekeeper
  SELECT hotel_id INTO v_hotel_id FROM profiles WHERE id = p_housekeeper_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Housekeeper profile not found';
  END IF;

  IF NOT has_hotel_access(v_hotel_id) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Lock and check the housekeeper allocation
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

  -- Deduct from the housekeeper's cart
  UPDATE housekeeper_allocations
  SET full_bottles = full_bottles - p_full_bottles,
      updated_at = now()
  WHERE housekeeper_id = p_housekeeper_id AND product_id = p_product_id;
END;
$$;

GRANT EXECUTE ON FUNCTION use_housekeeper_stock_for_room(uuid, uuid, int) TO authenticated;
