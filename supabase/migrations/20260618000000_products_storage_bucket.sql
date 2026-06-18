-- Provision the `products` storage bucket server-side.
--
-- The Flutter app previously tried to `createBucket('products', ...)` from the
-- client as a fallback when an image upload failed. That is fragile (the anon /
-- authenticated role generally lacks bucket-admin rights) and silently produced
-- broken public URLs. The bucket must instead be provisioned here, with RLS
-- storage policies that mirror the `products_write_ivra` table policy:
--   * public read for everyone (product images are shown in the catalog), and
--   * write/update/delete restricted to Ivra admins/managers
--     (`app_admin` / `app_manager`).

-- Create (or keep) a public bucket named `products`.
insert into storage.buckets (id, name, public)
values ('products', 'products', true)
on conflict (id) do update set public = true;

-- Public read: anyone may read objects in the `products` bucket.
drop policy if exists "products_bucket_public_read" on storage.objects;
create policy "products_bucket_public_read" on storage.objects
  for select
  using (bucket_id = 'products');

-- Write (insert): only Ivra admins/managers, matching products_write_ivra.
drop policy if exists "products_bucket_write_ivra" on storage.objects;
create policy "products_bucket_write_ivra" on storage.objects
  for insert
  with check (bucket_id = 'products' and public.is_ivra_admin());

-- Update: only Ivra admins/managers.
drop policy if exists "products_bucket_update_ivra" on storage.objects;
create policy "products_bucket_update_ivra" on storage.objects
  for update
  using (bucket_id = 'products' and public.is_ivra_admin())
  with check (bucket_id = 'products' and public.is_ivra_admin());

-- Delete: only Ivra admins/managers.
drop policy if exists "products_bucket_delete_ivra" on storage.objects;
create policy "products_bucket_delete_ivra" on storage.objects
  for delete
  using (bucket_id = 'products' and public.is_ivra_admin());
