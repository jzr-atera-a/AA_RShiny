# modules/visualizations/server.R

visualizations_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    viz_data <- reactiveVal(NULL)
    
    viz_taxonomy <- reactive({
      api_manager$state_trigger()
      if (!api_manager$bq_authenticated) {
        return(data.frame(category = character(), country = character(),
                           city_region = character(), stringsAsFactors = FALSE))
      }
      tryCatch(api_manager$bq_get_taxonomy(), error = function(e) {
        data.frame(category = character(), country = character(),
                   city_region = character(), stringsAsFactors = FALSE)
      })
    })
    
    observeEvent(viz_taxonomy(), {
      tax <- viz_taxonomy()
      
      categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
      updateSelectInput(session, "viz_category", choices = c("All" = "all", setNames(categories, categories)))
      
      countries <- sort(unique(tax$country[nchar(trimws(tax$country)) > 0]))
      updateSelectInput(session, "viz_country", choices = c("All" = "all", setNames(countries, countries)))
      
      updateSelectInput(session, "viz_cityregion", choices = c("All" = "all"))
    }, ignoreNULL = FALSE)
    
    observeEvent(input$viz_country, {
      tax <- viz_taxonomy()
      
      if (is.null(input$viz_country) || input$viz_country == "all") {
        updateSelectInput(session, "viz_cityregion", choices = c("All" = "all"))
        return()
      }
      
      regions <- sort(unique(tax$city_region[tax$country == input$viz_country &
                                              nchar(trimws(tax$city_region)) > 0 &
                                              tax$city_region != "All"]))
      
      updateSelectInput(session, "viz_cityregion",
                        choices = c("All" = "all", setNames(regions, regions)))
    }, ignoreInit = TRUE)
    
    observeEvent(input$load_viz, {
      
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading...")
      })
      
      tryCatch({
        conditions <- c()
        
        if (!is.null(input$viz_category) && input$viz_category != "all") {
          conditions <- c(conditions, sprintf("category = '%s'", safe_sql_escape(input$viz_category)))
        }
        if (!is.null(input$viz_country) && input$viz_country != "all") {
          conditions <- c(conditions, sprintf("country = '%s'", safe_sql_escape(input$viz_country)))
        }
        if (!is.null(input$viz_cityregion) && input$viz_cityregion != "all") {
          conditions <- c(conditions, sprintf("city_region = '%s'", safe_sql_escape(input$viz_cityregion)))
        }
        if (isTRUE(input$filter_start_date) && !is.null(input$start_date_range)) {
          conditions <- c(conditions, sprintf(
            "start_date_for_applying BETWEEN '%s' AND '%s'",
            format(input$start_date_range[1], "%Y-%m-%d"), format(input$start_date_range[2], "%Y-%m-%d")
          ))
        }
        if (isTRUE(input$filter_deadline) && !is.null(input$deadline_range)) {
          conditions <- c(conditions, sprintf(
            "deadline BETWEEN '%s' AND '%s'",
            format(input$deadline_range[1], "%Y-%m-%d"), format(input$deadline_range[2], "%Y-%m-%d")
          ))
        }
        
        where_clause <- if (length(conditions) > 0) {
          paste("WHERE", paste(conditions, collapse = " AND "))
        } else {
          ""
        }
        
        query <- sprintf("SELECT * FROM `%s` %s ORDER BY deadline ASC",
                         api_manager$bq_full_table_id, where_clause)
        
        data <- api_manager$bq_query(query)
        
        if (nrow(data) == 0) {
          viz_data(NULL)
          output$status <- renderUI({
            tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"),
                     " No programmes match these filters")
          })
          output$programme_cards <- renderUI({ tags$div() })
          return()
        }
        
        viz_data(data)
        
        output$total_programmes <- renderValueBox({
          valueBox(nrow(data), "Programmes", icon = icon("hand-holding-usd"), color = "aqua")
        })
        output$total_categories <- renderValueBox({
          valueBox(length(unique(data$category)), "Categories", icon = icon("layer-group"), color = "blue")
        })
        output$total_countries <- renderValueBox({
          valueBox(length(unique(data$country)), "Countries", icon = icon("globe"), color = "green")
        })
        
        today_str <- format(Sys.Date(), "%Y-%m-%d")
        upcoming <- sum(grepl("^\\d{4}-\\d{2}-\\d{2}$", data$deadline) & data$deadline >= today_str, na.rm = TRUE)
        output$upcoming_deadlines <- renderValueBox({
          valueBox(upcoming, "Upcoming Deadlines", icon = icon("clock"), color = "yellow")
        })
        
        # Category bar chart
        output$category_chart <- renderPlotly({
          cat_counts <- as.data.frame(table(data$category), stringsAsFactors = FALSE)
          names(cat_counts) <- c("category", "count")
          
          plot_ly(cat_counts, x = ~category, y = ~count, type = "bar",
                  marker = list(color = "#008A82")) %>%
            layout(title = "Programme Count by Category",
                   xaxis = list(title = ""), yaxis = list(title = "Count"))
        })
        
        # Programme cards - one viz-card per programme
        output$programme_cards <- renderUI({
          html_parts <- c()
          
          for (i in seq_len(nrow(data))) {
            row <- data[i, ]
            
            html_parts <- c(html_parts, '<div class="viz-card">')
            html_parts <- c(html_parts, sprintf('<div class="chapter-title"><i class="fa fa-hand-holding-usd"></i> %s</div>',
                                                as.character(row$programme_name)))
            html_parts <- c(html_parts, sprintf(
              '<div class="section-tag">%s</div> <div class="section-tag">%s%s</div>',
              as.character(row$category), as.character(row$country),
              if (!is.na(row$city_region) && row$city_region != "All") paste0(" - ", row$city_region) else ""
            ))
            
            if (!is.na(row$conditions) && trimws(row$conditions) != "") {
              html_parts <- c(html_parts, sprintf('<div class="details-text">%s</div>', as.character(row$conditions)))
            }
            
            metrics <- c()
            if (!is.na(row$amount_of_money) && trimws(row$amount_of_money) != "") {
              metrics <- c(metrics, sprintf(
                '<div class="metric-box"><div class="metric-label">Amount</div><div class="metric-value" style="font-size:1em;">%s</div></div>',
                as.character(row$amount_of_money)))
            }
            if (!is.na(row$start_date_for_applying) && trimws(row$start_date_for_applying) != "") {
              metrics <- c(metrics, sprintf(
                '<div class="metric-box"><div class="metric-label">Opens</div><div class="metric-value" style="font-size:1em;">%s</div></div>',
                as.character(row$start_date_for_applying)))
            }
            if (!is.na(row$deadline) && trimws(row$deadline) != "") {
              metrics <- c(metrics, sprintf(
                '<div class="metric-box"><div class="metric-label">Deadline</div><div class="metric-value" style="font-size:1em;">%s</div></div>',
                as.character(row$deadline)))
            }
            if (length(metrics) > 0) html_parts <- c(html_parts, paste(metrics, collapse = ""))
            
            if (!is.na(row$key_sponsors) && trimws(row$key_sponsors) != "") {
              html_parts <- c(html_parts, sprintf('<p style="margin-top:12px;"><strong>Key Sponsors:</strong> %s</p>',
                                                  as.character(row$key_sponsors)))
            }
            if (!is.na(row$key_organiser_profiles) && trimws(row$key_organiser_profiles) != "") {
              html_parts <- c(html_parts, sprintf('<p><strong>Key Organiser Profiles:</strong> %s</p>',
                                                  as.character(row$key_organiser_profiles)))
            }
            if (!is.na(row$areas_of_application) && trimws(row$areas_of_application) != "") {
              html_parts <- c(html_parts, sprintf('<p><strong>Areas of Application:</strong> %s</p>',
                                                  as.character(row$areas_of_application)))
            }
            
            if (!is.na(row$recommendations_for_applying) && trimws(row$recommendations_for_applying) != "") {
              html_parts <- c(html_parts, '<div class="reference-box">')
              html_parts <- c(html_parts, '<h5><i class="fa fa-lightbulb"></i> Recommendations for Applying</h5>')
              html_parts <- c(html_parts, sprintf('<p style="margin-top:8px; color:#555;">%s</p>',
                                                  as.character(row$recommendations_for_applying)))
              html_parts <- c(html_parts, '</div>')
            }
            
            if (!is.na(row$verified_urls) && trimws(row$verified_urls) != "") {
              urls <- trimws(strsplit(as.character(row$verified_urls), ",")[[1]])
              url_links <- paste(sprintf('<a href="%s" target="_blank">%s</a>', urls, urls), collapse = "<br>")
              html_parts <- c(html_parts, '<div class="formula-box">')
              html_parts <- c(html_parts, '<h5>Verified URLs</h5>')
              html_parts <- c(html_parts, sprintf('<p style="margin-top:8px;">%s</p>', url_links))
              html_parts <- c(html_parts, '</div>')
            }
            
            html_parts <- c(html_parts, '</div>')
          }
          
          HTML(paste(html_parts, collapse = ""))
        })
        
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded %d programme(s)", nrow(data)))
        })
        
        showNotification("✓ Visualizations loaded!", type = "message")
        
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Defaults
    output$status <- renderUI({ tags$div() })
    output$programme_cards <- renderUI({ tags$div() })
    output$category_chart <- renderPlotly({ plot_ly() })
    output$total_programmes <- renderValueBox({ valueBox(0, "Programmes", icon = icon("hand-holding-usd"), color = "aqua") })
    output$total_categories <- renderValueBox({ valueBox(0, "Categories", icon = icon("layer-group"), color = "blue") })
    output$total_countries <- renderValueBox({ valueBox(0, "Countries", icon = icon("globe"), color = "green") })
    output$upcoming_deadlines <- renderValueBox({ valueBox(0, "Upcoming Deadlines", icon = icon("clock"), color = "yellow") })
    
    session$onSessionEnded(function() {})
  })
}
