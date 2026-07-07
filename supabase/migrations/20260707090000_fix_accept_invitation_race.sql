-- Make accept_team_invitation idempotent: if the invitation was already
-- accepted (e.g. by auto_accept_invitations racing ahead), succeed silently
-- rather than raising an error.  Also ensure the caller's profile is created
-- even when the invitation was already consumed.

create or replace function accept_team_invitation(p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invitation user_invitations%rowtype;
  v_auth_email text;
begin
  if auth.uid() is null then
    raise exception 'Sign in or create an account before accepting this invitation';
  end if;

  v_auth_email := lower(coalesce(auth.jwt() ->> 'email', ''));

  -- First try to find a pending invitation.
  select * into v_invitation
  from user_invitations
  where invite_token = p_token and status = 'pending'
  for update;

  if not found then
    -- Check if the invitation was already accepted (race with auto_accept).
    select * into v_invitation
    from user_invitations
    where invite_token = p_token and status = 'accepted';

    if not found then
      raise exception 'Invitation not found or has been cancelled';
    end if;

    -- Already accepted. Ensure the profile exists for the current user
    -- (auto_accept may have created it) and return successfully.
    insert into profiles (id, hotel_id, email, full_name, role, is_active)
    values (
      auth.uid(),
      v_invitation.hotel_id,
      v_invitation.email,
      v_invitation.full_name,
      v_invitation.role,
      true
    )
    on conflict (id) do update
    set hotel_id = excluded.hotel_id,
        email = excluded.email,
        full_name = excluded.full_name,
        role = excluded.role,
        is_active = true;

    return;
  end if;

  if lower(v_invitation.email) <> v_auth_email then
    raise exception 'This invitation belongs to a different email address';
  end if;

  insert into profiles (
    id,
    hotel_id,
    email,
    full_name,
    role,
    is_active
  )
  values (
    auth.uid(),
    v_invitation.hotel_id,
    v_invitation.email,
    v_invitation.full_name,
    v_invitation.role,
    true
  )
  on conflict (id) do update
  set hotel_id = excluded.hotel_id,
      email = excluded.email,
      full_name = excluded.full_name,
      role = excluded.role,
      is_active = true;

  update user_invitations
  set status = 'accepted',
      accepted_by = auth.uid(),
      accepted_at = now()
  where id = v_invitation.id;

  insert into audit_log (actor_id, hotel_id, entity_table, entity_id, action, new_data)
  values (
    auth.uid(),
    v_invitation.hotel_id,
    'user_invitations',
    v_invitation.id,
    'team_invitation_accepted',
    jsonb_build_object('email', v_invitation.email, 'role', v_invitation.role)
  );
end;
$$;
