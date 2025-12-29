# modules/market_overview/ui.R

market_overview_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Data Information & Chart Controls",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(3,
                 div(class = "status-info",
                     uiOutput(ns("dataSourceInfo")))
          ),
          column(3,
                 checkboxGroupInput(ns("overviewComponents"), "Show Components:",
                                    choices = c("Close Price" = "close",
                                                "Volume" = "volume",
                                                "Moving Averages" = "ma"),
                                    selected = c("close", "volume"),
                                    inline = FALSE)
          ),
          column(3,
                 numericInput(ns("overviewMA"), "Moving Average Period:",
                              value = 20, min = 5, max = 200, step = 5)
          ),
          column(3,
                 actionButton(ns("refreshData"), "Refresh Data", 
                              class = "btn-primary", width = "100%")
          )
        )
      )
    ),
    
    fluidRow(
      valueBoxOutput(ns("currentPrice"), width = 3),
      valueBoxOutput(ns("dailyChange"), width = 3),
      valueBoxOutput(ns("volumeInfo"), width = 3),
      valueBoxOutput(ns("dataRange"), width = 3)
    ),
    
    fluidRow(
      box(
        title = "Price Chart with Volume", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        withSpinner(plotlyOutput(ns("overviewChart"), height = "500px"))
      )
    ),
    
    fluidRow(
      box(
        title = "Market Statistics", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        withSpinner(DT::dataTableOutput(ns("marketStats")))
      ),
      box(
        title = "Price Movement Analysis", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        withSpinner(DT::dataTableOutput(ns("priceMovementStats")))
      ),
      box(
        title = "Volume Analysis", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        withSpinner(DT::dataTableOutput(ns("volumeStats")))
      )
    ),
    
    fluidRow(
      box(
        title = "Returns Distribution", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("returnsDistribution"), height = "300px"))
      ),
      box(
        title = "Price Distribution", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("priceDistribution"), height = "300px"))
      )
    )
  )
}
