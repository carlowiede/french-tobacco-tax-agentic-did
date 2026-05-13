# french-tobacco-tax-agentic-did

**Replication package for:**
> Carlo Wiede (2026). *Quasi-Experimental Evidence on the 2017–2020 French Tobacco Tax: Causal Inference with an Agentic AI Research Framework*. Master thesis, KU Leuven.
> Supervisor: Jef Hendrickx.

---

## Overview

This repository contains the complete replication package for a difference-in-differences analysis of the causal effect of France's 2017–2020 tobacco tax programme on smoking prevalence among adults aged 50 and over. Germany serves as the sole control group. Data are drawn from the Survey of Health, Ageing and Retirement in Europe (SHARE), release 9.0.0.

The entire empirical pipeline was executed through an agentic AI framework: Claude Code connected to Stata via the Model Context Protocol (MCP), autonomously writing and executing Stata do-files under researcher direction. The `CLAUDE.md` file in this repository is the configuration file that governed the agent's behaviour throughout the analysis.

**Headline result:** A statistically significant reduction in smoking prevalence of 2.71 percentage points (SE 0.75, p < 0.001) in France relative to Germany, comparing Wave 6 (2015, pre-treatment) to Wave 9 (2021–2022, post full implementation), estimated via TWFE with individual and wave fixed effects on a balanced panel of 4,167 individuals.

---

## Data access

This repository does **not** contain SHARE microdata. Access to SHARE release 9.0.0 must be obtained independently from the SHARE research data centre at:

> https://share-eric.eu/data/data-access

SHARE data are provided free of charge for scientific research upon registration. Once access is granted, download the following modules for all relevant waves (1, 2, 4, 5, 6, 8, 9):

- `br` — Behavioural risks (smoking outcome variable `br002_`)
- `co` — Consumption (income proxy `co007_`)
- `dn` — Demographics (age, sex, education)
- `cv_r` — Cover screen (wave and respondent identifiers)

Place the downloaded `.dta` files in a `/data/raw/` folder in your local clone of this repository before running the do-files.

---

## Repository structure

```
/
├── README.md                  ← This file
├── CLAUDE.md                  ← Agent configuration file (meta-level instructions)
├── REPLICATION.md             ← Step-by-step replication guide
├── run_all.do                 ← Master do-file: runs the entire pipeline in sequence
├── results_summary.md         ← Verified Stata output for all reported results
│
├── do-files/
│   ├── 00b_merge_income.do    ← Merge income module
│   ├── 01_merge.do            ← Merge SHARE modules
│   ├── 02_clean.do            ← Data cleaning and variable construction
│   ├── 03_forwardfill.do      ← Forward-fill imputation for skip-pattern logic
│   ├── 04_sample.do           ← Sample construction (France + Germany, 50+)
│   ├── 05_descriptives.do     ← Descriptive statistics (Table 1)
│   ├── 06_parallel_trends.do  ← Parallel trends: visual plot + placebo DiDs
│   ├── 07_main.do             ← Primary results: OLS and TWFE (Table 2)
│   ├── 08_robustness.do       ← Robustness checks R1–R5 (Table 3)
│   ├── 09_heterogeneity.do    ← Heterogeneous effects: sex, education, age
│   ├── 10_income_het.do       ← Income heterogeneity (triple interaction + stratified)
│   ├── 11_event_study.do      ← Event study (Figure 2)
│   ├── 12_income_heterogeneity.do  ← Extended income heterogeneity specification
│   └── 13_descriptive_table.do     ← Formatted Table 1 output
│
└── .claude/
    └── commands/
        ├── did.md             ← /did slash command
        ├── robustness.md      ← /robustness slash command
        └── writeup.md         ← /writeup slash command
```

---

## Replication

To reproduce all results in the thesis, follow these steps:

1. Obtain SHARE release 9.0.0 access (see Data access above)
2. Clone this repository and place raw SHARE `.dta` files in `/data/raw/`
3. Open `run_all.do` in Stata and set the working directory to your local clone
4. Run `run_all.do` — this executes the full pipeline in sequence

All tables and figures in the thesis are produced by the do-files listed above. The `REPLICATION.md` file maps each table and figure to the specific do-file and output that produces it, and reports the expected Stata output for verification.

For a full description of the agentic setup used to execute this pipeline, see the **Agentic framework setup** section below.

---

## Key design choices

| Choice | Value |
|---|---|
| Treatment group | France (`country = 17`) |
| Control group | Germany (`country = 12`) |
| Primary outcome | Current smoker status (`br002_`, binary) |
| Headline window | Wave 6 (2015) vs Wave 9 (2021–2022) |
| Wave excluded | Wave 7 (SHARELIFE — no smoking variables) |
| Wave 8 role | Robustness only (interim period, ~70% of tax implemented) |
| Estimator | TWFE via `reghdfe`, individual + wave fixed effects |
| Standard errors | Clustered at individual level (`mergeid`) |
| Income proxy | `co007_` collapsed to 3 groups |
| Imputation | Forward-fill for SHARE skip-pattern logic |

---

## Headline results

