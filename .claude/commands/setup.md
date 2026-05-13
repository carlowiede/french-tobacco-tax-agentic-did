Explore the data and set up the identification strategy.

## Step 1 — Explore the data

```stata
describe
summarize
codebook, compact
xtsum [key variables]   // if panel data
```

Report: number of observations, key variable names, missing data rates, panel structure.

## Step 2 — Ask the researcher these five identification questions

1. What is the treatment variable, and when/where did it happen?
2. What is the control group?
3. What is the outcome variable, and is it continuous or binary?
4. What is the individual ID variable and the time variable?
5. What is the comparison window (pre vs post periods)?

## Step 3 — Verify key variables before proceeding

Never assume variable names, numeric codes, or coding structures. Always verify:

```stata
codebook treatment_var outcome_var
label list [relevant value labels]
tab treatment_var time_var, missing
```

Confirm the exact numeric codes for treatment and control groups with the researcher before running any regression.
