# modules/econ_calendar_viz.R
#
# "Visualisation" — queries the BigQuery economic_calendar_summary table with
# date range + asset class + specific asset filters, showing a self-joined
# view so each main event's linked prior/current-week context rows are
# visible alongside it.

econ_calendar_viz_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ua_intro("Economic Calendars", "Visualisation", "\u2014", "\u2014",
             "Filter and browse the stored economic-calendar data by date and asset class/asset."),

    fluidRow(
      box(title = "Filters", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, dateRangeInput(ns("dateRange"), "Event date range:",
                                      start = Sys.Date() - 14, end = Sys.Date() + 7)),
            column(3, selectInput(ns("assetClass"), "Asset class:",
                                   choices = c("All", "Commodities", "Forex", "Crypto", "Tech Equity"))),
            column(3, selectizeInput(ns("specificAsset"), "Specific asset:", choices = c("All"))),
            column(3, style = "padding-top:25px;",
                   actionButton(ns("refresh"), "Load / Refresh", icon = icon("rotate"), class = "btn-primary", width = "100%"))
          )
      )
    ),

    fluidRow(
      box(title = "Calendar Data", status = "success", solidHeader = TRUE, width = 12,
          uiOutput(ns("loadStatus")),
          withSpinner(DT::dataTableOutput(ns("vizTable")))
      )
    )
  )
}

econ_calendar_viz_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # Populate the specific-asset dropdown dynamically once we have data,
    # narrowed by whichever asset class is currently selected.
    observeEvent(input$assetClass, {
      if (!isTRUE(api_manager$bq_authenticated)) return()
      tryCatch({
        where <- if (input$assetClass != "All") sprintf("WHERE asset_class = '%s'", input$assetClass) else ""
        d <- api_manager$bq_query(sprintf(
          "SELECT DISTINCT specific_asset FROM `%s` %s ORDER BY specific_asset", api_manager$bq_full_table_economic_calendar, where))
        choices <- c("All", if (nrow(d) > 0) d$specific_asset else character(0))
        updateSelectizeInput(session, "specificAsset", choices = choices, selected = "All")
      }, error = function(e) {})
    })

    observeEvent(input$refresh, {
      if (!isTRUE(api_manager$bq_authenticated)) {
        output$loadStatus <- renderUI(tags$div(style="color:#c0392b;",
          "Configure BigQuery credentials on the API Configuration \u2192 BigQuery tab first."))
        return()
      }
      output$loadStatus <- renderUI(tags$div(style="color:#2980b9;", icon("spinner", class="fa-spin"), " Loading..."))

      tryCatch({
        d <- api_manager$bq_get_economic_calendar(
          date_from      = as.character(input$dateRange[1]),
          date_to        = as.character(input$dateRange[2]),
          asset_class    = input$assetClass,
          specific_asset = input$specificAsset
        )

        if (nrow(d) == 0) {
          output$loadStatus <- renderUI(tags$div(style="color:#e67e22;", "No rows match these filters."))
          output$vizTable <- DT::renderDataTable(DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE))
          return()
        }

        # Human-readable "linked to" column: resolve linked_to_event_id back
        # to that main event's name, so the table reads clearly without a
        # manual join.
        main_lookup <- setNames(d$event_name[d$event_role == "MAIN"], d$event_id[d$event_role == "MAIN"])
        d$linked_to_event_name <- ifelse(
          !is.na(d$linked_to_event_id) & d$linked_to_event_id %in% names(main_lookup),
          main_lookup[d$linked_to_event_id], NA_character_
        )

        display_cols <- c("event_date", "event_name", "event_role", "linked_to_event_name",
                           "event_importance", "asset_class", "specific_asset",
                           "impact_direction", "impact_rationale", "event_description", "source")
        display_cols <- intersect(display_cols, names(d))

        output$loadStatus <- renderUI(tags$div(style="color:#27ae60;", sprintf("%d row(s) loaded", nrow(d))))
        output$vizTable <- DT::renderDataTable({
          DT::datatable(
            d[, display_cols],
            options = list(scrollX = TRUE, pageLength = 20, order = list(list(0, 'desc'))),
            rownames = FALSE,
            colnames = c("Event Date", "Event", "Role", "Linked To (Main Event)", "Importance",
                         "Asset Class", "Asset", "Impact", "Rationale", "Description", "Source")
          ) %>% DT::formatStyle("event_role", target = "row",
                                  backgroundColor = DT::styleEqual(c("MAIN", "CONTEXT"), c("#eafaf1", "#ffffff")))
        })
      }, error = function(e) {
        output$loadStatus <- renderUI(tags$div(style="color:#c0392b;", "Query failed: ", e$message))
      })
    })

    output$loadStatus <- renderUI(tags$div())
    output$vizTable <- DT::renderDataTable(DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE))
  })
}
