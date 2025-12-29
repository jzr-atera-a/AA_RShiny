volatility_analysis_server <- function(id, shared_values) {
  moduleServer(id, function(input, output, session) {
    
    output$dataLoaded <- reactive({
      !is.null(shared_values$fx_data) && shared_values$data_loaded
    })
    outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
    
    output$volChart <- renderPlotly({
      req(shared_values$data_loaded)
      prices <- shared_values$fx_data$Mid
      returns <- diff(log(prices))
      vol <- rollapply(returns, width = 20, FUN = sd, fill = NA, align = "right") * sqrt(252) * 100
      
      data <- shared_values$fx_data
      x_var <- if (shared_values$source_table == "daily") data$Date[-1] else data$Timestamp[-1]
      
      plot_ly(x = x_var, y = vol, type = 'scatter', mode = 'lines', 
              line = list(color = '#008A82')) %>%
        layout(title = "Volatility (%)",
               xaxis = list(title = "Time"),
               yaxis = list(title = "Volatility (%)"))
    })
  })
}
