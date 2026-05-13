*==============================================================================
* 00b_merge_income.do
*
* Merges SHARE co007_ ("make ends meet") from the co module into the
* existing panel_frde_outcomes.dta.
*
* co007_ is a household-level question — only the designated financial
* respondent answers; the partner gets a system missing. We fill the
* partner's value from the financial respondent within the same household
* (verified: 99.5% of 2-person HHs have exactly 1 valid answer).
*
* Output variables added to the panel:
*   co007_raw   -- raw ordinal (1-4; missing for refusal/-2/-1 and skip)
*   inc_diff    -- 1 = difficulty (co007_ in 1-2), 0 = no difficulty (3-4)
*   inc_group   -- 1 = difficulty (1-2), 2 = fairly easily (3), 3 = easily (4)
*
* Coverage after partner-fill: ~88% of FR+DE observations with current_smoker.
*
* Run AFTER 02_build_outcomes.do. Overwrites panel_frde_outcomes.dta in-place.
*==============================================================================

clear all
set more off
version 17

local root "$root"
local waves "4 5 6 8 9"

*------------------------------------------------------------------------------
* Step 1: Build a cross-wave income dataset from the co modules
*------------------------------------------------------------------------------
tempfile income_all
local first 1

foreach w of local waves {
    use "`root'/SHARE WAVES/sharew`w'_rel9-0-0_co.dta", clear
    keep if inlist(country, 12, 17)

    * Standardise the wave-specific hhid to generic name
    rename hhid`w' hhid

    * Recode negatives (refusal = -2, don't know = -1) to missing
    replace co007_ = . if co007_ < 0

    * Fill in missing co007_ for partner within the same household.
    * bysort hhid: sort so the valid observation comes first, then carrydown.
    bysort hhid (co007_): replace co007_ = co007_[1] if missing(co007_)

    keep mergeid co007_
    rename co007_ co007_raw
    gen int wave = `w'

    if `first' {
        save `income_all'
        local first 0
    }
    else {
        append using `income_all'
        save `income_all', replace
    }
}

* verify no duplicates
duplicates report mergeid wave

*------------------------------------------------------------------------------
* Step 2: Merge into the main panel
*------------------------------------------------------------------------------
use "`root'/data_build/panel_frde_outcomes.dta", clear

merge m:1 mergeid wave using `income_all', keep(master match) nogenerate

*------------------------------------------------------------------------------
* Step 3: Create income groups
*------------------------------------------------------------------------------
* Binary: difficulty (1-2) vs no difficulty (3-4)
gen byte inc_diff = .
replace inc_diff = 1 if inlist(co007_raw, 1, 2)
replace inc_diff = 0 if inlist(co007_raw, 3, 4)
label define inc_diff_l 0 "No difficulty (3-4)" 1 "Difficulty (1-2)"
label values inc_diff inc_diff_l
label variable inc_diff "HH make-ends-meet: difficulty (1/0)"

* 3-group: difficulty / fairly easily / easily
gen byte inc_group = .
replace inc_group = 1 if inlist(co007_raw, 1, 2)
replace inc_group = 2 if co007_raw == 3
replace inc_group = 3 if co007_raw == 4
label define inc_group_l 1 "Difficulty (1-2)" 2 "Fairly easily (3)" 3 "Easily (4)"
label values inc_group inc_group_l
label variable inc_group "HH make-ends-meet: 3 groups"

*------------------------------------------------------------------------------
* Step 4: Report coverage in the primary analysis sample
*------------------------------------------------------------------------------
display as result _newline "=== Coverage in W6/W8 analysis sample ==="
preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker)
    tab wave, miss
    display "Valid inc_diff:"
    tab wave inc_diff, miss
restore

display as result _newline "=== Distribution of inc_group by wave (W6, W8) ==="
preserve
    keep if inlist(wave, 6, 8) & !missing(current_smoker)
    tab inc_group wave, miss
restore

*------------------------------------------------------------------------------
* Step 5: Save
*------------------------------------------------------------------------------
label variable co007_raw "co007_ raw (1=great diff, 4=easily; after partner-fill)"
save "`root'/data_build/panel_frde_outcomes.dta", replace

display as result _newline "Income variables added. Panel re-saved."
