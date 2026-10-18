# Call screen presentation

Incoming, dialing, connected, held, conference, private, and ended calls share a
photo-led backdrop. A contact with a photo gets the ColorOS 17 poster: the photo
full-screen, softly blurred (sigma 12) and cover-fit (decoded at screen height; the thumbnail stands
in until `ContactsRepository.fullPhoto` loads), under a shade at the top for the
name and a dark band at the bottom behind the controls. As the keypad opens the
poster blurs further (to sigma 28, driven by the keypad's morph) and the
shade eases from a dark bottom band to an even dim, as ColorOS does behind its
dial pad. Callers without a photo
get a static aurora: a dark base with soft colour blobs in hues around their
avatar colour (`LetterAvatar.colorFor`). Private, conference and bare-number
calls get a blue, teal and violet one.

The layout follows ColorOS 17. The name, number and status sit at the top on the
left, with the avatar in a circle on the right (contacts with a photo show it as the poster instead). The controls follow ColorOS 17: each is lightly frosted (the backdrop blurred behind it,
sigma 6, with `BackdropFilter.grouped`, all sharing one read under the panel's
`BackdropGroup`), milky, with a brighter glow right on the border and a wider soft
haze inside it (both least along the top, never reaching the centre), a 3D lip along the top edge and a fainter one
along the bottom (`CallBody`). The End
pill is a tomato red with a gloss across its top half. Labels are a soft
grey-white, 6 px under each circle. Mute always shows the slashed mic. Their motion comes from
`liquid_glass_widgets` (initialised in `inCallMain` only): each sits in a
`GlassButton.custom` with `GlassButtonStyle.transparent`, which gives the
package's squeeze, stretch and glow without a glass surface. Frosted and
refractive glass bodies were tried and dropped; if they come back, note that
premium glass paints nothing once a layer holds more than 16 shapes
(`LiquidGlassBlendGroup.maxShapesPerLayer`), and mid-morph the panel holds 18
controls. The main app's floating
chrome stays OneSpend's, without glass.

`InCallScreen` subscribes to the existing Telecom snapshot stream. Presentation
is split across four files:

- `call_screen_widgets.dart`: the backdrop, caller header, status line, ringing
  halo and held-call chip.
- `call_controls.dart`: solid action circles (`CallBody`) on the package's `GlassButton` press feel, the audio sheet, and
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

ColorOS 17 style: Decline (left) and Answer (right) each slide straight up to
act, with a "Decline with message" pill underneath. They're finished like
the connected screen: the balls take the End pill's look (top-lit gradient,
glossy top half, light rim, a glow that brightens as the drag arms) in End's red
and `answerGreen`, and the pill is a frosted `CallBody` with the same glass
press. While one is dragged,
the other button and the pill fade out as it arms.

- Release at least `threshold` (96 px) up to act. The ball moves only vertically (sideways is ignored), up to 1.3× the threshold, and grows and glows as it arms.
- Touching a ball grows it to 108% (a glass-button press); it settles back on release. Taps never act.
- **Answer → End**: the released Answer ball stays where it was let go until
  Telecom connects. Then the session flies it into the End pill along a curve, as
  on ColorOS: it drops first, then sweeps across (a quadratic Bezier bending
  25% of the way from the straight line toward the corner below the ball, level
  with End), fast at first, slowing into place,
  overshooting about 1% of the trip to the left and a little up, then gently back (850 ms, `Cubic(.2, 1, .25, 1.04)`, a long soft settle so it floats into place). The ball wears the End
  pill's finish the whole way (gradient, gloss, rim, glow, squircle shape) while
  its colour morphs green → orange → End's red, its icon grows to End's size and
  tips over into the hang-up glyph. The real pill stays hidden until it lands. If
  the call never connects, the ball is dropped after 4 s. Answering from the
  notification, or with reduced motion on, skips the flight.
