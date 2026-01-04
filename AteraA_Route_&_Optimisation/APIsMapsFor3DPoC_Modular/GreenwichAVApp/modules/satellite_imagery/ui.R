# modules/satellite_imagery/ui.R

satellite_imagery_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Satellite Imagery Configuration", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 4,
        
        h5("Imagery Source"),
        selectInput(ns("imagerySource"), "Select Provider:",
                   choices = c("Google Maps Static API" = "google",
                              "Bing Maps" = "bing",
                              "Mapbox Satellite" = "mapbox"),
                   selected = "google"),
        
        textInput(ns("imageryAPIKey"), "API Key:", 
                  value = "",
                  placeholder = "Enter your API key"),
        
        br(),
        
        h5("Image Settings"),
        selectInput(ns("imageryResolution"), "Resolution:",
                   choices = c("Standard (640x640)" = "640",
                              "High (1280x1280)" = "1280",
                              "Ultra (2048x2048)" = "2048"),
                   selected = "1280"),
        
        selectInput(ns("imageryZoom"), "Zoom Level:",
                   choices = c("17 - Building Details" = "17",
                              "18 - Fine Details" = "18",
                              "19 - Maximum Detail" = "19"),
                   selected = "17"),
        
        br(),
        
        actionButton(ns("downloadImagery"), "Download Satellite Imagery", 
                     class = "btn-success", 
                     icon = icon("download"),
                     style = "width: 100%;"),
        
        br(), br(),
        
        uiOutput(ns("imageryStatus"))
      ),
      
      box(
        title = "Satellite Imagery Information", 
        status = "info", 
        solidHeader = TRUE, 
        width = 8,
        
        h5("About Satellite Imagery:"),
        p("High-resolution aerial and satellite imagery provides realistic ground textures 
          for your Unity 3D environment."),
        
        tags$ul(
          tags$li("Google Maps: High-quality global coverage"),
          tags$li("Bing Maps: Alternative imagery source"),
          tags$li("Mapbox: Customizable satellite tiles"),
          tags$li("Format: PNG, GeoTIFF with georeferencing")
        ),
        
        br(),
        
        fluidRow(
          column(4, valueBoxOutput(ns("imageryRes"), width = NULL)),
          column(4, valueBoxOutput(ns("imageryZoomLevel"), width = NULL)),
          column(4, valueBoxOutput(ns("imageryFormat"), width = NULL))
        ),
        
        br(),
        
        div(class = "status-warning",
            h5("API Key Required:"),
            tags$ul(
              tags$li("Google Maps: Get key at console.cloud.google.com"),
              tags$li("Bing Maps: Get key at www.bingmapsportal.com"),
              tags$li("Mapbox: Get key at account.mapbox.com")
            ))
      )
    )
  )
}
