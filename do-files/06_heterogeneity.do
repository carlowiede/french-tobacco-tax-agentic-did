*------------------------------------------------------------------------------
* 06_heterogeneity.do
*
* Heterogeneous treatment effects for the France tobacco-tax DiD.
*   H1. By sex (female vs male)
*   H2. By education (low/mid/high, ISCED-97)
*   H3. By age band (50-64, 65-74, 75+)
*
* PRIMARY spec  : W6 (pre) vs W9 (post, full implementation) — HEADLINE
* SECONDARY spec: W6 (pre) vs W8 (during rollout, ~70% implemented)
*
* Each: triple-interaction FE + stratified FE + OLS lincom for subgroup totals.
* Individual-clustered SEs throughout.
*------------------------------------------------------------------------------

clear all
set more off
version 17

local root "$root"
use "`root'/data_build/panel_frde_outcomes.dta", clear

gen byte agecat = .
replace agecat = 1 if age_int >= 50 & age_int <= 64
replace agecat = 2 if age_int >= 65 & age_int <= 74
replace agecat = 3 if age_int >= 75 & !missing(age_int)
label define agecat 1 "50-64" 2 "65-74" 3 "75+"
label values agecat agecat

*==============================================================================
* PRIMARY: W6 (pre) vs W9 (post, full implementation)  *** HEADLINE ***
*==============================================================================
display as result _newline "============================================================"
display as result "PRIMARY HETEROGENEITY: W6 (pre) vs W9 (post, full implementation)"
display as result "============================================================"

preserve
    keep if inlist(wave, 6, 9) & !missing(current_smoker)
    gen byte post_69 = (wave == 9)

    *--------------------------------------------------------------------------
    * H1. By sex
    *--------------------------------------------------------------------------
    display as result _newline "=== H1. Triple FE: female x france x post_69 ==="
    reghdfe current_smoker c.france#c.post_69 c.france#c.post_69#c.female ///
        c.female#c.post_69, absorb(pid wave) vce(cluster pid)

    display as result _newline "=== H1. OLS lincom: subgroup totals by sex ==="
    reg current_smoker i.france##i.post_69##i.female, vce(cluster pid)
    display "Effect for MEN (female=0):"
    lincom 1.france#1.post_69
    display "Effect for WOMEN (female=1):"
    lincom 1.france#1.post_69 + 1.france#1.post_69#1.female

    *--------------------------------------------------------------------------
    * H2. By education
    *--------------------------------------------------------------------------
    display as result _newline "=== H2. Triple FE: edu_high x france x post_69 ==="
    reghdfe current_smoker c.france#c.post_69 c.france#c.post_69#c.edu_high ///
        c.edu_high#c.post_69, absorb(pid wave) vce(cluster pid)

    display as result _newline "=== H2. Stratified FE by education group ==="
    foreach grp in edu_low edu_mid edu_high {
        display as result "  -- `grp' == 1 --"
        reghdfe current_smoker c.france#c.post_69 if `grp' == 1, ///
            absorb(pid wave) vce(cluster pid)
    }

    *--------------------------------------------------------------------------
    * H3. By age band
    *--------------------------------------------------------------------------
    display as result _newline "=== H3. Triple OLS: agecat x france x post_69 ==="
    reg current_smoker i.france##i.post_69##i.agecat, vce(cluster pid)
    display "Effect 50-64 (agecat=1):"
    lincom 1.france#1.post_69
    display "Effect 65-74 (agecat=2):"
    lincom 1.france#1.post_69 + 1.france#1.post_69#2.agecat
    display "Effect 75+ (agecat=3):"
    lincom 1.france#1.post_69 + 1.france#1.post_69#3.agecat

    display as result _newline "=== H3. Stratified FE by age band ==="
    forvalues a = 1/3 {
        display as result "  -- agecat == `a' --"
        reghdfe current_smoker c.france#c.post_69 if agecat == `a', ///
            absorb(pid wave) vce(cluster pid)
    }
restore

*==============================================================================
* SECONDARY: W6 (pre) vs W8 (during rollout, ~70% implemented)
*==============================================================================
display as result _newline "============================================================"
display as result "SECONDARY HETEROGENEITY: W6 (pre) vs W8 (during rollout)"
display as result "============================================================"

preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker)

    *--------------------------------------------------------------------------
    * H1. By sex
    *--------------------------------------------------------------------------
    display as result _newline "=== H1 [W8]. Triple FE: female x france x post_w ==="
    reghdfe current_smoker c.france#c.post_w c.france#c.post_w#c.female ///
        c.female#c.post_w, absorb(pid wave) vce(cluster pid)

    display as result _newline "=== H1 [W8]. OLS lincom: subgroup totals by sex ==="
    reg current_smoker i.france##i.post_w##i.female, vce(cluster pid)
    display "Effect for MEN (female=0):"
    lincom 1.france#1.post_w
    display "Effect for WOMEN (female=1):"
    lincom 1.france#1.post_w + 1.france#1.post_w#1.female

    *--------------------------------------------------------------------------
    * H2. By education
    *--------------------------------------------------------------------------
    display as result _newline "=== H2 [W8]. Triple FE: edu_high x france x post_w ==="
    reghdfe current_smoker c.france#c.post_w c.france#c.post_w#c.edu_high ///
        c.edu_high#c.post_w, absorb(pid wave) vce(cluster pid)

    display as result _newline "=== H2 [W8]. Stratified FE by education group ==="
    foreach grp in edu_low edu_mid edu_high {
        display as result "  -- `grp' == 1 --"
        reghdfe current_smoker c.france#c.post_w if `grp' == 1, ///
            absorb(pid wave) vce(cluster pid)
    }

    *--------------------------------------------------------------------------
    * H3. By age band
    *--------------------------------------------------------------------------
    display as result _newline "=== H3 [W8]. Triple OLS: agecat x france x post_w ==="
    reg current_smoker i.france##i.post_w##i.agecat, vce(cluster pid)
    display "Effect 50-64 (agecat=1):"
    lincom 1.france#1.post_w
    display "Effect 65-74 (agecat=2):"
    lincom 1.france#1.post_w + 1.france#1.post_w#2.agecat
    display "Effect 75+ (agecat=3):"
    lincom 1.france#1.post_w + 1.france#1.post_w#3.agecat

    display as result _newline "=== H3 [W8]. Stratified FE by age band ==="
    forvalues a = 1/3 {
        display as result "  -- agecat == `a' --"
        reghdfe current_smoker c.france#c.post_w if agecat == `a', ///
            absorb(pid wave) vce(cluster pid)
    }

    *--------------------------------------------------------------------------
    * H*. cigs_day heterogeneity by sex (thin in W6, interpret with caution)
    *--------------------------------------------------------------------------
    display as result _newline "=== H* [W8]. cigs_day x sex (intensive margin, use cap) ==="
    cap reghdfe cigs_day c.france#c.post_w c.france#c.post_w#c.female ///
        c.female#c.post_w if current_smoker == 1, absorb(pid wave) vce(cluster pid)
restore
