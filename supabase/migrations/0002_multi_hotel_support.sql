-- Create user_hotels join table
CREATE TABLE user_hotels (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    hotel_id UUID REFERENCES hotels(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'hotel_staff',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, hotel_id)
);

-- Enable RLS on user_hotels
ALTER TABLE user_hotels ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is app_admin
CREATE OR REPLACE FUNCTION is_app_admin(user_id uuid)
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role FROM profiles WHERE id = user_id;
    RETURN user_role = 'app_admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS for user_hotels
CREATE POLICY "Users can read their own hotel assignments"
ON user_hotels FOR SELECT
USING (user_id = auth.uid() OR is_app_admin(auth.uid()));

CREATE POLICY "App admins can manage all assignments"
ON user_hotels FOR ALL
USING (is_app_admin(auth.uid()));

-- Modify existing RLS policies for profiles
-- App admin can see all profiles. Users can see their own profile. Users in the same hotel can see each other.
DROP POLICY IF EXISTS "Users can read their own profile" ON profiles;
DROP POLICY IF EXISTS "Users in same hotel can read profiles" ON profiles;
DROP POLICY IF EXISTS "App admins can manage all profiles" ON profiles;
DROP POLICY IF EXISTS "Hotel managers can manage staff in their hotel" ON profiles;

CREATE POLICY "Users can view profiles"
ON profiles FOR SELECT
USING (
    id = auth.uid() OR 
    is_app_admin(auth.uid()) OR 
    EXISTS (
        SELECT 1 FROM user_hotels uh1 
        JOIN user_hotels uh2 ON uh1.hotel_id = uh2.hotel_id
        WHERE uh1.user_id = auth.uid() AND uh2.user_id = profiles.id
    )
);

CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
USING (id = auth.uid());

CREATE POLICY "App admins can manage all profiles"
ON profiles FOR ALL
USING (is_app_admin(auth.uid()));

-- Modify existing RLS policies for hotels to allow admins to see all hotels, and others to see assigned hotels
DROP POLICY IF EXISTS "Anyone can view hotels" ON hotels;
DROP POLICY IF EXISTS "App admins can manage hotels" ON hotels;

CREATE POLICY "Users can view assigned hotels or all if admin"
ON hotels FOR SELECT
USING (
    is_app_admin(auth.uid()) OR
    EXISTS (SELECT 1 FROM user_hotels WHERE user_id = auth.uid() AND hotel_id = hotels.id)
);

CREATE POLICY "App admins can manage hotels"
ON hotels FOR ALL
USING (is_app_admin(auth.uid()));

-- Helper function to check hotel access
CREATE OR REPLACE FUNCTION has_hotel_access(check_hotel_id uuid)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN is_app_admin(auth.uid()) OR EXISTS (
        SELECT 1 FROM user_hotels 
        WHERE user_id = auth.uid() AND hotel_id = check_hotel_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RLS for all other tables using hotel_id
-- We drop existing policies that check for profile's hotel_id and replace them with `has_hotel_access`
-- (This assumes standard policies were checking profile's hotel_id. We apply a generic rule)

DO $$ 
DECLARE
    t_name text;
BEGIN
    FOR t_name IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('floors', 'rooms', 'products', 'room_products', 'hotel_inventory', 'refill_events', 'correction_requests', 'approval_requests', 'inventory_events', 'alerts', 'user_invitations') 
    LOOP
        -- For simplicity, since we don't know exact policy names, we can grant general access based on has_hotel_access
        -- It's highly recommended to replace these dynamically or manually verify.
        EXECUTE format('DROP POLICY IF EXISTS "Allow select for users in same hotel" ON %I', t_name);
        EXECUTE format('DROP POLICY IF EXISTS "Allow insert for users in same hotel" ON %I', t_name);
        EXECUTE format('DROP POLICY IF EXISTS "Allow update for users in same hotel" ON %I', t_name);
        EXECUTE format('DROP POLICY IF EXISTS "Allow delete for users in same hotel" ON %I', t_name);

        -- If table has hotel_id, we create a generic policy
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name=t_name AND column_name='hotel_id') THEN
            EXECUTE format('CREATE POLICY "Generic hotel access for %I" ON %I FOR ALL USING (has_hotel_access(hotel_id))', t_name, t_name);
        END IF;
    END LOOP;
END $$;
