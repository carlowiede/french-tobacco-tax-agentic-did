Run heterogeneous effects analysis using triple interaction models.

Formal heterogeneity claims require the triple interaction term itself to be statistically significant. Stratified estimates alone are descriptive — report them honestly as such if the interaction is null.

## Pattern for each subgroup

```stata
gen did_sub = did * subgroup_var
reghdfe outcome did did_sub post, absorb(id_var time_var) vce(cluster id_var)
lincom did + did_sub   // total effect for subgroup == 1
```

Note: time-invariant subgroup variables (e.g. sex, baseline education) are absorbed by individual fixed effects in the main effect, but their *interaction* with `did` is identified. Do NOT include `treated × subgroup` — also absorbed by individual FE.

## Steps

### 1. Define subgroups
Ask the researcher which subgroup dimensions are relevant. Common choices:
- Sex (binary)
- Education level (categorical: low / mid / high)
- Age group (categorical: e.g. younger / older)
- Income or financial situation (categorical or binary)

Verify all subgroup variable names and coding with `codebook` before proceeding.

### 2. Run triple interaction model for each subgroup

```stata
* Binary subgroup
gen did_sub = did * subgroup_binary
reghdfe outcome did did_sub post, absorb(id_var time_var) vce(cluster id_var)
lincom did            // effect for subgroup == 0
lincom did + did_sub  // effect for subgroup == 1

* Categorical subgroup (3 groups, group 1 as baseline)
gen did_g2 = did * (subgroup == 2)
gen did_g3 = did * (subgroup == 3)
reghdfe outcome did did_g2 did_g3 post, absorb(id_var time_var) vce(cluster id_var)
lincom did            // group 1 total
lincom did + did_g2   // group 2 total
lincom did + did_g3   // group 3 total
```

### 3. Stratified TWFE (as robustness)
Re-estimate the baseline TWFE separately within each subgroup:

```stata
reghdfe outcome did if subgroup == [value], absorb(id_var time_var) vce(cluster id_var)
```

### 4. Report
For each subgroup: triple interaction coefficient, SE, p-value; stratified TWFE estimates; note whether the interaction is significant or merely descriptive.

Follow all variable verification rules. Confirm variable names before running.
