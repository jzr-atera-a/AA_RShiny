# modules/advanced_metrics.R

advanced_metrics_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      valueBoxOutput(ns("sharpeRatioBox"), width = 3),
      valueBoxOutput(ns("sortinoRatioBox"), width = 3),
      valueBoxOutput(ns("calmarRatioBox"), width = 3),
      valueBoxOutput(ns("omegaRatioBox"), width = 3)
    ),
    fluidRow(
      box(
        title = "Advanced Metrics Configuration", status = "primary", solidHeader = TRUE, width = 12,
        fluidRow(
          column(3, numericInput(ns("riskFreeRate"), "Risk-Free Rate (%):", value = 4.5, min = 0, max = 10, step = 0.1)),
          column(3, numericInput(ns("targetReturn"), "Target Return for Omega/Downside Dev (%):", value = 0, min = -10, max = 20, step = 0.5)),
          column(3, numericInput(ns("rollingWindow"), "Rolling Window (days):", value = 50, min = 30, max = 500, step = 10)),
          column(3, checkboxInput(ns("annualizeMetrics"), "Annualize Metrics", TRUE))
        )
      )
    ),
    fluidRow(
      box(
        title = "Risk-Adjusted Performance Metrics", status = "primary", solidHeader = TRUE, width = 12,
        withSpinner(DT::dataTableOutput(ns("advancedMetricsTable")))
      )
    ),
    fluidRow(
      box(
        title = "Rolling Sharpe Ratio", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("rollingSharpeChart"), height = "400px"))
      ),
      box(
        title = "Rolling Sortino Ratio", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("rollingSortinoChart"), height = "400px"))
      )
    ),
    fluidRow(
      box(
        title = "Downside Risk Analysis", status = "info", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("downsideRiskChart"), height = "350px"))
      ),
      box(
        title = "Upside vs Downside Capture", status = "info", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("upsideDownsideChart"), height = "350px"))
      )
    ),
    fluidRow(
      box(
        title = "Maximum Drawdown Details", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("maxDrawdownDetailChart"), height = "350px"))
      ),
      box(
        title = "Recovery Period Analysis", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(DT::dataTableOutput(ns("recoveryPeriodTable")))
      )
    )
  )
}

