## 2024-06-25 - Extracting RegExp from build methods
**Learning:** Instantiating `RegExp` objects inside `build` methods forces Flutter to recompile the regular expression on every widget rebuild, which is an expensive operation.
**Action:** Always declare `RegExp` objects as `static final` or top-level `final` constants outside of `build` methods and frequently called functions to optimize performance.
