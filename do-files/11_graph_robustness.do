*==============================================================================
* 11_graph_robustness.do
*
* Graph 4: Robustness dot-plot
*           All 7 specifications, point estimate + 95% CI
*           Sorted by specification type (OLS vs FE)
*
* Run manually in Stata. Uncomment graph export at bottom to save.
*==============================================================================

clear all
set more off
version 17

local root "$root"
use "`root'/data_build/panel_frde_outcomes.dta", clear

gen int countrywave = country * 100 + wave

*------------------------------------------------------------------------------
* Run all specs and store estimates
*------------------------------------------------------------------------------

* M1 — OLS W6 vs W8
preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker)
    reg current_smoker i.france##i.post_w, vce(cluster pid)
    scalar b_m1  = _b[1.france#1.post_w]
    scalar se_m1 = _se[1.france#1.post_w]
restore

* M2 — OLS + controls
preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker)
    reg current_smoker i.france##i.post_w age_int i.female i.isced1997_r, ///
        vce(cluster pid)
    scalar b_m2  = _b[1.france#1.post_w]
    scalar se_m2 = _se[1.france#1.post_w]
restore

* M3 — FE primary W6 vs W8
preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker)
    reghdfe current_smoker c.france#c.post_w, absorb(pid wave) vce(cluster pid)
    scalar b_m3  = _b[c.france#c.post_w]
    scalar se_m3 = _se[c.france#c.post_w]
restore

* M4 — FE direct-obs only
preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker) & cs_imputed == 0
    reghdfe current_smoker c.france#c.post_w, absorb(pid wave) vce(cluster pid)
    scalar b_m4  = _b[c.france#c.post_w]
    scalar se_m4 = _se[c.france#c.post_w]
restore

* M5 — FE W6 vs W9
preserve
    keep if inlist(wave, 6, 9) & !missing(current_smoker)
    gen byte post_69 = (wave == 9)
    reghdfe current_smoker c.france#c.post_69, absorb(pid wave) vce(cluster pid)
    scalar b_m5  = _b[c.france#c.post_69]
    scalar se_m5 = _se[c.france#c.post_69]
restore

* M6 — FE W5+W6 vs W8+W9 pooled
preserve
    keep if inlist(wave, 5, 6, 8, 9) & !missing(current_smoker)
    gen byte post4 = inlist(wave, 8, 9)
    reghdfe current_smoker c.france#c.post4, absorb(pid wave) vce(cluster pid)
    scalar b_m6  = _b[c.france#c.post4]
    scalar se_m6 = _se[c.france#c.post4]
restore

* M7 — FE balanced panel
preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker)
    bysort pid: gen byte nwaves = _N
    keep if nwaves == 2
    reghdfe current_smoker c.france#c.post_w, absorb(pid wave) vce(cluster pid)
    scalar b_m7  = _b[c.france#c.post_w]
    scalar se_m7 = _se[c.france#c.post_w]
restore

* M8 — FE W6 vs W8+W9 pooled (co-primary)
preserve
    keep if inlist(wave, 6, 8, 9) & !missing(current_smoker)
    gen byte post_89 = inlist(wave, 8, 9)
    reghdfe current_smoker c.france#c.post_89, absorb(pid wave) vce(cluster pid)
    scalar b_m8  = _b[c.france#c.post_89]
    scalar se_m8 = _se[c.france#c.post_89]
restore

*------------------------------------------------------------------------------
* Build plot dataset
*------------------------------------------------------------------------------
clear
input str30 label row fe
    "OLS (W6 vs W8)"              8   0
    "OLS + controls"              7   0
    "FE primary (W6 vs W8)"       6   1
    "FE direct-obs only"          5   1
    "FE W6 vs W9"                 4   1
    "FE pooled (W5+6 vs W8+9)"    3   1
    "FE balanced panel"           2   1
    "FE W6 vs W8+W9 (co-primary)" 1   1
end

gen coef_pp  = .
gen ci_lo_pp = .
gen ci_hi_pp = .

local specs 1 2 3 4 5 6 7 8
local rows   8 7 6 5 4 3 2 1
local i = 1
foreach s of local specs {
    local r : word `i' of `rows'
    replace coef_pp  = scalar(b_m`s')  * 100                              if row == `r'
    replace ci_lo_pp = (scalar(b_m`s') - 1.96*scalar(se_m`s')) * 100     if row == `r'
    replace ci_hi_pp = (scalar(b_m`s') + 1.96*scalar(se_m`s')) * 100     if row == `r'
    local ++i
}

*------------------------------------------------------------------------------
* Plot
*------------------------------------------------------------------------------
twoway ///
    (rcap ci_lo_pp ci_hi_pp row if fe == 0, ///
        horizontal lcolor(maroon) lwidth(medium)) ///
    (scatter row coef_pp if fe == 0, ///
        mcolor(maroon) msymbol(triangle) msize(medium)) ///
    (rcap ci_lo_pp ci_hi_pp row if fe == 1, ///
        horizontal lcolor(navy) lwidth(medium)) ///
    (scatter row coef_pp if fe == 1, ///
        mcolor(navy) msymbol(circle) msize(medium)) ///
    , xline(0, lcolor(gray) lpattern(solid) lwidth(thin)) ///
      xlabel(-6 -4 -2 0 2, grid glcolor(gs14)) ///
      ylabel(8 "OLS (W6 vs W8)" ///
             7 "OLS + controls" ///
             6 "FE primary (W6 vs W8)" ///
             5 "FE direct-obs only" ///
             4 "FE W6 vs W9" ///
             3 "FE pooled (W5+6 vs W8+9)" ///
             2 "FE balanced panel" ///
             1 "FE W6 vs W8+W9", angle(0) noticks) ///
      ytitle("") xtitle("DiD estimate (percentage points)") ///
      title("Robustness: all specifications") ///
      subtitle("France vs Germany, age 50+; 95% CI; clustered by individual") ///
      legend(order(2 "Pooled OLS" 4 "Two-way FE") pos(6) ring(0) cols(2)) ///
      ysize(5) xsize(7) ///
      scheme(s2mono)

* graph export "`root'/output/fig4_robustness.png", replace width(2400)
