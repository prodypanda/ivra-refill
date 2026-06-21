-- Fix `has_hotel_access` to correctly allow `app_manager` by checking `is_ivra_admin()`
CREATE OR REPLACE FUNCTION has_hotel_access(check_hotel_id uuid)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN is_ivra_admin() OR EXISTS (
        SELECT 1 FROM user_hotels
        WHERE user_id = auth.uid() AND hotel_id = check_hotel_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix approve_change_request to allow hotel_managers for their assigned hotels and prevent self-approval
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
  select * into v_request
  from approval_requests
  where id = p_request_id and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending approval request not found';
  end if;

  if not (is_ivra_admin() or (current_user_role() = 'hotel_manager' and has_hotel_access(v_request.hotel_id))) then
    raise exception 'Access denied';
  end if;

  if v_request.requested_by = auth.uid() and not is_app_admin() then
    raise exception 'Cannot approve your own request';
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
    set name = coalesce(v_request.new_data->>'name', name),
        sort_order = coalesce((v_request.new_data->>'sort_order')::int, sort_order)
    where id = v_request.target_id and hotel_id = v_request.hotel_id;
  elsif v_request.target_table = 'rooms' then
    update rooms
    set name = coalesce(v_request.new_data->>'name', name),
        floor_id = coalesce((v_request.new_data->>'floor_id')::uuid, floor_id),
        sort_order = coalesce((v_request.new_data->>'sort_order')::int, sort_order)
    where id = v_request.target_id and hotel_id = v_request.hotel_id;
  else
    raise exception 'Unsupported target table for approval';
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

-- Fix reject_change_request to allow hotel_managers for their assigned hotels and prevent self-rejection
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
  select * into v_request
  from approval_requests
  where id = p_request_id and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending approval request not found';
  end if;

  if not (is_ivra_admin() or (current_user_role() = 'hotel_manager' and has_hotel_access(v_request.hotel_id))) then
    raise exception 'Access denied';
  end if;

  if v_request.requested_by = auth.uid() and not is_app_admin() then
    raise exception 'Cannot reject your own request';
  end if;

  if v_request.target_table = 'correction_requests' then
    select * into v_correction
    from correction_requests
    where id = v_request.target_id and status = 'pending'
    for update;

    if not found then
      raise exception 'Pending correction request not found';
    end if;

    update correction_requests
    set status = 'rejected',
        reviewed_by = auth.uid(),
        reviewed_at = now(),
        review_notes = p_notes
    where id = v_correction.id;

    select * into v_refill
    from refill_events
    where id = v_correction.refill_event_id;

    update room_products
    set status = 'active'
    where id = v_refill.room_product_id;
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

  insert into audit_log (actor_id, hotel_id, entity_table, entity_id, action, new_data)
  values (
    auth.uid(),
    v_request.hotel_id,
    v_request.target_table,
    v_request.target_id,
    'approval_rejected',
    jsonb_build_object('notes', p_notes)
  );
end;
$$;
