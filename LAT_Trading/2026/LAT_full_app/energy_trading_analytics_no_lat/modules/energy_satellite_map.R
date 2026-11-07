# modules/energy_satellite_map.R
#
# "External Sources -> Satellite Data" - a map simulating nighttime-light-
# style energy-demand patterns for oil & gas activity and electricity
# generation/demand across major US and Canadian energy hubs.
#
# MAP LIBRARY CHOICE (deliberate, matches a proven working pattern):
# Uses ONLY plotly::plot_ly(type = "scattermapbox") - no {leaflet}, no
# {sf}, no {raster}, and critically NO {terra} anywhere in the dependency
# tree. This mirrors the exact approach used successfully elsewhere
# (plotly scattermapbox for point/marker energy-infrastructure maps),
# adopted specifically because {leaflet} transitively pulls in
# {raster} -> {terra}, and that chain is what breaks `renv::snapshot()` /
# deployment on shinyapps.io. plotly is already a dependency of this app
# (used throughout for charts), so this adds ZERO new packages.
#
# DATA: the map below uses SIMULATED intensity values at real energy-hub
# locations (Houston, Fort McMurray, Cushing, etc.) with a seasonal pattern
# (heating-season / cooling-season swings), clearly labelled as simulated -
# consistent with this app's existing convention (e.g. the Step-by-Step
# Practice charts, Commodities for Mobility's event-reaction charts) of
# simulated-but-realistically-shaped data. A real implementation would
# replace this with actual pulls from the three sources cited in the
# "Data Sources" panel below.

# ══════════════════════════════════════════════════════════════════════════
# LOCATIONS — real energy hubs, US + Canada, oil/gas and electricity-demand
# ══════════════════════════════════════════════════════════════════════════

esm_locations <- data.frame(
  name        = c("Houston, TX", "Midland, TX (Permian Basin)", "Cushing, OK (Oil Storage Hub)",
                   "Henry Hub, LA (Nat Gas Pricing Hub)", "Williston, ND (Bakken)", "Prudhoe Bay, AK",
                   "New York City, NY", "Chicago, IL", "Los Angeles, CA",
                   "Fort McMurray, AB (Oil Sands)", "Calgary, AB", "Edmonton, AB",
                   "Toronto, ON", "Montreal, QC", "Vancouver, BC"),
  country     = c("US","US","US","US","US","US","US","US","US",
                   "Canada","Canada","Canada","Canada","Canada","Canada"),
  category    = c("Oil & Gas","Oil & Gas","Oil & Gas","Oil & Gas","Oil & Gas","Oil & Gas",
                   "Electricity Demand","Electricity Demand","Electricity Demand",
                   "Oil & Gas","Oil & Gas","Oil & Gas",
                   "Electricity Demand","Electricity Demand","Electricity Demand"),
  lat         = c(29.76, 31.99, 35.98, 30.35, 48.15, 70.25,
                   40.71, 41.88, 34.05,
                   56.73, 51.05, 53.55,
                   43.65, 45.50, 49.28),
  lng         = c(-95.37, -102.08, -96.77, -92.75, -103.62, -148.32,
                   -74.01, -87.63, -118.24,
                   -111.38, -114.07, -113.49,
                   -79.38, -73.57, -123.12),
  base_index  = c(88, 82, 79, 74, 70, 65,
                   72, 68, 66,
                   85, 76, 71,
                   70, 62, 58),
  stringsAsFactors = FALSE
)

# ══════════════════════════════════════════════════════════════════════════
# SIMULATED SEASONAL PATTERN
# ══════════════════════════════════════════════════════════════════════════

# Electricity demand: winter heating bump in Canada/northern US, summer
# cooling bump in southern US - a simple, illustrative seasonal curve, not a
# claim to reproduce a specific real dataset.
esm_seasonal_multiplier <- function(category, lat, month) {
  angle <- (month - 1) / 12 * 2 * pi
  winter_bump <- cos(angle) # peaks in Jan (month=1), trough in Jul
  summer_bump <- -cos(angle) # peaks in Jul

  ifelse(category == "Electricity Demand",
    ifelse(lat >= 45,
      1 + 0.30 * winter_bump,                      # northern: winter heating dominates
      1 + 0.18 * summer_bump + 0.08 * winter_bump), # southern: summer cooling dominates, mild winter bump
    1 + 0.10 * winter_bump                          # Oil & Gas: mild winter production/heating-demand bump
  )
}

esm_simulate <- function(month, seed = 42) {
  set.seed(seed + month)
  d <- esm_locations
  mult <- esm_seasonal_multiplier(d$category, d$lat, month)
  noise <- rnorm(nrow(d), mean = 1, sd = 0.06)
  d$intensity <- pmin(100, pmax(5, round(d$base_index * mult * noise, 1)))
  d
}

# ══════════════════════════════════════════════════════════════════════════
# UI HELPER — plain citation-card style (no "Task N / marks" framing, since
# this is a data-sources reference panel, not an assignment task)
# ══════════════════════════════════════════════════════════════════════════

esm_source_card <- function(title, ...) {
  tags$div(class = "ua-task",
    style = "background: #ffffff; border: 1px solid #e2e8f0; border-left: 5px solid #008A82; border-radius: 10px; padding: 16px 20px; margin-bottom: 18px; box-shadow: 0 1px 4px rgba(0,44,60,0.06);",
    tags$div(class = "ua-task-head",
      style = "margin-bottom: 10px; padding-bottom: 8px; border-bottom: 1px solid #e2e8f0;",
      tags$div(class = "ua-task-title", style = "font-size: 16px; font-weight: 800; color: #002C3C;", title)
    ),
    tags$div(class = "ua-task-body", style = "font-size: 13.5px; line-height: 1.75; color: #2c3e50;", ...)
  )
}

