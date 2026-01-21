# modules/price_analysis/ui.R

price_analysis_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Price Analysis Controls", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        fluidRow(
          column(3,
                 dateRangeInput(ns("priceRange"), "Analysis Period:",
                                start = Sys.Date() - months(6),
                                end = Sys.Date(),
                                format = "yyyy-mm-dd")
          ),
          column(3,
                 checkboxGroupInput(ns("priceComponents"), "Show Components:",
                                    choices = c("Close" = "close",
                                                "High/Low" = "highlow",
                                                "Open" = "open"),
                                    selected = c("close", "highlow"))
          ),
          column(3,
                 numericInput(ns("priceMAPeriod"), "MA Periods:",
                              value = 20, min = 5, max = 200),
                 checkboxInput(ns("showBollingerBands"), "Bollinger Bands", FALSE)
          ),
          column(3,
                 verbatimTextOutput(ns("priceStats"))
          )
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Detailed Price Chart", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        withSpinner(plotlyOutput(ns("detailedPriceChart"), height = "600px"))
      )
    ),
    
    fluidRow(
      box(
        title = "OHLC Candlestick Chart", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 8,
        withSpinner(plotlyOutput(ns("ohlcChart"), height = "450px"))
      ),
      box(
        title = "OHLC Statistics", 
        status = "info", 
        solidHeader = TRUE, 
        width = 4,
        withSpinner(DT::dataTableOutput(ns("ohlcStats")))
      )
    ),
    
    fluidRow(
      box(
        title = "Returns Analysis", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("returnsTimeSeries"), height = "350px"))
      ),
      box(
        title = "Cumulative Returns", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("cumulativeReturns"), height = "350px"))
      )
    )
  )
}
