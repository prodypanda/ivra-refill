# Ivra Refill — Public Production Deployment Guide

This guide takes Ivra from the repo to a public production deployment **for free**:

- Web app + a marketing landing page on **`refill.ivra-cosmetics.com`**
- A downloadable Android APK (link + QR code on the landing page)
- A "Login (Web App)" button that opens the web login

Layout used throughout:

```
refill.ivra-cosmetics.com/        -> landing page (download + QR + login button)
refill.ivra-cosmetics.com/app/    -> the Flutter web app (the Login button)
```

---

## 0. Prerequisites (one-time)

- Flutter installed (the version this repo uses).
- Node.js (for the Firebase CLI): https://nodejs.org (LTS).
- Your Supabase URL and **publishable anon key** (the same values you already
  pass to `run_android.ps1`). The anon key is a public client key — it is meant
  to ship inside the app, so it is safe to use in the web build.
- Access to DNS for `ivra-cosmetics.com` (to add the `refill` subdomain).

> Note on branding: the app no longer prints or displays the backend provider's
> name anywhere a customer can see (UI strings + the browser console log were
> removed in the same PR as this guide).

---

## 1. App version (done)

`pubspec.yaml` is set to `version: 1.0.1+2` (version name **1.0.1**, build code 2).
Bump the `+N` build number on every store/APK release so installs upgrade cleanly.

---

## 2. Replace the logo (launcher icon, splash, favicon)

The launcher icon and the native splash are both generated from one file:
**`assets/images/logo.png`**.

1. Replace `assets/images/logo.png` with your logo. Use a **square PNG, 1024×1024**,
   transparent background (a centered mark works best for the Android adaptive icon).
2. Regenerate the icons and splash:

   ```powershell
   flutter pub get
   dart run flutter_launcher_icons          # Android launcher / shortcut icon
   dart run flutter_native_splash:create    # Android + web native splash
   ```

3. Web favicon / PWA icons: replace `web/favicon.png` and the files in `web/icons/`
   (`Icon-192.png`, `Icon-512.png`, and the maskable variants) with your logo at
   those pixel sizes. Update `web/manifest.json` `name`/`short_name` if desired.

4. **In-app brand marks** (the header, the login screen, and the animated loading
   screen) currently render the word **"Ivra"** as styled text, *not* an image:
   - Header: `_BrandMark` in `lib/src/features/shell/app_shell.dart`
   - Login: `lib/src/features/auth/login_screen.dart` (the `'Ivra'` Text)
   - Loading screen: `lib/src/features/shared/premium_loading.dart`
   - Web pre-load splash text: `web/index.html` (`.app-name` / `.subtitle`)

   If you want your logo image instead of the text mark in these spots, tell me
   and I'll swap them to `Image.asset('assets/images/logo.png')` — it's a small
   change but a deliberate design choice, so I left the text marks intact.

---

## 3. Build the Android release APK

```powershell
flutter build apk --release `
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_ANON_KEY
```

Output: `build\app\outputs\flutter-apk\app-release.apk`.
Rename it to `ivra-refill.apk` for a stable download filename (the landing page
QR/link expect this name by default — see step 6).

> The APK above is signed with the **debug** key unless you configure a release
> keystore. That's fine for sideloading from your own site. If you later publish
> on Google Play, set up a release keystore in `android/app/build.gradle`.

---

## 4. Build + assemble the web bundle

From the repo root:

```powershell
.\deploy\assemble_public.ps1 -SupabaseUrl "https://YOUR-PROJECT.supabase.co" -SupabaseAnonKey "YOUR_PUBLISHABLE_ANON_KEY"
```

This builds the Flutter web app with `--base-href /app/` and produces a `public/`
folder:

```
public/
  index.html        (landing page)
  logo.png
  vendor/qrcode.min.js
  app/              (the Flutter web app)
```

It also copies `deploy/firebase.json` to the repo root for the Firebase CLI.

---

## 5. Free hosting options

Any of these have a free tier that comfortably fits this app:

| Host | Why | Custom domain (free) | Notes |
|------|-----|----------------------|-------|
| **Firebase Hosting** (recommended) | You already use Firebase; one CLI, free SSL | Yes | 10 GB storage, 360 MB/day transfer free |
| Cloudflare Pages | Generous free tier, fast CDN | Yes | Connect a Git repo or upload `public/` |
| Netlify | Drag-and-drop `public/` folder | Yes | 100 GB/month bandwidth free |

The rest of this guide uses **Firebase Hosting**. The `public/` folder produced
in step 4 works identically on Cloudflare Pages or Netlify (just point the host
at `public/` as the output directory).

---

## 6. Distribute the APK (GitHub Releases — free)

1. On GitHub: **Releases → Draft a new release**.
2. Tag `v1.0.1`, title `Ivra 1.0.1`.
3. Attach `ivra-refill.apk` as a release asset, publish.
4. The stable "latest" download URL is then:

   ```
   https://github.com/prodypanda/ivra-refill/releases/latest/download/ivra-refill.apk
   ```

   This is already the default `DOWNLOAD_URL` in `deploy/landing/index.html`.
   (Alternative: drop `ivra-refill.apk` into `public/` and use
   `https://refill.ivra-cosmetics.com/ivra-refill.apk`.)

---

## 7. Point the landing page at your URLs

Edit the config block near the top of `deploy/landing/index.html`:

```js
window.IVRA_CONFIG = {
  WEB_APP_URL: "/app/",
  DOWNLOAD_URL: "https://github.com/prodypanda/ivra-refill/releases/latest/download/ivra-refill.apk"
};
```

- `WEB_APP_URL` — leave `/app/` for the layout in this guide.
- `DOWNLOAD_URL` — the APK link from step 6.

Re-run `assemble_public.ps1` after editing so `public/` picks up the change.
The QR code is generated automatically from `DOWNLOAD_URL` in the browser.

---

## 8. Deploy to Firebase Hosting

```powershell
npm install -g firebase-tools
firebase login
firebase use --add            # pick your existing Firebase project, alias it "default"
firebase deploy --only hosting
```

You'll get a `*.web.app` URL. Verify:
- `https://YOURPROJECT.web.app/` shows the landing page.
- `https://YOURPROJECT.web.app/app/` loads the web app and reaches the login.

---

## 9. Custom domain: refill.ivra-cosmetics.com

1. Firebase Console → **Hosting → Add custom domain** → `refill.ivra-cosmetics.com`.
2. Firebase shows DNS records to add. Add them at your DNS provider for
   `ivra-cosmetics.com`:
   - Usually a single **A record** `refill` → the IP(s) Firebase gives you, **or**
     a **TXT** record for verification followed by the A records.
3. Wait for verification + SSL issuance (minutes to a few hours). Firebase
   provisions the HTTPS certificate automatically.
4. Done: `https://refill.ivra-cosmetics.com/` (landing) and `/app/` (web app).

> Cloudflare Pages / Netlify instead: add the same subdomain in their dashboard;
> they'll give you a **CNAME** target (e.g. `refill` → `your-site.pages.dev`).

---

## 10. Release checklist (every update)

- [ ] Bump `version:` in `pubspec.yaml` (at least the `+build` number).
- [ ] Rebuild APK (step 3) → upload to a new GitHub Release (step 6).
- [ ] `assemble_public.ps1` (step 4) → `firebase deploy --only hosting` (step 8).
- [ ] Hard-refresh the site and confirm landing + `/app/` login both work.
