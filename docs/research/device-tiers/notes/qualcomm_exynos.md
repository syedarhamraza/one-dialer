# Qualcomm Snapdragon and Samsung Exynos SoCs in South Asian budget and midrange phones (2018–2026): identifiers, GPUs, benchmarks

Legend used in the tables:
- **[V]**: verified with a cited source in "Cited Findings".
- **[K]**: from the researcher's prior knowledge (AOSP/LineageOS device trees, spec sheets). It is very likely right but was **not re-verified this session**. Check it against a real device (`adb shell getprop ro.soc.model ro.soc.manufacturer ro.board.platform ro.hardware`) before shipping a lookup table.
- Benchmarks: **WL** = 3DMark Wild Life (standard, the 1-min test); **WLE** = Wild Life Extreme. Sources mix them up, so every number below says which one it is.

## Which SM/SDM part numbers and board-platform codenames map to which marketing names?

### Takeaway
There are three separate naming layers, and a lookup has to handle all three:
1. **Part number** (SM6225, SDM450...). This is what `Build.SOC_MODEL` / `ro.soc.model` returns on Android 12+ Qualcomm phones, with `SOC_MANUFACTURER` = "QTI".
2. **Board platform / HLOS codename** (bengal, holi, lito, atoll, parrot, crow...). This is what `ro.board.platform` and often `Build.HARDWARE` return. One codename covers several marketing chips; for example `bengal` covers the SD460, 662 and 680.
3. **Qualcomm internal BSP codename** (DIVAR, STRAIT, MANNAR...). Android never reports this one, so it can be ignored.

Use `SOC_MODEL` as the primary key and keep `ro.board.platform` only as a coarse fallback for Android 11 and older.

### Master table: Qualcomm

