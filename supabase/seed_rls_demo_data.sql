-- Ivra RLS demo-data seed.
--
-- Run after:
-- 1. supabase/migrations/0001_initial_schema.sql has been applied.
-- 2. Four Supabase Auth users exist for app_admin, app_manager, hotel_manager, and hotel_staff.
--
-- Replace the four AUTH USER ID placeholders before running.
-- The hotel IDs are deterministic so they can be copied into supabase/rls_verification.sql.
-- Change them if they conflict with existing data.

create temp table if not exists ivra_rls_seed_context (
  app_admin_id uuid not null,
  app_manager_id uuid not null,
  hotel_manager_id uuid not null,
  hotel_staff_id uuid not null,
  hotel_a_id uuid not null,
  hotel_b_id uuid not null
) on commit drop;

insert into ivra_rls_seed_context (
  app_admin_id,
  app_manager_id,
  hotel_manager_id,
  hotel_staff_id,
  hotel_a_id,
  hotel_b_id
) values (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000004',
  '10000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000002'
);

do $$
begin
  if exists (
    select 1
    from ivra_rls_seed_context
    where app_admin_id = '00000000-0000-0000-0000-000000000001'
       or app_manager_id = '00000000-0000-0000-0000-000000000002'
       or hotel_manager_id = '00000000-0000-0000-0000-000000000003'
       or hotel_staff_id = '00000000-0000-0000-0000-000000000004'
  ) then
    raise exception 'Replace all AUTH USER ID placeholders before running seed_rls_demo_data.sql.';
  end if;

  if (
    select count(*)
    from auth.users u
    join (
      select app_admin_id as id from ivra_rls_seed_context
      union all
      select app_manager_id from ivra_rls_seed_context
      union all
      select hotel_manager_id from ivra_rls_seed_context
      union all
      select hotel_staff_id from ivra_rls_seed_context
    ) expected on expected.id = u.id
  ) <> 4 then
    raise exception 'All four configured role user IDs must exist in auth.users.';
  end if;

  if (select count(*) from public.products where is_active) < 3 then
    raise exception 'Expected at least three active products. Apply the initial migration product seed first.';
  end if;
end $$;

insert into public.hotels (
  id,
  name,
  legal_name,
  contact_name,
  phone,
  email,
  address,
  city,
  country,
  notes,
  created_by
)
select
  hotel_a_id,
  'Ivra RLS Hotel A',
  'Ivra RLS Hotel A LLC',
  'Hotel A Manager',
  '+0000000001',
  'hotel-a@ivra.test',
  'Demo address A',
  'Demo City',
  'Demo Country',
  'RLS verification hotel A',
  app_admin_id
from ivra_rls_seed_context
on conflict (id) do update
set name = excluded.name,
    legal_name = excluded.legal_name,
    contact_name = excluded.contact_name,
    phone = excluded.phone,
    email = excluded.email,
    address = excluded.address,
    city = excluded.city,
    country = excluded.country,
    notes = excluded.notes,
    updated_at = now();

insert into public.hotels (
  id,
  name,
  legal_name,
  contact_name,
  phone,
  email,
  address,
  city,
  country,
  notes,
  created_by
)
select
  hotel_b_id,
  'Ivra RLS Hotel B',
  'Ivra RLS Hotel B LLC',
  'Hotel B Manager',
  '+0000000002',
  'hotel-b@ivra.test',
  'Demo address B',
  'Demo City',
  'Demo Country',
  'RLS verification hotel B',
  app_admin_id
from ivra_rls_seed_context
on conflict (id) do update
set name = excluded.name,
    legal_name = excluded.legal_name,
    contact_name = excluded.contact_name,
    phone = excluded.phone,
    email = excluded.email,
    address = excluded.address,
    city = excluded.city,
    country = excluded.country,
    notes = excluded.notes,
    updated_at = now();

insert into public.profiles (
  id,
  hotel_id,
  email,
  full_name,
  role,
  is_active
)
select app_admin_id, null, 'app-admin@ivra.test', 'RLS App Admin', 'app_admin'::public.user_role, true
from ivra_rls_seed_context
union all
select app_manager_id, null, 'app-manager@ivra.test', 'RLS App Manager', 'app_manager'::public.user_role, true
from ivra_rls_seed_context
union all
select hotel_manager_id, hotel_a_id, 'hotel-manager@ivra.test', 'RLS Hotel Manager', 'hotel_manager'::public.user_role, true
from ivra_rls_seed_context
union all
select hotel_staff_id, hotel_a_id, 'hotel-staff@ivra.test', 'RLS Hotel Staff', 'hotel_staff'::public.user_role, true
from ivra_rls_seed_context
on conflict (id) do update
set hotel_id = excluded.hotel_id,
    email = excluded.email,
    full_name = excluded.full_name,
    role = excluded.role,
    is_active = true,
    updated_at = now();

with floor_rows as (
  insert into public.floors (hotel_id, floor_number, name)
  select hotel_a_id, 1, 'Floor 1' from ivra_rls_seed_context
  union all
  select hotel_b_id, 1, 'Floor 1' from ivra_rls_seed_context
  on conflict (hotel_id, floor_number) do update
  set name = excluded.name,
      updated_at = now()
  returning id, hotel_id
),
room_inputs as (
  select c.hotel_a_id as hotel_id, f.id as floor_id, '101' as room_number
  from ivra_rls_seed_context c
  join floor_rows f on f.hotel_id = c.hotel_a_id
  union all
  select c.hotel_a_id, f.id, '102'
  from ivra_rls_seed_context c
  join floor_rows f on f.hotel_id = c.hotel_a_id
  union all
  select c.hotel_b_id, f.id, '201'
  from ivra_rls_seed_context c
  join floor_rows f on f.hotel_id = c.hotel_b_id
),
room_rows as (
  insert into public.rooms (hotel_id, floor_id, room_number)
  select hotel_id, floor_id, room_number
  from room_inputs
  on conflict (hotel_id, room_number) do update
  set floor_id = excluded.floor_id,
      updated_at = now()
  returning id, hotel_id
),
seed_products as (
  select id
  from public.products
  where is_active
  order by sku
  limit 3
)
insert into public.room_products (hotel_id, room_id, product_id)
select rr.hotel_id, rr.id, sp.id
from room_rows rr
cross join seed_products sp
on conflict (room_id, product_id) do nothing;

insert into public.hotel_inventory (
  hotel_id,
  product_id,
  full_bottles,
  empty_bottles,
  full_bidons,
  open_bidons,
  empty_bidons
)
select c.hotel_a_id, p.id, 8, 1, 3, 1, 0
from ivra_rls_seed_context c
cross join (
  select id
  from public.products
  where is_active
  order by sku
  limit 3
) p
union all
select c.hotel_b_id, p.id, 9, 0, 4, 0, 0
from ivra_rls_seed_context c
cross join (
  select id
  from public.products
  where is_active
  order by sku
  limit 3
) p
on conflict (hotel_id, product_id) do update
set full_bottles = excluded.full_bottles,
    empty_bottles = excluded.empty_bottles,
    full_bidons = excluded.full_bidons,
    open_bidons = excluded.open_bidons,
    empty_bidons = excluded.empty_bidons,
    updated_at = now();

select
  'RLS demo data ready' as status,
  app_admin_id,
  app_manager_id,
  hotel_manager_id,
  hotel_staff_id,
  hotel_a_id,
  hotel_b_id
from ivra_rls_seed_context;
