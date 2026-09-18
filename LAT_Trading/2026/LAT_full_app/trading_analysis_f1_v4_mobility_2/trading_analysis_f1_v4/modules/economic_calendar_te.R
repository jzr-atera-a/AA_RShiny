# modules/economic_calendar_te.R

economic_calendar_te_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = TRUE, status = "primary",
        title = NULL,
        div(
          style = paste0(
            "background: linear-gradient(135deg, #002C3C 0%, #005f5a 60%, #00A39A 100%);",
            "border-radius: 10px; padding: 22px 28px; color: #ffffff;"
          ),
          tags$h2(HTML(paste0(icon("calendar-days"), " Economic Calendar \u2014 Trading Economics")),
                  style = "font-size:22px; font-weight:700; margin:0 0 8px 0; color:#ffffff;"),
          tags$p(HTML(paste0(
            "Pulls live economic calendar data (actual / forecast / previous / importance) from ",
            "Trading Economics, the closest free structural match to FXStreet's own calendar. Two access ",
            "modes: <strong>Guest</strong> (no signup, rate-limited demo access) or a <strong>Registered ",
            "API Key</strong> (free signup at tradingeconomics.com, higher limits)."
          )), style = "font-size:13px; line-height:1.6; color:#e8f8f6; margin:0;")
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Credentials & Filters", status = "primary", solidHeader = TRUE, width = 4,
        radioButtons(ns("teAccessMode"), "Access Mode:",
                     choices = c("Guest (no signup)" = "guest", "Registered API Key" = "registered"),
                     selected = "guest"),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'registered'", ns("teAccessMode")),
          textInput(ns("teApiKey"), "API Key (format: key:secret):", value = Sys.getenv("TE_API_KEY"),
                    placeholder = "e.g. abc123:def456"),
          tags$p(HTML(paste0(
                   "Get a free key at <a href='https://developer.tradingeconomics.com/' target='_blank'>",
                   "developer.tradingeconomics.com</a>. Pre-fills from the <code>TE_API_KEY</code> ",
                   "environment variable if set on the server."
                 )), style = "font-size:10.5px; color:#888; font-style:italic;")
        ),
        tags$hr(),
        selectInput(ns("teCountry"), "Country:",
                    choices = c("All Countries" = "all",
                                "United States" = "united states",
                                "United Kingdom" = "united kingdom",
                                "Euro Area" = "euro area",
                                "Japan" = "japan",
                                "China" = "china",
                                "Australia" = "australia",
                                "Canada" = "canada"),
                    selected = "united states"),
        dateRangeInput(ns("teDateRange"), "Date Range:",
                       start = Sys.Date() - 3, end = Sys.Date() + 7),
        actionButton(ns("teFetch"), "Fetch Calendar", icon = icon("cloud-arrow-down"),
                     class = "btn-primary", width = "100%"),
        tags$p("Guest access is shared and rate-limited \u2014 if a fetch fails, wait a few seconds and retry, or switch to a registered key.",
               style = "font-size:10.5px; color:#888; font-style:italic; margin-top:10px;")
      ),
      box(
        title = "Live Calendar", status = "info", solidHeader = TRUE, width = 8,
        uiOutput(ns("teStatusUI")),
        withSpinner(DT::dataTableOutput(ns("teCalendarTable")))
      )
    ),
    
    fluidRow(
      box(
        title = "How This Tab Sources Data", status = "info", solidHeader = TRUE, width = 12,
        tags$p(HTML(paste0(
          "Calls Trading Economics' REST API directly: <code>GET https://api.tradingeconomics.com/calendar",
          "/country/{country}?c={credentials}</code>. <strong>Actual</strong> values come from the official ",
          "releasing agency (e.g. BLS, ONS, Eurostat) in each case, not from Trading Economics itself. ",
          "<strong>Forecast</strong> is their survey consensus among economists. <strong>Importance</strong> ",
          "(Low/Medium/High) is Trading Economics' own market-impact classification."
        )), style = "font-size:12px; color:#666; line-height:1.6;")
      )
    )
  )
}

