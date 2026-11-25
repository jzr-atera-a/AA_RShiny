# ---- page ------------------------------------------------------------
# id:          trends
# tab label:   Trends & Forecast
# main group:  Overview & Monitoring   (sidebar; see modules/_module_registry.yml)
# description: longer-run trend, unusual days and a forward projection
# functions:   trends_ui(id), trends_server(id, ...)
# --------------------------------------------------------------------

trends_ui <- function(id) {
  ns <- NS(id)
  fm <- c("sessions", "totalUsers", "screenPageViews", "keyEvents")
  tagList(
    card(NULL,
      fluidRow(
        column(4, selectInput(ns("metric"), "Metric", choices = stats::setNames(fm, metric_label(fm)))),
        column(4, selectInput(ns("horizon"), "Project forward", selected = "30",
                              choices = c("14 days" = "14", "30 days" = "30", "60 days" = "60", "90 days" = "90"))),
        column(4, selectInput(ns("sens"), "Unusual-day sensitivity", selected = "3.5",
                              choices = c("High (more alerts)" = "2.5", "Normal" = "3.5", "Low (only extremes)" = "5")))
      )
    ),
    uiOutput(ns("kpis")),
    card("History, 7-day average and projection",
         sub = "Uses at least the last 180 days. The shaded band is the range the projection should fall in 4 times out of 5.",
         plotlyOutput(ns("chart"), height = "380px")),
    fluidRow(
      column(5, card("Typical week", sub = "Average per weekday", plotlyOutput(ns("weekday"), height = "280px"))),
      column(7, card("Unusual days", sub = "Days far above or below what that weekday normally gets",
                     right = dl_link(ns("dl_anom")), DT::DTOutput(ns("anomalies"))))
    ),
    card("Month by month", right = dl_link(ns("dl_months")), DT::DTOutput(ns("months"))),
    note_box(icon("info-circle"), " The projection is a simple model (recent trend plus weekday pattern). ",
             "It cannot know about campaigns, holidays or site changes - treat it as a baseline, not a promise.")
  )
}