| Marketing name | Part no. (SOC_MODEL) | ro.board.platform / HLOS codename | Qualcomm BSP codename [V] | Node | CPU | GPU | Tier guess |
|---|---|---|---|---|---|---|---|
| SD425 | MSM8917 | msm8937 [K] | FEEROLITE | 28nm | 4×A53 | Adreno 308 [K] | budget-low |
| SD429 | SDM429 | msm8937 [K] | HATHI | 12nm | 4×A53 | Adreno 504 [K] | budget-low |
| SD430 | MSM8937 | msm8937 [K] | FEERO | 28nm | 8×A53 | Adreno 505 [K] | budget-low |
| SD435 | MSM8940 | msm8937 [K] | – | 28nm | 8×A53 | Adreno 505 [K] | budget-low |
| SD439 | SDM439 | msm8937 [K] (sdm439 in some trees) | – (not in table) | 12nm | 8×A53 | Adreno 505 [K] | budget-low |
| SD450 | SDM450 | msm8953 [K] | FIRELORD | 14nm | 8×A53 | Adreno 506 [K] | budget-low |
| SD625 / 626 | MSM8953 (Pro) | msm8953 [K] | JACALA (626) | 14nm | 8×A53 | Adreno 506 [K] | budget-low |
| SD632 | SDM632 | msm8953 [K] | – | 14nm | 4×A73+4×A53 | Adreno 506 [K] | budget-low |
| SD630 | SDM630 | sdm660 [K] | STARHAWK | 14nm | 8×A53 | Adreno 508 [K] | budget |
| SD636 | SDM636 | sdm660 [K] | BLACKBOLT | 14nm | 4+4 Kryo 260 | Adreno 509 [K] | budget |
| SD660 | SDM660 | sdm660 [K] | STARLORD | 14nm | 4+4 Kryo 260 | Adreno 512 [K] | budget |
| SD665 | SM6125 | trinket [V] | NICOBAR | 11nm | 4+4 Kryo 260 | Adreno 610 [K] | budget |
| SD460 | SM4250 | bengal [V] | – | 11nm | 4+4 Kryo 240 | Adreno 610 [K] | budget |
| SD662 | SM6115 | bengal [V] | – | 11nm | 4+4 Kryo 260 | Adreno 610 [K] | budget |
| SD680 | SM6225 | bengal [K]; kernel/SoC codename khaje [V] | DIVAR | 6nm | 4+4 Kryo 265 | Adreno 610 [K] | budget |
| SD685 | SM6225-AD [K] | bengal [K] | – | 6nm | 4+4 Kryo 265 | Adreno 610 [K] | budget |
| SD675 / 678 | SM6150 (678 = SM6150-AC) [K] | sm6150 [K] (trinket per one community wiki [V], conflicting) | TALOS | 11nm | 2×A76+6×A55 | Adreno 612 [K] | budget-mid |
| SD710 / 712 | SDM710 / SDM712 [K] | sdm710 [K] | – | 10nm | 2+6 Kryo 360 | Adreno 616 [K] | budget-mid |
| SD720G | SM7125 | atoll [V] | RENNELL | 8nm | 2×A76+6×A55 | Adreno 618 [K] | mid |
| SD730 / 730G / 732G | SM7150 (-AA/-AB/-AC) [V for SM7150] | sm6150 [K]; HLOS codename "Magpie" (sdmmagpie) [V] | MOOREA | 8nm | 2×A76+6×A55 | Adreno 618 [K] | mid |
| SD690 | SM6350 | lito [K] | BITRA | 8nm | 2×A77+6×A55 | Adreno 619L [K] | mid |
| SD750G | SM7225 [K] | lito [K] | – | 8nm | 2×A77+6×A55 | Adreno 619 [K] | mid |
| SD765G / 768G | SM7250 | lito [V] | SAIPAN | 7nm | 1+1+6 Kryo 475 | Adreno 620 [K] | mid |
| SD480 / 480+ | SM4350 (-AC) | holi [V] | MANNAR | 8nm | 2×A76+6×A55 | Adreno 619 [K] | budget-mid |
| SD695 | SM6375 | holi [K] (also "blair" in some trees, unverified) | STRAIT | 6nm | 2×A78+6×A55 | Adreno 619 [K] | mid |
| SD4 Gen 1 | SM4375 [V model no.] | holi [K] | – | 6nm | 2×A78+6×A55 | Adreno 619 [K] | budget-mid |
| SD6s Gen 3 | SM6375-AC [K] | holi [K] | – | 6nm | 2×A78+6×A55 | Adreno 619 [K] | mid |
| SD4 Gen 2 | SM4450 [V model no.] | parrot? (conflicting, see Gaps) | CLARENCE | 4nm | 2×A78+6×A55 | Adreno 613 [K] | budget-mid |
| SD4 Gen 3 | SM4635 | pitti [V] | – | 4nm | 2×A78+6×A55 | Adreno 613? [K, unsure] | budget-mid |
| SD6 Gen 1 | SM6450 | parrot [V] | NETRANI | 4nm | 4×A78+4×A55 | Adreno 710 [K] | mid |
| SD7s Gen 2 | SM7435 | parrot [V] | NETRANI | 4nm | 4×A78+4×A55 | Adreno 710 [K] | mid |
| SD6 Gen 3 | SM6475(-AB) [V] | unknown (likely parrot family, unverified) | – | 4nm (Samsung) [V] | 4×A78+4×A55 [K] | Adreno 710 [K] | mid |
| SD778G / 778G+ / 782G | SM7325 | lahaina [K]; HLOS codename "Yupik" [V] | KODIAK | 6nm | 1+3 A78 + 4 A55 | Adreno 642L [K] | upper-mid |
| SD780G | SM7350 | lahaina [K] | CEDROS | 5nm | 1+3 A78 + 4 A55 | Adreno 642 [K] | upper-mid |
| SD7 Gen 1 | SM7450 | taro [K] | FILLMORE | 4nm | 1×A710+3×A710+4×A510 | Adreno 662 [K] | upper-mid |
| SD7+ Gen 2 | SM7475 | taro [K]; HLOS "Cape/Waipio" [V] | PALIMA | 4nm TSMC | 1×X2+3×A710+4×A510 | Adreno 725 [K] | flagship-lite |
| SD7 Gen 3 | SM7550(-AB) | crow [V] | – | 4nm | 1+3 A715 + 4 A510 | Adreno 720 [K] | upper-mid |
| SD7s Gen 3 | SM7635 | volcano / milos [V] | – | 4nm | 1+3 A720 + 4 A520 [K] | Adreno 810 [K] | upper-mid |
| SD7s Gen 4 | SM7635-AC | volcano / milos [V] | – | 4nm | same as 7s Gen 3, faster clocks [K] | Adreno 810 [K] | upper-mid |
| SD6 Gen 4 | SM6650 [K] | milos family [V: grouped on the same pmOS page] | – | 4nm | 1+3 A720 + 4 A520 [K] | Adreno 810 [K] | mid |
| SD7+ Gen 3 | SM7675 [K] | unknown | – | 4nm | 1×X4+... [K] | Adreno 732 [K] | flagship-lite |
| SD7 Gen 4 | SM7750 [K] | unknown | – | 4nm | – | Adreno 722 [K] | upper-mid |