economic_calendar_te_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    te_status <- reactiveVal(NULL)
    
    fetch_te_calendar <- function(country, from_date, to_date, credentials) {
      tryCatch({
        # NOTE: TE's current official docs (docs.tradingeconomics.com) show only the base
        # /calendar?c=... endpoint — the country-specific /calendar/country/{x} path variant
        # this tab used to call was returning HTTP 410 (Gone), meaning that specific route has
        # been retired/is no longer served (at least not for guest credentials). Always hitting
        # the base endpoint and filtering by country client-side avoids relying on a URL
        # variant that may not be supported.
        url <- paste0("https://api.tradingeconomics.com/calendar?c=", credentials,
                       "&d1=", format(from_date, "%Y-%m-%d"),
                       "&d2=", format(to_date, "%Y-%m-%d"))
        
        resp <- httr::GET(url, httr::add_headers(`User-Agent` = "Mozilla/5.0"))
        status <- httr::status_code(resp)
        
        if (status != 200) {
          return(list(ok = FALSE, msg = paste0(
            "HTTP ", status, " from Trading Economics. ",
            if (status == 410) "This usually means the requested endpoint/credentials combination is no longer available \u2014 try Guest mode or verify your API key is still active. "
            else "Check credentials or try Guest mode. ",
            "Try again in a few seconds if this is a transient rate limit."
          ), data = NULL))
        }
        
        raw_text <- httr::content(resp, as = "text", encoding = "UTF-8")
        parsed <- tryCatch(jsonlite::fromJSON(raw_text, flatten = TRUE), error = function(e) NULL)
        
        if (is.null(parsed) || (is.data.frame(parsed) && nrow(parsed) == 0) ||
            (is.list(parsed) && !is.data.frame(parsed) && length(parsed) == 0)) {
          return(list(ok = FALSE, msg = "No events returned for this date range \u2014 try widening the date range.", data = NULL))
        }
        
        df <- as.data.frame(parsed, stringsAsFactors = FALSE)
        
        # Client-side country filter (case-insensitive substring match on the Country column)
        if (!identical(country, "all")) {
          country_col <- intersect(c("Country", "country"), names(df))
          if (length(country_col) > 0) {
            df <- df[grepl(country, df[[country_col[1]]], ignore.case = TRUE), , drop = FALSE]
          }
        }
        
        if (nrow(df) == 0) {
          return(list(ok = FALSE, msg = "No events matched this country/date range \u2014 try 'All Countries' or a wider date range.", data = NULL))
        }
        
        list(ok = TRUE, msg = paste0("Loaded ", nrow(df), " event(s)."), data = df)
        
      }, error = function(e) {
        list(ok = FALSE, msg = paste0("Fetch error: ", conditionMessage(e)), data = NULL)
      })
    }
    
    observeEvent(input$teFetch, {
      credentials <- if (input$teAccessMode == "guest") {
        "guest:guest"
      } else {
        req(input$teApiKey)
        if (!nzchar(trimws(input$teApiKey))) {
          te_status(list(ok = FALSE, msg = "Enter a registered API key, or switch to Guest mode."))
          return(invisible(NULL))
        }
        trimws(input$teApiKey)
      }
      
      showNotification("Fetching Trading Economics calendar...", type = "message", duration = 2)
      result <- fetch_te_calendar(input$teCountry, input$teDateRange[1], input$teDateRange[2], credentials)
      
      te_status(result)
      
      if (!result$ok) {
        showNotification(result$msg, type = "error", duration = 8)
      } else {
        showNotification(result$msg, type = "message", duration = 4)
      }
    })
    
    output$teStatusUI <- renderUI({
      res <- te_status()
      if (is.null(res)) {
        return(div(style = "text-align:center; padding:16px; color:#888; font-size:12.5px;",
                    icon("hand-pointer"), " Set your filters and click Fetch Calendar."))
      }
      if (!res$ok) {
        return(div(style = "padding:10px; border-radius:8px; background:#fdecea; color:#c0392b; font-size:12.5px; margin-bottom:10px;",
                    icon("triangle-exclamation"), " ", res$msg))
      }
      div(style = "padding:8px; border-radius:8px; background:#eafaf1; color:#1e7e46; font-size:12.5px; margin-bottom:10px;",
          icon("circle-check"), " ", res$msg)
    })
    
    output$teCalendarTable <- renderDT({
      res <- te_status()
      req(res, res$ok, res$data)
      df <- res$data
      
      # Defensive column mapping: TE's documented field names, matched case-insensitively
      # in case of minor naming drift between API versions.
      find_col <- function(df, candidates) {
        hit <- intersect(candidates, names(df))
        if (length(hit) > 0) hit[1] else NA_character_
      }
      
      col_date     <- find_col(df, c("Date", "date"))
      col_country  <- find_col(df, c("Country", "country"))
      col_event    <- find_col(df, c("Event", "event", "Category", "category"))
      col_actual   <- find_col(df, c("Actual", "actual"))
      col_forecast <- find_col(df, c("Forecast", "forecast"))
      col_previous <- find_col(df, c("Previous", "previous"))
      col_importance <- find_col(df, c("Importance", "importance"))
      
      display <- data.frame(
        Date     = if (!is.na(col_date)) format(as.POSIXct(df[[col_date]], format = "%Y-%m-%dT%H:%M:%OS"), "%Y-%m-%d %H:%M") else "",
        Country  = if (!is.na(col_country)) df[[col_country]] else "",
        Event    = if (!is.na(col_event)) df[[col_event]] else "",
        Actual   = if (!is.na(col_actual)) df[[col_actual]] else "",
        Forecast = if (!is.na(col_forecast)) df[[col_forecast]] else "",
        Previous = if (!is.na(col_previous)) df[[col_previous]] else "",
        Importance = if (!is.na(col_importance)) {
          ifelse(df[[col_importance]] == 3, "High", ifelse(df[[col_importance]] == 2, "Medium", "Low"))
        } else "",
        stringsAsFactors = FALSE
      )
      
      datatable(display, options = list(pageLength = 15, scrollX = TRUE, order = list(list(0, 'asc'))), rownames = FALSE) %>%
        formatStyle("Importance",
                    backgroundColor = styleEqual(c("High", "Medium", "Low"), c("#fadbd8", "#fdebd0", "#d5f5e3")))
    })
    
    session$onSessionEnded(function() {})
  })
}
