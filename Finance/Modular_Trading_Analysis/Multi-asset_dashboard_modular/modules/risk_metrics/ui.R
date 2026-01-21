# modules/risk_metrics/ui.R

risk_metrics_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Risk Analysis Settings", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        
        numericInput(ns("portfolioValue"), "Portfolio Value (USD):",
                     value = 1000000, min = 10000, max = 100000000, step = 10000),
        
        sliderInput(ns("confidenceLevel"), "VaR Confidence (%):",
                    min = 90, max = 99.5, value = 95, step = 0.5),
        
        numericInput(ns("timeHorizon"), "Time Horizon (days):",
                     value = 1, min = 1, max = 30),
        
        radioButtons(ns("varMethod"), "VaR Method:",
                     choices = c("Historical" = "historical",
                                 "Parametric" = "parametric",
                                 "Cornish-Fisher" = "modified"),
                     selected = "historical"),
        
        numericInput(ns("varWindow"), "VaR Window:",
                     value = 250, min = 100, max = 1000),
        
        br(),
        h5("Risk Summary:"),
        verbatimTextOutput(ns("riskMetrics"))
      ),
      
      box(
        title = "Value at Risk Analysis", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 8,
        withSpinner(plotlyOutput(ns("varChart"), height = "450px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Expected Shortfall", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("expectedShortfall"), height = "350px"))
      ),
      box(
        title = "Drawdown Analysis", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("drawdownAnalysis"), height = "350px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Risk Statistics", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(DT::dataTableOutput(ns("riskStatsTable")))
      ),
      box(
        title = "Stress Testing", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(DT::dataTableOutput(ns("stressTestResults")))
      )
    )
  )
}
