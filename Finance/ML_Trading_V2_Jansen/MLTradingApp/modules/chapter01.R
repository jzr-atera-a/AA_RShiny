# modules/chapter01.R — Machine Learning for Trading: From Idea to Execution

chapter1_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(1, "🚀", "Machine Learning for Trading",
      "From Idea to Execution - Understanding the rise of ML in the investment industry and how to design and execute ML-driven trading strategies.",
      c("Algorithmic Trading", "Smart Beta", "Alternative Data", "Quantamental Funds")),

    stats_row(
      list("$1T+", "ML Fund AUM"),
      list("3", "Trading Phases"), 
      list("5+", "ML Use Cases"),
      list("2010s", "HFT Era")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🏦 The Rise of ML in Investment Industry", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Electronic to High-Frequency Trading",
                  "The evolution from manual trading to algorithmic systems has transformed financial markets. High-frequency trading (HFT) firms now account for a significant portion of market volume, executing thousands of trades per second."
                ),
                framework_card("Factor Investing and Smart Beta",
                  "Smart beta strategies systematically capture risk premiums through rule-based approaches. These strategies bridge traditional index investing and active management by targeting specific factors like value, momentum, quality, and low volatility."
                ),
                info_box("<strong>📊 Market Impact:</strong> Algorithmic pioneers like Renaissance Technologies' Medallion Fund have consistently outperformed traditional hedge funds, demonstrating the power of systematic, data-driven approaches.")
            ),
            
            box(title = "💰 ML-Driven Funds Performance", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Asset Growth",
                  "ML-driven funds have attracted over $1 trillion in assets under management (AUM), reflecting growing institutional confidence in algorithmic strategies."
                ),
                framework_card("Quantamental Funds",
                  "The emergence of quantamental funds combines quantitative modeling with fundamental analysis, leveraging ML to process vast amounts of structured and unstructured data including news, filings, and alternative datasets."
                ),
                tip_box("Strategic Capabilities", "Leading firms invest heavily in data infrastructure, computing resources, and ML talent to maintain competitive advantages in signal discovery and execution speed.")
            )
          ),
          
          fluidRow(
            box(title = "🔄 ML Trading Strategy Workflow", status = "success", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("strategy_workflow"), height = "400px")
            )
          ),
          
          fluidRow(
            box(title = "📊 Data Sourcing and Management", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Data Types",
                  tags$ul(
                    tags$li(tags$strong("Market Data:"), " Price, volume, order book, trades"),
                    tags$li(tags$strong("Fundamental Data:"), " Financial statements, earnings, ratios"),
                    tags$li(tags$strong("Alternative Data:"), " Satellite imagery, web traffic, sentiment"),
                    tags$li(tags$strong("Economic Data:"), " Macro indicators, central bank policies")
                  )
                ),
                framework_card("Data Pipeline Requirements",
                  tags$ul(
                    tags$li("High-frequency data ingestion and storage"),
                    tags$li("Data cleaning and normalization"),
                    tags$li("Feature engineering and transformation"),
                    tags$li("Versioning and reproducibility")
                  )
                )
            ),
            
            box(title = "🎯 Alpha Factor Research to Portfolio Management", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Research Phase",
                  tags$ol(
                    tags$li(tags$strong("Hypothesis Generation:"), " Identify potential alpha sources"),
                    tags$li(tags$strong("Data Collection:"), " Acquire relevant datasets"),
                    tags$li(tags$strong("Feature Engineering:"), " Transform raw data into predictive signals"),
                    tags$li(tags$strong("Model Development:"), " Train and validate ML models"),
                    tags$li(tags$strong("Backtesting:"), " Test strategy on historical data")
                  )
                ),
                framework_card("Execution Phase",
                  tags$ol(
                    tags$li(tags$strong("Signal Generation:"), " Deploy models in production"),
                    tags$li(tags$strong("Portfolio Construction:"), " Optimize position sizing and risk"),
                    tags$li(tags$strong("Order Execution:"), " Minimize market impact and slippage"),
                    tags$li(tags$strong("Performance Monitoring:"), " Track live results vs backtest"),
                    tags$li(tags$strong("Risk Management:"), " Control drawdowns and exposures")
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🧠 ML Use Cases for Trading", status = "success", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Use Case"), 
                    tags$th("Description"), 
                    tags$th("ML Approach"),
                    tags$th("Example")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td("Alpha Factor Creation"),
                      tags$td("Discover predictive signals from data"),
                      tags$td("Supervised Learning"),
                      tags$td("Gradient boosting to predict returns")
                    ),
                    tags$tr(
                      tags$td("Asset Allocation"),
                      tags$td("Optimize portfolio weights"),
                      tags$td("Optimization + ML"),
                      tags$td("Risk parity with return forecasts")
                    ),
                    tags$tr(
                      tags$td("Feature Extraction"),
                      tags$td("Extract insights from alternative data"),
                      tags$td("NLP, Computer Vision"),
                      tags$td("Sentiment analysis from news/tweets")
                    ),
                    tags$tr(
                      tags$td("Trade Execution"),
                      tags$td("Minimize market impact"),
                      tags$td("Reinforcement Learning"),
                      tags$td("Optimal order splitting and timing")
                    ),
                    tags$tr(
                      tags$td("Risk Management"),
                      tags$td("Predict and control downside risk"),
                      tags$td("Time Series Models"),
                      tags$td("Volatility forecasting with LSTM")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📈 Evolution of Algorithmic Strategies", status = "info", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("strategy_evolution"), height = "350px")
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

chapter1_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # Strategy workflow diagram
    output$strategy_workflow <- renderPlotly({
      stages <- c("Data\nSourcing", "Feature\nEngineering", "Model\nDevelopment", 
                  "Backtesting", "Paper\nTrading", "Live\nExecution")
      stage_num <- 1:6
      
      p <- plot_ly(
        x = stage_num,
        y = rep(1, 6),
        text = stages,
        mode = "markers+text",
        marker = list(
          size = 60,
          color = c("#008A82", "#00A39A", "#FF6B35", "#F7931E", "#20B2AA", "#7B68EE"),
          line = list(color = "white", width = 2)
        ),
        textposition = "middle center",
        textfont = list(color = "white", size = 11, family = "Inter"),
        hoverinfo = "text",
        hovertext = c(
          "Acquire market, fundamental, and alternative data",
          "Transform raw data into predictive features",
          "Train and validate ML models",
          "Test strategy on historical data",
          "Validate in simulated environment",
          "Deploy strategy with real capital"
        )
      ) %>%
        add_trace(
          x = stage_num,
          y = rep(1, 6),
          mode = "lines",
          line = list(color = "#008A82", width = 3),
          showlegend = FALSE,
          hoverinfo = "none"
        ) %>%
        layout(
          title = list(text = "ML Trading Strategy Development Workflow", font = list(color = "#E6EDF3")),
          xaxis = list(
            title = "",
            showgrid = FALSE,
            showticklabels = FALSE,
            zeroline = FALSE,
            range = c(0.5, 6.5)
          ),
          yaxis = list(
            title = "",
            showgrid = FALSE,
            showticklabels = FALSE,
            zeroline = FALSE,
            range = c(0.5, 1.5)
          ),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          margin = list(t = 60, b = 40),
          showlegend = FALSE
        )
      
      p
    })
    
    # Strategy evolution timeline
    output$strategy_evolution <- renderPlotly({
      timeline_data <- data.frame(
        Period = c("1970s-1980s", "1990s", "2000s", "2010s", "2020s"),
        Strategy = c("Program Trading", "Statistical Arbitrage", 
                     "High-Frequency Trading", "Machine Learning", 
                     "Deep Learning + Alt Data"),
        Complexity = c(2, 4, 6, 8, 10),
        Color = c("#6E7681", "#8B949E", "#00A39A", "#008A82", "#FF6B35")
      )
      
      p <- plot_ly(
        data = timeline_data,
        x = ~Period,
        y = ~Complexity,
        type = "scatter",
        mode = "markers+lines",
        marker = list(
          size = 20,
          color = ~Color,
          line = list(color = "white", width = 2)
        ),
        line = list(color = "#008A82", width = 3),
        text = ~Strategy,
        hovertemplate = paste(
          "<b>%{x}</b><br>",
          "Strategy: %{text}<br>",
          "Complexity: %{y}/10<br>",
          "<extra></extra>"
        )
      ) %>%
        add_text(
          x = ~Period,
          y = ~Complexity + 0.5,
          text = ~Strategy,
          textposition = "top",
          textfont = list(size = 10, color = "#E6EDF3"),
          showlegend = FALSE,
          hoverinfo = "none"
        ) %>%
        layout(
          title = list(text = "Evolution of Algorithmic Trading Strategies", font = list(color = "#E6EDF3")),
          xaxis = list(
            title = "Time Period",
            color = "#8B949E",
            gridcolor = "#30363D"
          ),
          yaxis = list(
            title = "Complexity & Sophistication",
            color = "#8B949E",
            gridcolor = "#30363D",
            range = c(0, 12)
          ),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
      
      p
    })
    
  })
}
