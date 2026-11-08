# Call recording plan (website APK only)

## Built: the companion app (accessibility tier)

Instead of a second One Dialer build (the `web` flavor in sections 3 and 6, now dropped), recording lives in a small sideloaded companion, **One Dialer Recorder** (`companion/`, `com.syedarhamraza.onedialer.recorder`, plain Kotlin). The Play app stays the only dialer and keeps its Play updates; it carries no mic permission and no accessibility service, only a `<queries>` entry and `RecorderCompanion.kt`.

- The companion holds `RECORD_AUDIO`, an empty `RecorderAccessibilityService` (the Android 10+ in-call mic exception) and `RecordingService` (microphone foreground service, `MediaRecorder` AAC, sources `VOICE_RECOGNITION` → `VOICE_COMMUNICATION` → `MIC`, the working one saved). Its one screen (`SetupActivity`) sets up the mic, the accessibility service (with Android 13+ "Allow restricted settings") and notifications.
- One Dialer drives it through the companion's exported `RecordingsProvider.call()` (`status`, `start`, `stop`, `list`, `delete`, `deleteAll`, `open`, `share`). Every call checks the caller is `com.syedarhamraza.onedialer` signed with a pinned certificate (`TrustedDialer.CERTS`: upload and debug keys; **add the Play app-signing key before a Play build can use it**). Play re-signs One Dialer, so a signature permission can't work.
- Status changes are a `notifyChange` on the provider's `status` URI; `RecorderCompanion` observes it while calls exist and puts it in `CallManager.snapshot()["recording"]`.
- Start: the call screen's ⋮ › Record, or auto-record (Settings › Call recording › Record all calls, `CallPrefs.autoRecord`) when a call turns active. Nothing records until the consent notice there is accepted (`CallPrefs.recordingConsent`). Stops when no call is active or held, or by the companion itself once the audio mode leaves the call (if One Dialer dies).
- Recordings: `filesDir/recordings/<startMillis>_<number>.m4a` inside the companion (the file name is the index). Play and share go through a `PendingIntent` the companion returns with a FileProvider grant, sent by One Dialer while it's in front.
- Not yet verified on a phone: whether the caller is heard on the earpiece, and whether Android 14+ lets the companion start its microphone service when One Dialer starts it.

Goal (original): a second build of One Dialer, downloaded from the website, that records calls. The Google Play build never contains any recording code or permissions.

## 1. What Android allows

