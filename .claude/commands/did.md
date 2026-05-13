Run the full Difference-in-Differences workflow.

## Steps

### 1. Baseline OLS
Run a simple pooled OLS DiD with no fixed effects as the naïve baseline:

```stata
reg outcome did post treated, vce(robust)
```

### 2. TWFE (preferred)
Upgrade to two-way fixed effects absorbing individual and time fixed effects:

```stata
reghdfe outcome did, absorb(id_var time_var) vce(cluster id_var)
```

Report both specifications side by side. The gap between OLS and TWFE typically reflects composition effects or time-invariant confounding — explain what is driving the difference.

### 3. Parallel trends
Run placebo DiDs on pre-treatment periods. See `/parallel-trends`.

### 4. Robustness checks
Run standard robustness checks. See `/robustness`.

### 5. Heterogeneous effects
Run triple interaction models by relevant subgroups. See `/heterogeneity`.

Follow all variable verification rules. Confirm variable names with `codebook` before running. Run in small steps and verify output after each step.
