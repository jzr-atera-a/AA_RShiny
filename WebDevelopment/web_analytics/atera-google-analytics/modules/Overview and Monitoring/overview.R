# ---- page ------------------------------------------------------------
# id:          overview
# tab label:   Overview
# main group:  Overview & Monitoring   (sidebar; see modules/_module_registry.yml)
# description: headline numbers, trend vs comparison, automatic insights
# functions:   overview_ui(id), overview_server(id, ...)
# --------------------------------------------------------------------

KPI_METS <- c("totalUsers", "newUsers", "sessions", "screenPageViews",
              "engagementRate", "averageSessionDuration", "bounceRate", "keyEvents")
TREND_METS <- c("totalUsers", "sessions", "screenPageViews", "keyEvents", "engagementRate")

overview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(8, card("Traffic over time", sub = "Solid = selected period, dashed = comparison period",
        right = selectInput(ns("metric"), NULL, width = "170px",
                            choices = stats::setNames(TREND_METS, metric_label(TREND_METS))),
        plotlyOutput(ns("trend"), height = "320px"))),
      column(4, card("What changed", right = downloadLink(ns("report"),
          label = tagList(icon("file-alt"), " Summary report"), class = "dl-link"),
        uiOutput(ns("insights"))))
    ),
    fluidRow(
      column(4, card("Sessions by channel", plotlyOutput(ns("channels"), height = "270px"))),
      column(4, card("Most viewed pages", plotlyOutput(ns("pages"), height = "270px"))),
      column(4, card("Sessions by device", plotlyOutput(ns("devices"), height = "270px")))
    ),
    fluidRow(
      column(7, card("Where visitors are", plotlyOutput(ns("map"), height = "340px"))),
      column(5, card("Top countries", right = dl_link(ns("dl_countries")), DT::DTOutput(ns("countries"))))
    )
  )
}

