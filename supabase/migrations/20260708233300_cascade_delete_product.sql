-- Migration to add ON DELETE CASCADE to foreign keys referencing the products table.

ALTER TABLE public.room_products
  DROP CONSTRAINT IF EXISTS room_products_product_id_fkey,
  ADD CONSTRAINT room_products_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

ALTER TABLE public.hotel_inventory
  DROP CONSTRAINT IF EXISTS hotel_inventory_product_id_fkey,
  ADD CONSTRAINT hotel_inventory_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

ALTER TABLE public.inventory_events
  DROP CONSTRAINT IF EXISTS inventory_events_product_id_fkey,
  ADD CONSTRAINT inventory_events_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

ALTER TABLE public.alerts
  DROP CONSTRAINT IF EXISTS alerts_product_id_fkey,
  ADD CONSTRAINT alerts_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;
