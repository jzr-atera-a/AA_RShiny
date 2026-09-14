# modules/DriveSafe/driver_road_risk/driver_road_risk_map/ui.R
# OSA Road Risk Map
# Interactive UK road-network heatmap of driving risk for drivers with
# obstructive sleep apnoea (OSA). Rendered with plotly::plot_ly(scattermapbox),
# the same proven, dependency-free pattern used by the working
# EnergyPlanningGeoApp reference on this Posit account - no leaflet, no
# raster/terra, no API key.

driver_road_risk_map_ui <- function(id) {
  ns <- NS(id)

  tagList(

    # ── Page Header ───────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        div(class = "book-header",
          fluidRow(
            column(8,
              tags$h2(icon("map-marked-alt"), " OSA Road Risk Heatmap - UK Network"),
              tags$p(class = "author",
                "Simulated driving-risk heatmap across 17 UK road corridors for drivers with ",
                "obstructive sleep apnoea (OSA). Risk combines road type, time-of-day circadian ",
                "dip, journey duration and OSA treatment status \u2014 the same factors driving the ",
                "DriveSafe A/B analysis \u2014 rendered spatially so high-risk corridors and times ",
                "of day are immediately visible.")
            ),
            column(4,
              br(),
              div(style = "text-align:right;",
                actionButton(ns("btn_reset_view"), "Reset Map View",
                  class = "btn-default btn-block", icon = icon("crosshairs"))
              )
            )
          )
        )
      )
    ),

    # ── KPI Row ───────────────────────────────────────────────────────────────
    fluidRow(
      column(3, valueBoxOutput(ns("kpi_pct_high_risk"), width = 12)),
      column(3, valueBoxOutput(ns("kpi_mean_risk"),      width = 12)),
      column(3, valueBoxOutput(ns("kpi_critical_count"), width = 12)),
      column(3, valueBoxOutput(ns("kpi_cpap_benefit"),   width = 12))
    ),

    # ── Filters + Map + Side Panel ───────────────────────────────────────────
    fluidRow(
      box(title = "Map Filters", status = "primary", solidHeader = TRUE, width = 12,
        collapsible = TRUE,
        fluidRow(
          column(3,
            selectInput(ns("f_osa_group"), "Driver Group (heatmap):",
              choices = c("Control (No OSA)"    = "control",
                          "OSA - CPAP Treated"   = "osa_treated",
                          "OSA - Untreated"      = "osa_untreated"),
              selected = "osa_untreated")
          ),
          column(3,
            selectInput(ns("f_time_window"), "Time Window:",
              choices = setNames(TIME_WINDOWS, TIME_WINDOW_LABELS[TIME_WINDOWS]),
              selected = "10-14")
          ),
          column(3,
            checkboxGroupInput(ns("f_road_type"), "Road Types:",
              choices  = setNames(names(ROAD_TYPE_LABELS), ROAD_TYPE_LABELS),
              selected = names(ROAD_TYPE_LABELS), inline = TRUE)
          ),
          column(3,
            sliderInput(ns("f_duration"), "Journey Duration (hrs):",
              min = 0.5, max = 8, value = 2, step = 0.5)
          )
        ),
        fluidRow(
          column(3,
            sliderInput(ns("f_heat_radius"), "Heatmap Point Radius:",
              min = 10, max = 45, value = 24, step = 1)
          ),
          column(3,
            sliderInput(ns("f_heat_opacity"), "Heatmap Opacity (%):",
              min = 10, max = 80, value = 35, step = 5)
          ),
          column(3,
            checkboxGroupInput(ns("f_layers"), "Show Layers:",
              choices = c("Risk Heatmap" = "heatmap",
                          "Corridor Markers" = "corridors",
                          "Near-Miss Incidents" = "incidents",
                          "Rest Areas / Sleep Clinics" = "services"),
              selected = c("heatmap","corridors","incidents","services"), inline = TRUE)
          ),
          column(3,
            div(style = "padding-top:22px;",
              helpText("Tap a corridor marker for a detailed risk breakdown.")
            )
          )
        )
      )
    ),

    fluidRow(
      box(title = "UK Road Risk Heatmap", status = "danger", solidHeader = TRUE, width = 8,
        plotly::plotlyOutput(ns("risk_map"), height = "560px")
      ),
      box(title = "Corridor Detail", status = "info", solidHeader = TRUE, width = 4,
        uiOutput(ns("corridor_detail_header")),
        plotly::plotlyOutput(ns("corridor_group_bar"), height = "200px"),
        plotly::plotlyOutput(ns("corridor_risk_donut"), height = "200px")
      )
    ),

    # ── Supporting Charts ────────────────────────────────────────────────────
    fluidRow(
      box(title = "Risk by Time of Day", status = "warning", solidHeader = TRUE, width = 6,
        plotly::plotlyOutput(ns("time_of_day_chart"), height = "300px"),
        helpText("Peaks in the early-morning and evening windows reflect the circadian alertness dip that is more pronounced in untreated OSA.")
      ),
      box(title = "Risk by Road Type", status = "success", solidHeader = TRUE, width = 6,
        plotly::plotlyOutput(ns("road_type_chart"), height = "300px"),
        helpText("Compares mean risk score across the three driver groups for each road type, at the current filter settings.")
      )
    )
  )
}
