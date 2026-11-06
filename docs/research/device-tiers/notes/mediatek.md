# MediaTek smartphone SoCs (Helio A/P/G, Dimensity 6000-9000), 2018-2026: part numbers, GPUs, benchmarks, Build.SOC_MODEL strings

Sources used: Wikipedia list (W), Notebookcheck smartphone GPU benchmark list (NBC), techrankup GPU ranking (TR), nanoreview/cputronic search snippets, GitHub device trees (GH).

- W = https://en.wikipedia.org/wiki/List_of_MediaTek_systems_on_chips
- NBC = https://www.notebookcheck.net/Smartphone-Graphics-Cards-Benchmark-List.149363.0.html
- TR = https://www.techrankup.com/en/smartphone-processors-ranking/gpu/

## Which part numbers map to which marketing names?

### Takeaway
A base part number often covers several marketing names, and only the suffix tells them apart. MT6765 = P35/G35/G36/G37/G50. MT6762 = P22/A25/G25. MT6769 = G70/G80/G81/G85/G88/G91. MT6785 = G90/G90T/G95. MT6789 = G99 and G100. MT6833 = D700/D810/D6020/D6080. MT6835 = D6100+/D6300/D6400. MT6855 = D930/D7020/D7025. MT6877 = D900/D920/D1080/D7050. MT6878 = D7300/D7360/D7400. MT6886 = D7200/D7350. MT6895 = D8100, MT6896 = D8200/D8250, MT6897 = D8300/D8350. MT6781 is the G96 only. The G99 is MT6789, not MT6781.

### Cited findings: master table (from W unless noted)
Tier column = my proposed GPU tier (inference, see the benchmark section). Node is from W where it is listed, otherwise marked "n/l" (not listed by the source).

