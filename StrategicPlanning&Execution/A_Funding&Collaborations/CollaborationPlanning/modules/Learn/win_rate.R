# ---- module ----------------------------------------------
# id:           win_rate
# name:         Win rate
# icon:         chart-line
# description:  Win rate by funder, category and theme, and the average fit score of won and lost bids
# packages:     shiny, plotly, DT
# -----------------------------------------------------------
# Use the fit score comparison to tune the weights in Admin > General settings.

win_rate_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("stats")),
    layout_columns(col_widths = c(6, 6),
      card("Win rate by", selectInput(ns("by"), NULL, c("Funder" = "funder", "Category" = "category", "Theme" = "theme")),
           plotlyOutput(ns("chart"), height = "320px")),
      card("Fit score: won against lost", plotlyOutput(ns("fit"), height = "320px"), uiOutput(ns("fit_note")))),
    card("Table", DTOutput(ns("table"))))
}

win_rate_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    base <- reactive({
      o <- latest_by(ctx$table("outcomes")(), "programme_id", "recorded_at"); o <- o[o$result %in% c("won", "lost"), , drop = FALSE]
      p <- ctx$programmes(); o <- o[o$programme_id %in% p$programme_id, , drop = FALSE]
      m <- match(o$programme_id, p$programme_id)
      o$funder <- p$funder[m] %|% "(none)"; o$category <- p$category[m]; o$themes <- p$themes[m]
      f <- ctx$status()$fit; o$fit <- f$fit[match(o$programme_id, f$programme_id)]
      o
    })
    grouped <- reactive({
      o <- base(); if (!nrow(o)) return(NULL)
      if (input$by == "theme") {
        o <- do.call(rbind, lapply(seq_len(nrow(o)), function(i) { th <- split_list(gsub(",", ";", o$themes[i])); if (!length(th)) th <- "(none)"
          data.frame(key = tolower(th), result = o$result[i]) }))
      } else o$key <- ifelse(nzchar(o[[input$by]]), o[[input$by]], "(none)")
      k <- unique(o$key)
      d <- data.frame(Group = k, Bids = vapply(k, function(x) sum(o$key == x), 1L), Won = vapply(k, function(x) sum(o$key == x & o$result == "won"), 1L), row.names = NULL)
      d$`Win rate %` <- round(100 * d$Won / d$Bids); d[order(-d$Bids), , drop = FALSE]
    })
    output$stats <- renderUI({
      o <- base(); all <- latest_by(ctx$table("outcomes")(), "programme_id", "recorded_at")
      if (!nrow(o)) return(empty_note("No won or lost bids recorded yet. Record results in Outcomes and lessons."))
      div(class = "stat-row",
        div(class = "stat", div(class = "stat-n", nrow(o)), div(class = "stat-l", "bids decided by funders")),
        div(class = "stat", div(class = "stat-n", sum(o$result == "won")), div(class = "stat-l", "won")),
        div(class = "stat", div(class = "stat-n", paste0(round(100 * mean(o$result == "won")), "%")), div(class = "stat-l", "win rate")),
        div(class = "stat", div(class = "stat-n", sum(all$result == "not pursued")), div(class = "stat-l", "not pursued")))
    })
    output$chart <- renderPlotly({ d <- grouped(); req(d); d <- utils::head(d, 15)
      plot_ly(d, x = ~Group, y = ~`Win rate %`, type = "bar", text = ~paste(Won, "of", Bids), marker = list(color = "#1a9aa8")) |>
        layout(xaxis = list(title = "", categoryorder = "array", categoryarray = d$Group), yaxis = list(title = "Win rate (%)", range = c(0, 100))) |>
        config(displayModeBar = FALSE) })
    output$fit <- renderPlotly({ o <- base(); o <- o[!is.na(o$fit), , drop = FALSE]; req(nrow(o) > 0)
      plot_ly(o, x = ~result, y = ~fit, type = "box", boxpoints = "all", jitter = 0.3, marker = list(color = "#0f4a5c"), line = list(color = "#1a9aa8")) |>
        layout(xaxis = list(title = ""), yaxis = list(title = "Fit score", range = c(0, 100))) |> config(displayModeBar = FALSE) })
    output$fit_note <- renderUI({ o <- base(); o <- o[!is.na(o$fit), , drop = FALSE]; req(nrow(o) >= 2)
      w <- mean(o$fit[o$result == "won"]); l <- mean(o$fit[o$result == "lost"])
      if (is.na(w) || is.na(l)) return(NULL)
      note(if (w > l) "ok" else "warn", sprintf("Average fit: won %d, lost %d. ", round(w), round(l)),
           if (w > l) "The fit score is pointing the right way." else "The fit score is not telling won from lost bids yet: consider changing the weights in Admin > General settings.") })
    output$table <- renderDT({ d <- grouped(); req(d); datatable(d, rownames = FALSE, options = list(dom = "tip", pageLength = 15)) })
  })
}
