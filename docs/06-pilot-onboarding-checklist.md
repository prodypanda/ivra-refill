# Ivra Pilot Onboarding Checklist

Use this checklist for the first hotel pilot and repeat it for each new hotel.

## Before The Pilot

- Confirm Supabase production project is ready.
- Apply `supabase/migrations/0001_initial_schema.sql`.
- Create the first `app_admin` with `supabase/bootstrap_first_admin.sql`.
- Create at least one App Manager account.
- Verify RLS with `supabase/rls_verification.sql`.
- Build Android and web with production Supabase values.
- Confirm support contact and escalation channel.

## Hotel Setup

- Create the hotel account.
- Add hotel legal name, address, city, country, phone, email, and contact person.
- Create floors.
- Create rooms manually or with room/floor templates.
- Assign products to each room.
- Set starting bottle dates and refill counts if bottles are already in use.
- Add starting inventory for 1L bottles and 5L bidons.
- Run smart-alert refresh and confirm starting alerts are expected.

## Team Setup

- Invite the Hotel Manager.
- Invite Hotel Staff users who will record refills.
- Confirm each user can sign in.
- Confirm each user sees only the correct hotel.
- Cancel unused invitations.

## Training

- Show Hotel Staff how to record a refill.
- Show Hotel Staff how to undo a refill within 30 minutes.
- Show Hotel Manager how to request a correction after 30 minutes.
- Show Hotel Manager how to submit hotel, room, and floor edits for approval.
- Show App Manager how to approve or reject pending edits.
- Show App Manager how to review low-stock and lifecycle alerts.
- Show App Manager how to export reports.

## First Week Checks

- Review refill events daily.
- Review correction requests daily.
- Check alerts for low stock, old bottles, and refill limits.
- Confirm offline actions sync correctly after reconnecting.
- Confirm suggested order quantities are reasonable.
- Confirm staff are not using shared accounts.

## Pilot Exit Criteria

- Hotel staff can record refills without assistance.
- Hotel manager understands correction and approval rules.
- App manager can generate accurate reports.
- Inventory and refill counts match physical stock checks.
- No cross-hotel data is visible to hotel users.
- Replacement and recycling alerts are trusted by the operations team.

