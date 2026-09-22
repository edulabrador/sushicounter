# Publishing Sushi Tracker to Google Play

## Prepared in this repository

- Android application ID: `dev.edulabrador.sushiscore`; app name: **Sushi Tracker**.
- Flutter 3.47.5 targets Android API 36, meeting the current Play requirement for new phone apps.
- Launcher icon: `assets/icon/app_icon.png`.
- Store icon: `assets/play-store/store-icon.png` (512×512); feature graphic: `assets/play-store/feature-graphic.png` (1024×500).
- Privacy policy text: `docs/privacy-policy.html`, with an offline copy accessible from Settings.
- Release builds require an upload keystore. They no longer silently use the debug key.
- CI checks Dart, tests, web release, and an Android debug build.

## Before uploading a release

1. Check whether this package already exists in your Play Console account. If it does, use its existing upload key. Do not create a replacement key without following Play Console's upload-key reset process.
2. Obtain the upload keystore and fill in `android/key.properties` using `android/key.properties.example`. Both the properties file and `.jks` files are ignored by Git. Store an independent backup of the keystore and passwords.
3. Run `flutter pub get` and `flutter build appbundle --release`. The upload file is `build/app/outputs/bundle/release/app-release.aab`. Check its signing certificate before upload. This checkout has no upload keystore, so the release command is expected to stop until step 2 is done.
4. Confirm that `version: 0.2.3+5` in `pubspec.yaml` has a version code greater than every build previously uploaded for this package. Increase it for each subsequent upload.
5. Publish `docs/privacy-policy.html` at a stable public URL and verify that it opens without authentication. GitHub Pages is not enabled for this repository; enabling it currently requires renewing the `gh` CLI login. The intended URL is `https://edulabrador.github.io/sushicounter/privacy-policy.html`. Enter it in Play Console only after it works.
6. Complete the Play Console store listing: use the prepared icon and feature graphic, add at least two genuine phone screenshots, the descriptions below, category and contact details. Review the graphic and icon in the Play Console preview.
7. Complete Data safety, target audience, content rating, and other requested Play Console declarations. The app currently stores counts locally and requests no special permissions; verify the final Android manifest and the declarations against the built AAB.
8. If the account is a personal developer account created after 13 November 2023, complete the required closed test with at least 12 opted-in testers for 14 continuous days before applying for production access.

Flutter's Android artifacts are cached, but this machine has no Android SDK or Java toolchain. The Android AAB has not been built here. The CI Android debug build will check compilation after the changes are pushed; a signed AAB still requires the upload key.

## Store listing draft

**App name:** Sushi Tracker

**Short description:** Count sushi with one tap. Save sessions and track your progress offline.

**Full description:**

Sushi Tracker is a simple, offline counter for sushi and anything else you want to count.

Tap the sushi to add one. Long press to correct a mistake. End a session to save its count and duration.

Review past sessions in your history, see your lifetime totals, and explore your recent trend in Statistics. Your counts stay on your device. No account, ads, or internet connection is required.
