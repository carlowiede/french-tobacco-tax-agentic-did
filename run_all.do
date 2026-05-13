*==============================================================================
* run_all.do
*
* Master do-file for the France tobacco-tax DiD analysis.
* Runs the full pipeline end-to-end in the correct order.
*
* HEADLINE SPEC: Wave 6 (pre, 2015) vs Wave 9 (post, 2021-22), TWFE.
*   W8 (2019-20) is the interim window (~70% implementation).
*   W6-W9 is the cleanest pre-vs-post comparison.
*
* Pipeline:
*   01_build_panel.do           assemble FR+DE panel from SHARE waves 1/2/4/5/6/8/9
*   02_build_outcomes.do        forward-fill current_smoker; build DiD variables
*   00b_merge_income.do         merge co007_ (make ends meet); partner-fill
*   03_did_baseline.do          [A] W6-W9 primary; [B] W6-W8 interim; [C] W6-W8+W9 sensitivity
*   04_parallel_trends.do       placebo DiDs + event study (ref W6)
*   05_robustness.do            direct-obs / extended pre / balanced / alt windows
*   06_heterogeneity.do         by sex, education, age band (W6-W9 primary + W6-W8 secondary)
*   07_wave9_extended.do        W6 vs W8+W9 pooled heterogeneity + intensive margin
*   12_income_heterogeneity.do  W6-W9 primary / W6-W8 interim / W6-W8+W9 sensitivity
*   robustness_table.do         esttab export: M1-M8 anchored to W6-W9 headline
*
* Author: Carlo Dante Wiede
* Data:   SHARE release 9.0.0 (waves 1, 2, 4, 5, 6, 8, 9)
* Sample: France (country==17) treatment; Germany (country==12) control
*         Respondents age 50+ at interview
* Shock:  2017-2020 French tobacco-tax hike (cigarette price €7 -> €10)
*
* To run: set global root below to your local clone of this repository,
*         then do "run_all.do" from Stata.
*==============================================================================

clear all
set more off
version 17

* !! CHANGE THIS to the path of your local clone of this repository !!
global root "/Users/carlo/MIB/Master Thesis/Latest_Run"

