# modules/Technical Designs/techdesign_recommender/ui.R

techdesign_recommender_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Design Recommender", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "alert alert-info",
              "Describe the problem you are solving. The Editing Tool ranks the best-fitting designs across ML / GenAI, Data Processing and Software Patterns. ",
              "Click a recommendation to jump to the matching subtab with the design preselected."),
          textAreaInput(ns("problem"), "Problem / situation: *", rows = 5, width = "100%",
                        placeholder = "e.g., We need to detect card fraud within 200 ms using live transactions and recent customer behaviour, and retrain weekly."),
          fluidRow(
            column(6, textInput(ns("constraints"), "Constraints (optional):", placeholder = "e.g., GCP only, small team, strict audit requirements")),
            column(3, numericInput(ns("n"), "How many designs:", value = 3, min = 1, max = 5)),
            column(3, checkboxInput(ns("pass_context"), "Pass my problem as context when jumping", value = TRUE))
          ),
          actionButton(ns("go"), "Recommend Designs", icon = icon("lightbulb"), class = "btn-primary btn-lg"),
          htmlOutput(ns("status"))
      )
    ),
    fluidRow(box(title = "Recommendations", status = "success", solidHeader = TRUE, width = 12, uiOutput(ns("results"))))
  )
}
