# ============================================================================
# ATERA ANALYTICS DASHBOARD
# Run with: open this file in RStudio and press Run App  (or shiny::runApp())
#
# Navigation comes from modules/_module_registry.yml: each sidebar item is a
# main group, and the group's pages are tabs across the top of the page.
# One file per page: modules/<group folder>/<page id>.R   (see README.md)
# ============================================================================

APP_DIR <- getwd()
APP_VERSION <- "5.0.0"

source("core/debug_capture.R", local = TRUE)          # first, so start-up output is captured too

required <- c("shiny", "shinydashboard", "plotly", "DT", "httr", "jsonlite", "yaml")
missing_pkgs <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs)) {
  stop("Install these packages first: install.packages(c(",
       paste0('"', missing_pkgs, '"', collapse = ", "), "))", call. = FALSE)
}

library(shiny)
library(shinydashboard)
library(plotly)

# Pin the functions this app relies on to the right package. Without this, a
# package loaded earlier in the same R session can replace them - e.g.
# jsonlite::validate() hides shiny::validate() and breaks every chart with
# "is.character(txt) is not TRUE"; httr::config() hides plotly::config().
validate     <- shiny::validate
need         <- shiny::need
req          <- shiny::req
layout       <- plotly::layout
config       <- plotly::config
plot_ly      <- plotly::plot_ly
add_trace    <- plotly::add_trace
renderPlotly <- plotly::renderPlotly
plotlyOutput <- plotly::plotlyOutput

source("core/helpers.R", local = TRUE)
source("core/ga4_api.R", local = TRUE)
source("core/demo_data.R", local = TRUE)
source("core/analytics.R", local = TRUE)
source("core/gdrive.R", local = TRUE)
source("core/chart_export.R", local = TRUE)
source("core/nav.R", local = TRUE)

NAV <- nav_load()
nav_source(NAV, environment())

# Labels used when charts are saved (folder names in Google Drive, file subtitles)
chart_pages <- NAV$pages[NAV$pages$charts, ]
TAB_LABELS <- stats::setNames(chart_pages$label, chart_pages$id)
TAB_GROUPS <- stats::setNames(chart_pages$group, chart_pages$id)

cat("[APP] Atera Analytics dashboard", APP_VERSION, "-", nrow(NAV$pages), "pages in", length(NAV$groups), "groups\n")

# ============================================================================
# UI
# ============================================================================
ui <- dashboardPage(
  skin = "blue",
  title = paste("Atera Analytics", APP_VERSION),
  dashboardHeader(
    title = tags$span(class = "brand", tags$span(class = "brand-mark", "A"), "Atera Analytics"),
    tags$li(class = "dropdown",
      tags$a(href = "#", class = "save-tab-link", onclick = "ateraSaveTab(); return false;",
             title = "Save every chart on this page to Google Drive or your computer",
             icon("upload"), " Save charts"))),
  dashboardSidebar(
    nav_sidebar(NAV),
    div(class = "sidebar-foot", paste("Version", APP_VERSION))
  ),
  dashboardBody(
    tags$head(
      includeCSS("www/styles.css"),
      tags$script(src = "vendor/jspdf.umd.min.js"),
      tags$script(src = "vendor/jszip.min.js"),
      tags$script(src = "vendor/gifenc.js"),
      tags$script(src = "export.js")
    ),
    uiOutput("mode_banner"),
    conditionalPanel(
      condition = nav_period_condition(NAV),
      div(class = "control-bar",
        selectInput("preset", "Period", selected = "28", width = "190px",
          choices = c("Last 7 days" = "7", "Last 28 days" = "28", "Last 90 days" = "90",
                      "This month so far" = "mtd", "Last month" = "lastmonth",
                      "This year so far" = "ytd", "Custom dates" = "custom")),
        conditionalPanel("input.preset == 'custom'",
          dateRangeInput("custom_range", "Dates", start = Sys.Date() - 28, end = Sys.Date() - 1,
                         max = Sys.Date(), width = "250px")),
        selectInput("compare", "Compare with", selected = "previous", width = "210px",
          choices = c("Previous period" = "previous", "Same period last year" = "year",
                      "No comparison" = "none")),
        div(class = "control-meta", uiOutput("period_label"))
      )
    ),
    nav_body(NAV, environment())
  )
)

# ============================================================================
# SERVER
# ============================================================================
server <- function(input, output, session) {

  app <- reactiveValues(conn = NULL, property_id = NULL, mode = "demo",
                        properties = NULL, metadata = NULL, refresh = 0)

  drive <- reactiveValues(d = NULL, status = "off", root_name = NULL, root_link = NULL,
                          scheme = DEFAULT_SCHEME, history = NULL, tick = 0)

  src <- reactive(list(mode = app$mode, conn = app$conn, property_id = app$property_id))

  period <- reactive({
    rng <- resolve_range(input$preset, input$custom_range)
    cmp_mode <- input$compare %||% "previous"
    cmp <- compare_range(rng[1], rng[2], cmp_mode)
    list(start = rng[1], end = rng[2], compare = cmp_mode,
         cmp_start = cmp[1], cmp_end = cmp[2],
         compare_label = switch(cmp_mode, previous = "the previous period",
                                year = "the same period last year", "no comparison"))
  })

  # The one function every page uses to get data. range = "cur", "prev" or c(start, end).
  # Returns NULL for "prev" when no comparison is selected.
  q <- function(dims = character(0), mets, range = "cur", limit = 10000,
                order_by = NULL, desc = TRUE, filter = NULL) {
    p <- period(); s <- src(); app$refresh
    rng <- if (is.character(range)) {
      if (identical(range, "prev")) {
        if (p$compare == "none") return(NULL)
        c(p$cmp_start, p$cmp_end)
      } else c(p$start, p$end)
    } else range
    tryCatch(
      ga_query(s, dims, mets, rng[1], rng[2], limit, order_by, desc, filter),
      error = function(e) {
        cat("[QUERY ERROR]", conditionMessage(e), "\n")
        validate(need(FALSE, conditionMessage(e)))
      })
  }
  ctx <- list(q = q, period = period, src = src)

  output$mode_banner <- renderUI({
    if (identical(app$mode, "live")) {
      div(class = "mode-banner live", icon("check-circle"),
          sprintf(" Live data - GA4 property %s", app$property_id))
    } else {
      div(class = "mode-banner demo", icon("exclamation-triangle"),
          " Demo data - these numbers are invented. Connect your key in ",
          actionLink("go_settings", "API Configuration > Google Analytics"), " to see real visitors.")
    }
  })
  observeEvent(input$go_settings, nav_goto(session, NAV, "settings"))

  output$period_label <- renderUI({
    p <- period()
    tagList(
      div(sprintf("%s - %s", format(p$start, "%d %b %Y"), format(p$end, "%d %b %Y"))),
      if (p$compare != "none")
        div(class = "muted", sprintf("vs %s - %s", format(p$cmp_start, "%d %b %Y"), format(p$cmp_end, "%d %b %Y")))
    )
  })

  nav_start_servers(NAV, environment(server), deps = list(ctx = ctx, app = app, drive = drive))
  chart_export_server(input, output, session, app, drive, period)

  cat("[APP] Session started\n")
}

shinyApp(ui = ui, server = server)
