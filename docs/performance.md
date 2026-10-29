# Performance

How to measure the main app's smoothness on a real phone, and what Settings › **Reduce visual effects** changes.

## Visual effects levels

One setting, read in one place (`OneUIEffectsController` in `lib/theme/one_ui_effects.dart`, saved by `DialerPrefs.visualEffects`), switches live:

| Level | Look | Backdrop reads while scrolling Calls |
|---|---|---|
| Full effects (default) | the call glass (cached glow artwork over a sigma-20 blur) and the header's progressive blur (a 49-tap shader), as designed | two: the tabs' group (header, pills, keypad sheet) and the nav bar, plus one per glass bar or menu on screen |
| Reduced effects | One UI glass: OneSpend's flat translucent fill over the blur, no glow artwork (light mode: flat grey, no shadows), flat One UI keypad keys; the header is one even blur that the shader only fades out (1 tap) | **one**, shared by everything (header, pills, keypad sheet, nav bar, glass bars) |
| Effects off | solid One UI fills everywhere (light mode: flat grey, no shadows); the header is its tint only | none |

Colours, shapes, the press glow, springs and page transitions are the same at every level.

The call screen (its own engine) has no backdrop blurs and its own setting, **Call screen effects** (`DialerPrefs.callEffects`, the same three levels). Below full its frosted controls are One UI's flat fill (translucent when reduced, solid when off) instead of the cached glow artwork, which was re-rasterized every frame the keypad morph resized it, and Answer, Decline and End are flat colour with no coloured glow, sheen or rim. The in-call engine reads it in `inCallMain` and on every resume, never awaited, so a ringing call never waits on storage. Read it in widgets with `callFlat(context)` (under `CallEffects`).

## Why blurs cost what they cost

Every `BackdropFilter` group ends the GPU render pass, copies what's drawn so far, blurs it and starts a new pass (Impeller on Vulkan). Adreno GPUs (Snapdragon) are tilers and pay the most per split. Lowering sigma doesn't make a blur cheaper: Impeller downsamples by 4x from sigma ~12 up, so a small sigma (like the menu's mid-grow blur at full effects) is the costliest per pixel. What reduced cuts, and off removes entirely:
- backdrop reads (reduced shares one for the whole page, off has none);
- the header's 49-tap progressive shader (reduced uses one plain blur and a 1-tap fade);
- the call glass artwork, which is re-rasterized (with mask blurs) every frame its size changes: the nav bar's morph, a menu growing. The One UI fill is a plain colour.

Impeller's backend can't be switched in release (`--impeller-backend` is debug/profile only), so measure what ships: Vulkan where the phone supports it.

## Benchmark (profile build, real phone)

`integration_test/perf_test.dart` drives the real app once per level (full, reduced, off), restoring the saved level at the end: Calls scrolling (6 flings each way), call details, ⋮ menu, keypad, tab switches, Contacts scrolling, contact details. For each scenario it records every frame's build, raster and total time (`FrameTiming`) and reports p50/p90/p95/p99/max and the frames over the **display's own** budget (`1000 / refreshRate`: 16.67 ms at 60 Hz, 11.11 at 90, 8.33 at 120).

Before running:
- The app must already be the default phone app on that phone, with real calls and contacts (the test uses the phone's data).
- A profile build installs over a debug build (same signing). Like any install, never during a call.
- Set the phone to its normal refresh rate, plug it in, let it cool, close other apps.

Run (one phone attached; add `-d <serial>` and `adb -s <serial>` with two). Results go to `build/perf/<PERF_DEVICE>.json`:

```bash
[ "$(adb shell dumpsys telephony.registry | grep -o 'mCallState=[0-9]' | sort -u)" = "mCallState=0" ] && PERF_DEVICE=t3x flutter drive --profile --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart || echo "CALL IN PROGRESS - not running"
```

Run it three times per phone and compare the median of each number. Read it like this:
- `raster` p90/p95 over budget, `build` well under: GPU-bound, which blur levels should fix.
- `build` over budget: Dart work (rebuilds, data loading); blur levels won't help; open DevTools' CPU profiler on that scenario.
- `jankyRaster` dropping sharply from full to reduced to off on one phone and not another: that phone's GPU/driver is the bottleneck.

### What the test can't cover

- **Cold start:** `adb shell am force-stop com.syedarhamraza.onedialer` (only with every SIM idle, gated like above), then `adb shell am start -W -n com.syedarhamraza.onedialer/com.syedarhamraza.dialer.MainActivity` and read `TotalTime`. Repeat 5 times.
- **Call screen** (a separate engine): with a debug build's fake Test line (see AGENTS.md), or a profile build and a real call, open DevTools (`flutter attach --profile`, pick the in-call isolate) and record the timeline while ringing, answering and opening the in-call keypad.
- **Memory:** DevTools › Memory on the profile build after scrolling Contacts and Calls a few times; compare levels (Off allocates no blur textures).
- **Throttling:** `adb shell dumpsys thermalservice` before and after a run; a run that starts hot isn't comparable.
- **Quick look:** a local, never committed `showPerformanceOverlay: true` on `DialerApp`'s `MaterialApp` in a profile build shows the UI and raster graphs live.

## Results

No device numbers have been recorded yet. Add each phone's medians here (device, refresh rate, Android version, level, Calls scroll raster p90/p95, janky frames).
