*==============================================================================
* 08_graph_trends.do
*
* Graph 1: Wave-by-wave smoking prevalence, France vs Germany
*           (raw trends, both forward-filled and direct-obs only)
*
* Run manually in Stata. Graph will appear in the Results window.
* To save: File > Save Graph, or uncomment the graph export lines below.
*==============================================================================

clear all
set more off
version 17

local root "$root"
use "`root'/data_build/panel_frde_outcomes.dta", clear

*------------------------------------------------------------------------------
* (A) Forward-filled prevalence (full sample)
*------------------------------------------------------------------------------
preserve
    keep if !missing(current_smoker)
    collapse (mean) prev = current_smoker (count) n = current_smoker, ///
        by(wave france)

    * real interview year midpoints by wave
    gen year = .
    replace year = 2004 if wave == 1
    replace year = 2006 if wave == 2
    replace year = 2011 if wave == 4
    replace year = 2013 if wave == 5
    replace year = 2015 if wave == 6
    replace year = 2019 if wave == 8
    replace year = 2021 if wave == 9

    label define france_l 0 "Germany" 1 "France"
    label values france france_l

    twoway ///
        (connected prev year if france == 0, ///
            lcolor(navy) mcolor(navy) msymbol(circle) lpattern(solid)) ///
        (connected prev year if france == 1, ///
            lcolor(maroon) mcolor(maroon) msymbol(square) lpattern(solid)) ///
        , xline(2017, lcolor(gray) lpattern(dash)) ///
          xlabel(2004 "W1" 2006 "W2" 2011 "W4" 2013 "W5" ///
                 2015 "W6" 2019 "W8" 2021 "W9", angle(0)) ///
          ylabel(0.10 "10%" 0.15 "15%" 0.20 "20%" 0.25 "25%" ///
                 0.30 "30%", grid glcolor(gs14)) ///
          xtitle("SHARE wave") ///
          ytitle("Current smoker prevalence") ///
          title("Smoking prevalence — France vs Germany, age 50+") ///
          subtitle("Forward-filled smoking status; dashed line = 2017 tax reform") ///
          legend(order(1 "Germany (control)" 2 "France (treated)") ///
                 pos(1) ring(0) cols(1)) ///
          scheme(s2mono)
    * graph export "`root'/output/fig1a_trends_ff.png", replace width(2400)
restore

*------------------------------------------------------------------------------
* (B) Direct-observation-only prevalence (cs_imputed == 0)
*------------------------------------------------------------------------------
preserve
    keep if !missing(current_smoker)
    keep if cs_imputed == 0
    collapse (mean) prev = current_smoker (count) n = current_smoker, ///
        by(wave france)

    gen year = .
    replace year = 2004 if wave == 1
    replace year = 2006 if wave == 2
    replace year = 2011 if wave == 4
    replace year = 2013 if wave == 5
    replace year = 2015 if wave == 6
    replace year = 2019 if wave == 8
    replace year = 2021 if wave == 9

    label define france_l 0 "Germany" 1 "France"
    label values france france_l

    twoway ///
        (connected prev year if france == 0, ///
            lcolor(navy) mcolor(navy) msymbol(circle) lpattern(solid)) ///
        (connected prev year if france == 1, ///
            lcolor(maroon) mcolor(maroon) msymbol(square) lpattern(solid)) ///
        , xline(2017, lcolor(gray) lpattern(dash)) ///
          xlabel(2004 "W1" 2006 "W2" 2011 "W4" 2013 "W5" ///
                 2015 "W6" 2019 "W8" 2021 "W9", angle(0)) ///
          ylabel(0.10 "10%" 0.15 "15%" 0.20 "20%" 0.25 "25%" ///
                 0.30 "30%", grid glcolor(gs14)) ///
          xtitle("SHARE wave") ///
          ytitle("Current smoker prevalence") ///
          title("Smoking prevalence — France vs Germany, age 50+") ///
          subtitle("Direct observations only (no forward-fill); dashed = 2017 reform") ///
          legend(order(1 "Germany (control)" 2 "France (treated)") ///
                 pos(1) ring(0) cols(1)) ///
          scheme(s2mono)
    * graph export "`root'/output/fig1b_trends_direct.png", replace width(2400)
restore