*------------------------------------------------------------------------------
* Root path guard
*   Stops the pipeline immediately if the user has not updated the root path.
*------------------------------------------------------------------------------
if "$root" == "" | "$root" == "/Users/carlo/MIB/Master Thesis/Latest_Run" {
    display as error ""
    display as error "======================================================"
    display as error "  ACTION REQUIRED: Update the root path before running"
    display as error "  Open run_all.do and change the line:"
    display as error `"  global root "/Users/carlo/MIB/Master Thesis/Latest_Run""'
    display as error "  to the path of your local clone of this repository."
    display as error "  Example (Mac):    global root "~/repos/french-tobacco-tax-agentic-did""
    display as error "  Example (Windows): global root "C:/Users/yourname/french-tobacco-tax-agentic-did""
    display as error "======================================================"
    exit 1
}

local root "$root"

cap mkdir "`root'/data_build"
cap mkdir "`root'/output"

*------------------------------------------------------------------------------
* Step 0a -- dependency check
*   Install any required user-written packages if missing.  reghdfe depends
*   on ftools; estout provides esttab for the results table.
*------------------------------------------------------------------------------
foreach pkg in ftools reghdfe estout {
    cap which `pkg'
    if _rc {
        display as result "Installing missing package: `pkg'"
        ssc install `pkg', replace
    }
}

*------------------------------------------------------------------------------
* Step 0b -- open pipeline log
*   Captures every do-file's console output.  File name includes today's
*   date so re-runs keep a history in output/.
*------------------------------------------------------------------------------
local stamp = string(date("`c(current_date)'", "DMY"), "%tdCCYYNNDD")
local logfile "`root'/output/pipeline_`stamp'.log"
cap log close _all
log using "`logfile'", replace text
display as result "Pipeline log: `logfile'"

*------------------------------------------------------------------------------
* Step 1 -- Build raw panel
*   Input:  SHARE wave .dta files under SHARE WAVES/
*   Output: data_build/panel_frde_raw.dta (50,924 person-wave obs)
*------------------------------------------------------------------------------
do "`root'/do-files/01_build_panel.do"

*------------------------------------------------------------------------------
* Step 2 -- Build outcomes and DiD variables
*   - Forward-fill current_smoker across waves (SHARE skip-pattern)
*   - Flag imputed observations (cs_imputed == 1)
*   - Generate france, post_w, did_w, female, edu_low/mid/high, cigs_day
*   Output: data_build/panel_frde_outcomes.dta
*------------------------------------------------------------------------------
do "`root'/do-files/02_build_outcomes.do"

*------------------------------------------------------------------------------
* Step 2b -- Merge household income (co007_ "make ends meet")
*   Merges co007_ from SHARE co module across waves 4/5/6/8/9.
*   Applies within-household partner-fill (99.5% of 2-person HHs have
*   exactly one valid answer).  Creates inc_diff (binary) and inc_group
*   (3-way: 1=difficulty, 2=fairly easily, 3=easily).
*   OVERWRITES data_build/panel_frde_outcomes.dta in place.
*------------------------------------------------------------------------------
do "`root'/do-files/00b_merge_income.do"

*------------------------------------------------------------------------------
* Step 3 -- Baseline DiD
*   [A] PRIMARY:     W6 (pre) vs W9 (post, full implementation)  *** HEADLINE ***
*   [B] INTERIM:     W6 (pre) vs W8 (during rollout, ~70% implemented)
*   [C] SENSITIVITY: W6 (pre) vs W8+W9 pooled
*   Each: 2x2 means; OLS; OLS + controls; TWFE (pid + wave FE)
*------------------------------------------------------------------------------
do "`root'/do-files/03_did_baseline.do"

*------------------------------------------------------------------------------
* Step 4 -- Parallel-trends tests
*   (a) Wave-by-wave means, forward-filled and direct-only
*   (b) Placebo DiDs on pre-treatment pairs (W4-W5, W5-W6, W4-W6)
*   (c) Event study: ib6.wave ## france (ref = W6)
*------------------------------------------------------------------------------
do "`root'/do-files/04_parallel_trends.do"

*------------------------------------------------------------------------------
* Step 5 -- Robustness (anchored to W6-W9 headline)
*   R1  direct-obs only (cs_imputed == 0)  -- addresses W6 imputation gap
*   R2  extended pre period: W5+W6 vs W9
*   R3  balanced panel (respondents in both W6 and W9)
*   R4  alt clustering: country-wave (4 clusters; OLS only, noted non-applicable for TWFE)
*   R5  interim: W6 vs W8 (robustness table column)
*   R6  sensitivity: W6 vs W8+W9 pooled
*------------------------------------------------------------------------------
do "`root'/do-files/05_robustness.do"

*------------------------------------------------------------------------------
* Step 6 -- Heterogeneous effects
*   PRIMARY (W6-W9):   H1 sex / H2 education / H3 age band
*   SECONDARY (W6-W8): same heterogeneity for comparison
*   Reports triple interactions + stratified FE estimates.
*------------------------------------------------------------------------------
do "`root'/do-files/06_heterogeneity.do"

*------------------------------------------------------------------------------
* Step 6b -- Pooled post and intensive margin
*   E1  W6 vs W8+W9 pooled: OLS, OLS+controls, TWFE
*   E2  Heterogeneity on pooled post: sex, education, age band
*   E3  Intensive margin (cigs/day): W8 vs W9, trimmed smokers only
*------------------------------------------------------------------------------
do "`root'/do-files/07_wave9_extended.do"

*------------------------------------------------------------------------------
* Step 6c -- Income heterogeneity
*   Window 0 (PRIMARY):     W6 vs W9, triple FE + stratified
*   Window I (INTERIM):     W6 vs W8, triple FE + stratified
*   Window II (SENSITIVITY): W6 vs W8+W9 pooled
*   Stratified by inc_group: difficulty / fairly easily / easily.
*   This is the thesis's second research question.
*------------------------------------------------------------------------------
do "`root'/do-files/12_income_heterogeneity.do"

*------------------------------------------------------------------------------
* Step 7 -- Results table for export
*   Produces output/robustness_table.rtf and .tex
*------------------------------------------------------------------------------
do "`root'/do-files/robustness_table.do"

display as result _newline "=============================================="
display as result "Pipeline complete."
display as result "Key results (headline: W6 pre vs W9 post):"
display as result "  TWFE DiD (W6 vs W9)       = -2.71pp, p<0.001  *** HEADLINE ***"
display as result "  TWFE DiD (W6 vs W8)       = -2.30pp, p=0.001  (interim)"
display as result "  TWFE DiD (W6 vs W8+W9)    = -2.46pp, p<0.001  (pooled sensitivity)"
display as result "  Income triple (W6 vs W9)  = -5.83pp extra for difficulty, p=0.018"
display as result "See results_summary.md for full interpretation."
display as result "Full log: `logfile'"
display as result "=============================================="

log close
