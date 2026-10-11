# modules/economic_calendar_fmp.R

economic_calendar_fmp_ui <- function(id) {
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
          tags$h2(HTML(paste0(icon("calendar-days"), " Economic Calendar \u2014 Financial Modeling Prep")),
                  style = "font-size:22px; font-weight:700; margin:0 0 8px 0; color:#ffffff;"),
          tags$p(HTML(paste0(
            "Pulls live economic calendar data from Financial Modeling Prep's (FMP) Economic Data Releases ",
            "Calendar API \u2014 a second, independent free source for comparison against the Trading Economics tab. ",
            "Requires a free registered API key (no guest/demo mode available for this provider)."
          )), style = "font-size:13px; line-height:1.6; color:#e8f8f6; margin:0;")
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Credentials & Filters", status = "primary", solidHeader = TRUE, width = 4,
        passwordInput(ns("fmpApiKey"), "FMP API Key:", value = Sys.getenv("FMP_API_KEY"),
                      placeholder = "Paste your free API key"),
        tags$p(HTML(paste0(
                 "Get a free key at <a href='https://site.financialmodelingprep.com/developer/docs' ",
                 "target='_blank'>financialmodelingprep.com</a> (free tier: 250 requests/day). Pre-fills from ",
                 "the <code>FMP_API_KEY</code> environment variable if set on the server. Never written to disk."
               )), style = "font-size:10.5px; color:#888; font-style:italic;"),
        tags$hr(),
        dateRangeInput(ns("fmpDateRange"), "Date Range (max ~3 months):",
                       start = Sys.Date() - 3, end = Sys.Date() + 7),
        actionButton(ns("fmpFetch"), "Fetch Calendar", icon = icon("cloud-arrow-down"),
                     class = "btn-primary", width = "100%"),
        tags$p("FMP has changed its economic calendar endpoint path before \u2014 if the primary request fails, this tab automatically tries the older legacy path as a fallback.",
               style = "font-size:10.5px; color:#888; font-style:italic; margin-top:10px;")
      ),
      box(
        title = "Live Calendar", status = "info", solidHeader = TRUE, width = 8,
        uiOutput(ns("fmpStatusUI")),
        withSpinner(DT::dataTableOutput(ns("fmpCalendarTable")))
      )
    ),
    
    fluidRow(
      box(
        title = "How This Tab Sources Data — and a Caveat", status = "warning", solidHeader = FALSE, width = 12,
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$p(HTML(paste0(
              "Calls <code>GET https://financialmodelingprep.com/stable/economic-calendar</code>, falling back ",
              "to the legacy <code>GET https://financialmodelingprep.com/api/v3/economic_calendar</code> if the ",
              "first attempt fails. FMP has migrated endpoint paths before, so <strong>this tab's column mapping ",
              "is defensive</strong> \u2014 it searches the response for likely field names (event, date, country, ",
              "actual, previous, estimate/forecast, impact) rather than assuming an exact fixed schema. If a ",
              "fetch succeeds but the table looks incomplete or mislabelled, check the raw response structure ",
              "against FMP's current docs and this mapping can be tightened."
            )), style = "font-size:12px; color:#5a3500; line-height:1.6; margin:0;")
          )
        )
      )
    )
  )
}

