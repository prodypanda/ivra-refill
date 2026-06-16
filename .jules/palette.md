## 2024-06-16 - RTL Layout with EdgeInsetsDirectional

**Learning:** `EdgeInsetsDirectional` in Flutter does not have `.all()` or `.symmetric()` constructors, because margins applied equally on all sides or equally on left/right sides are already direction-agnostic. Attempting to use `EdgeInsetsDirectional.all()` will result in compile errors.
**Action:** Use standard `EdgeInsets.all()` and `EdgeInsets.symmetric()` for symmetrical padding, and only use `EdgeInsetsDirectional.only(start: x, end: y)` when padding is specifically tied to the reading direction.
