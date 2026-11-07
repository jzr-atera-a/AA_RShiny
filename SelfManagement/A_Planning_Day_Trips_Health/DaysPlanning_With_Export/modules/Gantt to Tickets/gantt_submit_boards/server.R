# modules/Gantt to Tickets/gantt_submit_boards/server.R

gantt_submit_boards_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$load_trello_lists, {
      req(api_manager$trello_key, api_manager$trello_token, api_manager$trello_board_id)
      tryCatch({
        lists <- api_manager$get_trello_lists()
        if (length(lists) == 0) { showNotification("Board has no lists. Create lists in Trello first.", type = "warning"); return() }
        list_choices <- setNames(sapply(lists, function(x) as.character(x$id)), sapply(lists, function(x) as.character(x$name)))
        updateSelectInput(session, "trello_list", choices = list_choices)
        showNotification(paste("Loaded", length(list_choices), "lists"), type = "message")
      }, error = function(e) { showNotification(paste("Error:", e$message), type = "error") })
    })

    observeEvent(input$submit_trello, {
      req(api_manager$gantt_tasks_data, api_manager$trello_key, api_manager$trello_token, input$trello_list)
      d <- api_manager$gantt_tasks_data
      if (is.null(d) || nrow(d) == 0) { showNotification("No tasks to submit", type = "warning"); return() }

      results <- c()
      log_rows <- list()

      withProgress(message = 'Submitting to Trello...', value = 0, {
        for (i in 1:nrow(d)) {
          task <- d[i, ]
          desc_parts <- c()
          if ("Description" %in% names(task) && !is.na(task$Description)) desc_parts <- c(desc_parts, task$Description)
          if ("Start_Date" %in% names(task) && !is.na(task$Start_Date)) desc_parts <- c(desc_parts, paste("Start:", task$Start_Date))
          if ("End_Date" %in% names(task) && !is.na(task$End_Date)) desc_parts <- c(desc_parts, paste("End:", task$End_Date))
          if ("Assignee" %in% names(task) && !is.na(task$Assignee)) desc_parts <- c(desc_parts, paste("Assignee:", task$Assignee))
          description <- paste(desc_parts, collapse = "\n")

          result <- tryCatch(api_manager$create_trello_card(input$trello_list, task$Task_Name, description),
                             error = function(e) list(success = FALSE, error = e$message))

          submission_result <- if (isTRUE(result$success)) paste("Card:", result$url) else paste("Failed:", result$error %||% "unknown error")
          results <- c(results, paste(if (isTRUE(result$success)) "✓" else "✗", task$Task_Name, "-", submission_result))

          log_rows[[length(log_rows) + 1]] <- data.frame(
            task_name = task$Task_Name %||% "",
            description = if ("Description" %in% names(task)) as.character(task$Description) else "",
            start_date = if ("Start_Date" %in% names(task)) as.character(task$Start_Date) else "",
            end_date = if ("End_Date" %in% names(task)) as.character(task$End_Date) else "",
            duration_days = if ("Duration_Days" %in% names(task)) as.character(task$Duration_Days) else "",
            assignee = if ("Assignee" %in% names(task)) as.character(task$Assignee) else "",
            priority = if ("Priority" %in% names(task)) as.character(task$Priority) else "",
            status = if ("Status" %in% names(task)) as.character(task$Status) else "",
            labels = if ("Labels" %in% names(task)) as.character(task$Labels) else "",
            additional_notes = if ("Additional_Notes" %in% names(task)) as.character(task$Additional_Notes) else "",
            submission_result = submission_result,
            stringsAsFactors = FALSE
          )
          incProgress(1 / nrow(d))
        }
      })

      output$trello_result <- renderText({ paste(results, collapse = "\n") })
      showNotification(paste("Submitted", sum(grepl("✓", results)), "of", nrow(d), "tasks"), type = "message")

      if (api_manager$bq_authenticated && length(log_rows) > 0) {
        tryCatch({
          batch_df <- do.call(rbind, log_rows)
          api_manager$bq_insert_gantt_tasks(batch_df, log_stage = "Submitted_Trello",
                                            upload_batch = paste0("Trello_", format(Sys.time(), "%Y-%m-%d_%H%M%S")))
        }, error = function(e) { cat("⚠️  Failed to log Trello submission to BigQuery:", e$message, "\n") })
      }
    })

    observeEvent(input$submit_jira, {
      req(api_manager$gantt_tasks_data, api_manager$jira_url, api_manager$jira_email,
          api_manager$jira_token, api_manager$jira_project_key)
      d <- api_manager$gantt_tasks_data
      if (is.null(d) || nrow(d) == 0) { showNotification("No tasks to submit", type = "warning"); return() }

      results <- c()
      log_rows <- list()

      withProgress(message = 'Submitting to Jira...', value = 0, {
        for (i in 1:nrow(d)) {
          task <- d[i, ]
          desc_parts <- c()
          if ("Description" %in% names(task) && !is.na(task$Description)) desc_parts <- c(desc_parts, task$Description)
          if ("Start_Date" %in% names(task) && !is.na(task$Start_Date)) desc_parts <- c(desc_parts, paste("Start Date:", task$Start_Date))
          if ("End_Date" %in% names(task) && !is.na(task$End_Date)) desc_parts <- c(desc_parts, paste("End Date:", task$End_Date))
          description <- paste(desc_parts, collapse = "\n\n")

          labels <- if ("Labels" %in% names(task) && !is.na(task$Labels)) trimws(strsplit(as.character(task$Labels), ",")[[1]]) else NULL

          result <- api_manager$create_jira_issue(
            summary = task$Task_Name, description = description, issue_type = input$jira_issue_type,
            priority = if ("Priority" %in% names(task) && !is.na(task$Priority)) task$Priority else NULL, labels = labels
          )

          submission_result <- if (result$success) paste("Issue:", result$key) else paste("Failed:", result$error)
          results <- c(results, paste(if (result$success) "✓" else "✗", task$Task_Name, "-", submission_result))

          log_rows[[length(log_rows) + 1]] <- data.frame(
            task_name = task$Task_Name %||% "",
            description = if ("Description" %in% names(task)) as.character(task$Description) else "",
            start_date = if ("Start_Date" %in% names(task)) as.character(task$Start_Date) else "",
            end_date = if ("End_Date" %in% names(task)) as.character(task$End_Date) else "",
            duration_days = if ("Duration_Days" %in% names(task)) as.character(task$Duration_Days) else "",
            assignee = if ("Assignee" %in% names(task)) as.character(task$Assignee) else "",
            priority = if ("Priority" %in% names(task)) as.character(task$Priority) else "",
            status = if ("Status" %in% names(task)) as.character(task$Status) else "",
            labels = if ("Labels" %in% names(task)) as.character(task$Labels) else "",
            additional_notes = if ("Additional_Notes" %in% names(task)) as.character(task$Additional_Notes) else "",
            submission_result = submission_result,
            stringsAsFactors = FALSE
          )
          incProgress(1 / nrow(d))
        }
      })

      output$jira_result <- renderText({ paste(results, collapse = "\n") })
      showNotification("Submission to Jira complete!", type = "message")

      if (api_manager$bq_authenticated && length(log_rows) > 0) {
        tryCatch({
          batch_df <- do.call(rbind, log_rows)
          api_manager$bq_insert_gantt_tasks(batch_df, log_stage = "Submitted_Jira",
                                            upload_batch = paste0("Jira_", format(Sys.time(), "%Y-%m-%d_%H%M%S")))
        }, error = function(e) { cat("⚠️  Failed to log Jira submission to BigQuery:", e$message, "\n") })
      }
    })

    output$submission_summary <- renderText({
      if (!api_manager$bq_authenticated) return("Connect to BigQuery to see submission history.")
      tryCatch({
        d <- api_manager$bq_get_gantt_tasks(limit = 20)
        if (nrow(d) == 0) return("No submissions logged yet.")
        paste(sprintf("[%s] %s - %s (%s)", d$log_stage, d$task_name, d$submission_result, d$created_at), collapse = "\n")
      }, error = function(e) paste("Error loading history:", e$message))
    })

    output$trello_result <- renderText({ "" })
    output$jira_result <- renderText({ "" })
    session$onSessionEnded(function() {})
  })
}
