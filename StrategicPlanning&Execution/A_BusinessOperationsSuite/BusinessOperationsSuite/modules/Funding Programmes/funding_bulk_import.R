# modules/Funding Programmes/funding_bulk_import.R
# Subtab: Bulk Import

funding_bulk_import_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Bulk Import Funding Programmes to BigQuery", status = "primary", solidHeader = TRUE, width = 12,
          h4("Paste or Generate Programme Data"),
          p("Paste one or more programme entries to parse and upload to BigQuery."),
          div(class = "alert alert-info",
              tags$strong("Expected Format (one block per programme, blank line between):"),
              tags$ul(
                tags$li("[programme_name], [category], [country], [city_region]"),
                tags$li("[amount_of_money], [conditions], [key_sponsors]"),
                tags$li("[key_organiser_profiles], [areas_of_application]"),
                tags$li("[start_date_for_applying], [deadline]"),
                tags$li("[recommendations_for_applying], [verified_urls]")
              )),
          textAreaInput(ns("programme_text"), "Paste Programme Data Here:", height = "500px",
                        placeholder = "[programme_name]: Horizon Europe SME Instrument\n[category]: Grant\n[country]: European Union\n[city_region]: All\n..."),
          fluidRow(
            column(4, actionButton(ns("parse"), "Parse Programmes", class = "btn-info btn-lg", icon = icon("cogs"), width = "100%")),
            column(4, actionButton(ns("upload"), "Upload to BigQuery", class = "btn-success btn-lg", icon = icon("cloud-upload-alt"), width = "100%")),
            column(4, actionButton(ns("clear"), "Clear All", class = "btn-danger", icon = icon("trash"), width = "100%"))
          ),
          br(), htmlOutput(ns("status")))
    ),
    fluidRow(
      box(title = "Parsed Data Preview", status = "info", solidHeader = TRUE, width = 12,
          htmlOutput(ns("parse_info")), br(), DT::dataTableOutput(ns("preview_table")))
    )
  )
}

funding_bulk_import_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_data <- reactiveVal(NULL)

    observeEvent(api_manager$pending_bulk_text_funding(), {
      incoming_text <- api_manager$pending_bulk_text_funding()
      if (nchar(incoming_text) > 0) updateTextAreaInput(session, "programme_text", value = incoming_text)
    }, ignoreInit = TRUE)

    observeEvent(input$parse, {
      if (trimws(input$programme_text) == "") {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please paste programme data to parse") })
        return()
      }
      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing...") })

      tryCatch({
        parsed_df <- parse_programme_text(input$programme_text)
        parsed_data(parsed_df)
        output$parse_info <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Successfully parsed %d programme(s)", nrow(parsed_df)))
        })
        output$preview_table <- DT::renderDataTable({
          DT::datatable(parsed_df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Parsed %d programme(s)!", nrow(parsed_df)))
        })
        showNotification(sprintf("✓ Parsed %d programme(s)!", nrow(parsed_df)), type = "message")
      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      if (is.null(parsed_data())) { showNotification("Please parse the programme data first!", type = "error"); return() }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Uploading...") })

      tryCatch({
        rows_uploaded <- api_manager$bq_insert_funding(parsed_data())
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

    observeEvent(input$clear, {
      updateTextAreaInput(session, "programme_text", value = "")
      parsed_data(NULL)
      output$parse_info <- renderUI({})
      output$preview_table <- DT::renderDataTable({})
      output$status <- renderUI({ tags$div(class = "status-info", "Cleared.") })
    })

    output$status <- renderUI({ tags$div() })
    output$parse_info <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
  })
}
