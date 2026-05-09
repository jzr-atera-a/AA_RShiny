# ============================================================================
# TASK MODULE - UI
# Tab 2: Write spec, load previous session, kick off planning
# ============================================================================

task_ui <- function(id) {
  ns <- NS(id)

  fluidRow(

    column(8,
      box(
        title = "Notebook Specification", status = "primary",
        solidHeader = TRUE, width = 12,

        div(class = "info-box",
          icon("lightbulb"), " Describe what the notebook should do.",
          " Be specific about data sources, packages, and expected outputs.",
          " Agent 1 will first produce a cell-by-cell plan for your approval before writing any code."
        ),
        br(),

        textAreaInput(ns("spec"),
          label    = NULL,
          value    = "",
          rows     = 10,
          width    = "100%",
          placeholder = paste(
            "Example:\n",
            "Build an API integration notebook that:\n",
            "1. Loads auth credentials from environment variables\n",
            "2. Paginate through the /items endpoint handling rate limits\n",
            "3. Validates each response against the schema in context/schema.json\n",
            "4. Parses results into a DataFrame and computes summary stats\n",
            "5. Exports to CSV with a timestamp filename"
          )
        ),

        fluidRow(
          column(6,
            fileInput(ns("specFile"), "Or upload a .txt spec file:",
                      accept = c(".txt", ".md"), width = "100%")
          ),
          column(6,
            selectInput(ns("loadSession"),
              "Resume an existing run:",
              choices = c("— new run —" = ""), width = "100%"
            )
          )
        ),

        hr(),
        actionButton(ns("planBtn"), "Plan Task (Agent 1 estimates scope)",
                     class = "btn-info",  icon = icon("map"), width = "100%"),
        br(), br(),
        actionButton(ns("runBtn"),  "Run — Build Notebook",
                     class = "btn-success", icon = icon("play"), width = "100%",
                     disabled = "disabled")
      )
    ),

    column(4,
      box(
        title = "Task Plan", status = "primary",
        solidHeader = TRUE, width = 12,
        div(style = "min-height: 260px;",
          uiOutput(ns("planOutput"))
        )
      ),

      box(
        title = "Run Info", status = "info",
        solidHeader = TRUE, width = 12,
        uiOutput(ns("runInfo"))
      )
    )
  )
}
