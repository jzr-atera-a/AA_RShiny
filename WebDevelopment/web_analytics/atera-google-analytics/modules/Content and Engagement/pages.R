# ---- page ------------------------------------------------------------
# id:          pages
# tab label:   Page Performance
# main group:  Content & Engagement   (sidebar; see modules/_module_registry.yml)
# description: which pages work, which are slipping, which need attention
# functions:   pages_ui(id), pages_server(id, ...)
# --------------------------------------------------------------------

pages_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card("All pages", sub = "Change columns compare with the comparison period",
         right = dl_link(ns("dl_pages")), DT::DTOutput(ns("table"))),
    fluidRow(
      column(6, card("Biggest movers", sub = "Pages that gained or lost the most views",
                     plotlyOutput(ns("movers"), height = "320px"))),
      column(6, card("Pages that need attention",
                     sub = "Plenty of traffic, but visitors spend less time than on your typical page",
                     DT::DTOutput(ns("attention"))))
    ),
    card("Page trend", right = selectInput(ns("page"), NULL, choices = NULL, width = "320px"),
         plotlyOutput(ns("trend"), height = "280px"))
  )
}

pages_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    pm <- c("screenPageViews", "totalUsers", "userEngagementDuration", "keyEvents")
    pages <- reactive({
      d <- with_prev(ctx$q("pagePath", pm, limit = 500),
                     ctx$q("pagePath", pm, range = "prev", limit = 1000),
                     "pagePath", "screenPageViews")
      if (is.null(d) || nrow(d) == 0) return(d)
      d$avg_time  <- d$userEngagementDuration / pmax(1, d$totalUsers)
      d$views_per <- d$screenPageViews / pmax(1, d$totalUsers)
      d$share     <- d$screenPageViews / max(1, sum(d$screenPageViews))
      d
    })
    prev_views <- reactive(ctx$q("pagePath", "screenPageViews", range = "prev", limit = 1000))
    page_day <- reactive(ctx$q(c("date", "pagePath"), "screenPageViews", limit = 100000))

    observe({
      d <- pages()
      if (!is.null(d) && nrow(d) > 0) {
        updateSelectInput(session, "page", choices = utils::head(d$pagePath, 50), selected = d$pagePath[1])
      }
    })

    output$table <- DT::renderDT({
      d <- pages(); validate(need(!is.null(d) && nrow(d) > 0, "No page data for this period."))
      d <- d[c("pagePath", "screenPageViews", "share", "screenPageViews_chg", "totalUsers",
               "views_per", "avg_time", "keyEvents")]
      ga_table(d, labels = c(pagePath = "Page", screenPageViews = "Views", share = "Share of views",
                 screenPageViews_chg = "Views change", totalUsers = "Users", views_per = "Views per user",
                 avg_time = "Avg. time per user (s)", keyEvents = "Key events"),
               int = c("screenPageViews", "totalUsers", "avg_time", "keyEvents"),
               pct = "share", dec = "views_per", chg = "screenPageViews_chg", page = 15)
    })
    output$dl_pages <- csv_handler(pages, "pages")

    output$movers <- renderPlotly({
      d <- pages(); pv <- prev_views()
      validate(need(!is.null(pv), "Turn on a comparison period to see movers."),
               need(!is.null(d) && nrow(d) > 0, "No page data."))
      all_pages <- union(d$pagePath, pv$pagePath)
      cur_v  <- d$screenPageViews[match(all_pages, d$pagePath)];  cur_v[is.na(cur_v)] <- 0
      prev_v <- pv$screenPageViews[match(all_pages, pv$pagePath)]; prev_v[is.na(prev_v)] <- 0
      diff <- cur_v - prev_v
      ord <- order(-abs(diff))[seq_len(min(10, length(diff)))]
      ord <- ord[order(-diff[ord])]
      validate(need(length(ord) > 0 && any(diff[ord] != 0), "No change between the two periods."))
      labs <- trunc_lab(all_pages[ord], 34)
      p <- plot_ly(x = diff[ord], y = labs, type = "bar", orientation = "h",
        marker = list(color = ifelse(diff[ord] >= 0, PAL[1], PAL[2])),
        text = sprintf("%+d", as.integer(diff[ord])), textposition = "outside",
        textfont = list(color = INK2), cliponaxis = FALSE,
        hovertemplate = "%{y}: %{x:+,.0f} views<extra></extra>")
      p <- ga_layout(p, xtitle = "Change in views", hovermode = "closest")
      layout(p, yaxis = list(categoryorder = "array", categoryarray = rev(labs),
                             rangemode = "normal", gridcolor = "rgba(0,0,0,0)"),
             xaxis = list(rangemode = "normal", zeroline = TRUE, zerolinecolor = MUTED), bargap = 0.35)
    })

    attention <- reactive({
      d <- pages()
      if (is.null(d) || nrow(d) < 4) return(NULL)
      med_views <- stats::median(d$screenPageViews); med_time <- stats::median(d$avg_time)
      x <- d[d$screenPageViews >= med_views & d$avg_time < 0.75 * med_time, , drop = FALSE]
      x$gap <- x$avg_time / max(1, med_time) - 1
      x[order(-x$screenPageViews), c("pagePath", "screenPageViews", "avg_time", "gap"), drop = FALSE]
    })
    output$attention <- DT::renderDT({
      x <- attention()
      validate(need(!is.null(x) && nrow(x) > 0, "Nothing stands out - no busy page is far below your typical time on page."))
      ga_table(x, labels = c(pagePath = "Page", screenPageViews = "Views", avg_time = "Avg. time (s)",
                             gap = "vs typical page"),
               int = c("screenPageViews", "avg_time"), chg = "gap", page = 8, search = FALSE)
    })

    output$trend <- renderPlotly({
      d <- page_day(); p <- ctx$period(); pg <- input$page
      validate(need(!is.null(d) && nrow(d) > 0 && nzchar(pg %||% ""), "Choose a page."))
      x <- complete_days(d[d$pagePath == pg, , drop = FALSE], p$start, p$end, "screenPageViews")
      line_chart(x$date, list("Views" = x$screenPageViews), ytitle = "Views")
    })
  })
}
