*------------------------------------------------------------------------------
* 03_did_baseline.do
*
* Baseline DiD: France (treatment) vs Germany (control), 2017-2020 tobacco tax.
*
* HEADLINE SPEC: Wave 6 (pre, 2015) vs Wave 9 (post, 2021-22)
*   The French tobacco-tax reform was phased in from 2017 through late 2020.
*   Wave 9 captures the first full post-implementation period.
*   Wave 8 (2019-20) sits during the rollout (~70% implemented).
*   W6-vs-W9 is therefore the cleanest pre-vs-post comparison.
*
* Specifications reported in order:
*   [A] PRIMARY:     W6 (pre) vs W9 (post, full implementation)
*   [B] INTERIM:     W6 (pre) vs W8 (during rollout, ~70% implemented)
*   [C] SENSITIVITY: W6 (pre) vs W8+W9 pooled
*
* Each set: OLS | OLS+controls | TWFE (pid + wave)
*------------------------------------------------------------------------------

clear all
set more off
version 17

local root "$root"
use "`root'/data_build/panel_frde_outcomes.dta", clear

*==============================================================================
* SAMPLE SIZE OVERVIEW
*==============================================================================
display as result _newline "=== SAMPLE SIZES ACROSS WINDOWS (current_smoker non-missing) ==="
foreach wlist in "6,9" "6,8" "6,8,9" {
    local label = subinstr("`wlist'", ",", "+", .)
    quietly count if inlist(wave, `wlist') & !missing(current_smoker)
    display "  W`label':  OLS N = " r(N)
}

*==============================================================================
* [A] PRIMARY: W6 (pre, 2015) vs W9 (post, 2021-22)
*     First full post-implementation period.
*==============================================================================
display as result _newline "============================================================"
display as result "[A] PRIMARY: W6 (pre) vs W9 (post, full implementation)"
display as result "============================================================"

preserve
    keep if inlist(wave, 6, 9) & !missing(current_smoker)
    gen byte post_69 = (wave == 9)

    display as result _newline "=== A0. Sample counts ==="
    tab wave france

    display as result _newline "=== A0. 2x2 means: W6 vs W9 ==="
    table france post_69, stat(mean current_smoker) stat(count current_smoker) nformat(%6.4f)

    display as result _newline "=== A1. Pooled OLS: W6 vs W9 ==="
    reg current_smoker i.france##i.post_69, vce(cluster pid)

    display as result _newline "=== A2. OLS + controls: W6 vs W9 ==="
    reg current_smoker i.france##i.post_69 age_int i.female i.isced1997_r, ///
        vce(cluster pid)

    display as result _newline "=== A3. TWFE (pid + wave): W6 vs W9  *** HEADLINE ESTIMATE *** ==="
    reghdfe current_smoker c.france#c.post_69, absorb(pid wave) vce(cluster pid)
restore

*==============================================================================
* [B] INTERIM: W6 (pre, 2015) vs W8 (2019-20, during rollout)
*==============================================================================
display as result _newline "============================================================"
display as result "[B] INTERIM: W6 (pre) vs W8 (during phased rollout)"
display as result "============================================================"

preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker)

    display as result _newline "=== B0. Sample counts ==="
    tab wave france

    display as result _newline "=== B0. 2x2 means: W6 vs W8 ==="
    table france post_w, stat(mean current_smoker) stat(count current_smoker) nformat(%6.4f)

    display as result _newline "=== B1. Pooled OLS: W6 vs W8 ==="
    reg current_smoker i.france##i.post_w, vce(cluster pid)

    display as result _newline "=== B2. OLS + controls: W6 vs W8 ==="
    reg current_smoker i.france##i.post_w age_int i.female i.isced1997_r, ///
        vce(cluster pid)

    display as result _newline "=== B3. TWFE (pid + wave): W6 vs W8 ==="
    reghdfe current_smoker c.france#c.post_w, absorb(pid wave) vce(cluster pid)
restore

*==============================================================================
* [C] SENSITIVITY: W6 (pre) vs W8+W9 pooled
*==============================================================================
display as result _newline "============================================================"
display as result "[C] SENSITIVITY: W6 (pre) vs W8+W9 pooled"
display as result "============================================================"

preserve
    keep if inlist(wave, 6, 8, 9) & !missing(current_smoker)
    gen byte post_89 = inlist(wave, 8, 9)

    display as result _newline "=== C0. 2x2 means: W6 vs W8+W9 ==="
    table france post_89, stat(mean current_smoker) stat(count current_smoker) nformat(%6.4f)

    display as result _newline "=== C1. Pooled OLS: W6 vs W8+W9 ==="
    reg current_smoker i.france##i.post_89, vce(cluster pid)

    display as result _newline "=== C2. OLS + controls: W6 vs W8+W9 ==="
    reg current_smoker i.france##i.post_89 age_int i.female i.isced1997_r, ///
        vce(cluster pid)

    display as result _newline "=== C3. TWFE (pid + wave): W6 vs W8+W9 ==="
    reghdfe current_smoker c.france#c.post_89, absorb(pid wave) vce(cluster pid)
restore
