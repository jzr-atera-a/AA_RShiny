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
      selected_attraction = NULL
    )
    
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
    # DOWNLOADS - HIGH QUALITY HTML
    # ==================
    
    output$download_html <- downloadHandler(
      filename = function() { paste0(input$destination, "_itinerary.html") },
      content = function(file) {
        tryCatch({
          # Build HTML from structured itinerary
          html_content <- c(
            "<!DOCTYPE html>",
            "<html lang=\"en\">",
            "<head>",
            "  <meta charset=\"UTF-8\">",
            "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
            paste0("  <title>", input$destination, " Itinerary</title>"),
            "  <style>",
            "    * { margin: 0; padding: 0; box-sizing: border-box; }",
            "    body {",
            "      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;",
            "      line-height: 1.6;",
            "      color: #333;",
            "      background-color: #f5f5f5;",
            "      padding: 20px;",
            "    }",
            "    .container {",
            "      max-width: 900px;",
            "      margin: 0 auto;",
            "      background-color: white;",
            "      padding: 40px;",
            "      border-radius: 8px;",
            "      box-shadow: 0 2px 10px rgba(0,0,0,0.1);",
            "    }",
            "    .header {",
            "      border-bottom: 3px solid #2196F3;",
            "      padding-bottom: 20px;",
            "      margin-bottom: 30px;",
            "    }",
            "    .header h1 {",
            "      color: #2196F3;",
            "      font-size: 2.5em;",
            "      margin-bottom: 10px;",
            "    }",
            "    .trip-info {",
            "      background-color: #e3f2fd;",
            "      padding: 15px;",
            "      border-radius: 4px;",
            "      margin-bottom: 20px;",
            "    }",
            "    .trip-info p {",
            "      margin: 5px 0;",
            "    }",
            "    .day-section {",
            "      margin-bottom: 40px;",
            "      page-break-inside: avoid;",
            "    }",
            "    .day-header {",
            "      background: linear-gradient(135deg, #2196F3, #1976D2);",
            "      color: white;",
            "      padding: 15px;",
            "      border-radius: 4px;",
            "      margin-bottom: 15px;",
            "      font-size: 1.3em;",
            "      font-weight: bold;",
            "    }",
            "    .attraction {",
            "      border-left: 4px solid #2196F3;",
            "      padding: 15px;",
            "      margin-bottom: 15px;",
            "      background-color: #f9f9f9;",
            "      border-radius: 4px;",
            "      page-break-inside: avoid;",
            "    }",
            "    .attraction-name {",
            "      font-size: 1.2em;",
            "      font-weight: bold;",
            "      color: #1976D2;",
            "      margin-bottom: 8px;",
            "    }",
            "    .attraction-time {",
            "      background-color: #e3f2fd;",
            "      padding: 8px 12px;",
            "      border-radius: 4px;",
            "      display: inline-block;",
            "      font-weight: bold;",
            "      color: #1976D2;",
            "      margin-bottom: 10px;",
            "    }",
            "    .attraction-description {",
            "      margin: 10px 0;",
            "      line-height: 1.6;",
            "    }",
            "    .attraction-coords {",
            "      font-size: 0.9em;",
            "      color: #999;",
            "      margin-top: 8px;",
            "    }",
            "    .footer {",
            "      border-top: 1px solid #ddd;",
            "      padding-top: 20px;",
            "      margin-top: 40px;",
            "      text-align: center;",
            "      color: #999;",
            "      font-size: 0.9em;",
            "    }",
            "    @media print {",
            "      body { background: white; }",
            "      .container { box-shadow: none; padding: 0; }",
            "    }",
            "  </style>",
            "</head>",
            "<body>",
            "  <div class=\"container\">",
            "    <div class=\"header\">",
            paste0("      <h1>🌍 ", input$destination, " Itinerary</h1>"),
            "    </div>",
            "    <div class=\"trip-info\">",
            paste0("      <p><strong>Trip Duration:</strong> ", input$num_days, " day(s)</p>"),
            paste0("      <p><strong>Start Date:</strong> ", format(input$trip_start_date, "%A, %B %d, %Y"), "</p>"),
            paste0("      <p><strong>End Date:</strong> ", format(input$trip_end_date, "%A, %B %d, %Y"), "</p>"),
            "    </div>"
          )
          
          # Add day sections
          if (!is.null(rv$itinerary_data) && length(rv$itinerary_data) > 0) {
            for (day in rv$itinerary_data) {
              html_content <- c(html_content,
                paste0("    <div class=\"day-section\">"),
                paste0("      <div class=\"day-header\">", day$day_label, "</div>")
              )
              
              if (!is.null(day$attractions)) {
                for (attr in day$attractions) {
                  html_content <- c(html_content,
                    "      <div class=\"attraction\">",
                    paste0("        <div class=\"attraction-name\">", attr$name, "</div>"),
                    paste0("        <div class=\"attraction-time\">🕐 ", attr$time_start, " - ", attr$time_end, "</div>"),
                    paste0("        <div class=\"attraction-description\">", attr$description, "</div>"),
                    paste0("        <div class=\"attraction-coords\">📍 Latitude: ", round(attr$latitude, 4), ", Longitude: ", round(attr$longitude, 4), "</div>"),
                    "      </div>"
                  )
                }
              }
              
              html_content <- c(html_content, "    </div>")
            }
          }
          
          # Add footer
          html_content <- c(html_content,
            "    <div class=\"footer\">",
            paste0("      <p>Generated on ", format(Sys.time(), "%A, %B %d, %Y at %H:%M %Z"), "</p>"),
            "      <p>Travel Itinerary Planner - Powered by Claude AI</p>",
            "    </div>",
            "  </div>",
            "</body>",
            "</html>"
          )
          
          writeLines(html_content, file)
          cat("✅ HTML generated\n")
          
        }, error = function(e) {
          cat("HTML error:", e$message, "\n")
          writeLines("<html><body><p>Error generating HTML</p></body></html>", file)
        })
      }
    )
    
    # ==================
    # DOWNLOADS - HIGH QUALITY PDF
    # ==================
    
    output$download_pdf <- downloadHandler(
      filename = function() { paste0(input$destination, "_itinerary.pdf") },
      content = function(file) {
        tryCatch({
          # Create markdown content for PDF
          md_content <- c(
            "---",
            "title: \"Travel Itinerary\"",
            "author: \"Travel Planner\"",
            "date: \"" , format(Sys.Date(), "%B %d, %Y"), "\"",
            "output: pdf_document",
            "---",
            "",
            paste0("# 🌍 ", input$destination, " Itinerary"),
            "",
            "## Trip Information",
            "",
            paste0("- **Duration:** ", input$num_days, " day(s)"),
            paste0("- **Start Date:** ", format(input$trip_start_date, "%A, %B %d, %Y")),
            paste0("- **End Date:** ", format(input$trip_end_date, "%A, %B %d, %Y")),
            ""
          )
          
          # Add itinerary content
          if (!is.null(rv$itinerary_data) && length(rv$itinerary_data) > 0) {
            for (day in rv$itinerary_data) {
              md_content <- c(md_content,
                paste0("## ", day$day_label),
                ""
              )
              
              if (!is.null(day$attractions)) {
                for (idx in seq_along(day$attractions)) {
                  attr <- day$attractions[[idx]]
                  md_content <- c(md_content,
                    paste0("### ", idx, ". ", attr$name),
                    "",
                    paste0("**Time:** ", attr$time_start, " - ", attr$time_end),
                    "",
                    paste0("**Location:** ", round(attr$latitude, 4), ", ", round(attr$longitude, 4)),
                    "",
                    paste0(attr$description),
                    "",
                    "---",
                    ""
                  )
                }
              }
            }
          }
          
          md_content <- c(md_content,
            "## Notes",
            "",
            "- Plan transportation between attractions in advance",
            "- Check opening hours before visiting",
            "- Make restaurant reservations if needed",
            "",
            paste0("*Generated on ", format(Sys.time(), "%A, %B %d, %Y at %H:%M"), "*")
          )
          
          # Write temp markdown file
          temp_md <- tempfile(fileext = ".md")
          writeLines(md_content, temp_md)
          
          # Render to PDF
          rmarkdown::render(
            temp_md,
            output_file = file,
            output_format = "pdf_document",
            quiet = TRUE
          )
          
          cat("✅ PDF generated\n")
          
          # Clean up temp file
          unlink(temp_md)
          
        }, error = function(e) {
          cat("PDF error:", e$message, "\n")
          # Fallback: create simple text PDF
          tryCatch({
            temp_txt <- tempfile(fileext = ".txt")
            writeLines(c("Travel Itinerary", input$destination, "", 
                        "PDF generation requires rmarkdown and tinytex packages."), temp_txt)
            file.copy(temp_txt, file)
            unlink(temp_txt)
          }, error = function(e2) {
            cat("Fallback PDF error:", e2$message, "\n")
          })
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
    })
    
    output$discovery_status <- renderUI(NULL)
    output$places_checkboxes <- renderUI(NULL)
    output$places_counter <- renderUI(NULL)
  })
}
