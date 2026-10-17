# Call screen presentation

Incoming, dialing, connected, held, conference, private, and ended calls share a
static navy/teal backdrop with subtle violet shading. Caller photos remain inside
the avatar. The background uses gradients rather than full-screen blur or idle
animation.

`InCallScreen` subscribes to the existing Telecom snapshot stream. Presentation is
split between `call_screen_widgets.dart` (backdrop, caller header, status timer,
held-call chip), `call_controls.dart` (flat action circles and audio sheet),
`call_control_panel.dart` (control/keypad morph, DTMF, fixed bottom row), and
`incoming_controls.dart` (swipe gestures and quick replies). Native Telecom
contracts are unchanged.

Each primary call id gets its own presentation state, preventing keypad input
from carrying across calls. The timer starts explicitly for a connected call and
stops on hold, disconnection, or disposal. DTMF stops on release, cancellation,
keypad dismissal, and disposal. Stale quick-reply selections cannot reject a call
that has already changed state.

Controls remain reachable below independently scrollable caller details. Landscape
uses side-by-side caller details and controls. Audio output and quick replies use
the shared floating modal. Incoming buttons stay anchored with no progress rings;
threshold haptics and release-to-trigger swipes remain available. Cancelled pointers
clear the gesture distance before release handling. Connected controls use flat,
filled circles: Mute, Hold/Resume, Add call, Merge above Speaker, End call, Keypad.
End call has extra bottom clearance on taller portrait screens, with a smaller
gap on compact and landscape layouts.

A single reversible 280 ms controller shrinks and fades the four-action row
back while the keypad rises, scales in, and fades up. The action row does not
slide into digit positions. Panel height and caller-header compaction share that
controller. Whole circles reveal as space opens to avoid clipping their edges.
Speaker and the wide End call pill remain anchored; Keypad becomes Hide keypad.
Upper input is blocked during animation, while the bottom row stays active.
Back and rapid toggles reverse from the current value. Reduced motion snaps
directly to either endpoint. Portrait action circles are 76 px and keypad circles
80 px, with smaller sizes on compact and landscape screens.

## Verification

- `flutter analyze`
- `flutter test` (75 tests, including 16 call-screen cases and 6 swipe cases)
- Render previews with real fonts:
  `flutter test test/in_call_screen_test.dart --plain-name "render One UI call previews" --dart-define=PREVIEW_FONT=<path-to-roboto-regular.ttf>`
- Preview PNGs are local artifacts in `build/call-previews/`.
- Test coverage includes compact 320×568, landscape 700×360, phone portrait
  412×915, 150% text, floating sheets, timer updates, capabilities, DTMF, and
  private/conference/ended states, midpoint geometry, fixed bottom-row positions,
  rapid reversal, reduced motion, and swipe/tone cancellation.
- Previews include connected, keypad, midpoint, compact, and landscape layouts.
- Built the release APK and installed it on V2413 (`10FF1E07ET0001R`).
  Launch smoke check passed; no real call was placed. The temporary debug fake
  phone account was removed. Latest call-state and animation verification uses
  mocked Telecom events and the rendered previews above.
