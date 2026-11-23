# Guide pictures and videos

Every picture or video on the site's guides (`/guide/` and `/recorder/`) is a slot with an id. Save a capture here named after its slot and the page uses it on the next build; until then the slot shows `placeholder.webp` / `placeholder.mp4` with a "Placeholder" tag.

- **Screenshot:** `<id>.png` (or `.jpg`) straight from the phone. `npm run guide` crops the status and gesture bars, turns it into `<id>.webp` and deletes the original.
- **Recording:** `<id>.mp4`, a few seconds, no sound. Crop and shrink it to 720 wide (see the `ffmpeg` line below). A `<id>.webp` next to it becomes its poster.
- `npm run guide` also lists every slot, ✓ when it has its own capture.
- **No real data:** no real names, numbers or call logs. Use fake contacts and the debug build's Test line (`0300 1234567`).

```
ffmpeg -i in.mp4 -vf "crop=iw:ih-iw*198/1260:0:iw*144/1260,scale=720:-2,fps=30" -an -c:v libx264 -crf 28 -pix_fmt yuv420p -movflags +faststart <id>.mp4
```

## One Dialer (`/guide/`)

| Slot | Capture |
| --- | --- |
| `start-default` | Setup screen: Set as default phone app, and Android's role dialog |
| `settings-health` | Settings with the Needs attention card and its Fix buttons |
| `recents-tap` | Quick calling › Tap a recent call, with its choices open |
| `recents-swipe` | Video: swiping a recent call right to call |
| `sim-settings` | Settings › SIM cards |
| `sim-contact` | A contact's page, choosing its SIM |
| `sim-chooser` | Video: calling with Ask every time, the SIM chooser |
| `keypad-t9` | Video: typing on the keypad, matching contacts appear |
| `keypad-speed-dial` | Settings › Keypad › Speed dial |
| `contacts-index` | Contacts tab: favourites and the A–Z index |
| `contacts-manage` | Contacts ⋮ › Manage contacts |
| `blocking-rules` | Settings › Block & filter |
| `call-incoming` | Incoming call (Test line) on the lock screen |
| `call-controls` | The in-call controls |
| `effects-levels` | Video: switching Reduce visual effects between Full, Reduced and Off |
| `glass-style` | Glass & blur › Glass style |
| `settings-language` | Settings › Language |
| `setup-no-accidents` | Quick calling set to Open details, swipe off |
| `setup-two-sims` | SIM cards set up for work and personal |
| `setup-slow-phone` | Reduce visual effects on Reduced |

## One Recorder (`/recorder/`)

| Slot | Capture |
| --- | --- |
| `rec-setup` | One Recorder's Setup steps |
| `rec-pair` | Video: typing the pairing code into the notification |
| `rec-devoptions` | The Turn off Developer options row |
| `rec-check` | Check now and the last call's result |
| `rec-recordings` | A recording in One Dialer (fake caller) |
| `rec-away-wifi` | Keep recording away from Wi-Fi |
