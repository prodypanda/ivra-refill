create or replace function auto_accept_invitations()
returns void
language plpgsql
security definer
as $$
declare
  v_invitation record;
  v_user_email text;
begin
  -- Get the current user's email
  select email into v_user_email from auth.users where id = auth.uid();
  
  if v_user_email is null then
    return;
  end if;

  -- Find all pending invitations for this email
  for v_invitation in
    select id, role, hotel_id, full_name
    from public.team_invitations
    where lower(email) = lower(v_user_email)
      and status = 'pending'
  loop
    -- Insert or update the profile with the invited role and hotel
    insert into public.profiles (id, full_name, role, hotel_id)
    values (auth.uid(), v_invitation.full_name, v_invitation.role, v_invitation.hotel_id)
    on conflict (id) do update
    set role = excluded.role,
        hotel_id = excluded.hotel_id,
        full_name = case when profiles.full_name is null then excluded.full_name else profiles.full_name end;
        
    -- Mark the invitation as accepted
    update public.team_invitations
    set status = 'accepted',
        accepted_at = now(),
        accepted_by = auth.uid()
    where id = v_invitation.id;
  end loop;
end;
$$;
