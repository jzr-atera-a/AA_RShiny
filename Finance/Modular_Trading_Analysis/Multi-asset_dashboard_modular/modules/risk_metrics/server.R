# modules/risk_metrics/server.R

risk_metrics_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    observe({
      data_manager$state_trigger()
    })
    
    output$riskMetrics <- renderText({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) return("No data available")
      
      tail_data <- tail(data, input$varWindow)
      returns <- tail_data$returns[!is.na(tail_data$returns)]
      
      if (length(returns) < 30) return("Insufficient data")
      
      adjusted_returns <- returns * sqrt(input$timeHorizon)
      var_percentile <- (100 - input$confidenceLevel) / 100
      
      if (input$varMethod == "historical") {
        var_value <- quantile(adjusted_returns, var_percentile)
      } else {
        mean_ret <- mean(adjusted_returns)
        sd_ret <- sd(adjusted_returns)
        var_value <- mean_ret + qnorm(var_percentile) * sd_ret
      }
      
      var_dollar <- abs(var_value) * input$portfolioValue
      sharpe <- mean(returns) / sd(returns) * sqrt(252)
      
      paste(
        paste("Portfolio:", paste0("$", format(input$portfolioValue, big.mark = ","))),
        paste("Time Horizon:", input$timeHorizon, "day(s)"),
        "",
        paste("VaR:", paste0("$", format(round(var_dollar, 0), big.mark = ","))),
        paste("VaR %:", paste0(round(var_dollar / input$portfolioValue * 100, 3), "%")),
        paste("Sharpe Ratio:", round(sharpe, 3)),
        sep = "\n"
      )
    })
    
    output$varChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      tail_data <- tail(data, min(1000, nrow(data)))
      returns <- tail_data$returns
      var_percentile <- (100 - input$confidenceLevel) / 100
      window_size <- min(input$varWindow, sum(!is.na(returns)) - 50)
      
      if (window_size < 50) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      rolling_var <- rollapply(returns, window_size,
                               function(x) quantile(x * sqrt(input$timeHorizon), var_percentile, na.rm = TRUE),
                               fill = NA, align = "right")
      
      plot_data <- data.frame(
        Date = tail(tail_data$Date, length(rolling_var)),
        var_value = abs(rolling_var) * input$portfolioValue,
        daily_pnl = tail(returns, length(rolling_var)) * sqrt(input$timeHorizon) * input$portfolioValue
      ) %>% filter(!is.na(var_value))
      
      plot_ly(plot_data, x = ~Date) %>%
        add_lines(y = ~var_value, name = "VaR", 
                 line = list(color = "#e74c3c", width = 2),
                 type = "scatter", mode = "lines") %>%
        add_bars(y = ~daily_pnl, name = "Daily P&L", 
                marker = list(color = "#3498db"),
                type = "bar") %>%
        layout(
          title = "Value at Risk",
          xaxis = list(title = "Date"),
          yaxis = list(title = "USD"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$expectedShortfall <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      tail_data <- tail(data, 800)
      returns <- tail_data$returns
      var_percentile <- (100 - input$confidenceLevel) / 100
      window_size <- min(input$varWindow, sum(!is.na(returns)) - 50)
      
      if (window_size < 50) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      rolling_es <- rollapply(returns, window_size,
                              function(x) {
                                adj_ret <- x * sqrt(input$timeHorizon)
                                var_threshold <- quantile(adj_ret, var_percentile, na.rm = TRUE)
                                mean(adj_ret[adj_ret <= var_threshold], na.rm = TRUE)
                              },
                              fill = NA, align = "right")
      
      plot_data <- data.frame(
        Date = tail(tail_data$Date, length(rolling_es)),
        es_value = abs(rolling_es) * input$portfolioValue
      ) %>% filter(!is.na(es_value))
      
      plot_ly(plot_data, x = ~Date, y = ~es_value, type = "scatter", mode = "lines",
              line = list(color = "#8e44ad", width = 2)) %>%
        layout(
          title = "Expected Shortfall",
          xaxis = list(title = "Date"),
          yaxis = list(title = "USD"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$drawdownAnalysis <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      cumulative <- cumprod(1 + returns)
      running_max <- cummax(cumulative)
      drawdown <- (cumulative - running_max) / running_max * 100
      
      dd_data <- data.frame(
        Date = tail(data$Date, length(drawdown)),
        drawdown = drawdown
      )
      
      plot_ly(dd_data, x = ~Date, y = ~drawdown, type = "scatter", mode = "lines",
              fill = "tonexty", fillcolor = "rgba(214, 39, 40, 0.3)",
              line = list(color = "#d62728", width = 2)) %>%
        layout(
          title = "Drawdown Analysis",
          xaxis = list(title = "Date"),
          yaxis = list(title = "Drawdown (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$riskStatsTable <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(datatable(data.frame(Metric = "Error", Value = "No data")))
      }
      
      tail_data <- tail(data, input$varWindow)
      returns <- tail_data$returns[!is.na(tail_data$returns)]
      
      if (length(returns) < 30) {
        return(datatable(data.frame(Metric = "Error", Value = "Insufficient data")))
      }
      
      adj_returns <- returns * sqrt(input$timeHorizon)
      downside_returns <- returns[returns < 0]
      
      stats <- data.frame(
        Metric = c("Mean Return (%)", "Volatility (%)", "Sharpe Ratio", "Sortino Ratio",
                   "Max Loss (%)", "Max Gain (%)"),
        Value = c(
          round(mean(adj_returns) * 100, 4),
          round(sd(adj_returns) * 100, 4),
          round(mean(returns) / sd(returns) * sqrt(252), 3),
          round(mean(returns) / sqrt(mean(pmin(returns, 0)^2)) * sqrt(252), 3),
          round(min(adj_returns) * 100, 4),
          round(max(adj_returns) * 100, 4)
        )
      )
      
      datatable(stats, options = list(dom = 't'), rownames = FALSE)
    })
    
    output$stressTestResults <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(datatable(data.frame(Scenario = "Error", Impact = "No data")))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      hist_vol <- sd(returns) * sqrt(input$timeHorizon)
      
      scenarios <- data.frame(
        Scenario = c("2 Sigma Event", "3 Sigma Event", "4 Sigma Event", 
                     "Flash Crash", "Market Crisis"),
        Probability = c("4.5%", "0.3%", "0.006%", "0.01%", "0.1%"),
        Impact_Pct = paste0(round(c(-2, -3, -4, -5, -3.5) * hist_vol * 100, 2), "%"),
        Portfolio_Impact = paste0("-$", format(round(abs(c(-2, -3, -4, -5, -3.5) * hist_vol * input$portfolioValue), 0), big.mark = ","))
      )
      
      datatable(scenarios, options = list(dom = 't'), rownames = FALSE)
    })
    
    session$onSessionEnded(function() {})
  })
}
