# modules/road_network/server.R - WORKING VERSION

road_network_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    network_data <- reactiveVal(NULL)
    network_loaded <- reactiveVal(FALSE)
    
    observeEvent(input$downloadNetwork, {
      
      if (is.null(input$placeName) || input$placeName == "") {
        output$networkStatus <- renderUI({
          div(class = "status-error", h5("✗ Invalid"), p("Enter location"))
        })
        return()
      }
      
      withProgress(message = 'Downloading...', value = 0, {
        
        tryCatch({
          
          incProgress(0.2, detail = "Getting bbox")
          bbox <- getbb(input$placeName)
          if (is.null(bbox)) stop("Location not found")
          
          incProgress(0.4, detail = "Downloading")
          highway_query <- opq(bbox, timeout = 60) %>%
            add_osm_feature(key = "highway", 
                           value = c("motorway", "trunk", "primary", "secondary", "tertiary", "residential")) %>%
            osmdata_sf()
          
          if (is.null(highway_query$osm_lines) || nrow(highway_query$osm_lines) == 0) stop("No roads")
          
          incProgress(0.6, detail = "Processing")
          edges <- highway_query$osm_lines
          edges <- edges[st_geometry_type(edges$geometry) == "LINESTRING", ]
          if (nrow(edges) == 0) stop("No valid roads")
          
          edges <- st_transform(edges, 4326)
          keep_cols <- intersect(c("osm_id", "name", "highway", "geometry"), names(edges))
          edges <- edges[, keep_cols]
          
          incProgress(0.7, detail = "Creating graph")
          graph <- tryCatch({
            weight_streetnet(edges, wt_profile = "motorcar", type_col = "highway", id_col = "osm_id")
          }, error = function(e) {
            el <- do.call(rbind, lapply(1:min(nrow(edges), 500), function(i) {
              lc <- st_coordinates(edges[i,])
              if (nrow(lc) < 2) return(NULL)
              do.call(rbind, lapply(1:(nrow(lc)-1), function(j) {
                data.frame(from_lon = lc[j,1], from_lat = lc[j,2], 
                          to_lon = lc[j+1,1], to_lat = lc[j+1,2],
                          d = sqrt((lc[j+1,1] - lc[j,1])^2 + (lc[j+1,2] - lc[j,2])^2) * 111320)
              }))
            }))
            el$d_weighted <- el$d
            el
          })
          
          if (is.null(graph) || nrow(graph) == 0) stop("Graph failed")
          
          incProgress(0.9, detail = "Done")
          
          network_data(list(graph = graph, nodes = highway_query$osm_points, 
                           edges = edges, bbox = bbox, location = input$placeName))
          network_loaded(TRUE)
          if (!is.null(api_manager)) api_manager$network_data <- network_data()
          
          output$networkStatus <- renderUI({
            div(class = "status-success", h5("✓ Success"), 
                p(strong("Location:"), input$placeName),
                p(strong("Edges:"), format(nrow(graph), big.mark = ",")))
          })
          showNotification("Network ready!", type = "message", duration = 3)
          
        }, error = function(e) {
          network_loaded(FALSE)
          output$networkStatus <- renderUI({
            div(class = "status-error", h5("✗ Failed"), p(as.character(e$message)))
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    output$networkStats <- renderText({
      net <- network_data()
      if (is.null(net)) return("No network")
      paste("Location:", net$location, "\nNodes:", format(nrow(net$nodes), big.mark = ","))
    })
    
    output$networkNodes <- renderValueBox({
      net <- network_data()
      valueBox(if(is.null(net)) "N/A" else format(nrow(net$nodes), big.mark = ","), 
               "Nodes", icon = icon("circle"), color = "blue")
    })
    
    output$networkEdges <- renderValueBox({
      net <- network_data()
      valueBox(if(is.null(net)) "N/A" else format(nrow(net$edges), big.mark = ","), 
               "Edges", icon = icon("road"), color = "green")
    })
    
    output$networkStatus_box <- renderValueBox({
      valueBox(if(network_loaded()) "Ready" else "Not Loaded", "Status", 
               icon = icon(if(network_loaded()) "check-circle" else "times-circle"), 
               color = if(network_loaded()) "green" else "red")
    })
    
    output$networkLoaded <- reactive({ network_loaded() })
    outputOptions(output, "networkLoaded", suspendWhenHidden = FALSE)
  })
}
