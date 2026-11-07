# modules/chapter23.R — Interpretability and Explainability in Trading Models

chapter23_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(23, "🔍", "Model Interpretability",
      "Understanding Black Box Models - SHAP, LIME, permutation importance, and techniques for explaining ML predictions to stakeholders.",
      c("SHAP", "LIME", "Interpretability", "PDP", "ICE", "Feature Importance")),

    stats_row(
      list("SHAP", "Shapley Values"),
      list("LIME", "Local Approx"), 
      list("PDP", "Partial Dependence"),
      list("ICE", "Individual Effect")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),
        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🔍 Why Interpretability Matters", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Regulatory & Business Needs",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Regulatory Compliance:"), " Explain decisions to regulators (MiFID II, GDPR)"),
                      tags$li(tags$strong("Risk Management:"), " Understand what drives predictions, detect anomalies"),
                      tags$li(tags$strong("Model Debugging:"), " Identify failures, data quality issues"),
                      tags$li(tags$strong("Stakeholder Trust:"), " Build confidence with investors, clients"),
                      tags$li(tags$strong("Knowledge Discovery:"), " Learn new market relationships"),
                      tags$li(tags$strong("Model Validation:"), " Verify model behaves as expected")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📊 Interpretation Methods", status = "warning", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Method"), 
                    tags$th("Scope"), 
                    tags$th("Model-Agnostic?"),
                    tags$th("Output"),
                    tags$th("Pros/Cons")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Feature Importance")),
                      tags$td("Global"),
                      tags$td("Model-specific"),
                      tags$td("Ranking of features"),
                      tags$td("Fast / Model-dependent")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Permutation Importance")),
                      tags$td("Global"),
                      tags$td("Yes"),
                      tags$td("Performance drop when shuffled"),
                      tags$td("Accurate / Slow for large data")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Partial Dependence (PDP)")),
                      tags$td("Global"),
                      tags$td("Yes"),
                      tags$td("Marginal effect curve"),
                      tags$td("Intuitive / Assumes independence")
                    ),
                    tags$tr(
                      tags$td(tags$strong("ICE Plots")),
                      tags$td("Local"),
                      tags$td("Yes"),
                      tags$td("Individual predictions"),
                      tags$td("Shows heterogeneity / Many lines")
                    ),
                    tags$tr(
                      tags$td(tags$strong("SHAP")),
                      tags$td("Both"),
                      tags$td("Yes"),
                      tags$td("Contribution per feature"),
                      tags$td("Theoretically sound / Slow")
                    ),
                    tags$tr(
                      tags$td(tags$strong("LIME")),
                      tags$td("Local"),
                      tags$td("Yes"),
                      tags$td("Local linear approximation"),
                      tags$td("Fast / Unstable")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "⚡ SHAP: SHapley Additive exPlanations", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Game Theory Approach",
                  tagList(
                    tags$p("SHAP assigns each feature a contribution value based on Shapley values from cooperative game theory:"),
                    tags$ul(
                      tags$li(tags$strong("Properties:"), " Local accuracy, missingness, consistency"),
                      tags$li(tags$strong("Formula:"), " φ_i = Σ [contribution to prediction with/without feature i]"),
                      tags$li(tags$strong("Interpretation:"), " φ_i > 0 increases prediction, < 0 decreases"),
                      tags$li(tags$strong("Global:"), " Aggregate |φ_i| across samples for importance"),
                      tags$li(tags$strong("Variants:"), " TreeSHAP (fast for trees), KernelSHAP (model-agnostic)")
                    )
                  )
                ),
                plotlyOutput(ns("shap_waterfall"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "📈 Feature Importance", status = "info", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("feature_importance"), height = "300px")
            ),
            
            box(title = "📉 Partial Dependence Plot", status = "warning", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("pdp"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "🎯 LIME: Local Interpretable Model-agnostic Explanations", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Local Linear Approximation",
                  tagList(
                    tags$p("LIME explains individual predictions by fitting simple model locally:"),
                    tags$ol(
                      tags$li("Perturb input around instance to explain"),
                      tags$li("Get model predictions for perturbed samples"),
                      tags$li("Weight samples by proximity to original"),
                      tags$li("Fit simple model (linear, decision tree) on weighted samples"),
                      tags$li("Interpret simple model as explanation")
                    ),
                    tags$p(tags$strong("Advantage:"), " Works for any model, fast"),
                    tags$p(tags$strong("Limitation:"), " Unstable, sensitive to perturbation method")
                  )
                ),
                plotlyOutput(ns("lime_explanation"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "💼 Trading Use Cases", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Practical Applications",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Factor Validation:"), " Verify model uses expected factors (momentum, value)"),
                      tags$li(tags$strong("Anomaly Detection:"), " Identify predictions driven by unusual features"),
                      tags$li(tags$strong("Client Reporting:"), " Explain why portfolio was rebalanced"),
                      tags$li(tags$strong("Regulatory Audit:"), " Document decision-making process"),
                      tags$li(tags$strong("Model Debugging:"), " Find data leakage, spurious correlations"),
                      tags$li(tags$strong("Strategy Refinement:"), " Discover new alpha signals from SHAP patterns")
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

chapter23_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$shap_waterfall <- renderPlotly({
      features <- c("Base", "Momentum", "Value", "Quality", "Vol", "Size", "Prediction")
      contributions <- c(0, 0.12, -0.05, 0.08, -0.03, 0.02, NA)
      cumulative <- c(0.5, 0.62, 0.57, 0.65, 0.62, 0.64, 0.64)
      
      colors <- c("gray", ml_colors$success, ml_colors$danger, ml_colors$success, 
                  ml_colors$danger, ml_colors$success, ml_colors$primary)
      
      plot_ly() %>%
        add_trace(x = features, y = cumulative, type = "bar",
                  marker = list(color = colors, line = list(color = "white", width = 1)),
                  text = round(contributions, 3), textposition = "outside") %>%
        layout(
          title = list(text = "SHAP Waterfall: Feature Contributions to Prediction", font = list(color = "#E6EDF3")),
          xaxis = list(title = "", color = "#8B949E"),
          yaxis = list(title = "Predicted Return", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          showlegend = FALSE
        )
    })
    
    output$feature_importance <- renderPlotly({
      features <- c("Momentum_12m", "RSI", "PE_Ratio", "ROE", "Volatility_30d", 
                    "Volume_Ratio", "Beta", "Market_Cap")
      importance <- c(0.22, 0.18, 0.15, 0.13, 0.12, 0.09, 0.06, 0.05)
      
      plot_ly(x = importance, y = reorder(features, importance), type = "bar", orientation = "h",
              marker = list(color = ml_colors$primary, line = list(color = "white", width = 1)),
              text = round(importance, 3), textposition = "outside") %>%
        layout(
          title = list(text = "Global Feature Importance", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Importance", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "", color = "#8B949E"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          margin = list(l = 150)
        )
    })
    
    output$pdp <- renderPlotly({
      pe_ratio <- seq(5, 50, length.out = 100)
      predicted_return <- 0.1 - 0.003 * pe_ratio + 0.00003 * pe_ratio^2
      
      plot_ly(x = pe_ratio, y = predicted_return, type = "scatter", mode = "lines",
              line = list(color = ml_colors$primary, width = 3)) %>%
        layout(
          title = list(text = "Partial Dependence: P/E Ratio Effect", font = list(color = "#E6EDF3")),
          xaxis = list(title = "P/E Ratio", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Predicted Return", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3")
        )
    })
    
    output$lime_explanation <- renderPlotly({
      features <- c("Momentum", "PE_Ratio", "ROE", "Volatility", "Size")
      weights <- c(0.35, -0.15, 0.22, -0.08, 0.05)
      
      plot_ly(x = weights, y = reorder(features, abs(weights)), type = "bar", orientation = "h",
              marker = list(color = ifelse(weights > 0, ml_colors$success, ml_colors$danger),
                            line = list(color = "white", width = 1)),
              text = round(weights, 3), textposition = "outside") %>%
        layout(
          title = list(text = "LIME: Local Explanation for Single Prediction", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Contribution", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "", color = "#8B949E"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          margin = list(l = 120)
        )
    })
    
  })
}
