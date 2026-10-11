# modules/data_enrichment.R
#
# "External Sources > Data Enrichment (Energy)" - three public, non-price data
# streams that inform energy trading, each with a working tool:
#   * Satellite imagery - global storage-hub map + a shadow-based tank
#     occupancy estimator (the geometry commercial storage estimates rely on).
#   * Weather - live 7-day forecast at energy-relevant locations, converted to
#     heating/cooling degree days (EIA's standard measure), plus an offline
#     degree-day calculator.
#   * Energy release calendar - the weekly EIA / rig count / API schedule with a
#     live, time-aware countdown in US Eastern time.
#
# Ported from an earlier version of this app and improved. Changes on review:
#   * Every reference and every factual claim was checked; unverifiable ones
#     were removed or reworded (the original quoted "1-3% within minutes"
#     market-reaction figures that nothing checked supports).
#   * Open-Meteo's free tier is NON-COMMERCIAL only and requires an attribution
#     link - the original said only "free, no API key". Both are now shown.
#   * The countdown is time-aware (a release that already happened today is
#     no longer shown as "today"), works in US Eastern time, and handles the
#     clock change.
#   * The tank estimator validates its inputs rather than silently clamping an
#     impossible measurement (interior shadow longer than exterior).
#   * The weather parsing is separate from the network call so it can be tested;
#     missing temperatures are counted and reported instead of hiding in sums.
#
# NOT TESTED END-TO-END: the live Open-Meteo call cannot be reached from the
# build environment (outbound access is restricted). The URL, parsing and error
# handling were tested against realistic responses; please confirm the live
# fetch works the first time you run it.

# ===========================================================================
# PURE LOGIC
# ===========================================================================

# EIA definition: degree days are computed per day from the mean of the day's
# high and low against a 65F base, negatives set to zero, then summed.
de_degree_days <- function(tmax_f, tmin_f, base_f = 65) {
  mean_f <- (tmax_f + tmin_f) / 2
  list(mean = mean_f, hdd = pmax(base_f - mean_f, 0), cdd = pmax(mean_f - base_f, 0))
}

# Floating-roof tank occupancy from shadow lengths. The roof rim casts a shadow
# outside the tank (proportional to full height) and inside it (proportional to
# the empty headspace); both use the same sun angle, so the ratio cancels it:
#   occupancy = 1 - interior / exterior.
# Assumes a vertical cylinder. Returns a `problem` message instead of silently
# clamping an impossible input.
de_tank_shadow_volume <- function(diameter_m, height_m, exterior_shadow_m, interior_shadow_m) {
  bad <- function(msg) list(occupancy_pct = NA_real_, volume_bbl = NA_real_, capacity_bbl = NA_real_, problem = msg)
  vals <- c(diameter_m, height_m, exterior_shadow_m, interior_shadow_m)
  if (any(!is.finite(vals))) return(bad("Enter a number in every field."))
  if (diameter_m <= 0 || height_m <= 0) return(bad("Tank diameter and height must be positive."))
  if (exterior_shadow_m <= 0) return(bad("Enter a positive exterior shadow length."))
  if (interior_shadow_m < 0) return(bad("The interior shadow length cannot be negative."))
  if (interior_shadow_m > exterior_shadow_m)
    return(bad("The interior shadow is longer than the exterior shadow, which is physically impossible for one tank: re-check the measurements."))
  occ <- 1 - interior_shadow_m / exterior_shadow_m
  capacity_m3 <- pi * (diameter_m / 2)^2 * height_m
  list(occupancy_pct = occ * 100, volume_bbl = capacity_m3 * occ * 6.2898,
       capacity_bbl = capacity_m3 * 6.2898, problem = NULL)   # 1 m3 = 6.2898 US oil barrels
}

# Next occurrence of a weekly release, in US Eastern time, as a POSIXct.
# `wday` uses POSIXlt numbering (0 = Sunday ... 6 = Saturday). A release that
# already happened today rolls to next week. Built from the calendar date so a
# clock change between now and the release doesn't shift the wall-clock time.
de_next_release <- function(wday, hour, minute, now = Sys.time(), tz = "America/New_York") {
  now_et <- as.POSIXlt(now, tz = tz)
  today <- as.Date(format(now_et, "%Y-%m-%d"))
  add <- (wday - now_et$wday) %% 7
  make <- function(a) as.POSIXct(paste(today + a, sprintf("%02d:%02d:00", hour, minute)), tz = tz)
  cand <- make(add)
  if (cand <= now) cand <- make(add + 7)
  cand
}

