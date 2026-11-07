# modules/chapter24.R — Meta-Labeling, Stacking, and Ensemble Techniques

chapter24_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(24, "🏷️", "Meta-Labeling & Stacking",
      "Advanced Ensemble Techniques - Meta-labeling for position sizing, model stacking, and combining multiple predictors for robust signals.",
      c("Meta-Labeling", "Stacking", "Ensemble", "Blending", "Two-Stage")),

    stats_row(
      list("Meta", "Secondary Model"),
      list("Stacking", "Layer Models"), 
      list("Ensemble", "Combine"),
      list("Blending", "Weighted Avg")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),
        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🏷️ Meta-Labeling Framework", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Two-Stage Approach",
                  tagList(
                    tags$p("Separate trade direction from position sizing:"),
                    tags$h5("Stage 1: Primary Model"),
                    tags$ul(
                      tags$li(tags$strong("Input:"), " Market data, features"),
                      tags$li(tags$strong("Output:"), " Trade side (long/short)"),
                      tags$li(tags$strong("Focus:"), " Predict direction"),
                      tags$li(tags$strong("Label:"), " Binary (up/down) or continuous (returns)")
                    ),
                    tags$h5("Stage 2: Meta Model"),
                    tags$ul(
                      tags$li(tags$strong("Input:"), " Primary model predictions + features"),
                      tags$li(tags$strong("Output:"), " Position size (0 to 1) or bet yes/no"),
                      tags$li(tags$strong("Focus:"), " Confidence/conviction"),
                      tags$li(tags$strong("Label:"), " Did primary model prediction profit?")
                    ),
                    tags$p(tags$strong("Key Benefit:"), " Primary focuses on direction, meta on sizing → better risk-adjusted returns")
                  )
                ),
                plotlyOutput(ns("metalabeling_flow"), height = "200px")
            )
          ),
          
          fluidRow(
            box(title = "📊 Meta-Labeling vs Traditional", status = "success", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("metalabeling_comparison"), height = "300px")
            ),
            
            box(title = "📈 Position Size Distribution", status = "warning", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("position_sizes"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "📚 Model Stacking", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Hierarchical Ensemble",
                  tagList(
                    tags$p("Combine multiple base models using meta-model:"),
                    tags$h5("Process:"),
                    tags$ol(
                      tags$li(tags$strong("Train Base Models:"), " Random Forest, XGBoost, LSTM, Linear on training data"),
                      tags$li(tags$strong("Generate Predictions:"), " Each base model predicts on validation set"),
                      tags$li(tags$strong("Meta-Features:"), " Use base predictions as features for meta-model"),
                      tags$li(tags$strong("Train Meta-Model:"), " Logistic regression, neural net learns optimal combination"),
                      tags$li(tags$strong("Final Prediction:"), " Meta-model output")
                    ),
                    tags$p(tags$strong("Advantage:"), " Often outperforms individual models and simple averaging")
                  )
                ),
                plotlyOutput(ns("stacking_architecture"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "⚖️ Ensemble Strategies", status = "warning", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Method"), 
                    tags$th("Combination"), 
                    tags$th("Complexity"),
                    tags$th("Pros"),
                    tags$th("Cons")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Simple Average")),
                      tags$td("Equal weights"),
                      tags$td("Low"),
                      tags$td("Robust, simple"),
                      tags$td("Ignores model quality")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Weighted Average")),
                      tags$td("Optimized weights"),
                      tags$td("Medium"),
                      tags$td("Uses model performance"),
                      tags$td("Can overfit weights")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Stacking")),
                      tags$td("Meta-model learns"),
                      tags$td("High"),
                      tags$td("Optimal combination, interactions"),
                      tags$td("Complex, risk of overfitting")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Blending")),
                      tags$td("Hold-out for meta"),
                      tags$td("Medium"),
                      tags$td("Simpler than stacking"),
                      tags$td("Less data for meta-model")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Cascading")),
                      tags$td("Sequential refinement"),
                      tags$td("Medium"),
                      tags$td("Progressively improves"),
                      tags$td("Error propagation")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🎯 Ensemble Performance", status = "success", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("ensemble_performance"), height = "350px"),
                framework_card("Best Practices",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Diversity:"), " Use different model types (tree, linear, neural)"),
                      tags$li(tags$strong("Uncorrelated Errors:"), " Models should make different mistakes"),
                      tags$li(tags$strong("Cross-Validation:"), " Proper CV to avoid overfitting meta-model"),
                      tags$li(tags$strong("Simplicity:"), " Start with averaging before complex stacking"),
                      tags$li(tags$strong("Monitor:"), " Track individual model contributions over time")
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

chapter24_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$metalabeling_flow <- renderPlotly({
      stages <- c("Data", "Primary\nModel", "Direction", "Meta\nModel", "Size")
      x_pos <- 1:5
      
      plot_ly(x = x_pos, y = rep(1, 5), text = stages, mode = "markers+text",
              marker = list(size = 50, color = generate_palette(5), line = list(color = "white", width = 2)),
              textposition = "middle center", textfont = list(size = 10, color = "white"),
              hoverinfo = "none") %>%
        add_trace(x = x_pos, y = rep(1, 5), mode = "lines", 
                  line = list(color = ml_colors$primary, width = 2),
                  showlegend = FALSE, hoverinfo = "none") %>%
        layout(
          title = list(text = "Meta-Labeling Workflow", font = list(color = "#E6EDF3")),
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3")
        )
    })
    
    output$metalabeling_comparison <- renderPlotly({
      metrics <- c("Sharpe", "Win Rate", "Max DD", "Turnover")
      traditional <- c(0.8, 0.55, -0.25, 0.8)
      metalabel <- c(1.2, 0.62, -0.18, 0.65)
      
      plot_ly() %>%
        add_trace(x = metrics, y = traditional, name = "Traditional", type = "bar",
                  marker = list(color = ml_colors$secondary)) %>%
        add_trace(x = metrics, y = metalabel, name = "Meta-Labeling", type = "bar",
                  marker = list(color = ml_colors$primary)) %>%
        layout(
          title = list(text = "Meta-Labeling Performance", font = list(color = "#E6EDF3")),
          xaxis = list(title = "", color = "#8B949E"),
          yaxis = list(title = "Value (normalized)", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          barmode = "group",
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$position_sizes <- renderPlotly({
      sizes <- rnorm(1000, 0.5, 0.2)
      sizes <- pmax(0, pmin(1, sizes))
      
      plot_ly(x = sizes, type = "histogram", nbinsx = 30,
              marker = list(color = ml_colors$primary, line = list(color = "white", width = 1))) %>%
        layout(
          title = list(text = "Meta-Model Position Size Distribution", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Position Size (0-1)", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Frequency", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3")
        )
    })
    
    output$stacking_architecture <- renderPlotly({
      models <- c("Data", "RF", "XGB", "LSTM", "Linear", "Meta", "Final")
      x <- c(1, 2, 2, 2, 2, 3, 4)
      y <- c(2, 3, 2.5, 2, 1.5, 2, 2)
      
      plot_ly(x = x, y = y, text = models, mode = "markers+text",
              marker = list(size = c(40, 50, 50, 50, 50, 55, 45), 
                            color = generate_palette(7), line = list(color = "white", width = 2)),
              textposition = "middle center", textfont = list(size = 9, color = "white"),
              hoverinfo = "none") %>%
        layout(
          title = list(text = "Stacking Architecture", font = list(color = "#E6EDF3")),
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3")
        )
    })
    
    output$ensemble_performance <- renderPlotly({
      dates <- seq(as.Date("2020-01-01"), as.Date("2023-12-31"), by = "day")
      rf <- cumprod(1 + rnorm(length(dates), 0.0003, 0.014))
      xgb <- cumprod(1 + rnorm(length(dates), 0.0004, 0.013))
      lstm <- cumprod(1 + rnorm(length(dates), 0.0003, 0.015))
      ensemble <- cumprod(1 + rnorm(length(dates), 0.0005, 0.011))
      
      plot_ly() %>%
        add_trace(x = dates, y = rf, name = "Random Forest", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 1.5)) %>%
        add_trace(x = dates, y = xgb, name = "XGBoost", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent2, width = 1.5)) %>%
        add_trace(x = dates, y = lstm, name = "LSTM", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent3, width = 1.5)) %>%
        add_trace(x = dates, y = ensemble, name = "Stacked Ensemble", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 3)) %>%
        layout(
          title = list(text = "Ensemble vs Individual Models", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "Cumulative Returns", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
  })
}
