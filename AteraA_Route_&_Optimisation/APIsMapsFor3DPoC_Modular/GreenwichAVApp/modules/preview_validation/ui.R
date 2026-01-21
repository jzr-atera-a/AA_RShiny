# modules/preview_validation/ui.R

preview_validation_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Summary Row
    fluidRow(
      box(
        title = "Data Collection Summary", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        h4("Greenwich AV Project - Data Export Status"),
        
        br(),
        
        fluidRow(
          column(2, valueBoxOutput(ns("osmStatus"), width = NULL)),
          column(2, valueBoxOutput(ns("arcgisStatus"), width = NULL)),
          column(2, valueBoxOutput(ns("terrainStatus"), width = NULL)),
          column(2, valueBoxOutput(ns("lidarStatus"), width = NULL)),
          column(2, valueBoxOutput(ns("imageryStatus"), width = NULL)),
          column(2, valueBoxOutput(ns("exportStatus"), width = NULL))
        )
      )
    ),
    
    # Map and Controls Row
    fluidRow(
      box(
        title = "Data Layer Preview", 
        status = "success", 
        solidHeader = TRUE, 
        width = 8,
        
        leafletOutput(ns("previewMap"), height = "600px"),
        
        br(),
        
        div(style = "text-align: center;",
            h5("Map Legend:"),
            p(HTML("<span style='color: red;'>▪</span> Buildings | 
                   <span style='color: blue;'>―</span> Roads | 
                   <span style='color: green;'>●</span> POI | 
                   <span style='color: purple;'>□</span> Bounding Box"))
        )
      ),
      
      box(
        title = "Export Controls", 
        status = "info", 
        solidHeader = TRUE, 
        width = 4,
        
        h5("Data Validation"),
        uiOutput(ns("validationSummary")),
        
        br(),
        
        h5("Export Options"),
        checkboxGroupInput(ns("exportLayers"), "Layers to Export:",
                          choices = c("OSM Data (GeoJSON)" = "osm",
                                     "Terrain Data (GeoTIFF)" = "terrain",
                                     "LIDAR Data (GeoTIFF)" = "lidar",
                                     "Satellite Imagery (PNG)" = "imagery"),
                          selected = c("osm", "terrain", "imagery")),
        
        br(),
        
        actionButton(ns("exportAll"), "Export All Data", 
                     class = "btn-success", 
                     icon = icon("file-archive"),
                     style = "width: 100%;"),
        
        br(), br(),
        
        uiOutput(ns("exportInfo")),
        
        br(),
        
        conditionalPanel(
          condition = paste0("output['", ns("exportReady"), "']"),
          downloadButton(ns("downloadBundle"), "Download ZIP Bundle", 
                        class = "btn-primary", style = "width: 100%;")
        )
      )
    ),
    
    # Metadata Row
    fluidRow(
      box(
        title = "Area Information", 
        status = "warning", 
        solidHeader = TRUE, 
        width = 6,
        
        h5("Target Area Details:"),
        verbatimTextOutput(ns("areaInfo")),
        
        br(),
        
        h5("Coordinate System:"),
        p("WGS84 (EPSG:4326) - Standard for Unity import"),
        p("Can be converted to British National Grid (EPSG:27700) if needed")
      ),
      
      box(
        title = "Unity Import Instructions", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        
        h5("Steps for Unity 3D:"),
        tags$ol(
          tags$li("Extract the downloaded ZIP file"),
          tags$li("Import GeoJSON files using a Unity GIS plugin (e.g., Mapbox SDK)"),
          tags$li("Load terrain/LIDAR as heightmap"),
          tags$li("Apply satellite imagery as ground texture"),
          tags$li("Convert building footprints to 3D meshes")
        ),
        
        br(),
        
        p(class = "text-muted", 
          "Recommended Unity plugins: Mapbox SDK for Unity, GIS Tools, Terrain Toolkit")
      )
    )
  )
}
