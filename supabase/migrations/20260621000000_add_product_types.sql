-- Add product types columns to products table
alter table products
  add column if not exists bottle_type text not null default 'with_pump'
    check (bottle_type in ('with_pump', 'without_pump')),
  add column if not exists refill_type text not null default 'refillable'
    check (refill_type in ('refillable', 'direct_replacement'));

-- Update room_product_summaries view to include new columns
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
  p.name_it,
  p.bottle_volume_ml,
  p.bidon_volume_ml,
  p.max_refill_count,
  p.max_bottle_age_days,
  p.low_bottle_threshold,
  p.low_bidon_threshold,
  p.image_url,
  p.bottle_type,
  p.refill_type,
  rp.bottle_started_at,
  rp.refill_count,
  rp.last_refill_at,
  rp.status
from room_products rp
join rooms r on r.id = rp.room_id
join floors f on f.id = r.floor_id
join products p on p.id = rp.product_id;

-- Update inventory_summaries view to include new columns
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
  p.name_it,
  p.bottle_volume_ml,
  p.bidon_volume_ml,
  p.max_refill_count,
  p.max_bottle_age_days,
  p.low_bottle_threshold,
  p.low_bidon_threshold,
  p.image_url,
  p.bottle_type,
  p.refill_type,
  hi.full_bottles,
  hi.empty_bottles,
  hi.full_bidons,
  hi.open_bidons,
  hi.empty_bidons
from hotel_inventory hi
join products p on p.id = hi.product_id;

-- Update suggested_order_quantities view to include new columns and conditional order logic
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
  p.name_it,
  p.bottle_volume_ml,
  p.bidon_volume_ml,
  p.max_refill_count,
  p.max_bottle_age_days,
  p.low_bottle_threshold,
  p.low_bidon_threshold,
  p.image_url,
  p.bottle_type,
  p.refill_type,
  greatest(p.low_bottle_threshold * 2 - hi.full_bottles, 0)::int as bottles_to_order,
  (case when p.refill_type = 'refillable' then greatest(p.low_bidon_threshold * 2 - hi.full_bidons, 0)::int else 0 end) as bidons_to_order,
  count(rp.id) filter (
    where rp.status in ('refill_limit_reached', 'too_old', 'needs_replacement')
  )::int as bottles_to_recycle
from hotel_inventory hi
join products p on p.id = hi.product_id
left join room_products rp on rp.hotel_id = hi.hotel_id and rp.product_id = hi.product_id
group by hi.hotel_id, hi.product_id, p.id, hi.full_bottles, hi.full_bidons;
