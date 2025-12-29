# modules/price_analysis/server.R

price_analysis_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Watch for data changes
    observe({
      data_manager$state_trigger()
    })
    
    # Price statistics
    output$priceStats <- renderText({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) return("No data available")
      
      filtered_data <- data %>%
        filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
      
      if (nrow(filtered_data) == 0) return("No data in range")
      
      paste(
        paste("Period:", input$priceRange[1], "to", input$priceRange[2]),
        paste("Records:", nrow(filtered_data)),
        paste("Current:", round(tail(filtered_data$Close, 1), 2)),
        paste("High:", round(max(filtered_data$High), 2)),
        paste("Low:", round(min(filtered_data$Low), 2)),
        sep = "\n"
      )
    })
    
    # Detailed price chart
    output$detailedPriceChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      filtered_data <- data %>%
        filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
      
      if (nrow(filtered_data) == 0) {
        return(plot_ly() %>% layout(title = "No data in selected range"))
      }
      
      p <- plot_ly(filtered_data, x = ~Date)
      
      if ("close" %in% input$priceComponents) {
        p <- p %>% add_lines(y = ~Close, name = "Close", 
                            line = list(color = "#2c3e50", width = 2),
                            type = "scatter", mode = "lines")
      }
      
      if ("highlow" %in% input$priceComponents) {
        p <- p %>% 
          add_lines(y = ~High, name = "High", 
                   line = list(color = "#27ae60", width = 1),
                   type = "scatter", mode = "lines") %>%
          add_lines(y = ~Low, name = "Low", 
                   line = list(color = "#e74c3c", width = 1),
                   type = "scatter", mode = "lines")
      }
      
      if ("open" %in% input$priceComponents) {
        p <- p %>% add_lines(y = ~Open, name = "Open", 
                            line = list(color = "#95a5a6", width = 1),
                            type = "scatter", mode = "lines")
      }
      
      # Add MA
      if (nrow(filtered_data) >= input$priceMAPeriod) {
        ma <- SMA(filtered_data$Close, n = input$priceMAPeriod)
        p <- p %>% add_lines(y = ma, name = paste("MA(", input$priceMAPeriod, ")"),
                            line = list(color = "#9b59b6", width = 2, dash = "dash"),
                            type = "scatter", mode = "lines")
      }
      
      # Add Bollinger Bands
      if (input$showBollingerBands && nrow(filtered_data) >= 20) {
        bb <- BBands(filtered_data$Close, n = 20)
        p <- p %>%
          add_lines(y = bb[,"up"], name = "BB Upper", 
                   line = list(color = "#95a5a6", dash = "dot"),
                   type = "scatter", mode = "lines") %>%
          add_lines(y = bb[,"dn"], name = "BB Lower", 
                   line = list(color = "#95a5a6", dash = "dot"),
                   type = "scatter", mode = "lines")
      }
      
      p %>% layout(
        title = paste("Detailed Price Analysis -", data_manager$current_asset),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Price (USD)"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    })
    
    # OHLC Candlestick Chart
    output$ohlcChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      filtered_data <- data %>%
        filter(Date >= input$priceRange[1] & Date <= input$priceRange[2]) %>%
        tail(200)
      
      if (nrow(filtered_data) == 0) {
        return(plot_ly() %>% layout(title = "No data in selected range"))
      }
      
      plot_ly(filtered_data, x = ~Date, type = "candlestick",
              open = ~Open, high = ~High, low = ~Low, close = ~Close) %>%
        layout(
          title = paste("Candlestick Chart -", data_manager$current_asset),
          xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
          yaxis = list(title = "Price (USD)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    # OHLC Statistics
    output$ohlcStats <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(datatable(data.frame(Metric = "No data", Value = "--")))
      }
      
      filtered_data <- data %>%
        filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
      
      if (nrow(filtered_data) == 0) {
        return(datatable(data.frame(Message = "No data")))
      }
      
      stats <- data.frame(
        Metric = c("Avg Open", "Avg High", "Avg Low", "Avg Close", 
                   "Avg Range", "Max Range", "Bullish Days", "Bearish Days"),
        Value = c(
          round(mean(filtered_data$Open), 2),
          round(mean(filtered_data$High), 2),
          round(mean(filtered_data$Low), 2),
          round(mean(filtered_data$Close), 2),
          round(mean(filtered_data$High - filtered_data$Low), 2),
          round(max(filtered_data$High - filtered_data$Low), 2),
          paste0(round(sum(filtered_data$Close > filtered_data$Open) / nrow(filtered_data) * 100, 1), "%"),
          paste0(round(sum(filtered_data$Close < filtered_data$Open) / nrow(filtered_data) * 100, 1), "%")
        )
      )
      
      datatable(stats, options = list(dom = 't'), rownames = FALSE)
    })
    
    # Returns Time Series
    output$returnsTimeSeries <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      filtered_data <- data %>%
        filter(Date >= input$priceRange[1] & Date <= input$priceRange[2], !is.na(returns))
      
      if (nrow(filtered_data) == 0) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      plot_ly(filtered_data, x = ~Date, y = ~returns * 100, 
              type = "scatter", mode = "lines",
              line = list(color = "#8e44ad", width = 1)) %>%
        layout(
          title = "Returns Time Series",
          xaxis = list(title = "Date"),
          yaxis = list(title = "Returns (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    # Cumulative Returns
    output$cumulativeReturns <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      filtered_data <- data %>%
        filter(Date >= input$priceRange[1] & Date <= input$priceRange[2], !is.na(returns))
      
      if (nrow(filtered_data) == 0) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      filtered_data$cumulative_returns <- cumprod(1 + filtered_data$returns) - 1
      
      plot_ly(filtered_data, x = ~Date, y = ~cumulative_returns * 100, 
              type = "scatter", mode = "lines",
              line = list(color = "#27ae60", width = 2)) %>%
        layout(
          title = "Cumulative Returns",
          xaxis = list(title = "Date"),
          yaxis = list(title = "Cumulative Return (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    session$onSessionEnded(function() {})
  })
}
