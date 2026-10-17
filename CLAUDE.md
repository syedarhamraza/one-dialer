# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A custom Android default phone app (dialer). The UI is Flutter; a Kotlin layer under `android/` talks to Android's Telecom framework. Android-only (`--platforms android`); `minSdk 29` (needs `RoleManager.ROLE_DIALER`), `compileSdk 37` (required by `permission_handler_android`).

The UI design is ported from the sibling app OneSpend at `D:\one-spend` (pitch-black Samsung One UI); the reference screenshots of Samsung's Phone app are in `Images/` (local only, git-ignored). OneSpend widgets are copied **verbatim** into `lib/widgets/` (reformatted only) and compile against three stand-ins at the same import paths: `lib/theme/one_ui_effects.dart` (`OneUIEffectsController` returning OneSpend's flat-look values, re-exported by `one_ui_theme.dart`), `lib/core/haptics/haptics.dart`, and `lib/core/speech/voice_input.dart` (no mic yet). To add another OneSpend widget, copy it the same way; don't hand-rewrite. The one exception is the bottom nav bar: it's `GlassTabBar.bottom` from `liquid_glass_widgets` (shaders pre-warmed and the app wrapped in `main()`; follow `.claude/skills/liquid-glass-widgets/SKILL.md` for any glass work). It floats in a `Stack` in `MainShell`, not a `GlassScaffold`/`Scaffold.bottomNavigationBar`; tabs pad with `navBarClearance()` (`lib/app/layout.dart`), and a tab's selection bar (`navDock`) replaces it while selecting.

## Git workflow

Remote: `https://github.com/syedarhamraza/one-dialer` (private). Never commit to `main` directly: every change gets a branch (`feat/...`, `fix/...`), is pushed, and gets a pull request into `main` via `gh pr create`; merge only after the user approves.

## Commands

```bash
flutter pub get
flutter analyze
flutter test                                   # all tests
flutter test test/widget_test.dart             # one file
flutter test --plain-name "primary call"       # one test by name
flutter build apk --debug                      # also compiles the Kotlin layer
flutter run                                    # needs a real phone with a SIM for calls
```

Incoming calls can be tested without a second phone: debug builds include a fake "Test line" (`android/app/src/debug/.../FakeCalls.kt`, never in release). Enable it once, then ring the phone (add `--ez private true` for a hidden number):

```bash
adb shell telecom set-phone-account-enabled com.syedarhamraza.dialer/com.syedarhamraza.dialer.debug.FakeCallService fake 0
adb shell am broadcast -n com.syedarhamraza.dialer/.debug.FakeCallReceiver --es number 03001234567
```

