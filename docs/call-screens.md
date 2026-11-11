# Call screen presentation

Incoming, dialing, connected, held, conference, private, and ended calls share a
backdrop: `CallBackdrop` paints a soft aurora in hues around the caller's avatar
colour (blue, teal and violet for private, conference and unknown calls) under
black fades at the top and bottom, which ease to an even dim while the keypad is
open. The system wallpaper is not used: `InCallTheme` is an opaque black window
and Flutter runs opaque. (Showing the wallpaper behind a translucent window, blurred
by the compositor, was tried and removed: over the home screen vivo's open
animation showed the home screen or black through the window before the
wallpaper.) Contacts' photos only appear in the header circle.

The layout follows ColorOS 17. For a contact with a photo, the name, number and
status sit at the top on the left with the photo in a plain circle on the right
(no ring or ripple). Everyone else gets them centred, with no circle. The controls follow ColorOS 17: each is milky over the
already-blurred backdrop (no live blur of its own: a per-control `BackdropFilter`
looked the same but re-read the backdrop for every key on every frame), with a brighter glow right on the border and a wider soft
haze inside it (both least along the top, never reaching the centre), a 3D lip along the top edge and a fainter one
along the bottom (`CallBody`). The End
pill is a tomato red (`endRed`) lit from below like the other buttons: a shade
deeper at the top, lighter toward the bottom, with a glow rising from its bottom
edge (`solidBody` + `solidGlow`, shared with Decline, Answer and the Answer flight). Labels are a soft
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

- `call_screen_widgets.dart`: the backdrop, caller header, status line and
  held-call chip.
- `call_controls.dart`: solid action circles (`CallBody`) on the package's `GlassButton` press feel, the audio sheet, and
  `PressScale`.
- `call_control_panel.dart`: the control/keypad morph, DTMF, and the fixed
  bottom row.
- `incoming_controls.dart`: the draggable Answer and Decline balls and the message pill.

## Telecom fields

`CallManager.serialize` adds four fields:

- `formattedNumber` and `location`, from `NumberDisplay.kt`, which uses
  libphonenumber. The location is the caller's country, for every number (domestic
  too), since ColorOS shows a place for every caller.
- `disconnectCode` and `disconnectLabel`, from `DisconnectCause`.

When the last call is removed, its final snapshot stays in `snapshot()` for 2 s
(`isShowingCalls`). This keeps `InCallActivity` open long enough to show "Line
busy · 01:12", "Call declined" and similar before it finishes. The duration
freezes when the call ends. City and carrier lookup are not available: Android's
number geocoder isn't public API.

## Incoming

ColorOS 17 style: Decline (left) and Answer (right) each slide straight up to
act, with a "Decline with SMS" pill underneath. They're finished like
the connected screen: the balls take the End pill's look (the shared bottom-lit
`solidBody`/`solidGlow` finish, a glow that brightens as the drag arms) in End's red
and `answerGreen`, and the pill is a frosted `CallBody` with the same glass
press. The 2-button motion below was measured per frame off a 120 fps ColorOS 17 recording
(`Images/call_animation.mp4`, local only). While one is dragged,
the other button and the pill fade out in a straight line with the ball's height, gone at 75% of
its travel; the other ball also blurs as it goes (up to 8 px, not with call screen effects reduced).

