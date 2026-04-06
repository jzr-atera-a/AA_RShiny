# modules/chapter07.R — Linear Models: From Risk Factors to Return Forecasts

chapter7_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(7, "📐", "Linear Models",
      "From Risk Factors to Return Forecasts - Using regression for alpha factor discovery, risk modeling, and return prediction with regularization techniques.",
      c("OLS", "Ridge", "Lasso", "CAPM", "Fama-French", "statsmodels")),

    stats_row(
      list("OLS", "Baseline Method"),
      list("3+", "Factor Models"), 
      list("L1/L2", "Regularization"),
      list("IC", "Evaluation Metric")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "📊 Linear Regression Fundamentals", status = "info", solidHeader = TRUE, width = 6,
                framework_card("The Model",
                  tagList(
                    tags$p(tags$strong("y = β₀ + β₁x₁ + β₂x₂ + ... + βₚxₚ + ε")),
                    tags$ul(
                      tags$li(tags$strong("y:"), " Target (returns)"),
                      tags$li(tags$strong("x:"), " Features (factors)"),
                      tags$li(tags$strong("β:"), " Coefficients (factor loadings)"),
                      tags$li(tags$strong("ε:"), " Error term")
                    )
                  )
                ),
                framework_card("Training Methods",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("OLS:"), " Minimize sum of squared residuals. Closed-form solution: β = (X'X)⁻¹X'y"),
                      tags$li(tags$strong("MLE:"), " Maximize likelihood under normality assumption"),
                      tags$li(tags$strong("Gradient Descent:"), " Iterative optimization for large datasets")
                    )
                  )
                ),
                tip_box("Gauss-Markov Theorem", "Under assumptions (linearity, independence, homoskedasticity), OLS is BLUE: Best Linear Unbiased Estimator")
            ),
            
            box(title = "🔍 Diagnostic Checks", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Common Problems",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Heteroskedasticity:"), " Non-constant variance → use robust std errors or WLS"),
                      tags$li(tags$strong("Serial Correlation:"), " Correlated errors → use Newey-West, add lags"),
                      tags$li(tags$strong("Multicollinearity:"), " Correlated predictors → VIF test, remove/combine features"),
                      tags$li(tags$strong("Outliers:"), " Extreme values → winsorize, use robust regression")
                    )
                  )
                ),
                framework_card("Goodness of Fit",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("R²:"), " Proportion of variance explained (0-1)"),
                      tags$li(tags$strong("Adjusted R²:"), " Penalizes adding uninformative features"),
                      tags$li(tags$strong("AIC/BIC:"), " Information criteria for model selection"),
                      tags$li(tags$strong("F-statistic:"), " Overall model significance")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📈 Factor Models for Asset Pricing", status = "success", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Model"), 
                    tags$th("Factors"), 
                    tags$th("Formula"),
                    tags$th("Use Case")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("CAPM")),
                      tags$td("Market"),
                      tags$td("Rᵢ - Rƒ = α + β(Rₘ - Rƒ)"),
                      tags$td("Baseline risk-return relationship")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Fama-French 3-Factor")),
                      tags$td("Market, Size, Value"),
                      tags$td("Add SMB (small minus big), HML (high minus low)"),
                      tags$td("Explain size and value premiums")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Fama-French 5-Factor")),
                      tags$td("+ Profitability, Investment"),
                      tags$td("Add RMW (robust minus weak), CMA (conservative minus aggressive)"),
                      tags$td("More comprehensive factor exposure")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Carhart 4-Factor")),
                      tags$td("FF3 + Momentum"),
                      tags$td("Add UMD (up minus down)"),
                      tags$td("Include momentum effect")
                    )
                  )
                ),
                plotlyOutput(ns("factor_model_comparison"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "🛡️ Regularization: Preventing Overfitting", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Ridge Regression (L2)",
                  tagList(
                    tags$p(tags$strong("Minimize: RSS + λΣβ²")),
                    tags$ul(
                      tags$li("Shrinks coefficients toward zero"),
                      tags$li("Keeps all features (no feature selection)"),
                      tags$li("λ controls strength (higher = more shrinkage)"),
                      tags$li("Good when many correlated features")
                    )
                  )
                ),
                framework_card("Lasso Regression (L1)",
                  tagList(
                    tags$p(tags$strong("Minimize: RSS + λΣ|β|")),
                    tags$ul(
                      tags$li("Shrinks coefficients, some to exactly zero"),
                      tags$li("Performs feature selection automatically"),
                      tags$li("Produces sparse models"),
                      tags$li("Good for high-dimensional data")
                    )
                  )
                ),
                tip_box("Choosing λ", "Use cross-validation to select optimal regularization strength. Plot coefficient paths to understand feature importance at different λ values.")
            ),
            
            box(title = "📊 Regularization Paths", status = "warning", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("regularization_path"), height = "350px")
            )
          ),
          
          fluidRow(
            box(title = "🎯 Return Prediction with Linear Regression", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Implementation Workflow",
                  tagList(
                    tags$ol(
                      tags$li(tags$strong("Define Universe:"), " Select tradeable stocks (liquidity, market cap filters)"),
                      tags$li(tags$strong("Compute Alpha Factors:"), " Momentum, value, quality using TA-Lib, fundamental ratios"),
                      tags$li(tags$strong("Add Lagged Returns:"), " Historical returns as features (avoid lookahead)"),
                      tags$li(tags$strong("Generate Forward Returns:"), " Target variable (1-day, 5-day, 21-day ahead)"),
                      tags$li(tags$strong("Dummy Encode Categoricals:"), " Sector, industry if using"),
                      tags$li(tags$strong("Train-Test Split:"), " Time-series split (e.g., train on 2015-2019, test on 2020)"),
                      tags$li(tags$strong("Fit Model:"), " OLS, Ridge, or Lasso"),
                      tags$li(tags$strong("Cross-Validate:"), " Time-series CV for hyperparameters"),
                      tags$li(tags$strong("Evaluate:"), " Information Coefficient, RMSE, ranking correlation"),
                      tags$li(tags$strong("Generate Signals:"), " Predicted returns → long/short positions")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📉 Linear Classification: Logistic Regression", status = "info", solidHeader = TRUE, width = 6,
                framework_card("The Logistic Function",
                  tagList(
                    tags$p(tags$strong("P(y=1|x) = 1 / (1 + e⁻⁽β₀ + β'x⁾)")),
                    tags$p("Maps linear combination to probability [0,1]. Used for binary classification: price up/down, buy/sell signals.")
                  )
                ),
                framework_card("Loss Function",
                  "Maximizes log-likelihood (equivalent to minimizing cross-entropy). No closed form; use gradient descent or Newton's method."
                )
            ),
            
            box(title = "🎲 Predicting Price Movements", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("From Regression to Classification",
                  tagList(
                    tags$p("Convert continuous return prediction to binary outcome:"),
                    tags$ul(
                      tags$li("y = 1 if next-day return > 0"),
                      tags$li("y = 0 if next-day return ≤ 0")
                    ),
                    tags$p("Or use multiple classes: Large Up, Small Up, Flat, Small Down, Large Down")
                  )
                ),
                framework_card("Evaluation Metrics",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("AUC-ROC:"), " Overall classification quality"),
                      tags$li(tags$strong("Precision/Recall:"), " Trade-off between false signals"),
                      tags$li(tags$strong("IC:"), " Rank correlation with returns"),
                      tags$li(tags$strong("Sharpe:"), " Risk-adjusted backtest performance")
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

chapter7_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$factor_model_comparison <- renderPlotly({
      models <- c("CAPM", "FF3", "Carhart 4", "FF5")
      r_squared <- c(0.65, 0.82, 0.87, 0.91)
      
      plot_ly(x = models, y = r_squared, type = "bar",
              marker = list(color = generate_palette(4), line = list(color = "white", width = 1.5)),
              text = ~paste0(round(r_squared*100, 1), "%"),
              textposition = "outside") %>%
        layout(
          title = list(text = "Factor Model R² Comparison", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Model", color = "#8B949E"),
          yaxis = list(title = "R² (Explained Variance)", color = "#8B949E", gridcolor = "#30363D", range = c(0, 1)),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
    output$regularization_path <- renderPlotly({
      lambda <- 10^seq(-3, 2, length.out = 100)
      
      # Simulate coefficient paths for 5 features
      coef1 <- 5 * exp(-lambda * 0.5)
      coef2 <- -3 * exp(-lambda * 0.8)
      coef3 <- 2 * exp(-lambda * 1.2)
      coef4 <- -1 * exp(-lambda * 1.5)
      coef5 <- 0.5 * exp(-lambda * 2.0)
      
      plot_ly() %>%
        add_trace(x = log10(lambda), y = coef1, name = "Feature 1", type = "scatter", mode = "lines",
                  line = list(width = 2, color = ml_colors$primary)) %>%
        add_trace(x = log10(lambda), y = coef2, name = "Feature 2", type = "scatter", mode = "lines",
                  line = list(width = 2, color = ml_colors$secondary)) %>%
        add_trace(x = log10(lambda), y = coef3, name = "Feature 3", type = "scatter", mode = "lines",
                  line = list(width = 2, color = ml_colors$accent1)) %>%
        add_trace(x = log10(lambda), y = coef4, name = "Feature 4", type = "scatter", mode = "lines",
                  line = list(width = 2, color = ml_colors$accent2)) %>%
        add_trace(x = log10(lambda), y = coef5, name = "Feature 5", type = "scatter", mode = "lines",
                  line = list(width = 2, color = ml_colors$accent3)) %>%
        layout(
          title = list(text = "Ridge Regularization Path", font = list(color = "#E6EDF3")),
          xaxis = list(title = "log(λ)", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Coefficient Value", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
  })
}