trends_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    fm <- c("sessions", "totalUsers", "screenPageViews", "keyEvents")
    hist <- reactive({
      p <- ctx$period()
      start <- min(p$start, p$end - 179)
      complete_days(ctx$q("date", fm, range = c(start, p$end)), start, p$end, fm)
    })
    metric <- reactive(input$metric %||% "sessions")
    fc <- reactive({
      d <- hist()
      forecast_daily(d$date, d[[metric()]], h = as.integer(input$horizon %||% "30"))
    })
    anom <- reactive({
      d <- hist()
      detect_anomalies(d$date, d[[metric()]], z_cut = as.numeric(input$sens %||% "3.5"))
    })

    output$kpis <- renderUI({
      d <- hist(); f <- fc(); a <- anom(); y <- d[[metric()]]; n <- length(y)
      recent <- sum(utils::tail(y, 28)); before <- if (n >= 56) sum(y[(n - 55):(n - 28)]) else NA
      wd <- tapply(y, format(d$date, "%A"), mean)
      kpi_row(
        kpi_tile(sprintf("Projected next %d days", nrow(f)), fmt_int(sum(f$forecast)),
                 sub = sprintf("likely %s to %s", fmt_int(sum(f$lower)), fmt_int(sum(f$upper)))),
        kpi_tile("Last 28 days", fmt_int(recent), pct_change(recent, before), sub = "vs the 28 days before"),
        kpi_tile("Daily average", fmt_int(mean(utils::tail(y, 28))), sub = "over the last 28 days"),
        kpi_tile("Busiest weekday", names(wd)[which.max(wd)], sub = paste(fmt_int(max(wd)), "on average")),
        kpi_tile("Unusual days", fmt_int(sum(a$flag)), sub = sprintf("in the last %d days", n))
      )
    })

    output$chart <- renderPlotly({
      d <- hist(); f <- fc(); a <- anom(); m <- metric(); y <- d[[m]]
      validate(need(sum(y) > 0, "No data to chart yet."))
      fl <- a[a$flag, , drop = FALSE]
      p <- plot_ly()
      p <- add_trace(p, x = f$date, y = f$upper, type = "scatter", mode = "lines",
                     line = list(width = 0), showlegend = FALSE, hoverinfo = "skip")
      p <- add_trace(p, x = f$date, y = f$lower, type = "scatter", mode = "lines", fill = "tonexty",
                     fillcolor = "rgba(57,135,229,0.18)", line = list(width = 0),
                     name = "Likely range", hoverinfo = "skip")
      p <- add_trace(p, x = d$date, y = y, type = "scatter", mode = "lines", name = "Daily",
                     line = list(color = "#9fb4bd", width = 1),
                     hovertemplate = "%{y:,.0f}<extra>Daily</extra>")
      p <- add_trace(p, x = d$date, y = ma7(y), type = "scatter", mode = "lines", name = "7-day average",
                     line = list(color = PAL[1], width = 2),
                     hovertemplate = "%{y:,.0f}<extra>7-day average</extra>")
      p <- add_trace(p, x = f$date, y = f$forecast, type = "scatter", mode = "lines", name = "Projection",
                     line = list(color = PAL[1], width = 2, dash = "dash"),
                     hovertemplate = "%{y:,.0f}<extra>Projection</extra>")
      if (nrow(fl) > 0) {
        p <- add_trace(p, x = fl$date, y = fl$actual, type = "scatter", mode = "markers", name = "Unusual day",
                       marker = list(color = PAL[2], size = 10, line = list(color = SURFACE, width = 2)),
                       hovertemplate = "%{y:,.0f}<extra>Unusual day</extra>")
      }
      ga_layout(p, ytitle = metric_label(m), legend = TRUE)
    })

    output$weekday <- renderPlotly({
      d <- hist(); y <- d[[metric()]]
      validate(need(sum(y) > 0, "No data yet."))
      names_wd <- c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
      idx <- c(1:6, 0)
      avg <- vapply(idx, function(k) mean(y[as.POSIXlt(d$date)$wday == k]), numeric(1))
      avg[!is.finite(avg)] <- 0
      p <- plot_ly(x = names_wd, y = avg, type = "bar", marker = list(color = PAL[1]),
                   hovertemplate = "%{x}: %{y:,.0f}<extra></extra>")
      p <- ga_layout(p, hovermode = "closest")
      layout(p, xaxis = list(categoryorder = "array", categoryarray = names_wd), bargap = 0.35)
    })

    anom_table <- reactive({
      a <- anom(); fl <- a[a$flag, , drop = FALSE]
      if (nrow(fl) == 0) return(NULL)
      out <- data.frame(date = format(fl$date, "%a %d %b %Y"), actual = fl$actual, expected = fl$expected,
                        diff = fl$actual / pmax(1, fl$expected) - 1, stringsAsFactors = FALSE)
      out[rev(seq_len(nrow(out))), , drop = FALSE]
    })
    output$anomalies <- DT::renderDT({
      x <- anom_table()
      validate(need(!is.null(x), "No unusual days found at this sensitivity."))
      ga_table(x, labels = c(date = "Date", actual = "Actual", expected = "Expected", diff = "Difference"),
               int = c("actual", "expected"), chg = "diff", page = 6, search = FALSE)
    })
    output$dl_anom <- csv_handler(anom_table, "unusual_days")

    months <- reactive({
      d <- hist(); key <- format(d$date, "%Y-%m")
      out <- data.frame(month = sort(unique(key)), stringsAsFactors = FALSE)
      for (m in fm) out[[m]] <- as.numeric(tapply(d[[m]], key, sum)[out$month])
      out$days <- as.numeric(table(key)[out$month])
      out$per_day <- out[[metric()]] / pmax(1, out$days)
      out$chg <- c(NA, out$per_day[-1] / pmax(1e-9, out$per_day[-nrow(out)]) - 1)
      out[rev(seq_len(nrow(out))), , drop = FALSE]
    })
    output$months <- DT::renderDT({
      x <- months()
      ga_table(x, labels = c(month = "Month", sessions = "Sessions", totalUsers = "Users (daily sum)",
                             screenPageViews = "Page views", keyEvents = "Key events", days = "Days covered",
                             per_day = paste(metric_label(metric()), "per day"), chg = "Per-day change"),
               int = c(fm, "days"), dec = "per_day", chg = "chg", page = 12, search = FALSE)
    })
    output$dl_months <- csv_handler(months, "months")
  })
}