de_format_countdown <- function(secs) {
  if (secs < 3600) return(paste0(max(0, round(secs / 60)), " min"))
  if (secs < 86400) return(sprintf("%dh %dm", secs %/% 3600, round((secs %% 3600) / 60)))
  sprintf("%dd %dh", secs %/% 86400, round((secs %% 86400) / 3600))
}

# Energy-relevant weather locations.
de_energy_locations <- data.frame(
  Location = c("Cushing, Oklahoma (WTI hub)", "Erath, Louisiana (Henry Hub)", "Rotterdam, Netherlands (ARA hub)",
               "Chicago, Illinois (Midwest gas demand)", "Toronto, Ontario (Canadian gas demand)"),
  Relevance = c("The WTI crude delivery point; extreme cold can disrupt pipeline flows and refinery runs.",
                "The Henry Hub natural gas pricing point; heating demand is a major driver of winter gas price moves.",
                "The Amsterdam-Rotterdam-Antwerp refining and storage hub, a reference point for European demand.",
                "A large Midwest population centre where cold snaps lift regional heating-gas demand.",
                "A large Canadian population centre, tying this tab to the Canadian side of the Satellite Data map."),
  lat = c(35.98, 29.95, 51.92, 41.88, 43.65), lon = c(-96.77, -92.03, 4.48, -87.63, -79.38),
  stringsAsFactors = FALSE
)

# Parses an Open-Meteo forecast response. Returns list(ok, data, n_missing) or
# list(ok = FALSE, error). Open-Meteo reports request problems as
# {"error": true, "reason": "..."}; missing temperatures arrive as null.
de_parse_weather <- function(json_text) {
  js <- tryCatch(jsonlite::fromJSON(json_text), error = function(e) NULL)
  if (is.null(js) || !is.list(js)) return(list(ok = FALSE, error = "The response was not valid JSON."))
  if (isTRUE(js$error)) return(list(ok = FALSE, error = paste("Open-Meteo reported:", js$reason %||% "unknown error")))
  d <- js$daily
  if (is.null(d) || is.null(d$time) || is.null(d$temperature_2m_max) || is.null(d$temperature_2m_min))
    return(list(ok = FALSE, error = "The response did not contain the expected daily temperatures."))
  n <- length(d$time)
  if (length(d$temperature_2m_max) != n || length(d$temperature_2m_min) != n)
    return(list(ok = FALSE, error = "The temperature series were not the same length as the dates."))
  df <- data.frame(Date = as.Date(d$time), TMax = as.numeric(d$temperature_2m_max),
                   TMin = as.numeric(d$temperature_2m_min), stringsAsFactors = FALSE)
  list(ok = TRUE, data = df, n_missing = sum(is.na(df$TMax) | is.na(df$TMin)))
}

de_weather_url <- function(lat, lon) {
  paste0("https://api.open-meteo.com/v1/forecast?latitude=", lat, "&longitude=", lon,
         "&daily=temperature_2m_max,temperature_2m_min&temperature_unit=fahrenheit&timezone=auto&forecast_days=7")
}

de_fetch_weather <- function(lat, lon) {
  tryCatch({
    resp <- httr::GET(de_weather_url(lat, lon), httr::timeout(8))
    body <- httr::content(resp, as = "text", encoding = "UTF-8")
    if (httr::status_code(resp) != 200) {
      # Open-Meteo puts the reason in the body; a proxy/allow-list block does too.
      reason <- tryCatch(jsonlite::fromJSON(body)$reason, error = function(e) NULL)
      return(list(ok = FALSE, error = paste0("HTTP ", httr::status_code(resp), if (!is.null(reason)) paste0(": ", reason) else if (nzchar(body)) paste0(": ", substr(body, 1, 120)) else "")))
    }
    de_parse_weather(body)
  }, error = function(e) list(ok = FALSE, error = conditionMessage(e)))
}