overview_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {

    tot_cur  <- reactive(totals_list(ctx$q(mets = KPI_METS), KPI_METS))
    tot_prev <- reactive({
      d <- ctx$q(mets = KPI_METS, range = "prev")
      if (is.null(d)) NULL else totals_list(d, KPI_METS)
    })
    daily_cur <- reactive({
      p <- ctx$period()
      complete_days(ctx$q("date", TREND_METS), p$start, p$end, TREND_METS)
    })
    daily_prev <- reactive({
      p <- ctx$period()
      d <- ctx$q("date", TREND_METS, range = "prev")
      if (is.null(d)) NULL else complete_days(d, p$cmp_start, p$cmp_end, TREND_METS)
    })
    chan_mets <- c("sessions", "totalUsers", "engagementRate", "keyEvents")
    channels <- reactive({
      with_prev(ctx$q("sessionDefaultChannelGroup", chan_mets),
                ctx$q("sessionDefaultChannelGroup", chan_mets, range = "prev"),
                "sessionDefaultChannelGroup", "sessions")
    })
    pages     <- reactive(ctx$q("pagePath", c("screenPageViews", "totalUsers"), limit = 8))
    devices   <- reactive(ctx$q("deviceCategory", "sessions"))
    countries <- reactive(ctx$q("country", c("totalUsers", "sessions", "engagementRate"), limit = 250))

    insights <- reactive({
      build_insights(tot_cur(), tot_prev(), daily_cur(), channels(), pages(), devices(),
                     compare_label = ctx$period()$compare_label)
    })

    output$kpis <- renderUI({
      cur <- tot_cur(); prev <- tot_prev(); p <- ctx$period()
      sub <- if (is.null(prev)) NULL else paste("vs", p$compare_label)
      do.call(kpi_row, lapply(KPI_METS, function(m) {
        kpi_tile(metric_label(m), fmt_metric(cur[[m]], m),
                 delta = if (is.null(prev)) NULL else pct_change(cur[[m]], prev[[m]]),
                 good_dir = METRICS[[m]]$good, sub = sub)
      }))
    })

    output$trend <- renderPlotly({
      m <- input$metric %||% "totalUsers"
      cur <- daily_cur(); prev <- daily_prev()
      validate(need(nrow(cur) > 0, "No data for this period."))
      is_pct <- METRICS[[m]]$fmt == "pct"
      p <- plot_ly()
      if (!is.null(prev)) {
        n <- min(nrow(cur), nrow(prev))
        p <- add_trace(p, x = cur$date[seq_len(n)], y = prev[[m]][seq_len(n)],
          name = "Comparison", type = "scatter", mode = "lines",
          text = format(prev$date[seq_len(n)], "%d %b %Y"),
          hovertemplate = paste0("%{y:", if (is_pct) ".1%" else ",.0f", "} (%{text})<extra>Comparison</extra>"),
          line = list(color = MUTED, width = 2, dash = "dash"))
      }
      p <- add_trace(p, x = cur$date, y = cur[[m]], name = metric_label(m),
        type = "scatter", mode = "lines", line = list(color = PAL[1], width = 2),
        hovertemplate = paste0("%{y:", if (is_pct) ".1%" else ",.0f", "}<extra>", metric_label(m), "</extra>"))
      p <- ga_layout(p, legend = !is.null(prev))
      if (is_pct) p <- layout(p, yaxis = list(tickformat = ".0%"))
      p
    })

    output$insights <- renderUI(insights_ui(insights()))

    output$channels <- renderPlotly({
      d <- channels(); validate(need(!is.null(d) && nrow(d) > 0, "No channel data."))
      bar_h(d$sessionDefaultChannelGroup, d$sessions)
    })
    output$pages <- renderPlotly({
      d <- pages(); validate(need(!is.null(d) && nrow(d) > 0, "No page data."))
      bar_h(d$pagePath, d$screenPageViews)
    })
    output$devices <- renderPlotly({
      d <- devices(); validate(need(!is.null(d) && nrow(d) > 0, "No device data."))
      bar_h(d$deviceCategory, d$sessions)
    })

    output$map <- renderPlotly({
      d <- countries(); validate(need(!is.null(d) && nrow(d) > 0, "No location data."))
      p <- plot_ly(type = "choropleth", locations = d$country, locationmode = "country names",
        z = d$totalUsers, colorscale = SEQ_SCALE, showscale = FALSE,
        marker = list(line = list(color = SURFACE, width = 0.5)),
        hovertemplate = "%{location}: %{z:,.0f} users<extra></extra>")
      p <- layout(p, paper_bgcolor = "rgba(0,0,0,0)", margin = list(l = 0, r = 0, t = 0, b = 0),
        geo = list(bgcolor = "rgba(0,0,0,0)", showframe = FALSE, showcoastlines = FALSE,
                   showland = TRUE, landcolor = LAND, showcountries = TRUE,
                   countrycolor = "#c9d6d6", projection = list(type = "natural earth")))
      config(p, displayModeBar = FALSE)
    })
    output$countries <- DT::renderDT({
      d <- countries(); validate(need(!is.null(d) && nrow(d) > 0, "No location data."))
      ga_table(d, labels = c(country = "Country", totalUsers = "Users", sessions = "Sessions",
                             engagementRate = "Engagement"),
               int = c("totalUsers", "sessions"), pct = "engagementRate", page = 8, search = FALSE)
    })
    output$dl_countries <- csv_handler(countries, "countries")

    output$report <- downloadHandler(
      filename = function() paste0("atera_summary_", format(Sys.Date(), "%Y%m%d"), ".html"),
      content = function(file) {
        cur <- tot_cur(); prev <- tot_prev(); p <- ctx$period()
        kpis <- lapply(KPI_METS, function(m) {
          ch <- if (is.null(prev)) NA_real_ else pct_change(cur[[m]], prev[[m]])
          list(label = metric_label(m), value = fmt_metric(cur[[m]], m),
               delta = if (is.finite(ch)) sprintf("%s%s vs %s", if (ch >= 0) "+" else "-",
                                                   fmt_pct(abs(ch)), p$compare_label) else "")
        })
        ch <- channels(); pg <- pages()
        tables <- list(
          "Channels" = if (is.null(ch)) NULL else data.frame(
            Channel = ch$sessionDefaultChannelGroup, Sessions = fmt_int_vec(ch$sessions),
            Users = fmt_int_vec(ch$totalUsers), Engagement = fmt_pct_vec(ch$engagementRate),
            check.names = FALSE),
          "Most viewed pages" = if (is.null(pg)) NULL else data.frame(
            Page = pg$pagePath, Views = fmt_int_vec(pg$screenPageViews), Users = fmt_int_vec(pg$totalUsers),
            check.names = FALSE))
        html <- build_report_html(
          title = "Atera Analytics - website summary",
          period_label = sprintf("%s to %s%s", format(p$start, "%d %b %Y"), format(p$end, "%d %b %Y"),
                                 if (identical(ctx$src()$mode, "live")) "" else "  (DEMO DATA - not real visitors)"),
          kpis = kpis, insights = insights(), tables = tables)
        writeLines(html, file, useBytes = TRUE)
      }
    )
  })
}
