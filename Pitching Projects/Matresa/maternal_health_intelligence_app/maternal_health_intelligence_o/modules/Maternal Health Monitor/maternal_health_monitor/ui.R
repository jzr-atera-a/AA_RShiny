# modules/Maternal Health Monitor/maternal_health_monitor/ui.R
# Four subtabs:
#   1. Continuity Gap Timeline      (ref: "Maternal health isn't a wellness gap")
#   2. Intelligence Layer & Interventions (ref: "The Intelligence Layer...")
#   3. Risk Trajectory & Early Detection  (ref: "Detect the trajectory early")
#   4. Cohort A/B Simulation              (treatment-pathway analog of driver_ab_test)

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
                  div(class = "stat-number", "\u00A38.1bn"),
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
              tags$h4("Touchpoint density across the maternal journey"),
              p(style="font-size:12.5px; color:rgba(255,255,255,0.75);",
                "Baby touchpoints continue on a dense, well-defined schedule. Mother touchpoints ",
                "drop to almost nothing after birth, subject to GP availability, then stay silent ",
                "through the return-to-work transition."),

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

              tags$h4("Explore an input signal"),
              p(style="font-size:11.5px; color:rgba(255,255,255,0.6);",
                "Pick a signal to see what it captures and exactly which downstream capability it feeds. ",
                "No single signal feeds everything - that separation is what keeps the model explainable."),
              fluidRow(
                column(4,
                  selectInput(ns("signal_select"), NULL,
                    choices = c("Mood" = "mood", "Blood pressure" = "bp", "Sleep" = "sleep",
                                "Symptoms" = "symptoms", "Care history" = "care_history",
                                "Work & support context" = "work_context"))
                ),
                column(8, uiOutput(ns("signal_detail")))
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
              column(4, selectInput(ns("rt_cohort_filter"), "Cohort:",
                       choices = c("All cohorts" = "all", COHORT_LABELS), selected = "all")),
              column(4, uiOutput(ns("rt_mother_selector"))),
              column(4, br(), actionButton(ns("rt_resample"), "Resample Cohort",
                       class = "btn-primary", icon = icon("sync"), style = "width:100%;"))
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
          # SUBTAB 4 — COHORT A/B SIMULATION
          # ══════════════════════════════════════════════════════════════════
          tabPanel(
            title = tagList(icon("balance-scale"), " Cohort A/B Simulation"),
            br(),

            div(class = "slide-panel",
              span(class = "slide-pill", "VALIDATION"),
              tags$h3("Comparing pathways of support"),
              p(style="font-size:12.5px; color:rgba(255,255,255,0.75);",
                "App-supported vs standard NHS care vs no structured support - the same ",
                "cohort-comparison pattern used to compare CPAP-treated, untreated and control ",
                "drivers, applied here to maternal wellbeing outcomes."),
              actionButton(ns("ab_resimulate"), "Re-simulate Cohorts",
                           class = "btn-primary", icon = icon("sync"))
            ),

            p(style="font-size:11.5px; color:#a8b6d8; margin:2px 4px 10px 4px;",
              icon("info-circle"), " The four KPIs below all compare the App-Supported cohort against the ",
              "No-Support control at the same simulated point in time (week 24, or the mother's own ",
              "onset week for the timing metric). Positive numbers favour the App-Supported cohort."),

            fluidRow(
              column(3, valueBoxOutput(ns("kpi_epds_delta"), width = 12)),
              column(3, valueBoxOutput(ns("kpi_risk_delta"), width = 12)),
              column(3, valueBoxOutput(ns("kpi_flag_lead"), width = 12)),
              column(3, valueBoxOutput(ns("kpi_selfharm_rate"), width = 12))
            ),

            fluidRow(
              box(title = "Composite Risk Score by Cohort (latest week) \u2014 Distribution & Significance",
                  status = "primary", solidHeader = TRUE, width = 6,
                concept_note(
                  tags$strong("What this shows: "),
                  "Each cohort's full distribution at week 24: the violin outline is the density shape, ",
                  "the box marks the middle 50% of mothers, the white line is the median, and points are ",
                  "individual mothers. The bracket reports a two-sample t-test comparing App-Supported ",
                  "against No-Support - this is the same significance-testing step used to validate the ",
                  "CPAP-treated vs untreated contrast in the reference driver-safety app."
                ),
                plotly::plotlyOutput(ns("ab_box_plot"), height = "380px")
              ),
              box(title = "Distribution Shape by Cohort (density curves)", status = "primary",
                  solidHeader = TRUE, width = 6,
                concept_note(
                  tags$strong("What this shows: "),
                  "A smoothed density (kernel density estimate) of composite risk scores for each cohort - ",
                  "the \"bell curve\" shape of each group. Dashed vertical lines mark each cohort's mean. ",
                  "The further apart the peaks and the less the curves overlap, the more clearly the ",
                  "intervention is separating outcomes between cohorts."
                ),
                plotly::plotlyOutput(ns("ab_density_plot"), height = "380px")
              )
            ),

            fluidRow(
              box(title = "Risk Evolution Over Weeks Postpartum (cohort mean \u00B1 SE)", status = "primary",
                  solidHeader = TRUE, width = 6,
                concept_note(
                  tags$strong("What this shows: "),
                  "The average composite risk score across each cohort, tracked from birth to week 24. ",
                  "The shaded band (toggle below) is \u00B1 one standard error of the mean - a narrow band means ",
                  "the cohort average is estimated precisely; a wide band means individual mothers vary a lot."
                ),
                checkboxInput(ns("ab_show_ci"), "Show confidence band", value = TRUE),
                plotly::plotlyOutput(ns("ab_evolution_plot"), height = "290px")
              ),
              box(title = "Normalised Metric Heatmap by Cohort", status = "primary", solidHeader = TRUE, width = 6,
                concept_note(
                  tags$strong("What this shows: "),
                  "The five underlying behavioural signals (not the combined score), averaged per cohort ",
                  "at week 24. Darker blue means that signal is, on average, further from baseline for that ",
                  "cohort - reading down a column shows which signals are driving that cohort's outcomes."
                ),
                plotly::plotlyOutput(ns("ab_heatmap_plot"), height = "280px")
              )
            ),

            fluidRow(
              box(title = "Per-Mother Risk Delta vs No-Support Baseline", status = "primary", solidHeader = TRUE, width = 12,
                concept_note(
                  tags$strong("What this shows: "),
                  "Every App-Supported and Standard-Care mother's week-24 risk score, minus the average ",
                  "No-Support score. Bars below zero mean that mother is doing better than the average ",
                  "unsupported mother; bars above zero mean she is doing worse."
                ),
                plotly::plotlyOutput(ns("ab_delta_plot"), height = "260px")
              )
            ),

            fluidRow(
              box(title = "Recommended Sample Size per Cohort", status = "warning", solidHeader = TRUE, width = 12,
                concept_note(
                  tags$strong("What this shows: "),
                  "How many mothers per cohort a real-world trial would need to reliably detect each ",
                  "outcome, using a standard closed-form power calculation (Julious, 2004) rather than a ",
                  "rule of thumb. \"Smaller but still significant\" means picking the smallest effect size ",
                  "that is still clinically meaningful, on the outcome that measures it most efficiently - ",
                  "not simply lowering the statistical bar."
                ),
                fluidRow(
                  column(3, selectInput(ns("ss_effect_preset"), "Assumed effect size (Cohen's d):",
                           choices = c("Small (d = 0.2) - conservative, needs a large sample" = "Small",
                                       "Medium (d = 0.5) - recommended, clinically meaningful" = "Medium",
                                       "Large (d = 0.8) - only for a strong intervention effect" = "Large"),
                           selected = "Medium")),
                  column(3, sliderInput(ns("ss_power"), "Statistical power (1 - \u03B2):",
                           min = 0.7, max = 0.95, value = 0.8, step = 0.05)),
                  column(3, sliderInput(ns("ss_alpha"), "Significance level (\u03B1, two-sided):",
                           min = 0.01, max = 0.10, value = 0.05, step = 0.01)),
                  column(3, br(), uiOutput(ns("ss_recommendation_badge")))
                ),
                tags$table(class = "table table-condensed",
                  tags$thead(tags$tr(
                    tags$th("Outcome measure"), tags$th("Type"), tags$th("Test"),
                    tags$th("Effect assumed"), tags$th("n per group"), tags$th("Total N (3 arms)"),
                    tags$th("Medical / statistical justification")
                  )),
                  tags$tbody(uiOutput(ns("ss_table_rows")))
                ),
                p(style="font-size:11px; color:#a8b6d8; margin-top:8px;",
                  "Formulas: continuous outcomes use the two-independent-means Normal approximation ",
                  "n = 2(z\u03B1 + z\u03B2)\u00B2 / d\u00B2; the binary safety outcome uses the two-proportions approximation ",
                  "(Julious, 2004). Effect-size benchmarks follow Cohen (1988). These are simulated-cohort ",
                  "planning numbers, not a real trial's registered sample size calculation.")
              )
            ),

            reference_panel_ui(c("dennis2013", "bauer2014", "cohen1988", "julious2004"))
          )
        )
      )
    )
  )
}
