# modules/route_visualization.R
# Route Preview with Clickable Sensor Data Points
# Shows Kia Niro EV camera and LiDAR data on click

# ============================================================================
# UI FUNCTION
# ============================================================================

route_visualization_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Interactive Route Map - Click Points for Sensor Data", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        leaflet::leafletOutput(ns("routeMap"), height = "600px")
      )
    ),
    
    fluidRow(
      box(
        title = "Selected Point Sensor Data",
        status = "success",
        solidHeader = TRUE,
        width = 6,
        
        uiOutput(ns("sensorDataDisplay"))
      ),
      
      box(
        title = "Route Statistics",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        
        uiOutput(ns("routeStats"))
      )
    ),
    
    fluidRow(
      box(
        title = "Map Controls",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        
        column(3,
               selectInput(ns("baseMap"), "Base Map:",
                           choices = c("OpenStreetMap" = "osm",
                                       "CartoDB" = "carto",
                                       "Satellite" = "satellite"),
                           selected = "osm")
        ),
        column(3,
               checkboxInput(ns("showTrajectory"), "Show Route Line", value = TRUE)
        ),
        column(3,
               checkboxInput(ns("showIncidents"), "Show Incidents", value = TRUE)
        ),
        column(3,
               selectInput(ns("colorBy"), "Color Points By:",
                           choices = c("AV Readiness" = "av_readiness",
                                       "Lane Visibility" = "lane_vis",
                                       "LiDAR Density" = "lidar_dens"),
                           selected = "av_readiness")
        )
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

route_visualization_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    selected_scenario <- reactive({
      req(api_manager$selected_scenario)
      api_manager$selected_scenario
    })
    
    # Store clicked point data
    clicked_point <- reactiveVal(NULL)
    
    output$routeMap <- leaflet::renderLeaflet({
      s <- selected_scenario()
      req(s, s$trajectories)
      
      # Extract trajectory data
      lats <- sapply(s$trajectories, function(t) t$lat %||% NA)
      lons <- sapply(s$trajectories, function(t) t$lon %||% NA)
      
      # Extract Kia Niro sensor data
      lane_vis <- sapply(s$trajectories, function(t) t$lane_visibility %||% 5)
      lidar_dens <- sapply(s$trajectories, function(t) t$lidar_point_density %||% 500)
      av_status <- sapply(s$trajectories, function(t) t$av_readiness_status %||% "AMBER")
      av_scores <- sapply(s$trajectories, function(t) t$av_readiness_score %||% 5)
      
      valid <- !is.na(lats) & !is.na(lons)
      lats <- lats[valid]
      lons <- lons[valid]
      lane_vis <- lane_vis[valid]
      lidar_dens <- lidar_dens[valid]
      av_status <- av_status[valid]
      av_scores <- av_scores[valid]
      
      # Color points based on selection
      if (input$colorBy == "av_readiness") {
        colors <- ifelse(av_status == "GREEN", "#28a745",
                         ifelse(av_status == "AMBER", "#ffc107", "#dc3545"))
      } else if (input$colorBy == "lane_vis") {
        colors <- ifelse(lane_vis >= 8, "#28a745",
                         ifelse(lane_vis >= 5, "#ffc107", "#dc3545"))
      } else {  # lidar_dens
        colors <- ifelse(lidar_dens >= 700, "#28a745",
                         ifelse(lidar_dens >= 400, "#ffc107", "#dc3545"))
      }
      
      # Create map
      m <- leaflet::leaflet() %>%
        leaflet::setView(lng = mean(lons), lat = mean(lats), zoom = 10)
      
      # Base map
      if (input$baseMap == "osm") {
        m <- m %>% leaflet::addTiles()
      } else if (input$baseMap == "carto") {
        m <- m %>% leaflet::addProviderTiles("CartoDB.Positron")
      } else {
        m <- m %>% leaflet::addProviderTiles("Esri.WorldImagery")
      }
      
      # Route line
      if (input$showTrajectory) {
        m <- m %>% leaflet::addPolylines(
          lng = lons, lat = lats,
          color = "#008A82", weight = 4, opacity = 0.7
        )
      }
      
      # Clickable markers with sensor data
      for (i in seq_along(lats)) {
        traj <- s$trajectories[[which(valid)[i]]]
        
        # Build detailed popup
        popup_html <- paste0(
          "<div style='min-width:250px;'>",
          "<h4 style='margin:0 0 10px 0; color:#008A82;'>📍 Point ", i, "</h4>",
          "<hr style='margin:5px 0;'>",
          
          "<b>🚗 Kia Niro EV Sensors:</b><br>",
          "<table style='width:100%; font-size:12px;'>",
          "<tr><td>📷 Lane Visibility:</td><td><b>", traj$lane_visibility, "/10</b></td></tr>",
          "<tr><td>📷 Sign Detection:</td><td><b>", round(traj$sign_detection_confidence * 100, 1), "%</b></td></tr>",
          "<tr><td>📡 LiDAR Density:</td><td><b>", round(traj$lidar_point_density, 0), " pts/m²</b></td></tr>",
          "<tr><td>📡 LiDAR Confidence:</td><td><b>", round(traj$lidar_detection_confidence * 100, 1), "%</b></td></tr>",
          "</table>",
          
          "<hr style='margin:5px 0;'>",
          "<b>🎯 AV Readiness:</b> <span style='color:", 
          ifelse(traj$av_readiness_status == "GREEN", "#28a745",
                 ifelse(traj$av_readiness_status == "AMBER", "#ffc107", "#dc3545")),
          "; font-weight:bold; font-size:14px;'>", traj$av_readiness_status, "</span><br>",
          "<b>Score:</b> ", traj$av_readiness_score, "/10<br>",
          
          "<hr style='margin:5px 0;'>",
          "<b>🛣️ Road Type:</b> ", traj$road_type %||% "unknown", "<br>",
          "<b>⚡ Speed:</b> ", traj$speed, " km/h<br>",
          "<b>📍 GPS:</b> ", round(traj$lat, 5), ", ", round(traj$lon, 5),
          "</div>"
        )
        
        m <- m %>% leaflet::addCircleMarkers(
          lng = lons[i], lat = lats[i],
          radius = 6, 
          color = colors[i], 
          fillColor = colors[i],
          fill = TRUE,
          fillOpacity = 0.8, 
          stroke = TRUE, 
          weight = 2,
          opacity = 1,
          popup = popup_html,
          layerId = paste0("point_", i)
        )
      }
      
      # Incidents
      if (input$showIncidents && length(s$incidents) > 0) {
        inc_lats <- sapply(s$incidents, function(i) i$lat)
        inc_lons <- sapply(s$incidents, function(i) i$lon)
        inc_types <- sapply(s$incidents, function(i) i$type %||% "Unknown")
        
        m <- m %>% leaflet::addMarkers(
          lng = inc_lons, lat = inc_lats,
          popup = paste0("<b>⚠️ Incident:</b> ", inc_types),
          icon = leaflet::makeIcon(
            iconUrl = "https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png",
            iconWidth = 25, iconHeight = 41
          )
        )
      }
      
      m
    })
    
    # Display sensor data for selected point
    output$sensorDataDisplay <- renderUI({
      s <- selected_scenario()
      req(s, s$trajectories)
      
      if (length(s$trajectories) == 0) {
        return(tags$p("No trajectory data available", style = "color: #999;"))
      }
      
      # Show first point by default or clicked point
      traj <- s$trajectories[[1]]
      
      tagList(
        tags$div(style = "background: #f8f9fa; padding: 15px; border-radius: 5px;",
                 tags$h5("📷 Camera Sensor", style = "margin-top: 0; color: #007bff;"),
                 tags$table(style = "width: 100%; font-size: 14px;",
                            tags$tr(
                              tags$td("Lane Marking Visibility:"),
                              tags$td(tags$strong(traj$lane_visibility %||% "N/A", "/10"), style = "text-align: right;")
                            ),
                            tags$tr(
                              tags$td("Sign Detection Confidence:"),
                              tags$td(tags$strong(round((traj$sign_detection_confidence %||% 0) * 100, 1), "%"), style = "text-align: right;")
                            )
                 ),
                 
                 tags$hr(),
                 
                 tags$h5("📡 LiDAR Sensor", style = "color: #28a745;"),
                 tags$table(style = "width: 100%; font-size: 14px;",
                            tags$tr(
                              tags$td("Point Cloud Density:"),
                              tags$td(tags$strong(round(traj$lidar_point_density %||% 0, 0), " pts/m²"), style = "text-align: right;")
                            ),
                            tags$tr(
                              tags$td("Detection Confidence:"),
                              tags$td(tags$strong(round((traj$lidar_detection_confidence %||% 0) * 100, 1), "%"), style = "text-align: right;")
                            )
                 ),
                 
                 tags$hr(),
                 
                 tags$h5("🎯 AV Readiness", style = "color: #6c757d;"),
                 tags$div(
                   tags$span("Status: "),
                   tags$span(traj$av_readiness_status %||% "N/A", 
                             style = paste0("font-weight: bold; font-size: 16px; color: ",
                                            ifelse((traj$av_readiness_status %||% "AMBER") == "GREEN", "#28a745",
                                                   ifelse((traj$av_readiness_status %||% "AMBER") == "AMBER", "#ffc107", "#dc3545")), ";")),
                   tags$br(),
                   tags$span("Score: "),
                   tags$strong(traj$av_readiness_score %||% "N/A", "/10")
                 )
        ),
        
        tags$div(style = "margin-top: 15px; padding: 10px; background: #e7f3ff; border-radius: 5px;",
                 tags$p(style = "margin: 0; font-size: 12px; color: #0056b3;",
                        icon("info-circle"), " Click any point on the map to see its sensor data"
                 )
        )
      )
    })
    
    output$routeStats <- renderUI({
      s <- selected_scenario()
      req(s)
      
      # Calculate average sensor metrics
      avg_lane_vis <- mean(sapply(s$trajectories, function(t) t$lane_visibility %||% 0), na.rm = TRUE)
      avg_lidar_dens <- mean(sapply(s$trajectories, function(t) t$lidar_point_density %||% 0), na.rm = TRUE)
      
      # Count statuses
      statuses <- sapply(s$trajectories, function(t) t$av_readiness_status %||% "AMBER")
      green_pct <- sum(statuses == "GREEN") / length(statuses) * 100
      amber_pct <- sum(statuses == "AMBER") / length(statuses) * 100
      red_pct <- sum(statuses == "RED") / length(statuses) * 100
      
      tagList(
        fluidRow(
          column(4, 
                 div(class = "small-box", style = "background: #28a745; color: white; padding: 15px; border-radius: 5px;",
                     div(style = "font-size: 24px; font-weight: bold;", round(green_pct, 0), "%"),
                     div(style = "font-size: 14px;", "GREEN (Ready)")
                 )
          ),
          column(4,
                 div(class = "small-box", style = "background: #ffc107; color: white; padding: 15px; border-radius: 5px;",
                     div(style = "font-size: 24px; font-weight: bold;", round(amber_pct, 0), "%"),
                     div(style = "font-size: 14px;", "AMBER (Caution)")
                 )
          ),
          column(4,
                 div(class = "small-box", style = "background: #dc3545; color: white; padding: 15px; border-radius: 5px;",
                     div(style = "font-size: 24px; font-weight: bold;", round(red_pct, 0), "%"),
                     div(style = "font-size: 14px;", "RED (Not Ready)")
                 )
          )
        ),
        tags$hr(),
        fluidRow(
          column(6,
                 tags$p(tags$strong("📷 Avg Lane Visibility:"), round(avg_lane_vis, 1), "/10")
          ),
          column(6,
                 tags$p(tags$strong("📡 Avg LiDAR Density:"), round(avg_lidar_dens, 0), " pts/m²")
          )
        ),
        fluidRow(
          column(6,
                 tags$p(tags$strong("🚗 Vehicle:"), s$vehicle %||% "Kia Niro EV")
          ),
          column(6,
                 tags$p(tags$strong("🛣️ Distance:"), s$metadata$distance_km %||% "N/A", " km")
          )
        )
      )
    })
  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x