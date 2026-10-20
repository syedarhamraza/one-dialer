# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A custom Android default phone app, **One Dialer** (application id `com.syedarhamraza.onedialer`; the Kotlin namespace and channel names stay `com.syedarhamraza.dialer`). The UI is Flutter; a Kotlin layer under `android/` talks to Android's Telecom framework. Android-only (`--platforms android`); `minSdk 29` (needs `RoleManager.ROLE_DIALER`), `compileSdk 37` (required by `permission_handler_android`).

The UI design is ported from the sibling app OneSpend at `D:\one-spend` (pitch-black Samsung One UI); the reference screenshots of Samsung's Phone app are in `Images/` (local only, git-ignored). OneSpend widgets are copied **verbatim** into `lib/widgets/` (reformatted only) and compile against three stand-ins at the same import paths: `lib/theme/one_ui_effects.dart` (`OneUIEffectsController` returning OneSpend's flat-look values, re-exported by `one_ui_theme.dart`), `lib/core/haptics/haptics.dart`, and `lib/core/speech/voice_input.dart` (no mic yet). To add another OneSpend widget, copy it the same way; don't hand-rewrite.

Floating chrome is OneSpend's, 1:1 (no liquid glass; it was tried and removed). Only the call screen uses `liquid_glass_widgets`, for its ColorOS 17 control motion (see `docs/call-screens.md`); the main app's own buttons (keypad keys, green Call and dialpad buttons, return-to-call banner, contact page pills) press with `PressGlow` (`lib/widgets/press_glow.dart`, the call screen's transparent `GlassButton.custom`: glow and stretch, no shader, so the main engine needs no `LiquidGlassWidgets.initialize`), and the green ones are lit with the call screen's `solidBody`/`solidGlow` (`lib/features/in_call/call_controls.dart`):
- Every floating element (nav bar, header pills, scroll-to-top, action and selection bars, search pill, Cancel | Save, menus, modals) is a verbatim OneSpend widget on `OneUIGlassSurface`, in OneSpend's default flat look (the effects stand-in). Keep them verbatim: re-copy from `D:\one-spend\lib\widgets` rather than editing. Exceptions, restyled on purpose in the call screen's frosted "call glass" (`lib/widgets/call_glass.dart`: backdrop blur + `TintedCallBody` + `PressGlow`): the nav bar pill (`one_ui_floating_nav_bar.dart`), the floating menu (`one_ui_floating_menu.dart`, which grows out of its button on a spring), and the Calls header (`round_header_controls.dart`, `_HeaderControls` in `recents_screen.dart`, which morphs between normal, typing and selecting). Don't re-copy those.
- `MainShell` hosts `OneUIFloatingNavBar` the way OneSpend's `home_screen.dart` does: in a `Stack` (the bar fills its parent's height, so it can't be a `Scaffold.bottomNavigationBar`), under a top `OneUIStatusBarScrim`. The bar always stays visible, including under the keypad sheet while typing. Tab taps use `Haptics.tap()`. While a tab is selecting, the bar morphs into its actions (`navDock` → `dockedContent`, a docked `OneUIFloatingActionBar`).
- Tabs pad with `navBarClearance()` (`lib/app/layout.dart`); bottom bars sit on one baseline (`kFloatingNavBarHeight`, `kNavBarVerticalPadding`).
- Selection mode follows OneSpend: the header's `isSelectionMode` with `OneUISelectionCountPill` (select all) and the cancel pill.

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
flutter run --profile                          # judge smoothness here or in --release, never in debug (JIT)
flutter build apk --release                    # installs today: release falls back to debug signing without key.properties
```

Performance rules that keep the lists smooth: list content goes in lazy slivers (`SliverList.builder`, `DecoratedSliver` for card backgrounds), never a `Column` of all rows. Selection taps update a `ValueNotifier` that only the selection circle (`SelectMark`) listens to. Row structure stays the same in and out of selection mode (`SwipeToCallOrMessage(enabled:)`). Don't add new full-width `BackdropFilter`/`ShaderMask` layers beyond OneSpend's own (each is a save layer every frame).

`OneUIScrollPhysics` accepts drags only when content has a scroll range; do not give it an `AlwaysScrollableScrollPhysics` parent for ordinary pages. This prevents empty/short lists and the fitted keypad from stretching. Long pages keep their end stretch and big-header snap. The shared `placeCall` SIM chooser uses `OneUIFloatingModal.show`, matching the app's floating sheets.

Incoming calls can be tested without a second phone: debug builds include a fake "Test line" (`android/app/src/debug/.../FakeCalls.kt`, never in release). Enable it once, then ring the phone (add `--ez private true` for a hidden number):

```bash
adb shell telecom set-phone-account-enabled com.syedarhamraza.onedialer/com.syedarhamraza.dialer.debug.FakeCallService fake 0
adb shell am broadcast -n com.syedarhamraza.onedialer/com.syedarhamraza.dialer.debug.FakeCallReceiver --es number 03001234567
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
- On vivo (OriginOS), `CallNotifications` adds vivo's Atomic Island extras (`notification.superx.*`) to the ringing notification, so Origin Island shows a card with Decline/Answer; while unlocked it posts on a quieter channel so Android's banner doesn't double it. Answering on the card keeps the call in the island: the ongoing notification becomes an in-call card (Speaker toggle via `CallActionReceiver.ACTION_SPEAKER`, Hang up) and drops CallStyle on vivo, which would add vivo's own call island. vivo drops island updates closer than 10 s apart, so the ongoing one reposts only when its look changes. Other Android 16 phones get a Live Update request instead. The card's images are exported from Flutter by `test/island_buttons_test.dart` into `res/drawable-nodpi/`.
- `InCallActivity` finishes itself when `CallManager` has no calls left.
- The call screen is designed at 420 dp wide (the vivo it was tuned on): `DesignWidth` in `lib/app/in_call_app.dart` lays it out at that width and scales it to the screen (down on a 360 dp Galaxy S25, up to 1.15× on wider phones and tablets; landscape unscaled), so sizes in `lib/features/in_call/` are in vivo dp. `test/in_call_screen_test.dart` checks the proportions at common screen sizes (with `PREVIEW_FONT` it writes `build/call-previews/sizes/`); on a real phone, `adb shell wm density <dpi>` simulates other widths (`wm density reset` after).
- `InCallActivity` uses `InCallTheme`: the system wallpaper shows behind its transparent window and Android 12+ blurs it; `WallpaperBackdrop.kt` reports blur state and wallpaper colours to Flutter (`getWallpaperBackdrop` / `onWallpaperBackdropChanged`).

Main UI: `DialerApp` gates on the dialer role (`SetupScreen` until it's granted; `CallBridge` watches the call log only once `READ_CALL_LOG` arrives with the role, so launching without it doesn't crash), then `MainShell` (`lib/app/main_shell.dart`) shows the Calls (Recents) / Contacts tabs under `OneUIFloatingNavBar`, with `KeypadScreen` as a sheet over Calls (offstage on Contacts). `ContactsRepository.instance` (`lib/core/contacts/`, built on `flutter_contacts`) holds contacts for T9 search (`lib/features/keypad/t9.dart`, unit-tested in `test/t9_test.dart`). Recents reads the system call log through `CallLogSource.kt` (a `ContentObserver` in `CallBridge` pushes `onCallLogChanged`) into `CallLogRepository` (`lib/features/recents/`); grouping and labels are unit-tested in `test/call_log_test.dart`. Missed-call notifications are ours to post as default dialer (`MissedCallReceiver.kt`, built from the call log, never from the exported broadcast's extras). Call-log `simId`s use the same `component|accountId` form as `getSims()`. Contacts (`lib/features/contacts/`) read `ContactsRepository` (`DialerContact` extends T9's entry, numbers deduped by `numberKey`); add, edit and pick use Android's own contact screens via `flutter_contacts`' `native` API. Speed dial and per-contact SIM live in `DialerPrefs` (`shared_preferences`). Every call from a list or details page goes through `placeCall()` in `lib/widgets/place_call.dart`: explicit SIM, else the contact's SIM, else our SIM sheet on dual-SIM "Ask every time". Settings (`lib/features/settings/`) shows a health check from `getCallHealth` (default dialer, notifications, full-screen intent, screening role) with fix buttons. Quick decline messages live in native prefs (`QuickReplies.kt`) so the in-call engine reads the same list. Settings › Software update and its Changelog are ported from OneSpend (`lib/features/updates/`, `lib/core/config/changelog.dart`); Crashlytics starts in both engines (`lib/core/crash_reporting.dart`) and is off without `android/app/google-services.json`. Release: `tool/release.ps1` and `docs/play-release.md` (signing via `android/key.properties`, Play forms) and `docs/privacy-policy.md`; keep both in sync with the manifest's permissions.

Blocking (`lib/features/blocking/`): the block list is Android's system list via `flutter_contacts`' `blockedNumbers` (Telecom rejects those numbers itself); the private/non-contact rules run in `DialerScreeningService.kt`, read from native SharedPreferences (`BlockingPrefs`), with the decision in `BlockRules` (JVM tests: `cd android && ./gradlew :app:testDebugUnitTest`; results land in `build/app/test-results/`). Android only binds the **call-screening role** holder's screening service (being the default dialer isn't enough), so enabling a rule requests that role. SIMs come from `TelecomBridge.getSims()` (real SIM accounts only); the keypad uses the shared SIM chooser when there's no default SIM. The milestone plan (M1 keypad → M6 Play release) is in `C:\Users\trans\.claude\plans\now-how-will-we-fancy-wozniak.md`.

