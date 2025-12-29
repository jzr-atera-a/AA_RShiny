# Data View Module

dataViewUI <- function(id) {
  ns <- NS(id)
  
  fluidRow(
    box(
      title = "All Processed Receipts",
      status = "info",
      solidHeader = TRUE,
      width = 12,
      p("This table shows all receipts that have been processed and saved to the Excel file. Amount column contains numeric values only."),
      hr(),
      actionButton(ns("refresh_data"), "Refresh Data", icon = icon("refresh"), class = "btn-info"),
      downloadButton(ns("download_excel"), "Download Excel", class = "btn-success"),
      hr(),
      DT::dataTableOutput(ns("all_data_table"))
    )
  )
}

dataViewServer <- function(id, shared_rv) {
  moduleServer(id, function(input, output, session) {
    
    # Local reactive values
    rv <- reactiveValues(
      all_data = NULL
    )
    
    # Refresh all data
    observeEvent(input$refresh_data, {
      if (file.exists(shared_rv$excel_filename)) {
        rv$all_data <- openxlsx::read.xlsx(shared_rv$excel_filename)
        showNotification("Data refreshed successfully", type = "message", duration = 2)
      } else {
        showNotification("No data file found", type = "warning", duration = 3)
      }
    })
    
    # Display all processed receipts
    output$all_data_table <- DT::renderDataTable({
      if (file.exists(shared_rv$excel_filename)) {
        if (is.null(rv$all_data)) {
          rv$all_data <- openxlsx::read.xlsx(shared_rv$excel_filename)
        }
        DT::datatable(
          rv$all_data,
          options = list(
            pageLength = 25,
            scrollX = TRUE,
            dom = 'Bfrtip',
            order = list(list(6, 'desc'))
          ),
          rownames = FALSE,
          filter = 'top'
        )
      }
    })
    
    # Download Excel handler
    output$download_excel <- downloadHandler(
      filename = function() {
        paste0("receipt_data_export_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".xlsx")
      },
      content = function(file) {
        if (file.exists(shared_rv$excel_filename)) {
          file.copy(shared_rv$excel_filename, file)
        }
      }
    )
    
  })
}
