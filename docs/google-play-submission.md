# Google Play submission pack — Sushi Tracker

Current release candidate:
- App name: Sushi Tracker
- Package / application ID: `dev.edulabrador.sushiscore`
- Version name: `0.6.0`
- Version code: `11`
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

Review saved sessions in History and note the restaurant and what each meal cost. Check lifetime totals, averages, records, weekly streaks, cost per piece, a trend chart, per-restaurant stats and achievements in Statistics. Long-press the app icon to add a sushi straight away, and keep the screen on while you count.

Back up your history to a file and restore it on another phone. Available in English and Spanish. Your counts stay on your device. No account or ads, and no internet connection is required.

### Suggested category
Tools

## Store listing (es-ES)

### Nombre de la app
Sushi Tracker

### Descripción breve
Cuenta sushi con un toque. Guarda sesiones y sigue tu progreso sin conexión.

### Descripción completa
Sushi Tracker es un contador sencillo y sin conexión para sushi y cualquier otra cosa que quieras contar.

Toca el sushi para sumar uno. Usa Deshacer o mantén pulsado para corregir. Mira cuánto dura la sesión actual y termínala para guardarla.

Revisa tus sesiones en el Historial y anota el restaurante y cuánto costó cada comida. Consulta totales, medias, récords, rachas semanales, coste por pieza, la evolución, estadísticas por restaurante y logros en Estadísticas. Mantén pulsado el icono de la app para sumar un sushi al momento, y deja la pantalla encendida mientras cuentas.

Guarda una copia de tu historial en un archivo y recupérala en otro móvil. Disponible en español e inglés. Tus datos se quedan en tu dispositivo. Sin cuentas ni anuncios, y no necesita internet.

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
- Counts, sessions and totals are stored on-device. The app leaves Android Auto Backup enabled, so they can be included in the user's own Google backup. Check Play's current Data safety guidance on Android backup before answering, and keep the answers consistent with the privacy policy.
- Export/import uses the Android document picker (no storage permission) and only runs when the user asks; the user chooses where the file goes. The app itself sends nothing anywhere.

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
- `assets/play-store/store-icon.png` (512×512)
- `assets/play-store/feature-graphic.png` (1024×500, English) and `assets/play-store/feature-graphic-es.png` (Spanish)
- `assets/play-store/screenshots/en/` and `assets/play-store/screenshots/es/`: five 1080×1920 phone screenshots per language (counter, history, statistics, achievements, light theme)
- `assets/icon/app_icon.png`

The screenshots show the real app UI with sample data, rendered from the web design preview (`tool/design_preview.dart`, script `tool/store/render_screenshots.js`). They have no Android status bar; replace them with on-device captures if you prefer. The feature graphic is rendered from `tool/store/feature_graphic.html` with `tool/store/render_feature_graphic.js`.

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
2. Confirm version code 11 has never been uploaded. If it has, increment it.
3. Build the production AAB with the real upload key.
4. Upload to Internal testing.
5. Install from Google Play and smoke-test.
6. Complete Store listing.
7. Complete App content declarations.
8. Upload the screenshots and feature graphic for each language.
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
