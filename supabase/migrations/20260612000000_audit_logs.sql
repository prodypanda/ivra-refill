-- Migration to add comprehensive security audit logs
-- Creates the table, enables RLS, and adds a secure RPC function

CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    details JSONB,
    ip_address INET,
    device_info TEXT
);

-- Enable Row Level Security
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Super admins can view all audit logs
CREATE POLICY "Super admins can view audit logs"
    ON public.audit_logs
    FOR SELECT
    USING (
        public.current_user_role() IN ('app_admin')
    );

-- Secure function to insert an audit log, capturing the user's ID and IP securely
CREATE OR REPLACE FUNCTION public.log_audit_action(p_action TEXT, p_details JSONB DEFAULT NULL, p_device_info TEXT DEFAULT NULL)
RETURNS VOID AS $$
DECLARE
  v_user_id UUID;
  v_ip INET;
  v_headers JSONB;
  v_ip_str TEXT;
BEGIN
  v_user_id := auth.uid();
  
  BEGIN
    -- current_setting('request.headers', true) returns a JSON string in PostgREST
    v_headers := current_setting('request.headers', true)::jsonb;
    -- x-forwarded-for might be a comma-separated list of IPs. We take the first one.
    v_ip_str := split_part(v_headers->>'x-forwarded-for', ',', 1);
    
    IF v_ip_str IS NOT NULL AND v_ip_str != '' THEN
      v_ip := v_ip_str::inet;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_ip := NULL;
  END;

  INSERT INTO public.audit_logs (user_id, action, details, ip_address, device_info)
  VALUES (v_user_id, p_action, p_details, v_ip, p_device_info);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
