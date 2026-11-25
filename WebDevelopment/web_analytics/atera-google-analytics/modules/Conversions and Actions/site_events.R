# ---- page ------------------------------------------------------------
# id:          site_events
# tab label:   Website Events
# main group:  Conversions & Actions   (sidebar; see modules/_module_registry.yml)
# description: the events sent by the Atera WordPress theme (v5.3.0+): CTA clicks, navigation, contact form, FAQ, scroll depth, architecture diagram and live-platform opens. Includes a tracking-health check and one-click registration of the custom dimensions and key event in GA4.
# functions:   site_events_ui(id), site_events_server(id, ...)
# --------------------------------------------------------------------

THEME_EVENTS <- data.frame(
  event = c("generate_lead", "contact_form_start", "form_error", "cta_click", "navigation_click",
            "app_open", "architecture_view", "architecture_select", "architecture_open_full",
            "faq_open", "scroll_depth"),
  meaning = c("Contact form sent (an enquiry)", "Started filling in the contact form",
              "Contact form submission failed", "Call-to-action button clicked",
              "Menu, logo, footer or quick link clicked", "Live analytics platform opened",
              "Architecture diagram scrolled into view", "Box in the architecture diagram opened",
              "Architecture diagram opened full size", "FAQ question opened",
              "Page scrolled to 25 / 50 / 75 / 100%"),
  parameter = c("form_id", "form_id", "form_id", "cta_location", "nav_location", "app_name", "",
                "architecture_component", "", "faq_question", "percent_scrolled"),
  stringsAsFactors = FALSE)

site_events_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("kpis")),
    fluidRow(
      column(7, card("Tracking health",
        sub = "Is each event from the website theme arriving, and can its details be reported?",
        right = uiOutput(ns("setup_btn"), inline = TRUE),
        DT::DTOutput(ns("health")), uiOutput(ns("health_note")))),
      column(5, card("Website events per day",
        right = selectizeInput(ns("trend_ev"), NULL, choices = THEME_EVENTS$event, multiple = TRUE,
                               selected = c("cta_click", "generate_lead", "app_open", "architecture_select"),
                               width = "260px", options = list(maxItems = 5)),
        plotlyOutput(ns("trend"), height = "330px")))
    ),
    fluidRow(
      column(6, card("Calls to action: where on the page", sub = "cta_click by location",
                     plotlyOutput(ns("cta_where"), height = "280px"))),
      column(6, card("Calls to action: which button", sub = "cta_click by button text",
                     plotlyOutput(ns("cta_which"), height = "280px")))
    ),
    fluidRow(
      column(6, card("Live platforms opened", sub = "Clicks through to the shinyapps.io platforms",
                     plotlyOutput(ns("apps"), height = "240px"))),
      column(6, card("Architecture diagram: components opened", sub = "Boxes selected in the MLOps diagram on /projects/",
                     plotlyOutput(ns("arch"), height = "240px")))
    ),
    fluidRow(
      column(6, card("How far visitors scroll", sub = "Share of page views that reached each depth",
                     plotlyOutput(ns("scroll"), height = "260px"))),
      column(6, card("FAQ questions opened", plotlyOutput(ns("faq"), height = "260px")))
    ),
    fluidRow(
      column(6, card("Pages where calls to action are clicked", right = dl_link(ns("dl_cta_pages")),
                     DT::DTOutput(ns("cta_pages")))),
      column(6, card("Navigation clicks", right = dl_link(ns("dl_nav")), DT::DTOutput(ns("nav"))))
    ),
    note_box(icon("info-circle"),
      " These events come from the Atera WordPress theme (version 5.3.0 or later) through the Site Kit Google tag. ",
      "To watch them live, open any page of the site with ", tags$code("?ga_debug=1"),
      " added to the address and look at Google Analytics > Admin > DebugView. Visitors who decline cookies are only ",
      "partly counted by Google, so these numbers are lower than true traffic.")
  )
}

