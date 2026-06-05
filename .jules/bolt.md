## 2024-06-05 - Extract RegExp Compilations in Flutter Build Methods
**Learning:** In Flutter, `RegExp` compilation is relatively expensive. If instantiated directly within a `Widget.build` method (which can be called frequently, such as 60 times per second during animations or scrolling), it causes unnecessary re-compilations and can degrade performance.
**Action:** Always extract `RegExp` instances to static final variables at the class level or top-level final variables so they are compiled only once, rather than on every rebuild or function invocation.
