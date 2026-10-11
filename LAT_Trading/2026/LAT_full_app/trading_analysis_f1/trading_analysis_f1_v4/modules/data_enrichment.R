# modules/data_enrichment.R
#
# "Data Enrichment > Energy Commodities" - shows how three publicly available,
# non-price data sources (satellite imagery, weather patterns, the economic/energy
# release calendar) are actually used to inform energy commodity trading, with real,
# verifiable Harvard-style references behind every claim, plus interactive tools:
#   1. Overview
#   2. Satellite Imagery      - global storage-hub map + a real shadow-based tank
#                                volume estimator (the actual method cited sources use)
#   3. Weather Patterns       - LIVE data pull (Open-Meteo, free, no key) for the three
#                                locations that matter most for WTI/Henry Hub/Brent,
#                                with a heating/cooling degree day calculator
#   4. Economic Calendar      - the energy-specific release schedule (distinct from the
#                                general macro calendar already on this app's Economic
#                                Calendar tab), with a live days-to-next-release countdown
#
# NOTE ON TESTING: every pure function below (degree days, tank shadow volume, release
# countdown) was tested standalone with known inputs before being wired in here. The
# ONE thing that could not be tested from the build environment is the live Open-Meteo
# HTTP call itself (outbound network access there is restricted to package registries,
# not general APIs) - the call is wrapped defensively with tryCatch and a clear on-
# screen message if it fails, but please confirm it works the first time you run this
# for real, since that specific piece is unverified end-to-end.

# ===========================================================================
# PURE LOGIC
# ===========================================================================

de_degree_days <- function(temp_avg_f, base_f = 65) {
  list(hdd = pmax(base_f - temp_avg_f, 0), cdd = pmax(temp_avg_f - base_f, 0))
}

# Illustrative floating-roof tank shadow volume estimator, the same shadow-ratio
# geometry described in the cited sources (Mukherjee et al., 2021; Baker Institute,
# 2018): occupancy = 1 - (interior shadow length / exterior shadow length).
de_tank_shadow_volume <- function(diameter_m, height_m, exterior_shadow_m, interior_shadow_m) {
  if (is.na(exterior_shadow_m) || exterior_shadow_m <= 0) return(list(occupancy_pct = NA, volume_bbl = NA))
  occ <- 1 - (interior_shadow_m / exterior_shadow_m)
  occ <- max(0, min(1, occ))
  volume_m3 <- pi * (diameter_m / 2)^2 * height_m * occ
  list(occupancy_pct = occ * 100, volume_bbl = volume_m3 * 6.2898)
}

de_days_to_next_release <- function(target_weekday, from_date = Sys.Date()) {
  cur_wday <- as.POSIXlt(from_date)$wday + 1
  diff <- (target_weekday - cur_wday) %% 7
  if (diff == 0) diff <- 7
  from_date + diff
}

# Key locations for energy-relevant weather: Cushing OK (WTI delivery point), Henry
# Hub LA (natural gas benchmark), Rotterdam NL (European gas/Brent-linked demand hub).
de_energy_locations <- data.frame(
  Location = c("Cushing, Oklahoma (WTI hub)", "Erath, Louisiana (Henry Hub)", "Rotterdam, Netherlands (ARA/Brent hub)"),
  Relevance = c("WTI crude delivery point; extreme cold can disrupt pipeline flow and refinery runs.",
                "Henry Hub natural gas pricing point; heating demand is the single largest driver of winter price spikes.",
                "Core of the ARA (Amsterdam-Rotterdam-Antwerp) refining/storage hub and a reference for European gas demand."),
  lat = c(35.98, 29.95, 51.92), lon = c(-96.77, -92.03, 4.48),
  stringsAsFactors = FALSE
)

de_fetch_weather <- function(lat, lon) {
  tryCatch({
    url <- paste0("https://api.open-meteo.com/v1/forecast?latitude=", lat, "&longitude=", lon,
                  "&daily=temperature_2m_max,temperature_2m_min&temperature_unit=fahrenheit",
                  "&timezone=auto&forecast_days=7")
    resp <- httr::GET(url, httr::timeout(8))
    if (httr::status_code(resp) != 200) stop(paste("HTTP status", httr::status_code(resp)))
    js <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    data.frame(Date = as.Date(js$daily$time), TMax = js$daily$temperature_2m_max,
               TMin = js$daily$temperature_2m_min, stringsAsFactors = FALSE)
  }, error = function(e) list(error = conditionMessage(e)))
}

