# Task List — Product Types, Direct Replacement Products, and Refill-Bottle Rename

## Phase 1 — Planning Files
- [x] Add `IMPLEMENTATION_PLAN.md` to the project root.
- [x] Add `TASK_LIST.md` to the project root.

## Phase 2 — Domain Model
- [x] Add `BottleType` enum in `lib/src/domain/app_enums.dart`.
- [x] Add `RefillType` enum in `lib/src/domain/app_enums.dart`.
- [x] Update `Product` in `lib/src/domain/models.dart` with:
  - [x] `bottleType`
  - [x] `refillType`
  - [x] `isRefillable`
  - [x] `isDirectReplacement`
- [x] Update `Product.fromMap` and `Product.toMap`.
- [x] Update `Product.copyWith`.

## Phase 3 — Database
- [x] Create migration `supabase/migrations/0002_product_types.sql`.
- [x] Add `products.bottle_type`.
- [x] Add `products.refill_type`.

## Phase 4 — Repository Layer
- [x] Update `IvraRepository.createProduct` and `updateProduct`.
- [x] Update `MockIvraRepository`.
- [x] Update `SupabaseIvraRepository`.

## Phase 5 — Localization
- [x] Update English, French, Arabic, and Italian ARB files.
- [x] Add labels for new bottle/refill types.
- [x] Rename user-facing "bidon" terms to "refill bottle" equivalents.
- [x] Regenerate localization output and ensure `app_localizations_values.g.dart` is in sync.

## Phase 6 — Products Page
- [x] Update `_ProductDialog` in `products_screen.dart` with selectors.
- [x] Hide refill-only fields when direct replacement is selected.
- [x] Update product cards to show new configuration tags.

## Phase 7 — Inventory Page
- [x] Replace Full bottles icon with pump bottle.
- [x] Replace Full refill bottles icon with plain bottle.
- [x] Hide refill bottle areas for direct replacement products.
- [x] Update stock adjustment dialogs.
- [x] Exclude direct replacement from suggested refill bottle orders.

## Phase 8 — Rooms Page
- [x] Hide Refill button for direct replacement products.
- [x] Make Replace button primary.
- [x] Update QR action dialog.

## Phase 9 — Alerts and Reports
- [x] Update user-facing strings from "bidon" to "refill bottle" in alerts and reports.

## Phase 10 — Version
- [x] Update `pubspec.yaml` to `1.0.38+39`.
- [x] Run version generation script.

## Phase 11 — Verification
- [x] Run `flutter analyze`, `flutter test`, and build checks.
