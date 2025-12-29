db_connection_server <- function(id, shared_values) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$testConnection, {
      tryCatch({
        if (!is.null(shared_values$connection)) {
          dbDisconnect(shared_values$connection)
        }
        con <- dbConnect(MySQL(), 
                        host = input$host, 
                        port = input$port,
                        dbname = input$dbname, 
                        user = input$username, 
                        password = input$password)
        shared_values$connection <- con
        shared_values$connected <- TRUE
        shared_values$last_error <- NULL
      }, error = function(e) {
        shared_values$connected <- FALSE
        shared_values$last_error <- e$message
      })
    })
    
    observeEvent(input$loadData, {
      req(shared_values$connected)
      tryCatch({
        query <- sprintf("SELECT * FROM %s ORDER BY Date LIMIT 1000", input$sourceTable)
        data <- dbGetQuery(shared_values$connection, query)
        if (nrow(data) > 0) {
          if ("Date" %in% names(data)) data$Date <- as.Date(data$Date)
          shared_values$fx_data <- data
          shared_values$data_loaded <- TRUE
          shared_values$source_table <- ifelse(input$sourceTable == "fx_spot_prices_daily", "daily", "intraday")
        }
      }, error = function(e) {
        shared_values$last_error <- e$message
      })
    })
    
    output$connectionStatus <- renderUI({
      if (shared_values$connected) {
        div(class = "connection-success", h5("✓ Connected"), p("Database connection successful"))
      } else if (!is.null(shared_values$last_error)) {
        div(class = "connection-error", h5("✗ Failed"), p(shared_values$last_error))
      } else {
        div(class = "data-warning", h5("Not Connected"), p("Configure and test connection"))
      }
    })
    
    output$dataStatus <- renderUI({
      if (shared_values$data_loaded) {
        div(class = "connection-success", 
            h5("✓ Data Loaded"), 
            p(sprintf("%d records", nrow(shared_values$fx_data))))
      }
    })
    
    output$dataPreview <- DT::renderDataTable({
      req(shared_values$data_loaded)
      DT::datatable(head(shared_values$fx_data, 20), options = list(scrollX = TRUE))
    })
    
    output$connectionValid <- reactive({ shared_values$connected })
    outputOptions(output, "connectionValid", suspendWhenHidden = FALSE)
    
    output$dataLoaded <- reactive({ shared_values$data_loaded })
    outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
  })
}