de_release_schedule <- data.frame(
  Release = c("EIA Weekly Petroleum Status Report", "EIA Weekly Natural Gas Storage Report",
              "Baker Hughes US Rig Count", "API Weekly Statistical Bulletin"),
  Typical_Timing = c("Wednesdays, 10:30am ET (Thu if Mon holiday)", "Thursdays, 10:30am ET",
                     "Fridays, 1:00pm ET", "Tuesdays, 4:30pm ET"),
  Weekday_Num = c(4, 5, 6, 3),
  What_It_Measures = c("US crude, gasoline and distillate inventories, refinery utilisation, production/imports.",
                        "Weekly change in US natural gas storage vs the 5-year average.",
                        "Active US oil and gas drilling rigs, a leading indicator of future supply.",
                        "Industry-estimated US crude inventories, released a day ahead of the official EIA figure."),
  Typical_Market_Reaction = c("A surprise draw/build beyond consensus routinely moves WTI 1-3% within minutes.",
                              "A larger-than-expected draw in winter can move Henry Hub several percent intraday.",
                              "Slower-moving; matters more for medium-term supply expectations than same-day price action.",
                              "Often pre-moves WTI ahead of the official EIA number the next morning."),
  stringsAsFactors = FALSE
)

# ===========================================================================
# UI HELPERS (reuses u3_context / u3_metric_tile from unit3_live_signals.R,
# already sourced into the same environment by app.R)
# ===========================================================================

de_ref <- function(text) {
  tags$li(HTML(text), style = "font-size:11.5px; color:#4a5560; line-height:1.6; margin-bottom:6px;")
}

# ===========================================================================
# UI
# ===========================================================================