### Master table: Samsung Exynos

| Marketing name | SOC_MODEL / ro.hardware (expected) | Node | CPU | GPU | Tier guess |
|---|---|---|---|---|---|
| Exynos 7884 / 7904 | exynos7884 / exynos7904 [K] | 14nm | 2×A73+6×A53 | Mali-G71 MP2 [K] | budget-low |
| Exynos 9610 / 9611 | exynos9610 / exynos9611 (s5e9610?) [K] | 10nm | 4×A73+4×A53 | Mali-G72 MP3 [K] | budget |
| Exynos 850 | s5e3830; board "exynos850" [K] | 8nm | 8×A55 | Mali-G52 MP1 [K] | budget-low |
| Exynos 880 / 980 | s5e8805? / exynos980 [K] | 8nm | 2×A77+6×A55 | Mali-G76 MP5 [K] | mid |
| Exynos 1280 | s5e8825 [V] | 5nm [V] | 2×A78+6×A55 | Mali-G68 MP4 [V] | mid |
| Exynos 1330 | s5e8535 [K; cpubenchmark lists "Samsung s5e8535"] | 5nm [V] | 2×A78 2.4 GHz + 6×A55 2.0 GHz [V] | Mali-G68 MP2 [V] | budget-mid |
| Exynos 1380 | s5e8835 [V] | 5nm | 4×A78+4×A55 | Mali-G68 MP5 [K] | mid |
| Exynos 1480 | s5e8845 [K] | 4nm [V] | 4×A78+4×A55 (2.05–2.75 GHz) [V] | Xclipse 530 (1 RDNA WGP) [V/K] | upper-mid |
| Exynos 1580 | s5e8855 [K] | 4nm (3nm-class claims unverified) | 1×A720 2.9 + 3×A720 2.6 + 4×A520 1.95 [V] | Xclipse 540 (2 WGP, RDNA 3) [V] | upper-mid |

