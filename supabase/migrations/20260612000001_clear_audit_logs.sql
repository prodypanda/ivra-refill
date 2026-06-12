CREATE OR REPLACE FUNCTION public.clear_audit_logs()
RETURNS VOID AS $$
BEGIN
    -- Only allow app_admin to clear logs
    IF public.current_user_role() NOT IN ('app_admin') THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    DELETE FROM public.audit_logs;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
