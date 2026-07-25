# modules/visualizations/server.R

visualizations_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    viz_data <- reactiveVal(NULL)
    
    # Day Type -> Country -> Date cascade, refreshed whenever state_trigger
    # fires (e.g. after any new BigQuery upload elsewhere in the app)
    viz_taxonomy <- reactive({
      api_manager$state_trigger()
      if (!api_manager$bq_authenticated) {
        return(data.frame(day_type = character(), country = character(),
                           city = character(), schedule_date = character(),
                           stringsAsFactors = FALSE))
      }
      tryCatch(api_manager$bq_get_taxonomy(), error = function(e) {
        data.frame(day_type = character(), country = character(),
                   city = character(), schedule_date = character(),
                   stringsAsFactors = FALSE)
      })
    })
    
    observeEvent(viz_taxonomy(), {
      tax <- viz_taxonomy()
      day_types <- sort(unique(tax$day_type[nchar(trimws(tax$day_type)) > 0]))
      
      current <- isolate(input$viz_day_type)
      
      if (length(day_types) == 0) {
        updateSelectInput(session, "viz_day_type", choices = c("(no schedules yet)" = ""))
      } else {
        selected <- if (!is.null(current) && current %in% day_types) current else day_types[1]
        updateSelectInput(session, "viz_day_type", choices = setNames(day_types, day_types), selected = selected)
      }
    }, ignoreNULL = FALSE)
    
    observeEvent(input$viz_day_type, {
      tax <- viz_taxonomy()
      
      if (is.null(input$viz_day_type) || input$viz_day_type == "") {
        updateSelectInput(session, "viz_country", choices = c("(select a type first)" = ""))
        return()
      }
      
      countries <- sort(unique(tax$country[tax$day_type == input$viz_day_type & nchar(trimws(tax$country)) > 0]))
      
      if (length(countries) == 0) {
        updateSelectInput(session, "viz_country", choices = c("N/A" = "N/A"))
      } else {
        updateSelectInput(session, "viz_country", choices = setNames(countries, countries))
      }
    }, ignoreInit = TRUE)
    
    observeEvent(input$viz_country, {
      tax <- viz_taxonomy()
      
      if (is.null(input$viz_day_type) || is.null(input$viz_country) ||
          input$viz_day_type == "" || input$viz_country == "") {
        updateSelectInput(session, "select_date", choices = c("(select a country first)" = ""))
        return()
      }
      
      subset_rows <- tax[tax$day_type == input$viz_day_type & tax$country == input$viz_country, ]
      dates <- sort(unique(subset_rows$schedule_date), decreasing = TRUE)
      
      if (length(dates) == 0) {
        updateSelectInput(session, "select_date", choices = c("(no dates found)" = ""))
      } else {
        city_lookup <- subset_rows[!duplicated(subset_rows$schedule_date), c("schedule_date", "city")]
        labels <- paste0(city_lookup$schedule_date,
                          ifelse(nchar(trimws(city_lookup$city)) > 0 & city_lookup$city != "N/A",
                                 paste0(" — ", city_lookup$city), ""))
        updateSelectInput(session, "select_date",
                          choices = setNames(city_lookup$schedule_date, labels))
      }
    }, ignoreInit = TRUE)
    
    # Update row-type filter dropdown when date selected
    observeEvent(input$select_date, {
      if (!api_manager$bq_authenticated || is.null(input$select_date) || input$select_date == "") return()
      
      tryCatch({
        safe_date <- safe_sql_escape(input$select_date)
        query <- sprintf("SELECT DISTINCT row_type FROM `%s` WHERE schedule_date = '%s' ORDER BY row_type",
                         api_manager$bq_full_table_id, safe_date)
        row_types <- api_manager$bq_query(query)
        
        if (nrow(row_types) > 0) {
          updateSelectInput(session, "filter_row_type",
                            choices = c("All Rows" = "all",
                                        setNames(row_types$row_type, row_types$row_type)))
        }
      }, error = function(e) {})
    })
    
    # Load visualizations
    observeEvent(input$load_viz, {
      
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      
      if (is.null(input$select_date) || input$select_date == "") {
        showNotification("Please select a date!", type = "warning")
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Loading visualization data...")
      })
      
      tryCatch({
        safe_date <- safe_sql_escape(input$select_date)
        
        if (input$filter_row_type == "all") {
          query <- sprintf("SELECT * FROM `%s` WHERE schedule_date = '%s' ORDER BY row_sequence",
                           api_manager$bq_full_table_id, safe_date)
        } else {
          safe_row_type <- safe_sql_escape(input$filter_row_type)
          query <- sprintf("SELECT * FROM `%s` WHERE schedule_date = '%s' AND row_type = '%s' ORDER BY row_sequence",
                           api_manager$bq_full_table_id, safe_date, safe_row_type)
        }
        
        data <- api_manager$bq_query(query)
        
        if (nrow(data) == 0) {
          output$status <- renderUI({
            tags$div(class = "status-warning",
                     tags$i(class = "fa fa-exclamation-triangle"),
                     " No data found")
          })
          return()
        }
        
        viz_data(data)
        
        # Day header (reuses .book-header exactly as provided)
        location_line <- if (identical(data$day_type[1], "Travel") &&
                              !is.na(data$city[1]) && data$city[1] != "N/A") {
          paste0(data$city[1], ", ", data$country[1])
        } else {
          data$day_type[1]
        }
        
        output$day_header <- renderUI({
          tags$div(class = "book-header",
                   tags$h2(data$schedule_date[1]),
                   tags$div(class = "author", tags$i(class = "fa fa-tag"), " ", location_line))
        })
        
        # Metrics
        output$total_locations <- renderValueBox({
          valueBox(sum(data$row_type == "Location"), "Locations", icon = icon("map-pin"), color = "aqua")
        })
        
        output$total_transport <- renderValueBox({
          valueBox(sum(data$row_type == "Transport"), "Transport Legs", icon = icon("route"), color = "blue")
        })
        
        summary_row <- data[data$row_type == "Summary", ]
        total_time_val <- if (nrow(summary_row) > 0) summary_row$recommended_time[1] else "—"
        
        output$total_time <- renderValueBox({
          valueBox(total_time_val, "Total Day Time", icon = icon("clock"), color = "yellow")
        })
        
        output$total_entries <- renderValueBox({
          valueBox(nrow(data), "Total Entries", icon = icon("database"), color = "green")
        })
        
        # Itinerary Timeline - ONE viz-card for the day, rows as sections
        # divided by <hr>, exactly mirroring the book app's single-card
        # pattern (chapter card containing multiple section entries).
        output$timeline_html <- renderUI({
          
          html_parts <- c('<div class="viz-card">')
          html_parts <- c(html_parts, sprintf('<div class="chapter-title"><i class="fa fa-calendar-day"></i> %s Itinerary</div>',
                                              as.character(data$schedule_date[1])))
          
          row_icon <- function(rt) {
            switch(rt,
                   "Location" = "fa fa-map-pin",
                   "Transport" = "fa fa-route",
                   "Summary" = "fa fa-flag-checkered",
                   "fa fa-circle")
          }
          
          for (i in seq_len(nrow(data))) {
            row <- data[i, ]
            
            html_parts <- c(html_parts, sprintf('<div class="section-tag"><i class="%s"></i> %s: %s</div>',
                                                row_icon(as.character(row$row_type)),
                                                as.character(row$row_type),
                                                as.character(row$location_name)))
            html_parts <- c(html_parts, sprintf('<div class="details-text">%s</div>', as.character(row$location_details)))
            
            # Opening hours + recommended time as metric boxes (reused columns)
            if (row$row_type == "Location" && !is.na(row$opening_hours) &&
                trimws(as.character(row$opening_hours)) != "" &&
                tolower(trimws(as.character(row$opening_hours))) != "n/a") {
              html_parts <- c(html_parts, sprintf(
                '<div class="metric-box"><div class="metric-label">Opening Hours</div><div class="metric-value" style="font-size: 1em;">%s</div></div>',
                as.character(row$opening_hours)))
            }
            
            if (!is.na(row$recommended_time) && trimws(as.character(row$recommended_time)) != "") {
              html_parts <- c(html_parts, sprintf(
                '<div class="metric-box"><div class="metric-label">Recommended / Expected Time</div><div class="metric-value" style="font-size: 1em;">%s</div></div>',
                as.character(row$recommended_time)))
            }
            
            # Observations (reused column: what to expect / how-to / day insight)
            if (!is.na(row$observations) && trimws(as.character(row$observations)) != "") {
              html_parts <- c(html_parts, '<div class="reference-box">')
              html_parts <- c(html_parts, sprintf('<h5><i class="fa fa-lightbulb"></i> %s</h5>',
                                                  if (row$row_type == "Summary") "Key Insights" else "What to Expect"))
              html_parts <- c(html_parts, sprintf('<p style="margin-top: 8px; color: #555;">%s</p>',
                                                  as.character(row$observations)))
              html_parts <- c(html_parts, '</div>')
            }
            
            if (i < nrow(data)) {
              html_parts <- c(html_parts, '<hr style="margin: 20px 0; border-top: 1px solid #e0e0e0;">')
            }
          }
          
          html_parts <- c(html_parts, '</div>')
          
          HTML(paste(html_parts, collapse = ""))
        })
        
        # Time allocation chart
        output$time_chart <- renderPlotly({
          chart_data <- data.frame(stop = character(), row_type = character(), minutes = numeric(),
                                   stringsAsFactors = FALSE)
          
          plot_rows <- data[data$row_type %in% c("Location", "Transport"), ]
          
          for (i in seq_len(nrow(plot_rows))) {
            row <- plot_rows[i, ]
            mins <- parse_duration_minutes(row$recommended_time)
            if (!is.na(mins)) {
              chart_data <- rbind(chart_data, data.frame(
                stop = paste0(row$row_sequence, ". ", row$location_name),
                row_type = row$row_type,
                minutes = mins,
                stringsAsFactors = FALSE
              ))
            }
          }
          
          if (nrow(chart_data) == 0) {
            return(plot_ly() %>% layout(title = "No parsable durations available"))
          }
          
          chart_data$stop <- factor(chart_data$stop, levels = chart_data$stop)
          
          plot_ly(chart_data, x = ~stop, y = ~minutes, color = ~row_type,
                  type = 'bar') %>%
            layout(title = "Estimated Minutes per Stop",
                   xaxis = list(title = "", tickangle = -35),
                   yaxis = list(title = "Minutes"))
        })
        
        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded visualizations for %s (%d entries)", data$schedule_date[1], nrow(data)))
        })
        
        showNotification("✓ Visualizations loaded!", type = "message")
        
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Default outputs
    output$status <- renderUI({ tags$div() })
    output$day_header <- renderUI({ tags$div() })
    output$timeline_html <- renderUI({ tags$div() })
    output$time_chart <- renderPlotly({ plot_ly() })
    
    output$total_locations <- renderValueBox({
      valueBox(0, "Locations", icon = icon("map-pin"), color = "aqua")
    })
    output$total_transport <- renderValueBox({
      valueBox(0, "Transport Legs", icon = icon("route"), color = "blue")
    })
    output$total_time <- renderValueBox({
      valueBox("—", "Total Day Time", icon = icon("clock"), color = "yellow")
    })
    output$total_entries <- renderValueBox({
      valueBox(0, "Total Entries", icon = icon("database"), color = "green")
    })
    
    session$onSessionEnded(function() {})
  })
}
