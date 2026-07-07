-- Fix auto_accept_invitations() to include the 'email' column when inserting/updating profiles.
-- The email column is NOT NULL on the profiles table, which previously caused this function to fail silently.

CREATE OR REPLACE FUNCTION auto_accept_invitations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_invitation record;
  v_user_email text;
BEGIN
  -- Get the current user's email
  SELECT email INTO v_user_email FROM auth.users WHERE id = auth.uid();
  
  IF v_user_email IS NULL THEN
    RETURN;
  END IF;

  -- Find all pending invitations for this email in public.user_invitations
  FOR v_invitation IN
    SELECT id, role, hotel_id, full_name, email
    FROM public.user_invitations
    WHERE lower(email) = lower(v_user_email)
      AND status = 'pending'
  LOOP
    -- Insert or update the profile with the invited role, email and hotel
    INSERT INTO public.profiles (id, full_name, role, hotel_id, email)
    VALUES (auth.uid(), v_invitation.full_name, v_invitation.role, v_invitation.hotel_id, COALESCE(v_invitation.email, v_user_email))
    ON CONFLICT (id) DO UPDATE
    SET role = excluded.role,
        hotel_id = excluded.hotel_id,
        email = excluded.email,
        full_name = CASE WHEN profiles.full_name IS NULL THEN excluded.full_name ELSE profiles.full_name END;
        
    -- Mark the invitation as accepted
    UPDATE public.user_invitations
    SET status = 'accepted',
        accepted_at = now(),
        accepted_by = auth.uid()
    WHERE id = v_invitation.id;
  END LOOP;
END;
$$;
