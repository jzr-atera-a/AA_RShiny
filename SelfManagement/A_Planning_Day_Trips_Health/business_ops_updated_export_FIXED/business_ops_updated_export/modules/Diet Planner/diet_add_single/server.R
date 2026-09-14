# modules/Diet Planner/diet_add_single/server.R

diet_add_single_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    diet_type_react <- setup_diet_type_cascade(input, output, session, api_manager)

    observeEvent(input$submit, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      dt <- diet_type_react()
      if (nchar(dt) == 0 || trimws(input$meal_name) == "" || trimws(input$meal_details) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in Diet Type, Meal Name, and Details")
        })
        return()
      }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Submitting...") })

      tryCatch({
        log_date_chr <- as.character(input$log_date)

        next_seq <- tryCatch({
          safe_date <- safe_sql_escape(log_date_chr)
          q <- sprintf("SELECT COALESCE(MAX(row_sequence), 0) as max_seq FROM `%s` WHERE log_date = '%s'",
                       api_manager$bq_full_table_diet, safe_date)
          r <- api_manager$bq_query(q)
          as.integer(r$max_seq[1]) + 1
        }, error = function(e) 1)

        df <- data.frame(
          log_date = log_date_chr, diet_type = dt,
          dietary_restrictions = ifelse(trimws(input$dietary_restrictions) == "", "N/A", trimws(input$dietary_restrictions)),
          row_type = input$row_type, row_sequence = next_seq,
          meal_name = trimws(input$meal_name), meal_details = trimws(input$meal_details),
          meal_time = ifelse(trimws(input$meal_time) == "", "N/A", trimws(input$meal_time)),
          calories_macros = trimws(input$calories_macros), observations = trimws(input$observations),
          stringsAsFactors = FALSE
        )

        api_manager$bq_insert_diet(df)
        api_manager$trigger_state_update_diet()

        output$status <- renderUI({ tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Entry submitted successfully!") })
        showNotification("✓ Entry submitted!", type = "message")

        updateTextInput(session, "meal_name", value = "")
        updateTextInput(session, "meal_details", value = "")
        updateTextInput(session, "meal_time", value = "")
        updateTextInput(session, "calories_macros", value = "")
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
