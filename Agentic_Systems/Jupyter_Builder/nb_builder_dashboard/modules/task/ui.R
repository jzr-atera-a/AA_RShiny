task_ui <- function(id) {
  ns <- NS(id)
  tagList(
    # Row 1: spec (left) + run info (right)
    fluidRow(
      column(8,
        box(title = "Notebook Specification", status = "primary",
            solidHeader = TRUE, width = 12,
          div(class = "info-box",
            icon("lightbulb"),
            " Describe what the notebook should do. Be specific about data sources,",
            " packages, and expected outputs."
          ),
          br(),
          textAreaInput(ns("spec"), label = NULL, value = "", rows = 10, width = "100%",
            placeholder = paste(
              "Example:\nBuild an API integration notebook that:\n",
              "1. Loads auth credentials from environment variables\n",
              "2. Paginates through /items endpoint handling rate limits\n",
              "3. Validates responses against schema in context/schema.json\n",
              "4. Parses results into a DataFrame\n",
              "5. Exports to CSV with a timestamp filename"
            )
          ),
          fluidRow(
            column(6, fileInput(ns("specFile"), "Upload .txt spec:", accept = c(".txt",".md"), width = "100%")),
            column(6, selectInput(ns("loadSession"), "Resume existing run:", choices = c("— new run —" = ""), width = "100%"))
          ),
          hr(),
          actionButton(ns("planBtn"), "Plan Task", class = "btn-info", icon = icon("map"), width = "100%"),
          br(), br(),
          actionButton(ns("runBtn"), "Run — Build Notebook", class = "btn-success",
                       icon = icon("play"), width = "100%", disabled = "disabled")
        )
      ),
      column(4,
        box(title = "Run Info", status = "info", solidHeader = TRUE, width = 12,
          uiOutput(ns("runInfo"))
        )
      )
    ),
    # Row 2: plan table — FULL WIDTH
    fluidRow(
      column(12,
        box(title = "Task Plan", status = "primary", solidHeader = TRUE, width = 12,
          uiOutput(ns("planOutput"))
        )
      )
    )
  )
}
