# Changelog

## Unreleased
- Updated safe package dependencies: `firebase_core` (4.11.0 -> 4.12.1), `firebase_core_platform_interface` (7.1.0 -> 8.0.0), `firebase_core_web` (3.9.0 -> 3.9.1), `firebase_messaging` (16.4.1 -> 16.4.3), `firebase_messaging_platform_interface` (4.9.0 -> 4.9.2), `firebase_messaging_web` (4.2.1 -> 4.2.3), `flutter_cache_manager` (3.4.1 -> 3.4.2), `google_fonts` (8.1.0 -> 8.2.0), `gotrue` (2.25.0 -> 2.26.0), `local_auth` (3.0.1 -> 3.0.2), `matcher` (0.12.19 -> 0.12.18), `meta` (1.18.0 -> 1.17.0), `mobile_scanner` (7.2.0 -> 7.4.0), `passkeys_platform_interface` (2.8.0 -> 2.9.0), `posix` (6.5.0 -> 6.5.2), `realtime_client` (2.10.0 -> 2.11.0), `supabase` (2.13.4 -> 2.14.0), `supabase_flutter` (2.15.4 -> 2.16.0), `test_api` (0.7.11 -> 0.7.9), `uuid` (4.5.3 -> 4.6.0).

- Fixed an offline sync data-loss race: the workmanager background isolate and
  the UI isolate each cached their own `SharedPreferences` copy, so queued
  refill/undo/correction/stock actions could be silently dropped. The offline
  queue now reloads `SharedPreferences` before every read/write and re-derives
  the list from the reloaded instance.
- Fixed `NotificationService` crashing widget tests and demo/offline mode:
  `notificationServiceProvider` now passes a `null` Supabase client when
  `useSupabaseProvider` is false instead of eagerly reading the uninitialized
  `Supabase.instance.client`.
- Confirmed the previously English-fallback alert toasts
  (`alertResolveFailedToast`, `alertDeleteFailedToast`,
  `notificationAcknowledgedToast`) are translated for French, Arabic, and
  Italian.

- Migrated the hand-maintained localization map to the standard Flutter ARB +
  `gen_l10n` workflow (`lib/src/l10n/app_{en,fr,ar,it}.arb`, `l10n.yaml`,
  `flutter: generate: true`).
- Kept a backwards-compatible `AppLocalizations` shim (`t`, `tParams`,
  `userRoleLabel`, `invitationStatusLabel`, `syncActionTypeLabel`,
  `alertTypeLabel`) so existing call sites are unchanged.
- Backfilled three keys that were missing from the French and Arabic maps
  (`alertResolveFailedToast`, `alertDeleteFailedToast`,
  `notificationAcknowledgedToast`) using the English source string (flagged for
  translation).

## 0.1.0

Initial Ivra pilot foundation.

- Added Flutter Android + web app shell.
- Added role-aware navigation for App Admin, App Manager, Hotel Manager, and Hotel Staff.
- Added route and screen-action gates for role-specific management permissions.
- Added demo repository for local development.
- Added Supabase schema, RLS policies, RPCs, product seed data, reporting views, and alert scheduling.
- Added hotel, room, refill, inventory, product catalog, approval, alert, report, team, account, password reset, and invitation flows.
- Added Supabase auth-state refresh, account sign-out, and invitation sign-in handling.
- Added offline queue storage, retry, removal, and conflict payload editing.
- Added retry-safe client request ids for offline refill, bottle replacement, and stock sync.
- Added CSV/PDF report exports.
- Added inventory snapshot CSV/PDF exports.
- Added PDF exports for refill history and open alerts.
- Added localized report export cards and action labels.
- Added bundled Unicode fonts for localized PDF report output.
- Added English, French, Arabic, and RTL layout support.
- Added Android package identity, launcher icons, adaptive icons, splash assets, and release-signing hooks.
- Added web manifest, favicon, and PWA icons.
- Added deployment, release, security, privacy, and pilot onboarding docs.
- Added CI workflow for analyze, tests, web build, and Android debug build.
- Added Supabase CLI deployment and SQL rendering helper scripts.
- Added Supabase environment setup helper for production `.env` creation.
- Added REST-level Supabase RLS verification helper for real role accounts.
- Added Android release signing setup helper and key properties example.
- Added Android app bundle and combined release packaging helper scripts.
- Added release manifest generation for deployable artifact hashes and sizes.
- Added release archive helper for web zip, Android artifacts, manifest, and checksums.
- Added combined go-live preparation and release archive verification helpers.
- Added go-live evidence report generation for release handoff status.
- Added go-live record template for production setup and pilot sign-off.