| Specification | Coeff (pp) | SE | p-value | N |
|---|---|---|---|---|
| Pooled OLS, W6 vs W9 | −0.71 | 0.94 | 0.450 | 15,319 |
| **TWFE, W6 vs W9 (headline)** | **−2.71** | **0.75** | **<0.001** | **8,334** |
| TWFE, W6 vs W8 (interim, R4) | −2.30 | 0.68 | 0.001 | 9,490 |
| TWFE, W6 vs W8+W9 (pooled, R5) | −2.46 | 0.63 | <0.001 | 16,563 |

All robustness checks and heterogeneity results are reported in `results_summary.md`.

---

## Agentic framework setup

The analysis was executed via an AI agent connected to Stata through the Model Context Protocol (MCP). This thesis used Claude Code (Anthropic) running inside the Antigravity IDE, but the Stata MCP server is AI-agnostic — it works with any MCP-compatible client, including Cursor, GitHub Copilot, and others. The steps below describe the setup in general terms.

### Prerequisites

- A Mac (macOS 12+) or Windows (10+) computer
- Stata 17 or later (MP, SE, or BE — any licence works)
- An MCP-compatible AI client of your choice, for example:
  - Claude Code CLI — https://claude.ai/code (`npm install -g @anthropic-ai/claude-code`)
  - Cursor — https://cursor.com
  - GitHub Copilot (VS Code 1.102+)
  - Antigravity — https://antigravity.dev
- uv — install via Terminal:
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```
  Restart your terminal and verify with `uvx --version`.

### Step 1 — Install the Stata MCP server

The MCP server is the bridge between your AI client and Stata. Install it via `uvx`:

```bash
uvx --from mcp-stata@latest mcp-stata
```

You do not need to keep it running manually — your AI client will launch it as a subprocess automatically.

### Step 2 — Register the MCP server with your AI client

The registration command depends on which AI client you are using. For **Claude Code CLI**, run this once from your terminal:

```bash
claude mcp add-json stata-mcp '{"type":"stdio","command":"uvx","args":["--from","mcp-stata@latest","mcp-stata"]}' --scope user
```

For other clients, the MCP server configuration to register is:

```json
{
  "type": "stdio",
  "command": "uvx",
  "args": ["--from", "mcp-stata@latest", "mcp-stata"]
}
```

Consult your AI client's documentation for how to register an MCP server using this configuration block.

### Step 3 — Verify the connection

Restart your AI client. Most MCP-compatible clients provide a way to list active connections — check your client's documentation to confirm `stata-mcp` is listed as connected. In Claude Code, you can type `/mcp` in the chat to see all active servers. ✅

### Step 4 — Load the agent configuration

The `CLAUDE.md` file in this repository contains the meta-level instructions that governed the agent throughout this analysis. It encodes the methodological defaults used in this thesis: mandatory verification of variable codes before execution, fixed effects as default for panel data, clustering at the individual level, and parallel trends testing for every DiD specification.

To use it:
- **Claude Code** — open the cloned repository folder as your working directory; `CLAUDE.md` is read automatically at the start of every session.
- **Any other client** — simply download `CLAUDE.md` and drag it into your working environment or project folder. Most MCP-compatible clients will pick it up automatically, or you can paste its contents into your system prompt or project-level instructions file.

The following slash commands are available for Claude Code users:

- `/setup` — explore the data and confirm the identification strategy
- `/did` — run the full DiD workflow: OLS → TWFE → parallel trends → robustness → heterogeneity
- `/iv` — run the full IV workflow: first stage → reduced form → IV estimate → robustness
- `/rd` — run the full RD workflow: visual inspection → McCrary test → rdrobust → bandwidth sensitivity
- `/robustness` — run all standard robustness checks on the most recent model
- `/heterogeneity` — run triple interaction models by sex, education, and age
- `/parallel-trends` — run placebo DiD test on pre-treatment data only and plot trends
- `/event-study` — run an event study and plot coefficients
- `/writeup` — produce a commented do-file and plain-language results summary
- `/compare` — place the last two specifications side by side in a results table

### Notes

- The MCP server runs as a stdio subprocess — your AI client starts and manages it automatically.
- The `--from mcp-stata@latest` flag ensures the latest version is always pulled.
- To remove the server in Claude Code: `claude mcp remove stata-mcp`
- For extended troubleshooting, see: https://github.com/carlowiede/stata-claude-agent

---

## SHARE conditions of use

This repository complies with the SHARE Conditions of Use (SHARE-ERIC, 2026). No SHARE microdata are stored in this repository — only Stata do-files, configuration files, and results summaries (tables and figures). All analysis was conducted locally; no microdata were transmitted to external servers. See Section 4.6 of the thesis for a full compliance statement.

---

## Citation

If you use this replication package or the agentic framework in your own research, please cite:

> Wiede, C. (2026). *Quasi-Experimental Evidence on the 2017–2020 French Tobacco Tax: Causal Inference with an Agentic AI Research Framework*. Master thesis, KU Leuven.
> GitHub: https://github.com/carlowiede/french-tobacco-tax-agentic-did

---

## Credits

- **Stata MCP / Stata Workbench** by Thomas Monk (LSE) — https://github.com/tmonk/mcp-stata
- **Claude Code** by Anthropic — https://claude.ai/code
- **SHARE data** — Börsch-Supan et al. (2013), release 9.0.0
