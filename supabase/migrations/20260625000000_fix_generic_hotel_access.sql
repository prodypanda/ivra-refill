-- Fix the dynamic RLS loop from 0002_multi_hotel_support.sql that incorrectly granted FOR ALL access.
-- We drop the insecure "Generic hotel access for %" policies and replace them with strict SELECT policies.
DO $$
DECLARE
    t_name text;
BEGIN
    FOR t_name IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('floors', 'rooms', 'products', 'room_products', 'hotel_inventory', 'refill_events', 'correction_requests', 'approval_requests', 'inventory_events', 'alerts', 'user_invitations')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Generic hotel access for %I" ON %I', t_name, t_name);

        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name=t_name AND column_name='hotel_id') THEN
            -- Some tables already have explicitly named policies like "floors_select", "rooms_select" from 0001
            -- But we can safely ensure they at least have a SELECT policy based on has_hotel_access.
            -- Using a generic _select name to prevent conflicts or dropping older ones if they aren't harmful.
            EXECUTE format('DROP POLICY IF EXISTS "%I_generic_select" ON %I', t_name, t_name);
            EXECUTE format('CREATE POLICY "%I_generic_select" ON %I FOR SELECT USING (has_hotel_access(hotel_id))', t_name, t_name);
        END IF;
    END LOOP;
END $$;
