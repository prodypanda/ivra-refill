# Contributing To Ivra Refill

This project is a Flutter Android + web app backed by Supabase/Postgres.

## Local Setup

Use the stable working copy on a local disk when Flutter has trouble writing to external drives. On this machine, `C:\tmp\ivra_refill` has been used for builds while `H:\pulire app` is the shared workspace.

Run in demo mode:

```powershell
flutter pub get
.\scripts\run_web.ps1 -Demo
```

Run against Supabase:

```powershell
Copy-Item .env.example .env
# Edit .env with SUPABASE_URL and SUPABASE_ANON_KEY.
.\scripts\run_web.ps1
```

## Verification

Before opening a pull request, run:

```powershell
.\scripts\verify_local.ps1
```

For Android-related changes, also run:

```powershell
.\scripts\verify_local.ps1 -BuildAndroid
```

If you changed generated icons or splash assets:

```powershell
.\scripts\generate_web_icons.ps1
.\scripts\generate_android_icons.ps1
```

If you are preparing a signed release build, use:

```powershell
.\scripts\setup_android_signing.ps1
```

## Supabase Changes

When changing Supabase schema, RLS policies, or RPCs:

- Update `supabase/migrations/0001_initial_schema.sql`.
- Update affected repository methods in `lib/src/data/supabase_ivra_repository.dart`.
- Update `supabase/rls_verification.sql` when access rules change.
- Update `docs/04-supabase-deployment-runbook.md` if deployment steps change.
- Run `.\scripts\deploy_supabase.ps1 -DryRun` when deployment commands change.
- Run `.\scripts\render_supabase_sql.ps1` when SQL templates or placeholders change.
- Add or update tests for matching demo repository behavior.

## UI Changes

Keep the app operational and task-focused:

- Prefer dense, clear workflow screens over marketing-style layouts.
- Keep mobile and desktop layouts usable.
- Confirm Arabic RTL after navigation or layout changes.
- Avoid adding visible instructional copy unless it helps complete a real task.

## Security

Follow `SECURITY.md`.

Never commit:

- `.env`
- Supabase service-role keys
- Android keystores
- `android/key.properties`
