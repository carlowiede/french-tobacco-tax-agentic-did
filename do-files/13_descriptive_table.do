*==============================================================================
* 13_descriptive_table.do
*
* Descriptive statistics: Wave 6 (pre) and Wave 9 (post), Germany vs France.
* Columns: DE W6 | FR W6 | DE W9 | FR W9
* N appears as a single row at the bottom.
*
* Output:
*   writeup/descriptives.csv   (comma-separated, for Excel / paste)
*   writeup/descriptives.tex   (LaTeX, booktabs, simple header — no cmidrule)
*   writeup/descriptives.txt   (plain text, aligned columns)
*
* Requires 00b_merge_income.do to have been run (inc_diff in panel).
*==============================================================================

clear all
set more off
version 17

local root "$root"
use "`root'/data_build/panel_frde_outcomes.dta", clear

*--- Sample: W6 and W9, current_smoker non-missing ---
keep if inlist(wave, 6, 9)
keep if !missing(current_smoker)

*--- Group variable ---
gen byte grp = .
replace grp = 1 if country == 12 & wave == 6   // DE W6
replace grp = 2 if country == 17 & wave == 6   // FR W6
replace grp = 3 if country == 12 & wave == 9   // DE W9
replace grp = 4 if country == 17 & wave == 9   // FR W9

*--- Binary variables -> percent ---
gen double pct_smoker   = current_smoker * 100
gen double pct_female   = female * 100
gen double pct_edu_low  = edu_low  * 100
gen double pct_edu_mid  = edu_mid  * 100
gen double pct_edu_high = edu_high * 100
gen double pct_inc_diff = inc_diff * 100

*--- Means per group ---
local vars pct_smoker cigs_day age_int pct_female ///
           pct_edu_low pct_edu_mid pct_edu_high pct_inc_diff

foreach v of local vars {
    forvalues g = 1/4 {
        quietly summarize `v' if grp == `g'
        if r(N) > 0  local m_`v'_`g' = string(r(mean), "%6.2f")
        else         local m_`v'_`g' "."
    }
}

*--- N per group (main analysis sample) ---
forvalues g = 1/4 {
    quietly count if grp == `g'
    local n_`g' = r(N)
}

*--- cigs_day subsample N (smokers with non-missing cigs_day) ---
forvalues g = 1/4 {
    quietly count if grp == `g' & current_smoker == 1 & !missing(cigs_day)
    local nc_`g' = r(N)
}

local outfile "`root'/writeup/descriptives"

*==============================================================================
* CSV output
*==============================================================================
file open fout using "`outfile'.csv", write replace
file write fout "Variable,DE Wave 6,FR Wave 6,DE Wave 9,FR Wave 9" _n
file write fout `"Current smoker (%),`m_pct_smoker_1',`m_pct_smoker_2',`m_pct_smoker_3',`m_pct_smoker_4'"' _n
file write fout `"Cigarettes per day (smokers only),`m_cigs_day_1',`m_cigs_day_2',`m_cigs_day_3',`m_cigs_day_4'"' _n
file write fout `"Age at interview,`m_age_int_1',`m_age_int_2',`m_age_int_3',`m_age_int_4'"' _n
file write fout `"Female (%),`m_pct_female_1',`m_pct_female_2',`m_pct_female_3',`m_pct_female_4'"' _n
file write fout `"ISCED 1-2 (%),`m_pct_edu_low_1',`m_pct_edu_low_2',`m_pct_edu_low_3',`m_pct_edu_low_4'"' _n
file write fout `"ISCED 3-4 (%),`m_pct_edu_mid_1',`m_pct_edu_mid_2',`m_pct_edu_mid_3',`m_pct_edu_mid_4'"' _n
file write fout `"ISCED 5+ (%),`m_pct_edu_high_1',`m_pct_edu_high_2',`m_pct_edu_high_3',`m_pct_edu_high_4'"' _n
file write fout `"Financial difficulty (%),`m_pct_inc_diff_1',`m_pct_inc_diff_2',`m_pct_inc_diff_3',`m_pct_inc_diff_4'"' _n
file write fout `"N,`n_1',`n_2',`n_3',`n_4'"' _n
file write fout "" _n
file write fout "Note: Source: SHARE release 9.0.0. Sample: respondents aged 50+ with non-missing current-smoker status." _n
file write fout "Wave 6 = 2015 (pre-treatment); Wave 9 = 2021-22 (post-treatment, full implementation). Education: ISCED-97." _n
file write fout "Financial difficulty: co007_ = 1-2 (with great/some difficulty making ends meet); approx. 2% missing." _n
file write fout `"Cigarettes per day: among smokers with valid br006_ response (W6: n=`nc_1' DE, n=`nc_2' FR; W9: n=`nc_3' DE, n=`nc_4' FR)."' _n
file write fout "All percentages expressed as 0-100. N: main analysis sample (current_smoker non-missing)." _n
file close fout

