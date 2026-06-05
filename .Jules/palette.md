## 2024-05-24 - Missing Tooltips on IconButtons
**Learning:** In Flutter, `IconButton` widgets must include a `tooltip` property to ensure accessibility, providing semantic labels for screen readers. Icon-only buttons without tooltips are an accessibility violation.
**Action:** Always verify that `IconButton` implementations, especially those for toggling state (like password visibility), have a localizable `tooltip` property set.
