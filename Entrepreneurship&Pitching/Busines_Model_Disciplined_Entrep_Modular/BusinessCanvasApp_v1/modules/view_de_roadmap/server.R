view_de_roadmap_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    output$roadmap_display <- renderUI({
      HTML('<div class="alert alert-info"><h4>Select a roadmap above and click "Load Data"</h4></div>')
    })
    
    update_dropdowns <- function() {
      if (!api_manager$bq_authenticated) return()
      tryCatch({
        roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        query <- sprintf("SELECT DISTINCT business_area FROM `%s` ORDER BY business_area", roadmap_table)
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        if (nrow(result) > 0) {
          updateSelectInput(session, "roadmap_select_business_area", choices = c("Select..." = "", result$business_area))
        }
      }, error = function(e) {})
    }
    
    observeEvent(input$roadmap_select_business_area, {
      if (input$roadmap_select_business_area == "") return()
      tryCatch({
        roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        query <- sprintf("SELECT DISTINCT project FROM `%s` WHERE business_area = '%s'", 
                         roadmap_table, gsub("'", "\\\\'", input$roadmap_select_business_area))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        if (nrow(result) > 0) {
          updateSelectInput(session, "roadmap_select_project", choices = c("Select..." = "", result$project))
        }
      }, error = function(e) {})
    })
    
    observeEvent(input$roadmap_select_project, {
      if (input$roadmap_select_project == "") return()
      tryCatch({
        roadmap_table <- paste0(api_manager$bq_project_id, ".", api_manager$bq_dataset_id, ".disciplined_entrepreneurship_roadmap")
        query <- sprintf("SELECT DISTINCT business_focus FROM `%s` WHERE business_area = '%s' AND project = '%s'", 
                         roadmap_table, gsub("'", "\\\\'", input$roadmap_select_business_area), 
                         gsub("'", "\\\\'", input$roadmap_select_project))
        job <- bigrquery::bq_project_query(api_manager$bq_project_id, query)
        result <- bigrquery::bq_table_download(job)
        if (nrow(result) > 0) {
          updateSelectInput(session, "roadmap_select_business_focus", choices = c("Select..." = "", result$business_focus))
        }
      }, error = function(e) {})
    })
    
    observeEvent(input$loadRoadmap, {
      if (!api_manager$bq_authenticated) {
        showNotification("Authenticate BigQuery first", type = "error")
        return()
      }
      
      showNotification("Roadmap viewing is ready - data loaded from BigQuery would display here", type = "info")
      
      output$roadmap_display <- renderUI({
        HTML('<div class="de-roadmap-container"><div class="alert alert-success"><h4>✓ Roadmap data would display here</h4><p>The 24 steps would be shown in the grid layout defined in CSS</p></div></div>')
      })
    })
    
    update_dropdowns()
  })
}
