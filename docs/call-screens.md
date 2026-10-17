# Call screen presentation

Incoming, dialing, connected, held, conference, private, and ended calls share a
photo-led backdrop. A contact photo is decoded small and blurred once into a
90×200 bitmap, which is then scaled to fill the screen. Callers without a photo
get a dark gradient tinted from their avatar colour (`LetterAvatar.colorFor`).
Private, conference and bare-number calls keep a neutral navy. Nothing is
blurred per frame: there's no `BackdropFilter` or live blur. A fixed scrim keeps
white text readable.

`InCallScreen` subscribes to the existing Telecom snapshot stream. Presentation
is split across four files:

- `call_screen_widgets.dart`: the backdrop, caller header, status line, ringing
  halo and held-call chip.
- `call_controls.dart`: action circles with press scale, the audio sheet, and
  `PressScale`.
- `call_control_panel.dart`: the control/keypad morph, DTMF, and the fixed
  bottom row.
- `incoming_controls.dart`: the slide-up answer handle, Message and Decline.

## Telecom fields

`CallManager.serialize` adds four fields:

- `formattedNumber` and `location`, from `NumberDisplay.kt`, which uses
  libphonenumber. The location is the country, and only for foreign numbers.
- `disconnectCode` and `disconnectLabel`, from `DisconnectCause`.

When the last call is removed, its final snapshot stays in `snapshot()` for 2 s
(`isShowingCalls`). This keeps `InCallActivity` open long enough to show "Line
busy · 01:12", "Call declined" and similar before it finishes. The duration
freezes when the call ends. City and carrier lookup are not available: Android's
number geocoder isn't public API.

## Incoming

ColorOS-style: Decline (left) and Answer (right) are each swiped up to act, with a
"Decline with message" pill underneath. Each button follows the finger upward.

- Release past `threshold` (96 px) to act.
- Anything shorter springs back (`SpringSimulation`).
- Taps never answer or decline.
- The button grows and glows as it arms.
- A haptic fires when you cross a threshold.
- A cancelled pointer resets the offset before release handling runs.
- While idle, a dash above each button drifts up and fades (staggered), and rings breathe around
  the avatar. These loops stop while dragging and under reduced motion. Because
  they loop, widget tests pump fixed durations instead of `pumpAndSettle` while
  ringing (or use reduced motion).
- Screen readers activate Answer and Decline directly.

## Connected and keypad

Controls switch between incoming, connected and ended with a 300 ms fade-and-rise.
The header sits slightly above the centre of the space the controls leave.

- **Action circles** (`CallAction`):
  - A painted top-lit gradient with a hairline highlight (`callControlBody`, shared with keypad keys). Nothing is blurred.
  - Turning an action on grows a white fill out from the icon. The icon colour animates and the icon crossfades.
  - Unavailable actions (Hold while dialing) show as an outline, not a dim fill.
  - Press scale.
- **Fourth slot**: Note on a single call. It opens a floating sheet over the call that saves as you type, so the note survives the other side hanging up. Notes are stored in `DialerPrefs` as `call_note_<number>_<millis>`, and Recents call details show each note under the logged call it was taken during. The slot becomes Merge once two calls can merge.
- **End call**: a red gradient pill with a soft glow. Once tapped it draws in to a circle and dims. If Telecom hasn't ended the call within 3 s, it becomes tappable again.
- **Entrance**: when the connected or dialing controls appear, the action row and the bottom row fade and rise 16 px, staggered (520 ms total). Reduced motion skips it.
- **Header**:
  - A thin ring around the avatar.
  - The SIM badge carries the SIM's colour dot.
  - The running timer sits in a pill with a static green live dot. It doesn't pulse, because calls can last an hour.
  - While dialing, the avatar ripples slowly and "Calling" fills in its dots.
- **Status chip**: "Muted" shows under the timer. An audio route change shows a 1.5 s chip ("Speaker on", "Bluetooth"). Hold dims the header and pulses "On hold".

The keypad morph runs on a critically damped spring (`SpringSimulation` with a
1% snap tolerance). Reversing mid-flight keeps its velocity.

- **Action row**: the four actions fade out middle pair first, with a gentle
  10% scale.
- **Keys**: rows cascade bottom-up with the opening panel, rising 24 px from
  85% scale with a soft settle. Pressed keys brighten and shrink to 94%.
- **Header**: the avatar and badges collapse away. Typed digits replace the
  caller name, and the name becomes the subtitle.
- **Spacing**: with the keypad open, the gap above the bottom row equals the gap between key rows.
- **Bottom row**: Speaker, End call and Keypad/Hide keypad never move. Upper
  input is blocked while the panel animates.
- **Back** closes the keypad.
- **Reduced motion** snaps every transition.

## Verification

- `flutter analyze`
- `flutter test` (78 tests, including the call-screen and slide-handle cases)
- `cd android && ./gradlew :app:testDebugUnitTest` (includes `NumberDisplayTest`)
- Render previews with real fonts:
  `flutter test test/in_call_screen_test.dart --plain-name "render One UI call previews" --dart-define=PREVIEW_FONT=<path-to-roboto-regular.ttf>`.
  The PNGs (ringing, tinted, private, active, keypad, compact, landscape) are
  written to `build/call-previews/`.
- Judge animation smoothness on a phone with `flutter run --profile`, never in a
  debug build.
