# modules/preview_validation/server.R

preview_validation_server <- function(id, data_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    export_ready <- reactiveVal(FALSE)
    export_path <- reactiveVal(NULL)
    
    # Value boxes for each data source
    output$osmStatus <- renderValueBox({
      has_data <- !is.null(data_manager$osm_data)
      valueBox(if(has_data) "✓" else "✗", "OSM", 
              icon = icon("map"), 
              color = if(has_data) "green" else "red")
    })
    
    output$arcgisStatus <- renderValueBox({
      has_data <- !is.null(data_manager$arcgis_data)
      valueBox(if(has_data) "✓" else "✗", "ArcGIS", 
              icon = icon("globe"), 
              color = if(has_data) "aqua" else "red")
    })
    
    output$terrainStatus <- renderValueBox({
      has_data <- !is.null(data_manager$terrain_data)
      valueBox(if(has_data) "✓" else "✗", "Terrain", 
              icon = icon("mountain"), 
              color = if(has_data) "green" else "red")
    })
    
    output$lidarStatus <- renderValueBox({
      has_data <- !is.null(data_manager$lidar_data)
      valueBox(if(has_data) "✓" else "✗", "LIDAR", 
              icon = icon("layer-group"), 
              color = if(has_data) "blue" else "red")
    })
    
    output$imageryStatus <- renderValueBox({
      has_data <- !is.null(data_manager$imagery_data)
      valueBox(if(has_data) "✓" else "✗", "Imagery", 
              icon = icon("satellite"), 
              color = if(has_data) "yellow" else "red")
    })
    
    output$exportStatus <- renderValueBox({
      is_ready <- data_manager$check_export_ready()
      valueBox(if(is_ready) "Ready" else "Pending", "Export", 
              icon = icon(if(is_ready) "check-circle" else "clock"), 
              color = if(is_ready) "green" else "orange")
    })
    
    # Validation summary
    output$validationSummary <- renderUI({
      layers <- c(
        OSM = !is.null(data_manager$osm_data),
        ArcGIS = !is.null(data_manager$arcgis_data),
        Terrain = !is.null(data_manager$terrain_data),
        LIDAR = !is.null(data_manager$lidar_data),
        Imagery = !is.null(data_manager$imagery_data)
      )
      
      count <- sum(layers)
      
      if (count >= 2) {
        div(class = "status-success",
            h5("✓ Validation Passed"),
            p(paste(count, "of 5 data layers available")),
            p("Minimum requirements met for export"))
      } else {
        div(class = "status-warning",
            h5("⚠ Incomplete"),
            p(paste(count, "of 5 data layers available")),
            p("Download at least 2 layers to enable export"))
      }
    })
    
    # Area information
    output$areaInfo <- renderText({
      if (!is.null(data_manager$bbox)) {
        area_calc <- calculate_area_m2(data_manager$bbox)
        
        paste0(
          "Location: ", data_manager$location_name, "\n",
          "Bounding Box: ", format_bbox_display(data_manager$bbox), "\n\n",
          "Dimensions:\n",
          "  Width: ", round(area_calc$width, 1), " meters\n",
          "  Height: ", round(area_calc$height, 1), " meters\n",
          "  Area: ", format(round(area_calc$area), big.mark = ","), " m²\n",
          "  Area: ", round(area_calc$area / 10000, 2), " hectares"
        )
      } else {
        "No area defined"
      }
    })
    
    # Preview map
    output$previewMap <- renderLeaflet({
      leaflet() %>%
        addTiles() %>%
        setView(lng = 0.0027, lat = 51.503, zoom = 16)
    })
    
    observe({
      bbox <- data_manager$bbox
      osm <- data_manager$osm_data
      
      if (!is.null(bbox)) {
        
        map <- leaflet() %>%
          addTiles() %>%
          fitBounds(lng1 = bbox[1], lat1 = bbox[2], 
                   lng2 = bbox[3], lat2 = bbox[4])
        
        # Add bounding box rectangle
        map <- map %>%
          addRectangles(
            lng1 = bbox[1], lat1 = bbox[2],
            lng2 = bbox[3], lat2 = bbox[4],
            color = "purple", weight = 3, fillOpacity = 0.05,
            label = "Target Area (200m × 200m)"
          )
        
        # Add OSM data if available
        if (!is.null(osm)) {
          if (!is.null(osm$buildings)) {
            map <- map %>%
              addPolygons(data = osm$buildings, 
                         color = "red", weight = 2, fillOpacity = 0.3,
                         group = "Buildings",
                         popup = ~name)
          }
          
          if (!is.null(osm$roads)) {
            map <- map %>%
              addPolylines(data = osm$roads, 
                          color = "blue", weight = 3, opacity = 0.7,
                          group = "Roads",
                          popup = ~name)
          }
          
          if (!is.null(osm$poi)) {
            map <- map %>%
              addCircleMarkers(data = osm$poi, 
                             color = "green", radius = 5, fillOpacity = 0.8,
                             group = "POI",
                             popup = ~name)
          }
        }
        
        leafletProxy("previewMap", session) %>%
          clearShapes() %>%
          clearMarkers() %>%
          addTiles() %>%
          fitBounds(lng1 = bbox[1], lat1 = bbox[2], 
                   lng2 = bbox[3], lat2 = bbox[4]) %>%
          addRectangles(
            lng1 = bbox[1], lat1 = bbox[2],
            lng2 = bbox[3], lat2 = bbox[4],
            color = "purple", weight = 3, fillOpacity = 0.05,
            label = "Target Area"
          )
        
        if (!is.null(osm)) {
          if (!is.null(osm$buildings)) {
            leafletProxy("previewMap", session) %>%
              addPolygons(data = osm$buildings, 
                         color = "red", weight = 2, fillOpacity = 0.3,
                         popup = ~name)
          }
          
          if (!is.null(osm$roads)) {
            leafletProxy("previewMap", session) %>%
              addPolylines(data = osm$roads, 
                          color = "blue", weight = 3, opacity = 0.7,
                          popup = ~name)
          }
          
          if (!is.null(osm$poi)) {
            leafletProxy("previewMap", session) %>%
              addCircleMarkers(data = osm$poi, 
                             color = "green", radius = 5, fillOpacity = 0.8,
                             popup = ~name)
          }
        }
      }
    })
    
    # Export all data
    observeEvent(input$exportAll, {
      
      if (!data_manager$check_export_ready()) {
        showNotification("Please download at least 2 data layers before exporting", 
                        type = "warning", duration = 5)
        return()
      }
      
      withProgress(message = 'Creating export bundle...', value = 0, {
        
        tryCatch({
          
          # Create export directory
          incProgress(0.2, detail = "Creating directory")
          export_dir <- create_export_dir("Greenwich_AV_Data")
          
          # Save metadata
          incProgress(0.2, detail = "Saving metadata")
          save_metadata(data_manager, export_dir)
          
          # Export OSM data
          if ("osm" %in% input$exportLayers && !is.null(data_manager$osm_data)) {
            incProgress(0.2, detail = "Exporting OSM data")
            osm <- data_manager$osm_data
            
            if (!is.null(osm$buildings)) {
              st_write(osm$buildings, 
                      file.path(export_dir, "buildings.geojson"), 
                      driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
            }
            if (!is.null(osm$roads)) {
              st_write(osm$roads, 
                      file.path(export_dir, "roads.geojson"), 
                      driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
            }
            if (!is.null(osm$poi)) {
              st_write(osm$poi, 
                      file.path(export_dir, "poi.geojson"), 
                      driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
            }
          }
          
          # Create README
          incProgress(0.2, detail = "Creating README")
          readme_text <- paste0(
            "Greenwich AV Project Data Export\n",
            "=================================\n\n",
            "Export Date: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n",
            "Location: ", data_manager$location_name, "\n",
            "Area: 200m × 200m\n\n",
            "Files:\n",
            "- metadata.json: Export metadata and coordinate system info\n",
            "- buildings.geojson: Building footprints from OpenStreetMap\n",
            "- roads.geojson: Road network from OpenStreetMap\n",
            "- poi.geojson: Points of interest from OpenStreetMap\n\n",
            "Unity Import:\n",
            "1. Use Mapbox SDK for Unity or similar GIS plugin\n",
            "2. Import GeoJSON files as georeferenced data\n",
            "3. Convert to 3D meshes in Unity\n\n",
            "Coordinate System: WGS84 (EPSG:4326)\n"
          )
          writeLines(readme_text, file.path(export_dir, "README.txt"))
          
          incProgress(0.2, detail = "Complete")
          
          export_path(export_dir)
          export_ready(TRUE)
          
          output$exportInfo <- renderUI({
            status_message("success", "✓ Export Complete", 
                          paste("Data bundle created:", basename(export_dir)))
          })
          
          showNotification("Export complete! Click 'Download ZIP Bundle' to save.", 
                          type = "message", duration = 5)
          
        }, error = function(e) {
          output$exportInfo <- renderUI({
            status_message("error", "✗ Export Failed", e$message)
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    # Download bundle
    output$downloadBundle <- downloadHandler(
      filename = function() {
        paste0("Greenwich_AV_Data_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip")
      },
      content = function(file) {
        withProgress(message = 'Creating ZIP file...', value = 0.5, {
          dir_path <- export_path()
          if (!is.null(dir_path) && dir.exists(dir_path)) {
            files <- list.files(dir_path, full.names = TRUE, recursive = TRUE)
            zip(file, files, flags = "-r9Xj")
          }
        })
      }
    )
    
    output$exportReady <- reactive({ export_ready() })
    outputOptions(output, "exportReady", suspendWhenHidden = FALSE)
  })
}
