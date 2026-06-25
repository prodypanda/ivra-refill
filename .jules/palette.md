## 2024-05-18 - Dashboard UI/UX Enhancements

**Learning:** Enhancing `fl_chart` tooltips with dynamic theme colors (`onPrimaryContainer`, `primaryContainer`) significantly improves contrast over hardcoded white text, making charts more accessible. Using `CardShimmer` instead of `CircularProgressIndicator` creates a smoother, more modern perception of speed during data loads. Also, replacing `Positioned(right: ...)` with `PositionedDirectional(end: ...)` is crucial for robust RTL support.

**Action:** Consistently utilize `theme.colorScheme` for dynamic widget properties. Default to using shimmer loaders (`CardShimmer` / `ShimmerLoading`) for async data states across the application instead of basic spinners. Regularly review `Positioned` usage in Stacks to ensure directional variants are used when horizontal alignment depends on text direction.
