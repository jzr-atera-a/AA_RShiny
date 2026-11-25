# ---- page ------------------------------------------------------------
# id:          visitors
# tab label:   Visitors
# main group:  Audience   (sidebar; see modules/_module_registry.yml)
# description: who visits: new vs returning, when, where, on what
# functions:   visitors_ui(id), visitors_server(id, ...)
# --------------------------------------------------------------------

visitors_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(7, card("New vs returning users per day", plotlyOutput(ns("nvr_trend"), height = "300px"))),
      column(5, card("New vs returning: quality", sub = "Returning visitors usually engage more - a low figure here is worth a look",
                     DT::DTOutput(ns("nvr_table"))))
    ),
    fluidRow(
      column(7, card("When people visit", sub = "Sessions by weekday and hour (property time zone). Brighter = busier.",
                     plotlyOutput(ns("heat"), height = "300px"))),
      column(5, card("Technology",
        right = selectInput(ns("tech_dim"), NULL, width = "170px",
          choices = c("Device" = "deviceCategory", "Browser" = "browser", "Operating system" = "operatingSystem")),
        plotlyOutput(ns("tech"), height = "300px")))
    ),
    card("Cities", right = dl_link(ns("dl_cities")), DT::DTOutput(ns("cities")))
  )
}

visitors_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    nvr_mets <- c("totalUsers", "sessions", "engagementRate", "averageSessionDuration")
    nvr      <- reactive(ctx$q("newVsReturning", nvr_mets))
    nvr_prev <- reactive(ctx$q("newVsReturning", nvr_mets, range = "prev"))
    nvr_day  <- reactive(ctx$q(c("date", "newVsReturning"), "totalUsers", limit = 50000))
    heat     <- reactive(ctx$q(c("dayOfWeek", "hour"), "sessions", limit = 200))
    tech     <- reactive(ctx$q(input$tech_dim %||% "deviceCategory",
                               c("sessions", "engagementRate"), limit = 10))
    cities   <- reactive(ctx$q(c("city", "country"),
                               c("totalUsers", "sessions", "engagementRate"), limit = 200))

    pick <- function(d, kind, col) {
      if (is.null(d) || nrow(d) == 0) return(0)
      sum(d[[col]][d$newVsReturning == kind])
    }

    output$kpis <- renderUI({
      d <- nvr(); pv <- nvr_prev(); p <- ctx$period()
      validate(need(!is.null(d), "No data."))
      sub <- if (is.null(pv)) NULL else paste("vs", p$compare_label)
      new_u <- pick(d, "new", "totalUsers"); ret_u <- pick(d, "returning", "totalUsers")
      share <- ret_u / max(1, new_u + ret_u)
      dl <- function(cur, kind, col) if (is.null(pv)) NULL else pct_change(cur, pick(pv, kind, col))
      share_prev <- if (is.null(pv)) NA else pick(pv, "returning", "totalUsers") /
        max(1, pick(pv, "new", "totalUsers") + pick(pv, "returning", "totalUsers"))
      kpi_row(
        kpi_tile("New users", fmt_int(new_u), dl(new_u, "new", "totalUsers"), sub = sub),
        kpi_tile("Returning users", fmt_int(ret_u), dl(ret_u, "returning", "totalUsers"), sub = sub),
        kpi_tile("Returning share", fmt_pct(share),
                 if (is.null(pv)) NULL else pct_change(share, share_prev), sub = sub),
        kpi_tile("Sessions per user", formatC(sum(d$sessions) / max(1, sum(d$totalUsers)), format = "f", digits = 2))
      )
    })

    output$nvr_trend <- renderPlotly({
      d <- nvr_day(); p <- ctx$period()
      validate(need(!is.null(d) && nrow(d) > 0, "No data for this period."))
      one <- function(kind) complete_days(d[d$newVsReturning == kind, , drop = FALSE],
                                          p$start, p$end, "totalUsers")
      a <- one("new"); b <- one("returning")
      line_chart(a$date, list("New" = a$totalUsers, "Returning" = b$totalUsers))
    })

    output$nvr_table <- DT::renderDT({
      d <- nvr(); validate(need(!is.null(d) && nrow(d) > 0, "No data."))
      ga_table(d, labels = c(newVsReturning = "Visitor type", totalUsers = "Users", sessions = "Sessions",
                             engagementRate = "Engagement", averageSessionDuration = "Avg. session (s)"),
               int = c("totalUsers", "sessions", "averageSessionDuration"), pct = "engagementRate",
               search = FALSE)
    })

    output$heat <- renderPlotly({
      d <- heat(); validate(need(!is.null(d) && nrow(d) > 0, "No data for this period."))
      z <- matrix(0, nrow = 7, ncol = 24)
      ok <- !is.na(d$dayOfWeek) & !is.na(d$hour)
      z[cbind(d$dayOfWeek[ok] + 1, d$hour[ok] + 1)] <- d$sessions[ok]
      ord <- c(2:7, 1)                                  # Monday first
      days <- c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
      p <- plot_ly(x = 0:23, y = days[ord], z = z[ord, , drop = FALSE], type = "heatmap",
        colorscale = SEQ_SCALE, xgap = 2, ygap = 2, showscale = FALSE,
        hovertemplate = "%{y} %{x}:00 - %{z:,.0f} sessions<extra></extra>")
      p <- ga_layout(p, xtitle = "Hour of day", hovermode = "closest")
      layout(p, yaxis = list(autorange = "reversed", rangemode = "normal", gridcolor = "rgba(0,0,0,0)"),
             xaxis = list(dtick = 3, gridcolor = "rgba(0,0,0,0)"))
    })

    output$tech <- renderPlotly({
      d <- tech(); validate(need(!is.null(d) && nrow(d) > 0, "No data."))
      bar_h(d[[1]], d$sessions, xtitle = "Sessions")
    })

    output$cities <- DT::renderDT({
      d <- cities(); validate(need(!is.null(d) && nrow(d) > 0, "No data."))
      ga_table(d, labels = c(city = "City", country = "Country", totalUsers = "Users",
                             sessions = "Sessions", engagementRate = "Engagement"),
               int = c("totalUsers", "sessions"), pct = "engagementRate")
    })
    output$dl_cities <- csv_handler(cities, "cities")
  })
}