# ══════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════

energy_satellite_map_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ua_intro("External Sources", "Satellite Data \u2014 Energy Demand Patterns", "\u2014", "\u2014",
             "A simulated nighttime-light-style intensity map for oil & gas activity and electricity demand across major US and Canadian energy hubs, with real external data sources identified for a production version."),

    fluidRow(
      box(title = "Controls", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, checkboxGroupInput(ns("layers"), "Show:",
                     choices = c("Oil & Gas" = "Oil & Gas", "Electricity Demand" = "Electricity Demand"),
                     selected = c("Oil & Gas", "Electricity Demand"))),
            column(3, selectInput(ns("country"), "Country:", choices = c("Both", "US", "Canada"))),
            column(4, sliderInput(ns("month"), "Month (simulated seasonal pattern):",
                     min = 1, max = 12, value = 1, step = 1,
                     animate = animationOptions(interval = 900, loop = TRUE))),
            column(2, style = "padding-top:25px;",
                   actionButton(ns("resetView"), "Reset Map View", icon = icon("compress"), width = "100%"))
          )
      )
    ),

    fluidRow(
      box(title = "Simulated Energy Demand Intensity Map", status = "success", solidHeader = TRUE, width = 12,
          withSpinner(plotly::plotlyOutput(ns("energyMap"), height = "560px"))
      )
    ),

    tags$h3("Data Sources for a Production Version", style = "margin-top:24px; margin-bottom:14px;"),

    ua_callout("The map above uses simulated intensity values at real energy-hub locations \u2014 it does not pull live satellite or government data. The sources below are real and could replace the simulation."),

    esm_source_card("NASA Black Marble (VIIRS Nighttime Lights)",
      tags$p("A genuine satellite-derived nighttime-lights product (VIIRS Day/Night Band, on the Suomi NPP / NOAA-20 / NOAA-21 satellites), widely used in published research as a proxy for electricity demand, economic activity, and power-outage detection."),
      ua_ref("<b>NASA Black Marble</b> \u2014 project home and data access.", "https://blackmarble.gsfc.nasa.gov/"),
      ua_ref("<b>NASA Earthdata</b> \u2014 Black Marble dataset overview and access via Earthdata Search.", "https://www.earthdata.nasa.gov/data/projects/black-marble")
    ),

    esm_source_card("US Energy Information Administration (EIA)",
      tags$p("A free, registered-key API covering US electricity generation by state and fuel source, natural gas production/prices, and petroleum data \u2014 the natural source for the actual (non-satellite) US side of this map."),
      ua_ref("<b>EIA Open Data</b> \u2014 API documentation and registration.", "https://www.eia.gov/opendata/"),
      ua_ref("<b>EIA Electricity Data Browser</b> \u2014 generation by state/fuel, interactive and via API.", "https://www.eia.gov/electricity/data/browser/")
    ),

    esm_source_card("Canada Energy Regulator (CER) / Statistics Canada",
      tags$p("Canada's federal energy regulator publishes open electricity generation/capacity data by province, sourced in part from Statistics Canada's energy tables \u2014 the Canadian-side equivalent of the EIA data above."),
      ua_ref("<b>Canada Energy Regulator</b> \u2014 open data on electricity generation and capacity by province.", "https://www.cer-rec.gc.ca/en/data-analysis/energy-markets/"),
      ua_ref("<b>Statistics Canada</b> \u2014 Electric power generation, by class of producer (Table 25-10-0015-01).", "https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=2510001501")
    )
  )
}

# ══════════════════════════════════════════════════════════════════════════
# SERVER
# ══════════════════════════════════════════════════════════════════════════

energy_satellite_map_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    filtered_data <- reactive({
      d <- esm_simulate(input$month %||% 1)
      if (!is.null(input$layers)) d <- d[d$category %in% input$layers, , drop = FALSE]
      if (!is.null(input$country) && input$country != "Both") d <- d[d$country == input$country, , drop = FALSE]
      d
    })

    output$energyMap <- plotly::renderPlotly({
      d <- filtered_data()
      p <- plotly::plot_ly(source = "energy_map_plot")

      if (nrow(d) > 0) {
        d$hover_detail <- paste0(
          "<b>", d$name, "</b><br>",
          "Category: ", d$category, "<br>",
          "Simulated intensity: ", d$intensity, " / 100<br>",
          "<i>Simulated value \u2014 not live satellite/government data</i>"
        )
        p <- plotly::add_trace(p,
          data = d, type = "scattermapbox", lon = ~lng, lat = ~lat,
          mode = "markers", name = "Energy Hubs",
          marker = list(
            size = 8 + (d$intensity / 100) * 30,
            color = ~intensity,
            colorscale = list(list(0, "#1a3a6b"), list(0.4, "#008A82"), list(0.7, "#e67e22"), list(1, "#e74c3c")),
            cmin = 0, cmax = 100, opacity = 0.85,
            colorbar = list(title = "Intensity", titleside = "right", x = 1.02)
          ),
          text = ~hover_detail,
          hovertemplate = "%{text}<extra></extra>"
        )
      }

      p |> plotly::layout(
        mapbox = list(style = "open-street-map", center = list(lon = -100, lat = 45), zoom = 2.6),
        showlegend = FALSE,
        margin = list(l = 0, r = 0, t = 0, b = 0)
      ) |>
        plotly::config(displaylogo = FALSE)
    })

    observeEvent(input$resetView, {
      plotly::plotlyProxy("energyMap", session) |>
        plotly::plotlyProxyInvoke("relayout", list(
          "mapbox.center" = list(lon = -100, lat = 45),
          "mapbox.zoom"   = 2.6
        ))
    })
  })
}