| Marketing name | Part number(s) (W) | Node | CPU | GPU | Tier |
|---|---|---|---|---|---|
| Helio A20 | MT6761V/WE | 12 nm | 4xA53 1.8 | PowerVR GE8300 @550 | budget-low |
| Helio A22 | MT6761V/WAB, /WBB | n/l (12 nm family) | 4xA53 2.0 | PowerVR GE8300 @660 | budget-low |
| Helio A25 | MT6762V/WB, /WD | n/l | 4xA53 1.8 + 4xA53 1.5 | PowerVR GE8320 @600 | budget-low |
| Helio P22 | MT6762 | 12 nm | 4xA53 2.0 + 4xA53 1.5 | PowerVR GE8320 @650 | budget-low |
| Helio G25 | MT6762G | 12 nm | 4xA53 2.0 + 4xA53 1.5 | PowerVR GE8320 @650 | budget-low |
| Helio P35 | MT6765 | 12 nm | 4xA53 2.3 + 4xA53 1.8 | PowerVR GE8320 @680 | budget-low |
| Helio G35 | MT6765G, MT6765V/CB | n/l | 4xA53 2.3 + 4xA53 1.8 | PowerVR GE8320 @680 | budget-low |
| Helio G36 | MT6765V/XAA, /XBA | n/l | 4xA53 2.2 + 4xA53 1.6 | (GE8320 per TR) | budget-low |
| Helio G37 | MT6765H | n/l | 4xA53 2.3 + 4xA53 1.8 | (GE8320 per TR) | budget-low |
| Helio G50 | MT6765V | n/l | 4xA53 2.2 + 4xA53 1.7 | n/l | budget-low |
| Helio P60 / P70 | MT6771 / MT6771V/CT, /WT | n/l (12 nm) | 4xA73 + 4xA53 | Mali-G72 MP3 @800/900 | budget |
| Helio P65 | MT6768 | n/l (12 nm) | 2xA75 2.0 + 6xA55 1.7 | Mali-G52 MC2 @820 | budget |
| Helio G70 | MT6769V/CB | n/l | 2xA75 2.0 + 6xA55 1.7 | Mali-G52 MC2 @820 | budget |
| Helio G80 | MT6769T, MT6769V/CT, /CU | n/l | 2xA75 2.0 + 6xA55 1.8 | Mali-G52 MC2 @950 | budget |
| Helio G81 | MT6769J, /L, /S | n/l | 2xA75 2.0 + 6xA55 1.7 | Mali-G52 MC2 @820 | budget |
| Helio G85 | MT6769Z, MT6769V/CZ | n/l | 2xA75 2.0 + 6xA55 1.8 | Mali-G52 MC2 @1000 | budget |
| Helio G88 | MT6769H | n/l | n/l | Mali-G52 MC2 (TR) | budget |
| Helio G91 | MT6769G, MT6769K | n/l | n/l | n/l | budget |
| Helio P90 / P95 | MT6779V/CU / MT6779V/CV | n/l | 2xA75 2.2 + 6xA55 2.0 | PowerVR GM9446 @970 | budget-high |
| Helio G90 | MT6785, MT6785V | n/l (12 nm) | 2xA76 2.05 + 6xA55 2.0 | Mali-G76 MC4 @720 | mid |
| Helio G90T | MT6785V/CC | n/l | n/l | Mali-G76 MC4 @800 | mid |
| Helio G95 | MT6785V/CD | n/l | n/l | Mali-G76 MC4 @900 | mid |
| Helio G96 | MT6781, MT6781V/CD | 12 nm ([geektopia](https://www.geektopia.es/es/product/mediatek/helio-g96/)) | n/l | Mali-G57 MC2 @950 | budget-high |
| Helio G99 | MT6789, MT6789G, /U, MT6789V/CD (tablet: MT8781, MT8781V/CA, /NA) | 6 nm | 2xA76 2.2 + 6xA55 2.0 | Mali-G57 MC2 @1000 | budget-high |
| Helio G100 | MT6789H, /I, /J | n/l | n/l | n/l (G99-class) | budget-high |
| Dimensity 700 / 6020 (rename) | MT6833, MT6833G, MT6833V/ZA, /NZA | 7 nm | 2xA76 2.2 + 6xA55 2.0 | Mali-G57 MC2 @950 | budget-high |
| Dimensity 810 / 6080 (rename) | MT6833P, MT6833GP, MT6833V/PNZA | 6 nm | 2xA76 2.4 + 6xA55 2.0 | Mali-G57 MC2 @1068 | budget-high |
| Dimensity 720 | MT6853V/ZA, /NZA | n/l (7 nm) | 2xA76 2.0 + 6xA55 2.0 | Mali-G57 MC3 @730 | budget-high |
| Dimensity 800U | MT6853T, MT6853V/TNZA | 7 nm | 2xA76 2.4 + 6xA55 2.0 | Mali-G57 MC3 @950 | mid-low |
| Dimensity 800 | MT6873 | n/l | 4xA76 2.0 + 4xA55 2.0 | Mali-G57 MC4 @748 | mid-low |
| Dimensity 820 | MT6875 | 7 nm | 4xA76 2.6 + 4xA55 2.0 | Mali-G57 MC5 @900 | mid |
| Dimensity 6100+ | MT6835, MT6835V/ZA (tablet MT8755V/TZB) | n/l (6 nm) | 2xA76 2.2 + 6xA55 2.0 | Mali-G57 MC2 @962 | budget-high |
| Dimensity 6300 | MT6835, MT6835T, MT6835V/TZB | n/l (6 nm) | 2xA76 2.4 + 6xA55 2.0 | Mali-G57 MC2 @1072 | budget-high |
| Dimensity 6400 | MT6835, MT6835V/TTZB | n/l | 2xA76 2.5 + 6xA55 2.0 | Mali-G57 MC2 (TR) | budget-high |
| Dimensity 930 / 7020 (rename) | MT6855, MT6855G, MT6855V/AZA | 6 nm (7020) | 2xA78 2.2 + 6xA55 2.0 | IMG BXM-8-256 @950 | mid-low |
| Dimensity 7025 | MT6855V/ATZA, MT6855V_A/ATZA | n/l | 2xA78 2.5 + 6xA55 2.0 | IMG BXM-8-256 (TR) | mid-low |
| Dimensity 900 | MT6877, MT6877V/ZA | 6 nm | 2xA78 2.4 + 6xA55 2.0 | Mali-G68 MC4 @900 | mid |
| Dimensity 920 | MT6877T, MT6877V/TZA | n/l | 2xA78 2.5 + 6xA55 2.0 | Mali-G68 MC4 @950 | mid |
| Dimensity 1080 / 7050 (rename) | MT6877V/TTZA, MT6877V_T/TTZA | n/l (6 nm) | 2xA78 2.6 + 6xA55 2.0 | Mali-G68 MC4 @950 | mid |
| Dimensity 7030 (= 1050 rename) | n/l | n/l | n/l | Mali-G610 MC3 @1000 | mid |
| Dimensity 7200 | MT6886, MT6886V_A/CZA, _B/CZA | 4 nm | 2xA715 2.8 + 6xA510 2.0 | Mali-G610 MC4 @1130 | mid-high |
| Dimensity 7350 | MT6886V/TCZA | 4 nm | 2xA715 3.0 + 6xA510 2.0 | Mali-G610 MC4 @1300 | mid-high |
| Dimensity 7300 (and 7300X/Energy/Ultra) | MT6878, MT6878V/ZA, _A/_B/_E/ZA (tablet MT8775) | 4 nm | 4xA78 2.5 + 4xA55 2.0 (CPU not in W excerpt) | Mali-G615 MC2 @1047 | mid |
| Dimensity 7360 | MT6878V_G/ZA | n/l | n/l | n/l (G615 MC2 class) | mid |
| Dimensity 7400 | MT6878V/TZA, _B/TZA, _C/TZA | 4 nm | 4xA78 2.6 + 4xA55 2.0 | Mali-G615 MC2 @1300 | mid |
| Dimensity 1100 / 8020 | MT6891, MT6891Z/CZA, ... | n/l (6 nm) | 4xA78 2.6 + 4xA55 2.0 | Mali-G77 MC9 @836 | mid-high |
| Dimensity 1200 / 1300 / 8050 | MT6893, MT6893Z/CZA, Z_A, Z_Z, Z_T | n/l (6 nm) | 1xA78 3.0 + 3xA78 2.6 + 4xA55 | Mali-G77 MC9 @886 | mid-high |
| Dimensity 8100 | MT6895, MT6895Z/TCZA, Z_A, Z_B, ZB (tablet MT8795) | 5 nm | 4xA78 2.85 + 4xA55 2.0 | Mali-G610 MC6 @860 | flagship-low |
| Dimensity 8200 / 8250 | MT6896, MT6896Z/CZA, Z_B, Z_C | 4 nm | 1xA78 3.1 + 3xA78 3.0 + 4xA55 | Mali-G610 MC6 @950 | flagship-low |
| Dimensity 8300 / 8350 | MT6897, MT6897Z/ZA, Z_A..Z_F (tablet MT8792) | 4 nm | 1xA715 3.35 + 3xA715 3.2 + 4xA510 2.2 | Mali-G615 MC6 @1400 | flagship |
| Dimensity 8400 / 8450 | MT6899, MT6899Z/ZA, Z_A..Z_E | n/l | 8xA725 (3.25/3.0/2.1) | Mali-G720 MC7 @1300 | flagship |
| Dimensity 9000 | MT6983 | 4 nm | X2 + 3xA710 + 4xA510 | Mali-G710 MC10 | flagship |
| Dimensity 9200 | MT6985 | 4 nm | X3 + 3xA715 + 4xA510 | Immortalis-G715 MC11 | flagship |
| Dimensity 9300 | MT6989 | 4 nm | 4xX4 + 4xA720 | Immortalis-G720 MC12 | flagship |
| Dimensity 9400 | MT6991 | 3 nm | X925 + 3xX4 + 4xA720 | Immortalis-G925 MC12 | flagship |
| Dimensity 9500 | MT6993, MT6993W/CZA | n/l | n/l | Mali G1-Ultra MC12 @1716 | flagship |

- The postmarketOS wiki also groups the MT6769 family as G70 (MT6769V), G80 (MT6769T), G85 (MT6769Z), G88 (MT6769H) and G91 (MT6769G/K) — [postmarketOS](https://wiki.postmarketos.org/wiki/MediaTek_Helio_G91_(MT6769G/K))
- Helio G96 is listed as MT6781 / MT6781V/CD, announced 15 July 2021, TSMC 12 nm — [geektopia](https://www.geektopia.es/es/product/mediatek/helio-g96/)
- Helio P35 (MT6765) launched late 2018 with 8xA53 — [Notebookcheck](https://www.notebookcheck.net/Mediatek-Helio-P35-MT6765-SoC-Benchmarks-and-Specs.420407.0.html)
- cputronic gives the Helio G35 "Model Name" as MT6765G — [cputronic](https://cputronic.com/soc/mediatek-helio-g35)

### Inferences
- A tier classifier should match on the base part number (MT6765, MT6769, ...) for the tier and use the suffix only as a refinement. Everything on one base number shares one GPU, and only the clocks differ: MT6765 is GE8320, MT6769 is G52 MC2, MT6789/MT6833/MT6835/MT6781 are G57 MC2. The few base numbers that cross a tier line are MT6877 (D900 vs D1080: same GPU, so it doesn't matter), MT6833 (D700 vs D810: same GPU) and MT6762/MT6765 (both GE8320).
- Tablet part numbers (MT8781 = G99, MT8755 = D6100+, MT8775 = D7300, MT8792 = D8300, MT8795 = D8100) also show up in Build.SOC_MODEL and should map to the matching phone tier.

### Gaps
- Process nodes the excerpt didn't list (marked n/l) are from my general knowledge in brackets: A/P/G35/G85 family 12 nm, D6100+/6300 6 nm, D1100/1200 6 nm. Verify them against MediaTek product pages if needed. I did not fetch mediatek.com.
- The CPU for the Dimensity 7300 and the GPUs for G36/G37/G50/G91/G100/D6400/D7360 were not in the fetched excerpt. TR gives GE8320 for G36/G37 and G57 MC2 for D6400.
- Helio G81 Ultra, G85 variants, G86/G91 Ultra, G200, and Dimensity 7025-Ultra, 7060 and 6100 variants were not checked. TR lists a Helio G200 with Mali-G57 MC2.

## What GPU and benchmark score does each have?

### Takeaway
I found no single clean 3DMark Wild Life (Unlimited) table: nanoreview blocks fetching and mixes up test labels. The best like-for-like relative numbers are (a) NBC's per-GPU GFXBench offscreen medians and (b) TR's relative chart. A few absolute Wild Life / Wild Life Extreme points per phone back them up. Rough order: GE8300 < GE8320 << G52 MC2 < G72 MP3 / GM9446 < G57 MC2 (G96 < D700 < G99 ≈ D6100+ < D810 ≈ D6300) < G57 MC3 < BXM-8-256 ≈ G57 MC4 ≈ G76 MC4 < G68 MC4 < G615 MC2 ≈ G610 MC3 < G610 MC4 < G77 MC9 < G610 MC6 < G615 MC6 < G720 MC7 < flagship Immortalis.

### Cited findings
NBC per-GPU medians (fps; the columns appear in the order "GFXBench" [T-Rex offscreen, presumably] / GFXBench 3.0 Manhattan 1080p offscreen / GFXBench 3.1 Manhattan ES3.1 offscreen; NBC's markup didn't clearly align the values with the headers) — [NBC](https://www.notebookcheck.net/Smartphone-Graphics-Cards-Benchmark-List.149363.0.html):

| GPU | T-Rex? | Manhattan 3.0 offscr | Manhattan 3.1 offscr |
|---|---|---|---|
| PowerVR GE8300 | 14 | 6.6 | 4.3 |
| PowerVR GE8320 | 20 | 10.5 | 6.65 |
| Mali-G72 MP3 | 38 | 20 | 13 |
| Mali-G52 MP2 | 42.5 | 24 | 15 |
| Mali-G57 MP2 | 63 | 40 | 25 |
| Mali-G57 MP3 | 71 | 44 | 28 |
| IMG BXM-8-256 | 73.5 | 62 | 34.5 |
| Mali-G76 MP4 | 80 | 49.5 | 30 |
| Mali-G57 MP4 | 84 | 51.5 | 34 |
| Mali-G68 MP4 | 101.5 | 64.5 | 42 |
| Mali-G615 MP2 | 115 | 82.5 | 56 |
| Mali-G610 MP3 | 117 | 71 | 49 |
| Mali-G610 MP4 | 166 | 106 | 73 |
| Mali-G77 MP9 | 182.5 | 115 | 78 |
| Mali-G710 MP7 | 251 | 134 | 97 |
| Mali-G610 MP6 | 273 | 145.5 | 99 |
| Mali-G615 MP6 | 454 | 199.5 | 163 |
| Mali-G720 MP7 | 584 | 243 | 199 |
| Immortalis-G720 MP12 | 779 | 269 | 241 |

TR relative GPU chart (older chart, % of Apple A17 Pro; the benchmark isn't named) — [TR](https://www.techrankup.com/en/smartphone-processors-ranking/gpu/): D9200 77.8, D9000 58.5, D8300 53.3, D8200 46.7, D8100 38.5, D1200/1300 39.3, D8020 37, D1100 34.8, D7200 29.6, D1080/7050/920 20, D7030 19.3, D900 17.8, D7020/7025/930 14.8, D800U 14.8, G95 14.8, D720 13.3, D6100+/D6300/D810 11.9, G99 11.9, D6080 11.1, D700/D6020 10.4, G96 10.4, G88 8.9, G85 7.4, G70/G80 6.7, P95 5.9, G35/G36/G37 3.0, G25 2.2.
- TR's newer chart (3DMark Wild Life Extreme, % of Apple A20 Pro): D7200 13.2, D7300 Max 9.9, D7100 7.9, Helio G200 4.6, D6300 4.4, D6400 4.4, Helio G81 1.9 — [TR](https://www.techrankup.com/en/smartphone-processors-ranking/gpu/)
- TR mislabels the G99's GPU as Mali-G52 MC2. W says Mali-G57 MC2, so use W — [W](https://en.wikipedia.org/wiki/List_of_MediaTek_systems_on_chips)
- Absolute 3DMark points from search snippets (not fetched): Moto G23 (G85) Wild Life 746 / Wild Life Extreme 189; Realme 10 (G99) Wild Life 1,363 / WLE 377; Oppo Reno8 T (G99) 1,366 / 378 — [cputronic G88/G85 page snippet](https://cputronic.com/soc/mediatek-helio-g88)
- nanoreview: G99 WLE 346 vs G85 187; Steel Nomad Light G99 135 vs G85 80, D6100+ 134, D6300 151 — [nanoreview G99 vs G85](https://nanoreview.net/en/soc-compare/mediatek-helio-g99-vs-mediatek-helio-g85), [G99 vs 6100+](https://nanoreview.net/en/soc-compare/mediatek-helio-g99-vs-mediatek-dimensity-6100-plus), [G99 vs 6300](https://nanoreview.net/en/soc-compare/mediatek-helio-g99-vs-mediatek-dimensity-6300)
- nanoreview: D8300 Wild Life Extreme 2,768 — [nanoreview D8300](https://nanoreview.net/en/soc/mediatek-dimensity-8300)

### Inferences
- Suggested tier cutoffs in Manhattan 3.0 offscreen fps (NBC): budget-low < 15 (GE8300/8320), budget 15-35 (G52 MC2, G72 MP3, GM9446), budget-high 35-55 (G57 MC2/MC3, G76 MC4, G57 MC4), mid 55-90 (BXM-8-256, G68 MC4, G615 MC2, G610 MC3), mid-high 90-130 (G610 MC4, G77 MC9), flagship > 130 (G610 MC6 and up).
- Within G57 MC2 the SoC clock matters, roughly G96 (950) ≈ D700 (950) < D6100+ (962) < G99 (1000) < D810/6080 (1068) ≈ D6300 (1072). The spread is about 10-15%, so they belong in one tier.
- The Wild Life ratio G99/G85 is about 1.83 (1363/746), which matches NBC's Manhattan ratio of about 1.67 (40/24).

### Gaps
- I have no verified 3DMark Wild Life (Unlimited) scores for most chips (GE8320 chips, D7025, D7300, D7200, D8100, ...). Nanoreview returns 403 to fetches, and the cputronic D7300 and G35 pages have no Wild Life data. If an absolute number is needed, check UL's 3DMark Android rankings or Notebookcheck's per-GPU pages.
- The NBC medians are per GPU, not per SoC, and I inferred the column headers from link order.

## Which popular phones use each chip?

### Takeaway
I verified only a few phone examples in this pass. The rest below are from general knowledge and still need checking against GSMArena.

### Cited findings
- Dimensity 7300: Motorola Edge 50 Neo, Edge 60, Edge 60 Fusion, Moto G86 / G86 Power, Nothing CMF Phone 1, vivo T4x 5G, vivo V40e, vivo Y400 Pro (7300X: Lava Agni 3, Moto Razr 50) — [cputronic](https://cputronic.com/soc/mediatek-dimensity-7300)
- Helio G35: Realme C55, Redmi 12C — [cputronic](https://cputronic.com/soc/mediatek-helio-g35) (I'd expect the C55 to be a G88 phone, so this is suspect)
- G85: Moto G23; G99: Realme 10, Oppo Reno8 T — [cputronic snippet](https://cputronic.com/soc/mediatek-helio-g88)
- Device trees on GitHub confirm the phone-to-chip pairs below (with their soc.model):

| Phone | soc.model | Source |
|---|---|---|
| Realme 6 / Narzo (RMX2020) | MT6768 = G70/G80 class | [GH](https://github.com/sarthakroy2002/device_realme_RMX2020/blob/HEAD/configs/props/vendor.prop) |
| Realme C3 (RMX1941) | MT6765 | [GH](https://github.com/RayhanDz/device_realme_RMX1941/blob/HEAD/system.prop) |
| Redmi Note 8 Pro (begonia) | MT6785 = G90T | [GH](https://github.com/begonia-dev/android_device_redmi_begonia/blob/HEAD/vendor.prop) |
| Realme 8 5G / Narzo 30 5G (RMX2117) | MT6853V/TNZA = D800U | [GH](https://github.com/RMX2117-Source/android_device_tree_realme_RMX2117/blob/HEAD/odm.prop) |
| Realme RMX3686 (titan) | MT6877V/TTZA = D1080 | [GH](https://github.com/psychoxripp3r/android_device_realme_titan/blob/HEAD/odm.prop) |
| Moto cancunf, XT2431 (Moto G85/G64-class) | MT6855V/ATZA = D7025 | [GH](https://github.com/sarthakroy2002/device_motorola_cancunf/blob/HEAD/configs/properties/sku/vendor.XT2431-1.prop) |
| OnePlus 10R (pickle) | MT6895 and MT6895Z_A/TCZA = D8100 | [GH](https://github.com/Oneplus-10R/device_oneplus_pickle/blob/HEAD/odm.prop), [GH](https://github.com/CucumberMTK/device_oneplus_pickle/blob/HEAD/odm.prop) |
| Realme RMX3630 (Realme 10) | MT6789 = G99 | [GH](https://github.com/SayuZX/dump_oplus_mt6789/blob/HEAD/odm.prop) |
| Xiaomi 2311DRK48I (Poco X6 Pro / Redmi K70E) | MT6897 = D8300 Ultra | [GH](https://github.com/zenithblue-oss/fluxlinux/blob/HEAD/docs/plans/results/hw-accel-all-distros-report.md) |
| Realme GT Master / X7 Max (RMX3031) | MT6893 | [GH](https://github.com/realme-mt6893-dev/android_device_realme_RMX3031/blob/HEAD/vendor.prop) |
| Redmi K40 Gaming / Poco F3 GT (chopin) | MT6891, while the platform prop says MT6893 | [GH](https://github.com/xiaomi-mt6893-dev/android_device_xiaomi_chopin/blob/HEAD/vendor.prop) |

### Inferences
These are unverified examples from general knowledge (check them on GSMArena before using):
- G35: Redmi 9A/9C, Realme C11/C20, Samsung Galaxy A03s (P35).
- G37: I can't name G37 phones with confidence.
- G85: Redmi Note 8 2021, Redmi 9 / 10A?, Realme C25/Narzo 50A, Infinix Hot 12/Note 12?, Tecno Spark/Pova, Galaxy A05?
- G88: Redmi 10 / 10 Prime, Realme C35?, Galaxy A15 4G? (unsure, may be G99).
- G99: Redmi Note 12S / 13 4G-alt, Poco M5 / M6 Plus?, Samsung Galaxy A15 4G? / A24, Infinix Note 30, Tecno Pova 5.
- D6100+: Redmi 13C 5G, Realme 11x / Narzo 60x, Galaxy A14 5G (some variants), vivo Y28.
- D6300: Galaxy A16 5G, Redmi 14C 5G?, Poco M6? (that's a Snapdragon 4 Gen 2?), Realme C65 5G.
- D7025: Moto G85? (the device tree "cancunf" may be the Moto G64), Lava Agni.
- D7200: vivo V27/V29, Galaxy A35? (no, Exynos), Redmi Note 13 Pro+ = D7200 Ultra.
- D8100: OnePlus 10R, Poco X4 GT, Redmi K50.

### Gaps
- I couldn't verify phone examples per chip within the tool budget. Fill them in from GSMArena's chipset filter. Itel and Tecno low-end phones mostly use Unisoc and the Helio A22/G36 class; that is unverified.

## What strings does Build.SOC_MODEL actually return on MediaTek phones?

### Takeaway
Build.SOC_MODEL reads `ro.soc.model`, and on MediaTek phones it is vendor-set and not consistent. Seen values are a bare uppercase base (`MT6765`, `MT6768`, `MT6789`, `MT6893`, `MT6895`, `MT6897`, `MT6991`, `MT6993`), the full suffixed form (`MT6853V/TNZA`, `MT6877V/TTZA`, `MT6855V/ATZA`, `MT6895Z_A/TCZA`), a tablet part (`MT8781V/NA`, `MT8755` with `ro.board.platform=mt6835`), and occasionally lowercase (`mt8390`, from an embedded board). `ro.soc.manufacturer` is `Mediatek`, `MediaTek` or `mediatek`. `ro.board.platform` / `ro.hardware` are lowercase (`mt6991`, `mt6768`).

### Cited findings
- AOSP defines `ro.soc.manufacturer` and `ro.soc.model` as read-only public strings in SocProperties — [AOSP](https://android.googlesource.com/platform/system/libsysprop/+/80600fd/srcs/android/sysprop/SocProperties.sysprop)
- `ro.soc.model=MT6765` (Realme C3; also the "realme_g35" tree) — [GH](https://github.com/RayhanDz/device_realme_RMX1941/blob/HEAD/system.prop), [GH](https://github.com/mdsumon2001/dt_realme_g35/blob/HEAD/system.prop)
- `ro.soc.model=MT6768` with `ro.vendor.mediatek.platform=MT6768` (Realme RMX2020); `ro.board.platform=mt6768` (RMP6768 tablet) — [GH](https://github.com/sarthakroy2002/device_realme_RMX2020/blob/HEAD/configs/props/vendor.prop), [GH](https://github.com/StatiXOS/android_device_realme_RMP6768/blob/HEAD/configs/props/system.prop)
- `ro.soc.model=MT6853V/TNZA` (Realme 8 5G) — [GH](https://github.com/RMX2117-Source/android_device_tree_realme_RMX2117/blob/HEAD/odm.prop)
- `ro.soc.model=MT6877V/TTZA`, `ro.product.oplus.cpuinfo=MT6877TT` (Realme RMX3686) — [GH](https://github.com/psychoxripp3r/android_device_realme_titan/blob/HEAD/odm.prop)
- `ro.soc.model=MT6855V/ATZA` (Motorola XT2431) — [GH](https://github.com/sarthakroy2002/device_motorola_cancunf/blob/HEAD/configs/properties/sku/vendor.XT2431-1.prop)
- `ro.soc.model=MT6895Z_A/TCZA` in one OnePlus 10R dump vs `MT6895` in another tree for the same phone — [GH](https://github.com/CucumberMTK/device_oneplus_pickle/blob/HEAD/odm.prop), [GH](https://github.com/Oneplus-10R/device_oneplus_pickle/blob/HEAD/odm.prop)
- `ro.soc.model=MT8781V/NA` (Xiaomi "yunluo" in the xiaomi-mt6789-devs org, i.e. a G99-class tablet) — [GH](https://github.com/xiaomi-mt6789-devs/android_device_xiaomi_yunluo/blob/HEAD/configs/props/vendor.prop)
- `ro.soc.model=MT8755` while the board property says mt6835 (Lenovo TB336FU, Mali-G57 MC2) — [GH](https://github.com/zenithblue-oss/panvk-kbase-android/blob/HEAD/worklogs/g615-dxvk/device-runs/2026-10-29-local-v9-tb336fu-115c-panprobe/results.md)
- `ro.soc.model=MT6891` with `ro.vendor.mediatek.platform=MT6893` (Xiaomi chopin) — [GH](https://github.com/xiaomi-mt6893-dev/android_device_xiaomi_chopin/blob/HEAD/vendor.prop)
- `ro.board.platform=mt6991`, `ro.hardware=mt6991`, `ro.soc.model=MT6991` (Samsung tablet, Dimensity 9400) — [GH](https://github.com/zenithblue-oss/panvk-kbase-android/blob/HEAD/validation/rtl/g925-beta17/device.txt)
- `ro.soc.model=MT6993` and `ro.board.platform=mt6993` (Redmi, Dimensity 9500) — [GH](https://github.com/zeng060812-creator/NovaSched-Zen-Edition/blob/HEAD/native/src/soc.rs)
- `ro.soc.model=MT6789`, `ro.product.oplus.cpuinfo=MT6789` (Realme RMX3630) — [GH](https://github.com/SayuZX/dump_oplus_mt6789/blob/HEAD/odm.prop)
- Lowercase `ro.soc.manufacturer=mediatek`, `ro.soc.model=mt8390` (Boundary Devices board) — [GH](https://github.com/boundarydevices/android_device_mediatek/blob/HEAD/soc/mt8188/mt8390.mk)

### Inferences
- A parser should uppercase the string, take the first `MT\d{4}` as the base, then optionally read the letter or `_X` suffix before the `/` for the variant. When SOC_MODEL is empty (pre-Android 12) or a tablet part, fall back to `ro.board.platform` / Build.HARDWARE (lowercase `mt6xxx`).
- Bare base numbers can't tell P35 from G35/G37 or G70/G85/G88 apart, but the GPU is identical within each family, so this doesn't matter for a GPU tier.

### Gaps
- I didn't find Geekbench or AnTuTu examples, or any for Samsung, Tecno, Infinix or vivo MediaTek phones specifically. Samsung may report differently: its Exynos phones use `s5e8825`-style values, and its MediaTek phones (Galaxy A14/A15/A16) weren't checked. The example of a Samsung tab on MT6991 reporting `MT6991` suggests Samsung keeps the MediaTek form.
- I didn't check whether Build.HARDWARE on new MediaTek phones is `mt6789` or a codename. I saw `ro.hardware=mt6991` in one case.
