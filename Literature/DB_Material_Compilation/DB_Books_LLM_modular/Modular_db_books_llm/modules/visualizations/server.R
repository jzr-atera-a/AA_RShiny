# modules/visualizations/server.R

visualizations_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    viz_data <- reactiveVal(NULL)
    
    # Watch for BigQuery authentication AND data updates
    observe({
      api_manager$state_trigger()
      
      if (api_manager$bq_authenticated) {
        update_book_dropdown()
      }
    })
    
    # Update book dropdown
    update_book_dropdown <- function() {
      if (!api_manager$bq_authenticated) return()
      
      tryCatch({
        query <- sprintf("SELECT DISTINCT book_name FROM `%s` ORDER BY book_name",
                         api_manager$bq_full_table_id)
        books <- api_manager$bq_query(query)
        
        if (nrow(books) > 0) {
          updateSelectInput(session, "select_book",
                            choices = setNames(books$book_name, books$book_name))
        }
      }, error = function(e) {})
    }
    
    # Update chapter dropdown when book selected
    observeEvent(input$select_book, {
      if (!api_manager$bq_authenticated || is.null(input$select_book)) return()
      
      tryCatch({
        safe_book <- gsub("'", "''", input$select_book)
        query <- sprintf("SELECT DISTINCT chapter FROM `%s` WHERE book_name = '%s' ORDER BY chapter",
                         api_manager$bq_full_table_id, safe_book)
        chapters <- api_manager$bq_query(query)
        
        if (nrow(chapters) > 0) {
          updateSelectInput(session, "filter_chapter",
                            choices = c("All Chapters" = "all",
                                        setNames(chapters$chapter, chapters$chapter)))
        }
      }, error = function(e) {})
    })
    
    # Load visualizations
    observeEvent(input$load_viz, {
      
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      
      if (is.null(input$select_book)) {
        showNotification("Please select a book!", type = "warning")
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Loading visualization data...")
      })
      
      tryCatch({
        safe_book <- gsub("'", "''", input$select_book)
        
        if (input$filter_chapter == "all") {
          query <- sprintf("SELECT * FROM `%s` WHERE book_name = '%s' ORDER BY chapter, section",
                           api_manager$bq_full_table_id, safe_book)
        } else {
          safe_chapter <- gsub("'", "''", input$filter_chapter)
          query <- sprintf("SELECT * FROM `%s` WHERE book_name = '%s' AND chapter = '%s' ORDER BY section",
                           api_manager$bq_full_table_id, safe_book, safe_chapter)
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
        
        # Book header
        output$book_header <- renderUI({
          tags$div(class = "book-header",
                   tags$h2(data$book_name[1]),
                   tags$div(class = "author", tags$i(class = "fa fa-user"), " ", data$author[1]))
        })
        
        # Metrics
        output$total_chapters <- renderValueBox({
          valueBox(length(unique(data$chapter)), "Chapters", icon = icon("book-open"), color = "aqua")
        })
        
        output$total_sections <- renderValueBox({
          valueBox(length(unique(data$section)), "Sections", icon = icon("list-ol"), color = "blue")
        })
        
        avg_numeric <- tryCatch({
          all_nums <- unlist(lapply(data$numeric_data, function(x) {
            if (is.na(x) || trimws(x) == "") return(NULL)
            as.numeric(unlist(strsplit(as.character(x), ",")))
          }))
          round(mean(all_nums, na.rm = TRUE), 1)
        }, error = function(e) { 0 })
        
        output$avg_numeric <- renderValueBox({
          valueBox(avg_numeric, "Avg Metric", icon = icon("chart-line"), color = "yellow")
        })
        
        output$total_entries <- renderValueBox({
          valueBox(nrow(data), "Total Entries", icon = icon("database"), color = "green")
        })
        
        # Chapters HTML - Generate as HTML strings with proper type handling
        output$chapters_html <- renderUI({
          
          html_parts <- c()
          
          if (input$filter_chapter != "all") {
            # Single chapter - ONE viz-card with all sections
            
            html_parts <- c(html_parts, sprintf('<div class="viz-card">'))
            html_parts <- c(html_parts, sprintf('<div class="chapter-title"><i class="fa fa-bookmark"></i> %s</div>', 
                                                as.character(data$chapter[1])))
            
            for (i in seq_len(nrow(data))) {
              row <- data[i, ]
              
              # Section tag and content
              html_parts <- c(html_parts, sprintf('<div class="section-tag">%s</div>', as.character(row$section)))
              html_parts <- c(html_parts, sprintf('<div class="details-text">%s</div>', as.character(row$main_details)))
              
              # Formula
              if (!is.na(row$formula) && trimws(as.character(row$formula)) != "" && 
                  !tolower(trimws(as.character(row$formula))) %in% c("n/a", "na")) {
                
                html_parts <- c(html_parts, '<div class="formula-box">')
                html_parts <- c(html_parts, '<h5><i class="fa fa-calculator"></i> Mathematical Formula:</h5>')
                html_parts <- c(html_parts, sprintf('<div style="font-size: 1.2em; margin: 10px 0; padding: 10px; background: white; border-radius: 5px;">%s</div>', 
                                                    as.character(row$formula)))
                
                if (!is.na(row$formula_explanation) && trimws(as.character(row$formula_explanation)) != "") {
                  html_parts <- c(html_parts, sprintf('<p style="color: #555; font-style: italic; margin-top: 10px;">%s</p>', 
                                                      as.character(row$formula_explanation)))
                }
                html_parts <- c(html_parts, '</div>')
              }
              
              # Reference
              if (!is.na(row$reference_url) && trimws(as.character(row$reference_url)) != "") {
                html_parts <- c(html_parts, '<div class="reference-box">')
                html_parts <- c(html_parts, '<h5><i class="fa fa-link"></i> Reference Resource:</h5>')
                html_parts <- c(html_parts, sprintf('<a href="%s" target="_blank">%s <i class="fa fa-external-link-alt" style="margin-left: 5px; font-size: 0.8em;"></i></a>', 
                                                    as.character(row$reference_url), as.character(row$reference_url)))
                
                if (!is.na(row$reference_description) && trimws(as.character(row$reference_description)) != "") {
                  html_parts <- c(html_parts, sprintf('<p style="margin-top: 8px; color: #555;">%s</p>', 
                                                      as.character(row$reference_description)))
                }
                html_parts <- c(html_parts, '</div>')
              }
              
              # Metrics
              if (!is.na(row$numeric_data) && trimws(as.character(row$numeric_data)) != "") {
                nums <- as.numeric(unlist(strsplit(as.character(row$numeric_data), ",")))
                if (length(nums) > 0) {
                  html_parts <- c(html_parts, '<div style="margin-top: 15px;">')
                  html_parts <- c(html_parts, '<h5><i class="fa fa-chart-bar"></i> Metrics:</h5>')
                  
                  if (!is.na(row$numeric_data_description) && trimws(as.character(row$numeric_data_description)) != "") {
                    html_parts <- c(html_parts, sprintf('<p style="color: #666; font-size: 0.9em; font-style: italic; margin-bottom: 10px; background: #f8f9fa; padding: 8px; border-radius: 5px;"><i class="fa fa-info-circle"></i> %s</p>', 
                                                        as.character(row$numeric_data_description)))
                  }
                  
                  for (j in seq_along(nums)) {
                    html_parts <- c(html_parts, sprintf('<div class="metric-box"><div class="metric-label">METRIC %d</div><div class="metric-value">%s</div></div>', 
                                                        j, nums[j]))
                  }
                  
                  html_parts <- c(html_parts, '</div>')
                }
              }
              
              # Add separator if not last
              if (i < nrow(data)) {
                html_parts <- c(html_parts, '<hr style="margin: 20px 0; border-top: 1px solid #e0e0e0;">')
              }
            }
            
            html_parts <- c(html_parts, '</div>')
            
          } else {
            # All chapters - ONE viz-card per chapter
            chapters <- unique(data$chapter)
            
            for (chap in chapters) {
              chapter_data <- data[data$chapter == chap, ]
              
              html_parts <- c(html_parts, '<div class="viz-card">')
              html_parts <- c(html_parts, sprintf('<div class="chapter-title"><i class="fa fa-bookmark"></i> %s</div>', 
                                                  as.character(chap)))
              
              for (i in seq_len(nrow(chapter_data))) {
                row <- chapter_data[i, ]
                
                # Section tag and content
                html_parts <- c(html_parts, sprintf('<div class="section-tag">%s</div>', as.character(row$section)))
                html_parts <- c(html_parts, sprintf('<div class="details-text">%s</div>', as.character(row$main_details)))
                
                # Formula
                if (!is.na(row$formula) && trimws(as.character(row$formula)) != "" && 
                    !tolower(trimws(as.character(row$formula))) %in% c("n/a", "na")) {
                  
                  html_parts <- c(html_parts, '<div class="formula-box">')
                  html_parts <- c(html_parts, '<h5><i class="fa fa-calculator"></i> Mathematical Formula:</h5>')
                  html_parts <- c(html_parts, sprintf('<div style="font-size: 1.2em; margin: 10px 0; padding: 10px; background: white; border-radius: 5px;">%s</div>', 
                                                      as.character(row$formula)))
                  
                  if (!is.na(row$formula_explanation) && trimws(as.character(row$formula_explanation)) != "") {
                    html_parts <- c(html_parts, sprintf('<p style="color: #555; font-style: italic; margin-top: 10px;">%s</p>', 
                                                        as.character(row$formula_explanation)))
                  }
                  html_parts <- c(html_parts, '</div>')
                }
                
                # Reference
                if (!is.na(row$reference_url) && trimws(as.character(row$reference_url)) != "") {
                  html_parts <- c(html_parts, '<div class="reference-box">')
                  html_parts <- c(html_parts, '<h5><i class="fa fa-link"></i> Reference Resource:</h5>')
                  html_parts <- c(html_parts, sprintf('<a href="%s" target="_blank">%s <i class="fa fa-external-link-alt" style="margin-left: 5px; font-size: 0.8em;"></i></a>', 
                                                      as.character(row$reference_url), as.character(row$reference_url)))
                  
                  if (!is.na(row$reference_description) && trimws(as.character(row$reference_description)) != "") {
                    html_parts <- c(html_parts, sprintf('<p style="margin-top: 8px; color: #555;">%s</p>', 
                                                        as.character(row$reference_description)))
                  }
                  html_parts <- c(html_parts, '</div>')
                }
                
                # Metrics
                if (!is.na(row$numeric_data) && trimws(as.character(row$numeric_data)) != "") {
                  nums <- as.numeric(unlist(strsplit(as.character(row$numeric_data), ",")))
                  if (length(nums) > 0) {
                    html_parts <- c(html_parts, '<div style="margin-top: 15px;">')
                    html_parts <- c(html_parts, '<h5><i class="fa fa-chart-bar"></i> Metrics:</h5>')
                    
                    if (!is.na(row$numeric_data_description) && trimws(as.character(row$numeric_data_description)) != "") {
                      html_parts <- c(html_parts, sprintf('<p style="color: #666; font-size: 0.9em; font-style: italic; margin-bottom: 10px; background: #f8f9fa; padding: 8px; border-radius: 5px;"><i class="fa fa-info-circle"></i> %s</p>', 
                                                          as.character(row$numeric_data_description)))
                    }
                    
                    for (j in seq_along(nums)) {
                      html_parts <- c(html_parts, sprintf('<div class="metric-box"><div class="metric-label">METRIC %d</div><div class="metric-value">%s</div></div>', 
                                                          j, nums[j]))
                    }
                    
                    html_parts <- c(html_parts, '</div>')
                  }
                }
                
                # Add separator if not last
                if (i < nrow(chapter_data)) {
                  html_parts <- c(html_parts, '<hr style="margin: 20px 0; border-top: 1px solid #e0e0e0;">')
                }
              }
              
              html_parts <- c(html_parts, '</div>')
            }
          }
          
          # Add MathJax script
          html_parts <- c(html_parts, '<script>if (typeof MathJax !== "undefined") { MathJax.Hub.Queue(["Typeset", MathJax.Hub]); }</script>')
          
          # Combine all parts and return as HTML
          HTML(paste(html_parts, collapse = ""))
        })
        
        # Numeric chart
        output$numeric_chart <- renderPlotly({
          chart_data <- data.frame(chapter = character(), metric = character(), value = numeric(),
                                   stringsAsFactors = FALSE)
          
          for (i in seq_len(nrow(data))) {
            row <- data[i, ]
            if (!is.na(row$numeric_data) && trimws(row$numeric_data) != "") {
              nums <- as.numeric(unlist(strsplit(as.character(row$numeric_data), ",")))
              if (length(nums) > 0) {
                for (j in seq_along(nums)) {
                  chart_data <- rbind(chart_data, data.frame(
                    chapter = paste("Ch", i),
                    metric = paste("Metric", j),
                    value = nums[j],
                    stringsAsFactors = FALSE
                  ))
                }
              }
            }
          }
          
          if (nrow(chart_data) == 0) {
            return(plot_ly() %>% layout(title = "No numeric data available"))
          }
          
          plot_ly(chart_data, x = ~chapter, y = ~value, color = ~metric,
                  type = 'scatter', mode = 'lines+markers') %>%
            layout(title = "Numeric Data Trends Across Chapters",
                   xaxis = list(title = "Chapter"),
                   yaxis = list(title = "Value"))
        })
        
        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded visualizations for '%s' (%d entries)", data$book_name[1], nrow(data)))
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
    output$book_header <- renderUI({ tags$div() })
    output$chapters_html <- renderUI({ tags$div() })
    output$numeric_chart <- renderPlotly({ plot_ly() })
    
    output$total_chapters <- renderValueBox({
      valueBox(0, "Chapters", icon = icon("book-open"), color = "aqua")
    })
    output$total_sections <- renderValueBox({
      valueBox(0, "Sections", icon = icon("list-ol"), color = "blue")
    })
    output$avg_numeric <- renderValueBox({
      valueBox(0, "Avg Metric", icon = icon("chart-line"), color = "yellow")
    })
    output$total_entries <- renderValueBox({
      valueBox(0, "Total Entries", icon = icon("database"), color = "green")
    })
    
    session$onSessionEnded(function() {})
  })
}