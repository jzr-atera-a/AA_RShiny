# ---- module ----------------------------------------------
# id:           programme_add
# name:         Add entry
# icon:         plus
# description:  Add one programme by hand, with real dates and amounts
# packages:     shiny
# -----------------------------------------------------------
# Ported from Funding Programmes modules/add_single, with date inputs, a rolling box and numeric amounts.

programme_add_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card("Programme",
      layout_columns(col_widths = c(6, 6),
        textInput(ns("name"), "Programme name", width = "100%"),
        textInput(ns("funder"), "Funder", width = "100%")),
      layout_columns(col_widths = c(3, 3, 3, 3),
        selectInput(ns("category"), "Category", CATEGORIES),
        textInput(ns("country"), "Country", "United Kingdom"),
        textInput(ns("region"), "City or region", "All"),
        selectInput(ns("stage"), "Stage", STAGES[1:2])),
      textAreaInput(ns("summary"), "Summary", rows = 2, width = "100%"),
      textAreaInput(ns("conditions"), "Conditions (one per line, or separated by ;)", rows = 3, width = "100%"),
      textInput(ns("themes"), "Themes (separated by ;)", width = "100%")),
    card("Money and dates",
      layout_columns(col_widths = c(3, 3, 3, 3),
        numericInput(ns("min"), "Minimum (GBP)", NA, min = 0, step = 1000),
        numericInput(ns("max"), "Maximum (GBP)", NA, min = 0, step = 1000),
        numericInput(ns("rate"), "Funding rate (%)", NA, min = 0, max = 100),
        textInput(ns("amount_text"), "Amount as written", placeholder = "optional")),
      layout_columns(col_widths = c(3, 3, 3, 3),
        textInput(ns("opens"), "Opens (YYYY-MM-DD)", placeholder = "2027-01-05"),
        textInput(ns("closes"), "Closes (YYYY-MM-DD)", placeholder = "2027-02-14"),
        div(class = "align-bottom", checkboxInput(ns("rolling"), "Rolling (no fixed deadline)", FALSE)),
        textInput(ns("deadline_text"), "Deadline note", placeholder = "e.g. 11am UK time"))),
    card("Sources and tips",
      textInput(ns("source_url"), "Source page (URL)", width = "100%"),
      textAreaInput(ns("tips"), "Tips for applying", rows = 2, width = "100%"),
      checkboxInput(ns("checked"), "I checked these details on the funder's page today", FALSE)),
    actionButton(ns("save"), "Save programme", class = "btn-brand", icon = icon("floppy-disk")),
    uiOutput(ns("status")))
}

programme_add_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    output$status <- renderUI(NULL)
    observeEvent(input$save, {
      if (blank(input$name)) return(output$status <- renderUI(note("warn", "Give the programme a name.")))
      d <- function(x) { x <- trimws(x %||% ""); if (!nzchar(x)) return(""); v <- suppressWarnings(as.Date(x, optional = TRUE)); if (is.na(v)) NA else format(v) }
      if (anyNA(c(d(input$opens), d(input$closes)))) return(output$status <- renderUI(note("warn", "Write dates as YYYY-MM-DD, for example 2027-02-14.")))
      n <- function(x) if (length(x) && !is.na(x)) format(x, scientific = FALSE) else ""
      amount <- input$amount_text %|% (if (!is.na(input$max %||% NA)) paste0("GBP ", if (!is.na(input$min %||% NA)) paste0(fmt_num(input$min), " to ") else "up to ", fmt_num(input$max)) else "")
      url <- trimws(input$source_url %||% "")
      raw <- data.frame(programme_name = trimws(input$name), funder = input$funder, category = input$category,
        country = input$country, city_region = input$region, summary = input$summary,
        conditions = gsub("\n+", "; ", trimws(input$conditions %||% "")), themes = input$themes,
        amount_text = amount, min_gbp = n(input$min), max_gbp = n(input$max), funding_rate_pct = n(input$rate),
        opens_date = d(input$opens), closes_date = if (isTRUE(input$rolling)) "" else d(input$closes),
        deadline_text = if (isTRUE(input$rolling)) paste("Rolling", input$deadline_text) else input$deadline_text,
        rolling = if (isTRUE(input$rolling)) "TRUE" else "FALSE", recommendations = input$tips,
        verified_urls = url, source_url = url,
        verified_at = if (isTRUE(input$checked)) now_ts() else "", verified_by = if (isTRUE(input$checked)) ctx$user() else "",
        stage = input$stage, stringsAsFactors = FALSE)
      r <- add_programmes(map_programme_columns(raw, source = "Added by hand"), ctx$user())
      ctx$bump()
      output$status <- renderUI(if (r$added) note("ok", "Saved. It is now on the Home board.")
                                else note("warn", "A programme with this funder and name is already in the list, so nothing was added."))
      if (r$added) for (f in c("name", "summary", "conditions", "themes", "amount_text", "source_url", "tips", "deadline_text"))
        updateTextInput(session, f, value = "")
    })
  })
}