Call flows only work after the app is set as the default phone app (the home screen's "Set" button). Emulators can only fake calls (`adb emu gsm call <number>`).

## Architecture

Two Flutter engines run in one app, sharing the same Kotlin call state:

- **Main engine** (`main()` in `lib/main.dart` → `DialerApp`) is hosted by `MainActivity`: dial pad, recents, contacts, default-dialer setup.
- **In-call engine** (`inCallMain()`, `@pragma('vm:entry-point')`) is created and cached by `InCallEngine.kt` as soon as Telecom binds `DialerInCallService`, then hosted by `InCallActivity` (lock-screen capable, `singleInstance`). It's pre-warmed so the call screen opens without a cold start, and it outlives the activity (`shouldDestroyEngineWithHost = false`).

Call flow (Kotlin, `android/app/src/main/kotlin/com/syedarhamraza/dialer/`):

- `telecom/DialerInCallService` gets `onCallAdded`/`onCallRemoved` from Telecom. Ringing calls → `CallNotifications` full-screen CallStyle notification (the only reliable way to show UI from the background); other calls → `InCallActivity.start`.
- `telecom/CallManager` (singleton object) is the single source of truth: assigns string ids (`call-N`) to `android.telecom.Call` objects, registers callbacks, and serializes everything to `{calls: [...], audio: {...}}` via `snapshot()`. Every change calls `notifyChanged()` → listeners.
- `CallBridge` is created once per engine and exposes the method channel `com.syedarhamraza.dialer/telecom` plus the event channel `com.syedarhamraza.dialer/call_state` (which streams `CallManager.snapshot()` on every change). Role requests are delegated to `MainActivity` (it owns the activity result); the in-call engine's bridge has no `roleRequester`.
- `telecom/CallActionReceiver` handles the notification's Answer/Decline buttons.
- `InCallActivity` finishes itself when `CallManager` has no calls left.

Main UI: `DialerApp` gates on the dialer role (`SetupScreen` until it's granted or skipped), then `MainShell` (`lib/app/main_shell.dart`) shows the Keypad / Recents / Contacts tabs under `OneUIFloatingNavBar`. `ContactsRepository.instance` (`lib/core/contacts/`, built on `flutter_contacts`) holds contacts for T9 search (`lib/features/keypad/t9.dart`, unit-tested in `test/t9_test.dart`). Recents reads the system call log through `CallLogSource.kt` (a `ContentObserver` in `CallBridge` pushes `onCallLogChanged`) into `CallLogRepository` (`lib/features/recents/`); grouping and labels are unit-tested in `test/call_log_test.dart`. Missed-call notifications are ours to post as default dialer (`MissedCallReceiver.kt`, built from the call log, never from the exported broadcast's extras). Call-log `simId`s use the same `component|accountId` form as `getSims()`. Contacts (`lib/features/contacts/`) read `ContactsRepository` (`DialerContact` extends T9's entry, numbers deduped by `numberKey`); add, edit and pick use Android's own contact screens via `flutter_contacts`' `native` API. Speed dial and per-contact SIM live in `DialerPrefs` (`shared_preferences`). Every call from a list or details page goes through `placeCall()` in `lib/widgets/place_call.dart`: explicit SIM, else the contact's SIM, else our SIM sheet on dual-SIM "Ask every time". Settings (`lib/features/settings/`) shows a health check from `getCallHealth` (default dialer, notifications, full-screen intent, screening role) with fix buttons. Quick decline messages live in native prefs (`QuickReplies.kt`) so the in-call engine reads the same list. Release: `docs/play-release.md` (signing via `android/key.properties`, Play forms) and `docs/privacy-policy.md`; keep both in sync with the manifest's permissions.

Blocking (`lib/features/blocking/`): the block list is Android's system list via `flutter_contacts`' `blockedNumbers` (Telecom rejects those numbers itself); the private/non-contact rules run in `DialerScreeningService.kt`, read from native SharedPreferences (`BlockingPrefs`), with the decision in `BlockRules` (JVM tests: `cd android && ./gradlew :app:testDebugUnitTest`; results land in `build/app/test-results/`). Android only binds the **call-screening role** holder's screening service (being the default dialer isn't enough), so enabling a rule requests that role. SIMs come from `TelecomBridge.getSims()` (real SIM accounts only); the keypad shows one call button per SIM when there's no default SIM. The milestone plan (M1 keypad → M6 Play release) is in `C:\Users\trans\.claude\plans\now-how-will-we-fancy-wozniak.md`.

`android/gradle.properties` sets `kotlin.incremental=false`: the pub cache (C:) and the project (D:) are on different drives, and incremental Kotlin compilation of plugins fails across them.

Dart side: `lib/core/telecom/telecom_bridge.dart` (`TelecomBridge.instance`) mirrors `CallBridge.kt`, and `call_info.dart` parses the snapshot maps (`CallSnapshot`, `CallInfo`, `AudioInfo`). **Channel names, method names, argument keys and the state/route strings must stay in sync** between `CallBridge.kt`/`CallManager.kt` and these two Dart files.

The ringtone is played by Telecom, not the app: `IN_CALL_SERVICE_RINGING` is deliberately left out of `AndroidManifest.xml`. Add it only together with the app's own ringtone and vibration.

Audio routing and `onCallAudioStateChanged` use the `CallAudioState` APIs, which are deprecated on API 34+ but still work. They're kept for minSdk 29 compatibility.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

`graphify` is not on PATH; it's the pipx install at `C:\Users\trans\AppData\Local\pipx\pipx\venvs\graphifyy\Scripts\graphify.exe`. The graph covers project code only; `.agents/` and `.claude/` skill files are deliberately excluded.

Rules:

- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.

## Liquid Glass Widgets

For liquid glass widgets or any liquid glass request refer to skill in `.claude\skills\liquid-glass-widgets\SKILL.md`.
