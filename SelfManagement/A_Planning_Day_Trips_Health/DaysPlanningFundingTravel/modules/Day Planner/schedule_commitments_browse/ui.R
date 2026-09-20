# modules/Day Planner/schedule_commitments_browse/ui.R

schedule_commitments_browse_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Browse Monthly Commitments", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary", icon = icon("sync"))),
            column(3, downloadButton(ns("download"), "Download CSV", class = "btn-info")),
            column(6, br())
          ),
          br(), htmlOutput(ns("status")), br(),
          DT::dataTableOutput(ns("table"))
      )
    ),
    fluidRow(
      box(title = "Update Status of Selected Commitment", status = "warning", solidHeader = TRUE, width = 12,
          p("Click a row above to select it."),
          fluidRow(
            column(6, selectInput(ns("new_status"), "New Status:",
                                 choices = c("Not Started", "In Progress", "Delivered", "Missed", "At Risk"))),
            column(6, br(), actionButton(ns("btn_update_status"), "Update Status", class = "btn-warning"))
          ),
          htmlOutput(ns("update_status_msg"))
      )
    ),
    fluidRow(
      box(title = "Plan a Day Around This Commitment", status = "success", solidHeader = TRUE, width = 12,
          p("Load the selected commitment's full context into Generate Schedule's Additional Details field, ",
            "so Claude factors in the deadline, stakeholders, value, and consequences when planning that day."),
          actionButton(ns("btn_send_to_generate"), "Send to Generate Schedule", class = "btn-success btn-lg", icon = icon("route")),
          br(), br(),
          htmlOutput(ns("send_status"))
      )
    )
  )
}
