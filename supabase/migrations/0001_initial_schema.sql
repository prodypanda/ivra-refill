create extension if not exists pgcrypto;

create type user_role as enum ('app_admin', 'app_manager', 'hotel_manager', 'hotel_staff');
create type approval_status as enum ('pending', 'approved', 'rejected', 'cancelled');
create type bottle_status as enum (
  'active',
  'needs_refill',
  'refilled',
  'refill_limit_reached',
  'too_old',
  'needs_replacement',
  'recycled',
  'damaged',
  'lost'
);
create type refill_event_type as enum (
  'refill',
  'undo',
  'correction_requested',
  'correction_approved',
  'correction_rejected',
  'bottle_replaced'
);
create type alert_type as enum (
  'low_bidon_stock',
  'low_bottle_stock',
  'bottle_age_limit',
  'refill_limit',
  'pending_approval',
  'suspicious_activity',
  'inactive_hotel'
);

create table hotels (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  legal_name text,
  contact_name text not null default '',
  phone text not null default '',
  email text not null default '',
  address text not null default '',
  city text not null default '',
  country text not null default '',
  notes text not null default '',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  hotel_id uuid references hotels(id) on delete set null,
  email text not null,
  full_name text not null,
  role user_role not null default 'hotel_staff',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table user_invitations (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid references hotels(id) on delete cascade,
  email text not null,
  full_name text not null,
  role user_role not null,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'cancelled', 'expired')),
  invite_token text not null unique default encode(gen_random_bytes(24), 'hex'),
  invited_by uuid not null references auth.users(id),
  accepted_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  accepted_at timestamptz
);

create table floors (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references hotels(id) on delete cascade,
  floor_number int not null,
  name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (hotel_id, floor_number)
);

create table rooms (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references hotels(id) on delete cascade,
  floor_id uuid not null references floors(id) on delete cascade,
  room_number text not null,
  room_label text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (hotel_id, room_number)
);

