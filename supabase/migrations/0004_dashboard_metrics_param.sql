-- Create the updated dashboard_metrics function that accepts p_hotel_id
-- We use "CREATE OR REPLACE FUNCTION" and explicitly declare the parameter.
-- Note: if there is an existing dashboard_metrics() function with no parameters, 
-- this will create an overloaded function. We then drop the old one.

CREATE OR REPLACE FUNCTION dashboard_metrics(p_hotel_id uuid DEFAULT NULL)
RETURNS table (
  hotel_count int,
  room_count int,
  pending_approvals int,
  open_alerts int,
  bottles_to_replace int,
  low_stock_products int
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  select
    (select count(*)::int from hotels h where has_hotel_access(h.id) and (p_hotel_id is null or h.id = p_hotel_id)),
    (select count(*)::int from rooms r where has_hotel_access(r.hotel_id) and (p_hotel_id is null or r.hotel_id = p_hotel_id)),
    (select count(*)::int from approval_requests ar where ar.status = 'pending' and (is_ivra_admin() or has_hotel_access(ar.hotel_id)) and (p_hotel_id is null or ar.hotel_id = p_hotel_id)),
    (select count(*)::int from alerts a where not a.is_resolved and (a.hotel_id is null or has_hotel_access(a.hotel_id)) and (p_hotel_id is null or a.hotel_id = p_hotel_id)),
    (select count(*)::int from room_products rp where rp.status in ('refill_limit_reached', 'too_old', 'needs_replacement') and has_hotel_access(rp.hotel_id) and (p_hotel_id is null or rp.hotel_id = p_hotel_id)),
    (select count(*)::int from hotel_inventory hi join products p on p.id = hi.product_id where has_hotel_access(hi.hotel_id) and (p_hotel_id is null or hi.hotel_id = p_hotel_id) and (hi.full_bottles <= p.low_bottle_threshold or hi.full_bidons <= p.low_bidon_threshold))
$$;

-- Drop the old parameter-less version if it exists
DROP FUNCTION IF EXISTS dashboard_metrics();
