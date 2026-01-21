view_bm_canvas_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    load_default_canvas <- function() {
      output$canvas_key_partners <- renderUI({
        HTML('<div class="section-content"><p><strong>Who are our Key Partners?</strong></p><p><strong>Who are our key suppliers?</strong></p><p><strong>Which Key Resources are we acquiring from partners?</strong></p><p><strong>Which Key Activities do partners perform?</strong></p><hr><p><strong>Motivations for partnerships:</strong></p><ul><li>Optimization and economy of scale</li><li>Reduction of risk and uncertainty</li><li>Acquisition of particular resources and activities</li></ul></div>')
      })
      output$canvas_key_activities <- renderUI({
        HTML('<div class="section-content"><p><strong>What Key Activities does our Value Proposition require?</strong></p><p><strong>Our Distribution Channels?</strong></p><p><strong>Customer Relationships?</strong></p><p><strong>Revenue Streams?</strong></p><hr><p><strong>Categories:</strong></p><ul><li>Production</li><li>Problem Solving</li><li>Platform/Network</li></ul></div>')
      })
      output$canvas_key_resources <- renderUI({
        HTML('<div class="section-content"><p><strong>What Key Resources does our Value Proposition require?</strong></p><p><strong>Our Distribution Channels?</strong></p><p><strong>Customer Relationships?</strong></p><p><strong>Revenue Streams?</strong></p><hr><p><strong>Types of resources:</strong></p><ul><li>Physical</li><li>Intellectual</li><li>Human</li><li>Financial</li></ul></div>')
      })
      output$canvas_value_propositions <- renderUI({
        HTML('<div class="section-content"><p><strong>What value do we deliver to the customer?</strong></p><p><strong>Which one of our customer\'s problems are we helping to solve?</strong></p><p><strong>What bundles of products and services are we offering to each Customer Segment?</strong></p><p><strong>Which customer needs are we satisfying?</strong></p><hr><p><strong>Characteristics:</strong></p><ul><li>Newness</li><li>Performance</li><li>Customization</li><li>Getting the Job Done</li><li>Design</li><li>Brand/Status</li><li>Price</li><li>Cost Reduction</li><li>Risk Reduction</li><li>Accessibility</li><li>Convenience/Usability</li></ul></div>')
      })
      output$canvas_customer_relationships <- renderUI({
        HTML('<div class="section-content"><p><strong>What type of relationship does each Customer Segment expect?</strong></p><p><strong>Which ones have we established?</strong></p><p><strong>How are they integrated?</strong></p><p><strong>How costly are they?</strong></p><hr><p><strong>Categories:</strong></p><ul><li>Personal assistance</li><li>Dedicated assistance</li><li>Self-service</li><li>Automated services</li><li>Communities</li><li>Co-creation</li></ul></div>')
      })
      output$canvas_channels <- renderUI({
        HTML('<div class="section-content"><p><strong>Through which Channels do our Customer Segments want to be reached?</strong></p><p><strong>How are we reaching them now?</strong></p><p><strong>How are our Channels integrated?</strong></p><p><strong>Which ones work best?</strong></p><p><strong>Which ones are most cost-efficient?</strong></p><hr><p><strong>Channel phases:</strong></p><ul><li>1. Awareness</li><li>2. Evaluation</li><li>3. Purchase</li><li>4. Delivery</li><li>5. After sales</li></ul></div>')
      })
      output$canvas_customer_segments <- renderUI({
        HTML('<div class="section-content"><p><strong>For whom are we creating value?</strong></p><p><strong>Who are our most important customers?</strong></p><hr><p><strong>Groups of people or organizations:</strong></p><ul><li>Mass market</li><li>Niche market</li><li>Segmented</li><li>Diversified</li><li>Multi-sided platforms</li></ul><hr><p><strong>Customer characteristics:</strong></p><ul><li>Common needs</li><li>Common behaviors</li><li>Common attributes</li><li>Profitability</li><li>Distribution channels</li><li>Relationship types</li></ul></div>')
      })
      output$canvas_cost_structure <- renderUI({
        HTML('<div class="section-content two-column-content"><p><strong>What are the most important costs inherent in our business model?</strong></p><p><strong>Which Key Resources are most expensive?</strong></p><p><strong>Which Key Activities are most expensive?</strong></p><hr><p><strong>Is your business more:</strong></p><ul><li>Cost Driven (leanest cost structure, low price value proposition, maximum automation, extensive outsourcing)</li><li>Value Driven (focused on value creation, premium value propositions)</li></ul><hr><p><strong>Sample characteristics:</strong></p><ul><li>Fixed Costs</li><li>Variable costs</li><li>Economies of scale</li><li>Economies of scope</li></ul></div>')
      })
      output$canvas_revenue_streams <- renderUI({
        HTML('<div class="section-content two-column-content"><p><strong>What value are our customers really willing to pay for?</strong></p><p><strong>For what do they currently pay?</strong></p><p><strong>How are they currently paying?</strong></p><p><strong>How would they prefer to pay?</strong></p><p><strong>How much does each Revenue Stream contribute to overall revenues?</strong></p><hr><p><strong>Types:</strong></p><ul><li>Asset sale</li><li>Usage fee</li><li>Subscription fees</li><li>Lending/Renting/Leasing</li><li>Licensing</li><li>Brokerage fees</li><li>Advertising</li></ul><hr><p><strong>Fixed Menu Pricing:</strong></p><ul><li>List price</li><li>Product feature dependent</li><li>Customer segment dependent</li><li>Volume dependent</li></ul><hr><p><strong>Dynamic Pricing:</strong></p><ul><li>Negotiation</li><li>Yield management</li><li>Real-time-market</li></ul></div>')
      })
    }
    
    update_canvas_dropdowns <- function() {
      if (!api_manager$bq_authenticated) return()
      
      cat("🔍 BM Canvas - Updating dropdowns...\n")
      
      tryCatch({
        query <- sprintf("SELECT DISTINCT business_area FROM `%s` WHERE business_area IS NOT NULL ORDER BY business_area", 
                         api_manager$bq_full_table_id)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        cat("✓ BM Canvas - Found", nrow(result), "business areas\n")
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "select_business_area", 
                            choices = c("Select..." = "", result$business_area))
        }
      }, error = function(e) {
        cat("✗ BM Canvas - Error loading business areas:", e$message, "\n")
      })
    }
    
    # WATCH REACTIVE TRIGGER FROM API MANAGER
    observe({
      api_manager$bq_auth_trigger()  # Watch the reactive value
      if (api_manager$bq_authenticated) {
        cat("🔔 BM Canvas - Auth trigger fired!\n")
        update_canvas_dropdowns()
      }
    })
    
    observeEvent(input$select_business_area, {
      if (input$select_business_area == "" || !api_manager$bq_authenticated) return()
      
      tryCatch({
        business_area_clean <- gsub("'", "\\\\'", input$select_business_area)
        query <- sprintf("SELECT DISTINCT project FROM `%s` WHERE business_area = '%s' AND project IS NOT NULL ORDER BY project", 
                         api_manager$bq_full_table_id, business_area_clean)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
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
    
    observeEvent(input$select_project, {
      if (input$select_project == "" || !api_manager$bq_authenticated) return()
      
      tryCatch({
        business_area_clean <- gsub("'", "\\\\'", input$select_business_area)
        project_clean <- gsub("'", "\\\\'", input$select_project)
        query <- sprintf("SELECT DISTINCT business_focus FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus IS NOT NULL ORDER BY business_focus", 
                         api_manager$bq_full_table_id, business_area_clean, project_clean)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
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
    
    load_default_canvas()
    
  })
}
