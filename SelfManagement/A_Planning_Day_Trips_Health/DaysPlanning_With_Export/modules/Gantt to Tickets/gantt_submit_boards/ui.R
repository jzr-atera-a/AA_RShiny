# modules/Gantt to Tickets/gantt_submit_boards/ui.R

gantt_submit_boards_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Submit to Trello", status = "primary", solidHeader = TRUE, width = 6,
          actionButton(ns("load_trello_lists"), "Load Trello Lists", class = "btn-info"),
          selectInput(ns("trello_list"), "Trello List:", choices = NULL),
          actionButton(ns("submit_trello"), "Submit Tasks to Trello", class = "btn-success btn-lg", icon = icon("trello")),
          br(), br(),
          verbatimTextOutput(ns("trello_result"))
      ),
      box(title = "Submit to Jira", status = "info", solidHeader = TRUE, width = 6,
          selectInput(ns("jira_issue_type"), "Issue Type:", choices = c("Task", "Bug", "Story"), selected = "Task"),
          actionButton(ns("submit_jira"), "Submit Tasks to Jira", class = "btn-success btn-lg", icon = icon("jira")),
          br(), br(),
          verbatimTextOutput(ns("jira_result"))
      )
    ),
    fluidRow(
      box(title = "Submission History (from BigQuery)", status = "success", solidHeader = TRUE, width = 12,
          p("Every submission is logged as its own row in ", tags$code("gantt_tasks"), " - nothing here is ever overwritten."),
          verbatimTextOutput(ns("submission_summary"))
      )
    )
  )
}