- Release at least `threshold` (96 px) up to act. The ball moves only vertically (sideways is ignored), up to 2.08 diameters, and glows as it arms.
- The 2-button ball eases after the finger (an exponential follow, 30 ms time constant, on a `Ticker`), so it starts softly and glides into the top of its travel. The finger's position, not the trailing ball's, decides whether a release acts. Reduced motion and the 1-button ball follow the finger directly.
- Touching a ball grows it to 111.5% in 120 ms (the 1-button ball to 108%); it settles back on release. Taps never act.
- **Answer → End**: an Answer ball released short of the top
  glides on up to it (170 ms,
  ease-out) and waits there until Telecom connects. Then the session flies it into the End pill
  in 800 ms on three springs: down on stiffness 142 at damping ratio 0.75 (82% of the way at
  200 ms, 3% past the pill at 400 ms, then easing back), across on a critically damped 90 (57% at
  200 ms, no overshoot, so it curves in from above), and circle to pill on a critically damped 290
  (done by about 280 ms). Its green fades out over the first 80 ms and End's red fades in from
  50 ms (half at 110 ms, solid at 330 ms; two stacked layers, not a colour tween, so around
  70 ms the ball is almost see-through), while the
  handset tips over 135° in the first 320 ms. The 1-button ball keeps the glass package's bouncy
  spring over 900 ms (1.1 s swiped up), going straight and softly overshooting its size and place,
  green for the first 14% and red by 43%. The ball wears the End
  pill's finish the whole way (the shared `solidBody`/`solidGlow`, squircle shape), and the
  connected controls fade in over 150 ms as it flies. The real pill stays hidden until it lands.
  If the call never connects, the ball is dropped after 4 s. Answering from the notification, or
  with reduced motion on, skips the flight.
- Anything shorter springs back on `GlassSpring.snappy`, carrying a third of the fling, wobbling at most 8% past rest (never through to the other side). Downward drags give only 16 px.
- Taps never answer or decline.
- A haptic fires when you cross a threshold.
- A cancelled pointer resets the offset before release handling runs.
- While idle, a dash above each button drifts up and fades (staggered). These loops stop while dragging and under reduced motion. Because
  they loop, widget tests pump fixed durations instead of `pumpAndSettle` while
  ringing (or use reduced motion).
- Screen readers activate Answer and Decline directly.
- **1 button** (Settings › Answer buttons, `DialerPrefs.answerStyle == 'one'`; "Answer call" ›
  Swipe down to answer swaps the directions): ColorOS 17's white ball with a dark handset
  (`oneButtonWhite`), `SwipeUpButton` with `onSwipeDown`. Matched frame by frame to a ColorOS 17
  recording: the ball rests about 260 dp above the bottom edge with a green arc on the
  answering side and a red one on the declining side (short arcs as round as the ball itself, which drift away and fade once a cycle like the 2-button dashes until it is touched). It follows the finger like the 2-button
  balls, its colour blending to that side's green or red (toward Decline the handset crossfades into
  the hang-up glyph) and growing as it arms, while the arc it's pulled over fades; it arms after 80 dp.
  Released, it stays where it was let go (no further glide either way) and, once Telecom connects,
  springs from there into End over 900 ms on the glass package's bouncy spring (stretching into the pill,
  overshooting its size and place softly, then settling, turning red, its handset
  crossfading into the hang-up glyph without tipping over) while the connected controls rise in, held back until
  then. Swiping up to answer flies it down into End from where it was let go, the same way,
  over 1.1 s as it has further to come.
  Screen readers get the up
  action as the tap and the down one as a custom action. `IncomingControls` is keyed per call, as
  the cached engine keeps the screen between calls.

## Connected and keypad

Controls crossfade between incoming, connected and ended (350 ms). The header fades in
(450 ms) when the call screen opens.
The header sits slightly above the centre of the space the controls leave.

- **Action circles** (`CallAction`):
  - The frosted `CallBody` finish (milky wash, edge glow lit from below, 3D lips along the top and bottom), shared with keypad keys. Nothing is blurred.
  - Turning an action on grows a white fill out from the icon on the bouncy glass spring (`GlassSpringCurve`). The icon colour animates and the icon crossfades.
  - Unavailable actions (Hold while dialing) show as an outline, not a dim fill.
  - Press feel from the package's `GlassButton.custom`: squeeze, stretch toward the finger and glow. It reads raw pointer events only, so taps, tooltips and semantics stay on the inner `IconButton`.
