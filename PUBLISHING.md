# Sushi Tracker release checklist

## Done in repository

- Android app label and display branding: **Sushi Tracker**.
- Android `applicationId`: `dev.edulabrador.sushiscore` (unchanged). Android namespace: `dev.edulabrador.sushiscore`.
- Release version in `pubspec.yaml`: `0.2.4+6`. Confirm that version code 6 exceeds the latest code in Play Console before uploading.
- Android uses AGP 9.0.1 with Flutter 3.47.5, compile/target SDK 36, and Kotlin Gradle Plugin 2.3.20. `android.builtInKotlin=false` and `android.newDsl=false` remain enabled for the temporary legacy mode.
- The current resolved Android plugin graph was reviewed for KGP usage. `path_provider_android` delegates Android integration through `jni_flutter`; its Android module applies only `com.android.library` and contains no Kotlin Gradle Plugin usage.
- Built-in Kotlin migration is deferred: AGP 9.0.1 supplies KGP 2.2.10, below Flutter 3.47.5's minimum 2.2.20, and an attempted migration failed the Android debug build. The existing legacy-mode build emits Flutter's future-migration warning; it is non-blocking for this release and must be revisited after a compatible toolchain is available.
- The release merged manifest is checked by CI for package ID, version, target SDK, and permissions. CI also checks arm64/x86_64 native libraries, 16 KB ELF alignment, and APK zip alignment from the generated AAB.
- Release signing requires `android/key.properties` and an existing upload keystore. There is no debug signing fallback. Keep the properties file and keystore out of Git.
- CI generates a disposable JKS and temporary `android/key.properties` only to smoke-test the signed release AAB path. That AAB is not uploaded or retained as a production artifact, and its key must never be used for Play Console.
- Store icon: `assets/play-store/store-icon.png` (512×512). Feature graphic: `assets/play-store/feature-graphic.png` (1024×500). Launcher source: `assets/icon/app_icon.png`.
- Privacy policy source: `docs/privacy-policy.html`, last updated 23 September 2026. The intended public URL is `https://edulabrador.github.io/sushicounter/privacy-policy.html`; its live availability has not been verified from this environment.

## Repository and CI validation

CI is pinned to Flutter 3.47.5 and runs Dart format checking, `flutter pub get`, `flutter analyze`, `flutter analyze --suggestions`, `flutter test`, web release, Android debug APK, and Android release AAB validation. The AAB is inspected for its merged manifest, version/package metadata, permissions, 64-bit ABIs, and 16 KB compatibility. Check the latest Actions run for its exact result.

## CI release AAB versus production AAB

The CI release AAB is signed with an ephemeral disposable test JKS. It proves the AGP release build and bundle validation path works. It is not a production artifact and must not be uploaded to Play Console.

A production AAB still requires Eduardo's private Play upload key in `android/key.properties`. Never create or substitute a new key for an existing Play app, and never commit the key or its passwords.

## External Play Console steps

1. Confirm the app/package exists in Play Console and that `0.2.4+6` uses a version code greater than every uploaded release.
2. Obtain the real upload keystore for this app, populate `android/key.properties`, and build/sign `build/app/outputs/bundle/release/app-release.aab`. Do not generate a replacement key if the package already has an upload key. In Windows `.properties` files, prefer forward slashes for `storeFile`, for example `C:/Users/Edu/path/upload-keystore.jks`; backslashes can be interpreted as escapes. Never commit the real path or passwords.
3. Verify the public privacy-policy URL opens without authentication and points to the current policy. Publish the policy if the URL is unavailable.
4. Capture genuine phone screenshots from the final app build. No screenshots are included in this repository.
5. Create or update the Play Console listing and upload the signed AAB. Review the final app label, icon, feature graphic, screenshots, and descriptions.
6. Complete Data safety, Ads, content rating, target audience, contact details, Play App Signing, and testing-track declarations based on the submitted binary and account.
7. For personal developer accounts created after 13 November 2023, Play currently requires a closed test with at least 12 opted-in testers for 14 continuous days before applying for production access. Check the current Play Console requirements for the account.

## Store listing draft

**App name:** Sushi Tracker

**Short description:** Count sushi with one tap. Save sessions and track your progress offline.

**Full description:**

Sushi Tracker is a simple offline counter for sushi and anything else you want to count.

Tap the sushi to add one. Use Undo or long-press to correct a count. See how long your current session has lasted, then end it to save the session.

Review saved sessions in History. Check lifetime totals, averages, best sessions, and trends in Statistics. Your counts stay on your device. No account or ads, and no internet connection is required.
