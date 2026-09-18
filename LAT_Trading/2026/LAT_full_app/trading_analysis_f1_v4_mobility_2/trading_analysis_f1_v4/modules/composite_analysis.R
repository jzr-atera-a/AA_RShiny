# modules/composite_analysis.R

composite_analysis_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "warning",
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$strong("How to use this tab:", style = "color:#7d4a00; font-size:14px;"),
            tags$p(HTML(paste0(
              "Tick two or more assets, set an analysis period, choose a normalisation method, then click ",
              "<strong>Run Analysis</strong>. This tab fetches its own independent multi-asset dataset via ",
              "Yahoo Finance (daily resolution) rather than using the sidebar's single-asset selection — ",
              "currently limited to the original 9 Crypto/Equity/Commodity presets, not Forex or IG."
            )), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    fluidRow(
      box(
        title = "Composite Analysis Settings", status = "primary", solidHeader = TRUE, width = 12,
        fluidRow(
          column(4,
                 h5("Compare Multiple Assets:"),
                 checkboxGroupInput(ns("compositeAssets"), "Select Assets to Compare:",
                                    choices = c("Bitcoin (BTC-USD)" = "BTC-USD",
                                                "Ethereum (ETH-USD)" = "ETH-USD",
                                                "Cardano (ADA-USD)" = "ADA-USD",
                                                "NVIDIA (NVDA)" = "NVDA",
                                                "Microsoft (MSFT)" = "MSFT",
                                                "Apple (AAPL)" = "AAPL",
                                                "Gold (GC=F)" = "GC=F",
                                                "Crude Oil (CL=F)" = "CL=F",
                                                "Natural Gas (NG=F)" = "NG=F"),
                                    selected = c("BTC-USD", "NVDA", "GC=F"))
          ),
          column(4,
                 h5("Analysis Period:"),
                 dateRangeInput(ns("compositeRange"), NULL, start = Sys.Date() - months(12), end = Sys.Date())
          ),
          column(4,
                 h5("Normalization:"),
                 radioButtons(ns("normalizeMethod"), NULL,
                              choices = c("Index (Base 100)" = "index", "Percentage Returns" = "returns", "Raw Prices" = "raw"),
                              selected = "index"),
                 actionButton(ns("runComposite"), "Run Analysis", class = "btn-primary", width = "100%")
          )
        )
      )
    ),
    fluidRow(
      box(
        title = "Comparative Performance Chart", status = "primary", solidHeader = TRUE, width = 12,
        withSpinner(plotlyOutput(ns("compositePerformance"), height = "500px"))
      )
    ),
    fluidRow(
      box(
        title = "Correlation Heatmap", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(plotOutput(ns("compositeCorrelation"), height = "400px"))
      ),
      box(
        title = "Risk-Return Scatter", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("riskReturnScatter"), height = "400px"))
      )
    ),
    fluidRow(
      box(
        title = "Performance Metrics Comparison", status = "info", solidHeader = TRUE, width = 6,
        withSpinner(DT::dataTableOutput(ns("compositeMetrics")))
      ),
      box(
        title = "Rolling Correlations", status = "info", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("rollingCorrelations"), height = "350px"))
      )
    ),
    fluidRow(
      box(
        title = "Asset Class Comparison", status = "primary", solidHeader = TRUE, width = 12,
        fluidRow(
          column(3, h5("Crypto Average Performance:"), verbatimTextOutput(ns("cryptoSummary"))),
          column(3, h5("Equity Average Performance:"), verbatimTextOutput(ns("equitySummary"))),
          column(3, h5("Commodity Average Performance:"), verbatimTextOutput(ns("commoditySummary"))),
          column(3, h5("Class Comparison:"), verbatimTextOutput(ns("classComparison")))
        )
      )
    )
  )
}

