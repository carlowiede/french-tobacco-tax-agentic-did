Put the last two model specifications side by side in a clean results table.

```stata
esttab [model1] [model2], ///
    b(2) se(2) star(* 0.05 ** 0.01 *** 0.001) ///
    keep(did) label ///
    mtitles("Specification 1" "Specification 2")
```

Report for each model:
- Coefficient on the DiD term
- Standard error
- p-value
- Number of observations
- Fixed effects included (individual / time / none)
- Controls included (list them)
- Clustering level

Highlight any meaningful differences in coefficients or significance and explain in plain language why they might differ — for example, composition effects, sample restriction, imputation, or alternative clustering.
