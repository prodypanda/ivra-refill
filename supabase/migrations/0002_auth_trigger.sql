-- Trigger to automatically create a profile and accept the invitation when a new user is invited
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_invitation_id uuid;
  v_invitation user_invitations%rowtype;
begin
  -- Check if the user was invited using our Edge Function (has invitation_id in metadata)
  v_invitation_id := (new.raw_user_meta_data->>'invitation_id')::uuid;

  if v_invitation_id is not null then
    -- Fetch the invitation details
    select * into v_invitation
    from user_invitations
    where id = v_invitation_id;

    if found then
      -- Insert the new user's profile automatically
      insert into public.profiles (
        id,
        hotel_id,
        email,
        full_name,
        role,
        is_active
      ) values (
        new.id,
        v_invitation.hotel_id,
        new.email,
        v_invitation.full_name,
        v_invitation.role,
        true
      );

      -- Mark the invitation as accepted
      update public.user_invitations
      set status = 'accepted',
          accepted_by = new.id,
          accepted_at = now()
      where id = v_invitation_id;
      
      -- Log the acceptance
      insert into audit_log (actor_id, hotel_id, entity_table, entity_id, action, new_data)
      values (
        new.id,
        v_invitation.hotel_id,
        'user_invitations',
        v_invitation_id,
        'team_invitation_accepted',
        jsonb_build_object('email', new.email, 'role', v_invitation.role)
      );
    end if;
  end if;

  return new;
end;
$$;

-- Drop the trigger if it already exists, then create it
drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
