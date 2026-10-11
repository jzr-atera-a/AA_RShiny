# modules/Day Planner/schedule_prep_checklist/ui.R

schedule_prep_checklist_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Select Preparation Date", status = "primary", solidHeader = TRUE, width = 12,
          p("Your progress is saved automatically - no save button needed."),
          fluidRow(
            column(6, dateInput(ns("select_date"), "Which day are you preparing for?", value = Sys.Date() + 1)),
            column(6, br(), actionButton(ns("btn_refresh"), "Refresh", class = "btn-info", icon = icon("sync")))
          )
      )
    ),

    fluidRow(
      box(title = "Progress Overview", status = "warning", solidHeader = TRUE, width = 12,
          htmlOutput(ns("progress_stats")))
    ),

    fluidRow(
      box(title = "Preparation Steps", status = "success", solidHeader = TRUE, width = 12,
          htmlOutput(ns("steps_checklist")))
    )
  )
}
