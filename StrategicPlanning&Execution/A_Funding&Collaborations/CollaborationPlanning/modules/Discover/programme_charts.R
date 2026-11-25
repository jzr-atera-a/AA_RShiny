# ---- module ----------------------------------------------
# id:           programme_charts
# name:         Charts and calendar
# icon:         chart-column
# description:  Counts and charts of programmes, a deadline calendar, and an .ics file of deadlines
# packages:     shiny, plotly
# -----------------------------------------------------------
# Ported from Funding Programmes modules/visualizations, plus the deadline calendar.

programme_charts_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL,
      layout_columns(col_widths = c(3, 3, 3, 3),
        selectInput(ns("cat"), "Category", "All"),
        selectInput(ns("country"), "Country", "All"),
        selectInput(ns("region"), "City or region", "All"),
        div(checkboxInput(ns("use_dates"), "Only programmes closing between", FALSE),
            dateRangeInput(ns("dates"), NULL, start = Sys.Date(), end = Sys.Date() + 180)))),
    uiOutput(ns("counters")),
    layout_columns(col_widths = c(6, 6),
      card("Programmes by category", plotlyOutput(ns("by_cat"), height = "300px")),
      card("Programmes by stage", plotlyOutput(ns("by_stage"), height = "300px"))),
    card("Deadline calendar",
      p(class = "small muted", "Programmes at Qualify or later, by closing date. Rolling programmes are listed when no date range is set. ",
        "The .ics file adds each deadline to your calendar with a reminder 7 days before."),
      downloadButton(ns("ics"), "Download deadlines (.ics)", class = "btn-ghost sm"),
      uiOutput(ns("calendar"))))
}

programme_charts_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    observe({
      p <- ctx$programmes()
      for (f in list(c("cat", "category"), c("country", "country"), c("region", "city_region")))
        updateSelectInput(session, f[1], choices = c("All", sort(unique(p[[f[2]]][nzchar(p[[f[2]]])]))), selected = isolate(input[[f[1]]]))
    })
    date_set <- reactive(isTRUE(input$use_dates) && length(input$dates) == 2)
    filtered <- reactive({
      p <- ctx$programmes()
      if (!identical(input$cat, "All")) p <- p[p$category == input$cat, , drop = FALSE]
      if (!identical(input$country, "All")) p <- p[p$country == input$country, , drop = FALSE]
      if (!identical(input$region, "All")) p <- p[p$city_region == input$region, , drop = FALSE]
      if (date_set()) {
        d <- suppressWarnings(as.Date(p$closes_date))
        lo <- if (is.na(input$dates[1])) as.Date("1900-01-01") else input$dates[1]
        hi <- if (is.na(input$dates[2])) as.Date("2999-12-31") else input$dates[2]
        p <- p[!is.na(d) & d >= lo & d <= hi, , drop = FALSE]
      }
      p
    })
    output$counters <- renderUI({
      p <- filtered(); d <- suppressWarnings(as.Date(p$closes_date))
      stat <- function(n, l) div(class = "stat", div(class = "stat-n", n), div(class = "stat-l", l))
      div(class = "stat-row",
          stat(nrow(p), "programmes"),
          stat(sum(!is.na(d) & d >= Sys.Date() & d <= Sys.Date() + 30), "close in the next 30 days"),
          stat(sum(is_true_vec(p$rolling)), "rolling"),
          stat(sum(!nzchar(p$verified_at)), "not checked at source"))
    })
    bar <- function(x, lab, sorted = TRUE) {
      t <- table(x); if (sorted) t <- sort(t, decreasing = TRUE)
      plot_ly(x = names(t), y = as.integer(t), type = "bar", marker = list(color = "#1a9aa8")) |>
        layout(xaxis = list(title = "", categoryorder = "array", categoryarray = names(t)), yaxis = list(title = lab), margin = list(b = 80)) |> config(displayModeBar = FALSE)
    }
    output$by_cat <- renderPlotly({ p <- filtered(); req(nrow(p) > 0); bar(ifelse(nzchar(p$category), p$category, "(none)"), "Programmes") })
    output$by_stage <- renderPlotly({ p <- filtered(); req(nrow(p) > 0); bar(factor(p$stage, levels = STAGES), "Programmes", sorted = FALSE) })

    deadlines <- reactive({
      p <- filtered(); p <- p[p$stage %in% STAGES[-1], , drop = FALSE]
      p$d <- suppressWarnings(as.Date(p$closes_date))
      p
    })
    output$calendar <- renderUI({
      p <- deadlines()
      dated <- p[!is.na(p$d), , drop = FALSE]; dated <- dated[order(dated$d), , drop = FALSE]
      rolling <- if (!date_set()) p[is.na(p$d) & is_true_vec(p$rolling), , drop = FALSE] else p[0, ]
      if (!nrow(dated) && !nrow(rolling)) return(empty_note("No deadlines yet. Programmes appear here once they reach Qualify."))
      months <- unique(format(dated$d, "%Y-%m"))
      tagList(
        lapply(months, function(m) {
          r <- dated[format(dated$d, "%Y-%m") == m, , drop = FALSE]
          div(class = "cal-month", h5(format(as.Date(paste0(m, "-01")), "%B %Y")),
              lapply(seq_len(nrow(r)), function(i) div(class = "cal-row",
                span(class = "cal-d", format(r$d[i], "%a %d %b")),
                span(tags$b(r$programme_name[i]), " ", span(class = "muted", r$funder[i], "-", r$stage[i]),
                     if (r$d[i] < Sys.Date()) span(class = "pill pill-off", "closed")))))
        }),
        if (nrow(rolling)) div(class = "cal-month", h5("Rolling"),
          lapply(seq_len(nrow(rolling)), function(i) div(class = "cal-row", span(class = "cal-d", "rolling"),
            span(tags$b(rolling$programme_name[i]), " ", span(class = "muted", rolling$funder[i], "-", rolling$stage[i]))))))
    })
    output$ics <- downloadHandler(
      filename = function() paste0("programme_deadlines_", format(Sys.Date(), "%Y%m%d"), ".ics"),
      content = function(file) {
        p <- deadlines(); p <- p[!is.na(p$d), , drop = FALSE]
        if (!nrow(p)) return(writeLines(ics_calendar(data.frame(uid = character(0)), "Programme deadlines"), file, sep = ""))
        ev <- data.frame(uid = paste0(p$programme_id, "@collaboration-planning"),
                         summary = paste("Deadline:", p$programme_name), date = format(p$d),
                         description = paste0(p$funder, ". Stage: ", p$stage, ". ", p$source_url), alarm_days = 7,
                         stringsAsFactors = FALSE)
        writeLines(ics_calendar(ev, "Programme deadlines"), file, sep = "", useBytes = TRUE)
      })
  })
}
