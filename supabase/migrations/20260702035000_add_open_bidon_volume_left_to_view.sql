-- Migration: Add open_bidon_volume_left_ml to inventory_summaries view
-- Recreate inventory_summaries view to include open_bidon_volume_left_ml column from hotel_inventory

DROP VIEW IF EXISTS inventory_summaries;

CREATE OR REPLACE VIEW inventory_summaries
WITH (security_invoker = true) AS
SELECT
  hi.id,
  hi.hotel_id,
  hi.product_id,
  p.sku,
  p.default_name AS product_name,
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
  hi.empty_bidons,
  hi.open_bidon_volume_left_ml
FROM hotel_inventory hi
JOIN products p ON p.id = hi.product_id;
