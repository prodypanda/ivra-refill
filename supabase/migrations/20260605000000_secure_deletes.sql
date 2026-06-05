-- Fix is_app_admin to also include app_manager
CREATE OR REPLACE FUNCTION is_app_admin(user_id uuid)
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role FROM profiles WHERE id = user_id;
    RETURN user_role IN ('app_admin', 'app_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper to check if caller is hotel_manager for a specific hotel
CREATE OR REPLACE FUNCTION is_hotel_manager(check_hotel_id uuid)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN is_app_admin(auth.uid()) OR EXISTS (
        SELECT 1 FROM user_hotels 
        WHERE user_id = auth.uid() AND hotel_id = check_hotel_id AND role IN ('hotel_manager', 'app_admin', 'app_manager')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to completely delete a user
CREATE OR REPLACE FUNCTION delete_user(target_user_id uuid)
RETURNS void AS $$
BEGIN
    -- Check if caller is app_admin/app_manager
    IF NOT is_app_admin(auth.uid()) THEN
        RAISE EXCEPTION 'Only App Admins and Managers can delete users';
    END IF;

    -- Delete from auth.users (will cascade to profiles, user_hotels, etc.)
    DELETE FROM auth.users WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function to secure delete operations
CREATE OR REPLACE FUNCTION check_delete_permission()
RETURNS TRIGGER AS $$
DECLARE
    table_name TEXT := TG_TABLE_NAME;
    h_id UUID;
BEGIN
    -- Only app_admin/app_manager can delete hotels and products
    IF table_name IN ('hotels', 'products') THEN
        IF NOT is_app_admin(auth.uid()) THEN
            RAISE EXCEPTION 'Only App Admins and Managers can delete %', table_name;
        END IF;
    -- For hotel-specific entities, hotel_manager can also delete
    ELSIF table_name IN ('rooms', 'floors', 'inventory_events', 'alerts') THEN
        -- get hotel_id
        IF table_name = 'rooms' THEN h_id := OLD.hotel_id;
        ELSIF table_name = 'floors' THEN h_id := OLD.hotel_id;
        ELSIF table_name = 'inventory_events' THEN h_id := OLD.hotel_id;
        ELSIF table_name = 'alerts' THEN h_id := OLD.hotel_id;
        END IF;

        IF NOT is_hotel_manager(h_id) THEN
            RAISE EXCEPTION 'Only Hotel Managers and App Admins can delete %', table_name;
        END IF;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
DROP TRIGGER IF EXISTS trg_check_delete_hotels ON hotels;
CREATE TRIGGER trg_check_delete_hotels BEFORE DELETE ON hotels FOR EACH ROW EXECUTE FUNCTION check_delete_permission();

DROP TRIGGER IF EXISTS trg_check_delete_products ON products;
CREATE TRIGGER trg_check_delete_products BEFORE DELETE ON products FOR EACH ROW EXECUTE FUNCTION check_delete_permission();

DROP TRIGGER IF EXISTS trg_check_delete_rooms ON rooms;
CREATE TRIGGER trg_check_delete_rooms BEFORE DELETE ON rooms FOR EACH ROW EXECUTE FUNCTION check_delete_permission();

DROP TRIGGER IF EXISTS trg_check_delete_floors ON floors;
CREATE TRIGGER trg_check_delete_floors BEFORE DELETE ON floors FOR EACH ROW EXECUTE FUNCTION check_delete_permission();

DROP TRIGGER IF EXISTS trg_check_delete_inventory_events ON inventory_events;
CREATE TRIGGER trg_check_delete_inventory_events BEFORE DELETE ON inventory_events FOR EACH ROW EXECUTE FUNCTION check_delete_permission();

DROP TRIGGER IF EXISTS trg_check_delete_alerts ON alerts;
CREATE TRIGGER trg_check_delete_alerts BEFORE DELETE ON alerts FOR EACH ROW EXECUTE FUNCTION check_delete_permission();