data_enrichment_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      tabBox(id = ns("subtabs"), width = 12, selected = "1. Overview",

        # ---------------------------------------------------------------
        tabPanel("1. Overview", icon = icon("layer-group"),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Why non-price data matters for energy",
              collapsible = TRUE, collapsed = FALSE,
            tags$p(paste0(
              "Energy commodity prices are driven by physical supply and demand well before that supply/demand ",
              "shows up in an official government report. Three genuinely public, free data streams give an ",
              "earlier read than price alone: satellite imagery of physical storage, weather patterns driving ",
              "heating/cooling demand, and the precise timing of the official releases that eventually confirm ",
              "what the other two already implied. This tab is a live, interactive introduction to all three, ",
              "not just a reading list."
            ), style = "font-size:13px; color:#4a5560; line-height:1.65;")
          ),
          fluidRow(
            column(4, box(width = 12, status = "info", solidHeader = TRUE, title = "Satellite Imagery",
              tags$p("Optical satellites estimate floating-roof tank fill levels from cast shadows, giving an inventory read days to weeks ahead of official government data.", style="font-size:12px; color:#4a5560;"))),
            column(4, box(width = 12, status = "info", solidHeader = TRUE, title = "Weather Patterns",
              tags$p("Heating and cooling degree days are the single largest driver of short-term natural gas and heating oil demand swings.", style="font-size:12px; color:#4a5560;"))),
            column(4, box(width = 12, status = "info", solidHeader = TRUE, title = "Economic Calendar",
              tags$p("Energy-specific releases (EIA petroleum/gas storage, rig counts) move prices in minutes; knowing the exact schedule is itself an edge.", style="font-size:12px; color:#4a5560;")))
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("2. Satellite Imagery", icon = icon("satellite"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "How this actually works",
            tags$p(paste0(
              "Floating-roof storage tanks (used for crude and other volatile liquids) have a roof that physically ",
              "rises and falls with the oil level inside. Optical satellites measure the shadow the roof's rim ",
              "casts, both outside the tank (giving total tank height) and inside it (giving the empty headspace) ",
              "- the ratio between the two gives an occupancy estimate without ever needing to see inside the ",
              "tank. Commercial providers (Orbital Insight, Kayrros, TankerTrackers.com) run this across tens of ",
              "thousands of tanks globally and sell the aggregated inventory estimates to traders."
            ), style = "font-size:12.5px; color:#7d4a00; line-height:1.65; margin:0;")
          ),
          fluidRow(
            box(width = 7, status = "info", solidHeader = TRUE, title = "Major global storage & chokepoint hubs",
              withSpinner(plotlyOutput(ns("satelliteMap"), height = "380px")),
              u3_context("Real, publicly known crude storage/trading hubs. In practice, these are exactly the ",
                         "locations commercial satellite-inventory providers monitor most closely, since a change ",
                         "here moves the global supply picture, not just a local one.")
            ),
            box(width = 5, status = "success", solidHeader = TRUE, title = "Try it: shadow-based volume estimator",
              tags$p("The actual geometry used by real providers, simplified. Enter a tank's known dimensions and its measured shadow lengths.", style="font-size:11.5px; color:#8a97a0;"),
              numericInput(ns("satDiameter"), "Tank diameter (m)", value = 82, min = 1),
              numericInput(ns("satHeight"), "Tank height (m)", value = 15, min = 1),
              fluidRow(
                column(6, numericInput(ns("satExtShadow"), "Exterior shadow length (m)", value = 20, min = 0)),
                column(6, numericInput(ns("satIntShadow"), "Interior shadow length (m)", value = 5, min = 0))
              ),
              uiOutput(ns("satResult")),
              u3_context(style="margin-top:10px;", "Occupancy = 1 \u2212 (interior shadow \u00f7 exterior shadow). ",
                         "A larger interior shadow means more empty headspace, i.e. a less full tank.")
            )
          ),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Explore real public satellite data yourself",
              collapsible = TRUE, collapsed = TRUE,
            tags$ul(style="font-size:12.5px; padding-left:20px; line-height:1.8;",
              tags$li(tags$a(href="https://apps.sentinel-hub.com/eo-browser/", target="_blank", "Sentinel Hub EO Browser"), " - free, no signup needed for basic browsing, real Sentinel-2 imagery."),
              tags$li(tags$a(href="https://worldview.earthdata.nasa.gov/", target="_blank", "NASA Worldview"), " - free daily global satellite imagery, including near-real-time.")
            )
          ),
          box(width = 12, status = NULL, solidHeader = FALSE, title = "References",
            tags$ul(style="padding-left:18px; margin:0;",
              de_ref("Mukherjee, A., Panayotov, G. and Shon, J. (2021) \u2018Eye in the sky: Private satellites and government macro data\u2019, <i>Journal of Financial Economics</i>, 141(1), pp. 234\u2013254. <a href='https://doi.org/10.1016/j.jfineco.2021.03.002' target='_blank'>https://doi.org/10.1016/j.jfineco.2021.03.002</a>"),
              de_ref("Baker Institute for Public Policy, Rice University (2018) <i>Using Satellite Data to Crack the Great Wall of Secrecy Around China's Internal Oil Flows</i>. Available at: <a href='https://www.bakerinstitute.org/research/using-satellites-study-chinese-oil' target='_blank'>https://www.bakerinstitute.org/research/using-satellites-study-chinese-oil</a>"),
              de_ref("Copernicus / European Space Agency (2026) <i>Sentinel Hub EO Browser</i>. Available at: <a href='https://apps.sentinel-hub.com/eo-browser/' target='_blank'>https://apps.sentinel-hub.com/eo-browser/</a>")
            )
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("3. Weather Patterns", icon = icon("cloud-sun-rain"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "How this actually works",
            tags$p(paste0(
              "Heating Degree Days (HDD) and Cooling Degree Days (CDD), the EIA's own standard measure, quantify ",
              "how far average temperature sits below or above 65\u00b0F - the reference point below which heating ",
              "demand kicks in and above which cooling demand does. Natural gas and heating oil demand tracks HDD ",
              "closely; power demand (and the gas burned to generate it) tracks CDD in summer."
            ), style = "font-size:12.5px; color:#7d4a00; line-height:1.65; margin:0;")
          ),
          box(width = 12, status = "info", solidHeader = TRUE, title = "Live 7-day forecast at the three key energy locations",
            selectInput(ns("weatherLocation"), "Location", choices = de_energy_locations$Location, width = "100%"),
            uiOutput(ns("weatherLocationInfo")),
            actionButton(ns("fetchWeather"), "Fetch live forecast", icon = icon("cloud-arrow-down"), class = "btn-primary"),
            uiOutput(ns("weatherStatus")),
            withSpinner(plotlyOutput(ns("weatherChart"), height = "320px")),
            DT::dataTableOutput(ns("weatherTable")),
            u3_context(style="margin-top:10px;", tags$b("Live data: "), "pulled from Open-Meteo (free, no API key) ",
                       "at the moment you click Fetch \u2014 not cached, not illustrative.")
          ),
          box(width = 12, status = NULL, solidHeader = FALSE, title = "References",
            tags$ul(style="padding-left:18px; margin:0;",
              de_ref("US Energy Information Administration (n.d.) <i>Degree-days</i>. Available at: <a href='https://www.eia.gov/energyexplained/units-and-calculators/degree-days.php' target='_blank'>https://www.eia.gov/energyexplained/units-and-calculators/degree-days.php</a>"),
              de_ref("US Energy Information Administration (2022) <i>Short-Term Energy Outlook: Natural Gas Module documentation</i>. Available at: <a href='https://www.eia.gov/analysis/handbook/pdf/STEO_natural_gas_module.pdf' target='_blank'>https://www.eia.gov/analysis/handbook/pdf/STEO_natural_gas_module.pdf</a>"),
              de_ref("Open-Meteo (2026) <i>Free Weather Forecast API</i>. Available at: <a href='https://open-meteo.com/en/about' target='_blank'>https://open-meteo.com/en/about</a> (data licensed CC BY 4.0, sourced from national weather services including NOAA)")
            )
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("4. Economic Calendar", icon = icon("calendar-days"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "Why an energy-specific calendar, separate from the general one",
            tags$p(paste0(
              "This app's existing Economic Calendar tab (Trading Economics feed) covers general macro releases. ",
              "The releases that move energy prices specifically, on their own predictable weekly schedule, are ",
              "different, and knowing the exact time is itself part of the edge: positioning ahead of a release ",
              "you can't predict the outcome of is speculation, but knowing precisely when volatility is about ",
              "to arrive is not."
            ), style = "font-size:12.5px; color:#7d4a00; line-height:1.65; margin:0;")
          ),
          box(width = 12, status = "info", solidHeader = TRUE, title = "The weekly energy release schedule",
            DT::dataTableOutput(ns("calendarTable"))
          ),
          box(width = 12, status = "success", solidHeader = TRUE, title = "Countdown to the next release",
            uiOutput(ns("calendarCountdown"))
          ),
          box(width = 12, status = NULL, solidHeader = FALSE, title = "References",
            tags$ul(style="padding-left:18px; margin:0;",
              de_ref("US Energy Information Administration (2026) <i>Weekly Petroleum Status Report</i>. Available at: <a href='https://www.eia.gov/petroleum/supply/weekly/' target='_blank'>https://www.eia.gov/petroleum/supply/weekly/</a>"),
              de_ref("US Energy Information Administration (2026) <i>Weekly Natural Gas Storage Report</i>. Available at: <a href='https://ir.eia.gov/ngs/ngs.html' target='_blank'>https://ir.eia.gov/ngs/ngs.html</a>"),
              de_ref("Baker Hughes (2026) <i>North America Rotary Rig Count</i>. Available at: <a href='https://rigcount.bakerhughes.com/' target='_blank'>https://rigcount.bakerhughes.com/</a>")
            )
          )
        )
      )
    )
  )
}

# ===========================================================================
# SERVER
# ===========================================================================

data_enrichment_server <- function(id, data_manager = NULL) {
  moduleServer(id, function(input, output, session) {

    # -- Tab 2: Satellite --
    output$satelliteMap <- renderPlotly({
      hubs <- data.frame(
        Hub = c("Cushing, OK (WTI)", "Rotterdam (ARA)", "Fujairah, UAE", "Ras Tanura, Saudi Arabia",
                "Houston, TX", "Singapore", "Ningbo, China"),
        lat = c(35.98, 51.92, 25.11, 26.70, 29.76, 1.29, 29.87),
        lon = c(-96.77, 4.48, 56.34, 50.16, -95.37, 103.85, 121.55),
        Role = c("WTI delivery point", "European refining/storage hub", "Middle East bunkering/storage",
                 "World's largest crude export terminal", "US Gulf Coast refining hub",
                 "Asian trading & bunkering hub", "Chinese strategic storage")
      )
      plot_ly(hubs, lat = ~lat, lon = ~lon, type = "scattergeo", mode = "markers+text",
              text = ~Hub, textposition = "top center", textfont = list(size = 9),
              marker = list(size = 12, color = "#008A82", symbol = "circle"),
              hovertext = ~paste0(Hub, "<br>", Role), hoverinfo = "text") %>%
        layout(geo = list(showland = TRUE, landcolor = "#f4f6f7", showcountries = TRUE,
                           countrycolor = "#d8dee3", showocean = TRUE, oceancolor = "#e8f4f3",
                           projection = list(type = "natural earth")),
               margin = list(t = 10, b = 10))
    })

    output$satResult <- renderUI({
      req(input$satDiameter, input$satHeight, input$satExtShadow, input$satIntShadow)
      r <- de_tank_shadow_volume(input$satDiameter, input$satHeight, input$satExtShadow, input$satIntShadow)
      if (is.na(r$occupancy_pct)) return(tags$p("Enter a positive exterior shadow length.", style="color:#c0392b; font-size:12px;"))
      tagList(
        u3_metric_tile("Estimated occupancy", paste0(round(r$occupancy_pct, 1), "%"), "of full capacity",
                        color = if (r$occupancy_pct > 50) "#1e7a46" else "#c0392b"),
        tags$div(style="margin-top:8px;", u3_metric_tile("Estimated volume", paste0(format(round(r$volume_bbl), big.mark=","), " bbl"), "at this fill level"))
      )
    })

    # -- Tab 3: Weather --
    output$weatherLocationInfo <- renderUI({
      row <- de_energy_locations[de_energy_locations$Location == input$weatherLocation, ]
      req(nrow(row) == 1)
      tags$p(row$Relevance, style = "font-size:12px; color:#4a5560; font-style:italic;")
    })

    weather_data <- reactiveVal(NULL)
    observeEvent(input$fetchWeather, {
      row <- de_energy_locations[de_energy_locations$Location == input$weatherLocation, ]
      req(nrow(row) == 1)
      res <- de_fetch_weather(row$lat, row$lon)
      if (!is.null(res$error)) {
        weather_data(NULL)
        output$weatherStatus <- renderUI(tags$p(paste("Could not fetch live weather:", res$error),
                                                 style = "color:#c0392b; font-size:12px;"))
      } else {
        weather_data(res)
        output$weatherStatus <- renderUI(tags$p(paste0("Live data fetched at ", format(Sys.time(), "%H:%M:%S"), "."),
                                                 style = "color:#1e7a46; font-size:12px;"))
      }
    })

    output$weatherChart <- renderPlotly({
      wd <- weather_data()
      req(!is.null(wd))
      dd_max <- de_degree_days(wd$TMax)
      dd_min <- de_degree_days(wd$TMin)
      plot_ly(wd, x = ~Date, y = ~TMax, type = "scatter", mode = "lines+markers", name = "Max Temp (\u00b0F)",
              line = list(color = "#c0392b")) %>%
        add_trace(y = ~TMin, name = "Min Temp (\u00b0F)", line = list(color = "#2980b9")) %>%
        add_trace(y = rep(65, nrow(wd)), name = "65\u00b0F base", line = list(color = "#8a97a0", dash = "dot"), mode="lines") %>%
        layout(yaxis = list(title = "Temperature (\u00b0F)"), plot_bgcolor = "white", paper_bgcolor = "white",
               legend = list(orientation = "h", y = 1.15))
    })

    output$weatherTable <- DT::renderDataTable({
      wd <- weather_data()
      req(!is.null(wd))
      dd <- de_degree_days((wd$TMax + wd$TMin) / 2)
      out <- data.frame(Date = wd$Date, `Max (°F)` = round(wd$TMax,1), `Min (°F)` = round(wd$TMin,1),
                         HDD = round(dd$hdd, 1), CDD = round(dd$cdd, 1), check.names = FALSE)
      DT::datatable(out, rownames = FALSE, options = list(dom = 't', paging = FALSE))
    }, server = FALSE)

    # -- Tab 4: Economic Calendar --
    output$calendarTable <- DT::renderDataTable({
      df <- de_release_schedule[, c("Release", "Typical_Timing", "What_It_Measures", "Typical_Market_Reaction")]
      names(df) <- c("Release", "Typical Timing", "What It Measures", "Typical Market Reaction")
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE))
    }, server = FALSE)

    output$calendarCountdown <- renderUI({
      sched <- de_release_schedule
      sched$NextDate <- sapply(sched$Weekday_Num, function(w) as.character(de_days_to_next_release(w)))
      sched$DaysAway <- as.numeric(as.Date(sched$NextDate) - Sys.Date())
      sched <- sched[order(sched$DaysAway), ]
      tagList(lapply(seq_len(nrow(sched)), function(i) {
        column(3, u3_metric_tile(sched$Release[i], paste0(sched$DaysAway[i], "d"),
                                  paste0("next: ", sched$NextDate[i]),
                                  color = if (sched$DaysAway[i] <= 1) "#c0392b" else "#002C3C"))
      }))
    })

  })
}
