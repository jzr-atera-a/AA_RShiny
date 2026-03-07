# modules/streetview_capture.R
# Street View Capture Module - Python Backend Integration

# ============================================================================
# UI FUNCTION
# ============================================================================

streetview_capture_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Street View Python Backend",
        status = "primary",
        solidHeader = TRUE,
        width = 4,
        
        textInput(ns("api_key"),
                  "Google Maps API Key:",
                  placeholder = "Enter your API key"),
        
        sliderInput(ns("sample_rate"),
                    "Sample every Nth waypoint:",
                    min = 1, max = 10, value = 5, step = 1),
        
        tags$small(class = "text-muted",
                  "Higher = fewer images = lower cost"),
        
        selectInput(ns("image_size"),
                    "Image Size:",
                    choices = c("400x400", "640x640"),
                    selected = "640x640"),
        
        sliderInput(ns("fov"),
                    "Field of View (degrees):",
                    min = 60, max = 120, value = 90, step = 10),
        
        actionButton(ns("download_images_python"),
                     "Download Images (Python)",
                     class = "btn-success btn-block",
                     icon = icon("download")),
        
        br(), br(),
        uiOutput(ns("download_status"))
      ),
      
      box(
        title = "Download Statistics",
        status = "info",
        solidHeader = TRUE,
        width = 8,
        
        tags$div(style = "background: #e8f5e9; padding: 10px; border-radius: 5px;",
          tags$p(icon("python"), strong(" Python Backend:"),
                "Automated batch download with progress tracking")
        ),
        
        fluidRow(
          column(3, valueBoxOutput(ns("total_waypoints"), width = NULL)),
          column(3, valueBoxOutput(ns("images_to_download"), width = NULL)),
          column(3, valueBoxOutput(ns("images_downloaded"), width = NULL)),
          column(3, valueBoxOutput(ns("download_cost"), width = NULL))
        )
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

streetview_capture_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    image_metadata <- reactiveVal(NULL)
    download_stats <- reactiveVal(list(total = 0, downloaded = 0))
    
    observeEvent(input$download_images_python, {
      
      if (is.null(api_manager) || is.null(api_manager$cav_waypoints)) {
        output$download_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  "No waypoints. Generate waypoints first.")
        })
        return()
      }
      
      if (is.null(input$api_key) || input$api_key == "") {
        output$download_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  "Enter Google Maps API key.")
        })
        return()
      }
      
      withProgress(message = 'Downloading via Python...', value = 0, {
        
        tryCatch({
          
          incProgress(0.2, detail = "Preparing")
          
          waypoints <- api_manager$cav_waypoints
          output_dir <- "data/raw/images"
          dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
          
          incProgress(0.3, detail = "Calling Python backend")
          
          # PYTHON BACKEND CALL
          result <- download_streetview_python(
            waypoints = waypoints,
            output_dir = output_dir,
            api_key = input$api_key,
            sample_rate = input$sample_rate,
            size = input$image_size,
            fov = input$fov
          )
          
          if (!result$success) stop(result$error)
          
          incProgress(0.9, detail = "Processing results")
          
          metadata <- as.data.frame(do.call(rbind, result$results))
          image_metadata(metadata)
          
          if (!is.null(api_manager)) {
            api_manager$cav_images <- metadata
          }
          
          download_stats(list(
            total = result$total_waypoints,
            downloaded = result$successful_downloads
          ))
          
          output$download_status <- renderUI({
            tags$div(class = "alert alert-success",
                    sprintf("Downloaded %d images (failed: %d)",
                           result$successful_downloads,
                           result$failed_downloads))
          })
          
        }, error = function(e) {
          output$download_status <- renderUI({
            tags$div(class = "alert alert-danger", e$message)
          })
        })
      })
    })
    
    output$total_waypoints <- renderValueBox({
      wp <- if (!is.null(api_manager)) api_manager$cav_waypoints else NULL
      valueBox(
        if (is.null(wp)) "0" else nrow(wp),
        "Waypoints", icon = icon("map-marker-alt"), color = "blue"
      )
    })
    
    output$images_to_download <- renderValueBox({
      wp <- if (!is.null(api_manager)) api_manager$cav_waypoints else NULL
      count <- if (is.null(wp)) 0 else ceiling(nrow(wp) / input$sample_rate)
      valueBox(count, "To Download", icon = icon("camera"), color = "orange")
    })
    
    output$images_downloaded <- renderValueBox({
      stats <- download_stats()
      valueBox(stats$downloaded, "Downloaded", icon = icon("check"), color = "green")
    })
    
    output$download_cost <- renderValueBox({
      wp <- if (!is.null(api_manager)) api_manager$cav_waypoints else NULL
      count <- if (is.null(wp)) 0 else ceiling(nrow(wp) / input$sample_rate)
      valueBox(sprintf("$%.2f", count * 0.007), "Cost", icon = icon("dollar-sign"), color = "red")
    })
  })
}
