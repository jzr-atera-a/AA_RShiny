# modules/Travel Planning/travel_itinerary_planner/server.R
# Travel Itinerary Planner Server Logic with Claude API

travel_itinerary_planner_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    
    # ==================
    # Reactive Values
    # ==================
    rv <- reactiveValues(
      discovered_places = NULL,
      selected_places = character(0),
      generated_itinerary = NULL,
      places_data = NULL
    )
    
    # ==================
    # STEP 1: DISCOVER PLACES
    # ==================
    observeEvent(input$discover_places, {
      req(input$destination, input$num_places)
      
      # Show loading spinner
      shinyjs::hide("places_checkboxes", anim = TRUE)
      shinyjs::show("loading_spinner", anim = TRUE)
      output$discovery_status <- renderUI({
        tags$div(class = "alert alert-info",
                tags$strong("Status: "), "Discovering attractions in ", input$destination, "...")
      })
      
      tryCatch({
        # Build prompt for Claude
        prompt <- paste0(
          "Please provide the top ", input$num_places, " places to visit in ", input$destination, 
          " according to TripAdvisor and other reputable tourism sources.\n\n",
          "Format your response EXACTLY as follows - one place per line, numbered:\n",
          "1. Attraction Name (Category)\n",
          "2. Another Attraction (Category)\n",
          "... and so on\n\n",
          "Categories can be: Museum, Park, Landmark, Restaurant, Historical Site, Shopping, ",
          "Entertainment, Nature, Cultural Site, etc.\n\n",
          "Only provide the numbered list with no additional text or explanations."
        )
        
        # Call Claude API
        if (!is.null(api_manager)) {
          response <- api_manager$call_claude_api(prompt)
        } else {
          stop("API Manager not available. Please configure Claude API credentials first.")
        }
        
        # Parse response into places
        lines <- strsplit(response, "\n")[[1]]
        places_list <- grep("^\\d+\\.", lines, value = TRUE)
        places_list <- trimws(places_list)
        places_list <- places_list[places_list != ""]
        
        if (length(places_list) == 0) {
          stop("No places found in response. Please try again.")
        }
        
        # Store places data
        rv$places_data <- data.frame(
          id = seq_along(places_list),
          name = places_list,
          selected = FALSE,
          stringsAsFactors = FALSE
        )
        
        rv$discovered_places <- places_list
        rv$selected_places <- character(0)
        
        # Hide loading, show places
        shinyjs::hide("loading_spinner", anim = TRUE)
        shinyjs::show("places_checkboxes", anim = TRUE)
        
        output$discovery_status <- renderUI({
          tags$div(class = "alert alert-success",
                  tags$strong("✓ Success! "), "Found ", length(places_list), " attractions in ", 
                  input$destination, ". Select the ones you want to visit.")
        })
        
        # Render checkboxes
        output$places_checkboxes <- renderUI({
          if (is.null(rv$places_data)) return(NULL)
          
          lapply(1:nrow(rv$places_data), function(i) {
            div(
              style = "margin-bottom: 10px;",
              checkboxInput(ns(paste0("place_", i)), 
                          rv$places_data$name[i],
                          value = FALSE),
              tags$small(class = "text-muted", style = "margin-left: 20px;")
            )
          })
        })
        
      }, error = function(e) {
        shinyjs::hide("loading_spinner", anim = TRUE)
        output$discovery_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  tags$strong("Error: "), e$message)
        })
        showNotification(paste("Error discovering places:", e$message), type = "error", duration = 10)
      })
    })
    
    # Update selected places count
    output$places_counter <- renderUI({
      req(rv$places_data)
      selected_count <- sum(sapply(1:nrow(rv$places_data), function(i) {
        isTRUE(input[[paste0("place_", i)]])
      }))
      tags$span(tags$strong("Selected: "), selected_count, " / ", nrow(rv$places_data))
    })
    
    # Select all places
    observeEvent(input$select_all_places, {
      if (!is.null(rv$places_data)) {
        for (i in 1:nrow(rv$places_data)) {
          shinyjs::runjs(paste0("$('#", ns(paste0("place_", i)), "').prop('checked', true).change();"))
        }
      }
    })
    
    # Deselect all places
    observeEvent(input$deselect_all_places, {
      if (!is.null(rv$places_data)) {
        for (i in 1:nrow(rv$places_data)) {
          shinyjs::runjs(paste0("$('#", ns(paste0("place_", i)), "').prop('checked', false).change();"))
        }
      }
    })
    
    # Reset discovery
    observeEvent(input$reset_discovery, {
      rv$discovered_places <- NULL
      rv$selected_places <- character(0)
      rv$places_data <- NULL
      output$places_checkboxes <- renderUI(NULL)
      output$discovery_status <- renderUI(NULL)
      shinyjs::show("places_checkboxes", anim = TRUE)
      shinyjs::hide("loading_spinner", anim = TRUE)
    })
    
    # ==================
    # STEP 2 & 3: GENERATE ITINERARY
    # ==================
    observeEvent(input$generate_itinerary, {
      req(input$destination, input$num_days)
      
      # Get selected places
      if (!is.null(rv$places_data)) {
        selected_indices <- which(sapply(1:nrow(rv$places_data), function(i) {
          isTRUE(input[[paste0("place_", i)]])
        }))
        
        if (length(selected_indices) == 0) {
          showNotification("Please select at least one place to visit!", type = "warning")
          return()
        }
        
        selected_places_list <- rv$places_data$name[selected_indices]
      } else {
        showNotification("Please discover places first!", type = "warning")
        return()
      }
      
      # Show loading spinner
      shinyjs::show("itinerary_loading_spinner", anim = TRUE)
      shinyjs::hide("itinerary_content", anim = TRUE)
      output$itinerary_status <- renderUI({
        tags$div(class = "alert alert-info",
                tags$strong("Status: "), "Generating your personalized itinerary...")
      })
      
      tryCatch({
        # Build comprehensive prompt for itinerary generation
        selected_places_text <- paste(sprintf("- %s", selected_places_list), collapse = "\n")
        
        constraints_text <- if (input$constraints == "") {
          "No specific constraints."
        } else {
          paste("User constraints:\n", input$constraints)
        }
        
        prompt <- paste0(
          "Create a detailed ", input$num_days, "-day itinerary for visiting ", input$destination, ".\n\n",
          "SELECTED ATTRACTIONS (must include all of these):\n",
          selected_places_text, "\n\n",
          "TRIP PARAMETERS:\n",
          "- Days: ", input$num_days, "\n",
          "- Daily start time: ", input$start_time, "\n",
          "- Daily end time: ", input$end_time, "\n",
          "- Location: ", input$destination, "\n\n",
          "CONSTRAINTS:\n", constraints_text, "\n\n",
          "REQUIREMENTS FOR YOUR RESPONSE:\n",
          "1. Create a day-by-day breakdown\n",
          "2. Include exact times for each activity (e.g., 9:00-11:00 AM: CN Tower)\n",
          "3. Include travel time between attractions using public transit estimates\n",
          "4. Include 1-2 meal breaks per day\n",
          "5. Group nearby attractions to minimize travel\n",
          "6. Provide realistic visit durations based on the attraction type\n",
          "7. Include subway lines, streetcars, or walking directions where applicable\n",
          "8. Format as clear, readable text with day headers (e.g., 'DAY 1: ...')\n",
          "9. Include opening hours verification where relevant\n",
          "10. Add tips for each day regarding best times to visit, what to bring, etc.\n\n",
          "Please create the itinerary now, optimized for minimum travel distance between attractions."
        )
        
        # Call Claude API
        if (!is.null(api_manager)) {
          itinerary_response <- api_manager$call_claude_api(prompt)
        } else {
          stop("API Manager not available. Please configure Claude API credentials first.")
        }
        
        # Store generated itinerary
        rv$generated_itinerary <- itinerary_response
        
        # Hide loading, show content
        shinyjs::hide("itinerary_loading_spinner", anim = TRUE)
        shinyjs::show("itinerary_content", anim = TRUE)
        
        output$itinerary_html <- renderUI({
          # Format the itinerary with better readability
          itinerary_formatted <- gsub("\\n", "<br/>", itinerary_response)
          itinerary_formatted <- gsub("DAY (\\d+)", "<h3 style='color: #27ae60; margin-top: 20px;'>DAY \\1</h3>", 
                                     itinerary_formatted)
          
          HTML(paste0(
            "<div style='background-color: #f9f9f9; padding: 20px; border-radius: 4px; ",
            "border-left: 4px solid #27ae60;'>",
            itinerary_formatted,
            "</div>"
          ))
        })
        
        output$itinerary_status <- renderUI({
          tags$div(class = "alert alert-success",
                  tags$strong("✓ Itinerary Generated! "),
                  "Your ", input$num_days, "-day plan is ready. ",
                  "You can refine it, download it, or start a new search.",
                  style = "margin-top: 20px;")
        })
        
      }, error = function(e) {
        shinyjs::hide("itinerary_loading_spinner", anim = TRUE)
        output$itinerary_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  tags$strong("Error: "), e$message)
        })
        showNotification(paste("Error generating itinerary:", e$message), type = "error", duration = 10)
      })
    })
    
    # ==================
    # DOWNLOAD ITINERARY
    # ==================
    output$download_itinerary <- downloadHandler(
      filename = function() {
        paste0(input$destination, "_itinerary_", input$num_days, "days.txt")
      },
      content = function(file) {
        if (!is.null(rv$generated_itinerary)) {
          writeLines(rv$generated_itinerary, file)
        }
      }
    )
    
    # ==================
    # EXPORT FORMATS: HTML, PDF, CALENDAR
    # ==================
    
    # HTML Export (with map placeholder)
    output$download_html <- downloadHandler(
      filename = function() {
        paste0(input$destination, "_itinerary_", input$num_days, "days.html")
      },
      content = function(file) {
        if (!is.null(rv$generated_itinerary)) {
          # Format itinerary for HTML
          itinerary_html_content <- gsub("\\n", "</p><p>", rv$generated_itinerary)
          itinerary_html_content <- gsub("DAY (\\d+)", "<h2 style='color: #27ae60; page-break-before: avoid; margin-top: 30px;'>DAY \\1</h2>", 
                                        itinerary_html_content)
          
          html_content <- paste0(
            "<!DOCTYPE html>",
            "<html lang='en'>",
            "<head>",
            "  <meta charset='UTF-8'>",
            "  <meta name='viewport' content='width=device-width, initial-scale=1.0'>",
            "  <title>", input$destination, " - ", input$num_days, " Day Itinerary</title>",
            "  <style>",
            "    * { margin: 0; padding: 0; box-sizing: border-box; }",
            "    body { font-family: 'Segoe UI', Tahoma, Geneva, sans-serif; line-height: 1.6; color: #333; }",
            "    .container { max-width: 900px; margin: 0 auto; padding: 20px; }",
            "    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px; margin-bottom: 30px; text-align: center; }",
            "    .header h1 { font-size: 2.5em; margin-bottom: 10px; }",
            "    .header p { font-size: 1.1em; opacity: 0.9; }",
            "    .trip-info { background: #f0f7ff; border-left: 4px solid #667eea; padding: 15px; margin-bottom: 30px; border-radius: 4px; }",
            "    .trip-info p { margin: 8px 0; }",
            "    h2 { color: #27ae60; margin-top: 40px; margin-bottom: 15px; border-bottom: 2px solid #27ae60; padding-bottom: 10px; }",
            "    p { margin-bottom: 12px; text-align: justify; }",
            "    .map-section { margin: 40px 0; padding: 30px; background: #f5f5f5; border: 2px dashed #ccc; border-radius: 8px; text-align: center; }",
            "    .map-section h3 { color: #667eea; margin-bottom: 10px; }",
            "    .map-section p { color: #999; font-size: 0.95em; }",
            "    .footer { text-align: center; margin-top: 50px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 0.9em; }",
            "    @media print { .map-section { page-break-inside: avoid; } }",
            "    @media (max-width: 768px) { .header { padding: 20px; } .header h1 { font-size: 1.8em; } .container { padding: 15px; } }",
            "  </style>",
            "</head>",
            "<body>",
            "  <div class='container'>",
            "    <div class='header'>",
            "      <h1>🌍 ", input$destination, " Itinerary</h1>",
            "      <p>", input$num_days, "-Day Travel Plan</p>",
            "    </div>",
            "    <div class='trip-info'>",
            "      <p><strong>Destination:</strong> ", input$destination, "</p>",
            "      <p><strong>Duration:</strong> ", input$num_days, " day(s)</p>",
            "      <p><strong>Daily Hours:</strong> ", input$start_time, " - ", input$end_time, "</p>",
            "      <p><strong>Generated:</strong> ", format(Sys.time(), '%B %d, %Y at %H:%M'), "</p>",
            "    </div>",
            "    <div class='itinerary-content'>",
            "      <p>", itinerary_html_content, "</p>",
            "    </div>",
            "    <div class='map-section'>",
            "      <h3>📍 Interactive Map</h3>",
            "      <p>Map visualization showing all attractions and suggested routes.</p>",
            "      <p style='margin-top: 20px; padding: 20px; background: white; border-radius: 4px;'>[Map will be displayed here - optimized for your preferred map library]</p>",
            "    </div>",
            "    <div class='footer'>",
            "      <p>Generated by AI Travel Itinerary Planner | Print-friendly format</p>",
            "      <p>Open in any web browser or print to PDF for offline access</p>",
            "    </div>",
            "  </div>",
            "</body>",
            "</html>"
          )
          
          writeLines(html_content, file)
        }
      }
    )
    
    # PDF Export (mobile-friendly)
    output$download_pdf <- downloadHandler(
      filename = function() {
        paste0(input$destination, "_itinerary_", input$num_days, "days.pdf")
      },
      content = function(file) {
        if (!is.null(rv$generated_itinerary)) {
          tryCatch({
            # Create temporary markdown file for conversion
            temp_md <- tempfile(fileext = ".md")
            
            pdf_content <- paste0(
              "---\n",
              "title: '", input$destination, " - ", input$num_days, " Day Itinerary'\n",
              "author: 'AI Travel Planner'\n",
              "date: '", format(Sys.time(), '%B %d, %Y'), "'\n",
              "geometry: margin=0.5in\n",
              "mainfont: 'Arial'\n",
              "fontsize: 11pt\n",
              "---\n\n",
              "# 🌍 ", input$destination, " Itinerary\n\n",
              "**Duration:** ", input$num_days, " day(s)  \n",
              "**Daily Hours:** ", input$start_time, " - ", input$end_time, "  \n",
              "**Generated:** ", format(Sys.time(), '%B %d, %Y at %H:%M'), "\n\n",
              "---\n\n",
              rv$generated_itinerary, "\n\n",
              "---\n\n",
              "## 📍 Map & Transportation\n\n",
              "An interactive map showing all attractions and suggested routes will be displayed in the HTML version.\n",
              "For this PDF version, refer to Google Maps with the listed attractions for detailed directions.\n\n",
              "---\n\n",
              "*Generated by AI Travel Itinerary Planner*  \n",
              "*Mobile-optimized PDF format - readable on all devices*\n"
            )
            
            writeLines(pdf_content, temp_md)
            
            # Try using rmarkdown if available
            if (requireNamespace("rmarkdown", quietly = TRUE)) {
              rmarkdown::render(
                temp_md,
                output_format = rmarkdown::pdf_document(
                  highlight = "default",
                  toc = TRUE,
                  toc_depth = 2
                ),
                output_file = file,
                quiet = TRUE
              )
            } else {
              # Fallback: write markdown-formatted text
              writeLines(pdf_content, file)
            }
            
            unlink(temp_md)
          }, error = function(e) {
            # Fallback to text-based PDF content
            pdf_lines <- c(
              paste0("ITINERARY: ", input$destination, " - ", input$num_days, " DAYS"),
              paste0("Daily Hours: ", input$start_time, " - ", input$end_time),
              paste0("Generated: ", format(Sys.time(), '%B %d, %Y at %H:%M')),
              "",
              "---------------------------------------------",
              "",
              rv$generated_itinerary,
              "",
              "---------------------------------------------",
              "",
              "Mobile-friendly PDF format",
              "Readable on all devices",
              "",
              "Generated by AI Travel Itinerary Planner"
            )
            writeLines(pdf_lines, file)
          })
        }
      }
    )
    
    # Calendar (.ics) Export for Outlook, Google Calendar, etc.
    output$download_calendar <- downloadHandler(
      filename = function() {
        paste0(input$destination, "_itinerary_", input$num_days, "days.ics")
      },
      content = function(file) {
        if (!is.null(rv$generated_itinerary)) {
          tryCatch({
            # Parse itinerary to extract activities with times
            lines <- strsplit(rv$generated_itinerary, "\n")[[1]]
            
            # Create iCalendar format
            ics_content <- c(
              "BEGIN:VCALENDAR",
              "VERSION:2.0",
              "PRODID:-//AI Travel Planner//Travel Itinerary//EN",
              "CALSCALE:GREGORIAN",
              paste0("X-WR-CALNAME:", input$destination, " Itinerary"),
              paste0("X-WR-TIMEZONE:UTC"),
              paste0("DESCRIPTION:", input$destination, " - ", input$num_days, " Day Travel Plan"),
              ""
            )
            
            # Extract date for calendar (assume starting today)
            start_date <- Sys.Date()
            
            # Parse days and create events
            day_num <- 0
            current_time <- paste0(gsub(":", "", input$start_time), "00")
            
            for (i in seq_along(lines)) {
              line <- trimws(lines[i])
              
              # Check if line starts a new day
              if (grepl("^DAY\\s+\\d+", line, ignore.case = TRUE)) {
                day_num <- day_num + 1
                event_date <- format(start_date + (day_num - 1), "%Y%m%d")
              }
              
              # Look for time entries (HH:MM format)
              if (grepl("^\\d{1,2}:\\d{2}", line) && day_num > 0) {
                # Extract time and activity
                time_match <- regexpr("^\\d{1,2}:\\d{2}[AP]M", line)
                if (time_match != -1) {
                  time_str <- regmatches(line, time_match)
                  activity <- trimws(sub("^\\d{1,2}:\\d{2}[AP]M\\s*-?\\s*", "", line))
                  
                  if (activity != "" && nchar(activity) > 0) {
                    # Convert time to 24hr format for iCal
                    time_24 <- convert_to_24hr(time_str)
                    
                    # Create event
                    event_start <- paste0(event_date, "T", time_24, "00Z")
                    event_end <- paste0(event_date, "T", 
                                       add_minutes_to_time(time_24, 120), "00Z")
                    
                    ics_content <- c(
                      ics_content,
                      "BEGIN:VEVENT",
                      paste0("UID:travel-", day_num, "-", i, "@travelplanner.local"),
                      paste0("DTSTAMP:", format(Sys.time(), "%Y%m%dT%H%M%SZ")),
                      paste0("DTSTART:", event_start),
                      paste0("DTEND:", event_end),
                      paste0("SUMMARY:", activity),
                      paste0("DESCRIPTION:Activity in ", input$destination, " itinerary"),
                      "STATUS:CONFIRMED",
                      "SEQUENCE:0",
                      "END:VEVENT",
                      ""
                    )
                  }
                }
              }
            }
            
            ics_content <- c(ics_content, "END:VCALENDAR")
            writeLines(ics_content, file)
            
          }, error = function(e) {
            # Fallback: create basic calendar with full itinerary as single event
            event_date <- format(Sys.Date(), "%Y%m%d")
            event_start <- paste0(event_date, "T090000Z")
            event_end <- paste0(event_date, "T170000Z")
            
            ics_lines <- c(
              "BEGIN:VCALENDAR",
              "VERSION:2.0",
              "PRODID:-//AI Travel Planner//Travel Itinerary//EN",
              "CALSCALE:GREGORIAN",
              paste0("X-WR-CALNAME:", input$destination, " Itinerary"),
              "BEGIN:VEVENT",
              paste0("UID:travel-main@travelplanner.local"),
              paste0("DTSTAMP:", format(Sys.time(), "%Y%m%dT%H%M%SZ")),
              paste0("DTSTART:", event_start),
              paste0("DTEND:", event_end),
              paste0("SUMMARY:", input$destination, " - ", input$num_days, " Day Trip"),
              paste0("DESCRIPTION:", gsub("\n", "\\n", rv$generated_itinerary)),
              "STATUS:CONFIRMED",
              "END:VEVENT",
              "END:VCALENDAR"
            )
            
            writeLines(ics_lines, file)
          })
        }
      }
    )
    
    # Helper function: Convert 12-hour time to 24-hour format
    convert_to_24hr <- function(time_str) {
      time_str <- trimws(time_str)
      is_pm <- grepl("PM|pm", time_str)
      time_clean <- gsub("[APap][Mm]", "", time_str)
      parts <- strsplit(time_clean, ":")[[1]]
      
      if (length(parts) == 2) {
        hour <- as.numeric(parts[1])
        min <- as.numeric(parts[2])
        
        if (is_pm && hour != 12) {
          hour <- hour + 12
        } else if (!is_pm && hour == 12) {
          hour <- 0
        }
        
        return(sprintf("%02d%02d", hour, min))
      }
      return("090000")
    }
    
    # Helper function: Add minutes to time
    add_minutes_to_time <- function(time_str, minutes) {
      hour <- as.numeric(substr(time_str, 1, 2))
      min <- as.numeric(substr(time_str, 3, 4))
      
      total_min <- hour * 60 + min + minutes
      new_hour <- (total_min %/% 60) %% 24
      new_min <- total_min %% 60
      
      sprintf("%02d%02d", new_hour, new_min)
    }
    
    # ==================
    # SHARE & REFINE
    # ==================
    observeEvent(input$share_itinerary, {
      showNotification("Share functionality coming soon! Copy-paste the itinerary or download it.",
                      type = "info")
    })
    
    observeEvent(input$refine_itinerary, {
      showNotification("Refinement options will allow you to adjust timing, add/remove places, or change constraints.",
                      type = "info")
    })
    
    # Start over
    observeEvent(input$start_over, {
      rv$discovered_places <- NULL
      rv$selected_places <- character(0)
      rv$places_data <- NULL
      rv$generated_itinerary <- NULL
      output$places_checkboxes <- renderUI(NULL)
      output$discovery_status <- renderUI(NULL)
      output$itinerary_html <- renderUI(NULL)
      output$itinerary_status <- renderUI(NULL)
      shinyjs::hide("itinerary_content", anim = TRUE)
      shinyjs::hide("itinerary_loading_spinner", anim = TRUE)
      shinyjs::show("places_checkboxes", anim = TRUE)
    })
    
    # Initialize
    output$discovery_status <- renderUI(NULL)
    output$places_checkboxes <- renderUI(NULL)
    output$itinerary_status <- renderUI(NULL)
    shinyjs::hide("loading_spinner", anim = TRUE)
    shinyjs::hide("itinerary_loading_spinner", anim = TRUE)
  })
}
