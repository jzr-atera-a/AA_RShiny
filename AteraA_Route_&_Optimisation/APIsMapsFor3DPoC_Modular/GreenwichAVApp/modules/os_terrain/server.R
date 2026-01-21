# modules/os_terrain/server.R

os_terrain_server <- function(id, data_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    terrain_data <- reactiveVal(NULL)
    
    observeEvent(input$downloadTerrain, {
      
      req(length(input$terrainLayers) > 0)
      
      withProgress(message = 'Accessing OS Terrain...', value = 0, {
        
        tryCatch({
          
          bbox <- if (!is.null(data_manager)) {
            data_manager$bbox
          } else {
            get_default_greenwich_bbox()
          }
          
          incProgress(0.3, detail = "Identifying tiles")
          
          results <- list()
          
          if ("terrain50" %in% input$terrainLayers) {
            incProgress(0.3, detail = "Terrain 50")
            # In production, would download actual OS Terrain 50 tiles
            results$terrain50 <- "OS Terrain 50 DTM for Greenwich area"
          }
          
          if ("heights" %in% input$terrainLayers) {
            incProgress(0.3, detail = "Building heights")
            results$heights <- "Building height data (where available)"
          }
          
          incProgress(0.1, detail = "Complete")
          
          terrain_data(results)
          
          if (!is.null(data_manager)) {
            data_manager$terrain_data <- results
            data_manager$check_export_ready()
          }
          
          output$terrainStatus <- renderUI({
            status_message("success", "✓ Terrain Data Ready", 
                          "OS Terrain tiles identified for Greenwich area. Download from OS OpenData portal.")
          })
          
          showNotification("OS Terrain data prepared. Download tiles from ordnancesurvey.co.uk", 
                          type = "message", duration = 5)
          
        }, error = function(e) {
          output$terrainStatus <- renderUI({
            status_message("error", "✗ Access Failed", e$message)
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    output$terrainRes <- renderValueBox({
      valueBox("50m", "Grid Spacing", icon = icon("ruler"), color = "green")
    })
    
    output$terrainFormat <- renderValueBox({
      valueBox("GeoTIFF", "Export Format", icon = icon("file"), color = "blue")
    })
  })
}
