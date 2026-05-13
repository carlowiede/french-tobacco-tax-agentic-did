*------------------------------------------------------------------------------
* 07_wave9_extended.do
*
* Extend the primary DiD to use BOTH post-treatment waves (W8 + W9 pooled
* as the post period), alongside the W6-vs-W8-only primary.
*
*   E1. Primary with pooled post: W6 (pre) vs W8+W9 (post), OLS & FE
*   E2. Heterogeneity on pooled post: sex, education, age band
*   E3. Intensive margin (cigs/day) -- levels France vs Germany at W8 and W9
*       (W6 too thin for DiD; present as post-period comparison only)
*
* Runs on same panel as 03_/06_. Individual-clustered SEs throughout.
*------------------------------------------------------------------------------

clear all
set more off
version 17

local root "$root"
use "`root'/data_build/panel_frde_outcomes.dta", clear

* age band at interview (same coding as 06_heterogeneity.do)
gen byte agecat = .
replace agecat = 1 if age_int >= 50 & age_int <= 64
replace agecat = 2 if age_int >= 65 & age_int <= 74
replace agecat = 3 if age_int >= 75 & !missing(age_int)
label define agecat 1 "50-64" 2 "65-74" 3 "75+"
label values agecat agecat

*------------------------------------------------------------------------------
* E1. Primary spec with pooled post (W6 pre, W8+W9 post)
*------------------------------------------------------------------------------
preserve
    keep if inlist(wave, 6, 8, 9)
    keep if !missing(current_smoker)
    gen byte post_89 = inlist(wave, 8, 9)

    display as result _newline "=== E1a. 2x2 means: W6 vs W8+W9 pooled ==="
    table france post_89, stat(mean current_smoker) stat(count current_smoker) ///
        nformat(%6.4f)

    display as result _newline "=== E1b. OLS DiD: W6 vs W8+W9 pooled ==="
    reg current_smoker i.france##i.post_89, vce(cluster pid)

    display as result _newline "=== E1c. OLS + controls: W6 vs W8+W9 pooled ==="
    reg current_smoker i.france##i.post_89 age_int i.female i.isced1997_r, ///
        vce(cluster pid)

    display as result _newline "=== E1d. Two-way FE: W6 vs W8+W9 pooled ==="
    reghdfe current_smoker c.france#c.post_89, absorb(pid wave) vce(cluster pid)
restore

*------------------------------------------------------------------------------
* E2. Heterogeneity with pooled post
*------------------------------------------------------------------------------
preserve
    keep if inlist(wave, 6, 8, 9)
    keep if !missing(current_smoker)
    gen byte post_89 = inlist(wave, 8, 9)

    *-- E2a. By sex
    display as result _newline "=== E2a. Triple: female x france x post_89 (FE) ==="
    reghdfe current_smoker c.france#c.post_89 c.france#c.post_89#c.female ///
        c.female#c.post_89, absorb(pid wave) vce(cluster pid)

    display as result _newline "=== E2a. Subgroup totals by sex (OLS interaction) ==="
    reg current_smoker i.france##i.post_89##i.female, vce(cluster pid)
    display "Effect for MEN:"
    lincom 1.france#1.post_89
    display "Effect for WOMEN:"
    lincom 1.france#1.post_89 + 1.france#1.post_89#1.female

    *-- E2b. By education
    display as result _newline "=== E2b. Triple: edu_high x france x post_89 (FE) ==="
    reghdfe current_smoker c.france#c.post_89 c.france#c.post_89#c.edu_high ///
        c.edu_high#c.post_89, absorb(pid wave) vce(cluster pid)

    display as result _newline "=== E2b. Stratified FE by education group ==="
    foreach grp in edu_low edu_mid edu_high {
        display as result "  -- `grp' == 1 --"
        reghdfe current_smoker c.france#c.post_89 if `grp' == 1, ///
            absorb(pid wave) vce(cluster pid)
    }

    *-- E2c. By age band
    display as result _newline "=== E2c. Triple: agecat x france x post_89 (OLS) ==="
    reg current_smoker i.france##i.post_89##i.agecat, vce(cluster pid)
    display "Effect 50-64:"
    lincom 1.france#1.post_89
    display "Effect 65-74:"
    lincom 1.france#1.post_89 + 1.france#1.post_89#2.agecat
    display "Effect 75+:"
    lincom 1.france#1.post_89 + 1.france#1.post_89#3.agecat

    display as result _newline "=== E2c. Stratified FE by age band ==="
    forvalues a = 1/3 {
        display as result "  -- agecat == `a' --"
        reghdfe current_smoker c.france#c.post_89 if agecat == `a', ///
            absorb(pid wave) vce(cluster pid)
    }
restore

*------------------------------------------------------------------------------
* E3. Intensive margin: cigs/day at W8 and W9, France vs Germany
*     (W6 cell sizes too thin for a credible DiD; present W8 and W9 levels)
*------------------------------------------------------------------------------
preserve
    keep if inlist(wave, 8, 9)
    keep if current_smoker == 1 & !missing(cigs_day)
    * Methodology: keep 1 <= cigs_day <= 40.  0 = occasional smokers who
    * reported current-smoker status but 0 cigs/day -> dropped from intensive
    * margin; >40 = likely misreporting, also dropped.
    count if cigs_day < 1
    display as result "Dropped `r(N)' observations with cigs_day < 1 (occasional smokers)"
    replace cigs_day = . if cigs_day < 1 | cigs_day > 40
    drop if missing(cigs_day)

    display as result _newline "=== E3a. Cells for cigs_day at W8/W9 (smokers, trimmed) ==="
    table wave france, stat(count cigs_day) stat(mean cigs_day) nformat(%6.2f)

    display as result _newline "=== E3b. OLS levels DiD: W8 vs W9, trimmed ==="
    gen byte post_89 = (wave == 9)
    reg cigs_day i.france##i.post_89, vce(cluster pid)

    display as result _newline "=== E3c. FE: W8 vs W9, trimmed ==="
    reghdfe cigs_day c.france#c.post_89, absorb(pid wave) vce(cluster pid)
restore
