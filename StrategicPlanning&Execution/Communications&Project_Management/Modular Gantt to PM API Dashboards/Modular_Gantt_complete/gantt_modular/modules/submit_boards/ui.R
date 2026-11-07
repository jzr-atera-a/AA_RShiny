# modules/submit_boards/ui.R
# Submit to Boards UI
# ===================

submit_boards_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Submit to Trello",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        selectInput(ns("trello_list"), "Select Trello List:", choices = NULL),
        actionButton(ns("load_trello_lists"), "Load Lists from Board", class = "btn-info"),
        br(), br(),
        actionButton(ns("submit_trello"), "Submit to Trello", 
                     class = "btn-success btn-lg", 
                     icon = icon("trello")),
        br(), br(),
        verbatimTextOutput(ns("trello_result"))
      ),
      box(
        title = "Submit to Jira",
        status = "info",
        solidHeader = TRUE,
        width = 6,
        selectInput(ns("jira_issue_type"), "Issue Type:", 
                    choices = c("Task", "Story", "Bug", "Epic")),
        actionButton(ns("submit_jira"), "Submit to Jira", 
                     class = "btn-success btn-lg",
                     icon = icon("jira")),
        br(), br(),
        verbatimTextOutput(ns("jira_result"))
      )
    ),
    fluidRow(
      box(
        title = "Submission Summary",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        verbatimTextOutput(ns("submission_summary"))
      )
    )
  )
}
