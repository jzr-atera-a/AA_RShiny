# modules/volatility_analysis/server.R

volatility_analysis_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    observe({
      data_manager$state_trigger()
    })
    
    output$volatilityMetrics <- renderText({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) return("No data available")
      
      tail_data <- tail(data, 500)
      returns <- tail_data$returns[!is.na(tail_data$returns)]
      
      if (length(returns) < input$volWindow) return("Insufficient data")
      
      current_vol <- sd(tail(returns, input$volWindow))
      if (input$annualizeVol) current_vol <- current_vol * sqrt(252)
      
      all_vol <- sd(returns)
      if (input$annualizeVol) all_vol <- all_vol * sqrt(252)
      
      vol_unit <- ifelse(input$annualizeVol, "% (ann.)", "% (daily)")
      
      paste(
        paste("Current Volatility:", round(current_vol * 100, 3), vol_unit),
        paste("Historical Avg:", round(all_vol * 100, 3), vol_unit),
        paste("Data Points:", length(returns)),
        sep = "\n"
      )
    })
    
    output$volatilityChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      tail_data <- tail(data, 1000)
      returns <- tail_data$returns
      
      if (sum(!is.na(returns)) < input$volWindow) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
      if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
      
      vol_mean <- mean(rolling_vol, na.rm = TRUE)
      vol_sd <- sd(rolling_vol, na.rm = TRUE)
      confidence_mult <- qnorm((100 + input$volConfidence) / 200)
      
      plot_data <- data.frame(
        Date = tail_data$Date,
        vol = rolling_vol,
        upper = vol_mean + confidence_mult * vol_sd,
        lower = pmax(0, vol_mean - confidence_mult * vol_sd)
      ) %>% filter(!is.na(vol))
      
      plot_ly(plot_data, x = ~Date) %>%
        add_lines(y = ~vol * 100, name = "Volatility", 
                 line = list(color = "#2c3e50", width = 2),
                 type = "scatter", mode = "lines") %>%
        add_lines(y = ~upper * 100, name = "Upper Band", 
                 line = list(color = "#e74c3c", dash = "dash"),
                 type = "scatter", mode = "lines") %>%
        add_lines(y = ~lower * 100, name = "Lower Band", 
                 line = list(color = "#27ae60", dash = "dash"),
                 type = "scatter", mode = "lines") %>%
        layout(
          title = paste("Volatility Analysis -", data_manager$current_asset),
          xaxis = list(title = "Date"),
          yaxis = list(title = ifelse(input$annualizeVol, "Ann. Volatility (%)", "Daily Vol (%)")),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$volatilityDist <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
      if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
      
      vol_data <- rolling_vol[!is.na(rolling_vol)]
      
      if (length(vol_data) < 20) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      plot_ly(type = "histogram") %>%
        add_histogram(x = vol_data * 100, nbinsx = 30,
                     marker = list(color = "#3498db", opacity = 0.7)) %>%
        layout(
          title = "Volatility Distribution",
          xaxis = list(title = ifelse(input$annualizeVol, "Ann. Vol (%)", "Daily Vol (%)")),
          yaxis = list(title = "Frequency"),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          showlegend = FALSE
        )
    })
    
    output$volatilityClustering <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      tail_data <- tail(data, 500) %>% filter(!is.na(returns))
      
      if (nrow(tail_data) < 20) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      tail_data$abs_returns <- abs(tail_data$returns) * 100
      
      plot_ly(tail_data, x = ~Date, y = ~abs_returns, type = "scatter", mode = "lines",
              line = list(color = "#e74c3c", width = 1.5)) %>%
        layout(
          title = "Volatility Clustering",
          xaxis = list(title = "Date"),
          yaxis = list(title = "Absolute Return (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$volatilityRegimes <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
      if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
      
      vol_25 <- quantile(rolling_vol, 0.25, na.rm = TRUE)
      vol_75 <- quantile(rolling_vol, 0.75, na.rm = TRUE)
      
      regime_data <- data.frame(
        Date = tail(data$Date, length(rolling_vol)),
        vol = rolling_vol,
        regime = ifelse(rolling_vol <= vol_25, "Low",
                        ifelse(rolling_vol >= vol_75, "High", "Normal"))
      ) %>% filter(!is.na(vol))
      
      colors <- c("Low" = "#27ae60", "Normal" = "#3498db", "High" = "#e74c3c")
      
      plot_ly(regime_data, x = ~Date, y = ~vol * 100, color = ~regime, colors = colors,
              type = "scatter", mode = "markers") %>%
        layout(
          title = "Volatility Regimes",
          xaxis = list(title = "Date"),
          yaxis = list(title = ifelse(input$annualizeVol, "Ann. Vol (%)", "Daily Vol (%)")),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    session$onSessionEnded(function() {})
  })
}
