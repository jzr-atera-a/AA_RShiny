# modules/Events Scheduling/bulk_import_events.R
# ---- module ----------------------------------------------
# id:           bulk_import_events
# name:         Bulk Import Events
# label:        Bulk Import
# icon:         file-import
# description:  Parse and bulk-upload events text to BigQuery
# packages:     shiny, shinydashboard, DT
# -----------------------------------------------------------

# ---- UI ----
bulk_import_events_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Bulk Import Events to BigQuery",
        status = "primary", solidHeader = TRUE, width = 12,

        h4("Paste or Receive Events Text"),
        p("Paste a structured events block (from Scan Events or manually written) to parse and upload."),

        div(class = "alert alert-info",
            tags$strong("Expected Format:"),
            tags$ul(
              tags$li("Header: [city]: ... (blank = global), [country]: ..., [scan_date]: ..."),
              tags$li("[event_name], [organiser], [category], [subcategory]"),
              tags$li("[event_date] (YYYY-MM-DD), [event_time], [venue_name], [address]"),
              tags$li("[latitude], [longitude], [description]"),
              tags$li("[ticket_url], [price_range], [source_url]"),
              tags$li("[extra_info] — additional notes, accessibility, requirements (or N/A)")
            )
        ),

        bos_tz_dropdown_ui(ns, label = "Time zone of the pasted times:", help = "Used only when the text has no [time_zone] line (text from the generator tabs already carries one)."),
        textAreaInput(ns("events_text"), "Paste Events Text Here:", height = "500px",
                      placeholder = paste0(
                        "[city]: London\n[country]: United Kingdom\n[scan_date]: 2026-07-01\n\n",
                        "[event_name]: ...\n[organiser]: ...\n[category]: Music\n",
                        "[subcategory]: Jazz\n[event_date]: 2026-07-15\n[event_time]: 19:30\n",
                        "[venue_name]: ...\n[address]: ...\n[latitude]: 51.5\n[longitude]: -0.1\n",
                        "[description]: ...\n[ticket_url]: N/A\n[price_range]: Free\n",
                        "[source_url]: N/A\n[extra_info]: N/A"
                      )),

        fluidRow(
          column(4, actionButton(ns("parse"),  "Parse Events",      class = "btn-info btn-lg",
                                 icon = icon("cogs"),               style = "width: 100%;")),
          column(4, actionButton(ns("upload"), "Upload to BigQuery", class = "btn-success btn-lg",
                                 icon = icon("cloud-upload-alt"),   style = "width: 100%;")),
          column(4, actionButton(ns("clear"),  "Clear All",          class = "btn-danger",
                                 icon = icon("trash"),              style = "width: 100%;"))
        ),

        br(),
        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Parsed Data Preview", status = "info", solidHeader = TRUE, width = 12,
        htmlOutput(ns("parse_info")),
        br(),
        div(class = "preview-section", DT::dataTableOutput(ns("preview_table")))
      )
    )
  )
}

# ---- Server ----
bulk_import_events_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_data <- reactiveVal(NULL)

    # Receive text from scan_events via api_manager$pending_bulk_text
    observeEvent(api_manager$pending_bulk_text_events(), {
      incoming <- api_manager$pending_bulk_text_events()
      if (nchar(incoming) > 0) {
        cat("📥 [bulk_import_events] Received", nchar(incoming), "chars from scan_events\n")
        updateTextAreaInput(session, "events_text", value = incoming)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$parse, {
      if (trimws(input$events_text) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"), " Please paste events text to parse")
        })
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing...")
      })

      tryCatch({
        df <- parse_events_text(input$events_text, default_tz = input$time_zone)
        parsed_data(df)

        output$parse_info <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully parsed %d events in %s, %s",
                           nrow(df),
                           if (nrow(df) > 0) df$city[1] else "?",
                           if (nrow(df) > 0) df$country[1] else "?"))
        })

        output$preview_table <- DT::renderDataTable({
          show_cols <- c("event_name", "category", "subcategory", "event_date",
                         "event_time", "venue_name", "city", "price_range")
          show_cols <- intersect(show_cols, names(df))
          DT::datatable(df[, show_cols], options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Parsed %d events!", nrow(df)))
        })
        showNotification(sprintf("✓ Parsed %d events!", nrow(df)), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$upload, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      if (is.null(parsed_data())) {
        showNotification("Please parse the events first!", type = "error")
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Uploading...")
      })

      tryCatch({
        rows_uploaded <- api_manager$bq_insert_events(parsed_data())
        api_manager$trigger_state_update_events()

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

    observeEvent(input$clear, {
      updateTextAreaInput(session, "events_text", value = "")
      parsed_data(NULL)
      output$parse_info    <- renderUI({})
      output$preview_table <- DT::renderDataTable({})
      output$status        <- renderUI({ tags$div(class = "status-info", "Cleared.") })
    })

    output$status        <- renderUI({ tags$div() })
    output$parse_info    <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
    session$onSessionEnded(function() {})
  })
}