*==============================================================================
* LaTeX output -- booktabs, simple 5-column layout, note below tabular
*==============================================================================
file open ftex using "`outfile'.tex", write replace
file write ftex "\begin{table}[htbp]" _n
file write ftex "\centering" _n
file write ftex "\caption{Descriptive statistics: France vs Germany, SHARE respondents aged 50+}" _n
file write ftex "\label{tab:descriptives}" _n
file write ftex "\begin{tabular}{lcccc}" _n
file write ftex "\toprule" _n
file write ftex " & DE Wave 6 & FR Wave 6 & DE Wave 9 & FR Wave 9 \\" _n
file write ftex "\midrule" _n
file write ftex `"Current smoker (\%)                    & `m_pct_smoker_1'   & `m_pct_smoker_2'   & `m_pct_smoker_3'   & `m_pct_smoker_4'   \\"' _n
file write ftex `"Cigarettes/day (smokers)\textsuperscript{a}  & `m_cigs_day_1'     & `m_cigs_day_2'     & `m_cigs_day_3'     & `m_cigs_day_4'     \\"' _n
file write ftex `"Age at interview                       & `m_age_int_1'      & `m_age_int_2'      & `m_age_int_3'      & `m_age_int_4'      \\"' _n
file write ftex `"Female (\%)                            & `m_pct_female_1'   & `m_pct_female_2'   & `m_pct_female_3'   & `m_pct_female_4'   \\"' _n
file write ftex `"ISCED 1--2 (\%)                        & `m_pct_edu_low_1'  & `m_pct_edu_low_2'  & `m_pct_edu_low_3'  & `m_pct_edu_low_4'  \\"' _n
file write ftex `"ISCED 3--4 (\%)                        & `m_pct_edu_mid_1'  & `m_pct_edu_mid_2'  & `m_pct_edu_mid_3'  & `m_pct_edu_mid_4'  \\"' _n
file write ftex `"ISCED 5+ (\%)                          & `m_pct_edu_high_1' & `m_pct_edu_high_2' & `m_pct_edu_high_3' & `m_pct_edu_high_4' \\"' _n
file write ftex `"Financial difficulty (\%)              & `m_pct_inc_diff_1' & `m_pct_inc_diff_2' & `m_pct_inc_diff_3' & `m_pct_inc_diff_4' \\"' _n
file write ftex "\midrule" _n
file write ftex `"N                                      & `n_1'              & `n_2'              & `n_3'              & `n_4'              \\"' _n
file write ftex "\bottomrule" _n
file write ftex "\end{tabular}" _n
file write ftex "\par\smallskip" _n
file write ftex "\begin{minipage}{\linewidth}" _n
file write ftex "\footnotesize" _n
file write ftex "\textit{Notes:} Source: SHARE release 9.0.0. Sample: respondents aged 50+ with non-missing" _n
file write ftex "current-smoker status. Wave~6 = 2015 (pre-treatment); Wave~9 = 2021--22 (post-treatment," _n
file write ftex "full implementation). Education: ISCED-97. Financial difficulty: \textit{co007\_} = 1--2" _n
file write ftex "(with great/some difficulty making ends meet); approx.\ 2\% of observations have missing" _n
file write ftex "education or financial difficulty. All percentages expressed as 0--100." _n
file write ftex `"N: main analysis sample.\\"' _n
file write ftex "\textsuperscript{a}~Cigarettes per day: means among smokers with valid \textit{br006\_} response" _n
file write ftex `"only (W6: n=`nc_1' DE, n=`nc_2' FR; W9: n=`nc_3' DE, n=`nc_4' FR)."' _n
file write ftex "\end{minipage}" _n
file write ftex "\end{table}" _n
file close ftex

