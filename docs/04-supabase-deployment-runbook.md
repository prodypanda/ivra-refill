# Ivra Supabase Deployment Runbook

This runbook covers the remaining production setup steps that need a real Supabase project.

## 1. Create The Supabase Project

- Create a Supabase project for Ivra.
- Copy the project URL and anon key into the app environment:

```powershell
$env:SUPABASE_URL="https://YOUR_PROJECT.supabase.co"
$env:SUPABASE_ANON_KEY="YOUR_ANON_KEY"
$env:SUPABASE_PROJECT_REF="YOUR_PROJECT_REF"
```

Use `.env.example` as the local template for these values.

You can also create `.env` with guided prompts:

```powershell
.\scripts\setup_supabase_env.ps1
```

If you already have the values in your shell environment, the helper can validate them without writing a file:

```powershell
.\scripts\setup_supabase_env.ps1 -DryRun
```

For Flutter web builds, pass them as compile-time values:

```powershell
flutter build web --dart-define=SUPABASE_URL=$env:SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
```

For Android builds:

```powershell
flutter build apk --debug --dart-define=SUPABASE_URL=$env:SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
```

## 2. Apply The Database Migration

Using the Supabase SQL editor, paste and run:

```text
supabase/migrations/0001_initial_schema.sql
```

Or with Supabase CLI:

```powershell
.\scripts\deploy_supabase.ps1 -DryRun
.\scripts\deploy_supabase.ps1 -Login
```

Use `-Login` only when the machine has not already authenticated with Supabase CLI.

### Product images storage bucket

The app stores uploaded product images in a public Supabase Storage bucket named
`products`. This bucket is provisioned server-side by the migration:

```text
supabase/migrations/20260618000000_products_storage_bucket.sql
```

The app no longer creates the bucket from the client. Apply this migration along
with the rest. It creates a public `products` bucket and storage RLS policies that
mirror the `products_write_ivra` table policy:

- public read for everyone (product images render in the catalog), and
- insert/update/delete restricted to Ivra admins/managers (`app_admin` /
  `app_manager`).

If you provision the bucket through the Supabase Storage UI instead of the
migration, create it as **public** and add the same write/update/delete policies
gated on `public.is_ivra_admin()`. Without the bucket, image uploads fail
gracefully and the user is shown a localized error instead of saving a broken
image URL.

## 3. Create The First Admin User

- Create the first user in Supabase Auth.
- Find the user's `auth.users.id`.
- Run `supabase/bootstrap_first_admin.sql` after replacing the placeholder user ID, email, and name. The script inserts or updates their profile as `app_admin` and verifies that the Auth user exists first.
- Or render a filled copy first:

```powershell
.\scripts\render_supabase_sql.ps1 -BootstrapFirstAdmin -AdminUserId "AUTH_USER_ID" -AdminEmail "admin@your-company.com" -AdminFullName "Ivra Admin"
```

Then review and run `.generated/supabase/bootstrap_first_admin.rendered.sql`.

After this, use the app Team screen to invite App Managers, Hotel Managers, and Hotel Staff.

## 4. Verify Role Access

Create one account for each role:

- `app_admin`
- `app_manager`
- `hotel_manager`
- `hotel_staff`

Then verify:

- App Admin can access every hotel, product, approval, alert, report, and team action.
- App Manager can create hotels, manage rooms/products/inventory, approve hotel edits, and view reports.
- Hotel Manager can only access their assigned hotel, submit hotel/room edits for approval, manage hotel team, and record or correct refills.
- Hotel Staff can only record refill and stock actions for their assigned hotel.

## 5. Verify RLS Directly

For each role account, sign in through the app and exercise the main screens. Then test denied cases:

- Hotel Manager cannot view another hotel's rooms.
- Hotel Staff cannot approve requests.
- Hotel Staff cannot invite users.
- App Manager cannot bypass approval history or audit records.
- Anonymous users cannot read operational tables.

You can also run `supabase/rls_verification.sql` in the Supabase SQL editor after replacing the placeholder UUIDs. It checks the main anonymous, admin, manager, hotel-manager, hotel-staff, and reporting-view access rules.

For a quicker smoke-test dataset, create four Supabase Auth users and then run `supabase/seed_rls_demo_data.sql` after replacing the four auth user ID placeholders. It creates two demo hotels, sample rooms/products/inventory, and matching profiles. Copy the output IDs into `supabase/rls_verification.sql`.

You can render filled seed and RLS verification SQL files with:

```powershell
.\scripts\render_supabase_sql.ps1 -SeedRlsDemoData -RlsVerification `
  -AdminUserId "APP_ADMIN_AUTH_ID" `
  -AppManagerUserId "APP_MANAGER_AUTH_ID" `
  -HotelManagerUserId "HOTEL_MANAGER_AUTH_ID" `
  -HotelStaffUserId "HOTEL_STAFF_AUTH_ID" `
  -AdminEmail "admin@your-company.com" `
  -AppManagerEmail "manager@your-company.com" `
  -HotelManagerEmail "hotel-manager@hotel.com" `
  -HotelStaffEmail "staff@hotel.com"
```

If any denied case succeeds, pause release and tighten the related RLS policy before onboarding hotels.

After real role accounts exist, you can also run the REST-level RLS smoke test against the deployed Supabase API:

```powershell
$env:IVRA_APP_ADMIN_PASSWORD="APP_ADMIN_PASSWORD"
$env:IVRA_APP_MANAGER_PASSWORD="APP_MANAGER_PASSWORD"
$env:IVRA_HOTEL_MANAGER_PASSWORD="HOTEL_MANAGER_PASSWORD"
$env:IVRA_HOTEL_STAFF_PASSWORD="HOTEL_STAFF_PASSWORD"
.\scripts\verify_supabase_rls.ps1
```

The helper signs in as each role, verifies profile role data, checks hotel/inventory scoping for hotel users, confirms direct writes to sensitive workflow tables are denied, verifies anonymous data is blocked, and writes `.generated/supabase/rls-rest-verification.md`.

## 6. Release Gate

Only mark Supabase deployment complete after:

- Migration applies without errors.
- First admin profile exists and can sign in.
- All four role accounts pass UI checks.
- RLS denied cases are confirmed.
- Refill, undo, correction request, approval, stock update, alert refresh, and export flows work against Supabase data.
