-- Drop the generic overly-permissive "FOR ALL" policies created in 0002_multi_hotel_support.sql
DROP POLICY IF EXISTS "Generic hotel access for floors" ON floors;
DROP POLICY IF EXISTS "Generic hotel access for rooms" ON rooms;
DROP POLICY IF EXISTS "Generic hotel access for products" ON products;
DROP POLICY IF EXISTS "Generic hotel access for room_products" ON room_products;
DROP POLICY IF EXISTS "Generic hotel access for hotel_inventory" ON hotel_inventory;
DROP POLICY IF EXISTS "Generic hotel access for refill_events" ON refill_events;
DROP POLICY IF EXISTS "Generic hotel access for correction_requests" ON correction_requests;
DROP POLICY IF EXISTS "Generic hotel access for approval_requests" ON approval_requests;
DROP POLICY IF EXISTS "Generic hotel access for inventory_events" ON inventory_events;
DROP POLICY IF EXISTS "Generic hotel access for alerts" ON alerts;
DROP POLICY IF EXISTS "Generic hotel access for user_invitations" ON user_invitations;

-- Re-instate restricted policies.
-- `has_hotel_access` is for read access (SELECT). Write operations require explicit permissions.

-- floors
CREATE POLICY "floors_select" ON floors FOR SELECT USING (has_hotel_access(hotel_id));
CREATE POLICY "floors_write_ivra" ON floors FOR ALL USING (is_ivra_admin()) WITH CHECK (is_ivra_admin());

-- rooms
CREATE POLICY "rooms_select" ON rooms FOR SELECT USING (has_hotel_access(hotel_id));
CREATE POLICY "rooms_write_ivra" ON rooms FOR ALL USING (is_ivra_admin()) WITH CHECK (is_ivra_admin());

-- products
CREATE POLICY "products_select" ON products FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "products_write_ivra" ON products FOR ALL USING (is_ivra_admin()) WITH CHECK (is_ivra_admin());

-- room_products
CREATE POLICY "room_products_select" ON room_products FOR SELECT USING (has_hotel_access(hotel_id));
CREATE POLICY "room_products_write_ivra" ON room_products FOR ALL USING (is_ivra_admin()) WITH CHECK (is_ivra_admin());

-- hotel_inventory
CREATE POLICY "inventory_select" ON hotel_inventory FOR SELECT USING (has_hotel_access(hotel_id));
-- inventory mutations are typically done via RPC, but let's ensure admins can manage them
CREATE POLICY "inventory_write_ivra" ON hotel_inventory FOR ALL USING (is_ivra_admin()) WITH CHECK (is_ivra_admin());

-- refill_events
CREATE POLICY "refill_events_select" ON refill_events FOR SELECT USING (has_hotel_access(hotel_id));
CREATE POLICY "refill_events_insert" ON refill_events FOR INSERT WITH CHECK (has_hotel_access(hotel_id));
-- Prevent updates or deletes on refill events for staff
CREATE POLICY "refill_events_write_ivra" ON refill_events FOR UPDATE USING (is_ivra_admin()) WITH CHECK (is_ivra_admin());
CREATE POLICY "refill_events_delete_ivra" ON refill_events FOR DELETE USING (is_ivra_admin());

-- correction_requests
CREATE POLICY "corrections_select" ON correction_requests FOR SELECT USING (has_hotel_access(hotel_id));
CREATE POLICY "corrections_insert" ON correction_requests FOR INSERT WITH CHECK (has_hotel_access(hotel_id));
CREATE POLICY "corrections_write_ivra" ON correction_requests FOR UPDATE USING (is_ivra_admin() OR (current_user_role() = 'hotel_manager' AND has_hotel_access(hotel_id))) WITH CHECK (is_ivra_admin() OR (current_user_role() = 'hotel_manager' AND has_hotel_access(hotel_id)));

-- approval_requests
CREATE POLICY "approvals_select" ON approval_requests FOR SELECT USING (has_hotel_access(hotel_id) OR is_ivra_admin());
CREATE POLICY "approvals_insert" ON approval_requests FOR INSERT WITH CHECK (has_hotel_access(hotel_id));
-- explicitly blocking self approvals via policy or ensuring it goes through RPC
CREATE POLICY "approvals_update" ON approval_requests FOR UPDATE USING (
  is_ivra_admin() OR (current_user_role() = 'hotel_manager' AND has_hotel_access(hotel_id) AND requested_by != auth.uid())
) WITH CHECK (
  is_ivra_admin() OR (current_user_role() = 'hotel_manager' AND has_hotel_access(hotel_id) AND requested_by != auth.uid())
);


-- inventory_events
CREATE POLICY "inventory_events_select" ON inventory_events FOR SELECT USING (has_hotel_access(hotel_id));
CREATE POLICY "inventory_events_insert" ON inventory_events FOR INSERT WITH CHECK (has_hotel_access(hotel_id));

-- alerts
CREATE POLICY "alerts_select" ON alerts FOR SELECT USING (hotel_id IS NULL OR has_hotel_access(hotel_id));
CREATE POLICY "alerts_write" ON alerts FOR UPDATE USING (has_hotel_access(hotel_id)) WITH CHECK (has_hotel_access(hotel_id));

-- user_invitations
CREATE POLICY "user_invitations_select" ON user_invitations FOR SELECT USING (
  is_ivra_admin()
  OR invited_by = auth.uid()
  OR (
    current_user_role() = 'hotel_manager'
    AND hotel_id = current_user_hotel_id()
  )
);
CREATE POLICY "user_invitations_insert" ON user_invitations FOR INSERT WITH CHECK (
  is_ivra_admin() OR (current_user_role() = 'hotel_manager' AND has_hotel_access(hotel_id))
);
CREATE POLICY "user_invitations_delete" ON user_invitations FOR DELETE USING (
  is_ivra_admin() OR (current_user_role() = 'hotel_manager' AND has_hotel_access(hotel_id))
);
