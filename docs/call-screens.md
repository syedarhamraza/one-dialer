# Call screen presentation

Incoming, dialing, connected, held, conference, private, and ended calls share a
static navy/teal backdrop with subtle violet shading. Caller photos remain inside
the avatar. The background uses gradients rather than full-screen blur or idle
animation.

`InCallScreen` subscribes to the existing Telecom snapshot stream. Presentation is
split between `call_screen_widgets.dart` (backdrop, caller header, status timer,
held-call chip), `call_controls.dart` (actions, DTMF, End call), and
`incoming_controls.dart` (swipe gestures and quick replies). Native Telecom
contracts are unchanged.

Each primary call id gets its own presentation state, preventing keypad input
from carrying across calls. The timer starts explicitly for a connected call and
stops on hold, disconnection, or disposal. DTMF stops on release, cancellation,
keypad dismissal, and disposal. Stale quick-reply selections cannot reject a call
that has already changed state.

Controls remain reachable below independently scrollable caller details. Landscape
uses side-by-side caller details and controls. Transitions last 200 ms and respect
reduced motion. Audio output and quick replies use the shared floating modal.

## Verification

- `flutter analyze`
- `flutter test` (69 tests, including 12 call-screen cases)
- Render previews with real fonts:
  `flutter test test/in_call_screen_test.dart --plain-name "render One UI call previews" --dart-define=PREVIEW_FONT=<path-to-roboto-regular.ttf>`
- Preview PNGs are local artifacts in `build/call-previews/`.
- Test coverage includes compact 320×568, landscape 700×360, phone portrait
  412×915, 150% text, floating sheets, timer updates, capabilities, DTMF, and
  private/conference/ended states. Existing swipe-threshold tests remain intact.
- The existing debug-only fake phone account was used on V2413 to check the
  connected screen and live timer without placing a real call. The temporary
  account was removed afterward; the delivered build is release mode.
