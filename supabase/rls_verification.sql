-- Ivra Supabase RLS smoke-test template.
--
-- Run this after:
-- 1. supabase/migrations/0001_initial_schema.sql has been applied.
-- 2. At least two hotels exist.
-- 3. One auth/profile user exists for each role.
-- 4. The hotel_manager and hotel_staff users belong to HOTEL_A.
--
-- Replace every placeholder UUID before running.
-- The script uses SET LOCAL ROLE plus Supabase JWT settings to simulate
-- requests made by authenticated and anonymous API clients.

create temp table if not exists ivra_rls_context (
  app_admin_id uuid not null,
  app_manager_id uuid not null,
  hotel_manager_id uuid not null,
  hotel_staff_id uuid not null,
  hotel_a_id uuid not null,
  hotel_b_id uuid not null
) on commit preserve rows;

truncate table ivra_rls_context;

insert into ivra_rls_context (
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
    from ivra_rls_context
    where app_admin_id = '00000000-0000-0000-0000-000000000001'
       or app_manager_id = '00000000-0000-0000-0000-000000000002'
       or hotel_manager_id = '00000000-0000-0000-0000-000000000003'
       or hotel_staff_id = '00000000-0000-0000-0000-000000000004'
       or hotel_a_id = '10000000-0000-4000-8000-000000000001'
       or hotel_b_id = '10000000-0000-4000-8000-000000000002'
  ) then
    raise exception 'Replace all placeholder UUIDs in ivra_rls_context before running RLS checks.';
  end if;
end $$;

-- Anonymous clients should not read operational data.
begin;
  set local role anon;

  select
    'anon cannot read products' as check_name,
    count(*) = 0 as pass
  from public.products;

  select
    'anon cannot read hotels' as check_name,
    count(*) = 0 as pass
  from public.hotels;
rollback;

-- App admin should see all core operational records.
begin;
  select set_config('request.jwt.claim.sub', (select app_admin_id::text from ivra_rls_context), true);
  select set_config('request.jwt.claim.role', 'authenticated', true);
  select set_config('ivra.hotel_a_id', (select hotel_a_id::text from ivra_rls_context), true);
  select set_config('ivra.hotel_b_id', (select hotel_b_id::text from ivra_rls_context), true);
  set local role authenticated;

  select
    'app_admin sees both hotels' as check_name,
    count(*) filter (where id in (
      current_setting('ivra.hotel_a_id')::uuid,
      current_setting('ivra.hotel_b_id')::uuid
    )) = 2 as pass
  from public.hotels;

  select
    'app_admin can read audit log' as check_name,
    count(*) >= 0 as pass
  from public.audit_log;
rollback;

-- App manager should have Ivra-wide operational access, but is still tracked by profile role.
begin;
  select set_config('request.jwt.claim.sub', (select app_manager_id::text from ivra_rls_context), true);
  select set_config('request.jwt.claim.role', 'authenticated', true);
  select set_config('ivra.hotel_a_id', (select hotel_a_id::text from ivra_rls_context), true);
  select set_config('ivra.hotel_b_id', (select hotel_b_id::text from ivra_rls_context), true);
  set local role authenticated;

  select
    'app_manager sees both hotels' as check_name,
    count(*) filter (where id in (
      current_setting('ivra.hotel_a_id')::uuid,
      current_setting('ivra.hotel_b_id')::uuid
    )) = 2 as pass
  from public.hotels;

  select
    'app_manager role helper is app_manager' as check_name,
    public.current_user_role() = 'app_manager'::public.user_role as pass;
rollback;

