## 2024-07-06 - RTL Support for Border Radius
**Learning:** `BorderRadius.only(topLeft: ..., topRight: ...)` relies on physical directions that do not correctly mirror in RTL layouts (like Arabic).
**Action:** When supporting RTL layouts in Flutter, use `BorderRadius.vertical(top: ...)` or `BorderRadiusDirectional.horizontal(start: ...)` instead.
