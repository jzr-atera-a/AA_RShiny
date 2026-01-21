technical_indicators_server <- function(id, shared_values) {
  moduleServer(id, function(input, output, session) {
    
    output$dataLoaded <- reactive({
      !is.null(shared_values$fx_data) && shared_values$data_loaded
    })
    outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
    
    output$technicalChart <- renderPlotly({
      req(shared_values$data_loaded)
      data <- shared_values$fx_data
      prices <- data$Mid
      sma_val <- SMA(prices, n = input$sma_period)
      x_var <- if (shared_values$source_table == "daily") data$Date else data$Timestamp
      
      plot_ly() %>%
        add_trace(x = x_var, y = prices, type = 'scatter', mode = 'lines', 
                  name = 'Price', line = list(color = '#008A82')) %>%
        add_trace(x = x_var, y = sma_val, type = 'scatter', mode = 'lines', 
                  name = 'SMA', line = list(color = '#e74c3c')) %>%
        layout(title = "Technical Indicators",
               xaxis = list(title = "Time"),
               yaxis = list(title = "Price"))
    })
  })
}
