## 2024-05-15 - AnimatedSwitcher requires explicit Keys for identical widget types
**Learning:** When using `AnimatedSwitcher` to transition between states that yield the same root widget type (e.g., `SizedBox`), Flutter cannot detect the change in the widget tree without explicit `ValueKey`s, causing the animation to fail silently.
**Action:** Always provide unique `key` parameters (e.g., `key: ValueKey('loading')`) to the top-level children of an `AnimatedSwitcher` if they share the same `runtimeType`.
