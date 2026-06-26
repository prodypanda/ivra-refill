## 2026-06-26 - Prevent Unbounded Height Exceptions with ListView in Loading States
**Learning:** Using `ListView.builder` (even with `shrinkWrap: true`) inside an unconstrained widget (like `AsyncValueView.loadingWidget`) can cause a 'Vertical viewport was given unbounded height' rendering exception.
**Action:** For finite, static loading placeholders (like a list of 3 shimmer cards), always use a `Column` with `List.generate` instead of `ListView.builder` to guarantee layout boundaries without relying on external constraints.

## 2026-06-26 - Modern fl_chart Animations
**Learning:** In `fl_chart`, the `swapAnimationDuration` and `swapAnimationCurve` properties are deprecated on the  widget.
**Action:** Use the `duration` and `curve` properties directly on the `BarChart` widget instead.

## 2026-06-26 - Modern fl_chart Animations
**Learning:** In fl_chart, the swapAnimationDuration and swapAnimationCurve properties are deprecated on the BarChart widget.
**Action:** Use the duration and curve properties directly on the BarChart widget instead.
