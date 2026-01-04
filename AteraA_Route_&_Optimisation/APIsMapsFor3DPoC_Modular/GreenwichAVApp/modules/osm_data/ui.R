# modules/osm_data/ui.R

osm_data_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      # Configuration Box
      box(
        title = "OpenStreetMap Configuration", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        
        h5("Location Settings"),
        textInput(ns("location"), "Location Name:", 
                  value = "Greenwich Peninsula, London",
                  placeholder = "e.g., Greenwich Peninsula, London"),
        
        textInput(ns("bbox_coords"), "Bounding Box (lat_min, lon_min, lat_max, lon_max):", 
                  value = "51.5025, 0.0020, 51.5035, 0.0035",
                  placeholder = "51.5025, 0.0020, 51.5035, 0.0035"),
        
        p(class = "text-muted", 
          "Default: 200m × 200m around O2 Arena. Enter coordinates or use location name."),
        
        actionButton(ns("useLocation"), "Use Location Name", 
                     class = "btn-info", icon = icon("search"),
                     style = "width: 100%; margin-bottom: 10px;"),
        
        br(),
        
        h5("Data Layers to Download"),
        checkboxGroupInput(ns("dataTypes"), NULL,
                          choices = c("Buildings" = "building",
                                     "Roads" = "highway",
                                     "Points of Interest" = "poi"),
                          selected = c("building", "highway", "poi")),
        
        br(),
        
        actionButton(ns("downloadOSM"), "Download OSM Data", 
                     class = "btn-success", 
                     icon = icon("download"),
                     style = "width: 100%;"),
        
        br(), br(),
        
        uiOutput(ns("osmStatus"))
      ),
      
      # Results Box
      box(
        title = "OpenStreetMap Data Overview", 
        status = "info", 
        solidHeader = TRUE, 
        width = 8,
        
        h5("About OpenStreetMap:"),
        p("OpenStreetMap (OSM) provides free geographic data including building footprints, 
          road networks, and points of interest. This data is perfect for creating 3D environments."),
        
        tags$ul(
          tags$li("Buildings: Footprints with height data where available"),
          tags$li("Roads: Complete street network with classifications"),
          tags$li("POI: Amenities, shops, landmarks"),
          tags$li("Export Format: GeoJSON (Unity-ready)")
        ),
        
        br(),
        
        fluidRow(
          column(4, valueBoxOutput(ns("buildingCount"), width = NULL)),
          column(4, valueBoxOutput(ns("roadCount"), width = NULL)),
          column(4, valueBoxOutput(ns("poiCount"), width = NULL))
        ),
        
        br(),
        
        conditionalPanel(
          condition = paste0("output['", ns("osmLoaded"), "']"),
          downloadButton(ns("downloadGeoJSON"), "Download GeoJSON Files", 
                        class = "btn-primary", style = "width: 100%;")
        )
      )
    ),
    
    # Preview Map
    fluidRow(
      box(
        title = "Data Preview Map", 
        status = "success", 
        solidHeader = TRUE, 
        width = 12,
        
        leafletOutput(ns("previewMap"), height = "500px"),
        
        br(),
        
        div(style = "text-align: center;",
            p(HTML("<span style='color: red;'>▪</span> Buildings | 
                   <span style='color: blue;'>―</span> Roads | 
                   <span style='color: green;'>●</span> Points of Interest"))
        )
      )
    )
  )
}
