market_overview_server <- function(id, shared_values) {
  moduleServer(id, function(input, output, session) {
    
    output$dataLoaded <- reactive({
      !is.null(shared_values$fx_data) && shared_values$data_loaded
    })
    outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
    
    output$totalPairs <- renderValueBox({
      req(shared_values$data_loaded)
      pairs <- length(unique(shared_values$fx_data$CurrencyPair))
      valueBox(pairs, "Currency Pairs", icon = icon("coins"), color = "blue")
    })
    
    output$totalRecords <- renderValueBox({
      req(shared_values$data_loaded)
      valueBox(format_number(nrow(shared_values$fx_data), 0), "Records", 
               icon = icon("database"), color = "green")
    })
    
    output$dateRange <- renderValueBox({
      req(shared_values$data_loaded)
      data <- shared_values$fx_data
      days <- if (shared_values$source_table == "daily") {
        as.numeric(max(data$Date) - min(data$Date))
      } else {
        round(as.numeric(difftime(max(data$Timestamp), min(data$Timestamp), units = "hours")), 1)
      }
      valueBox(days, ifelse(shared_values$source_table == "daily", "Days", "Hours"), 
               icon = icon("calendar"), color = "yellow")
    })
    
    output$avgPrice <- renderValueBox({
      req(shared_values$data_loaded)
      avg <- mean(shared_values$fx_data$Mid, na.rm = TRUE)
      valueBox(round(avg, 4), "Avg Mid Price", icon = icon("chart-line"), color = "purple")
    })
    
    output$overviewPlot <- renderPlotly({
      req(shared_values$data_loaded)
      data <- shared_values$fx_data
      if (shared_values$source_table == "daily") {
        plot_ly(data, x = ~Date, y = ~Mid, color = ~CurrencyPair, 
                type = 'scatter', mode = 'lines')
      } else {
        plot_ly(data, x = ~Timestamp, y = ~Mid, type = 'scatter', mode = 'lines', 
                line = list(color = '#008A82'))
      }
    })
  })
}
