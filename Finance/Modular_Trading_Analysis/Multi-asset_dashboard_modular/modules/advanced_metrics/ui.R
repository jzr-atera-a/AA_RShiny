# modules/advanced_metrics/ui.R

advanced_metrics_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      valueBoxOutput(ns("sharpeRatioBox"), width = 3),
      valueBoxOutput(ns("sortinoRatioBox"), width = 3),
      valueBoxOutput(ns("calmarRatioBox"), width = 3),
      valueBoxOutput(ns("omegaRatioBox"), width = 3)
    ),
    
    fluidRow(
      box(
        title = "Advanced Metrics Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(3,
                 numericInput(ns("riskFreeRate"), "Risk-Free Rate (%):",
                              value = 4.5, min = 0, max = 10, step = 0.1)
          ),
          column(3,
                 numericInput(ns("targetReturn"), "Target Return (%):",
                              value = 0, min = -10, max = 20, step = 0.5)
          ),
          column(3,
                 numericInput(ns("rollingWindow"), "Rolling Window (days):",
                              value = 252, min = 30, max = 500, step = 10)
          ),
          column(3,
                 checkboxInput(ns("annualizeMetrics"), "Annualize Metrics", TRUE)
          )
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Risk-Adjusted Performance Metrics",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        withSpinner(DT::dataTableOutput(ns("advancedMetricsTable")))
      )
    ),
    
    fluidRow(
      box(
        title = "Rolling Sharpe Ratio",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("rollingSharpeChart"), height = "400px"))
      ),
      box(
        title = "Rolling Sortino Ratio",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("rollingSortinoChart"), height = "400px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Downside Risk Analysis",
        status = "info",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("downsideRiskChart"), height = "350px"))
      ),
      box(
        title = "Upside vs Downside Capture",
        status = "info",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("upsideDownsideChart"), height = "350px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Maximum Drawdown Details",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("maxDrawdownDetailChart"), height = "350px"))
      ),
      box(
        title = "Recovery Period Analysis",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        withSpinner(DT::dataTableOutput(ns("recoveryPeriodTable")))
      )
    )
  )
}
