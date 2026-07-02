-- Fix the typo in auto_accept_invitations() to query and update user_invitations instead of non-existent team_invitations
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
    SELECT id, role, hotel_id, full_name
    FROM public.user_invitations
    WHERE lower(email) = lower(v_user_email)
      AND status = 'pending'
  LOOP
    -- Insert or update the profile with the invited role and hotel
    INSERT INTO public.profiles (id, full_name, role, hotel_id)
    VALUES (auth.uid(), v_invitation.full_name, v_invitation.role, v_invitation.hotel_id)
    ON CONFLICT (id) DO UPDATE
    SET role = excluded.role,
        hotel_id = excluded.hotel_id,
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
