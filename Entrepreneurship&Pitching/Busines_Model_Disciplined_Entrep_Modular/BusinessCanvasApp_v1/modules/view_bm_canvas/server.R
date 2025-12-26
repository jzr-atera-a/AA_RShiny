# View Business Model Canvas Module - Server

view_bm_canvas_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Load default canvas content
    load_default_canvas <- function() {
      output$canvas_key_partners <- renderUI({
        HTML('<div class="section-content"><p><strong>Key Partners</strong></p><p>Click "Load Canvas" to view saved data</p></div>')
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
    
    # Update dropdowns
    update_canvas_dropdowns <- function() {
      if (!api_manager$bq_authenticated) return()
      
      tryCatch({
        query <- sprintf("SELECT DISTINCT business_area FROM `%s` WHERE business_area IS NOT NULL ORDER BY business_area", 
                         api_manager$bq_full_table_id)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "select_business_area", choices = c("Select..." = "", result$business_area))
        }
      }, error = function(e) {})
    }
    
    # Update project dropdown
    observeEvent(input$select_business_area, {
      if (input$select_business_area == "" || !api_manager$bq_authenticated) return()
      
      tryCatch({
        query <- sprintf("SELECT DISTINCT project FROM `%s` WHERE business_area = '%s' ORDER BY project", 
                         api_manager$bq_full_table_id, gsub("'", "\\\\'", input$select_business_area))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "select_project", choices = c("Select..." = "", result$project))
        }
      }, error = function(e) {})
    })
    
    # Update focus dropdown
    observeEvent(input$select_project, {
      if (input$select_project == "" || !api_manager$bq_authenticated) return()
      
      tryCatch({
        query <- sprintf("SELECT DISTINCT business_focus FROM `%s` WHERE business_area = '%s' AND project = '%s' ORDER BY business_focus", 
                         api_manager$bq_full_table_id, 
                         gsub("'", "\\\\'", input$select_business_area),
                         gsub("'", "\\\\'", input$select_project))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "select_business_focus", choices = c("Select..." = "", result$business_focus))
        }
      }, error = function(e) {})
    })
    
    # Load canvas from BigQuery
    observeEvent(input$loadCanvas, {
      if (!api_manager$bq_authenticated) {
        showNotification("Authenticate BigQuery first", type = "error")
        return()
      }
      
      if (input$select_business_area == "" || input$select_project == "" || input$select_business_focus == "") {
        showNotification("Select all fields", type = "warning")
        return()
      }
      
      tryCatch({
        query <- sprintf("SELECT * FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus = '%s' ORDER BY updated_at DESC LIMIT 1",
                         api_manager$bq_full_table_id,
                         gsub("'", "\\\\'", input$select_business_area),
                         gsub("'", "\\\\'", input$select_project),
                         gsub("'", "\\\\'", input$select_business_focus))
        
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
          
          showNotification("✓ Canvas loaded!", type = "message")
        } else {
          showNotification("No canvas found", type = "warning")
          load_default_canvas()
        }
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Initialize
    load_default_canvas()
    update_canvas_dropdowns()
    
  })
}
