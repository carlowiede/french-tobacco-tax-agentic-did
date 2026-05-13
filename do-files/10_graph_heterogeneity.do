*==============================================================================
* 10_graph_heterogeneity.do
*
* Graph 3: Heterogeneous treatment effects — forest-plot style
*           Shows FE DiD estimates + 95% CI for each subgroup,
*           for BOTH the W6-vs-W8 and W6-vs-W8+W9 windows side by side.
*
* Subgroups:
*   Overall (all 50+)
*   Income: Difficulty (1-2), Fairly easily (3), Easily (4)
*   Sex:    Men, Women
*   Edu:    Low/mid, High
*   Age:    50-64, 65-74, 75+
*
* Run manually in Stata. Uncomment graph export at bottom to save.
*==============================================================================

clear all
set more off
version 17

local root "$root"
use "`root'/data_build/panel_frde_outcomes.dta", clear

gen byte agecat = .
replace agecat = 1 if age_int >= 50 & age_int <= 64
replace agecat = 2 if age_int >= 65 & age_int <= 74
replace agecat = 3 if age_int >= 75 & !missing(age_int)

*------------------------------------------------------------------------------
* Collect FE DiD estimates for each subgroup, both windows
*------------------------------------------------------------------------------
* window 1: W6 vs W8 | window 2: W6 vs W8+W9

local groups overall inc_diff inc_fairly inc_easy male female edu_loMid edu_hi age5064 age6574 age75

foreach g of local groups {
    foreach w in 68 689 {
        scalar b_`g'_`w'  = .
        scalar se_`g'_`w' = .
    }
}

