# modules/email_send/server.R
# Send Email Notifications Server Logic
# ======================================

email_send_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Email Preview Table
    output$email_preview_table <- DT::renderDataTable({
      req(api_manager$gantt_data)
      
      if ("Assignee" %in% names(api_manager$gantt_data)) {
        email_preview <- api_manager$gantt_data %>%
          dplyr::filter(!is.na(Assignee) & Assignee != "") %>%
          dplyr::select(Task_Name, Assignee, Priority, Start_Date, End_Date)
        
        DT::datatable(email_preview, 
                      options = list(scrollX = TRUE, pageLength = 10))
      }
    })
    
    # Email Summary
    output$email_summary <- renderText({
      req(api_manager$gantt_data)
      
      if ("Assignee" %in% names(api_manager$gantt_data)) {
        tasks_with_assignees <- api_manager$gantt_data %>%
          dplyr::filter(!is.na(Assignee) & Assignee != "")
        
        unique_assignees <- unique(tasks_with_assignees$Assignee)
        
        if (input$group_by_assignee) {
          paste0(
            "Total tasks to notify: ", nrow(tasks_with_assignees), "\n",
            "Unique assignees: ", length(unique_assignees), "\n",
            "Emails to send: ", length(unique_assignees), "\n\n",
            "Assignees: ", paste(unique_assignees, collapse = ", ")
          )
        } else {
          paste0(
            "Total tasks to notify: ", nrow(tasks_with_assignees), "\n",
            "Unique assignees: ", length(unique_assignees), "\n",
            "Emails to send: ", nrow(tasks_with_assignees), " (one per task)\n\n",
            "Assignees: ", paste(unique_assignees, collapse = ", ")
          )
        }
      } else {
        "No assignees found in the data. Please add an 'Assignee' column."
      }
    })
    
    # Send Test Email
    observeEvent(input$send_test_email, {
      req(api_manager$gantt_data, api_manager$email_connected)
      
      if (nrow(api_manager$gantt_data) == 0) {
        showNotification("No tasks to preview", type = "warning")
        return()
      }
      
      sample_task <- api_manager$gantt_data[1, ]
      subject <- "Test Email - Task Assignment"
      body <- paste0(
        "**THIS IS A TEST EMAIL**\n\n",
        "Task: ", sample_task$Task_Name, "\n",
        "Description: ", ifelse(is.na(sample_task$Description), "N/A", sample_task$Description), "\n",
        "Start: ", ifelse(is.na(sample_task$Start_Date), "N/A", sample_task$Start_Date), "\n",
        "End: ", ifelse(is.na(sample_task$End_Date), "N/A", sample_task$End_Date), "\n\n",
        "---\n*This is how your task notifications will look.*"
      )
      
      tryCatch({
        api_manager$send_email(
          to = api_manager$smtp_config$user,
          subject = subject,
          body = body
        )
        showNotification("Test email sent to your address!", type = "message")
      }, error = function(e) {
        showNotification(paste("Failed to send test email:", e$message), type = "error")
      })
    })
    
    # Send All Emails
    observeEvent(input$send_emails, {
      req(api_manager$gantt_data, api_manager$email_connected)
      
      if (!"Assignee" %in% names(api_manager$gantt_data)) {
        showNotification("No 'Assignee' column found in data", type = "error")
        return()
      }
      
      tasks_with_assignees <- api_manager$gantt_data %>%
        dplyr::filter(!is.na(Assignee) & Assignee != "")
      
      if (nrow(tasks_with_assignees) == 0) {
        showNotification("No tasks with assignees found", type = "warning")
        return()
      }
      
      results <- c()
      
      tryCatch({
        if (input$group_by_assignee) {
          unique_assignees <- unique(tasks_with_assignees$Assignee)
          
          withProgress(message = 'Sending emails...', value = 0, {
            for (assignee in unique_assignees) {
              assignee_tasks <- tasks_with_assignees %>%
                dplyr::filter(Assignee == assignee)
              
              task_list <- ""
              for (i in 1:nrow(assignee_tasks)) {
                task <- assignee_tasks[i, ]
                task_list <- paste0(
                  task_list,
                  "\n\n--- Task ", i, " ---\n",
                  "Task: ", task$Task_Name, "\n",
                  ifelse(!is.na(task$Description), paste0("Description: ", task$Description, "\n"), ""),
                  ifelse(!is.na(task$Start_Date), paste0("Start Date: ", task$Start_Date, "\n"), ""),
                  ifelse(!is.na(task$End_Date), paste0("End Date: ", task$End_Date, "\n"), ""),
                  ifelse(!is.na(task$Priority), paste0("Priority: ", task$Priority, "\n"), "")
                )
              }
              
              subject <- paste("Task Assignment:", nrow(assignee_tasks), "tasks assigned")
              body <- paste0(
                "Hello ", assignee, ",\n\n",
                "You have been assigned ", nrow(assignee_tasks), " task(s):\n",
                task_list,
                "\n\nPlease review and confirm.\n\nBest regards"
              )
              
              to_email <- parse_email(assignee)
              
              api_manager$send_email(to = to_email, subject = subject, body = body)
              results <- c(results, paste("✓ Sent to", assignee, "-", nrow(assignee_tasks), "tasks"))
              incProgress(1/length(unique_assignees))
            }
          })
        } else {
          withProgress(message = 'Sending emails...', value = 0, {
            for (i in 1:nrow(tasks_with_assignees)) {
              task <- tasks_with_assignees[i, ]
              
              subject <- paste("New Task Assignment:", task$Task_Name)
              body <- paste0(
                "Hello ", task$Assignee, ",\n\n",
                "You have been assigned a new task:\n\n",
                "Task: ", task$Task_Name, "\n",
                ifelse(!is.na(task$Description), paste0("Description: ", task$Description, "\n"), ""),
                ifelse(!is.na(task$Start_Date), paste0("Start Date: ", task$Start_Date, "\n"), ""),
                ifelse(!is.na(task$End_Date), paste0("End Date: ", task$End_Date, "\n"), ""),
                ifelse(!is.na(task$Priority), paste0("Priority: ", task$Priority, "\n"), ""),
                "\n\nPlease review and confirm.\n\nBest regards"
              )
              
              to_email <- parse_email(task$Assignee)
              
              api_manager$send_email(to = to_email, subject = subject, body = body)
              results <- c(results, paste("✓", task$Task_Name, "->", task$Assignee))
              incProgress(1/nrow(tasks_with_assignees))
            }
          })
        }
        
        output$email_send_result <- renderText({
          paste(results, collapse = "\n")
        })
        
        showNotification(
          paste("Successfully sent", length(results), "email(s)!"), 
          type = "message", 
          duration = 10
        )
        
      }, error = function(e) {
        showNotification(paste("Error sending emails:", e$message), type = "error")
        output$email_send_result <- renderText({
          paste("Error:", e$message, "\n\nResults so far:\n", paste(results, collapse = "\n"))
        })
      })
    })
    
    # Default outputs
    output$email_send_result <- renderText({ "" })
  })
}
