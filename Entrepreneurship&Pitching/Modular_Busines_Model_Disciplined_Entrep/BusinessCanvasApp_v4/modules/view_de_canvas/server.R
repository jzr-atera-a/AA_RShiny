view_de_canvas_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    load_default <- function() {
      output$de_box1_content <- renderUI({ HTML('<div class="de-box-content">Mission, Passion, Values, Initial Assets, Initial Idea</div>') })
      output$de_box2_content <- renderUI({ HTML('<div class="de-box-content">Beachhead, End User Profile, TAM, Persona, First 10 Customers</div>') })
      output$de_box3_content <- renderUI({ HTML('<div class="de-box-content">Use Case, Product Description, Problem Being Solved, Quantified Value Proposition</div>') })
      output$de_box4_content <- renderUI({ HTML('<div class="de-box-content">Moats, Core, Competitive Positioning</div>') })
      output$de_box5_content <- renderUI({ HTML('<div class="de-box-content">DMU, Process to Acquire Customer, Windows of Opportunity, Possible Triggers</div>') })
      output$de_box6_content <- renderUI({ HTML('<div class="de-box-content">Business Model, Estimated Pricing, Short/Medium/Long Term LTV and COCA</div>') })
      output$de_box7_content <- renderUI({ HTML('<div class="de-box-content">Preferred Sales Channel, Sales Funnel, Short/Medium/Long Term Mix</div>') })
      output$de_box8_content <- renderUI({ HTML('<div class="de-box-content">Estimated R&D Expenses, Estimated G&A Expenses, LTV/COCA Ratio High Enough</div>') })
      output$de_box9_content <- renderUI({ HTML('<div class="de-box-content">Identify Key Assumptions, Test Key Assumptions, MVBP, Tracking Metrics</div>') })
      output$de_box10_content <- renderUI({ HTML('<div class="de-box-content">Product Plan for Beachhead, Next Market, Product Plan Beyond Beachhead, Follow-on TAM</div>') })
    }
    
    update_de_dropdowns <- function() {
      if (!api_manager$bq_authenticated) return()
      cat("🔍 DE Canvas - Updating dropdowns...\n")
      tryCatch({
        de_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_canvas")
        query <- sprintf("SELECT DISTINCT business_area FROM `%s` WHERE business_area IS NOT NULL ORDER BY business_area", de_table)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        cat("✓ DE Canvas - Found", nrow(result), "business areas\n")
        if (nrow(result) > 0) {
          updateSelectInput(session, "de_select_business_area", choices = c("Select..." = "", result$business_area))
        }
      }, error = function(e) {
        cat("✗ DE Canvas - Error:", e$message, "\n")
      })
    }
    
    observe({
      api_manager$bq_auth_trigger()
      if (api_manager$bq_authenticated) {
        cat("🔔 DE Canvas - Auth trigger fired!\n")
        update_de_dropdowns()
      }
    })
    
    observeEvent(input$de_select_business_area, {
      if (input$de_select_business_area == "" || !api_manager$bq_authenticated) return()
      tryCatch({
        de_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_canvas")
        query <- sprintf("SELECT DISTINCT project FROM `%s` WHERE business_area = '%s' AND project IS NOT NULL ORDER BY project", 
                         de_table, gsub("'", "\\\\'", input$de_select_business_area))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        if (nrow(result) > 0) {
          updateSelectInput(session, "de_select_project", choices = c("Select..." = "", result$project))
        }
      }, error = function(e) { })
    })
    
    observeEvent(input$de_select_project, {
      if (input$de_select_project == "" || !api_manager$bq_authenticated) return()
      tryCatch({
        de_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_canvas")
        query <- sprintf("SELECT DISTINCT business_focus FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus IS NOT NULL ORDER BY business_focus", 
                         de_table, gsub("'", "\\\\'", input$de_select_business_area), gsub("'", "\\\\'", input$de_select_project))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        if (nrow(result) > 0) {
          updateSelectInput(session, "de_select_business_focus", choices = c("Select..." = "", result$business_focus))
        }
      }, error = function(e) { })
    })
    
    observeEvent(input$loadDECanvas, {
      if (!api_manager$bq_authenticated || input$de_select_business_area == "" || input$de_select_project == "" || input$de_select_business_focus == "") {
        showNotification("Select all fields", type = "warning")
        return()
      }
      tryCatch({
        de_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_canvas")
        query <- sprintf("SELECT * FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus = '%s' ORDER BY updated_at DESC LIMIT 1",
                         de_table, gsub("'", "\\\\'", input$de_select_business_area), gsub("'", "\\\\'", input$de_select_project), gsub("'", "\\\\'", input$de_select_business_focus))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        if (nrow(result) > 0) {
          output$de_box1_content <- renderUI(HTML(paste0('<div class="de-box-content">', gsub("\n", "<br>", result$raison_detre), '</div>')))
          output$de_box2_content <- renderUI(HTML(paste0('<div class="de-box-content">', gsub("\n", "<br>", result$initial_market), '</div>')))
          output$de_box3_content <- renderUI(HTML(paste0('<div class="de-box-content">', gsub("\n", "<br>", result$value_creation), '</div>')))
          output$de_box4_content <- renderUI(HTML(paste0('<div class="de-box-content">', gsub("\n", "<br>", result$competitive_advantage), '</div>')))
          output$de_box5_content <- renderUI(HTML(paste0('<div class="de-box-content">', gsub("\n", "<br>", result$customer_acquisition), '</div>')))
          output$de_box6_content <- renderUI(HTML(paste0('<div class="de-box-content">', gsub("\n", "<br>", result$product_unit_economics), '</div>')))
          output$de_box7_content <- renderUI(HTML(paste0('<div class="de-box-content">', gsub("\n", "<br>", result$sales), '</div>')))
          output$de_box8_content <- renderUI(HTML(paste0('<div class="de-box-content">', gsub("\n", "<br>", result$overall_economics), '</div>')))
          output$de_box9_content <- renderUI(HTML(paste0('<div class="de-box-content">', gsub("\n", "<br>", result$design_build), '</div>')))
          output$de_box10_content <- renderUI(HTML(paste0('<div class="de-box-content">', gsub("\n", "<br>", result$scaling), '</div>')))
          showNotification("✓ DE Canvas loaded!", type = "message")
        }
      }, error = function(e) { })
    })
    
    load_default()
  })
}
