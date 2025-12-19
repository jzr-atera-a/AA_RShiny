# EV Route Optimizer Dashboard with BigQuery Integration
# Required Libraries
library(shiny)
library(shinydashboard)
library(leaflet)
library(osmdata)
library(sf)
library(dplyr)
library(bigrquery)
library(htmltools)
library(tmaptools)
library(dodgr)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "EV Route Optimizer"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("BigQuery Setup", tabName = "connection", icon = icon("database")),
      menuItem("Road Network", tabName = "network", icon = icon("road")),
      menuItem("Route Optimizer", tabName = "optimizer", icon = icon("route")),
      menuItem("Route Map", tabName = "map", icon = icon("map"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* Main body background with teal gradient */
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          min-height: 100vh;
        }
        
        /* Sidebar styling with teal gradient */
        .sidebar, .main-sidebar {
          background: linear-gradient(180deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
        }
        
        .sidebar .sidebar-menu > li > a {
          color: #ffffff !important;
          border-left: 3px solid transparent;
          transition: all 0.3s ease;
        }
        
        .sidebar .sidebar-menu > li.active > a,
        .sidebar .sidebar-menu > li:hover > a {
          background: rgba(255, 255, 255, 0.15) !important;
          border-left: 3px solid #00A39A !important;
          color: #ffffff !important;
        }
        
        /* Header/navbar with matching gradient */
        .main-header, .main-header .navbar {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          border-bottom: none;
        }
        
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          font-weight: 600;
        }
        
        /* Box styling with enhanced gradients */
        .box {
          background: rgba(255, 255, 255, 0.98) !important;
          border: none !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(0, 44, 60, 0.2) !important;
          margin-bottom: 20px;
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        
        .box:hover {
          transform: translateY(-2px);
          box-shadow: 0 12px 35px rgba(0, 44, 60, 0.3) !important;
        }
        
        /* Box headers with gradients */
        .box-header {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          color: white !important;
          border-radius: 12px 12px 0 0 !important;
          padding: 15px 20px;
          border-bottom: none !important;
        }
        
        .box-header > .box-title {
          color: #ffffff !important;
          font-weight: 600;
          font-size: 16px;
        }
        
        .box-body {
          background-color: #ffffff !important;
          color: #2c3e50 !important;
          padding: 20px;
          border-radius: 0 0 12px 12px;
        }
        
        /* Status message styling */
        .connection-success {
          background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
          color: #155724 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #00A39A !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(0, 163, 154, 0.2);
        }
        
        .connection-error {
          background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
          color: #721c24 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #e74c3c !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(231, 76, 60, 0.2);
        }
        
        .connection-warning {
          background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%) !important;
          color: #856404 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #f39c12 !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(243, 156, 18, 0.2);
        }
        
        /* Input and form styling */
        .form-control {
          border-radius: 8px !important;
          border: 2px solid #ddd !important;
          transition: border-color 0.3s ease, box-shadow 0.3s ease;
        }
        
        .form-control:focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 3px rgba(0, 138, 130, 0.1) !important;
        }
        
        /* Button styling with gradients */
        .btn-primary {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          padding: 10px 20px;
          font-weight: 600;
          transition: transform 0.2s ease, box-shadow 0.2s ease;
          color: white !important;
        }
        
        .btn-primary:hover {
          background: linear-gradient(135deg, #006b63 0%, #007d75 100%) !important;
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(0, 138, 130, 0.3);
        }
        
        .btn-success {
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
        }
        
        .btn-warning {
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
        }
        
        .btn-info {
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
        }
        
        /* Value boxes */
        .small-box {
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15) !important;
          transition: transform 0.2s ease;
        }
        
        .small-box:hover {
          transform: translateY(-3px);
        }
        
        .small-box.bg-blue { 
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important; 
        }
        
        .small-box.bg-green { 
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important; 
        }
        
        .small-box.bg-yellow { 
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important; 
        }
        
        .small-box.bg-red { 
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important; 
        }
        
        /* Leaflet map styling */
        .leaflet-container {
          border-radius: 12px;
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }
        
        /* Progress indicator */
        .progress {
          height: 25px;
          border-radius: 8px;
          background: #ecf0f1;
        }
        
        .progress-bar {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border-radius: 8px;
        }
      "))
    ),
    
    tabItems(
      # BigQuery Connection Tab
      tabItem(tabName = "connection",
              fluidRow(
                box(
                  title = "BigQuery Authentication", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  
                  h4("Upload Service Account Key"),
                  p("Please upload your Google Cloud service account JSON key file to authenticate with BigQuery."),
                  
                  fileInput("jsonKey", "Select JSON Key File:",
                            accept = c(".json"),
                            buttonLabel = "Browse...",
                            placeholder = "No file selected"),
                  
                  textInput("projectId", "Google Cloud Project ID:", 
                            value = "atera-2",
                            placeholder = "Enter your GCP project ID"),
                  
                  textInput("datasetId", "Dataset ID:", 
                            value = "EVs_Infrastructure",
                            placeholder = "Enter dataset ID"),
                  
                  textInput("tableId", "Table ID:", 
                            value = "Charge_Points_UK_EVs",
                            placeholder = "Enter table ID"),
                  
                  br(),
                  
                  actionButton("testBQConnection", "Test Connection", 
                               class = "btn btn-primary", width = "48%"),
                  actionButton("clearAuth", "Clear Authentication", 
                               class = "btn btn-warning", width = "48%"),
                  
                  br(), br(),
                  uiOutput("bqConnectionStatus")
                ),
                
                box(
                  title = "Connection Information", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  
                  h5("Setup Instructions:"),
                  tags$ol(
                    tags$li("Create a service account in Google Cloud Console"),
                    tags$li("Download the JSON key file"),
                    tags$li("Grant BigQuery Data Viewer role to the service account"),
                    tags$li("Upload the JSON key file using the button above"),
                    tags$li("Enter your project, dataset, and table information")
                  ),
                  
                  br(),
                  h5("Current Configuration:"),
                  verbatimTextOutput("bqConfigInfo"),
                  
                  br(),
                  h5("Data Preview:"),
                  verbatimTextOutput("bqDataPreview")
                )
              )
      ),
      
      # Road Network Tab - UPDATED WITH MILTON KEYNES
      tabItem(tabName = "network",
              fluidRow(
                box(
                  title = "Road Network Configuration", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  
                  textInput("placeName", "Location Name:", 
                            value = "Milton Keynes, UK",
                            placeholder = "e.g., Milton Keynes, UK"),
                  
                  p(style = "color: #7f8c8d; font-size: 12px;", 
                    "Enter a city or region name to download the road network from Atera Analytics DBs."),
                  
                  br(),
                  
                  actionButton("downloadNetwork", "Download Road Network", 
                               class = "btn btn-success", width = "100%"),
                  
                  br(), br(),
                  
                  uiOutput("networkStatus"),
                  
                  br(),
                  
                  conditionalPanel(
                    condition = "output.networkLoaded",
                    div(
                      h5("Network Statistics:"),
                      verbatimTextOutput("networkStats")
                    )
                  )
                ),
                
                box(
                  title = "Network Information", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 8,
                  
                  h5("About Road Networks:"),
                  p("The road network is downloaded from Atera Analytics DBs and converted into a routing graph. 
                    This graph will be used to calculate optimal routes through EV charging stations."),
                  
                  tags$ul(
                    tags$li("Network Type: Drive (suitable for vehicles)"),
                    tags$li("Data Source: Atera Analytics DBs"),
                    tags$li("Routing Engine: dodgr (Distances On Directed Graphs)"),
                    tags$li("Path Finding: Shortest path algorithm with length weighting")
                  ),
                  
                  br(),
                  
                  valueBoxOutput("networkNodes", width = 4),
                  valueBoxOutput("networkEdges", width = 4),
                  valueBoxOutput("networkStatus_box", width = 4)
                )
              )
      ),
      
      # Route Optimizer Tab - UPDATED WITH MILTON KEYNES LOCATIONS
      tabItem(tabName = "optimizer",
              fluidRow(
                box(
                  title = "Route Selection", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  
                  h4("Select Origin and Destination"),
                  
                  selectInput("originAddress", "Origin:",
                              choices = c(
                                "Bletchley, Milton Keynes, UK",
                                "Wolverton, Milton Keynes, UK",
                                "Stony Stratford, Milton Keynes, UK",
                                "Newport Pagnell, Milton Keynes, UK"
                              ),
                              selected = "Bletchley, Milton Keynes, UK"),
                  
                  selectInput("destinationAddress", "Destination:",
                              choices = c(
                                "Woburn Sands, Milton Keynes, UK",
                                "Bow Brickhill, Milton Keynes, UK",
                                "Wavendon, Milton Keynes, UK",
                                "Shenley Brook End, Milton Keynes, UK"
                              ),
                              selected = "Woburn Sands, Milton Keynes, UK"),
                  
                  br(),
                  
                  numericInput("numChargingPoints", "Number of Nearest Charging Points to Consider:",
                               value = 3, min = 1, max = 10, step = 1),
                  
                  p(style = "color: #7f8c8d; font-size: 12px;", 
                    "The system will find the nearest charging points and calculate the optimal route."),
                  
                  br(),
                  
                  actionButton("calculateRoute", "Calculate Optimal Route", 
                               class = "btn btn-success", 
                               icon = icon("route"),
                               width = "100%"),
                  
                  br(), br(),
                  
                  uiOutput("routeStatus")
                ),
                
                box(
                  title = "Route Information", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  
                  conditionalPanel(
                    condition = "output.routeCalculated",
                    h5("Route Summary:"),
                    verbatimTextOutput("routeSummary"),
                    
                    br(),
                    h5("Nearest Charging Points:"),
                    verbatimTextOutput("chargingPointsInfo"),
                    
                    br(),
                    actionButton("viewMap", "View Route Map", 
                                 class = "btn btn-info", 
                                 icon = icon("map"),
                                 width = "100%")
                  ),
                  
                  conditionalPanel(
                    condition = "!output.routeCalculated",
                    div(style = "text-align: center; padding: 50px;",
                        icon("info-circle", style = "font-size: 48px; color: #95a5a6;"),
                        h4("No Route Calculated", style = "color: #7f8c8d; margin-top: 20px;"),
                        p("Select origin and destination, then click 'Calculate Optimal Route' to begin.", 
                          style = "color: #95a5a6;")
                    )
                  )
                )
              )
      ),
      
      # Route Map Tab - UPDATED WITH MILTON KEYNES COORDINATES
      tabItem(tabName = "map",
              fluidRow(
                box(
                  title = "Interactive Route Map", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  leafletOutput("routeMap", height = "600px"),
                  
                  br(),
                  
                  div(style = "text-align: center;",
                      h5("Map Legend:"),
                      p(HTML("<span style='color: green;'>●</span> Start Point | 
                             <span style='color: orange;'>●</span> Charging Points | 
                             <span style='color: red;'>●</span> End Point | 
                             <span style='color: blue;'>―</span> Optimal Route"))
                  )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Helper function to validate and clean geometries
  clean_linestrings <- function(sf_object) {
    sf_object <- sf_object[st_geometry_type(sf_object) == "LINESTRING", ]
    valid_geoms <- st_is_valid(sf_object)
    sf_object <- sf_object[valid_geoms, ]
    sf_object <- sf_object[!st_is_empty(sf_object), ]
    return(sf_object)
  }
  
  # Reactive values
  values <- reactiveValues(
    bq_authenticated = FALSE,
    bq_project = NULL,
    charging_points = NULL,
    road_network = NULL,
    network_loaded = FALSE,
    route_calculated = FALSE,
    route_data = NULL,
    nearest_points = NULL,
    start_coords = NULL,
    end_coords = NULL
  )
  
  # Helper function to validate numeric
  is_valid_float <- function(x) {
    !is.na(suppressWarnings(as.numeric(x)))
  }
  
  # BigQuery Authentication
  observeEvent(input$testBQConnection, {
    if (is.null(input$jsonKey)) {
      output$bqConnectionStatus <- renderUI({
        div(class = "connection-error", 
            h5("Authentication Failed"), 
            p("Please upload a JSON key file."))
      })
      return()
    }
    
    tryCatch({
      bq_auth(path = input$jsonKey$datapath)
      
      sql <- sprintf("SELECT * FROM `%s.%s.%s` LIMIT 10",
                     input$projectId,
                     input$datasetId,
                     input$tableId)
      
      test_query <- bq_project_query(input$projectId, sql)
      test_data <- bq_table_download(test_query)
      
      values$bq_authenticated <- TRUE
      values$bq_project <- input$projectId
      
      output$bqConnectionStatus <- renderUI({
        div(class = "connection-success",
            h5("Connection Successful"),
            p(paste("Connected to project:", input$projectId)),
            p(paste("Dataset:", input$datasetId)),
            p(paste("Table:", input$tableId)))
      })
      
      showNotification("BigQuery connection established!", type = "message")
      
      full_sql <- sprintf("SELECT * FROM `%s.%s.%s`",
                          input$projectId,
                          input$datasetId,
                          input$tableId)
      
      full_query <- bq_project_query(input$projectId, full_sql)
      df_charging <- bq_table_download(full_query)
      
      df_charging <- df_charging %>%
        filter(!is.na(latitude) & !is.na(longitude)) %>%
        filter(is_valid_float(latitude) & is_valid_float(longitude)) %>%
        mutate(
          latitude = as.numeric(latitude),
          longitude = as.numeric(longitude)
        )
      
      values$charging_points <- st_as_sf(
        df_charging,
        coords = c("longitude", "latitude"),
        crs = 4326
      )
      
      showNotification(paste("Loaded", nrow(values$charging_points), "charging points"), 
                       type = "message")
      
    }, error = function(e) {
      values$bq_authenticated <- FALSE
      
      output$bqConnectionStatus <- renderUI({
        div(class = "connection-error",
            h5("Connection Failed"),
            p("Error:", e$message))
      })
      showNotification(paste("Connection failed:", e$message), type = "error")
    })
  })
  
  # Clear authentication
  observeEvent(input$clearAuth, {
    values$bq_authenticated <- FALSE
    values$bq_project <- NULL
    values$charging_points <- NULL
    
    output$bqConnectionStatus <- renderUI({
      div(class = "connection-success",
          h5("Authentication Cleared"),
          p("Please upload a new JSON key file to reconnect."))
    })
    
    showNotification("Authentication cleared", type = "message")
  })
  
  # BigQuery config info
  output$bqConfigInfo <- renderText({
    if (!values$bq_authenticated) {
      return("Not connected")
    }
    
    paste(
      paste("Project ID:", input$projectId),
      paste("Dataset:", input$datasetId),
      paste("Table:", input$tableId),
      paste("Status: Connected"),
      sep = "\n"
    )
  })
  
  # BigQuery data preview
  output$bqDataPreview <- renderText({
    if (is.null(values$charging_points)) {
      return("No data loaded")
    }
    
    paste(
      paste("Total Charging Points:", nrow(values$charging_points)),
      paste("Columns:", ncol(values$charging_points)),
      paste("CRS:", st_crs(values$charging_points)$input),
      sep = "\n"
    )
  })
  
  # Download Road Network
  observeEvent(input$downloadNetwork, {
    if (input$placeName == "") {
      output$networkStatus <- renderUI({
        div(class = "connection-error",
            p("Please enter a location name."))
      })
      return()
    }
    
    withProgress(message = 'Downloading road network...', value = 0, {
      
      tryCatch({
        incProgress(0.2, detail = "Getting location bounding box")
        
        bbox <- getbb(input$placeName)
        
        if (is.null(bbox) || length(bbox) == 0) {
          stop("Location not found. Try 'Milton Keynes, UK' or 'London, UK'")
        }
        
        incProgress(0.4, detail = "Downloading data from Atera Analytics DBs")
        
        highway_query <- opq(bbox = bbox, timeout = 60) %>%
          add_osm_feature(key = "highway", 
                          value = c("motorway", "trunk", "primary", 
                                    "secondary", "tertiary", "residential",
                                    "unclassified", "service",
                                    "motorway_link", "trunk_link",
                                    "primary_link", "secondary_link")) %>%
          osmdata_sf()
        
        if (is.null(highway_query$osm_lines) || nrow(highway_query$osm_lines) == 0) {
          stop("No road data found for this location")
        }
        
        incProgress(0.6, detail = "Processing road geometries")
        
        edges <- highway_query$osm_lines
        
        edges <- edges %>%
          filter(st_geometry_type(geometry) == "LINESTRING")
        
        if (nrow(edges) == 0) {
          stop("No valid road linestrings found")
        }
        
        edges <- st_transform(edges, 4326)
        
        edges <- edges %>%
          filter(!is.na(st_dimension(geometry))) %>%
          select(osm_id, name, highway, geometry)
        
        incProgress(0.7, detail = "Creating routing graph")
        
        graph <- tryCatch({
          dodgr::weight_streetnet(
            edges, 
            wt_profile = "motorcar",
            type_col = "highway",
            id_col = "osm_id",
            keep_cols = c("name")
          )
        }, error = function(e) {
          message("Trying alternative graph creation method...")
          
          edge_list <- data.frame()
          
          for (i in 1:nrow(edges)) {
            line_coords <- st_coordinates(edges[i,])
            
            if (nrow(line_coords) >= 2) {
              for (j in 1:(nrow(line_coords)-1)) {
                edge_list <- rbind(edge_list, data.frame(
                  from_id = paste0("node_", i, "_", j),
                  to_id = paste0("node_", i, "_", j+1),
                  from_lon = line_coords[j, "X"],
                  from_lat = line_coords[j, "Y"],
                  to_lon = line_coords[j+1, "X"],
                  to_lat = line_coords[j+1, "Y"],
                  d = sqrt((line_coords[j+1, "X"] - line_coords[j, "X"])^2 + 
                             (line_coords[j+1, "Y"] - line_coords[j, "Y"])^2) * 111320,
                  highway = as.character(edges$highway[i])
                ))
              }
            }
          }
          
          edge_list$d_weighted <- edge_list$d
          
          return(edge_list)
        })
        
        if (is.null(graph) || nrow(graph) == 0) {
          stop("Could not create routing graph from network data")
        }
        
        incProgress(0.9, detail = "Finalizing network")
        
        values$road_network <- list(
          graph = graph,
          nodes = highway_query$osm_points,
          edges = edges,
          bbox = bbox
        )
        
        values$network_loaded <- TRUE
        
        output$networkStatus <- renderUI({
          div(class = "connection-success",
              h5("✓ Network Downloaded Successfully"),
              p(strong("Location:"), input$placeName),
              p(strong("Graph edges:"), format(nrow(graph), big.mark = ",")),
              p(strong("Road segments:"), format(nrow(edges), big.mark = ",")))
        })
        
        showNotification("Road network ready!", type = "message", duration = 3)
        
      }, error = function(e) {
        values$network_loaded <- FALSE
        
        output$networkStatus <- renderUI({
          div(class = "connection-error",
              h5("✗ Download Failed"),
              p(strong("Error:"), as.character(e$message)),
              hr(),
              h5("Troubleshooting:"),
              tags$ul(
                tags$li("Try a different location format:"),
                tags$ul(
                  tags$li(tags$code("Milton Keynes, UK")),
                  tags$li(tags$code("London, UK")),
                  tags$li(tags$code("Oxford, England"))
                ),
                tags$li("Check your internet connection"),
                tags$li("Try a larger city if the area is too small")
              ))
        })
        showNotification(paste("Failed:", e$message), type = "error", duration = 5)
      })
    })
  })
  
  # Network statistics
  output$networkStats <- renderText({
    if (!values$network_loaded) {
      return("No network loaded")
    }
    
    paste(
      paste("Nodes:", nrow(values$road_network$nodes)),
      paste("Edges:", nrow(values$road_network$edges)),
      paste("Graph rows:", nrow(values$road_network$graph)),
      sep = "\n"
    )
  })
  
  # Network value boxes
  output$networkNodes <- renderValueBox({
    if (!values$network_loaded) {
      valueBox(
        value = "N/A",
        subtitle = "Network Nodes",
        icon = icon("circle"),
        color = "blue"
      )
    } else {
      valueBox(
        value = format(nrow(values$road_network$nodes), big.mark = ","),
        subtitle = "Network Nodes",
        icon = icon("circle"),
        color = "blue"
      )
    }
  })
  
  output$networkEdges <- renderValueBox({
    if (!values$network_loaded) {
      valueBox(
        value = "N/A",
        subtitle = "Network Edges",
        icon = icon("road"),
        color = "green"
      )
    } else {
      valueBox(
        value = format(nrow(values$road_network$edges), big.mark = ","),
        subtitle = "Network Edges",
        icon = icon("road"),
        color = "green"
      )
    }
  })
  
  output$networkStatus_box <- renderValueBox({
    if (!values$network_loaded) {
      valueBox(
        value = "Not Loaded",
        subtitle = "Network Status",
        icon = icon("times-circle"),
        color = "red"
      )
    } else {
      valueBox(
        value = "Ready",
        subtitle = "Network Status",
        icon = icon("check-circle"),
        color = "green"
      )
    }
  })
  
  # Network loaded output for conditional panel
  output$networkLoaded <- reactive({
    values$network_loaded
  })
  outputOptions(output, "networkLoaded", suspendWhenHidden = FALSE)
  
  # Calculate Route
  observeEvent(input$calculateRoute, {
    if (!values$bq_authenticated) {
      output$routeStatus <- renderUI({
        div(class = "connection-error",
            p("Please connect to BigQuery first."))
      })
      return()
    }
    
    if (!values$network_loaded) {
      output$routeStatus <- renderUI({
        div(class = "connection-error",
            p("Please download the road network first."))
      })
      return()
    }
    
    withProgress(message = 'Calculating optimal route...', value = 0, {
      
      tryCatch({
        incProgress(0.2, detail = "Geocoding addresses")
        
        origin_coords <- geocode_OSM(input$originAddress, as.sf = TRUE)
        dest_coords <- geocode_OSM(input$destinationAddress, as.sf = TRUE)
        
        if (is.null(origin_coords) || is.null(dest_coords)) {
          stop("Unable to geocode addresses")
        }
        
        start_point <- st_geometry(origin_coords)[[1]]
        end_point <- st_geometry(dest_coords)[[1]]
        
        values$start_coords <- st_coordinates(start_point)
        values$end_coords <- st_coordinates(end_point)
        
        incProgress(0.4, detail = "Finding nearest charging points")
        
        charging_proj <- st_transform(values$charging_points, crs = 27700)
        start_proj <- st_transform(st_sfc(start_point, crs = 4326), crs = 27700)
        
        distances <- st_distance(charging_proj, start_proj)
        values$charging_points$distance <- as.numeric(distances)
        
        nearest <- values$charging_points %>%
          arrange(distance) %>%
          head(input$numChargingPoints)
        
        values$nearest_points <- nearest
        
        incProgress(0.6, detail = "Calculating routes")
        
        graph <- values$road_network$graph
        
        shortest_path <- NULL
        shortest_length <- Inf
        best_charge_point <- NULL
        
        for (i in 1:nrow(nearest)) {
          charge_coords <- st_coordinates(st_geometry(nearest[i,]))
          
          dist_to_charge <- dodgr_dists(
            graph,
            from = values$start_coords,
            to = charge_coords
          )[1]
          
          dist_from_charge <- dodgr_dists(
            graph,
            from = charge_coords,
            to = values$end_coords
          )[1]
          
          total_dist <- dist_to_charge + dist_from_charge
          
          if (!is.na(total_dist) && total_dist < shortest_length) {
            shortest_length <- total_dist
            best_charge_point <- i
          }
        }
        
        incProgress(0.9, detail = "Finalizing route")
        
        values$route_data <- list(
          length = shortest_length,
          charge_point_index = best_charge_point
        )
        
        values$route_calculated <- TRUE
        
        output$routeStatus <- renderUI({
          div(class = "connection-success",
              h5("Route Calculated Successfully"),
              p(paste("Total Distance:", round(shortest_length/1000, 2), "km")))
        })
        
        showNotification("Route calculated successfully!", type = "message")
        
      }, error = function(e) {
        values$route_calculated <- FALSE
        
        output$routeStatus <- renderUI({
          div(class = "connection-error",
              h5("Calculation Failed"),
              p("Error:", e$message))
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
  })
  
  # Route summary
  output$routeSummary <- renderText({
    if (!values$route_calculated || is.null(values$route_data)) {
      return("No route calculated")
    }
    
    paste(
      paste("Origin:", input$originAddress),
      paste("Destination:", input$destinationAddress),
      paste("Total Distance:", round(values$route_data$length/1000, 2), "km"),
      paste("Charging Points Considered:", input$numChargingPoints),
      sep = "\n"
    )
  })
  
  # Charging points info
  output$chargingPointsInfo <- renderText({
    if (is.null(values$nearest_points)) {
      return("No charging points found")
    }
    
    info <- ""
    for (i in 1:nrow(values$nearest_points)) {
      point <- values$nearest_points[i,]
      coords <- st_coordinates(st_geometry(point))
      
      info <- paste0(info, 
                     sprintf("%d. Distance: %.2f km (%.2f, %.2f)\n", 
                             i, 
                             point$distance/1000,
                             coords[1],
                             coords[2]))
    }
    
    return(info)
  })
  
  # Route calculated output for conditional panel
  output$routeCalculated <- reactive({
    values$route_calculated
  })
  outputOptions(output, "routeCalculated", suspendWhenHidden = FALSE)
  
  # Switch to map tab when view map button clicked
  observeEvent(input$viewMap, {
    updateTabItems(session, "sidebar", "map")
  })
  
  # Render route map - UPDATED WITH MILTON KEYNES COORDINATES
  output$routeMap <- renderLeaflet({
    if (!values$route_calculated) {
      # Show empty map with message - CENTERED ON MILTON KEYNES
      leaflet() %>%
        addTiles() %>%
        setView(lng = -0.7594, lat = 52.0406, zoom = 13) %>%
        addControl(
          html = "<div style='padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);'>
                  <h4 style='margin: 0; color: #7f8c8d;'>No Route Calculated</h4>
                  <p style='margin: 5px 0 0 0; color: #95a5a6;'>Please calculate a route first.</p>
                </div>",
          position = "topright"
        )
    } else {
      tryCatch({
        map <- leaflet() %>%
          addTiles() %>%
          setView(lng = values$start_coords[1], 
                  lat = values$start_coords[2], 
                  zoom = 13)
        
        map <- map %>%
          addAwesomeMarkers(
            lng = values$start_coords[1],
            lat = values$start_coords[2],
            popup = paste("<b>Start:</b><br>", input$originAddress),
            icon = awesomeIcons(
              icon = "play",
              iconColor = "white",
              markerColor = "green",
              library = "fa"
            )
          )
        
        map <- map %>%
          addAwesomeMarkers(
            lng = values$end_coords[1],
            lat = values$end_coords[2],
            popup = paste("<b>End:</b><br>", input$destinationAddress),
            icon = awesomeIcons(
              icon = "stop",
              iconColor = "white",
              markerColor = "red",
              library = "fa"
            )
          )
        
        if (!is.null(values$nearest_points)) {
          for (i in 1:nrow(values$nearest_points)) {
            point <- values$nearest_points[i,]
            coords <- st_coordinates(st_geometry(point))
            
            is_selected <- (i == values$route_data$charge_point_index)
            
            popup_text <- sprintf(
              "<b>Charging Point %d</b><br>Distance from origin: %.2f km<br>%s",
              i,
              point$distance/1000,
              if(is_selected) "<b style='color: #00A39A;'>✓ Selected for route</b>" else ""
            )
            
            map <- map %>%
              addCircleMarkers(
                lng = coords[1],
                lat = coords[2],
                radius = if(is_selected) 10 else 7,
                color = if(is_selected) "#00A39A" else "#f39c12",
                fillColor = if(is_selected) "#00A39A" else "#f39c12",
                fillOpacity = if(is_selected) 0.9 else 0.7,
                weight = if(is_selected) 3 else 2,
                popup = popup_text
              )
          }
        }
        
        if (!is.null(values$route_data$charge_point_index)) {
          charge_point <- values$nearest_points[values$route_data$charge_point_index,]
          charge_coords <- st_coordinates(st_geometry(charge_point))
          
          graph <- values$road_network$graph
          
          withProgress(message = 'Drawing route on map...', value = 0, {
            
            tryCatch({
              incProgress(0.3, detail = "Computing route geometry")
              
              flows_to_charge <- data.frame(
                from_x = values$start_coords[1],
                from_y = values$start_coords[2],
                to_x = charge_coords[1],
                to_y = charge_coords[2],
                flow = 1
              )
              
              graph_with_flow_1 <- dodgr::dodgr_flows_aggregate(
                graph = graph,
                from = flows_to_charge[, c("from_x", "from_y")],
                to = flows_to_charge[, c("to_x", "to_y")],
                flows = flows_to_charge$flow
              )
              
              route_edges_1 <- graph_with_flow_1[graph_with_flow_1$flow > 0, ]
              
              if (nrow(route_edges_1) > 0) {
                incProgress(0.5, detail = "Drawing first route segment")
                
                for (i in 1:nrow(route_edges_1)) {
                  edge <- route_edges_1[i, ]
                  
                  map <- map %>%
                    addPolylines(
                      lng = c(edge$from_lon, edge$to_lon),
                      lat = c(edge$from_lat, edge$to_lat),
                      color = "#3498db",
                      weight = 6,
                      opacity = 0.9,
                      group = "route_to_charge"
                    )
                }
                
                showNotification("Route to charging point drawn!", type = "message", duration = 2)
              } else {
                message("No route edges found for first segment")
              }
              
              incProgress(0.7, detail = "Computing return route")
              
              flows_from_charge <- data.frame(
                from_x = charge_coords[1],
                from_y = charge_coords[2],
                to_x = values$end_coords[1],
                to_y = values$end_coords[2],
                flow = 1
              )
              
              graph_with_flow_2 <- dodgr::dodgr_flows_aggregate(
                graph = graph,
                from = flows_from_charge[, c("from_x", "from_y")],
                to = flows_from_charge[, c("to_x", "to_y")],
                flows = flows_from_charge$flow
              )
              
              route_edges_2 <- graph_with_flow_2[graph_with_flow_2$flow > 0, ]
              
              if (nrow(route_edges_2) > 0) {
                incProgress(0.9, detail = "Drawing second route segment")
                
                for (i in 1:nrow(route_edges_2)) {
                  edge <- route_edges_2[i, ]
                  
                  map <- map %>%
                    addPolylines(
                      lng = c(edge$from_lon, edge$to_lon),
                      lat = c(edge$from_lat, edge$to_lat),
                      color = "#2980b9",
                      weight = 6,
                      opacity = 0.9,
                      group = "route_from_charge"
                    )
                }
                
                showNotification("Complete route drawn!", type = "message", duration = 3)
              } else {
                message("No route edges found for second segment")
              }
              
              incProgress(1, detail = "Complete")
              
            }, error = function(e) {
              showNotification(paste("Could not draw detailed route:", e$message), 
                               type = "warning", duration = 5)
              message("Route drawing error: ", e$message)
              
              map <<- map %>%
                addPolylines(
                  lng = c(values$start_coords[1], charge_coords[1]),
                  lat = c(values$start_coords[2], charge_coords[2]),
                  color = "#3498db",
                  weight = 4,
                  opacity = 0.6,
                  dashArray = "10, 10",
                  popup = "Approximate route to charging point"
                ) %>%
                addPolylines(
                  lng = c(charge_coords[1], values$end_coords[1]),
                  lat = c(charge_coords[2], values$end_coords[2]),
                  color = "#2980b9",
                  weight = 4,
                  opacity = 0.6,
                  dashArray = "10, 10",
                  popup = "Approximate route from charging point"
                )
            })
          })
        }
        
        map <- map %>%
          addControl(
            html = sprintf(
              "<div style='padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);'>
              <h4 style='margin: 0 0 10px 0; color: #2c3e50;'>Route Summary</h4>
              <p style='margin: 5px 0;'><span style='color: green;'>●</span> <b>Start:</b> %s</p>
              <p style='margin: 5px 0;'><span style='color: #00A39A;'>●</span> <b>Charging Point:</b> %.2f km from start</p>
              <p style='margin: 5px 0;'><span style='color: red;'>●</span> <b>End:</b> %s</p>
              <p style='margin: 5px 0;'><span style='color: #3498db;'>━</span> <b>Total Distance:</b> %.2f km</p>
              <hr style='margin: 10px 0;'>
              <p style='margin: 5px 0; font-size: 12px;'><b>Map Legend:</b></p>
              <p style='margin: 3px 0; font-size: 11px;'>● Start Point | ● Charging Points | ● End Point</p>
              <p style='margin: 3px 0; font-size: 11px;'><span style='color: #3498db;'>━━━</span> Route to charge | <span style='color: #2980b9;'>━━━</span> Route to destination</p>
            </div>",
              input$originAddress,
              if(!is.null(values$nearest_points) && !is.null(values$route_data$charge_point_index)) 
                values$nearest_points[values$route_data$charge_point_index,]$distance/1000 else 0,
              input$destinationAddress,
              values$route_data$length/1000
            ),
            position = "topright"
          )
        
        map
        
      }, error = function(e) {
        message("Major error in map rendering: ", e$message)
        leaflet() %>%
          addTiles() %>%
          setView(lng = values$start_coords[1], lat = values$start_coords[2], zoom = 13) %>%
          addMarkers(lng = values$start_coords[1], lat = values$start_coords[2], 
                     popup = paste("<b>Start:</b>", input$originAddress)) %>%
          addMarkers(lng = values$end_coords[1], lat = values$end_coords[2], 
                     popup = paste("<b>End:</b>", input$destinationAddress)) %>%
          addControl(
            html = paste0("<div style='padding: 15px; background: #fff3cd; border-radius: 8px;'>
                          <h4 style='margin: 0; color: #856404;'>⚠ Unable to Display Route</h4>
                          <p style='margin: 5px 0;'>", e$message, "</p>
                          <p style='margin: 5px 0;'>Showing markers only.</p>
                        </div>"),
            position = "topright"
          )
      })
    }
  })
  
  # Session cleanup
  session$onSessionEnded(function() {
    values$road_network <- NULL
    values$charging_points <- NULL
  })
}

# Run the application
shinyApp(ui = ui, server = server)