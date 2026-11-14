# Detecting chipset / GPU class at runtime and where to draw tier cut-offs (Flutter + Impeller, minSdk 29)

## 1. SoC identifiers: Build.SOC_MANUFACTURER / SOC_MODEL (API 31+) and API 29-30 fallbacks

### Takeaway
On API 31+ `Build.SOC_MANUFACTURER` / `Build.SOC_MODEL` (backed by `ro.soc.manufacturer` / `ro.soc.model`) are the cleanest chipset identifiers, but the docs promise only a free-form string, they fall back to `"unknown"`, and I found no published table of vendor values. On API 29-30 use `Build.HARDWARE` / `Build.BOARD` / `ro.board.platform`. Don't count on the `/proc/cpuinfo` "Hardware" line: arm64 kernels removed it.

### Cited Findings
- `SOC_MANUFACTURER`: "The manufacturer of the device's primary system-on-chip". `SOC_MODEL`: "The model name of the device's primary system-on-chip". Both were added in API level 31. Unknown build properties report `Build.UNKNOWN` = `"unknown"`. — [Android Build reference](https://developer.android.com/reference/android/os/Build)
- `HARDWARE` (API 8) is documented as "The name of the hardware (from the kernel command line or /proc)". `BOARD` is "The name of the underlying board, like 'goldfish'". — [Android Build reference](https://developer.android.com/reference/android/os/Build)
- AOSP defines `ro.soc.manufacturer` and `ro.soc.model` as public read-only sysprops. These are the values the Build fields read. — [AOSP SocProperties.sysprop](https://android.googlesource.com/platform/system/libsysprop/+/80600fd/srcs/android/sysprop/SocProperties.sysprop)
- Google's own Play Developer API models a device's SystemOnChip as manufacturer + model, with "Google" / "Tensor" as the examples. That shows the strings are marketing-ish, not part numbers, on at least some devices. — [androidpublisher SystemOnChip.model](https://pub.dev/documentation/googleapis/latest/androidpublisher_v3/SystemOnChip/model.html), [SystemOnChip.manufacturer](https://pub.dev/documentation/googleapis/latest/androidpublisher_v3/SystemOnChip/manufacturer.html)
- Play's device-targeting system-on-chip selector is available only for API 31+. That is consistent with SoC info being reliable only from Android 12 on. — [Play Asset Delivery device targeting (zh-cn)](https://developer.android.com/guide/playcore/asset-delivery/device-targeting?hl=zh-cn)
- Upstream arm64 kernels dropped the system-wide `Hardware`, `Revision` and `Serial` lines from `/proc/cpuinfo`. Android vendor kernels (e.g. msm-5.15) carry that change. Only the per-CPU implementer/variant/part/revision fields remain. — [arm64: Fix up /proc/cpuinfo (msm-5.15)](https://git.evolution-x.org/anierin/msm-5.15/commit/44b82b7700d0), [Arch Linux ARM forum](https://archlinuxarm.org/forum/viewtopic.php?f=65&p=64937&t=14858)

### Inferences
- Practical order: on API 31+ read `SOC_MODEL` and treat `"unknown"`/empty as missing. Then fall back to `Build.HARDWARE`, then `Build.BOARD`. Normalise to lower case and match by prefix/regex (e.g. `^mt67`, `^sm6`, `^ums`, `^s5e`).
- The `/proc/cpuinfo` CPU `part` fields (e.g. 0xd03 = Cortex-A53, 0xd05 = A55, 0xd41 = A78) are a usable fallback for "all little cores" detection on arm64. An 8x A53/A55 chip with no big cores is a strong budget signal.

### Gaps
- No authoritative per-vendor table of actual `ro.soc.model` strings turned up (e.g. whether MediaTek reports `MT6789` vs `MT6789V/CD`, Unisoc `T606` vs `ums512`, Exynos `s5e8835` vs `Exynos 1380`). Collect them from your own users (log `SOC_MANUFACTURER|SOC_MODEL|HARDWARE|BOARD|GL_RENDERER` to Crashlytics custom keys) or with `adb shell getprop ro.soc.model` on test phones.
- I couldn't confirm whether the CDD makes `ro.soc.*` a MUST for devices launching on Android 12+ (the search didn't surface the clause).

## 2. Getting the GPU name (GL_RENDERER, Vulkan deviceName) and its startup cost

### Takeaway
The GPU name is the single best tier signal, and it is exactly what Flutter's Impeller and Unreal use to choose backends and profiles. You can get it from `VkPhysicalDeviceProperties.deviceName` or `glGetString(GL_RENDERER)`. Both need a graphics instance/context, so compute it once, cache it in prefs keyed by `Build.FINGERPRINT`, and don't recompute every launch.

### Cited Findings
- Impeller parses the Vulkan device name to classify GPUs: Adreno model numbers (504…750, X145, X185), names with a `Mali-` prefix (T760…G925, including "Immortalis-G715 a Mali-G715"), and PowerVR series (Rogue, AXE…DXT). — [Impeller driver_info_vk.cc](https://api.flutter.dev/impeller/driver__info__vk_8cc_source.html), [driver_info_vk.h](https://api.flutter.dev/impeller/driver__info__vk_8h_source.html)
- Unreal Engine picks Android device profiles from the GL renderer / GPU family string (plus manufacturer, GL version and Android version), matching with regexes such as `^Mali-T8`. — [UE 4.27 device compatibility](https://docs.unrealengine.com/4.27/en/SharingAndReleasing/Mobile/Android/DeviceCompatibility), [UE Android device profiles](https://dev.epicgames.com/documentation/en-us/unreal-engine/customizing-device-profiles-and-scalability-in-unreal-engine-projects-for-android)

### Inferences
- Cheapest Kotlin route: `vkCreateInstance` + `vkEnumeratePhysicalDevices` + `vkGetPhysicalDeviceProperties` through a few lines of JNI, or (no NDK) an EGL pbuffer context with `EGL14`/`GLES20.glGetString(GL_RENDERER)` on a background thread. It is typically single-digit to tens of ms. That is my estimate, not measured: I found no source. Run it off the main thread on first launch, cache the result, and apply the default before the first frame only if the cache is warm. Otherwise apply it on the next launch or after the probe returns.
- The GL path also gives you `GL_VERSION`. The Vulkan path gives `apiVersion` and `driverVersion`, which Impeller itself uses (see 5) to decide GLES vs Vulkan. The Vulkan path therefore also predicts which Impeller backend the app will get.

### Gaps
- No published measurement of the EGL/Vulkan probe's startup cost on low-end phones.

## 3. Generic signals: Media Performance Class, isLowRamDevice, RAM, CPU frequency, cores

### Takeaway
Media Performance Class is a good "definitely flagship / upper midrange" flag, but 0 (undeclared) covers nearly every budget and many midrange phones, so it can't separate budget from midrange. RAM and core/frequency heuristics (device-year-class) are coarse and outdated. Use them only as a fallback when the GPU/SoC is unknown.

### Cited Findings
- Performance class first appeared in Android 12. A device declares it via `Build.VERSION.MEDIA_PERFORMANCE_CLASS`. The Jetpack `core-performance` library (`DevicePerformance.mediaPerformanceClass`) returns that value, or Play services' value via `core-performance-play-services`. The class is forward-compatible: a device keeps reporting its original class after an OS upgrade. — [Android performance class](https://developer.android.com/topic/performance/performance-class)
- Levels: 30 (Android 11, subset of 31), 31, 33, 34, 35. There is no level 32. "An MPC level of 0 indicates that the MPC level is undefined for the current device and build." MPC 31 covers memory, storage read/write, screen resolution and density. MPC 35 adds graphics requirements (EGL extensions, Vulkan structures). — [Android performance class](https://developer.android.com/topic/performance/performance-class)
- Press coverage of the Android 12 CDD: performance class S requires at least 6 GB RAM and a 12 MP rear camera with 4K30. — [AndroidHeadlines](https://www.androidheadlines.com/2021/10/android-12-cdd-performance-class-requirements.html), [XDA](https://www.xda-developers.com/android-12-cdd-released/)
- Facebook's device-year-class maps RAM, cores and clock to a "year" (e.g. ≤2 GB → 2013, ≤3 GB → 2014, ≤5 GB → 2015, more → 2016). "RAM is a ceiling." The repo was archived on 3 March 2020. — [facebookarchive/device-year-class](https://github.com/facebookarchive/device-year-class)

### Inferences
- MPC ≥ 33 means safe for Full effects (these are flagship/upper-midrange camera and media phones). MPC 0 tells you nothing. Many Chinese-brand midrangers never declare MPC.
- `ActivityManager.isLowRamDevice()` (Android Go) and total RAM ≤ 3 GB are reasonable "force Off" signals. RAM above that doesn't track GPU strength: budget phones in South Asia ship with 6-8 GB on Helio G85/G99 or Unisoc T606/T616.
- Max CPU frequency and core count are near-useless for GPU tier: an 8x A55 at 2.0 GHz and a 2+6 A76/A55 chip at 2.0 GHz look similar but differ by about 2x in GPU.

### Gaps
- Share of devices in the market that declare each MPC level: not found.
- I didn't fetch the `isLowRamDevice` reference page. Its semantics here come from general knowledge (it is set for low-RAM / Android Go builds).

## 4. Existing device-tier approaches (Meta, Play, game engines, ADPF, Firebase)

### Takeaway
No turnkey "UI tier" API exists. The industry pattern (Unreal, Impeller) is a GPU-family regex table with a RAM/OS fallback. Play's device tiers only steer asset delivery. Remote Config can't target by device model, except through a custom signal you send yourself.

### Cited Findings
- Unreal's default Android buckets: Android_High = Adreno 6xx, Mali G72/G76/G77, PowerVR GM9xxx. Android_Medium = Adreno 5xx, Mali T8xx/G71. Android_Low = Adreno 4xx, Mali T6xx/T7xx. Rules are ordered by manufacturer, then from low-end to high-end, with the standard profiles as fallback. (These are UE4-era docs and the buckets are dated.) — [UE 4.27 device compatibility](https://docs.unrealengine.com/4.27/en/SharingAndReleasing/Mobile/Android/DeviceCompatibility), [UE Android device profiles](https://dev.epicgames.com/documentation/en-us/unreal-engine/customizing-device-profiles-and-scalability-in-unreal-engine-projects-for-android)
- Play device targeting (beta): device groups are defined by RAM (`ram-min-bytes`), device models, system features and system-on-chip, in an XML config. Groups match in order, and unmatched devices get the default variant. It is used for asset packs, not as a runtime query. — [Device targeting for asset delivery](https://developer.android.com/guide/playcore/asset-delivery/device-targeting)
- The ADPF thermal API (`getThermalHeadroom`) appeared in Android 11 (API 30), with the NDK version in Android 12. It returns NaN if polled too often. Docs give at most once every 10 s (an older version said once per second). A first value of 0 or NaN means unsupported. It reports thermal headroom, not device class. — [ADPF Thermal API](https://developer.android.com/games/optimize/adpf/thermal?authuser=7)
- Firebase Remote Config conditions list `device.country`, `device.language`, `device.os` and `device.dateTime`, plus app version/build and custom signals. There is no device-model condition. — [Remote Config condition reference](https://firebase.google.com/docs/remote-config/condition-reference)

### Inferences
- A cheap override channel: send `app.customSignal` with the SoC/GPU string, so a Remote Config value can later demote specific chips that turn out janky in the field, without an app release.
- ADPF thermal headroom could later demote Full → Reduced while hot. That is optional, and out of scope for start-up classification.

### Gaps
- I didn't look at Unity's own tiering (`SystemInfo.graphicsDeviceName`, Adaptive Performance) or Play Console's "device catalog" export. The catalog can be downloaded with SoC/GPU/RAM columns for building a table offline, but I didn't verify its current columns.

## 5. Backdrop-blur cost on Impeller, and which devices fall back to OpenGL ES

### Takeaway
This is the most important finding. Current Impeller does not use Vulkan on older Adreno GPUs: it falls back to OpenGL ES on every Adreno ≤ 650 (so all Adreno 6xx except 660+), on PowerVR older than CXT (GE8320 is Rogue, so it falls back), on Huawei Maleoon, and on Samsung Xclipse with Vulkan < 1.3. Mali is never blocklisted. So most budget/midrange Snapdragons (Adreno 610/613/618/619/642L) and PowerVR Helio G35/G37/P35 phones run Impeller GLES, while Mali phones (Helio G85/G99, Dimensity, Unisoc T6xx with Mali-G57) run Impeller Vulkan. Blur cost depends on GPU and on the backend.

### Cited Findings
- `IsKnownBadDriver()` returns true (Vulkan rejected, so OpenGL ES) for:
  1. Pixel 10 PowerVR with driver < 25.1.
  2. `adreno_gpu_ <= AdrenoGPU::kAdreno650`, commented "Fall back to OpenGL ES on older Adreno devices that require additional workarounds".
  3. Vendor Huawei ("Disable Maleoon series GPUs").
  4. Samsung Xclipse with Vulkan API < 1.3.
  5. PowerVR older than CXT.

  No Mali model is blocked. — [Impeller driver_info_vk.cc](https://api.flutter.dev/impeller/driver__info__vk_8cc_source.html)
- Enum order (this defines "≤ 650"): 504, 505, 506, 508, 509, 510, 512, 530, 540, 605, 608, 610, 612, 613, 615, 616, 618, 619L, 619, 620, 630, 640, 642L, 642, 643L, 644, 650, then 660, 663, 675, 680, 685, 690, 695, 702, 710, 720, 725, 730, 732, 735, 740, 750, X145, X185, kUnknown. PowerVR order: kUnknown, Rogue, AXE, AXM, AXT, BXE, BXM, BXS, BXT, CXT, DXT. So Rogue (GE8320/GE8322) and unknown PowerVR are < CXT and fall back. — [driver_info_vk.h](https://api.flutter.dev/impeller/driver__info__vk_8h_source.html)
- The Adreno fallback commit "[Impeller] Fall back to OpenGL ES on older Adreno GPUs" appears in an engine autoroll dated around 31 Oct 2025 (I couldn't confirm the PR number). — search result referencing [flutter/engine](https://github.com/flutter/engine/pull/56591) and the autoroll listing. Treat the date as approximate.
- Impeller's general rules: Vulkan needs Android API ≥ 29, Vulkan ≥ 1.1, and `VK_ANDROID_external_memory_android_hardware_buffer`. Otherwise it uses OpenGL ES. That covers Android ≤ 9, devices without Vulkan (e.g. 64-bit kernel with a 32-bit userspace, some RAM-constrained devices) and Vulkan 1.0 devices. — [Impeller android.md](https://flutter.googlesource.com/mirrors/engine/+/refs/heads/main/impeller/docs/android.md)
- The PowerVR GE8320's Vulkan level is reported inconsistently: 1.1 at Notebookcheck (EN), 1.0 at Notebookcheck (IT), 1.3 for the IP at Imagination. The level actually exposed depends on the driver. Moot now, since Impeller rejects Rogue anyway. — [Notebookcheck GE8320](https://www.notebookcheck.net/PowerVR-GE8320-Graphics-Card-Benchmarks-and-Specs.372646.0.html), [Notebookcheck IT](https://www.notebookcheck.it/Imagination-PowerVR-GE8320.576308.0.html), [Imagination GE8320](https://www.imaginationtech.com/product/ge8320/)
- Bug report: a PowerVR IMG8322 phone (Positivo Q20, Android 10) renders gradients incorrectly only when Impeller falls back from Vulkan to GLES, on Flutter 3.38.3 but not 3.27.4. — [flutter/flutter#179268](https://github.com/flutter/flutter/issues/179268)
- Motorola Edge 30 (Adreno 645L, 144 Hz) on Impeller Vulkan, Flutter 3.22: the reporter saw less fluid scrolling and weaker backdrop-blur fidelity. The maintainer measured simple scrolls at 2-3 ms against a ~7 ms budget, but "Animated complex opacity" dropped frames with stalls in drawable acquisition (GPU-bound). The same scene took ~10 ms on a Pixel 7. Blur fidelity tracked in #149431 (missing mipmap downsample). — [flutter/flutter#148493](https://github.com/flutter/flutter/issues/148493)
- iOS ListView jank with Impeller: the cost split roughly evenly between the rounded-rect blur (exp/sqrt-heavy) and a linear-gradient shader. — [flutter/flutter#148496](https://www.GitHub.com/flutter/flutter/issues/148496)
- A backdrop blur on a small region used to blur the whole backdrop texture. The fix clips before filtering. — [flutter/flutter#126696](https://github.com/flutter/flutter/issues/126696)
- Long-standing report that BackdropFilter blur slows ListView scrolling. — [flutter/flutter#32804](https://github.com/flutter/flutter/issues/32804)
- Impeller fast-scroll jank worse than Skia in profile mode (Flutter 3.32, Samsung). — [flutter/flutter#168788](https://github.com/flutter/flutter/issues/168788)
- Anecdotal: BackdropFilter + ImageFilter.blur flickered badly on a low-end device after Impeller. It was fine on 3.24.5 (pre-Impeller default). — [itsallwidgets forum](https://forum.itsallwidgets.com/t/android-builds-are-being-rejected-by-google/2860?page=2)

### Inferences
- This corrects a project assumption. AGENTS.md says Snapdragon (Adreno) phones pay most because Impeller's Vulkan path splits the render pass at every blur. On a Flutter engine that includes the Oct-2025 Adreno change, phones with Adreno ≤ 650 (e.g. SD 680/685 with Adreno 610, SD 695 with Adreno 619, SD 865 with Adreno 650; my mapping of chips to GPUs, not from the source) run GLES, so that cost model applies only to Adreno 660+/7xx. Verify the app's actual backend with `adb logcat | grep -i impeller` ("Using the Impeller rendering backend (Vulkan/OpenGLES)"), and check whether the pinned Flutter version contains the change.
- Each backdrop read is a full offscreen copy plus downsample and blur passes. On tile-based Mali Bifrost (G52/G57) and PowerVR Rogue, extra render-pass breaks mean tile flushes to memory, and their memory bandwidth (LPDDR4X, single/dual channel) is the bottleneck. The project's lever (one grouped backdrop read per page) is the right one on every GPU family.
- Because the backend differs by family, classify by GPU family + model, not by "Vulkan supported".

### Gaps
- No public benchmark of ms-per-BackdropFilter on Impeller per GPU (Mali-G52/G57, GE8320, Adreno 610/619) was found. Measure it with the project's `showPerformanceOverlay` profile build on 2-3 reference phones.
- I couldn't confirm the exact Flutter stable release that first shipped the Adreno ≤ 650 GLES fallback.

## 6. Benchmark-level thresholds for "smooth 60 fps with several full-screen blurs"

### Takeaway
No source ties a 3DMark/GFXBench score to smooth multi-blur Flutter UI. Anchor the tiers on known chips instead. Helio G99 scores about 1,200 in 3DMark Wild Life and Snapdragon 685 about 640, so a working split is: below ~1,000 Wild Life = budget (Off), ~1,000-3,000 = midrange (Reduced), above ~3,000 = Full. Calibrate on real phones.

### Cited Findings
- Helio G99: 3DMark Wild Life 1,243 (7 fps graphics test) per Nanoreview, and 1,204 (98% stability) in a UL review. Snapdragon 685: 641 (3 fps). — [Nanoreview SD685 vs G99](https://nanoreview.info/en/compare/soc/qualcomm-snapdragon-685-vs-mediatek-helio-g99), [UL benchmarks phone review](https://benchmarks.ul.com/hardware/phone/Xiaomi+Poco+M5+review)
- Notebookcheck rates Helio G99 at ~156% of Unisoc T606's average benchmark result, and Dimensity 7050 at ~125% of the G99's (composite figures, not Wild Life). — [Notebookcheck T606 vs G99](https://www.notebookcheck.net/T606-vs-Helio-G99-vs-T610_14018_14649_14014.247596.0.html), [Notebookcheck G99 vs D7050](https://www.notebookcheck.net/Helio-G99-vs-Dimensity-7050_14649_15080.247596.0.html)
- Helio G35: 8x Cortex-A53 at 2.3 GHz, PowerVR GE8320 at up to 680 MHz. — [XDA](https://www.xda-developers.com/mediatek-helio-g35-g25-chipsets-unveiled-gaming-budget/)

### Inferences (proposed rule set; not sourced, calibrate on device)
- **Budget → Off**: PowerVR Rogue (GE8320/GE8322, Helio G25/G35/G36/G37/P35/A22). Mali-G52 MC2 or less (Helio G85/G88/G80). Mali-G57 MP1 (Unisoc T606/T612/T616, Dimensity 6020-class MP2 borderline). Adreno 504-619 (SD 4xx/6xx incl. 680/685, 480). Any `isLowRamDevice()`, or RAM ≤ 3 GB. Unisoc SC9863A (PowerVR GE8322).
- **Midrange → Reduced**: Mali-G57 MC2 / G68 MC4 / G610 MC2-MC3 / G615 MC2 (Helio G99, Dimensity 6080-7050, Exynos 1280/1330/1380). Adreno 620-650, 642L, 710, 613 upper end (SD 695, 778G, 6 Gen 1, 7s Gen 2). Xclipse with Vulkan < 1.3.
- **Flagship → Full**: Adreno 660+, 720+, 7xx in 8-series. Mali-G710/G715/G720/Immortalis and G610 MC6+ (Dimensity 8100/8200/9000+). Xclipse 920+ with Vulkan 1.3. Apple-class only if MPC ≥ 33.
- **Unknown GPU** → use MPC ≥ 33 → Full, else RAM ≥ 8 GB and a big core present → Reduced, else Off.
- Users can always raise the setting. Default conservatively, since a smooth flat UI beats a janky glass one.

### Gaps
- Wild Life scores for T606, Helio G85 and Dimensity 7050 weren't retrieved from an authoritative source.
- Nothing published maps benchmark scores to Flutter blur frame times.
