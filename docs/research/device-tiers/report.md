# Key effect tiers to the GPU, not RAM

The GPU family is the signal that separates a phone that can draw One Dialer's glass from one that can't, and it is easy to read at runtime. On Android 12+ use `Build.SOC_MODEL`. On Android 10–11 use `ro.board.platform` / `Build.HARDWARE`. The proposed cut-offs are:

- **Off:** every PowerVR Rogue GE83xx chip (Helio A22/P22/G25/P35/G35/G36/G37, Unisoc SC9863A), every Mali-G52/G72/G57-MP1 chip (Helio G70–G91, Unisoc T606/T612/T616/T610, Exynos 850/9611), and Adreno 610/612 Snapdragons (SD460/662/665/680/685/675/678).
- **Reduced:** the Mali-G57 MC2 to G68 to G615-MC2 midrange (Helio G96/G99, Dimensity 700/6020/6080/6100+/6300/7020/7050/7300, Exynos 1280/1330/1380) and Adreno 613–710 (SD 4 Gen 1/2, 695, 720G/732G, 778G, 6 Gen 1, 7s Gen 2).
- **Full:** everything from Adreno 720 and Mali-G610 MC6 upward.

This matters because the market is overwhelmingly low-end. MediaTek holds **45–53% of Indian shipments** and Qualcomm about 25–31%, and **41% of Indian phones sell for under $200**. Pakistan and Bangladesh are led by Transsion (Infinix, Tecno, itel), whose entry phones run Unisoc and low-end Helio.

The app's current default can't see any of this. It applies Reduced only when RAM is 4 GB or less, but South Asian budget phones now ship with 6–8 GB on a Helio G85 or Unisoc T606. Its own Crashlytics data already shows the damage: a 715 ms frame on a PowerVR GE8320 phone running Reduced, and RenderStalls on Mali-G57 MC2 and Adreno 710 phones with Liquid glass on.

None of the cut-offs has been measured as Flutter blur frame times on these GPUs; they come from GPU benchmarks and four field data points. Ship them with a remote override and calibrate on two or three reference phones.

## Three GPU families cover almost every phone sold in the region

India's market is concentrated. Counterpoint put **MediaTek at 50% and Qualcomm at 25% in 2023** ([91mobiles](https://www.91mobiles.com/hub/?p=556606)) and **47% / 29% for full-year 2025** ([FoneArena](https://www.fonearena.com/blog/?p=474743)). The remaining ~22% is "Unisoc, Samsung and others", never broken out further ([Beebom](https://gadgets.beebom.com/news/indian-smartphone-market-q2-2025-counterpoint-report)). By brand, vivo (19.3%), Samsung (14.1%) and OPPO (13.3%) led 2025 in a flat 152M-unit market, and the sub-$200 "mass budget" band was still **41% of shipments** ([GSMArena](https://www.gsmarena.com/indian_smartphone_market_remains_flat_in_2025_signals_structural_changes-news-71575.php)).