composite_analysis_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    composite_data <- reactiveVal(NULL)
    
    observeEvent(input$runComposite, {
      showNotification("Loading composite data...", type = "message", duration = 3)
      selected_assets <- input$compositeAssets
      
      if (length(selected_assets) < 2) {
        showNotification("Please select at least 2 assets", type = "warning")
        return()
      }
      
      composite_list <- list()
      failed_assets <- c()
      
      for (symbol in selected_assets) {
        d <- data_manager$fetch_yahoo_daily(symbol)
        if (!is.null(d) && nrow(d) > 0) {
          d <- d %>%
            filter(Date >= input$compositeRange[1] & Date <= input$compositeRange[2]) %>%
            select(Date, Close, returns) %>%
            mutate(asset = symbol)
          composite_list[[symbol]] <- d
        } else {
          failed_assets <- c(failed_assets, symbol)
        }
      }
      
      if (length(failed_assets) > 0) {
        showNotification(paste("Could not load:", paste(failed_assets, collapse = ", ")), type = "warning", duration = 6)
      }
      
      if (length(composite_list) >= 2) {
        composite_data(bind_rows(composite_list))
        showNotification(paste("Loaded", length(composite_list), "assets"), type = "message")
      } else if (length(composite_list) == 1) {
        showNotification("Need at least 2 assets with data for composite analysis", type = "warning")
      } else {
        showNotification("Failed to load composite data — check your internet connection", type = "error")
      }
    })
    
    output$compositePerformance <- renderPlotly({
      data <- composite_data()
      req(data)
      
      if (input$normalizeMethod == "index") {
        data <- data %>% group_by(asset) %>% arrange(Date) %>% mutate(indexed = Close / first(Close) * 100) %>% ungroup()
        p <- plot_ly(data, x = ~Date, y = ~indexed, color = ~asset, type = "scatter", mode = "lines")
        y_title <- "Indexed Value (Base 100)"
      } else if (input$normalizeMethod == "returns") {
        data <- data %>% group_by(asset) %>% arrange(Date) %>%
          mutate(cum_return = cumprod(1 + ifelse(is.na(returns), 0, returns)) - 1) %>% ungroup()
        p <- plot_ly(data, x = ~Date, y = ~cum_return * 100, color = ~asset, type = "scatter", mode = "lines")
        y_title <- "Cumulative Return (%)"
      } else {
        p <- plot_ly(data, x = ~Date, y = ~Close, color = ~asset, type = "scatter", mode = "lines")
        y_title <- "Price (USD)"
      }
      
      p %>% layout(title = "Comparative Performance", xaxis = list(title = "Date"),
                   yaxis = list(title = y_title), plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    output$compositeCorrelation <- renderPlot({
      data <- composite_data()
      req(data)
      
      corr_data <- data %>% filter(!is.na(returns)) %>% select(Date, asset, returns) %>%
        pivot_wider(names_from = asset, values_from = returns) %>% select(-Date) %>% na.omit()
      
      if (ncol(corr_data) < 2) {
        plot.new(); text(0.5, 0.5, "Insufficient data", cex = 1.5); return()
      }
      
      corr_matrix <- cor(corr_data, use = "complete.obs")
      corrplot(corr_matrix, method = "color", type = "upper", tl.cex = 1.0, tl.col = "#2c3e50",
               addCoef.col = "#2c3e50", number.cex = 1.0,
               col = colorRampPalette(c("#e74c3c", "white", "#3498db"))(200), title = "Correlation Matrix")
    })
    
    output$riskReturnScatter <- renderPlotly({
      data <- composite_data()
      req(data)
      
      risk_return <- data %>% filter(!is.na(returns)) %>% group_by(asset) %>%
        summarise(mean_return = mean(returns, na.rm = TRUE) * 252 * 100,
                  volatility = sd(returns, na.rm = TRUE) * sqrt(252) * 100, .groups = 'drop')
      
      plot_ly(risk_return, x = ~volatility, y = ~mean_return, text = ~asset,
              type = "scatter", mode = "markers+text", marker = list(size = 15, color = "#3498db"),
              textposition = "top center") %>%
        layout(title = "Risk-Return Profile", xaxis = list(title = "Annualized Volatility (%)"),
               yaxis = list(title = "Annualized Return (%)"), plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    output$compositeMetrics <- renderDT({
      data <- composite_data()
      req(data)
      
      metrics <- data %>% filter(!is.na(returns)) %>% group_by(asset) %>%
        summarise(
          Total_Return = round((last(Close) / first(Close) - 1) * 100, 2),
          Ann_Return = round(mean(returns) * 252 * 100, 2),
          Ann_Vol = round(sd(returns) * sqrt(252) * 100, 2),
          Sharpe = round(mean(returns) / sd(returns) * sqrt(252), 3),
          Max_DD = round(min((Close / cummax(Close) - 1)) * 100, 2),
          .groups = 'drop'
        )
      
      datatable(metrics, options = list(dom = 't', scrollX = TRUE), rownames = FALSE) %>%
        formatStyle(columns = "Total_Return", backgroundColor = styleInterval(0, c("#f8d7da", "#d4edda")))
    })
    
    output$rollingCorrelations <- renderPlotly({
      data <- composite_data()
      req(data)
      selected <- input$compositeAssets[1:min(2, length(input$compositeAssets))]
      if (length(selected) < 2) return(plot_ly() %>% layout(title = "Select at least 2 assets"))
      
      corr_data <- data %>% filter(asset %in% selected, !is.na(returns)) %>%
        select(Date, asset, returns) %>% pivot_wider(names_from = asset, values_from = returns) %>% arrange(Date)
      
      if (nrow(corr_data) < 60) return(plot_ly() %>% layout(title = "Insufficient data"))
      
      rolling_corr <- rollapply(corr_data[, 2:3], width = 60,
                                FUN = function(x) cor(x[,1], x[,2], use = "complete.obs"),
                                fill = NA, align = "right", by.column = FALSE)
      
      corr_df <- data.frame(Date = tail(corr_data$Date, length(rolling_corr)), correlation = rolling_corr) %>% filter(!is.na(correlation))
      
      plot_ly(corr_df, x = ~Date, y = ~correlation, type = "scatter", mode = "lines", line = list(color = "#3498db", width = 2)) %>%
        layout(title = paste("Rolling Correlation:", paste(selected, collapse = " vs ")), xaxis = list(title = "Date"),
               yaxis = list(title = "Correlation", range = c(-1, 1)), plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    class_summary_text <- function(data, assets, label) {
      d <- data %>% filter(asset %in% assets, !is.na(returns))
      if (nrow(d) == 0) return(paste0("No ", tolower(label), " data"))
      s <- d %>% group_by(asset) %>% summarise(ret = mean(returns) * 252 * 100, vol = sd(returns) * sqrt(252) * 100, .groups = 'drop')
      paste(paste0(label, " Class:"), paste("Avg Return:", round(mean(s$ret), 2), "%"),
            paste("Avg Volatility:", round(mean(s$vol), 2), "%"), paste("Assets:", nrow(s)), sep = "\n")
    }
    
    output$cryptoSummary <- renderText({
      data <- composite_data(); req(data)
      class_summary_text(data, c("BTC-USD", "ETH-USD", "ADA-USD"), "Cryptocurrency")
    })
    output$equitySummary <- renderText({
      data <- composite_data(); req(data)
      class_summary_text(data, c("NVDA", "MSFT", "AAPL"), "Equity")
    })
    output$commoditySummary <- renderText({
      data <- composite_data(); req(data)
      class_summary_text(data, c("GC=F", "CL=F", "NG=F"), "Commodity")
    })
    
    output$classComparison <- renderText({
      data <- composite_data(); req(data)
      crypto_assets <- c("BTC-USD", "ETH-USD", "ADA-USD"); equity_assets <- c("NVDA", "MSFT", "AAPL"); commodity_assets <- c("GC=F", "CL=F", "NG=F")
      crypto_data <- data %>% filter(asset %in% crypto_assets, !is.na(returns))
      equity_data <- data %>% filter(asset %in% equity_assets, !is.na(returns))
      commodity_data <- data %>% filter(asset %in% commodity_assets, !is.na(returns))
      
      if (nrow(crypto_data) == 0 && nrow(equity_data) == 0 && nrow(commodity_data) == 0) return("Insufficient data for comparison")
      
      crypto_ret <- if (nrow(crypto_data) > 0) mean(crypto_data$returns) * 252 * 100 else NA
      equity_ret <- if (nrow(equity_data) > 0) mean(equity_data$returns) * 252 * 100 else NA
      commodity_ret <- if (nrow(commodity_data) > 0) mean(commodity_data$returns) * 252 * 100 else NA
      crypto_vol <- if (nrow(crypto_data) > 0) sd(crypto_data$returns) * sqrt(252) * 100 else NA
      equity_vol <- if (nrow(equity_data) > 0) sd(equity_data$returns) * sqrt(252) * 100 else NA
      commodity_vol <- if (nrow(commodity_data) > 0) sd(commodity_data$returns) * sqrt(252) * 100 else NA
      
      returns_v <- c(Crypto = crypto_ret, Equity = equity_ret, Commodity = commodity_ret); returns_v <- returns_v[!is.na(returns_v)]
      best_return <- if (length(returns_v) > 0) names(which.max(returns_v)) else "N/A"
      vols_v <- c(Crypto = crypto_vol, Equity = equity_vol, Commodity = commodity_vol); vols_v <- vols_v[!is.na(vols_v)]
      most_volatile <- if (length(vols_v) > 0) names(which.max(vols_v)) else "N/A"
      
      paste(
        "Class Comparison:", paste("Best Performer:", best_return), paste("Most Volatile:", most_volatile), "",
        if (!is.na(crypto_ret)) paste("Crypto Return:", round(crypto_ret, 2), "%") else NULL,
        if (!is.na(equity_ret)) paste("Equity Return:", round(equity_ret, 2), "%") else NULL,
        if (!is.na(commodity_ret)) paste("Commodity Return:", round(commodity_ret, 2), "%") else NULL,
        sep = "\n"
      )
    })
    
    session$onSessionEnded(function() {})
  })
}
