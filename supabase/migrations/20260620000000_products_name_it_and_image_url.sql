-- Adds the columns the Flutter client already writes when creating/updating
-- products:
--   * name_it   - Italian product name
--   * image_url - public URL of the uploaded product image
--
-- Without these columns, PostgREST rejects the insert/update payload with
-- HTTP 400 ("Could not find the 'name_it' column ... in the schema cache"),
-- which breaks product creation and the create_rooms_from_template flow.

alter table products
  add column if not exists name_it text not null default '';

alter table products
  add column if not exists image_url text;

-- Backfill Italian names for existing rows so the catalog renders a sensible
-- value instead of an empty string in the Italian locale.
update products
set name_it = name_en
where name_it = '';
