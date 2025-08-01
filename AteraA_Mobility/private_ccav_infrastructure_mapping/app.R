library(shiny)
library(shinydashboard)
library(sf)
library(leaflet)
library(dplyr)
library(DT)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Dover to Milton Keynes Route Infrastructure"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Route Mapper", tabName = "mapper", icon = icon("map")),
      menuItem("Data Summary", tabName = "summary", icon = icon("table")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # First tab - Route Mapper
      tabItem(tabName = "mapper",
              fluidRow(
                box(
                  title = "Route Controls", status = "primary", solidHeader = TRUE,
                  width = 4, height = "550px",
                  
                  h4("Highway Types:"),
                  checkboxGroupInput("highway_types", 
                                     NULL,
                                     choices = list(
                                       "Motorways (M-roads)" = "motorway",
                                       "Primary roads (A-roads)" = "primary", 
                                       "Secondary roads" = "secondary",
                                       "Trunk roads" = "trunk",
                                       "Motorway links" = "motorway_link",
                                       "Primary links" = "primary_link"
                                     ),
                                     selected = c("motorway", "primary", "trunk")),
                  
                  h4("Infrastructure:"),
                  checkboxInput("show_junctions", "Show Junctions", value = TRUE),
                  checkboxInput("show_traffic_signals", "Show Traffic Signals", value = FALSE),
                  
                  hr(),
                  h4("Actions:"),
                  
                  # Action buttons with proper spacing
                  div(style = "margin-bottom: 10px;",
                      actionButton("load_data", "1. Load Local Data", 
                                   icon = icon("database"),
                                   class = "btn-primary btn-block")
                  ),
                  
                  div(style = "margin-bottom: 10px;",
                      actionButton("render_map", "2. Render Route Map", 
                                   icon = icon("map"),
                                   class = "btn-info btn-block")
                  ),
                  
                  div(style = "margin-bottom: 10px;",
                      downloadButton("download_infrastructure", "3. Download Infrastructure CSV",
                                     icon = icon("download"),
                                     class = "btn-success btn-block")
                  ),
                  
                  div(style = "margin-bottom: 10px;",
                      downloadButton("download_highways", "4. Download Highway Data CSV",
                                     icon = icon("road"),
                                     class = "btn-warning btn-block")
                  ),
                  
                  div(style = "margin-bottom: 10px;",
                      downloadButton("download_filtered", "5. Download Current Selection",
                                     icon = icon("filter"),
                                     class = "btn-secondary btn-block")
                  )
                ),
                
                box(
                  title = "Route Statistics", status = "info", solidHeader = TRUE,
                  width = 8, height = "550px",
                  verbatimTextOutput("route_stats")
                )
              ),
              
              fluidRow(
                box(
                  title = "Dover to Milton Keynes Route Map", status = "success", 
                  solidHeader = TRUE, width = 12,
                  leafletOutput("route_map", height = "600px")
                )
              )
      ),
      
      # Second tab - Data Summary
      tabItem(tabName = "summary",
              fluidRow(
                box(
                  title = "Downloaded Data Summary", status = "primary", 
                  solidHeader = TRUE, width = 6,
                  DT::dataTableOutput("data_summary_table")
                ),
                
                box(
                  title = "Data Files Status", status = "info", 
                  solidHeader = TRUE, width = 6,
                  verbatimTextOutput("file_status")
                )
              ),
              
              fluidRow(
                box(
                  title = "Dataset Statistics", status = "success", 
                  solidHeader = TRUE, width = 12,
                  plotOutput("data_size_plot", height = "400px")
                )
              )
      ),
      
      # Third tab - About
      tabItem(tabName = "about",
              fluidRow(
                box(
                  title = "About This Application", status = "primary", 
                  solidHeader = TRUE, width = 12,
                  
                  h3("Dover to Milton Keynes Route Infrastructure Mapper"),
                  
                  p("This Shiny application provides an interactive mapping tool for analyzing 
              road infrastructure along the route from Dover to Milton Keynes in the UK using 
              pre-downloaded OpenStreetMap data."),
                  
                  h4("Available Downloads:"),
                  tags$ul(
                    tags$li(strong("Infrastructure CSV:"), " All junctions and traffic signals with coordinates"),
                    tags$li(strong("Highway Data CSV:"), " Complete road network with attributes"),
                    tags$li(strong("Current Selection CSV:"), " Filtered data based on your current map selection")
                  )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Reactive values to store data
  values <- reactiveValues(
    highways_data = NULL,
    junctions_data = NULL,
    traffic_signals_data = NULL,
    data_loaded = FALSE,
    download_summary = NULL
  )
  
  # Load download summary on startup
  observe({
    tryCatch({
      summary_paths <- c(
        file.path("route_data", "download_summary.csv"),
        file.path("route_map", "download_summary.csv")
      )
      
      for (summary_path in summary_paths) {
        if (file.exists(summary_path)) {
          values$download_summary <- read.csv(summary_path, stringsAsFactors = FALSE)
          cat("✓ Loaded download summary from:", summary_path, "\n")
          break
        }
      }
    }, error = function(e) {
      cat("Could not load download summary:", e$message, "\n")
    })
  })
  
  # Load local data when button is pressed
  observeEvent(input$load_data, {
    
    withProgress(message = 'Loading data...', value = 0, {
      
      tryCatch({
        incProgress(0.1, detail = "Checking directories...")
        
        # Determine data directory
        if (dir.exists("route_data")) {
          data_dir <- "route_data"
        } else if (dir.exists("route_map")) {
          data_dir <- "route_map"
          showNotification("Using 'route_map' directory", type = "warning")
        } else {
          showNotification("Error: No data directory found!", type = "error", duration = 10)
          return()
        }
        
        cat("Using data directory:", data_dir, "\n")
        
        incProgress(0.2, detail = "Loading highways...")
        
        # Load highways
        highways_path <- file.path(data_dir, "all_highways_combined.gpkg")
        if (file.exists(highways_path)) {
          values$highways_data <- st_read(highways_path, quiet = TRUE)
          cat("✓ Loaded", nrow(values$highways_data), "highway segments\n")
        } else {
          showNotification("Highway file not found!", type = "error")
          return()
        }
        
        incProgress(0.4, detail = "Loading junctions...")
        
        # Load junctions
        junctions_path <- file.path(data_dir, "all_junctions_combined.gpkg")
        if (file.exists(junctions_path)) {
          values$junctions_data <- st_read(junctions_path, quiet = TRUE)
          cat("✓ Loaded", nrow(values$junctions_data), "junctions\n")
        }
        
        incProgress(0.3, detail = "Loading traffic signals...")
        
        # Load traffic signals
        signals_path <- file.path(data_dir, "traffic_signals.gpkg")
        if (file.exists(signals_path)) {
          values$traffic_signals_data <- st_read(signals_path, quiet = TRUE)
          cat("✓ Loaded", nrow(values$traffic_signals_data), "traffic signals\n")
        }
        
        values$data_loaded <- TRUE
        showNotification("Data loaded successfully!", type = "message", duration = 3)
        
      }, error = function(e) {
        showNotification(paste("Error loading data:", e$message), type = "error", duration = 10)
        cat("Error:", e$message, "\n")
      })
    })
  })
  
  # Render the base map
  output$route_map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = 0.5, lat = 51.4, zoom = 8) %>%
      addProviderTiles(providers$CartoDB.Positron)
  })
  
  # Render map when button is pressed
  observeEvent(input$render_map, {
    if (!values$data_loaded) {
      showNotification("Please load data first!", type = "warning", duration = 3)
      return()
    }
    
    cat("Starting map render...\n")
    
    withProgress(message = 'Rendering map...', value = 0, {
      
      incProgress(0.2, detail = "Clearing map...")
      
      leafletProxy("route_map") %>%
        clearShapes() %>%
        clearMarkers() %>%
        clearControls()
      
      incProgress(0.3, detail = "Adding highways...")
      
      # Filter and add highways
      if (length(input$highway_types) > 0 && !is.null(values$highways_data)) {
        
        filtered_highways <- values$highways_data %>%
          filter(road_type %in% input$highway_types)
        
        cat("Filtered highways:", nrow(filtered_highways), "segments\n")
        
        # Define colors
        road_colors <- c(
          "motorway" = "#0066CC", 
          "primary" = "#FF6600",
          "secondary" = "#FFCC00", 
          "trunk" = "#009900",
          "motorway_link" = "#0099FF",
          "primary_link" = "#FF9933"
        )
        
        # Add each road type
        for (road_type in unique(filtered_highways$road_type)) {
          if (road_type %in% names(road_colors)) {
            road_subset <- filtered_highways %>% filter(road_type == road_type)
            cat("Adding", nrow(road_subset), road_type, "roads\n")
            
            leafletProxy("route_map") %>%
              addPolylines(
                data = road_subset,
                color = road_colors[road_type],
                weight = if(road_type %in% c("motorway", "trunk")) 4 else 3,
                opacity = 0.8,
                popup = ~paste0("<b>", ifelse(is.na(name), "Unnamed", name), "</b><br>",
                                "Type: ", road_type, "<br>",
                                "Highway: ", highway)
              )
          }
        }
        
        incProgress(0.2, detail = "Adding legend...")
        
        # Add legend
        selected_colors <- road_colors[names(road_colors) %in% input$highway_types]
        if (length(selected_colors) > 0) {
          leafletProxy("route_map") %>%
            addLegend(
              position = "bottomright",
              colors = unname(selected_colors),
              labels = names(selected_colors),
              title = "Highway Types",
              opacity = 0.8
            )
        }
      }
      
      incProgress(0.2, detail = "Adding infrastructure...")
      
      # Add junctions
      if (input$show_junctions && !is.null(values$junctions_data)) {
        cat("Adding", nrow(values$junctions_data), "junctions\n")
        leafletProxy("route_map") %>%
          addCircleMarkers(
            data = values$junctions_data,
            radius = 4,
            color = "#FF0000",
            fillColor = "#FF0000",
            fillOpacity = 0.7,
            popup = ~paste0("<b>Junction</b><br>", "Name: ", ifelse(is.na(name), "Unnamed", name))
          )
      }
      
      # Add traffic signals
      if (input$show_traffic_signals && !is.null(values$traffic_signals_data)) {
        cat("Adding", nrow(values$traffic_signals_data), "traffic signals\n")
        leafletProxy("route_map") %>%
          addCircleMarkers(
            data = values$traffic_signals_data,
            radius = 3,
            color = "#FFA500",
            fillColor = "#FFA500",
            fillOpacity = 0.8,
            popup = ~paste0("<b>Traffic Signal</b><br>", "Name: ", ifelse(is.na(name), "Unnamed", name))
          )
      }
      
      incProgress(0.1, detail = "Complete!")
      showNotification("Map rendered successfully!", type = "message", duration = 2)
      cat("Map rendering complete!\n")
    })
  })
  
  # Auto-update map when filters change
  observeEvent(c(input$highway_types, input$show_junctions, input$show_traffic_signals), {
    if (values$data_loaded) {
      # Auto-render when filters change
      cat("Filters changed, auto-updating map...\n")
      
      leafletProxy("route_map") %>%
        clearShapes() %>%
        clearMarkers() %>%
        clearControls()
      
      # Filter and add highways
      if (length(input$highway_types) > 0 && !is.null(values$highways_data)) {
        
        filtered_highways <- values$highways_data %>%
          filter(road_type %in% input$highway_types)
        
        # Define colors
        road_colors <- c(
          "motorway" = "#0066CC", 
          "primary" = "#FF6600",
          "secondary" = "#FFCC00", 
          "trunk" = "#009900",
          "motorway_link" = "#0099FF",
          "primary_link" = "#FF9933"
        )
        
        # Add each road type
        for (road_type in unique(filtered_highways$road_type)) {
          if (road_type %in% names(road_colors)) {
            road_subset <- filtered_highways %>% filter(road_type == road_type)
            
            leafletProxy("route_map") %>%
              addPolylines(
                data = road_subset,
                color = road_colors[road_type],
                weight = if(road_type %in% c("motorway", "trunk")) 4 else 3,
                opacity = 0.8,
                popup = ~paste0("<b>", ifelse(is.na(name), "Unnamed", name), "</b><br>",
                                "Type: ", road_type, "<br>",
                                "Highway: ", highway)
              )
          }
        }
        
        # Add legend
        selected_colors <- road_colors[names(road_colors) %in% input$highway_types]
        if (length(selected_colors) > 0) {
          leafletProxy("route_map") %>%
            addLegend(
              position = "bottomright",
              colors = unname(selected_colors),
              labels = names(selected_colors),
              title = "Highway Types",
              opacity = 0.8
            )
        }
      }
      
      # Add junctions
      if (input$show_junctions && !is.null(values$junctions_data)) {
        leafletProxy("route_map") %>%
          addCircleMarkers(
            data = values$junctions_data,
            radius = 4,
            color = "#FF0000",
            fillColor = "#FF0000",
            fillOpacity = 0.7,
            popup = ~paste0("<b>Junction</b><br>", "Name: ", ifelse(is.na(name), "Unnamed", name))
          )
      }
      
      # Add traffic signals
      if (input$show_traffic_signals && !is.null(values$traffic_signals_data)) {
        leafletProxy("route_map") %>%
          addCircleMarkers(
            data = values$traffic_signals_data,
            radius = 3,
            color = "#FFA500",
            fillColor = "#FFA500",
            fillOpacity = 0.8,
            popup = ~paste0("<b>Traffic Signal</b><br>", "Name: ", ifelse(is.na(name), "Unnamed", name))
          )
      }
    }
  }, ignoreInit = TRUE)
  
  # Generate route statistics
  output$route_stats <- renderText({
    if (values$data_loaded && !is.null(values$highways_data)) {
      
      # Filter data
      filtered_highways <- values$highways_data
      if (length(input$highway_types) > 0) {
        filtered_highways <- filtered_highways %>%
          filter(road_type %in% input$highway_types)
      }
      
      total_segments <- nrow(filtered_highways)
      
      # Count by type
      type_counts <- filtered_highways %>%
        st_drop_geometry() %>%
        count(road_type, sort = TRUE)
      
      # Create stats
      stats_text <- paste0(
        "Current Selection Statistics:\n",
        "==============================\n",
        "Highway segments: ", total_segments, "\n",
        "Junctions: ", if(!is.null(values$junctions_data)) nrow(values$junctions_data) else 0, "\n",
        "Traffic signals: ", if(!is.null(values$traffic_signals_data)) nrow(values$traffic_signals_data) else 0, "\n\n",
        "Highway Breakdown:\n",
        "------------------\n"
      )
      
      # Add breakdown
      if (nrow(type_counts) > 0) {
        for (i in 1:nrow(type_counts)) {
          stats_text <- paste0(stats_text, 
                               type_counts$road_type[i], ": ", 
                               type_counts$n[i], " segments\n")
        }
      }
      
      return(stats_text)
      
    } else {
      return("Click 'Load Local Data' first, then 'Render Route Map' to see statistics")
    }
  })
  
  # Data summary table
  output$data_summary_table <- DT::renderDataTable({
    if (!is.null(values$download_summary)) {
      values$download_summary %>%
        mutate(file_size_mb = round(file_size_mb, 2)) %>%
        rename("Dataset" = dataset, "Features" = feature_count, "Size (MB)" = file_size_mb)
    } else {
      data.frame(Dataset = "No summary", Features = 0, "Size (MB)" = 0)
    }
  }, options = list(pageLength = 10))
  
  # File status
  output$file_status <- renderText({
    files <- c("all_highways_combined.gpkg", "all_junctions_combined.gpkg", "traffic_signals.gpkg")
    data_dir <- if(dir.exists("route_data")) "route_data" else if(dir.exists("route_map")) "route_map" else NULL
    
    status_text <- paste0("Working directory: ", getwd(), "\n\n")
    
    if (is.null(data_dir)) {
      return(paste0(status_text, "✗ No data directory found!\n"))
    }
    
    status_text <- paste0(status_text, "✓ Using directory: ", data_dir, "\n\n")
    
    for (file in files) {
      file_path <- file.path(data_dir, file)
      if (file.exists(file_path)) {
        size_mb <- round(file.info(file_path)$size / (1024^2), 2)
        status_text <- paste0(status_text, "✓ ", file, " (", size_mb, " MB)\n")
      } else {
        status_text <- paste0(status_text, "✗ ", file, " - MISSING\n")
      }
    }
    
    return(status_text)
  })
  
  # Plot
  output$data_size_plot <- renderPlot({
    if (!is.null(values$download_summary)) {
      library(ggplot2)
      ggplot(values$download_summary, aes(x = reorder(dataset, file_size_mb), y = file_size_mb)) +
        geom_col(fill = "steelblue") +
        coord_flip() +
        labs(title = "Dataset Sizes", x = "Dataset", y = "Size (MB)") +
        theme_minimal()
    }
  })
  
  # Download handlers
  output$download_infrastructure <- downloadHandler(
    filename = function() paste0("infrastructure_", Sys.Date(), ".csv"),
    content = function(file) {
      if (!values$data_loaded) {
        write.csv(data.frame(error = "No data loaded"), file, row.names = FALSE)
        return()
      }
      
      all_infrastructure <- list()
      
      # Add junctions
      if (!is.null(values$junctions_data)) {
        coords <- st_coordinates(values$junctions_data)
        junctions_df <- data.frame(
          type = "junction",
          osm_id = values$junctions_data$osm_id,
          name = ifelse(is.na(values$junctions_data$name), "Unnamed", values$junctions_data$name),
          longitude = coords[,1],
          latitude = coords[,2]
        )
        all_infrastructure[[1]] <- junctions_df
      }
      
      # Add traffic signals
      if (!is.null(values$traffic_signals_data)) {
        coords <- st_coordinates(values$traffic_signals_data)
        signals_df <- data.frame(
          type = "traffic_signal",
          osm_id = values$traffic_signals_data$osm_id,
          name = ifelse(is.na(values$traffic_signals_data$name), "Unnamed", values$traffic_signals_data$name),
          longitude = coords[,1],
          latitude = coords[,2]
        )
        all_infrastructure[[2]] <- signals_df
      }
      
      if (length(all_infrastructure) > 0) {
        combined <- do.call(rbind, all_infrastructure)
        write.csv(combined, file, row.names = FALSE)
      } else {
        write.csv(data.frame(message = "No infrastructure data"), file, row.names = FALSE)
      }
    }
  )
  
  output$download_highways <- downloadHandler(
    filename = function() paste0("highways_", Sys.Date(), ".csv"),
    content = function(file) {
      if (values$data_loaded && !is.null(values$highways_data)) {
        coords <- st_coordinates(values$highways_data)
        highways_df <- data.frame(
          osm_id = values$highways_data$osm_id,
          name = ifelse(is.na(values$highways_data$name), "Unnamed", values$highways_data$name),
          highway = values$highways_data$highway,
          road_type = values$highways_data$road_type,
          lanes = values$highways_data$lanes,
          longitude = coords[,1],
          latitude = coords[,2]
        )
        write.csv(highways_df, file, row.names = FALSE)
      } else {
        write.csv(data.frame(error = "No highway data"), file, row.names = FALSE)
      }
    }
  )
  
  output$download_filtered <- downloadHandler(
    filename = function() paste0("filtered_", Sys.Date(), ".csv"),
    content = function(file) {
      if (values$data_loaded && !is.null(values$highways_data)) {
        filtered <- values$highways_data
        if (length(input$highway_types) > 0) {
          filtered <- filtered %>% filter(road_type %in% input$highway_types)
        }
        
        coords <- st_coordinates(filtered)
        filtered_df <- data.frame(
          osm_id = filtered$osm_id,
          name = ifelse(is.na(filtered$name), "Unnamed", filtered$name),
          highway = filtered$highway,
          road_type = filtered$road_type,
          selected_types = paste(input$highway_types, collapse = ", "),
          longitude = coords[,1],
          latitude = coords[,2]
        )
        write.csv(filtered_df, file, row.names = FALSE)
      } else {
        write.csv(data.frame(error = "No filtered data"), file, row.names = FALSE)
      }
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)