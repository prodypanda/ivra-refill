-- Fix `has_hotel_access` to support both multi-hotel assignment (via user_hotels table)
-- and single-hotel assignment (via profiles table) for housekeepers, staff, and managers.
CREATE OR REPLACE FUNCTION has_hotel_access(check_hotel_id uuid)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN is_ivra_admin() OR EXISTS (
        SELECT 1 FROM user_hotels
        WHERE user_id = auth.uid() AND hotel_id = check_hotel_id
    ) OR EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND hotel_id = check_hotel_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
