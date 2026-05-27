# Ivra Acceptance Tests

## Roles And Security

- [ ] App Admin can view and manage all hotels, rooms, products, inventory, users, approvals, alerts, and reports.
- [ ] App Manager can create and manage hotels and approve hotel manager requests.
- [ ] Hotel Manager can only access their assigned hotel.
- [ ] Hotel Staff can only record refill and stock actions for their assigned hotel.
- [ ] Supabase RLS blocks cross-hotel reads and writes.

## Approval Workflow

- [ ] Hotel Manager edits hotel information and the app creates a pending approval request.
- [ ] Pending edits do not change live hotel data.
- [ ] App Manager/Admin approves a request and the change becomes active.
- [ ] Rejected requests keep live data unchanged.
- [ ] Old values, new values, requester, reviewer, and timestamps are stored.

## Refill Workflow

- [ ] User records a refill for one room product.
- [ ] Refill count increments by one.
- [ ] Last refill datetime updates.
- [ ] Bottle status changes when max refill count or max bottle age is reached.
- [ ] Refills create immutable history records.

## Undo And Correction

- [ ] Refill can be undone by the same user within 30 minutes.
- [ ] Undo creates an undo event and restores the previous refill count.
- [ ] Undo is rejected after 30 minutes.
- [ ] User can submit a correction request after 30 minutes.
- [ ] App Manager/Admin can approve or reject correction requests.

## Inventory And Orders

- [ ] Hotel inventory shows 1L bottle and 5L bidon counts per product.
- [ ] Low stock alerts appear when thresholds are crossed.
- [ ] Suggested order quantities calculate needed bottles and bidons.
- [ ] Suggested orders do not create formal purchase orders in V1.

## Offline Mode

- [ ] Refill actions can be queued while offline.
- [ ] Queued actions sync when online.
- [ ] Failed sync actions show clear error state.
- [ ] Duplicate refill submissions are not created after retry.

## Reports And Localization

- [ ] Reports export CSV data matching current records.
- [ ] PDF export can be generated for management reports.
- [ ] English, French, and Arabic labels are available for core navigation.
- [ ] Arabic switches the app to RTL layout.

