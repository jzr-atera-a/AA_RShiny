# ---- page ------------------------------------------------------------
# id:          conversions
# tab label:   Contact Funnel
# main group:  Conversions & Actions   (sidebar; see modules/_module_registry.yml)
# description: contact page funnel and enquiries
# functions:   conversions_ui(id), conversions_server(id, ...)
# --------------------------------------------------------------------

conversions_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL,
      fluidRow(
        column(4, textInput(ns("pattern"), "Contact page address contains", value = "contact")),
        column(4, selectizeInput(ns("start_ev"), "Event when a visitor starts the form",
                                 choices = c("contact_form_start", "form_start"),
                                 selected = "contact_form_start", options = list(create = TRUE))),
        column(4, selectizeInput(ns("conv_ev"), "Event(s) that count as an enquiry",
                                 choices = c("generate_lead", "form_submit"),
                                 selected = "generate_lead", multiple = TRUE, options = list(create = TRUE)))
      )
    ),
    uiOutput(ns("kpis")),
    uiOutput(ns("hint")),
    fluidRow(
      column(5, card("Contact funnel", sub = "Users at each step (approximate: GA4 counts users per page and per event separately)",
                     plotlyOutput(ns("funnel"), height = "320px"))),
      column(7, card("Contact page views per day", plotlyOutput(ns("trend_views"), height = "130px")),
                card("Enquiries per day", plotlyOutput(ns("trend_conv"), height = "130px")))
    ),
    card("Enquiries by channel", sub = "Which traffic sources actually produce enquiries",
         right = dl_link(ns("dl_chan")), DT::DTOutput(ns("by_channel")))
  )
}

