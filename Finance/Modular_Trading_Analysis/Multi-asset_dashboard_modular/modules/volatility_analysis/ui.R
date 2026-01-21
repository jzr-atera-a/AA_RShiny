# modules/volatility_analysis/ui.R

volatility_analysis_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Volatility Analysis Controls", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        
        radioButtons(ns("volatilityType"), "Volatility Method:",
                     choices = c("Realized (Close-to-Close)" = "realized",
                                 "Parkinson (High-Low)" = "parkinson",
                                 "Garman-Klass (OHLC)" = "gk"),
                     selected = "realized"),
        
        numericInput(ns("volWindow"), "Rolling Window:",
                     value = 30, min = 10, max = 252),
        
        sliderInput(ns("volConfidence"), "Confidence Level:",
                    min = 90, max = 99, value = 95),
        
        checkboxInput(ns("annualizeVol"), "Annualize Volatility", TRUE),
        
        br(),
        h5("Volatility Metrics:"),
        verbatimTextOutput(ns("volatilityMetrics"))
      ),
      
      box(
        title = "Volatility Time Series", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 8,
        withSpinner(plotlyOutput(ns("volatilityChart"), height = "450px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Volatility Distribution", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("volatilityDist"), height = "350px"))
      ),
      box(
        title = "Volatility Clustering", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("volatilityClustering"), height = "350px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Volatility Regime Analysis", 
        status = "info", 
        solidHeader = TRUE, 
        width = 12,
        withSpinner(plotlyOutput(ns("volatilityRegimes"), height = "300px"))
      )
    )
  )
}
