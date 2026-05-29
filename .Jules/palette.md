## 2024-05-29 - Missing Tooltips on IconButtons
**Learning:** Found several `IconButton` widgets used for clearing searches or closing dialogs that were missing tooltips. In Flutter, the `tooltip` property also acts as the semantic label for screen readers. Missing these makes the app less accessible.
**Action:** Always ensure icon-only buttons (`IconButton`) have a descriptive `tooltip` provided, and remember to add the localized strings to `lib/src/l10n/app_localizations.dart`.
