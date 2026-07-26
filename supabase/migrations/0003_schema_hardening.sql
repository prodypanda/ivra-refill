ALTER TABLE refill_events
  DROP CONSTRAINT IF EXISTS refill_events_undone_event_id_fkey,
  ADD CONSTRAINT refill_events_undone_event_id_fkey FOREIGN KEY (undone_event_id) REFERENCES refill_events(id) ON DELETE SET NULL;

ALTER TABLE refill_events
  DROP CONSTRAINT IF EXISTS refill_events_correction_request_fk,
  ADD CONSTRAINT refill_events_correction_request_fk FOREIGN KEY (correction_request_id) REFERENCES correction_requests(id) ON DELETE SET NULL;

ALTER TABLE correction_requests
  DROP CONSTRAINT IF EXISTS correction_requests_refill_event_id_fkey,
  ADD CONSTRAINT correction_requests_refill_event_id_fkey FOREIGN KEY (refill_event_id) REFERENCES refill_events(id) ON DELETE CASCADE;

ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profiles_role_check,
  ADD CONSTRAINT profiles_role_check CHECK (role IN ('app_admin', 'app_manager', 'hotel_manager', 'hotel_staff'));

ALTER TABLE approval_requests
  DROP CONSTRAINT IF EXISTS approval_requests_status_check,
  ADD CONSTRAINT approval_requests_status_check CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled'));

CREATE INDEX IF NOT EXISTS refill_events_room_product_type_idx ON refill_events(room_product_id, event_type);
CREATE INDEX IF NOT EXISTS audit_log_actor_idx ON audit_log(actor_id);
