# modules/technical_indicators/ui.R

technical_indicators_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Technical Analysis Settings", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 3,
        
        checkboxGroupInput(ns("technicalIndicators"), "Select Indicators:",
                           choices = c("Simple Moving Average" = "sma",
                                       "Exponential Moving Average" = "ema",
                                       "RSI" = "rsi",
                                       "MACD" = "macd",
                                       "Bollinger Bands" = "bb",
                                       "Stochastic" = "stoch"),
                           selected = c("sma", "rsi")),
        
        numericInput(ns("smaLength"), "SMA Length:", value = 20, min = 5, max = 200),
        numericInput(ns("emaLength"), "EMA Length:", value = 20, min = 5, max = 200),
        numericInput(ns("rsiLength"), "RSI Length:", value = 14, min = 5, max = 50),
        numericInput(ns("bbLength"), "BB Length:", value = 20, min = 5, max = 100),
        numericInput(ns("bbSd"), "BB Std Dev:", value = 2, min = 1, max = 3, step = 0.1),
        
        br(),
        h5("Current Signals:"),
        verbatimTextOutput(ns("technicalSignals"))
      ),
      
      box(
        title = "Technical Chart", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 9,
        withSpinner(plotlyOutput(ns("technicalChart"), height = "600px"))
      )
    ),
    
    conditionalPanel(
      condition = sprintf("input['%s'].includes('rsi')", ns("technicalIndicators")),
      fluidRow(
        box(
          title = "RSI Oscillator", 
          status = "primary", 
          solidHeader = TRUE, 
          width = 12,
          withSpinner(plotlyOutput(ns("rsiChart"), height = "300px"))
        )
      )
    ),
    
    conditionalPanel(
      condition = sprintf("input['%s'].includes('macd')", ns("technicalIndicators")),
      fluidRow(
        box(
          title = "MACD Indicator", 
          status = "primary", 
          solidHeader = TRUE, 
          width = 12,
          withSpinner(plotlyOutput(ns("macdChart"), height = "300px"))
        )
      )
    ),
    
    conditionalPanel(
      condition = sprintf("input['%s'].includes('stoch')", ns("technicalIndicators")),
      fluidRow(
        box(
          title = "Stochastic Oscillator", 
          status = "primary", 
          solidHeader = TRUE, 
          width = 12,
          withSpinner(plotlyOutput(ns("stochChart"), height = "300px"))
        )
      )
    )
  )
}