* -------- W6 vs W8 --------
preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker)

    * overall
    reghdfe current_smoker c.france#c.post_w, absorb(pid wave) vce(cluster pid)
    scalar b_overall_68  = _b[c.france#c.post_w]
    scalar se_overall_68 = _se[c.france#c.post_w]

    * income: difficulty (1-2)
    cap reghdfe current_smoker c.france#c.post_w if inc_group == 1, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_inc_diff_68  = _b[c.france#c.post_w]
    scalar se_inc_diff_68 = _se[c.france#c.post_w]

    * income: fairly easily (3)
    cap reghdfe current_smoker c.france#c.post_w if inc_group == 2, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_inc_fairly_68  = _b[c.france#c.post_w]
    scalar se_inc_fairly_68 = _se[c.france#c.post_w]

    * income: easily (4)
    cap reghdfe current_smoker c.france#c.post_w if inc_group == 3, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_inc_easy_68  = _b[c.france#c.post_w]
    scalar se_inc_easy_68 = _se[c.france#c.post_w]

    * male (female == 0)
    cap reghdfe current_smoker c.france#c.post_w if female == 0, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_male_68  = _b[c.france#c.post_w]
    scalar se_male_68 = _se[c.france#c.post_w]

    * female
    cap reghdfe current_smoker c.france#c.post_w if female == 1, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_female_68  = _b[c.france#c.post_w]
    scalar se_female_68 = _se[c.france#c.post_w]

    * edu low/mid
    cap reghdfe current_smoker c.france#c.post_w if edu_high == 0, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_edu_loMid_68  = _b[c.france#c.post_w]
    scalar se_edu_loMid_68 = _se[c.france#c.post_w]

    * edu high
    cap reghdfe current_smoker c.france#c.post_w if edu_high == 1, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_edu_hi_68  = _b[c.france#c.post_w]
    scalar se_edu_hi_68 = _se[c.france#c.post_w]

    * age 50-64
    cap reghdfe current_smoker c.france#c.post_w if agecat == 1, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_age5064_68  = _b[c.france#c.post_w]
    scalar se_age5064_68 = _se[c.france#c.post_w]

    * age 65-74
    cap reghdfe current_smoker c.france#c.post_w if agecat == 2, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_age6574_68  = _b[c.france#c.post_w]
    scalar se_age6574_68 = _se[c.france#c.post_w]

    * age 75+
    cap reghdfe current_smoker c.france#c.post_w if agecat == 3, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_age75_68  = _b[c.france#c.post_w]
    scalar se_age75_68 = _se[c.france#c.post_w]
restore

* -------- W6 vs W8+W9 --------
preserve
    keep if inlist(wave, 6, 8, 9) & !missing(current_smoker)
    gen byte post_89 = inlist(wave, 8, 9)

    * overall
    reghdfe current_smoker c.france#c.post_89, absorb(pid wave) vce(cluster pid)
    scalar b_overall_689  = _b[c.france#c.post_89]
    scalar se_overall_689 = _se[c.france#c.post_89]

    * income: difficulty (1-2)
    cap reghdfe current_smoker c.france#c.post_89 if inc_group == 1, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_inc_diff_689  = _b[c.france#c.post_89]
    scalar se_inc_diff_689 = _se[c.france#c.post_89]

    * income: fairly easily (3)
    cap reghdfe current_smoker c.france#c.post_89 if inc_group == 2, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_inc_fairly_689  = _b[c.france#c.post_89]
    scalar se_inc_fairly_689 = _se[c.france#c.post_89]

    * income: easily (4)
    cap reghdfe current_smoker c.france#c.post_89 if inc_group == 3, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_inc_easy_689  = _b[c.france#c.post_89]
    scalar se_inc_easy_689 = _se[c.france#c.post_89]

    * male
    cap reghdfe current_smoker c.france#c.post_89 if female == 0, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_male_689  = _b[c.france#c.post_89]
    scalar se_male_689 = _se[c.france#c.post_89]

    * female
    cap reghdfe current_smoker c.france#c.post_89 if female == 1, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_female_689  = _b[c.france#c.post_89]
    scalar se_female_689 = _se[c.france#c.post_89]

    * edu low/mid
    cap reghdfe current_smoker c.france#c.post_89 if edu_high == 0, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_edu_loMid_689  = _b[c.france#c.post_89]
    scalar se_edu_loMid_689 = _se[c.france#c.post_89]

    * edu high
    cap reghdfe current_smoker c.france#c.post_89 if edu_high == 1, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_edu_hi_689  = _b[c.france#c.post_89]
    scalar se_edu_hi_689 = _se[c.france#c.post_89]

    * age 50-64
    cap reghdfe current_smoker c.france#c.post_89 if agecat == 1, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_age5064_689  = _b[c.france#c.post_89]
    scalar se_age5064_689 = _se[c.france#c.post_89]

    * age 65-74
    cap reghdfe current_smoker c.france#c.post_89 if agecat == 2, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_age6574_689  = _b[c.france#c.post_89]
    scalar se_age6574_689 = _se[c.france#c.post_89]

    * age 75+
    cap reghdfe current_smoker c.france#c.post_89 if agecat == 3, ///
        absorb(pid wave) vce(cluster pid)
    scalar b_age75_689  = _b[c.france#c.post_89]
    scalar se_age75_689 = _se[c.france#c.post_89]
restore

*------------------------------------------------------------------------------
* Build plot dataset
*------------------------------------------------------------------------------
clear
* rows: 8 subgroups × 2 windows = 16 obs
* y-axis: subgroup labels, staggered slightly so W8 and W8+W9 don't overlap

input str20 label row window
    "Overall"          11   68
    "Difficulty (1-2)" 10   68
    "Fairly easily (3)" 9   68
    "Easily (4)"        8   68
    "Men"               7   68
    "Women"             6   68
    "Low/mid edu"       5   68
    "High edu"          4   68
    "Age 50-64"         3   68
    "Age 65-74"         2   68
    "Age 75+"           1   68
    "Overall"          11   689
    "Difficulty (1-2)" 10   689
    "Fairly easily (3)" 9   689
    "Easily (4)"        8   689
    "Men"               7   689
    "Women"             6   689
    "Low/mid edu"       5   689
    "High edu"          4   689
    "Age 50-64"         3   689
    "Age 65-74"         2   689
    "Age 75+"           1   689
end

gen coef_pp  = .
gen ci_lo_pp = .
gen ci_hi_pp = .
gen ypos     = row + 0.15*(window == 689) - 0.15*(window == 68)

* fill W6-W8 window
local gs overall inc_diff inc_fairly inc_easy male female edu_loMid edu_hi age5064 age6574 age75
local rows   11 10 9 8 7 6 5 4 3 2 1
local i = 1
foreach g of local gs {
    local r : word `i' of `rows'
    replace coef_pp  = scalar(b_`g'_68)  * 100                                if row == `r' & window == 68
    replace ci_lo_pp = (scalar(b_`g'_68) - 1.96*scalar(se_`g'_68)) * 100     if row == `r' & window == 68
    replace ci_hi_pp = (scalar(b_`g'_68) + 1.96*scalar(se_`g'_68)) * 100     if row == `r' & window == 68
    local ++i
}

* fill W6-W8+W9 window
local gs overall inc_diff inc_fairly inc_easy male female edu_loMid edu_hi age5064 age6574 age75
local rows   11 10 9 8 7 6 5 4 3 2 1
local i = 1
foreach g of local gs {
    local r : word `i' of `rows'
    replace coef_pp  = scalar(b_`g'_689)  * 100                                if row == `r' & window == 689
    replace ci_lo_pp = (scalar(b_`g'_689) - 1.96*scalar(se_`g'_689)) * 100    if row == `r' & window == 689
    replace ci_hi_pp = (scalar(b_`g'_689) + 1.96*scalar(se_`g'_689)) * 100    if row == `r' & window == 689
    local ++i
}

*------------------------------------------------------------------------------
* Plot
*------------------------------------------------------------------------------
* y-axis labels at integer positions (subgroup midpoints)
label define ylbl ///
    11 "Overall" ///
    10 "Income: difficulty" 9 "Income: fairly easily" 8 "Income: easily" ///
    7 "Men" 6 "Women" ///
    5 "Low/mid edu" 4 "High edu" ///
    3 "Age 50-64" 2 "Age 65-74" 1 "Age 75+"
labmask row, values(label)

twoway ///
    (rcap ci_lo_pp ci_hi_pp ypos if window == 68, ///
        horizontal lcolor(navy) lwidth(medium)) ///
    (scatter ypos coef_pp if window == 68, ///
        mcolor(navy) msymbol(circle) msize(medsmall)) ///
    (rcap ci_lo_pp ci_hi_pp ypos if window == 689, ///
        horizontal lcolor(maroon) lwidth(medium)) ///
    (scatter ypos coef_pp if window == 689, ///
        mcolor(maroon) msymbol(square) msize(medsmall)) ///
    , xline(0, lcolor(gray) lpattern(solid) lwidth(thin)) ///
      xlabel(-12 -10 -8 -6 -4 -2 0 2 4, grid glcolor(gs14)) ///
      ylabel(11 "Overall" ///
             10 "Income: difficulty (1-2)" 9 "Income: fairly easily (3)" 8 "Income: easily (4)" ///
             7 "Men" 6 "Women" ///
             5 "Low/mid edu" 4 "High edu" ///
             3 "Age 50-64" 2 "Age 65-74" 1 "Age 75+", angle(0) noticks) ///
      ytitle("") xtitle("DiD estimate (percentage points)") ///
      title("Heterogeneous treatment effects") ///
      subtitle("FE DiD (pid + wave FE); 95% CI; France vs Germany, age 50+") ///
      legend(order(2 "W6 vs W8 only" 4 "W6 vs W8+W9 pooled") ///
             pos(6) ring(0) cols(2)) ///
      ysize(5) xsize(7) ///
      scheme(s2mono)

* graph export "`root'/output/fig3_heterogeneity.png", replace width(2400)
