# modules/econ_calendar_viz.R
#
# "Visualisation" — queries the BigQuery economic_calendar_summary table with
# date range + asset class + specific asset filters, showing a self-joined
# view so each main event's linked prior/current-week context rows are
# visible alongside it.
#
# Grid rendering: a custom sticky-header / sticky-first-column / checkerboard
# HTML table (not DT), matching the professional look of the FlexTable app's
# comparison grid — frozen header row, frozen first column, alternating row
# shading, and a column-width slider, all in a single scrollable container.

econ_viz_grid_html <- function(d, display_cols, col_labels, column_width_ch) {
  role_badge <- function(role) {
    if (identical(role, "MAIN")) {
      "<span style=\"display:inline-block; padding:2px 9px; border-radius:10px; font-size:10.5px; font-weight:700; background:#eafaf1; color:#1e8449;\">MAIN</span>"
    } else {
      "<span style=\"display:inline-block; padding:2px 9px; border-radius:10px; font-size:10.5px; font-weight:700; background:#f2f4f7; color:#5a6b7a;\">CONTEXT</span>"
    }
  }
  impact_color <- function(impact) {
    switch(impact %||% "",
      "Bullish" = "#1e8449", "Bearish" = "#c0392b", "Mixed" = "#b7791f", "#5a6b7a")
  }

  header_html <- paste0(
    "<th class=\"econ-grid-sticky-col\">", htmltools::htmlEscape(col_labels[1]), "</th>",
    paste(sprintf("<th>%s</th>", vapply(col_labels[-1], htmltools::htmlEscape, character(1))), collapse = "")
  )

  rows_html <- vapply(seq_len(nrow(d)), function(i) {
    row <- d[i, ]
    first_cell <- sprintf("<th class=\"econ-grid-sticky-col\">%s</th>", htmltools::htmlEscape(as.character(row[[display_cols[1]]])))
    other_cells <- vapply(display_cols[-1], function(col) {
      val <- row[[col]]
      cell_style <- sprintf("max-width:%dch;", column_width_ch)
      if (col == "event_role") {
        return(sprintf("<td style=\"%s\">%s</td>", cell_style, role_badge(val)))
      }
      if (col == "impact_direction") {
        return(sprintf("<td style=\"%s color:%s; font-weight:700;\">%s</td>", cell_style, impact_color(val), htmltools::htmlEscape(as.character(val %||% ""))))
      }
      sprintf("<td style=\"%s\">%s</td>", cell_style, htmltools::htmlEscape(as.character(val %||% "")))
    }, character(1))
    paste0("<tr>", first_cell, paste(other_cells, collapse = ""), "</tr>")
  }, character(1))

  HTML(paste0(
    "<div class=\"econ-grid-outer\">",
    "<p style=\"font-size:12px; color:#64748b; margin-bottom:8px;\">", nrow(d), " row(s) \u00b7 ",
    length(display_cols), " columns \u00b7 scroll to see more</p>",
    "<div class=\"econ-grid-scroll\"><table class=\"econ-grid-table\"><thead><tr>", header_html, "</tr></thead>",
    "<tbody>", paste(rows_html, collapse = ""), "</tbody></table></div></div>"
  ))
}

econ_calendar_viz_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ua_intro("Economic Calendars", "Visualisation", "\u2014", "\u2014",
             "Filter and browse the stored economic-calendar data by date and asset class/asset."),

    fluidRow(
      box(title = "Filters", status = "primary", solidHeader = TRUE, width = 12,
          class = "controls-box-elevated",
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
          sliderInput(ns("columnWidth"), "Column Width (characters):",
                      min = 30, max = 110, value = 70, step = 10, width = "100%"),
          tags$p("Adjusts how wide each column is before text wraps to the next line.",
                 style = "color:#7f8c8d; font-size:12px; margin-top:-10px;"),
          withSpinner(uiOutput(ns("vizGrid"))),
          tags$hr(),
          actionButton(ns("sendToLiveSignals"), "Send to Live Signals", icon = icon("share-from-square"),
                       class = "btn-warning", width = "100%"),
          tags$p("Sends exactly what's currently loaded above (respecting your date range / asset class / asset filters) to Unit 3 \u2192 Live Signals for analysis.",
                 style = "color:#7f8c8d; font-size:11.5px; margin-top:6px;"),
          uiOutput(ns("sendStatus"))
      )
    )
  )
}

econ_calendar_viz_server <- function(id, api_manager, shared_econ_state) {
  moduleServer(id, function(input, output, session) {

    loaded_data <- reactiveVal(NULL)

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
          loaded_data(NULL)
          return()
        }

        # Human-readable "linked to" column: resolve linked_to_event_id back
        # to that main event's name, so the table reads clearly without a
        # manual join.
        main_lookup <- setNames(d$event_name[d$event_role == "MAIN"], d$event_id[d$event_role == "MAIN"])
        d$linked_to_event_name <- ifelse(
          !is.na(d$linked_to_event_id) & d$linked_to_event_id %in% names(main_lookup),
          main_lookup[d$linked_to_event_id], ""
        )

        output$loadStatus <- renderUI(tags$div(style="color:#27ae60;", sprintf("%d row(s) loaded", nrow(d))))
        loaded_data(d)
      }, error = function(e) {
        output$loadStatus <- renderUI(tags$div(style="color:#c0392b;", "Query failed: ", e$message))
        loaded_data(NULL)
      })
    })

    output$vizGrid <- renderUI({
      d <- loaded_data()
      if (is.null(d)) return(tags$div(class = "status-info", style = "color:#7f8c8d; padding:20px; text-align:center;",
                                        "Set your filters above and click Load / Refresh."))

      display_cols <- c("event_date", "event_name", "event_role", "linked_to_event_name",
                         "event_importance", "asset_class", "specific_asset",
                         "impact_direction", "impact_rationale", "event_description", "source")
      display_cols <- intersect(display_cols, names(d))
      col_labels <- c("Event Date", "Event", "Role", "Linked To (Main Event)", "Importance",
                       "Asset Class", "Asset", "Impact", "Rationale", "Description", "Source")
      col_labels <- col_labels[seq_along(display_cols)]

      d_sorted <- d[order(d$event_date, decreasing = TRUE), ]
      econ_viz_grid_html(d_sorted, display_cols, col_labels, input$columnWidth %||% 70)
    })

    observeEvent(input$sendToLiveSignals, {
      d <- loaded_data()
      if (is.null(d) || nrow(d) == 0) {
        output$sendStatus <- renderUI(tags$div(style="color:#e67e22; margin-top:6px;",
          "Nothing loaded to send \u2014 click Load / Refresh first."))
        return()
      }
      shared_econ_state$transfer_df <- d
      shared_econ_state$transfer_asset_class <- input$assetClass
      shared_econ_state$transfer_ts <- shared_econ_state$transfer_ts + 1
      output$sendStatus <- renderUI(tags$div(style="color:#27ae60; margin-top:6px;",
        icon("check-circle"), sprintf(" Sent %d row(s) (asset class: %s) to Unit 3 \u2192 Live Signals.", nrow(d), input$assetClass)))
      showNotification(sprintf("\u2713 Sent %d row(s) to Live Signals", nrow(d)), type = "message")
    })

    output$loadStatus <- renderUI(tags$div())
    output$sendStatus <- renderUI(tags$div())
  })
}