advanced_metrics_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    calculate_sharpe <- function(returns, rf_rate, annualize = TRUE) {
      rf_daily <- rf_rate / 100 / 252
      excess_returns <- returns - rf_daily
      sharpe <- mean(excess_returns, na.rm = TRUE) / sd(excess_returns, na.rm = TRUE)
      if (annualize) sharpe <- sharpe * sqrt(252)
      sharpe
    }
    
    calculate_sortino <- function(returns, rf_rate, annualize = TRUE) {
      rf_daily <- rf_rate / 100 / 252
      excess <- returns - rf_daily
      downside <- pmin(excess, 0)
      ann_mean <- mean(excess, na.rm = TRUE) * 252
      ann_dd <- sqrt(mean(downside^2, na.rm = TRUE)) * sqrt(252)
      if (ann_dd == 0 || is.nan(ann_dd)) return(NA)
      sortino <- ann_mean / ann_dd
      if (!annualize) sortino <- sortino / sqrt(252)
      sortino
    }
    
    calculate_calmar <- function(returns, annualize = TRUE) {
      cumulative <- cumprod(1 + returns)
      running_max <- cummax(cumulative)
      drawdown <- (cumulative - running_max) / running_max
      max_dd <- min(drawdown, na.rm = TRUE)
      if (max_dd == 0) return(NA)
      ann_return <- mean(returns, na.rm = TRUE) * 252
      ann_return / abs(max_dd)
    }
    
    calculate_omega <- function(returns, threshold = 0) {
      threshold_daily <- threshold / 252
      gains <- sum(pmax(returns - threshold_daily, 0), na.rm = TRUE)
      losses <- sum(abs(pmin(returns - threshold_daily, 0)), na.rm = TRUE)
      if (losses == 0) return(Inf)
      gains / losses
    }
    
    output$sharpeRatioBox <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      returns <- data$returns[!is.na(data$returns)]
      sharpe <- if (length(returns) < 30) NA else calculate_sharpe(returns, input$riskFreeRate, input$annualizeMetrics)
      valueBox(value = ifelse(is.na(sharpe), "N/A", round(sharpe, 3)), subtitle = "Sharpe Ratio", icon = icon("chart-line"), color = "blue")
    })
    
    output$sortinoRatioBox <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      returns <- data$returns[!is.na(data$returns)]
      sortino <- if (length(returns) < 30) NA else calculate_sortino(returns, input$riskFreeRate, input$annualizeMetrics)
      valueBox(value = ifelse(is.na(sortino), "N/A", round(sortino, 3)), subtitle = "Sortino Ratio (hurdle = Rf rate)", icon = icon("arrow-trend-down"), color = "green")
    })
    
    output$calmarRatioBox <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      returns <- data$returns[!is.na(data$returns)]
      calmar <- if (length(returns) < 30) NA else calculate_calmar(returns, input$annualizeMetrics)
      valueBox(value = ifelse(is.na(calmar), "N/A", round(calmar, 3)), subtitle = "Calmar Ratio", icon = icon("shield-halved"), color = "teal")
    })
    
    output$omegaRatioBox <- renderValueBox({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      returns <- data$returns[!is.na(data$returns)]
      omega <- if (length(returns) < 30) NA else calculate_omega(returns, input$targetReturn)
      valueBox(value = ifelse(is.na(omega) || is.infinite(omega), "N/A", round(omega, 3)), subtitle = "Omega Ratio", icon = icon("circle-notch"), color = "orange")
    })
    
    output$advancedMetricsTable <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      returns <- data$returns[!is.na(data$returns)]
      if (length(returns) < 30) return(datatable(data.frame(Metric = "Error", Value = "Insufficient data")))
      
      sharpe <- calculate_sharpe(returns, input$riskFreeRate, input$annualizeMetrics)
      sortino <- calculate_sortino(returns, input$riskFreeRate, input$annualizeMetrics)
      calmar <- calculate_calmar(returns)
      omega <- calculate_omega(returns, input$targetReturn)
      
      downside_returns <- pmin(returns - input$targetReturn / 100 / 252, 0)
      downside_dev <- sqrt(mean(downside_returns^2, na.rm = TRUE)) * sqrt(252) * 100
      upside_returns <- pmax(returns - input$targetReturn / 100 / 252, 0)
      upside_pot <- mean(upside_returns, na.rm = TRUE) / sqrt(mean(downside_returns^2, na.rm = TRUE))
      
      cumulative <- cumprod(1 + returns)
      running_max <- cummax(cumulative)
      drawdown <- (cumulative - running_max) / running_max
      max_dd <- min(drawdown, na.rm = TRUE) * 100
      
      metrics <- data.frame(
        Metric = c("Sharpe Ratio", "Sortino Ratio", "Calmar Ratio", "Omega Ratio",
                   "Downside Deviation (%)", "Upside Potential Ratio", "Max Drawdown (%)",
                   "Annualized Return (%)", "Annualized Volatility (%)"),
        Value = c(
          ifelse(is.na(sharpe), "N/A", round(sharpe, 3)),
          ifelse(is.na(sortino), "N/A", round(sortino, 3)),
          ifelse(is.na(calmar), "N/A", round(calmar, 3)),
          ifelse(is.na(omega) || is.infinite(omega), "N/A", round(omega, 3)),
          round(downside_dev, 2),
          ifelse(is.na(upside_pot) || is.infinite(upside_pot), "N/A", round(upside_pot, 3)),
          round(max_dd, 2),
          round(mean(returns, na.rm = TRUE) * 252 * 100, 2),
          round(sd(returns, na.rm = TRUE) * sqrt(252) * 100, 2)
        )
      )
      datatable(metrics, options = list(dom = 't', pageLength = 20), rownames = FALSE)
    })
    
    output$rollingSharpeChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% tail(1000)
      returns <- data$returns
      if (sum(!is.na(returns)) < input$rollingWindow) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      rf_daily <- input$riskFreeRate / 100 / 252
      rolling_sharpe <- rollapply(returns, input$rollingWindow, function(x) {
        excess <- x - rf_daily
        s <- mean(excess, na.rm = TRUE) / sd(excess, na.rm = TRUE)
        if (input$annualizeMetrics) s <- s * sqrt(252)
        s
      }, fill = NA, align = "right")
      
      plot_data <- data.frame(Date = tail(data$Date, length(rolling_sharpe)), sharpe = rolling_sharpe) %>% filter(!is.na(sharpe))
      plot_ly(plot_data, x = ~Date, y = ~sharpe, type = "scatter", mode = "lines", line = list(color = "#3498db", width = 2)) %>%
        layout(title = paste("Rolling Sharpe Ratio (", input$rollingWindow, " days)"), xaxis = list(title = "Date"),
               yaxis = list(title = "Sharpe Ratio"), plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    output$rollingSortinoChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% tail(1000)
      returns <- data$returns
      if (sum(!is.na(returns)) < input$rollingWindow) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      target_daily <- input$riskFreeRate / 100 / 252
      rolling_sortino <- rollapply(returns, input$rollingWindow, function(x) {
        exc <- x - target_daily
        downside <- pmin(exc, 0)
        ann_dd <- sqrt(mean(downside^2, na.rm = TRUE)) * sqrt(252)
        if (ann_dd == 0 || is.nan(ann_dd)) return(NA)
        ann_mean <- mean(exc, na.rm = TRUE) * 252
        s <- ann_mean / ann_dd
        if (!input$annualizeMetrics) s <- s / sqrt(252)
        s
      }, fill = NA, align = "right")
      
      plot_data <- data.frame(Date = tail(data$Date, length(rolling_sortino)), sortino = rolling_sortino) %>% filter(!is.na(sortino))
      plot_ly(plot_data, x = ~Date, y = ~sortino, type = "scatter", mode = "lines", line = list(color = "#27ae60", width = 2)) %>%
        layout(title = paste("Rolling Sortino Ratio (", input$rollingWindow, " days)"), xaxis = list(title = "Date"),
               yaxis = list(title = "Sortino Ratio"), plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    output$downsideRiskChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% tail(500)
      returns <- data$returns[!is.na(data$returns)]
      if (length(returns) < 30) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      target_daily <- input$riskFreeRate / 100 / 252
      downside_returns <- pmin(returns - target_daily, 0) * 100
      plot_data <- data.frame(Date = tail(data$Date, length(downside_returns)), downside = downside_returns)
      
      plot_ly(plot_data, x = ~Date, y = ~downside, type = "scatter", mode = "lines",
              fill = "tozeroy", fillcolor = "rgba(231, 76, 60, 0.3)", line = list(color = "#e74c3c", width = 1.5)) %>%
        layout(title = "Downside Risk (Below Target)", xaxis = list(title = "Date"),
               yaxis = list(title = "Downside Return (%)"), plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    output$upsideDownsideChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      returns <- data$returns[!is.na(data$returns)]
      if (length(returns) < 30) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      target_daily <- input$riskFreeRate / 100 / 252
      upside <- mean(pmax(returns - target_daily, 0), na.rm = TRUE) * 252 * 100
      downside <- abs(mean(pmin(returns - target_daily, 0), na.rm = TRUE)) * 252 * 100
      plot_data <- data.frame(Type = c("Upside Capture", "Downside Capture"), Value = c(upside, downside), Color = c("#27ae60", "#e74c3c"))
      
      plot_ly(plot_data, x = ~Type, y = ~Value, type = "bar", marker = list(color = ~Color)) %>%
        layout(title = "Upside vs Downside Capture", xaxis = list(title = ""),
               yaxis = list(title = "Annualized (%)"), plot_bgcolor = "white", paper_bgcolor = "white", showlegend = FALSE)
    })
    
    output$maxDrawdownDetailChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      returns <- data$returns[!is.na(data$returns)]
      if (length(returns) < 30) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      cumulative <- cumprod(1 + returns)
      running_max <- cummax(cumulative)
      drawdown <- (cumulative - running_max) / running_max * 100
      dd_data <- data.frame(Date = tail(data$Date, length(drawdown)), drawdown = drawdown, cumulative = (cumulative - 1) * 100)
      
      plot_ly(dd_data, x = ~Date) %>%
        add_lines(y = ~cumulative, name = "Cumulative Return", line = list(color = "#3498db", width = 2)) %>%
        add_lines(y = ~drawdown, name = "Drawdown", line = list(color = "#e74c3c", width = 2)) %>%
        layout(title = "Drawdown from Peak", xaxis = list(title = "Date"),
               yaxis = list(title = "Percentage (%)"), plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    output$recoveryPeriodTable <- renderDT({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      returns <- data$returns[!is.na(data$returns)]
      dates <- tail(data$Date, length(returns))
      if (length(returns) < 30) return(datatable(data.frame(Metric = "Error", Value = "Insufficient data")))
      
      cumulative <- cumprod(1 + returns)
      running_max <- cummax(cumulative)
      drawdown <- (cumulative - running_max) / running_max
      max_dd_idx <- which.min(drawdown)
      max_dd_value <- drawdown[max_dd_idx] * 100
      max_dd_date <- dates[max_dd_idx]
      
      if (max_dd_idx < length(drawdown)) {
        recovery_idx <- which(drawdown[(max_dd_idx + 1):length(drawdown)] >= 0)[1]
        if (!is.na(recovery_idx)) {
          recovery_date <- dates[max_dd_idx + recovery_idx]
          recovery_days <- as.numeric(recovery_date - max_dd_date)
        } else {
          recovery_date <- "Not recovered"; recovery_days <- NA
        }
      } else {
        recovery_date <- "Not recovered"; recovery_days <- NA
      }
      
      recovery_data <- data.frame(
        Metric = c("Max Drawdown (%)", "Drawdown Date", "Recovery Date", "Recovery Period (days)", "Current Drawdown (%)", "Days Since Peak"),
        Value = c(
          round(max_dd_value, 2), as.character(max_dd_date), as.character(recovery_date),
          ifelse(is.na(recovery_days), "N/A", recovery_days), round(tail(drawdown, 1) * 100, 2),
          as.numeric(tail(dates, 1) - dates[which.max(cumulative)])
        )
      )
      datatable(recovery_data, options = list(dom = 't'), rownames = FALSE)
    })
    
    session$onSessionEnded(function() {})
  })
}
