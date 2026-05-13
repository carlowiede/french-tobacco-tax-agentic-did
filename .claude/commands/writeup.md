Produce a full write-up of the analysis.

## 1. Commented do-file
Generate a clean, commented Stata do-file with the full analysis pipeline, including:
- Data loading and sample construction
- Variable definitions and coding
- Parallel trends tests
- Baseline OLS and TWFE estimates
- Robustness checks
- Heterogeneous effects

## 2. Markdown results summary
Produce a plain-language summary covering:
- Research question and identification strategy
- Main results: coefficient, SE, p-value, N
- Robustness check outcomes and what changed across specifications
- Heterogeneous effects findings — distinguish significant triple interactions from descriptive stratified patterns
- Honest interpretation including null results and caveats about identification assumptions

## 3. Robustness table
Produce a side-by-side comparison of all specifications:

```stata
esttab using "output/robustness_table.rtf", ///
    b(2) se(2) star(* 0.05 ** 0.01 *** 0.001) ///
    keep(did) label replace
```

Be honest: report all specifications, not just the best-looking one. Flag null results clearly and note any concerns about the parallel trends assumption or other identification threats.
