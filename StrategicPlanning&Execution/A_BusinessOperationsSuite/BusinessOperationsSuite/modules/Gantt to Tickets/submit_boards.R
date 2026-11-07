# modules/Gantt to Tickets/submit_boards.R
# Subtab: Submit to Boards

submit_boards_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Submit to Trello", status = "primary", solidHeader = TRUE, width = 6,
          selectInput(ns("trello_list"), "Select Trello List:", choices = NULL),
          actionButton(ns("load_trello_lists"), "Load Lists from Board", class = "btn-info"),
          br(), br(),
          actionButton(ns("submit_trello"), "Submit to Trello", class = "btn-success btn-lg", icon = icon("trello")),
          br(), br(), verbatimTextOutput(ns("trello_result"))),
      box(title = "Submit to Jira", status = "info", solidHeader = TRUE, width = 6,
          selectInput(ns("jira_issue_type"), "Issue Type:", choices = c("Task", "Story", "Bug", "Epic")),
          actionButton(ns("submit_jira"), "Submit to Jira", class = "btn-success btn-lg", icon = icon("jira")),
          br(), br(), verbatimTextOutput(ns("jira_result")))
    ),
    fluidRow(
      box(title = "Submission Summary", status = "success", solidHeader = TRUE, width = 12,
          verbatimTextOutput(ns("submission_summary")))
    )
  )
}

submit_boards_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$load_trello_lists, {
      req(api_manager$trello_key, api_manager$trello_token, api_manager$trello_board_id)
      tryCatch({
        lists <- api_manager$get_trello_lists()
        if (length(lists) == 0) {
          showNotification("Board has no lists. Create lists in Trello first.", type = "warning")
          return()
        }
        list_choices <- setNames(sapply(lists, function(x) as.character(x$id)), sapply(lists, function(x) as.character(x$name)))
        updateSelectInput(session, "trello_list", choices = list_choices)
        showNotification(paste("Loaded", length(list_choices), "lists"), type = "message")
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

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
          desc_parts <- c()
          if ("Description" %in% names(task) && !is.na(task$Description)) desc_parts <- c(desc_parts, task$Description)
          if ("Start_Date" %in% names(task) && !is.na(task$Start_Date)) desc_parts <- c(desc_parts, paste("Start:", task$Start_Date))
          if ("End_Date" %in% names(task) && !is.na(task$End_Date)) desc_parts <- c(desc_parts, paste("End:", task$End_Date))
          if ("Assignee" %in% names(task) && !is.na(task$Assignee)) desc_parts <- c(desc_parts, paste("Assignee:", task$Assignee))
          if ("Priority" %in% names(task) && !is.na(task$Priority)) desc_parts <- c(desc_parts, paste("Priority:", task$Priority))
          description <- paste(desc_parts, collapse = "\n")

          tryCatch({
            success <- api_manager$create_trello_card(list_id = input$trello_list, name = task$Task_Name, description = description)
            results <- c(results, if (success) paste("✓", task$Task_Name) else paste("✗", task$Task_Name, "- Failed"))
          }, error = function(e) {
            results <<- c(results, paste("✗", task$Task_Name, "- Error:", e$message))
          })
          incProgress(1 / nrow(api_manager$gantt_data))
        }
      })

      output$trello_result <- renderText(paste(results, collapse = "\n"))
      showNotification(paste("Submitted", sum(grepl("✓", results)), "of", nrow(api_manager$gantt_data), "tasks"), type = "message")
    })

    observeEvent(input$submit_jira, {
      req(api_manager$gantt_data, api_manager$jira_url, api_manager$jira_email, api_manager$jira_token, api_manager$jira_project_key)

      results <- c()
      withProgress(message = 'Submitting to Jira...', value = 0, {
        for (i in 1:nrow(api_manager$gantt_data)) {
          task <- api_manager$gantt_data[i, ]
          desc_parts <- c()
          if (!is.na(task$Description)) desc_parts <- c(desc_parts, task$Description)
          if (!is.na(task$Start_Date)) desc_parts <- c(desc_parts, paste("Start Date:", task$Start_Date))
          if (!is.na(task$End_Date)) desc_parts <- c(desc_parts, paste("End Date:", task$End_Date))
          if (!is.na(task$Duration_Days)) desc_parts <- c(desc_parts, paste("Duration:", task$Duration_Days, "days"))
          if (!is.na(task$Assignee)) desc_parts <- c(desc_parts, paste("Assignee:", task$Assignee))
          description <- paste(desc_parts, collapse = "\n\n")

          labels <- NULL
          if (!is.na(task$Labels)) labels <- trimws(strsplit(as.character(task$Labels), ",")[[1]])

          result <- api_manager$create_jira_issue(summary = task$Task_Name, description = description,
                                                   issue_type = input$jira_issue_type,
                                                   priority = if (!is.na(task$Priority)) task$Priority else NULL, labels = labels)

          results <- c(results, if (result$success) paste("✓", task$Task_Name, "-", result$key)
                       else paste("✗", task$Task_Name, "- Error:", result$error))
          incProgress(1 / nrow(api_manager$gantt_data))
        }
      })

      output$jira_result <- renderText(paste(results, collapse = "\n"))
      showNotification("Submission to Jira complete!", type = "message")
    })

    output$trello_result <- renderText({ "" })
    output$jira_result <- renderText({ "" })
    output$submission_summary <- renderText({ "" })
  })
}
