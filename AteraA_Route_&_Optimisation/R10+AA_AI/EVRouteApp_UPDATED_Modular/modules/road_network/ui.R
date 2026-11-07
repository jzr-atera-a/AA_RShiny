# modules/road_network/ui.R

road_network_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Road Network Configuration", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        
        textInput(ns("placeName"), "Location Name:", 
                  value = "Cambridge, England",
                  placeholder = "e.g., Cambridge, England"),
        
        p(class = "text-muted", 
          "Enter a city or region name to download the road network from OpenStreetMap."),
        
        br(),
        
        actionButton(ns("downloadNetwork"), "Download Road Network", 
                     class = "btn-success", 
                     icon = icon("download"),
                     width = "100%"),
        
        br(), br(),
        
        uiOutput(ns("networkStatus")),
        
        br(),
        
        conditionalPanel(
          condition = paste0("output['", ns("networkLoaded"), "']"),
          div(
            h5("Network Statistics:"),
            verbatimTextOutput(ns("networkStats"))
          )
        )
      ),
      
      box(
        title = "Network Information", 
        status = "info", 
        solidHeader = TRUE, 
        width = 8,
        
        h5("About Road Networks:"),
        p("The road network is downloaded from OpenStreetMap and converted into a routing graph."),
        
        tags$ul(
          tags$li("Network Type: Drive (suitable for vehicles)"),
          tags$li("Data Source: OpenStreetMap"),
          tags$li("Routing Engine: dodgr (Distances On Directed Graphs)"),
          tags$li("Path Finding: Shortest path algorithm")
        ),
        
        br(),
        
        fluidRow(
          column(4, valueBoxOutput(ns("networkNodes"), width = NULL)),
          column(4, valueBoxOutput(ns("networkEdges"), width = NULL)),
          column(4, valueBoxOutput(ns("networkStatus_box"), width = NULL))
        )
      )
    )
  )
}