- The clean source, `AudioSource.VOICE_CALL` (both sides, straight from the modem), needs `CAPTURE_AUDIO_OUTPUT`. That permission is `signature|privileged`: only system apps get it. Being the default dialer doesn't grant it, and `adb pm grant` can't either.
- What a sideloaded app can do (how Cube ACR and similar apps work on Android 10+):
  - Record with `VOICE_RECOGNITION` / `VOICE_COMMUNICATION` / `MIC`. Since Android 10, a normal app gets **silence** from the mic while a call is active. Exception: an app with an **enabled accessibility service** is allowed to capture during a call.
  - Your voice is always clear. The other person is clear on speaker; on the earpiece it depends on the phone (some OEMs feed the call downlink into these sources, some don't).
- **Root**, when the device has it (Magisk, or any temp-root the user set up — the app neither performs nor cares how): run the recorder as uid 0, which definitely holds `CAPTURE_AUDIO_OUTPUT`, and use `VOICE_CALL`. The app only asks "is there a usable `su` right now?" — run `su -c id` and look for `uid=0` (presence of a `su` binary is not enough; it can be denied or faked). Never cache it: temp root dies on reboot, so re-check right before each recording. Gate the first probe behind an explicit Settings action (it pops the superuser grant dialog), not app launch.
- **Shizuku** (no root; the user installs the Shizuku app and starts it over Wireless debugging) lets our code run as the `shell` user (uid 2000). Two uses:
  - **Sure:** turn our accessibility service on ourselves (`settings put secure enabled_accessibility_services …`), skipping the manual toggle and Android 13+'s "Allow restricted settings" step.
  - **Unverified, the real win:** a Shizuku *user service* (`Shizuku.bindUserService`) runs our recorder class in a process with shell's identity. If the Shell package holds `CAPTURE_AUDIO_OUTPUT` (believed, not checked on Android 15/16), `AudioRecord` with `VOICE_CALL` records both sides cleanly, like a root recorder.
  - Limits: without root Shizuku stops on every reboot until the user starts it again, so recording must detect that and fall back to the accessibility path. Power-user only; web build only.

So the plan is **default dialer + an accessibility service + `MediaRecorder` with a source fallback list**, with Shizuku `VOICE_CALL` as the preferred source if the spike proves it, and a device spike before building any UI.

## 2. Spike first (1–2 days, throwaway branch)

On the vivo and the Galaxy S25, in a debug build:

1. Add a do-nothing `AccessibilityService` (no event types, `canRetrieveWindowContent=false`).
2. When a call goes `active` in `CallManager`, start a `MediaRecorder` (AAC in `.m4a`, 16 kHz mono is enough), stop on `disconnected`.
3. Try each source in order: `VOICE_CALL` (expect a failure), `VOICE_RECOGNITION`, `VOICE_COMMUNICATION`, `MIC`. Note per phone: does it start, is your voice there, is the caller there on earpiece / on speaker.
4. Check starting it with the call screen hidden (Home pressed) on Android 14+: microphone access is "while-in-use", so a microphone foreground service may refuse to start from the background. Find out whether the bound `InCallService` is enough or recording must start while `InCallActivity` is visible.

5. **Root (2a):** if either phone has root available, confirm `su -c id` returns `uid=0` and the same `VOICE_CALL` recorder started as root captures both sides on the earpiece. This is the surest tier and needs no permission bet.
6. **Shizuku (2b):** check `adb shell dumpsys package com.android.shell | grep CAPTURE_AUDIO_OUTPUT` on both phones. Then add the Shizuku API, bind a user service that runs `AudioRecord(VOICE_CALL)` for 10 s during a call and writes to a file our app can read. Note: does it start (no `SecurityException`, non-silent), are both sides clear on earpiece, does vivo/Samsung block it. Also check the `settings put secure enabled_accessibility_services` route turns our service on.

Write the results in this file. If no source records the caller on the earpiece on either phone, decide before going on whether "records on speaker only" is worth shipping.

## 3. Two build flavors

`android/app/build.gradle`: add a `distribution` flavor dimension.

| | `play` | `web` |
|---|---|---|
| applicationId | `com.syedarhamraza.onedialer` | `com.syedarhamraza.onedialer.web` |
| Recording | no | yes |
| Updates | Play in-app update (today's `update_service.dart`) | site JSON + `PackageInstaller` |
| Extra permissions | none | `RECORD_AUDIO`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`, `REQUEST_INSTALL_PACKAGES` |

- Why a different applicationId: Play re-signs the Play build with Google's app-signing key, the website APK is signed with the upload key, so one can never update over the other. Different ids make that explicit (both can be installed; only one is the default dialer at a time).
- Code and manifest additions live in `android/app/src/web/` (Kotlin + a `AndroidManifest.xml` that merges in the service, the accessibility service and the permissions). `src/main` stays exactly what Play reviews.
- Flutter: `flutter build apk --flavor web --release` / `--flavor play`. `tool/release.ps1` builds both. Debug flavors: `flutter run --flavor web`.
- Firebase: register the `.web` package in the same Firebase project and re-download `google-services.json` (it holds both clients).
- Dart knows what it can do by asking Kotlin: a `getCapabilities` method on `com.syedarhamraza.dialer/telecom` returns `{recording: BuildConfig.FLAVOR == "web"}`. All recording UI hides behind it, so the Play build carries no recording UI either. Keep the method and key names in sync in `CallBridge.kt` and `telecom_bridge.dart`.

## 4. Recording (Kotlin, `src/web`)

- `CallRecorder` (object): listens to `CallManager` (`notifyChanged`). When a call becomes `active` and the auto-record rule matches → start; on `disconnected` (or held, if you want to pause) → stop and save. One recording per call; a conference / swap keeps one file going.
- `RecordingService`: foreground service, `foregroundServiceType="microphone"`, shows "Recording" in the ongoing call notification (reuse `CallNotifications`' channel rather than adding a second notification).
- `RecorderAccessibilityService`: empty; its only job is the Android 10+ capture exception. Settings shows whether it's on and opens `Settings.ACTION_ACCESSIBILITY_SETTINGS` (the user must turn it on; Android 13+ also needs "Allow restricted settings" for sideloaded apps, so the setup screen must explain that step).
- Pick a **capability, not a tool**, at the moment a recording starts, highest tier first:

  ```
  usable root      → VOICE_CALL in a root process      (surest; permission guaranteed)
  Shizuku ready    → VOICE_CALL in the shell user svc  (if spike proves shell holds the perm)
  accessibility on → MediaRecorder from the mic         (your side + caller on speaker)
  none             → recording disabled, setup prompt   (app is still a normal dialer)
  ```

  Write the `VOICE_CALL` recorder class **once**; root and Shizuku launch the same class in different privileged processes (uid 0 vs shell uid 2000). Don't fork it.
- `ShizukuRecorder` (if the spike works): the user service that records `VOICE_CALL`; used when there's no root but Shizuku is running and granted, else the `MediaRecorder` path. Settings shows Shizuku status (not installed / not running / not granted / ready). Adds the Shizuku API dependency to the `web` flavor only.
- Settings shows one "Recording quality" row that resolves to the active tier (Full (root) / Full (Shizuku) / Your side + speaker / Not set up), with a Fix button routing to the next tier down's setup. Same pattern as the call-health check. `none` is a real state (button hidden/disabled), never a crash.
- Source fallback list from the spike, the working source saved per device in prefs so later calls start right away.
- Files: app storage, `filesDir/recordings/<timestamp>_<number>.m4a`. Not shared storage (no extra permission, deleted with the app). Export through a share intent.
- Index: a small JSON or `SharedPreferences` list (`{file, number, startMillis, durationMs, simId}`). Match a call-log row by number + start time within a few seconds; don't write into the call log.
- In-call screen control: a Record / Stop button in the call controls (call engine reads `snapshot().audio.recording` added to `CallManager.snapshot()` — keep that key in sync with `call_info.dart`).

## 5. Flutter UI (shown only when `recording` is true)

- Settings › Call recording: Off / All calls / Unknown numbers / Selected contacts, accessibility status with a Fix button (same pattern as the call health check), storage used, Delete all.
- Call details page: the call's recording row with play / share / delete. Playback: start with the system player via a `FileProvider` content URI (no new dependency). Add an in-app player later only if wanted.
- In-call: the Record toggle above, with the recording time.

## 6. Website updates for the web build

- `tool/release.ps1` writes `one-dialer/web.json` (`versionCode`, `versionName`, `apkUrl`, `sha256`) to `D:\syedarhamraza.github.io` next to `changelog.json`, and copies the APK there (or uploads it to a GitHub release and links that, to keep the site repo small).
- `update_service.dart` gets a second implementation for the web flavor: fetch `web.json`, compare `versionCode`, download the APK, verify its SHA-256, hand it to Android's installer (`PackageInstaller` session, or `ACTION_VIEW` with a content URI). Android checks the signature matches the installed app.
- Never put the signing password anywhere but `android/key.properties`.

## 7. Legal and privacy

- Recording laws differ by country (some need everyone's consent). First enable shows a one-time notice that the user is responsible for consent; optional "Announce recording" beep is a later item.
- `docs/privacy-policy.md`: add a section for the web build (recordings stay on the phone, never uploaded, deleted with the app). Crashlytics must never log file names or numbers from recordings.
- The website download page states it's the same app plus recording, and that it can't be updated from Play.

## 8. Order of work

1. Spike (section 2, including Shizuku 2b) → decide go / speaker-only / no-go, and whether Shizuku `VOICE_CALL` is the preferred source.
2. Flavors + `getCapabilities` (Play build unchanged; check `flutter build apk --flavor play` merged manifest has no new permissions).
3. Recorder + service + accessibility service, manual Record button in the call screen.
4. Settings page and auto-record rules.
5. Recordings on the call details page.
6. Web update channel and `release.ps1`.
7. Privacy policy, website page.
8. Optional: root/privileged `VOICE_CALL` path.

## Tests

- Kotlin JVM test for the auto-record rule (number, contact, unknown) like `BlockRules`.
- Dart test that recording UI is hidden when `recording` is false.
- Release check: `aapt dump permissions` on the Play APK shows no `RECORD_AUDIO` / accessibility service / Shizuku provider.
