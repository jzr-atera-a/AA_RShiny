# modules/DriveSafe/driver_health_monitor/ui.R
# DriveSafe - Driver Health Monitor
# Subtabs: Live Overview | Alertness & Fatigue | Sleep & OSA | Cognitive Performance

driver_health_monitor_ui <- function(id) {
  ns <- NS(id)

  tagList(

    # ── Page Header ──────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        div(class = "book-header",
          fluidRow(
            column(8,
              tags$h2(icon("heartbeat"), " DriveSafe - Driver Health Monitor"),
              tags$p(class = "author",
                "Real-time monitoring of driver alertness, fatigue, cognitive performance ",
                "and sleep-related impairment indicators across your commercial fleet.")
            ),
            column(4,
              br(),
              div(style = "text-align:right;",
                selectInput(ns("selected_driver"), "Select Driver:",
                  choices  = c("All Drivers" = "all",
                               "Driver: Adams, J"  = "D001",
                               "Driver: Patel, R"  = "D002",
                               "Driver: Okafor, C" = "D003",
                               "Driver: Williams, S" = "D004",
                               "Driver: Hassan, M"  = "D005",
                               "Driver: Chen, L"    = "D006",
                               "Driver: Thompson, K" = "D007",
                               "Driver: Singh, P"   = "D008"),
                  width = "100%"
                ),
                actionButton(ns("refresh_all"), "Refresh Dashboard",
                  class = "btn-primary", icon = icon("sync"), style = "margin-top:4px; width:100%;")
              )
            )
          )
        )
      )
    ),

    # ── KPI Summary Row ───────────────────────────────────────────────────────
    fluidRow(
      column(3, valueBoxOutput(ns("kpi_alertness"),    width = 12)),
      column(3, valueBoxOutput(ns("kpi_fatigue"),      width = 12)),
      column(3, valueBoxOutput(ns("kpi_osa_risk"),     width = 12)),
      column(3, valueBoxOutput(ns("kpi_reaction"),     width = 12))
    ),

    # ── Alert Banner ─────────────────────────────────────────────────────────
    fluidRow(
      column(12, uiOutput(ns("alert_banner")))
    ),

    # ── Subtabs ───────────────────────────────────────────────────────────────
    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,

        tabsetPanel(id = ns("health_tabs"),

          # ── SUBTAB 1: LIVE OVERVIEW ────────────────────────────────────────
          tabPanel(
            title = tagList(icon("tachometer-alt"), " Live Overview"),
            br(),

            fluidRow(
              box(title = "Alertness Score Over Journey (KSS - Karolinska Sleepiness Scale)",
                  status = "primary", solidHeader = TRUE, width = 8,
                plotly::plotlyOutput(ns("alertness_timeline"), height = "300px")
              ),
              box(title = "Current Session Risk Summary",
                  status = "warning", solidHeader = TRUE, width = 4,
                br(),
                uiOutput(ns("risk_summary_cards")),
                br(),
                sliderInput(ns("journey_hour"), "Simulate Journey Hour:",
                  min = 0, max = 8, value = 2, step = 0.5,
                  post = "h", width = "100%"),
                helpText("Drag to explore how driver metrics evolve across a shift.")
              )
            ),

            fluidRow(
              box(title = "Multi-Metric Radar: Current Driver State",
                  status = "info", solidHeader = TRUE, width = 6,
                plotly::plotlyOutput(ns("radar_chart"), height = "320px")
              ),
              box(title = "Driving Behaviour Indicators (Speed Variance, Hard Braking, Lane Events)",
                  status = "success", solidHeader = TRUE, width = 6,
                plotly::plotlyOutput(ns("behaviour_chart"), height = "320px")
              )
            )
          ),

          # ── SUBTAB 2: ALERTNESS & FATIGUE ─────────────────────────────────
          tabPanel(
            title = tagList(icon("moon"), " Alertness and Fatigue"),
            br(),

            fluidRow(
              column(4,
                div(class = "status-info",
                  tags$strong(icon("info-circle"), " About these metrics"),
                  tags$p(style = "margin-top:8px; font-size:0.88em;",
                    "Alertness is assessed using passive smartphone telematics combined with ",
                    "brief ecological momentary assessments (EMA). The Karolinska Sleepiness ",
                    "Scale (KSS 1-9) is used as the primary subjective anchor. Fatigue ",
                    "indicators are derived from nonlinear changes in wakefulness and ",
                    "perceived driving performance observed during longer journeys.")
                ),
                br(),
                selectInput(ns("fatigue_metric"), "Display Metric:",
                  choices = c(
                    "KSS Alertness Score (1-9)"       = "kss",
                    "Mind Wandering Index (0-100)"    = "mind_wander",
                    "Perceived Effort Score (0-100)"  = "effort",
                    "Reaction Time Deviation (ms)"    = "reaction"
                  ), width = "100%"),
                br(),
                radioButtons(ns("fatigue_timeframe"), "Time Window:",
                  choices  = c("Last Journey" = "journey",
                               "Last 7 Days"  = "week",
                               "Last 30 Days" = "month"),
                  selected = "journey", inline = TRUE),
                br(),
                div(class = "metric-box",
                  div(class = "metric-label", "Fleet Mean KSS"),
                  div(class = "metric-value", textOutput(ns("fleet_mean_kss"), inline = TRUE))
                ),
                div(class = "metric-box",
                  div(class = "metric-label", "High Fatigue Events"),
                  div(class = "metric-value", textOutput(ns("high_fatigue_count"), inline = TRUE))
                )
              ),
              column(8,
                plotly::plotlyOutput(ns("fatigue_trend"), height = "380px")
              )
            ),

            br(),
            fluidRow(
              box(title = "Fatigue Event Distribution Across Fleet",
                  status = "warning", solidHeader = TRUE, width = 6,
                plotly::plotlyOutput(ns("fatigue_distribution"), height = "280px")
              ),
              box(title = "Time-of-Day Alertness Heatmap",
                  status = "success", solidHeader = TRUE, width = 6,
                plotly::plotlyOutput(ns("alertness_heatmap"), height = "280px")
              )
            )
          ),

          # ── SUBTAB 3: SLEEP & OSA ──────────────────────────────────────────
          tabPanel(
            title = tagList(icon("bed"), " Sleep and OSA"),
            br(),

            fluidRow(
              box(title = "Obstructive Sleep Apnoea (OSA) Risk Indicators",
                  status = "danger", solidHeader = TRUE, width = 12,
                fluidRow(
                  column(3,
                    div(class = "status-warning",
                      tags$strong("OSA Prevalence in HGV Drivers"),
                      tags$p(style = "font-size:0.85em; margin-top:6px;",
                        "Estimated 20-40% of professional HGV drivers have clinically ",
                        "relevant OSA. The DriveSafe framework uses real-world driving ",
                        "behaviour as an objective, passive proxy for functional impairment ",
                        "linked to sleep-related conditions.")
                    ),
                    br(),
                    checkboxGroupInput(ns("osa_indicators"), "Show Indicators:",
                      choices = c(
                        "Excessive Daytime Sleepiness (EDS)" = "eds",
                        "Speed Consistency Index"            = "speed_consistency",
                        "Lateral Position Variance"          = "lateral",
                        "OSA Risk Score (Composite)"         = "osa_composite"
                      ),
                      selected = c("eds", "osa_composite")
                    )
                  ),
                  column(9,
                    plotly::plotlyOutput(ns("osa_indicators_plot"), height = "340px")
                  )
                )
              )
            ),

            fluidRow(
              box(title = "Driver OSA Risk Classification",
                  status = "primary", solidHeader = TRUE, width = 5,
                plotly::plotlyOutput(ns("osa_risk_pie"), height = "280px"),
                helpText("Based on composite behavioural impairment score. ",
                         "Classification does not replace clinical diagnosis.")
              ),
              box(title = "Sleep Quality Score vs Next-Day Driving Performance",
                  status = "info", solidHeader = TRUE, width = 7,
                plotly::plotlyOutput(ns("sleep_vs_performance"), height = "280px")
              )
            )
          ),

          # ── SUBTAB 4: COGNITIVE PERFORMANCE ───────────────────────────────
          tabPanel(
            title = tagList(icon("brain"), " Cognitive Performance"),
            br(),

            fluidRow(
              column(3,
                div(class = "status-info",
                  tags$strong(icon("brain"), " Cognitive Metrics"),
                  tags$p(style = "font-size:0.85em; margin-top:6px;",
                    "Measured via lightweight smartphone-delivered psychomotor ",
                    "vigilance tasks (PVT) and ecological momentary cognitive probes. ",
                    "Metrics reflect attention, working memory load and sustained focus ",
                    "capacity across journey durations.")
                ),
                br(),
                numericInput(ns("pvt_threshold"), "PVT Lapse Threshold (ms):",
                  value = 500, min = 300, max = 1000, step = 50),
                helpText("Lapses are defined as reaction times exceeding this threshold."),
                br(),
                selectInput(ns("cog_driver_filter"), "Filter Driver:",
                  choices = c("All Drivers" = "all",
                              "D001 - Adams, J"    = "D001",
                              "D002 - Patel, R"    = "D002",
                              "D003 - Okafor, C"   = "D003",
                              "D004 - Williams, S" = "D004",
                              "D005 - Hassan, M"   = "D005",
                              "D006 - Chen, L"     = "D006",
                              "D007 - Thompson, K" = "D007",
                              "D008 - Singh, P"    = "D008"),
                  width = "100%"
                ),
                br(),
                div(class = "metric-box",
                  div(class = "metric-label", "Mean Reaction Time"),
                  div(class = "metric-value", textOutput(ns("mean_rt"), inline = TRUE))
                ),
                div(class = "metric-box",
                  div(class = "metric-label", "PVT Lapses (24h)"),
                  div(class = "metric-value", textOutput(ns("pvt_lapses"), inline = TRUE))
                )
              ),
              column(9,
                fluidRow(
                  box(title = "Psychomotor Vigilance Task (PVT) - Reaction Time Distribution",
                      status = "primary", solidHeader = TRUE, width = 12,
                    plotly::plotlyOutput(ns("pvt_distribution"), height = "260px")
                  )
                ),
                fluidRow(
                  box(title = "Cognitive Load vs Journey Duration",
                      status = "success", solidHeader = TRUE, width = 6,
                    plotly::plotlyOutput(ns("cog_load_journey"), height = "240px")
                  ),
                  box(title = "Attention Lapse Events per Driver (Last 30 Days)",
                      status = "warning", solidHeader = TRUE, width = 6,
                    plotly::plotlyOutput(ns("lapse_by_driver"), height = "240px")
                  )
                )
              )
            )
          )

        ) # end tabsetPanel
      )
    ) # end fluidRow
  )
}