- **Row**: Mute, Hold, Note (or Merge), Add call.
- **Third slot**: Note on a single call. It opens a floating sheet over the call that saves as you type, so the note survives the other side hanging up. Notes are stored in `DialerPrefs` as `call_note_<number>_<millis>`, and Recents call details show each note under the logged call it was taken during. The slot becomes Merge once two calls can merge.
- **Icons** are 46% of the circle. Dial pad uses `DialPadGlyph`, ColorOS's 3×4 grid of 12 dots (Material's dialpad has 10).
- **End call**: a squircle-ended tomato-red pill, lit from below (`solidBody`), with a soft glow. As on ColorOS 17 it is a little smaller than its row: 90% of the circles' height, centred on them, and 87.5% of the space between Speaker and Dial pad. Its press comes from a `GlassButton.custom` in `GlassButtonStyle.transparent` (the package's glow and stretch, no glass body). Once tapped it draws in to a circle and dims. If Telecom hasn't ended the call within 3 s, it becomes tappable again.
- **Entrance**: when the connected or dialing controls appear, the action row and the bottom row fade and rise 16 px, staggered (520 ms total). Reduced motion skips it.
- **Header** (ColorOS 17):
  - Name 32 px bold, then the number and the city on lines of their own.
  - The status line: small glyphs (HD call, Wi-Fi calling, and on dual-SIM phones a small white outlined SIM card with its slot number) followed by the timer or status as plain white text. No pill or live dot, and no chip row.
  - While dialing, "Calling" fills in its dots.
- **Status chip**: "Muted" shows under the timer. An audio route change shows a 1.5 s chip ("Speaker on", "Bluetooth"). Hold dims the header and pulses "On hold".

The keypad opens on the glass package's smooth spring (`GlassSpring.smooth`, 700 ms,
no overshoot, 1% snap tolerance). Closing uses a 450 ms ease-in-out collapse alongside
the reversed key cascade. Changing direction resumes the current geometry and paint values.

- **Action row**: all four actions fade out together over the first 20% of the keys' clock, shrinking 6%. Closing reverses that same fade and scale as the last keys leave. Opacity and scale update every frame from the shared key clock.
- **Keys**: squircle-ended keys (a superellipse, `bodyPath`, rather than true semicircle ends), three across (ColorOS 17). Each key has its own entrance, as in the ColorOS 17 video: rows arrive bottom-up a beat apart (`* 0 #` first, where the action row was), the middle key of each row leads its neighbours, and each key fades in and floats up 40 px, overshooting its place by about 16% on a bouncier glass spring (`GlassSpring.bouncy(extraBounce: .2)`) before settling, growing from 86%. The keys run on their own steady 650 ms clock (`_keysIn`), not the panel's spring, which does most of its travel at the start. Closing runs the same animation backwards over 450 ms: upper rows leave first, sinking, shrinking and fading, then lower rows follow while the panel collapses smoothly. There is no separate fade or waiting phase. Interrupted transitions resume the current clock value without restarting or jumping. Presses get the same `GlassButton` squeeze and glow.
- **Header**: the avatar folds away. Typed digits replace the
  caller name, and the name becomes the subtitle.
- **Spacing**: with the keypad open, the gap above the bottom row is a little more than the gap between key rows (10 px more; 6 compact). Labels sit in a 32 px box, enough for two lines, so the rows stay close when the keypad is closed.
- **Bottom row**: Speaker, End call and Dial pad never move. Dial pad lights white while the keypad is open, as on ColorOS. Upper
  input is blocked while the panel animates in either direction.
- **Back** closes the keypad.
- **Reduced motion** snaps every transition.

## Verification

The static control wash, glow and rim are rasterized once at device pixel ratio,
then reused while the controls move and scale. Their image is regenerated when
size, radius or pixel ratio changes and disposed with the control. Text, icons and
press feedback remain live. Nothing in the call screen blurs per frame any more:
the per-control backdrop blur was removed, and the backdrop is a painted gradient.

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
