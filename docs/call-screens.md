# Call screen presentation

Incoming, dialing, connected, held, conference, private, and ended calls share a
photo-led backdrop. A contact photo is decoded small and blurred once into a
90×200 bitmap, which is then scaled to fill the screen. Callers without a photo
get a static aurora: a dark base with soft colour blobs in hues around their
avatar colour (`LetterAvatar.colorFor`), so the glass controls have light to bend.
Private, conference and bare-number calls get a blue, teal and violet one. Nothing is
blurred per frame: there's no `BackdropFilter` or live blur. A fixed scrim keeps
white text readable.

The layout follows ColorOS 17. The name, number and status sit at the top on the
left, with the photo in a circle on the right. The controls are liquid glass
(`liquid_glass_widgets`, initialised in `inCallMain` only) at `GlassQuality.premium`
with the package's native frost, tuned to its dark-material values
(`CallGlassLayer.settings`). Premium draws at most 16 shapes per layer
(`LiquidGlassBlendGroup.maxShapesPerLayer`) and paints nothing above that, which
showed as the controls blanking mid-morph. So the upper panel (4 actions + 12
keys, exactly 16) and the bottom row (Speaker, Keypad) each get their own
`CallGlassLayer`, and every circle and key is a grouped `CallGlass` inside one.
Keep any new glass control under that limit. The main app's floating
chrome stays OneSpend's, without glass.

`InCallScreen` subscribes to the existing Telecom snapshot stream. Presentation
is split across four files:

- `call_screen_widgets.dart`: the backdrop, caller header, status line, ringing
  halo and held-call chip.
- `call_controls.dart`: action circles on the package's `GlassButton` press feel, the audio sheet, and
  `PressScale`.
- `call_control_panel.dart`: the control/keypad morph, DTMF, and the fixed
  bottom row.
- `incoming_controls.dart`: the draggable Answer and Decline balls and the message pill.

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

ColorOS 17 style: Decline (left) and Answer (right) each follow the finger
anywhere, with a "Decline with message" pill underneath. While one is dragged,
the other button and the pill fade out as it arms.

- Release at least `threshold` (96 px) away, moving upward, to act. Downward drags never arm.
- **Answer → End**: the released Answer ball stays where it was let go until
  Telecom connects. Then the session flies it into the End pill on `GlassSpring.snappy` (a slight overshoot),
  stretching from a circle to a stadium. Its colour goes from green through
  orange to red, and the handset tips over into the hang-up glyph. The real pill
  stays hidden until it lands. If the call never connects, the ball is dropped
  after 4 s. Answering from the notification, or with reduced motion on, skips
  the flight.
- While dragged, a ball stretches like jelly: it elongates along the drag and squashes
  a third as much across it (up to 18%).
- Anything shorter springs back on `GlassSpring.bouncy`.
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

Controls crossfade between incoming, connected and ended (350 ms). The header fades in
(450 ms) when the call screen opens.
The header sits slightly above the centre of the space the controls leave.

- **Action circles** (`CallAction`):
  - A painted top-lit gradient with a hairline highlight (`callControlBody`, shared with keypad keys). Nothing is blurred.
  - Turning an action on grows a white fill out from the icon on the bouncy glass spring (`GlassSpringCurve`). The icon colour animates and the icon crossfades.
  - Unavailable actions (Hold while dialing) show as an outline, not a dim fill.
  - Press feel from the package's `GlassButton.custom`: squeeze, stretch toward the finger and glow. It reads raw pointer events only, so taps, tooltips and semantics stay on the inner `IconButton`.
- **Row**: Mute, Hold, Note (or Merge), More. More opens the package's `GlassMenu`, which grows
  out of the More circle (its label stays below),
  with Add call, Audio output, and Note when Merge has taken its slot.
- **Third slot**: Note on a single call. It opens a floating sheet over the call that saves as you type, so the note survives the other side hanging up. Notes are stored in `DialerPrefs` as `call_note_<number>_<millis>`, and Recents call details show each note under the logged call it was taken during. The slot becomes Merge once two calls can merge.
- **End call**: a red gradient pill with a soft glow. Once tapped it draws in to a circle and dims. If Telecom hasn't ended the call within 3 s, it becomes tappable again.
- **Entrance**: when the connected or dialing controls appear, the action row and the bottom row fade and rise 16 px, staggered (520 ms total). Reduced motion skips it.
- **Header**:
  - A thin ring around the avatar.
  - The SIM badge carries the SIM's colour dot.
  - The running timer sits in a pill with a static green live dot. It doesn't pulse, because calls can last an hour.
  - While dialing, the avatar ripples slowly and "Calling" fills in its dots.
- **Status chip**: "Muted" shows under the timer. An audio route change shows a 1.5 s chip ("Speaker on", "Bluetooth"). Hold dims the header and pulses "On hold".

The keypad morph runs on the glass package's smooth spring (`GlassSpring.smooth`,
no overshoot, 1% snap tolerance). Reversing mid-flight keeps its velocity.

- **Action row**: the four actions fade out in place, middle pair first.
- **Keys**: glass stadiums, three across (ColorOS 17). Keys fade in where they sit, rows a beat apart
  bottom-up with the opening panel. Presses get the same `GlassButton` squeeze and glow.
- **Header**: the avatar and badges collapse away. Typed digits replace the
  caller name, and the name becomes the subtitle.
- **Spacing**: with the keypad open, the gap above the bottom row equals the gap between key rows.
- **Bottom row**: Speaker, End call and Keypad/Hide keypad never move. Upper
  input is blocked while the panel animates.
- **Back** closes the keypad.
- **Reduced motion** snaps every transition.

## Verification

- `flutter analyze`
- `flutter test` (89 tests, including the call-screen and slide-handle cases)
- `cd android && ./gradlew :app:testDebugUnitTest` (includes `NumberDisplayTest`)
- Render previews with real fonts:
  `flutter test test/in_call_screen_test.dart --plain-name "render One UI call previews" --dart-define=PREVIEW_FONT=<path-to-roboto-regular.ttf>`.
  The PNGs (ringing, tinted, private, active, keypad, compact, landscape) are
  written to `build/call-previews/`.
- Judge animation smoothness on a phone with `flutter run --profile`, never in a
  debug build.
