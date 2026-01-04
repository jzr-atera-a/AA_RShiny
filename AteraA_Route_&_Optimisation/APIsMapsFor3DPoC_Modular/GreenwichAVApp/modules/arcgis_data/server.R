# modules/arcgis_data/server.R

arcgis_data_server <- function(id, data_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    arcgis_data <- reactiveVal(NULL)
    
    observeEvent(input$downloadArcGIS, {
      
      req(length(input$arcgisLayers) > 0)
      
      withProgress(message = 'Accessing ArcGIS Living Atlas...', value = 0, {
        
        tryCatch({
          
          # Get bbox from data manager
          bbox <- if (!is.null(data_manager)) {
            data_manager$bbox
          } else {
            get_default_greenwich_bbox()
          }
          
          incProgress(0.3, detail = "Preparing request")
          
          results <- list()
          
          # Note: This is a simplified implementation
          # Full implementation would require proper ArcGIS REST API calls
          
          if ("buildings" %in% input$arcgisLayers) {
            incProgress(0.2, detail = "Buildings layer")
            results$buildings_status <- "Available (requires API implementation)"
          }
          
          if ("imagery" %in% input$arcgisLayers) {
            incProgress(0.2, detail = "Imagery layer")
            results$imagery_status <- "Available (requires API implementation)"
          }
          
          if ("elevation" %in% input$arcgisLayers) {
            incProgress(0.2, detail = "Elevation layer")
            results$elevation_status <- "Available (requires API implementation)"
          }
          
          incProgress(0.1, detail = "Complete")
          
          arcgis_data(results)
          
          if (!is.null(data_manager)) {
            data_manager$arcgis_data <- results
          }
          
          output$arcgisStatus <- renderUI({
            status_message("success", "✓ Request Prepared", 
                          "ArcGIS Living Atlas layers identified. Full API integration required for download.")
          })
          
          showNotification("ArcGIS layers prepared. This module requires API key and full implementation.", 
                          type = "message", duration = 5)
          
        }, error = function(e) {
          output$arcgisStatus <- renderUI({
            status_message("error", "✗ Request Failed", e$message)
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    output$arcgisBuildings <- renderValueBox({
      valueBox("Ready", "Buildings", icon = icon("building"), color = "aqua")
    })
    
    output$arcgisImagery <- renderValueBox({
      valueBox("Ready", "Imagery", icon = icon("image"), color = "blue")
    })
    
    output$arcgisElevation <- renderValueBox({
      valueBox("Ready", "Elevation", icon = icon("mountain"), color = "green")
    })
  })
}
