# Implementation Plan — Product Bottle Types, Refill Capability, and Refill-Bottle Terminology

App: `ivra-refill`  
Status: Ready for implementation

## Goal

Add two product configuration choices:

1. Bottle type:
   - Bottle with pump
   - Bottle without pump

2. Refill capability:
   - Refillable product
   - Direct replacement product (no refill bottle, replaced directly)

Also rename all user-facing “bidon” / “bidon de recharge” terminology to “refill bottle” / “bouteille de recharge” across the app and the four supported languages (English, French, Arabic, and Italian).

## Important Existing Code Areas

- Product model: [models.dart](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/domain/models.dart)
- Enums: [app_enums.dart](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/domain/app_enums.dart)
- Repository interface: [ivra_repository.dart](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/data/ivra_repository.dart)
- Mock repository: [mock_ivra_repository.dart](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/data/mock_ivra_repository.dart)
- Supabase repository: [supabase_ivra_repository.dart](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/data/supabase_ivra_repository.dart)
- Product UI: [products_screen.dart](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/features/products/products_screen.dart)
- Inventory UI: [inventory_screen.dart](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/features/inventory/inventory_screen.dart)
- Rooms UI: [rooms_screen.dart](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/features/rooms/rooms_screen.dart)
- Localization:
  - [app_en.arb](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/l10n/app_en.arb)
  - [app_fr.arb](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/l10n/app_fr.arb)
  - [app_ar.arb](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/l10n/app_ar.arb)
  - [app_it.arb](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/l10n/app_it.arb)
- Version: [pubspec.yaml](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/pubspec.yaml) and [version.dart](file:///C:/Users/PC/.gemini/antigravity/worktrees/ivra_refill/resume-unfinished-devin-session/lib/src/version.dart)

## Data Model Changes

Add two new enums in `lib/src/domain/app_enums.dart`:

```dart
enum BottleType {
  withPump('with_pump'),
  withoutPump('without_pump');

  final String value;
  const BottleType(this.value);

  static BottleType fromValue(String value) {
    return BottleType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BottleType.withPump,
    );
  }
}

enum RefillType {
  refillable('refillable'),
  directReplacement('direct_replacement');

  final String value;
  const RefillType(this.value);

  static RefillType fromValue(String value) {
    return RefillType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RefillType.refillable,
    );
  }
}
```

Add fields to `Product` in `lib/src/domain/models.dart`:

```dart
final BottleType bottleType;
final RefillType refillType;

bool get isRefillable => refillType == RefillType.refillable;
bool get isDirectReplacement => refillType == RefillType.directReplacement;
```

Default existing products to:
- `bottleType = BottleType.withPump`
- `refillType = RefillType.refillable`

## Database Migration

Create a new migration: `supabase/migrations/0002_product_types.sql`

```sql
alter table products
  add column if not exists bottle_type text not null default 'with_pump'
    check (bottle_type in ('with_pump', 'without_pump')),
  add column if not exists refill_type text not null default 'refillable'
    check (refill_type in ('refillable', 'direct_replacement'));
```

## Repository Updates

Update the interfaces and mock/Supabase repositories to read/write `bottleType` and `refillType`.

## Product Create/Edit UI

In `products_screen.dart`, update `_ProductDialog`:
- Add selectors/buttons for Bottle Type and Refill Type.
- Hide refill-bottle-specific fields when Refill Type is "Direct replacement":
  - Refill bottle volume (refill bottle ml)
  - Max refills
  - Max age days
  - Low threshold (low refill bottles)
- Ensure hidden fields default safely to prevent validation errors.
- Display premium tags on product cards showing bottle type & refill type.

## Inventory Page

- Replace Full bottles icon with a bottle-with-pump icon.
- Replace Full refill bottles (bidons) icon with a standard bottle icon.
- For direct replacement products, hide the "Full refill bottles" and "Opened refill bottles" areas.
- Update stock adjustment dialogs (single & bulk) to hide refill-bottle fields for direct replacement products.
- Ensure suggested orders do not suggest refill-bottle orders for direct replacement products.

## Rooms Page

For direct replacement products:
- Hide/remove the Refill button.
- Make "Replace bottle" the primary/only action.
- Update QR action dialog to only offer Replace.

## Localization

- Update English, French, Arabic, and Italian translation files.
- Rename all user-facing "bidon" strings to "refill bottle" equivalents.
- Add new translations for bottle types, refill types, and selectors.
- Regenerate localizations and ensure compatibility shims are updated.

## Version Update

Bump `pubspec.yaml` to `1.0.38+39`, and run version generation.

## Validation

Run analyze, tests, and builds to ensure correctness.
