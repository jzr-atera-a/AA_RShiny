# modules/composite_analysis/ui.R

composite_analysis_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Multi-Asset Comparison Settings",
        status = "primary",
        solidHeader = TRUE,
        width = 4,
        
        checkboxGroupInput(ns("compareAssets"), "Select Assets to Compare:",
                          choices = c("Bitcoin (BTC-USD)" = "BTC-USD",
                                      "Ethereum (ETH-USD)" = "ETH-USD",
                                      "Cardano (ADA-USD)" = "ADA-USD",
                                      "NVIDIA (NVDA)" = "NVDA",
                                      "Microsoft (MSFT)" = "MSFT",
                                      "Apple (AAPL)" = "AAPL",
                                      "Gold (GC=F)" = "GC=F",
                                      "Crude Oil (CL=F)" = "CL=F",
                                      "Natural Gas (NG=F)" = "NG=F"),
                          selected = c("BTC-USD", "ETH-USD", "NVDA", "GC=F")),
        
        radioButtons(ns("normalizationMethod"), "Normalization Method:",
                    choices = c("Index (Base 100)" = "index",
                               "Percentage Returns" = "returns",
                               "Raw Prices" = "raw"),
                    selected = "index"),
        
        dateRangeInput(ns("compareRange"), "Comparison Period:",
                      start = Sys.Date() - months(6),
                      end = Sys.Date()),
        
        actionButton(ns("runComparison"), "Run Comparison", 
                    class = "btn-primary", width = "100%")
      ),
      
      box(
        title = "Asset Class Summary",
        status = "info",
        solidHeader = TRUE,
        width = 8,
        withSpinner(DT::dataTableOutput(ns("assetClassSummary")))
      )
    ),
    
    fluidRow(
      box(
        title = "Multi-Asset Performance Comparison",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        withSpinner(plotlyOutput(ns("multiAssetChart"), height = "600px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Correlation Heatmap",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("correlationHeatmap"), height = "500px"))
      ),
      box(
        title = "Risk-Return Profile",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        withSpinner(plotlyOutput(ns("riskReturnScatter"), height = "500px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Rolling Correlations",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        withSpinner(plotlyOutput(ns("rollingCorrelations"), height = "400px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Performance Metrics Comparison",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        withSpinner(DT::dataTableOutput(ns("performanceMetricsTable")))
      )
    )
  )
}
