## 2024-06-12 - RTL and Refactoring

**Learning:** When dealing with RTL (Right-to-Left) languages like Arabic in Flutter, `Alignment` and `EdgeInsets` must be replaced with `AlignmentDirectional` and `EdgeInsetsDirectional`. Hardcoding left/right will break the layout. Large widget trees should be extracted into smaller, reusable, `const` classes to improve the workflow for hotel staff and managers (speed, clarity, aesthetics).

**Action:** Always prefer directional classes (`AlignmentDirectional.centerStart`, `EdgeInsetsDirectional.only(start: ...)`) for layout configurations. Make UI components `const` where possible and separate large `build` methods into private classes.
