# modules/chapter11.R — Random Forests: A Long-Short Strategy for Japanese Stocks

chapter11_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(11, "🌲", "Random Forests",
      "A Long-Short Strategy for Japanese Stocks - Ensemble learning with decision trees for robust return prediction and feature discovery.",
      c("Decision Trees", "Random Forest", "Bagging", "Feature Importance", "Out-of-Bag")),

    stats_row(
      list("100+", "Trees in Forest"),
      list("Bagging", "Ensemble Method"), 
      list("OOB", "Validation"),
      list("Gini", "Split Criterion")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🌳 Decision Trees Fundamentals", status = "info", solidHeader = TRUE, width = 6,
                framework_card("How Trees Work",
                  tagList(
                    tags$p("Recursively partition feature space into regions:"),
                    tags$ol(
                      tags$li("Find best feature and split point"),
                      tags$li("Divide data into left/right branches"),
                      tags$li("Repeat until stopping criterion"),
                      tags$li("Predict: mean (regression) or mode (classification)")
                    )
                  )
                ),
                framework_card("Split Criteria",
                  tagList(
                    tags$p(tags$strong("Regression:")),
                    tags$ul(
                      tags$li("MSE reduction"),
                      tags$li("MAE reduction")
                    ),
                    tags$p(tags$strong("Classification:")),
                    tags$ul(
                      tags$li("Gini impurity"),
                      tags$li("Entropy/information gain")
                    )
                  )
                )
            ),
            
            box(title = "⚙️ Tree Hyperparameters", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Regularization",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("max_depth:"), " Maximum tree depth (3-10 typical)"),
                      tags$li(tags$strong("min_samples_split:"), " Min samples to split node"),
                      tags$li(tags$strong("min_samples_leaf:"), " Min samples in leaf"),
                      tags$li(tags$strong("max_features:"), " Features considered per split"),
                      tags$li(tags$strong("max_leaf_nodes:"), " Limit total leaves")
                    ),
                    tags$p("Deeper trees → more variance (overfitting)")
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🌲 Random Forest: Bootstrap Aggregating", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Why Ensemble Works",
                  tagList(
                    tags$p(tags$strong("Wisdom of Crowds:"), " Average many weak learners → strong learner"),
                    tags$p(tags$strong("Variance Reduction:"), " Individual trees overfit differently, averaging cancels noise"),
                    tags$p(tags$strong("Formula:"), " Var(avg) = σ²/n for independent trees")
                  )
                ),
                framework_card("Random Forest Algorithm",
                  tagList(
                    tags$p("For each of B trees:"),
                    tags$ol(
                      tags$li(tags$strong("Bootstrap:"), " Sample N observations with replacement"),
                      tags$li(tags$strong("Randomize Features:"), " At each split, consider random subset of m features"),
                      tags$li(tags$strong("Grow Tree:"), " Build deep tree (no pruning)"),
                      tags$li(tags$strong("Average:"), " Final prediction = mean/vote of all trees")
                    ),
                    tags$p(tags$strong("Typical:"), " B=100-500 trees, m=√p features (classification) or p/3 (regression)")
                  )
                ),
                plotlyOutput(ns("rf_performance"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "📊 Feature Importance", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Measuring Importance",
                  tagList(
                    tags$p(tags$strong("Gini Importance:")),
                    tags$p("Total reduction in node impurity from splits on feature, averaged over all trees"),
                    tags$p(tags$strong("Permutation Importance:")),
                    tags$p("Decrease in model accuracy when feature values are randomly shuffled. More reliable but slower.")
                  )
                ),
                plotlyOutput(ns("feature_importance"), height = "250px")
            ),
            
            box(title = "🎯 Out-of-Bag Evaluation", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Free Cross-Validation",
                  tagList(
                    tags$p("Each tree uses ~63% of data (bootstrap). Remaining 37% are out-of-bag (OOB) samples."),
                    tags$p(tags$strong("OOB Score:"), " Aggregate predictions on OOB samples → unbiased estimate of test error"),
                    tags$p(tags$strong("Advantage:"), " No need for separate validation set")
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📈 Long-Short Strategy Implementation", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Workflow",
                  tagList(
                    tags$ol(
                      tags$li(tags$strong("Universe:"), " Japanese equities (TOPIX 500)"),
                      tags$li(tags$strong("Features:"), " Lagged returns, momentum, value, quality, technical indicators"),
                      tags$li(tags$strong("Target:"), " Forward 1-month returns"),
                      tags$li(tags$strong("Model:"), " Random Forest (500 trees, max_depth=10)"),
                      tags$li(tags$strong("Signals:"), " Rank predicted returns"),
                      tags$li(tags$strong("Portfolio:"), " Long top quintile, short bottom quintile"),
                      tags$li(tags$strong("Rebalance:"), " Monthly"),
                      tags$li(tags$strong("Backtest:"), " Zipline + pyfolio")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "✅ Pros & Cons", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Strengths",
                  tagList(
                    tags$ul(
                      tags$li("Handles non-linear relationships"),
                      tags$li("Minimal preprocessing (scaling not needed)"),
                      tags$li("Robust to outliers"),
                      tags$li("Handles missing values"),
                      tags$li("Feature importance built-in"),
                      tags$li("Parallelizable (fast training)")
                    )
                  )
                )
            ),
            
            box(title = "⚠️ Limitations", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Weaknesses",
                  tagList(
                    tags$ul(
                      tags$li("Black box (less interpretable than linear models)"),
                      tags$li("Can't extrapolate beyond training range"),
                      tags$li("Large model size (memory)"),
                      tags$li("Slower prediction than linear models"),
                      tags$li("Biased toward features with many categories"),
                      tags$li("Can still overfit with very deep trees")
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

chapter11_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$rf_performance <- renderPlotly({
      n_trees <- c(1, 5, 10, 25, 50, 100, 200, 500)
      train_rmse <- c(0.45, 0.32, 0.25, 0.18, 0.15, 0.13, 0.12, 0.12)
      test_rmse <- c(0.55, 0.42, 0.38, 0.32, 0.29, 0.27, 0.27, 0.27)
      
      plot_ly() %>%
        add_trace(x = n_trees, y = train_rmse, name = "Train RMSE", type = "scatter", mode = "lines+markers",
                  line = list(color = ml_colors$success, width = 2), marker = list(size = 8)) %>%
        add_trace(x = n_trees, y = test_rmse, name = "Test RMSE", type = "scatter", mode = "lines+markers",
                  line = list(color = ml_colors$primary, width = 2), marker = list(size = 8)) %>%
        layout(
          title = list(text = "Random Forest Performance vs Number of Trees", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Number of Trees", type = "log", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "RMSE", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$feature_importance <- renderPlotly({
      features <- c("Momentum_12m", "RSI_14", "PE_Ratio", "ROE", "Volatility", "Volume_Ratio", "Market_Cap", "Beta")
      importance <- c(0.18, 0.15, 0.14, 0.12, 0.11, 0.10, 0.08, 0.12)
      
      plot_ly(x = importance, y = reorder(features, importance), type = "bar", orientation = "h",
              marker = list(color = generate_palette(8), line = list(color = "white", width = 1))) %>%
        layout(
          title = list(text = "Feature Importance", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Importance", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "", color = "#8B949E"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
  })
}
