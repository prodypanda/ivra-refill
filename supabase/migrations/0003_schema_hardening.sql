-- Check constraints for enums
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check CHECK (role IN ('app_admin', 'app_manager', 'hotel_manager', 'hotel_staff', 'housekeeper'));
ALTER TABLE refill_events ADD CONSTRAINT refill_events_event_type_check CHECK (event_type IN ('refill', 'undo', 'correction_requested', 'correction_approved', 'correction_rejected', 'bottle_replaced'));
ALTER TABLE correction_requests ADD CONSTRAINT correction_requests_status_check CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled'));
ALTER TABLE approval_requests ADD CONSTRAINT approval_requests_status_check CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled'));

-- Missing indexes
CREATE INDEX rooms_floor_id_idx ON rooms(floor_id);
CREATE INDEX audit_log_actor_id_idx ON audit_log(actor_id);
CREATE INDEX audit_log_entity_id_idx ON audit_log(entity_id);
CREATE INDEX correction_requests_refill_event_id_idx ON correction_requests(refill_event_id);

-- Ensure client_request_id is uniquely constrained in all tables that use it for idempotency
ALTER TABLE housekeeper_allocations ADD CONSTRAINT housekeeper_allocations_client_request_id_key UNIQUE (client_request_id);
ALTER TABLE housekeeper_stock_events ADD CONSTRAINT housekeeper_stock_events_client_request_id_key UNIQUE (client_request_id);

-- Enforce explicit ON DELETE on existing foreign keys
ALTER TABLE refill_events DROP CONSTRAINT IF EXISTS refill_events_performed_by_fkey;
ALTER TABLE refill_events ADD CONSTRAINT refill_events_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES profiles(id) ON DELETE SET NULL;


-- Enable RLS just in case any table misses it (most do already have it, but for safety)
ALTER TABLE hotels ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE floors ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE hotel_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE refill_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE correction_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_hotels ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE housekeeper_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE housekeeper_stock_events ENABLE ROW LEVEL SECURITY;
