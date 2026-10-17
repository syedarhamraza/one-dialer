# Releasing Dialer on Google Play

## One-time setup

1. **Upload key** (keep it and its passwords safe):
   ```bash
   keytool -genkey -v -keystore C:/Users/YOU/keys/dialer-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Copy `android/key.properties.example` to `android/key.properties` and fill it in. Without it, release builds are signed with the debug key and Play rejects them.
2. **Play App Signing**: accept it when creating the app (Google holds the app signing key, so a lost upload key can be reset).
3. **Privacy policy**: publish `docs/privacy-policy.md` at the URL in `lib/app/app_info.dart` (`https://syedarhamraza.github.io/dialer/privacy`) before submitting.
4. **Firebase Crashlytics**: add the Android app `com.syedarhamraza.dialer` to a Firebase project and put `google-services.json` in `android/app/`.

## Each release

1. Bump `version:` in `pubspec.yaml` (the number after `+` must go up every upload).
2. `flutter build appbundle --release` → upload `build/app/outputs/bundle/release/app-release.aab`.
3. Start on the **Internal testing** track, install from Play on a real phone, and make real outgoing and incoming calls on each SIM before promoting.

## Play Console forms

### App content › Permissions declaration (call log / phone)

- **Core functionality:** Default Phone handler (the app is a dialer and asks to be the default phone app on first launch).
- Permissions: `READ_CALL_LOG`, `WRITE_CALL_LOG` (Recents, missed and blocked calls, deleting history), `CALL_PHONE`, `READ_PHONE_STATE` (placing calls, choosing SIMs).
- Video: record a short screen capture of the setup screen → "Set as default" → making a call → Recents. Play asks for one.

### Full-screen intent (`USE_FULL_SCREEN_INTENT`)

Declare **"Calling"**: the full-screen intent shows incoming calls over the lock screen.

### Data safety

- **Data collected:** App info and performance → Crash logs and Diagnostics (Crashlytics), *not* linked to the user, not used for ads, collection required.
- **Data shared:** none.
- Calls, call history, contacts and SMS: **not collected** (processed on the device only; nothing leaves it).
- Encrypted in transit: yes (Crashlytics uses HTTPS). Users can't request deletion of crash logs (they contain no personal data).

### Other

- Category: Communication. Ads: none. Target audience: 13+.
- `targetSdk` follows Flutter's default (`flutter.targetSdkVersion`); Play requires the current year's level for new apps and updates.

## Not in this app (by design)

- **Call recording:** Play doesn't allow it for third-party apps, and Android blocks the call audio.
- **Spam caller ID for unknown numbers:** needs a paid data provider; blocking rules and the block list work without one.
