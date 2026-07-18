# Publishing to the Play Store

Progress checklist for getting Sushi Tracker onto Google Play.

## Done (in the repo)

- [x] **Application ID** set to `dev.edulabrador.sushiscore` (no more `com.example.*`, which Play rejects).
- [x] **App display name** set to "Sushi Tracker" (`android:label`) — matches the Play Store listing name below.
- [x] **Release signing wired up** — `android/app/build.gradle.kts` reads an upload key from
      `android/key.properties`. Without that file it falls back to the debug key so local
      `flutter run --release` still works. Template: `android/key.properties.example`.
- [x] **Upload keystore generated** — `sushiscore-upload.jks` (kept outside the repo, path in
      `android/key.properties`, both gitignored). **Back up the `.jks` and its password somewhere
      safe** — losing either means you can never push an update to this app again.
- [x] **App icon** — `assets/icon/app_icon.png` (the sushi tray icon), wired through
      `flutter_launcher_icons` in `pubspec.yaml`. Regenerate anytime with `dart run flutter_launcher_icons`.
- [x] **Privacy policy page written** — `docs/privacy-policy.html` (collects nothing, all data
      local, no network). To get the public URL Play requires: in the GitHub repo go to
      **Settings → Pages → Source: Deploy from a branch → main / `/docs`**. The URL will then be
      `https://edulabrador.github.io/sushicounter/privacy-policy.html`.

### Play Store listing copy (use when filling out the Play Console form — not code)
- **App name:** Sushi Tracker
- **Subtitle / short description:** Buffet Counter

## To do

### 1. Build the release bundle (Play wants an AAB, not an APK)
On **Windows**, first enable Developer Mode (Flutter needs symlink support to build
with plugins): Settings → Privacy & security → For developers → Developer Mode = On
(or run `start ms-settings:developers`). Then:
```bash
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab
```

### 2. Bump the version before each upload
`pubspec.yaml` → `version: 0.1.0+1` (the `+1` is the versionCode; Play rejects a
reused versionCode).

### 3. Play Console setup (not code)
- [ ] Google Play developer account (one-time $25).
- [ ] Store listing: 512×512 icon, 1024×500 feature graphic, ≥2 phone screenshots, short + full description.
- [ ] **Privacy policy URL** — page already written (`docs/privacy-policy.html`); just enable
      GitHub Pages (see the Done section) and use the resulting URL.
- [ ] Data safety form: declare no data collected / no data shared.
- [ ] Content rating questionnaire.
- [ ] Target audience + content declarations.

### 4. Closed testing requirement (new personal accounts)
Google requires a **closed test with 12+ testers opted in for 14 continuous days**
before a personal developer account can promote an app to production. Plan for this
lead time.
