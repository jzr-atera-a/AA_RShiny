# Maternal Health Intelligence App (independent prototype)

A completely separate, standalone R Shiny app built on the same manifest-driven
module architecture as the DriveSafe Suite reference. Two main modules
(sidebar groups) only:

1. **API Configuration** — `bigquery_auth` + `claude_api_config`, reused
   near-verbatim from the reference app (generic, domain-agnostic), retargeted
   to a `maternal_screening_log` table.
2. **Maternal Health Monitor** — one new module, four subtabs:
   - **Continuity Gap** — the pregnancy → birth → postnatal → return-to-work
     touchpoint timeline (baby vs mother), based on the "Maternal health
     isn't a wellness gap" slide.
   - **Intelligence Layer** — the input-signals → maternal digital twin →
     outputs diagram, an interactive signal explorer, and the V1/V2/V3
     roadmap, based on the "Intelligence Layer" slide.
   - **Risk Trajectory** — per-mother risk-vs-own-baseline trajectory, flag
     point, lead-time KPI, "what raised the flag" breakdown, and a
     calibration-check distribution chart, based on the "Detect the
     trajectory early" slide.
   - **Cohort A/B Simulation** — App-Supported vs Standard NHS Care vs No
     Support, mirroring the driver_ab_test (CPAP treated/untreated/control)
     pattern: KPI deltas, a violin+box plot with a two-sample t-test
     significance bracket, kernel-density "bell curve" plots per cohort,
     trajectory evolution with confidence band, normalised metric heatmap,
     per-mother delta chart, and an interactive recommended-sample-size
     table (power calculation per outcome, with medical/statistical
     justification).

## References
Every subtab cites two real, independently verifiable, Harvard-style
references at its foot (full list also in `R/utils_ppd_risk.R`,
`REFERENCES`):

- Bauer, A., Parsonage, M., Knapp, M., Iemmi, V. and Adelaja, B. (2014) *The
  Costs of Perinatal Mental Health Problems*. London: Centre for Mental
  Health and London School of Economics and Political Science.
- Cox, J.L., Holden, J.M. and Sagovsky, R. (1987) 'Detection of postnatal
  depression: development of the 10-item Edinburgh Postnatal Depression
  Scale', *British Journal of Psychiatry*, 150(6), pp. 782–786.
- Hurwitz, E., Butzin-Dozier, Z., Master, H., O'Neil, S.T., Walden, A.,
  Holko, M., Patel, R.C. and Haendel, M.A. (2024) 'Harnessing consumer
  wearable digital biomarkers for individualized recognition of postpartum
  depression using the All of Us Research Program data set: cross-sectional
  study', *JMIR mHealth and uHealth*, 12, e54622.
- Abd-Alrazaq, A., AlSaad, R., Shuweihdi, F., Ahmed, A., Aziz, S. and
  Sheikh, J. (2023) 'Systematic review and meta-analysis of performance of
  wearable artificial intelligence in detecting and predicting depression',
  *npj Digital Medicine*, 6, 84.
- Dennis, C.-L. and Dowswell, T. (2013) 'Psychosocial and psychological
  interventions for preventing postpartum depression', *Cochrane Database
  of Systematic Reviews*, Issue 2, Art. No. CD001134.
- Cohen, J. (1988) *Statistical Power Analysis for the Behavioral Sciences*.
  2nd edn. Hillsdale, NJ: Lawrence Erlbaum Associates.
- Julious, S.A. (2004) 'Tutorial in biostatistics: sample sizes for
  clinical trials with Normal data', *Statistics in Medicine*, 23(12),
  pp. 1921–1986.

## Colour palette
Ported directly from a reference "Menu Degustacion" Shiny app's CSS: a deep
navy-blue base (`#0a1128` → `#1e3c72` → `#2a5298`), a bright-blue/light-blue
accent (`#4a90e2` / `#7ec8e3`), and a purple-blue gradient (`#667eea` →
`#764ba2`) used for headers, buttons, active menu items and the brand
accent throughout. Content boxes are dark glass-style cards (matching that
reference exactly) with light lavender body text (`#e0e7ff`), not white
cards — every chart uses light gridlines/fonts (`apply_plotly_theme()` in
`R/utils_ppd_risk.R`) so it reads correctly against that dark card
background. The clinical risk scale (green/amber/orange/red bands) is kept
as a universal signal colour set, unaffected by the brand palette.

## To run
```r
setwd("maternal_health_intelligence")
shiny::runApp()
```
Requires: shiny, shinydashboard, R6, yaml, purrr, shinyjs, httr, curl,
jsonlite, bigrquery, DT, plotly, dplyr, stringr, tidyr.

BigQuery/Claude credentials are optional — the Maternal Health Monitor
module works fully offline on simulated data.

## Safety notes carried over from the design
- The EPDS self-harm item (item 10) is a deterministic hard trigger, kept
  separate from the weighted composite risk score everywhere in the code
  (`R/utils_ppd_risk.R`).
- Every screen showing a risk score sits under the app-wide disclaimer
  banner: this is decision support, not a diagnosis.
- All mother-level and cohort data is simulated; only the five references
  above are real.