site_events_server <- function(id, ctx, app) {
  moduleServer(id, function(input, output, session) {

    # ---- which custom dimensions exist in the property ---------------------------
    registered <- reactive({
      app$refresh
      s <- ctx$src()
      if (!identical(s$mode, "live")) return(THEME_CUSTOM_DIMS$parameter)   # demo: everything available
      md <- app$metadata
      if (is.null(md)) {
        md <- tryCatch(ga_metadata(s$conn, s$property_id), error = function(e) {
          cat("[EVENTS] metadata failed:", conditionMessage(e), "\n"); NULL })
        if (!is.null(md)) app$metadata <- md
      }
      if (is.null(md)) return(character(0))
      sub("^customEvent:", "", grep("^customEvent:", md$dimensions$apiName, value = TRUE))
    })
    need_dim <- function(param, label) {
      need(param %in% registered(), paste0(
        "'", label, "' is not registered as a custom dimension yet, so GA4 cannot report it. ",
        "Press 'Set up in GA4' in Tracking health above. Data appears from the day it is registered."))
    }

    one_event <- function(ev, dims, mets = "eventCount", limit = 500) {
      ctx$q(unique(c("eventName", dims)), mets, limit = limit,
            filter = list(field = "eventName", match = "EXACT", value = ev))
    }

    ev_now  <- reactive(ctx$q("eventName", c("eventCount", "totalUsers"), limit = 500))
    ev_prev <- reactive(ctx$q("eventName", c("eventCount", "totalUsers"), range = "prev", limit = 500))
    pv_tot  <- reactive(totals_list(ctx$q(mets = c("screenPageViews", "sessions")), c("screenPageViews", "sessions")))
    count_of <- function(d, ev, col = "eventCount") if (is.null(d) || nrow(d) == 0) 0 else sum(d[[col]][d$eventName %in% ev])

    # ---- KPIs ------------------------------------------------------------------
    output$kpis <- renderUI({
      cur <- ev_now(); prev <- ev_prev(); p <- ctx$period()
      sub <- if (is.null(prev)) NULL else paste("vs", p$compare_label)
      dl <- function(ev) if (is.null(prev)) NULL else pct_change(count_of(cur, ev), count_of(prev, ev))
      leads <- count_of(cur, "generate_lead"); starts <- count_of(cur, "contact_form_start")
      cta <- count_of(cur, "cta_click"); views <- pv_tot()$screenPageViews
      kpi_row(
        kpi_tile("Enquiries sent", fmt_int(leads), dl("generate_lead"), sub = sub),
        kpi_tile("Contact forms started", fmt_int(starts), dl("contact_form_start"), sub = sub),
        kpi_tile("Started forms that were sent", if (starts > 0) fmt_pct(min(1, leads / starts)) else "-",
                 sub = "enquiries / form starts"),
        kpi_tile("CTA clicks", fmt_int(cta), dl("cta_click"), sub = sub),
        kpi_tile("CTA clicks per 100 page views", if (views > 0) formatC(100 * cta / views, format = "f", digits = 1) else "-"),
        kpi_tile("Live platform opens", fmt_int(count_of(cur, "app_open")), dl("app_open"), sub = sub),
        kpi_tile("Diagram boxes opened", fmt_int(count_of(cur, "architecture_select")), dl("architecture_select"), sub = sub)
      )
    })

    # ---- Tracking health ----------------------------------------------------------
    health <- reactive({
      cur <- ev_now(); reg <- registered()
      n <- vapply(THEME_EVENTS$event, function(e) count_of(cur, e), numeric(1))
      data.frame(
        Event = THEME_EVENTS$event, `What it means` = THEME_EVENTS$meaning, Count = n,
        Receiving = ifelse(n > 0, "✓ yes", "✗ none yet"),
        `Detail reported` = ifelse(!nzchar(THEME_EVENTS$parameter), "not needed",
                                   ifelse(THEME_EVENTS$parameter %in% reg,
                                          paste("✓", THEME_EVENTS$parameter),
                                          paste("✗", THEME_EVENTS$parameter, "not registered"))),
        check.names = FALSE, stringsAsFactors = FALSE)
    })
    output$health <- DT::renderDT({
      h <- health()
      dt <- DT::datatable(h, rownames = FALSE, class = "compact hover",
                          options = list(dom = "t", pageLength = 20, ordering = FALSE, scrollX = TRUE))
      dt <- DT::formatRound(dt, "Count", 0)
      lv <- unique(c(h$Receiving, h$`Detail reported`))
      cols <- ifelse(grepl("^\u2717", lv), BAD, ifelse(grepl("^\u2713", lv), GOOD, MUTED))
      DT::formatStyle(dt, c("Receiving", "Detail reported"), color = DT::styleEqual(lv, cols))
    })
    output$health_note <- renderUI({
      h <- health()
      missing_dims <- sum(grepl("not registered", h$`Detail reported`))
      tagList(
        if (all(h$Count == 0)) note_box(kind = "warn", icon("exclamation-triangle"),
          " None of the theme's events have arrived in this period. Check that: the theme is version 5.3.0 ",
          "(WordPress > Appearance > Themes); Site Kit is connected to this GA4 property; and your own visit used ",
          tags$code("?ga_debug=1"), " to confirm in DebugView. New events can take 24-48 hours to show in reports."),
        if (missing_dims > 0 && identical(ctx$src()$mode, "live")) note_box(kind = "warn", icon("exclamation-triangle"),
          sprintf(" %d event detail(s) are not registered in GA4, so charts below that need them stay empty. ", missing_dims),
          "Press 'Set up in GA4' - it registers them and marks generate_lead as a key event.")
      )
    })

    output$setup_btn <- renderUI({
      if (!identical(ctx$src()$mode, "live")) return(span(class = "ga-card-sub", "Connect GA4 to set up"))
      actionButton(session$ns("setup"), "Set up in GA4", icon = icon("magic"), class = "btn-primary")
    })
    observeEvent(input$setup, {
      s <- ctx$src()
      res <- tryCatch(
        withProgress(message = "Registering custom dimensions in GA4", value = 0.5,
                     ga_setup_theme_tracking(s$conn, s$property_id)),
        error = function(e) data.frame(item = "Set-up", status = paste("failed:", conditionMessage(e))))
      cat("[EVENTS] GA4 set-up:\n", paste(" -", res$item, "->", res$status, collapse = "\n"), "\n")
      app$metadata <- NULL
      app$refresh <- isolate(app$refresh) + 1
      failed <- grepl("^failed", res$status)
      showModal(modalDialog(title = if (any(failed)) "Set-up finished with problems" else "GA4 is set up for the website events",
        easyClose = TRUE,
        tags$ul(class = "diag", lapply(seq_len(nrow(res)), function(i) {
          ok <- !failed[i]
          tags$li(class = if (ok) "ok" else "fail", icon(if (ok) "check-circle" else "times-circle"),
                  div(div(class = "diag-title", res$item[i]), div(class = "diag-detail", res$status[i])))
        })),
        note_box(icon("info-circle"), " Custom dimensions only collect data from now on - earlier events cannot be ",
                 "broken down by them. Allow 24-48 hours before the new charts fill in."),
        if (any(grepl("403|permission", res$status, ignore.case = TRUE)))
          note_box(kind = "warn", " The service account needs the Editor or Administrator role on the property ",
                   "(Google Analytics > Admin > Property access management)."),
        footer = modalButton("Close")))
    })

    # ---- Trend ----------------------------------------------------------------------
    ev_day <- reactive(ctx$q(c("date", "eventName"), "eventCount", limit = 100000))
    output$trend <- renderPlotly({
      d <- ev_day(); p <- ctx$period(); sel <- input$trend_ev
      validate(need(length(sel) > 0, "Choose one or more events."),
               need(!is.null(d) && any(d$eventName %in% sel), "None of these events in this period."))
      days <- seq(p$start, p$end, by = "day")
      series <- lapply(sel, function(e) complete_days(d[d$eventName == e, , drop = FALSE], p$start, p$end, "eventCount")$eventCount)
      names(series) <- sel
      line_chart(days, series, ytitle = "Events")
    })

    # ---- Breakdown charts -------------------------------------------------------------
    bar_of <- function(d, col, empty) {
      validate(need(!is.null(d) && nrow(d) > 0, empty))
      agg <- sort(tapply(d$eventCount, d[[col]], sum), decreasing = TRUE)
      agg <- agg[names(agg) != "(not set)"]
      validate(need(length(agg) > 0, empty))
      bar_h(names(agg), as.numeric(utils::head(agg, 12)), xtitle = "Clicks")
    }
    cta_where <- reactive({ validate(need_dim("cta_location", "CTA location")); one_event("cta_click", "customEvent:cta_location") })
    output$cta_where <- renderPlotly(bar_of(cta_where(), "customEvent:cta_location", "No CTA clicks in this period."))
    output$cta_which <- renderPlotly(bar_of(one_event("cta_click", "linkText"), "linkText", "No CTA clicks in this period."))
    output$apps <- renderPlotly({
      validate(need_dim("app_name", "Live platform"))
      bar_of(one_event("app_open", "customEvent:app_name"), "customEvent:app_name", "No live platform opens in this period.")
    })
    output$arch <- renderPlotly({
      validate(need_dim("architecture_component", "Architecture component"))
      bar_of(one_event("architecture_select", "customEvent:architecture_component"),
             "customEvent:architecture_component", "Nobody opened a diagram box in this period.")
    })
    output$faq <- renderPlotly({
      validate(need_dim("faq_question", "FAQ question"))
      bar_of(one_event("faq_open", "customEvent:faq_question"), "customEvent:faq_question", "No FAQ questions opened in this period.")
    })
    output$scroll <- renderPlotly({
      validate(need_dim("percent_scrolled", "Scroll depth (%)"))
      d <- one_event("scroll_depth", "customEvent:percent_scrolled")
      views <- pv_tot()$screenPageViews
      validate(need(!is.null(d) && nrow(d) > 0 && views > 0, "No scroll-depth events in this period."))
      depths <- c("25", "50", "75", "100")
      v <- vapply(depths, function(x) sum(d$eventCount[d$`customEvent:percent_scrolled` == x]), numeric(1))
      share <- pmin(1, v / views)
      p <- plot_ly(x = paste0(depths, "%"), y = share, type = "bar", marker = list(color = PAL[1]),
                   text = fmt_pct_vec(share), textposition = "outside", textfont = list(color = INK2),
                   cliponaxis = FALSE, hovertemplate = "%{x}: %{y:.1%} of page views<extra></extra>")
      p <- ga_layout(p, hovermode = "closest")
      layout(p, yaxis = list(tickformat = ".0%", range = c(0, max(share, 0.1) * 1.18)),
             xaxis = list(categoryorder = "array", categoryarray = paste0(depths, "%")), bargap = 0.35)
    })

    cta_pages <- reactive({
      d <- one_event("cta_click", "pagePath", limit = 1000)
      pv <- ctx$q("pagePath", "screenPageViews", limit = 1000)
      if (is.null(d) || nrow(d) == 0) return(NULL)
      agg <- tapply(d$eventCount, d$pagePath, sum)
      out <- data.frame(page = names(agg), clicks = as.numeric(agg), stringsAsFactors = FALSE)
      out$views <- if (is.null(pv)) NA else pv$screenPageViews[match(out$page, pv$pagePath)]
      out$per100 <- 100 * out$clicks / pmax(1, out$views)
      out[order(-out$clicks), , drop = FALSE]
    })
    output$cta_pages <- DT::renderDT({
      d <- cta_pages(); validate(need(!is.null(d), "No CTA clicks in this period."))
      ga_table(d, labels = c(page = "Page", clicks = "CTA clicks", views = "Page views", per100 = "Clicks per 100 views"),
               int = c("clicks", "views"), dec = "per100", page = 8, search = FALSE)
    })
    output$dl_cta_pages <- csv_handler(cta_pages, "cta_by_page")

    nav <- reactive({
      validate(need_dim("nav_location", "Navigation location"))
      d <- one_event("navigation_click", c("customEvent:nav_location", "linkText"), limit = 1000)
      if (is.null(d) || nrow(d) == 0) return(NULL)
      out <- data.frame(where = d$`customEvent:nav_location`, link = d$linkText, clicks = d$eventCount,
                        stringsAsFactors = FALSE)
      out[order(-out$clicks), , drop = FALSE]
    })
    output$nav <- DT::renderDT({
      d <- nav(); validate(need(!is.null(d), "No navigation clicks in this period."))
      ga_table(d, labels = c(where = "Where", link = "Link", clicks = "Clicks"), int = "clicks", page = 8, search = FALSE)
    })
    output$dl_nav <- csv_handler(nav, "navigation_clicks")
  })
}
