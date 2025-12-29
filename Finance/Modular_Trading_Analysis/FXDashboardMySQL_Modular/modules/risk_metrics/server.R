risk_metrics_server <- function(id, shared_values) {
  moduleServer(id, function(input, output, session) {
    
    output$dataLoaded <- reactive({
      !is.null(shared_values$fx_data) && shared_values$data_loaded
    })
    outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
    
    risk_calc <- reactive({
      req(shared_values$data_loaded)
      prices <- shared_values$fx_data$Mid
      returns <- diff(prices) / prices[-length(prices)]
      
      var_95 <- quantile(returns, 0.05, na.rm = TRUE)
      cumret <- cumprod(1 + returns)
      dd <- (cumret - cummax(cumret)) / cummax(cumret) * 100
      max_dd <- min(dd, na.rm = TRUE)
      sharpe <- mean(returns, na.rm = TRUE) / sd(returns, na.rm = TRUE) * sqrt(252)
      
      list(var = var_95 * 100, max_dd = max_dd, sharpe = sharpe, dd = dd)
    })
    
    output$varBox <- renderValueBox({
      r <- risk_calc()
      valueBox(paste0(round(abs(r$var), 2), "%"), "VaR (95%)", 
               icon = icon("exclamation-triangle"), color = "red")
    })
    
    output$maxDDBox <- renderValueBox({
      r <- risk_calc()
      valueBox(paste0(round(abs(r$max_dd), 2), "%"), "Max Drawdown", 
               icon = icon("arrow-down"), color = "purple")
    })
    
    output$sharpeBox <- renderValueBox({
      r <- risk_calc()
      valueBox(round(r$sharpe, 2), "Sharpe Ratio", 
               icon = icon("chart-bar"), color = "green")
    })
    
    output$ddChart <- renderPlotly({
      req(shared_values$data_loaded)
      r <- risk_calc()
      data <- shared_values$fx_data
      x_var <- if (shared_values$source_table == "daily") data$Date[-1] else data$Timestamp[-1]
      
      plot_ly(x = x_var, y = r$dd, type = 'scatter', mode = 'lines', 
              fill = 'tozeroy', line = list(color = '#e74c3c')) %>%
        layout(title = "Drawdown (%)",
               xaxis = list(title = "Time"),
               yaxis = list(title = "Drawdown (%)"))
    })
  })
}