create table products (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  default_name text not null,
  name_en text not null,
  name_fr text not null,
  name_ar text not null,
  bottle_volume_ml int not null default 1000,
  bidon_volume_ml int not null default 5000,
  max_refill_count int not null default 10,
  max_bottle_age_days int not null default 240,
  low_bottle_threshold int not null default 12,
  low_bidon_threshold int not null default 4,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table room_products (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references hotels(id) on delete cascade,
  room_id uuid not null references rooms(id) on delete cascade,
  product_id uuid not null references products(id),
  bottle_started_at date not null default current_date,
  refill_count int not null default 0,
  last_refill_at timestamptz,
  status bottle_status not null default 'active',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (room_id, product_id)
);

create table hotel_inventory (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references hotels(id) on delete cascade,
  product_id uuid not null references products(id),
  full_bottles int not null default 0,
  empty_bottles int not null default 0,
  full_bidons int not null default 0,
  open_bidons int not null default 0,
  empty_bidons int not null default 0,
  updated_at timestamptz not null default now(),
  unique (hotel_id, product_id),
  check (full_bottles >= 0 and empty_bottles >= 0),
  check (full_bidons >= 0 and open_bidons >= 0 and empty_bidons >= 0)
);

create table refill_events (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references hotels(id) on delete cascade,
  room_product_id uuid not null references room_products(id) on delete cascade,
  event_type refill_event_type not null,
  previous_refill_count int not null default 0,
  new_refill_count int not null default 0,
  occurred_at timestamptz not null default now(),
  performed_by uuid not null references auth.users(id),
  undone_event_id uuid references refill_events(id),
  correction_request_id uuid,
  notes text,
  client_request_id text unique
);

create table correction_requests (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references hotels(id) on delete cascade,
  refill_event_id uuid not null references refill_events(id),
  reason text not null,
  status approval_status not null default 'pending',
  requested_by uuid not null references auth.users(id),
  reviewed_by uuid references auth.users(id),
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  review_notes text,
  client_request_id text unique
);

alter table refill_events
  add constraint refill_events_correction_request_fk
  foreign key (correction_request_id) references correction_requests(id);

create table approval_requests (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid references hotels(id) on delete cascade,
  title text not null,
  target_table text not null,
  target_id uuid,
  action text not null,
  status approval_status not null default 'pending',
  old_data jsonb not null default '{}'::jsonb,
  new_data jsonb not null default '{}'::jsonb,
  requested_by uuid not null references auth.users(id),
  reviewed_by uuid references auth.users(id),
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  review_notes text,
  client_request_id text unique
);

create table inventory_events (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references hotels(id) on delete cascade,
  product_id uuid not null references products(id),
  full_bottles_delta int not null default 0,
  empty_bottles_delta int not null default 0,
  full_bidons_delta int not null default 0,
  open_bidons_delta int not null default 0,
  empty_bidons_delta int not null default 0,
  reason text not null default '',
  performed_by uuid not null references auth.users(id),
  occurred_at timestamptz not null default now(),
  client_request_id text unique
);

create table audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id),
  hotel_id uuid references hotels(id) on delete set null,
  entity_table text not null,
  entity_id uuid,
  action text not null,
  old_data jsonb not null default '{}'::jsonb,
  new_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table alerts (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid references hotels(id) on delete cascade,
  room_product_id uuid references room_products(id) on delete cascade,
  product_id uuid references products(id),
  alert_type alert_type not null,
  severity int not null default 1 check (severity between 1 and 3),
  title text not null,
  body text not null,
  is_resolved boolean not null default false,
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index profiles_hotel_id_idx on profiles(hotel_id);
create index user_invitations_hotel_status_idx on user_invitations(hotel_id, status, created_at desc);
create index user_invitations_token_idx on user_invitations(invite_token);
create index rooms_hotel_id_idx on rooms(hotel_id);
create index room_products_hotel_room_idx on room_products(hotel_id, room_id);
create index refill_events_hotel_time_idx on refill_events(hotel_id, occurred_at desc);
create index approval_requests_status_idx on approval_requests(status, requested_at desc);
create index alerts_open_idx on alerts(hotel_id, is_resolved, created_at desc);
create index inventory_events_hotel_time_idx on inventory_events(hotel_id, occurred_at desc);

create or replace function current_user_role()
returns user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from profiles where id = auth.uid() and is_active
$$;

create or replace function current_user_hotel_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select hotel_id from profiles where id = auth.uid() and is_active
$$;

create or replace function is_ivra_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(current_user_role() in ('app_admin', 'app_manager'), false)
$$;

create or replace function is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(current_user_role() = 'app_admin', false)
$$;

create or replace function has_hotel_access(p_hotel_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(is_ivra_admin() or current_user_hotel_id() = p_hotel_id, false)
$$;

alter table hotels enable row level security;
alter table profiles enable row level security;
alter table user_invitations enable row level security;
alter table floors enable row level security;
alter table rooms enable row level security;
alter table products enable row level security;
alter table room_products enable row level security;
alter table hotel_inventory enable row level security;
alter table refill_events enable row level security;
alter table correction_requests enable row level security;
alter table approval_requests enable row level security;
alter table inventory_events enable row level security;
alter table audit_log enable row level security;
alter table alerts enable row level security;

create policy "hotels_select" on hotels for select using (has_hotel_access(id));
create policy "hotels_insert_ivra" on hotels for insert with check (is_ivra_admin());
create policy "hotels_update_ivra" on hotels for update using (is_ivra_admin());

create policy "profiles_select" on profiles for select using (
  id = auth.uid()
  or is_ivra_admin()
  or (
    current_user_role() = 'hotel_manager'
    and hotel_id = current_user_hotel_id()
  )
);

create policy "user_invitations_select" on user_invitations for select using (
  is_ivra_admin()
  or invited_by = auth.uid()
  or (
    current_user_role() = 'hotel_manager'
    and hotel_id = current_user_hotel_id()
  )
);

create policy "floors_select" on floors for select using (has_hotel_access(hotel_id));
create policy "floors_write_ivra" on floors for all using (is_ivra_admin()) with check (is_ivra_admin());

create policy "rooms_select" on rooms for select using (has_hotel_access(hotel_id));
create policy "rooms_write_ivra" on rooms for all using (is_ivra_admin()) with check (is_ivra_admin());

create policy "products_select" on products for select using (auth.uid() is not null);
create policy "products_write_ivra" on products for all using (is_ivra_admin()) with check (is_ivra_admin());

create policy "room_products_select" on room_products for select using (has_hotel_access(hotel_id));
create policy "room_products_write_ivra" on room_products for all using (is_ivra_admin()) with check (is_ivra_admin());

create policy "inventory_select" on hotel_inventory for select using (has_hotel_access(hotel_id));

create policy "refill_events_select" on refill_events for select using (has_hotel_access(hotel_id));

create policy "corrections_select" on correction_requests for select using (has_hotel_access(hotel_id));

create policy "approvals_select" on approval_requests for select using (has_hotel_access(hotel_id) or is_ivra_admin());

create policy "inventory_events_select" on inventory_events for select using (has_hotel_access(hotel_id));

create policy "audit_select_ivra" on audit_log for select using (is_ivra_admin());

create policy "alerts_select" on alerts for select using (hotel_id is null or has_hotel_access(hotel_id));

create or replace function touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger hotels_touch before update on hotels
for each row execute function touch_updated_at();
create trigger profiles_touch before update on profiles
for each row execute function touch_updated_at();
create trigger floors_touch before update on floors
for each row execute function touch_updated_at();
create trigger rooms_touch before update on rooms
for each row execute function touch_updated_at();
create trigger products_touch before update on products
for each row execute function touch_updated_at();
create trigger room_products_touch before update on room_products
for each row execute function touch_updated_at();

create or replace function record_refill(
  p_room_product_id uuid,
  p_notes text default null,
  p_client_request_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_product room_products%rowtype;
  v_product products%rowtype;
  v_new_count int;
  v_new_status bottle_status;
  v_event_id uuid;
begin
  select * into v_room_product from room_products where id = p_room_product_id for update;
  if not found then
    raise exception 'Room product not found';
  end if;
  if not has_hotel_access(v_room_product.hotel_id) then
    raise exception 'Access denied';
  end if;

  if p_client_request_id is not null then
    select id into v_event_id
    from refill_events
    where client_request_id = p_client_request_id
      and hotel_id = v_room_product.hotel_id;

    if found then
      return v_event_id;
    end if;
  end if;

  select * into v_product from products where id = v_room_product.product_id;
  v_new_count := v_room_product.refill_count + 1;

  if v_new_count >= v_product.max_refill_count then
    v_new_status := 'refill_limit_reached';
  elsif current_date - v_room_product.bottle_started_at >= v_product.max_bottle_age_days then
    v_new_status := 'too_old';
  else
    v_new_status := 'refilled';
  end if;

  update room_products
  set refill_count = v_new_count,
      last_refill_at = now(),
      status = v_new_status
  where id = p_room_product_id;

  insert into refill_events (
    hotel_id,
    room_product_id,
    event_type,
    previous_refill_count,
    new_refill_count,
    performed_by,
    notes,
    client_request_id
  )
  values (
    v_room_product.hotel_id,
    p_room_product_id,
    'refill',
    v_room_product.refill_count,
    v_new_count,
    auth.uid(),
    p_notes,
    p_client_request_id
  )
  returning id into v_event_id;

  if v_new_status in ('refill_limit_reached', 'too_old') then
    insert into alerts (hotel_id, room_product_id, product_id, alert_type, severity, title, body)
    values (
      v_room_product.hotel_id,
      p_room_product_id,
      v_room_product.product_id,
      case when v_new_status = 'too_old' then 'bottle_age_limit'::alert_type else 'refill_limit'::alert_type end,
      3,
      'Bottle replacement needed',
      'A room product bottle reached an Ivra replacement rule.'
    );
  end if;

  return v_event_id;
end;
$$;

create or replace function replace_bottle(
  p_room_product_id uuid,
  p_notes text default null,
  p_client_request_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_product room_products%rowtype;
  v_event_id uuid;
begin
  select * into v_room_product
  from room_products
  where id = p_room_product_id
  for update;

  if not found then
    raise exception 'Room product not found';
  end if;

  if not has_hotel_access(v_room_product.hotel_id) then
    raise exception 'Access denied';
  end if;

  if p_client_request_id is not null then
    select id into v_event_id
    from refill_events
    where client_request_id = p_client_request_id
      and hotel_id = v_room_product.hotel_id;

    if found then
      return v_event_id;
    end if;
  end if;

  update room_products
  set refill_count = 0,
      last_refill_at = null,
      bottle_started_at = current_date,
      status = 'active'
  where id = p_room_product_id;

  update hotel_inventory
  set full_bottles = greatest(full_bottles - 1, 0),
      empty_bottles = empty_bottles + 1,
      updated_at = now()
  where hotel_id = v_room_product.hotel_id
    and product_id = v_room_product.product_id;

  insert into refill_events (
    hotel_id,
    room_product_id,
    event_type,
    previous_refill_count,
    new_refill_count,
    performed_by,
    notes,
    client_request_id
  )
  values (
    v_room_product.hotel_id,
    p_room_product_id,
    'bottle_replaced',
    v_room_product.refill_count,
    0,
    auth.uid(),
    p_notes,
    p_client_request_id
  )
  returning id into v_event_id;

  update alerts
  set is_resolved = true,
      resolved_at = now(),
      resolved_by = auth.uid()
  where room_product_id = p_room_product_id
    and not is_resolved
    and alert_type in ('refill_limit', 'bottle_age_limit');

  return v_event_id;
end;
$$;

create or replace function undo_refill(
  p_refill_event_id uuid,
  p_client_request_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event refill_events%rowtype;
  v_undo_id uuid;
begin
  select * into v_event from refill_events where id = p_refill_event_id for update;
  if not found then
    raise exception 'Refill event not found';
  end if;
  if v_event.event_type <> 'refill' then
    raise exception 'Only refill events can be undone';
  end if;
  if v_event.performed_by <> auth.uid() then
    raise exception 'Only the user who recorded the refill can undo it';
  end if;
  if now() - v_event.occurred_at > interval '30 minutes' then
    raise exception 'Undo window expired; submit a correction request';
  end if;
  if p_client_request_id is not null then
    select id into v_undo_id
    from refill_events
    where client_request_id = p_client_request_id
      and hotel_id = v_event.hotel_id
      and undone_event_id = v_event.id;

    if found then
      return v_undo_id;
    end if;
  end if;
  if exists (select 1 from refill_events where undone_event_id = v_event.id) then
    raise exception 'Refill event was already undone';
  end if;

  update room_products
  set refill_count = v_event.previous_refill_count,
      status = 'active'
  where id = v_event.room_product_id;

  insert into refill_events (
    hotel_id,
    room_product_id,
    event_type,
    previous_refill_count,
    new_refill_count,
    performed_by,
    undone_event_id,
    client_request_id
  )
  values (
    v_event.hotel_id,
    v_event.room_product_id,
    'undo',
    v_event.new_refill_count,
    v_event.previous_refill_count,
    auth.uid(),
    v_event.id,
    p_client_request_id
  )
  returning id into v_undo_id;

  return v_undo_id;
end;
$$;

create or replace function request_refill_correction(
  p_refill_event_id uuid,
  p_reason text,
  p_client_request_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event refill_events%rowtype;
  v_request_id uuid;
begin
  select * into v_event from refill_events where id = p_refill_event_id;
  if not found then
    raise exception 'Refill event not found';
  end if;
  if not has_hotel_access(v_event.hotel_id) then
    raise exception 'Access denied';
  end if;

  if p_client_request_id is not null then
    select id into v_request_id
    from correction_requests
    where client_request_id = p_client_request_id
      and hotel_id = v_event.hotel_id;

    if found then
      return v_request_id;
    end if;
  end if;

  insert into correction_requests (
    hotel_id,
    refill_event_id,
    reason,
    requested_by,
    client_request_id
  )
  values (
    v_event.hotel_id,
    p_refill_event_id,
    p_reason,
    auth.uid(),
    p_client_request_id
  )
  returning id into v_request_id;

  insert into refill_events (
    hotel_id,
    room_product_id,
    event_type,
    previous_refill_count,
    new_refill_count,
    performed_by,
    correction_request_id,
    notes
  )
  values (
    v_event.hotel_id,
    v_event.room_product_id,
    'correction_requested',
    v_event.previous_refill_count,
    v_event.new_refill_count,
    auth.uid(),
    v_request_id,
    p_reason
  );

  insert into approval_requests (
    hotel_id,
    title,
    target_table,
    target_id,
    action,
    old_data,
    new_data,
    requested_by,
    client_request_id
  )
  values (
    v_event.hotel_id,
    'Correction request for refill event',
    'correction_requests',
    v_request_id,
    'correction',
    jsonb_build_object(
      'refill_event_id', v_event.id,
      'room_product_id', v_event.room_product_id,
      'refill_count', v_event.new_refill_count
    ),
    jsonb_build_object(
      'reason', p_reason,
      'requested_refill_count', v_event.previous_refill_count
    ),
    auth.uid(),
    p_client_request_id
  );

  return v_request_id;
end;
$$;

create or replace function submit_change_request(
  p_hotel_id uuid,
  p_title text,
  p_target_table text,
  p_target_id uuid,
  p_action text,
  p_old_data jsonb,
  p_new_data jsonb,
  p_client_request_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request_id uuid;
begin
  if not has_hotel_access(p_hotel_id) then
    raise exception 'Access denied';
  end if;
  if coalesce(
    current_user_role() in ('hotel_manager', 'app_admin', 'app_manager'),
    false
  ) = false then
    raise exception 'Only managers can request structural edits';
  end if;
  if p_target_table not in ('hotels', 'floors', 'rooms', 'room_products') then
    raise exception 'Unsupported target table';
  end if;

  if p_client_request_id is not null then
    select id into v_request_id
    from approval_requests
    where client_request_id = p_client_request_id
      and hotel_id = p_hotel_id;

    if found then
      return v_request_id;
    end if;
  end if;

  insert into approval_requests (
    hotel_id,
    title,
    target_table,
    target_id,
    action,
    old_data,
    new_data,
    requested_by,
    client_request_id
  )
  values (
    p_hotel_id,
    p_title,
    p_target_table,
    p_target_id,
    p_action,
    coalesce(p_old_data, '{}'::jsonb),
    coalesce(p_new_data, '{}'::jsonb),
    auth.uid(),
    p_client_request_id
  )
  returning id into v_request_id;

  insert into alerts (hotel_id, alert_type, severity, title, body)
  values (p_hotel_id, 'pending_approval', 1, 'Pending hotel edit', p_title);

  return v_request_id;
end;
$$;

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

create or replace function get_team_invitation_by_token(p_token text)
returns table (
  id uuid,
  hotel_id uuid,
  hotel_name text,
  email text,
  full_name text,
  role user_role,
  status text,
  invite_token text,
  created_at timestamptz,
  accepted_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ui.id,
    ui.hotel_id,
    h.name as hotel_name,
    ui.email,
    ui.full_name,
    ui.role,
    ui.status,
    ui.invite_token,
    ui.created_at,
    ui.accepted_at
  from user_invitations ui
  left join hotels h on h.id = ui.hotel_id
  where ui.invite_token = p_token
    and ui.status = 'pending'
  limit 1
$$;

create or replace function update_current_profile(p_full_name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_full_name text := nullif(btrim(p_full_name), '');
  v_profile profiles%rowtype;
begin
  if v_user_id is null then
    raise exception 'Sign in before updating your profile';
  end if;

  if v_full_name is null then
    raise exception 'Full name is required';
  end if;

  select * into v_profile
  from profiles
  where id = v_user_id
  for update;

  if not found then
    raise exception 'Profile not found';
  end if;

  update profiles
  set full_name = v_full_name
  where id = v_user_id;

  insert into audit_log (
    actor_id,
    hotel_id,
    entity_table,
    entity_id,
    action,
    old_data,
    new_data
  )
  values (
    v_user_id,
    v_profile.hotel_id,
    'profiles',
    v_user_id,
    'profile_updated',
    jsonb_build_object('full_name', v_profile.full_name),
    jsonb_build_object('full_name', v_full_name)
  );
end;
$$;

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

  select * into v_invitation
  from user_invitations
  where invite_token = p_token and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending invitation not found';
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

create or replace function cancel_team_invitation(p_invitation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invitation user_invitations%rowtype;
begin
  select * into v_invitation
  from user_invitations
  where id = p_invitation_id and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending invitation not found';
  end if;

  if current_user_role() = 'hotel_manager' then
    if v_invitation.role <> 'hotel_staff'
        or v_invitation.hotel_id is distinct from current_user_hotel_id() then
      raise exception 'Hotel managers can only cancel staff invitations for their own hotel';
    end if;
  elsif current_user_role() = 'app_manager' then
    if v_invitation.role in ('app_admin', 'app_manager') then
      raise exception 'Only app admins can cancel Ivra admin invitations';
    end if;
  elsif current_user_role() is distinct from 'app_admin' then
    raise exception 'Access denied';
  end if;

  update user_invitations
  set status = 'cancelled'
  where id = p_invitation_id;

  insert into audit_log (actor_id, hotel_id, entity_table, entity_id, action, old_data, new_data)
  values (
    auth.uid(),
    v_invitation.hotel_id,
    'user_invitations',
    p_invitation_id,
    'team_invitation_cancelled',
    jsonb_build_object('status', v_invitation.status),
    jsonb_build_object('status', 'cancelled')
  );
end;
$$;

create or replace function resend_team_invitation(p_invitation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invitation user_invitations%rowtype;
begin
  select * into v_invitation
  from user_invitations
  where id = p_invitation_id and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending invitation not found';
  end if;

  if current_user_role() = 'hotel_manager' then
    if v_invitation.role <> 'hotel_staff'
        or v_invitation.hotel_id is distinct from current_user_hotel_id() then
      raise exception 'Hotel managers can only resend staff invitations for their own hotel';
    end if;
  elsif current_user_role() = 'app_manager' then
    if v_invitation.role in ('app_admin', 'app_manager') then
      raise exception 'Only app admins can resend Ivra admin invitations';
    end if;
  elsif current_user_role() is distinct from 'app_admin' then
    raise exception 'Access denied';
  end if;

  update user_invitations
  set created_at = now()
  where id = p_invitation_id;

  insert into audit_log (actor_id, hotel_id, entity_table, entity_id, action, new_data)
  values (
    auth.uid(),
    v_invitation.hotel_id,
    'user_invitations',
    p_invitation_id,
    'team_invitation_resent',
    jsonb_build_object('email', v_invitation.email)
  );
end;
$$;

create or replace function set_team_member_active(
  p_user_id uuid,
  p_is_active boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile profiles%rowtype;
begin
  if p_user_id = auth.uid() then
    raise exception 'Users cannot deactivate their own account';
  end if;

  select * into v_profile
  from profiles
  where id = p_user_id
  for update;

  if not found then
    raise exception 'Team member not found';
  end if;

  if current_user_role() = 'hotel_manager' then
    if v_profile.role <> 'hotel_staff'
        or v_profile.hotel_id is distinct from current_user_hotel_id() then
      raise exception 'Hotel managers can only manage staff in their own hotel';
    end if;
  elsif current_user_role() = 'app_manager' then
    if v_profile.role in ('app_admin', 'app_manager') then
      raise exception 'Only app admins can manage Ivra admin accounts';
    end if;
  elsif current_user_role() is distinct from 'app_admin' then
    raise exception 'Access denied';
  end if;

  update profiles
  set is_active = p_is_active
  where id = p_user_id;

  insert into audit_log (actor_id, hotel_id, entity_table, entity_id, action, old_data, new_data)
  values (
    auth.uid(),
    v_profile.hotel_id,
    'profiles',
    p_user_id,
    case when p_is_active then 'team_member_reactivated' else 'team_member_deactivated' end,
    jsonb_build_object('is_active', v_profile.is_active),
    jsonb_build_object('is_active', p_is_active)
  );
end;
$$;

create or replace function record_stock_adjustment(
  p_hotel_id uuid,
  p_product_id uuid,
  p_full_bottles_delta int default 0,
  p_empty_bottles_delta int default 0,
  p_full_bidons_delta int default 0,
  p_open_bidons_delta int default 0,
  p_empty_bidons_delta int default 0,
  p_reason text default '',
  p_client_request_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_id uuid;
begin
  if not has_hotel_access(p_hotel_id) then
    raise exception 'Access denied';
  end if;

  if p_client_request_id is not null then
    select id into v_event_id
    from inventory_events
    where client_request_id = p_client_request_id
      and hotel_id = p_hotel_id;

    if found then
      return v_event_id;
    end if;
  end if;

  insert into hotel_inventory (hotel_id, product_id)
  values (p_hotel_id, p_product_id)
  on conflict (hotel_id, product_id) do nothing;

  update hotel_inventory
  set full_bottles = full_bottles + p_full_bottles_delta,
      empty_bottles = empty_bottles + p_empty_bottles_delta,
      full_bidons = full_bidons + p_full_bidons_delta,
      open_bidons = open_bidons + p_open_bidons_delta,
      empty_bidons = empty_bidons + p_empty_bidons_delta,
      updated_at = now()
  where hotel_id = p_hotel_id and product_id = p_product_id;

  if exists (
    select 1 from hotel_inventory
    where hotel_id = p_hotel_id
      and product_id = p_product_id
      and (full_bottles < 0 or empty_bottles < 0 or full_bidons < 0 or open_bidons < 0 or empty_bidons < 0)
  ) then
    raise exception 'Inventory cannot become negative';
  end if;

  insert into inventory_events (
    hotel_id,
    product_id,
    full_bottles_delta,
    empty_bottles_delta,
    full_bidons_delta,
    open_bidons_delta,
    empty_bidons_delta,
    reason,
    performed_by,
    client_request_id
  )
  values (
    p_hotel_id,
    p_product_id,
    p_full_bottles_delta,
    p_empty_bottles_delta,
    p_full_bidons_delta,
    p_open_bidons_delta,
    p_empty_bidons_delta,
    p_reason,
    auth.uid(),
    p_client_request_id
  )
  returning id into v_event_id;

  return v_event_id;
end;
$$;

create or replace function create_rooms_from_template(
  p_hotel_id uuid,
  p_floor_number int,
  p_first_room_number int,
  p_room_count int,
  p_product_ids uuid[]
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_floor_id uuid;
  v_room_id uuid;
  v_room_number text;
  v_created_count int := 0;
  v_product_id uuid;
begin
  if not is_ivra_admin() then
    raise exception 'Only Ivra admins and managers can create rooms directly';
  end if;
  if p_room_count <= 0 or p_room_count > 500 then
    raise exception 'Room count must be between 1 and 500';
  end if;
  if array_length(p_product_ids, 1) is null or array_length(p_product_ids, 1) = 0 then
    raise exception 'At least one product is required';
  end if;

  insert into floors (hotel_id, floor_number, name)
  values (p_hotel_id, p_floor_number, 'Floor ' || p_floor_number)
  on conflict (hotel_id, floor_number)
  do update set name = excluded.name
  returning id into v_floor_id;

  for v_created_count in 0..(p_room_count - 1) loop
    v_room_number := (p_first_room_number + v_created_count)::text;

    insert into rooms (hotel_id, floor_id, room_number)
    values (p_hotel_id, v_floor_id, v_room_number)
    on conflict (hotel_id, room_number)
    do update set floor_id = excluded.floor_id
    returning id into v_room_id;

    foreach v_product_id in array p_product_ids loop
      insert into room_products (hotel_id, room_id, product_id)
      values (p_hotel_id, v_room_id, v_product_id)
      on conflict (room_id, product_id) do nothing;
    end loop;
  end loop;

  insert into audit_log (actor_id, hotel_id, entity_table, action, new_data)
  values (
    auth.uid(),
    p_hotel_id,
    'rooms',
    'template_created',
    jsonb_build_object(
      'floor_number', p_floor_number,
      'first_room_number', p_first_room_number,
      'room_count', p_room_count,
      'product_ids', p_product_ids
    )
  );

  return p_room_count;
end;
$$;

create or replace function approve_change_request(
  p_request_id uuid,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request approval_requests%rowtype;
  v_correction correction_requests%rowtype;
  v_refill refill_events%rowtype;
  v_floor_id uuid;
begin
  if not is_ivra_admin() then
    raise exception 'Access denied';
  end if;

  select * into v_request
  from approval_requests
  where id = p_request_id and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending approval request not found';
  end if;

  if v_request.target_table = 'correction_requests' then
    select * into v_correction
    from correction_requests
    where id = v_request.target_id and status = 'pending'
    for update;

    if not found then
      raise exception 'Pending correction request not found';
    end if;

    select * into v_refill
    from refill_events
    where id = v_correction.refill_event_id
    for update;

    update correction_requests
    set status = 'approved',
        reviewed_by = auth.uid(),
        reviewed_at = now(),
        review_notes = p_notes
    where id = v_correction.id;

    update room_products
    set refill_count = v_refill.previous_refill_count,
        status = 'active'
    where id = v_refill.room_product_id;

    insert into refill_events (
      hotel_id,
      room_product_id,
      event_type,
      previous_refill_count,
      new_refill_count,
      performed_by,
      correction_request_id,
      notes
    )
    values (
      v_refill.hotel_id,
      v_refill.room_product_id,
      'correction_approved',
      v_refill.new_refill_count,
      v_refill.previous_refill_count,
      auth.uid(),
      v_correction.id,
      p_notes
    );
  elsif v_request.action <> 'update' then
    raise exception 'Unsupported approval action';
  elsif v_request.target_table = 'hotels' then
    update hotels
    set name = coalesce(v_request.new_data->>'name', name),
        legal_name = coalesce(v_request.new_data->>'legal_name', legal_name),
        contact_name = coalesce(v_request.new_data->>'contact_name', contact_name),
        phone = coalesce(v_request.new_data->>'phone', phone),
        email = coalesce(v_request.new_data->>'email', email),
        address = coalesce(v_request.new_data->>'address', address),
        city = coalesce(v_request.new_data->>'city', city),
        country = coalesce(v_request.new_data->>'country', country),
        notes = coalesce(v_request.new_data->>'notes', notes)
    where id = v_request.target_id and id = v_request.hotel_id;
  elsif v_request.target_table = 'floors' then
    update floors
    set floor_number = coalesce((v_request.new_data->>'floor_number')::int, floor_number),
        name = coalesce(v_request.new_data->>'name', name)
    where id = v_request.target_id and hotel_id = v_request.hotel_id;
  elsif v_request.target_table = 'rooms' then
    if v_request.new_data ? 'floor_number' then
      insert into floors (hotel_id, floor_number, name)
      values (
        v_request.hotel_id,
        (v_request.new_data->>'floor_number')::int,
        concat('Floor ', v_request.new_data->>'floor_number')
      )
      on conflict (hotel_id, floor_number)
      do update set floor_number = excluded.floor_number
      returning id into v_floor_id;
    end if;

    update rooms
    set floor_id = coalesce(v_floor_id, (v_request.new_data->>'floor_id')::uuid, floor_id),
        room_number = coalesce(v_request.new_data->>'room_number', room_number),
        room_label = coalesce(v_request.new_data->>'room_label', room_label),
        is_active = coalesce((v_request.new_data->>'is_active')::boolean, is_active)
    where id = v_request.target_id and hotel_id = v_request.hotel_id;
  elsif v_request.target_table = 'room_products' then
    update room_products
    set product_id = coalesce((v_request.new_data->>'product_id')::uuid, product_id),
        bottle_started_at = coalesce((v_request.new_data->>'bottle_started_at')::date, bottle_started_at),
        status = coalesce((v_request.new_data->>'status')::bottle_status, status),
        is_active = coalesce((v_request.new_data->>'is_active')::boolean, is_active)
    where id = v_request.target_id and hotel_id = v_request.hotel_id;
  else
    raise exception 'Unsupported target table';
  end if;

  update approval_requests
  set status = 'approved',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      review_notes = p_notes
  where id = p_request_id;

  update alerts
  set is_resolved = true,
      resolved_at = now(),
      resolved_by = auth.uid()
  where hotel_id = v_request.hotel_id
    and alert_type = 'pending_approval'
    and not is_resolved
    and (
      body = v_request.title
      or title = 'Pending approval: ' || v_request.title
    );

  insert into audit_log (actor_id, hotel_id, entity_table, entity_id, action, new_data)
  values (
    auth.uid(),
    v_request.hotel_id,
    v_request.target_table,
    v_request.target_id,
    'approval_approved',
    v_request.new_data
  );
end;
$$;

create or replace function reject_change_request(
  p_request_id uuid,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request approval_requests%rowtype;
  v_correction correction_requests%rowtype;
  v_refill refill_events%rowtype;
begin
  if not is_ivra_admin() then
    raise exception 'Access denied';
  end if;

  select * into v_request
  from approval_requests
  where id = p_request_id and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending approval request not found';
  end if;

  if v_request.target_table = 'correction_requests' then
    select * into v_correction
    from correction_requests
    where id = v_request.target_id and status = 'pending'
    for update;

    if found then
      select * into v_refill
      from refill_events
      where id = v_correction.refill_event_id;

      update correction_requests
      set status = 'rejected',
          reviewed_by = auth.uid(),
          reviewed_at = now(),
          review_notes = p_notes
      where id = v_correction.id;

      insert into refill_events (
        hotel_id,
        room_product_id,
        event_type,
        previous_refill_count,
        new_refill_count,
        performed_by,
        correction_request_id,
        notes
      )
      values (
        v_refill.hotel_id,
        v_refill.room_product_id,
        'correction_rejected',
        v_refill.previous_refill_count,
        v_refill.new_refill_count,
        auth.uid(),
        v_correction.id,
        p_notes
      );
    end if;
  end if;

  update approval_requests
  set status = 'rejected',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      review_notes = p_notes
  where id = p_request_id;

  update alerts
  set is_resolved = true,
      resolved_at = now(),
      resolved_by = auth.uid()
  where hotel_id = v_request.hotel_id
    and alert_type = 'pending_approval'
    and not is_resolved
    and (
      body = v_request.title
      or title = 'Pending approval: ' || v_request.title
    );

  insert into audit_log (actor_id, hotel_id, entity_table, entity_id, action, old_data, new_data)
  values (
    auth.uid(),
    v_request.hotel_id,
    v_request.target_table,
    v_request.target_id,
    'approval_rejected',
    v_request.old_data,
    v_request.new_data
  );
end;
$$;

create or replace function resolve_alert(p_alert_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_alert alerts%rowtype;
begin
  select * into v_alert
  from alerts
  where id = p_alert_id
  for update;

  if not found then
    raise exception 'Alert not found';
  end if;

  if v_alert.hotel_id is null then
    if not is_ivra_admin() then
      raise exception 'Access denied';
    end if;
  elsif not has_hotel_access(v_alert.hotel_id) then
    raise exception 'Access denied';
  end if;

  update alerts
  set is_resolved = true,
      resolved_at = now(),
      resolved_by = auth.uid()
  where id = p_alert_id;

  insert into audit_log (actor_id, hotel_id, entity_table, entity_id, action, old_data, new_data)
  values (
    auth.uid(),
    v_alert.hotel_id,
    'alerts',
    p_alert_id,
    'alert_resolved',
    jsonb_build_object('is_resolved', v_alert.is_resolved),
    jsonb_build_object('is_resolved', true)
  );
end;
$$;

create or replace function refresh_smart_alerts(
  p_hotel_id uuid default null,
  p_bypass_access boolean default false
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_created int := 0;
  v_added int := 0;
begin
  if p_hotel_id is not null
      and not p_bypass_access
      and not has_hotel_access(p_hotel_id) then
    raise exception 'Access denied';
  end if;

  insert into alerts (hotel_id, product_id, alert_type, severity, title, body)
  select
    hi.hotel_id,
    hi.product_id,
    'low_bottle_stock',
    2,
    'Low ' || lower(p.default_name) || ' bottle stock',
    h.name || ' has ' || hi.full_bottles || ' full bottles remaining. Threshold is ' || p.low_bottle_threshold || '.'
  from hotel_inventory hi
  join products p on p.id = hi.product_id
  join hotels h on h.id = hi.hotel_id
  where (p_hotel_id is null or hi.hotel_id = p_hotel_id)
    and (p_bypass_access or has_hotel_access(hi.hotel_id))
    and hi.full_bottles <= p.low_bottle_threshold
    and not exists (
      select 1
      from alerts a
      where not a.is_resolved
        and a.hotel_id = hi.hotel_id
        and a.product_id = hi.product_id
        and a.room_product_id is null
        and a.alert_type = 'low_bottle_stock'
    );
  get diagnostics v_added = row_count;
  v_created := v_created + v_added;

  insert into alerts (hotel_id, product_id, alert_type, severity, title, body)
  select
    hi.hotel_id,
    hi.product_id,
    'low_bidon_stock',
    2,
    'Low ' || lower(p.default_name) || ' bidon stock',
    h.name || ' has ' || hi.full_bidons || ' full bidons remaining. Threshold is ' || p.low_bidon_threshold || '.'
  from hotel_inventory hi
  join products p on p.id = hi.product_id
  join hotels h on h.id = hi.hotel_id
  where (p_hotel_id is null or hi.hotel_id = p_hotel_id)
    and (p_bypass_access or has_hotel_access(hi.hotel_id))
    and hi.full_bidons <= p.low_bidon_threshold
    and not exists (
      select 1
      from alerts a
      where not a.is_resolved
        and a.hotel_id = hi.hotel_id
        and a.product_id = hi.product_id
        and a.room_product_id is null
        and a.alert_type = 'low_bidon_stock'
    );
  get diagnostics v_added = row_count;
  v_created := v_created + v_added;

  insert into alerts (hotel_id, room_product_id, product_id, alert_type, severity, title, body)
  select
    rp.hotel_id,
    rp.id,
    rp.product_id,
    'refill_limit',
    3,
    'Room ' || r.room_number || ' ' || p.default_name || ' reached refill limit',
    rp.refill_count || '/' || p.max_refill_count || ' refills used. Replace and recycle the bottle.'
  from room_products rp
  join products p on p.id = rp.product_id
  join rooms r on r.id = rp.room_id
  where (p_hotel_id is null or rp.hotel_id = p_hotel_id)
    and (p_bypass_access or has_hotel_access(rp.hotel_id))
    and (
      rp.refill_count >= p.max_refill_count
      or rp.status in ('refill_limit_reached', 'needs_replacement')
    )
    and not exists (
      select 1
      from alerts a
      where not a.is_resolved
        and a.hotel_id = rp.hotel_id
        and a.product_id = rp.product_id
        and a.room_product_id = rp.id
        and a.alert_type = 'refill_limit'
    );
  get diagnostics v_added = row_count;
  v_created := v_created + v_added;

  insert into alerts (hotel_id, room_product_id, product_id, alert_type, severity, title, body)
  select
    rp.hotel_id,
    rp.id,
    rp.product_id,
    'bottle_age_limit',
    3,
    'Room ' || r.room_number || ' ' || p.default_name || ' bottle is too old',
    'Bottle age is ' || (current_date - rp.bottle_started_at) || ' days. Limit is ' || p.max_bottle_age_days || ' days.'
  from room_products rp
  join products p on p.id = rp.product_id
  join rooms r on r.id = rp.room_id
  where (p_hotel_id is null or rp.hotel_id = p_hotel_id)
    and (p_bypass_access or has_hotel_access(rp.hotel_id))
    and current_date - rp.bottle_started_at >= p.max_bottle_age_days
    and not exists (
      select 1
      from alerts a
      where not a.is_resolved
        and a.hotel_id = rp.hotel_id
        and a.product_id = rp.product_id
        and a.room_product_id = rp.id
        and a.alert_type = 'bottle_age_limit'
    );
  get diagnostics v_added = row_count;
  v_created := v_created + v_added;

  insert into alerts (hotel_id, alert_type, severity, title, body)
  select
    ar.hotel_id,
    'pending_approval',
    1,
    'Pending approval: ' || ar.title,
    'Requested by ' || coalesce(p.full_name, 'Unknown') || '.'
  from approval_requests ar
  left join profiles p on p.id = ar.requested_by
  where ar.status = 'pending'
    and ar.hotel_id is not null
    and (p_hotel_id is null or ar.hotel_id = p_hotel_id)
    and (p_bypass_access or has_hotel_access(ar.hotel_id))
    and not exists (
      select 1
      from alerts a
      where not a.is_resolved
        and a.hotel_id = ar.hotel_id
        and a.alert_type = 'pending_approval'
        and a.title = 'Pending approval: ' || ar.title
    );
  get diagnostics v_added = row_count;
  v_created := v_created + v_added;

  return v_created;
end;
$$;

create or replace function run_scheduled_smart_alerts()
returns int
language sql
security definer
set search_path = public
as $$
  select refresh_smart_alerts(null, true)
$$;

do $$
begin
  begin
    create extension if not exists pg_cron;
  exception
    when insufficient_privilege or undefined_file then
      raise notice 'pg_cron is unavailable; create the ivra-refresh-smart-alerts job manually.';
  end;

  if to_regnamespace('cron') is not null then
    if exists (
      select 1
      from cron.job
      where jobname = 'ivra-refresh-smart-alerts'
    ) then
      perform cron.unschedule('ivra-refresh-smart-alerts');
    end if;

    perform cron.schedule(
      'ivra-refresh-smart-alerts',
      '*/30 * * * *',
      $job$select public.run_scheduled_smart_alerts();$job$
    );
  end if;
end $$;

create or replace view hotel_summaries
with (security_invoker = true) as
select
  h.*,
  count(distinct r.id)::int as room_count,
  count(ar.id) filter (where ar.status = 'pending')::int as pending_edits
from hotels h
left join rooms r on r.hotel_id = h.id
left join approval_requests ar on ar.hotel_id = h.id
group by h.id;

create or replace view team_invitation_summaries
with (security_invoker = true) as
select
  ui.id,
  ui.hotel_id,
  h.name as hotel_name,
  ui.email,
  ui.full_name,
  ui.role,
  ui.status,
  ui.invite_token,
  ui.invited_by,
  ui.created_at,
  ui.accepted_at
from user_invitations ui
left join hotels h on h.id = ui.hotel_id;

create or replace view room_summaries
with (security_invoker = true) as
select
  r.id,
  r.hotel_id,
  r.floor_id,
  r.room_number,
  f.floor_number,
  count(rp.id)::int as product_count
from rooms r
join floors f on f.id = r.floor_id
left join room_products rp on rp.room_id = r.id and rp.is_active
group by r.id, f.floor_number;

create or replace view room_product_summaries
with (security_invoker = true) as
select
  rp.id,
  rp.hotel_id,
  rp.room_id,
  r.room_number,
  f.floor_number,
  rp.product_id,
  p.sku,
  p.default_name,
  p.name_en,
  p.name_fr,
  p.name_ar,
  p.bottle_volume_ml,
  p.bidon_volume_ml,
  p.max_refill_count,
  p.max_bottle_age_days,
  p.low_bottle_threshold,
  p.low_bidon_threshold,
  rp.bottle_started_at,
  rp.refill_count,
  rp.last_refill_at,
  rp.status
from room_products rp
join rooms r on r.id = rp.room_id
join floors f on f.id = r.floor_id
join products p on p.id = rp.product_id;

create or replace view inventory_summaries
with (security_invoker = true) as
select
  hi.id,
  hi.hotel_id,
  hi.product_id,
  p.sku,
  p.default_name as product_name,
  p.default_name,
  p.name_en,
  p.name_fr,
  p.name_ar,
  p.bottle_volume_ml,
  p.bidon_volume_ml,
  p.max_refill_count,
  p.max_bottle_age_days,
  p.low_bottle_threshold,
  p.low_bidon_threshold,
  hi.full_bottles,
  hi.empty_bottles,
  hi.full_bidons,
  hi.open_bidons,
  hi.empty_bidons
from hotel_inventory hi
join products p on p.id = hi.product_id;

create or replace view suggested_order_quantities
with (security_invoker = true) as
select
  hi.hotel_id,
  hi.product_id,
  p.sku,
  p.default_name as product_name,
  p.default_name,
  p.name_en,
  p.name_fr,
  p.name_ar,
  p.bottle_volume_ml,
  p.bidon_volume_ml,
  p.max_refill_count,
  p.max_bottle_age_days,
  p.low_bottle_threshold,
  p.low_bidon_threshold,
  greatest(p.low_bottle_threshold * 2 - hi.full_bottles, 0)::int as bottles_to_order,
  greatest(p.low_bidon_threshold * 2 - hi.full_bidons, 0)::int as bidons_to_order,
  count(rp.id) filter (
    where rp.status in ('refill_limit_reached', 'too_old', 'needs_replacement')
  )::int as bottles_to_recycle
from hotel_inventory hi
join products p on p.id = hi.product_id
left join room_products rp on rp.hotel_id = hi.hotel_id and rp.product_id = hi.product_id
group by hi.hotel_id, hi.product_id, p.id, hi.full_bottles, hi.full_bidons;

create or replace view approval_request_summaries
with (security_invoker = true) as
select
  ar.id,
  ar.hotel_id,
  ar.title,
  ar.target_id,
  ar.target_table,
  ar.status,
  p.full_name as requested_by_name,
  ar.requested_at,
  ar.old_data,
  ar.new_data,
  ar.old_data::text as old_value,
  ar.new_data::text as new_value
from approval_requests ar
join profiles p on p.id = ar.requested_by;

create or replace function dashboard_metrics()
returns table (
  hotel_count int,
  room_count int,
  pending_approvals int,
  open_alerts int,
  bottles_to_replace int,
  low_stock_products int
)
language sql
stable
security definer
set search_path = public
as $$
  select
    (select count(*)::int from hotels h where has_hotel_access(h.id)),
    (select count(*)::int from rooms r where has_hotel_access(r.hotel_id)),
    (select count(*)::int from approval_requests ar where ar.status = 'pending' and (is_ivra_admin() or has_hotel_access(ar.hotel_id))),
    (select count(*)::int from alerts a where not a.is_resolved and (a.hotel_id is null or has_hotel_access(a.hotel_id))),
    (select count(*)::int from room_products rp where rp.status in ('refill_limit_reached', 'too_old', 'needs_replacement') and has_hotel_access(rp.hotel_id)),
    (select count(*)::int from hotel_inventory hi join products p on p.id = hi.product_id where has_hotel_access(hi.hotel_id) and (hi.full_bottles <= p.low_bottle_threshold or hi.full_bidons <= p.low_bidon_threshold))
$$;

insert into products (
  sku,
  default_name,
  name_en,
  name_fr,
  name_ar,
  max_refill_count,
  max_bottle_age_days,
  low_bottle_threshold,
  low_bidon_threshold
)
values
  ('IVR-SHA-1L', 'Shampoo', 'Shampoo', 'Shampooing', 'شامبو', 10, 240, 12, 4),
  ('IVR-CON-1L', 'Conditioner', 'Conditioner', 'Apres-shampooing', 'بلسم', 10, 240, 12, 4),
  ('IVR-GEL-1L', 'Shower Gel', 'Shower Gel', 'Gel douche', 'جل الاستحمام', 10, 240, 12, 4),
  ('IVR-HWA-1L', 'Hand Wash', 'Hand Wash', 'Savon mains', 'غسول اليدين', 10, 240, 12, 4),
  ('IVR-LOT-1L', 'Hand and Body Lotion', 'Hand and Body Lotion', 'Lait mains et corps', 'لوشن اليد والجسم', 10, 240, 12, 4)
on conflict (sku) do nothing;
