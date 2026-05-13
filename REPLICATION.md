# Replication Guide

This file maps every table and figure in the thesis to the do-file that produces it, and reports the expected Stata output for verification. All numbers are from verified live Stata runs on SHARE release 9.0.0.

Run the full pipeline via `run_all.do`. See `README.md` for setup instructions.

---

## Pipeline execution order

| Step | Do-file | What it does |
|------|---------|--------------|
| 1 | `do-files/01_build_panel.do` | Assembles FR+DE panel from SHARE waves 1, 2, 4, 5, 6, 8, 9 |
| 2 | `do-files/02_build_outcomes.do` | Forward-fills `current_smoker`; builds DiD variables |
| 2b | `do-files/00b_merge_income.do` | Merges `co007_` income proxy; partner-fill within household |
| 3 | `do-files/03_did_baseline.do` | Primary, interim, and sensitivity DiD estimates |
| 4 | `do-files/04_parallel_trends.do` | Placebo DiDs and event study |
| 5 | `do-files/05_robustness.do` | Robustness checks R1–R6 |
| 6 | `do-files/06_heterogeneity.do` | Heterogeneous effects by sex, education, age |
| 6b | `do-files/07_wave9_extended.do` | Pooled post specifications |
| 6c | `do-files/12_income_heterogeneity.do` | Income heterogeneity (triple interaction + stratified) |
| 7 | `do-files/robustness_table.do` | Exports robustness table to `output/` |

---

## Table 1 — Descriptive statistics

**Produced by:** `do-files/01_build_panel.do` and `do-files/02_build_outcomes.do`

Expected values:

| Statistic | Germany W6 | France W6 | Germany W9 | France W9 |
|-----------|-----------|-----------|-----------|-----------|
| Current smoker (%) | 19.43 | 15.78 | 17.29 | 12.93 |
| Age at interview | 66.31 | 67.87 | 68.05 | 69.92 |
| Female (%) | 52.06 | 56.94 | 53.77 | 56.74 |
| Low education ISCED 1–2 (%) | 11.66 | 41.33 | 8.61 | 30.28 |
| Medium education ISCED 3–4 (%) | 57.01 | 36.13 | 54.72 | 40.42 |
| High education ISCED 5+ (%) | 31.34 | 22.54 | 36.67 | 29.30 |
| Financial difficulty (%) | 16.35 | 28.84 | 11.34 | 23.66 |
| N | 4,195 | 3,816 | 4,430 | 2,878 |

---

## Figure 1 — Smoking prevalence over time (France vs Germany)

**Produced by:** `do-files/04_parallel_trends.do`

Expected output: a line plot of wave-by-wave current smoker prevalence for France and Germany across waves 1, 2, 4, 5, 6, 8, 9. The dashed vertical line marks 2017 (start of tax reform). France fluctuates between approximately 14–16%; Germany peaks around 20% at Wave 5 then declines.

---

## Figure 2 — Event study

**Produced by:** `do-files/04_parallel_trends.do`

Expected coefficients (Wave 6 reference, individual and wave fixed effects, SEs clustered at pid):

| Wave | Coefficient (pp) | SE | p-value |
|------|-----------------|-----|---------|
| W4 | −1.00 | 0.84 | 0.233 |
| W5 | +0.35 | 0.24 | 0.145 |
| W6 | 0 (ref) | — | — |
| W8 | −2.20 | 0.64 | 0.001 |
| W9 | −2.48 | 0.68 | 0.0003 |

Pre-treatment coefficients (W4, W5) are statistically insignificant and centred near zero. Post-treatment coefficients (W8, W9) are negative and significant.

> **Note:** The event study W9 coefficient (−2.48 pp) differs from the headline TWFE estimate (−2.71 pp) because they use different specifications and samples. The event study pools all five waves in a single regression; the headline TWFE uses only W6 and W9 observations. Both are correct.

---

## Table 2 — Primary results (Wave 6 vs Wave 9)

**Produced by:** `do-files/03_did_baseline.do`, specification [A]

| Specification | DiD coeff (pp) | SE | p-value | N |
|--------------|---------------|----|---------|---|
| Pooled OLS | −0.71 | 0.94 | 0.450 | 15,319 |
| OLS + controls | −0.60 | 0.93 | 0.523 | 15,178 |
| **TWFE (headline)** | **−2.71** | **0.75** | **<0.001** | **8,334** |

Controls: age at interview, sex, ISCED-97 education. Individual and wave fixed effects in TWFE. SEs clustered at individual level (mergeid).

---

## Table 3 — Robustness checks

**Produced by:** `do-files/05_robustness.do` and `do-files/robustness_table.do`

