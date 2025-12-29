# modules/market_overview/server.R

market_overview_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Watch for data changes
    observe({
      data_manager$state_trigger()
    })
    
    # Refresh data
    observeEvent(input$refreshData, {
      data_manager$trigger_refresh()
    })
    
    # Data source info
    output$dataSourceInfo <- renderUI({
      data_manager$state_trigger()
      
      summary <- data_manager$get_summary()
      
      if (!summary$loaded) {
        return(div("No data loaded. Select an asset to begin."))
      }
      
      asset_name <- paste(summary$asset_class, ":", summary$asset)
      
      div(
        h6(asset_name),
        p(paste("Records:", summary$records), style = "margin: 0; font-size: 12px;"),
        p(paste("Last Updated:", format(summary$last_update, "%Y-%m-%d %H:%M")), 
          style = "margin: 0; font-size: 12px;"),
        p(paste("Date Range:", summary$start_date, "to", summary$end_date), 
          style = "margin: 0; font-size: 12px;")
      )
    })
    
    # Value boxes
    output$currentPrice <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(valueBox(value = "--", subtitle = "Current Price", icon = icon("dollar-sign"), color = "blue"))
      }
      
      current_price <- tail(data$Close, 1)
      
      valueBox(
        value = paste0("$", format(round(current_price, 2), big.mark = ",", nsmall = 2)),
        subtitle = paste("Current Price -", data_manager$current_asset),
        icon = icon("dollar-sign"),
        color = "blue"
      )
    })
    
    output$dailyChange <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data) || nrow(data) < 2) {
        return(valueBox(value = "--", subtitle = "Daily Change", icon = icon("minus"), color = "yellow"))
      }
      
      recent <- tail(data, 2)
      change <- (recent$Close[2] - recent$Close[1]) / recent$Close[1] * 100
      color <- ifelse(change > 0, "green", "red")
      icon_name <- ifelse(change > 0, "arrow-up", "arrow-down")
      
      valueBox(
        value = paste0(ifelse(change > 0, "+", ""), format(round(change, 2), nsmall = 2), "%"),
        subtitle = "Daily Change",
        icon = icon(icon_name),
        color = color
      )
    })
    
    output$volumeInfo <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(valueBox(value = "--", subtitle = "Avg Volume", icon = icon("chart-bar"), color = "yellow"))
      }
      
      avg_volume <- mean(data$Volume, na.rm = TRUE)
      
      valueBox(
        value = format(round(avg_volume, 0), big.mark = ","),
        subtitle = "Average Daily Volume",
        icon = icon("chart-bar"),
        color = "yellow"
      )
    })
    
    output$dataRange <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(valueBox(value = "--", subtitle = "Data Range", icon = icon("calendar"), color = "purple"))
      }
      
      days <- as.numeric(max(data$Date) - min(data$Date))
      
      valueBox(
        value = paste(nrow(data), "days"),
        subtitle = paste(days, "days of data"),
        icon = icon("calendar"),
        color = "purple"
      )
    })
    
    # Overview chart
    output$overviewChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      p <- plot_ly()
      
      if ("close" %in% input$overviewComponents) {
        p <- p %>% add_lines(data = data, x = ~Date, y = ~Close, name = "Close Price",
                             line = list(color = "#2c3e50", width = 2),
                             type = "scatter", mode = "lines")
      }
      
      if ("ma" %in% input$overviewComponents && nrow(data) >= input$overviewMA) {
        ma <- SMA(data$Close, n = input$overviewMA)
        p <- p %>% add_lines(data = data, x = ~Date, y = ma, 
                             name = paste("MA(", input$overviewMA, ")"),
                             line = list(color = "#e74c3c", width = 2, dash = "dash"),
                             type = "scatter", mode = "lines")
      }
      
      if ("volume" %in% input$overviewComponents) {
        p <- p %>% add_bars(data = data, x = ~Date, y = ~Volume, name = "Volume",
                            yaxis = "y2", marker = list(color = "#95a5a6", opacity = 0.3),
                            type = "bar")
      }
      
      p <- p %>% layout(
        title = paste(data_manager$current_asset, "- Price & Volume"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Price (USD)", side = "left"),
        yaxis2 = list(title = "Volume", overlaying = "y", side = "right"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
      
      p
    })
    
    # Market stats
    output$marketStats <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(datatable(data.frame(Metric = "No data", Value = "--")))
      }
      
      stats <- data.frame(
        Metric = c("Current", "Mean", "Median", "Min", "Max", "Range", "Std Dev"),
        Value = c(
          format(round(tail(data$Close, 1), 2), big.mark = ","),
          format(round(mean(data$Close), 2), big.mark = ","),
          format(round(median(data$Close), 2), big.mark = ","),
          format(round(min(data$Close), 2), big.mark = ","),
          format(round(max(data$Close), 2), big.mark = ","),
          format(round(max(data$Close) - min(data$Close), 2), big.mark = ","),
          format(round(sd(data$Close), 2), big.mark = ",")
        )
      )
      
      datatable(stats, options = list(dom = 't', pageLength = 10), rownames = FALSE)
    })
    
    # Price movement stats
    output$priceMovementStats <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(datatable(data.frame(Metric = "No data", Value = "--")))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      
      stats <- data.frame(
        Metric = c("Valid Returns", "Mean Return (%)", "Volatility (%)", 
                   "Max Gain (%)", "Max Loss (%)", "Annualized Vol (%)"),
        Value = c(
          length(returns),
          round(mean(returns) * 100, 4),
          round(sd(returns) * 100, 4),
          round(max(returns) * 100, 4),
          round(min(returns) * 100, 4),
          round(sd(returns) * sqrt(252) * 100, 2)
        )
      )
      
      datatable(stats, options = list(dom = 't'), rownames = FALSE)
    })
    
    # Volume stats
    output$volumeStats <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(datatable(data.frame(Metric = "No data", Value = "--")))
      }
      
      stats <- data.frame(
        Metric = c("Mean Volume", "Median Volume", "Max Volume", "Min Volume", "Std Dev"),
        Value = c(
          format(round(mean(data$Volume)), big.mark = ","),
          format(round(median(data$Volume)), big.mark = ","),
          format(round(max(data$Volume)), big.mark = ","),
          format(round(min(data$Volume)), big.mark = ","),
          format(round(sd(data$Volume)), big.mark = ",")
        )
      )
      
      datatable(stats, options = list(dom = 't'), rownames = FALSE)
    })
    
    # Returns distribution
    output$returnsDistribution <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      returns <- data$returns[!is.na(data$returns)] * 100
      
      plot_ly(type = "histogram") %>%
        add_histogram(x = returns, nbinsx = 40,
                     marker = list(color = "#8e44ad", opacity = 0.7)) %>%
        layout(
          title = "Returns Distribution",
          xaxis = list(title = "Returns (%)"),
          yaxis = list(title = "Frequency"),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          showlegend = FALSE
        )
    })
    
    # Price distribution
    output$priceDistribution <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      
      if (is.null(data)) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      plot_ly(type = "histogram") %>%
        add_histogram(x = data$Close, nbinsx = 40,
                     marker = list(color = "#3498db", opacity = 0.7)) %>%
        layout(
          title = "Price Distribution",
          xaxis = list(title = "Price (USD)"),
          yaxis = list(title = "Frequency"),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          showlegend = FALSE
        )
    })
    
    session$onSessionEnded(function() {})
  })
}
