# ADD THESE FUNCTIONS TO THE SERVER.R FILE (after the existing reactive values)

# ==================
# MAP DATA PROCESSING
# ==================

# Extract coordinates from itinerary JSON
extract_itinerary_data <- function(itinerary_text) {
  tryCatch({
    # Find JSON block in the response
    json_start <- regexpr("```json", itinerary_text, fixed = TRUE)[1]
    json_end <- regexpr("```", substr(itinerary_text, json_start + 7, nchar(itinerary_text)), fixed = TRUE)[1]
    
    if (json_start > 0 && json_end > 0) {
      json_text <- substring(itinerary_text, json_start + 7, json_start + 7 + json_end - 2)
      itinerary_data <- jsonlite::fromJSON(json_text)
      return(itinerary_data$itinerary)
    }
    return(NULL)
  }, error = function(e) {
    return(NULL)
  })
}

# Convert itinerary data to map-ready format
prepare_map_data <- function(itinerary_list) {
  tryCatch({
    map_data <- data.frame()
    
    for (day_idx in seq_along(itinerary_list)) {
      day_obj <- itinerary_list[[day_idx]]
      day_num <- day_obj$day %||% day_idx
      
      for (act_idx in seq_along(day_obj$activities)) {
        activity <- day_obj$activities[[act_idx]]
        
        map_data <- rbind(map_data, data.frame(
          day = day_num,
          day_label = day_obj$day_label %||% paste0("Day ", day_num),
          order = activity$order %||% act_idx,
          name = activity$name %||% "Unnamed",
          time_start = activity$time_start %||% "00:00",
          time_end = activity$time_end %||% "00:00",
          description = activity$description %||% "",
          latitude = as.numeric(activity$latitude) %||% 0,
          longitude = as.numeric(activity$longitude) %||% 0,
          marker_label = paste0(activity$order %||% act_idx),
          stringsAsFactors = FALSE
        ))
      }
    }
    
    return(map_data[map_data$latitude != 0 & map_data$longitude != 0, ])
  }, error = function(e) {
    return(data.frame())
  })
}

# ==================
# ADD TO REACTIVE VALUES (after existing rv <- reactiveValues(...))
# ==================
# rv$itinerary_data <- NULL
# rv$map_data <- NULL
# rv$selected_attraction <- NULL

# ==================
# ADD MAP RENDERING (in observeEvent for generate_itinerary)
# ==================

# After setting rv$generated_itinerary, add:
# rv$itinerary_data <- extract_itinerary_data(itinerary_response)
# rv$map_data <- prepare_map_data(rv$itinerary_data)

# ==================
# ADD MAP PLOT OUTPUT
# ==================

output$trip_map <- plotly::renderPlotly({
  req(rv$map_data)
  md <- rv$map_data
  
  if (nrow(md) == 0) {
    return(plotly::plot_ly() %>% 
      plotly::layout(title = "No location data available"))
  }
  
  # Color palette for days
  day_colors <- c("#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#F7DC6F", "#BB8FCE")
  
  # Create map
  p <- plotly::plot_ly(source = "trip_map_click")
  
  # Add markers for each activity
  for (day_val in unique(md$day)) {
    day_data <- md[md$day == day_val, ]
    day_color <- day_colors[(day_val - 1) %% length(day_colors) + 1]
    
    p <- p %>%
      plotly::add_trace(
        data = day_data,
        type = "scattermapbox",
        lon = ~longitude,
        lat = ~latitude,
        mode = "markers+text",
        text = ~marker_label,
        textposition = "middle center",
        textfont = list(color = "white", size = 14, family = "Arial Black"),
        marker = list(
          size = 35,
          color = day_color,
          opacity = 0.85,
          line = list(color = "white", width = 2)
        ),
        customdata = ~paste0(day, "|", order),
        hovertemplate = paste0(
          "<b>%{customdata}</b><br>",
          "Name: %{name}<br>",
          "Time: %{time}<br>",
          "Lat: %{lat}<br>",
          "Lon: %{lon}<extra></extra>"
        ),
        name = paste0("Day ", day_val),
        showlegend = TRUE
      )
  }
  
  # Get center coordinates (average of all points)
  center_lat <- mean(md$latitude, na.rm = TRUE)
  center_lon <- mean(md$longitude, na.rm = TRUE)
  
  # Calculate zoom level based on spread
  lat_range <- max(md$latitude) - min(md$latitude)
  lon_range <- max(md$longitude) - min(md$longitude)
  max_range <- max(lat_range, lon_range)
  zoom <- ifelse(max_range > 2, 11, ifelse(max_range > 0.5, 12, 13))
  
  p %>%
    plotly::layout(
      mapbox = list(
        style = "open-street-map",
        center = list(lon = center_lon, lat = center_lat),
        zoom = zoom
      ),
      hovermode = "closest",
      margin = list(l = 0, r = 0, t = 0, b = 0),
      showlegend = TRUE,
      legend = list(orientation = "v", x = 0.02, y = 0.98)
    ) %>%
    plotly::config(displaylogo = FALSE, responsive = TRUE)
})

# ==================
# CLICK HANDLER
# ==================

observeEvent(plotly::event_data("plotly_click", source = "trip_map_click"), {
  click <- plotly::event_data("plotly_click", source = "trip_map_click")
  
  if (!is.null(click) && !is.null(click$customdata)) {
    parts <- strsplit(click$customdata[1], "\\|")[[1]]
    if (length(parts) == 2) {
      selected_day <- as.numeric(parts[1])
      selected_order <- as.numeric(parts[2])
      rv$selected_attraction <- paste0(selected_day, "_", selected_order)
    }
  }
})

# ==================
# ATTRACTION DETAIL PANEL
# ==================

output$attraction_detail <- renderUI({
  req(rv$selected_attraction, rv$map_data)
  
  parts <- strsplit(rv$selected_attraction, "_")[[1]]
  selected_day <- as.numeric(parts[1])
  selected_order <- as.numeric(parts[2])
  
  attraction <- rv$map_data[rv$map_data$day == selected_day & rv$map_data$order == selected_order, ]
  
  if (nrow(attraction) == 0) {
    return(tags$p("Click on a marker to see details"))
  }
  
  attraction <- attraction[1, ]
  
  tagList(
    tags$h4(icon("map-pin"), " ", attraction$name),
    tags$hr(),
    tags$div(
      tags$strong("Date: "), tags$span(attraction$day_label), tags$br(),
      tags$strong("Order: "), tags$span("Stop #", attraction$order), tags$br(),
      tags$strong("Time: "), tags$span(attraction$time_start, " - ", attraction$time_end), tags$br(),
      tags$strong("Location: "), tags$span("(", round(attraction$latitude, 4), ", ", round(attraction$longitude, 4), ")"), tags$br(),
      tags$br(),
      tags$strong("Description:"), tags$br(),
      tags$p(attraction$description, style = "font-size: 0.95em; line-height: 1.5;")
    )
  )
})

