# Changelog

## Unreleased
- Updated safe packages for security audit: app_links, firebase_core, firebase_messaging, google_fonts, gotrue, local_auth, mobile_scanner, realtime_client, supabase, supabase_flutter, uuid.

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