economic_calendar_fmp_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    fmp_status <- reactiveVal(NULL)
    
    fetch_fmp_calendar <- function(api_key, from_date, to_date) {
      tryCatch({
        from_str <- format(from_date, "%Y-%m-%d")
        to_str   <- format(to_date, "%Y-%m-%d")
        
        urls <- c(
          paste0("https://financialmodelingprep.com/stable/economic-calendar?from=", from_str,
                 "&to=", to_str, "&apikey=", api_key),
          paste0("https://financialmodelingprep.com/api/v3/economic_calendar?from=", from_str,
                 "&to=", to_str, "&apikey=", api_key)
        )
        
        last_error <- NULL
        for (url in urls) {
          resp <- tryCatch(httr::GET(url, httr::add_headers(`User-Agent` = "Mozilla/5.0")),
                            error = function(e) { last_error <<- conditionMessage(e); NULL })
          if (is.null(resp)) next
          
          status <- httr::status_code(resp)
          if (status != 200) {
            last_error <- paste0("HTTP ", status, " from ", url)
            next
          }
          
          raw_text <- httr::content(resp, as = "text", encoding = "UTF-8")
          parsed <- tryCatch(jsonlite::fromJSON(raw_text, flatten = TRUE), error = function(e) NULL)
          
          if (is.null(parsed)) { last_error <- "Could not parse JSON response."; next }
          
          # An error payload (e.g. bad key) usually comes back as a named list/object, not an array
          if (is.list(parsed) && !is.data.frame(parsed) && !is.null(parsed[["Error Message"]])) {
            last_error <- paste0("FMP error: ", parsed[["Error Message"]])
            next
          }
          
          df <- tryCatch(as.data.frame(parsed, stringsAsFactors = FALSE), error = function(e) NULL)
          if (is.null(df) || nrow(df) == 0) { last_error <- "No events returned for this date range."; next }
          
          return(list(ok = TRUE, msg = paste0("Loaded ", nrow(df), " event(s) from ", url), data = df))
        }
        
        list(ok = FALSE, msg = paste0("All endpoint attempts failed. ", last_error %||% ""), data = NULL)
        
      }, error = function(e) {
        list(ok = FALSE, msg = paste0("Fetch error: ", conditionMessage(e)), data = NULL)
      })
    }
    
    observeEvent(input$fmpFetch, {
      req(input$fmpApiKey)
      if (!nzchar(trimws(input$fmpApiKey))) {
        fmp_status(list(ok = FALSE, msg = "Enter your FMP API key first."))
        showNotification("Enter your FMP API key first.", type = "warning", duration = 5)
        return(invisible(NULL))
      }
      
      showNotification("Fetching FMP economic calendar...", type = "message", duration = 2)
      result <- fetch_fmp_calendar(trimws(input$fmpApiKey), input$fmpDateRange[1], input$fmpDateRange[2])
      
      fmp_status(result)
      
      if (!result$ok) {
        showNotification(result$msg, type = "error", duration = 8)
      } else {
        showNotification(paste0("Loaded ", nrow(result$data), " event(s)."), type = "message", duration = 4)
      }
    })
    
    output$fmpStatusUI <- renderUI({
      res <- fmp_status()
      if (is.null(res)) {
        return(div(style = "text-align:center; padding:16px; color:#888; font-size:12.5px;",
                    icon("hand-pointer"), " Enter your API key and click Fetch Calendar."))
      }
      if (!res$ok) {
        return(div(style = "padding:10px; border-radius:8px; background:#fdecea; color:#c0392b; font-size:12.5px; margin-bottom:10px;",
                    icon("triangle-exclamation"), " ", res$msg))
      }
      div(style = "padding:8px; border-radius:8px; background:#eafaf1; color:#1e7e46; font-size:12.5px; margin-bottom:10px;",
          icon("circle-check"), " ", res$msg)
    })
    
    output$fmpCalendarTable <- renderDT({
      res <- fmp_status()
      req(res, res$ok, res$data)
      df <- res$data
      
      # Defensive column mapping — FMP's exact field names aren't confirmed from a live capture,
      # so this searches for plausible candidates rather than assuming a fixed schema. Falls back
      # to showing the raw columns returned if none of the expected names are found, so the tab
      # never silently produces an empty-looking table.
      find_col <- function(df, patterns) {
        for (p in patterns) {
          hit <- grep(p, names(df), ignore.case = TRUE, value = TRUE)
          if (length(hit) > 0) return(hit[1])
        }
        NA_character_
      }
      
      col_date     <- find_col(df, c("^date$"))
      col_country  <- find_col(df, c("^country$", "currency"))
      col_event    <- find_col(df, c("^event$"))
      col_actual   <- find_col(df, c("^actual$"))
      col_forecast <- find_col(df, c("^estimate$", "^forecast$", "^consensus$"))
      col_previous <- find_col(df, c("^previous$"))
      col_impact   <- find_col(df, c("^impact$", "importance"))
      
      mapped_ok <- !all(is.na(c(col_date, col_country, col_event, col_actual)))
      
      if (!mapped_ok) {
        # Column-name guesses didn't match anything recognisable — show the raw response so the
        # data is still usable, and flag that the mapping needs updating against FMP's current docs.
        showNotification(
          "Could not confidently map FMP's response columns — showing raw data below. Check the column names against FMP's current docs.",
          type = "warning", duration = 8
        )
        datatable(df, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE)
      } else {
        display <- data.frame(
          Date     = if (!is.na(col_date)) df[[col_date]] else "",
          Country  = if (!is.na(col_country)) df[[col_country]] else "",
          Event    = if (!is.na(col_event)) df[[col_event]] else "",
          Actual   = if (!is.na(col_actual)) df[[col_actual]] else "",
          Forecast = if (!is.na(col_forecast)) df[[col_forecast]] else "",
          Previous = if (!is.na(col_previous)) df[[col_previous]] else "",
          Impact   = if (!is.na(col_impact)) df[[col_impact]] else "",
          stringsAsFactors = FALSE
        )
        datatable(display, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE)
      }
    })
    
    session$onSessionEnded(function() {})
  })
}
