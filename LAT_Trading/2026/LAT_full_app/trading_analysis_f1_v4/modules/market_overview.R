# modules/market_overview.R


market_overview_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Data Information & Chart Controls",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(4,
                 div(class = "data-info",
                     uiOutput(ns("dataSourceInfo")))
          ),
          column(4,
                 checkboxGroupInput(ns("overviewComponents"), "Show Components:",
                                    choices = c("Close Price" = "close",
                                                "Volume" = "volume",
                                                "Moving Averages" = "ma"),
                                    selected = c("close", "volume"),
                                    inline = FALSE)
          ),
          column(4,
                 numericInput(ns("overviewMA"), "Moving Average Period:",
                              value = 20, min = 5, max = 200, step = 5),
                 tags$p("Use the Refresh Data link in the header to re-fetch the current asset.",
                        style = "font-size:11px; color:#888; font-style:italic; margin-top:6px;")
          )
        )
      )
    ),
    
    fluidRow(
      valueBoxOutput(ns("currentPrice"), width = 3),
      valueBoxOutput(ns("dailyChange"), width = 3),
      valueBoxOutput(ns("volumeInfo"), width = 3),
      valueBoxOutput(ns("dataRange"), width = 3)
    ),
    
    fluidRow(
      box(
        title = "Price Chart with Volume", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        withSpinner(plotlyOutput(ns("overviewChart"), height = "500px")),
        tags$p(paste0(
          "Combined price and volume chart for the selected asset. The main line shows the closing price ",
          "over the full loaded history. Volume bars at the bottom indicate how many units were traded each ",
          "session; high-volume sessions accompanied by large price moves are generally considered more ",
          "significant signals than low-volume moves. The optional moving average overlay helps identify ",
          "whether the asset is in an uptrend, downtrend, or sideways range."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    
    fluidRow(
      box(
        title = "Market Statistics", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        withSpinner(DT::dataTableOutput(ns("marketStats"))),
        tags$p(paste0(
          "Key price level statistics across the full loaded data range, including average, minimum, and ",
          "maximum closing prices. These anchor values provide context for where the current price sits ",
          "relative to the asset's historical range."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      ),
      box(
        title = "Price Movement Analysis", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        withSpinner(DT::dataTableOutput(ns("priceMovementStats"))),
        tags$p(paste0(
          "Breakdown of price behaviour patterns: average range, frequency of gap opens, and session-level ",
          "directional statistics. Useful for understanding the typical volatility character of the asset."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      ),
      box(
        title = "Volume Analysis", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        withSpinner(DT::dataTableOutput(ns("volumeStats"))),
        tags$p(paste0(
          "Summary of trading volume across the data range. Mean, median, and standard deviation of volume ",
          "reveal whether liquidity is consistent or episodic. Note: volume data is not available for some ",
          "commodity futures, FX, or crypto feeds and will display as N/A for those instruments."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    
    fluidRow(
      box(
        title = "Returns Distribution", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("returnsDistribution"), height = "300px")),
        tags$p(paste0(
          "Histogram of all returns over the full loaded history. A symmetrical bell shape centred near zero ",
          "is consistent with a random walk. Fat tails indicate more frequent extreme moves than a normal ",
          "distribution would predict — characteristic of crypto and commodity markets."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      ),
      box(
        title = "Price Distribution", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("priceDistribution"), height = "300px")),
        tags$p(paste0(
          "Histogram of all closing price levels over the full loaded history. Multiple peaks indicate a ",
          "ranging market spending extended time at key support/resistance levels; a single peak suggests a ",
          "trending period."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    )
  )
}


market_overview_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    observe({
      data_manager$state_trigger()
    })
    
    output$dataSourceInfo <- renderUI({
      data_manager$state_trigger()
      
      if (!data_manager$data_loaded) {
        return(div("No data loaded. Select an asset to begin."))
      }
      
      class_labels <- c(crypto = "Cryptocurrency", equity = "Equity", commodity = "Commodity",
                         forex = "Forex", ig = "IG (CFD)")
      class_label <- class_labels[[data_manager$current_asset_class]] %||% data_manager$current_asset_class
      asset_name <- paste0(class_label, ": ", data_manager$current_asset)
      
      data <- data_manager$asset_data
      
      div(
        h6(asset_name),
        p(paste("Records:", nrow(data)), style = "margin: 0; font-size: 12px;"),
        p(paste("Last Updated:", format(data_manager$last_update, "%Y-%m-%d %H:%M")), 
          style = "margin: 0; font-size: 12px;"),
        p(paste("Date Range:", min(data$Date), "to", max(data$Date)), 
          style = "margin: 0; font-size: 12px;")
      )
    })
    
    output$currentPrice <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      
      current_price <- tail(data$Close, 1)
      price_display <- if (is.na(current_price) || is.nan(current_price)) {
        "N/A"
      } else {
        paste0("$", format(round(current_price, 2), big.mark = ",", nsmall = 2))
      }
      
      valueBox(
        value    = price_display,
        subtitle = paste("Current Price -", data_manager$current_asset),
        icon     = icon("dollar-sign"),
        color    = "blue"
      )
    })
    
    output$dailyChange <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      
      if (nrow(data) >= 2) {
        recent <- tail(data, 2)
        change <- (recent$Close[2] - recent$Close[1]) / recent$Close[1] * 100
        color <- ifelse(change > 0, "green", "red")
        icon_name <- ifelse(change > 0, "arrow-up", "arrow-down")
      } else {
        change <- 0
        color <- "yellow"
        icon_name <- "minus"
      }
      
      valueBox(
        value = paste0(ifelse(change > 0, "+", ""), format(round(change, 2), nsmall = 2), "%"),
        subtitle = "Period Change",
        icon = icon(icon_name),
        color = color
      )
    })
    
    output$volumeInfo <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      
      avg_volume <- mean(data$Volume, na.rm = TRUE)
      has_volume  <- !is.nan(avg_volume) && !is.na(avg_volume) && avg_volume > 0
      vol_display <- if (has_volume) format(round(avg_volume, 0), big.mark = ",") else "N/A"
      vol_label   <- if (has_volume) "Average Volume" else "Volume Not Available"
      
      valueBox(
        value    = vol_display,
        subtitle = vol_label,
        icon     = icon("chart-bar"),
        color    = "yellow"
      )
    })
    
    output$dataRange <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      
      days <- as.numeric(difftime(max(data$Date), min(data$Date), units = "days"))
      
      valueBox(
        value = paste(nrow(data), "bars"),
        subtitle = paste(round(days, 1), "days of data"),
        icon = icon("calendar"),
        color = "purple"
      )
    })
    
    output$overviewChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      
      p <- plot_ly()
      
      if ("close" %in% input$overviewComponents) {
        p <- p %>% add_lines(data = data, x = ~Date, y = ~Close, name = "Close Price",
                             line = list(color = "#2c3e50", width = 2))
      }
      
      if ("ma" %in% input$overviewComponents && nrow(data) >= input$overviewMA) {
        ma <- SMA(data$Close, n = input$overviewMA)
        p <- p %>% add_lines(data = data, x = ~Date, y = ma, 
                             name = paste("MA(", input$overviewMA, ")"),
                             line = list(color = "#e74c3c", width = 2, dash = "dash"))
      }
      
      if ("volume" %in% input$overviewComponents) {
        has_vol <- any(!is.na(data$Volume) & data$Volume > 0, na.rm = TRUE)
        if (has_vol) {
          p <- p %>% add_bars(data = data, x = ~Date, y = ~Volume, name = "Volume",
                              yaxis = "y2", marker = list(color = "#95a5a6", opacity = 0.3))
        }
      }
      
      p %>% layout(
        title = paste(data_manager$current_asset, "- Price & Volume"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Price", side = "left"),
        yaxis2 = list(title = "Volume", overlaying = "y", side = "right"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    })
    
    output$marketStats <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      
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
    
    output$priceMovementStats <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      
      returns <- data$returns[!is.na(data$returns)]
      req(length(returns) > 0)
      
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
    
    output$volumeStats <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      
      vol <- data$Volume
      has_vol <- any(!is.na(vol) & vol > 0, na.rm = TRUE)
      
      safe_fmt <- function(x) {
        if (is.na(x) || is.nan(x) || is.infinite(x)) "N/A"
        else format(round(x), big.mark = ",")
      }
      
      stats <- data.frame(
        Metric = c("Mean Volume", "Median Volume", "Max Volume", "Min Volume", "Std Dev"),
        Value  = if (has_vol) {
          c(safe_fmt(mean(vol, na.rm = TRUE)),
            safe_fmt(median(vol, na.rm = TRUE)),
            safe_fmt(max(vol,  na.rm = TRUE)),
            safe_fmt(min(vol,  na.rm = TRUE)),
            safe_fmt(sd(vol,   na.rm = TRUE)))
        } else {
          rep("N/A (no volume data)", 5)
        }
      )
      
      datatable(stats, options = list(dom = 't'), rownames = FALSE)
    })
    
    output$returnsDistribution <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      
      returns <- data$returns[!is.na(data$returns)] * 100
      req(length(returns) > 0)
      
      plot_ly(x = returns, type = "histogram", nbinsx = 40,
              marker = list(color = "#8e44ad", opacity = 0.7)) %>%
        layout(
          title = "Returns Distribution",
          xaxis = list(title = "Returns (%)"),
          yaxis = list(title = "Frequency"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$priceDistribution <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      
      plot_ly(x = data$Close, type = "histogram", nbinsx = 40,
              marker = list(color = "#3498db", opacity = 0.7)) %>%
        layout(
          title = "Price Distribution",
          xaxis = list(title = "Price"),
          yaxis = list(title = "Frequency"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    session$onSessionEnded(function() {})
  })
}
