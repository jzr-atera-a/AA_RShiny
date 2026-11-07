# modules/chapter08.R — The ML4T Workflow: From Model to Strategy Backtesting

chapter8_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(8, "🔄", "ML4T Workflow",
      "From Model to Strategy Backtesting - Complete workflow for developing, testing, and deploying ML-driven trading strategies with realistic simulation.",
      c("Backtesting", "backtrader", "Zipline", "Pipeline", "Walk-Forward")),

    stats_row(
      list("3", "Data Pitfalls"),
      list("2", "Engine Types"), 
      list("Zipline", "Quantopian Framework"),
      list("Pipeline", "Factor API")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "⚠️ Backtesting Pitfalls", status = "warning", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Pitfall"), 
                    tags$th("Description"), 
                    tags$th("Impact"),
                    tags$th("Solution")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Look-Ahead Bias")),
                      tags$td("Using future information in signals"),
                      tags$td("Inflated returns, fails live"),
                      tags$td("Point-in-time data, lag features")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Survivorship Bias")),
                      tags$td("Excluding delisted/failed stocks"),
                      tags$td("+2-3% annual return bias"),
                      tags$td("Track full historical universe")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Outlier Exclusion")),
                      tags$td("Removing extreme but realistic events"),
                      tags$td("Underestimate tail risk"),
                      tags$td("Winsorize, don't exclude")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Sample Period")),
                      tags$td("Testing on non-representative period"),
                      tags$td("Overfitted to regime"),
                      tags$td("Test across market cycles")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Transaction Costs")),
                      tags$td("Ignoring slippage, commissions"),
                      tags$td("10-50% return reduction"),
                      tags$td("Model realistic costs")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Timing Mismatch")),
                      tags$td("Incorrect signal-to-trade sequencing"),
                      tags$td("Impossible execution"),
                      tags$td("Event-driven simulation")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📊 Getting the Statistics Right", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Minimum Backtest Length",
                  tagList(
                    tags$p("Sharpe ratio estimation requires sufficient independent observations:"),
                    tags$ul(
                      tags$li(tags$strong("Daily SR:"), " ~500 days (2 years) for 95% confidence"),
                      tags$li(tags$strong("Monthly SR:"), " ~60 months (5 years)"),
                      tags$li(tags$strong("Weekly SR:"), " ~100 weeks (2 years)")
                    ),
                    tags$p("Shorter periods → unreliable performance estimates")
                  )
                ),
                framework_card("Deflated Sharpe Ratio",
                  "Adjusts for multiple testing: DSR = SR × √(1 - γ·V[SR]), where γ accounts for number of trials. Prevents cherry-picking best backtest from many attempts."
                )
            ),
            
            box(title = "🏗️ Backtesting Engine Types", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Vectorized",
                  tagList(
                    tags$p(tags$strong("Pros:")),
                    tags$ul(
                      tags$li("Fast - operations on arrays"),
                      tags$li("Simple to code"),
                      tags$li("Good for research/exploration")
                    ),
                    tags$p(tags$strong("Cons:")),
                    tags$ul(
                      tags$li("Limited realism"),
                      tags$li("Hard to model complex orders"),
                      tags$li("Can't handle intraday signals")
                    )
                  )
                ),
                framework_card("Event-Driven",
                  tagList(
                    tags$p(tags$strong("Pros:")),
                    tags$ul(
                      tags$li("Realistic simulation"),
                      tags$li("Supports complex strategies"),
                      tags$li("Intraday data compatible")
                    ),
                    tags$p(tags$strong("Cons:")),
                    tags$ul(
                      tags$li("Slower execution"),
                      tags$li("More complex to implement"),
                      tags$li("Steeper learning curve")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🔧 backtrader Architecture", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Cerebro: The Brain",
                  tagList(
                    tags$p("Central component that orchestrates the backtest:"),
                    tags$ul(
                      tags$li(tags$strong("Data Feeds:"), " Load OHLCV, fundamentals, custom data"),
                      tags$li(tags$strong("Strategy:"), " Define trading logic in strategy class"),
                      tags$li(tags$strong("Broker:"), " Simulates order execution, tracks cash/positions"),
                      tags$li(tags$strong("Analyzers:"), " Calculate metrics (Sharpe, drawdown, returns)"),
                      tags$li(tags$strong("Observers:"), " Track portfolio value, trades, benchmark"),
                      tags$li(tags$strong("Commissions:"), " Model transaction costs realistically")
                    )
                  )
                ),
                plotlyOutput(ns("backtest_workflow"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "🚀 Zipline: Production-Grade Backtesting", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Key Features",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Trading Calendars:"), " NYSE, NASDAQ, LSE, TSE - handles holidays, half-days"),
                      tags$li(tags$strong("Point-in-Time Data:"), " Bundles with split/dividend adjustments"),
                      tags$li(tags$strong("Pipeline API:"), " Declarative factor computation"),
                      tags$li(tags$strong("Event-Driven:"), " Realistic simulation with proper sequencing"),
                      tags$li(tags$strong("Integration:"), " Works with Alphalens (factors) and pyfolio (performance)")
                    )
                  )
                ),
                framework_card("Algorithm API",
                  tagList(
                    tags$p("Schedule-based backtesting:"),
                    tags$ul(
                      tags$li(tags$code("initialize()"), " - Setup, schedules"),
                      tags$li(tags$code("before_trading_start()"), " - Daily pre-market prep"),
                      tags$li(tags$code("handle_data()"), " - Per-bar execution"),
                      tags$li(tags$code("order()"), " / ", tags$code("order_target()"), " - Trade placement"),
                      tags$li(tags$code("record()"), " - Custom metric tracking")
                    )
                  )
                )
            ),
            
            box(title = "🔬 Pipeline API for ML", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Declarative Factor Computation",
                  tagList(
                    tags$p("Define factors once, compute automatically each day:"),
                    tags$ol(
                      tags$li(tags$strong("Create Factors:"), " Mean, StdDev, Returns, custom ML predictions"),
                      tags$li(tags$strong("Combine Logic:"), " Filter universe, rank signals"),
                      tags$li(tags$strong("Attach Pipeline:"), " Runs before_trading_start()"),
                      tags$li(tags$strong("Access Results:"), " context.pipeline_output()"),
                      tags$li(tags$strong("Generate Orders:"), " Based on factor values")
                    )
                  )
                ),
                framework_card("Custom ML Factor",
                  tagList(
                    tags$p("Integrate trained models into Pipeline:"),
                    tags$ul(
                      tags$li("Train model offline (cross-validation)"),
                      tags$li("Save model (pickle, joblib)"),
                      tags$li("Load in custom Factor class"),
                      tags$li("Compute predictions in compute() method"),
                      tags$li("Pipeline handles scheduling/universe")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📈 Walk-Forward Testing", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Out-of-Sample Validation",
                  tagList(
                    tags$p("Avoid overfitting by splitting time series:"),
                    tags$ol(
                      tags$li(tags$strong("Train:"), " 2015-2017 → optimize hyperparameters"),
                      tags$li(tags$strong("Validate:"), " 2018 → select best model"),
                      tags$li(tags$strong("Test:"), " 2019-2020 → final performance (never touched during development)")
                    ),
                    tags$p(tags$strong("Walk-Forward:"), " Retrain periodically (quarterly/annually) on expanding or rolling window to adapt to regime changes.")
                  )
                ),
                plotlyOutput(ns("walkforward"), height = "300px")
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Python Code"),
          python_code_tab()
        )
      )
    )
  )
}

