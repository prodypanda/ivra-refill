## 2024-05-24 - Flutter List Rendering vs Lazy Slivers
**Learning:** Using `ListView.builder` with `shrinkWrap: true` inside a scrollable layout like a `Column` or `SliverToBoxAdapter` forces the framework to synchronously instantiate all children, defeating the intended performance benefits of lazy-loading.
**Action:** Only use `ListView.builder` without `shrinkWrap` in bounded contexts, or use `SliverList.builder` directly within a `CustomScrollView` for true lazy rendering.

## 2024-05-24 - RegExp compilation in build methods
**Learning:** Compiling a `RegExp` object inside a `build` method forces the regex engine to re-parse and re-compile the pattern on every widget rebuild, which is an unnecessary CPU hit for stateless patterns.
**Action:** Always extract regex patterns into `static final` constants.
