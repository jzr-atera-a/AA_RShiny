# modules/hedging_strategies/server.R

hedging_strategies_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    hedge_data <- reactiveVal(NULL)
    
    observe({
      data_manager$state_trigger()
    })
    
    observeEvent(input$runHedgeAnalysis, {
      data_manager$state_trigger()
      primary_data <- data_manager$get_data()
      
      if (is.null(primary_data)) {
        showNotification("No primary asset data available", type = "error")
        return()
      }
      
      tryCatch({
        hedge_asset_data <- getSymbols(input$hedgeAsset, src = "yahoo", auto.assign = FALSE, from = min(primary_data$Date))
        hedge_df <- data.frame(
          Date = index(hedge_asset_data),
          Close = as.numeric(Cl(hedge_asset_data))
        )
        
        merged <- merge(primary_data[, c("Date", "Close", "returns")], 
                       hedge_df, by = "Date", suffixes = c("_primary", "_hedge"))
        merged$hedge_returns <- c(NA, diff(log(merged$Close_hedge)))
        merged <- merged[complete.cases(merged), ]
        
        hedge_data(merged)
        showNotification("Hedge analysis complete", type = "message")
      }, error = function(e) {
        showNotification(paste("Error fetching hedge data:", e$message), type = "error")
      })
    })
    
    output$unhedgedStats <- renderText({
      hd <- hedge_data()
      if (is.null(hd)) return("Run analysis to see stats")
      
      ret <- mean(hd$returns, na.rm = TRUE) * 252 * 100
      vol <- sd(hd$returns, na.rm = TRUE) * sqrt(252) * 100
      sharpe <- ret / vol
      
      paste(
        paste("Return:", round(ret, 2), "%"),
        paste("Volatility:", round(vol, 2), "%"),
        paste("Sharpe:", round(sharpe, 3)),
        sep = "\n"
      )
    })
    
    output$hedgedStats <- renderText({
      hd <- hedge_data()
      if (is.null(hd)) return("Run analysis to see stats")
      
      if (input$hedgeMethod == "static") {
        hedge_ratio <- input$hedgeRatio
      } else if (input$hedgeMethod == "dynamic") {
        hedge_ratio <- cor(hd$returns, hd$hedge_returns, use = "complete.obs")
      } else if (input$hedgeMethod == "beta") {
        hedge_ratio <- cov(hd$returns, hd$hedge_returns, use = "complete.obs") / var(hd$hedge_returns, na.rm = TRUE)
      } else {
        hedge_ratio <- 1
      }
      
      hedged_returns <- hd$returns - hedge_ratio * hd$hedge_returns
      
      ret <- mean(hedged_returns, na.rm = TRUE) * 252 * 100
      vol <- sd(hedged_returns, na.rm = TRUE) * sqrt(252) * 100
      sharpe <- ret / vol
      
      paste(
        paste("Return:", round(ret, 2), "%"),
        paste("Volatility:", round(vol, 2), "%"),
        paste("Sharpe:", round(sharpe, 3)),
        paste("Hedge Ratio:", round(hedge_ratio, 3)),
        sep = "\n"
      )
    })
    
    output$hedgePerformanceChart <- renderPlotly({
      hd <- hedge_data()
      if (is.null(hd)) {
        return(plot_ly() %>% layout(title = "Run hedge analysis to see results"))
      }
      
      if (input$hedgeMethod == "static") {
        hedge_ratio <- input$hedgeRatio
      } else if (input$hedgeMethod == "dynamic") {
        hedge_ratio <- rollapply(cbind(hd$returns, hd$hedge_returns), input$hedgeLookback,
                                 function(x) cor(x[,1], x[,2], use = "complete.obs"),
                                 by.column = FALSE, fill = NA, align = "right")
      } else if (input$hedgeMethod == "beta") {
        hedge_ratio <- rollapply(cbind(hd$returns, hd$hedge_returns), input$hedgeLookback,
                                 function(x) cov(x[,1], x[,2], use = "complete.obs") / var(x[,2], na.rm = TRUE),
                                 by.column = FALSE, fill = NA, align = "right")
      } else {
        hedge_ratio <- 1
      }
      
      if (length(hedge_ratio) == 1) {
        hedged_returns <- hd$returns - hedge_ratio * hd$hedge_returns
      } else {
        hedged_returns <- hd$returns - hedge_ratio * hd$hedge_returns
      }
      
      unhedged_cum <- cumprod(1 + hd$returns) - 1
      hedged_cum <- cumprod(1 + hedged_returns) - 1
      
      plot_data <- data.frame(
        Date = hd$Date,
        Unhedged = unhedged_cum * 100,
        Hedged = hedged_cum * 100
      )
      
      plot_ly(plot_data, x = ~Date) %>%
        add_lines(y = ~Unhedged, name = "Unhedged", line = list(color = "#e74c3c", width = 2), type = "scatter", mode = "lines") %>%
        add_lines(y = ~Hedged, name = "Hedged", line = list(color = "#27ae60", width = 2), type = "scatter", mode = "lines") %>%
        layout(
          title = "Cumulative Performance: Hedged vs Unhedged",
          xaxis = list(title = "Date"),
          yaxis = list(title = "Cumulative Return (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$hedgeRatioChart <- renderPlotly({
      hd <- hedge_data()
      if (is.null(hd)) {
        return(plot_ly() %>% layout(title = "Run hedge analysis"))
      }
      
      if (input$hedgeMethod == "static") {
        rolling_ratio <- rep(input$hedgeRatio, nrow(hd))
      } else if (input$hedgeMethod == "dynamic") {
        rolling_ratio <- rollapply(cbind(hd$returns, hd$hedge_returns), input$hedgeLookback,
                                   function(x) cor(x[,1], x[,2], use = "complete.obs"),
                                   by.column = FALSE, fill = NA, align = "right")
      } else {
        rolling_ratio <- rollapply(cbind(hd$returns, hd$hedge_returns), input$hedgeLookback,
                                   function(x) cov(x[,1], x[,2], use = "complete.obs") / var(x[,2], na.rm = TRUE),
                                   by.column = FALSE, fill = NA, align = "right")
      }
      
      plot_data <- data.frame(Date = hd$Date, ratio = rolling_ratio) %>% filter(!is.na(ratio))
      
      plot_ly(plot_data, x = ~Date, y = ~ratio, type = "scatter", mode = "lines",
              line = list(color = "#3498db", width = 2)) %>%
        layout(
          title = "Rolling Hedge Ratio",
          xaxis = list(title = "Date"),
          yaxis = list(title = "Hedge Ratio"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$hedgeCorrelationChart <- renderPlotly({
      hd <- hedge_data()
      if (is.null(hd)) {
        return(plot_ly() %>% layout(title = "Run hedge analysis"))
      }
      
      rolling_corr <- rollapply(cbind(hd$returns, hd$hedge_returns), input$hedgeLookback,
                               function(x) cor(x[,1], x[,2], use = "complete.obs"),
                               by.column = FALSE, fill = NA, align = "right")
      
      plot_data <- data.frame(Date = hd$Date, corr = rolling_corr) %>% filter(!is.na(corr))
      
      plot_ly(plot_data, x = ~Date, y = ~corr, type = "scatter", mode = "lines",
              line = list(color = "#9b59b6", width = 2)) %>%
        layout(
          title = "Rolling Correlation",
          xaxis = list(title = "Date"),
          yaxis = list(title = "Correlation", range = c(-1, 1)),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$hedgeEffectivenessTable <- renderDT({
      hd <- hedge_data()
      if (is.null(hd)) {
        return(datatable(data.frame(Metric = "Run analysis")))
      }
      
      if (input$hedgeMethod == "static") {
        hedge_ratio <- input$hedgeRatio
      } else if (input$hedgeMethod == "dynamic") {
        hedge_ratio <- cor(hd$returns, hd$hedge_returns, use = "complete.obs")
      } else {
        hedge_ratio <- cov(hd$returns, hd$hedge_returns, use = "complete.obs") / var(hd$hedge_returns, na.rm = TRUE)
      }
      
      hedged_returns <- hd$returns - hedge_ratio * hd$hedge_returns
      
      var_reduction <- (1 - var(hedged_returns, na.rm = TRUE) / var(hd$returns, na.rm = TRUE)) * 100
      vol_reduction <- (1 - sd(hedged_returns, na.rm = TRUE) / sd(hd$returns, na.rm = TRUE)) * 100
      
      metrics <- data.frame(
        Metric = c("Hedge Ratio", "Variance Reduction (%)", "Volatility Reduction (%)",
                   "Correlation", "R-squared"),
        Value = c(
          round(hedge_ratio, 4),
          round(var_reduction, 2),
          round(vol_reduction, 2),
          round(cor(hd$returns, hd$hedge_returns, use = "complete.obs"), 4),
          round(cor(hd$returns, hd$hedge_returns, use = "complete.obs")^2, 4)
        )
      )
      
      datatable(metrics, options = list(dom = 't'), rownames = FALSE)
    })
    
    output$betaAnalysisChart <- renderPlotly({
      hd <- hedge_data()
      if (is.null(hd)) {
        return(plot_ly() %>% layout(title = "Run hedge analysis"))
      }
      
      plot_ly(data = hd, x = ~hedge_returns * 100, y = ~returns * 100, type = "scatter", mode = "markers",
              marker = list(color = "#3498db", size = 5, opacity = 0.6)) %>%
        add_lines(x = hd$hedge_returns * 100, 
                 y = fitted(lm(returns ~ hedge_returns, data = hd)) * 100,
                 line = list(color = "#e74c3c", width = 2),
                 type = "scatter", mode = "lines") %>%
        layout(
          title = "Beta Analysis",
          xaxis = list(title = "Hedge Asset Returns (%)"),
          yaxis = list(title = "Primary Asset Returns (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          showlegend = FALSE
        )
    })
    
    output$hedgeCostBenefitTable <- renderDT({
      hd <- hedge_data()
      if (is.null(hd)) {
        return(datatable(data.frame(Metric = "Run analysis")))
      }
      
      if (input$hedgeMethod == "static") {
        hedge_ratio <- input$hedgeRatio
      } else if (input$hedgeMethod == "dynamic") {
        hedge_ratio <- cor(hd$returns, hd$hedge_returns, use = "complete.obs")
      } else {
        hedge_ratio <- cov(hd$returns, hd$hedge_returns, use = "complete.obs") / var(hd$hedge_returns, na.rm = TRUE)
      }
      
      hedged_returns <- hd$returns - hedge_ratio * hd$hedge_returns
      
      unhedged_sharpe <- mean(hd$returns, na.rm = TRUE) / sd(hd$returns, na.rm = TRUE) * sqrt(252)
      hedged_sharpe <- mean(hedged_returns, na.rm = TRUE) / sd(hedged_returns, na.rm = TRUE) * sqrt(252)
      
      analysis <- data.frame(
        Scenario = c("Unhedged Portfolio", "Hedged Portfolio", "Benefit"),
        Ann_Return = c(
          paste0(round(mean(hd$returns, na.rm = TRUE) * 252 * 100, 2), "%"),
          paste0(round(mean(hedged_returns, na.rm = TRUE) * 252 * 100, 2), "%"),
          paste0(round((mean(hedged_returns, na.rm = TRUE) - mean(hd$returns, na.rm = TRUE)) * 252 * 100, 2), "%")
        ),
        Ann_Volatility = c(
          paste0(round(sd(hd$returns, na.rm = TRUE) * sqrt(252) * 100, 2), "%"),
          paste0(round(sd(hedged_returns, na.rm = TRUE) * sqrt(252) * 100, 2), "%"),
          paste0(round((sd(hedged_returns, na.rm = TRUE) - sd(hd$returns, na.rm = TRUE)) * sqrt(252) * 100, 2), "%")
        ),
        Sharpe_Ratio = c(
          round(unhedged_sharpe, 3),
          round(hedged_sharpe, 3),
          round(hedged_sharpe - unhedged_sharpe, 3)
        )
      )
      
      datatable(analysis, options = list(dom = 't'), rownames = FALSE)
    })
    
    session$onSessionEnded(function() {})
  })
}
