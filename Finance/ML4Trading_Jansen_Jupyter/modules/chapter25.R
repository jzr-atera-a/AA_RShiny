# modules/chapter25.R — End-to-End Workflow: From Research to Production

chapter25_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(25, "🚀", "Complete ML Trading Workflow",
      "Production ML Systems - End-to-end pipeline from research to deployment, monitoring, and continuous improvement.",
      c("Production", "MLOps", "Pipeline", "Deployment", "Monitoring", "Backtesting")),

    stats_row(
      list("Research", "Hypothesis"),
      list("Backtest", "Validate"), 
      list("Deploy", "Production"),
      list("Monitor", "Maintain")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),
        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🚀 End-to-End ML Trading Pipeline", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Complete Workflow",
                  tagList(
                    tags$ol(
                      tags$li(tags$strong("Research & Hypothesis:"), " Develop trading idea, literature review"),
                      tags$li(tags$strong("Data Collection:"), " Gather historical data, alternative data sources"),
                      tags$li(tags$strong("Feature Engineering:"), " Create predictive features, transformations"),
                      tags$li(tags$strong("Model Development:"), " Train multiple models, hyperparameter tuning"),
                      tags$li(tags$strong("Backtesting:"), " Walk-forward validation, transaction costs"),
                      tags$li(tags$strong("Risk Analysis:"), " Drawdown, volatility, correlation with portfolio"),
                      tags$li(tags$strong("Paper Trading:"), " Live simulation without real money"),
                      tags$li(tags$strong("Production Deployment:"), " Real-time data pipeline, execution"),
                      tags$li(tags$strong("Monitoring:"), " Performance tracking, drift detection"),
                      tags$li(tags$strong("Continuous Improvement:"), " Retrain, A/B testing, iteration")
                    )
                  )
                ),
                plotlyOutput(ns("pipeline_flow"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "🔍 Research Phase", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Hypothesis Development",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Literature Review:"), " Academic papers, factor research"),
                      tags$li(tags$strong("Idea Generation:"), " Market inefficiencies, behavioral biases"),
                      tags$li(tags$strong("Preliminary Analysis:"), " Exploratory data analysis"),
                      tags$li(tags$strong("Alpha Hypothesis:"), " Clear, testable prediction"),
                      tags$li(tags$strong("Success Criteria:"), " Sharpe > 1, low correlation with existing strategies")
                    )
                  )
                )
            ),
            
            box(title = "📊 Backtesting Best Practices", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Avoiding Pitfalls",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Walk-Forward:"), " Expanding/rolling window, never look ahead"),
                      tags$li(tags$strong("Transaction Costs:"), " Realistic slippage, commissions, bid-ask"),
                      tags$li(tags$strong("Market Impact:"), " Account for your order size"),
                      tags$li(tags$strong("Survivorship Bias:"), " Include delisted stocks"),
                      tags$li(tags$strong("Overfitting:"), " Cross-validation, hold-out test set"),
                      tags$li(tags$strong("Data Snooping:"), " Multiple hypothesis correction")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🏗️ Production Considerations", status = "info", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Component"), 
                    tags$th("Requirement"), 
                    tags$th("Challenges"),
                    tags$th("Solutions")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Data Pipeline")),
                      tags$td("Real-time, reliable"),
                      tags$td("Missing data, API failures"),
                      tags$td("Redundant sources, caching, monitoring")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Model Serving")),
                      tags$td("Low latency (<100ms)"),
                      tags$td("Scale, GPU allocation"),
                      tags$td("Model optimization, batching, containers")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Execution")),
                      tags$td("Reliable order routing"),
                      tags$td("Failures, partial fills"),
                      tags$td("Smart order router, retry logic")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Risk Management")),
                      tags$td("Real-time limits"),
                      tags$td("Runaway models, fat fingers"),
                      tags$td("Pre-trade checks, kill switches")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Monitoring")),
                      tags$td("24/7 alerting"),
                      tags$td("Drift, performance degradation"),
                      tags$td("Dashboards, anomaly detection, PagerDuty")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📈 Monitoring & Drift Detection", status = "success", solidHeader = TRUE, width = 12,
                framework_card("What to Monitor",
                  tagList(
                    tags$h5("Performance Metrics:"),
                    tags$ul(
                      tags$li("Sharpe ratio, max drawdown, win rate (rolling windows)"),
                      tags$li("Slippage vs backtest assumptions"),
                      tags$li("Comparison to baseline/benchmark")
                    ),
                    tags$h5("Data Quality:"),
                    tags$ul(
                      tags$li("Missing features, outliers, distribution shifts"),
                      tags$li("Correlation stability, feature importance changes")
                    ),
                    tags$h5("Model Health:"),
                    tags$ul(
                      tags$li("Prediction distribution vs training"),
                      tags$li("Calibration (predicted probabilities vs actual)"),
                      tags$li("Feature drift (KL divergence, Kolmogorov-Smirnov test)")
                    )
                  )
                ),
                plotlyOutput(ns("monitoring_dashboard"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "🔄 Continuous Improvement", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Iteration Cycle",
                  tagList(
                    tags$ol(
                      tags$li(tags$strong("Monitor:"), " Track live performance vs expectations"),
                      tags$li(tags$strong("Analyze:"), " Identify failures, edge cases"),
                      tags$li(tags$strong("Hypothesize:"), " What can improve the model?"),
                      tags$li(tags$strong("Experiment:"), " A/B test changes (10-20% allocation)"),
                      tags$li(tags$strong("Validate:"), " Statistical significance test"),
                      tags$li(tags$strong("Deploy:"), " Gradual rollout if successful"),
                      tags$li(tags$strong("Repeat:"), " Continuous learning loop")
                    )
                  )
                )
            ),
            
            box(title = "⚙️ Retraining Strategy", status = "info", solidHeader = TRUE, width = 6,
                framework_card("When and How",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Scheduled:"), " Weekly/monthly with new data"),
                      tags$li(tags$strong("Triggered:"), " Performance degradation alert"),
                      tags$li(tags$strong("Incremental:"), " Online learning for some models"),
                      tags$li(tags$strong("Full Retrain:"), " Periodically rebuild from scratch"),
                      tags$li(tags$strong("Validation:"), " Shadow mode before replacing live model"),
                      tags$li(tags$strong("Rollback:"), " Keep previous version for quick revert")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "✅ Production Checklist", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Before Going Live",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("✓ Backtesting:"), " Walk-forward, realistic costs, multiple market regimes"),
                      tags$li(tags$strong("✓ Paper Trading:"), " Live data, no real money, at least 1-3 months"),
                      tags$li(tags$strong("✓ Risk Controls:"), " Position limits, stop-loss, daily loss limits"),
                      tags$li(tags$strong("✓ Monitoring:"), " Dashboards, alerts, logging infrastructure"),
                      tags$li(tags$strong("✓ Disaster Recovery:"), " Kill switch, rollback procedure, backup systems"),
                      tags$li(tags$strong("✓ Documentation:"), " Model card, runbook, code documentation"),
                      tags$li(tags$strong("✓ Compliance:"), " Regulatory review, audit trail"),
                      tags$li(tags$strong("✓ Team Readiness:"), " On-call rotation, escalation procedures")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🎯 Key Takeaways", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Lessons for ML Trading",
                  tagList(
                    tags$ol(
                      tags$li(tags$strong("Start Simple:"), " Begin with interpretable models before deep learning"),
                      tags$li(tags$strong("Domain Knowledge:"), " Finance expertise matters as much as ML skills"),
                      tags$li(tags$strong("Robustness > Accuracy:"), " Prefer stable returns over peak performance"),
                      tags$li(tags$strong("Risk First:"), " Build risk management before optimization"),
                      tags$li(tags$strong("Test Rigorously:"), " Markets punish overfitting harshly"),
                      tags$li(tags$strong("Monitor Everything:"), " Production is where models meet reality"),
                      tags$li(tags$strong("Iterate Continuously:"), " Markets evolve, your models must too"),
                      tags$li(tags$strong("Stay Humble:"), " Most strategies eventually decay")
                    )
                  )
                )
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

chapter25_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$pipeline_flow <- renderPlotly({
      stages <- c("Research", "Data", "Features", "Models", "Backtest", "Risk", "Paper", "Deploy", "Monitor", "Improve")
      x <- 1:10
      y <- rep(1, 10)
      
      plot_ly(x = x, y = y, text = stages, mode = "markers+text",
              marker = list(size = 45, color = generate_palette(10), line = list(color = "white", width = 2)),
              textposition = "middle center", textfont = list(size = 8, color = "white"),
              hoverinfo = "none") %>%
        add_trace(x = x, y = y, mode = "lines", 
                  line = list(color = ml_colors$primary, width = 2),
                  showlegend = FALSE, hoverinfo = "none") %>%
        layout(
          title = list(text = "ML Trading Pipeline: Research to Production", font = list(color = "#E6EDF3")),
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3")
        )
    })
    
    output$monitoring_dashboard <- renderPlotly({
      dates <- seq(as.Date("2023-01-01"), as.Date("2023-12-31"), by = "day")
      sharpe_rolling <- 1.5 + 0.5 * sin(seq(0, 4*pi, length.out = length(dates))) + rnorm(length(dates), 0, 0.2)
      threshold <- 1.0
      
      plot_ly() %>%
        add_trace(x = dates, y = sharpe_rolling, name = "Rolling 30d Sharpe", 
                  type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2)) %>%
        add_trace(x = dates, y = rep(threshold, length(dates)), name = "Alert Threshold", 
                  type = "scatter", mode = "lines",
                  line = list(color = ml_colors$danger, width = 2, dash = "dash")) %>%
        layout(
          title = list(text = "Live Strategy Performance Monitoring", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "Sharpe Ratio (30d)", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
  })
}
