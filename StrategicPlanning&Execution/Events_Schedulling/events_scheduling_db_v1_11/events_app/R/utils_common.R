# R/utils_common.R
# Shared Utility Functions — Events Scheduling DB
# ================================================

# Safe SQL escape: BigQuery GoogleSQL uses backslash-escape, not doubled-quote.
safe_sql_escape <- function(x) {
  gsub("'", "\\'", x, fixed = TRUE)
}

# Returns TRUE if value is non-blank, non-NA, non-"N/A".
has_real_value <- function(x) {
  if (is.na(x)) return(FALSE)
  trimmed <- trimws(as.character(x))
  if (nchar(trimmed) == 0) return(FALSE)
  if (tolower(trimmed) %in% c("n/a", "na")) return(FALSE)
  TRUE
}

# ============================================================
# TEXT FORMAT CONTRACT
# ============================================================
# Header (shared across all events in one scan):
#   [city]: London              ← blank = global / top-N mode
#   [country]: United Kingdom
#   [scan_date]: 2026-07-01
#
# Per-event block:
#   [event_name]: ...
#   [organiser]: ...
#   [category]: Music
#   [subcategory]: Jazz
#   [event_date]: 2026-07-15
#   [event_time]: 19:30
#   [venue_name]: Ronnie Scott's
#   [address]: 47 Frith Street, Soho, London W1D 4HT
#   [latitude]: 51.5132
#   [longitude]: -0.1314
#   [description]: ...
#   [ticket_url]: https://...
#   [price_range]: £25–£45
#   [source_url]: https://...
#   [extra_info]: ...

parse_events_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]

  # Extract header fields
  city      <- extract_event_field(lines, "city")
  country   <- extract_event_field(lines, "country")
  scan_date <- extract_event_field(lines, "scan_date")

  if (is.null(city))      city      <- ""
  if (is.null(country))   country   <- ""
  if (is.null(scan_date)) scan_date <- as.character(Sys.Date())

  # Parse entries
  entries  <- list()
  curr     <- list()
  in_event <- FALSE

  for (line in lines) {
    line <- trimws(line)

    if (grepl("^\\[event_name\\]:", line, ignore.case = TRUE)) {
      if (in_event && !is.null(curr$event_name)) {
        entries[[length(entries) + 1]] <- curr
      }
      curr     <- list()
      in_event <- TRUE
      curr$event_name <- trimws(sub("^\\[event_name\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (in_event) {
      curr <- parse_event_line(line, curr)
    }
  }
  if (in_event && !is.null(curr$event_name)) {
    entries[[length(entries) + 1]] <- curr
  }

  if (length(entries) == 0) stop("No valid event entries found in text")

  df <- do.call(rbind, lapply(entries, function(e) {
    data.frame(
      event_name  = e$event_name  %||% "",
      organiser   = e$organiser   %||% "N/A",
      city        = if (nchar(trimws(city)) > 0) city else e$city %||% "",
      country     = if (nchar(trimws(country)) > 0) country else e$country %||% "",
      category    = e$category    %||% "",
      subcategory = e$subcategory %||% "",
      event_date  = e$event_date  %||% "",
      event_time  = e$event_time  %||% "TBD",
      venue_name  = e$venue_name  %||% "",
      address     = e$address     %||% "",
      latitude    = e$latitude    %||% "N/A",
      longitude   = e$longitude   %||% "N/A",
      description = e$description %||% "",
      ticket_url  = e$ticket_url  %||% "N/A",
      price_range = e$price_range %||% "N/A",
      source_url  = e$source_url  %||% "N/A",
      scan_date   = scan_date,
      extra_info  = e$extra_info  %||% "",
      stringsAsFactors = FALSE
    )
  }))

  df
}

parse_event_line <- function(line, curr) {
  fields <- c("organiser", "category", "subcategory", "city", "country",
              "event_date", "event_time", "venue_name", "address",
              "latitude", "longitude", "description",
              "ticket_url", "price_range", "source_url", "extra_info")
  for (f in fields) {
    if (grepl(paste0("^\\[", f, "\\]:"), line, ignore.case = TRUE)) {
      curr[[f]] <- trimws(sub(paste0("^\\[", f, "\\]:\\s*"), "", line, ignore.case = TRUE))
      return(curr)
    }
  }
  curr
}

extract_event_field <- function(lines, field_name) {
  pat <- paste0("^\\[", field_name, "\\]:\\s*(.+)$")
  for (line in lines) {
    if (grepl(pat, line, ignore.case = TRUE, perl = TRUE)) {
      return(trimws(sub(paste0("^\\[", field_name, "\\]:\\s*"), "", line, ignore.case = TRUE)))
    }
  }
  NULL
}

# Force-overwrite city/country/scan_date header with known-correct values
overwrite_events_header <- function(text, city, country, scan_date) {
  lines     <- strsplit(text, "\n")[[1]]
  event_idx <- which(grepl("^\\s*\\[event_name\\]:", lines, ignore.case = TRUE))[1]
  if (is.na(event_idx)) return(text)
  remaining <- lines[event_idx:length(lines)]
  header    <- c(
    paste0("[city]: ",      city),
    paste0("[country]: ",   country),
    paste0("[scan_date]: ", scan_date),
    ""
  )
  paste(c(header, remaining), collapse = "\n")
}

# ============================================================
# CATEGORY / SUBCATEGORY — mirrors Genre/Topic pattern exactly
# ============================================================
CATEGORY_ADD_NEW_VALUE    <- "__ADD_NEW_CATEGORY__"
SUBCATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_SUBCATEGORY__"

# Shared UI block: Category dropdown + conditional new-category text box,
# Subcategory dropdown + conditional new-subcategory text box.
# Mirrors genre_topic_dropdown_ui() from the books app exactly.
category_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("category_select"), "Category: *",
                choices = c("+ Add New Category" = CATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("category_select"), CATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_category_text"), "New Category Name:",
                placeholder = "e.g., Music")
    ),
    selectInput(ns("subcategory_select"), "Subcategory: *",
                choices = c("+ Add New Subcategory" = SUBCATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("subcategory_select"), SUBCATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_subcategory_text"), "New Subcategory Name:",
                placeholder = "e.g., Jazz")
    )
  )
}

