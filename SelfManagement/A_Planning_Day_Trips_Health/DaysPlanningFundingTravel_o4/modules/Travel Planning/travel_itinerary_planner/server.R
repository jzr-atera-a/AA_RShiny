# modules/Travel Planning/travel_itinerary_planner/server.R
# FIXED: High-quality HTML and PDF generation

travel_itinerary_planner_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    cat("\n🔍 Module initialized: travel_itinerary_planner\n")
    
    ns <- session$ns
    map_source <- "trip_map_click"
    
    rv <- reactiveValues(
      discovered_places = NULL,
      selected_places = character(0),
      generated_itinerary = NULL,
      itinerary_data = NULL,
      places_data = NULL,
      selected_attraction = NULL,
      map_image_path = NULL    # local PNG path once "Save Map Image" succeeds
    )
    
    # ==================
    # MAP HELPERS (shared by save button + HTML export + PDF export)
    # ==================
    
    # Pull every lat/lon pair out of the generated itinerary
    get_all_coords <- function(itinerary_data) {
      lats <- c()
      lons <- c()
      if (!is.null(itinerary_data)) {
        for (day in itinerary_data) {
          if (!is.null(day$attractions)) {
            for (attr in day$attractions) {
              lat <- suppressWarnings(as.numeric(attr$latitude))
              lon <- suppressWarnings(as.numeric(attr$longitude))
              if (length(lat) == 1 && !is.na(lat)) lats <- c(lats, lat)
              if (length(lon) == 1 && !is.na(lon)) lons <- c(lons, lon)
            }
          }
        }
      }
      list(lats = lats, lons = lons)
    }
    
    # Build static-map image URLs from a set of coordinates.
    # NOTE: Google's Static Maps API now REQUIRES a billed API key - without one
    # it silently returns an error page (not an image), which is exactly why
    # the map showed up as a broken image placeholder in exports. We use free,
    # no-key-required OSM static map renderers instead, with a fallback in case
    # the primary one is unreachable.
    build_static_map_urls <- function(lats, lons, width = 900, height = 400) {
      if (length(lats) == 0 || length(lats) != length(lons)) return(list())
      
      lat_center <- mean(lats)
      lon_center <- mean(lons)
      
      # Cap the number of markers - extremely long URLs can get rejected
      n <- length(lats)
      idx <- if (n > 25) unique(round(seq(1, n, length.out = 25))) else seq_len(n)
      
      marker_params <- paste(
        sapply(idx, function(i) paste0("&markers=", lats[i], ",", lons[i], ",red-pushpin")),
        collapse = ""
      )
      
      primary <- paste0(
        "https://staticmap.openstreetmap.de/staticmap.php?center=", lat_center, ",", lon_center,
        "&zoom=12&size=", width, "x", height, "&maptype=mapnik", marker_params
      )
      
      # Wikimedia's static map renderer as a fallback - reliable, no key needed,
      # but doesn't support markers, so it just shows the area.
      fallback <- paste0(
        "https://maps.wikimedia.org/img/osm-intl,12,", lat_center, ",", lon_center, ",", width, "x", height, ".png"
      )
      
      list(primary = primary, fallback = fallback)
    }
    
    # Confirm a downloaded file is actually a PNG (checks the magic bytes)
    # rather than trusting file.size() alone, which can't tell a real image
    # apart from a small HTML/JSON error page saved with a .png extension.
    is_valid_png <- function(path) {
      if (!file.exists(path) || file.size(path) < 8) return(FALSE)
      header <- readBin(path, "raw", 8)
      identical(as.integer(header), c(137L, 80L, 78L, 71L, 13L, 10L, 26L, 10L))
    }
    
    # Guaranteed-offline map: plots the attractions' own lat/lon coordinates
    # with base R graphics (grDevices::png + graphics). No network call at
    # all, so this always works even when the server has no outbound
    # internet access (or the map services above are unreachable/blocked).
    # It's a schematic layout, not a street map, but it always renders.
    generate_offline_map_png <- function(coords, itinerary_data, path, width_px = 900, height_px = 400) {
      tryCatch({
        grDevices::png(path, width = width_px, height = height_px, res = 100)
        on.exit(grDevices::dev.off(), add = TRUE)
        
        lats <- coords$lats
        lons <- coords$lons
        
        lat_pad <- max(diff(range(lats)) * 0.3, 0.01)
        lon_pad <- max(diff(range(lons)) * 0.3, 0.01)
        
        graphics::par(mar = c(3, 3, 2, 1), bg = "white")
        graphics::plot(
          lons, lats, type = "n",
          xlim = range(lons) + c(-lon_pad, lon_pad),
          ylim = range(lats) + c(-lat_pad, lat_pad),
          xlab = "Longitude", ylab = "Latitude",
          main = "Trip Map (offline layout - no internet access from server)",
          cex.main = 0.95, font.main = 2, col.main = "#2196F3"
        )
        graphics::grid(col = "grey85")
        
        day_colors <- c("#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#F7DC6F", "#BB8FCE")
        marker_i <- 1
        
        if (!is.null(itinerary_data)) {
          for (d_idx in seq_along(itinerary_data)) {
            day <- itinerary_data[[d_idx]]
            if (is.null(day$attractions)) next
            day_col <- day_colors[((day$day %||% d_idx) - 1) %% length(day_colors) + 1]
            
            day_lats <- c(); day_lons <- c()
            for (attr in day$attractions) {
              lat <- suppressWarnings(as.numeric(attr$latitude))
              lon <- suppressWarnings(as.numeric(attr$longitude))
              if (length(lat) != 1 || is.na(lat) || length(lon) != 1 || is.na(lon)) next
              day_lats <- c(day_lats, lat)
              day_lons <- c(day_lons, lon)
            }
            
            if (length(day_lats) > 1) {
              graphics::lines(day_lons, day_lats, col = day_col, lty = 2, lwd = 1.2)
            }
            if (length(day_lats) > 0) {
              graphics::points(day_lons, day_lats, pch = 21, bg = day_col, col = "white", cex = 2.3, lwd = 1)
              graphics::text(day_lons, day_lats, labels = marker_i:(marker_i + length(day_lats) - 1),
                              cex = 0.65, col = "white", font = 2)
              marker_i <- marker_i + length(day_lats)
            }
          }
        }
        
        TRUE
      }, error = function(e) {
        cat("  ❌ Offline map generation failed:", e$message, "\n")
        FALSE
      })
    }
    
    # ==================
    # DISCOVER PLACES
    # ==================
    
    observeEvent(input$discover_places, {
      cat("\n🔍 [DISCOVER] Button clicked for:", input$destination, "\n")
      
      req(input$destination, input$num_places)
      
      shinyjs::show("loading_spinner", anim = TRUE)
      output$discovery_status <- renderUI({
        tags$div(class = "alert alert-info",
                tags$strong("Status: "), "Discovering attractions...")
      })
      
      tryCatch({
        prompt <- paste0(
          "List top ", input$num_places, " places in ", input$destination, 
          ". Format: 1. Name (Category). No explanations."
        )
        
        cat("  Calling api_manager$call_claude()...\n")
        response <- api_manager$call_claude(prompt)
        
        if (!is.character(response)) {
          response <- as.character(response)
        }
        
        lines <- strsplit(response, "\n", fixed = TRUE)[[1]]
        cat("  Lines parsed:", length(lines), "\n")
        
        parsed_places <- character()
        for (line in lines) {
          line <- trimws(line)
          if (nchar(line) > 2) {
            cleaned <- sub("^[0-9]+\\.\\s*", "", line)
            if (cleaned != line && nchar(cleaned) > 0) {
              parsed_places <- c(parsed_places, cleaned)
            }
          }
        }
        
        cat("  Total places parsed:", length(parsed_places), "\n")
        
        if (length(parsed_places) == 0) {
          stop("No places parsed from response")
        }
        
        rv$discovered_places <- parsed_places
        rv$places_data <- data.frame(name = parsed_places, stringsAsFactors = FALSE)
        
        shinyjs::hide("loading_spinner", anim = TRUE)
        
        output$places_checkboxes <- renderUI({
          tags$div(
            lapply(1:length(parsed_places), function(i) {
              tagList(
                checkboxInput(ns(paste0("place_", i)), parsed_places[i], value = FALSE)
              )
            })
          )
        })
        
        output$places_counter <- renderUI({
          HTML(sprintf("<strong>%d of %d selected</strong>", 0, length(parsed_places)))
        })
        
        output$discovery_status <- renderUI({
          tags$div(class = "alert alert-success",
                  tags$strong("✓ Found "), length(parsed_places), " attractions!")
        })
        
        cat("✅ [DISCOVER] Success!\n")
        
      }, error = function(e) {
        cat("❌ [ERROR]:", e$message, "\n")
        shinyjs::hide("loading_spinner", anim = TRUE)
        output$discovery_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  tags$strong("❌ Error: "), e$message)
        })
      })
    })
    
    # ==================
    # GENERATE ITINERARY
    # ==================
    
    observeEvent(input$generate_itinerary, {
      cat("\n🔍 [GENERATE] Button clicked\n")
      
      req(input$destination, input$num_days)
      
      if (is.null(rv$places_data) || nrow(rv$places_data) == 0) {
        showNotification("Click 'Discover Places' first!", type = "warning")
        return()
      }
      
      selected_indices <- which(sapply(1:nrow(rv$places_data), function(i) {
        isTRUE(input[[paste0("place_", i)]])
      }))
      
      if (length(selected_indices) == 0) {
        showNotification("Select at least one place!", type = "warning")
        return()
      }
      
      selected_places_list <- rv$places_data$name[selected_indices]
      
      cat("  Selected", length(selected_places_list), "places\n")
      
      shinyjs::show("itinerary_loading_spinner", anim = TRUE)
      shinyjs::hide("itinerary_content", anim = TRUE)
      output$itinerary_status <- renderUI({
        tags$div(class = "alert alert-info",
                tags$strong("Status: "), "Generating itinerary...")
      })
      
      tryCatch({
        selected_places_text <- paste(sprintf("- %s", selected_places_list), collapse = "\n")
        
        prompt <- paste0(
          "Create ", input$num_days, "-day itinerary for ", input$destination, "\n\n",
          "Must visit these attractions:\n", selected_places_text, "\n\n",
          "For EACH attraction, provide:\n",
          "- Time (HH:MM-HH:MM format, e.g., 09:00-11:30)\n",
          "- 1-2 sentence description\n",
          "- GPS coordinates (latitude as number, longitude as number)\n\n",
          "End with JSON block EXACTLY like this (no markdown, just raw JSON):\n\n",
          "```json\n",
          "{\n",
          "  \"itinerary\": [\n",
          "    {\n",
          "      \"day\": 1,\n",
          "      \"day_label\": \"Day 1 - Monday\",\n",
          "      \"attractions\": [\n",
          "        {\n",
          "          \"name\": \"Eiffel Tower\",\n",
          "          \"latitude\": 48.8584,\n",
          "          \"longitude\": 2.2945,\n",
          "          \"time_start\": \"09:00\",\n",
          "          \"time_end\": \"11:30\",\n",
          "          \"description\": \"Iconic iron tower with 3 floors and restaurant.\"\n",
          "        }\n",
          "      ]\n",
          "    }\n",
          "  ]\n",
          "}\n",
          "```"
        )
        
        cat("  Calling api_manager$call_claude()...\n")
        itinerary_response <- api_manager$call_claude(prompt)
        
        if (!is.character(itinerary_response)) {
          itinerary_response <- paste(as.character(itinerary_response), collapse = " ")
        }
        
        cat("  Response received:", nchar(itinerary_response), "chars\n")
        
        # EXTRACT JSON
        json_text <- NULL
        patterns <- c(
          "```json\\s*\\{[^`]*\"itinerary\"[^`]*\\}[^`]*```",
          "\\{[^}]*\"itinerary\"[^}]*\\}",
          "```\\s*\\{[^`]*\"itinerary\"[^`]*\\}\\s*```"
        )
        
        for (pattern in patterns) {
          match <- gregexpr(pattern, itinerary_response, perl = TRUE)
          if (match[[1]][1] > 0) {
            matched_text <- regmatches(itinerary_response, match)[[1]][1]
            json_text <- gsub("```json\\s*|```\\s*|\\s*```", "", matched_text)
            cat("  JSON found:", nchar(json_text), "chars\n")
            break
          }
        }
        
        # PARSE JSON
        if (!is.null(json_text) && nchar(json_text) > 50) {
          tryCatch({
            raw_json <- jsonlite::fromJSON(json_text, simplifyDataFrame = FALSE)
            
            if (!is.null(raw_json$itinerary) && is.list(raw_json$itinerary)) {
              itinerary_list <- lapply(raw_json$itinerary, function(day) {
                list(
                  day = as.numeric(day$day) %||% 1,
                  day_label = as.character(day$day_label) %||% paste0("Day ", day$day),
                  attractions = lapply(day$attractions, function(attr) {
                    list(
                      name = as.character(attr$name),
                      latitude = as.numeric(attr$latitude),
                      longitude = as.numeric(attr$longitude),
                      time_start = as.character(attr$time_start),
                      time_end = as.character(attr$time_end),
                      description = as.character(attr$description) %||% ""
                    )
                  })
                )
              })
              
              rv$itinerary_data <- itinerary_list
              # New itinerary = new coordinates, so any previously saved map image is stale
              rv$map_image_path <- NULL
              cat("  ✅ Parsed", length(itinerary_list), "days with GPS\n")
            }
          }, error = function(e) {
            cat("  JSON parse error:", e$message, "\n")
          })
        }
        
        rv$generated_itinerary <- itinerary_response
        
        shinyjs::hide("itinerary_loading_spinner", anim = TRUE)
        shinyjs::show("itinerary_content", anim = TRUE)
        
        # RENDER ITINERARY
        output$itinerary_html <- renderUI({
          if (!is.null(rv$itinerary_data) && length(rv$itinerary_data) > 0) {
            cat("  Rendering", length(rv$itinerary_data), "days with boxes\n")
            
            return(tagList(lapply(rv$itinerary_data, function(day) {
              if (is.null(day) || is.null(day$attractions)) return(NULL)
              
              day_label <- day$day_label %||% paste0("Day ", day$day)
              
              attraction_boxes <- tagList(lapply(day$attractions, function(attr) {
                if (is.null(attr$name)) return(NULL)
                
                time_label <- paste0(attr$time_start %||% "??:??", " - ", attr$time_end %||% "??:??")
                
                tags$details(
                  tags$summary(
                    tags$strong(attr$name),
                    tags$span(class = "text-muted", style = "float:right; font-size:0.85em;",
                             time_label)
                  ),
                  tags$div(
                    style = "background-color: #f9f9f9; padding: 12px; border-radius: 4px; margin-top: 8px;",
                    tags$p(tags$strong("Time: "), time_label),
                    tags$p(attr$description %||% "No description"),
                    tags$p(class = "text-muted", style = "font-size:0.9em;",
                          "📍 ", 
                          if (!is.null(attr$latitude)) round(attr$latitude, 4) else "?",
                          ", ", 
                          if (!is.null(attr$longitude)) round(attr$longitude, 4) else "?")
                  )
                )
              }))
              
              tags$div(
                style = "background-color: #f0f8ff; padding: 12px; border-radius: 4px; margin-bottom: 12px; border-left: 4px solid #2196F3;",
                tags$h5(day_label),
                attraction_boxes
              )
            })))
          }
          
          # FALLBACK
          cat("  Falling back to text display\n")
          tags$div(
            tags$div(class = "alert alert-warning",
              "⚠️ GPS coordinates not available. Showing text itinerary:"),
            tags$div(
              style = "background-color: #f9f9f9; padding: 15px; border-radius: 4px; margin-top: 10px; white-space: pre-wrap; max-height: 500px; overflow-y: auto;",
              tags$code(rv$generated_itinerary)
            )
          )
        })
        
        output$itinerary_status <- renderUI({
          if (!is.null(rv$itinerary_data) && length(rv$itinerary_data) > 0) {
            tags$div(class = "alert alert-success",
                    tags$strong("✓ Itinerary created with GPS!"))
          } else {
            tags$div(class = "alert alert-warning",
                    tags$strong("⚠️ Itinerary created (text mode)"))
          }
        })
        
        cat("✅ [GENERATE] Success!\n")
        
      }, error = function(e) {
        cat("❌ [ERROR]:", e$message, "\n")
        shinyjs::hide("itinerary_loading_spinner", anim = TRUE)
        output$itinerary_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  tags$strong("❌ Error: "), e$message)
        })
      })
    })
    
    # ==================
    # MAP
    # ==================
    
    output$trip_map <- plotly::renderPlotly({
      if (is.null(rv$itinerary_data) || length(rv$itinerary_data) == 0) {
        return(plotly::plot_ly() %>%
          plotly::layout(title = "Map will appear after generating itinerary"))
      }
      
      tryCatch({
        all_attractions <- do.call(rbind, lapply(seq_along(rv$itinerary_data), function(i) {
          day <- rv$itinerary_data[[i]]
          if (is.null(day$attractions)) return(NULL)
          
          do.call(rbind, lapply(day$attractions, function(attr) {
            data.frame(
              day = day$day,
              day_label = day$day_label,
              name = attr$name,
              latitude = as.numeric(attr$latitude),
              longitude = as.numeric(attr$longitude),
              time_start = attr$time_start,
              time_end = attr$time_end,
              description = attr$description,
              stringsAsFactors = FALSE
            )
          }))
        }))
        
        if (is.null(all_attractions) || nrow(all_attractions) == 0) {
          return(plotly::plot_ly() %>%
            plotly::layout(title = "No attractions with coordinates"))
        }
        
        all_attractions <- all_attractions[!is.na(all_attractions$latitude) & !is.na(all_attractions$longitude), ]
        
        if (nrow(all_attractions) == 0) {
          return(plotly::plot_ly() %>%
            plotly::layout(title = "No valid coordinates available"))
        }
        
        day_colors <- c("#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#F7DC6F", "#BB8FCE")
        all_attractions$day_color <- day_colors[(all_attractions$day - 1) %% length(day_colors) + 1]
        
        all_attractions$hover_detail <- paste0(
          "<b>", all_attractions$name, "</b><br>",
          all_attractions$day_label, "<br>",
          all_attractions$time_start, " - ", all_attractions$time_end, "<br>",
          all_attractions$description
        )
        
        p <- plotly::plot_ly(source = map_source, data = all_attractions)
        
        for (d in unique(all_attractions$day)) {
          day_data <- all_attractions[all_attractions$day == d, ]
          day_label <- day_data$day_label[1]
          day_color <- day_data$day_color[1]
          
          p <- plotly::add_trace(p,
            data = day_data,
            type = "scattermapbox",
            lon = ~longitude,
            lat = ~latitude,
            mode = "markers",
            name = day_label,
            marker = list(size = 12, color = day_color, opacity = 0.85),
            text = ~hover_detail,
            hovertemplate = "%{text}<extra></extra>",
            customdata = ~name
          )
        }
        
        lat_center <- mean(all_attractions$latitude, na.rm = TRUE)
        lon_center <- mean(all_attractions$longitude, na.rm = TRUE)
        
        p |> plotly::layout(
          mapbox = list(
            style = "open-street-map",
            center = list(lon = lon_center, lat = lat_center),
            zoom = 12
          ),
          showlegend = TRUE,
          legend = list(orientation = "h", y = -0.02, bgcolor = "rgba(255,255,255,0.85)"),
          margin = list(l = 0, r = 0, t = 0, b = 0)
        ) |>
          plotly::config(displaylogo = FALSE)
        
      }, error = function(e) {
        cat("Map rendering error:", e$message, "\n")
        plotly::plot_ly() %>%
          plotly::layout(title = paste("Map Error:", e$message))
      })
    })
    
    observeEvent(plotly::event_data("plotly_click", source = map_source), {
      click <- plotly::event_data("plotly_click", source = map_source)
      if (!is.null(click) && !is.null(click$customdata)) {
        rv$selected_attraction <- click$customdata[1]
      }
    })
    
    output$attraction_detail <- renderUI({
      if (is.null(rv$selected_attraction) || is.null(rv$itinerary_data)) {
        return(tags$p("Click a marker to see details", class = "text-muted"))
      }
      
      for (day in rv$itinerary_data) {
        if (is.null(day$attractions)) next
        for (attr in day$attractions) {
          if (!is.null(attr$name) && attr$name == rv$selected_attraction) {
            return(tagList(
              tags$h4(attr$name),
              tags$p(tags$strong("Day: "), day$day_label %||% paste0("Day ", day$day)),
              tags$p(tags$strong("Time: "), attr$time_start, " - ", attr$time_end),
              tags$p(attr$description),
              tags$p(class = "text-muted",
                    "📍 ", attr$latitude, ", ", attr$longitude)
            ))
          }
        }
      }
      tags$p("Not found", class = "text-muted")
    })
    
    # ==================
    # SAVE MAP IMAGE
    # ==================
    
    output$save_map_button <- renderUI({
      if (is.null(rv$itinerary_data) || length(rv$itinerary_data) == 0) {
        return(NULL)
      }
      
      tagList(
        br(),
        actionButton(ns("save_map_image"), "💾 Save Map Image", icon = icon("camera"),
                     class = "btn-info", style = "width: 100%;"),
        if (!is.null(rv$map_image_path)) {
          tags$p(class = "text-success", style = "margin-top: 8px; font-size: 0.85em;",
                 icon("check-circle"), " Map image saved. Ready for export.")
        }
      )
    })
    
    
    # ==================
    # SAVE MAP IMAGE (CLIENT-SIDE CAPTURE)
    # ==================
    # FIX: Use Plotly.js's built-in client-side image export instead of trying
    # to download map tiles from the network (which fails when server has no internet).
    # This captures the exact beautiful map the user sees in the browser.
    
    output$save_map_button <- renderUI({
      if (is.null(rv$itinerary_data) || length(rv$itinerary_data) == 0) {
        return(NULL)
      }
      
      tagList(
        br(),
        actionButton(ns("save_map_image"), "💾 Save Map Image", icon = icon("camera"),
                     class = "btn-info", style = "width: 100%;"),
        if (!is.null(rv$map_image_path)) {
          tags$p(class = "text-success", style = "margin-top: 8px; font-size: 0.85em;",
                 icon("check-circle"), " Map image saved. Ready for export.")
        }
      )
    })
    
    observeEvent(input$save_map_image, {
      cat("\n📸 MAP CAPTURE: User clicked 'Save Map Image'\n")
      
      if (is.null(rv$itinerary_data) || length(rv$itinerary_data) == 0) {
        cat("  ❌ No itinerary available yet\n")
        showNotification("Generate an itinerary first!", type = "warning")
        return()
      }
      
      # Trigger client-side JavaScript to capture the Plotly map
      # This uses Plotly.toImage() which runs entirely in the browser - no server network access needed
      plotly_div_id <- ns("trip_map")
      cat("  📸 Requesting client-side map capture for Plotly div:", plotly_div_id, "\n")
      
      # Tell JavaScript to capture the map and send back base64 data
      shinyjs::runjs(sprintf("
        (function() {
          var plotDiv = document.getElementById('%s');
          if (!plotDiv) {
            console.error('❌ Could not find Plotly div: %s');
            return;
          }
          console.log('📸 Capturing Plotly map via toImage()...');
          
          Plotly.toImage(plotDiv, { format: 'png', width: 1200, height: 600 })
            .then(function(imgData) {
              console.log('✅ Plotly map captured, sending to Shiny...');
              // Send the data URL to Shiny
              Shiny.setInputValue('%s', imgData, { priority: 'event' });
            })
            .catch(function(err) {
              console.error('❌ Map capture failed:', err);
              alert('❌ Map capture failed: ' + err.message);
            });
        })();
      ", plotly_div_id, plotly_div_id, ns("map_capture_base64")))
      
      cat("  ⏳ Waiting for browser to send back map image...\n")
    }, ignoreInit = TRUE)
    
    # Observer: when JavaScript sends back the base64 map image
    observeEvent(input$map_capture_base64, {
      cat("\n📸 MAP RECEIVED: Browser sent base64 image\n")
      
      base64_data <- input$map_capture_base64
      
      if (is.null(base64_data) || nchar(base64_data) < 500) {
        cat("  ❌ Invalid base64 data received (too short)\n")
        showNotification("Map capture failed - invalid data from browser", type = "error")
        return()
      }
      
      cat("  📊 Received", nchar(base64_data), "characters of base64 data\n")
      
      # Strip the "data:image/png;base64," prefix if present
      if (grepl("^data:image/png;base64,", base64_data)) {
        base64_data <- sub("^data:image/png;base64,", "", base64_data)
        cat("  ✂️ Stripped data URL prefix\n")
      }
      
      # Create temp directory for maps
      map_dir <- file.path(tempdir(), "travel_maps")
      if (!dir.exists(map_dir)) dir.create(map_dir, recursive = TRUE)
      
      timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
      map_path <- file.path(map_dir, paste0("map_", timestamp, ".png"))
      
      tryCatch({
        cat("  🔄 Decoding base64 data...\n")
        # Decode base64 to raw bytes
        raw_bytes <- jsonlite::base64_dec(base64_data)
        
        cat("  💾 Writing", length(raw_bytes), "bytes to file...\n")
        # Write to file
        writeBin(raw_bytes, map_path)
        
        cat("  ✓ File written, verifying...\n")
        # Verify it's actually a valid PNG (check magic bytes)
        if (file.exists(map_path) && file.size(map_path) > 100) {
          header <- readBin(map_path, "raw", 8)
          # PNG magic: 137 80 78 71 13 10 26 10
          is_png <- identical(as.integer(header), c(137L, 80L, 78L, 71L, 13L, 10L, 26L, 10L))
          
          if (is_png) {
            rv$map_image_path <- map_path
            cat("  ✅ Map image saved successfully\n")
            cat("  📁 Path:", map_path, "\n")
            cat("  📊 File size:", format(file.size(map_path), big.mark = ","), "bytes\n")
            cat("  ✅ Ready for HTML, PDF, KML, GPX, Google Maps exports\n")
            showNotification("✅ Map image captured and saved! Ready for export.", 
                           type = "message", duration = 5)
          } else {
            cat("  ❌ PNG validation failed - invalid magic bytes\n")
            stop("PNG validation failed - file header does not match PNG format")
          }
        } else {
          cat("  ❌ File missing or too small:", file.size(map_path), "bytes\n")
          stop("File too small or doesn't exist - capture may have been incomplete")
        }
      }, error = function(e) {
        cat("  ❌ Error saving map:", e$message, "\n")
        showNotification(paste("❌ Map save error:", e$message), type = "error", duration = 5)
        if (file.exists(map_path)) {
          unlink(map_path)
          cat("  🗑️ Cleaned up incomplete file\n")
        }
      })
    }, ignoreInit = TRUE)
    
    
    # ==================
    # DOWNLOADS - HIGH QUALITY HTML
    # ==================
    

    output$download_html <- downloadHandler(
      filename = function() { paste0(input$destination, "_itinerary.html") },
      content = function(file) {
        tryCatch({
          cat("\n📄 EXPORTING: HTML\n")
          cat("  Destination:", input$destination, "\n")
          
          lats <- c()
          lons <- c()
          
          if (!is.null(rv$itinerary_data)) {
            for (day in rv$itinerary_data) {
              if (!is.null(day$attractions)) {
                for (attr in day$attractions) {
                  if (!is.na(attr$latitude)) lats <- c(lats, as.numeric(attr$latitude))
                  if (!is.na(attr$longitude)) lons <- c(lons, as.numeric(attr$longitude))
                }
              }
            }
          }
          
          cat("  📍 Found", length(lats), "attractions\n")
          
          # Embed the locally saved map PNG (from "Save Map Image") as base64 so
          # the exported HTML is fully self-contained and works offline. We only
          # ever embed a *verified* local image - never a live external URL that
          # could 404/error and show up as a broken image placeholder.
          if (!is.null(rv$map_image_path) && file.exists(rv$map_image_path)) {
            img_bytes <- readBin(rv$map_image_path, "raw", file.info(rv$map_image_path)$size)
            img_b64 <- jsonlite::base64_enc(img_bytes)
            map_img_html <- paste0(
              "<div style='text-align:center; margin:20px 0;'><img src='data:image/png;base64,",
              img_b64, "' alt='Trip Map' style='width:100%; max-width:900px; border-radius:4px; border:1px solid #ddd;'></div>"
            )
            cat("  🗺️ Map embedded (from saved image)\n")
          } else {
            map_img_html <- paste0(
              "<div style='text-align:center; margin:20px 0; padding:18px; background:#fff3cd; ",
              "border:1px solid #ffe08a; border-radius:4px; color:#7a5c00;'>",
              "🗺️ Map not included - click <strong>💾 Save Map Image</strong> in the app before downloading, then re-download this file.",
              "</div>"
            )
            cat("  ⚠️ No saved map image - inserted a notice instead of a broken image\n")
          }
          
          html <- c(
            "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>", input$destination, " Itinerary</title>",
            "<style>",
            "body{font-family:Segoe UI,Arial;background:#f5f5f5;padding:20px;margin:0}",
            ".container{max-width:900px;margin:0 auto;background:white;padding:40px;border-radius:8px;box-shadow:0 2px 10px rgba(0,0,0,0.1)}",
            ".header{border-bottom:3px solid #2196F3;padding-bottom:20px;margin-bottom:30px}",
            ".header h1{color:#2196F3;font-size:2.5em;margin:0}",
            ".trip-info{background:#e3f2fd;padding:15px;border-radius:4px;margin:20px 0}",
            ".trip-info p{margin:5px 0}",
            ".day-section{margin-bottom:40px}",
            ".day-header{background:linear-gradient(135deg,#2196F3,#1976D2);color:white;padding:15px;border-radius:4px;margin:30px 0 15px;font-weight:bold;font-size:1.2em}",
            ".attraction{border-left:4px solid #2196F3;padding:15px;margin:15px 0;background:#f9f9f9;border-radius:4px}",
            ".attraction-name{font-size:1.1em;font-weight:bold;color:#1976D2;margin-bottom:8px}",
            ".attraction-time{background:#e3f2fd;padding:8px;border-radius:3px;display:inline-block;font-weight:bold;color:#1976D2;margin-bottom:10px}",
            ".attraction-desc{margin:10px 0}",
            ".attraction-coords{color:#999;font-size:0.9em;margin-top:8px}",
            ".footer{border-top:1px solid #ddd;padding-top:20px;margin-top:40px;text-align:center;color:#999;font-size:0.9em}",
            "</style></head><body><div class='container'>",
            "<div class='header'><h1>🌍 ", input$destination, " Itinerary</h1></div>",
            "<div class='trip-info'>",
            "<p><strong>Duration:</strong> ", input$num_days, " day(s) | <strong>Start:</strong> ", format(input$trip_start_date, "%a, %b %d, %Y"), "</p>",
            "</div>"
          )
          
          if (map_img_html != "") html <- c(html, map_img_html)
          
          if (!is.null(rv$itinerary_data)) {
            for (day in rv$itinerary_data) {
              html <- c(html, "<div class='day-section'>", paste0("<div class='day-header'>", day$day_label, "</div>"))
              if (!is.null(day$attractions)) {
                for (attr in day$attractions) {
                  html <- c(html,
                    "<div class='attraction'>",
                    paste0("<div class='attraction-name'>", attr$name, "</div>"),
                    paste0("<div class='attraction-time'>🕐 ", attr$time_start, " - ", attr$time_end, "</div>"),
                    paste0("<div class='attraction-desc'>", attr$description, "</div>"),
                    paste0("<div class='attraction-coords'>📍 ", round(attr$latitude, 4), ", ", round(attr$longitude, 4), "</div>"),
                    "</div>"
                  )
                }
              }
              html <- c(html, "</div>")
            }
          }
          
          html <- c(html,
            "<div class='footer'>",
            paste0("<p>Generated ", format(Sys.time(), "%a, %b %d, %Y at %H:%M"), "</p>"),
            "</div></div></body></html>"
          )
          
          writeLines(html, file)
          cat("  ✅ HTML WITH MAP generated\n")
          cat("  📊 File size:", format(file.size(file), big.mark = ","), "bytes\n")
        }, error = function(e) {
          cat("  ❌ ERROR:", e$message, "\n")
          writeLines("<html><body>Error</body></html>", file)
        })
      }
    )

    # Draws one line of wrapped text starting at the current y position,
    # moving to a new page automatically when it runs off the bottom.
    # Returns the updated y position (and, invisibly, whether a new page
    # was started, via the `page_started` env flag).
    pdf_new_page <- function() {
      grid::grid.newpage()
      grid::pushViewport(grid::viewport(x = 0.5, y = 0.5, width = 0.9, height = 0.94))
      0.98
    }
    
    output$download_pdf <- downloadHandler(
      filename = function() { paste0(input$destination, "_itinerary.pdf") },
      contentType = "application/pdf",
      content = function(file) {
        cat("\n📕 EXPORTING: PDF\n")
        cat("  Destination:", input$destination, "\n")
        
        coords <- get_all_coords(rv$itinerary_data)
        cat("  📍 Found", length(coords$lats), "attractions\n")
        
        # Build the whole PDF with R's built-in graphics device (grDevices::pdf).
        # This never touches LaTeX, pandoc, or a headless browser - it's part of
        # base R, so it always works, which is exactly what was missing before:
        # rmarkdown::render() was silently failing (no tinytex/LaTeX on the
        # server) and its error handler was writing a *text file* renamed to
        # ".pdf" - a file no PDF reader can open. That whole failure path is
        # gone now.
        pdf_ok <- tryCatch({
          grDevices::pdf(file, width = 8.27, height = 11.69, onefile = TRUE,
                         title = paste0(input$destination, " Itinerary"))
          
          y <- pdf_new_page()
          line_h <- 0.024
          
          new_page_if_needed <- function(y, needed = line_h) {
            if (y - needed < 0.03) return(pdf_new_page())
            y
          }
          
          grid::grid.text(paste0(input$destination, " Itinerary"),
                           x = 0.5, y = y, gp = grid::gpar(fontsize = 20, fontface = "bold", col = "#2196F3"))
          y <- y - 0.045
          grid::grid.text(
            paste0("Duration: ", input$num_days, " day(s)   |   ",
                   format(input$trip_start_date, "%b %d, %Y"), " - ", format(input$trip_end_date, "%b %d, %Y")),
            x = 0.5, y = y, gp = grid::gpar(fontsize = 10, col = "#555555")
          )
          y <- y - 0.045
          
          # Trip map - only ever draws a REAL, verified saved image; otherwise
          # a plain text note so the PDF always renders cleanly either way.
          if (!is.null(rv$map_image_path) && file.exists(rv$map_image_path) && requireNamespace("png", quietly = TRUE)) {
            img <- tryCatch(png::readPNG(rv$map_image_path), error = function(e) NULL)
            if (!is.null(img)) {
              grid::grid.raster(img, x = 0.5, y = y - 0.14, width = 0.95, height = 0.26)
              y <- y - 0.32
              cat("  🗺️ Map embedded (from saved image)\n")
            } else {
              grid::grid.text("(Map image could not be read)", x = 0.5, y = y - 0.02, gp = grid::gpar(fontsize = 9, col = "#999999"))
              y <- y - 0.05
            }
          } else {
            grid::grid.text("Map not included - click Save Map Image before exporting, then re-download.",
                             x = 0.5, y = y - 0.02, gp = grid::gpar(fontsize = 9, fontface = "italic", col = "#b58900"))
            y <- y - 0.05
            cat("  ⚠️ No saved map image - PDF includes a text note instead of a broken image\n")
          }
          
          y <- new_page_if_needed(y, 0.05)
          grid::grid.text("Itinerary", x = 0.02, y = y, just = "left",
                           gp = grid::gpar(fontsize = 14, fontface = "bold", col = "#1976D2"))
          y <- y - 0.04
          
          if (!is.null(rv$itinerary_data) && length(rv$itinerary_data) > 0) {
            for (day in rv$itinerary_data) {
              y <- new_page_if_needed(y, 0.045)
              grid::grid.text(day$day_label %||% paste0("Day ", day$day), x = 0.02, y = y, just = "left",
                               gp = grid::gpar(fontsize = 12, fontface = "bold", col = "#2196F3"))
              y <- y - line_h * 1.3
              
              if (!is.null(day$attractions)) {
                for (idx in seq_along(day$attractions)) {
                  attr <- day$attractions[[idx]]
                  
                  y <- new_page_if_needed(y)
                  header <- paste0(idx, ". ", attr$name, "   (", attr$time_start, " - ", attr$time_end, ")")
                  grid::grid.text(header, x = 0.03, y = y, just = "left", gp = grid::gpar(fontsize = 10.5, fontface = "bold"))
                  y <- y - line_h
                  
                  desc_lines <- strwrap(attr$description %||% "", width = 100)
                  for (dline in desc_lines) {
                    y <- new_page_if_needed(y)
                    grid::grid.text(dline, x = 0.05, y = y, just = "left", gp = grid::gpar(fontsize = 9.5, col = "#333333"))
                    y <- y - line_h * 0.85
                  }
                  
                  y <- new_page_if_needed(y)
                  grid::grid.text(paste0("Location: ", round(attr$latitude, 4), ", ", round(attr$longitude, 4)),
                                   x = 0.05, y = y, just = "left", gp = grid::gpar(fontsize = 8.5, col = "#999999"))
                  y <- y - line_h * 1.2
                }
              }
            }
          }
          
          y <- new_page_if_needed(y, 0.03)
          grid::grid.text(paste0("Generated ", format(Sys.time(), "%a, %b %d, %Y at %H:%M")),
                           x = 0.5, y = 0.02, gp = grid::gpar(fontsize = 8, col = "#999999"))
          
          grDevices::dev.off()
          TRUE
        }, error = function(e) {
          cat("  ❌ PDF error:", e$message, "\n")
          if (!is.null(grDevices::dev.list()) && names(grDevices::dev.cur()) == "pdf") grDevices::dev.off()
          FALSE
        })
        
        if (!isTRUE(pdf_ok)) {
          # Last-resort minimal (but still 100% valid) PDF so the download
          # button never hands back an unopenable file.
          tryCatch({
            grDevices::pdf(file, width = 8.27, height = 11.69)
            grid::grid.text(
              paste0("Could not fully generate the itinerary PDF for ", input$destination, ".\nPlease try again."),
              gp = grid::gpar(fontsize = 13)
            )
            grDevices::dev.off()
          }, error = function(e2) {
            cat("  ❌ Fallback PDF also failed:", e2$message, "\n")
          })
        }
        
        cat("  ✅ PDF generated\n")
        cat("  📊 File size:", format(file.size(file), big.mark = ","), "bytes\n")
      }
    )
    
    # ==================
    # DOWNLOADS - KML (Google Maps / Google Earth)
    # ==================
    
    esc_xml <- function(x) {
      x <- as.character(x %||% "")
      x <- gsub("&", "&amp;", x, fixed = TRUE)
      x <- gsub("<", "&lt;", x, fixed = TRUE)
      x <- gsub(">", "&gt;", x, fixed = TRUE)
      x
    }
    
    output$download_kml <- downloadHandler(
      filename = function() { paste0(input$destination, "_itinerary.kml") },
      contentType = "application/vnd.google-earth.kml+xml",
      content = function(file) {
        cat("\n🗺️ EXPORTING: KML\n")
        cat("  Destination:", input$destination, "\n")
        
        tryCatch({
          if (is.null(rv$itinerary_data) || length(rv$itinerary_data) == 0) {
            stop("No itinerary generated yet")
          }
          
          placemarks <- c()
          total <- 0
          
          for (day in rv$itinerary_data) {
            if (is.null(day$attractions)) next
            placemarks <- c(placemarks, paste0("<Folder><name>", esc_xml(day$day_label %||% paste0("Day ", day$day)), "</name>"))
            for (attr in day$attractions) {
              lat <- suppressWarnings(as.numeric(attr$latitude))
              lon <- suppressWarnings(as.numeric(attr$longitude))
              if (length(lat) != 1 || is.na(lat) || length(lon) != 1 || is.na(lon)) next
              total <- total + 1
              placemarks <- c(placemarks,
                "<Placemark>",
                paste0("<name>", esc_xml(attr$name), "</name>"),
                paste0("<description>", esc_xml(paste0(attr$time_start, " - ", attr$time_end, ": ", attr$description)), "</description>"),
                paste0("<Point><coordinates>", lon, ",", lat, ",0</coordinates></Point>"),
                "</Placemark>"
              )
            }
            placemarks <- c(placemarks, "</Folder>")
          }
          
          cat("  📍 Found", total, "attractions\n")
          
          if (total == 0) stop("No GPS coordinates available to export")
          
          kml <- c(
            "<?xml version='1.0' encoding='UTF-8'?>",
            "<kml xmlns='http://www.opengis.net/kml/2.2'><Document>",
            paste0("<name>", esc_xml(input$destination), " Itinerary</name>"),
            placemarks,
            "</Document></kml>"
          )
          
          writeLines(kml, file)
          cat("  ✅ KML generated\n")
          cat("  📊 File size:", format(file.size(file), big.mark = ","), "bytes\n")
          
        }, error = function(e) {
          cat("  ❌ KML error:", e$message, "\n")
          writeLines(c(
            "<?xml version='1.0' encoding='UTF-8'?>",
            "<kml xmlns='http://www.opengis.net/kml/2.2'><Document>",
            paste0("<!-- ", esc_xml(e$message), " -->"),
            "</Document></kml>"
          ), file)
        })
      }
    )
    
    # ==================
    # DOWNLOADS - GPX (GPS Navigation)
    # ==================
    
    output$download_gpx <- downloadHandler(
      filename = function() { paste0(input$destination, "_itinerary.gpx") },
      contentType = "application/gpx+xml",
      content = function(file) {
        cat("\n📍 EXPORTING: GPX\n")
        cat("  Destination:", input$destination, "\n")
        
        tryCatch({
          if (is.null(rv$itinerary_data) || length(rv$itinerary_data) == 0) {
            stop("No itinerary generated yet")
          }
          
          waypoints <- c()
          total <- 0
          
          for (day in rv$itinerary_data) {
            if (is.null(day$attractions)) next
            for (attr in day$attractions) {
              lat <- suppressWarnings(as.numeric(attr$latitude))
              lon <- suppressWarnings(as.numeric(attr$longitude))
              if (length(lat) != 1 || is.na(lat) || length(lon) != 1 || is.na(lon)) next
              total <- total + 1
              waypoints <- c(waypoints,
                paste0("<wpt lat='", lat, "' lon='", lon, "'>"),
                paste0("<name>", esc_xml(attr$name), "</name>"),
                paste0("<desc>", esc_xml(paste0(day$day_label %||% "", " | ", attr$time_start, "-", attr$time_end, ": ", attr$description)), "</desc>"),
                "</wpt>"
              )
            }
          }
          
          cat("  📍 Found", total, "attractions\n")
          
          if (total == 0) stop("No GPS coordinates available to export")
          
          gpx <- c(
            "<?xml version='1.0' encoding='UTF-8'?>",
            "<gpx version='1.1' creator='Travel Itinerary Planner' xmlns='http://www.topografix.com/GPX/1/1'>",
            paste0("<metadata><name>", esc_xml(input$destination), " Itinerary</name></metadata>"),
            waypoints,
            "</gpx>"
          )
          
          writeLines(gpx, file)
          cat("  ✅ GPX generated\n")
          cat("  📊 File size:", format(file.size(file), big.mark = ","), "bytes\n")
          
        }, error = function(e) {
          cat("  ❌ GPX error:", e$message, "\n")
          writeLines(c(
            "<?xml version='1.0' encoding='UTF-8'?>",
            "<gpx version='1.1' xmlns='http://www.topografix.com/GPX/1/1'></gpx>"
          ), file)
        })
      }
    )
    
    # ==================
    # DOWNLOADS - GOOGLE MAPS LINK
    # ==================
    
    output$download_google_maps_url <- downloadHandler(
      filename = function() { paste0(input$destination, "_google_maps_link.url") },
      contentType = "text/plain",
      content = function(file) {
        cat("\n🔗 EXPORTING: Google Maps Link\n")
        cat("  Destination:", input$destination, "\n")
        
        tryCatch({
          coords <- get_all_coords(rv$itinerary_data)
          
          if (length(coords$lats) == 0) stop("No GPS coordinates available to export")
          
          cat("  📍 Found", length(coords$lats), "attractions\n")
          
          n <- length(coords$lats)
          origin <- paste0(coords$lats[1], ",", coords$lons[1])
          destination <- paste0(coords$lats[n], ",", coords$lons[n])
          
          if (n > 2) {
            mid_idx <- seq(2, n - 1)
            # Google's Directions URL supports ~23 intermediate waypoints
            if (length(mid_idx) > 23) mid_idx <- unique(round(seq(mid_idx[1], mid_idx[length(mid_idx)], length.out = 23)))
            waypoints_str <- paste(sapply(mid_idx, function(i) paste0(coords$lats[i], ",", coords$lons[i])), collapse = "|")
            maps_url <- paste0("https://www.google.com/maps/dir/?api=1&origin=", origin,
                               "&destination=", destination, "&waypoints=", waypoints_str)
          } else {
            maps_url <- paste0("https://www.google.com/maps/dir/?api=1&origin=", origin, "&destination=", destination)
          }
          
          # .url is a Windows Internet Shortcut - double-clicking it opens the
          # link directly in the browser. Also perfectly readable as plain text
          # on any OS if opened in a text editor.
          writeLines(c("[InternetShortcut]", paste0("URL=", maps_url)), file)
          
          cat("  ✅ Google Maps link generated\n")
          cat("  🔗", maps_url, "\n")
          
        }, error = function(e) {
          cat("  ❌ Google Maps link error:", e$message, "\n")
          writeLines(c("[InternetShortcut]", "URL=https://www.google.com/maps"), file)
        })
      }
    )
    
    # ==================
    # DOWNLOADS - ICS CALENDAR
    # ==================
    
    output$download_calendar <- downloadHandler(
      filename = function() { paste0(input$destination, "_itinerary.ics") },
      content = function(file) {
        tryCatch({
          if (is.null(rv$itinerary_data) || length(rv$itinerary_data) == 0) {
            writeLines("BEGIN:VCALENDAR\nVERSION:2.0\nEND:VCALENDAR", file)
            return()
          }
          
          trip_start <- input$trip_start_date
          events <- c()
          
          for (day_idx in seq_along(rv$itinerary_data)) {
            day <- rv$itinerary_data[[day_idx]]
            if (is.null(day$attractions)) next
            
            current_date <- trip_start + (day$day - 1)
            
            for (attr in day$attractions) {
              if (is.null(attr$name)) next
              
              time_parts_start <- strsplit(attr$time_start, ":")[[1]]
              time_parts_end <- strsplit(attr$time_end, ":")[[1]]
              
              dtstart <- paste0(format(current_date, "%Y%m%d"), "T", 
                              time_parts_start[1], time_parts_start[2], "00")
              dtend <- paste0(format(current_date, "%Y%m%d"), "T", 
                            time_parts_end[1], time_parts_end[2], "00")
              
              uid <- paste0("trip-", gsub(" ", "-", attr$name), "-", day$day)
              
              events <- c(events,
                "BEGIN:VEVENT",
                paste0("UID:", uid, "@travelplanner"),
                paste0("DTSTAMP:", format(Sys.time(), "%Y%m%dT%H%M%SZ")),
                paste0("DTSTART:", dtstart),
                paste0("DTEND:", dtend),
                paste0("SUMMARY:", attr$name),
                paste0("DESCRIPTION:", gsub("\n", "\\\\n", attr$description %||% "")),
                "STATUS:CONFIRMED",
                "END:VEVENT"
              )
            }
          }
          
          ics <- c(
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//Travel Planner//Travel Itinerary",
            "CALSCALE:GREGORIAN",
            events,
            "END:VCALENDAR"
          )
          
          writeLines(ics, file)
          cat("✅ ICS generated\n")
          
        }, error = function(e) {
          cat("ICS error:", e$message, "\n")
          writeLines("BEGIN:VCALENDAR\nVERSION:2.0\nEND:VCALENDAR", file)
        })
      }
    )
    
    # ==================
    # RESET
    # ==================
    
    observeEvent(input$reset_discovery, {
      cat("\n🔍 [RESET]\n")
      rv$discovered_places <- NULL
      rv$places_data <- NULL
      rv$generated_itinerary <- NULL
      rv$itinerary_data <- NULL
      rv$selected_attraction <- NULL
      rv$map_image_path <- NULL
    })
    
    output$discovery_status <- renderUI(NULL)
    output$places_checkboxes <- renderUI(NULL)
    output$places_counter <- renderUI(NULL)
  })
}
