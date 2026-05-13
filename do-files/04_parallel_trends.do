*------------------------------------------------------------------------------
* 04_parallel_trends.do
*
* Test the parallel-trends assumption for the France vs Germany DiD.
*  (a) Visual: wave-by-wave means of current_smoker by country.
*  (b) Placebo DiD on pre-treatment waves only (4 -> 5, 5 -> 6).
*  (c) Event study style: interact country with wave dummies,
*      Wave 6 as the reference (last pre-treatment wave).
*
* All specs run on directly-observed current_smoker (cs_imputed == 0)
* as main, with forward-filled as robustness — the skip-pattern
* imputation is asymmetric across waves (very high in W6, low in W8/W9).
*------------------------------------------------------------------------------

clear all
set more off
version 17

local root "$root"
cap mkdir "`root'/output"
use "`root'/data_build/panel_frde_outcomes.dta", clear

*------------------------------------------------------------------------------
* (a) Wave-by-wave means, forward-filled vs direct-only
*------------------------------------------------------------------------------
display as result _newline "=== (a) Wave-by-wave means — forward-filled ==="
table wave france, stat(mean current_smoker) stat(count current_smoker) nformat(%6.4f)

display as result _newline "=== (a) Wave-by-wave means — DIRECT OBSERVATION ONLY ==="
table wave france if cs_imputed == 0 & !missing(br002_), ///
    stat(mean current_smoker) stat(count current_smoker) nformat(%6.4f)
* note the condition: we want direct observations at THIS wave, so
* !missing(br002_) AND ever_smoker == 1/0 via direct observation path.
* That's what cs_imputed == 0 is on ever_smoker!=0 branch; we also need
* ever_smoker==0 to be flagged direct (it isn't — those have missing
* br002_). So for prevalence-by-wave we actually want: either direct
* br002_ OR ever_smoker==0 (known non-smoker). Both are non-imputed.
display as result _newline "=== (a') Non-imputed (direct br002_ OR known never-smoker) ==="
table wave france if cs_imputed == 0, ///
    stat(mean current_smoker) stat(count current_smoker) nformat(%6.4f)

*------------------------------------------------------------------------------
* (b) Placebo DiD on pre-treatment waves (should be 0 if PT holds)
*     spec 1: W4 (pre-pre) vs W5 (pre), fake treatment at W5
*     spec 2: W5 (pre-pre) vs W6 (pre), fake treatment at W6
*     spec 3: W4 (pre-pre) vs W6 (pre), fake treatment at W6
*------------------------------------------------------------------------------
foreach spec in "4 5" "5 6" "4 6" {
    tokenize "`spec'"
    local pre  = `1'
    local post = `2'
    display as result _newline "=== (b) Placebo DiD: W`pre' vs W`post' (pre-treatment) ==="
    preserve
        keep if inlist(wave, `pre', `post')
        keep if !missing(current_smoker)
        gen byte placebo_post = (wave == `post')
        reg current_smoker i.france##i.placebo_post, vce(cluster pid)
        display as result "  ---- same, within-person FE ----"
        reghdfe current_smoker c.france#c.placebo_post, absorb(pid wave) vce(cluster pid)
    restore
}

*------------------------------------------------------------------------------
* (c) Event study: interact france with wave dummies, reference = W6
*     Use waves 4, 5, 6, 8, 9 (full available set for prevalence).
*------------------------------------------------------------------------------
preserve
    keep if inlist(wave, 4, 5, 6, 8, 9)
    keep if !missing(current_smoker)

    display as result _newline "=== (c) Event study: ref wave 6 ==="
    reghdfe current_smoker ib6.wave##c.france, absorb(pid) vce(cluster pid)
restore
