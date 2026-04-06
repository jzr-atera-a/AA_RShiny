# modules/chapter02.R — Market and Fundamental Data: Sources and Techniques

chapter2_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(2, "📊", "Market and Fundamental Data",
      "Sources and Techniques - Understanding market microstructure, working with high-frequency data, and accessing fundamental information for algorithmic trading.",
      c("Order Book", "Tick Data", "XBRL", "API Access")),

    stats_row(
      list("8,500+", "NASDAQ Stocks"),
      list("4", "Bar Types"), 
      list("μs", "Latency"),
      list("TB", "Daily Data Volume")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🏛️ Market Microstructure", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Order Types",
                  tags$ul(
                    tags$li(tags$strong("Market Orders:"), " Execute immediately at best available price"),
                    tags$li(tags$strong("Limit Orders:"), " Execute only at specified price or better"),
                    tags$li(tags$strong("Stop Orders:"), " Trigger market/limit order when price threshold reached"),
                    tags$li(tags$strong("Iceberg Orders:"), " Display partial quantity, hide remainder"),
                    tags$li(tags$strong("IOC (Immediate or Cancel):"), " Execute immediately, cancel unfilled"),
                    tags$li(tags$strong("FOK (Fill or Kill):"), " Execute entire order or cancel")
                  )
                ),
                tip_box("Trading Venues", "Modern trading occurs across exchanges (NYSE, NASDAQ), ECNs (Electronic Communication Networks), and dark pools (private exchanges) requiring sophisticated routing algorithms.")
            ),
            
            box(title = "📈 High-Frequency Data Processing", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("NASDAQ TotalView-ITCH",
                  "Binary data feed providing real-time order book updates including all order additions, modifications, cancellations, and executions. Enables reconstruction of complete limit order book state at microsecond granularity."
                ),
                framework_card("FIX Protocol",
                  "Financial Information eXchange (FIX) is the industry-standard messaging protocol for electronic trading. Enables communication between buy-side, sell-side, and exchanges for order routing and execution reporting."
                ),
                info_box("<strong>⚡ Performance:</strong> Processing millions of messages per second requires optimized parsing, efficient data structures, and parallel processing architectures.")
            )
          ),
          
          fluidRow(
            box(title = "📊 Bar Type Comparison", status = "success", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("bar_type_comparison"), height = "400px")
            )
          ),
          
          fluidRow(
            box(title = "🕐 From Ticks to Bars: Data Regularization", status = "info", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Bar Type"), 
                    tags$th("Definition"), 
                    tags$th("Advantages"),
                    tags$th("Use Cases")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Tick Bars")),
                      tags$td("Raw transaction data (every trade)"),
                      tags$td("Maximum information, no aggregation loss"),
                      tags$td("Ultra high-frequency trading, microstructure analysis")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Time Bars")),
                      tags$td("Aggregate over fixed time intervals (1min, 5min, 1hr)"),
                      tags$td("Easy to work with, regular sampling, standard in industry"),
                      tags$td("Technical analysis, intraday strategies, volatility estimation")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Volume Bars")),
                      tags$td("New bar after fixed volume traded"),
                      tags$td("Accounts for order fragmentation, more uniform information"),
                      tags$td("Volume-based strategies, detecting hidden liquidity")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Dollar Bars")),
                      tags$td("New bar after fixed dollar amount traded"),
                      tags$td("Adjusts for price changes, better stationarity"),
                      tags$td("Multi-asset strategies, portfolios with varying prices")
                    )
                  )
                ),
                info_box("<strong>💡 Key Insight:</strong> Alternative bar methods (volume, dollar) can improve signal quality by creating more uniform information content per bar, especially during periods of varying market activity.")
            )
          ),
          
          fluidRow(
            box(title = "💹 Market Data APIs and Sources", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Free/Open Source APIs",
                  tags$ul(
                    tags$li(tags$strong("yfinance:"), " Yahoo Finance data scraper for EOD prices, splits, dividends"),
                    tags$li(tags$strong("pandas-datareader:"), " Multiple source aggregator (FRED, World Bank, OECD)"),
                    tags$li(tags$strong("Alpha Vantage:"), " Free API with rate limits for stocks, forex, crypto"),
                    tags$li(tags$strong("IEX Cloud:"), " Real-time and historical market data with free tier"),
                    tags$li(tags$strong("Quandl:"), " Economic and financial datasets (acquired by NASDAQ)")
                  )
                ),
                framework_card("Professional Data Providers",
                  tags$ul(
                    tags$li(tags$strong("Bloomberg Terminal:"), " Industry standard, comprehensive coverage"),
                    tags$li(tags$strong("Refinitiv Eikon:"), " Real-time data, news, analytics"),
                    tags$li(tags$strong("FactSet:"), " Fundamental and estimates data"),
                    tags$li(tags$strong("AlgoSeek:"), " Historical tick and order book data")
                  )
                )
            ),
            
            box(title = "📄 Fundamental Data Sources", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Financial Statements (XBRL)",
                  "eXtensible Business Reporting Language (XBRL) is the standard format for SEC filings. Enables automated extraction of financial statement data including balance sheets, income statements, cash flows, and footnotes."
                ),
                framework_card("Building Fundamental Time Series",
                  tags$ol(
                    tags$li("Download quarterly/annual filings from SEC EDGAR"),
                    tags$li("Parse XBRL tags to extract financial metrics"),
                    tags$li("Handle restatements and reporting changes"),
                    tags$li("Compute derived ratios and growth rates"),
                    tags$li("Align fiscal periods to calendar dates"),
                    tags$li("Forward-fill point-in-time values to avoid lookahead bias")
                  )
                ),
                tip_box("Point-in-Time Data", "Critical to avoid lookahead bias: only use information that was actually available to market participants at each historical point. Account for reporting lags and restatements.")
            )
          ),
          
          fluidRow(
            box(title = "🗄️ Efficient Data Storage", status = "info", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("storage_comparison"), height = "300px"),
                div(style = "margin-top: 20px;",
                  framework_card("Storage Format Recommendations",
                    tags$ul(
                      tags$li(tags$strong("HDF5 (.h5):"), " Fast random access, compression, supports large datasets. Best for tick/intraday data."),
                      tags$li(tags$strong("Parquet:"), " Columnar storage, excellent compression, integrates with Apache ecosystem. Best for structured datasets."),
                      tags$li(tags$strong("CSV/Feather:"), " CSV for small datasets and interchange; Feather for fast pandas I/O."),
                      tags$li(tags$strong("Databases:"), " PostgreSQL with TimescaleDB for time-series; Arctic for tick data with pandas integration.")
                    )
                  )
                )
            )
          )
        ), # end Theory

        tabPanel(title = tagList(icon("code"), " Python Code"),
          python_code_tab()
        )
      )
    )
  )
}

