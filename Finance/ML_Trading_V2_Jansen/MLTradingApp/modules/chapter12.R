# modules/chapter12.R — Boosting Your Trading Strategy

chapter12_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(12, "🚀", "Boosting Your Trading Strategy",
      "Gradient Boosting Machines for Trading - XGBoost, LightGBM, and CatBoost for state-of-the-art predictive performance.",
      c("Gradient Boosting", "XGBoost", "LightGBM", "CatBoost", "SHAP")),

    stats_row(
      list("AdaBoost", "First Boosting"),
      list("GBM", "Sequential Learning"), 
      list("3", "Top Libraries"),
      list("SHAP", "Interpretability")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🎯 Boosting vs Bagging", status = "info", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Aspect"), 
                    tags$th("Bagging (Random Forest)"), 
                    tags$th("Boosting (GBM)")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Training")),
                      tags$td("Parallel - trees independent"),
                      tags$td("Sequential - each tree corrects previous")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Goal")),
                      tags$td("Reduce variance"),
                      tags$td("Reduce bias and variance")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Weighting")),
                      tags$td("Equal vote per tree"),
                      tags$td("Weighted by performance")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Overfitting Risk")),
                      tags$td("Lower (robust)"),
                      tags$td("Higher (needs regularization)")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Speed")),
                      tags$td("Faster (parallelizable)"),
                      tags$td("Slower (sequential)")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📊 AdaBoost Algorithm", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Adaptive Boosting",
                  tagList(
                    tags$p("First boosting algorithm (1996):"),
                    tags$ol(
                      tags$li("Train weak learner on data"),
                      tags$li("Upweight misclassified samples"),
                      tags$li("Train next learner on reweighted data"),
                      tags$li("Repeat M times"),
                      tags$li("Final: weighted vote of all learners")
                    ),
                    tags$p(tags$strong("Weakness:"), " Sensitive to noise and outliers")
                  )
                )
            ),
            
            box(title = "🔥 Gradient Boosting", status = "success", solidHeader = TRUE, width = 6,
                framework_card("The Algorithm",
                  tagList(
                    tags$p("Fit trees to residuals sequentially:"),
                    tags$ol(
                      tags$li("Initialize: F₀(x) = mean(y)"),
                      tags$li("Compute residuals: r = y - F(x)"),
                      tags$li("Fit tree h(x) to residuals"),
                      tags$li("Update: F(x) += η·h(x)"),
                      tags$li("Repeat steps 2-4 M times")
                    ),
                    tags$p(tags$strong("η:"), " Learning rate (shrinkage)")
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "⚙️ Key Hyperparameters", status = "info", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Parameter"), 
                    tags$th("Description"), 
                    tags$th("Typical Range"),
                    tags$th("Effect")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("n_estimators")),
                      tags$td("Number of boosting rounds"),
                      tags$td("100-1000"),
                      tags$td("More trees → better fit, slower, overfitting risk")
                    ),
                    tags$tr(
                      tags$td(tags$strong("learning_rate")),
                      tags$td("Shrinkage (η)"),
                      tags$td("0.01-0.3"),
                      tags$td("Lower → more robust, needs more trees")
                    ),
                    tags$tr(
                      tags$td(tags$strong("max_depth")),
                      tags$td("Tree depth"),
                      tags$td("3-10"),
                      tags$td("Deeper → more interactions, overfitting risk")
                    ),
                    tags$tr(
                      tags$td(tags$strong("subsample")),
                      tags$td("Row sampling fraction"),
                      tags$td("0.5-1.0"),
                      tags$td("< 1.0 = stochastic GBM, reduces overfitting")
                    ),
                    tags$tr(
                      tags$td(tags$strong("colsample_bytree")),
                      tags$td("Column sampling per tree"),
                      tags$td("0.5-1.0"),
                      tags$td("Similar to Random Forest feature randomization")
                    ),
                    tags$tr(
                      tags$td(tags$strong("min_child_weight")),
                      tags$td("Minimum sum of weights in leaf"),
                      tags$td("1-10"),
                      tags$td("Higher → more conservative, less overfitting")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🏆 Modern GBM Libraries", status = "success", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Library"), 
                    tags$th("Key Innovation"), 
                    tags$th("Strengths"),
                    tags$th("Best For")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("XGBoost")),
                      tags$td("2nd-order approximation, parallel trees"),
                      tags$td("Fast, regularization, handles missing data"),
                      tags$td("General purpose, Kaggle competitions")
                    ),
                    tags$tr(
                      tags$td(tags$strong("LightGBM")),
                      tags$td("Leaf-wise growth, histogram binning"),
                      tags$td("Very fast, low memory, large datasets"),
                      tags$td("High-dimensional data, speed critical")
                    ),
                    tags$tr(
                      tags$td(tags$strong("CatBoost")),
                      tags$td("Ordered boosting, native categorical support"),
                      tags$td("Best default params, robust to overfitting"),
                      tags$td("Categorical features, quick baseline")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🔍 Model Interpretability", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Feature Importance",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Gain:"), " Total reduction in loss from splits"),
                      tags$li(tags$strong("Coverage:"), " Fraction of samples using feature"),
                      tags$li(tags$strong("Frequency:"), " Number of times feature used")
                    )
                  )
                ),
                framework_card("Partial Dependence Plots",
                  "Show marginal effect of feature on predictions. PDPs reveal feature-target relationships after accounting for other features."
                ),
                plotlyOutput(ns("feature_importance"), height = "200px")
            ),
            
            box(title = "🎯 SHAP Values", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("SHapley Additive exPlanations",
                  tagList(
                    tags$p("Game theory approach to explain predictions:"),
                    tags$ul(
                      tags$li("Fair allocation of prediction to features"),
                      tags$li("Local (per-prediction) explanations"),
                      tags$li("Global feature importance via aggregation"),
                      tags$li("Interaction detection"),
                      tags$li("Consistent and theoretically grounded")
                    ),
                    tags$p(tags$strong("Output:"), " How much each feature contributed to this prediction")
                  )
                ),
                plotlyOutput(ns("shap_example"), height = "200px")
            )
          ),
          
          fluidRow(
            box(title = "📈 Long-Short Strategy with Boosting", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Implementation",
                  tagList(
                    tags$ol(
                      tags$li(tags$strong("Features:"), " 50+ alpha factors (technical, fundamental, alternative)"),
                      tags$li(tags$strong("Target:"), " 5-day forward returns"),
                      tags$li(tags$strong("Model:"), " LightGBM (1000 trees, depth=5, lr=0.05)"),
                      tags$li(tags$strong("CV:"), " Walk-forward with purged K-fold"),
                      tags$li(tags$strong("Optimization:"), " Bayesian hyperparameter search"),
                      tags$li(tags$strong("Signals:"), " Rank predicted returns, long top decile, short bottom decile"),
                      tags$li(tags$strong("Risk Mgmt:"), " Max position 2%, sector neutrality"),
                      tags$li(tags$strong("Execution:"), " Backtest with Zipline, analyze with pyfolio")
                    )
                  )
                ),
                plotlyOutput(ns("backtest_results"), height = "300px")
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

chapter12_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$feature_importance <- renderPlotly({
      features <- c("Momentum_3m", "Value_PE", "Quality_ROE", "Vol_30d", "RSI")
      importance <- c(850, 720, 650, 540, 480)
      
      plot_ly(x = importance, y = reorder(features, importance), type = "bar", orientation = "h",
              marker = list(color = ml_colors$primary, line = list(color = "white", width = 1))) %>%
        layout(
          title = list(text = "XGBoost Feature Importance (Gain)", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Importance", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "", color = "#8B949E"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          margin = list(l = 120)
        )
    })
    
    output$shap_example <- renderPlotly({
      features <- c("Momentum", "Value", "Quality", "Volatility", "Size")
      shap_values <- c(0.03, -0.01, 0.02, -0.015, 0.005)
      
      plot_ly(x = shap_values, y = reorder(features, abs(shap_values)), type = "bar", orientation = "h",
              marker = list(color = ifelse(shap_values > 0, ml_colors$success, ml_colors$danger),
                            line = list(color = "white", width = 1))) %>%
        layout(
          title = list(text = "SHAP Values for Single Prediction", font = list(color = "#E6EDF3")),
          xaxis = list(title = "SHAP Value (Impact on Prediction)", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "", color = "#8B949E"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          margin = list(l = 100)
        )
    })
    
    output$backtest_results <- renderPlotly({
      dates <- seq(as.Date("2018-01-01"), as.Date("2023-12-31"), by = "day")
      strategy_returns <- cumprod(1 + rnorm(length(dates), 0.0005, 0.012))
      benchmark_returns <- cumprod(1 + rnorm(length(dates), 0.0003, 0.010))
      
      plot_ly() %>%
        add_trace(x = dates, y = strategy_returns, name = "GBM Strategy", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2)) %>%
        add_trace(x = dates, y = benchmark_returns, name = "Benchmark", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 2)) %>%
        layout(
          title = list(text = "Long-Short Strategy: Boosting vs Benchmark", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "Cumulative Returns", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
  })
}
