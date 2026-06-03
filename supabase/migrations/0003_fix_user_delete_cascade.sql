-- Fix 1: Add ON DELETE CASCADE to all foreign keys referencing auth.users
-- This allows deleting users from the Supabase dashboard without FK errors.

-- user_invitations.invited_by
ALTER TABLE user_invitations
  DROP CONSTRAINT IF EXISTS user_invitations_invited_by_fkey,
  ADD CONSTRAINT user_invitations_invited_by_fkey
    FOREIGN KEY (invited_by) REFERENCES auth.users(id) ON DELETE CASCADE;

-- user_invitations.accepted_by
ALTER TABLE user_invitations
  DROP CONSTRAINT IF EXISTS user_invitations_accepted_by_fkey,
  ADD CONSTRAINT user_invitations_accepted_by_fkey
    FOREIGN KEY (accepted_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- refill_events.performed_by
ALTER TABLE refill_events
  DROP CONSTRAINT IF EXISTS refill_events_performed_by_fkey,
  ADD CONSTRAINT refill_events_performed_by_fkey
    FOREIGN KEY (performed_by) REFERENCES auth.users(id) ON DELETE CASCADE;

-- approval_requests.requested_by
ALTER TABLE approval_requests
  DROP CONSTRAINT IF EXISTS approval_requests_requested_by_fkey,
  ADD CONSTRAINT approval_requests_requested_by_fkey
    FOREIGN KEY (requested_by) REFERENCES auth.users(id) ON DELETE CASCADE;

-- approval_requests.reviewed_by
ALTER TABLE approval_requests
  DROP CONSTRAINT IF EXISTS approval_requests_reviewed_by_fkey,
  ADD CONSTRAINT approval_requests_reviewed_by_fkey
    FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- correction_requests.requested_by
ALTER TABLE correction_requests
  DROP CONSTRAINT IF EXISTS correction_requests_requested_by_fkey,
  ADD CONSTRAINT correction_requests_requested_by_fkey
    FOREIGN KEY (requested_by) REFERENCES auth.users(id) ON DELETE CASCADE;

-- correction_requests.reviewed_by
ALTER TABLE correction_requests
  DROP CONSTRAINT IF EXISTS correction_requests_reviewed_by_fkey,
  ADD CONSTRAINT correction_requests_reviewed_by_fkey
    FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- inventory_events.performed_by
ALTER TABLE inventory_events
  DROP CONSTRAINT IF EXISTS inventory_events_performed_by_fkey,
  ADD CONSTRAINT inventory_events_performed_by_fkey
    FOREIGN KEY (performed_by) REFERENCES auth.users(id) ON DELETE CASCADE;

-- audit_log.actor_id
ALTER TABLE audit_log
  DROP CONSTRAINT IF EXISTS audit_log_actor_id_fkey,
  ADD CONSTRAINT audit_log_actor_id_fkey
    FOREIGN KEY (actor_id) REFERENCES auth.users(id) ON DELETE SET NULL;

-- alerts.resolved_by
ALTER TABLE alerts
  DROP CONSTRAINT IF EXISTS alerts_resolved_by_fkey,
  ADD CONSTRAINT alerts_resolved_by_fkey
    FOREIGN KEY (resolved_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- hotels.created_by
ALTER TABLE hotels
  DROP CONSTRAINT IF EXISTS hotels_created_by_fkey,
  ADD CONSTRAINT hotels_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
