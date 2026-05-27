# Ivra Todo Checklist

## Foundation

- [x] Create project documentation.
- [x] Create Flutter project metadata.
- [x] Create app domain models and enums.
- [x] Create demo repository for local UI development.
- [x] Create Supabase repository adapter.
- [x] Create Supabase schema migration.
- [x] Generate native Flutter Android/web folders with `flutter create --platforms=android,web .`.
- [x] Run `flutter pub get`.

## Backend

- [x] Define core enums.
- [x] Define hotels, floors, rooms, products, room products, inventory, refill events, approvals, corrections, alerts, and audit tables.
- [x] Add RLS helper functions and policies.
- [x] Add refill, undo, and correction RPCs.
- [x] Add pending edit request and stock adjustment RPCs.
- [x] Add product seed data.
- [x] Add suggested-order and room-product reporting views.
- [x] Apply migration to Supabase project.
- [x] Create real users and assign profiles/roles.
- [x] Add manual smart-alert generation trigger and alert resolve RPC.
- [x] Add scheduled alert generation job.

## Flutter App

- [x] Add responsive app shell.
- [x] Add role-aware navigation.
- [x] Add role-gated route redirects and screen action controls.
- [x] Add dashboard metrics.
- [x] Add hotels screen.
- [x] Add rooms/refill screen.
- [x] Add inventory/suggested orders screen.
- [x] Add approvals/corrections screen.
- [x] Add alerts screen.
- [x] Add reports/export screen.
- [x] Add settings and language selector foundation.
- [x] Add initial Supabase email/password authentication screen.
- [x] Add first working hotel creation, hotel edit request, room template, and stock adjustment forms.
- [x] Add refill history, undo, correction request, and correction approval backend flow.
- [x] Add Team screen with active accounts, pending invitations, and role-safe invitation RPC.
- [x] Wire refill, undo, correction, and stock actions into an offline queue with Settings sync controls.
- [x] Add retry-safe client request ids for offline refill, bottle replacement, and stock sync.
- [x] Add Product Catalog screen with editable bottle/bidon sizes, refill limits, age limits, and stock thresholds.
- [x] Add smart-alert refresh, counters, severity display, and resolve action.
- [x] Add real CSV/PDF export downloads for reports.
- [x] Add inventory snapshot CSV/PDF exports.
- [x] Add PDF exports for refill history and open alerts.
- [x] Localize report export cards and actions.
- [x] Add Unicode-capable fonts for localized PDF reports.
- [x] Add team invitation resend/cancel and account activate/deactivate controls.
- [x] Add full create/edit forms for remaining entities and user/team management.
- [x] Add password reset screens.
- [x] Add invitation acceptance screen and token-based join flow.
- [x] Add Supabase auth-state refresh, sign-out, and invitation sign-in handling.
- [x] Add remaining account-management screens.
- [x] Add persistent offline queue storage.
- [x] Add failed sync visibility with retry/remove controls.
- [x] Add deeper conflict-resolution UI for server-side data conflicts.

## QA

- [x] Run Flutter analyzer.
- [x] Run Flutter tests.
- [x] Verify web layout in desktop and mobile widths.
- [x] Verify Android build.
- [x] Verify Android release build configuration.
- [x] Add CI workflow for analyze, tests, web build, and Android debug build.
- [x] Add security, privacy, and pilot onboarding handoff docs.
- [x] Add contribution, changelog, PR, and issue templates.
- [x] Add release-readiness gate script.
- [x] Add Supabase environment setup helper.
- [x] Add Supabase CLI deployment helper.
- [x] Add Supabase SQL rendering helper.
- [x] Add REST-level Supabase RLS verification helper.
- [x] Add Android release signing setup helper.
- [x] Add Android app bundle and combined release packaging helpers.
- [x] Add release manifest generation with artifact hashes.
- [x] Add release archive helper with web zip and checksums.
- [x] Add combined go-live preparation and release archive verification helpers.
- [x] Add go-live evidence report generation.
- [x] Add go-live record template for production setup and pilot sign-off.
- [x] Verify Supabase RLS with all 4 role accounts.
- [x] Verify Arabic RTL screens.
