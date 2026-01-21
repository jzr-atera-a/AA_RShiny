# modules/lidar_data/ui.R

lidar_data_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "LIDAR Data Configuration", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        
        h5("Environment Agency LIDAR"),
        p("High-resolution elevation data (1-2m resolution) for England."),
        
        selectInput(ns("lidarResolution"), "Resolution:",
                   choices = c("1m DTM" = "1m",
                              "2m DTM" = "2m",
                              "1m DSM" = "1m_dsm"),
                   selected = "1m"),
        
        p(class = "text-muted", 
          "DTM = Digital Terrain Model (ground), DSM = Digital Surface Model (includes buildings)"),
        
        br(),
        
        actionButton(ns("downloadLIDAR"), "Find LIDAR Tiles", 
                     class = "btn-success", 
                     icon = icon("download"),
                     style = "width: 100%;"),
        
        br(), br(),
        
        uiOutput(ns("lidarStatus"))
      ),
      
      box(
        title = "LIDAR Information", 
        status = "info", 
        solidHeader = TRUE, 
        width = 8,
        
        h5("About LIDAR Data:"),
        p("LIDAR (Light Detection and Ranging) provides precise elevation measurements 
          using laser scanning. Perfect for creating accurate 3D terrain."),
        
        tags$ul(
          tags$li("Resolution: 1-2 meter grid spacing"),
          tags$li("Accuracy: Sub-meter vertical accuracy"),
          tags$li("Coverage: Most of England, including Greater London"),
          tags$li("Format: GeoTIFF, ASCII Grid")
        ),
        
        br(),
        
        fluidRow(
          column(4, valueBoxOutput(ns("lidarTiles"), width = NULL)),
          column(4, valueBoxOutput(ns("lidarRes"), width = NULL)),
          column(4, valueBoxOutput(ns("lidarSize"), width = NULL))
        ),
        
        br(),
        
        div(class = "status-info",
            h5("Download Instructions:"),
            p("LIDAR data is freely available from the Environment Agency. 
              Visit environment.data.gov.uk/survey to download tiles for your area."))
      )
    )
  )
}
