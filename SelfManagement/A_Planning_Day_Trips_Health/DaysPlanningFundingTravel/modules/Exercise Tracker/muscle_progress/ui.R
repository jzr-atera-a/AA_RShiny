# modules/Exercise Tracker/muscle_progress/ui.R

muscle_progress_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(box(title = "Progress", status = "primary", solidHeader = TRUE, width = 12,
      actionButton(ns("reload"), "Reload from BigQuery", icon = icon("sync"), class = "btn-sm"),
      uiOutput(ns("headline")),
      tabsetPanel(
        tabPanel("Weekly volume", br(),
                 plotly::plotlyOutput(ns("vol_plot"), height = "380px"), br(),
                 h4("This week against target"), plotly::plotlyOutput(ns("target_plot"), height = "520px"), br(),
                 h4("Week over week"), DT::dataTableOutput(ns("wow_tbl"))),
        tabPanel("Lifts (progressive overload)", br(),
                 selectInput(ns("exercise"), "Exercise", choices = character(0), width = "400px"),
                 plotly::plotlyOutput(ns("lift_plot"), height = "380px"), DT::dataTableOutput(ns("lift_tbl"))),
        tabPanel("Weekly set targets", br(),
                 p("Each build week adds sets from the minimum effective volume (MEV) towards the maximum recoverable volume (MRV); week 5 is a deload at about half the MEV. ",
                   "Edit MEV / MRV (double-click a cell) and save to change the targets for every future week. Evidence-based range: roughly 10-20 hard sets per big muscle per week."),
                 DT::dataTableOutput(ns("targets_tbl")),
                 actionButton(ns("save_targets"), "Save targets to BigQuery", icon = icon("cloud-upload-alt"), class = "btn-success"),
                 actionButton(ns("reset_targets"), "Reset to defaults", icon = icon("undo")),
                 htmlOutput(ns("status")),
                 h4("Resulting weekly targets (sets)"), DT::dataTableOutput(ns("ramp_tbl")))
      )))
  )
}
