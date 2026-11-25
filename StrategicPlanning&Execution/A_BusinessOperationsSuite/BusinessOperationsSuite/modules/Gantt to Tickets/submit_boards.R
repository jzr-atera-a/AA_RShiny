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
          actionButton(ns("pull_trello"), "Read status back", class = "btn-info", icon = icon("sync")),
          helpText("Tasks sent before are updated, not added again. Cards made by CollaborationPlanning on the same board are left alone."),
          br(), br(), verbatimTextOutput(ns("trello_result"))),
      box(title = "Submit to Jira", status = "info", solidHeader = TRUE, width = 6,
          selectInput(ns("jira_issue_type"), "Issue Type:", choices = c("Task", "Story", "Bug", "Epic")),
          actionButton(ns("submit_jira"), "Submit to Jira", class = "btn-success btn-lg", icon = icon("jira")),
          br(), br(), verbatimTextOutput(ns("jira_result")))
    ),
    fluidRow(
      box(title = "Submission History (from BigQuery)", status = "success", solidHeader = TRUE, width = 12,
          p("Every submission is logged as its own row in ", tags$code("gantt_tasks"), " - nothing is ever overwritten."),
          actionButton(ns("refresh_history"), "Refresh", icon = icon("sync"), class = "btn-info"), br(), br(),
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
      d <- api_manager$gantt_data
      for (col in c("Trello_Card_ID", "Trello_URL")) if (!col %in% names(d)) d[[col]] <- ""
      # cards already on the board: a task sent before is UPDATED, not added again. Cards made by CollaborationPlanning
      # (its own tasks) are never touched.
      board <- tryCatch(api_manager$trello_board_cards(), error = function(e) NULL)
      if (!is.null(board)) board <- board[!board$closed & !grepl(GANTT_TRELLO_CP_MARK, board$desc, fixed = TRUE), , drop = FALSE]

      results <- c(); n_new <- 0; n_upd <- 0
      withProgress(message = 'Submitting to Trello...', value = 0, {
        for (i in 1:nrow(d)) {
          task <- d[i, ]
          desc_parts <- c()
          if ("Description" %in% names(task) && !is.na(task$Description)) desc_parts <- c(desc_parts, task$Description)
          if ("Start_Date" %in% names(task) && !is.na(task$Start_Date)) desc_parts <- c(desc_parts, paste("Start:", task$Start_Date))
          if ("End_Date" %in% names(task) && !is.na(task$End_Date)) desc_parts <- c(desc_parts, paste("End:", task$End_Date))
          if ("Assignee" %in% names(task) && !is.na(task$Assignee)) desc_parts <- c(desc_parts, paste("Assignee:", task$Assignee))
          if ("Priority" %in% names(task) && !is.na(task$Priority)) desc_parts <- c(desc_parts, paste("Priority:", task$Priority))
          description <- paste(c(desc_parts, GANTT_TRELLO_MARK), collapse = "\n")

          card_id <- as.character(task$Trello_Card_ID %||% ""); if (is.na(card_id)) card_id <- ""
          if (!nzchar(card_id) && !is.null(board)) { hit <- which(board$name == task$Task_Name); if (length(hit)) card_id <- board$id[hit[1]] }
          due <- tryCatch(format(as.Date(as.character(task$End_Date))), error = function(e) "")
          if (is.na(due)) due <- ""
          tryCatch({
            card <- tryCatch(api_manager$trello_card_upsert(card_id, input$trello_list, task$Task_Name, description, due),
              error = function(e) if (nzchar(card_id) && grepl("not found|invalid id|404", conditionMessage(e), ignore.case = TRUE))
                api_manager$trello_card_upsert("", input$trello_list, task$Task_Name, description, due) else stop(e))   # deleted on Trello
            if (nzchar(card_id) && identical(card$id, card_id)) n_upd <- n_upd + 1 else n_new <- n_new + 1
            d$Trello_Card_ID[i] <- card$id; d$Trello_URL[i] <- card$url
            results <- c(results, paste("✓", task$Task_Name, if (identical(card$id, card_id)) "(updated)" else "(new)", card$url))
          }, error = function(e) {
            results <<- c(results, paste("✗", task$Task_Name, "- Error:", conditionMessage(e)))
          })
          incProgress(1 / nrow(d))
        }
      })
      api_manager$gantt_data <- d
      api_manager$trigger_state_update_gantt()

      gantt_log_submission(api_manager, results, "Submitted_Trello", "Trello")
      output$trello_result <- renderText(paste(results, collapse = "\n"))
      showNotification(sprintf("Trello: %d new card(s), %d updated.", n_new, n_upd), type = "message")
    })

    # status back from the board (same rule as CollaborationPlanning: Done / In Progress / Blocked by list name or completion)
    observeEvent(input$pull_trello, {
      d <- api_manager$gantt_data
      if (is.null(d) || !"Trello_Card_ID" %in% names(d) || !any(nzchar(na.omit(d$Trello_Card_ID)))) {
        output$trello_result <- renderText("No tasks have been sent to Trello yet in this session."); return()
      }
      r <- tryCatch({
        cards <- api_manager$trello_board_cards()
        lists <- api_manager$trello_call("GET", paste0("boards/", api_manager$trello_board_id, "/lists"), list(fields = "name"))
        ln <- setNames(tolower(vapply(lists, function(x) as.character(x$name), "")), vapply(lists, function(x) as.character(x$id), ""))
        if (!"Status" %in% names(d)) d$Status <- ""
        n <- 0
        for (i in which(nzchar(d$Trello_Card_ID %||% ""))) {
          cd <- cards[cards$id == d$Trello_Card_ID[i], , drop = FALSE]; if (!nrow(cd)) next
          l <- ln[[cd$idList]] %||% ""
          st <- if (cd$closed || cd$dueComplete || grepl("done|complete", l)) "Done" else if (grepl("doing|progress", l)) "In Progress"
                else if (grepl("block", l)) "Blocked" else d$Status[i]
          if (!identical(as.character(st), as.character(d$Status[i]))) { d$Status[i] <- st; n <- n + 1 }
        }
        api_manager$gantt_data <- d; api_manager$trigger_state_update_gantt()
        sprintf("Checked the board: %d status change(s). See Review & Edit.", n)
      }, error = function(e) paste("Could not read the board:", conditionMessage(e)))
      output$trello_result <- renderText(r)
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

      gantt_log_submission(api_manager, results, "Submitted_Jira", "Jira")
      output$jira_result <- renderText(paste(results, collapse = "\n"))
      showNotification("Submission to Jira complete!", type = "message")
    })

    output$trello_result <- renderText({ "" })
    output$jira_result <- renderText({ "" })
    output$submission_summary <- renderText({
      input$refresh_history; api_manager$state_trigger_gantt()
      if (!isTRUE(api_manager$bq_authenticated)) return("Connect to BigQuery (API Settings > BigQuery) to see the submission history.")
      d <- api_manager$bq_get_gantt_tasks(limit = 30)
      if (is.null(d) || nrow(d) == 0) return("No submissions logged yet.")
      paste(sprintf("[%s] %s - %s (%s)", d$log_stage, d$task_name, d$submission_result, d$created_at), collapse = "\n")
    })
  })
}

# Logs one row per task to BigQuery gantt_tasks after a Trello/Jira run (skipped quietly without BigQuery).
gantt_log_submission <- function(api_manager, results, stage, board) {
  d <- api_manager$gantt_data
  if (!isTRUE(api_manager$bq_authenticated) || is.null(d) || nrow(d) == 0) return(invisible(FALSE))
  res <- rep_len(if (length(results)) results else "", nrow(d))
  tryCatch({
    api_manager$bq_insert_gantt_tasks(gantt_rows_for_bq(d, res, api_manager$gantt_time_zone), log_stage = stage,
                                      upload_batch = paste0(board, "_", format(Sys.time(), "%Y-%m-%d_%H%M%S")))
    api_manager$trigger_state_update_gantt()
    TRUE
  }, error = function(e) { showNotification(paste("Submitted, but the BigQuery log failed:", conditionMessage(e)), type = "warning"); FALSE })
}

# marks in card descriptions: ours, and the one CollaborationPlanning writes on its own task cards
GANTT_TRELLO_MARK <- "From Business Operations Suite - Gantt to Tickets"
GANTT_TRELLO_CP_MARK <- "From Collaboration Planning task"
