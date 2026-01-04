# modules/arcgis_data/ui.R

arcgis_data_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "ArcGIS Living Atlas Configuration", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        
        h5("API Configuration"),
        textInput(ns("apiKey"), "ArcGIS API Key (Optional):", 
                  value = "",
                  placeholder = "Enter your API key from developers.arcgis.com"),
        
        p(class = "text-muted", 
          "Free tier allows limited requests. Get a free key at developers.arcgis.com"),
        
        br(),
        
        h5("Data Layers"),
        checkboxGroupInput(ns("arcgisLayers"), NULL,
                          choices = c("Buildings (3D)" = "buildings",
                                     "Imagery (Satellite)" = "imagery",
                                     "Elevation (DEM)" = "elevation"),
                          selected = c("buildings", "imagery")),
        
        br(),
        
        actionButton(ns("downloadArcGIS"), "Download ArcGIS Data", 
                     class = "btn-success", 
                     icon = icon("download"),
                     style = "width: 100%;"),
        
        br(), br(),
        
        uiOutput(ns("arcgisStatus"))
      ),
      
      box(
        title = "ArcGIS Living Atlas Information", 
        status = "info", 
        solidHeader = TRUE, 
        width = 8,
        
        h5("About ArcGIS Living Atlas:"),
        p("ArcGIS Living Atlas provides authoritative, ready-to-use global geographic content 
          including high-resolution imagery, building footprints, and elevation data."),
        
        tags$ul(
          tags$li("Buildings: 3D building models where available"),
          tags$li("Imagery: High-resolution satellite and aerial imagery"),
          tags$li("Elevation: Digital elevation models (DEM)"),
          tags$li("Export Formats: GeoJSON, SLPK, GeoTIFF")
        ),
        
        br(),
        
        fluidRow(
          column(4, valueBoxOutput(ns("arcgisBuildings"), width = NULL)),
          column(4, valueBoxOutput(ns("arcgisImagery"), width = NULL)),
          column(4, valueBoxOutput(ns("arcgisElevation"), width = NULL))
        ),
        
        br(),
        
        div(class = "status-info",
            h5("Note:"),
            p("ArcGIS Living Atlas requires an API key for full access. Without a key, 
              only limited public data is available. Sign up for a free developer account 
              at developers.arcgis.com to access more features."))
      )
    )
  )
}
