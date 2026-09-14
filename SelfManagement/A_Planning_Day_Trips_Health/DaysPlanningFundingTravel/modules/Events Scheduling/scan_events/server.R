# modules/Events Scheduling/scan_events/server.R

scan_events_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_preview <- reactiveVal(NULL)

    # Wire the Category -> Subcategory cascade (renamed to avoid colliding
    # with Funding Programmes' own Category cascade - see utils_common.R)
    cat_sub <- setup_events_category_cascade(input, output, session, api_manager)

    run_parse_preview <- function(text, quiet = FALSE) {
      if (trimws(text) == "") {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        return(invisible(NULL))
      }
      tryCatch({
        df <- parse_events_text(text)
        parsed_preview(df)
        output$preview_table <- DT::renderDataTable({
          DT::datatable(df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        if (!quiet) {
          output$status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Parsed %d event(s)", nrow(df)))
          })
        }
      }, error = function(e) {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        if (!quiet) {
          output$status <- renderUI({
            tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Parse issue (blocking): ", e$message)
          })
        }
      })
    }

    observeEvent(input$scan, {

      if (!api_manager$claude_authenticated) {
        showNotification("Please configure Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please configure Claude API in the Claude API Config tab first!")
        })
        return()
      }

      if (!is.null(input$date_from) && !is.null(input$date_to) && input$date_from > input$date_to) {
        showNotification("'From Date' must be before 'To Date'!", type = "error")
        return()
      }

      cs <- cat_sub()

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "scan_text_edit", value = "")

      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      top_n <- as.integer(input$top_n %||% 10)

      prompt <- generate_scan_prompt(
        city            = trimws(input$city    %||% ""),
        country         = trimws(input$country %||% ""),
        date_from       = if (!is.null(input$date_from)) as.character(input$date_from) else NULL,
        date_to         = if (!is.null(input$date_to))   as.character(input$date_to)   else NULL,
        category        = cs$category,
        subcategory     = cs$subcategory,
        top_n           = top_n,
        extra_info      = trimws(input$extra_info %||% ""),
        optional_fields = input$optional_fields %||% "core"
      )

      cat("✓ [scan_events] Prompt built (", nchar(prompt), "chars) | top_n =", top_n,
          "| city =", trimws(input$city %||% "(blank)"), "| category =", cs$category, "/", cs$subcategory, "\n")

      tryCatch({
        progress_msg(paste0("Sending request to Claude for top ", top_n, " events (web search enabled)..."))

        # enable_web_search = TRUE - Events needs real, currently-happening
        # events with verified source URLs, not training-data recall alone.
        api_result <- api_manager$call_claude(
          prompt = prompt,
          progress_callback = function(msg) { progress_msg(msg) },
          enable_web_search = TRUE
        )

        city_val    <- trimws(input$city    %||% "")
        country_val <- trimws(input$country %||% "")

        events_text <- overwrite_events_header(api_result$text, city = city_val, country = country_val, scan_date = as.character(Sys.Date()))

        updateTextAreaInput(session, "scan_text_edit", value = events_text)
        shinyjs::hide("loading_spinner")

        run_parse_preview(events_text, quiet = TRUE)

        truncation_warning <- if (isTRUE(api_result$truncated)) {
          tagList(tags$br(), tags$span(style = "color: #e67e22; font-weight: bold;",
                    "⚠️ Response was cut off at the Max Tokens limit - some events may be missing."))
        } else NULL

        n_found <- length(grep("^\\[event_name\\]:", strsplit(events_text, "\n")[[1]], ignore.case = TRUE))

        output$status <- renderUI({
          tags$div(class = if (isTRUE(api_result$truncated)) "status-warning" else "status-success",
                   tags$i(class = if (isTRUE(api_result$truncated)) "fa fa-exclamation-triangle" else "fa fa-check-circle"),
                   if (isTRUE(api_result$truncated)) " Scan complete (truncated)" else " ✓ Scan complete!",
                   tags$br(), tags$small(sprintf("Found %d events - %d characters generated", n_found, nchar(events_text))),
                   truncation_warning)
        })

        if (!isTRUE(api_result$truncated)) showNotification(sprintf("✓ %d events scanned!", n_found), type = "message")
        else showNotification("⚠️ Response truncated - increase Max Tokens", type = "warning", duration = 15)

      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        suggestion <- ""
        if (grepl("timeout", e$message, ignore.case = TRUE)) suggestion <- "💡 Try: Increase timeout in Claude API Config"
        else if (grepl("401|authentication", e$message, ignore.case = TRUE)) suggestion <- "💡 Try: Re-enter your API key in Claude API Config"
        else if (grepl("429|rate limit", e$message, ignore.case = TRUE)) suggestion <- "💡 Try: Wait a few moments and try again"

        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Scan Failed",
                   tags$br(), tags$strong("Error: "), tags$small(e$message),
                   if (nchar(suggestion) > 0) tagList(tags$br(), tags$br(), tags$span(style = "color:#f39c12;", suggestion)) else NULL)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 15)
      })
    })

    observeEvent(input$reparse, {
      run_parse_preview(input$scan_text_edit)
    })

    observeEvent(input$copy_to_bulk, {
      current_text <- input$scan_text_edit
      if (nchar(trimws(current_text %||% "")) > 0) {
        api_manager$set_pending_bulk_text_events(current_text)
        updateTabItems(session$rootScope(), "sidebar_menu", selected = "bulk_import_events")
        showNotification("✓ Events copied to Bulk Import tab!", type = "message")
      } else {
        showNotification("No events to copy. Scan first.", type = "warning")
      }
    })

    observeEvent(input$parse_and_upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      current_text <- input$scan_text_edit
      if (nchar(trimws(current_text %||% "")) == 0) { showNotification("No events to upload. Scan first.", type = "warning"); return() }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing and uploading...") })

      tryCatch({
        parsed_df     <- parse_events_text(current_text)
        rows_uploaded <- api_manager$bq_insert_events(parsed_df)
        api_manager$trigger_state_update_events()

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d events!", rows_uploaded))
        })
        showNotification(sprintf("✓ Uploaded %d events!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() {
        city_part <- if (nchar(trimws(input$city %||% "")) > 0) gsub(" ", "_", trimws(input$city)) else "global"
        paste0("events_", city_part, "_", format(Sys.Date(), "%Y%m%d"), ".txt")
      },
      content = function(file) { writeLines(input$scan_text_edit %||% "", file) }
    )

    output$status <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
    session$onSessionEnded(function() {})
  })
}
