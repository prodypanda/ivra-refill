# Ivra Security Policy

## Supported Versions

The active pilot version is:

- `0.1.x`

Security fixes should be applied to the active pilot branch before onboarding more hotels.

## Reporting A Security Issue

Report security issues privately to the Ivra app owner or project maintainer. Do not open public issues for:

- Authentication bypasses.
- Cross-hotel data access.
- Exposed Supabase keys beyond the public anon key.
- Approval, refill, or inventory tampering.
- Lost device or account compromise incidents.

Include:

- What account or role was used.
- What hotel was expected to be visible.
- What data or action was incorrectly allowed.
- Screenshots or logs if available.
- Date and time of the incident.

## Secrets

Never commit:

- `.env`
- Supabase service-role keys.
- Android keystores.
- `android/key.properties`
- Production passwords.

The Supabase anon key is public by design, but the app still depends on RLS policies to protect data. Treat any RLS bypass as a high-priority security issue.

## Access Rules

The release gate must verify:

- `app_admin` can access all operational data.
- `app_manager` can manage hotels, inventory, products, approvals, alerts, and reports.
- `hotel_manager` can access only their assigned hotel.
- `hotel_staff` can record allowed hotel actions only.
- Anonymous users cannot read operational tables.

Use `supabase/rls_verification.sql` after setting up real role accounts.

## Device And Account Handling

- Disable accounts immediately when staff leave a hotel.
- Rotate passwords for shared test accounts after pilot demos.
- Do not share App Admin credentials with hotel users.
- Prefer named user accounts over shared hotel accounts.
- Review pending invitations regularly and cancel stale ones.

## Release Safety

Before shipping to hotels:

- Build Android with a real release keystore.
- Deploy web with production Supabase values.
- Confirm the app is not running against demo data.
- Run `.\scripts\verify_local.ps1 -BuildAndroid`.
- Complete `docs/05-release-checklist.md`.