Pakistan looks different. Transsion held about **44% of units in Q2 2025**, ahead of Xiaomi at 18% and vivo at 17% ([Business Recorder](https://www.brecorder.com/news/40388277)), and Infinix is the largest locally assembled brand ([ProPakistani](https://propakistani.pk/2025/11/25/infinix-overtakes-vgo-tel-to-become-pakistans-biggest-locally-built-phone-brand/amp/)). Bangladesh's IDC Q3 2025 leaders were TECNO (20.4%) and Infinix (18.2%) ([Daily Sun](https://www.daily-sun.com/other/838292/value-for-money-redefines-bangladesh-s-smartphone-market)). Sri Lanka's web traffic is Samsung-led at 33% ([Statcounter](https://gs.statcounter.com/vendor-market-share/mobile-device/sri-lanka)).

**Inferred:** the Transsion skew means far more Unisoc and Helio G25–G85 phones in Pakistan and Bangladesh than in India. No Unisoc share figure exists for any of these countries.

The confirmed best sellers show what the installed base looks like:

| Period | Best seller (confirmed) | Source |
|---|---|---|
| Q1 2021 | Redmi 9A, India's top model | [Marketing Mind](https://marketingmind.in/the-best-selling-smartphones-in-india-q1-2021) |
| Q4 2020 | Transsion's top models: TECNO Spark 6 Air, itel Vision 1, Infinix Smart 4 Plus | [Gizmochina](https://www.gizmochina.com/2021/01/28/india-smartphone-market-q4-2020-counterpoint-research/) |
| 2023 | Galaxy A14 5G, India's top model | [MySmartPrice](https://www.mysmartprice.com/gear/?p=392829) |
| Q1 2024 | Top 5G models: Redmi 13C 5G, vivo T2x, Galaxy A15, vivo Y28 | [91mobiles](https://www.91mobiles.com/hub/indian-smartphone-market-units-shipped-idc-report/) |

Their chips are researcher knowledge, not verified this session: Helio G25, then Helio A22/A25 and SC9863A, then Exynos 1330, then Dimensity 6020/6100+. On that basis the volume floor moved from PowerVR GE83xx (2019–21), to Mali-G52/G57 (2022–24), to G57 MC2 and Adreno 613 (2025–26).

The Android-version spread sets how often the fallback path runs. Statcounter India shows **Android 11 at about 9%** in mid/late 2026 ([Statcounter](https://gs.statcounter.com/android-version-market-share/mobile-tablet/india)). Adding the Android 10 users the snapshot didn't break out, **an estimated 10–20% of Indian devices sit below API 31** (inferred) and have no `Build.SOC_MODEL`. Those are mostly the weakest chips, which makes the fallback path important.

### The chips and their GPUs, ranked

Per-GPU GFXBench offscreen medians from Notebookcheck give the cleanest like-for-like order ([Notebookcheck](https://www.notebookcheck.net/Smartphone-Graphics-Cards-Benchmark-List.149363.0.html)). In Manhattan 3.0 offscreen fps:

| GPU | Manhattan 3.0 (fps) |
|---|---|
| PowerVR GE8300 | 6.6 |
| PowerVR GE8320 | 10.5 |
| Mali-G72 MP3 | 20 |
| Mali-G52 MP2 | 24 |
| Mali-G57 MP2 | 40 |
| Mali-G57 MP3 | 44 |
| Mali-G76 MP4 | 49.5 |
| Mali-G57 MP4 | 51.5 |
| IMG BXM-8-256 | 62 |
| Mali-G68 MP4 | 64.5 |
| Mali-G610 MP3 | 71 |
| Mali-G615 MP2 | 82.5 |
| Mali-G610 MP4 | 106 |
| Mali-G77 MP9 | 115 |
| Mali-G610 MP6 | 145.5 |
| Mali-G615 MP6 | 199.5 |
| Mali-G720 MP7 | 243 |

The gap at the bottom is stark: **the GE8320 in a Helio G35 does roughly a quarter of the work of a G99's G57 MC2.**

Absolute 3DMark points anchor that order:

| Chip | Wild Life | Source |
|---|---|---|
| Unisoc T606/T612/T616 class (Mali-G57 MP1) | ~442 (Unlimited) | [Notebookcheck](https://www.notebookcheck.net/ARM-Mali-G57-MP1-GPU-Benchmarks-and-Specs.588111.0.html) |
| Snapdragon 685 | 641 | [Nanoreview](https://nanoreview.info/en/compare/soc/qualcomm-snapdragon-685-vs-mediatek-helio-g99) |
| Helio G85 (Moto G23) | 746 | [cputronic](https://cputronic.com/soc/mediatek-helio-g88) |
| Helio G99 | ~1,200–1,360 | [UL](https://benchmarks.ul.com/hardware/phone/Xiaomi+Poco+M5+review) |
| Exynos 1380 | ~2,800 | [GeeksDigit](https://www.geeksdigit.com/snapdragon-7-gen-3-vs-exynos-1380-comparison/) |
| Snapdragon 7 Gen 3 | 5,414 | [GeeksDigit](https://www.geeksdigit.com/snapdragon-7-gen-3-vs-exynos-1380-comparison/) |

The Wild Life Extreme pairs agree. The SD695 scores 360 against the SD680's 172 ([nanoreview](https://nanoreview.net/en/soc-compare/qualcomm-snapdragon-695-vs-qualcomm-snapdragon-680)), and the SD 7 Gen 1 scores 857 against the Exynos 1380's 808 ([nanoreview](https://nanoreview.net/en/soc-compare/samsung-exynos-1380-vs-qualcomm-snapdragon-7-gen-1)). Across these pairs Wild Life runs about 3.4× Wild Life Extreme (inferred), so the two scales convert roughly.

## Impeller already splits these phones into two rendering backends

The finding that most changes the cost model is in Impeller's driver table. `IsKnownBadDriver()` rejects Vulkan, so Impeller runs OpenGL ES instead, in these cases ([Impeller driver_info_vk.cc](https://api.flutter.dev/impeller/driver__info__vk_8cc_source.html)):

- **every Adreno at or below 650**, commented "older Adreno devices that require additional workarounds";
- **PowerVR older than CXT**, which includes the Rogue GE8320/GE8322;
- Huawei Maleoon;
- Samsung Xclipse with Vulkan below 1.3.

**No Mali GPU is blocklisted.** In practice, budget Snapdragons (Adreno 610/613/618/619) and PowerVR Helio and SC9863A phones run Impeller GLES, while Mali phones (every Helio G7x–G99, Dimensity and Unisoc T6xx) run Impeller Vulkan. The chip-to-GPU mapping here is researcher knowledge; the blocklist itself is verified from source.

That fallback reportedly landed in an engine roll around late October 2025. The date is approximate, and it's unconfirmed whether the app's pinned Flutter includes it. If it does, **AGENTS.md's note that Adreno phones pay most because Vulkan splits the render pass at every blur now applies only to Adreno 660 and newer.** Check it with `adb logcat | grep -i impeller` on an Adreno 610/619 phone.

Blur cost on Impeller is documented only through bug reports, never per GPU:

- An Adreno 645L phone stalled in drawable acquisition on complex animated opacity, a GPU-bound case ([flutter#148493](https://github.com/flutter/flutter/issues/148493)).
- Blur fidelity misses a mipmap downsample, tracked as #149431 according to the same thread ([flutter#148493](https://github.com/flutter/flutter/issues/148493)).
- BackdropFilter has long slowed scrolling lists ([flutter#32804](https://github.com/flutter/flutter/issues/32804)).
- A PowerVR IMG8322 phone renders gradients wrongly only on the GLES fallback ([flutter#179268](https://github.com/flutter/flutter/issues/179268)).

**Inferred:** on tile-based Mali Bifrost and PowerVR Rogue, each extra backdrop read flushes tiles to narrow LPDDR4X memory. The project's existing lever, one grouped backdrop read per page, is the right one on every family. But no grouping rescues a GE8320, which is why it belongs at Off.

## The app's own field reports land on the proposed boundaries

The coordinator's verified data points line up with the GPU ranking rather than with RAM:

- **MediaTek MT6765G** (Helio G35, PowerVR GE8320, the bottom of the Notebookcheck table): a **715 ms frame at cold start while on Reduced**. Reduced still blurs, and this GPU also runs on Impeller's GLES fallback. Some of that frame may be first-frame shader or pipeline work rather than blur cost; this wasn't separated. Either way, Off is the right default here.
- **MT6835** (Dimensity 6100+/6300, Mali-G57 MC2) and **Qualcomm SM6450** (Snapdragon 6 Gen 1, Adreno 710): **RenderStall reports only while Liquid glass was on**. The SM6450 had a raster p95 of 28 ms at 60 Hz, nearly twice the 16.7 ms budget. Both chips cope with the design but not its heaviest variant, which is the definition of Reduced.
- **SM7550** (Snapdragon 7 Gen 3, Adreno 720, Wild Life ~5,400): only false in-call stall reports. That supports Full from Adreno 720 up.

The current default rule (Reduced when `isLowRamDevice` or `totalMem < 5e9`, applied once at first launch with no saved choice) misses all three cases. A 6 GB Helio G35 or G85 phone gets Full. A 4 GB Dimensity 7050 gets Reduced, which is merely conservative. RAM is a ceiling, not a GPU measure, and Facebook's archived device-year-class library was built on that same caveat ([device-year-class](https://github.com/facebookarchive/device-year-class)).

Media Performance Class doesn't fix this either. Level 0, meaning undeclared, covers almost every budget phone, so it can flag Full but can't separate Off from Reduced ([Android performance class](https://developer.android.com/topic/performance/performance-class)).

## Read SOC_MODEL first, then the board platform, then the GPU name

On API 31+, `Build.SOC_MANUFACTURER` and `Build.SOC_MODEL` read `ro.soc.manufacturer` and `ro.soc.model`. Missing values are reported as `"unknown"` ([Android Build](https://developer.android.com/reference/android/os/Build), [AOSP SocProperties](https://android.googlesource.com/platform/system/libsysprop/+/80600fd/srcs/android/sysprop/SocProperties.sysprop)). The strings are vendor-set and inconsistent, so match by regex, not equality.

**Verified string forms:**

| Vendor | Field | Values seen |
|---|---|---|
| MediaTek | `ro.soc.model` | Bare base number: `MT6765` (Realme C3) ([GitHub](https://github.com/RayhanDz/device_realme_RMX1941/blob/HEAD/system.prop)), `MT6789` (Realme 10) ([GitHub](https://github.com/SayuZX/dump_oplus_mt6789/blob/HEAD/odm.prop)) |
| MediaTek | `ro.soc.model` | Full suffix: `MT6853V/TNZA` ([GitHub](https://github.com/RMX2117-Source/android_device_tree_realme_RMX2117/blob/HEAD/odm.prop)), `MT6855V/ATZA` ([GitHub](https://github.com/sarthakroy2002/device_motorola_cancunf/blob/HEAD/configs/properties/sku/vendor.XT2431-1.prop)), `MT6895Z_A/TCZA` ([GitHub](https://github.com/CucumberMTK/device_oneplus_pickle/blob/HEAD/odm.prop)) |
| MediaTek | `ro.soc.model` | Tablet parts: `MT8781V/NA` ([GitHub](https://github.com/xiaomi-mt6789-devs/android_device_xiaomi_yunluo/blob/HEAD/configs/props/vendor.prop)), `MT8755` with `ro.board.platform=mt6835` ([GitHub](https://github.com/zenithblue-oss/panvk-kbase-android/blob/HEAD/worklogs/g615-dxvk/device-runs/2026-10-29-local-v9-tb336fu-115c-panprobe/results.md)) |
| MediaTek | adb, this session | vivo V2413: `ro.soc.manufacturer=Mediatek`, `ro.soc.model=MT6991`, `ro.board.platform=mt6991`, `ro.hardware=mt6991`; SurfaceFlinger GLES line `ARM, Mali-G925-Immortalis MC12` |
| Qualcomm | `ro.soc.*` | `QTI` + bare part number (`SM8350`) ([Level1Techs](https://forum.level1techs.com/t/bedhedds-xperia-5-iii-lineageos-project/221060)) |
| Play catalog | SoC strings | `QTI SM6225`, `Qualcomm SM7435`, `Samsung Exynos 850`, `Spreadtrum UMS9230E` ([pytorch/cpuinfo#329](https://github.com/pytorch/cpuinfo/issues/329)) |

The cpuinfo maintainers moved from `ro.board.platform` to `ro.soc.model` for exactly this purpose ([pytorch/cpuinfo#329](https://github.com/pytorch/cpuinfo/issues/329)).

**Not verified:** no raw Exynos or Unisoc device dump was found. Exynos phones may report `s5e8825`-style codes or `Exynos 850`, and Unisoc may report `ums9230` or `T606`.

Below API 31, read `ro.board.platform` (through `SystemProperties` reflection), then `Build.HARDWARE` and `Build.BOARD`. Don't use `/proc/cpuinfo`: arm64 kernels dropped its `Hardware` line ([msm-5.15 commit](https://git.evolution-x.org/anierin/msm-5.15/commit/44b82b7700d0)). These platform names are coarser than part numbers:

| Platform name | Chips it covers | GPU |
|---|---|---|
| `bengal` | SD460, 662, 680 | Adreno 610 |
| `holi` | SD480, 695, 4 Gen 1 | Adreno 619 |
| `parrot` | SD6 Gen 1, 7s Gen 2 | Adreno 710 |
| `ums9230` (Unisoc) | T606, T612, T616, T72xx | Mali-G57 MP1 |

Each name maps to one GPU class, which is all a tier needs (partly verified ([PhoneDB](https://phonedb.net/index.php?m=processor&id=852&d=detailed_specs), [TomKing062 wiki](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader/wiki/AddSupportToModel))). MediaTek platforms are just the lowercase part number (`mt6765`, `mt6768`, `mt6991`).

The GPU name is the strongest tie-breaker. It is the same string Impeller and Unreal key on ([Impeller](https://api.flutter.dev/impeller/driver__info__vk_8cc_source.html), [Unreal](https://docs.unrealengine.com/4.27/en/SharingAndReleasing/Mobile/Android/DeviceCompatibility)). Get it from an EGL pbuffer `glGetString(GL_RENDERER)` or from Vulkan `deviceName`, off the main thread. Cache it keyed by `Build.FINGERPRINT`, and use it only when the SoC string doesn't match the table. Its probe cost on low-end phones is unmeasured.

Firebase Remote Config has no device-model condition, but it accepts custom signals ([Remote Config](https://firebase.google.com/docs/remote-config/condition-reference)). Sending the normalised SoC as one lets a chip be demoted later without a release. Logging `SOC_MANUFACTURER|SOC_MODEL|board.platform|HARDWARE|GL_RENDERER` as Crashlytics keys fills in the unverified strings from real users.

### Proposed tier table, keyed by reported strings

Normalise to upper case and match the first pattern. In the "Basis" column, **V** means the chip-to-GPU mapping is cited, **K** means it is researcher knowledge not re-verified this session, and **F** means it is backed by the app's own field data. Every tier assignment is an inference from the benchmark ranking.

| Tier | SOC_MODEL patterns (API 31+) | Platform / HARDWARE fallback | Chips → GPU | Basis |
|---|---|---|---|---|
| **Off** | `MT6761`, `MT6762`, `MT6765` | `mt6761`, `mt6762`, `mt6765` | Helio A20/A22/A25/P22/G25/P35/G35/G36/G37/G50 → PowerVR GE8300/GE8320 | V ([Wikipedia](https://en.wikipedia.org/wiki/List_of_MediaTek_systems_on_chips)), F |
| **Off** | `MT6768`, `MT6769`, `MT6771`, `MT6779` | same, lowercase | Helio P65/G70/G80/G85/G88/G91 → Mali-G52 MC2; P60/P70 → G72 MP3; P90/P95 → GM9446 | V |
| **Off** | `SC9863A`, `UMS312`, `UMS512`, `UMS9230`, `T606`, `T61x`, `T7250` | `sc9863a`, `sp9863a`, `ums312`, `ums512`, `ums9230` | SC9863A → GE8322; T606/T612/T616/T72xx → Mali-G57 MP1; T610/T618/T700 → G52 MP2 | V ([Android Authority](https://www.androidauthority.com/unisoc-processors-guide-848691/)); codename strings K |
| **Off** | `MSM89xx`, `SDM4xx`, `SDM6[0-6]x`, `SM4250`, `SM6115`, `SM6125`, `SM6150`, `SM6225` | `msm8937`, `msm8953`, `sdm660`, `trinket`, `bengal`, `khaje`, `sm6150` | SD425–665, 460/662/680/685, 675/678 → Adreno 3xx/50x/51x/610/612 | K (platform names partly V) |
| **Off** | `S5E3830`, `EXYNOS850`, `EXYNOS7884`/`7904`, `EXYNOS9610`/`9611` | `exynos850`, `exynos9611` | Exynos 850 → G52 MP1; 9611 → G72 MP3 | K |
| **Reduced** | `MT6781`, `MT6789`, `MT6833`, `MT6835`, `MT6853`, `MT6873`, `MT6875`, `MT8781`, `MT8755` | same, lowercase | Helio G96/G99/G100, Dimensity 700/6020/810/6080/6100+/6300/6400/720/800U/800/820 → Mali-G57 MC2–MC5 | V, F (MT6835) |
| **Reduced** | `MT6785`, `MT6855`, `MT6877`, `MT6878`, `MT6886`, `MT8775` | same | G90/G95 → G76 MC4; D7020/7025 → BXM-8-256; D900/1080/7050 → G68 MC4; D7300/7400 → G615 MC2; D7200/7350 → G610 MC4 | V |
| **Reduced** | `UMS9620`, `UMS9621`, `T8200`, `T760` | `ums9620`, `ums9621` | T760/T770/T8200 → Mali-G57 MP2–MP4 | V (GPU), K (strings) |
| **Reduced** | `SM4350`, `SM4375`, `SM4450`, `SM4635`, `SM6350`, `SM6375`, `SM7125`, `SM7150`, `SM7225`, `SM7250`, `SDM710`/`712` | `holi`, `atoll`, `lito`, `sdmmagpie`, `pitti`, `sdm710` | SD480/695/4 Gen 1–3/690/750G/765G/720G/730G/732G → Adreno 613–620 | V (codenames), K (GPUs) |
| **Reduced** | `SM6450`, `SM6475`, `SM7435`, `SM7325`, `SM7350`, `SM7450` | `parrot`, `lahaina`, `taro` | SD6 Gen 1/6 Gen 3/7s Gen 2 → Adreno 710; 778G/780G → 642L/642; 7 Gen 1 → 662 | V (codenames), F (SM6450) |
| **Reduced** | `S5E8535`, `S5E8825`, `S5E8835`, `S5E8845`, `EXYNOS 1[2-4]80`, `EXYNOS 1330` | — | Exynos 1330 → G68 MP2; 1280 → G68 MP4; 1380 → G68 MP5; 1480 → Xclipse 530 | V (1280/1330), K (rest) |
| **Full** | `MT689[5-9]`, `MT698x`, `MT699x`, `MT879x` | same | Dimensity 8100–8450, 9000–9500 → Mali-G610 MC6 and up, Immortalis | V; V2413 (MT6991) verified via adb |
| **Full** | `SM7475`, `SM7550`, `SM7635`, `SM6650`, `SM7675`, `SM7750`, `SM8xxx` | `crow`, `volcano`, `milos`, `kalama`, `pineapple`, ... | SD7+ Gen 2/7 Gen 3/7s Gen 3–4/6 Gen 4/7+ Gen 3/8-series → Adreno 720+/810 | V (crow, milos), F (SM7550) |
| **Full** | `S5E8855`, `EXYNOS 1580`, `S5E99xx`, `TENSOR` | — | Exynos 1580 → Xclipse 540; flagships | V (1580 GPU) |

Two placements are judgment calls:

- **`lahaina` and `taro` also cover the Snapdragon 888 and 8 Gen 1.** That only matters on the platform fallback, and phones with those chips launched on Android 12 or later, so they should report `SOC_MODEL`.
- **The Exynos 1480 is placed at Reduced, not Full.** Impeller sends Xclipse with Vulkan below 1.3 to GLES, and no measured score was found for it.

Order the decision as follows:

1. `isLowRamDevice` or RAM ≤ 3 GB → Off, whatever the chip.
2. Otherwise the table above.
3. An unmatched string with a known GPU name → classify by GPU family (GE83xx/G52/G57 MP1/Adreno ≤ 612 → Off; G57 MC2 to G68/G615 MC2/Adreno 613–710 → Reduced; higher → Full).
4. Fully unknown → MPC ≥ 33 → Full, else Reduced.

Keep today's first-launch-only rule, so a user's saved choice is never overridden.

## Conclusion

The data turns the RAM heuristic into a GPU-family question, and the GPU families fall into three groups:

- **PowerVR Rogue:** clearly too weak for blur, and on Impeller's GLES fallback besides.
- **Mali-G57 MC2:** the Dimensity 6100+/6300 and Helio G99 class that now dominates 5G volume in India. It is the real calibration boundary: it can run Reduced, but its field reports show it can't carry Liquid glass. If profile builds on an MT6835 phone show Reduced still dropping frames on the Calls list, moving the whole MT6781/6789/6833/6835 row to Off is the single change with the biggest effect.
- **Adreno 610/619 Snapdragons:** no longer the Vulkan render-pass-split case the codebase assumed, if the pinned Flutter carries the late-2025 fallback.

Measuring that before tuning further is cheap, and it changes which optimisations pay off on the most common budget Snapdragons. The tier table is a starting map, not ground truth. The fastest way to harden it is to log the SoC and GPU strings to Crashlytics and gate the table behind a Remote Config custom signal.
