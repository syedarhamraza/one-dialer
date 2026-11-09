# Contributing to One Dialer

Thanks for helping! Small, focused pull requests are easiest to review. For anything big, open an issue first so we can agree on the approach.

## Setup

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug      # also compiles the Kotlin layer
cd android && ./gradlew :app:testDebugUnitTest   # Kotlin unit tests (after one flutter build)
```

You don't need Firebase or a signing key. See the README's "Build from source" section.

## Branches

- `main` only moves when a beta ships.
- Each beta has its own branch, `beta/<n>`. **Open pull requests against the current `beta/<n>` branch**, not `main`.
- Name your branch `feat/...`, `fix/...` or `docs/...`.
- CI (analyze, tests, debug build) must pass before review.

## Rules the code follows

[AGENTS.md](AGENTS.md) is the full guide. The ones that most often catch new contributors:

- **No user-facing text in code.** UI strings go in `lib/l10n/app_en.arb` **and** `lib/l10n/app_it.arb` and are read as `context.l10n.key`. `test/l10n_test.dart` checks that both files have the same keys. Notification text goes in `res/values*/strings.xml`.
- **The design language is ColorOS 17.** Rounded rectangles use `SquircleBorder`, pages use `OneUISubpage`/`OneUIGroupCard`, and big buttons use `GlowButton`.
- **Follow *Reduce visual effects*.** New blur or glass must look right at Full, Reduced and Off (`OneUIEffectsController`).
- **Keep lists lazy** (`SliverList.builder`). Don't add new full-screen `BackdropFilter` layers.
- **Telecom channel names, methods and keys** must match between `CallBridge.kt`/`CallManager.kt` and `lib/core/telecom/`.
- **Never put real phone numbers or names in tests, comments or screenshots.** Use obvious fakes like `0300 1234567` or `555-0100`.

## Testing calls

Calls need a real phone with One Dialer set as the default phone app. To ring the phone without a second one, use a debug or profile build:

```bash
adb shell telecom set-phone-account-enabled com.syedarhamraza.onedialer/com.syedarhamraza.dialer.debug.FakeCallService fake 0
adb shell am broadcast -n com.syedarhamraza.onedialer/com.syedarhamraza.dialer.debug.FakeCallReceiver --es number 03001234567
```

**Never install over the app during a call.** Android hands the call to another dialer or drops it. Check that every SIM is idle first:

```bash
[ "$(adb shell dumpsys telephony.registry | grep -o 'mCallState=[0-9]' | sort -u)" = "mCallState=0" ] && adb install -r build/app/outputs/flutter-apk/app-debug.apk || echo "CALL IN PROGRESS - not installing"
```

Judge animation smoothness in a `--profile` build, never in debug.

## Translations

See [docs/localization.md](docs/localization.md) for how to add a language. Native speakers checking the Italian strings: see [docs/l10n-review.md](docs/l10n-review.md).

## Bug reports

Use the issue template. A dialer behaves differently on each phone maker's Android, so the phone model, Android version and OS skin (One UI, ColorOS, OriginOS, HyperOS...) matter most.

## License

By contributing, you agree that your contribution is licensed under the [GPL-3.0](LICENSE).
