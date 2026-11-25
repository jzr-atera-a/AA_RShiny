# ---- page ------------------------------------------------------------
# id:          realtime
# tab label:   Real-time
# main group:  Overview & Monitoring   (sidebar; see modules/_module_registry.yml)
# description: who is on the site in the last 30 minutes
# functions:   realtime_ui(id), realtime_server(id, ...)
# --------------------------------------------------------------------

realtime_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL,
      div(class = "btn-row",
        checkboxInput(ns("auto"), "Refresh every 60 seconds", value = TRUE),
        actionButton(ns("now"), "Refresh now", icon = icon("sync")),
        uiOutput(ns("stamp"), inline = TRUE))),
    uiOutput(ns("kpis")),
    fluidRow(
      column(7, card("Active users per minute", sub = "Last 30 minutes, most recent on the right",
                     plotlyOutput(ns("minutes"), height = "260px"))),
      column(5, card("By device", plotlyOutput(ns("devices"), height = "260px")))
    ),
    fluidRow(
      column(7, card("Pages being viewed now", DT::DTOutput(ns("pages")))),
      column(5, card("Visitor countries", DT::DTOutput(ns("countries"))))
    )
  )
}

realtime_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    tick <- reactive({
      input$now
      if (isTRUE(input$auto)) invalidateLater(60000, session)
      Sys.time()
    })
    rt <- function(dims = character(0), mets = "activeUsers") {
      tick()
      src <- ctx$src()
      tryCatch(ga_realtime(src, dims, mets), error = function(e) {
        cat("[REALTIME ERROR]", conditionMessage(e), "\n")
        validate(need(FALSE, conditionMessage(e)))
      })
    }
    totals  <- reactive(rt(mets = c("activeUsers", "screenPageViews", "eventCount")))
    minutes <- reactive(rt("minutesAgo", "activeUsers"))
    pages   <- reactive(rt("unifiedScreenName", c("activeUsers", "screenPageViews")))
    country <- reactive(rt("country", "activeUsers"))
    device  <- reactive(rt("deviceCategory", "activeUsers"))

    output$stamp <- renderUI({
      span(class = "ga-card-sub", paste0("Updated ", format(tick(), "%H:%M:%S"),
           if (identical(ctx$src()$mode, "live")) "" else " - simulated demo numbers"))
    })

    output$kpis <- renderUI({
      t <- totals_list(totals(), c("activeUsers", "screenPageViews", "eventCount"))
      kpi_row(
        kpi_tile("Active users", fmt_int(t$activeUsers), sub = "in the last 30 minutes"),
        kpi_tile("Page views", fmt_int(t$screenPageViews), sub = "in the last 30 minutes"),
        kpi_tile("Events", fmt_int(t$eventCount), sub = "in the last 30 minutes")
      )
    })

    output$minutes <- renderPlotly({
      d <- minutes()
      v <- rep(0, 30)
      if (!is.null(d) && nrow(d) > 0) {
        ok <- !is.na(d$minutesAgo) & d$minutesAgo >= 0 & d$minutesAgo <= 29
        v[d$minutesAgo[ok] + 1] <- d$activeUsers[ok]
      }
      lab <- ifelse(0:29 == 0, "now", paste0(0:29, " min ago"))
      p <- plot_ly(x = -(0:29), y = v, type = "bar", marker = list(color = PAL[1]), text = lab,
                   hovertemplate = "%{text}: %{y:,.0f} active<extra></extra>", textposition = "none")
      p <- ga_layout(p, xtitle = "Minutes ago", hovermode = "closest")
      layout(p, xaxis = list(tickvals = c(-29, -20, -10, 0), ticktext = c("29", "20", "10", "now")), bargap = 0.3)
    })
    output$devices <- renderPlotly({
      d <- device(); validate(need(!is.null(d) && nrow(d) > 0, "Nobody is on the site right now."))
      bar_h(d$deviceCategory, d$activeUsers)
    })
    output$pages <- DT::renderDT({
      d <- pages(); validate(need(!is.null(d) && nrow(d) > 0, "Nobody is on the site right now."))
      ga_table(d, labels = c(unifiedScreenName = "Page", activeUsers = "Active users", screenPageViews = "Views"),
               int = c("activeUsers", "screenPageViews"), page = 8, search = FALSE)
    })
    output$countries <- DT::renderDT({
      d <- country(); validate(need(!is.null(d) && nrow(d) > 0, "Nobody is on the site right now."))
      ga_table(d, labels = c(country = "Country", activeUsers = "Active users"),
               int = "activeUsers", page = 8, search = FALSE)
    })
  })
}