# Wires the Category → Subcategory cascade inside a moduleServer.
# Mirrors setup_genre_topic_cascade() from the books app exactly.
# Returns a reactive() yielding list(category, subcategory).
setup_category_cascade <- function(input, output, session, api_manager) {

  taxonomy <- reactive({
    api_manager$state_trigger()
    if (!api_manager$bq_authenticated) {
      return(data.frame(category = character(), subcategory = character(),
                         stringsAsFactors = FALSE))
    }
    tryCatch(api_manager$bq_get_taxonomy(), error = function(e) {
      data.frame(category = character(), subcategory = character(),
                 stringsAsFactors = FALSE)
    })
  })

  # Populate / refresh Category dropdown whenever taxonomy changes
  observeEvent(taxonomy(), {
    tax     <- taxonomy()
    cats    <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
    choices <- c("+ Add New Category" = CATEGORY_ADD_NEW_VALUE, setNames(cats, cats))
    current  <- isolate(input$category_select)
    selected <- if (!is.null(current) && current %in% choices) current else CATEGORY_ADD_NEW_VALUE
    updateSelectInput(session, "category_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  # Cascade: Subcategory choices depend on selected Category
  observeEvent(input$category_select, {
    tax <- taxonomy()
    if (is.null(input$category_select) || input$category_select == CATEGORY_ADD_NEW_VALUE) {
      updateSelectInput(session, "subcategory_select",
                        choices = c("+ Add New Subcategory" = SUBCATEGORY_ADD_NEW_VALUE))
      return()
    }
    subs <- sort(unique(tax$subcategory[
      tax$category == input$category_select & nchar(trimws(tax$subcategory)) > 0
    ]))
    if (length(subs) == 0) {
      updateSelectInput(session, "subcategory_select",
                        choices = c("+ Add New Subcategory" = SUBCATEGORY_ADD_NEW_VALUE))
    } else {
      updateSelectInput(session, "subcategory_select",
                        choices = c("+ Add New Subcategory" = SUBCATEGORY_ADD_NEW_VALUE,
                                    setNames(subs, subs)))
    }
  }, ignoreInit = TRUE)

  # Resolved final category/subcategory strings (sentinel → typed text)
  reactive({
    category <- if (identical(input$category_select, CATEGORY_ADD_NEW_VALUE)) {
      trimws(input$new_category_text %||% "")
    } else {
      input$category_select %||% ""
    }
    subcategory <- if (identical(input$subcategory_select, SUBCATEGORY_ADD_NEW_VALUE)) {
      trimws(input$new_subcategory_text %||% "")
    } else {
      input$subcategory_select %||% ""
    }
    list(category = category, subcategory = subcategory)
  })
}

# ============================================================
# CLAUDE PROMPT — lean, fast, optional-fields aware
# ============================================================
generate_scan_prompt <- function(city            = "",
                                 country         = "",
                                 date_from       = NULL,
                                 date_to         = NULL,
                                 category        = "",
                                 subcategory     = "",
                                 top_n           = 10,
                                 extra_info      = "",
                                 optional_fields = "core") {

  # Location
  location_str <- if (nchar(trimws(city)) > 0 && nchar(trimws(country)) > 0) {
    paste0(city, ", ", country)
  } else if (nchar(trimws(city)) > 0) {
    city
  } else if (nchar(trimws(country)) > 0) {
    paste0(country, " (most relevant cities)")
  } else {
    "worldwide (most notable events)"
  }

  # Dates
  date_range_days <- if (!is.null(date_from) && !is.null(date_to)) {
    as.integer(as.Date(date_to) - as.Date(date_from))
  } else 365

  date_str <- if (!is.null(date_from) && !is.null(date_to)) {
    if (date_range_days > 90) {
      paste0(date_from, " to ", date_to, " (pick the ", top_n, " most significant)")
    } else {
      paste0(date_from, " to ", date_to)
    }
  } else {
    "next 3 months"
  }

  # Category
  cat_str <- if (nchar(trimws(subcategory)) > 0) {
    paste0(category, " / ", subcategory)
  } else if (nchar(trimws(category)) > 0) {
    category
  } else {
    "any"
  }

  # Optional extra context
  extra_line <- if (nchar(trimws(extra_info)) > 0)
    paste0("\nExtra requirements: ", trimws(extra_info)) else ""

  # Core fields — always required
  core_fields <- paste0(
    "[event_name]: event name\n",
    "[organiser]: name or N/A\n",
    "[category]: Music/Tech/Art/Food/Sports/Family/Business/Health/Film/Comedy/Other\n",
    "[subcategory]: specific type\n",
    "[event_date]: YYYY-MM-DD\n",
    "[event_time]: HH:MM or All Day\n",
    "[venue_name]: name\n",
    "[address]: street address or N/A\n",
    "[description]: 2-3 sentences about the event\n",
    "[price_range]: Free or £10-£25 or N/A\n",
    "[source_url]: URL or N/A"
  )

  # Optional field blocks by selection
  geo_fields     <- "\n[latitude]: decimal degrees or N/A\n[longitude]: decimal degrees or N/A"
  ticket_fields  <- "\n[ticket_url]: URL or N/A\n[extra_info]: brief notes or N/A"

  optional_block <- switch(optional_fields %||% "core",
    "core"        = "",
    "core_geo"    = geo_fields,
    "core_tickets"= ticket_fields,
    "full"        = paste0(geo_fields, ticket_fields),
    ""
  )

  cat("🤖 [Prompt] optional_fields =", optional_fields %||% "core",
      "| optional block:", nchar(optional_block), "chars\n")

  paste0(
    "List ", top_n, " events in ", location_str, " between ", date_str, ".\n",
    "Category: ", cat_str, ".", extra_line, "\n\n",
    "Output ONLY this block format. One blank line between events. No extra text.\n\n",
    "[city]: ", if (nchar(trimws(city)) > 0) city else "Global", "\n",
    "[country]: ", if (nchar(trimws(country)) > 0) country else "Various", "\n",
    "[scan_date]: ", as.character(Sys.Date()), "\n\n",
    core_fields, optional_block
  )
}


`%||%` <- function(x, y) if (is.null(x)) y else x
