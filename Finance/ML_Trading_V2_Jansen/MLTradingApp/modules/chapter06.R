# modules/chapter06.R — The Machine Learning Process

chapter6_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(6, "🤖", "The Machine Learning Process",
      "Understanding how machine learning works from data to predictions, including supervised, unsupervised, and reinforcement learning paradigms.",
      c("Supervised", "Unsupervised", "Cross-Validation", "Bias-Variance", "scikit-learn")),

    stats_row(
      list("3", "Learning Paradigms"),
      list("7", "Workflow Steps"), 
      list("K-Fold", "CV Method"),
      list("GridSearch", "Tuning")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🎓 Machine Learning Paradigms", status = "info", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Type"), 
                    tags$th("Goal"), 
                    tags$th("Training Data"),
                    tags$th("Trading Use Cases")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Supervised Learning")),
                      tags$td("Learn input → output mapping"),
                      tags$td("Labeled examples (X, y)"),
                      tags$td("Return prediction, price direction, credit risk")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Unsupervised Learning")),
                      tags$td("Find patterns in data"),
                      tags$td("Unlabeled data (X only)"),
                      tags$td("Clustering stocks, dimensionality reduction, anomaly detection")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Reinforcement Learning")),
                      tags$td("Learn optimal actions via rewards"),
                      tags$td("Environment interactions"),
                      tags$td("Order execution, portfolio management, market making")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🔄 The ML Workflow", status = "warning", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("ml_workflow"), height = "350px")
            )
          ),
          
          fluidRow(
            box(title = "🎯 Framing the Problem", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Prediction vs Inference",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Prediction:"), " Focus on accuracy. Care about out-of-sample performance, not interpretability. Use ensemble methods, neural networks."),
                      tags$li(tags$strong("Inference:"), " Focus on understanding relationships. Want interpretable coefficients, statistical significance. Use linear models, GLMs.")
                    ),
                    tags$p("Trading typically prioritizes prediction — we care about accuracy, not why the model works.")
                  )
                ),
                framework_card("Regression Metrics",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("MSE:"), " Mean Squared Error - penalizes large errors heavily"),
                      tags$li(tags$strong("RMSE:"), " Root MSE - same units as target"),
                      tags$li(tags$strong("MAE:"), " Mean Absolute Error - robust to outliers"),
                      tags$li(tags$strong("R²:"), " Explained variance (1 = perfect)")
                    )
                  )
                )
            ),
            
            box(title = "📊 Classification Metrics", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Confusion Matrix",
                  tagList(
                    tags$table(class = "algo-table",
                      tags$thead(tags$tr(tags$th(""), tags$th("Predicted +"), tags$th("Predicted -"))),
                      tags$tbody(
                        tags$tr(tags$td(tags$strong("Actual +")), tags$td("TP"), tags$td("FN")),
                        tags$tr(tags$td(tags$strong("Actual -")), tags$td("FP"), tags$td("TN"))
                      )
                    )
                  )
                ),
                framework_card("Key Metrics",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Accuracy:"), " (TP+TN) / Total"),
                      tags$li(tags$strong("Precision:"), " TP / (TP+FP) - of predicted positives, how many correct"),
                      tags$li(tags$strong("Recall:"), " TP / (TP+FN) - of actual positives, how many found"),
                      tags$li(tags$strong("F1-Score:"), " Harmonic mean of precision and recall"),
                      tags$li(tags$strong("AUC-ROC:"), " Area under curve - overall classification quality")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "⚖️ The Bias-Variance Trade-off", status = "warning", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("bias_variance"), height = "350px"),
                div(style = "margin-top: 15px;",
                  framework_card("Understanding the Trade-off",
                    tagList(
                      tags$ul(
                        tags$li(tags$strong("Bias:"), " Error from overly simple model (underfitting). High bias → model too rigid, misses patterns."),
                        tags$li(tags$strong("Variance:"), " Error from overly complex model (overfitting). High variance → model fits noise, poor generalization."),
                        tags$li(tags$strong("Sweet Spot:"), " Balance between capturing true patterns and avoiding noise fitting.")
                      )
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "✂️ Cross-Validation Methods", status = "info", solidHeader = TRUE, width = 6,
                framework_card("K-Fold CV",
                  tagList(
                    tags$p("Split data into K equal folds. Train on K-1, validate on remaining fold. Repeat K times, average results."),
                    tags$ul(
                      tags$li(tags$strong("K=5:"), " Common default, good balance"),
                      tags$li(tags$strong("K=10:"), " More folds, less bias but higher variance"),
                      tags$li(tags$strong("K=N (LOOCV):"), " Maximum data usage, computationally expensive")
                    )
                  )
                ),
                framework_card("Time Series CV",
                  tagList(
                    tags$p("Standard K-Fold violates temporal order! Use forward-chaining instead:"),
                    tags$ul(
                      tags$li("Train: periods 1-10, Test: period 11"),
                      tags$li("Train: periods 1-11, Test: period 12"),
                      tags$li("Train: periods 1-12, Test: period 13")
                    ),
                    tags$p("Preserves temporal causality and avoids lookahead bias.")
                  )
                ),
                tip_box("Financial Data", "Use purged/embargoed CV to handle overlapping labels and prevent information leakage in financial time series.")
            ),
            
            box(title = "🎛️ Hyperparameter Tuning", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Grid Search",
                  "Exhaustively search predefined parameter grid. E.g., for Random Forest: n_estimators ∈ {100, 200, 500}, max_depth ∈ {10, 20, 30}. Tests all 9 combinations."
                ),
                framework_card("Random Search",
                  "Sample random parameter combinations. Often finds good solutions faster than grid search. Useful when parameter space is large or continuous."
                ),
                framework_card("scikit-learn GridSearchCV",
                  tagList(
                    tags$p("Combines CV with parameter search:"),
                    tags$ul(
                      tags$li("Tries all parameter combinations"),
                      tags$li("Uses cross-validation for each"),
                      tags$li("Selects best based on chosen metric"),
                      tags$li("Refits on full data with best params")
                    )
                  )
                ),
                plotlyOutput(ns("validation_curve"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "📚 Feature Engineering & Selection", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Feature Engineering Techniques",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Transformations:"), " Log, sqrt, Box-Cox for skewed distributions"),
                      tags$li(tags$strong("Interactions:"), " Product/ratio of features (P/E ratio, momentum × volatility)"),
                      tags$li(tags$strong("Polynomial Features:"), " x², x³ to capture non-linear relationships"),
                      tags$li(tags$strong("Binning:"), " Discretize continuous features into buckets"),
                      tags$li(tags$strong("Encoding:"), " One-hot, target encoding for categorical variables"),
                      tags$li(tags$strong("Time Features:"), " Day of week, month, quarter for seasonality")
                    )
                  )
                ),
                framework_card("Information Theory for Feature Selection",
                  tagList(
                    tags$p(tags$strong("Mutual Information:"), " Measures dependency between feature and target. Higher = more informative."),
                    tags$p(tags$strong("Entropy:"), " Uncertainty in target. Features that reduce entropy are valuable."),
                    tags$p("Use sklearn.feature_selection.mutual_info_regression/classification to rank features.")
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

chapter6_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$ml_workflow <- renderPlotly({
      steps <- c("1. Frame\nProblem", "2. Collect\nData", "3. Engineer\nFeatures", 
                 "4. Select\nAlgorithm", "5. Train\nModel", "6. Evaluate\nPerformance", "7. Deploy &\nMonitor")
      x_pos <- 1:7
      y_pos <- rep(1, 7)
      
      plot_ly(x = x_pos, y = y_pos, text = steps, mode = "markers+text",
              marker = list(size = 50, color = generate_palette(7), line = list(color = "white", width = 2)),
              textposition = "middle center", textfont = list(size = 10, color = "white"),
              hoverinfo = "none") %>%
        add_trace(x = x_pos, y = y_pos, mode = "lines", line = list(color = ml_colors$primary, width = 3),
                  showlegend = FALSE, hoverinfo = "none") %>%
        layout(
          title = list(text = "Machine Learning Workflow", font = list(color = "#E6EDF3")),
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE, range = c(0.5, 7.5)),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE, range = c(0.5, 1.5)),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          showlegend = FALSE
        )
    })
    
    output$bias_variance <- renderPlotly({
      complexity <- seq(1, 10, length.out = 50)
      bias <- 10 / complexity
      variance <- complexity * 0.3
      total_error <- bias + variance
      
      data <- data.frame(Complexity = complexity, Bias = bias, Variance = variance, Total = total_error)
      
      plot_ly(data) %>%
        add_trace(x = ~Complexity, y = ~Bias, name = "Bias (Underfitting)", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 3)) %>%
        add_trace(x = ~Complexity, y = ~Variance, name = "Variance (Overfitting)", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent2, width = 3)) %>%
        add_trace(x = ~Complexity, y = ~Total, name = "Total Error", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 3, dash = "dash")) %>%
        layout(
          title = list(text = "Bias-Variance Trade-off", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Model Complexity", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Error", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$validation_curve <- renderPlotly({
      param_values <- c(1, 2, 5, 10, 20, 50, 100)
      train_score <- c(0.6, 0.72, 0.85, 0.92, 0.97, 0.99, 1.0)
      val_score <- c(0.58, 0.70, 0.82, 0.87, 0.86, 0.80, 0.75)
      
      plot_ly() %>%
        add_trace(x = param_values, y = train_score, name = "Training Score", type = "scatter", mode = "lines+markers",
                  line = list(color = ml_colors$success, width = 2), marker = list(size = 8)) %>%
        add_trace(x = param_values, y = val_score, name = "Validation Score", type = "scatter", mode = "lines+markers",
                  line = list(color = ml_colors$primary, width = 2), marker = list(size = 8)) %>%
        layout(
          title = list(text = "Validation Curve: Hyperparameter Impact", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Parameter Value", type = "log", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Score (R²)", color = "#8B949E", gridcolor = "#30363D", range = c(0.5, 1.05)),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
  })
}
