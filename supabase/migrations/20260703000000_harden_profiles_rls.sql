-- Migration: Harden profiles RLS and protect sensitive columns
-- Drops the flawed "Users can update their own profile" policy which lacked a WITH CHECK clause,
-- and replaces it with a robust BEFORE UPDATE trigger to prevent non-admins from altering
-- their own `role` or `hotel_id` (privilege escalation).

-- First, drop the overly permissive policy
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Recreate it safely if needed (though the trigger handles the column protection)
CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
USING (id = auth.uid());

-- 1. Create a trigger function to protect sensitive profile columns
CREATE OR REPLACE FUNCTION protect_profile_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Allow app_admins and app_managers to modify any field
    IF is_app_admin(auth.uid()) OR current_user_role() = 'app_manager' THEN
        RETURN NEW;
    END IF;

    -- For normal users, prevent modifications to role, hotel_id, and is_active
    IF OLD.role IS DISTINCT FROM NEW.role THEN
        RAISE EXCEPTION 'Privilege escalation attempt: cannot modify role';
    END IF;

    IF OLD.hotel_id IS DISTINCT FROM NEW.hotel_id THEN
        RAISE EXCEPTION 'Privilege escalation attempt: cannot modify hotel_id';
    END IF;

    IF OLD.is_active IS DISTINCT FROM NEW.is_active THEN
        RAISE EXCEPTION 'Cannot modify active status';
    END IF;

    RETURN NEW;
END;
$$;

-- 2. Apply the trigger to the profiles table
DROP TRIGGER IF EXISTS trg_protect_profile_columns ON profiles;
CREATE TRIGGER trg_protect_profile_columns
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION protect_profile_columns();
