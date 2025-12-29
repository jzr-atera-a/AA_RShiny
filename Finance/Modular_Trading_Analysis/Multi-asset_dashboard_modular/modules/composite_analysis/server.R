# modules/composite_analysis/server.R

composite_analysis_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    composite_data <- reactiveVal(NULL)
    
    observe({
      data_manager$state_trigger()
    })
    
    observeEvent(input$runComparison, {
      if (length(input$compareAssets) < 2) {
        showNotification("Select at least 2 assets to compare", type = "warning")
        return()
      }
      
      tryCatch({
        all_data <- list()
        
        for (symbol in input$compareAssets) {
          asset_data <- getSymbols(symbol, src = "yahoo", auto.assign = FALSE, 
                                  from = input$compareRange[1], to = input$compareRange[2])
          df <- data.frame(
            Date = index(asset_data),
            Close = as.numeric(Cl(asset_data))
          )
          df$returns <- c(NA, diff(log(df$Close)))
          df$Asset <- symbol
          all_data[[symbol]] <- df
        }
        
        composite_data(all_data)
        showNotification("Comparison complete", type = "message")
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    output$assetClassSummary <- renderDT({
      cd <- composite_data()
      if (is.null(cd)) {
        return(datatable(data.frame(Info = "Run comparison to see results")))
      }
      
      summary_data <- do.call(rbind, lapply(names(cd), function(asset) {
        df <- cd[[asset]]
        returns <- df$returns[!is.na(df$returns)]
        
        asset_class <- if (grepl("USD", asset)) "Cryptocurrency"
        else if (grepl("=F", asset)) "Commodity"
        else "Equity"
        
        data.frame(
          Asset = asset,
          Class = asset_class,
          Current_Price = round(tail(df$Close, 1), 2),
          Total_Return = paste0(round((tail(df$Close, 1) / head(df$Close, 1) - 1) * 100, 2), "%"),
          Ann_Return = paste0(round(mean(returns, na.rm = TRUE) * 252 * 100, 2), "%"),
          Ann_Volatility = paste0(round(sd(returns, na.rm = TRUE) * sqrt(252) * 100, 2), "%")
        )
      }))
      
      datatable(summary_data, options = list(pageLength = 10), rownames = FALSE)
    })
    
    output$multiAssetChart <- renderPlotly({
      cd <- composite_data()
      if (is.null(cd)) {
        return(plot_ly() %>% layout(title = "Run comparison to see chart"))
      }
      
      p <- plot_ly()
      colors <- c("#e74c3c", "#3498db", "#27ae60", "#f39c12", "#9b59b6", "#1abc9c", "#e67e22", "#34495e", "#95a5a6")
      
      for (i in seq_along(cd)) {
        asset <- names(cd)[i]
        df <- cd[[asset]]
        
        if (input$normalizationMethod == "index") {
          df$normalized <- df$Close / df$Close[1] * 100
          y_label <- "Index (Base 100)"
        } else if (input$normalizationMethod == "returns") {
          df$normalized <- (cumprod(1 + df$returns) - 1) * 100
          df$normalized[1] <- 0
          y_label <- "Cumulative Return (%)"
        } else {
          df$normalized <- df$Close
          y_label <- "Price"
        }
        
        p <- p %>% add_lines(data = df, x = ~Date, y = ~normalized, name = asset,
                            line = list(color = colors[i], width = 2),
                            type = "scatter", mode = "lines")
      }
      
      p %>% layout(
        title = "Multi-Asset Performance Comparison",
        xaxis = list(title = "Date"),
        yaxis = list(title = y_label),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    })
    
    output$correlationHeatmap <- renderPlotly({
      cd <- composite_data()
      if (is.null(cd)) {
        return(plot_ly() %>% layout(title = "Run comparison"))
      }
      
      returns_matrix <- do.call(cbind, lapply(cd, function(df) df$returns))
      colnames(returns_matrix) <- names(cd)
      returns_matrix <- returns_matrix[complete.cases(returns_matrix), ]
      
      if (nrow(returns_matrix) < 2) {
        return(plot_ly() %>% layout(title = "Insufficient data"))
      }
      
      corr_matrix <- cor(returns_matrix, use = "complete.obs")
      
      plot_ly(z = corr_matrix, x = colnames(corr_matrix), y = colnames(corr_matrix),
              type = "heatmap", colors = colorRamp(c("#e74c3c", "#ffffff", "#27ae60")),
              zmin = -1, zmax = 1) %>%
        layout(
          title = "Correlation Heatmap",
          xaxis = list(title = ""),
          yaxis = list(title = ""),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$riskReturnScatter <- renderPlotly({
      cd <- composite_data()
      if (is.null(cd)) {
        return(plot_ly() %>% layout(title = "Run comparison"))
      }
      
      risk_return <- do.call(rbind, lapply(names(cd), function(asset) {
        df <- cd[[asset]]
        returns <- df$returns[!is.na(df$returns)]
        
        data.frame(
          Asset = asset,
          Return = mean(returns, na.rm = TRUE) * 252 * 100,
          Risk = sd(returns, na.rm = TRUE) * sqrt(252) * 100,
          Sharpe = (mean(returns, na.rm = TRUE) / sd(returns, na.rm = TRUE)) * sqrt(252)
        )
      }))
      
      plot_ly(risk_return, x = ~Risk, y = ~Return, text = ~Asset, type = "scatter", mode = "markers+text",
              marker = list(size = 12, color = ~Sharpe, colorscale = "Viridis", 
                          showscale = TRUE, colorbar = list(title = "Sharpe")),
              textposition = "top center") %>%
        layout(
          title = "Risk-Return Profile",
          xaxis = list(title = "Annualized Volatility (%)"),
          yaxis = list(title = "Annualized Return (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$rollingCorrelations <- renderPlotly({
      cd <- composite_data()
      if (is.null(cd) || length(cd) < 2) {
        return(plot_ly() %>% layout(title = "Run comparison with at least 2 assets"))
      }
      
      returns_matrix <- do.call(cbind, lapply(cd, function(df) df$returns))
      colnames(returns_matrix) <- names(cd)
      
      if (nrow(returns_matrix) < 60) {
        return(plot_ly() %>% layout(title = "Insufficient data for rolling correlation"))
      }
      
      asset1 <- names(cd)[1]
      asset2 <- names(cd)[2]
      
      rolling_corr <- rollapply(returns_matrix[, c(asset1, asset2)], 60,
                               function(x) cor(x[,1], x[,2], use = "complete.obs"),
                               by.column = FALSE, fill = NA, align = "right")
      
      dates <- cd[[1]]$Date
      plot_data <- data.frame(
        Date = tail(dates, length(rolling_corr)),
        Correlation = rolling_corr
      ) %>% filter(!is.na(Correlation))
      
      plot_ly(plot_data, x = ~Date, y = ~Correlation, type = "scatter", mode = "lines",
              line = list(color = "#3498db", width = 2)) %>%
        layout(
          title = paste("Rolling 60-Day Correlation:", asset1, "vs", asset2),
          xaxis = list(title = "Date"),
          yaxis = list(title = "Correlation", range = c(-1, 1)),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$performanceMetricsTable <- renderDT({
      cd <- composite_data()
      if (is.null(cd)) {
        return(datatable(data.frame(Info = "Run comparison")))
      }
      
      metrics <- do.call(rbind, lapply(names(cd), function(asset) {
        df <- cd[[asset]]
        returns <- df$returns[!is.na(df$returns)]
        
        cumulative <- cumprod(1 + returns)
        running_max <- cummax(cumulative)
        drawdown <- (cumulative - running_max) / running_max
        
        data.frame(
          Asset = asset,
          Total_Return = paste0(round((tail(df$Close, 1) / head(df$Close, 1) - 1) * 100, 2), "%"),
          Ann_Return = paste0(round(mean(returns, na.rm = TRUE) * 252 * 100, 2), "%"),
          Ann_Volatility = paste0(round(sd(returns, na.rm = TRUE) * sqrt(252) * 100, 2), "%"),
          Sharpe = round((mean(returns, na.rm = TRUE) / sd(returns, na.rm = TRUE)) * sqrt(252), 3),
          Max_Drawdown = paste0(round(min(drawdown, na.rm = TRUE) * 100, 2), "%"),
          Sortino = round(mean(returns, na.rm = TRUE) / sqrt(mean(pmin(returns, 0)^2, na.rm = TRUE)) * sqrt(252), 3),
          Calmar = round((mean(returns, na.rm = TRUE) * 252) / abs(min(drawdown, na.rm = TRUE)), 3)
        )
      }))
      
      datatable(metrics, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
    })
    
    session$onSessionEnded(function() {})
  })
}