chapter8_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$backtest_workflow <- renderPlotly({
      steps <- c("Data\nFeed", "Strategy\nLogic", "Broker\nSim", "Analyzers", "Results")
      x_pos <- 1:5
      
      plot_ly(x = x_pos, y = rep(1, 5), text = steps, mode = "markers+text",
              marker = list(size = 45, color = generate_palette(5), line = list(color = "white", width = 2)),
              textposition = "middle center", textfont = list(size = 11, color = "white"),
              hoverinfo = "none") %>%
        add_trace(x = x_pos, y = rep(1, 5), mode = "lines", 
                  line = list(color = ml_colors$primary, width = 3),
                  showlegend = FALSE, hoverinfo = "none") %>%
        layout(
          title = list(text = "backtrader Cerebro Workflow", font = list(color = "#E6EDF3")),
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE, range = c(0.5, 5.5)),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE, range = c(0.5, 1.5)),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          showlegend = FALSE
        )
    })
    
    output$walkforward <- renderPlotly({
      periods <- data.frame(
        Period = c("Train 1", "Valid 1", "Test 1", "Train 2", "Valid 2", "Test 2"),
        Start = as.Date(c("2015-01-01", "2018-01-01", "2019-01-01", "2016-01-01", "2019-01-01", "2020-01-01")),
        End = as.Date(c("2017-12-31", "2018-12-31", "2019-12-31", "2018-12-31", "2019-12-31", "2020-12-31")),
        Type = c("Train", "Validate", "Test", "Train", "Validate", "Test"),
        y = c(3, 2, 1, 3, 2, 1)
      )
      
      colors_map <- c("Train" = ml_colors$primary, "Validate" = ml_colors$accent2, "Test" = ml_colors$success)
      
      plot_ly(periods, x = ~Start, y = ~y, xend = ~End, yend = ~y, color = ~Type, colors = colors_map,
              type = "scatter", mode = "lines", line = list(width = 20),
              text = ~Period, hovertemplate = "%{text}<br>%{x} to %{xend}<extra></extra>") %>%
        layout(
          title = list(text = "Walk-Forward Testing: Rolling Windows", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "", showticklabels = FALSE, color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
  })
}
