*==============================================================================
* 12_income_heterogeneity.do
*
* Heterogeneous treatment effects by income/financial situation.
* Income proxy: co007_ "Is household able to make ends meet?"
*   1 = With great difficulty
*   2 = With some difficulty
*   3 = Fairly easily
*   4 = Easily
*
* Groups:
*   inc_diff  -- binary: 1=difficulty (1-2), 0=no difficulty (3-4)
*   inc_group -- 3-way:  1=difficulty, 2=fairly easily, 3=easily
*
* HEADLINE (Window 0): W6 (pre) vs W9 (post, full implementation)
* INTERIM  (Window I): W6 (pre) vs W8 (during rollout, ~70%)
* SENSITIVITY (Window II): W6 (pre) vs W8+W9 pooled
*
* Requires 00b_merge_income.do to have been run first.
*==============================================================================

clear all
set more off
version 17

local root "$root"
use "`root'/data_build/panel_frde_outcomes.dta", clear

*==============================================================================
* WINDOW 0 (HEADLINE): W6 vs W9 — full post-implementation period
*==============================================================================
display as result _newline "============================================================"
display as result "WINDOW 0 (HEADLINE): W6 (pre) vs W9 (post, full implementation)"
display as result "============================================================"

preserve
    keep if inlist(wave, 6, 9) & !missing(current_smoker)
    gen byte post_69 = (wave == 9)

    *--------------------------------------------------------------------------
    * 0-A. Triple interaction: inc_diff × france × post_69 (FE)
    *--------------------------------------------------------------------------
    display as result _newline "=== 0-A. Triple FE: inc_diff × france × post_69 ==="
    reghdfe current_smoker c.france#c.post_69 c.france#c.post_69#c.inc_diff ///
        c.inc_diff#c.post_69, absorb(pid wave) vce(cluster pid)

    *--------------------------------------------------------------------------
    * 0-B. Subgroup totals via OLS interaction (for lincom)
    *--------------------------------------------------------------------------
    display as result _newline "=== 0-B. OLS interaction: no difficulty (baseline), difficulty ==="
    reg current_smoker i.france##i.post_69##i.inc_diff, vce(cluster pid)
    display "Effect for NO DIFFICULTY (inc_diff=0):"
    lincom 1.france#1.post_69
    display "Effect for DIFFICULTY (inc_diff=1):"
    lincom 1.france#1.post_69 + 1.france#1.post_69#1.inc_diff

    *--------------------------------------------------------------------------
    * 0-C. Stratified FE by 3-group (difficulty / fairly easily / easily)
    *--------------------------------------------------------------------------
    display as result _newline "=== 0-C. Stratified FE by inc_group (3 categories) ==="
    display "Sample sizes:"
    tab inc_group, miss
    foreach g of numlist 1/3 {
        display as result "  -- inc_group == `g' --"
        qui count if inc_group == `g'
        display "    N obs = " r(N)
        reghdfe current_smoker c.france#c.post_69 if inc_group == `g', ///
            absorb(pid wave) vce(cluster pid)
    }
restore

*==============================================================================
* WINDOW I (INTERIM): W6 vs W8 — during phased rollout (~70% implemented)
*==============================================================================
display as result _newline "============================================================"
display as result "WINDOW I (INTERIM): W6 (pre) vs W8 (during rollout)"
display as result "============================================================"

preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker)

    *--------------------------------------------------------------------------
    * I-A. Triple interaction: inc_diff × france × post_w (FE)
    *--------------------------------------------------------------------------
    display as result _newline "=== I-A. Triple FE: inc_diff × france × post_w ==="
    reghdfe current_smoker c.france#c.post_w c.france#c.post_w#c.inc_diff ///
        c.inc_diff#c.post_w, absorb(pid wave) vce(cluster pid)

    *--------------------------------------------------------------------------
    * I-B. Subgroup totals via OLS interaction (for lincom)
    *--------------------------------------------------------------------------
    display as result _newline "=== I-B. OLS interaction: no difficulty (baseline), difficulty ==="
    reg current_smoker i.france##i.post_w##i.inc_diff, vce(cluster pid)
    display "Effect for NO DIFFICULTY (inc_diff=0):"
    lincom 1.france#1.post_w
    display "Effect for DIFFICULTY (inc_diff=1):"
    lincom 1.france#1.post_w + 1.france#1.post_w#1.inc_diff

    *--------------------------------------------------------------------------
    * I-C. Stratified FE by 3-group (difficulty / fairly easily / easily)
    *--------------------------------------------------------------------------
    display as result _newline "=== I-C. Stratified FE by inc_group (3 categories) ==="
    display "Sample sizes:"
    tab inc_group, miss
    foreach g of numlist 1/3 {
        display as result "  -- inc_group == `g' --"
        qui count if inc_group == `g'
        display "    N obs = " r(N)
        reghdfe current_smoker c.france#c.post_w if inc_group == `g', ///
            absorb(pid wave) vce(cluster pid)
    }
restore

*==============================================================================
* WINDOW II (SENSITIVITY): W6 vs W8+W9 pooled
*==============================================================================
display as result _newline "============================================================"
display as result "WINDOW II (SENSITIVITY): W6 (pre) vs W8+W9 pooled (post)"
display as result "============================================================"

preserve
    keep if inlist(wave, 6, 8, 9) & !missing(current_smoker)
    gen byte post_89 = inlist(wave, 8, 9)

    *--------------------------------------------------------------------------
    * II-A. Triple interaction: inc_diff × france × post_89 (FE)
    *--------------------------------------------------------------------------
    display as result _newline "=== II-A. Triple FE: inc_diff × france × post_89 ==="
    reghdfe current_smoker c.france#c.post_89 c.france#c.post_89#c.inc_diff ///
        c.inc_diff#c.post_89, absorb(pid wave) vce(cluster pid)

    *--------------------------------------------------------------------------
    * II-B. Subgroup totals via OLS interaction
    *--------------------------------------------------------------------------
    display as result _newline "=== II-B. OLS interaction: no difficulty vs difficulty ==="
    reg current_smoker i.france##i.post_89##i.inc_diff, vce(cluster pid)
    display "Effect for NO DIFFICULTY (inc_diff=0):"
    lincom 1.france#1.post_89
    display "Effect for DIFFICULTY (inc_diff=1):"
    lincom 1.france#1.post_89 + 1.france#1.post_89#1.inc_diff

    *--------------------------------------------------------------------------
    * II-C. Stratified FE by 3-group
    *--------------------------------------------------------------------------
    display as result _newline "=== II-C. Stratified FE by inc_group (W6 vs W8+W9) ==="
    foreach g of numlist 1/3 {
        display as result "  -- inc_group == `g' --"
        reghdfe current_smoker c.france#c.post_89 if inc_group == `g', ///
            absorb(pid wave) vce(cluster pid)
    }
restore

*==============================================================================
* WINDOW III: Baseline smoking prevalence by income group — descriptive
*   Shows whether baseline rates differ across income groups (context for
*   effect size interpretation). Uses W6 (pre-treatment) only.
*==============================================================================
display as result _newline "=== III. Baseline (W6) smoking prevalence by income group and country ==="
preserve
    keep if wave == 6 & !missing(current_smoker) & !missing(inc_group)
    table france inc_group, stat(mean current_smoker) stat(count current_smoker) nformat(%6.4f)
restore
