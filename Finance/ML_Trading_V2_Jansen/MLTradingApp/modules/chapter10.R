# modules/chapter10.R — Bayesian ML: Dynamic Sharpe Ratios and Pairs Trading

chapter10_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(10, "🎲", "Bayesian Machine Learning",
      "Dynamic Sharpe Ratios and Pairs Trading - Probabilistic models, uncertainty quantification, and adaptive strategies using PyMC3.",
      c("Bayes Theorem", "MCMC", "PyMC3", "Posterior", "Conjugate Priors")),

    stats_row(
      list("P(θ|D)", "Posterior"),
      list("MCMC", "Sampling"), 
      list("PyMC3", "Framework"),
      list("NUTS", "Sampler")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🎯 Bayes' Theorem", status = "info", solidHeader = TRUE, width = 6,
                framework_card("The Formula",
                  tagList(
                    tags$p(tags$strong("P(θ|D) = P(D|θ) × P(θ) / P(D)")),
                    tags$ul(
                      tags$li(tags$strong("P(θ|D):"), " Posterior"),
                      tags$li(tags$strong("P(D|θ):"), " Likelihood"),
                      tags$li(tags$strong("P(θ):"), " Prior"),
                      tags$li(tags$strong("P(D):"), " Evidence")
                    )
                  )
                )
            ),
            
            box(title = "📊 Posterior Example", status = "warning", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("posterior_dist"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "🔮 Inference Methods", status = "success", solidHeader = TRUE, width = 12,
                framework_card("MCMC Sampling",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Metropolis-Hastings:"), " Accept/reject proposals"),
                      tags$li(tags$strong("NUTS:"), " No-U-Turn Sampler (PyMC3 default)"),
                      tags$li(tags$strong("Gibbs:"), " Conditional sampling"),
                      tags$li(tags$strong("Variational:"), " Fast approximation")
                    )
                  )
                ),
                plotlyOutput(ns("mcmc_trace"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "📈 Bayesian Sharpe Ratio", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Performance Comparison",
                  "Compare two strategies probabilistically. Output: P(Sharpe_A > Sharpe_B) instead of point estimates. Accounts for estimation uncertainty."
                )
            ),
            
            box(title = "💹 Bayesian Pairs Trading", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Rolling Regression",
                  "Update hedge ratio dynamically using Bayesian linear regression. Adapt to regime changes. Quantify parameter uncertainty."
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

chapter10_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$posterior_dist <- renderPlotly({
      x <- seq(-3, 3, length.out = 200)
      prior <- dnorm(x, 0, 1)
      likelihood <- dnorm(x, 1, 0.5)
      posterior <- dnorm(x, 0.67, 0.45)
      
      plot_ly() %>%
        add_trace(x = x, y = prior, name = "Prior", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 2)) %>%
        add_trace(x = x, y = likelihood, name = "Likelihood", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$secondary, width = 2)) %>%
        add_trace(x = x, y = posterior, name = "Posterior", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 3)) %>%
        layout(
          title = list(text = "Prior + Likelihood → Posterior", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Parameter θ", color = "#8B949E"),
          yaxis = list(title = "Density", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$mcmc_trace <- renderPlotly({
      set.seed(789)
      iterations <- 1:1000
      samples <- cumsum(rnorm(1000, 0, 0.1)) + 0.5
      
      plot_ly(x = iterations, y = samples, type = "scatter", mode = "lines",
              line = list(color = ml_colors$primary, width = 1)) %>%
        layout(
          title = list(text = "MCMC Trace Plot: Parameter Samples", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Iteration", color = "#8B949E"),
          yaxis = list(title = "Parameter Value", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
  })
}
