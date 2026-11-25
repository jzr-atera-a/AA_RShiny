# ---- page ------------------------------------------------------------
# id:          behavior
# tab label:   User Behaviour
# main group:  Content & Engagement   (sidebar; see modules/_module_registry.yml)
# description: what people do on the site (GA4 events)
# functions:   behavior_ui(id), behavior_server(id, ...)
# --------------------------------------------------------------------

behavior_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(6, card("All events", sub = "Everything GA4 recorded, with change vs the comparison period",
                     right = dl_link(ns("dl_events")), DT::DTOutput(ns("events")))),
      column(6, card("Event trend",
        right = selectizeInput(ns("pick"), NULL, choices = NULL, multiple = TRUE, width = "320px",
                               options = list(maxItems = 4, placeholder = "Choose up to 4 events")),
        plotlyOutput(ns("trend"), height = "330px")))
    ),
    fluidRow(
      column(6, card("Outbound link clicks", sub = "Links that take visitors off the site",
                     DT::DTOutput(ns("links")))),
      column(6, card("About these numbers",
        note_box(icon("info-circle"),
          " Scroll, outbound click, file download and form events come from GA4 'Enhanced measurement'. ",
          "If a panel is empty, switch it on in Google Analytics > Admin > Data streams > your stream. ",
          "GA4's API does not provide click heatmaps, per-element click tracking or user-flow paths, ",
          "so this app only shows what Google actually records.")))
    )
  )
}

behavior_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    tm <- c("sessions", "totalUsers", "engagedSessions", "engagementRate",
            "screenPageViews", "eventCount", "userEngagementDuration")
    tot      <- reactive(totals_list(ctx$q(mets = tm), tm))
    tot_prev <- reactive({ d <- ctx$q(mets = tm, range = "prev"); if (is.null(d)) NULL else totals_list(d, tm) })
    events <- reactive({
      d <- with_prev(ctx$q("eventName", c("eventCount", "totalUsers"), limit = 200),
                     ctx$q("eventName", c("eventCount", "totalUsers"), range = "prev", limit = 200),
                     "eventName", "eventCount")
      if (!is.null(d) && nrow(d) > 0) d$per_user <- d$eventCount / pmax(1, d$totalUsers)
      d
    })
    ev_day <- reactive(ctx$q(c("date", "eventName"), "eventCount", limit = 100000))
    links  <- reactive({
      d <- ctx$q(c("eventName", "linkUrl"), c("eventCount", "totalUsers"), limit = 5000)
      if (is.null(d)) return(NULL)
      d <- d[d$eventName == "click" & nzchar(d$linkUrl) & d$linkUrl != "(not set)", , drop = FALSE]
      d[order(-d$eventCount), c("linkUrl", "eventCount", "totalUsers"), drop = FALSE]
    })

    observe({
      d <- events()
      if (!is.null(d) && nrow(d) > 0) {
        want <- intersect(c("page_view", "scroll", "click", "form_submit"), d$eventName)
        if (length(want) == 0) want <- utils::head(d$eventName, 3)
        updateSelectizeInput(session, "pick", choices = d$eventName, selected = want)
      }
    })

    output$kpis <- renderUI({
      cur <- tot(); pv <- tot_prev(); ev <- events(); p <- ctx$period()
      sub <- if (is.null(pv)) NULL else paste("vs", p$compare_label)
      ratio <- function(t, a, b) if (is.null(t)) NULL else t[[a]] / max(1, t[[b]])
      dl <- function(a, b) if (is.null(pv)) NULL else pct_change(ratio(cur, a, b), ratio(pv, a, b))
      scroll_users <- if (!is.null(ev) && any(ev$eventName == "scroll")) ev$totalUsers[ev$eventName == "scroll"][1] else NA
      kpi_row(
        kpi_tile("Engagement rate", fmt_pct(cur$engagementRate),
                 if (is.null(pv)) NULL else pct_change(cur$engagementRate, pv$engagementRate), sub = sub),
        kpi_tile("Avg. engaged time per user", fmt_dur(ratio(cur, "userEngagementDuration", "totalUsers")),
                 dl("userEngagementDuration", "totalUsers"), sub = sub),
        kpi_tile("Views per session", formatC(ratio(cur, "screenPageViews", "sessions"), format = "f", digits = 2),
                 dl("screenPageViews", "sessions"), sub = sub),
        kpi_tile("Events per session", formatC(ratio(cur, "eventCount", "sessions"), format = "f", digits = 1),
                 dl("eventCount", "sessions"), sub = sub),
        kpi_tile("Users who scroll to the bottom",
                 if (is.na(scroll_users)) "-" else fmt_pct(scroll_users / max(1, cur$totalUsers)),
                 sub = "reached 90% of a page")
      )
    })

    output$events <- DT::renderDT({
      d <- events(); validate(need(!is.null(d) && nrow(d) > 0, "No events in this period."))
      d <- d[c("eventName", "eventCount", "eventCount_chg", "totalUsers", "per_user")]
      ga_table(d, labels = c(eventName = "Event", eventCount = "Count", eventCount_chg = "Change",
                             totalUsers = "Users", per_user = "Per user"),
               int = c("eventCount", "totalUsers"), dec = "per_user", chg = "eventCount_chg")
    })
    output$dl_events <- csv_handler(events, "events")

    output$trend <- renderPlotly({
      d <- ev_day(); p <- ctx$period(); sel <- input$pick
      validate(need(!is.null(d) && nrow(d) > 0, "No events in this period."),
               need(length(sel) > 0, "Choose one or more events."))
      days <- seq(p$start, p$end, by = "day")
      series <- lapply(sel, function(e) {
        complete_days(d[d$eventName == e, , drop = FALSE], p$start, p$end, "eventCount")$eventCount
      })
      names(series) <- sel
      line_chart(days, series, ytitle = "Events")
    })

    output$links <- DT::renderDT({
      d <- links()
      validate(need(!is.null(d) && nrow(d) > 0, "No outbound clicks recorded in this period."))
      ga_table(d, labels = c(linkUrl = "Link", eventCount = "Clicks", totalUsers = "Users"),
               int = c("eventCount", "totalUsers"), page = 8, search = FALSE)
    })
  })
}
