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
   - **Statistical Concepts** — four boxes (Correlation, Causality,
     Statistical Significance, A/B Testing) explaining each idea in plain
     language with a general mental-health example, each with its own pair
     of verified references.
   - **Concepts Applied to Our Monitoring** — the same four ideas, applied
     directly to this app's own simulated data: a live correlation scatter
     (signal vs EPDS, with r computed on the fly), a confounding diagram,
     a live-recomputed significance + effect-size recap of the cohort
     comparison, and a table of what a real A/B trial would additionally
     require.
   - **Intervention Timeline** — a clickable care-pathway chart from 8 weeks
     before birth to 24 months after, with an illustrative "risk index"
     curve (support vs no support) and eleven intervention points; clicking
     a point shows its evidence, timing rationale, and which Intelligence
     Layer output it feeds. Includes the original pitch-deck matrescence
     slide for context.

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
- Kohavi, R., Longbotham, R., Sommerfield, D. and Henne, R.M. (2009)
  'Controlled experiments on the web: survey and practical guide', *Data
  Mining and Knowledge Discovery*, 18(1), pp. 140–181.
- Altman, N. and Krzywinski, M. (2015) 'Points of significance: association,
  correlation and causation', *Nature Methods*, 12(10), pp. 899–900.
- Baglioni, C., Battagliese, G., Feige, B., Spiegelhalder, K., Nissen, C.,
  Voderholzer, U., Lombardo, C. and Riemann, D. (2011) 'Insomnia as a
  predictor of depression: a meta-analytic evaluation of longitudinal
  epidemiological studies', *Journal of Affective Disorders*, 135(1-3),
  pp. 10–19.
- Hill, A.B. (1965) 'The environment and disease: association or
  causation?', *Proceedings of the Royal Society of Medicine*, 58(5),
  pp. 295–300.
- Wasserstein, R.L. and Lazar, N.A. (2016) 'The ASA statement on p-values:
  context, process, and purpose', *The American Statistician*, 70(2),
  pp. 129–133.
- Sullivan, G.M. and Feinn, R. (2012) 'Using effect size - or why the P
  value is not enough', *Journal of Graduate Medical Education*, 4(3),
  pp. 279–282.

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
