## 2026-06-03 - Missing Tooltips on Icon-Only Buttons
**Learning:** IconButtons used inside `suffixIcon` (like clear search) or internal widget implementations often get overlooked for accessibility because they are visually obvious but functionally opaque to screen readers without a `tooltip` property.
**Action:** Always verify that every `IconButton`, especially those nested in text fields or dialogs, has a localized `tooltip` set.
