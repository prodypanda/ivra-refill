## 2024-07-03 - Avoid Division by Zero in Visual Proportion Bars

**Learning:** When generating a dynamic `LinearProgressIndicator` based on a list of data rows (e.g. `row.value / maxVal`), if all counts are zero or the list is empty, `maxVal` resolves to 0 resulting in `NaN`, which causes a debug assertion crash in Flutter.

**Action:** Always safely fallback maximum layout values to at least 1: `final maxVal = (rows.isEmpty || rows.first.value == 0) ? 1 : rows.first.value;`.

## 2024-07-03 - Smooth Loading States for Riverpod Data

**Learning:** Displaying empty states instantly when network data is still fetching creates visual jarring. `AsyncValue` provides an `.isLoading` state that should be leveraged alongside an `AnimatedSwitcher` and `ShimmerLoading` placeholders.
