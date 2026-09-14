# modules/Maternal Health Monitor/maternal_health_monitor/ui.R
# SIGNIFICANTLY ENRICHED VERSION
# Seven subtabs, in order of increasing complexity:
#   1. Continuity Gap Timeline            (ref: "Maternal health isn't a wellness gap")
#   2. Intelligence Layer & Interventions (ref: "The Intelligence Layer...")
#   3. Risk Trajectory & Early Detection  (ref: "Detect the trajectory early")
#   4. Statistical Concepts               (ENRICHED: correlation, causality, significance, A/B testing with interactive graphs)
#   5. Concepts Applied to Our Monitoring (ENRICHED: detailed examples with interactive components)
#   6. Cohort A/B Simulation              (ENHANCED: parameter controls, power calculations)
#   7. Intervention Timeline              (SIGNIFICANTLY ENHANCED: risk curves, clickable interventions with context)

maternal_health_monitor_ui <- function(id) {
  ns <- NS(id)

  tagList(

    fluidRow(
      column(12,
        div(class = "book-header",
          tags$h2(icon("heartbeat"), " Maternal Health Monitor"),
          tags$p(class = "author",
            "Continuity-gap timeline, the intelligence layer feeding the model, early-detection ",
            "risk trajectory, and a cohort simulation comparing pathways of support. ",
            "All figures are simulated except where a reference is cited.")
        )
      )
    ),

    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,

        tabsetPanel(id = ns("mh_tabs"),

          # ══════════════════════════════════════════════════════════════════
          # SUBTAB 1 — CONTINUITY GAP TIMELINE
          # ══════════════════════════════════════════════════════════════════
          tabPanel(
            title = tagList(icon("stream"), " Continuity Gap"),
            br(),

            div(class = "slide-panel",
              span(class = "slide-pill", "THE PROBLEM"),
              tags$h3("Maternal health isn't a wellness gap - it's a continuity gap"),

              fluidRow(
                column(4, div(style="text-align:center;",
                  div(class = "stat-number", "£8.1bn"),
                  div(class = "stat-label", "Annual cost of perinatal mental health problems, UK"))),
                column(4, div(style="text-align:center;",
                  div(class = "stat-number", "~20%"),
                  div(class = "stat-label", "Of mothers affected by a perinatal mental health problem"))),
                column(4, div(style="text-align:center;",
                  div(class = "stat-number", "1"),
                  div(class = "stat-label", "Structured postnatal mental health check in standard care (6-8 weeks)")))
              ),
              p(style="font-size:11px; color:rgba(255,255,255,0.6); text-align:center; margin-top:10px;",
                "Figures cited above are drawn from the reference list at the foot of this tab, not from ",
                "the simulated data used elsewhere in the app."),

              br(),
              fluidRow(
                column(4,
                  div(style="background:rgba(255,255,255,0.06); border:1px solid rgba(74,144,226,0.4); border-radius:8px; padding:8px; text-align:center;",
                    tags$img(src = "img/slide_continuity_gap.png", style = "width:100%; border-radius:4px;"),
                    tags$p(style="font-size:10px; color:#a8b6d8; margin:6px 0 0 0;",
                      "Original pitch-deck slide, provided for context.")
                  )
                ),
                column(8,
                  tags$h4("Touchpoint density across the maternal journey"),
                  p(style="font-size:12.5px; color:rgba(255,255,255,0.75);",
                    "Baby touchpoints continue on a dense, well-defined schedule. Mother touchpoints ",
                    "drop to almost nothing after birth, subject to GP availability, then stay silent ",
                    "through the return-to-work transition.")
                )
              ),

              uiOutput(ns("journey_track")),

              p(style="font-size:11px; color:rgba(255,255,255,0.55); margin-top:6px;",
                icon("info-circle"), " Filled dots = an active, structured touchpoint for that stage. ",
                "Faded dots = no structured contact scheduled - this is where the continuity gap lives."),

              plotly::plotlyOutput(ns("touchpoint_density_plot"), height = "280px"),
              concept_note(
                tags$strong("What this shows: "),
                "The grouped bars count structured, scheduled touchpoints per journey stage for the ",
                "baby (health visitor checks, immunisations) versus the mother (antenatal appointments, ",
                "delivery care, the single 6-8 week postnatal check). The gap between the two bars in the ",
                "Postnatal and Return to Work columns is the continuity gap this app exists to close - it is ",
                "not that mothers are unwell less often, it is that almost nobody is structurally checking."
              )
            ),

            reference_panel_ui(c("bauer2014", "cox1987"))
          ),

          # ══════════════════════════════════════════════════════════════════
          # SUBTAB 2 — INTELLIGENCE LAYER & INTERVENTIONS
          # ══════════════════════════════════════════════════════════════════
          tabPanel(
            title = tagList(icon("brain"), " Intelligence Layer"),
            br(),

            div(class = "slide-panel",
              span(class = "slide-pill", "THE TECHNOLOGY"),
              tags$h3("The intelligence layer for preventative maternal health"),
              p(style="font-size:12.5px; color:rgba(255,255,255,0.75);",
                "Building the longitudinal data foundation for a maternal digital twin: continuous ",
                "inputs feed a single intelligence layer, which drives four downstream capabilities."),

              fluidRow(
                column(3,
                  div(style="background:rgba(255,255,255,0.06); border:1px solid rgba(74,144,226,0.4); border-radius:8px; padding:8px; text-align:center;",
                    tags$img(src = "img/slide_intelligence_layer.png", style = "width:100%; border-radius:4px;"),
                    tags$p(style="font-size:10px; color:#a8b6d8; margin:6px 0 0 0;",
                      "Original pitch-deck slide, provided for context.")
                  )
                ),
                column(9,
                  tags$h4("Explore an input signal", style="margin-top:0;"),
                  p(style="font-size:11.5px; color:rgba(255,255,255,0.6);",
                    "Pick a signal to see what it captures and exactly which downstream capability it feeds. ",
                    "No single signal feeds everything - that separation is what keeps the model explainable."),
                  selectInput(ns("signal_select"), NULL,
                    choices = c("Mood" = "mood", "Blood pressure" = "bp", "Sleep" = "sleep",
                                "Symptoms" = "symptoms", "Care history" = "care_history",
                                "Work & support context" = "work_context")),
                  uiOutput(ns("signal_detail"))
                )
              ),

              br(),
              tags$h4("The maternal digital twin"),
              p(style="font-size:11.5px; color:rgba(255,255,255,0.6);",
                "Six continuous input streams (left) are combined into one longitudinal record per mother ",
                "- the digital twin - which in turn drives four distinct outputs (right). Inputs never feed ",
                "an output directly; everything passes through the twin, which is what lets the model compare ",
                "a mother to her own history rather than to a population average."),
              uiOutput(ns("digital_twin_diagram")),

              br(),
              tags$h4("Roadmap"),
              p(style="font-size:11.5px; color:rgba(255,255,255,0.6);",
                "The intelligence layer is built in three stages, each unlocking a heavier level of ",
                "regulatory classification as the model moves from personalisation to prediction."),
              fluidRow(
                column(4, div(class = "mint-card",
                  span(class="risk-badge", style="background:#1a6b35;", "In beta testing"),
                  tags$h5("V1 - Capture & personalise"),
                  p(style="font-size:12px;", "Continuous check-ins and connected-device signals generate personalised education and the first longitudinal maternal dataset."),
                  p(style="font-size:10.5px; color:#a8b6d8;", tags$em("Regulatory: Class I device")))),
                column(4, div(class = "mint-card",
                  span(class="risk-badge", style="background:#d4ac0d;", "In development"),
                  tags$h5("V2 - Support clinician decisions"),
                  p(style="font-size:12px;", "Longitudinal insights and scored screening at the periodic check help clinicians prioritise concerns and reduce missed issues."),
                  p(style="font-size:10.5px; color:#a8b6d8;", tags$em("Regulatory: Class I device")))),
                column(4, div(class = "mint-card",
                  span(class="risk-badge", style="background:#c0392b;", "2027+"),
                  tags$h5("V3 - Predict & prevent"),
                  p(style="font-size:12px;", "Condition-specific models flag divergence from a mother's own baseline weeks before a clinical threshold is crossed."),
                  p(style="font-size:10.5px; color:#a8b6d8;", tags$em("Regulatory: Class IIa / FDA track"))))
              )
            ),

            reference_panel_ui(c("hurwitz2024", "abdalrazaq2023"))
          ),

          # ══════════════════════════════════════════════════════════════════
          # SUBTAB 3 — RISK TRAJECTORY & EARLY DETECTION
          # ══════════════════════════════════════════════════════════════════
          tabPanel(
            title = tagList(icon("chart-line"), " Risk Trajectory"),
            br(),

            div(class = "slide-panel",
              span(class = "slide-pill", "THE BACK END"),
              tags$h3("Detect the trajectory early - months before crisis"),
              p(style="font-size:12.5px; color:rgba(255,255,255,0.75);",
                "Condition-specific models read the longitudinal record continuously and flag ",
                "divergence from a mother's own baseline before a clinical threshold is crossed.")
            ),

            fluidRow(
              column(3,
                div(style="background:rgba(255,255,255,0.06); border:1px solid rgba(74,144,226,0.4); border-radius:8px; padding:8px; text-align:center; margin-bottom:14px;",
                  tags$img(src = "img/slide_risk_trajectory.png", style = "width:100%; border-radius:4px;"),
                  tags$p(style="font-size:10px; color:#a8b6d8; margin:6px 0 0 0;",
                    "Original pitch-deck slide, provided for context.")
                )
              ),
              column(9,
                fluidRow(
                  column(4, selectInput(ns("rt_cohort_filter"), "Cohort:",
                           choices = c("All cohorts" = "all", COHORT_LABELS), selected = "all")),
                  column(4, uiOutput(ns("rt_mother_selector"))),
                  column(4, br(), actionButton(ns("rt_resample"), "Resample Cohort",
                           class = "btn-primary", icon = icon("sync"), style = "width:100%;"))
                )
              )
            ),

            fluidRow(
              box(title = "Risk Trajectory vs Own Baseline", status = "primary", solidHeader = TRUE, width = 8,
                concept_note(
                  tags$strong("What this shows: "),
                  "The composite risk score (0-100) for the selected mother, plotted week by week since ",
                  "birth. It is scored against her own baseline, not a population average, so a steady ",
                  "climb is meaningful even if her absolute score never looks extreme. The dashed line is ",
                  "the clinical threshold zone; the annotated point is where the model first flags sustained ",
                  "divergence - typically weeks before that dashed line is reached."
                ),
                plotly::plotlyOutput(ns("trajectory_plot"), height = "360px")
              ),
              box(title = "What Raised The Flag", status = "warning", solidHeader = TRUE, width = 4,
                concept_note(
                  tags$strong("Flagged: "), "the week the behavioural score first crossed the early-warning ",
                  "level. ", tags$strong("Lead time: "), "how many days earlier that is than the clinical ",
                  "threshold would have been crossed - the window in which support can still change the outcome."
                ),
                uiOutput(ns("flag_kpis")),
                br(),
                p(style="font-size:11px; color:#a8b6d8; margin-bottom:2px;",
                  "Each bar below is one signal's weighted contribution to the score at the flagged week - ",
                  "the longer the bar, the more that signal drove the flag."),
                plotly::plotlyOutput(ns("breakdown_plot"), height = "200px"),
                br(),
                uiOutput(ns("action_panel"))
              )
            ),

            fluidRow(
              box(title = "Risk Criteria & Calibration Check", status = "primary", solidHeader = TRUE, width = 12,
                fluidRow(
                  column(6,
                    p(style="font-size:12px; color:#e0e7ff;",
                      "Five behavioural signals feed the composite score. Each is a 0-1 measure of how far ",
                      "that week's reading has drifted from the mother's own recent baseline; the weight sets ",
                      "how much a full-scale drift in that signal alone can move the composite score."),
                    tags$table(class = "table table-condensed",
                      tags$thead(tags$tr(tags$th("Signal"), tags$th("Weight"), tags$th("What it captures"))),
                      tags$tbody(
                        tags$tr(tags$td("Sleep fragmentation"), tags$td("0.89"), tags$td("Broken, non-restorative sleep vs the mother's own recent pattern")),
                        tags$tr(tags$td("Mood variance (14-day)"), tags$td("0.74"), tags$td("How much day-to-day mood is swinging over a rolling 2-week window")),
                        tags$tr(tags$td("Check-in engagement drop"), tags$td("0.61"), tags$td("Falling participation in app check-ins - often an early withdrawal signal")),
                        tags$tr(tags$td("Support content change"), tags$td("0.49"), tags$td("Shift in which support/education content she is engaging with")),
                        tags$tr(tags$td("Resting HRV vs own baseline"), tags$td("0.39"), tags$td("Autonomic/physiological strain relative to her own resting baseline"))
                      )
                    ),
                    p(style="font-size:11.5px; color:#a8b6d8;",
                      "The EPDS self-harm item (item 10) is a separate, deterministic trigger and is ",
                      "never blended into this weighted composite - see the app README for the safety rationale.")
                  ),
                  column(6,
                    p(style="font-size:12px; color:#e0e7ff;",
                      "A risk score is only useful as a visual if it spans the whole colour scale under ",
                      "realistic inputs, rather than clustering everyone into one band. This chart is that ",
                      "check: each mother's latest-week score, banded Low/Moderate/High/Critical, by cohort."),
                    plotly::plotlyOutput(ns("distribution_plot"), height = "240px")
                  )
                )
              )
            ),

            reference_panel_ui(c("abdalrazaq2023", "hurwitz2024"))
          ),

          # ══════════════════════════════════════════════════════════════════
          # SUBTAB 4 — STATISTICAL CONCEPTS (ENRICHED with interactive visuals)
          # ══════════════════════════════════════════════════════════════════
          tabPanel(
            title = tagList(icon("graduation-cap"), " Statistical Concepts"),
            br(),

            div(class = "slide-panel",
              span(class = "slide-pill", "FOUNDATIONS"),
              tags$h3("Four ideas behind every chart in this app"),
              p(style="font-size:12.5px; color:rgba(255,255,255,0.75);",
                "Correlation, causality, statistical significance and A/B testing are easy to blur together. ",
                "Each box below explains one concept in plain language with a mental-health example, ",
                "accompanied by interactive visualizations that show exactly how these concepts work in practice.")
            ),

            # ────────────────────────────────────────────────────────────────
            # CONCEPT 1: CORRELATION
            # ────────────────────────────────────────────────────────────────
            fluidRow(
              column(6,
                div(class = "mint-card", style = "margin-bottom:18px;",
                  tags$h4(icon("link"), " Correlation: Two things moving together"),
                  p("Two variables move together across a population. The correlation coefficient (r) ranges from -1 (perfect ",
                    "negative) through 0 (no relationship) to +1 (perfect positive). But correlation alone says nothing about ",
                    "direction of causality or confounding factors."),
                  div(class = "concept-note",
                    tags$strong("Mental health example: "),
                    "Poor sleep and depression correlate strongly in maternal populations (r ≈ 0.4-0.6). Yet poor sleep may ",
                    "cause depression, depression may disrupt sleep, or both could result from untreated anxiety. Correlation ",
                    "shows they move together; establishing which is the cause requires additional evidence."
                  ),
                  box_reference_note(c("baglioni2011", "altman2015"))
                )
              ),
              column(6,
                box(title = "Interactive: Correlation Strength Explorer", status = "warning", solidHeader = TRUE, width = 12,
                  p(style="font-size:11px; color:#e0e7ff;",
                    "Drag the slider below to adjust the correlation strength. Watch how the scatter plot changes: ",
                    "higher correlation means points cluster tighter along a line."),
                  fluidRow(
                    column(12,
                      sliderInput(ns("corr_demo_strength"), "Correlation strength (r):",
                                 min = -1, max = 1, value = 0.5, step = 0.1),
                      selectInput(ns("corr_demo_direction"), "Direction:",
                                 choices = c("Positive (↑ together)" = "pos", "Negative (↑ vs ↓)" = "neg"))
                    )
                  ),
                  plotly::plotlyOutput(ns("corr_demo_scatter"), height = "260px"),
                  div(style="background:rgba(255,255,255,0.04); border-left:3px solid #667eea; padding:8px; font-size:11px; color:#a8b6d8; margin-top:8px;",
                    tags$strong("Interpretation guide: "),
                    br(),
                    "r = 0 → no relationship (scatter looks random)",
                    br(),
                    "r = ±0.3 → weak but detectable",
                    br(),
                    "r = ±0.6 → moderate, useful for prediction",
                    br(),
                    "r = ±0.9 → very strong, tightly clustered"
                  )
                )
              )
            ),

            # ────────────────────────────────────────────────────────────────
            # CONCEPT 2: CAUSALITY
            # ────────────────────────────────────────────────────────────────
            fluidRow(
              column(6,
                box(title = "Interactive: Causality & Confounding", status = "warning", solidHeader = TRUE, width = 12,
                  p(style="font-size:11px; color:#e0e7ff;",
                    "Toggle below to see how a hidden confounder can create a spurious correlation between ",
                    "two variables that don't actually cause each other."),
                  fluidRow(
                    column(12,
                      checkboxInput(ns("causal_show_confounder"), 
                                   "Show hidden confounder (e.g., stress driving both)", value = FALSE)
                    )
                  ),
                  plotly::plotlyOutput(ns("causal_demo_dag"), height = "280px"),
                  div(style="background:rgba(255,255,255,0.04); border-left:3px solid #667eea; padding:8px; font-size:11px; color:#a8b6d8; margin-top:8px;",
                    tags$strong("What this shows: "),
                    br(),
                    "Left panel (without confounder): Sleep → Depression appears causal.",
                    br(),
                    "Right panel (with confounder): High stress causes both poor sleep AND depression, ",
                    "making them correlated even if sleep doesn't cause depression directly.",
                    br(),
                    "Only experiments (randomisation) or careful adjustment can disentangle this."
                  )
                )
              ),
              column(6,
                div(class = "mint-card", style = "margin-bottom:18px;",
                  tags$h4(icon("arrow-right"), " Causality: X actually causes Y"),
                  p("Causality means manipulating X produces a change in Y. Establishing causality typically requires: ",
                    tags$strong("(1)"), " a strong, consistent association; ",
                    tags$strong("(2)"), " temporal precedence (cause before effect); ",
                    tags$strong("(3)"), " a plausible mechanism; and ",
                    tags$strong("(4)"), " elimination of confounds (usually via randomisation)."),
                  div(class = "concept-note",
                    tags$strong("Mental health example: "),
                    "\"Mothers receiving peer support improved\" could mean more resourced mothers both sought support ",
                    "and improved anyway. A randomised trial—randomly assigning some mothers to support—lets researchers ",
                    "claim the support caused the improvement, because assignment was not self-selected."
                  ),
                  box_reference_note(c("hill1965", "dennis2013"))
                )
              )
            ),

            # ────────────────────────────────────────────────────────────────
            # CONCEPT 3: STATISTICAL SIGNIFICANCE
            # ────────────────────────────────────────────────────────────────
            fluidRow(
              column(6,
                div(class = "mint-card",
                  tags$h4(icon("percentage"), " Statistical Significance: Unlikely by chance"),
                  p("A p-value answers a specific question: ",
                    tags$em("If there were truly no effect, how surprising would this result be?"), 
                    " A small p-value means \"unlikely under the null hypothesis\", not \"large\", ",
                    "\"important\", or \"clinically meaningful\". Those require effect size."),
                  div(class = "concept-note",
                    tags$strong("Mental health example: "),
                    "A trial with 10,000 mothers could find a statistically significant (p < 0.001) ",
                    "1-point reduction on a 30-point depression scale. Significant? Yes. Clinically important? ",
                    "Probably not—mothers may notice no difference. Significance and importance are separate."
                  ),
                  box_reference_note(c("wasserstein2016", "sullivan2012"))
                )
              ),
              column(6,
                box(title = "Interactive: P-values Explained", status = "warning", solidHeader = TRUE, width = 12,
                  p(style="font-size:11px; color:#e0e7ff;",
                    "Adjust sample size and effect size. Watch how the p-value and significance threshold change—",
                    "larger effects and bigger samples make small differences detectable."),
                  fluidRow(
                    column(6, sliderInput(ns("pval_n"), "Sample size per group:",
                                         min = 10, max = 500, value = 50, step = 10)),
                    column(6, sliderInput(ns("pval_effect"), "Effect size (Cohen's d):",
                                         min = 0, max = 1.5, value = 0.5, step = 0.05))
                  ),
                  plotly::plotlyOutput(ns("pval_demo_curves"), height = "280px"),
                  div(style="background:rgba(255,255,255,0.04); border-left:3px solid #667eea; padding:8px; font-size:11px; color:#a8b6d8; margin-top:8px;",
                    tags$strong("Key insight: "),
                    "The red and blue curves represent the \"null\" (no effect) and \"true effect\" distributions. ",
                    "The overlap area is the p-value threshold. Bigger samples and larger effects shrink that overlap."
                  )
                )
              )
            ),

            # ────────────────────────────────────────────────────────────────
            # CONCEPT 4: A/B TESTING
            # ────────────────────────────────────────────────────────────────
            fluidRow(
              column(6,
                box(title = "Interactive: A/B Test Power Calculator", status = "warning", solidHeader = TRUE, width = 12,
                  p(style="font-size:11px; color:#e0e7ff;",
                    "Adjust parameters below to see how sample size needs to change to detect a real effect. ",
                    "The curves show required n for different combinations of power and effect size."),
                  fluidRow(
                    column(4, selectInput(ns("power_alpha"), "Significance level (α):",
                                         choices = c("0.05 (standard)" = 0.05, "0.01 (strict)" = 0.01, 
                                                    "0.10 (lenient)" = 0.10), selected = 0.05)),
                    column(4, selectInput(ns("power_beta"), "Power (1 - β):",
                                         choices = c("0.80 (standard)" = 0.80, "0.90 (high)" = 0.90), 
                                         selected = 0.80)),
                    column(4, selectInput(ns("power_test"), "Test type:",
                                         choices = c("Two independent means" = "means", 
                                                    "Two proportions" = "props"), 
                                         selected = "means"))
                  ),
                  plotly::plotlyOutput(ns("power_demo_curves"), height = "280px"),
                  div(style="background:rgba(255,255,255,0.04); border-left:3px solid #667eea; padding:8px; font-size:11px; color:#a8b6d8; margin-top:8px;",
                    tags$strong("Reading the curves: "),
                    "Each line represents a different effect size (Cohen's d). ",
                    "The x-axis is the sample size needed. Smaller effects require larger samples."
                  )
                )
              ),
              column(6,
                div(class = "mint-card",
                  tags$h4(icon("balance-scale"), " A/B Testing: Randomised comparison"),
                  p("An A/B test (randomised controlled trial by another name) randomly assigns people to different ",
                    "groups and compares outcomes. Random assignment is crucial—it makes the groups equal ",
                    "in expectation before the intervention, so any difference can be attributed to the intervention."),
                  div(class = "concept-note",
                    tags$strong("Mental health example: "),
                    "Comparing mothers who chose to download an app against those who did not is NOT an A/B test; ",
                    "the groups likely differ in motivation and access before the app. A genuine test randomly assigns ",
                    "who gets the app. The randomisation is what licenses the causal claim."
                  ),
                  box_reference_note(c("kohavi2009", "dennis2013"))
                )
              )
            ),

            reference_panel_ui(c("baglioni2011", "altman2015", "hill1965", "dennis2013", 
                                 "wasserstein2016", "sullivan2012", "kohavi2009"))
          ),

          # ══════════════════════════════════════════════════════════════════
          # SUBTAB 5 — CONCEPTS APPLIED TO PPD MONITORING (SIGNIFICANTLY ENRICHED)
          # ══════════════════════════════════════════════════════════════════
          tabPanel(
            title = tagList(icon("microscope"), " Applied to Our Monitoring"),
            br(),

            div(class = "slide-panel",
              span(class = "slide-pill", "IN PRACTICE"),
              tags$h3("The same four ideas, applied directly to this app's data"),
              p(style="font-size:12.5px; color:rgba(255,255,255,0.75);",
                "Every chart elsewhere in this module rests on one of the four concepts from the previous tab. ",
                "Below, we apply each one to postpartum depression monitoring using this app's own data and outputs.")
            ),

            # Correlation Applied
            fluidRow(
              column(6,
                div(class = "mint-card", style = "margin-bottom:18px;",
                  tags$h4(icon("link"), " Correlation in Postpartum Depression"),
                  p("The five behavioural signals behind the composite risk score were chosen because they correlate ",
                    "with EPDS scores in our simulated cohort. The scatter plot (right) shows this relationship for one ",
                    "signal; the correlation coefficient is recomputed each time the signal selection changes."),
                  div(class = "concept-note",
                    tags$strong("What this tells us: "),
                    "A high correlation means the signal moves with EPDS scores, making it useful for early warning. ",
                    "But correlation alone does NOT tell us the signal causes the depression or vice versa—just that ",
                    "they are linked, and we can use that linkage for prediction."
                  ),
                  box_reference_note(c("baglioni2011", "altman2015"))
                )
              ),
              column(6,
                box(title = "Signal-to-EPDS Correlation (Live Data)", status = "primary", solidHeader = TRUE, width = 12,
                  fluidRow(
                    column(12, selectInput(ns("corr_ppd_signal"), "Select a behavioural signal:",
                             choices = c("Sleep fragmentation" = "sleep_fragmentation",
                                         "Mood variance (14-day)" = "mood_variance_14d",
                                         "Check-in engagement drop" = "checkin_engagement_drop",
                                         "Support content shift" = "support_content_change",
                                         "HRV delta vs baseline" = "resting_hrv_delta")))
                  ),
                  plotly::plotlyOutput(ns("corr_ppd_scatter"), height = "280px"),
                  div(style="background:rgba(255,255,255,0.04); border-left:3px solid #667eea; padding:8px; font-size:11px; color:#a8b6d8; margin-top:8px;",
                    uiOutput(ns("corr_ppd_interpretation"))
                  )
                )
              )
            ),

            # Causality Applied
            fluidRow(
              column(6,
                box(title = "Causality: Risk Score → Outcome (Simulated)", status = "primary", solidHeader = TRUE, width = 12,
                  p(style="font-size:11px; color:#e0e7ff;",
                    "Below: mothers split by risk score quartile at week 4, followed forward to week 24. ",
                    "Higher initial risk predicts worse outcomes at the end—but this is correlational, not causal, ",
                    "unless the risk score somehow caused the poor outcome (which it does not by definition)."),
                  plotly::plotlyOutput(ns("causal_ppd_trajectory"), height = "280px"),
                  div(style="background:rgba(255,255,255,0.04); border-left:3px solid #667eea; padding:8px; font-size:11px; color:#a8b6d8; margin-top:8px;",
                    tags$strong("Critical interpretation: "),
                    "The gap between quartiles shows that the risk score predicts divergent outcomes. ",
                    "For a causal claim—i.e., that reducing the risk score causes better outcomes—we need ",
                    "an intervention (the next tab) randomly assigned to some mothers."
                  ),
                  box_reference_note(c("hill1965", "dennis2013"))
                )
              ),
              column(6,
                div(class = "mint-card", style = "margin-bottom:18px;",
                  tags$h4(icon("arrow-right"), " Causality in our framework"),
                  p("The Risk Trajectory tab is NOT a causal claim—it shows that the risk score predicts outcomes. ",
                    "The Cohort A/B Simulation tab comes closer to causality, because it models random assignment to ",
                    "support vs control, which removes self-selection bias."),
                  div(class = "concept-note",
                    tags$strong("The careful limit we respect: "),
                    "In a real deployment, mothers who opt into the app are self-selected (motivated, tech-savvy, etc.). ",
                    "A true causal claim—\"our app causes better mental health\"—requires a randomised trial, not just ",
                    "comparing opt-in against opt-out."
                  ),
                  box_reference_note(c("hill1965", "dennis2013"))
                )
              )
            ),

            # Significance Applied
            fluidRow(
              column(6,
                div(class = "mint-card",
                  tags$h4(icon("percentage"), " Statistical Significance in our data"),
                  p("The Cohort A/B Simulation tab (next) reports a t-test comparing App-Supported mothers against ",
                    "No-Support controls. Below, that same test is recomputed live, alongside the effect size, because ",
                    "p-values and effect sizes answer different questions."),
                  div(class = "concept-note",
                    tags$strong("The distinction that matters: "),
                    "A p < 0.05 means \"unlikely by chance under no-effect.\" ",
                    "But \"unlikely by chance\" and \"clinically large\" are different. We report both."
                  ),
                  box_reference_note(c("wasserstein2016", "sullivan2012"))
                )
              ),
              column(6,
                box(title = "P-value & Effect Size (App-Supported vs No-Support)", status = "warning", 
                    solidHeader = TRUE, width = 12,
                  p(style="font-size:11px; color:#e0e7ff;",
                    "Below: t-test comparing the two cohorts at week 24. The shaded region represents the ",
                    "distribution of risk scores for each group; their overlap (if any) informs the p-value."),
                  plotly::plotlyOutput(ns("significance_ppd_distributions"), height = "260px"),
                  uiOutput(ns("significance_ppd_kpis")),
                  div(style="background:rgba(255,255,255,0.04); border-left:3px solid #667eea; padding:8px; font-size:11px; color:#a8b6d8; margin-top:8px;",
                    tags$strong("Interpretation: "),
                    "Small p-value = the difference is unlikely by chance. Large effect size (Cohen's d) = the ",
                    "difference is clinically meaningful. You need both for strong evidence."
                  )
                )
              )
            ),

            # A/B Testing Applied
            fluidRow(
              column(12,
                div(class = "mint-card",
                  tags$h4(icon("balance-scale"), " A/B Testing in our PPD monitoring"),
                  p("The Cohort A/B Simulation tab models three arms: App-Supported, Standard Care, and No-Support. ",
                    "In a simulated randomised trial, we assign mothers to arms at random, track outcomes, and compare. ",
                    "Below: a plain-language statement of what would need to be true for a real-world trial to license ",
                    "a causal claim, versus what our simulation provides."),
                  tags$table(class = "table table-striped",
                    tags$thead(tags$tr(
                      tags$th("Requirement for a causal claim"), 
                      tags$th("Our simulation"), 
                      tags$th("A real trial")
                    )),
                    tags$tbody(
                      tags$tr(tags$td("Random assignment to arm"), 
                              tags$td(tags$span(class="badge badge-success", "✓ Yes, by construction")), 
                              tags$td("Must use randomisation protocol (minimisation, stratification, etc.)")),
                      tags$tr(tags$td("Primary outcome pre-registered"), 
                              tags$td(tags$span(class="badge badge-warning", "⚠ Simulated (composite risk score)")), 
                              tags$td("Fixed before data collection—usually EPDS at a specific week")),
                      tags$tr(tags$td("Sample size justified in advance"), 
                              tags$td(tags$span(class="badge badge-info", "→ See Cohort tab power table")), 
                              tags$td("Power calculation using real pilot-study variance and effect size)")),
                      tags$tr(tags$td("Blinding"), 
                              tags$td(tags$span(class="badge badge-secondary", "N/A (aware of arm assignment)")), 
                              tags$td("Usually not possible (mothers know if they have the app)")),
                      tags$tr(tags$td("Registered trial protocol"), 
                              tags$td(tags$span(class="badge badge-muted", "Not applicable (simulation)")), 
                              tags$td("Prospective registration (ClinicalTrials.gov or ISRCTN)"))
                    )
                  ),
                  br(),
                  div(class = "concept-note",
                    tags$strong("Why simulation vs reality matter: "),
                    "In the simulation, we control randomisation perfectly. In a real deployment, mothers self-select. ",
                    "A genuine causal claim requires a registered RCT, not retrospective comparison of opt-in vs opt-out."
                  ),
                  box_reference_note(c("kohavi2009", "dennis2013", "julious2004"))
                )
              )
            ),

            reference_panel_ui(c("baglioni2011", "altman2015", "hill1965", "dennis2013",
                                 "wasserstein2016", "sullivan2012", "kohavi2009", "julious2004"))
          ),

          # ══════════════════════════════════════════════════════════════════
          # SUBTAB 6 — COHORT A/B SIMULATION (ENHANCED with parameter controls)
          # ══════════════════════════════════════════════════════════════════
          tabPanel(
            title = tagList(icon("balance-scale"), " Cohort A/B Simulation"),
            br(),

            div(class = "slide-panel",
              span(class = "slide-pill", "VALIDATION"),
              tags$h3("Comparing pathways of support across randomised cohorts"),
              p(style="font-size:12.5px; color:rgba(255,255,255,0.75);",
                "App-supported vs standard NHS care vs no structured support—the same cohort-comparison pattern ",
                "used to validate maternal wellbeing interventions.")
            ),

            fluidRow(
              box(title = "Simulation Parameters & Controls", status = "info", solidHeader = TRUE, width = 12,
                p(style="font-size:11px; color:#e0e7ff;",
                  "Adjust the parameters below to re-run the simulation with different assumptions. ",
                  "Watch how changes in cohort size, effect size, or signal weights alter the outcomes."),
                fluidRow(
                  column(3, 
                    sliderInput(ns("ab_cohort_size"), "Mothers per cohort:",
                               min = 20, max = 200, value = 100, step = 10)),
                  column(3,
                    sliderInput(ns("ab_effect_multiplier"), "App effect multiplier:",
                               min = 0.5, max = 2.0, value = 1.0, step = 0.1),
                    p(style="font-size:10px; color:#a8b6d8; margin-top:4px;",
                      "1.0 = standard effect; >1 = stronger app benefit")),
                  column(3,
                    selectInput(ns("ab_signal_weights"), "Signal weighting:",
                               choices = c("Equal (simple)" = "equal",
                                          "Optimised (sleep-heavy)" = "sleep_heavy",
                                          "Conservative (engagement-heavy)" = "engagement_heavy"))),
                  column(3,
                    actionButton(ns("ab_resimulate"), "Re-simulate",
                               class = "btn-primary", style = "width:100%; margin-top:28px;",
                               icon = icon("sync")))
                )
              )
            ),

            p(style="font-size:11.5px; color:#a8b6d8; margin:2px 4px 10px 4px;",
              icon("info-circle"), " All KPIs below compare App-Supported mothers against No-Support controls at ",
              "week 24 (or the mother's onset week for timing metrics). Positive numbers favour App-Supported."),

            fluidRow(
              column(3, valueBoxOutput(ns("kpi_epds_delta"), width = 12)),
              column(3, valueBoxOutput(ns("kpi_risk_delta"), width = 12)),
              column(3, valueBoxOutput(ns("kpi_flag_lead"), width = 12)),
              column(3, valueBoxOutput(ns("kpi_selfharm_rate"), width = 12))
            ),

            fluidRow(
              box(title = "Risk Score Distribution by Cohort (week 24)", status = "primary", solidHeader = TRUE, width = 6,
                concept_note(
                  tags$strong("What this shows: "),
                  "Each cohort's distribution at week 24. The box marks the middle 50%, the line is the median, ",
                  "points are individual mothers. The bracket reports a two-sample t-test."
                ),
                plotly::plotlyOutput(ns("ab_box_plot"), height = "380px")
              ),
              box(title = "Kernel Density Estimate by Cohort", status = "primary", solidHeader = TRUE, width = 6,
                concept_note(
                  tags$strong("What this shows: "),
                  "A smoothed density curve for each cohort. Dashed lines mark the mean. The further apart ",
                  "and less overlapped, the clearer the separation."
                ),
                plotly::plotlyOutput(ns("ab_density_plot"), height = "380px")
              )
            ),

            fluidRow(
              box(title = "Risk Score Evolution Over Weeks (cohort mean ± SE)", status = "primary", 
                  solidHeader = TRUE, width = 6,
                concept_note(
                  tags$strong("What this shows: "),
                  "The average risk trajectory for each cohort from birth to week 24. The shaded band is ±1 SE—",
                  "narrow means cohort average is stable, wide means mothers vary a lot."
                ),
                checkboxInput(ns("ab_show_ci"), "Show confidence band", value = TRUE),
                plotly::plotlyOutput(ns("ab_evolution_plot"), height = "290px")
              ),
              box(title = "Normalised Signal Heatmap (week 24)", status = "primary", solidHeader = TRUE, width = 6,
                concept_note(
                  tags$strong("What this shows: "),
                  "The five underlying signals (not the composite score), averaged per cohort at week 24. ",
                  "Darker blue = further from baseline."
                ),
                plotly::plotlyOutput(ns("ab_heatmap_plot"), height = "290px")
              )
            ),

            fluidRow(
              box(title = "Per-Mother Risk Delta vs No-Support Baseline", status = "primary", solidHeader = TRUE, width = 12,
                concept_note(
                  tags$strong("What this shows: "),
                  "Every App-Supported and Standard-Care mother's week-24 risk score, minus the average No-Support score. ",
                  "Bars below zero = doing better than unsupported average; above zero = doing worse."
                ),
                plotly::plotlyOutput(ns("ab_delta_plot"), height = "260px")
              )
            ),

            fluidRow(
              box(title = "Sample Size Recommendation for Real-World Trial", status = "warning", solidHeader = TRUE, width = 12,
                concept_note(
                  tags$strong("What this shows: "),
                  "How many mothers per cohort a real trial would need to reliably detect each outcome, using ",
                  "standard power calculations. Smaller effect sizes require larger samples."
                ),
                fluidRow(
                  column(3, selectInput(ns("ss_effect_preset"), "Effect size (Cohen's d):",
                           choices = c("Small (0.2) - conservative" = "Small",
                                       "Medium (0.5) - recommended" = "Medium",
                                       "Large (0.8) - strong effect" = "Large"),
                           selected = "Medium")),
                  column(3, sliderInput(ns("ss_power"), "Statistical power (1 - β):",
                           min = 0.7, max = 0.95, value = 0.8, step = 0.05)),
                  column(3, sliderInput(ns("ss_alpha"), "Significance level (α):",
                           min = 0.01, max = 0.10, value = 0.05, step = 0.01)),
                  column(3, br(), uiOutput(ns("ss_recommendation_badge")))
                ),
                tags$table(class = "table table-condensed",
                  tags$thead(tags$tr(
                    tags$th("Outcome"), tags$th("Type"), tags$th("Test"), 
                    tags$th("Effect assumed"), tags$th("n per group"), tags$th("Total (3 arms)"), 
                    tags$th("Justification")
                  )),
                  tags$tbody(uiOutput(ns("ss_table_rows")))
                ),
                p(style="font-size:11px; color:#a8b6d8; margin-top:8px;",
                  "Formulas: continuous outcomes use n = 2(z_α + z_β)² / d²; binary uses the two-proportions ",
                  "approximation (Julious, 2004). Effect sizes follow Cohen (1988).")
              )
            ),

            reference_panel_ui(c("dennis2013", "bauer2014", "cohen1988", "julious2004"))
          ),

          # ══════════════════════════════════════════════════════════════════
          # SUBTAB 7 — INTERVENTION TIMELINE (SIGNIFICANTLY ENHANCED)
          # ══════════════════════════════════════════════════════════════════
          tabPanel(
            title = tagList(icon("route"), " Intervention Timeline"),
            br(),

            div(class = "slide-panel",
              span(class = "slide-pill", "THE CARE PATHWAY"),
              tags$h3("Support from several weeks before birth to two years after"),
              p(style="font-size:12.5px; color:rgba(255,255,255,0.75);",
                "\"Matrescence\" - the physical, psychological and identity transition into motherhood - ",
                "spans far longer than a single postnatal check. Below: a timeline of evidence-based interventions, ",
                "paired with a mental-health risk curve showing how continuous support mitigates the natural rise in risk."),
              fluidRow(
                column(3,
                  div(style="background:rgba(255,255,255,0.06); border:1px solid rgba(74,144,226,0.4); border-radius:8px; padding:8px; text-align:center;",
                    tags$img(src = "img/slide_matrescence_definition.png", style = "width:100%; border-radius:4px;"),
                    tags$p(style="font-size:10px; color:#a8b6d8; margin:6px 0 0 0;",
                      "Original pitch-deck slide, provided for context.")
                  )
                ),
                column(9,
                  p(style="font-size:11.5px; color:rgba(255,255,255,0.6);",
                    "Each intervention point below (click any marker on the graph) represents an evidence-based ",
                    "support touchpoint across the maternal journey. The curves show illustrative mental-health risk ",
                    "trajectories: without structured support (grey), and with layered, continuous support (teal). ",
                    "Notice the risk rise around return-to-work (week 52) persists in both—the support cannot eliminate ",
                    "real-world stressors, but it can accelerate recovery."),
                  p(style="font-size:10px; color:rgba(255,255,255,0.45);",
                    icon("info-circle"), " Risk curves are illustrative conceptual indices (0-100), not measured data. ",
                    "The simulated cohort dataset only runs to 24 weeks postpartum.")
                )
              )
            ),

            fluidRow(
              box(title = "Mental Health Risk Index: With vs Without Structured Support",
                  status = "primary", solidHeader = TRUE, width = 12,
                concept_note(
                  tags$strong("How to read this: "),
                  "Grey line = standard unstructured care. Teal line = continuous, layered support as described below. ",
                  tags$strong("Click any red marker"), 
                  " to see the intervention detail. Both curves rise around week 52 (return-to-work), ",
                  "because that transition carries real risk—support's value is in the height of the rise and recovery speed."
                ),
                plotly::plotlyOutput(ns("intervention_plot"), height = "420px")
              )
            ),

            fluidRow(
              box(title = "Intervention Touchpoints: Click a Marker for Details", status = "info", solidHeader = TRUE, width = 12,
                p(style="font-size:11px; color:#e0e7ff; margin-bottom:12px;",
                  "Below: detailed evidence and guidance for each intervention point along the timeline."),
                uiOutput(ns("intervention_detail"))
              )
            ),

            fluidRow(
              box(title = "Intervention Evidence Summary", status = "warning", solidHeader = TRUE, width = 12,
                p(style="font-size:11.5px; color:#e0e7ff;",
                  "Below is a summary table of the key interventions, their timing, and the clinical evidence supporting them."),
                tags$table(class = "table table-striped table-sm",
                  tags$thead(tags$tr(
                    tags$th("Period"), tags$th("Weeks"), tags$th("Intervention"),  tags$th("Risk factor addressed"),
                    tags$th("Key reference")
                  )),
                  tags$tbody(
                    tags$tr(tags$td("Antenatal"), tags$td("-8 to 0"), 
                           tags$td("Structured screening & psychoeducation"), 
                           tags$td("Early identification, normalisation"), 
                           tags$td("Bauer et al. (2014)")),
                    tags$tr(tags$td("Perinatal"), tags$td("0 to 2"), 
                           tags$td("Continuous monitoring + immediate support"), 
                           tags$td("Postnatal crisis, isolation"), 
                           tags$td("Dennis & Dowswell (2013)")),
                    tags$tr(tags$td("Early postpartum"), tags$td("2 to 8"), 
                           tags$td("Peer support + clinical touchpoints"), 
                           tags$td("Sleep deprivation, mood"), 
                           tags$td("Dennis & Dowswell (2013)")),
                    tags$tr(tags$td("Transition"), tags$td("8 to 24"), 
                           tags$td("Symptom-triggered intervention + planning"), 
                           tags$td("Subsyndromal depression, anxiety"), 
                           tags$td("Cox et al. (1987)")),
                    tags$tr(tags$td("Return to work"), tags$td("20 to 56"), 
                           tags$td("Employer engagement + continuity planning"), 
                           tags$td("Role strain, identity, support drop-off"), 
                           tags$td("Abdalrazaq et al. (2023)")),
                    tags$tr(tags$td("Consolidation"), tags$td("56 to 104"), 
                           tags$td("Ongoing monitoring + lifestyle support"), 
                           tags$td("Chronic stress, isolation"), 
                           tags$td("Bauer et al. (2014)"))
                  )
                )
              )
            ),

            reference_panel_ui(c("dennis2013", "cox1987", "bauer2014", "abdalrazaq2023", "hurwitz2024"))
          )
        )
      )
    )
  )
}
