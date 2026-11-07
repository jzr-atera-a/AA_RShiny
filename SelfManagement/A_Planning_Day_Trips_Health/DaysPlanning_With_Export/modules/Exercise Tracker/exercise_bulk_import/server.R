# modules/Exercise Tracker/exercise_bulk_import/server.R

exercise_bulk_import_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_data <- reactiveVal(NULL)

    observeEvent(api_manager$pending_bulk_text_exercise(), {
      incoming_text <- api_manager$pending_bulk_text_exercise()
      if (nchar(incoming_text) > 0) updateTextAreaInput(session, "exercise_text", value = incoming_text)
    }, ignoreInit = TRUE)

    observeEvent(input$parse, {
      if (trimws(input$exercise_text) == "") {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please paste a workout session to parse") })
        return()
      }
      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing...") })

      tryCatch({
        parsed_df <- parse_exercise_text(input$exercise_text)
        parsed_data(parsed_df)

        output$parse_info <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully parsed %d rows for %s (%s)", nrow(parsed_df), parsed_df$workout_date[1], parsed_df$session_type[1]))
        })
        output$preview_table <- DT::renderDataTable({
          DT::datatable(parsed_df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Parsed %d rows!", nrow(parsed_df)))
        })
        showNotification(sprintf("✓ Parsed %d rows!", nrow(parsed_df)), type = "message")

      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      if (is.null(parsed_data())) { showNotification("Please parse the workout session first!", type = "error"); return() }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Uploading...") })

      tryCatch({
        rows_uploaded <- api_manager$bq_insert_exercise(parsed_data())
        api_manager$trigger_state_update_exercise()

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Successfully uploaded %d rows!", rows_uploaded))
        })
        showNotification(sprintf("✓ Uploaded %d rows!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$clear, {
      updateTextAreaInput(session, "exercise_text", value = "")
      parsed_data(NULL)
      output$parse_info <- renderUI({})
      output$preview_table <- DT::renderDataTable({})
      output$status <- renderUI({ tags$div(class = "status-info", "Cleared.") })
    })

    output$status <- renderUI({ tags$div() })
    output$parse_info <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})

    session$onSessionEnded(function() {})
  })
}
