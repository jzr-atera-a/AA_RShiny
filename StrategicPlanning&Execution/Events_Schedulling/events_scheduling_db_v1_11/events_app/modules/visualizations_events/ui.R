# modules/visualizations_events/ui.R

visualizations_events_ui <- function(id) {
  ns <- NS(id)

  tagList(

    # ── Filter Panel ──────────────────────────────────────────
    fluidRow(
      box(
        title = "Filter Events", status = "primary", solidHeader = TRUE, width = 12,

        p(style = "color: #7f8c8d; font-size: 0.85em; margin-bottom: 8px;",
          icon("info-circle"),
          " These dropdowns mirror the values used when scanning events. Leave at 'All' to include everything."),

        fluidRow(
          column(3, selectInput(ns("viz_country"),     "Country:",    choices = c("All" = ""))),
          column(3, selectInput(ns("viz_city"),        "City:",       choices = c("All" = ""))),
          column(3, selectInput(ns("viz_category"),    "Category:",   choices = c("All" = ""))),
          column(3, selectInput(ns("viz_subcategory"), "Subcategory:",choices = c("All" = "")))
        ),

        fluidRow(
          column(4,
                 dateRangeInput(ns("date_range"), "Event Date Range:",
                                start  = Sys.Date() - 30,
                                end    = Sys.Date() + 90,
                                format = "yyyy-mm-dd"),
                 p(style = "color: #7f8c8d; font-size: 0.8em; margin-top: -6px;",
                   "Filters on ", tags$strong("event_date"), " — when the event occurs")
          ),
          column(4,
                 selectInput(ns("viz_scan_date"), "Inserted on (Scan Date):",
                             choices = c("All" = ""), width = "100%"),
                 p(style = "color: #7f8c8d; font-size: 0.8em; margin-top: -6px;",
                   "Filters on ", tags$strong("scan_date"), " — date the row was written to BigQuery")
          ),
          column(2,
                 br(),
                 actionButton(ns("load_viz"), "Load Visualizations",
                              class = "btn-success btn-lg", icon = icon("chart-bar"),
                              style = "width: 100%;")
          ),
          column(2,
                 br(),
                 htmlOutput(ns("status")))
        )
      )
    ),

    # ── Summary Cards ─────────────────────────────────────────
    fluidRow(
      column(3, valueBoxOutput(ns("total_events"),      width = 12)),
      column(3, valueBoxOutput(ns("total_cities"),      width = 12)),
      column(3, valueBoxOutput(ns("total_categories"),  width = 12)),
      column(3, valueBoxOutput(ns("upcoming_events"),   width = 12))
    ),

    # ── Tabbed Views — Events Detail FIRST, Map LAST ──────────
    fluidRow(
      box(
        title = NULL, status = "info", solidHeader = FALSE, width = 12,

        tabsetPanel(
          id = ns("viz_tabs"),

          # ── TAB 1: EVENT CARDS (default) ────────────────────
          tabPanel(
            title = tagList(icon("list-alt"), " Event Details"),
            br(),
            uiOutput(ns("event_cards"))
          ),

          # ── TAB 2: CALENDAR ─────────────────────────────────
          tabPanel(
            title = tagList(icon("calendar-alt"), " Calendar View"),
            br(),
            fluidRow(
              column(3,
                     selectInput(ns("cal_month"), "Month:",
                                 choices = setNames(
                                   format(seq(as.Date("2025-01-01"), by = "month", length.out = 36), "%Y-%m"),
                                   format(seq(as.Date("2025-01-01"), by = "month", length.out = 36), "%b %Y")
                                 ),
                                 selected = format(Sys.Date(), "%Y-%m"))
              ),
              column(9, htmlOutput(ns("calendar_html")))
            )
          ),

          # ── TAB 3: CHARTS ───────────────────────────────────
          tabPanel(
            title = tagList(icon("chart-bar"), " Charts"),
            br(),
            fluidRow(
              box(title = "Events by Category", status = "warning", solidHeader = TRUE, width = 6,
                  plotly::plotlyOutput(ns("category_chart"), height = "350px")),
              box(title = "Events by Week (Timeline)", status = "success", solidHeader = TRUE, width = 6,
                  plotly::plotlyOutput(ns("timeline_chart"), height = "350px"))
            )
          ),

          # ── TAB 4: MAP (last) ────────────────────────────────
          tabPanel(
            title = tagList(icon("map-marker-alt"), " Map View"),
            br(),
            uiOutput(ns("map_or_message"))
          )
        )
      )
    )
  )
}
