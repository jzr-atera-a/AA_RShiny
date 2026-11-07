# modules/volatility_analysis.R

volatility_analysis_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Volatility Analysis Controls", status = "primary", solidHeader = TRUE, width = 4,
        radioButtons(ns("volatilityType"), "Volatility Method:",
                     choices = c("Realized (Close-to-Close)" = "realized",
                                 "Parkinson (High-Low)" = "parkinson",
                                 "Garman-Klass (OHLC)" = "gk"),
                     selected = "realized"),
        numericInput(ns("volWindow"), "Rolling Window:", value = 30, min = 10, max = 252),
        sliderInput(ns("volConfidence"), "Confidence Level:", min = 90, max = 99, value = 95),
        checkboxInput(ns("annualizeVol"), "Annualize Volatility", TRUE),
        br(),
        h5("Volatility Metrics:"),
        verbatimTextOutput(ns("volatilityMetrics"))
      ),
      box(
        title = "Volatility Time Series", status = "primary", solidHeader = TRUE, width = 8,
        withSpinner(plotlyOutput(ns("volatilityChart"), height = "450px")),
        tags$p(paste0(
          "Rolling volatility of the selected asset. Peaks identify periods of elevated market stress. ",
          "Sustained readings near the upper band suggest a high-volatility regime; readings near the lower ",
          "band suggest a calm, low-risk environment."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    fluidRow(
      box(
        title = "Volatility Distribution", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("volatilityDist"), height = "350px")),
        tags$p("Histogram of all rolling volatility readings over the full history.",
               style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      ),
      box(
        title = "Volatility Clustering", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("volatilityClustering"), height = "350px")),
        tags$p(paste0(
          "Absolute daily returns over time. Clustering is visible when tall spikes appear in groups — the ",
          "empirical basis for GARCH-type volatility models."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    fluidRow(
      box(
        title = "Volatility Regime Analysis", status = "info", solidHeader = TRUE, width = 12,
        withSpinner(plotlyOutput(ns("volatilityRegimes"), height = "300px")),
        tags$p(paste0(
          "Each observation colour-coded into Low / Normal / High volatility regimes based on the 25th and ",
          "75th historical percentile thresholds."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    )
  )
}

volatility_analysis_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Computes rolling volatility (decimal, non-annualized) using the selected estimator.
    # Realized (close-to-close) uses log returns' rolling std dev. Parkinson uses the
    # High-Low range, more efficient for assets with large intraday extremes. Garman-Klass
    # additionally uses Open/Close and is the most statistically efficient of the three —
    # all standard published estimator formulas.
    compute_rolling_vol <- function(data, method, window) {
      n <- nrow(data)
      if (n < window) return(rep(NA_real_, n))
      
      if (method == "parkinson") {
        log_hl2 <- (log(data$High / data$Low))^2
        roll_sum <- rollapply(log_hl2, window, sum, fill = NA, align = "right", na.rm = TRUE)
        return(sqrt(roll_sum / (4 * log(2) * window)))
      } else if (method == "gk") {
        log_hl2 <- (log(data$High / data$Low))^2
        log_co2 <- (log(data$Close / data$Open))^2
        gk_term <- 0.5 * log_hl2 - (2 * log(2) - 1) * log_co2
        roll_sum <- rollapply(gk_term, window, sum, fill = NA, align = "right", na.rm = TRUE)
        return(sqrt(pmax(roll_sum, 0) / window))
      } else {
        # realized (close-to-close)
        return(as.numeric(rollapply(data$returns, window, sd, fill = NA, align = "right", na.rm = TRUE)))
      }
    }
    
    output$volatilityMetrics <- renderText({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% tail(500)
      if (nrow(data) < input$volWindow) return("Insufficient data")
      
      rolling_vol <- compute_rolling_vol(data, input$volatilityType, input$volWindow)
      rolling_vol <- rolling_vol[!is.na(rolling_vol)]
      if (length(rolling_vol) == 0) return("Insufficient data")
      
      current_vol <- tail(rolling_vol, 1)
      all_vol <- mean(rolling_vol)
      if (input$annualizeVol) { current_vol <- current_vol * sqrt(252); all_vol <- all_vol * sqrt(252) }
      vol_unit <- ifelse(input$annualizeVol, "% (ann.)", "% (daily)")
      method_label <- c(realized = "Realized (Close-to-Close)", parkinson = "Parkinson (High-Low)", gk = "Garman-Klass (OHLC)")[[input$volatilityType]]
      
      paste(
        paste("Method:", method_label),
        paste("Current Volatility:", round(current_vol * 100, 3), vol_unit),
        paste("Historical Avg:", round(all_vol * 100, 3), vol_unit),
        paste("Data Points:", length(rolling_vol)),
        sep = "\n"
      )
    })
    
    output$volatilityChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% tail(1000)
      if (nrow(data) < input$volWindow) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      rolling_vol <- compute_rolling_vol(data, input$volatilityType, input$volWindow)
      if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
      vol_mean <- mean(rolling_vol, na.rm = TRUE)
      vol_sd <- sd(rolling_vol, na.rm = TRUE)
      confidence_mult <- qnorm((100 + input$volConfidence) / 200)
      
      plot_data <- data.frame(
        Date = data$Date, vol = rolling_vol,
        upper = vol_mean + confidence_mult * vol_sd,
        lower = pmax(0, vol_mean - confidence_mult * vol_sd)
      ) %>% filter(!is.na(vol))
      
      method_label <- c(realized = "Realized", parkinson = "Parkinson", gk = "Garman-Klass")[[input$volatilityType]]
      
      plot_ly(plot_data, x = ~Date) %>%
        add_lines(y = ~vol * 100, name = paste0("Volatility (", method_label, ")"), line = list(color = "#2c3e50", width = 2)) %>%
        add_lines(y = ~upper * 100, name = "Upper Band", line = list(color = "#e74c3c", dash = "dash")) %>%
        add_lines(y = ~lower * 100, name = "Lower Band", line = list(color = "#27ae60", dash = "dash")) %>%
        layout(
          title = paste("Volatility Analysis (", method_label, ") -", data_manager$current_asset),
          xaxis = list(title = "Date"),
          yaxis = list(title = ifelse(input$annualizeVol, "Ann. Volatility (%)", "Daily Vol (%)")),
          plot_bgcolor = "white", paper_bgcolor = "white"
        )
    })
    
    output$volatilityDist <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      if (nrow(data) < input$volWindow) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      rolling_vol <- compute_rolling_vol(data, input$volatilityType, input$volWindow)
      if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
      vol_data <- rolling_vol[!is.na(rolling_vol)]
      if (length(vol_data) < 20) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      plot_ly(x = vol_data * 100, type = "histogram", nbinsx = 30,
              marker = list(color = "#3498db", opacity = 0.7)) %>%
        layout(title = "Volatility Distribution",
               xaxis = list(title = ifelse(input$annualizeVol, "Ann. Vol (%)", "Daily Vol (%)")),
               yaxis = list(title = "Frequency"), plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    output$volatilityClustering <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% tail(500) %>% filter(!is.na(returns))
      if (nrow(data) < 20) return(plot_ly() %>% layout(title = "Insufficient data"))
      data$abs_returns <- abs(data$returns) * 100
      
      plot_ly(data, x = ~Date, y = ~abs_returns, type = "scatter", mode = "lines",
              line = list(color = "#e74c3c", width = 1.5)) %>%
        layout(title = "Volatility Clustering", xaxis = list(title = "Date"),
               yaxis = list(title = "Absolute Return (%)"), plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    output$volatilityRegimes <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      if (nrow(data) < input$volWindow) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      rolling_vol <- compute_rolling_vol(data, input$volatilityType, input$volWindow)
      if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
      vol_25 <- quantile(rolling_vol, 0.25, na.rm = TRUE)
      vol_75 <- quantile(rolling_vol, 0.75, na.rm = TRUE)
      
      regime_data <- data.frame(
        Date = data$Date, vol = rolling_vol,
        regime = ifelse(rolling_vol <= vol_25, "Low", ifelse(rolling_vol >= vol_75, "High", "Normal"))
      ) %>% filter(!is.na(vol))
      
      colors <- c("Low" = "#27ae60", "Normal" = "#3498db", "High" = "#e74c3c")
      plot_ly(regime_data, x = ~Date, y = ~vol * 100, color = ~regime, colors = colors,
              type = "scatter", mode = "markers") %>%
        layout(title = "Volatility Regimes", xaxis = list(title = "Date"),
               yaxis = list(title = ifelse(input$annualizeVol, "Ann. Vol (%)", "Daily Vol (%)")),
               plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    session$onSessionEnded(function() {})
  })
}
