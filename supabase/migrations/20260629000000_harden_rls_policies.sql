-- Drop the overly permissive FOR ALL policies and replace them with strict FOR SELECT policies.
-- Mutations on these tables should rely on strict role hierarchy checks or SECURITY DEFINER RPCs.
DO $$
DECLARE
    t_name text;
BEGIN
    FOR t_name IN SELECT unnest(ARRAY['floors', 'rooms', 'products', 'room_products', 'hotel_inventory', 'refill_events', 'correction_requests', 'approval_requests', 'inventory_events', 'alerts', 'user_invitations'])
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Generic hotel access for %I" ON %I', t_name, t_name);

        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name=t_name AND column_name='hotel_id') THEN
            EXECUTE format('CREATE POLICY "Generic hotel access for %I" ON %I FOR SELECT USING (has_hotel_access(hotel_id))', t_name, t_name);
        END IF;
    END LOOP;
END $$;