*==============================================================================
* Plain text output -- aligned columns
*==============================================================================
file open ftxt using "`outfile'.txt", write replace
file write ftxt "Table 1. Descriptive statistics: France vs Germany, SHARE respondents aged 50+" _n
file write ftxt "Source: SHARE release 9.0.0. Wave 6 = 2015 (pre-treatment); Wave 9 = 2021-22 (post-treatment)." _n
file write ftxt "" _n
file write ftxt "----------------------------------------------------------------------" _n
file write ftxt "                                  DE       FR       DE       FR" _n
file write ftxt "                                Wave 6   Wave 6   Wave 9   Wave 9" _n
file write ftxt "----------------------------------------------------------------------" _n
file write ftxt `"Current smoker (%)             `m_pct_smoker_1'     `m_pct_smoker_2'     `m_pct_smoker_3'     `m_pct_smoker_4'"' _n
file write ftxt `"Cigarettes/day (smokers) [a]   `m_cigs_day_1'     `m_cigs_day_2'     `m_cigs_day_3'     `m_cigs_day_4'"' _n
file write ftxt `"Age at interview               `m_age_int_1'     `m_age_int_2'     `m_age_int_3'     `m_age_int_4'"' _n
file write ftxt `"Female (%)                     `m_pct_female_1'     `m_pct_female_2'     `m_pct_female_3'     `m_pct_female_4'"' _n
file write ftxt `"ISCED 1-2 (%)                  `m_pct_edu_low_1'     `m_pct_edu_low_2'     `m_pct_edu_low_3'     `m_pct_edu_low_4'"' _n
file write ftxt `"ISCED 3-4 (%)                  `m_pct_edu_mid_1'     `m_pct_edu_mid_2'     `m_pct_edu_mid_3'     `m_pct_edu_mid_4'"' _n
file write ftxt `"ISCED 5+ (%)                   `m_pct_edu_high_1'     `m_pct_edu_high_2'     `m_pct_edu_high_3'     `m_pct_edu_high_4'"' _n
file write ftxt `"Financial difficulty (%)       `m_pct_inc_diff_1'     `m_pct_inc_diff_2'     `m_pct_inc_diff_3'     `m_pct_inc_diff_4'"' _n
file write ftxt "----------------------------------------------------------------------" _n
file write ftxt `"N                              `n_1'      `n_2'      `n_3'      `n_4'"' _n
file write ftxt "----------------------------------------------------------------------" _n
file write ftxt "" _n
file write ftxt `"[a] Among smokers with valid br006_ response (W6: n=`nc_1' DE, n=`nc_2' FR;"' _n
file write ftxt `"    W9: n=`nc_3' DE, n=`nc_4' FR). W6 is sparse — interpret with caution."' _n
file write ftxt "Education: ISCED-97. Financial difficulty: co007_ = 1-2 (great/some difficulty" _n
file write ftxt "making ends meet). All percentages as 0-100. N: current_smoker non-missing." _n
file close ftxt

*==============================================================================
* Console preview
*==============================================================================
display as result _newline "=== Table 1: Descriptive statistics (W6 pre, W9 post) ==="
display as result "----------------------------------------------------------------------"
display as result "                                  DE       FR       DE       FR"
display as result "                                Wave 6   Wave 6   Wave 9   Wave 9"
display as result "----------------------------------------------------------------------"
display as result "Current smoker (%)          " ///
    "`m_pct_smoker_1'" "     " "`m_pct_smoker_2'" "     " "`m_pct_smoker_3'" "     " "`m_pct_smoker_4'"
display as result "Cigarettes/day (smokers)[a] " ///
    "`m_cigs_day_1'" "     " "`m_cigs_day_2'" "     " "`m_cigs_day_3'" "     " "`m_cigs_day_4'"
display as result "Age at interview            " ///
    "`m_age_int_1'" "     " "`m_age_int_2'" "     " "`m_age_int_3'" "     " "`m_age_int_4'"
display as result "Female (%)                  " ///
    "`m_pct_female_1'" "     " "`m_pct_female_2'" "     " "`m_pct_female_3'" "     " "`m_pct_female_4'"
display as result "ISCED 1-2 (%)               " ///
    "`m_pct_edu_low_1'" "     " "`m_pct_edu_low_2'" "     " "`m_pct_edu_low_3'" "     " "`m_pct_edu_low_4'"
display as result "ISCED 3-4 (%)               " ///
    "`m_pct_edu_mid_1'" "     " "`m_pct_edu_mid_2'" "     " "`m_pct_edu_mid_3'" "     " "`m_pct_edu_mid_4'"
display as result "ISCED 5+ (%)                " ///
    "`m_pct_edu_high_1'" "     " "`m_pct_edu_high_2'" "     " "`m_pct_edu_high_3'" "     " "`m_pct_edu_high_4'"
display as result "Financial difficulty (%)    " ///
    "`m_pct_inc_diff_1'" "     " "`m_pct_inc_diff_2'" "     " "`m_pct_inc_diff_3'" "     " "`m_pct_inc_diff_4'"
display as result "----------------------------------------------------------------------"
display as result "N                           " ///
    "`n_1'" "      " "`n_2'" "      " "`n_3'" "      " "`n_4'"
display as result "----------------------------------------------------------------------"
display as result `"[a] W6: n=`nc_1' DE, n=`nc_2' FR; W9: n=`nc_3' DE, n=`nc_4' FR smokers with valid cigs/day."'

display as result _newline "Files written:"
display as result "  `outfile'.csv"
display as result "  `outfile'.tex"
display as result "  `outfile'.txt"