### Cited Findings
- Qualcomm BSP codenames: SD429 = SDM429 "HATHI"; SD450 = SDM450 "FIRELORD"; SD626 = MSM8953 Pro "JACALA"; SD430 = MSM8937 "FEERO"; SD425 = MSM8917 "FEEROLITE"; SD630 = SDM630 "STARHAWK"; SD636 = SDM636 "BLACKBOLT"; SD660 = SDM660 "STARLORD"; SD665 = SM6125 "NICOBAR"; SD675 = SM6150 "TALOS"; SD680 = SM6225 "DIVAR"; SD695 = SM6375 "STRAIT"; SD480 = SM4350 "MANNAR"; SD4 Gen 2 = SM4450 "CLARENCE"; SD6 Gen 1 = SM6450 "NETRANI", HLOS "Parrot"; SD720 = SM7125 "RENNELL", HLOS "Atoll"; SD730/730G/732G = SM7150 "MOOREA", HLOS "Magpie"; SD765G = SM7250 "SAIPAN"; SD778G/782G = SM7325 "KODIAK", HLOS "Yupik"; SD7s Gen 2 = SM7435 "NETRANI", HLOS "Parrot"; SD7 Gen 1 = SM7450 "FILLMORE"; SD7+ Gen 2 = SM7475 "PALIMA", HLOS "Cape/Waipio"; SD690 = SM6350 "BITRA"; SD780G = SM7350 "CEDROS"; SD670 = SDM670 "WARLOCK" — [Qualcomm Chips Codename Reference Table (aloha.firmware.icu)](https://aloha.firmware.icu/ReferenceTables/QCSiliconCodenameReferenceTable.html)
- That table has no rows for SDM439, SDM632, SM6115, SM4250, SM4375, SM4635, SM6475, SM6650, SM7225, SM7550, SM7635, SM7675, SM7750 or SDM710/712 — [same table](https://aloha.firmware.icu/ReferenceTables/QCSiliconCodenameReferenceTable.html)
- A community wiki maps SD680/SM6225 to "khaje"; SM4250 (SD460) and SM6115 (SD662) to "bengal"; SM4450 and SM6450/SM7435 to "parrot"; SM6125/SM6150 to "trinket"; SM7250 (765/765G/768G) to "lito". This is a search-engine summary; the page itself was bot-blocked when fetched — [postmarketOS wiki, User:Akku/Qualcomm SoCs](https://wiki.postmarketos.org/wiki/User:Akku/Qualcomm_SoCs)
- Notebookcheck noted that "bengal" in a Geekbench listing is a Qualcomm platform codename — [Notebookcheck](https://www.notebookcheck.net/Potential-new-OPPO-phones-with-an-interesting-code-name-leak-onto-Geekbench.478570.0.html)
- SD480 5G = SM4350 "Holi" (2021); 480+ = SM4350-AC "Holi" — [PhoneDB SM4350](https://phonedb.net/index.php?m=processor&id=852&d=detailed_specs), [PhoneDB SM4350-AC](https://phonedb.net/index.php?m=processor&id=875&c=qualcomm_snapdragon_480plus_5g_sm4350-ac__holi)
- "Holi" is the SM4350 with an Adreno 619 — [Adam Conway on X](https://x.com/adamconwayie/status/1344685193534320644?lang=en); the OnePlus Nord N200's fastboot product name is "holi" — [XDA forums](https://xdaforums.com/t/is-holi-actually-the-device-codename-or-only-the-soc-codename.4314311/)
- SD7 Gen 3 = SM7550-AB "Crow" (2023) — [PhoneDB SM7550-AB](https://phonedb.net/index.php?m=processor&id=954&d=detailed_specs), [igeekphone](https://www.igeekphone.com/xiaomi-code-found-code-crow-processor-qualcomm-snapdragon-sm7550/)
- SD7s Gen 3 = SM7635, codenames "volcano / milos"; the 7s Gen 4 is SM7635-AC; postmarketOS groups 7s Gen 3, 7s Gen 4 and 6 Gen 4 under "Milos" and names the Redmi Note 14 Pro+ as an SM7635 device — [postmarketOS Milos](https://wiki.postmarketos.org/wiki/Qualcomm_Snapdragon_7s_Gen_3/7s_Gen_4/6_Gen_4_(Milos)), [Android Headlines](https://www.androidheadlines.com/2024/04/exclusive-qualcomm-is-set-to-unveil-its-new-mid-range-socs.html), [geektopia 7s Gen 4](https://www.geektopia.es/es/product/qualcomm/snapdragon-7s-gen-4/)
- SD4 Gen 1 = SM4375 and SD4 Gen 2 = SM4450; "pitti" is SM4635 (SD4 Gen 3) — [fonearena](https://www.fonearena.com/blog/421417/qualcomm-snapdragon-7s-gen-3-6-gen-2-4-gen-3.html/amp), [gizmochina](https://www.gizmochina.com/?p=617799)
- SD6 Gen 3 = SM6475-AB, 4nm Samsung, launched Sept 2024 — [geektopia 6 Gen 3](https://www.geektopia.es/es/product/qualcomm/snapdragon-6-gen-3/)
- 6s Gen 3 announced as a mid-range chip — [PhoneArena](https://www.phonearena.com/news/qualcomm-introduces-mid-range-snapdragon-6s-gen-3_id159205) (the page wasn't fetched, so the SM6375-AC part number is [K])
- Exynos 1280 = s5e8825, 5nm, Mali-G68 MP4, Q1 2022 — [Wikipedia: Exynos](https://en.wikipedia.org/wiki/Exynos); "Samsung s5e8825": 8 cores at 2.4 GHz — [cpubenchmark](https://www.cpubenchmark.net/cpu.php?cpu=Samsung+s5e8825&id=5395)
- Exynos 1380 = s5e8835 (2023) — [devicebeast](https://devicebeast.com/processor/samsung-exynos-1380-5g-s5e8835/devices?page=2); "Samsung s5e8535" is a listed CPU name — [cpubenchmark](https://www.cpubenchmark.net/compare/5363vs5502/Qualcomm-SM7250-vs-Samsung-s5e8535)
- Exynos 1330: 5nm, 2×A78 2.4 GHz + 6×A55 2.0 GHz, Mali-G68 MP2 — [SamMobile](https://www.sammobile.com/news/exynos-1330-1380-5nm-chips-announced-specifications/), [fonearena](https://www.fonearena.com/blog/386237/samsung-exynos-1330-1380-specs-features.html/amp)
- Exynos 1480: 4nm, 8 cores at 2.05–2.75 GHz, used in the Galaxy A55 — [Notebookcheck Exynos 1480](https://www.notebookcheck.com/Samsung-Exynos-1480-Prozessor-Benchmarks-und-Specs.831252.0.html)
- Exynos 1580: 1×A720 2.9 GHz + 3×A720 2.6 GHz + 4×A520 1.95 GHz; RDNA 3 GPU with 2 WGPs, double the 1480's — [GSMArena](https://m.gsmarena.com/exynos_1580_unveiled_with_cortexa720_cores_double_the_gpu_hardware-amp-65051.php)

### Inferences
- The aloha table and PhoneDB disagree on SM4350 (MANNAR vs Holi), but they don't conflict: MANNAR is Qualcomm's BSP name and holi is the HLOS/board-platform name Android reports. The same goes for SM6450/SM7435: NETRANI is the BSP name, parrot the platform name. So for the dialer, use only the HLOS codenames (`ro.board.platform`).
- `bengal` alone can't tell an SD460 (weakest) from an SD680. They all share the Adreno 610, so for GPU tiering that's acceptable: bengal maps to one tier. `holi` covers SD480, 695, 4 Gen 1 and 6s Gen 3, which all use the Adreno 619 (same tier). `parrot` covers 6 Gen 1 and 7s Gen 2 (Adreno 710, same tier); if the SM4450 really is parrot, it carries an Adreno 613 and sits a tier lower. That case is why SOC_MODEL should come first.
- Older Qualcomm phones (Android 11 and below, so most SD4xx/6xx-era devices) have no `ro.soc.model` (`Build.SOC_MODEL` is API 31+). For those, `ro.board.platform` (msm8937, msm8953, sdm660, trinket, bengal...) is the only signal.

### Gaps
- The `ro.board.platform` values marked [K] (msm8937 for SD425/429/430/435/439, msm8953 for 450/625/632, sdm660, sm6150, sdm710, lahaina, taro, bengal for SD680) weren't fetched from device trees this session. The postmarketOS SoC table was bot-blocked, and a search for the spes (Redmi Note 11) BoardConfig `TARGET_BOARD_PLATFORM` didn't surface the file.
- The SM4450 (4 Gen 2) platform codename is unconfirmed: a community wiki summary says parrot, nothing else corroborates it. The SM6475 (6 Gen 3), SM7675 (7+ Gen 3) and SM7750 (7 Gen 4) codenames weren't found.
- Whether SM6375 also appears as "blair" wasn't confirmed; the search returned nothing for "blair".
- The Exynos s5e codes for the 850 (s5e3830), 1330 (s5e8535), 1480 (s5e8845) and 1580 (s5e8855) were not confirmed by a primary source.

## GPU and benchmark score for each

### Takeaway
No fetchable single source gave a full GPU benchmark table: nanoreview returned 403 and the Notebookcheck list is CPU-only. The few cited numbers below are consistent with this ordering: Adreno 610 (SD680) < Adreno 619 (SD695) < Mali-G68 MP5 (Exynos 1380) ≈ Adreno 662 (7 Gen 1) < Adreno 720 (7 Gen 3).

### Cited Findings
- WLE: SD695 = 360, SD680 = 172 (695 is +109%) — [nanoreview 695 vs 680](https://nanoreview.net/en/soc-compare/qualcomm-snapdragon-695-vs-qualcomm-snapdragon-680) (search snippet; the page itself returns 403 to fetches)
- WLE: Exynos 1380 = 808, SD7 Gen 3 = 1596 — [nanoreview 1380 vs 7 Gen 3](https://nanoreview.net/en/soc-compare/samsung-exynos-1380-vs-qualcomm-snapdragon-7-gen-3)
- WLE: SD7 Gen 1 = 857 vs Exynos 1380 = 808 — [nanoreview 1380 vs 7 Gen 1](https://nanoreview.net/en/soc-compare/samsung-exynos-1380-vs-qualcomm-snapdragon-7-gen-1)
- 3DMark Steel Nomad Light: SD6 Gen 3 = 306, Exynos 1380 = 279 — [nanoreview 1380 vs 6 Gen 3](https://nanoreview.net/en/soc-compare/samsung-exynos-1380-vs-qualcomm-snapdragon-6-gen-3)
- WL: Exynos 1380 = 2772, SD695 = 1215. The same article's summary table says 2235 vs 1211, so it contradicts itself — [Cashify](https://www.cashify.in/samsung-exynos-1380-vs-snapdragon-695)
- WL: SD7 Gen 3 = 5414 (32 fps), Exynos 1380 = 2813 — [GeeksDigit](https://www.geeksdigit.com/snapdragon-7-gen-3-vs-exynos-1380-comparison/)

### Inferences
- WL ≈ 3.4–3.5 × WLE across these pairs (1380: 2772–2813 WL vs 808 WLE; 7 Gen 3: 5414 vs 1596), so one can be converted roughly into the other for tiering.
- Proposed GPU tiers by GPU family (an inference from the GPU assignments above, not measured):
  - **Low (A3xx/A50x, Mali-G52 MP1, G71 MP2):** SD425–SD450, 625, 632, Exynos 850 / 7884 / 7904.
  - **Budget (A508–A512, A610, A612, Mali-G72 MP3, Mali-G68 MP2):** SD630/636/660, 460/662/665/680/685, 675/678, Exynos 9611, Exynos 1330 (approx).
  - **Mid (A613, A616–A620, A619L, Mali-G68 MP4, G76 MP5):** SD4 Gen 2/3, 710/712, 720G/730G/732G, 690, 750G, 765G, 480, 695, 4 Gen 1, 6s Gen 3, Exynos 1280, 880/980.
  - **Upper-mid (A642L/642, A662, A710, A720, Mali-G68 MP5, Xclipse 530):** SD778G/780G/782G, 7 Gen 1, 6 Gen 1, 6 Gen 3, 7s Gen 2, 7 Gen 3, Exynos 1380, 1480.
  - **Near-flagship (A725/A732/A810, Xclipse 540):** SD7+ Gen 2, 7+ Gen 3, 7s Gen 3/7s Gen 4, 6 Gen 4, 7 Gen 4, Exynos 1580.

### Gaps
- No verified per-chip WL or Aztec numbers for SD4xx, 6xx (other than 680/695), 720G/732G, 750G, 765G, 778G, 4 Gen 1/2/3, 6 Gen 1, 7s Gen 2, 7+ Gen 2, 7s Gen 3, or Exynos 850, 9611, 1280, 1330, 1480, 1580. Nanoreview (403) and Notebookcheck (CPU-only list) blocked this; UL's 3DMark Android ranking was not tried. The researcher's rough prior-knowledge WL ballpark, all **unverified** and to be checked before use: Adreno 610 ≈ 400–450, Adreno 618 ≈ 1100, Adreno 619 ≈ 1200, Adreno 642L ≈ 2900, Adreno 710 ≈ 2100–2500, Exynos 1280 ≈ 1800–2000, Exynos 850 ≈ 200 or below, Xclipse 530 ≈ 3500–4000, Adreno 725 ≈ 6000+.

## Which popular phones use each chip?

### Takeaway
Only a few device-chip pairs were verified this session (from the Play-catalog data in the pytorch/cpuinfo issue). The rest come from prior knowledge and are marked [K].

### Cited Findings
- SM6225 (SD680): Samsung Galaxy A05s (SM-A057F/G/M), Redmi Note 13 4G (23124RA7EO), OPPO A60 (CPH2631) — [pytorch/cpuinfo #329](https://github.com/pytorch/cpuinfo/issues/329)
- SM7435 (SD7s Gen 2): Redmi Note 13 Pro 5G (2312DRA50G/I) — [pytorch/cpuinfo #329](https://github.com/pytorch/cpuinfo/issues/329)
- SM6115 (SD662/6s 4G Gen 1 family): OPPO A3x (CPH2641), OPPO A3 / A40 / A40m (CPH2669) — [pytorch/cpuinfo #329](https://github.com/pytorch/cpuinfo/issues/329)
- Exynos 850: Galaxy A04s (SM-A047F), Galaxy A21s (SM-A217F/M), Galaxy A12 (SM-A127F) — [pytorch/cpuinfo #329](https://github.com/pytorch/cpuinfo/issues/329)
- SD680: Redmi Note 11 (spes/spesn) — [PixelExperience wiki](https://wiki.pixelexperience.org/devices/spes)
- SM7635 (SD7s Gen 3): Redmi Note 14 Pro+ — [postmarketOS](https://wiki.postmarketos.org/wiki/Qualcomm_Snapdragon_7s_Gen_3/7s_Gen_4/6_Gen_4_(Milos))
- SD480: OnePlus Nord N200 — [XDA](https://xdaforums.com/t/is-holi-actually-the-device-codename-or-only-the-soc-codename.4314311/)
- Exynos 1480: Galaxy A55 — [Notebookcheck](https://www.notebookcheck.com/Samsung-Exynos-1480-Prozessor-Benchmarks-und-Specs.831252.0.html); Exynos 1580: expected in the Galaxy A56 — [GSMArena](https://m.gsmarena.com/exynos_1580_unveiled_with_cortexa720_cores_double_the_gpu_hardware-amp-65051.php)

### Inferences (all [K], unverified this session)
- SD439: Redmi 8/8A, Realme C2? (C2 is MediaTek, so treat as doubtful), vivo Y91 Q-variant, Galaxy A10s? (MediaTek; doubtful). Treat the whole SD439 list as unreliable.
- SD450: Redmi 6 Pro?, Moto G6 Play, vivo Y81i?
- SD460: Moto G10/G30, OPPO A54 4G? (the A54 is Helio, doubtful), Nokia 5.4.
- SD662: Redmi 9 Power / 9T, Realme 7i, Moto G20? (Unisoc, doubtful), vivo Y20, Galaxy A11? (SD450).
- SD665: Redmi Note 8, Realme 5/5i, Galaxy A30s? (Exynos), vivo Y11?
- SD680: Redmi Note 11/12 4G, Realme 9i/C55? (Helio, doubtful), vivo Y22s/T2x 4G, OPPO A57/A77s, Galaxy A23 4G, Galaxy M13? (Exynos 850, doubtful), Poco M4 Pro? (Helio, doubtful).
- SD685: Redmi Note 13 4G (Global), Realme C67, Galaxy A24? (Helio, doubtful).
- SD695: Redmi Note 11 Pro+ 5G / Note 12 5G, Poco X5, Moto G62/G72? (G72 is Helio, doubtful), vivo T1 5G, Realme 9 Pro, Galaxy A23 5G / M33? (M33 is Exynos 1280, doubtful), OnePlus Nord CE 2 Lite.
- SD4 Gen 1: Redmi Note 12 5G (India), Poco M5? (Helio, doubtful), iQOO Z6 Lite.
- SD4 Gen 2: Redmi 12 5G / 13C 5G? (13C 5G is Dimensity, doubtful), Poco M6 Pro 5G, vivo Y28 5G?
- SD6 Gen 1: Galaxy A35? (Exynos 1380, doubtful), Realme 11 Pro? (Dimensity, doubtful), Honor 90 Lite? Treat as unreliable; iQOO Z7 Pro? (Dimensity, doubtful).
- SD720G: Redmi Note 9 Pro/9S, Realme 6 Pro, Galaxy A52 4G (SM7125), Poco M2 Pro.
- SD732G: Redmi Note 10 Pro, Poco X3 NFC, Galaxy A72.
- SD750G: Galaxy A52 5G, Galaxy M42, Redmi Note 10 Pro 5G (China)? Unreliable.
- SD778G: Galaxy A52s, Galaxy A73, Realme GT Master Edition, iQOO Z5? (778G), Poco X5 Pro.
- SD7s Gen 2: Redmi Note 13 Pro 5G [V], Poco X6, Realme 12 Pro?, Galaxy A25? (Exynos 1280, doubtful).
- SD7 Gen 3: vivo V30 / T3 Ultra?, OnePlus Nord CE4, Realme 13 Pro.
- Exynos 9611: Galaxy M30s, M21, A51, A50s.
- Exynos 1280: Galaxy A53, A25, M33/M34/M35? (M35 is Exynos 1380), F23? (Snapdragon, doubtful).
- Exynos 1330: Galaxy A14 5G, A15 5G, M14 5G, A16 5G?
- Exynos 1380: Galaxy A34? (Dimensity, doubtful), A54, A35, M35 / M55? (M55 is Snapdragon, doubtful), F54.

These lists mix real and doubtful entries. Before publishing any device-to-SoC mapping, check each one on GSMArena; the "?" items are the most likely to be wrong.

### Gaps
- Systematic per-chip device lists weren't fetched (GSMArena/nanoreview device pages); verified examples cover only SD680, SD662/SM6115, SD7s Gen 2, SD7s Gen 3, SD480 and Exynos 850/1480.

## What exact strings do Build.SOC_MODEL / Build.SOC_MANUFACTURER return?

### Takeaway
On Qualcomm phones `ro.soc.manufacturer` is "QTI" and `ro.soc.model` is the bare part number (for example "SM8350"); Play's device catalog shows "QTI SM6225" too. No real device dump was found for Samsung Exynos; Play's catalog shows "Samsung Exynos 850", which may be normalised by Play rather than a raw property value.

### Cited Findings
- A real `getprop` dump from a Sony Xperia 5 III shows `ro.soc.manufacturer` = QTI and `ro.soc.model` = SM8350 — [Level1Techs forum](https://forum.level1techs.com/t/bedhedds-xperia-5-iii-lineageos-project/221060)
- Play Store device catalog SoC strings: "QTI SM6225" (Galaxy A05s, Redmi Note 13, OPPO A60), "QTI SM8550" / "QTI SM8650" / "QTI SM8750" (Galaxy S23/S24/S25 Ultra), "Qualcomm SM7435" (Redmi Note 13 Pro 5G), "Qualcomm SM6115" (OPPO A3x/A3/A40), "Samsung Exynos 850" (Galaxy A04s/A21s/A12), "Spreadtrum UMS9230E" (Redmi A5) — [pytorch/cpuinfo #329](https://github.com/pytorch/cpuinfo/issues/329)
- The cpuinfo maintainer said `ro.soc.model` is a better field than `ro.board.platform`, used it for the Qualcomm fix (PR #381, plus #382 for Google Tensor), and closed the issue on 18 May 2026 — [pytorch/cpuinfo #329](https://github.com/pytorch/cpuinfo/issues/329)

### Inferences
- The manufacturer field varies between "QTI" and "Qualcomm" even within Qualcomm phones (Play shows both). A matcher should accept both, case-insensitively, and key on the model string.
- Model strings may carry suffixes in some builds (for example "SM7550-AB" vs "SM7550", "SM6225-AD"). Match on the prefix (`^SM\d{4}` / `^SDM\d{3}`), and fall back to `ro.board.platform` for Android 11 and older.
- On Samsung Exynos, the expected (unverified) values are SOC_MANUFACTURER "Samsung" and SOC_MODEL as the s5eXXXX code (for example "s5e8825") or "Exynos 850"/"exynos850". The Play string "Samsung Exynos 850" suggests at least some devices report a marketing-style name. Handle both forms: s5e8825↔1280, s5e8835↔1380, s5e8535↔1330, s5e3830↔850, s5e8845↔1480, s5e8855↔1580.

### Gaps
- No raw `getprop ro.soc.*` / `Build.SOC_MODEL` output from any Exynos phone was found. Confirm it on a real Galaxy A-series device (the user's or a tester's phone).
- No raw dump from a budget Qualcomm phone (SM6225/SM6375) was found; the "QTI SM6225" form comes from Play's catalog, not a device dump.
