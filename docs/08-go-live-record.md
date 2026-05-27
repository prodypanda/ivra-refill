# Ivra Go-Live Record

Use this record when Ivra moves from local/demo testing to a real Supabase project, a signed Android build, and the first hotel pilot. Do not store passwords, Supabase keys, private keystore files, or other secrets in this file.

## Release Snapshot

- Release owner:
- Release date:
- App version:
- Supabase environment:
- Web deployment URL:
- Android package: `com.ivra.refill`
- Android app label: `Ivra Refill`

## Supabase Project

- Project reference:
- Project URL host:
- Migration applied date:
- Migration source: `supabase/migrations/0001_initial_schema.sql`
- First app admin auth user ID:
- First app admin email:
- First app manager email:
- Hotel manager test email:
- Hotel staff test email:
- RLS verification date:
- RLS verification file: `supabase/rls_verification.sql`

## Android Signing

- Keystore storage location:
- Key alias:
- Signing setup command: `.\scripts\setup_android_signing.ps1`
- Local signing properties: `android/key.properties`
- Build command: `.\scripts\build_android_release.ps1`
- Release APK or AAB path:
- Release manifest path: `.generated/release/release-manifest.json`
- Go-live evidence path: `.generated/release/go-live-evidence.md`
- Release archive folder:
- Release checksums path:
- Android device smoke-test date:

## Web Deployment

- Hosting provider:
- Production domain:
- Build command: `.\scripts\build_web.ps1`
- Build folder: `build/web`
- Archived web zip:
- Browser smoke-test date:
- Mobile-width smoke-test date:

## Pilot Hotel

- Hotel name:
- Hotel manager contact:
- App manager contact:
- Number of floors:
- Number of rooms:
- Product set:
- Starting bottle stock:
- Starting 5L bidon stock:
- Room setup method:
- Training date:

## Sign-Off Checklist

- [ ] Production `.env` exists locally with real Supabase values.
- [ ] `android/key.properties` exists locally and points to a private keystore outside source control.
- [ ] Supabase migration has been applied to the production project.
- [ ] First `app_admin` profile has been created.
- [ ] Real app manager, hotel manager, and hotel staff accounts have been created.
- [ ] RLS verification passed for all four roles.
- [ ] Release readiness gate passed with `.\scripts\check_release_readiness.ps1`.
- [ ] Android release build installed and opened on a real device.
- [ ] Web deployment opened successfully on desktop and mobile width.
- [ ] Refill, undo, correction request, approval, inventory, alert, and export flows were smoke-tested.
- [ ] English, French, and Arabic UI were spot-checked.
- [ ] Arabic RTL layout was spot-checked.
- [ ] Pilot hotel staff received basic operating instructions.

## Notes

- Deployment notes:
- Known limitations:
- Follow-up items:
