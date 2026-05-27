# Ivra Data And Privacy Notes

This document summarizes the operational data the app handles and the expected safeguards for pilots.

## Data Stored

- Hotel profile information.
- Floor and room information.
- Product catalog settings.
- Room product lifecycle data.
- Refill events and undo events.
- Correction requests.
- Approval requests.
- Inventory events.
- Alert history.
- Team profiles and invitations.
- Audit history.

## Data Not Stored In V1

- QR code scans.
- Bottle photos.
- Guest personal data.
- Payment information.
- Purchase order fulfillment records.

## Access Principles

- Ivra App Admins can manage all data.
- Ivra App Managers can operate across hotels.
- Hotel Managers and Hotel Staff can access only their assigned hotel.
- Hotel Staff should have the narrowest access needed to record daily actions.
- Anonymous users should have no operational data access.

## Retention Guidance

For the pilot, keep operational records long enough to validate refill limits, bottle age, inventory accuracy, and recycling needs. Before a full production rollout, define retention periods for:

- Audit history.
- Refill event history.
- Correction requests.
- Cancelled invitations.
- Deactivated staff profiles.

## Export Handling

CSV and PDF exports can contain hotel operational data. Treat exports as internal Ivra documents:

- Do not send exports to unrelated hotels.
- Store exports in approved company storage.
- Delete outdated exports from shared machines.
- Review exported report contents before sharing externally.

## Production Review

Before production launch, confirm:

- Supabase RLS has been tested with all four roles.
- Service-role keys are not used in the Flutter app.
- `.env` and signing files are not committed.
- Account deactivation process is clear.
- Support team knows how to handle incorrect refill records.
- Privacy wording is ready for hotel contracts or onboarding documents.

