ALTER TABLE refill_events DROP CONSTRAINT IF EXISTS refill_events_correction_request_fk;
ALTER TABLE refill_events ADD CONSTRAINT refill_events_correction_request_fk FOREIGN KEY (correction_request_id) REFERENCES correction_requests(id) ON DELETE SET NULL;

DO $$
DECLARE
    fk_name text;
BEGIN
    SELECT constraint_name INTO fk_name
    FROM information_schema.key_column_usage
    WHERE table_name = 'refill_events' AND column_name = 'undone_event_id' AND constraint_name LIKE '%fkey%';

    IF fk_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE refill_events DROP CONSTRAINT ' || fk_name;
    END IF;
END $$;
ALTER TABLE refill_events ADD CONSTRAINT refill_events_undone_event_id_fkey FOREIGN KEY (undone_event_id) REFERENCES refill_events(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS audit_logs_user_id_idx ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS alerts_hotel_id_idx ON alerts(hotel_id);
CREATE INDEX IF NOT EXISTS refill_events_room_product_id_idx ON refill_events(room_product_id);

ALTER TABLE profiles ADD CONSTRAINT profiles_role_check CHECK (role IN ('app_admin', 'app_manager', 'hotel_manager', 'hotel_staff'));
ALTER TABLE approval_requests ADD CONSTRAINT approval_requests_status_check CHECK (status IN ('pending', 'accepted', 'cancelled', 'expired'));
