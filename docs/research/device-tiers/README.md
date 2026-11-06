# Device tiers research

Why `DeviceTier.kt` puts each phone chip at Off, Reduced or Full visual effects by default (Settings › Reduce visual effects and Call screen effects, until the user picks a level).

- [report.md](report.md): the findings, the tier table keyed by the strings Android reports (`Build.SOC_MODEL`, `ro.board.platform`, GL renderer), and what is verified vs inferred.
- [notes/](notes/): the raw research notes with sources: MediaTek, Qualcomm and Exynos, the South Asia market with Unisoc, and runtime detection with blur cut-offs.

Researched November 2026 for 1.0.0-beta.8. The tiers come from GPU benchmarks, not measured blur frame times: when Crashlytics lag reports (keys `device_soc`, `device_gpu`, `effects_default`, `effects_source`) show a chip lagging at its default, move it in `DeviceTier.kt` and note it here.
