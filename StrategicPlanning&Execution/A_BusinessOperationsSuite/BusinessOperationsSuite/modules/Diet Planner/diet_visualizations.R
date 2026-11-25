# modules/Diet Planner/diet_visualizations.R
# ---- module ----------------------------------------------
# id:           diet_visualizations
# name:         Visualizations
# icon:         chart-pie
# description:  Daily nutrition timeline and macro chart
# packages:     shiny, shinydashboard, DT, plotly
# -----------------------------------------------------------

# ---- UI ----
diet_visualizations_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Select a Day to Visualize", status = "primary", solidHeader = TRUE, width = 12,
          p("Filter by Diet Type to find the logged day you want, then load its meal timeline."),
          fluidRow(
            column(4, selectInput(ns("viz_diet_type"), "Diet Type:", choices = NULL)),
            column(4, selectInput(ns("select_date"), "Date:", choices = NULL)),
            column(4, selectInput(ns("filter_row_type"), "Filter by Row Type (Optional):", choices = c("All Rows" = "all")))
          ),
          fluidRow(column(12, actionButton(ns("load_viz"), "Load Visualizations",
                                          class = "btn-success btn-lg", icon = icon("chart-pie"), style = "width: 100%;"))),
          hr(), htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(title = "Day Overview", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          htmlOutput(ns("day_header")),
          fluidRow(
            column(3, valueBoxOutput(ns("total_meals"), width = 12)),
            column(3, valueBoxOutput(ns("total_calories"), width = 12)),
            column(3, valueBoxOutput(ns("diet_type_box"), width = 12)),
            column(3, valueBoxOutput(ns("total_entries"), width = 12))
          )
      )
    ),

    fluidRow(
      box(title = "Meal Timeline", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE,
          htmlOutput(ns("timeline_html")))
    ),

    fluidRow(
      box(title = "Macro Breakdown per Meal", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE,
          plotlyOutput(ns("macro_chart"), height = "500px"))
    ),

    generic_export_box_ui(ns, title = "Save This Day's Diet Log", ics = TRUE),
    drive_export_ui(ns)
  )
}

# Chart data for the macro chart: one row per meal with parsable macros. Shared by the in-app chart and the Drive diagram.
diet_chart_data <- function(d) {
  meal_rows <- d[d$row_type == "Meal", ]
  chart_data <- data.frame(meal = character(), protein = numeric(), carbs = numeric(), fat = numeric(), stringsAsFactors = FALSE)
  for (i in seq_len(nrow(meal_rows))) {
    row <- meal_rows[i, ]
    macros <- diet_parse_calories_macros(row$calories_macros)
    if (!is.na(macros$protein) || !is.na(macros$carbs) || !is.na(macros$fat)) {
      chart_data <- rbind(chart_data, data.frame(
        meal = paste0(row$row_sequence, ". ", row$meal_name),
        protein = macros$protein %||% 0, carbs = macros$carbs %||% 0, fat = macros$fat %||% 0,
        stringsAsFactors = FALSE))
    }
  }
  chart_data
}

# Diagram of the macro chart for the Save-to-Google-Drive box.
diet_diagram_macros <- function(d) {
  cd <- diet_chart_data(d)
  dg_bar(paste0("Macro breakdown per meal (g) - ", d$log_date[1]), cd$meal,
         list(list(name = "Protein (g)", values = cd$protein, color = "#008A82"),
              list(name = "Carbs (g)", values = cd$carbs, color = "#2E86C1"),
              list(name = "Fat (g)", values = cd$fat, color = "#E67E22")),
         subtitle = paste0(length(cd$meal), " meals with macros"), stacked = TRUE, y_title = "Grams", table = cd)
}