chapter2_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # Bar type comparison visualization
    output$bar_type_comparison <- renderPlotly({
      # Simulated data showing different bar types
      set.seed(42)
      n_points <- 100
      time_bars <- data.frame(
        bar_num = 1:20,
        method = "Time Bars (5min)",
        bars_created = 20,
        info_variance = runif(20, 0.8, 1.2)
      )
      
      volume_bars <- data.frame(
        bar_num = 1:25,
        method = "Volume Bars",
        bars_created = 25,
        info_variance = runif(25, 0.9, 1.1)
      )
      
      dollar_bars <- data.frame(
        bar_num = 1:23,
        method = "Dollar Bars",
        bars_created = 23,
        info_variance = runif(23, 0.95, 1.05)
      )
      
      all_bars <- rbind(
        data.frame(Method = "Time Bars", Variance = sd(time_bars$info_variance), Bars = 20),
        data.frame(Method = "Volume Bars", Variance = sd(volume_bars$info_variance), Bars = 25),
        data.frame(Method = "Dollar Bars", Variance = sd(dollar_bars$info_variance), Bars = 23)
      )
      
      p <- plot_ly(
        data = all_bars,
        x = ~Method,
        y = ~Variance,
        type = "bar",
        marker = list(
          color = c("#008A82", "#00A39A", "#FF6B35"),
          line = list(color = "white", width = 1.5)
        ),
        text = ~paste0(round(Variance, 3)),
        textposition = "outside",
        hovertemplate = paste(
          "<b>%{x}</b><br>",
          "Information Variance: %{y:.4f}<br>",
          "Bars Created: %{customdata}<br>",
          "<extra></extra>"
        ),
        customdata = ~Bars
      ) %>%
        layout(
          title = list(text = "Information Content Variance by Bar Type<br><sub>Lower variance = more uniform information per bar</sub>", 
                      font = list(color = "#E6EDF3")),
          xaxis = list(
            title = "Bar Construction Method",
            color = "#8B949E"
          ),
          yaxis = list(
            title = "Information Variance (lower is better)",
            color = "#8B949E",
            gridcolor = "#30363D"
          ),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
      
      p
    })
    
    # Storage format comparison
    output$storage_comparison <- renderPlotly({
      storage_data <- data.frame(
        Format = c("CSV", "HDF5", "Parquet", "Feather"),
        Read_Speed = c(1, 8, 12, 15),
        Write_Speed = c(1, 6, 10, 14),
        Compression = c(1, 7, 11, 5),
        Flexibility = c(10, 8, 6, 7)
      )
      
      p <- plot_ly(storage_data) %>%
        add_trace(
          x = ~Format,
          y = ~Read_Speed,
          name = "Read Speed",
          type = "scatter",
          mode = "lines+markers",
          line = list(color = "#008A82", width = 3),
          marker = list(size = 10, color = "#008A82")
        ) %>%
        add_trace(
          x = ~Format,
          y = ~Write_Speed,
          name = "Write Speed",
          type = "scatter",
          mode = "lines+markers",
          line = list(color = "#00A39A", width = 3),
          marker = list(size = 10, color = "#00A39A")
        ) %>%
        add_trace(
          x = ~Format,
          y = ~Compression,
          name = "Compression",
          type = "scatter",
          mode = "lines+markers",
          line = list(color = "#FF6B35", width = 3),
          marker = list(size = 10, color = "#FF6B35")
        ) %>%
        layout(
          title = list(text = "Storage Format Performance Comparison", font = list(color = "#E6EDF3")),
          xaxis = list(
            title = "Storage Format",
            color = "#8B949E"
          ),
          yaxis = list(
            title = "Relative Performance (higher is better)",
            color = "#8B949E",
            gridcolor = "#30363D",
            range = c(0, 16)
          ),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(
            font = list(color = "#E6EDF3"),
            bgcolor = "rgba(28, 33, 40, 0.8)"
          )
        )
      
      p
    })
    
  })
}
