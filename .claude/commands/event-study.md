Run an event study to examine the dynamic treatment effect over time.

An event study augments the TWFE specification with interactions between the treatment indicator and a dummy for each time period, with one period designated as the reference. Pre-treatment coefficients assess parallel trends; post-treatment coefficients reveal the dynamics of the treatment effect.

## Stata

```stata
* ref_period = last pre-treatment period (omitted reference)
reghdfe outcome ib[ref_period].time_var##treated, absorb(id_var time_var) vce(cluster id_var)

* Plot coefficients (requires coefplot)
cap ssc install coefplot
coefplot, keep(*treated*) omit base ///
    xline(0) vertical ///
    title("Event study: treatment effect over time") ///
    ytitle("Coefficient (relative to reference period)") ///
    xtitle("Time period")
```

## R (alternative)

```r
library(fixest)

model_es <- feols(outcome ~ i(time_var, treated, ref = ref_period) | id_var + time_var,
                  cluster = ~id_var,
                  data = df)

iplot(model_es,
      main = "Event study: treatment effect over time",
      xlab = "Time period")
```

## Interpretation

- **Pre-treatment coefficients** should be centred near zero and statistically insignificant — supports parallel trends
- **Post-treatment coefficients** capture the treatment effect at each period relative to the reference
- A growing post-treatment pattern is consistent with a dose-response or lagged effect
- A flat post-treatment pattern suggests an immediate, stable treatment effect

## Reporting
Report each coefficient with its SE and 95% confidence interval. Note whether pre-treatment coefficients are jointly insignificant. As Roth (2022) notes, passing pre-trend tests is necessary but not sufficient evidence that parallel trends holds.

Follow all variable verification rules. Confirm variable names before running.
