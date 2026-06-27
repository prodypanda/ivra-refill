-- Create roles table to support dynamic role creation in the future
CREATE TABLE IF NOT EXISTS public.roles (
    name text PRIMARY KEY,
    description text
);

-- Seed initial roles
INSERT INTO public.roles (name, description) VALUES
    ('app_admin', 'System Administrator with full access'),
    ('app_manager', 'App-wide Operations Manager'),
    ('hotel_manager', 'Manager restricted to a specific hotel'),
    ('hotel_staff', 'Staff member restricted to a specific hotel')
ON CONFLICT (name) DO NOTHING;

-- Create role_permissions table referencing public.roles
CREATE TABLE IF NOT EXISTS public.role_permissions (
    role text REFERENCES public.roles(name) ON DELETE CASCADE,
    permission text NOT NULL,
    is_enabled boolean NOT NULL DEFAULT false,
    PRIMARY KEY (role, permission)
);

-- Enable Row Level Security
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY roles_select ON public.roles FOR SELECT TO authenticated USING (true);
CREATE POLICY roles_write ON public.roles FOR ALL TO authenticated USING (is_app_admin());

CREATE POLICY role_permissions_select ON public.role_permissions FOR SELECT TO authenticated USING (true);
CREATE POLICY role_permissions_write ON public.role_permissions FOR ALL TO authenticated USING (is_app_admin());

-- Seed default permissions mapping the existing hardcoded permission logic
INSERT INTO public.role_permissions (role, permission, is_enabled) VALUES
    -- app_admin defaults
    ('app_admin', 'manage_hotels', true),
    ('app_admin', 'manage_rooms', true),
    ('app_admin', 'manage_products', true),
    ('app_admin', 'manage_team', true),
    ('app_admin', 'view_approvals', true),
    ('app_admin', 'approve_corrections', true),
    ('app_admin', 'view_reports', true),
    ('app_admin', 'send_notifications', true),
    ('app_admin', 'view_audit_logs', true),
    ('app_admin', 'view_alerts', true),
    ('app_admin', 'view_rooms', true),
    ('app_admin', 'view_inventory', true),
    ('app_admin', 'view_authorizations', true),
    
    -- app_manager defaults
    ('app_manager', 'manage_hotels', true),
    ('app_manager', 'manage_rooms', true),
    ('app_manager', 'manage_products', true),
    ('app_manager', 'manage_team', true),
    ('app_manager', 'view_approvals', true),
    ('app_manager', 'approve_corrections', true),
    ('app_manager', 'view_reports', true),
    ('app_manager', 'send_notifications', true),
    ('app_manager', 'view_audit_logs', false),
    ('app_manager', 'view_alerts', true),
    ('app_manager', 'view_rooms', true),
    ('app_manager', 'view_inventory', true),

    -- hotel_manager defaults
    ('hotel_manager', 'manage_hotels', true),
    ('hotel_manager', 'manage_rooms', true),
    ('hotel_manager', 'manage_products', false),
    ('hotel_manager', 'manage_team', true),
    ('hotel_manager', 'view_approvals', true),
    ('hotel_manager', 'approve_corrections', true),
    ('hotel_manager', 'view_reports', true),
    ('hotel_manager', 'send_notifications', false),
    ('hotel_manager', 'view_audit_logs', false),
    ('hotel_manager', 'view_alerts', true),
    ('hotel_manager', 'view_rooms', true),
    ('hotel_manager', 'view_inventory', true),

    -- hotel_staff defaults
    ('hotel_staff', 'manage_hotels', false),
    ('hotel_staff', 'manage_rooms', false),
    ('hotel_staff', 'manage_products', false),
    ('hotel_staff', 'manage_team', false),
    ('hotel_staff', 'view_approvals', false),
    ('hotel_staff', 'approve_corrections', false),
    ('hotel_staff', 'view_reports', false),
    ('hotel_staff', 'send_notifications', false),
    ('hotel_staff', 'view_audit_logs', false),
    ('hotel_staff', 'view_alerts', true),
    ('hotel_staff', 'view_rooms', true),
    ('hotel_staff', 'view_inventory', true)
ON CONFLICT (role, permission) DO NOTHING;
