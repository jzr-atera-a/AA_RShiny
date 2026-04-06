# modules/route_optimizer/ui.R

route_optimizer_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Route Selection", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        
        h4("Select Origin and Destination"),
        
        selectInput(ns("originAddress"), "Origin:",
                    choices = c(
                      "Judge Business School, Cambridge England",
                      "North Cambridge, Cambridge England",
                      "Cambridge West, Cambridge England",
                      "Addenbrooke's Hospital, Cambridge England"
                    ),
                    selected = "Judge Business School, Cambridge England"),
        
        selectInput(ns("destinationAddress"), "Destination:",
                    choices = c(
                      "Petersfield, Cambridge England",
                      "Chesterton, Cambridge England",
                      "Teversham, Cambridge England",
                      "Girton, Cambridge England"
                    ),
                    selected = "Petersfield, Cambridge England"),
        
        br(),
        
        numericInput(ns("numChargingPoints"), "Number of Charging Points:",
                     value = 3, min = 1, max = 10, step = 1),
        
        p(class = "text-muted", 
          "The system will find nearest charging points and calculate optimal route."),
        
        br(),
        
        actionButton(ns("calculateRoute"), "Calculate Optimal Route", 
                     class = "btn-success", 
                     icon = icon("route"),
                     width = "100%"),
        
        br(), br(),
        uiOutput(ns("routeStatus"))
      ),
      
      box(
        title = "Route Information", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        
        conditionalPanel(
          condition = paste0("output['", ns("routeCalculated"), "']"),
          h5("Route Summary:"),
          verbatimTextOutput(ns("routeSummary")),
          br(),
          h5("Nearest Charging Points:"),
          verbatimTextOutput(ns("chargingPointsInfo")),
          br(),
          actionButton(ns("viewMap"), "View Route Map", 
                       class = "btn-info", 
                       icon = icon("map"),
                       width = "100%")
        ),
        
        conditionalPanel(
          condition = paste0("!output['", ns("routeCalculated"), "']"),
          div(style = "text-align: center; padding: 50px;",
              icon("info-circle", style = "font-size: 48px; color: #95a5a6;"),
              h4("No Route Calculated", style = "color: #7f8c8d; margin-top: 20px;"),
              p("Select addresses and click Calculate.", style = "color: #95a5a6;")
          )
        )
      )
    )
  )
}
