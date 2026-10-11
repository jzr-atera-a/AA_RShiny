# modules/Funding Programmes/funding_browse.R
# Subtab: Browse Data

funding_browse_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Browse Funding Programmes", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary", icon = icon("sync"))),
            column(3, downloadButton(ns("download"), "Download CSV", class = "btn-info")),
            column(6, numericInput(ns("max_rows"), "Max Rows to Display:", value = 200, min = 10, max = 2000, step = 10))
          ),
          br(), htmlOutput(ns("status")), br(), DT::dataTableOutput(ns("table")))
    )
  )
}

funding_browse_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    browse_data <- reactiveVal(NULL)

    observeEvent(input$refresh, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading data...") })

      tryCatch({
        query <- sprintf("SELECT * FROM `%s` ORDER BY deadline ASC, category ASC LIMIT %d",
                        api_manager$bq_full_table_funding, input$max_rows)
        data <- api_manager$bq_query(query)
        browse_data(data)

        output$table <- DT::renderDataTable({
          DT::datatable(data, options = list(pageLength = 25, scrollX = TRUE), rownames = FALSE)
        })
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Loaded %d rows", nrow(data)))
        })
        showNotification(sprintf("✓ Loaded %d rows", nrow(data)), type = "message")
      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() paste0("funding_programmes_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) if (!is.null(browse_data())) write.csv(browse_data(), file, row.names = FALSE)
    )

    output$status <- renderUI({ tags$div() })
    output$table <- DT::renderDataTable({})
  })
}
