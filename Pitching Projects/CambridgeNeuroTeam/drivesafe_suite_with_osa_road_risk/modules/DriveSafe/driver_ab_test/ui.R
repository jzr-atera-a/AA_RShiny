# modules/DriveSafe/driver_ab_test/ui.R
# DriveSafe - A/B Test: OSA Treated vs Untreated
# Compares drivers receiving CPAP treatment vs untreated OSA drivers
# across alertness, fatigue, cognitive and driving behaviour metrics

driver_ab_test_ui <- function(id) {
  ns <- NS(id)

  tagList(

    # ── Page Header ───────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        div(class = "book-header",
          fluidRow(
            column(8,
              tags$h2(icon("flask"), " DriveSafe - A/B Test: OSA Treatment Effect"),
              tags$p(class = "author",
                "Comparing driver performance and safety metrics between OSA-treated ",
                "(CPAP), OSA-untreated, and control populations. ",
                "Measuring improvement from medical intervention across key DriveSafe indicators.")
            ),
            column(4,
              br(),
              div(style = "text-align:right;",
                checkboxGroupInput(ns("ab_groups"), "Show Groups:",
                  choices  = c("Control (No OSA)"         = "control",
                               "OSA - CPAP Treated"        = "osa_treated",
                               "OSA - Untreated"           = "osa_untreated"),
                  selected = c("control","osa_treated","osa_untreated"),
                  inline   = FALSE
                ),
                actionButton(ns("btn_resim"), "Re-simulate Data",
                  class = "btn-primary btn-block", icon = icon("random"),
                  style = "margin-top:8px;")
              )
            )
          )
        )
      )
    ),

    # ── Hypothesis Panel ─────────────────────────────────────────────────────
    fluidRow(
      column(12,
        div(class = "status-info",
          fluidRow(
            column(1, tags$h3(icon("microscope"), style = "text-align:center; margin-top:4px;")),
            column(11,
              tags$strong("Study Hypothesis:"),
              tags$p(style = "margin:4px 0 0 0; font-size:0.92em;",
                "Drivers with untreated obstructive sleep apnoea (OSA) show significantly ",
                "worse alertness (higher KSS), longer reaction times, higher mind-wandering scores, ",
                "and more driving behaviour anomalies compared to both healthy controls and ",
                "OSA drivers who have received CPAP treatment. ",
                "CPAP-treated drivers are expected to converge towards control-group performance ",
                "levels, demonstrating the functional driving safety benefit of the medical intervention.")
            )
          )
        )
      )
    ),
    br(),

    # ── Effect Size Summary Cards ─────────────────────────────────────────────
    fluidRow(
      column(3, valueBoxOutput(ns("ab_kss_delta"),      width = 12)),
      column(3, valueBoxOutput(ns("ab_rt_delta"),       width = 12)),
      column(3, valueBoxOutput(ns("ab_osa_delta"),      width = 12)),
      column(3, valueBoxOutput(ns("ab_lapse_delta"),    width = 12))
    ),

    # ── Main A/B Charts ───────────────────────────────────────────────────────
    fluidRow(
      box(title = "KSS Alertness Score Distribution by Group",
          status = "primary", solidHeader = TRUE, width = 6,
        plotly::plotlyOutput(ns("ab_kss_violin"), height = "320px"),
        helpText("Lower KSS = more alert. Target: treated group approaching control-group levels.")
      ),
      box(title = "Reaction Time Distribution by Group (ms)",
          status = "danger", solidHeader = TRUE, width = 6,
        plotly::plotlyOutput(ns("ab_rt_violin"), height = "320px"),
        helpText("Faster reaction times indicate reduced fatigue-related impairment.")
      )
    ),

    fluidRow(
      box(title = "OSA Composite Risk Score - Group Comparison",
          status = "warning", solidHeader = TRUE, width = 6,
        plotly::plotlyOutput(ns("ab_osa_box"), height = "320px"),
        helpText("Composite score integrating KSS, reaction time and driving behaviour variance.")
      ),
      box(title = "Mind Wandering Index - Group Comparison",
          status = "info", solidHeader = TRUE, width = 6,
        plotly::plotlyOutput(ns("ab_mw_box"), height = "320px"),
        helpText("Mind wandering is a sensitive marker of attentional impairment during longer journeys.")
      )
    ),

    # ── Journey-level progression ─────────────────────────────────────────────
    fluidRow(
      box(title = "Metric Evolution Across Journey Duration - Group Comparison",
          status = "success", solidHeader = TRUE, width = 12,

        fluidRow(
          column(4,
            selectInput(ns("ab_journey_metric"), "Select Metric:",
              choices = c(
                "KSS Alertness Score"          = "kss",
                "Reaction Time (ms)"           = "reaction_time",
                "Mind Wandering Index"         = "mind_wander",
                "OSA Composite Risk"           = "osa_composite",
                "Speed Variance"               = "speed_variance",
                "Hard Braking Events"          = "hard_braking",
                "PVT Lapse Count"              = "pvt_lapses"
              ), width = "100%"
            )
          ),
          column(4,
            sliderInput(ns("ab_smooth"), "Smoothing Window (hrs):",
              min = 0.5, max = 3, value = 1, step = 0.5)
          ),
          column(4,
            checkboxInput(ns("ab_show_ci"), "Show Confidence Interval", value = TRUE)
          )
        ),
        plotly::plotlyOutput(ns("ab_journey_plot"), height = "380px")
      )
    ),

    # ── Metric Summary Table ──────────────────────────────────────────────────
    fluidRow(
      box(title = "Summary Statistics by Group and Metric",
          status = "primary", solidHeader = TRUE, width = 12,

        fluidRow(
          column(4,
            selectInput(ns("ab_summary_metric"), "Metric:",
              choices = c(
                "KSS Alertness Score"   = "kss_score",
                "Reaction Time (ms)"    = "reaction_time_ms",
                "Mind Wandering Index"  = "mind_wander_idx",
                "OSA Composite Score"   = "osa_risk_score",
                "Speed Variance"        = "speed_variance",
                "PVT Lapses"            = "pvt_lapses_n",
                "Sleep Quality Score"   = "sleep_quality"
              ), width = "100%"
            )
          ),
          column(8, htmlOutput(ns("effect_size_note")))
        ),
        br(),
        DT::dataTableOutput(ns("ab_summary_table"))
      )
    ),

    # ── Multi-metric heatmap ──────────────────────────────────────────────────
    fluidRow(
      box(title = "Multi-Metric Performance Heatmap by Group and Driver",
          status = "info", solidHeader = TRUE, width = 12,
        plotly::plotlyOutput(ns("ab_heatmap"), height = "340px"),
        helpText("Normalised scores (0-100): green = better performance, red = worse.")
      )
    ),

    # ── Per-driver delta table ────────────────────────────────────────────────
    fluidRow(
      box(title = "Per-Driver Performance Delta: Treated vs Untreated OSA Benchmark",
          status = "warning", solidHeader = TRUE, width = 12,
        plotly::plotlyOutput(ns("ab_driver_delta"), height = "300px"),
        helpText("Positive delta = better than untreated OSA baseline. ",
                 "Control drivers shown as reference.")
      )
    )

  )
}
