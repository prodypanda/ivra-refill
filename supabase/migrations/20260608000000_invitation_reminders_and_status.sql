-- 1. Add reminders_sent column to user_invitations
ALTER TABLE public.user_invitations
ADD COLUMN reminders_sent INTEGER NOT NULL DEFAULT 0;

-- 2. Modify handle_user_verification trigger function to delay accepted status
CREATE OR REPLACE FUNCTION public.handle_user_verification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_invitation_id uuid;
  v_invitation user_invitations%rowtype;
BEGIN
  -- We only want to trigger profile creation when email_confirmed_at changes from null to not null
  -- This indicates the user has successfully clicked the invite/verification link
  IF OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL THEN
    
    v_invitation_id := (NEW.raw_user_meta_data->>'invitation_id')::uuid;

    IF v_invitation_id IS NOT NULL THEN
      -- Fetch the invitation details
      SELECT * INTO v_invitation
      FROM user_invitations
      WHERE id = v_invitation_id;

      IF FOUND THEN
        -- Insert the new user's profile automatically
        INSERT INTO public.profiles (
          id,
          hotel_id,
          email,
          full_name,
          role,
          is_active
        ) VALUES (
          NEW.id,
          v_invitation.hotel_id,
          NEW.email,
          v_invitation.full_name,
          v_invitation.role,
          true
        ) ON CONFLICT (id) DO NOTHING;
      END IF;
    END IF;
  END IF;

  -- Only mark the invitation as accepted when the user successfully sets their password!
  IF OLD.encrypted_password IS NULL AND NEW.encrypted_password IS NOT NULL THEN
    v_invitation_id := (NEW.raw_user_meta_data->>'invitation_id')::uuid;

    IF v_invitation_id IS NOT NULL THEN
      SELECT * INTO v_invitation
      FROM user_invitations
      WHERE id = v_invitation_id;

      IF FOUND AND v_invitation.status = 'pending' THEN
        -- Mark the invitation as accepted
        UPDATE public.user_invitations
        SET status = 'accepted',
            accepted_by = NEW.id,
            accepted_at = now()
        WHERE id = v_invitation_id;
        
        -- Log the acceptance
        INSERT INTO audit_log (actor_id, hotel_id, entity_table, entity_id, action, new_data)
        VALUES (
          NEW.id,
          v_invitation.hotel_id,
          'user_invitations',
          v_invitation_id,
          'team_invitation_accepted',
          jsonb_build_object('email', NEW.email, 'role', v_invitation.role)
        );
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- 3. Create process_invitation_reminders function for cron job
CREATE OR REPLACE FUNCTION public.process_invitation_reminders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.user_invitations
  SET 
    created_at = now(),
    reminders_sent = reminders_sent + 1
  WHERE status = 'pending'
    AND created_at <= now() - interval '23 hours'
    AND reminders_sent < 5;
END;
$$;

-- 4. Schedule the pg_cron job
DO $$
BEGIN
  IF to_regnamespace('cron') IS NOT NULL THEN
    -- Try to unschedule if it exists
    BEGIN
      PERFORM cron.unschedule('ivra-invitation-reminders');
    EXCEPTION WHEN OTHERS THEN
      -- ignore
    END;
    
    PERFORM cron.schedule(
      'ivra-invitation-reminders',
      '0 * * * *', -- every hour
      'SELECT public.process_invitation_reminders();'
    );
  ELSE
    RAISE NOTICE 'pg_cron is unavailable; cannot schedule ivra-invitation-reminders.';
  END IF;
END $$;
