# modules/visualizations/server.R

visualizations_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    viz_data <- reactiveVal(NULL)
    
    # Watch for BigQuery authentication
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
        
        # Chapters HTML
        output$chapters_html <- renderUI({
          chapter_cards <- lapply(seq_len(nrow(data)), function(i) {
            row <- data[i, ]
            
            # Formula section
            formula_html <- ""
            if (!is.na(row$formula) && trimws(row$formula) != "" && 
                !tolower(trimws(row$formula)) %in% c("n/a", "na")) {
              formula_html <- tags$div(
                class = "formula-box",
                tags$h5(tags$i(class = "fa fa-calculator"), " Mathematical Formula:"),
                tags$div(style = "font-size: 1.2em; margin: 10px 0; padding: 10px; background: white; border-radius: 5px;",
                        HTML(row$formula)),
                if (!is.na(row$formula_explanation) && trimws(row$formula_explanation) != "") {
                  tags$p(style = "color: #555; font-style: italic;", row$formula_explanation)
                }
              )
            }
            
            # Reference section
            reference_html <- ""
            if (!is.na(row$reference_url) && trimws(row$reference_url) != "") {
              reference_html <- tags$div(
                class = "reference-box",
                tags$h5(tags$i(class = "fa fa-link"), " Reference Resource:"),
                tags$a(href = row$reference_url, target = "_blank", row$reference_url,
                      tags$i(class = "fa fa-external-link-alt", style = "margin-left: 5px;")),
                if (!is.na(row$reference_description) && trimws(row$reference_description) != "") {
                  tags$p(style = "margin-top: 8px; color: #555;", row$reference_description)
                }
              )
            }
            
            tags$div(
              class = "viz-card",
              tags$div(class = "chapter-title", tags$i(class = "fa fa-bookmark"), " ", row$chapter),
              tags$div(class = "section-tag", row$section),
              tags$div(class = "details-text", HTML(row$main_details)),
              formula_html,
              reference_html
            )
          })
          
          tags$div(
            do.call(tagList, chapter_cards),
            tags$script(HTML("if (typeof MathJax !== 'undefined') { MathJax.Hub.Queue(['Typeset', MathJax.Hub]); }"))
          )
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
