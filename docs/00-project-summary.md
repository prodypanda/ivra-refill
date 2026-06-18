# Ivra Project Summary

Ivra sells personal care products to hotels, including shampoo, conditioner, shower gel, hand wash, and hand/body lotion. Products are placed in hotel rooms as 1L bottles and refilled from 5L bidons.

The app manages the full refill operation across Android and web:

- Hotels, floors, rooms, and room product assignments.
- Bottle refill count, bottle age, last refill datetime, and lifecycle status.
- Hotel inventory for 1L bottles and 5L bidons.
- Suggested reorder quantities for new bottles and refill bidons.
- Hotel manager edits that require App Manager/Admin approval.
- Refill undo within 30 minutes.
- Correction requests after 30 minutes.
- Approval history, audit history, reports, alerts, exports, and offline sync.

## Roles

### App Admin

Full access and control over every hotel, user, approval, report, and setting.

### App Manager

Can create hotel accounts, manage hotel structure and products, approve hotel manager edits, manage inventory and reports, and review correction requests.

### Hotel Manager

Can manage their own hotel information, floors, rooms, room products, hotel team accounts, refill updates, stock updates, and correction requests. Edits to hotel structure/information are pending until approved by App Manager/Admin.

### Hotel Staff

Can record refills and stock actions for their assigned hotel. They cannot edit hotel structure or approve requests.

## V1 Scope

- Flutter shared app for Android and web.
- Supabase Auth and Postgres backend.
- In-app smart alerts and push notifications (Firebase Cloud Messaging).
- QR code bottle scanning.
- Product/photo images for products.
- Offline action queue for refill/stock workflows.
- English, French, Arabic, and Italian localization (RTL for Arabic).

Out of V1:

- Full purchase-order fulfillment.

