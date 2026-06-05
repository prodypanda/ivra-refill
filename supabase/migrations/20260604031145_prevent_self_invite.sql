create or replace function create_team_invitation(
  p_email text,
  p_full_name text,
  p_role text,
  p_hotel_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role user_role;
  v_invitation_id uuid;
begin
  v_role := p_role::user_role;

  if trim(p_email) = '' or position('@' in p_email) = 0 then
    raise exception 'A valid email is required';
  end if;
  if trim(p_full_name) = '' then
    raise exception 'Full name is required';
  end if;

  -- Prevent self-invitation
  if lower(trim(p_email)) = lower(coalesce(auth.jwt() ->> 'email', '')) then
    raise exception 'You cannot invite yourself';
  end if;

  if current_user_role() = 'hotel_manager' then
    if v_role <> 'hotel_staff' then
      raise exception 'Hotel managers can only invite hotel staff';
    end if;
    if p_hotel_id is distinct from current_user_hotel_id() then
      raise exception 'Hotel managers can only invite users to their own hotel';
    end if;
  elsif current_user_role() = 'app_manager' then
    if v_role in ('app_admin', 'app_manager') then
      raise exception 'Only app admins can invite Ivra admin users';
    end if;
  elsif current_user_role() is distinct from 'app_admin' then
    raise exception 'Access denied';
  end if;

  if v_role in ('hotel_manager', 'hotel_staff') and p_hotel_id is null then
    raise exception 'Hotel users require a hotel';
  end if;
  if v_role in ('app_admin', 'app_manager') and p_hotel_id is not null then
    raise exception 'Ivra users cannot be assigned to one hotel';
  end if;
  if exists (
    select 1
    from user_invitations
    where email = lower(trim(p_email))
      and status = 'pending'
  ) then
    raise exception 'A pending invitation already exists for this email';
  end if;

  insert into user_invitations (
    hotel_id,
    email,
    full_name,
    role,
    invited_by
  )
  values (
    p_hotel_id,
    lower(trim(p_email)),
    trim(p_full_name),
    v_role,
    auth.uid()
  )
  returning id into v_invitation_id;

  insert into audit_log (actor_id, hotel_id, entity_table, entity_id, action, new_data)
  values (
    auth.uid(),
    p_hotel_id,
    'user_invitations',
    v_invitation_id,
    'team_invited',
    jsonb_build_object('email', lower(trim(p_email)), 'role', v_role)
  );

  return v_invitation_id;
end;
$$;
