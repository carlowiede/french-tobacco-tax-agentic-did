Run the parallel trends diagnostics for the DiD analysis.

The parallel trends assumption requires that treatment and control groups would have followed the same outcome trajectory absent the intervention. It cannot be directly tested, but three diagnostics assess its plausibility.

## Step 1 — Visual inspection

Plot raw outcome means by period for treatment and control groups:

```stata
collapse (mean) outcome, by(time_var treated)
twoway (connected outcome time_var if treated == 0) ///
       (connected outcome time_var if treated == 1), ///
       xline([treatment_cutoff], lpattern(dash)) ///
       legend(label(1 "Control") label(2 "Treatment")) ///
       title("Outcome over time: treatment vs control")
```

Pre-treatment lines should move roughly in parallel.

## Step 2 — Placebo DiDs

Re-estimate the TWFE specification on pre-treatment periods only, with a placebo treatment date set within the pre-period. Under parallel trends, placebo coefficients should be small and statistically insignificant.

```stata
* Example: placebo treating period T-1 as "post"
preserve
keep if time_var <= [last_pre_period]
gen placebo_post = (time_var == [placebo_period])
gen placebo_did  = treated * placebo_post
reghdfe outcome placebo_did, absorb(id_var time_var) vce(cluster id_var)
restore
```

Run one placebo for each available pre-treatment pair. Report coefficient, SE, and p-value for each.

## Step 3 — Event study

Run an event study with the last pre-treatment period as the reference wave:

```stata
reghdfe outcome ib[ref_period].time_var##treated, absorb(id_var time_var) vce(cluster id_var)
```

Pre-treatment coefficients should be centred near zero and statistically insignificant. Post-treatment coefficients reveal the dynamic treatment effect.

## Step 4 — Report verdict

- **Pass:** pre-treatment coefficients near zero, p > 0.05
- **Marginal:** small coefficients, p between 0.05 and 0.10 — report as caveat
- **Fail:** large coefficients or p < 0.05 — flag explicitly and discuss implications

As noted by Roth (2022), passing pre-trend tests is necessary but not sufficient evidence that parallel trends holds.
