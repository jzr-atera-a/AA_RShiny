# modules/econ_trend_summary.R
#
# "Daily/Weekly Trend Summary" — generates a Claude-written summary of key
# economic-calendar trends for the previous week and current week (relative
# to a chosen query date), mapped to four asset classes: Commodities, Forex,
# Crypto, Tech Equity. Claude runs with the web_search tool enabled (see
# ApiManager$call_claude) so events/dates/figures come from real,
# searched sources rather than being generated from training data.
#
# Output is parsed into the row-per-(event, asset) shape matching the
# BigQuery schema in R/utils_econ_calendar_api.R, and stashed on the shared
# api_manager (last_query_id / last_raw_response / last_parsed_df) so the
# Parse & Export tab can review and commit it without re-generating.

# ══════════════════════════════════════════════════════════════════════════
# PROMPT
# ══════════════════════════════════════════════════════════════════════════

etc_build_prompt <- function(query_date) {
  query_date <- as.Date(query_date)
  cur_start  <- query_date - as.integer(format(query_date, "%u")) + 1   # Monday of current week
  cur_end    <- cur_start + 6
  prev_start <- cur_start - 7
  prev_end   <- cur_start - 1

  paste0(
    "You are a financial markets analyst. Using web search, find the REAL, high- and medium-importance ",
    "scheduled or already-released economic calendar events for two periods:\n",
    "  PREVIOUS WEEK: ", prev_start, " to ", prev_end, "\n",
    "  CURRENT WEEK:  ", cur_start, " to ", cur_end, " (today is ", query_date, ")\n\n",
    "Search reputable sources only (e.g. Trading Economics, ForexFactory, official releases such as the ",
    "US Bureau of Labor Statistics, Federal Reserve, ECB, Bank of England, ONS, OPEC). Do not invent an ",
    "event, date, or figure you cannot verify via search.\n\n",
    "For each week, identify the 3-5 MAIN events (the ones that genuinely moved or are expected to move ",
    "markets) and, where relevant, 1-2 CONTEXT events that help explain or forecast a main event (e.g. a ",
    "prior week's ADP print as context for the current week's Non-Farm Payrolls).\n\n",
    "For EVERY event (main or context), assess its actual or likely impact on all FOUR of these asset ",
    "classes, naming ONE specific, real, liquid asset per class: Commodities (e.g. Gold, Brent Crude, ",
    "Copper), Forex (e.g. EUR/USD, GBP/USD, DXY), Crypto (e.g. Bitcoin, Ethereum), Tech Equity (e.g. ",
    "Nasdaq 100, a specific major tech stock). If an event genuinely has no material impact on a class, ",
    "you may write 'Neutral / no material impact' rather than forcing a reaction.\n\n",
    "Output STRICTLY in this exact machine-parseable format, nothing else before, between, or after ",
    "blocks (no preamble, no markdown, no commentary):\n\n",
    "EVENT|||<YYYY-MM-DD>|||<event name>|||<High|Medium|Low>|||<MAIN|CONTEXT>|||<exact event name of the MAIN event this links to, or NONE if this row IS a MAIN event>|||<one to two sentence description of what happened or is expected>\n",
    "ASSET|||<Commodities|Forex|Crypto|Tech Equity>|||<specific asset name>|||<Bullish|Bearish|Neutral|Mixed>|||<one sentence rationale>\n",
    "ASSET|||...(repeat for all 4 asset classes)\n",
    "---END EVENT---\n\n",
    "Repeat the EVENT/ASSET/---END EVENT--- block for every event, previous week first, then current week."
  )
}

# ══════════════════════════════════════════════════════════════════════════
# PARSER — turns Claude's delimited text into the BigQuery row shape
# ══════════════════════════════════════════════════════════════════════════

