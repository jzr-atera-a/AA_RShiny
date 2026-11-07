# modules/Day Planner/generate_schedule/server.R

generate_schedule_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_preview <- reactiveVal(NULL)
    day_type_react <- setup_schedule_daytype_cascade(input, output, session, api_manager)
    country_city_react <- setup_schedule_country_city_cascade(input, output, session, api_manager)

    run_parse_preview <- function(text, quiet = FALSE) {
      if (trimws(text) == "") {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        return(invisible(NULL))
      }
      tryCatch({
        df <- parse_schedule_text(text)
        parsed_preview(df)
        output$preview_table <- DT::renderDataTable({
          DT::datatable(df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })

        warnings <- c()
        if (!"Summary" %in% df$row_type) warnings <- c(warnings, "No Summary row found - the day total/insights row is missing.")
        if (!"Location" %in% df$row_type) warnings <- c(warnings, "No Location row found - is this really a full day plan?")

        if (!quiet) {
          output$status <- renderUI({
            tagList(
              tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                       sprintf(" Parsed %d row(s)", nrow(df))),
              if (length(warnings) > 0) tags$div(class = "status-warning",
                       tags$i(class = "fa fa-exclamation-triangle"),
                       paste(" Warning:", paste(warnings, collapse = "; "))) else NULL
            )
          })
        }
      }, error = function(e) {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        if (!quiet) {
          output$status <- renderUI({
            tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                     " Parse issue (blocking): ", e$message)
          })
        }
      })
    }

    observeEvent(input$generate, {

      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please configure Claude API in the Claude API Config tab first!")
        })
        return()
      }

      dt <- day_type_react()
      if (nchar(dt) == 0) { showNotification("Please select or enter a Type of Day!", type = "error"); return() }

      is_travel <- identical(dt, "Travel")
      cc <- country_city_react()

      if (is_travel) {
        if (nchar(cc$country) == 0 || nchar(cc$city) == 0) {
          showNotification("Please select or enter both Country and City for a Travel day!", type = "error"); return()
        }
      }
      # Country/City are optional for non-Travel days - when provided, they're
      # used to look up the real weather forecast and are stored on the row;
      # when left blank, weather lookup is skipped gracefully (see
      # generate_schedule_prompt()).
      country <- if (nchar(cc$country) > 0) cc$country else "N/A"
      city    <- if (nchar(cc$city) > 0) cc$city else "N/A"

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "schedule_text_edit", value = "")

      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      prompt <- tryCatch({
        generate_schedule_prompt(as.character(input$schedule_date), dt, country, city, input$trip_details)
      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Failed to build prompt: ", e$message)
        })
        NULL
      })
      if (is.null(prompt)) return()

      tryCatch({
        # enable_web_search = TRUE - the prompt instructs Claude to look up
        # the real weather forecast for the day/location before planning
        # (see generate_schedule_prompt's WEATHER RESEARCH step).
        result <- api_manager$call_claude(
          prompt = prompt,
          progress_callback = function(msg) { progress_msg(msg) },
          enable_web_search = TRUE
        )

        schedule_text <- overwrite_schedule_header(
          result$text, as.character(input$schedule_date), dt, country, city, input$trip_details
        )

        updateTextAreaInput(session, "schedule_text_edit", value = schedule_text)
        shinyjs::hide("loading_spinner")

        run_parse_preview(schedule_text, quiet = TRUE)

        truncation_note <- if (isTRUE(result$truncated)) {
          tagList(tags$br(), tags$span(style = "color: #f39c12;",
                                        "⚠️ Response truncated - increase Max Tokens and try again"))
        } else NULL

        output$status <- renderUI({
          tags$div(class = if (isTRUE(result$truncated)) "status-warning" else "status-success",
                   tags$i(class = if (isTRUE(result$truncated)) "fa fa-exclamation-triangle" else "fa fa-check-circle"),
                   " ✓ Schedule planned!", truncation_note)
        })

        showNotification("✓ Schedule planned successfully!", type = "message")

      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Planning Failed: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 15)
      })
    })

    observeEvent(input$reparse, {
      run_parse_preview(input$schedule_text_edit)
    })

    observeEvent(input$copy_to_bulk, {
      current_text <- input$schedule_text_edit
      if (nchar(trimws(current_text %||% "")) > 0) {
        api_manager$set_pending_bulk_text_schedule(current_text)
        updateTabItems(session$rootScope(), "sidebar_menu", selected = "schedule_bulk_import")
        showNotification("✓ Schedule copied to Bulk Import tab!", type = "message")
      } else {
        showNotification("No schedule to copy. Generate first.", type = "warning")
      }
    })

    observeEvent(input$parse_and_upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      current_text <- input$schedule_text_edit
      if (nchar(trimws(current_text %||% "")) == 0) { showNotification("No schedule to upload. Generate first.", type = "warning"); return() }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing and uploading...")
      })

      tryCatch({
        parsed_df <- parse_schedule_text(current_text)
        rows_uploaded <- api_manager$bq_insert_schedule(parsed_df)
        api_manager$trigger_state_update_schedule()

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d rows!", rows_uploaded))
        })
        showNotification(sprintf("✓ Uploaded %d rows!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() paste0("schedule_", as.character(input$schedule_date), "_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) writeLines(input$schedule_text_edit %||% "", file)
    )

    output$status <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})

    session$onSessionEnded(function() {})
  })
}
