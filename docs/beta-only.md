# Beta-only

Things that exist only to test the betas. **Before the first production (non-beta) release**, remove each one in the first table, together with its privacy policy text and Play Data safety entry. When you add something beta-only, give it a row here in the same PR.

## Remove before production

Nothing left: Firebase Performance Monitoring was removed for 1.0.0.

## Decide before production

These were added for the betas but could stay in production if still useful.

| What | Where | To remove |
| --- | --- | --- |
| Settings › Quick calling › Swipe style (Glass button, Flat) and Call button style (Soft tint, Glyph only, Green circle; pickers to compare the designs) | `DialerPrefs.swipeStyle`/`callButtonStyle`, `lib/widgets/swipe_action.dart`, `lib/widgets/row_call_button.dart`, `dialing_settings_screen.dart` | Keep the style testers like, delete the others and both pickers |
| Lag diagnostics (`SevereFrameDelay`, `NativeMainStall`, `DartStall`, `RenderStall`, `InputStall`), sent as Crashlytics non-fatals | `lib/core/diagnostics/lag_diagnostics.dart`, `LagDiagnostics.kt`, `DiagnosticsPolicy.kt`, the `dispatchTouchEvent` overrides in `MainActivity`/`InCallActivity`, the `LagDiagnostics.start` call in `crash_reporting.dart`, `integration_test/lag_*`, `docs/lag-diagnostics.md` | Delete those, then delete the "limited performance diagnostics" paragraphs from the privacy policy and the Diagnostics entry from Data safety (Crashlytics crash logs stay) |
| Settings › Help & feedback › Report lag (`UserReportedLag`) | `lib/features/settings/help_feedback_screen.dart` (uses lag diagnostics) | Goes with lag diagnostics, or keep it on its own |

## Already left out of release builds

For reference: these never reach a release build, so nothing needs doing.

- The fake "Test line" for incoming calls: `android/app/src/debug/` (debug source set only).
- `debug.onedialer.stock` (`CallNotifications.capsuleAndroid`): a system property that gives a vivo or ColorOS phone the stock call notifications, to check them without another phone.
- `TELEMETRY_IN_DEBUG` and `LAG_DIAGNOSTICS_TEST_HOOKS`: `--dart-define`s that are never passed to release commands.
- `integration_test/` entry points: never built by `tool/release.ps1`.
- `showPerformanceOverlay`: a local edit only, never committed.
