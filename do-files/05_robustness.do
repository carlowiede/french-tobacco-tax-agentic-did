*------------------------------------------------------------------------------
* 05_robustness.do
*
* Robustness checks anchored to the headline spec: W6 (pre) vs W9 (post).
*
* HEADLINE: W6 vs W9, TWFE (pid + wave FE), SEs clustered at pid.
*
* Checks:
*   R1. Direct-observation-only current_smoker (cs_imputed == 0)
*   R2. Extended pre period: W5+W6 vs W9
*   R3. Balanced panel: respondents in BOTH W6 and W9
*   R4. Alt clustering: country-wave (4 clusters) — OLS only, TWFE degenerate
*       with pid FE (noted as non-applicable)
*   R5. INTERIM window: W6 vs W8 (for robustness table column)
*   R6. SENSITIVITY window: W6 vs W8+W9 pooled
*
* Run AFTER 03_did_baseline.do.
*------------------------------------------------------------------------------

clear all
set more off
version 17

local root "$root"
use "`root'/data_build/panel_frde_outcomes.dta", clear

gen int countrywave = country * 100 + wave

*------------------------------------------------------------------------------
* R1. Direct-observation-only current_smoker (W6 vs W9)
*     Drops all skip-pattern imputations (cs_imputed == 0)
*------------------------------------------------------------------------------
display as result _newline "=== R1. Direct obs only: W6 vs W9 (cs_imputed == 0) ==="
preserve
    keep if inlist(wave, 6, 9) & !missing(current_smoker)
    keep if cs_imputed == 0
    gen byte post_69 = (wave == 9)
    tab wave france
    reg current_smoker i.france##i.post_69, vce(cluster pid)
    reghdfe current_smoker c.france#c.post_69, absorb(pid wave) vce(cluster pid)
restore

*------------------------------------------------------------------------------
* R2. Extended pre period: W5+W6 (pre) vs W9 (post)
*------------------------------------------------------------------------------
display as result _newline "=== R2. Extended pre: W5+W6 vs W9 ==="
preserve
    keep if inlist(wave, 5, 6, 9) & !missing(current_smoker)
    gen byte post_r2 = (wave == 9)
    tab wave france
    reg current_smoker i.france##i.post_r2, vce(cluster pid)
    reghdfe current_smoker c.france#c.post_r2, absorb(pid wave) vce(cluster pid)
restore

*------------------------------------------------------------------------------
* R3. Balanced panel: respondents observed in BOTH W6 and W9
*------------------------------------------------------------------------------
display as result _newline "=== R3. Balanced panel: W6 & W9 ==="
preserve
    keep if inlist(wave, 6, 9) & !missing(current_smoker)
    gen byte post_69 = (wave == 9)
    bysort pid: gen byte nwaves = _N
    keep if nwaves == 2
    tab wave france
    reg current_smoker i.france##i.post_69, vce(cluster pid)
    reghdfe current_smoker c.france#c.post_69, absorb(pid wave) vce(cluster pid)
restore

*------------------------------------------------------------------------------
* R4. Alternative clustering: country-wave (4 clusters)
*     NOTE: This check is NOT reported in the thesis. With only 2 countries,
*     country-level clustering produces only 2 clusters (unreliable). The
*     country-wave alternative (4 clusters) is also too few for reliable
*     inference and adds no information beyond the headline pid-clustered
*     estimate. Retained here for completeness only.
*     TWFE with pid FE is degenerate under 4-cluster VCE (pids perfectly
*     nested within country-wave) — OLS only, presented for reference.
*------------------------------------------------------------------------------
display as result _newline "=== R4. Alt clustering: country-wave (4 clusters), OLS only ==="
preserve
    keep if inlist(wave, 6, 9) & !missing(current_smoker)
    gen byte post_69 = (wave == 9)
    reg current_smoker i.france##i.post_69, vce(cluster countrywave)
    display "(TWFE with pid FE and 4-cluster VCE is degenerate: pids perfectly nested in country-wave)"
restore

*------------------------------------------------------------------------------
* R5. Interim window: W6 (pre) vs W8 (during rollout, ~70% implemented)
*     Companion to headline; shows pattern during implementation phase.
*------------------------------------------------------------------------------
display as result _newline "=== R5. Interim: W6 vs W8 ==="
preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker)
    tab wave france
    reg current_smoker i.france##i.post_w, vce(cluster pid)
    reghdfe current_smoker c.france#c.post_w, absorb(pid wave) vce(cluster pid)
restore

*------------------------------------------------------------------------------
* R6. Sensitivity: W6 (pre) vs W8+W9 pooled
*------------------------------------------------------------------------------
display as result _newline "=== R6. Pooled post: W6 vs W8+W9 ==="
preserve
    keep if inlist(wave, 6, 8, 9) & !missing(current_smoker)
    gen byte post_89 = inlist(wave, 8, 9)
    tab wave france
    reg current_smoker i.france##i.post_89, vce(cluster pid)
    reghdfe current_smoker c.france#c.post_89, absorb(pid wave) vce(cluster pid)
restore
