# modules/os_terrain/ui.R

os_terrain_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "OS Terrain Configuration", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        
        h5("Ordnance Survey Data"),
        p("Download high-quality terrain data from UK Ordnance Survey."),
        
        checkboxGroupInput(ns("terrainLayers"), "Select Layers:",
                          choices = c("OS Terrain 50 (DTM)" = "terrain50",
                                     "Building Heights" = "heights"),
                          selected = c("terrain50")),
        
        br(),
        
        actionButton(ns("downloadTerrain"), "Download Terrain Data", 
                     class = "btn-success", 
                     icon = icon("download"),
                     style = "width: 100%;"),
        
        br(), br(),
        
        uiOutput(ns("terrainStatus"))
      ),
      
      box(
        title = "OS Terrain Information", 
        status = "info", 
        solidHeader = TRUE, 
        width = 8,
        
        h5("About OS Terrain Data:"),
        p("Ordnance Survey provides authoritative elevation data for the UK, 
          including digital terrain models and building heights."),
        
        tags$ul(
          tags$li("OS Terrain 50: 50m grid spacing elevation data"),
          tags$li("DTM: Digital Terrain Model showing ground surface"),
          tags$li("Building Heights: Estimated heights for structures"),
          tags$li("Format: ASCII Grid, GeoTIFF")
        ),
        
        br(),
        
        fluidRow(
          column(6, valueBoxOutput(ns("terrainRes"), width = NULL)),
          column(6, valueBoxOutput(ns("terrainFormat"), width = NULL))
        ),
        
        br(),
        
        div(class = "status-warning",
            h5("Access Note:"),
            p("OS OpenData products are freely available. Premium products may require 
              licensing. Visit ordnancesurvey.co.uk/opendatadownload for access."))
      )
    )
  )
}
