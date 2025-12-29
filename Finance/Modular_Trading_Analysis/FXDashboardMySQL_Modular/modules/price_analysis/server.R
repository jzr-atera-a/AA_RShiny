price_analysis_server <- function(id, shared_values) {
  moduleServer(id, function(input, output, session) {
    
    output$dataLoaded <- reactive({
      !is.null(shared_values$fx_data) && shared_values$data_loaded
    })
    outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
    
    output$priceChart <- renderPlotly({
      req(shared_values$data_loaded)
      data <- shared_values$fx_data
      x_var <- if (shared_values$source_table == "daily") data$Date else data$Timestamp
      plot_ly(x = x_var, y = data$Mid, type = 'scatter', mode = 'lines', 
              line = list(color = '#008A82', width = 2)) %>%
        layout(title = "Price Chart", 
               xaxis = list(title = "Time"), 
               yaxis = list(title = "Price"))
    })
  })
}
