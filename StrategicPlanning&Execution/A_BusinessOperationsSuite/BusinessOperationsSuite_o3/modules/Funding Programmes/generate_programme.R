# modules/Funding Programmes/generate_programme.R
# Subtab: Find Programmes (flagship AI discovery tab)

generate_programme_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Find Funding Programmes", status = "primary", solidHeader = TRUE, width = 12,

        div(class = "alert alert-info",
            tags$strong("Accuracy note:"),
            " Claude generates results from its training data, which can be outdated or incomplete for ",
            "fast-changing programmes. Always verify amounts, dates, and URLs on the official site before ",
            "relying on them."),

        fluidRow(
          column(6, funding_category_dropdown_ui(ns), funding_country_cityregion_dropdown_ui(ns)),
          column(6,
                 textAreaInput(ns("search_focus"), "Additional Focus (optional):", height = "140px",
                               placeholder = paste("e.g., Early-stage climate tech startups,",
                                                    "non-dilutive funding preferred,", "pre-seed to seed stage", sep = "\n")),
                 numericInput(ns("n_results"), "Number of Programmes to Find:", value = 4, min = 1, max = 8, step = 1))
        ),

        hr(),
        fluidRow(
          column(3, actionButton(ns("generate"), "Find Programmes", icon = icon("search-dollar"), class = "btn-primary btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("copy_to_bulk"), "Copy to Bulk Import", icon = icon("arrow-right"), class = "btn-info btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("parse_and_upload"), "Parse & Upload Direct", icon = icon("cloud-upload-alt"), class = "btn-success btn-lg", style = "width: 100%;")),
          column(3, downloadButton(ns("download"), "Download Text", class = "btn-warning", style = "width: 100%;"))
        )
      )
    ),
    fluidRow(
      box(title = "Discovered Programmes", status = "success", solidHeader = TRUE, width = 12,
          div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
              icon("spinner", class = "fa-spin fa-3x"), h4("Searching... This may take 30-90 seconds.")),
          h5("Review & Edit (re-parse after any manual fix):"),
          textAreaInput(ns("programme_text_edit"), NULL, height = "350px",
                        placeholder = "Discovered programmes will appear here - editable before upload."),
          actionButton(ns("reparse"), "Re-Parse & Update Preview", icon = icon("sync"), class = "btn-default"),
          br(), br(), htmlOutput(ns("status")), br(), DT::dataTableOutput(ns("preview_table")))
    )
  )
}

generate_programme_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_preview <- reactiveVal(NULL)
    category_react <- setup_funding_category_cascade(input, output, session, api_manager)
    country_cityregion_react <- setup_funding_country_cityregion_cascade(input, output, session, api_manager)

    run_parse_preview <- function(text, quiet = FALSE) {
      if (trimws(text) == "") {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        return(invisible(NULL))
      }
      tryCatch({
        df <- parse_programme_text(text)
        parsed_preview(df)
        output$preview_table <- DT::renderDataTable({
          DT::datatable(df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        if (!quiet) {
          output$status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Parsed %d programme(s)", nrow(df)))
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

    observeEvent(input$generate, {
      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please configure Claude API in API Settings > Claude API Config first!")
        })
        return()
      }

      cat_val <- category_react()
      if (nchar(cat_val) == 0) { showNotification("Please select or enter a Category!", type = "error"); return() }
      cc <- country_cityregion_react()
      if (nchar(cc$country) == 0) { showNotification("Please select or enter a Country!", type = "error"); return() }

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "programme_text_edit", value = "")

      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg()) })

      prompt <- tryCatch({
        generate_programme_prompt(cat_val, cc$country, cc$city_region, input$search_focus, input$n_results)
      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Failed to build prompt: ", e$message) })
        NULL
      })
      if (is.null(prompt)) return()

      tryCatch({
        progress_msg("Searching (this may take 30-90 seconds)...")
        result <- api_manager$call_claude(prompt = prompt, progress_callback = function(msg) { progress_msg(msg) })
        programme_text <- overwrite_programme_taxonomy(result$text, cat_val, cc$country, cc$city_region)

        updateTextAreaInput(session, "programme_text_edit", value = programme_text)
        shinyjs::hide("loading_spinner")
        run_parse_preview(programme_text, quiet = TRUE)

        truncation_note <- if (isTRUE(result$truncated)) {
          tagList(tags$br(), tags$span(style = "color: #f39c12;", "⚠️ Response truncated - increase Max Tokens and try again"))
        } else NULL

        output$status <- renderUI({
          tags$div(class = if (isTRUE(result$truncated)) "status-warning" else "status-success",
                   tags$i(class = if (isTRUE(result$truncated)) "fa fa-exclamation-triangle" else "fa fa-check-circle"),
                   " ✓ Programmes found!", truncation_note)
        })
        showNotification("✓ Programmes found!", type = "message")

      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        error_message <- e$message
        suggestion <- ""
        if (grepl("timeout", error_message, ignore.case = TRUE)) suggestion <- "💡 Try: Increase timeout in Claude API Config"
        else if (grepl("network|peer|connection", error_message, ignore.case = TRUE)) suggestion <- "💡 Try: Check internet connection or try again in a moment"
        else if (grepl("401|authentication", error_message, ignore.case = TRUE)) suggestion <- "💡 Try: Re-enter your API key in Claude API Config"
        else if (grepl("429|rate limit", error_message, ignore.case = TRUE)) suggestion <- "💡 Try: Wait a few moments and try again"

        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Search Failed",
                   tags$br(), tags$strong("Error: "), tags$small(error_message),
                   if (nchar(suggestion) > 0) tagList(tags$br(), tags$br(), tags$span(style = "color: #f39c12;", suggestion)) else NULL)
        })
        showNotification(paste("Error:", error_message), type = "error", duration = 15)
      })
    })

    observeEvent(input$reparse, { run_parse_preview(input$programme_text_edit) })

    observeEvent(input$copy_to_bulk, {
      current_text <- input$programme_text_edit
      if (nchar(trimws(current_text %||% "")) > 0) {
        api_manager$set_pending_bulk_text_funding(current_text)
        updateTabItems(session$rootScope(), "sidebar_menu", "funding_bulk_import")
        showNotification("✓ Programmes copied to Bulk Import tab!", type = "message")
      } else {
        showNotification("No programmes to copy. Find some first.", type = "warning")
      }
    })

    observeEvent(input$parse_and_upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      current_text <- input$programme_text_edit
      if (nchar(trimws(current_text %||% "")) == 0) { showNotification("No programmes to upload. Find some first.", type = "warning"); return() }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing and uploading...") })

      tryCatch({
        parsed_df <- parse_programme_text(current_text)
        rows_uploaded <- api_manager$bq_insert_funding(parsed_df)
        api_manager$trigger_state_update_funding()

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Successfully uploaded %d programme(s)!", rows_uploaded))
        })
        showNotification(sprintf("✓ Uploaded %d programme(s)!", rows_uploaded), type = "message")
      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() paste0("programmes_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) writeLines(input$programme_text_edit %||% "", file)
    )

    output$status <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
  })
}