# Release schedule. Rows marked "EIA (primary)" were checked against EIA's own
# pages; the others rest on secondary reporting only.
de_release_schedule <- data.frame(
  Release = c("EIA Weekly Petroleum Status Report", "EIA Weekly Natural Gas Storage Report",
              "Baker Hughes US Rig Count", "API Weekly Statistical Bulletin"),
  Timing = c("Wednesdays, 10:30 ET", "Thursdays, 10:30 ET", "Fridays, 1:00 pm ET", "Tuesdays, 4:30 pm ET"),
  wday = c(3, 4, 5, 2), hour = c(10, 10, 13, 16), minute = c(30, 30, 0, 30),
  Measures = c("US crude and product inventories, refinery utilisation, production, imports and product supplied.",
               "Weekly change in working natural gas in storage, compared with the five-year average and last year.",
               "The number of rigs actively drilling for oil and gas: a leading indicator of future supply.",
               "Industry-survey estimate of US crude inventories, published the evening before the EIA report."),
  Reaction = c("Prices tend to respond to the surprise against expectations rather than the level itself; Cushing stocks matter directly for WTI.",
               "The surprise against expectations is what moves natural gas; the winter weather backdrop matters (see the Weather tab).",
               "Slow-moving: relevant to medium-term supply expectations more than same-day price action. Higher prices often precede rig additions.",
               "Voluntary survey, less complete than the EIA's mandatory one, but published first, so it can move prices in anticipation."),
  Source = c("EIA (primary)", "EIA (primary)", "Secondary sources", "Secondary sources"),
  stringsAsFactors = FALSE
)

de_hubs <- data.frame(
  Hub = c("Cushing, OK", "Houston, TX", "Rotterdam (ARA)", "Fujairah, UAE", "Ras Tanura, Saudi Arabia", "Singapore", "Ningbo, China"),
  lat = c(35.98, 29.76, 51.92, 25.11, 26.70, 1.29, 29.87), lon = c(-96.77, -95.37, 4.48, 56.34, 50.16, 103.85, 121.55),
  Role = c("WTI delivery point and a major US crude storage hub", "US Gulf Coast refining and export hub",
           "European refining and storage hub", "Middle East bunkering and storage hub",
           "Major Saudi crude export terminal", "Asian trading and bunkering hub", "Major Chinese oil import port"),
  stringsAsFactors = FALSE
)

# ===========================================================================
# UI
# ===========================================================================

