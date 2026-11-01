# Releasing One Dialer on Google Play

Application id `com.syedarhamraza.onedialer` (can't change once on Play). The Kotlin namespace stays `com.syedarhamraza.dialer`.

## One-time setup

1. **Upload key** (keep it and its passwords safe, outside the repo):
   ```bash
   keytool -genkey -v -keystore C:/Users/YOU/keys/onedialer-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Copy `android/key.properties.example` to `android/key.properties` and fill it in. Without it, release builds are signed with the debug key; `flutter build` allows that, the release script refuses.
2. **Play App Signing**: accept it when creating the app (Google holds the app signing key, so a lost upload key can be reset).
3. **Privacy policy**: `docs/privacy-policy.md` is published by the website repo ([syedarhamraza.github.io](https://github.com/syedarhamraza/syedarhamraza.github.io), `content/one-dialer-privacy-policy.md`) at `AppInfo.privacyPolicyUrl`. After changing the policy, copy it there and push.
4. **Firebase Crashlytics**: Firebase project for One Dialer, Android app `com.syedarhamraza.onedialer`, `google-services.json` in `android/app/` (committed; it holds no secrets). Without the file the Gradle plugins are skipped and the app runs with crash reporting off. Run `npx firebase-tools login` once so the release script can upload symbols.

## Versioning

`pubspec.yaml` holds it: `MAJOR.MINOR.PATCH[-alpha.N|-beta.N]+CODE`. Users see the name as "1.0.0 Alpha 1" (`AppVersion`, `lib/core/config/app_version.dart`); CODE is the versionCode and goes up on every upload.

| Suffix | Play track |
|---|---|
| `-alpha.N` | Closed testing |
| `-beta.N` | Open testing |
| none | Production |

`test/app_version_test.dart` fails if pubspec and the newest entry in `lib/core/config/changelog.dart` (Settings › Software update › Changelog) differ.

## Each release

Before the first production (non-beta) release, work through [beta-only.md](beta-only.md): it lists what comes out of the app (Performance Monitoring first).

For beta 5 diagnostics, follow [the diagnostics verification guide](lag-diagnostics.md) before uploading. Publish the updated privacy policy and review the Play Data safety declarations for diagnostics/performance data. Filter Crashlytics **non-fatal** issues for `SevereFrameDelay`, `NativeMainStall`, `DartStall`, `RenderStall`, `InputStall`, and `UserReportedLag`; the crash-free release chart is not a lag metric. Do not include the diagnostics integration-test entrypoint or `LAG_DIAGNOSTICS_TEST_HOOKS` in a release command. Version bump, signing, upload, and publishing remain the release workflow below.

From a clean tree on a `release/<version>` branch (main only changes through PRs):

| You want to… | Command |
|---|---|
| First upload (1.0.0-alpha.1 is already in pubspec) | `./tool/release.ps1 -Rebuild` |
| Next alpha | `./tool/release.ps1 -Pre alpha` |
| Move to open beta | `./tool/release.ps1 -Pre beta` |
| Release | `./tool/release.ps1 -Promote` |
| Bug fix after release | `./tool/release.ps1 -Bump patch` |

The script runs analyze and tests, bumps pubspec, adds a Changelog entry and waits for you to write it, builds an obfuscated `app-release.aab`, uploads the Dart symbols to Crashlytics, commits `chore(release): …` and tags `v<name>`. `./tool/release.ps1 -Help` lists every option.

Keep `symbols/<version>/` (git-ignored): it decodes that release's crashes (`flutter symbolize -i trace.txt -d symbols/<version>/app.android-arm64.symbols`; exception messages via `symbols/<version>.obfuscation-map.json`).

Then upload `build/app/outputs/bundle/release/app-release.aab`, push the branch with `git push --follow-tags`, and open the PR. The script also writes the release notes to the website (`public/one-dialer/changelog.json`) for Software update: commit and push the website too.

## Closed testing

1. Play Console › Testing › Closed testing › create a track, add testers by email list or Google Group.
2. Upload the bundle, fill in the forms below, send for review (call-log permissions make review take longer than usual).
3. Once approved, send testers the track's **opt-in link**; each tester accepts it, then installs from Play. Testers are per track: someone on internal testing must opt in again for closed.
4. Make real outgoing and incoming calls on each SIM from the Play-installed build before widening the track.
5. New personal developer accounts need **12 testers opted in for 14 days** of closed testing before Production can be requested.

In-app updates (Settings › Software update) only work on Play-installed builds; `flutter run` and sideloaded APKs say "not installed from Play". Test them with a higher versionCode on the same track.

## Play Console forms

### App content › Permissions declaration (call log / phone)

- **Core functionality:** Default Phone handler (the app is a dialer and asks to be the default phone app on first launch).
- Permissions: `READ_CALL_LOG`, `WRITE_CALL_LOG` (Recents, missed and blocked calls, deleting history), `CALL_PHONE`, `READ_PHONE_STATE` (placing calls, choosing SIMs). `BLUETOOTH_CONNECT` (no form) names the Bluetooth devices in the call's audio menu.
- Video: record a short screen capture of the setup screen → "Set as default" → making a call → Recents. Play asks for one.

### Full-screen intent (`USE_FULL_SCREEN_INTENT`)

Declare **"Calling"**: the full-screen intent shows incoming calls over the lock screen.

### Data safety

- **Data collected:** App info and performance → Crash logs and Diagnostics, plus Device or other IDs (the Firebase installation and app instance IDs) — Crashlytics, plus Performance Monitoring in betas — and App activity → App interactions (Firebase Analytics: opens, sessions, screens; no advertising ID) (Approximate location is *not* collected: Firebase only derives the country from the IP address), *not* linked to the user, not used for ads, collection required.
- **Data shared:** none.
- Calls, call history, contacts and SMS: **not collected** (processed on the device only; nothing leaves it).
- Encrypted in transit: yes (Firebase uses HTTPS). Users can't request deletion of crash logs or usage stats (they contain no personal data; Analytics keeps them 2 months).

### Other

- Category: Communication. Ads: none. Target audience: 13+.
- App icon (512 × 512): `docs/play-icon.png`, rendered with the launcher icons by `python tool/icons/render_icons.py`; re-run it after changing the icon design.
- Feature graphic (1024 × 500) and phone screenshots (1080 × 2160, the bare app): `docs/play/`, rendered from the real screens with made-up contacts and calls by `test/play_store_screenshots_test.dart` (see the file for the command); re-run after UI changes.
- `targetSdk` follows Flutter's default (`flutter.targetSdkVersion`); Play requires the current year's level for new apps and updates.

## Not in this app (by design)

- **Call recording:** Play doesn't allow it for third-party apps, and Android blocks the call audio.
- **Spam caller ID for unknown numbers:** needs a paid data provider; blocking rules and the block list work without one.
