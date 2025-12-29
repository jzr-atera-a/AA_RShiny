# modules/technical_indicators/server.R

technical_indicators_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    observe({
      data_manager$state_trigger()
    })
    
    output$technicalSignals <- renderText({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) return("No data available")
      
      tail_data <- tail(data, 200)
      signals <- c()
      
      if ("rsi" %in% input$technicalIndicators && nrow(tail_data) >= input$rsiLength) {
        rsi_values <- RSI(tail_data$Close, n = input$rsiLength)
        rsi <- tail(rsi_values[!is.na(rsi_values)], 1)
        if (length(rsi) > 0) {
          if (rsi > 70) signals <- c(signals, paste("RSI:", round(rsi, 2), "- Overbought"))
          else if (rsi < 30) signals <- c(signals, paste("RSI:", round(rsi, 2), "- Oversold"))
          else signals <- c(signals, paste("RSI:", round(rsi, 2), "- Neutral"))
        }
      }
      
      if ("sma" %in% input$technicalIndicators && nrow(tail_data) >= input$smaLength) {
        sma <- tail(SMA(tail_data$Close, n = input$smaLength), 1)
        current <- tail(tail_data$Close, 1)
        if (!is.na(sma)) {
          pct <- (current - sma) / sma * 100
          signals <- c(signals, paste("Price vs SMA:", ifelse(current > sma, "Above", "Below"), 
                                      paste0("(", round(pct, 2), "%)")))
        }
      }
      
      paste(if (length(signals) > 0) signals else "Select indicators to see signals", collapse = "\n")
    })
    
    output$technicalChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      tail_data <- tail(data, 500)
      
      p <- plot_ly(tail_data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                   name = "Close", line = list(color = "#2c3e50", width = 2))
      
      if ("sma" %in% input$technicalIndicators && nrow(tail_data) >= input$smaLength) {
        p <- p %>% add_lines(y = SMA(tail_data$Close, n = input$smaLength),
                             name = paste("SMA(", input$smaLength, ")"),
                             line = list(color = "#e74c3c", width = 2),
                             type = "scatter", mode = "lines")
      }
      
      if ("ema" %in% input$technicalIndicators && nrow(tail_data) >= input$emaLength) {
        p <- p %>% add_lines(y = EMA(tail_data$Close, n = input$emaLength),
                             name = paste("EMA(", input$emaLength, ")"),
                             line = list(color = "#27ae60", width = 2),
                             type = "scatter", mode = "lines")
      }
      
      if ("bb" %in% input$technicalIndicators && nrow(tail_data) >= input$bbLength) {
        bb <- BBands(tail_data$Close, n = input$bbLength, sd = input$bbSd)
        p <- p %>%
          add_lines(y = bb[,"up"], name = "BB Upper", 
                   line = list(color = "#95a5a6", dash = "dash"),
                   type = "scatter", mode = "lines") %>%
          add_lines(y = bb[,"dn"], name = "BB Lower", 
                   line = list(color = "#95a5a6", dash = "dash"),
                   type = "scatter", mode = "lines")
      }
      
      p %>% layout(
        title = paste("Technical Analysis -", data_manager$current_asset),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Price (USD)"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    })
    
    output$rsiChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      tail_data <- tail(data, 200)
      
      if (nrow(tail_data) < input$rsiLength) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      rsi_values <- RSI(tail_data$Close, n = input$rsiLength)
      plot_data <- tail_data[!is.na(rsi_values),]
      rsi_values <- rsi_values[!is.na(rsi_values)]
      
      plot_ly(plot_data, x = ~Date, y = rsi_values, type = "scatter", mode = "lines",
              line = list(color = "#9b59b6", width = 2)) %>%
        layout(
          title = paste("RSI(", input$rsiLength, ")"),
          xaxis = list(title = "Date"),
          yaxis = list(title = "RSI", range = c(0, 100)),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          shapes = list(
            list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
                 y0 = 70, y1 = 70, line = list(color = "#e74c3c", dash = "dash")),
            list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
                 y0 = 30, y1 = 30, line = list(color = "#27ae60", dash = "dash"))
          )
        )
    })
    
    output$macdChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      tail_data <- tail(data, 200)
      
      if (nrow(tail_data) < 50) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      macd <- MACD(tail_data$Close, nFast = 12, nSlow = 26, nSig = 9)
      plot_data <- data.frame(
        Date = tail_data$Date,
        macd = macd[,"macd"],
        signal = macd[,"signal"]
      ) %>% filter(complete.cases(.))
      
      plot_data$histogram <- plot_data$macd - plot_data$signal
      
      plot_ly(plot_data, x = ~Date) %>%
        add_lines(y = ~macd, name = "MACD", line = list(color = "#3498db", width = 2),
                 type = "scatter", mode = "lines") %>%
        add_lines(y = ~signal, name = "Signal", line = list(color = "#e74c3c", width = 1),
                 type = "scatter", mode = "lines") %>%
        add_bars(y = ~histogram, name = "Histogram",
                 marker = list(color = ifelse(plot_data$histogram > 0, "#27ae60", "#e74c3c")),
                 type = "bar") %>%
        layout(
          title = "MACD",
          xaxis = list(title = "Date"),
          yaxis = list(title = "Value"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$stochChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      tail_data <- tail(data, 200)
      
      if (nrow(tail_data) < 30) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      k_period <- 14
      d_period <- 3
      
      rolling_low <- rollapply(tail_data$Low, width = k_period, FUN = min, align = "right", fill = NA)
      rolling_high <- rollapply(tail_data$High, width = k_period, FUN = max, align = "right", fill = NA)
      
      stoch_k <- ifelse(rolling_high - rolling_low != 0,
                        (tail_data$Close - rolling_low) / (rolling_high - rolling_low) * 100, 50)
      stoch_d <- SMA(stoch_k, n = d_period)
      
      plot_data <- data.frame(Date = tail_data$Date, stoch_k = stoch_k, stoch_d = stoch_d) %>%
        filter(complete.cases(.))
      
      plot_ly(plot_data, x = ~Date) %>%
        add_lines(y = ~stoch_k, name = "%K", line = list(color = "#3498db", width = 2),
                 type = "scatter", mode = "lines") %>%
        add_lines(y = ~stoch_d, name = "%D", line = list(color = "#e74c3c", width = 1),
                 type = "scatter", mode = "lines") %>%
        layout(
          title = "Stochastic Oscillator",
          xaxis = list(title = "Date"),
          yaxis = list(title = "Stochastic (%)", range = c(0, 100)),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          shapes = list(
            list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
                 y0 = 80, y1 = 80, line = list(color = "#e74c3c", dash = "dash")),
            list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
                 y0 = 20, y1 = 20, line = list(color = "#27ae60", dash = "dash"))
          )
        )
    })
    
    session$onSessionEnded(function() {})
  })
}