# ---- Server ----
diet_visualizations_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    viz_data <- reactiveVal(NULL)

    viz_taxonomy <- reactive({
      api_manager$tab_gate("diet_visualizations")     # loads when this tab is first opened, not before
      api_manager$state_trigger_diet()
      if (!api_manager$bq_authenticated) return(data.frame(diet_type = character(), stringsAsFactors = FALSE))
      tryCatch(api_manager$bq_get_diet_taxonomy(), error = function(e) data.frame(diet_type = character(), stringsAsFactors = FALSE))
    })

    observeEvent(viz_taxonomy(), {
      tax <- viz_taxonomy()
      diet_types <- sort(unique(tax$diet_type[nchar(trimws(tax$diet_type)) > 0]))
      if (length(diet_types) == 0) {
        updateSelectInput(session, "viz_diet_type", choices = c("(no diet logs yet)" = ""))
      } else {
        current <- isolate(input$viz_diet_type)
        selected <- if (!is.null(current) && current %in% diet_types) current else diet_types[1]
        updateSelectInput(session, "viz_diet_type", choices = setNames(diet_types, diet_types), selected = selected)
      }
    }, ignoreNULL = FALSE)

    observeEvent(input$viz_diet_type, {
      if (is.null(input$viz_diet_type) || input$viz_diet_type == "") {
        updateSelectInput(session, "select_date", choices = c("(select a diet type first)" = ""))
        return()
      }
      dates <- tryCatch({
        safe_dt <- safe_sql_escape(input$viz_diet_type)
        r <- api_manager$bq_query(sprintf(
          "SELECT DISTINCT log_date FROM `%s` WHERE diet_type = '%s' ORDER BY log_date DESC",
          api_manager$bq_full_table_diet, safe_dt))
        r$log_date
      }, error = function(e) character())

      if (length(dates) == 0) updateSelectInput(session, "select_date", choices = c("(no dates found)" = ""))
      else updateSelectInput(session, "select_date", choices = setNames(dates, dates))
    }, ignoreInit = TRUE)

    observeEvent(input$select_date, {
      if (!api_manager$bq_authenticated || is.null(input$select_date) || input$select_date == "") return()
      tryCatch({
        safe_date <- safe_sql_escape(input$select_date)
        query <- sprintf("SELECT DISTINCT row_type FROM `%s` WHERE log_date = '%s' ORDER BY row_type",
                         api_manager$bq_full_table_diet, safe_date)
        row_types <- api_manager$bq_query(query)
        if (nrow(row_types) > 0) {
          updateSelectInput(session, "filter_row_type", choices = c("All Rows" = "all", setNames(row_types$row_type, row_types$row_type)))
        }
      }, error = function(e) {})
    })

    observeEvent(input$load_viz, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      if (is.null(input$select_date) || input$select_date == "") { showNotification("Please select a date!", type = "warning"); return() }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading visualization data...") })

      tryCatch({
        safe_date <- safe_sql_escape(input$select_date)
        query <- if (input$filter_row_type == "all") {
          sprintf("SELECT * FROM `%s` WHERE log_date = '%s' ORDER BY row_sequence", api_manager$bq_full_table_diet, safe_date)
        } else {
          sprintf("SELECT * FROM `%s` WHERE log_date = '%s' AND row_type = '%s' ORDER BY row_sequence",
                  api_manager$bq_full_table_diet, safe_date, safe_sql_escape(input$filter_row_type))
        }
        data <- api_manager$bq_query(query)

        if (nrow(data) == 0) {
          output$status <- renderUI({ tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"), " No data found") })
          return()
        }

        viz_data(data)

        output$day_header <- renderUI({
          tags$div(class = "book-header", tags$h2(data$log_date[1]),
                   tags$div(class = "author", tags$i(class = "fa fa-utensils"), " ", data$diet_type[1]))
        })

        output$total_meals <- renderValueBox({ valueBox(sum(data$row_type == "Meal"), "Meals", icon = icon("utensils"), color = "aqua") })

        summary_row <- data[data$row_type == "Summary", ]
        total_cal_val <- if (nrow(summary_row) > 0) summary_row$calories_macros[1] else "—"
        output$total_calories <- renderValueBox({ valueBox(total_cal_val, "Total Calories/Macros", icon = icon("fire"), color = "yellow") })

        output$diet_type_box <- renderValueBox({ valueBox(data$diet_type[1], "Diet Type", icon = icon("tag"), color = "green") })
        output$total_entries <- renderValueBox({ valueBox(nrow(data), "Total Entries", icon = icon("database"), color = "blue") })

        output$timeline_html <- renderUI({
          d <- viz_data(); req(!is.null(d))
          html_parts <- c('<div class="viz-card">')
          html_parts <- c(html_parts, sprintf('<div class="chapter-title"><i class="fa fa-calendar-day"></i> %s Meal Plan</div>', as.character(d$log_date[1])))

          row_icon <- function(rt) switch(rt, "Meal" = "fa fa-utensils", "Summary" = "fa fa-flag-checkered", "fa fa-circle")

          for (i in seq_len(nrow(d))) {
            row <- d[i, ]
            html_parts <- c(html_parts, sprintf('<div class="section-tag"><i class="%s"></i> %s: %s</div>',
                                                row_icon(as.character(row$row_type)), as.character(row$row_type), as.character(row$meal_name)))
            html_parts <- c(html_parts, sprintf('<div class="details-text">%s</div>', as.character(row$meal_details)))

            if (has_real_value(row$meal_time)) {
              html_parts <- c(html_parts, sprintf(
                '<div class="metric-box"><div class="metric-label">Meal Time</div><div class="metric-value" style="font-size: 1em;">%s</div></div>',
                as.character(row$meal_time)))
            }
            if (has_real_value(row$calories_macros)) {
              html_parts <- c(html_parts, sprintf(
                '<div class="metric-box"><div class="metric-label">Calories / Macros</div><div class="metric-value" style="font-size: 1em;">%s</div></div>',
                as.character(row$calories_macros)))
            }
            if (has_real_value(row$observations)) {
              html_parts <- c(html_parts, '<div class="reference-box">')
              html_parts <- c(html_parts, sprintf('<h5><i class="fa fa-lightbulb"></i> %s</h5>', if (row$row_type == "Summary") "Key Insights" else "Notes"))
              html_parts <- c(html_parts, sprintf('<p style="margin-top: 8px; color: #555;">%s</p>', as.character(row$observations)))
              html_parts <- c(html_parts, '</div>')
            }
            if (i < nrow(d)) html_parts <- c(html_parts, '<hr style="margin: 20px 0; border-top: 1px solid #e0e0e0;">')
          }
          html_parts <- c(html_parts, '</div>')
          HTML(paste(html_parts, collapse = ""))
        })

        output$macro_chart <- renderPlotly({
          d <- viz_data(); req(!is.null(d))
          chart_data <- diet_chart_data(d)

          if (nrow(chart_data) == 0) return(plot_ly() %>% layout(title = "No parsable macro data available"))

          chart_data$meal <- factor(chart_data$meal, levels = chart_data$meal)
          plot_ly(chart_data, x = ~meal, y = ~protein, type = 'bar', name = 'Protein (g)', marker = list(color = '#008A82')) %>%
            add_trace(y = ~carbs, name = 'Carbs (g)', marker = list(color = '#00A39A')) %>%
            add_trace(y = ~fat, name = 'Fat (g)', marker = list(color = '#f39c12')) %>%
            layout(barmode = 'stack', title = "Macro Breakdown per Meal (g)",
                   xaxis = list(title = "", tickangle = -35), yaxis = list(title = "Grams"))
        })

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded visualizations for %s (%d entries)", data$log_date[1], nrow(data)))
        })
        showNotification("✓ Visualizations loaded!", type = "message")

      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$status <- renderUI({ tags$div() })
    output$day_header <- renderUI({ tags$div() })
    output$timeline_html <- renderUI({ tags$div() })
    output$macro_chart <- renderPlotly({ plot_ly() })
    output$total_meals <- renderValueBox({ valueBox(0, "Meals", icon = icon("utensils"), color = "aqua") })
    output$total_calories <- renderValueBox({ valueBox("—", "Total Calories/Macros", icon = icon("fire"), color = "yellow") })
    output$diet_type_box <- renderValueBox({ valueBox("—", "Diet Type", icon = icon("tag"), color = "green") })
    output$total_entries <- renderValueBox({ valueBox(0, "Total Entries", icon = icon("database"), color = "blue") })

    # ── Save as HTML/PDF (shared generic exporter, see R/utils_export.R) ──
    output$export_download <- downloadHandler(
      filename = function() {
        d <- viz_data()
        base_name <- if (!is.null(d) && nrow(d) > 0) paste0("diet_log_", d$log_date[1]) else "diet_log_export"
        paste0(base_name, if (identical(input$export_format, "pdf")) ".pdf" else ".html")
      },
      content = function(file) {
        tryCatch({
          d <- viz_data()
          if (is.null(d) || nrow(d) == 0) {
            writeLines("<html><body><p>No data loaded - load a day's diet log first.</p></body></html>", file)
            return()
          }

          cols <- c("row_type", "meal_name", "meal_details", "meal_time", "calories_macros", "observations")
          labels <- c("Type", "Meal", "Details", "Time", "Calories/Macros", "Notes")
          subtitle <- sprintf("%s - %s | %d entries", d$log_date[1], d$diet_type[1], nrow(d))

          if (identical(input$export_format, "pdf")) {
            ok <- generate_generic_pdf(file, paste0("Diet Log - ", d$log_date[1]), subtitle, d, cols, labels)
            if (!isTRUE(ok)) stop("PDF generation failed internally - see console log above for the real cause")
          } else {
            result <- generate_generic_html(paste0("Diet Log - ", d$log_date[1]), subtitle, d, cols, labels)
            writeLines(result$content, file)
          }
        }, error = function(e) {
          cat("\u274c [diet_visualizations export] Error:", e$message, "\n")
          writeLines(c("<html><body>", "<h2>Export failed</h2>",
                       paste0("<p>", htmltools::htmlEscape(e$message), "</p>"),
                       "<p>Check the Debug Console (API Configuration group) for full detail.</p>",
                       "</body></html>"), file)
        })
      }
    )
    output$export_status <- renderUI({ tags$div() })

    # ── Add to Calendar (.ics) - engine in R/utils_ics.R ──
    ics_result <- reactive({
      ics_safe_build(ics_events_diet, viz_data(), alarms = isTRUE(input$ics_alarms))
    })
    output$export_ics_status <- renderUI({ ics_status_html(ics_result(), loaded = !is.null(viz_data())) })
    output$export_ics <- downloadHandler(
      filename = function() { d <- viz_data(); ics_filename("diet_plan", if (!is.null(d) && nrow(d) > 0) d$log_date[1]) },
      content = function(file) {
        d <- viz_data()
        ics_write_safe(function() ics_result()$events,
                       paste("Diet Plan", if (!is.null(d) && nrow(d) > 0) as.character(d$log_date[1]) else ""), file)
      },
      contentType = "text/calendar"
    )

    # Titan calendar buttons (".ics load to calendar" / "Load events into calendar")
    drive_export_server(input, output, session, api_manager, group = "Diet Planner", tab = "Visualizations",
      specs = reactive({
        d <- viz_data()
        if (is.null(d) || nrow(d) == 0) return(list())
        list(macros_per_meal = diet_diagram_macros(d))
      }),
      subject = function() { d <- viz_data(); if (is.null(d) || nrow(d) == 0) "general" else as.character(d$log_date[1]) })

    titan_viz_hook(input, output, session, api_manager, ics_result, "Diet Planner")

    session$onSessionEnded(function() {})
  })
}
