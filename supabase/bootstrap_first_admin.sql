-- Ivra first-admin bootstrap.
--
-- Run after:
-- 1. supabase/migrations/0001_initial_schema.sql has been applied.
-- 2. The first admin user has been created in Supabase Auth.
--
-- Replace the placeholder values below before running.

create temp table if not exists ivra_first_admin_context (
  auth_user_id uuid not null,
  email text not null,
  full_name text not null
) on commit drop;

insert into ivra_first_admin_context (
  auth_user_id,
  email,
  full_name
) values (
  '00000000-0000-0000-0000-000000000001',
  'admin@ivra.test',
  'Ivra Admin'
);

do $$
begin
  if exists (
    select 1
    from ivra_first_admin_context
    where auth_user_id = '00000000-0000-0000-0000-000000000001'
       or email = 'admin@ivra.test'
  ) then
    raise exception 'Replace auth_user_id and email before running bootstrap_first_admin.sql.';
  end if;

  if not exists (
    select 1
    from auth.users u
    join ivra_first_admin_context c on c.auth_user_id = u.id
  ) then
    raise exception 'The configured auth_user_id does not exist in auth.users.';
  end if;
end $$;

insert into public.profiles (
  id,
  hotel_id,
  email,
  full_name,
  role,
  is_active
)
select
  auth_user_id,
  null,
  email,
  full_name,
  'app_admin'::public.user_role,
  true
from ivra_first_admin_context
on conflict (id) do update
set hotel_id = null,
    email = excluded.email,
    full_name = excluded.full_name,
    role = excluded.role,
    is_active = true,
    updated_at = now();

select
  'first admin ready' as status,
  p.id,
  p.email,
  p.full_name,
  p.role,
  p.is_active
from public.profiles p
join ivra_first_admin_context c on c.auth_user_id = p.id;
