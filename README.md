# Ivra Refill Operations

## ⚠️ MANDATORY DEVELOPER WORKFLOW (FOR ALL UPDATES)
Any AI developer or coding assistant working on this codebase MUST follow these steps exactly:
1. **Update the App Version**:
   - Every single update/feature MUST bump the version in `pubspec.yaml` (e.g. from `1.0.19+20` to `1.0.20+21`).
   - Run `.\scripts\generate_version.ps1` to update `lib/src/version.dart`.
2. **Commit and Create a Pull Request**:
   - Commit all code changes.
   - Push your branch and create a Pull Request from `resume-unfinished-devin-session` to the `main` branch.
3. **Wait for Code Review**:
   - DO NOT deploy or publish until you receive a review from Devin AI on the pull request.
   - If changes are requested, apply them and update the Pull Request.
4. **Compile Both Web and Android Versions**:
   - Run `flutter build apk --release --tree-shake-icons` (or use the deploy scripts) to compile the Android app.
   - Run the Flutter web build.
5. **Publish the Web Version**:
   - Publish the compiled web build to Firebase Hosting.

---

Flutter Android + web app for Ivra hotel product refill operations, backed by Supabase/Postgres.

## Current Status

This repository contains the V1 implementation foundation:

- Product, hotel, room, refill, inventory, approval, alert, and report domain models.
- Responsive Flutter UI for admin/manager and hotel workflows.
- Demo repository so the app can be explored before Supabase credentials are added.
- Supabase SQL migration with schema, enums, RLS policies, RPCs, seed products, and reporting views.
- Offline queue, exports, team invitations, smart alerts, multilingual UI, and responsive/RTL checks.
- Planning, checklist, acceptance-test, and deployment documents in `docs/`.

Flutter is installed on the current development machine. Run the app in demo mode with:

```powershell
flutter pub get
flutter run -d chrome
```

The Android and web folders have already been generated. If `flutter create` is run again and asks about overwriting files, keep the existing `lib/`, `pubspec.yaml`, `README.md`, `analysis_options.yaml`, `docs/`, and `supabase/` files.

## Windows Helper Scripts

Copy `.env.example` to `.env` and fill in real Supabase values when you are ready to use live data. Without a real `.env`, the scripts run in demo mode.

```powershell
.\scripts\run_web.ps1
.\scripts\build_web.ps1
.\scripts\build_android_debug.ps1
.\scripts\build_android_release.ps1
.\scripts\build_android_bundle.ps1
.\scripts\verify_local.ps1
```

To create `.env` from real Supabase values:

```powershell
.\scripts\setup_supabase_env.ps1
```

To set up Android release signing on a release machine:

```powershell
.\scripts\setup_android_signing.ps1
```

To regenerate the web favicon and PWA icons:

```powershell
.\scripts\generate_web_icons.ps1
```

To regenerate Android launcher icons:

```powershell
.\scripts\generate_android_icons.ps1
```

To force demo mode even when `.env` exists:

```powershell
.\scripts\run_web.ps1 -Demo
```

To include the Android APK build in the full local verification pass:

```powershell
.\scripts\verify_local.ps1 -BuildAndroid
```

Before shipping to real hotels, run the stricter release gate:

```powershell
.\scripts\check_release_readiness.ps1
```

This check intentionally fails until production `.env`, Android release signing, and Supabase checklist items are complete.

To build deployable web and Android release artifacts together after the release gate passes:

```powershell
.\scripts\package_release.ps1
```

Use `-IncludeAppBundle` when preparing a Play Store-style Android app bundle. The packaging script also writes `.generated/release/release-manifest.json` with artifact paths, sizes, hashes, and app version.

To collect the built web zip, Android artifacts, manifest, and checksums into one handoff folder:

```powershell
.\scripts\archive_release_artifacts.ps1 -IncludeAppBundle
```

To run verification, packaging, archiving, and archive checksum verification together:

```powershell
.\scripts\prepare_go_live.ps1 -IncludeAppBundle
```

For a non-production demo package, add `-Demo`. The combined command also writes `.generated/release/go-live-evidence.md`.

## Continuous Integration

The GitHub Actions workflow in `.github/workflows/flutter-ci.yml` runs:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build web`
- `flutter build apk --debug`

See `CONTRIBUTING.md` for local setup, verification, Supabase-change expectations, and PR hygiene.

## Operational Handoff

- `docs/04-supabase-deployment-runbook.md`: live Supabase setup.
- `docs/05-release-checklist.md`: Android/web release checks.
- `docs/06-pilot-onboarding-checklist.md`: first hotel rollout steps.
- `docs/07-data-and-privacy-notes.md`: pilot data handling notes.
- `docs/08-go-live-record.md`: production setup and first pilot sign-off record.
- `SECURITY.md`: security reporting and release-safety guidance.

## Supabase Setup

1. Create a Supabase project.
2. Add `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_PROJECT_REF` to `.env`.
3. Run the deployment helper or paste the migration in the SQL editor:

```powershell
.\scripts\deploy_supabase.ps1 -DryRun
.\scripts\deploy_supabase.ps1
```

4. Run `supabase/migrations/0001_initial_schema.sql` in the SQL editor if you are not using the CLI helper.
5. Create the first `app_admin` profile using `docs/04-supabase-deployment-runbook.md`.
6. Add environment values when running Flutter:

```powershell
flutter run -d chrome --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

When no Supabase values are provided, the app uses demo data.

After creating real role accounts, run `supabase/rls_verification.sql` from the Supabase SQL editor to smoke-test the most important access rules.

To generate filled SQL files from the templates without editing the source templates:

```powershell
.\scripts\render_supabase_sql.ps1 -BootstrapFirstAdmin -AdminUserId "AUTH_USER_ID" -AdminEmail "admin@your-company.com" -AdminFullName "Ivra Admin"
```

Rendered SQL files are written to `.generated/supabase/`, which is ignored by git.

## Main Roles

- `app_admin`: full access and control.
- `app_manager`: hotel/account management, approvals, reports, inventory.
- `hotel_manager`: own hotel operations, team accounts, pending edit requests, refill/correction flow.
- `hotel_staff`: refill and stock actions only.

## Important V1 Decisions

- No QR code tracking.
- No photo proof.
- Reorder flow provides suggested quantities only.
- Alerts are in-app/dashboard alerts.
- Undo is allowed within 30 minutes; later fixes require correction approval.
- English, French, and Arabic are planned, including RTL for Arabic.
