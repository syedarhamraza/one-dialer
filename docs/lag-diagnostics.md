# Lag diagnostics

Beta 5 adds bounded technical diagnostics to answer: which screen/engine stalled, whether completed frames were slow in Dart or raster work, and which operation preceded it. It does not fix or establish the cause of the beta 4 vivo report.

## Signals and limits

- `SevereFrameDelay`: a completed frame with build or raster duration >=700 ms. The last 600 frames provide count, p50/p95/p99/max; normal idle time creates no frames and is not a stall.
- `NativeMainStall`: Android's main-thread heartbeat is >=3 seconds old. A dedicated worker captures up to 64 stack frames.
- `DartStall`: the engine heartbeat is >=3 seconds old while the main heartbeat is healthy. No Dart stack is claimed. Engines that share Android's main thread may instead produce `NativeMainStall`.
- `RenderStall`: Dart is running but a requested frame has not been drawn for >=3 seconds (`hasScheduledFrame` with no new `FrameTiming`): a stuck raster thread or missing vsync, which the other signals miss. Reports include the SoC (`soc`), since the beta 4 vivo freeze was on a MediaTek/Mali phone.
- `UserReportedLag`: Help & feedback's report action. The ID can be copied and sent with feedback.

Automatic checks require a resumed activity, five seconds of startup/resume grace, and no attached native debugger. The watcher stops when no monitored activity is resumed. Reports are suspected stalls, not Android-confirmed ANRs. A process killed before detection or persistence, a raster stall while Dart is also blocked, or a diagnostics worker blocked on disk can leave gaps. Native ANR reporting remains enabled through Crashlytics.

Automatic limits are process-wide, per category: once per ten minutes, at most three per process session. Manual reports have a separate one-minute cooldown. Engine registration and context are separate for `main` and `in_call`; reports retain the originating engine even when replayed by the other engine.

The native worker stores at most 20 incidents / 256 KB of encoded queue data in `noBackupFilesDir/lag-diagnostics/queue`. Records expire after 24 hours and are pruned on reads, startup, and foreground maintenance. Read leases last 60 seconds; acknowledgements happen only after Crashlytics accepts the event locally. Restart after an interrupted acknowledgement may replay an event: use its report ID to identify duplicates. Firebase handles later network upload and its own retention. There is no server-delivery guarantee in the UI.

## Privacy and operation

Only allowlisted screen/action names, timing numbers, effects settings, random report/session IDs, device/app versions and technical stacks are collected. No raw channel arguments, digits, phone numbers, contact IDs/names, messages, or call history. Native sanitization rejects unknown fields and invalid numeric values. Breadcrumbs are bounded to 40 entries per engine. Each report's complete immutable JSON is in Crashlytics Logs; engine-prefixed Keys aid filtering. Reporting failures are contained and do not fail call operations.

Debug builds are off unless `TELEMETRY_IN_DEBUG=true`. Without Firebase initialization, diagnostics do not start and the report action explains unavailability. Offline Firebase SDK acceptance still permits queueing for later delivery. Ordinary production crashes retain their existing classification.

## Verification

Unit checks: `flutter analyze`, `flutter test`, and `android/gradlew.bat :app:testDebugUnitTest`.

Development-only device test (sends synthetic non-fatal reports to Firebase): run `flutter drive --debug -d <serial> --driver=test_driver/lag_diagnostics_driver.dart --target=integration_test/lag_diagnostics_test.dart --dart-define=LAG_DIAGNOSTICS_TEST_HOOKS=true --dart-define=TELEMETRY_IN_DEBUG=true`. Gate the entire command on every SIM being idle, just like any install. It briefly blocks Android and Dart execution; never run during a call. The test uses a dedicated screen and no contacts/call-log content. It writes IDs to `build/lag-diagnostics-results.json`. Restore a normal debug APK afterward, again only when idle.

The `simulate` hooks cannot run in release; native blocking additionally requires a debuggable APK. The synthetic frame hook tests threshold/report delivery; it is not a GPU stress benchmark.

Verify Firebase ingestion separately: in Crashlytics select non-fatal issues and find the generated IDs in Keys/Logs. SDK acceptance alone is not proof of dashboard ingestion. The existing `integration_test/perf_test.dart` measures app scenarios; use profile mode for overhead comparisons, not debug timings. A small diagnostics-only profile benchmark is in `integration_test/lag_overhead_test.dart`.

Release checklist: publish the privacy policy update with beta 5, reconcile Data safety diagnostics declarations, preserve Dart symbols, and inspect both non-fatal issues and Android vitals ANRs. Do not publish test builds.
