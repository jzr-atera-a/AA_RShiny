# modules/hedging_strategies/ui.R

hedging_strategies_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Hedging Strategy Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 4,
        
        selectInput(ns("hedgeAsset"), "Hedge Against:",
                    choices = c("Bitcoin (BTC-USD)" = "BTC-USD",
                                "Ethereum (ETH-USD)" = "ETH-USD",
                                "Gold (GC=F)" = "GC=F",
                                "Crude Oil (CL=F)" = "CL=F",
                                "S&P 500 (^GSPC)" = "^GSPC"),
                    selected = "^GSPC"),
        
        numericInput(ns("hedgeRatio"), "Initial Hedge Ratio:",
                     value = 1.0, min = 0.1, max = 2.0, step = 0.1),
        
        numericInput(ns("rebalanceFreq"), "Rebalance Frequency (days):",
                     value = 30, min = 1, max = 90, step = 1),
        
        radioButtons(ns("hedgeMethod"), "Hedge Method:",
                     choices = c("Static Hedge" = "static",
                                 "Dynamic (Correlation-based)" = "dynamic",
                                 "Beta-Adjusted" = "beta",
                                 "Minimum Variance" = "minvar"),
                     selected = "dynamic"),
        
        numericInput(ns("hedgeLookback"), "Lookback Period (days):",
                     value = 60, min = 20, max = 250, step = 10),
        
        actionButton(ns("runHedgeAnalysis"), "Run Hedge Analysis", 
                     class = "btn-primary", width = "100%")
      ),
      
      box(
        title = "Hedging Effectiveness Summary",
        status = "info",
        solidHeader = TRUE,
        width = 8,
        
        fluidRow(
          column(6,
                 h5("Without Hedge:"),
                 verbatimTextOutput(ns("unhedgedStats"))
          ),
          column(6,
                 h5("With Hedge:"),
                 verbatimTextOutput(ns("hedgedStats"))
          )
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Portfolio Performance: Hedged vs Unhedged",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        withSpinner(plotlyOutput(ns("hedgePerformanceChart"), height = "500px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Rolling Hedge Ratio",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("hedgeRatioChart"), height = "350px"))
      ),
      box(
        title = "Rolling Correlation",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("hedgeCorrelationChart"), height = "350px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Hedge Effectiveness Metrics",
        status = "info",
        solidHeader = TRUE,
        width = 6,
        withSpinner(DT::dataTableOutput(ns("hedgeEffectivenessTable")))
      ),
      box(
        title = "Beta Analysis",
        status = "info",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("betaAnalysisChart"), height = "350px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Cost-Benefit Analysis",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        withSpinner(DT::dataTableOutput(ns("hedgeCostBenefitTable")))
      )
    )
  )
}