conversions_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    pattern <- reactive(tolower(trimws(input$pattern %||% "contact")))
    conv_ev <- reactive(input$conv_ev %||% character(0))
    start_ev <- reactive(input$start_ev %||% "contact_form_start")

    users    <- reactive(totals_list(ctx$q(mets = c("totalUsers", "sessions")), c("totalUsers", "sessions")))
    ev_tot   <- reactive(ctx$q("eventName", c("eventCount", "totalUsers"), limit = 200))
    ev_prev  <- reactive(ctx$q("eventName", c("eventCount", "totalUsers"), range = "prev", limit = 200))
    pg       <- reactive(ctx$q("pagePath", c("screenPageViews", "totalUsers"), limit = 1000))
    pg_prev  <- reactive(ctx$q("pagePath", c("screenPageViews", "totalUsers"), range = "prev", limit = 1000))
    pg_day   <- reactive(ctx$q(c("date", "pagePath"), "screenPageViews", limit = 100000))
    ev_day   <- reactive(ctx$q(c("date", "eventName"), "eventCount", limit = 100000))
    chan_ev  <- reactive(ctx$q(c("sessionDefaultChannelGroup", "eventName"), "eventCount", limit = 5000))
    chan_ses <- reactive(ctx$q("sessionDefaultChannelGroup", "sessions"))

    observe({
      d <- ev_tot()
      if (!is.null(d) && nrow(d) > 0) {
        isolate({
          updateSelectizeInput(session, "conv_ev", choices = union(d$eventName, input$conv_ev),
                               selected = input$conv_ev)
          updateSelectizeInput(session, "start_ev", choices = union(d$eventName, input$start_ev),
                               selected = input$start_ev)
        })
      }
    })

    is_contact <- function(paths) {
      if (!nzchar(pattern())) return(rep(FALSE, length(paths)))
      grepl(pattern(), tolower(paths), fixed = TRUE)
    }
    sum_where <- function(d, keep, col) if (is.null(d) || nrow(d) == 0) 0 else sum(d[[col]][keep(d)])
    contact_of <- function(d, col) sum_where(d, function(x) is_contact(x$pagePath), col)
    event_of <- function(d, names, col) sum_where(d, function(x) x$eventName %in% names, col)

    output$kpis <- renderUI({
      p <- ctx$period(); has_prev <- !is.null(pg_prev())
      sub <- if (has_prev) paste("vs", p$compare_label) else NULL
      views <- contact_of(pg(), "screenPageViews"); viewers <- contact_of(pg(), "totalUsers")
      conv  <- event_of(ev_tot(), conv_ev(), "eventCount")
      starts <- event_of(ev_tot(), start_ev(), "eventCount")
      rate_page <- conv / max(1, viewers); rate_site <- conv / max(1, users()$sessions)
      d <- function(cur, prev) if (has_prev) pct_change(cur, prev) else NULL
      kpi_row(
        kpi_tile("Contact page views", fmt_int(views), d(views, contact_of(pg_prev(), "screenPageViews")), sub = sub),
        kpi_tile("Forms started", fmt_int(starts), d(starts, event_of(ev_prev(), start_ev(), "eventCount")), sub = sub),
        kpi_tile("Enquiries", fmt_int(conv), d(conv, event_of(ev_prev(), conv_ev(), "eventCount")), sub = sub),
        kpi_tile("Contact page to enquiry", fmt_pct(rate_page), sub = "enquiries per contact-page visitor"),
        kpi_tile("Site conversion rate", fmt_pct(rate_site, 2), sub = "enquiries per session")
      )
    })

    output$hint <- renderUI({
      d <- ev_tot()
      if (is.null(d)) return(NULL)
      if (event_of(d, conv_ev(), "eventCount") > 0) return(NULL)
      note_box(kind = "warn", icon("exclamation-triangle"),
        " No '", paste(conv_ev(), collapse = "', '"), "' events were recorded in this period. ",
        "Either nobody submitted the form, or it is not being tracked yet. 'generate_lead' and 'contact_form_start' ",
        "are sent by the Atera WordPress theme from version 5.3.0 - check it is installed (see the Website Events tab). ",
        "Before that, the closest substitute is GA4's own 'form_submit' (Enhanced measurement > Form interactions); ",
        "pick it in the box above.")
    })

    output$funnel <- renderPlotly({
      stages <- c("All visitors", "Viewed contact page", "Started the form", "Sent an enquiry")
      vals <- c(users()$totalUsers, contact_of(pg(), "totalUsers"),
                event_of(ev_tot(), start_ev(), "totalUsers"), event_of(ev_tot(), conv_ev(), "totalUsers"))
      validate(need(vals[1] > 0, "No visitors in this period."))
      p <- plot_ly(type = "funnel", y = stages, x = vals, textinfo = "value+percent initial",
        textfont = list(color = "#ffffff"), marker = list(color = PAL[1]),
        connector = list(fillcolor = "#e3f3f1", line = list(width = 0)),
        hovertemplate = "%{y}: %{x:,.0f} users<extra></extra>")
      p <- ga_layout(p, hovermode = "closest")
      layout(p, yaxis = list(categoryorder = "array", categoryarray = rev(stages),
                             rangemode = "normal", gridcolor = "rgba(0,0,0,0)"),
             xaxis = list(showticklabels = FALSE, gridcolor = "rgba(0,0,0,0)"))
    })

    by_day <- function(d, col, days) {
      if (is.null(d) || nrow(d) == 0) return(rep(0, length(days)))
      agg <- tapply(d[[col]], format(d$date), sum)
      v <- as.numeric(agg[format(days)]); v[is.na(v)] <- 0; v
    }
    output$trend_views <- renderPlotly({
      p <- ctx$period(); pd <- pg_day()
      validate(need(!is.null(pd), "No data for this period."))
      days <- seq(p$start, p$end, by = "day")
      line_chart(days, list("Contact page views" = by_day(pd[is_contact(pd$pagePath), , drop = FALSE],
                                                          "screenPageViews", days)))
    })
    output$trend_conv <- renderPlotly({
      p <- ctx$period(); ed <- ev_day()
      validate(need(!is.null(ed), "No data for this period."))
      days <- seq(p$start, p$end, by = "day")
      conv <- by_day(ed[ed$eventName %in% conv_ev(), , drop = FALSE], "eventCount", days)
      pl <- plot_ly(x = days, y = conv, type = "bar", marker = list(color = PAL[3]),
                    hovertemplate = "%{y:,.0f} enquiries<extra></extra>")
      ga_layout(pl)
    })

    by_channel <- reactive({
      ce <- chan_ev(); cs <- chan_ses()
      if (is.null(cs) || nrow(cs) == 0) return(NULL)
      grab <- function(names) {
        if (is.null(ce) || nrow(ce) == 0) return(rep(0, nrow(cs)))
        x <- ce[ce$eventName %in% names, , drop = FALSE]
        if (nrow(x) == 0) return(rep(0, nrow(cs)))
        agg <- tapply(x$eventCount, x$sessionDefaultChannelGroup, sum)
        v <- as.numeric(agg[cs$sessionDefaultChannelGroup]); v[is.na(v)] <- 0; v
      }
      out <- data.frame(channel = cs$sessionDefaultChannelGroup, sessions = cs$sessions,
                        starts = grab(start_ev()), enquiries = grab(conv_ev()), stringsAsFactors = FALSE)
      out$rate  <- out$enquiries / pmax(1, out$sessions)
      out$share <- out$enquiries / max(1, sum(out$enquiries))
      out[order(-out$enquiries, -out$sessions), , drop = FALSE]
    })
    output$by_channel <- DT::renderDT({
      d <- by_channel(); validate(need(!is.null(d) && nrow(d) > 0, "No channel data."))
      tbl <- ga_table(d, labels = c(channel = "Channel", sessions = "Sessions", starts = "Forms started",
                        enquiries = "Enquiries", rate = "Enquiries per session", share = "Share of enquiries"),
                      int = c("sessions", "starts", "enquiries"), pct = "share", search = FALSE)
      DT::formatPercentage(tbl, "rate", 2)
    })
    output$dl_chan <- csv_handler(by_channel, "enquiries_by_channel")
  })
}
