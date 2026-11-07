# modules/Exercise Tracker/exercise_visualizations/server.R

exercise_visualizations_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    viz_data <- reactiveVal(NULL)

    viz_taxonomy <- reactive({
      api_manager$state_trigger_exercise()
      if (!api_manager$bq_authenticated) return(data.frame(session_type = character(), stringsAsFactors = FALSE))
      tryCatch(api_manager$bq_get_exercise_taxonomy(), error = function(e) data.frame(session_type = character(), stringsAsFactors = FALSE))
    })

    observeEvent(viz_taxonomy(), {
      tax <- viz_taxonomy()
      session_types <- sort(unique(tax$session_type[nchar(trimws(tax$session_type)) > 0]))
      if (length(session_types) == 0) {
        updateSelectInput(session, "viz_session_type", choices = c("(no workouts logged yet)" = ""))
      } else {
        current <- isolate(input$viz_session_type)
        selected <- if (!is.null(current) && current %in% session_types) current else session_types[1]
        updateSelectInput(session, "viz_session_type", choices = setNames(session_types, session_types), selected = selected)
      }
    }, ignoreNULL = FALSE)

    observeEvent(input$viz_session_type, {
      if (is.null(input$viz_session_type) || input$viz_session_type == "") {
        updateSelectInput(session, "select_date", choices = c("(select a session type first)" = ""))
        return()
      }
      dates <- tryCatch({
        safe_st <- safe_sql_escape(input$viz_session_type)
        r <- api_manager$bq_query(sprintf(
          "SELECT DISTINCT workout_date FROM `%s` WHERE session_type = '%s' ORDER BY workout_date DESC",
          api_manager$bq_full_table_exercise, safe_st))
        r$workout_date
      }, error = function(e) character())

      if (length(dates) == 0) updateSelectInput(session, "select_date", choices = c("(no dates found)" = ""))
      else updateSelectInput(session, "select_date", choices = setNames(dates, dates))
    }, ignoreInit = TRUE)

    observeEvent(input$select_date, {
      if (!api_manager$bq_authenticated || is.null(input$select_date) || input$select_date == "") return()
      tryCatch({
        safe_date <- safe_sql_escape(input$select_date)
        query <- sprintf("SELECT DISTINCT row_type FROM `%s` WHERE workout_date = '%s' ORDER BY row_type",
                         api_manager$bq_full_table_exercise, safe_date)
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
          sprintf("SELECT * FROM `%s` WHERE workout_date = '%s' ORDER BY row_sequence", api_manager$bq_full_table_exercise, safe_date)
        } else {
          sprintf("SELECT * FROM `%s` WHERE workout_date = '%s' AND row_type = '%s' ORDER BY row_sequence",
                  api_manager$bq_full_table_exercise, safe_date, safe_sql_escape(input$filter_row_type))
        }
        data <- api_manager$bq_query(query)

        if (nrow(data) == 0) {
          output$status <- renderUI({ tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"), " No data found") })
          return()
        }

        viz_data(data)

        output$day_header <- renderUI({
          tags$div(class = "book-header", tags$h2(data$workout_date[1]),
                   tags$div(class = "author", tags$i(class = "fa fa-dumbbell"), " ", data$session_type[1]))
        })

        output$total_exercises <- renderValueBox({ valueBox(sum(data$row_type == "Exercise"), "Exercises", icon = icon("dumbbell"), color = "aqua") })

        summary_row <- data[data$row_type == "Summary", ]
        total_cal_val <- if (nrow(summary_row) > 0) summary_row$calories_burned[1] else "—"
        output$total_calories <- renderValueBox({ valueBox(total_cal_val, "Total Calories Burned", icon = icon("fire"), color = "yellow") })

        output$session_type_box <- renderValueBox({ valueBox(data$session_type[1], "Session Type", icon = icon("tag"), color = "green") })
        output$total_entries <- renderValueBox({ valueBox(nrow(data), "Total Entries", icon = icon("database"), color = "blue") })

        output$timeline_html <- renderUI({
          d <- viz_data(); req(!is.null(d))
          html_parts <- c('<div class="viz-card">')
          html_parts <- c(html_parts, sprintf('<div class="chapter-title"><i class="fa fa-calendar-day"></i> %s Session</div>', as.character(d$workout_date[1])))

          row_icon <- function(rt) switch(rt, "Exercise" = "fa fa-dumbbell", "Summary" = "fa fa-flag-checkered", "fa fa-circle")

          for (i in seq_len(nrow(d))) {
            row <- d[i, ]
            cat_label <- if (has_real_value(row$exercise_category)) paste0(" (", row$exercise_category, ")") else ""
            html_parts <- c(html_parts, sprintf('<div class="section-tag"><i class="%s"></i> %s: %s%s</div>',
                                                row_icon(as.character(row$row_type)), as.character(row$row_type),
                                                as.character(row$exercise_name), cat_label))
            html_parts <- c(html_parts, sprintf('<div class="details-text">%s</div>', as.character(row$exercise_details)))

            metrics <- c()
            if (has_real_value(row$metric_primary)) {
              metrics <- c(metrics, sprintf('<div class="metric-box"><div class="metric-label">Primary Metric</div><div class="metric-value" style="font-size: 1em;">%s</div></div>', as.character(row$metric_primary)))
            }
            if (has_real_value(row$metric_secondary)) {
              metrics <- c(metrics, sprintf('<div class="metric-box"><div class="metric-label">Secondary Metric</div><div class="metric-value" style="font-size: 1em;">%s</div></div>', as.character(row$metric_secondary)))
            }
            if (has_real_value(row$calories_burned)) {
              metrics <- c(metrics, sprintf('<div class="metric-box"><div class="metric-label">Calories</div><div class="metric-value" style="font-size: 1em;">%s</div></div>', as.character(row$calories_burned)))
            }
            if (length(metrics) > 0) html_parts <- c(html_parts, paste(metrics, collapse = ""))

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

        output$calories_chart <- renderPlotly({
          d <- viz_data(); req(!is.null(d))
          ex_rows <- d[d$row_type == "Exercise", ]

          chart_data <- data.frame(entry = character(), category = character(), calories = numeric(), stringsAsFactors = FALSE)
          for (i in seq_len(nrow(ex_rows))) {
            row <- ex_rows[i, ]
            cal <- exercise_parse_calories(row$calories_burned)
            if (!is.na(cal)) {
              chart_data <- rbind(chart_data, data.frame(
                entry = paste0(row$row_sequence, ". ", row$exercise_name),
                category = row$exercise_category %||% "Other", calories = cal, stringsAsFactors = FALSE))
            }
          }

          if (nrow(chart_data) == 0) return(plot_ly() %>% layout(title = "No parsable calorie data available"))

          chart_data$entry <- factor(chart_data$entry, levels = chart_data$entry)
          plot_ly(chart_data, x = ~entry, y = ~calories, color = ~category, type = 'bar') %>%
            layout(title = "Estimated Calories per Entry", xaxis = list(title = "", tickangle = -35), yaxis = list(title = "Calories (kcal)"))
        })

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded visualizations for %s (%d entries)", data$workout_date[1], nrow(data)))
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
    output$calories_chart <- renderPlotly({ plot_ly() })
    output$total_exercises <- renderValueBox({ valueBox(0, "Exercises", icon = icon("dumbbell"), color = "aqua") })
    output$total_calories <- renderValueBox({ valueBox("—", "Total Calories Burned", icon = icon("fire"), color = "yellow") })
    output$session_type_box <- renderValueBox({ valueBox("—", "Session Type", icon = icon("tag"), color = "green") })
    output$total_entries <- renderValueBox({ valueBox(0, "Total Entries", icon = icon("database"), color = "blue") })

    session$onSessionEnded(function() {})
  })
}
