# modules/lidar_data/server.R

lidar_data_server <- function(id, data_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    lidar_data <- reactiveVal(NULL)
    lidar_tiles <- reactiveVal(0)
    
    observeEvent(input$downloadLIDAR, {
      
      withProgress(message = 'Finding LIDAR tiles...', value = 0, {
        
        tryCatch({
          
          bbox <- if (!is.null(data_manager)) {
            data_manager$bbox
          } else {
            get_default_greenwich_bbox()
          }
          
          incProgress(0.3, detail = "Checking coverage")
          
          # Calculate area
          area_info <- calculate_area_m2(bbox)
          
          # Estimate tiles (LIDAR tiles are typically 1km x 1km)
          tiles_needed <- ceiling(area_info$width / 1000) * ceiling(area_info$height / 1000)
          lidar_tiles(tiles_needed)
          
          incProgress(0.4, detail = "Identifying tiles")
          
          results <- list(
            resolution = input$lidarResolution,
            tiles = tiles_needed,
            area = area_info,
            tile_ids = paste0("TQ", 37:38, 78:79)  # Example tile IDs for Greenwich
          )
          
          incProgress(0.3, detail = "Complete")
          
          lidar_data(results)
          
          if (!is.null(data_manager)) {
            data_manager$lidar_data <- results
            data_manager$check_export_ready()
          }
          
          output$lidarStatus <- renderUI({
            status_message("success", "✓ LIDAR Tiles Identified", 
                          paste("Found", tiles_needed, "tile(s) covering the Greenwich area. 
                                Download from Environment Agency data portal."))
          })
          
          showNotification(paste("Need", tiles_needed, "LIDAR tile(s). Visit environment.data.gov.uk"), 
                          type = "message", duration = 5)
          
        }, error = function(e) {
          output$lidarStatus <- renderUI({
            status_message("error", "✗ Search Failed", e$message)
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    output$lidarTiles <- renderValueBox({
      tiles <- lidar_tiles()
      valueBox(tiles, "Tiles Needed", icon = icon("th"), color = "aqua")
    })
    
    output$lidarRes <- renderValueBox({
      valueBox("1-2m", "Resolution", icon = icon("ruler-combined"), color = "green")
    })
    
    output$lidarSize <- renderValueBox({
      tiles <- lidar_tiles()
      size_mb <- tiles * 50  # Approximate size per tile
      valueBox(paste0("~", size_mb, "MB"), "Est. Size", icon = icon("hdd"), color = "yellow")
    })
  })
}