data_enrichment_ui <- function(id) {
  ns <- NS(id)
  note <- function(...) tags$p(..., style = "font-size:12.5px; color:#7d4a00; line-height:1.65; margin:0;")

  tagList(
    ui_banner("External Sources", "Data Enrichment: Energy Commodities",
              "Three public, non-price data streams that inform energy trading \u2014 satellite imagery, weather and the release calendar \u2014 each with a working tool."),

    fluidRow(
      tabBox(id = ns("subtabs"), width = 12, selected = "1. Overview",

        tabPanel("1. Overview", icon = icon("layer-group"),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Why non-price data matters for energy",
              collapsible = TRUE, collapsed = FALSE,
            tags$p(paste0(
              "Energy prices are driven by physical supply and demand, which is visible in other data before an official ",
              "report confirms it. Three public streams give an earlier or sharper read than price alone: satellite views ",
              "of physical storage, weather that drives heating and cooling demand, and the exact timing of the official ",
              "releases that later confirm what the other two implied."
            ), style = "font-size:13px; color:#4a5560; line-height:1.65; margin:0;")
          ),
          fluidRow(
            column(4, box(width = 12, status = "info", solidHeader = TRUE, title = "Satellite imagery",
              tags$p("Optical satellites can estimate how full floating-roof storage tanks are from the shadows they cast, ahead of official inventory data.", style = "font-size:12px; color:#4a5560;"))),
            column(4, box(width = 12, status = "info", solidHeader = TRUE, title = "Weather patterns",
              tags$p("Heating and cooling degree days are a standard measure of weather-driven demand for natural gas, heating oil and power.", style = "font-size:12px; color:#4a5560;"))),
            column(4, box(width = 12, status = "info", solidHeader = TRUE, title = "Release calendar",
              tags$p("Weekly EIA, rig-count and API releases arrive on a predictable schedule; knowing when volatility is due is itself useful.", style = "font-size:12px; color:#4a5560;")))
          ),
          box(width = 12, status = "warning", solidHeader = FALSE, title = "How this connects to the rest of the app",
            note("The Hedge Fund / Wealth tab's natural-gas weather strategy leans on the Weather tab here, and its inventory strategy on the release calendar. The Satellite Data tab above this one shows simulated regional demand patterns for the US and Canada; the tab you are on now covers the real, public data sources behind that kind of analysis. The Economic Calendars group covers general macro releases; this calendar covers only the energy-specific ones.")
          )
        ),

        tabPanel("2. Satellite Imagery", icon = icon("satellite"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE, title = "How this works",
            note(paste0(
              "Floating-roof tanks have a roof that rises and falls with the liquid level. Optical satellites can measure ",
              "the shadow the roof rim casts outside the tank (giving its full height) and inside it (giving the empty ",
              "headspace). The ratio gives an occupancy estimate without seeing inside, and because both shadows share one ",
              "sun angle the angle cancels out. Commercial providers sell estimates built this way."
            ))
          ),
          box(width = 12, status = "info", solidHeader = TRUE, title = "What the research finds",
            tags$p(paste0(
              "Mukherjee, Panayotov and Shon (2021) study whether commercial satellite estimates can substitute for ",
              "government data. Looking at US crude oil storage and Chinese manufacturing, they find that some satellite ",
              "estimates are now so effective that markets are no longer surprised by the official announcement."
            ), style = "font-size:12.5px; color:#4a5560; line-height:1.65;"),
            tags$p(paste0(
              "One limit matters for anyone relying on this: their method uses cloud cover, which stops satellites seeing ",
              "some key hubs on some days. Satellite estimates concentrate on a handful of locations, such as Cushing, Oklahoma."
            ), style = "font-size:12.5px; color:#4a5560; line-height:1.65; margin-bottom:0;")
          ),
          fluidRow(
            box(width = 7, status = "info", solidHeader = TRUE, title = "Major crude storage and trading hubs (illustrative selection)",
              withSpinner(plotly::plotlyOutput(ns("satelliteMap"), height = "380px")),
              ui_context("Real, publicly known hubs. A selection, not an exhaustive or authoritative list of what any provider monitors.")
            ),
            box(width = 5, status = "success", solidHeader = TRUE, title = "Try it: shadow-based occupancy estimator",
              tags$p("The geometry, simplified. Enter a tank's dimensions and the two measured shadow lengths.", style = "font-size:11.5px; color:#6b7883;"),
              numericInput(ns("satDiameter"), "Tank diameter (m)", value = 82, min = 1),
              numericInput(ns("satHeight"), "Tank height (m)", value = 15, min = 1),
              fluidRow(
                column(6, numericInput(ns("satExtShadow"), "Exterior shadow (m)", value = 20, min = 0)),
                column(6, numericInput(ns("satIntShadow"), "Interior shadow (m)", value = 5, min = 0))
              ),
              uiOutput(ns("satResult")),
              ui_context("Occupancy = 1 \u2212 (interior shadow \u00f7 exterior shadow). A longer interior shadow means more empty headspace. Assumes a vertical cylindrical tank.")
            )
          ),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Explore public satellite imagery yourself",
              collapsible = TRUE, collapsed = TRUE,
            tags$ul(style = "font-size:12.5px; padding-left:20px; line-height:1.8; margin:0;",
              tags$li(tags$a(href = "https://apps.sentinel-hub.com/eo-browser/", target = "_blank", "Sentinel Hub EO Browser"), " \u2014 browse Sentinel imagery."),
              tags$li(tags$a(href = "https://worldview.earthdata.nasa.gov/", target = "_blank", "NASA Worldview"), " \u2014 daily global imagery from NASA."))
          ),
          fluidRow(column(12, ua_references(
            ua_ref("<b>Mukherjee, A., Panayotov, G. and Shon, J. (2021)</b> \u2018Eye in the sky: Private satellites and government macro data\u2019, <i>Journal of Financial Economics</i>, 141(1), pp. 234\u2013254.",
                   "https://www.sciencedirect.com/science/article/abs/pii/S0304405X21000921"),
            ua_ref("<b>South China Morning Post / HKUST Business School (2020)</b> <i>Eye in the sky</i>. (Plain-language summary of the paper.)",
                   "https://www.scmp.com/presented/news/hong-kong/education/topics/new-normal/article/3098774/eye-sky")
          )))
        ),

        tabPanel("3. Weather Patterns", icon = icon("cloud-sun-rain"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE, title = "How this works",
            note(paste0(
              "Heating degree days (HDD) and cooling degree days (CDD) measure how far a day's mean temperature sits below or ",
              "above a 65\u00b0F base. Per the EIA, each day's figure is the base minus the average of that day's high and ",
              "low (or the reverse for cooling), with negatives set to zero, then summed over the period. Gas and heating-oil ",
              "demand track HDD; summer power demand, and the gas burned for it, tracks CDD."
            ))
          ),
          fluidRow(
            box(width = 5, status = "success", solidHeader = TRUE, title = "Try it: degree-day calculator",
              tags$p("Works offline. Enter a day's high and low.", style = "font-size:11.5px; color:#6b7883;"),
              fluidRow(column(6, numericInput(ns("calcHigh"), "High (\u00b0F)", value = 40)),
                       column(6, numericInput(ns("calcLow"), "Low (\u00b0F)", value = 20))),
              uiOutput(ns("calcResult"))
            ),
            box(width = 7, status = "info", solidHeader = TRUE, title = "Live 7-day forecast at an energy location",
              selectInput(ns("weatherLocation"), "Location", choices = de_energy_locations$Location, width = "100%"),
              uiOutput(ns("weatherLocationInfo")),
              actionButton(ns("fetchWeather"), "Fetch live forecast", icon = icon("cloud-arrow-down"), class = "btn-primary"),
              uiOutput(ns("weatherStatus"))
            )
          ),
          box(width = 12, status = "info", solidHeader = TRUE, title = "Forecast and degree days",
            uiOutput(ns("weatherTiles")),
            withSpinner(plotly::plotlyOutput(ns("weatherChart"), height = "320px")),
            DT::dataTableOutput(ns("weatherTable")),
            tags$p(style = "font-size:11.5px; color:#6b7883; margin:8px 0 0 0;",
                   tags$a(href = "https://open-meteo.com/", target = "_blank", "Weather data by Open-Meteo.com"),
                   " (CC BY 4.0). Fetched when you click, not cached."),
            ui_context(tags$b("Commercial use: "), "Open-Meteo's free service is for non-commercial use only \u2014 private, non-profit, educational or research use ",
                       "without subscriptions or advertising. If this were used inside a commercial managed-money business, you would need a paid Open-Meteo plan ",
                       "or a different source. Check their terms before relying on it.")
          ),
          fluidRow(column(12, ua_references(
            ua_ref("<b>US Energy Information Administration (n.d.)</b> <i>Glossary: heating degree days</i>.",
                   "https://www.eia.gov/tools/glossary/index.php?id=Heating"),
            ua_ref("<b>Open-Meteo (n.d.)</b> <i>Terms of use</i>. (Free use is non-commercial; data licensed CC BY 4.0 with attribution.)",
                   "https://open-meteo.com/en/terms")
          )))
        ),

        tabPanel("4. Release Calendar", icon = icon("calendar-days"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "Why an energy-specific calendar",
            note(paste0(
              "The Economic Calendars group covers general macro releases. The releases that move energy prices specifically ",
              "come on their own weekly schedule. You cannot predict the outcome, but you can know precisely when the ",
              "volatility is due."
            ))
          ),
          box(width = 12, status = "success", solidHeader = TRUE, title = "Countdown to the next release (US Eastern time)",
            uiOutput(ns("calendarCountdown")),
            ui_context("The countdown does not know about holidays: EIA moves releases in some holiday weeks, so check EIA's schedule pages before trading around one.")
          ),
          box(width = 12, status = "info", solidHeader = TRUE, title = "The weekly energy release schedule",
            DT::dataTableOutput(ns("calendarTable"))
          ),
          fluidRow(column(12, ua_references(
            ua_ref("<b>US Energy Information Administration (2026)</b> <i>Weekly Petroleum Status Report: release schedule</i>.",
                   "https://www.eia.gov/oil_gas/petroleum/data_publications/weekly_petroleum_status_report/schedule.html"),
            ua_ref("<b>US Energy Information Administration (2026)</b> <i>Weekly Natural Gas Storage Report: schedule</i>.",
                   "https://ir.eia.gov/ngs/schedule.html"),
            ua_ref("<b>Baker Hughes (2026)</b> <i>Rig Count</i>. (Release day and time from secondary reporting.)",
                   "https://rigcount.bakerhughes.com/")
          )))
        )
      )
    )
  )
}

