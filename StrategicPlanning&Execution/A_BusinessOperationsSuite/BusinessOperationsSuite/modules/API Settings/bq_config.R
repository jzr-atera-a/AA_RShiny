# modules/API Settings/bq_config.R
# Subtab: BigQuery Config (API Settings group)
# Ported from DaysPlanningFundingTravel modules/API Configuration/bigquery_auth
# (same JSON upload/paste, Connect, and Test Query flow), with this suite's tables.

bq_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Google Cloud Platform Authentication",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        h4("BigQuery Configuration"),
        p("Connect once to enable every BigQuery-backed tab: Communications, Funding Programmes and Strategy Canvases."),

        div(class = "alert alert-info",
            tags$strong("Note:"),
            " This app requires a valid Google Cloud service account with BigQuery permissions.",
            tags$br(),
            tags$strong("Default Configuration:"),
            " Project: atera-2, Dataset: business_strategy"),

        fluidRow(
          column(6,
                 h5("Upload Service Account JSON File:"),
                 fileInput(ns("json_file"), "Select JSON File:", accept = ".json", width = "100%"),

                 h5("Or paste JSON content:"),
                 textAreaInput(ns("json_text"), "JSON Content:", height = "150px", width = "100%",
                               placeholder = "Paste your service account JSON here...")
          ),
          column(6,
                 h5("BigQuery Project Configuration"),
                 textInput(ns("project_id"), "Project ID:", value = "atera-2", width = "100%"),
                 textInput(ns("dataset_id"), "Dataset ID:", value = "business_strategy", width = "100%"),

                 tags$table(class = "table table-condensed", style = "margin-top: 10px;",
                   tags$tbody(
                     tags$tr(tags$td(tags$strong("Funding Programmes:")), tags$td(tags$code("funding_programmes"))),
                     tags$tr(tags$td(tags$strong("Communications:")), tags$td(tags$code("business_contacts, contact_communications"))),
                     tags$tr(tags$td(tags$strong("Strategy Canvases:")), tags$td(tags$code("business_model_canvas, disciplined_entrepreneurship_canvas, disciplined_entrepreneurship_roadmap")))
                   )
                 ),
                 p(style = "color: #7f8c8d; font-size: 12px;",
                   "Table names are fixed per suite. Connecting creates any that don't exist yet",
                   " (CREATE TABLE IF NOT EXISTS - never alters or drops an existing table).")
          )
        ),

        br(),
        fluidRow(
          column(5,
                 actionButton(ns("authenticate"), "Connect to BigQuery",
                              class = "btn-primary btn-lg", icon = icon("plug"), style = "width: 100%;")
          ),
          column(4,
                 selectInput(ns("test_table_choice"), "Table to test:",
                             choices = c("Funding Programmes" = "funding",
                                         "Business Contacts" = "contacts",
                                         "Contact Communications" = "communications",
                                         "Business Model Canvas" = "bm_canvas",
                                         "DE Canvas" = "de_canvas",
                                         "DE Roadmap" = "de_roadmap"))
          ),
          column(3,
                 br(),
                 actionButton(ns("test_query"), "Test Query (top 5 rows)",
                              class = "btn-info btn-lg", icon = icon("table"), style = "width: 100%;")
          )
        ),

        hr(),
        h4("Connection Status"),
        htmlOutput(ns("auth_status")),

        hr(),
        h4("Test Query Results"),
        htmlOutput(ns("test_status")),
        DT::dataTableOutput(ns("test_table"))
      )
    )
  )
}

bq_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$authenticate, {

      if (trimws(input$project_id) == "" || trimws(input$dataset_id) == "") {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in Project ID and Dataset ID")
        })
        return()
      }

      tryCatch({
        api_manager$set_bigquery_credentials(
          project_id = trimws(input$project_id),
          dataset_id = trimws(input$dataset_id)
        )

        if (!is.null(input$json_file) && !is.null(input$json_file$datapath)) {
          api_manager$authenticate_bigquery(json_path = input$json_file$datapath)
        } else if (!is.null(input$json_text) && trimws(input$json_text) != "") {
          api_manager$authenticate_bigquery(json_text = input$json_text)
        } else {
          stop("Please provide credentials via file upload or text paste")
        }

        output$auth_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ Successfully authenticated! Tables are ready:",
                   tags$br(),
                   tags$small("Funding Programmes: ", api_manager$bq_full_table_funding),
                   tags$br(),
                   tags$small("Communications: ", api_manager$bq_full_table_contacts, ", ", api_manager$bq_full_table_communications),
                   tags$br(),
                   tags$small("Strategy Canvases: ", api_manager$bq_full_table_bm_canvas, ", ",
                              api_manager$bq_full_table_de_canvas, ", ", api_manager$bq_full_table_de_roadmap))
        })

        tryCatch(api_manager$bq_load_contacts(), error = function(e) NULL)
        showNotification("✓ BigQuery connected - all tabs ready!", type = "message")

      }, error = function(e) {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Authentication failed: ", tags$br(), tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$test_query, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate first!", type = "error")
        output$test_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Please authenticate before testing")
        })
        return()
      }

      full_table <- switch(input$test_table_choice,
        funding        = api_manager$bq_full_table_funding,
        contacts       = api_manager$bq_full_table_contacts,
        communications = api_manager$bq_full_table_communications,
        bm_canvas      = api_manager$bq_full_table_bm_canvas,
        de_canvas      = api_manager$bq_full_table_de_canvas,
        de_roadmap     = api_manager$bq_full_table_de_roadmap
      )

      output$test_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Running test query...")
      })

      tryCatch({
        test_query <- sprintf("SELECT * FROM `%s` LIMIT 5", full_table)
        test_data <- api_manager$bq_query(test_query)

        if (nrow(test_data) == 0) {
          output$test_status <- renderUI({
            tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"),
                     " Query successful but table is empty (0 rows)")
          })
          output$test_table <- DT::renderDataTable({
            DT::datatable(data.frame(Message = "Table is empty - no data to display"), options = list(dom = 't'), rownames = FALSE)
          })
        } else {
          output$test_status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     sprintf(" Successfully retrieved %d rows from %s", nrow(test_data), full_table))
          })
          output$test_table <- DT::renderDataTable({
            DT::datatable(test_data, options = list(pageLength = 5, scrollX = TRUE, dom = 'Bfrtip'), rownames = FALSE)
          })
        }

        showNotification(sprintf("✓ Retrieved %d rows", nrow(test_data)), type = "message")

      }, error = function(e) {
        output$test_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Test query failed: ", tags$br(), tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$auth_status <- renderUI({ tags$div() })
    output$test_status <- renderUI({ tags$div() })
    output$test_table <- DT::renderDataTable({
      DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE)
    })

    session$onSessionEnded(function() {})
  })
}
