# Contributing to One Dialer

Thanks for helping! This guide takes you from nothing installed to an open pull request. If anything here is unclear or doesn't work for you, that's a bug too: open an issue.

Everyone whose pull request is merged shows up in the README's [Contributors](README.md#contributors) section automatically, whether they used an AI assistant or not.

## Ways to help

- **Report a bug.** Use the bug report form. The phone model, Android version and OS skin (One UI, ColorOS, OriginOS, HyperOS...) matter most, because a dialer behaves differently on each phone maker's Android.
- **Translate the app.** No coding needed: see [TRANSLATING.md](TRANSLATING.md).
- **Suggest a feature.** Use the feature request form. Screenshots of how another phone app does it help a lot.
- **Write code.** Read on. For anything bigger than a small fix, open an issue first so we can agree on the approach before you spend time on it.

## 1. What you need

| Tool | Why | Get it |
|---|---|---|
| Flutter (stable) | Builds the app. CI uses the version in [`.github/workflows/ci.yml`](.github/workflows/ci.yml); use the same one if you can. | [flutter.dev/get-started](https://docs.flutter.dev/get-started/install) |
| Android Studio (or just the Android SDK) | The Android build tools and `adb` | [developer.android.com/studio](https://developer.android.com/studio) |
| JDK 17 | Gradle, the Android build system | Comes with Android Studio, or [Adoptium](https://adoptium.net/) |
| Git | Getting the code and sending changes | [git-scm.com](https://git-scm.com/) |
| An Android 10+ phone | Calls only work on a real phone with a SIM. Emulators can only fake calls. | Turn on **Developer options › USB debugging** and plug it in |

Check that everything is found:

```bash
flutter doctor
adb devices
```

`flutter doctor` should show green ticks for Flutter and the Android toolchain, and `adb devices` should list your phone.

## 2. Get the code

1. Click **Fork** at the top of the [repository page](https://github.com/syedarhamraza/one-dialer) to make your own copy.
2. Clone your fork and switch to the current beta branch (the repository's default branch, `beta/<n>`):

   ```bash
   git clone https://github.com/<your-username>/one-dialer.git
   cd one-dialer
   flutter pub get
   ```

## 3. Run it on your phone

```bash
flutter run
```

Things to know before the first run:

- **If you have One Dialer from Google Play, uninstall it first.** Your build is signed with your own debug key, so Android won't install it over the Play version. Uninstalling erases its settings and call notes; your contacts and call history are Android's and stay.
- **You don't need Firebase or a signing key.** Without `android/app/google-services.json` crash reporting is simply off, and release builds fall back to debug signing.
- **Make it the default phone app** by tapping **Set** on the first screen. Calls only go through One Dialer once it is the default. To go back, choose your old phone app in Android's **Settings › Apps › Default apps › Phone**.
- **Judge animations in a profile build** (`flutter run --profile`). Debug builds are slow on purpose and drop frames.

## 4. A quick tour of the code

| Folder | What's there |
|---|---|
| `lib/app/` | The app shell: the Calls/Contacts tabs, the floating nav bar, page layout |
| `lib/features/` | One folder per screen: `keypad`, `recents`, `contacts`, `in_call`, `settings`, `blocking`, ... |
| `lib/widgets/` | Shared widgets: glass surfaces, buttons, menus, pages |
| `lib/core/` | Non-UI code: telecom bridge, contacts, preferences, crash reporting |
| `lib/l10n/` | The app's text in each language (`app_en.arb`, `app_it.arb`) |
| `android/app/src/main/kotlin/.../telecom/` | The Kotlin side that talks to Android's call system |
| `companion/` | One Dialer Recorder, the separate call-recording app |
| `test/` | Flutter tests |

Two Flutter engines run in one app: one for the main screens and one, kept warm, for the call screen. [AGENTS.md](AGENTS.md) explains how everything fits together; read its **Architecture** section before changing anything call-related.

## 5. Make your change

1. Create a branch named after what you're doing:

   ```bash
   git switch -c fix/keypad-delete-long-press      # or feat/..., docs/...
   ```

2. Make the change, following the rules below.
3. Run the same checks CI runs:

   ```bash
   flutter analyze
   flutter test
   flutter build apk --debug                          # also compiles the Kotlin layer
   cd android && ./gradlew :app:testDebugUnitTest     # Kotlin unit tests (after one flutter build)
   ```

   For a change in `companion/`: `companion/gradlew -p companion test assembleDebug` (needs `companion/local.properties` with `sdk.dir=<your Android SDK path>`).

4. Try it on your phone.

### Rules the code follows

[AGENTS.md](AGENTS.md) is the full list. These catch new contributors most often:

- **No user-facing text in code.** UI text goes in `lib/l10n/app_en.arb` **and** `lib/l10n/app_it.arb` (English is fine for the Italian file if you don't speak it; say so in the PR) and is read as `context.l10n.key`. `test/l10n_test.dart` checks that both files have the same keys. Notification text goes in `android/app/src/main/res/values*/strings.xml`.
- **The design language is ColorOS 17.** Rounded rectangles use `SquircleBorder`, pages use `OneUISubpage`/`OneUIGroupCard`, and big buttons use `GlowButton`.
- **Follow *Reduce visual effects*.** New blur or glass must look right at Full, Reduced and Off (`OneUIEffectsController`).
- **Keep lists lazy** (`SliverList.builder`). Don't add new full-screen `BackdropFilter` layers.
- **Telecom channel names, methods and keys** must match between `CallBridge.kt`/`CallManager.kt` and `lib/core/telecom/`.
- **Never put real phone numbers or names in code, tests, comments, screenshots or logs.** Use obvious fakes like `0300 1234567` or `555-0100`.

## 6. Testing calls

Calls need a real phone with One Dialer set as the default phone app. To ring the phone without a second one, debug and profile builds include a fake "Test line":

```bash
adb shell telecom set-phone-account-enabled com.syedarhamraza.onedialer/com.syedarhamraza.dialer.debug.FakeCallService fake 0
adb shell am broadcast -n com.syedarhamraza.onedialer/com.syedarhamraza.dialer.debug.FakeCallReceiver --es number 03001234567
```

Add `--ez private true` to the second command for a hidden number.

**Never install over the app during a call.** Android hands the call to another dialer or drops it. This only installs when every SIM is idle:

```bash
[ "$(adb shell dumpsys telephony.registry | grep -o 'mCallState=[0-9]' | sort -u)" = "mCallState=0" ] && adb install -r build/app/outputs/flutter-apk/app-debug.apk || echo "CALL IN PROGRESS - not installing"
```

## 7. Open a pull request

1. Commit and push to your fork:

   ```bash
   git add -A
   git commit -m "fix: keep the typed number when the SIM chooser is cancelled"
   git push -u origin fix/keypad-delete-long-press
   ```

2. GitHub shows a **Compare & pull request** button. Make sure the base branch is the current **`beta/<n>`**, not `main` (`main` only moves when a beta ships).
3. Fill in the template. For anything you can see, add before/after screenshots or a short screen recording (with fake numbers).
4. CI (analyze, tests, debug build) must pass. Keep pull requests small and about one thing; they get reviewed faster.

## Vibe coding (building with an AI assistant)

Welcome, even if you've never written Flutter. If you want a feature for yourself or a bug fixed, an AI coding assistant (Claude Code, Codex, Cursor, Copilot...) can do most of the work. [AGENTS.md](AGENTS.md) is written for people and agents alike, and these tools read it automatically.

1. **Say what you'll build.** For anything bigger than a small fix, open a feature request first and tick *I'd like to build this myself*, so we agree on the approach before you spend time on it.
2. **Set up** with sections 1–3 above: the tools, your fork, and `flutter run` working on your phone. Your assistant can help with this too.
3. **Open the project folder in your assistant** and start with a prompt like this:

   ```text
   Read AGENTS.md and CONTRIBUTING.md first. I'm working on my fork of One Dialer.
   I want: <describe the feature or bug, what you expect to happen>.
   Make the smallest change that does it, on a new feat/... or fix/... branch.
   Put any new text in both app_en.arb and app_it.arb.
   Then run flutter analyze, flutter test and flutter build apk --debug,
   and tell me how to install it and what to try on my phone.
   ```

4. **Try it on your phone.** Does it do what you asked? Did anything else break? Tell the assistant what's wrong and repeat. Don't trust "it works" until you've seen it work.
5. **Ask the assistant to explain the diff** in plain words, and read it yourself. You're responsible for every line you submit.
6. **Open the pull request** (section 7). Ask the assistant to fill in the template, then check it. Say which tool you used; it helps the review, and it's not held against you.

Don't paste real phone numbers, contacts or call logs into a prompt, a log or a commit. Work with the `liquid_glass_widgets` package follows that package's own guide; AGENTS.md says where to find it and which of this app's rules come first.

## License

By contributing, you agree that your contribution is licensed under the [GPL-3.0](LICENSE).
