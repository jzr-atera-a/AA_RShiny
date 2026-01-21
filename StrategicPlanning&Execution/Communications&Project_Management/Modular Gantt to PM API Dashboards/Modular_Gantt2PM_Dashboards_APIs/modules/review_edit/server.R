# modules/review_edit/server.R
# Review & Edit Tasks Server Logic
# =================================

review_edit_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive trigger to reload when data changes
    observe({
      api_manager$state_trigger()
      
      if (!is.null(api_manager$gantt_data)) {
        # Update task selector
        updateSelectInput(session, "select_task", 
                          choices = api_manager$gantt_data$Task_Name)
      }
    })
    
    # Render editable table
    output$editable_table <- DT::renderDataTable({
      req(api_manager$gantt_data)
      DT::datatable(
        api_manager$gantt_data,
        editable = TRUE,
        options = list(scrollX = TRUE, pageLength = 15)
      )
    })
    
    # Handle table edits
    observeEvent(input$editable_table_cell_edit, {
      info <- input$editable_table_cell_edit
      api_manager$gantt_data[info$row, info$col] <- info$value
      api_manager$trigger_state_update()
    })
    
    # Update selected task with additional info
    observeEvent(input$update_task, {
      req(api_manager$gantt_data, input$select_task)
      
      row_idx <- which(api_manager$gantt_data$Task_Name == input$select_task)
      
      if (length(row_idx) > 0) {
        # Add or update additional notes
        if (!"Additional_Notes" %in% names(api_manager$gantt_data)) {
          api_manager$gantt_data$Additional_Notes <- NA
        }
        api_manager$gantt_data$Additional_Notes[row_idx] <- input$additional_notes
        
        # Append labels
        if (input$additional_labels != "") {
          current_labels <- api_manager$gantt_data$Labels[row_idx]
          if (is.na(current_labels) || current_labels == "") {
            api_manager$gantt_data$Labels[row_idx] <- input$additional_labels
          } else {
            api_manager$gantt_data$Labels[row_idx] <- paste(current_labels, 
                                                             input$additional_labels, 
                                                             sep = ",")
          }
        }
        
        api_manager$trigger_state_update()
        showNotification("Task updated successfully!", type = "message")
      }
    })
    
    # Refresh table
    observeEvent(input$refresh_table, {
      api_manager$trigger_state_update()
    })
  })
}
