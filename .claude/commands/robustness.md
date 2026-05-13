Run robustness checks on the headline DiD estimate.

After each check report: DiD coefficient, SE, p-value, N. Summarise what changed and what stayed the same. If any check produces a sign reversal or loss of significance, flag it explicitly — a null result is a valid finding.

## Standard checks

### 1. Add demographic controls
Add time-varying covariates to the TWFE specification. Note: time-invariant variables (e.g. sex, baseline education) are absorbed by individual fixed effects and should not be included.

```stata
reghdfe outcome did [controls], absorb(id_var time_var) vce(cluster id_var)
```

### 2. Direct observations only
If the outcome variable has been imputed or forward-filled, restrict to directly observed values to assess sensitivity to imputation:

```stata
reghdfe outcome did if imputed == 0, absorb(id_var time_var) vce(cluster id_var)
```

### 3. Alternative pre-treatment window
Extend or change the pre-treatment baseline to check sensitivity to the choice of comparison period:

```stata
* Example: pool two pre-treatment periods as baseline
keep if inlist(time_var, pre1, pre2, post_period)
reghdfe outcome did, absorb(id_var time_var) vce(cluster id_var)
```

### 4. Balanced panel
Restrict to units observed in both the pre- and post-treatment periods to address attrition:

```stata
bysort id_var: keep if _N == [expected_obs]
reghdfe outcome did, absorb(id_var time_var) vce(cluster id_var)
```

### 5. Alternative post-treatment window
If multiple post-treatment periods are available, check sensitivity to the definition of the post period.

```stata
* Example: use an earlier or later post period
keep if inlist(time_var, pre_period, alt_post_period)
reghdfe outcome did, absorb(id_var time_var) vce(cluster id_var)
```

Follow all variable verification rules. Confirm variable names before running.
