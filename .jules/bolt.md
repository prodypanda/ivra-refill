## 2024-06-25 - Extracting RegExp compilation in Flutter build methods
**Learning:** Compiling a `RegExp` pattern inside a Flutter widget's `build` method forces the regular expression to be expensively recompiled on every single rebuild of that widget. In widgets that rebuild frequently (like `PageScaffold` when state changes), this can cause unnecessary performance overhead.
**Action:** Always extract `RegExp` objects as `static final` properties at the class level or define them outside the widget scope so they are compiled only once.
