-- Drop the restrictive select policy on hotels and use has_hotel_access() which covers
-- both user_hotels (multi-hotel) and profiles.hotel_id (single-hotel/housekeeper assignment).
DROP POLICY IF EXISTS "Users can view assigned hotels or all if admin" ON hotels;
CREATE POLICY "Users can view assigned hotels or all if admin" ON hotels FOR SELECT USING (has_hotel_access(id));