`android/gradle.properties` sets `kotlin.incremental=false`: the pub cache (C:) and the project (D:) are on different drives, and incremental Kotlin compilation of plugins fails across them.

Keypad layout: `KeypadScreen` is a flat, rounded sheet (drag handle, stadium-pill keys, bottom row dialpad | green Call | delete) over the Calls list; the shell's `open` notifier says whether it's up (`tel:` links open it, the missed-call notification closes it). With nothing typed it draws no backdrop, so Calls shows and takes taps; while typing, T9 results fill the space above it. The handle, the dialpad pill, Android Back or scrolling the results hide it, leaving a green dialpad button beside the nav bar; that button or a picked result brings it back, and the typed number is kept. Its `isActive` flag prevents the offstage keypad from intercepting Back. Small/landscape screens scroll inside the sheet.

The keypad has one centered cellular call button. `placeCall` uses the contact's saved SIM or the system default, otherwise shows the shared SIM chooser; its boolean result lets the keypad retain the typed number when selection is cancelled. The sheet's bottom keeps navigation-bar clearance, so the keys sit above the bar and don't shift while typing. A 300 ms slide moves the sheet down and up, honoring reduced-motion settings. The experimental keypad WhatsApp calling integration was removed; existing contact-page WhatsApp chat actions are unchanged. Optional visual review: `flutter test test/keypad_screen_test.dart --dart-define=PREVIEW_FONT=<Flutter SDK>/bin/cache/artifacts/material_fonts/roboto-regular.ttf` writes previews to `build/`.

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
