# modules/DriveSafe/driver_road_risk/driver_road_risk_interventions/ui.R
# Risk Interventions
# Scenario builder: treatment status, rest-break policy, route optimisation and
# clinical monitoring, with before/after gauges, a contribution waterfall,
# a per-driver CPAP adherence trajectory and a fleet-level risk projection.

driver_road_risk_interventions_ui <- function(id) {
  ns <- NS(id)

  tagList(

    fluidRow(
      column(12,
        div(class = "book-header",
          tags$h2(icon("hand-holding-medical"), " Risk Interventions - OSA Scenario Builder"),
          tags$p(class = "author",
            "Model the effect of CPAP treatment, rest-break policy, route optimisation and ",
            "clinical monitoring on driving risk for an OSA driver, then project the combined ",
            "impact across the fleet as CPAP uptake increases.")
        )
      )
    ),

    fluidRow(
      # Scenario builder panel
      box(title = "Scenario Builder", status = "primary", solidHeader = TRUE, width = 4,
        tags$h5(icon("user-doctor"), " Treatment Status"),
        radioButtons(ns("sc_treatment"), NULL,
          choices = c("None (Untreated OSA)"             = "none",
                      "CPAP - Newly Started (<3 months)"  = "cpap_new",
                      "CPAP - Established (>3 months)"    = "cpap_established",
                      "Mandibular Advancement Device"     = "mandibular"),
          selected = "none"),
        hr(),

        tags$h5(icon("mug-hot"), " Rest Break Policy"),
        sliderInput(ns("sc_break_freq"), "Breaks per 4h driving:",
          min = 0, max = 4, value = 1, step = 1),
        sliderInput(ns("sc_break_dur"), "Break duration (minutes):",
          min = 5, max = 30, value = 15, step = 5),
        hr(),

        tags$h5(icon("route"), " Route Optimisation"),
        checkboxInput(ns("sc_avoid_night"), "Avoid night driving (00:00-06:00 / 18:00-24:00)", value = FALSE),
        checkboxInput(ns("sc_cap_journey"), "Cap journey at 4 hours", value = FALSE),
        checkboxInput(ns("sc_prefer_motorway"), "Prefer motorways over A/B-roads", value = FALSE),
        hr(),

        tags$h5(icon("stethoscope"), " Clinical Monitoring"),
        checkboxInput(ns("sc_monthly_review"), "Monthly clinical review", value = FALSE),
        checkboxInput(ns("sc_telemetry"), "CPAP adherence telemetry", value = FALSE)
      ),

      column(8,
        fluidRow(
          box(title = "Baseline Risk (Untreated OSA, No Interventions)",
              status = "danger", solidHeader = TRUE, width = 6,
            plotly::plotlyOutput(ns("gauge_baseline"), height = "260px")
          ),
          box(title = "Scenario Risk (With Selected Interventions)",
              status = "success", solidHeader = TRUE, width = 6,
            plotly::plotlyOutput(ns("gauge_scenario"), height = "260px")
          )
        ),
        fluidRow(
          box(title = "Risk Reduction Waterfall", status = "info", solidHeader = TRUE, width = 12,
            plotly::plotlyOutput(ns("waterfall_chart"), height = "320px"),
            helpText("Shows how much each intervention category contributes to the total risk reduction from baseline to scenario.")
          )
        )
      )
    ),

    fluidRow(
      box(title = "CPAP Adherence Trajectory - Per-Driver Risk Convergence",
          status = "success", solidHeader = TRUE, width = 12,
        fluidRow(
          column(4,
            sliderInput(ns("traj_week"), "Week:", min = 1, max = 52, value = 12, step = 1,
              animate = animationOptions(interval = 300, loop = FALSE))
          ),
          column(8,
            uiOutput(ns("traj_week_note"))
          )
        ),
        plotly::plotlyOutput(ns("adherence_trajectory"), height = "360px"),
        helpText("Simulated weekly risk score for four OSA drivers over 52 weeks of CPAP therapy, converging toward the control-group baseline (dashed line) at different adherence-driven rates.")
      )
    ),

    fluidRow(
      box(title = "Action Plan by Driver Risk Tier", status = "warning", solidHeader = TRUE, width = 12,
        uiOutput(ns("action_plan_cards"))
      )
    ),

    fluidRow(
      box(title = "Fleet-Level Risk Projection", status = "primary", solidHeader = TRUE, width = 12,
        fluidRow(
          column(4, sliderInput(ns("fleet_size"), "Fleet Size (drivers):",
            min = 10, max = 500, value = 150, step = 10)),
          column(4, sliderInput(ns("fleet_prevalence"), "OSA Prevalence (%):",
            min = 5, max = 30, value = 15, step = 1)),
          column(4, sliderInput(ns("fleet_uptake"), "CPAP Uptake Among OSA Drivers (%):",
            min = 0, max = 100, value = 60, step = 5))
        ),
        fluidRow(
          column(4, valueBoxOutput(ns("fleet_osa_drivers"), width = 12)),
          column(4, valueBoxOutput(ns("fleet_risk_reduction"), width = 12)),
          column(4, valueBoxOutput(ns("fleet_journeys_saved"), width = 12))
        ),
        plotly::plotlyOutput(ns("fleet_projection_chart"), height = "320px")
      )
    )
  )
}
