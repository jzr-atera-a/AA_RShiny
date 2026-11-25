# ---- page ------------------------------------------------------------
# id:          explorer
# tab label:   Data Explorer
# main group:  Data Explorer   (sidebar; see modules/_module_registry.yml)
# description: build any GA4 report: pick dimensions + metrics, run, chart, export
# functions:   explorer_ui(id), explorer_server(id, ...)
# --------------------------------------------------------------------

EXPLORER_FALLBACK_DIMS <- c("date", "sessionDefaultChannelGroup", "sessionSourceMedium", "country", "city",
                            "deviceCategory", "browser", "operatingSystem", "pagePath", "landingPage",
                            "eventName", "newVsReturning", "dayOfWeek", "hour")

explorer_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card("Build a report", sub = "Uses the date range at the top of the page. Live mode lists every field your property supports.",
      fluidRow(
        column(5, selectizeInput(ns("dims"), "Break down by (up to 3)", choices = NULL, multiple = TRUE,
                                 options = list(maxItems = 3, placeholder = "e.g. Date, Country"))),
        column(5, selectizeInput(ns("mets"), "Numbers to show (up to 6)", choices = NULL, multiple = TRUE,
                                 options = list(maxItems = 6, placeholder = "e.g. Sessions"))),
        column(2, numericInput(ns("limit"), "Max rows", value = 1000, min = 10, max = 100000, step = 100))
      ),
      fluidRow(
        column(3, selectInput(ns("f_field"), "Only rows where", choices = c("(no filter)" = ""))),
        column(2, selectInput(ns("f_match"), " ", choices = c("contains" = "CONTAINS", "is exactly" = "EXACT"))),
        column(3, textInput(ns("f_value"), " ", placeholder = "text to match")),
        column(4, div(class = "btn-row", style = "margin-top:25px;",
          actionButton(ns("run"), "Run report", icon = icon("play"), class = "btn-primary"),
          dl_link(ns("dl"), "Download CSV")))
      )
    ),
    card("Chart", plotlyOutput(ns("chart"), height = "340px")),
    card("Result", uiOutput(ns("meta")), DT::DTOutput(ns("table")))
  )
}

explorer_server <- function(id, ctx, app) {
  moduleServer(id, function(input, output, session) {

    # Field lists: full property metadata when live, demo catalogue otherwise
    fields <- reactive({
      src <- ctx$src()
      if (identical(src$mode, "live")) {
        md <- app$metadata
        if (is.null(md)) {
          md <- tryCatch(ga_metadata(src$conn, src$property_id), error = function(e) {
            cat("[EXPLORER] metadata failed:", conditionMessage(e), "\n"); NULL })
          if (!is.null(md)) app$metadata <- md
        }
        if (!is.null(md) && nrow(md$dimensions) > 0) {
          grp <- function(x) lapply(split(stats::setNames(x$apiName, x$uiName), x$category), as.list)
          return(list(dims = grp(md$dimensions), mets = grp(md$metrics),
                      flat_dims = stats::setNames(md$dimensions$apiName, md$dimensions$uiName)))
        }
        return(list(dims = EXPLORER_FALLBACK_DIMS, mets = names(METRICS), flat_dims = EXPLORER_FALLBACK_DIMS))
      }
      d <- c("date", names(DEMO_DIMS))
      list(dims = d, mets = stats::setNames(DEMO_METRICS, metric_label(DEMO_METRICS)), flat_dims = d)
    })

    observe({
      f <- fields()
      isolate({
        updateSelectizeInput(session, "dims", choices = f$dims, selected = c("date", "sessionDefaultChannelGroup"))
        updateSelectizeInput(session, "mets", choices = f$mets, selected = c("sessions", "totalUsers"))
        updateSelectInput(session, "f_field", choices = c("(no filter)" = "", f$flat_dims))
      })
    })

    result <- eventReactive(input$run, {
      dims <- input$dims %||% character(0); mets <- input$mets
      validate(need(length(mets) > 0, "Choose at least one number to show."))
      flt <- if (nzchar(input$f_field %||% "") && nzchar(trimws(input$f_value %||% ""))) {
        list(field = input$f_field, match = input$f_match, value = trimws(input$f_value))
      } else NULL
      lim <- max(10, min(100000, as.integer(input$limit %||% 1000), na.rm = TRUE))
      ctx$q(dims, mets, limit = lim, filter = flt)
    })

    output$meta <- renderUI({
      d <- result()
      tags$p(class = "ga-card-sub", sprintf("%s row(s)%s", fmt_int(nrow(d)),
        if (nrow(d) >= (input$limit %||% 1000)) " - hit the row limit, raise 'Max rows' to see more" else ""))
    })

    output$table <- DT::renderDT({
      d <- result(); validate(need(nrow(d) > 0, "The report came back empty."))
      num  <- names(d)[vapply(d, is.numeric, logical(1))]
      rate <- num[vapply(num, function(n) max(abs(d[[n]]), na.rm = TRUE) <= 1 && any(d[[n]] %% 1 != 0, na.rm = TRUE), logical(1))]
      ga_table(d, int = setdiff(num, c(rate, "hour", "dayOfWeek")), pct = rate, page = 15)
    })
    output$dl <- csv_handler(function() tryCatch(result(), error = function(e) NULL), "explorer")

    output$chart <- renderPlotly({
      d <- result(); validate(need(nrow(d) > 0, "Nothing to chart."))
      dims <- intersect(isolate(input$dims) %||% character(0), names(d))
      mets <- intersect(isolate(input$mets), names(d))
      m <- mets[1]
      other <- setdiff(dims, "date")
      if ("date" %in% dims) {
        days <- sort(unique(d$date))
        if (length(other) == 0) {
          v <- as.numeric(tapply(d[[m]], format(d$date), sum)[format(days)])
          return(line_chart(days, stats::setNames(list(v), metric_label(m)), ytitle = metric_label(m)))
        }
        d$grp <- do.call(paste, c(unname(as.list(d[other])), sep = " / "))
        top <- top_groups(d, "grp", m, 6)
        series <- lapply(top, function(g) {
          x <- d[d$grp == g, , drop = FALSE]
          v <- as.numeric(tapply(x[[m]], format(x$date), sum)[format(days)]); v[is.na(v)] <- 0; v
        })
        names(series) <- trunc_lab(top, 30)
        return(line_chart(days, series, ytitle = metric_label(m)))
      }
      validate(need(length(dims) > 0, "Add a 'Break down by' field to draw a chart."))
      d$grp <- do.call(paste, c(unname(as.list(d[dims])), sep = " / "))
      agg <- sort(tapply(d[[m]], d$grp, sum), decreasing = TRUE)
      agg <- utils::head(agg, 20)
      bar_h(names(agg), as.numeric(agg), xtitle = metric_label(m))
    })
  })
}