# ===========================================================================
# SERVER
# ===========================================================================

data_enrichment_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # -- Satellite --
    output$satelliteMap <- plotly::renderPlotly({
      plotly::plot_ly(de_hubs, lat = ~lat, lon = ~lon, type = "scattergeo", mode = "markers+text",
                      text = ~Hub, textposition = "top center", textfont = list(size = 9),
                      marker = list(size = 12, color = "#008A82"),
                      hovertext = ~paste0(Hub, "<br>", Role), hoverinfo = "text") |>
        plotly::layout(geo = list(showland = TRUE, landcolor = "#f4f6f7", showcountries = TRUE, countrycolor = "#d8dee3",
                                  showocean = TRUE, oceancolor = "#e8f4f3", projection = list(type = "natural earth")),
                       margin = list(t = 10, b = 10))
    })

    output$satResult <- renderUI({
      r <- de_tank_shadow_volume(input$satDiameter %||% NA, input$satHeight %||% NA,
                                 input$satExtShadow %||% NA, input$satIntShadow %||% NA)
      if (!is.null(r$problem)) return(tags$p(r$problem, style = "color:#c0392b; font-size:12px;"))
      tagList(
        ui_metric_tile("Estimated occupancy", paste0(round(r$occupancy_pct, 1), "%"), "of full capacity",
                       color = if (r$occupancy_pct > 50) "#1e7a46" else "#c0392b"),
        ui_metric_tile("Estimated volume", paste0(format(round(r$volume_bbl), big.mark = ","), " bbl"),
                       paste0("of a ", format(round(r$capacity_bbl), big.mark = ","), " bbl tank"))
      )
    })

    # -- Weather --
    output$calcResult <- renderUI({
      hi <- input$calcHigh; lo <- input$calcLow
      if (is.null(hi) || is.null(lo) || is.na(hi) || is.na(lo)) return(NULL)
      if (lo > hi) return(tags$p("The low is higher than the high \u2014 check the values.", style = "color:#c0392b; font-size:12px;"))
      d <- de_degree_days(hi, lo)
      fluidRow(column(4, ui_metric_tile("Mean", paste0(round(d$mean, 1), "\u00b0F"), "(high + low) \u00f7 2")),
               column(4, ui_metric_tile("HDD", round(d$hdd, 1), "heating demand", color = "#2980b9")),
               column(4, ui_metric_tile("CDD", round(d$cdd, 1), "cooling demand", color = "#c0392b")))
    })

    output$weatherLocationInfo <- renderUI({
      row <- de_energy_locations[de_energy_locations$Location == input$weatherLocation, ]
      req(nrow(row) == 1)
      tags$p(row$Relevance, style = "font-size:12px; color:#4a5560; font-style:italic;")
    })

    weather_data <- reactiveVal(NULL)
    weather_status <- reactiveVal(NULL)
    observeEvent(input$fetchWeather, {
      row <- de_energy_locations[de_energy_locations$Location == input$weatherLocation, ]
      req(nrow(row) == 1)
      cat("[Data Enrichment] Fetching weather for", row$Location, "\n")
      res <- de_fetch_weather(row$lat, row$lon)
      if (!isTRUE(res$ok)) {
        cat("[Data Enrichment] Weather fetch FAILED:", res$error, "\n")
        weather_data(NULL)
        weather_status(list(ok = FALSE, msg = res$error))
      } else {
        cat("[Data Enrichment] Weather fetched:", nrow(res$data), "days,", res$n_missing, "missing\n")
        weather_data(cbind(res$data, Location = row$Location))
        weather_status(list(ok = TRUE, n_missing = res$n_missing, time = format(Sys.time(), "%H:%M:%S")))
      }
    })

    output$weatherStatus <- renderUI({
      s <- weather_status()
      if (is.null(s)) return(NULL)
      if (!isTRUE(s$ok)) return(tags$p(paste("Could not fetch live weather:", s$msg), style = "color:#c0392b; font-size:12px; margin-top:8px;"))
      tags$p(paste0("Fetched at ", s$time, ".", if (s$n_missing > 0) paste0(" ", s$n_missing, " day(s) had a missing temperature and are left out of the totals.") else ""),
             style = "color:#1e7a46; font-size:12px; margin-top:8px;")
    })

    weather_dd <- reactive({
      wd <- weather_data(); req(wd)
      d <- de_degree_days(wd$TMax, wd$TMin)
      cbind(wd, Mean = d$mean, HDD = d$hdd, CDD = d$cdd)
    })

    output$weatherTiles <- renderUI({
      wd <- weather_data()
      if (is.null(wd)) return(tags$p("Click \u201cFetch live forecast\u201d above to load a 7-day forecast.", style = "color:#6b7883; font-size:12.5px;"))
      dd <- weather_dd()
      fluidRow(
        column(4, ui_metric_tile("7-day HDD total", round(sum(dd$HDD, na.rm = TRUE), 1), wd$Location[1], color = "#2980b9")),
        column(4, ui_metric_tile("7-day CDD total", round(sum(dd$CDD, na.rm = TRUE), 1), "cooling demand", color = "#c0392b")),
        column(4, ui_metric_tile("Days with data", sum(!is.na(dd$Mean)), "of 7"))
      )
    })

    output$weatherChart <- plotly::renderPlotly({
      # Qualified on purpose: jsonlite (attached after shiny in app.R) also exports a
      # function called validate(), which would otherwise mask shiny's.
      shiny::validate(shiny::need(!is.null(weather_data()), "No forecast loaded yet."))
      dd <- weather_dd()
      plotly::plot_ly(dd, x = ~Date, y = ~TMax, type = "scatter", mode = "lines+markers", name = "High (\u00b0F)", line = list(color = "#c0392b")) |>
        plotly::add_trace(y = ~TMin, name = "Low (\u00b0F)", line = list(color = "#2980b9")) |>
        plotly::add_trace(y = rep(65, nrow(dd)), name = "65\u00b0F base", mode = "lines", line = list(color = "#8a97a0", dash = "dot")) |>
        plotly::layout(yaxis = list(title = "Temperature (\u00b0F)"), plot_bgcolor = "white", paper_bgcolor = "white",
                       legend = list(orientation = "h", y = 1.15))
    })

    output$weatherTable <- DT::renderDataTable({
      dd <- weather_dd()
      out <- data.frame(dd$Date, round(dd$TMax, 1), round(dd$TMin, 1), round(dd$Mean, 1), round(dd$HDD, 1), round(dd$CDD, 1))
      names(out) <- c("Date", "High (\u00b0F)", "Low (\u00b0F)", "Mean (\u00b0F)", "HDD", "CDD")
      DT::datatable(out, rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)

    # -- Release calendar --
    output$calendarTable <- DT::renderDataTable({
      df <- de_release_schedule[, c("Release", "Timing", "Measures", "Reaction", "Source")]
      names(df) <- c("Release", "Typical timing", "What it measures", "How markets tend to treat it", "Timing source")
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)

    output$calendarCountdown <- renderUI({
      invalidateLater(60000, session)   # refresh each minute
      now <- Sys.time()
      s <- de_release_schedule
      s$when <- lapply(seq_len(nrow(s)), function(i) de_next_release(s$wday[i], s$hour[i], s$minute[i], now))
      s$secs <- vapply(s$when, function(w) as.numeric(difftime(w, now, units = "secs")), numeric(1))
      s <- s[order(s$secs), ]
      fluidRow(lapply(seq_len(nrow(s)), function(i) {
        column(3, ui_metric_tile(s$Release[i], de_format_countdown(s$secs[i]),
                                 paste0("next: ", format(s$when[[i]], "%a %d %b, %H:%M ET")),
                                 color = if (s$secs[i] < 86400) "#c0392b" else "#002C3C"))
      }))
    })
  })
}
