# modules/API Configuration/bigquery_auth.R
# ---- module --------------------------------------------------------------------------------------
# id:           bigquery_auth
# name:         BigQuery Authentication
# label:        BigQuery Setup
# icon:         database
# description:  Sign in to Google BigQuery once for every suite; each suite's table is checked and loaded when its tab is first opened
# packages:     shiny, shinydashboard, shinyjs, bigrquery, jsonlite
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

bigquery_auth_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Google Cloud Platform Authentication",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        app_cred_box_ui(ns, "BigQuery service-account key (*.json)"),
        h4("BigQuery Configuration - shared by all eight suites"),
        p("Connect ONCE here. This authenticates Book Summary, Flex Table, Mind Map, Knowledge Graph, ",
          "Sankey Graph, Strategic Analysis, AND Six Sigma Analysis together - they share the same ",
          "project/dataset, but each has its own table, all auto-created below."),

        div(class = "alert alert-info",
            tags$strong("Note:"),
            " This app requires a valid Google Cloud service account with BigQuery permissions.",
            tags$br(),
            tags$strong("Tables auto-created on connect (same project/dataset, one table per suite):"),
            tags$ul(
              tags$li(tags$strong("Book Summary:"), " book_summaries_test3"),
              tags$li(tags$strong("Flex Table:"), " flex_comparison_tables"),
              tags$li(tags$strong("Mind Map:"), " mindmap_nodes"),
              tags$li(tags$strong("Knowledge Graph:"), " knowledge_graph"),
              tags$li(tags$strong("Sankey Graph:"), " sankey_graphs"),
              tags$li(tags$strong("Strategic Analysis:"), " strategy_diagrams"),
              tags$li(tags$strong("Six Sigma Analysis:"), " six_sigma_diagrams")
            )),

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
                 textInput(ns("dataset_id"), "Dataset ID:", value = "Wonderfulp_March", width = "100%"),

                 p(style = "color: #7f8c8d; font-size: 12px;",
                   "All eight tables live in this one project/dataset. Table names are fixed (shown above) ",
                   "since each suite's code targets its table by name directly.")
          )
        ),

        br(),
        fluidRow(
          column(6,
                 actionButton(ns("authenticate"), "Connect to BigQuery (all 8 tables)",
                              class = "btn-primary btn-lg", icon = icon("plug"), style = "width: 100%;")
          ),
          column(6,
                 selectInput(ns("test_table_choice"), "Table to test-query:",
                            choices = c("Book Summary" = "books", "Flex Table" = "flex", "Mind Map" = "mindmap",
                                        "Knowledge Graph" = "kg", "Sankey Graph" = "sankey",
                                        "Strategic Analysis" = "diagram", "Six Sigma Analysis" = "sixsigma", "Technical Designs" = "techdesign"))
          )
        ),
        actionButton(ns("test_query"), "Test Query (Top 5 Rows of selected table)",
                    class = "btn-info btn-lg", icon = icon("table"), style = "width: 100%;"),

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

# ==== Server =======================================================================================

bigquery_auth_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # ⭐ Re-entry guard: connecting fires triggers for all 7 suites at once
    # (see authenticate_bigquery()'s success branch), which - because
    # shinydashboard keeps every suite's reactive code alive regardless of
    # which tab is visible - cascades into dozens of sequential BigQuery
    # round trips that can take well over a minute on a single-threaded
    # Shiny session. During that time the UI genuinely can't show whether
    # the click registered, so a second, impatient click is an entirely
    # reasonable thing for a person to do - but without this guard, Shiny
    # queues that second click and re-runs the WHOLE connect-and-fire-
    # every-trigger cascade again once the first one finishes, doubling
    # an already-long wait for no benefit (the connection was already
    # succeeding). This guard makes a click during an in-flight connection
    # a no-op instead.
    authenticating <- reactiveVal(FALSE)

    cred_tick <- reactiveVal(0)
    output$auto_key <- renderUI(app_cred_banner("bq", cred_tick))
    observeEvent(input$cred_load, {
      d <- trimws(input$cred_dir %||% ""); if (!nzchar(d)) { showNotification("Type the folder first.", type = "warning"); return() }
      showNotification("Looking for the key and connecting ...", type = "message")
      app_cred_autoload(api_manager, dir = d, which = "bq", force = TRUE); cred_tick(cred_tick() + 1)
    })

    observeEvent(input$authenticate, {

      if (isTRUE(authenticating())) {
        showNotification("Already connecting - please wait for it to finish before clicking again.", type = "warning")
        return()
      }

      if (trimws(input$project_id) == "" || trimws(input$dataset_id) == "") {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in Project ID and Dataset ID")
        })
        return()
      }

      authenticating(TRUE)
      shinyjs::disable("authenticate")
      output$auth_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"),
                 " Connecting to BigQuery ... this takes a few seconds. Each suite's table is checked and its lists are loaded when you open its tab.")
      })

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
                   " ✓ Connected! Tables used (each is checked and loaded when you open its tab):",
                   tags$br(),
                   tags$small("Book Summary: ", api_manager$bq_full_table_books),
                   tags$br(),
                   tags$small("Flex Table: ", api_manager$bq_full_table_flex),
                   tags$br(),
                   tags$small("Mind Map: ", api_manager$bq_full_table_mindmap),
                   tags$br(),
                   tags$small("Knowledge Graph: ", api_manager$bq_full_table_kg),
                   tags$br(),
                   tags$small("Sankey Graph: ", api_manager$bq_full_table_sankey),
                   tags$br(),
                   tags$small("Strategic Analysis: ", api_manager$bq_full_table_diagram),
                   tags$br(),
                   tags$small("Six Sigma Analysis: ", api_manager$bq_full_table_sixsigma),
                   tags$br(),
                   tags$small("Technical Designs: ", api_manager$bq_full_table_techdesign))
        })

        showNotification("✓ BigQuery connected. Each suite loads when you open its tab.", type = "message")

      }, error = function(e) {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Authentication failed: ", tags$br(), tags$small(app_err_text(e)))
        })
        showNotification(paste("Error:", app_err_text(e)), type = "error")
      })

      authenticating(FALSE)
      shinyjs::enable("authenticate")
    })

    observeEvent(input$test_query, {

      if (!(isTRUE(api_manager$bq_authenticated) || isTRUE(api_manager$bq_connected))) {
        showNotification("Please authenticate first!", type = "error")
        output$test_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Please authenticate before testing")
        })
        return()
      }

      full_table <- switch(input$test_table_choice,
        books = api_manager$bq_full_table_books,
        flex = api_manager$bq_full_table_flex,
        mindmap = api_manager$bq_full_table_mindmap,
        kg = api_manager$bq_full_table_kg,
        sankey = api_manager$bq_full_table_sankey,
        diagram = api_manager$bq_full_table_diagram,
        sixsigma = api_manager$bq_full_table_sixsigma,
        techdesign = api_manager$bq_full_table_techdesign
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
                   " Test query failed: ", tags$br(), tags$small(app_err_text(e)))
        })
        showNotification(paste("Error:", app_err_text(e)), type = "error")
      })
    })

    output$auth_status <- renderUI({ tags$div() })
    output$test_status <- renderUI({ tags$div() })
    output$test_table <- DT::renderDataTable({
      DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE)
    })

  })
}
