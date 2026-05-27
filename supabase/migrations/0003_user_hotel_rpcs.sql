-- =============================================
-- RPC: assign_user_hotel
-- Assigns a hotel to a user. Only app_admin / app_manager can call this.
-- =============================================
CREATE OR REPLACE FUNCTION assign_user_hotel(p_user_id uuid, p_hotel_id uuid)
RETURNS void AS $$
DECLARE
    caller_role TEXT;
BEGIN
    SELECT role INTO caller_role FROM profiles WHERE id = auth.uid();
    IF caller_role NOT IN ('app_admin', 'app_manager') THEN
        RAISE EXCEPTION 'Only app admins and managers can assign hotels';
    END IF;

    INSERT INTO user_hotels (user_id, hotel_id)
    VALUES (p_user_id, p_hotel_id)
    ON CONFLICT (user_id, hotel_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- RPC: unassign_user_hotel
-- Removes a hotel assignment from a user. Only app_admin / app_manager can call this.
-- =============================================
CREATE OR REPLACE FUNCTION unassign_user_hotel(p_user_id uuid, p_hotel_id uuid)
RETURNS void AS $$
DECLARE
    caller_role TEXT;
BEGIN
    SELECT role INTO caller_role FROM profiles WHERE id = auth.uid();
    IF caller_role NOT IN ('app_admin', 'app_manager') THEN
        RAISE EXCEPTION 'Only app admins and managers can unassign hotels';
    END IF;

    DELETE FROM user_hotels
    WHERE user_id = p_user_id AND hotel_id = p_hotel_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- RPC: get_user_hotels
-- Returns all hotel IDs assigned to a given user.
-- Callable by admins, managers, and the user themselves.
-- =============================================
CREATE OR REPLACE FUNCTION get_user_hotels(p_user_id uuid)
RETURNS TABLE(hotel_id uuid, hotel_name text) AS $$
DECLARE
    caller_role TEXT;
BEGIN
    SELECT role INTO caller_role FROM profiles WHERE id = auth.uid();
    IF caller_role NOT IN ('app_admin', 'app_manager') AND auth.uid() != p_user_id THEN
        RAISE EXCEPTION 'Insufficient permissions to view hotel assignments';
    END IF;

    RETURN QUERY
    SELECT uh.hotel_id, h.name
    FROM user_hotels uh
    JOIN hotels h ON h.id = uh.hotel_id
    WHERE uh.user_id = p_user_id
    ORDER BY h.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
