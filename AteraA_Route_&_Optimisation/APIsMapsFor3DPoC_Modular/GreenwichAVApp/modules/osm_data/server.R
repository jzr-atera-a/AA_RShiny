# modules/osm_data/server.R

osm_data_server <- function(id, data_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    osm_data <- reactiveVal(NULL)
    osm_loaded <- reactiveVal(FALSE)
    current_bbox <- reactiveVal(NULL)
    
    # Use location name to get bbox
    observeEvent(input$useLocation, {
      req(input$location)
      
      withProgress(message = 'Looking up location...', value = 0.5, {
        bbox <- get_bbox_from_place(input$location)
        
        if (!is.null(bbox)) {
          # Update bbox input field
          bbox_string <- paste(bbox[2], bbox[1], bbox[4], bbox[3], sep = ", ")
          updateTextInput(session, "bbox_coords", value = bbox_string)
          
          showNotification("Location found! Bounding box updated.", 
                          type = "message", duration = 3)
        } else {
          showNotification("Location not found. Using default bbox.", 
                          type = "warning", duration = 5)
        }
      })
    })
    
    # Download OSM data
    observeEvent(input$downloadOSM, {
      
      req(input$bbox_coords)
      req(length(input$dataTypes) > 0)
      
      withProgress(message = 'Downloading OSM data...', value = 0, {
        
        tryCatch({
          
          # Parse bbox
          incProgress(0.1, detail = "Parsing coordinates")
          bbox_parsed <- parse_coordinates(input$bbox_coords)
          
          if (is.null(bbox_parsed)) {
            stop("Invalid bounding box coordinates")
          }
          
          bbox_vector <- c(bbox_parsed$xmin, bbox_parsed$ymin, 
                          bbox_parsed$xmax, bbox_parsed$ymax)
          current_bbox(bbox_vector)
          
          # Update data manager
          if (!is.null(data_manager)) {
            data_manager$update_bbox(bbox_vector)
            data_manager$update_location(input$location)
          }
          
          # Build OSM query
          incProgress(0.2, detail = "Building query")
          query <- opq(bbox = bbox_vector, timeout = 120)
          
          # Download data layers
          results <- list()
          
          # Buildings
          if ("building" %in% input$dataTypes) {
            incProgress(0.1, detail = "Downloading buildings")
            buildings_query <- query %>%
              add_osm_feature(key = "building") %>%
              osmdata_sf()
            
            if (!is.null(buildings_query$osm_polygons) && 
                nrow(buildings_query$osm_polygons) > 0) {
              results$buildings <- buildings_query$osm_polygons
            }
          }
          
          # Roads
          if ("highway" %in% input$dataTypes) {
            incProgress(0.2, detail = "Downloading roads")
            roads_query <- query %>%
              add_osm_feature(key = "highway") %>%
              osmdata_sf()
            
            if (!is.null(roads_query$osm_lines) && 
                nrow(roads_query$osm_lines) > 0) {
              results$roads <- roads_query$osm_lines
            }
          }
          
          # POI
          if ("poi" %in% input$dataTypes) {
            incProgress(0.2, detail = "Downloading POI")
            poi_query <- query %>%
              add_osm_feature(key = "amenity") %>%
              osmdata_sf()
            
            if (!is.null(poi_query$osm_points) && 
                nrow(poi_query$osm_points) > 0) {
              results$poi <- poi_query$osm_points
            }
          }
          
          incProgress(0.3, detail = "Processing data")
          
          # Store results
          osm_data(results)
          osm_loaded(TRUE)
          
          # Update data manager
          if (!is.null(data_manager)) {
            data_manager$osm_data <- results
            data_manager$check_export_ready()
          }
          
          output$osmStatus <- renderUI({
            status_message("success", "✓ Download Complete", 
                          paste("Retrieved", length(results), "data layers from OpenStreetMap"))
          })
          
          showNotification("OSM data downloaded successfully!", 
                          type = "message", duration = 3)
          
        }, error = function(e) {
          osm_loaded(FALSE)
          output$osmStatus <- renderUI({
            status_message("error", "✗ Download Failed", e$message)
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    # Value boxes
    output$buildingCount <- renderValueBox({
      data <- osm_data()
      count <- if (!is.null(data$buildings)) nrow(data$buildings) else 0
      valueBox(format(count, big.mark = ","), "Buildings", 
              icon = icon("building"), color = "red")
    })
    
    output$roadCount <- renderValueBox({
      data <- osm_data()
      count <- if (!is.null(data$roads)) nrow(data$roads) else 0
      valueBox(format(count, big.mark = ","), "Roads", 
              icon = icon("road"), color = "blue")
    })
    
    output$poiCount <- renderValueBox({
      data <- osm_data()
      count <- if (!is.null(data$poi)) nrow(data$poi) else 0
      valueBox(format(count, big.mark = ","), "POI", 
              icon = icon("map-pin"), color = "green")
    })
    
    # Preview map
    output$previewMap <- renderLeaflet({
      leaflet() %>%
        addTiles() %>%
        setView(lng = 0.0027, lat = 51.503, zoom = 16)
    })
    
    observe({
      data <- osm_data()
      bbox <- current_bbox()
      
      if (!is.null(data) && !is.null(bbox)) {
        
        map <- leaflet() %>%
          addTiles() %>%
          fitBounds(lng1 = bbox[1], lat1 = bbox[2], 
                   lng2 = bbox[3], lat2 = bbox[4])
        
        # Add buildings
        if (!is.null(data$buildings)) {
          map <- map %>%
            addPolygons(data = data$buildings, 
                       color = "red", weight = 2, fillOpacity = 0.3,
                       popup = ~name)
        }
        
        # Add roads
        if (!is.null(data$roads)) {
          map <- map %>%
            addPolylines(data = data$roads, 
                        color = "blue", weight = 3, opacity = 0.7,
                        popup = ~name)
        }
        
        # Add POI
        if (!is.null(data$poi)) {
          map <- map %>%
            addCircleMarkers(data = data$poi, 
                           color = "green", radius = 5, fillOpacity = 0.8,
                           popup = ~name)
        }
        
        leafletProxy("previewMap", session) %>%
          clearShapes() %>%
          clearMarkers() %>%
          addTiles() %>%
          fitBounds(lng1 = bbox[1], lat1 = bbox[2], 
                   lng2 = bbox[3], lat2 = bbox[4])
        
        # Re-add layers
        if (!is.null(data$buildings)) {
          leafletProxy("previewMap", session) %>%
            addPolygons(data = data$buildings, 
                       color = "red", weight = 2, fillOpacity = 0.3,
                       popup = ~name)
        }
        
        if (!is.null(data$roads)) {
          leafletProxy("previewMap", session) %>%
            addPolylines(data = data$roads, 
                        color = "blue", weight = 3, opacity = 0.7,
                        popup = ~name)
        }
        
        if (!is.null(data$poi)) {
          leafletProxy("previewMap", session) %>%
            addCircleMarkers(data = data$poi, 
                           color = "green", radius = 5, fillOpacity = 0.8,
                           popup = ~name)
        }
      }
    })
    
    # Download handler
    output$downloadGeoJSON <- downloadHandler(
      filename = function() {
        paste0("OSM_Greenwich_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip")
      },
      content = function(file) {
        withProgress(message = 'Creating GeoJSON files...', value = 0, {
          
          temp_dir <- tempdir()
          data <- osm_data()
          
          files_created <- c()
          
          if (!is.null(data$buildings)) {
            incProgress(0.3, detail = "Buildings")
            buildings_file <- file.path(temp_dir, "buildings.geojson")
            st_write(data$buildings, buildings_file, driver = "GeoJSON", 
                    delete_dsn = TRUE, quiet = TRUE)
            files_created <- c(files_created, buildings_file)
          }
          
          if (!is.null(data$roads)) {
            incProgress(0.3, detail = "Roads")
            roads_file <- file.path(temp_dir, "roads.geojson")
            st_write(data$roads, roads_file, driver = "GeoJSON", 
                    delete_dsn = TRUE, quiet = TRUE)
            files_created <- c(files_created, roads_file)
          }
          
          if (!is.null(data$poi)) {
            incProgress(0.3, detail = "POI")
            poi_file <- file.path(temp_dir, "poi.geojson")
            st_write(data$poi, poi_file, driver = "GeoJSON", 
                    delete_dsn = TRUE, quiet = TRUE)
            files_created <- c(files_created, poi_file)
          }
          
          incProgress(0.1, detail = "Creating zip")
          zip(file, files_created, flags = "-r9Xj")
        })
      }
    )
    
    output$osmLoaded <- reactive({ osm_loaded() })
    outputOptions(output, "osmLoaded", suspendWhenHidden = FALSE)
  })
}
