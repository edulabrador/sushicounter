# Publishing to the Play Store

Progress checklist for getting Sushi Score onto Google Play.

## Done (in the repo)

- [x] **Application ID** set to `dev.edulabrador.sushiscore` (no more `com.example.*`, which Play rejects).
- [x] **App display name** set to "Sushi Score" (`android:label`).
- [x] **Release signing wired up** — `android/app/build.gradle.kts` reads an upload key from
      `android/key.properties`. Without that file it falls back to the debug key so local
      `flutter run --release` still works. Template: `android/key.properties.example`.

## To do

### 1. Generate the upload keystore (you do this — the key must not pass through anyone else)
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Then `cp android/key.properties.example android/key.properties` and fill in the passwords,
alias, and absolute path to the `.jks`. Keep both files backed up somewhere safe and
**out of git** (already gitignored). Losing this key means you can never update the app.

### 2. App icon (still the default Flutter icon)
Add a 1024×1024 PNG and generate all densities:
```yaml
# pubspec.yaml dev_dependencies:
flutter_launcher_icons: ^0.13.1
# then a flutter_launcher_icons: block pointing at the source PNG
```
Run `dart run flutter_launcher_icons`.

### 3. Build the release bundle (Play wants an AAB, not an APK)
```bash
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab
```

### 4. Bump the version before each upload
`pubspec.yaml` → `version: 0.1.0+1` (the `+1` is the versionCode; Play rejects a
reused versionCode).

### 5. Play Console setup (not code)
- [ ] Google Play developer account (one-time $25).
- [ ] Store listing: 512×512 icon, 1024×500 feature graphic, ≥2 phone screenshots, short + full description.
- [ ] **Privacy policy URL** — required even though the app collects nothing. A single
      GitHub Pages page stating "all data is stored locally on your device, nothing is
      collected or transmitted" is enough.
- [ ] Data safety form: declare no data collected / no data shared.
- [ ] Content rating questionnaire.
- [ ] Target audience + content declarations.

### 6. Closed testing requirement (new personal accounts)
Google requires a **closed test with 12+ testers opted in for 14 continuous days**
before a personal developer account can promote an app to production. Plan for this
lead time.