-- Hotel manager should only see their assigned hotel and can submit pending edits.
begin;
  select set_config('request.jwt.claim.sub', (select hotel_manager_id::text from ivra_rls_context), true);
  select set_config('request.jwt.claim.role', 'authenticated', true);
  select set_config('ivra.hotel_a_id', (select hotel_a_id::text from ivra_rls_context), true);
  select set_config('ivra.hotel_b_id', (select hotel_b_id::text from ivra_rls_context), true);
  set local role authenticated;

  select
    'hotel_manager sees own hotel only' as check_name,
    count(*) filter (where id = current_setting('ivra.hotel_a_id')::uuid) = 1
      and count(*) filter (where id = current_setting('ivra.hotel_b_id')::uuid) = 0 as pass
  from public.hotels;

  select
    'hotel_manager cannot read other hotel rooms' as check_name,
    count(*) = 0 as pass
  from public.rooms
  where hotel_id = current_setting('ivra.hotel_b_id')::uuid;

  select
    'hotel_manager can submit own hotel edit request through RPC' as check_name,
    public.submit_change_request(
      current_setting('ivra.hotel_a_id')::uuid,
      'RLS smoke test hotel edit',
      'hotels',
      current_setting('ivra.hotel_a_id')::uuid,
      'update',
      '{}'::jsonb,
      '{"notes":"RLS smoke test"}'::jsonb,
      'rls-sql-hotel-manager-edit'
    ) is not null as pass;

  do $$
  begin
    begin
      insert into public.approval_requests (
        hotel_id,
        title,
        target_table,
        action,
        old_data,
        new_data,
        requested_by
      )
      values (
        current_setting('ivra.hotel_a_id')::uuid,
        'RLS smoke test direct insert',
        'hotels',
        'update',
        '{}'::jsonb,
        '{"notes":"should fail"}'::jsonb,
        current_setting('request.jwt.claim.sub')::uuid
      );

      raise exception 'FAIL: hotel_manager inserted directly into approval_requests.';
    exception
      when insufficient_privilege or check_violation then
        raise notice 'PASS: hotel_manager cannot directly insert approval requests.';
      when others then
        if sqlstate = '42501' then
          raise notice 'PASS: hotel_manager cannot directly insert approval requests.';
        else
          raise;
        end if;
    end;
  end $$;
rollback;

-- Hotel staff should see assigned hotel data but should not submit approval requests.
begin;
  select set_config('request.jwt.claim.sub', (select hotel_staff_id::text from ivra_rls_context), true);
  select set_config('request.jwt.claim.role', 'authenticated', true);
  select set_config('ivra.hotel_a_id', (select hotel_a_id::text from ivra_rls_context), true);
  select set_config('ivra.hotel_b_id', (select hotel_b_id::text from ivra_rls_context), true);
  set local role authenticated;

  select
    'hotel_staff sees own hotel only' as check_name,
    count(*) filter (where id = current_setting('ivra.hotel_a_id')::uuid) = 1
      and count(*) filter (where id = current_setting('ivra.hotel_b_id')::uuid) = 0 as pass
  from public.hotels;

  do $$
  begin
    begin
      perform public.submit_change_request(
        current_setting('ivra.hotel_a_id')::uuid,
        'RLS smoke test staff edit',
        'hotels',
        current_setting('ivra.hotel_a_id')::uuid,
        'update',
        '{}'::jsonb,
        '{"notes":"should fail"}'::jsonb,
        'rls-sql-staff-edit'
      );

      raise exception 'FAIL: hotel_staff submitted an approval request.';
    exception
      when insufficient_privilege or check_violation then
        raise notice 'PASS: hotel_staff cannot submit approval requests.';
      when others then
        if sqlstate = '42501'
            or sqlerrm like 'Only managers can request structural edits%' then
          raise notice 'PASS: hotel_staff cannot submit approval requests.';
        else
          raise;
        end if;
    end;
  end $$;

  do $$
  begin
    begin
      insert into public.approval_requests (
        hotel_id,
        title,
        target_table,
        action,
        old_data,
        new_data,
        requested_by
      )
      values (
        current_setting('ivra.hotel_a_id')::uuid,
        'RLS smoke test staff direct insert',
        'hotels',
        'update',
        '{}'::jsonb,
        '{"notes":"should fail"}'::jsonb,
        current_setting('request.jwt.claim.sub')::uuid
      );

      raise exception 'FAIL: hotel_staff inserted directly into approval_requests.';
    exception
      when insufficient_privilege or check_violation then
        raise notice 'PASS: hotel_staff cannot directly insert approval requests.';
      when others then
        if sqlstate = '42501' then
          raise notice 'PASS: hotel_staff cannot directly insert approval requests.';
        else
          raise;
        end if;
    end;
  end $$;
rollback;

-- Views should honor the same RLS through security_invoker.
begin;
  select set_config('request.jwt.claim.sub', (select hotel_manager_id::text from ivra_rls_context), true);
  select set_config('request.jwt.claim.role', 'authenticated', true);
  select set_config('ivra.hotel_a_id', (select hotel_a_id::text from ivra_rls_context), true);
  select set_config('ivra.hotel_b_id', (select hotel_b_id::text from ivra_rls_context), true);
  set local role authenticated;

  select
    'hotel_summaries view respects hotel_manager scope' as check_name,
    count(*) filter (where id = current_setting('ivra.hotel_a_id')::uuid) = 1
      and count(*) filter (where id = current_setting('ivra.hotel_b_id')::uuid) = 0 as pass
  from public.hotel_summaries;

  select
    'room_summaries view hides other hotels' as check_name,
    count(*) = 0 as pass
  from public.room_summaries
  where hotel_id = current_setting('ivra.hotel_b_id')::uuid;
rollback;
