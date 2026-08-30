# modules/table_viewer/ui.R

table_viewer_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Select Table to View",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("All four filters below are required. Pick a Category, Topic, Row, and Columns Data ",
          "entry (e.g. one specific ML Model) to view exactly ONE combination at a time - the ",
          "value stored for that single row/column intersection."),

        fluidRow(
          column(3, selectInput(ns("viz_category"), "Category: *", choices = NULL)),
          column(3, selectInput(ns("viz_topic"), "Topic: *", choices = NULL)),
          column(3, selectInput(ns("row_select"), "Row: *", choices = NULL)),
          column(3, selectInput(ns("column_select"), "Columns Data: *", choices = NULL))
        ),

        fluidRow(
          column(12, actionButton(ns("view_value"), "View Value",
                                 class = "btn-success btn-lg", icon = icon("th"),
                                 style = "width: 100%;"))
        ),

        hr(),
        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Selected Combination",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        uiOutput(ns("value_display"))
      )
    )
  )
}
