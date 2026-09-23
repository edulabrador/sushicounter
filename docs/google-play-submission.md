# Google Play submission pack — Sushi Tracker

Current release candidate:
- App name: Sushi Tracker
- Package / application ID: `dev.edulabrador.sushiscore`
- Version name: `0.2.4`
- Version code: `6`
- Target SDK: 36
- Release AAB path: `build/app/outputs/bundle/release/app-release.aab`
- Privacy policy: https://edulabrador.github.io/sushicounter/privacy-policy.html

## Store listing

### App name
Sushi Tracker

### Short description
Count sushi with one tap. Save sessions and track your progress offline.

### Full description
Sushi Tracker is a simple offline counter for sushi and anything else you want to count.

Tap the sushi to add one. Use Undo or long-press to correct a count. See how long your current session has lasted, then end it to save the session.

Review saved sessions in History. Check lifetime totals, averages, best sessions, and trends in Statistics. Your counts stay on your device. No account or ads, and no internet connection is required.

### Suggested category
Tools

## App content declarations

### Ads
No.

### App access
All functionality is available without login, membership, subscription, special credentials, location, or other access restrictions. No reviewer instructions are required.

### Privacy policy
https://edulabrador.github.io/sushicounter/privacy-policy.html

Before submission, open it in an incognito/private browser and confirm that it loads without authentication.

### Data safety
Based on the current release:
- Data collected: No
- Data shared with third parties: No
- Accounts: No
- Analytics: No
- Advertising/tracking: No
- Backend/cloud transmission: No
- Counts, sessions and totals remain on-device.

The release manifest contains AndroidX's app-scoped `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.
It does not request INTERNET, location, contacts, camera, microphone or storage-access runtime permissions.

### Other declarations
- News app: No
- Government app: No
- Financial features: No
- Health features: No
- User-generated/social content: No

## Content rating

The current application itself contains no:
- violence
- sexual content or nudity
- profanity supplied by the app
- gambling or simulated gambling
- controlled-substance promotion
- user-to-user communication
- public user-generated content
- location sharing
- purchases
- ads

Answer the exact IARC questions according to their wording.

## Target audience — EDU DECISION REQUIRED

This depends on product intent, not only code.

Do not select child age groups merely because the application is harmless. Selecting children as a target audience can trigger Google Play Families requirements.

Choose only the age groups the product is genuinely designed and marketed for.

## Pricing — EDU DECISION REQUIRED

Choose Free or Paid in Play Console.

The current app has no billing, subscription, advertising or monetization code.

## Countries / regions — EDU DECISION REQUIRED

Choose the markets where you want the app available.

## Developer contact details — EDU REQUIRED

Enter the public developer/support contact details you want associated with the listing.

The current privacy policy lists:
`labradorsantoseduardo@gmail.com`

## Screenshots

Repository assets already prepared:
- `assets/play-store/store-icon.png`
- `assets/play-store/feature-graphic.png`
- `assets/icon/app_icon.png`

Still needed:
- genuine final-app phone screenshots

Recommended screenshots:
1. Counter at zero
2. Counter with active session and timer
3. History with saved sessions
4. Statistics with trend chart

## Production signing — EDU / LOCAL MACHINE REQUIRED

CI validates release AAB generation with a disposable signing key. Never upload that CI-signed bundle to Play Console.

The production bundle must be signed using the real upload key.

Required local files:
- `android/key.properties`
- private upload `.jks`

On Windows, prefer forward slashes:
`storeFile=C:/Users/Edu/path/upload-keystore.jks`

Run:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Expected file:
`build/app/outputs/bundle/release/app-release.aab`

Never commit or share the keystore/passwords.

## Play App Signing — EDU REQUIRED

Enroll/confirm Play App Signing and upload the production AAB using the proper upload key.

If this package has already existed in Play Console, do not casually replace the original upload key.

## Testing requirement — ACCOUNT DEPENDENT

For personal Google Play developer accounts created after 13 November 2023, Google currently requires a closed test with at least 12 testers continuously opted in for at least 14 days before production access can be requested.

Internal testing is recommended first.

## Final real-device smoke test

After installing the Play-distributed build, verify:
- fresh launch
- add / Undo / long press
- timer
- active-session restoration after restart
- End Session saves once
- History
- Statistics
- delete + Undo
- Lifetime reset protection
- correct app icon/name
- no unexpected permission prompts

## Suggested publication sequence

1. Confirm/create the Play Console app with package `dev.edulabrador.sushiscore`.
2. Confirm version code 6 has never been uploaded. If it has, increment it.
3. Build the production AAB with the real upload key.
4. Upload to Internal testing.
5. Install from Google Play and smoke-test.
6. Complete Store listing.
7. Complete App content declarations.
8. Add genuine screenshots.
9. Configure pricing and countries/regions.
10. If required, run the 12-tester / 14-day closed test.
11. Apply for production access if required.
12. Submit production release for review.

## Already validated by CI

- Dart formatting
- `flutter analyze`
- Android toolchain compatibility
- 55 tests
- web release
- Android debug APK
- signed release AAB with disposable signing
- package/version/target SDK
- release permissions
- 64-bit ABIs
- 16 KB ELF/page alignment
