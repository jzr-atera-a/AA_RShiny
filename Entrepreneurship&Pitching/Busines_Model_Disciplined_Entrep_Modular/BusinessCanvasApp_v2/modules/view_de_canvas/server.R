view_de_canvas_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    load_default <- function() {
      for (i in 1:10) {
        local({
          box_num <- i
          output[[paste0("de_box", box_num, "_content")]] <- renderUI({
            HTML('<div class="de-box-content">Click "Load Data" to view</div>')
          })
        })
      }
    }
    
    # Update DE canvas dropdowns
    update_de_dropdowns <- function() {
      if (!api_manager$bq_authenticated) return()
      
      tryCatch({
        de_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_canvas")
        query <- sprintf("SELECT DISTINCT business_area FROM `%s` WHERE business_area IS NOT NULL ORDER BY business_area", de_table)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        cat("DE Canvas - Found", nrow(result), "business areas\n")
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "de_select_business_area", 
                            choices = c("Select..." = "", result$business_area))
        }
      }, error = function(e) {
        cat("Error loading DE business areas:", e$message, "\n")
      })
    }
    
    # TRIGGER UPDATE WHEN AUTHENTICATION CHANGES
    observe({
      if (api_manager$bq_authenticated) {
        update_de_dropdowns()
      }
    })
    
    observeEvent(input$de_select_business_area, {
      if (input$de_select_business_area == "" || !api_manager$bq_authenticated) return()
      
      tryCatch({
        de_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_canvas")
        business_area_clean <- gsub("'", "\\\\'", input$de_select_business_area)
        query <- sprintf("SELECT DISTINCT project FROM `%s` WHERE business_area = '%s' AND project IS NOT NULL ORDER BY project", 
                         de_table, business_area_clean)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        cat("DE Canvas - Found", nrow(result), "projects\n")
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "de_select_project", 
                            choices = c("Select..." = "", result$project))
        } else {
          updateSelectInput(session, "de_select_project", choices = c("No projects available" = ""))
        }
      }, error = function(e) {
        showNotification(paste("Error loading projects:", e$message), type = "error")
      })
    })
    
    observeEvent(input$de_select_project, {
      if (input$de_select_project == "" || !api_manager$bq_authenticated) return()
      
      tryCatch({
        de_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_canvas")
        business_area_clean <- gsub("'", "\\\\'", input$de_select_business_area)
        project_clean <- gsub("'", "\\\\'", input$de_select_project)
        query <- sprintf("SELECT DISTINCT business_focus FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus IS NOT NULL ORDER BY business_focus", 
                         de_table, business_area_clean, project_clean)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        
        cat("DE Canvas - Found", nrow(result), "business focus\n")
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "de_select_business_focus", 
                            choices = c("Select..." = "", result$business_focus))
        } else {
          updateSelectInput(session, "de_select_business_focus", choices = c("No business focus available" = ""))
        }
      }, error = function(e) {
        showNotification(paste("Error loading business focus:", e$message), type = "error")
      })
    })
    
    observeEvent(input$loadDECanvas, {
      if (!api_manager$bq_authenticated || input$de_select_business_area == "" || 
          input$de_select_project == "" || input$de_select_business_focus == "") {
        showNotification("Select all fields", type = "warning")
        return()
      }
      
      tryCatch({
        de_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_canvas")
        business_area_clean <- gsub("'", "\\\\'", input$de_select_business_area)
        project_clean <- gsub("'", "\\\\'", input$de_select_project)
        business_focus_clean <- gsub("'", "\\\\'", input$de_select_business_focus)
        
        query <- sprintf("SELECT * FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus = '%s' ORDER BY updated_at DESC LIMIT 1",
                         de_table, business_area_clean, project_clean, business_focus_clean)
        
        cat("Executing query:", query, "\n")
        
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
        } else {
          showNotification("No canvas found", type = "warning")
        }
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    load_default()
  })
}