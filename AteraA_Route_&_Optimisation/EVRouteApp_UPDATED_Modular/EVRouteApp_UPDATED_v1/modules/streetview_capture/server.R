# modules/streetview_capture/server.R

streetview_capture_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    image_metadata <- reactiveVal(NULL)
    download_stats <- reactiveVal(list(total = 0, downloaded = 0))
    
    observeEvent(input$download_images, {
      
      # Validate API key
      if (is.null(input$api_key) || input$api_key == "") {
        output$download_status <- renderUI({
          div(class = "status-error",
              h5("✗ Missing API Key"),
              p("Please enter your Google Maps API key."))
        })
        return()
      }
      
      # Check for waypoints
      if (is.null(api_manager) || is.null(api_manager$cav_waypoints)) {
        output$download_status <- renderUI({
          div(class = "status-error",
              h5("✗ No Waypoints"),
              p("Please generate waypoints in Route Sampler first."))
        })
        return()
      }
      
      withProgress(message = 'Downloading images...', value = 0, {
        
        tryCatch({
          
          # Ensure data directory exists
          ensure_data_dirs()
          
          waypoints <- api_manager$cav_waypoints
          
          # Sample waypoints
          sampled_indices <- seq(1, nrow(waypoints), by = input$sample_rate)
          sampled_waypoints <- waypoints[sampled_indices, ]
          
          total_images <- nrow(sampled_waypoints)
          images_downloaded <- 0
          metadata_list <- list()
          
          incProgress(0.1, detail = paste("Downloading", total_images, "images"))
          
          for (i in 1:nrow(sampled_waypoints)) {
            wp <- sampled_waypoints[i, ]
            
            # Generate filename
            filename <- generate_image_filename(wp$lat, wp$lon, wp$sequence_number)
            filepath <- file.path("data", "raw", "images", filename)
            
            # Construct Street View URL
            size <- input$image_size
            location <- paste0(wp$lat, ",", wp$lon)
            
            url <- paste0(
              "https://maps.googleapis.com/maps/api/streetview",
              "?size=", size,
              "&location=", location,
              "&fov=", input$fov,
              "&key=", input$api_key
            )
            
            # Download image
            tryCatch({
              response <- httr::GET(url)
              
              if (httr::status_code(response) == 200) {
                # Save image
                writeBin(httr::content(response, "raw"), filepath)
                
                # Store metadata
                metadata_list[[length(metadata_list) + 1]] <- data.frame(
                  waypoint_id = wp$waypoint_id,
                  lat = wp$lat,
                  lon = wp$lon,
                  filename = filename,
                  filepath = filepath,
                  file_size = file.info(filepath)$size,
                  image_size = size,
                  fov = input$fov,
                  downloaded_at = Sys.time(),
                  stringsAsFactors = FALSE
                )
                
                images_downloaded <- images_downloaded + 1
              }
              
              # Rate limiting (avoid hitting API limits)
              Sys.sleep(0.1)
              
            }, error = function(e) {
              cat("Error downloading image for waypoint", wp$waypoint_id, ":", e$message, "\n")
            })
            
            # Update progress
            incProgress(0.8 / total_images, detail = paste(i, "of", total_images))
          }
          
          # Combine metadata
          if (length(metadata_list) > 0) {
            metadata <- do.call(rbind, metadata_list)
            image_metadata(metadata)
            
            if (!is.null(api_manager)) {
              api_manager$cav_images <- metadata
            }
          }
          
          # Update stats
          download_stats(list(
            total = total_images,
            downloaded = images_downloaded
          ))
          
          output$download_status <- renderUI({
            div(class = "status-success",
                h5("✓ Download Complete"),
                p(strong("Images downloaded:"), images_downloaded, "of", total_images),
                p(strong("Storage location:"), "data/raw/images/"))
          })
          
          showNotification(
            paste("Downloaded", images_downloaded, "images successfully!"),
            type = "message",
            duration = 5
          )
          
        }, error = function(e) {
          output$download_status <- renderUI({
            div(class = "status-error",
                h5("✗ Download Failed"),
                p(as.character(e$message)))
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    # Value boxes
    output$total_waypoints <- renderValueBox({
      wp <- if (!is.null(api_manager)) api_manager$cav_waypoints else NULL
      valueBox(
        if (is.null(wp)) "0" else format(nrow(wp), big.mark = ","),
        "Total Waypoints",
        icon = icon("map-marker-alt"),
        color = "blue"
      )
    })
    
    output$images_to_download <- renderValueBox({
      wp <- if (!is.null(api_manager)) api_manager$cav_waypoints else NULL
      count <- if (is.null(wp)) 0 else ceiling(nrow(wp) / input$sample_rate)
      valueBox(
        format(count, big.mark = ","),
        "Images to Download",
        icon = icon("camera"),
        color = "orange"
      )
    })
    
    output$images_downloaded <- renderValueBox({
      stats <- download_stats()
      valueBox(
        format(stats$downloaded, big.mark = ","),
        "Downloaded",
        icon = icon("check-circle"),
        color = "green"
      )
    })
    
    output$download_cost <- renderValueBox({
      wp <- if (!is.null(api_manager)) api_manager$cav_waypoints else NULL
      count <- if (is.null(wp)) 0 else ceiling(nrow(wp) / input$sample_rate)
      cost <- count * 0.007
      valueBox(
        sprintf("$%.2f", cost),
        "Estimated Cost",
        icon = icon("dollar-sign"),
        color = "red"
      )
    })
    
    # Image gallery
    output$image_gallery <- renderUI({
      metadata <- image_metadata()
      if (is.null(metadata) || nrow(metadata) == 0) {
        return(p("No images downloaded yet."))
      }
      
      # Display first 12 images
      display_count <- min(12, nrow(metadata))
      
      img_tags <- lapply(1:display_count, function(i) {
        tags$div(
          style = "display: inline-block; margin: 10px;",
          tags$img(src = metadata$filepath[i], width = "200px", height = "200px"),
          tags$p(style = "text-align: center; font-size: 10px;", metadata$waypoint_id[i])
        )
      })
      
      tagList(
        h5(paste("Showing", display_count, "of", nrow(metadata), "images")),
        do.call(tagList, img_tags)
      )
    })
  })
}
