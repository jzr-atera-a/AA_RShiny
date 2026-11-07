# modules/submit_boards/server.R
# Submit to Boards Server Logic
# ==============================

submit_boards_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Load Trello Lists
    observeEvent(input$load_trello_lists, {
      req(api_manager$trello_key, api_manager$trello_token, api_manager$trello_board_id)
      
      tryCatch({
        lists <- api_manager$get_trello_lists()
        
        if (length(lists) == 0) {
          showNotification("Board has no lists. Create lists in Trello first.", type = "warning")
          return()
        }
        
        list_choices <- setNames(
          sapply(lists, function(x) as.character(x$id)),
          sapply(lists, function(x) as.character(x$name))
        )
        
        updateSelectInput(session, "trello_list", choices = list_choices)
        showNotification(paste("Loaded", length(list_choices), "lists"), type = "message")
        
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Submit to Trello
    observeEvent(input$submit_trello, {
      req(api_manager$gantt_data, api_manager$trello_key, api_manager$trello_token, input$trello_list)
      
      if (is.null(api_manager$gantt_data) || nrow(api_manager$gantt_data) == 0) {
        showNotification("No tasks to submit", type = "warning")
        return()
      }
      
      results <- c()
      
      withProgress(message = 'Submitting to Trello...', value = 0, {
        for (i in 1:nrow(api_manager$gantt_data)) {
          task <- api_manager$gantt_data[i, ]
          
          # Build description
          desc_parts <- c()
          if ("Description" %in% names(task) && !is.na(task$Description)) {
            desc_parts <- c(desc_parts, task$Description)
          }
          if ("Start_Date" %in% names(task) && !is.na(task$Start_Date)) {
            desc_parts <- c(desc_parts, paste("Start:", task$Start_Date))
          }
          if ("End_Date" %in% names(task) && !is.na(task$End_Date)) {
            desc_parts <- c(desc_parts, paste("End:", task$End_Date))
          }
          if ("Assignee" %in% names(task) && !is.na(task$Assignee)) {
            desc_parts <- c(desc_parts, paste("Assignee:", task$Assignee))
          }
          if ("Priority" %in% names(task) && !is.na(task$Priority)) {
            desc_parts <- c(desc_parts, paste("Priority:", task$Priority))
          }
          
          description <- paste(desc_parts, collapse = "\n")
          
          # Create card
          tryCatch({
            success <- api_manager$create_trello_card(
              list_id = input$trello_list,
              name = task$Task_Name,
              description = description
            )
            
            if (success) {
              results <- c(results, paste("✓", task$Task_Name))
            } else {
              results <- c(results, paste("✗", task$Task_Name, "- Failed"))
            }
          }, error = function(e) {
            results <<- c(results, paste("✗", task$Task_Name, "- Error:", e$message))
          })
          
          incProgress(1/nrow(api_manager$gantt_data))
        }
      })
      
      output$trello_result <- renderText({
        paste(results, collapse = "\n")
      })
      
      showNotification(
        paste("Submitted", sum(grepl("✓", results)), "of", nrow(api_manager$gantt_data), "tasks"), 
        type = "message"
      )
    })
    
    # Submit to Jira
    observeEvent(input$submit_jira, {
      req(api_manager$gantt_data, api_manager$jira_url, api_manager$jira_email, 
          api_manager$jira_token, api_manager$jira_project_key)
      
      results <- c()
      
      withProgress(message = 'Submitting to Jira...', value = 0, {
        for (i in 1:nrow(api_manager$gantt_data)) {
          task <- api_manager$gantt_data[i, ]
          
          # Build description
          desc_parts <- c()
          if (!is.na(task$Description)) desc_parts <- c(desc_parts, task$Description)
          if (!is.na(task$Start_Date)) desc_parts <- c(desc_parts, paste("Start Date:", task$Start_Date))
          if (!is.na(task$End_Date)) desc_parts <- c(desc_parts, paste("End Date:", task$End_Date))
          if (!is.na(task$Duration_Days)) desc_parts <- c(desc_parts, paste("Duration:", task$Duration_Days, "days"))
          if (!is.na(task$Assignee)) desc_parts <- c(desc_parts, paste("Assignee:", task$Assignee))
          
          description <- paste(desc_parts, collapse = "\n\n")
          
          # Prepare labels
          labels <- NULL
          if (!is.na(task$Labels)) {
            labels <- trimws(strsplit(as.character(task$Labels), ",")[[1]])
          }
          
          # Create issue
          result <- api_manager$create_jira_issue(
            summary = task$Task_Name,
            description = description,
            issue_type = input$jira_issue_type,
            priority = if (!is.na(task$Priority)) task$Priority else NULL,
            labels = labels
          )
          
          if (result$success) {
            results <- c(results, paste("✓", task$Task_Name, "-", result$key))
          } else {
            results <- c(results, paste("✗", task$Task_Name, "- Error:", result$error))
          }
          
          incProgress(1/nrow(api_manager$gantt_data))
        }
      })
      
      output$jira_result <- renderText({
        paste(results, collapse = "\n")
      })
      
      showNotification("Submission to Jira complete!", type = "message")
    })
    
    # Default outputs
    output$trello_result <- renderText({ "" })
    output$jira_result <- renderText({ "" })
    output$submission_summary <- renderText({ "" })
  })
}
