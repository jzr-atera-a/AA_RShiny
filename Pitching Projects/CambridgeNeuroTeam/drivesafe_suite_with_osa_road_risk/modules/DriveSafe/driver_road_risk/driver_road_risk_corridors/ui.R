# modules/DriveSafe/driver_road_risk/driver_road_risk_corridors/ui.R
# High-Risk Corridors
# Ranks the 17 simulated UK corridors by OSA driver risk and quantifies the
# CPAP treatment effect by road type and time of day.

driver_road_risk_corridors_ui <- function(id) {
  ns <- NS(id)

  tagList(

    fluidRow(
      column(12,
        div(class = "book-header",
          tags$h2(icon("ranking-star"), " High-Risk Corridors - OSA Driver Analysis"),
          tags$p(class = "author",
            "Ranks the 17 simulated UK road corridors by driving risk for OSA drivers, and ",
            "quantifies how much of that risk is recovered once CPAP treatment is established. ",
            "Use this view to prioritise which corridors most need route-optimisation or ",
            "scheduling interventions for untreated / newly-diagnosed drivers.")
        )
      )
    ),

    fluidRow(
      box(title = "Filters", status = "primary", solidHeader = TRUE, width = 12,
          collapsible = TRUE,
        fluidRow(
          column(4,
            checkboxGroupInput(ns("c_groups"), "Show Groups:",
              choices  = c("Control (No OSA)"    = "control",
                           "OSA - CPAP Treated"   = "osa_treated",
                           "OSA - Untreated"      = "osa_untreated"),
              selected = c("control","osa_treated","osa_untreated"), inline = TRUE)
          ),
          column(4,
            sliderInput(ns("c_duration"), "Representative Journey Duration (hrs):",
              min = 0.5, max = 8, value = 4, step = 0.5)
          ),
          column(4,
            selectInput(ns("c_heatmap_group"), "Time-of-Day Heatmap Group:",
              choices = c("Control (No OSA)"    = "control",
                          "OSA - CPAP Treated"   = "osa_treated",
                          "OSA - Untreated"      = "osa_untreated"),
              selected = "osa_untreated")
          )
        )
      )
    ),

    fluidRow(
      box(title = "Top 10 Highest-Risk Corridors", status = "danger", solidHeader = TRUE, width = 6,
        plotly::plotlyOutput(ns("top10_chart"), height = "420px")
      ),
      box(title = "CPAP Treatment Effect by Road Type", status = "success", solidHeader = TRUE, width = 6,
        plotly::plotlyOutput(ns("lollipop_chart"), height = "420px"),
        helpText("Red dot = untreated OSA risk. Green dot = CPAP-treated risk. Line length = risk recovered through treatment.")
      )
    ),

    fluidRow(
      box(title = "Corridor \u00d7 Time-of-Day Risk Heatmap", status = "warning", solidHeader = TRUE, width = 12,
        plotly::plotlyOutput(ns("corridor_time_heatmap"), height = "480px"),
        helpText("Selected group's risk score across all 17 corridors and 5 time windows. Darker red = higher risk.")
      )
    ),

    fluidRow(
      box(title = "Risk Profile by Journey Duration", status = "info", solidHeader = TRUE, width = 6,
        plotly::plotlyOutput(ns("duration_profile_chart"), height = "340px"),
        helpText("Short (<2h) / Medium (2-4h) / Long (>4h) journeys \u2014 fatigue accumulates faster in untreated OSA drivers.")
      ),
      box(title = "Full Corridor Risk Table", status = "primary", solidHeader = TRUE, width = 6,
        DT::dataTableOutput(ns("corridor_table")),
        br(),
        downloadButton(ns("dl_corridor_csv"), "Download CSV", class = "btn-primary")
      )
    )
  )
}
