view_bm_canvas_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Load default canvas content
    load_default_canvas <- function() {
      output$canvas_key_partners <- renderUI({
        HTML('<div class="section-content"><p><strong>Key Partners</strong></p><p>Select filters to load canvas</p></div>')
      })
      output$canvas_key_activities <- renderUI({
        HTML('<div class="section-content"><p><strong>Key Activities</strong></p></div>')
      })
      output$canvas_key_resources <- renderUI({
        HTML('<div class="section-content"><p><strong>Key Resources</strong></p></div>')
      })
      output$canvas_value_propositions <- renderUI({
        HTML('<div class="section-content"><p><strong>Value Propositions</strong></p></div>')
      })
      output$canvas_customer_relationships <- renderUI({
        HTML('<div class="section-content"><p><strong>Customer Relationships</strong></p></div>')
      })
      output$canvas_channels <- renderUI({
        HTML('<div class="section-content"><p><strong>Channels</strong></p></div>')
      })
      output$canvas_customer_segments <- renderUI({
        HTML('<div class="section-content"><p><strong>Customer Segments</strong></p></div>')
      })
      output$canvas_cost_structure <- renderUI({
        HTML('<div class="section-content"><p><strong>Cost Structure</strong></p></div>')
      })
      output$canvas_revenue_streams <- renderUI({
        HTML('<div class="section-content"><p><strong>Revenue Streams</strong></p></div>')
      })
    }
    
    # Update canvas dropdowns - CALLED WHEN AUTHENTICATED
    update_canvas_dropdowns <- function() {
      if (!api_manager$bq_authenticated) return()
      
      tryCatch({
        query <- sprintf("SELECT DISTINCT business_area FROM `%s` WHERE business_area IS NOT NULL ORDER BY business_area", 
                         api_manager$bq_full_table_id)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        cat("BM Canvas - Found", nrow(result), "business areas\n")
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "select_business_area", 
                            choices = c("Select..." = "", result$business_area))
        }
      }, error = function(e) {
        cat("Error loading business areas:", e$message, "\n")
      })
    }
    
    # TRIGGER UPDATE WHEN AUTHENTICATION CHANGES
    observe({
      if (api_manager$bq_authenticated) {
        update_canvas_dropdowns()
      }
    })
    
    # Update project dropdown when business area selected
    observeEvent(input$select_business_area, {
      if (input$select_business_area == "" || !api_manager$bq_authenticated) return()
      
      tryCatch({
        business_area_clean <- gsub("'", "\\\\'", input$select_business_area)
        query <- sprintf("SELECT DISTINCT project FROM `%s` WHERE business_area = '%s' AND project IS NOT NULL ORDER BY project", 
                         api_manager$bq_full_table_id, business_area_clean)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        cat("BM Canvas - Found", nrow(result), "projects\n")
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "select_project", 
                            choices = c("Select..." = "", result$project))
        } else {
          updateSelectInput(session, "select_project", choices = c("No projects available" = ""))
        }
      }, error = function(e) {
        showNotification(paste("Error loading projects:", e$message), type = "error")
      })
    })
    
    # Update focus dropdown when project selected
    observeEvent(input$select_project, {
      if (input$select_project == "" || !api_manager$bq_authenticated) return()
      
      tryCatch({
        business_area_clean <- gsub("'", "\\\\'", input$select_business_area)
        project_clean <- gsub("'", "\\\\'", input$select_project)
        query <- sprintf("SELECT DISTINCT business_focus FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus IS NOT NULL ORDER BY business_focus", 
                         api_manager$bq_full_table_id, business_area_clean, project_clean)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        cat("BM Canvas - Found", nrow(result), "business focus\n")
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "select_business_focus", 
                            choices = c("Select..." = "", result$business_focus))
        } else {
          updateSelectInput(session, "select_business_focus", choices = c("No business focus available" = ""))
        }
      }, error = function(e) {
        showNotification(paste("Error loading business focus:", e$message), type = "error")
      })
    })
    
    # Load canvas from BigQuery
    observeEvent(input$loadCanvas, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate first", type = "error")
        return()
      }
      
      if (input$select_business_area == "" || input$select_project == "" || input$select_business_focus == "") {
        showNotification("Please select Business Area, Project, and Business Focus", type = "warning")
        return()
      }
      
      tryCatch({
        business_area_clean <- gsub("'", "\\\\'", input$select_business_area)
        project_clean <- gsub("'", "\\\\'", input$select_project)
        business_focus_clean <- gsub("'", "\\\\'", input$select_business_focus)
        
        query <- sprintf("
          SELECT * FROM `%s` 
          WHERE business_area = '%s' 
          AND project = '%s' 
          AND business_focus = '%s' 
          ORDER BY updated_at DESC 
          LIMIT 1",
                         api_manager$bq_full_table_id,
                         business_area_clean,
                         project_clean,
                         business_focus_clean
        )
        
        cat("Executing query:", query, "\n")
        
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        if (nrow(result) > 0) {
          output$canvas_key_partners <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$key_partners), '</div>')))
          output$canvas_key_activities <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$key_activities), '</div>')))
          output$canvas_key_resources <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$key_resources), '</div>')))
          output$canvas_value_propositions <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$value_propositions), '</div>')))
          output$canvas_customer_relationships <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$customer_relationships), '</div>')))
          output$canvas_channels <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$channels), '</div>')))
          output$canvas_customer_segments <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$customer_segments), '</div>')))
          output$canvas_cost_structure <- renderUI(HTML(paste0('<div class="section-content two-column-content">', gsub("\n", "<br>", result$cost_structure), '</div>')))
          output$canvas_revenue_streams <- renderUI(HTML(paste0('<div class="section-content two-column-content">', gsub("\n", "<br>", result$revenue_streams), '</div>')))
          
          showNotification("✓ Canvas loaded successfully!", type = "message")
        } else {
          showNotification("No canvas found for this selection. Showing default template.", type = "warning")
          load_default_canvas()
        }
        
      }, error = function(e) {
        showNotification(paste("Error loading canvas:", e$message), type = "error")
        load_default_canvas()
      })
    })
    
    # Initialize with default canvas on startup
    load_default_canvas()
    
  })
}