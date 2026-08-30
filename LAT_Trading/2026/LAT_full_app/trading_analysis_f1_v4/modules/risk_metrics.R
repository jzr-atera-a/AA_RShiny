# modules/risk_metrics.R

risk_metrics_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Risk Analysis Settings", status = "primary", solidHeader = TRUE, width = 4,
        numericInput(ns("portfolioValue"), "Portfolio Value (USD):",
                     value = 1000000, min = 10000, max = 100000000, step = 10000),
        sliderInput(ns("confidenceLevel"), "VaR Confidence (%):",
                    min = 90, max = 99.5, value = 95, step = 0.5),
        numericInput(ns("timeHorizon"), "Time Horizon (days):", value = 1, min = 1, max = 30),
        radioButtons(ns("varMethod"), "VaR Method:",
                     choices = c("Historical" = "historical", "Parametric" = "parametric",
                                 "Cornish-Fisher" = "modified"),
                     selected = "historical"),
        numericInput(ns("varWindow"), "VaR Window:", value = 250, min = 100, max = 1000),
        br(),
        h5("Risk Summary:"),
        verbatimTextOutput(ns("riskMetrics"))
      ),
      box(
        title = "Value at Risk Analysis", status = "primary", solidHeader = TRUE, width = 8,
        withSpinner(plotlyOutput(ns("varChart"), height = "450px")),
        tags$p(paste0(
          "The red line is rolling VaR in dollar terms; blue bars are actual daily P&L. A blue bar extending ",
          "below the red line is a VaR breach — under 95% confidence you'd expect roughly one breach every ",
          "20 trading sessions."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    fluidRow(
      box(
        title = "Expected Shortfall", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("expectedShortfall"), height = "350px")),
        tags$p("Average loss on the worst days beyond the VaR threshold — 'when things go wrong, how bad does it get on average?'",
               style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      ),
      box(
        title = "Drawdown Analysis", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("drawdownAnalysis"), height = "350px")),
        tags$p("How far the asset has fallen below its most recent all-time high at each point in time.",
               style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    fluidRow(
      box(
        title = "Risk Statistics", status = "info", solidHeader = TRUE, width = 6,
        withSpinner(DT::dataTableOutput(ns("riskStatsTable")))
      ),
      box(
        title = "Stress Testing", status = "info", solidHeader = TRUE, width = 6,
        withSpinner(DT::dataTableOutput(ns("stressTestResults")))
      )
    )
  )
}

risk_metrics_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    output$riskMetrics <- renderText({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% tail(input$varWindow)
      returns <- data$returns[!is.na(data$returns)]
      if (length(returns) < 30) return("Insufficient data")
      
      adjusted_returns <- returns * sqrt(input$timeHorizon)
      var_percentile <- (100 - input$confidenceLevel) / 100
      
      var_value <- if (input$varMethod == "historical") {
        quantile(adjusted_returns, var_percentile)
      } else {
        mean(adjusted_returns) + qnorm(var_percentile) * sd(adjusted_returns)
      }
      
      var_dollar <- abs(var_value) * input$portfolioValue
      sharpe <- mean(returns) / sd(returns) * sqrt(252)
      
      paste(
        paste("Portfolio:", paste0("$", format(input$portfolioValue, big.mark = ","))),
        paste("Time Horizon:", input$timeHorizon, "day(s)"), "",
        paste("VaR:", paste0("$", format(round(var_dollar, 0), big.mark = ","))),
        paste("VaR %:", paste0(round(var_dollar / input$portfolioValue * 100, 3), "%")),
        paste("Sharpe Ratio:", round(sharpe, 3)),
        sep = "\n"
      )
    })
    
    output$varChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% tail(min(1000, nrow(data)))
      returns <- data$returns
      var_percentile <- (100 - input$confidenceLevel) / 100
      window_size <- min(input$varWindow, sum(!is.na(returns)) - 50)
      if (window_size < 50) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      rolling_var <- rollapply(returns, window_size,
                               function(x) quantile(x * sqrt(input$timeHorizon), var_percentile, na.rm = TRUE),
                               fill = NA, align = "right")
      
      plot_data <- data.frame(
        Date = tail(data$Date, length(rolling_var)),
        var_value = abs(rolling_var) * input$portfolioValue,
        daily_pnl = tail(returns, length(rolling_var)) * sqrt(input$timeHorizon) * input$portfolioValue
      ) %>% filter(!is.na(var_value))
      
      plot_ly(plot_data, x = ~Date) %>%
        add_lines(y = ~var_value, name = "VaR", line = list(color = "#e74c3c", width = 2)) %>%
        add_bars(y = ~daily_pnl, name = "Daily P&L", marker = list(color = "#3498db")) %>%
        layout(title = "Value at Risk", xaxis = list(title = "Date"), yaxis = list(title = "USD"),
               plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    output$expectedShortfall <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% tail(800)
      returns <- data$returns
      var_percentile <- (100 - input$confidenceLevel) / 100
      window_size <- min(input$varWindow, sum(!is.na(returns)) - 50)
      if (window_size < 50) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      rolling_es <- rollapply(returns, window_size, function(x) {
        adj_ret <- x * sqrt(input$timeHorizon)
        var_threshold <- quantile(adj_ret, var_percentile, na.rm = TRUE)
        mean(adj_ret[adj_ret <= var_threshold], na.rm = TRUE)
      }, fill = NA, align = "right")
      
      plot_data <- data.frame(Date = tail(data$Date, length(rolling_es)),
                               es_value = abs(rolling_es) * input$portfolioValue) %>% filter(!is.na(es_value))
      
      plot_ly(plot_data, x = ~Date, y = ~es_value, type = "scatter", mode = "lines",
              line = list(color = "#8e44ad", width = 2)) %>%
        layout(title = "Expected Shortfall", xaxis = list(title = "Date"), yaxis = list(title = "USD"),
               plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    output$drawdownAnalysis <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      returns <- data$returns[!is.na(data$returns)]
      cumulative <- cumprod(1 + returns)
      running_max <- cummax(cumulative)
      drawdown <- (cumulative - running_max) / running_max * 100
      dd_data <- data.frame(Date = tail(data$Date, length(drawdown)), drawdown = drawdown)
      
      plot_ly(dd_data, x = ~Date, y = ~drawdown, type = "scatter", mode = "lines",
              fill = "tonexty", fillcolor = "rgba(214, 39, 40, 0.3)",
              line = list(color = "#d62728", width = 2)) %>%
        layout(title = "Drawdown Analysis", xaxis = list(title = "Date"), yaxis = list(title = "Drawdown (%)"),
               plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    output$riskStatsTable <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% tail(input$varWindow)
      returns <- data$returns[!is.na(data$returns)]
      if (length(returns) < 30) return(datatable(data.frame(Metric = "Error", Value = "Insufficient data")))
      
      adj_returns <- returns * sqrt(input$timeHorizon)
      stats <- data.frame(
        Metric = c("Mean Return (%)", "Volatility (%)", "Sharpe Ratio", "Sortino Ratio", "Max Loss (%)", "Max Gain (%)"),
        Value = c(
          round(mean(adj_returns) * 100, 4), round(sd(adj_returns) * 100, 4),
          round(mean(returns) / sd(returns) * sqrt(252), 3),
          round({
            rf_d <- 0.045 / 252
            exc <- returns - rf_d
            ann_dd <- sqrt(mean(pmin(exc, 0)^2, na.rm = TRUE)) * sqrt(252)
            if (ann_dd == 0) NA else mean(exc, na.rm = TRUE) * 252 / ann_dd
          }, 3),
          round(min(adj_returns) * 100, 4), round(max(adj_returns) * 100, 4)
        )
      )
      datatable(stats, options = list(dom = 't'), rownames = FALSE)
    })
    
    output$stressTestResults <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      returns <- data$returns[!is.na(data$returns)]
      hist_vol <- sd(returns) * sqrt(input$timeHorizon)
      
      scenarios <- data.frame(
        Scenario = c("2 Sigma Event", "3 Sigma Event", "4 Sigma Event", "Flash Crash", "Market Crisis"),
        Probability = c("4.5%", "0.3%", "0.006%", "0.01%", "0.1%"),
        Impact_Pct = paste0(round(c(-2, -3, -4, -5, -3.5) * hist_vol * 100, 2), "%"),
        Portfolio_Impact = paste0("-$", format(round(abs(c(-2, -3, -4, -5, -3.5) * hist_vol * input$portfolioValue), 0), big.mark = ","))
      )
      datatable(scenarios, options = list(dom = 't'), rownames = FALSE)
    })
    
    session$onSessionEnded(function() {})
  })
}