etc_parse_response <- function(raw_text, query_date) {
  query_id  <- uuid_like()
  blocks    <- strsplit(raw_text, "---END EVENT---", fixed = TRUE)[[1]]
  rows      <- list()
  event_name_to_id <- list()

  # First pass: register every MAIN event's id by name (so CONTEXT rows can
  # resolve linked_to_event_id even if they appear before their MAIN event
  # in a slightly reordered response).
  for (blk in blocks) {
    lines <- strsplit(trimws(blk), "\n")[[1]]
    ev_line <- lines[grepl("^EVENT\\|\\|\\|", lines)]
    if (length(ev_line) == 0) next
    parts <- strsplit(ev_line[1], "\\|\\|\\|")[[1]]
    if (length(parts) < 7) next
    role <- trimws(parts[5])
    name <- trimws(parts[3])
    if (toupper(role) == "MAIN") event_name_to_id[[name]] <- uuid_like()
  }

  for (blk in blocks) {
    lines <- strsplit(trimws(blk), "\n")[[1]]
    lines <- lines[trimws(lines) != ""]
    if (length(lines) == 0) next

    ev_line <- lines[grepl("^EVENT\\|\\|\\|", lines)]
    if (length(ev_line) == 0) next
    ep <- strsplit(ev_line[1], "\\|\\|\\|")[[1]]
    if (length(ep) < 7) next

    event_date  <- suppressWarnings(as.character(as.Date(trimws(ep[2]))))
    event_name  <- trimws(ep[3])
    importance  <- trimws(ep[4])
    role        <- toupper(trimws(ep[5]))
    linked_name <- trimws(ep[6])
    description <- trimws(paste(ep[7:length(ep)], collapse = "|||"))

    event_id <- if (!is.null(event_name_to_id[[event_name]])) event_name_to_id[[event_name]] else uuid_like()
    linked_to_event_id <- NA_character_
    if (role == "CONTEXT" && toupper(linked_name) != "NONE" && !is.null(event_name_to_id[[linked_name]])) {
      linked_to_event_id <- event_name_to_id[[linked_name]]
    }

    asset_lines <- lines[grepl("^ASSET\\|\\|\\|", lines)]
    if (length(asset_lines) == 0) next

    for (al in asset_lines) {
      ap <- strsplit(al, "\\|\\|\\|")[[1]]
      if (length(ap) < 5) next
      rows[[length(rows) + 1]] <- data.frame(
        row_id             = uuid_like(),
        query_id           = query_id,
        query_date         = as.character(query_date),
        query_timestamp    = format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC"),
        event_id           = event_id,
        event_date         = event_date,
        event_name         = event_name,
        event_description  = description,
        event_importance   = importance,
        event_role         = role,
        linked_to_event_id = linked_to_event_id,
        asset_class        = trimws(ap[2]),
        specific_asset      = trimws(ap[3]),
        impact_direction    = trimws(ap[4]),
        impact_rationale    = trimws(paste(ap[5:length(ap)], collapse = "|||")),
        source              = "Claude (web_search: Trading Economics / official releases)",
        stringsAsFactors    = FALSE
      )
    }
  }

  if (length(rows) == 0) return(data.frame())
  out <- do.call(rbind, rows)
  out$query_id <- query_id
  out
}

uuid_like <- function() {
  paste0(format(Sys.time(), "%Y%m%d%H%M%S"), "-", paste(sample(c(letters, 0:9), 8, replace = TRUE), collapse = ""))
}

# ══════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════

econ_trend_summary_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ua_intro("Economic Calendars", "Daily/Weekly Trend Summary", "\u2014", "\u2014",
             "A Claude-generated summary of the key economic-calendar trends for the previous week and current week, mapped to Commodities, Forex, Crypto, and Tech Equity."),

    fluidRow(
      box(title = "Generate", status = "primary", solidHeader = TRUE, width = 4,
          dateInput(ns("queryDate"), "Query date (defaults to today):", value = Sys.Date()),
          actionButton(ns("generate"), "Generate Summary", icon = icon("bolt"), class = "btn-primary", width = "100%"),
          tags$p("Uses web search \u2014 events, dates and figures come from real sources, not generated from training data.",
                 style = "font-size:11px; color:#888; margin-top:8px;"),
          uiOutput(ns("genStatus"))
      ),
      box(title = "What this does", status = "info", solidHeader = TRUE, width = 8,
          tags$p("For the chosen date's current week and the week before it, Claude searches reputable sources (Trading Economics, ForexFactory, official releases) for the main market-moving events, plus any relevant context events, and assesses the impact on one specific asset per class."),
          tags$p("The result is parsed into rows below (one row per event/asset combination). Nothing is written to BigQuery from this tab \u2014 review it here, then commit it on the Parse & Export to BigQuery tab.")
      )
    ),

    fluidRow(
      box(title = "Parsed Preview", status = "success", solidHeader = TRUE, width = 12,
          withSpinner(DT::dataTableOutput(ns("previewTable")))
      )
    )
  )
}

econ_trend_summary_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$generate, {
      if (!isTRUE(api_manager$claude_authenticated)) {
        output$genStatus <- renderUI(tags$div(style="color:#c0392b; margin-top:8px;",
          "Configure Claude API credentials on the API Configuration \u2192 Claude API tab first."))
        return()
      }

      output$genStatus <- renderUI(tags$div(style="color:#2980b9; margin-top:8px;", icon("spinner", class="fa-spin"), " Generating..."))

      tryCatch({
        prompt <- etc_build_prompt(input$queryDate)
        raw <- api_manager$call_claude(prompt, enable_web_search = TRUE)
        parsed <- etc_parse_response(raw, input$queryDate)

        api_manager$last_query_id     <- if (nrow(parsed) > 0) parsed$query_id[1] else NULL
        api_manager$last_query_date   <- as.character(input$queryDate)
        api_manager$last_raw_response <- raw
        api_manager$last_parsed_df    <- parsed

        output$previewTable <- DT::renderDataTable({
          DT::datatable(parsed, options = list(scrollX = TRUE, pageLength = 15), rownames = FALSE)
        })

        if (nrow(parsed) == 0) {
          output$genStatus <- renderUI(tags$div(style="color:#e67e22; margin-top:8px;",
            "Generated, but no rows could be parsed \u2014 check the response format. Try again or widen the date."))
        } else {
          output$genStatus <- renderUI(tags$div(style="color:#27ae60; margin-top:8px;",
            icon("check-circle"), sprintf(" %d row(s) ready \u2014 go to Parse & Export to BigQuery to commit.", nrow(parsed))))
        }
      }, error = function(e) {
        output$genStatus <- renderUI(tags$div(style="color:#c0392b; margin-top:8px;", "Failed: ", e$message))
      })
    })

    output$genStatus <- renderUI(tags$div())
    output$previewTable <- DT::renderDataTable(DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE))
  })
}