| Specification | Coeff (pp) | SE | p-value | N |
|--------------|------------|----|---------|---|
| Headline: W6 vs W9 (TWFE) | −2.71 | 0.75 | <0.001 | 8,334 |
| R1. Direct observations only | −1.07 | 0.43 | 0.013 | 4,168 |
| R2. Extended pre: W5+W6 vs W9 | −2.77 | 0.74 | <0.001 | 19,319 |
| R3. Balanced panel W6 & W9 | −2.71 | 0.75 | <0.001 | 8,334 |
| R4. Interim: W6 vs W8 | −2.30 | 0.68 | 0.001 | 9,490 |
| R5. Pooled post: W6 vs W8+W9 | −2.46 | 0.63 | <0.001 | 16,563 |

All specifications use TWFE with individual and wave fixed effects, SEs clustered at individual level.

---

## Heterogeneous effects — Sex

**Produced by:** `do-files/06_heterogeneity.do`

Triple interaction (female differential): +0.58 pp (SE 1.54, p = 0.705) — null. No statistically significant gender heterogeneity.

---

## Heterogeneous effects — Education

**Produced by:** `do-files/06_heterogeneity.do`

Triple interaction: null (p = 0.443). Stratified TWFE:

| Group | Coeff (pp) | SE | p-value | N (FE) |
|-------|------------|----|---------|---------|
| Low ISCED 1–2 | −0.94 | 1.71 | 0.581 | 1,616 |
| Mid ISCED 3–4 | −4.89 | 1.32 | 0.0002 | 3,936 |
| High ISCED 5+ | −1.87 | 1.24 | 0.131 | 2,660 |

---

## Heterogeneous effects — Age

**Produced by:** `do-files/06_heterogeneity.do`

Triple interaction: null (p > 0.5). Stratified TWFE:

| Group | Coeff (pp) | SE | p-value | N (FE) |
|-------|------------|----|---------|---------|
| 50–64 years | −6.48 | 1.94 | 0.001 | 1,878 |
| 65–74 years | −1.61 | 1.66 | 0.333 | 1,106 |
| 75+ years | +1.34 | 1.35 | 0.321 | 1,372 |

---

## Heterogeneous effects — Income

**Produced by:** `do-files/12_income_heterogeneity.do`

Triple interaction (difficulty vs no difficulty):
- Main effect (no difficulty baseline): −1.84 pp (SE 0.79, p = 0.022)
- Additional effect for difficulty group: −5.83 pp (SE 2.46, p = 0.018)

Stratified TWFE by income group:

| Group | Coeff (pp) | SE | p-value | N (FE) |
|-------|------------|----|---------|---------|
| Difficulty (co007_ 1–2) | −7.32 | 3.06 | 0.017 | 738 |
| Fairly easily (co007_ 3) | +1.24 | 1.88 | 0.508 | 1,156 |
| Easily (co007_ 4) | −3.80 | 1.39 | 0.006 | 2,840 |

---

## Placebo DiDs

**Produced by:** `do-files/04_parallel_trends.do`

| Placebo window | Coeff (pp) | SE | p-value |
|---------------|------------|----|---------|
| W4 → W5 | +0.30 | 0.92 | 0.740 |
| W5 → W6 | −0.71 | 0.21 | 0.001 |
| W4 → W6 | +1.23 | 0.89 | 0.170 |

The W5→W6 placebo is statistically significant but its magnitude (−0.71 pp) is approximately one-quarter of the headline estimate (−2.71 pp). Two of three placebo tests pass. See Section 5.1 of the thesis for interpretation.

---

## Output files

After running `run_all.do`, the following files are saved to `output/`:

| File | Contents |
|------|----------|
| `pipeline_YYYYMMDD.log` | Full Stata console output from the pipeline run |
| `robustness_table.rtf` | Robustness table formatted for Word |
| `robustness_table.tex` | Robustness table formatted for LaTeX |

Intermediate datasets are saved to `data_build/`:

| File | Contents |
|------|----------|
| `panel_frde_raw.dta` | Raw FR+DE panel, waves 1/2/4/5/6/8/9, age 50+ |
| `panel_frde_outcomes.dta` | Panel with forward-filled smoking, DiD variables, and income proxy |

---

## Verification

To verify your results match, compare your Stata output against `results_summary.md`. Every specification reported in the thesis is documented there with its exact coefficient, standard error, p-value, and sample size.

If results differ, check:
1. SHARE release version — must be 9.0.0
2. The `SHARE WAVES/` subfolder contains all required modules for waves 1, 2, 4, 5, 6, 8, 9
3. The root path in `run_all.do` points to the correct folder
4. Required packages (`reghdfe`, `ftools`, `estout`) installed correctly — `run_all.do` installs them automatically if missing
