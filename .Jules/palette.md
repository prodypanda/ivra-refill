## 2024-05-18 - Icon Button Accessibility
**Learning:** IconButton widgets inside text fields or dialogs without text labels must have tooltips for screen reader accessibility and general UX. Running repository-wide formatting commands (`dart format .`) can result in large, unrelated diffs that violate PR size limits and cause merge conflicts.
**Action:** Always add the `tooltip` property to `IconButton` widgets if they lack visible text labels. When making targeted changes, avoid running global formatters unless explicitly scoped to the modified files to keep the PR clean and within limits.