- Anything shorter springs back on `GlassSpring.snappy`, carrying a third of the fling, wobbling at most 8% past rest (never through to the other side). Downward drags give only 16 px.
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
- **Row**: Mute, Hold, Note (or Merge), Add call.
- **Third slot**: Note on a single call. It opens a floating sheet over the call that saves as you type, so the note survives the other side hanging up. Notes are stored in `DialerPrefs` as `call_note_<number>_<millis>`, and Recents call details show each note under the logged call it was taken during. The slot becomes Merge once two calls can merge.
- **Icons** are 46% of the circle. Dial pad uses `DialPadGlyph`, ColorOS's 3×4 grid of 12 dots (Material's dialpad has 10).
- **End call**: a squircle-ended tomato-red gradient pill with a glossy rim and a soft glow. Its press comes from a `GlassButton.custom` in `GlassButtonStyle.transparent` (the package's glow and stretch, no glass body). Once tapped it draws in to a circle and dims. If Telecom hasn't ended the call within 3 s, it becomes tappable again.
- **Entrance**: when the connected or dialing controls appear, the action row and the bottom row fade and rise 16 px, staggered (520 ms total). Reduced motion skips it.
- **Header**:
  - A thin ring around the avatar.
  - The SIM badge carries the SIM's colour dot.
  - The running timer sits in a pill with a static green live dot. It doesn't pulse, because calls can last an hour.
  - While dialing, the avatar ripples slowly and "Calling" fills in its dots.
- **Status chip**: "Muted" shows under the timer. An audio route change shows a 1.5 s chip ("Speaker on", "Bluetooth"). Hold dims the header and pulses "On hold".

The keypad opens on the glass package's smooth spring (`GlassSpring.smooth`, 700 ms,
no overshoot, 1% snap tolerance). Closing uses a 450 ms ease-in-out collapse alongside
the reversed key cascade. Changing direction resumes the current geometry and paint values.

- **Action row**: all four actions fade out together over the first 20% of the keys' clock, shrinking 6%. Closing reverses that same fade and scale as the last keys leave. Opacity and scale update every frame from the shared key clock.
- **Keys**: squircle-ended keys (a superellipse, `bodyPath`, rather than true semicircle ends), three across (ColorOS 17). Each key has its own entrance, as in the ColorOS 17 video: rows arrive bottom-up a beat apart (`* 0 #` first, where the action row was), the middle key of each row leads its neighbours, and each key fades in and floats up 40 px, overshooting its place by about 16% on a bouncier glass spring (`GlassSpring.bouncy(extraBounce: .2)`) before settling, growing from 86%. The keys run on their own steady 650 ms clock (`_keysIn`), not the panel's spring, which does most of its travel at the start. Closing runs the same animation backwards over 450 ms: upper rows leave first, sinking, shrinking and fading, then lower rows follow while the panel collapses smoothly. There is no separate fade or waiting phase. Interrupted transitions resume the current clock value without restarting or jumping. Presses get the same `GlassButton` squeeze and glow.
- **Header**: the avatar and badges collapse away. Typed digits replace the
  caller name, and the name becomes the subtitle.
- **Spacing**: with the keypad open, the gap above the bottom row is a little more than the gap between key rows (10 px more; 6 compact). Labels sit in a 32 px box, enough for two lines, so the rows stay close when the keypad is closed.
- **Bottom row**: Speaker, End call and Dial pad never move. Dial pad lights white while the keypad is open, as on ColorOS. Upper
  input is blocked while the panel animates in either direction.
- **Back** closes the keypad.
- **Reduced motion** snaps every transition.

## Verification

The static control wash, glow and rim are rasterized once at device pixel ratio,
then reused while the controls move and scale. Their image is regenerated when
size, radius or pixel ratio changes and disposed with the control. The frosted
backdrop stays live outside this cache; text, icons and press feedback remain live.

On the V2413, the 2026-10-18 connected-keypad profile traces showed median
`GPURasterizer::Draw` time dropping from 5.37 ms to 4.56 ms and P95 from 8.95 ms
to 8.34 ms. The user also reported smoother toggles. These are individual-device
comparisons, not a guarantee that every frame stays within the 8.33 ms budget.

Profile builds save their VM-service URI to `dialer-vm-service.txt` in the app's
temporary directory, allowing local USB attachment when log discovery fails.
Release builds omit this diagnostic path.

- `flutter analyze`
- `flutter test` (89 tests, including the call-screen and slide-handle cases)
- `cd android && ./gradlew :app:testDebugUnitTest` (includes `NumberDisplayTest`)
- Render previews with real fonts:
  `flutter test test/in_call_screen_test.dart --plain-name "render One UI call previews" --dart-define=PREVIEW_FONT=<path-to-roboto-regular.ttf>`.
  The PNGs (ringing, tinted, private, active, keypad, compact, landscape) are
  written to `build/call-previews/`.
- Judge animation smoothness on a phone with `flutter run --profile`, never in a
  debug build.
