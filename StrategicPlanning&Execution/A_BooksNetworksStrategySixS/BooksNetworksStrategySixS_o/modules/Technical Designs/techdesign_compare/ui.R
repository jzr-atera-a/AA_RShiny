# modules/Technical Designs/techdesign_compare/ui.R

techdesign_compare_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Compare Designs", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "alert alert-info",
              "Pick any two designs (starter library or saved). The app draws them side by side and computes a comparison table. ",
              "Optionally ask the Editing Tool for a deeper written comparison."),
          fluidRow(
            column(5, selectInput(ns("a"), "Design A:", choices = c("Loading..." = ""))),
            column(5, selectInput(ns("b"), "Design B:", choices = c("Loading..." = ""))),
            column(2, br(), actionButton(ns("reload"), "Reload lists", icon = icon("sync"), class = "btn-default"))
          ),
          fluidRow(
            column(4, actionButton(ns("compare"), "Compare", icon = icon("columns"), class = "btn-primary btn-lg", style = "width:100%;")),
            column(5, textInput(ns("focus"), NULL, placeholder = "Optional focus for the Editing Tool, e.g., cost and operations")),
            column(3, actionButton(ns("ask"), "Ask the Editing Tool", icon = icon("robot"), class = "btn-info btn-lg", style = "width:100%;"))
          ),
          htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      box(title = "Side by Side", status = "info", solidHeader = TRUE, width = 12,
          export_controls_ui(ns, ns("export_target"), "technical_design_comparison"),
          uiOutput(ns("view")))
    )
  )
}
