# modules/Exercise Tracker/exercise_add_single/server.R

exercise_add_single_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    session_type_react <- setup_session_type_cascade(input, output, session, api_manager)
    exercise_cat_react <- setup_exercise_category_cascade(input, output, session, api_manager)

    observeEvent(input$submit, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      st <- session_type_react()
      ec <- exercise_cat_react()

      if (nchar(st) == 0 || nchar(ec$exercise_name) == 0 || trimws(input$exercise_details) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in Session Type, Exercise/Activity Name, and Details")
        })
        return()
      }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Submitting...") })

      tryCatch({
        workout_date_chr <- as.character(input$workout_date)

        next_seq <- tryCatch({
          safe_date <- safe_sql_escape(workout_date_chr)
          q <- sprintf("SELECT COALESCE(MAX(row_sequence), 0) as max_seq FROM `%s` WHERE workout_date = '%s'",
                       api_manager$bq_full_table_exercise, safe_date)
          r <- api_manager$bq_query(q)
          as.integer(r$max_seq[1]) + 1
        }, error = function(e) 1)

        df <- data.frame(
          workout_date = workout_date_chr, session_type = st,
          session_notes = ifelse(trimws(input$session_notes) == "", "N/A", trimws(input$session_notes)),
          row_type = input$row_type, row_sequence = next_seq,
          exercise_category = ec$category, exercise_name = ec$exercise_name,
          exercise_details = trimws(input$exercise_details),
          metric_primary = trimws(input$metric_primary),
          metric_secondary = ifelse(trimws(input$metric_secondary) == "", "N/A", trimws(input$metric_secondary)),
          calories_burned = ifelse(trimws(input$calories_burned) == "", "N/A", trimws(input$calories_burned)),
          observations = trimws(input$observations),
          stringsAsFactors = FALSE
        )

        api_manager$bq_insert_exercise(df)
        api_manager$trigger_state_update_exercise()

        output$status <- renderUI({ tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Entry submitted successfully!") })
        showNotification("✓ Entry submitted!", type = "message")

        updateTextInput(session, "exercise_details", value = "")
        updateTextInput(session, "metric_primary", value = "")
        updateTextInput(session, "metric_secondary", value = "")
        updateTextInput(session, "calories_burned", value = "")
        updateTextAreaInput(session, "observations", value = "")

      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
