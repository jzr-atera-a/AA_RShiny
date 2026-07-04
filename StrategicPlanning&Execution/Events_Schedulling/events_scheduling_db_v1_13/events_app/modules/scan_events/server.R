# modules/scan_events/server.R

scan_events_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    scan_data <- reactiveVal("")

    # Wire the Category → Subcategory cascade (mirrors genre_topic in books app)
    cat_sub <- setup_category_cascade(input, output, session, api_manager)

    observeEvent(input$scan, {

      # ── Auth guard ──────────────────────────────────────────
      if (!api_manager$claude_authenticated) {
        showNotification("Please configure Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please configure Claude API in the Claude API Config tab first!")
        })
        return()
      }

      # ── Date validation ─────────────────────────────────────
      if (!is.null(input$date_from) && !is.null(input$date_to) &&
          input$date_from > input$date_to) {
        showNotification("'From Date' must be before 'To Date'!", type = "error")
        return()
      }

      # Resolve category/subcategory (may be "" if user left as "Add New" with no text)
      cs <- cat_sub()

      shinyjs::show("loading_spinner")
      output$scan_text <- renderText({ "" })

      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      # ── Build prompt ────────────────────────────────────────
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
          "| city =", trimws(input$city %||% "(blank)"),
          "| category =", cs$category, "/", cs$subcategory, "\n")

      tryCatch({
        progress_msg(paste0("Sending request to Claude for top ", top_n, " events..."))

        api_result <- api_manager$call_claude(
          prompt = prompt,
          progress_callback = function(msg) { progress_msg(msg) }
        )

        city_val    <- trimws(input$city    %||% "")
        country_val <- trimws(input$country %||% "")

        # Force-overwrite header with exact user-supplied values
        events_text <- overwrite_events_header(
          api_result$text,
          city      = city_val,
          country   = country_val,
          scan_date = as.character(Sys.Date())
        )

        scan_data(events_text)
        output$scan_text <- renderText({ events_text })

        truncation_warning <- if (isTRUE(api_result$truncated)) {
          tagList(
            tags$br(), tags$br(),
            tags$span(style = "color: #e67e22; font-weight: bold;",
                      "⚠️ Response was cut off at the Max Tokens limit — some events may be missing. ",
                      "Increase Max Tokens in Claude API Config and rescan.")
          )
        } else NULL

        # Count events in returned text
        n_found <- length(grep("^\\[event_name\\]:", strsplit(events_text, "\n")[[1]],
                               ignore.case = TRUE))

        output$status <- renderUI({
          tags$div(
            class = if (isTRUE(api_result$truncated)) "status-warning" else "status-success",
            tags$i(class = if (isTRUE(api_result$truncated))
                     "fa fa-exclamation-triangle" else "fa fa-check-circle"),
            if (isTRUE(api_result$truncated)) " Scan complete (truncated)" else " ✓ Scan complete!",
            tags$br(),
            tags$small(sprintf("Found %d events · %d characters generated",
                               n_found, nchar(events_text))),
            truncation_warning
          )
        })

        shinyjs::hide("loading_spinner")
        if (!isTRUE(api_result$truncated)) {
          showNotification(sprintf("✓ %d events scanned!", n_found), type = "message")
        } else {
          showNotification("⚠️ Response truncated — increase Max Tokens", type = "warning", duration = 15)
        }

      }, error = function(e) {
        shinyjs::hide("loading_spinner")

        suggestion <- ""
        if (grepl("timeout", e$message, ignore.case = TRUE))
          suggestion <- "💡 Try: Increase timeout in Claude API Config"
        else if (grepl("401|authentication", e$message, ignore.case = TRUE))
          suggestion <- "💡 Try: Re-enter your API key in Claude API Config"
        else if (grepl("429|rate limit", e$message, ignore.case = TRUE))
          suggestion <- "💡 Try: Wait a few moments and try again"

        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"), " Scan Failed",
                   tags$br(), tags$strong("Error: "), tags$small(e$message),
                   if (nchar(suggestion) > 0)
                     tagList(tags$br(), tags$br(), tags$span(style = "color:#f39c12;", suggestion))
                   else NULL)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 15)
      })
    })

    # ── Copy to Bulk Import ─────────────────────────────────
    observeEvent(input$copy_to_bulk, {
      if (nchar(scan_data()) > 0) {
        api_manager$set_pending_bulk_text(scan_data())
        updateTabItems(session$rootScope(), "sidebar_menu", selected = "bulk_import_events")
        showNotification("✓ Events copied to Bulk Import tab!", type = "message")
      } else {
        showNotification("No events to copy. Scan first.", type = "warning")
      }
    })

    # ── Parse & Upload Direct ───────────────────────────────
    observeEvent(input$parse_and_upload, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      if (nchar(scan_data()) == 0) {
        showNotification("No events to upload. Scan first.", type = "warning")
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"), " Parsing and uploading...")
      })

      tryCatch({
        parsed_df     <- parse_events_text(scan_data())
        rows_uploaded <- api_manager$bq_insert(parsed_df)
        api_manager$trigger_state_update()

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d events! Visualizations updated.", rows_uploaded))
        })
        showNotification(sprintf("✓ Uploaded %d events!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    # ── Download ────────────────────────────────────────────
    output$download <- downloadHandler(
      filename = function() {
        city_part <- if (nchar(trimws(input$city %||% "")) > 0)
          gsub(" ", "_", trimws(input$city)) else "global"
        paste0("events_", city_part, "_", format(Sys.Date(), "%Y%m%d"), ".txt")
      },
      content = function(file) { writeLines(scan_data(), file) }
    )

    output$scan_text <- renderText({ "" })
    output$status    <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
