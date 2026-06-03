## 2024-06-25 - Extracted RegExp Compilations from Build Methods
**Learning:** Recompiling `RegExp` inside Flutter `build` methods is an expensive operation that runs synchronously every time the widget rebuilds. This can cause unnecessary jank, especially in widgets that rebuild frequently.
**Action:** Always declare `RegExp` objects as `static final` (for classes) or top-level `final` variables so they are compiled only once during the application's lifecycle.
