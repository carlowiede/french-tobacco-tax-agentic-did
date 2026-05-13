*------------------------------------------------------------------------------
* 02_build_outcomes.do
*
* Reconstruct smoking-status outcomes from raw br001_/br002_ across
* panel waves, correcting for the SHARE skip pattern (status not re-asked
* once known).
*
* Logic:
*   ever_smoker (time-invariant)
*     = 1 if any wave br001_ == 1
*     = 0 if any wave br001_ == 5 and no wave br001_ == 1
*     = . otherwise
*
*   current_smoker at wave W
*     = 0 if ever_smoker == 0
*     = 1 if br002_ observed at W and == 1
*     = 0 if br002_ observed at W and == 5
*     = carry-forward of most recent non-missing br002_ at wave <= W
*
* br006_ (cigarettes/day) is used as observed — not imputed. Only
* available in waves 6, 8, 9.
*
* Output: data_build/panel_frde_outcomes.dta
*------------------------------------------------------------------------------

clear all
set more off
version 17

local root "$root"
local out  "`root'/data_build"

use "`out'/panel_frde_raw.dta", clear

* --- clean raw br codes: SHARE treats negative codes as DK/refusal/NA ---
foreach v in br001_ br002_ {
    replace `v' = . if `v' < 0
    * valid codes 1=yes, 5=no — drop anything else
    replace `v' = . if !inlist(`v', 1, 5)
}
replace br006_ = . if br006_ < 0

* --- panel setup ---
encode mergeid, gen(pid)
xtset pid wave

* --- ever-smoker: any-wave rule (time-invariant) ---
by pid: egen any_yes  = max(cond(br001_ == 1, 1, .))
by pid: egen any_no   = max(cond(br001_ == 5, 1, .))
gen byte ever_smoker = .
replace  ever_smoker = 1 if any_yes == 1
replace  ever_smoker = 0 if any_yes != 1 & any_no == 1
drop any_yes any_no

* --- current smoker at each wave, with forward-fill ---
* step 1: direct observation at this wave
gen byte cur_direct = .
replace  cur_direct = 1 if br002_ == 1
replace  cur_direct = 0 if br002_ == 5

* step 2: non-smokers by ever-status
gen byte cur_ff = cur_direct
replace  cur_ff = 0 if missing(cur_ff) & ever_smoker == 0

* step 3: carry-forward most recent prior non-missing br002_ within pid
sort pid wave
by pid: gen double _lastwave = wave if !missing(cur_direct)
by pid: replace _lastwave = _lastwave[_n-1] if missing(_lastwave) & _n > 1
by pid: gen double _lastval  = cur_direct if !missing(cur_direct)
by pid: replace _lastval  = _lastval[_n-1]  if missing(_lastval)  & _n > 1
replace cur_ff = _lastval if missing(cur_ff)
drop _lastwave _lastval cur_direct

rename cur_ff current_smoker

* --- imputation flag: 1 if current_smoker came from carry-forward, not
*     from direct observation at this wave, and not from ever_smoker==0
gen byte cs_imputed = 0
replace  cs_imputed = 1 if !missing(current_smoker) & missing(br002_) & ever_smoker != 0

* --- cigarettes/day among current smokers ---
gen double cigs_day = br006_ if current_smoker == 1
* sanity cap for robustness check later (will trim 50+ separately)

* --- treatment / post / DiD ---
gen byte france = (country == 17)
gen byte germany = (country == 12)
label define treat 0 "Germany (control)" 1 "France (treated)"
label values france treat

* ALTERNATIVE SPEC (not used in analysis) -- kept for reference only.
* Interview-year-based post indicator: rejected because Wave 8 fieldwork
* straddled 2018-2020, so int_year >= 2018 would mis-classify W8 respondents
* interviewed in late 2019/2020 vs early 2018.  Analysis uses post_w (below).
gen byte post = (int_year >= 2018) if !missing(int_year)
label define postl 0 "Pre (<=2017)" 1 "Post (>=2018)"
label values post postl

* wave-based post (for Wave 6 vs 8 primary spec): Wave 6 = 2015, Wave 8 = 2019-20
gen byte post_w = (wave >= 8) if !missing(wave)

gen byte did   = france * post
gen byte did_w = france * post_w

* --- demographics tidy ---
gen byte female = (gender == 2) if inlist(gender, 1, 2)

* education: isced1997_r categories — 0..6 typical, negatives = missing
replace isced1997_r = . if isced1997_r < 0 | isced1997_r > 6
gen byte edu_low  = (isced1997_r <= 2) if !missing(isced1997_r)
gen byte edu_mid  = (isced1997_r == 3 | isced1997_r == 4) if !missing(isced1997_r)
gen byte edu_high = (isced1997_r == 5 | isced1997_r == 6) if !missing(isced1997_r)

label data "FR+DE smoking panel with forward-filled current smoker status"
compress
save "`out'/panel_frde_outcomes.dta", replace

*------------------------------------------------------------------------------
* DIAGNOSTICS
*------------------------------------------------------------------------------
display as result _newline "=== Ever smoker coverage ==="
tab wave ever_smoker, missing row

display as result _newline "=== Current smoker after forward-fill (by wave x country) ==="
tab wave country if !missing(current_smoker)
table wave country, stat(mean current_smoker) stat(count current_smoker) nformat(%6.3f)

display as result _newline "=== Share of current_smoker that came from imputation ==="
tab wave cs_imputed, row

display as result _newline "=== br006_ (cigs/day) availability ==="
tab wave if !missing(br006_)
table wave country if current_smoker == 1, stat(mean cigs_day) stat(count cigs_day) nformat(%6.2f)

*------------------------------------------------------------------------------
* SANITY CHECK: gender coding direction
*   Verifies SHARE's 1=male, 2=female convention so that (gender == 2) maps
*   correctly to female. Eyeball this cross-tab -- all non-zero cells should
*   be on the diagonal 0/1 == 1/2.
*------------------------------------------------------------------------------
display as result _newline "=== Gender coding check: tab gender female ==="
display as result "Expected: gender=1 -> female=0 (male); gender=2 -> female=1 (female)"
tab gender female, missing
