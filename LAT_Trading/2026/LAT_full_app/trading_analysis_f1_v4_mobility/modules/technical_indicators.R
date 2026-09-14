# modules/technical_indicators.R


technical_indicators_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Technical Analysis Settings", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 3,
        
        checkboxGroupInput(ns("technicalIndicators"), "Select Indicators:",
                           choices = c("Simple Moving Average" = "sma",
                                       "Exponential Moving Average" = "ema",
                                       "RSI" = "rsi",
                                       "MACD" = "macd",
                                       "Bollinger Bands" = "bb",
                                       "Stochastic" = "stoch"),
                           selected = c("sma", "rsi")),
        
        numericInput(ns("smaLength"), "SMA Length:", value = 20, min = 5, max = 200),
        numericInput(ns("emaLength"), "EMA Length:", value = 20, min = 5, max = 200),
        numericInput(ns("rsiLength"), "RSI Length:", value = 14, min = 5, max = 50),
        numericInput(ns("bbLength"), "BB Length:", value = 20, min = 5, max = 100),
        numericInput(ns("bbSd"), "BB Std Dev:", value = 2, min = 1, max = 3, step = 0.1),
        
        br(),
        h5("Current Signals:"),
        verbatimTextOutput(ns("technicalSignals"))
      ),
      
      box(
        title = "Technical Chart", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 9,
        withSpinner(plotlyOutput(ns("technicalChart"), height = "600px")),
        tags$p(paste0(
          "Price chart with the selected technical indicator overlays. SMA and EMA lines track the trend: ",
          "when price is above the line the asset is in an uptrend relative to that period; below signals a ",
          "downtrend. EMA reacts faster than SMA to recent price changes. Bollinger Bands form a volatility ",
          "envelope; a squeeze (bands narrowing) often precedes a significant price move. Use the Current ",
          "Signals panel on the left for a plain-language interpretation of the active indicators."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    
    conditionalPanel(
      condition = sprintf("input['%s'].includes('rsi')", ns("technicalIndicators")),
      fluidRow(
        box(
          title = "RSI Oscillator", 
          status = "primary", 
          solidHeader = TRUE, 
          width = 12,
          withSpinner(plotlyOutput(ns("rsiChart"), height = "300px")),
          tags$p(paste0(
            "The Relative Strength Index oscillates between 0 and 100. Readings above 70 (red dashed line) ",
            "indicate the asset may be overbought and due for a pullback. Readings below 30 (green dashed ",
            "line) suggest oversold conditions and a potential bounce. The RSI crossing back through these ",
            "thresholds is often used as an entry or exit signal. In strong trending markets the RSI can ",
            "remain in overbought or oversold territory for extended periods."
          ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
        )
      )
    ),
    
    conditionalPanel(
      condition = sprintf("input['%s'].includes('macd')", ns("technicalIndicators")),
      fluidRow(
        box(
          title = "MACD Indicator", 
          status = "primary", 
          solidHeader = TRUE, 
          width = 12,
          withSpinner(plotlyOutput(ns("macdChart"), height = "300px")),
          tags$p(paste0(
            "The MACD line (blue) is the difference between the 12-period and 26-period EMAs. The Signal ",
            "line (red) is a 9-period EMA of the MACD line. When MACD crosses above the Signal line it is ",
            "considered a bullish signal; crossing below is bearish. The histogram bars show the gap between ",
            "the two lines: growing green bars indicate strengthening upward momentum; growing red bars ",
            "indicate strengthening downward momentum."
          ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
        )
      )
    ),
    
    conditionalPanel(
      condition = sprintf("input['%s'].includes('stoch')", ns("technicalIndicators")),
      fluidRow(
        box(
          title = "Stochastic Oscillator", 
          status = "primary", 
          solidHeader = TRUE, 
          width = 12,
          withSpinner(plotlyOutput(ns("stochChart"), height = "300px")),
          tags$p(paste0(
            "The Stochastic Oscillator compares the closing price to the High-Low range over the lookback ",
            "period. The %K line (blue) is the raw reading; the %D line (red) is a smoothed signal line. ",
            "Readings above 80 (red dashed line) indicate overbought conditions; below 20 (green dashed ",
            "line) indicate oversold. A %K crossover above %D near the 20 level is a classic buy signal; a ",
            "crossover below %D near 80 is a sell signal."
          ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
        )
      )
    )
  )
}


technical_indicators_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    observe({
      data_manager$state_trigger()
    })
    
    output$technicalSignals <- renderText({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- tail(data, 200)
      
      signals <- c()
      
      if ("rsi" %in% input$technicalIndicators && nrow(data) >= input$rsiLength) {
        rsi_values <- RSI(data$Close, n = input$rsiLength)
        rsi <- tail(rsi_values[!is.na(rsi_values)], 1)
        if (length(rsi) > 0) {
          if (rsi > 70) signals <- c(signals, paste("RSI:", round(rsi, 2), "- Overbought"))
          else if (rsi < 30) signals <- c(signals, paste("RSI:", round(rsi, 2), "- Oversold"))
          else signals <- c(signals, paste("RSI:", round(rsi, 2), "- Neutral"))
        }
      }
      
      if ("sma" %in% input$technicalIndicators && nrow(data) >= input$smaLength) {
        sma <- tail(SMA(data$Close, n = input$smaLength), 1)
        current <- tail(data$Close, 1)
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
      req(data)
      data <- tail(data, 500)
      
      p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                   name = "Close", line = list(color = "#2c3e50", width = 2))
      
      if ("sma" %in% input$technicalIndicators && nrow(data) >= input$smaLength) {
        p <- p %>% add_lines(y = SMA(data$Close, n = input$smaLength),
                             name = paste("SMA(", input$smaLength, ")"),
                             line = list(color = "#e74c3c", width = 2))
      }
      
      if ("ema" %in% input$technicalIndicators && nrow(data) >= input$emaLength) {
        p <- p %>% add_lines(y = EMA(data$Close, n = input$emaLength),
                             name = paste("EMA(", input$emaLength, ")"),
                             line = list(color = "#27ae60", width = 2))
      }
      
      if ("bb" %in% input$technicalIndicators && nrow(data) >= input$bbLength) {
        bb <- BBands(data$Close, n = input$bbLength, sd = input$bbSd)
        p <- p %>%
          add_lines(y = bb[,"up"], name = "BB Upper", line = list(color = "#95a5a6", dash = "dash")) %>%
          add_lines(y = bb[,"dn"], name = "BB Lower", line = list(color = "#95a5a6", dash = "dash"))
      }
      
      p %>% layout(
        title = paste("Technical Analysis -", data_manager$current_asset),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Price"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    })
    
    output$rsiChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- tail(data, 200)
      
      if (nrow(data) < input$rsiLength) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      rsi_values <- RSI(data$Close, n = input$rsiLength)
      plot_data <- data[!is.na(rsi_values), ]
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
      req(data)
      data <- tail(data, 200)
      
      if (nrow(data) < 50) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      macd <- MACD(data$Close, nFast = 12, nSlow = 26, nSig = 9)
      plot_data <- data.frame(
        Date = data$Date,
        macd = macd[, "macd"],
        signal = macd[, "signal"]
      ) %>% filter(complete.cases(.))
      
      plot_data$histogram <- plot_data$macd - plot_data$signal
      
      plot_ly(plot_data, x = ~Date) %>%
        add_lines(y = ~macd, name = "MACD", line = list(color = "#3498db", width = 2)) %>%
        add_lines(y = ~signal, name = "Signal", line = list(color = "#e74c3c", width = 1)) %>%
        add_bars(y = ~histogram, name = "Histogram",
                 marker = list(color = ifelse(plot_data$histogram > 0, "#27ae60", "#e74c3c"))) %>%
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
      req(data)
      data <- tail(data, 200)
      
      if (nrow(data) < 30) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      k_period <- 14
      d_period <- 3
      
      rolling_low <- rollapply(data$Low, width = k_period, FUN = min, align = "right", fill = NA)
      rolling_high <- rollapply(data$High, width = k_period, FUN = max, align = "right", fill = NA)
      
      stoch_k <- ifelse(rolling_high - rolling_low != 0,
                        (data$Close - rolling_low) / (rolling_high - rolling_low) * 100, 50)
      stoch_d <- SMA(stoch_k, n = d_period)
      
      plot_data <- data.frame(Date = data$Date, stoch_k = stoch_k, stoch_d = stoch_d) %>%
        filter(complete.cases(.))
      
      plot_ly(plot_data, x = ~Date) %>%
        add_lines(y = ~stoch_k, name = "%K", line = list(color = "#3498db", width = 2)) %>%
        add_lines(y = ~stoch_d, name = "%D", line = list(color = "#e74c3c", width = 1)) %>%
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
