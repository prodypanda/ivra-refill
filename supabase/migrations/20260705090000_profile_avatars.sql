-- ============================================================
-- Profile avatars: avatar_url column, avatars storage bucket,
-- and a permission-checked RPC to update a user's avatar.
--
-- Permissions for changing a user's avatar:
--   - the user themself
--   - a hotel_manager of the same hotel
--   - app_admin / app_manager (full access)
-- ============================================================

-- 1) Avatar column on profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_url text;

-- 2) Public avatars bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for the avatars bucket.
-- Reads are public (bucket is public); writes are limited to
-- authenticated users. Fine-grained "who may change whose avatar"
-- is enforced by the update_user_avatar RPC which is the only
-- thing that persists the URL onto the profile.
DROP POLICY IF EXISTS avatars_bucket_public_read ON storage.objects;
CREATE POLICY avatars_bucket_public_read
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS avatars_bucket_insert_auth ON storage.objects;
CREATE POLICY avatars_bucket_insert_auth
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS avatars_bucket_update_auth ON storage.objects;
CREATE POLICY avatars_bucket_update_auth
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS avatars_bucket_delete_auth ON storage.objects;
CREATE POLICY avatars_bucket_delete_auth
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'avatars');

-- 3) Permission-checked RPC to set a user's avatar_url
CREATE OR REPLACE FUNCTION public.update_user_avatar(
  p_user_id uuid,
  p_avatar_url text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller uuid := auth.uid();
  v_caller_role text;
  v_allowed boolean := false;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT role INTO v_caller_role FROM profiles WHERE id = v_caller;

  -- Self-service: anyone may change their own picture.
  IF v_caller = p_user_id THEN
    v_allowed := true;
  -- App admin / app manager: full access.
  ELSIF v_caller_role IN ('app_admin', 'app_manager') THEN
    v_allowed := true;
  -- Hotel manager: may change avatars of users in a hotel they manage.
  ELSIF v_caller_role = 'hotel_manager' THEN
    v_allowed := EXISTS (
      -- Shared hotel via profiles.hotel_id
      SELECT 1
      FROM profiles target
      WHERE target.id = p_user_id
        AND target.hotel_id IS NOT NULL
        AND has_hotel_access(target.hotel_id)
    ) OR EXISTS (
      -- Shared hotel via user_hotels join table
      SELECT 1
      FROM user_hotels uh_target
      WHERE uh_target.user_id = p_user_id
        AND has_hotel_access(uh_target.hotel_id)
    );
  END IF;

  IF NOT v_allowed THEN
    RAISE EXCEPTION 'Not authorized to update this user''s avatar';
  END IF;

  UPDATE profiles
  SET avatar_url = p_avatar_url
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile not found: %', p_user_id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_user_avatar(uuid, text) TO authenticated;
