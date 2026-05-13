*==============================================================================
* 09_graph_event_study.do
*
* Figure 2: Event-study estimates (France × wave dummies, ref = W6).
*
* Regression: reghdfe current_smoker ib6.wave##c.france, absorb(pid) vce(cluster pid)
* Sample: waves 4, 5, 6, 8, 9 with non-missing current_smoker (N=33,028; 10,128 pids).
*
* VERIFIED coefficients (pp, 95% CI, p-value):
*   W4: −1.00  [−2.64, +0.64]  p=0.233
*   W5: +0.35  [−0.12, +0.81]  p=0.145
*   W6:  0.00  (reference)
*   W8: −2.20  [−3.45, −0.96]  p=0.001
*   W9: −2.48  [−3.82, −1.14]  p=0.0003
*
* Note: W9 event-study coef = −2.48pp. The two-wave W6-vs-W9 TWFE gives
* −2.71pp — different spec (only pid+wave FE, two waves only). Not a
* discrepancy; both are correct for their respective models.
*==============================================================================

clear all
set more off
version 17

local root "$root"
use "`root'/data_build/panel_frde_outcomes.dta", clear

keep if inlist(wave, 4, 5, 6, 8, 9)
keep if !missing(current_smoker)

*------------------------------------------------------------------------------
* Step 1: Run regression and print output for log verification
*------------------------------------------------------------------------------
display as result _newline "=== EVENT STUDY REGRESSION (verification) ==="
reghdfe current_smoker ib6.wave##c.france, absorb(pid) vce(cluster pid)

display as result _newline "=== COEFFICIENTS IN PERCENTAGE POINTS ==="
foreach w in 4 5 8 9 {
    local b  = _b[`w'.wave#c.france]
    local se = _se[`w'.wave#c.france]
    local lo = (`b' - 1.96*`se') * 100
    local hi = (`b' + 1.96*`se') * 100
    local t  = `b'/`se'
    local p  = 2*(1 - normal(abs(`t')))
    display as result "  W`w': " %6.2f (`b'*100) "pp  SE=" %5.2f (`se'*100) "  95%CI=[" %6.2f `lo' ", " %6.2f `hi' "]  p=" %6.4f `p'
}

*------------------------------------------------------------------------------
* Step 2: Save scalars
*------------------------------------------------------------------------------
foreach w in 4 5 8 9 {
    scalar b_`w'  = _b[`w'.wave#c.france]
    scalar se_`w' = _se[`w'.wave#c.france]
}

*------------------------------------------------------------------------------
* Step 3: Build plotting dataset
*------------------------------------------------------------------------------
clear
input wave_num coef_pp ci_lo_pp ci_hi_pp year
    4   .   .   .   2011
    5   .   .   .   2013
    6   0   0   0   2015
    8   .   .   .   2019
    9   .   .   .   2021
end

foreach w in 4 5 8 9 {
    replace coef_pp  = scalar(b_`w') * 100                            if wave_num == `w'
    replace ci_lo_pp = (scalar(b_`w') - 1.96*scalar(se_`w')) * 100   if wave_num == `w'
    replace ci_hi_pp = (scalar(b_`w') + 1.96*scalar(se_`w')) * 100   if wave_num == `w'
}

*------------------------------------------------------------------------------
* Step 4: Plot
*------------------------------------------------------------------------------
twoway ///
    (rcap ci_lo_pp ci_hi_pp year if wave_num != 6, ///
        lcolor(navy) lwidth(medthin)) ///
    (scatter coef_pp year, ///
        mcolor(navy) msymbol(circle) msize(medsmall)) ///
    , yline(0, lcolor(gs10) lpattern(solid) lwidth(thin)) ///
      xline(2017, lcolor(cranberry) lpattern(dash) lwidth(thin)) ///
      xlabel(2011 "W4" 2013 "W5" 2015 "W6 (ref)" ///
             2019 "W8" 2021 "W9", angle(0) labsize(small)) ///
      ylabel(-6 -4 -2 0 2 4, grid glcolor(gs14) glwidth(vthin) angle(0)) ///
      xtitle("SHARE wave", size(small)) ///
      ytitle("Gap relative to Wave 6 (pp)", size(small) margin(r=3)) ///
      title("Event study: smoking-prevalence gap relative to Wave 6", ///
            size(medsmall) margin(b=2)) ///
      legend(order(1 "95% confidence interval" 2 "Point estimate") ///
             pos(6) row(1) size(vsmall) region(lstyle(none))) ///
      graphregion(color(white) margin(l=4 r=4 t=2 b=2)) ///
      plotregion(margin(l=1 r=1 t=1 b=1)) ///
      scheme(s2mono)

graph export "`root'/writeup/fig2_event_study.png", replace width(2400)
display as result _newline "Figure saved: `root'/writeup/fig2_event_study.png"
