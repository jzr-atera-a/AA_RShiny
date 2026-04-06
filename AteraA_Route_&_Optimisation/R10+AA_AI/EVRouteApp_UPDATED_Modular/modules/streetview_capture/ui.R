# modules/streetview_capture/ui.R

streetview_capture_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Street View Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 4,
        
        textInput(
          ns("api_key"),
          "Google Maps API Key:",
          value = "",
          placeholder = "Enter your API key"
        ),
        
        p(class = "text-muted small",
          "Required for downloading Street View images. Get yours at ",
          tags$a("Google Cloud Console", href = "https://console.cloud.google.com", target = "_blank")),
        
        br(),
        
        sliderInput(
          ns("sample_rate"),
          "Sample every Nth waypoint:",
          min = 1,
          max = 10,
          value = 5,
          step = 1
        ),
        
        p(class = "text-muted small",
          "Reduce API costs by sampling subset of waypoints."),
        
        selectInput(
          ns("image_size"),
          "Image Size:",
          choices = c("400x400" = "400x400",
                      "640x640" = "640x640"),
          selected = "640x640"
        ),
        
        sliderInput(
          ns("fov"),
          "Field of View (degrees):",
          min = 60,
          max = 120,
          value = 90,
          step = 10
        ),
        
        br(),
        
        actionButton(
          ns("download_images"),
          "Download Street View Images",
          class = "btn-success",
          icon = icon("download"),
          width = "100%"
        ),
        
        br(), br(),
        
        uiOutput(ns("download_status"))
      ),
      
      box(
        title = "Download Information",
        status = "info",
        solidHeader = TRUE,
        width = 8,
        
        h5("About Street View Capture:"),
        p("Downloads Google Street View static images at waypoint locations for ML analysis."),
        
        tags$ul(
          tags$li("Images saved to data/raw/images/ directory"),
          tags$li("Metadata tracked in database"),
          tags$li("Cost: $0.007 per image (as of 2024)"),
          tags$li("Sampling reduces cost while maintaining coverage")
        ),
        
        br(),
        
        fluidRow(
          column(3, valueBoxOutput(ns("total_waypoints"), width = NULL)),
          column(3, valueBoxOutput(ns("images_to_download"), width = NULL)),
          column(3, valueBoxOutput(ns("images_downloaded"), width = NULL)),
          column(3, valueBoxOutput(ns("download_cost"), width = NULL))
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Image Gallery",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        collapsed = TRUE,
        
        uiOutput(ns("image_gallery"))
      )
    )
  )
}
