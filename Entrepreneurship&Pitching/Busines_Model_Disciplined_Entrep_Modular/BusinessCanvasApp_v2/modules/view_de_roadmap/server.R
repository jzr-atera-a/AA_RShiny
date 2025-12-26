view_de_roadmap_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    initialized <- reactiveVal(FALSE)
    
    output$roadmap_display <- renderUI({
      HTML('<div class="alert alert-info"><h4>Select filters above to load roadmap</h4></div>')
    })
    
    # Populate business area dropdown when clicked
    observeEvent(input$roadmap_select_business_area_clicked, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate BigQuery first", type = "error")
        return()
      }
      
      if (!initialized()) {
        tryCatch({
          roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
          query <- sprintf("SELECT DISTINCT business_area FROM `%s` WHERE business_area IS NOT NULL ORDER BY business_area", roadmap_table)
          job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
          result <- bigrquery::bq_table_download(job)
          
          cat("DE Roadmap - Found", nrow(result), "business areas\n")
          
          if (nrow(result) > 0) {
            updateSelectInput(session, "roadmap_select_business_area", 
                              choices = c("Select..." = "", result$business_area))
            initialized(TRUE)
          } else {
            showNotification("No data found in table", type = "warning")
          }
        }, error = function(e) {
          showNotification(paste("Error:", e$message), type = "error")
          cat("Error loading roadmap business areas:", e$message, "\n")
        })
      }
    })
    
    observeEvent(input$roadmap_select_business_area, {
      if (is.null(input$roadmap_select_business_area) || input$roadmap_select_business_area == "") {
        updateSelectInput(session, "roadmap_select_project", choices = c("Select..." = ""))
        updateSelectInput(session, "roadmap_select_business_focus", choices = c("Select..." = ""))
        return()
      }
      if (!api_manager$bq_authenticated) return()
      
      tryCatch({
        roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        query <- sprintf("SELECT DISTINCT project FROM `%s` WHERE business_area = '%s' AND project IS NOT NULL ORDER BY project", 
                         roadmap_table, gsub("'", "''", input$roadmap_select_business_area))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        cat("DE Roadmap - Found", nrow(result), "projects\n")
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "roadmap_select_project", 
                            choices = c("Select..." = "", result$project))
        } else {
          updateSelectInput(session, "roadmap_select_project", choices = c("No projects available" = ""))
        }
        updateSelectInput(session, "roadmap_select_business_focus", choices = c("Select..." = ""))
      }, error = function(e) {
        cat("Error loading roadmap projects:", e$message, "\n")
      })
    })
    
    observeEvent(input$roadmap_select_project, {
      if (is.null(input$roadmap_select_project) || input$roadmap_select_project == "") {
        updateSelectInput(session, "roadmap_select_business_focus", choices = c("Select..." = ""))
        return()
      }
      if (!api_manager$bq_authenticated) return()
      
      tryCatch({
        roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        query <- sprintf("SELECT DISTINCT business_focus FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus IS NOT NULL ORDER BY business_focus", 
                         roadmap_table, 
                         gsub("'", "''", input$roadmap_select_business_area), 
                         gsub("'", "''", input$roadmap_select_project))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        cat("DE Roadmap - Found", nrow(result), "business focus\n")
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "roadmap_select_business_focus", 
                            choices = c("Select..." = "", result$business_focus))
        } else {
          updateSelectInput(session, "roadmap_select_business_focus", choices = c("No business focus available" = ""))
        }
      }, error = function(e) {
        cat("Error loading roadmap business focus:", e$message, "\n")
      })
    })
    
    observeEvent(input$loadRoadmap, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate BigQuery first", type = "error")
        return()
      }
      
      if (is.null(input$roadmap_select_business_area) || input$roadmap_select_business_area == "" ||
          is.null(input$roadmap_select_project) || input$roadmap_select_project == "" ||
          is.null(input$roadmap_select_business_focus) || input$roadmap_select_business_focus == "") {
        showNotification("Please select all fields", type = "warning")
        return()
      }
      
      tryCatch({
        roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        query <- sprintf("SELECT * FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus = '%s' ORDER BY updated_at DESC LIMIT 1",
                         roadmap_table,
                         gsub("'", "''", input$roadmap_select_business_area),
                         gsub("'", "''", input$roadmap_select_project),
                         gsub("'", "''", input$roadmap_select_business_focus))
        
        cat("Executing query:", query, "\n")
        
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        if (nrow(result) > 0) {
          steps_html <- '<div class="de-roadmap-container" style="padding: 20px;">'
          
          step_cols <- c(
            "step_01_market_segmentation", "step_02_select_beachhead_market", "step_03_build_end_user_profile",
            "step_04_calculate_tam_beachhead", "step_05_profile_persona", "step_06_full_life_cycle_use_case",
            "step_07_high_level_product_spec", "step_08_quantify_value_proposition", "step_09_identify_next_10_customers",
            "step_10_define_your_core", "step_11_chart_competitive_position", "step_12_determine_dmu",
            "step_13_map_process_acquire_customer", "step_14_calculate_tam_followon", "step_15_design_business_model",
            "step_16_set_pricing_framework", "step_17_calculate_ltv", "step_18_map_sales_process",
            "step_19_calculate_cac", "step_20_identify_key_assumptions", "step_21_test_key_assumptions",
            "step_22_define_mvbp", "step_23_dogs_eat_dog_food", "step_24_develop_product_plan"
          )
          
          for (i in 1:24) {
            step_col <- step_cols[i]
            if (step_col %in% names(result)) {
              steps_html <- paste0(steps_html, 
                                   '<div class="roadmap-step" style="margin-bottom: 20px; padding: 15px; background: white; border-radius: 8px; border-left: 4px solid #008A82;">',
                                   '<h4 style="color: #008A82; margin-top: 0;">Step ', i, '</h4>',
                                   '<div style="line-height: 1.6;">', gsub("\n", "<br>", result[[step_col]]), '</div>',
                                   '</div>')
            }
          }
          
          steps_html <- paste0(steps_html, '</div>')
          
          output$roadmap_display <- renderUI({
            HTML(steps_html)
          })
          
          showNotification("✓ Roadmap loaded successfully!", type = "message")
        } else {
          showNotification("No roadmap found with selected criteria", type = "warning")
          output$roadmap_display <- renderUI({
            HTML('<div class="alert alert-warning"><h4>No roadmap found</h4></div>')
          })
        }
      }, error = function(e) {
        showNotification(paste("Error loading roadmap:", e$message), type = "error")
        cat("Error:", e$message, "\n")
        output$roadmap_display <- renderUI({
          HTML(paste0('<div class="alert alert-danger"><h4>Error: ', e$message, '</h4></div>'))
        })
      })
    })
    
  })
}