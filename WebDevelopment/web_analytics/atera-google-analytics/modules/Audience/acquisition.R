# ---- page ------------------------------------------------------------
# id:          acquisition
# tab label:   Acquisition
# main group:  Audience   (sidebar; see modules/_module_registry.yml)
# description: where visitors come from and which sources are worth it
# functions:   acquisition_ui(id), acquisition_server(id, ...)
# --------------------------------------------------------------------

acquisition_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(7, card("Sessions by channel over time", sub = "Top five channels; the rest are grouped as Other",
                     plotlyOutput(ns("chan_trend"), height = "320px"))),
      column(5, card("Volume vs quality", sub = "Right = more sessions, up = more engaged. Top-right channels deserve more investment.",
                     plotlyOutput(ns("quality"), height = "320px")))
    ),
    card("Channels", right = dl_link(ns("dl_channels")), DT::DTOutput(ns("chan_table"))),
    fluidRow(
      column(6, card("Source / medium", right = dl_link(ns("dl_sources")), DT::DTOutput(ns("sources")))),
      column(6, card("Landing pages", sub = "The first page of a visit",
                     right = dl_link(ns("dl_landing")), DT::DTOutput(ns("landing"))))
    )
  )
}

acquisition_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    cm <- c("sessions", "totalUsers", "newUsers", "engagementRate", "averageSessionDuration", "keyEvents")
    channels <- reactive({
      d <- with_prev(ctx$q("sessionDefaultChannelGroup", cm),
                     ctx$q("sessionDefaultChannelGroup", cm, range = "prev"),
                     "sessionDefaultChannelGroup", c("sessions", "keyEvents"))
      if (!is.null(d) && nrow(d) > 0) d$share <- d$sessions / max(1, sum(d$sessions))
      d
    })
    chan_day <- reactive(ctx$q(c("date", "sessionDefaultChannelGroup"), "sessions", limit = 50000))
    sources  <- reactive(with_prev(
      ctx$q("sessionSourceMedium", c("sessions", "totalUsers", "engagementRate", "keyEvents"), limit = 100),
      ctx$q("sessionSourceMedium", c("sessions", "totalUsers", "engagementRate", "keyEvents"),
            range = "prev", limit = 500),
      "sessionSourceMedium", "sessions"))
    landing  <- reactive(ctx$q("landingPage",
      c("sessions", "engagementRate", "averageSessionDuration", "keyEvents"), limit = 100))

    output$chan_trend <- renderPlotly({
      d <- chan_day(); p <- ctx$period()
      validate(need(!is.null(d) && nrow(d) > 0, "No data for this period."))
      top <- top_groups(d, "sessionDefaultChannelGroup", "sessions", 5)
      d$grp <- ifelse(d$sessionDefaultChannelGroup %in% top, d$sessionDefaultChannelGroup, "Other")
      groups <- c(top, if (any(d$grp == "Other")) "Other")
      days <- seq(p$start, p$end, by = "day")
      series <- lapply(groups, function(g) {
        x <- d[d$grp == g, , drop = FALSE]
        agg <- tapply(x$sessions, format(x$date), sum)
        v <- as.numeric(agg[format(days)]); v[is.na(v)] <- 0; v
      })
      names(series) <- groups
      line_chart(days, series)
    })

    output$quality <- renderPlotly({
      d <- channels(); validate(need(!is.null(d) && nrow(d) > 0, "No channel data."))
      p <- plot_ly(x = d$sessions, y = d$engagementRate, type = "scatter", mode = "markers+text",
        text = d$sessionDefaultChannelGroup, textposition = "top center",
        textfont = list(color = INK2, size = 11),
        marker = list(size = 12, color = PAL[1], line = list(color = SURFACE, width = 2)),
        hovertemplate = "%{text}<br>%{x:,.0f} sessions<br>%{y:.1%} engaged<extra></extra>")
      p <- ga_layout(p, xtitle = "Sessions", ytitle = "Engagement rate", hovermode = "closest")
      layout(p, yaxis = list(tickformat = ".0%", rangemode = "normal"), xaxis = list(rangemode = "tozero"))
    })

    output$chan_table <- DT::renderDT({
      d <- channels(); validate(need(!is.null(d) && nrow(d) > 0, "No channel data."))
      d <- d[c("sessionDefaultChannelGroup", "sessions", "share", "sessions_chg", "totalUsers", "newUsers",
               "engagementRate", "averageSessionDuration", "keyEvents", "keyEvents_chg")]
      ga_table(d, labels = c(sessionDefaultChannelGroup = "Channel", sessions = "Sessions", share = "Share",
                 sessions_chg = "Sessions change", totalUsers = "Users", newUsers = "New users",
                 engagementRate = "Engagement", averageSessionDuration = "Avg. session (s)",
                 keyEvents = "Key events", keyEvents_chg = "Key events change"),
               int = c("sessions", "totalUsers", "newUsers", "averageSessionDuration", "keyEvents"),
               pct = c("share", "engagementRate"), chg = c("sessions_chg", "keyEvents_chg"), search = FALSE)
    })
    output$sources <- DT::renderDT({
      d <- sources(); validate(need(!is.null(d) && nrow(d) > 0, "No source data."))
      ga_table(d, labels = c(sessionSourceMedium = "Source / medium", sessions = "Sessions", totalUsers = "Users",
                 engagementRate = "Engagement", keyEvents = "Key events", sessions_chg = "Change"),
               int = c("sessions", "totalUsers", "keyEvents"), pct = "engagementRate", chg = "sessions_chg")
    })
    output$landing <- DT::renderDT({
      d <- landing(); validate(need(!is.null(d) && nrow(d) > 0, "No landing page data."))
      ga_table(d, labels = c(landingPage = "Landing page", sessions = "Sessions", engagementRate = "Engagement",
                 averageSessionDuration = "Avg. session (s)", keyEvents = "Key events"),
               int = c("sessions", "averageSessionDuration", "keyEvents"), pct = "engagementRate")
    })
    output$dl_channels <- csv_handler(channels, "channels")
    output$dl_sources  <- csv_handler(sources, "sources")
    output$dl_landing  <- csv_handler(landing, "landing_pages")
  })
}
