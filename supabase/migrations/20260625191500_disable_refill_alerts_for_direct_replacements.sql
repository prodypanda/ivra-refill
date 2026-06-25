-- Migration: Disable refill limit alerts for direct replacement products since they are one-time use.

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

  -- 1. Low Bottle Stock Alerts
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

  -- 2. Low Bidon Stock Alerts
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

  -- 3. Refill Limit Alerts (only for refillable products)
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
    and p.refill_type = 'refillable'
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

  -- 4. Bottle Age Limit Alerts
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

  -- 5. Pending Approval Alerts
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
