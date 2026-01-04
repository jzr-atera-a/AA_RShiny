# modules/satellite_imagery/server.R

satellite_imagery_server <- function(id, data_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    imagery_data <- reactiveVal(NULL)
    
    observeEvent(input$downloadImagery, {
      
      withProgress(message = 'Preparing imagery download...', value = 0, {
        
        tryCatch({
          
          bbox <- if (!is.null(data_manager)) {
            data_manager$bbox
          } else {
            get_default_greenwich_bbox()
          }
          
          # Calculate center point
          center_lat <- (bbox[2] + bbox[4]) / 2
          center_lon <- (bbox[1] + bbox[3]) / 2
          
          incProgress(0.3, detail = "Building request")
          
          # Check if API key provided
          if (input$imageryAPIKey == "") {
            output$imageryStatus <- renderUI({
              status_message("warning", "⚠ API Key Required", 
                            "Please enter an API key to download imagery. Free keys available from provider.")
            })
            
            showNotification("API key required for imagery download", 
                            type = "warning", duration = 5)
            return()
          }
          
          incProgress(0.4, detail = "Preparing download")
          
          # Build URL based on provider
          url <- switch(input$imagerySource,
            "google" = paste0("https://maps.googleapis.com/maps/api/staticmap?",
                             "center=", center_lat, ",", center_lon,
                             "&zoom=", input$imageryZoom,
                             "&size=", input$imageryResolution, "x", input$imageryResolution,
                             "&maptype=satellite",
                             "&key=", input$imageryAPIKey),
            "bing" = paste0("Bing Maps API URL - Implementation needed"),
            "mapbox" = paste0("Mapbox API URL - Implementation needed")
          )
          
          results <- list(
            provider = input$imagerySource,
            resolution = input$imageryResolution,
            zoom = input$imageryZoom,
            center = c(center_lat, center_lon),
            url = url,
            api_key_set = TRUE
          )
          
          incProgress(0.3, detail = "Complete")
          
          imagery_data(results)
          
          if (!is.null(data_manager)) {
            data_manager$imagery_data <- results
            data_manager$check_export_ready()
          }
          
          output$imageryStatus <- renderUI({
            status_message("success", "✓ Imagery URL Generated", 
                          paste("Ready to download", input$imageryResolution, 
                                "imagery at zoom level", input$imageryZoom, 
                                "from", toupper(input$imagerySource)))
          })
          
          showNotification("Imagery download URL prepared. Use the URL to fetch imagery.", 
                          type = "message", duration = 5)
          
        }, error = function(e) {
          output$imageryStatus <- renderUI({
            status_message("error", "✗ Preparation Failed", e$message)
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    output$imageryRes <- renderValueBox({
      res <- imagery_data()
      if (!is.null(res)) {
        valueBox(paste0(res$resolution, "px"), "Resolution", 
                icon = icon("image"), color = "blue")
      } else {
        valueBox("Not Set", "Resolution", icon = icon("image"), color = "red")
      }
    })
    
    output$imageryZoomLevel <- renderValueBox({
      res <- imagery_data()
      if (!is.null(res)) {
        valueBox(res$zoom, "Zoom Level", icon = icon("search-plus"), color = "green")
      } else {
        valueBox("Not Set", "Zoom Level", icon = icon("search-plus"), color = "red")
      }
    })
    
    output$imageryFormat <- renderValueBox({
      valueBox("PNG", "Format", icon = icon("file-image"), color = "yellow")
    })
  })
}
