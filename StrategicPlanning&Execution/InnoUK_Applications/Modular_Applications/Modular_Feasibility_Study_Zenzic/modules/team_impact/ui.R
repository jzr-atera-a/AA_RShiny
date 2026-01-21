team_impact_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Word Limits Configuration - Team & Impact",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        p("Set the word limit for each Team & Impact section."),
        column(3, numericInput(ns("limitti1"), "Team & Capability:", value = 400, min = 50, max = 2000, step = 50)),
        column(3, numericInput(ns("limitti2"), "Finance & Risks:", value = 400, min = 50, max = 2000, step = 50)),
        column(3, numericInput(ns("limitti3"), "Impact:", value = 500, min = 50, max = 2000, step = 50)),
        column(3, numericInput(ns("limitti4"), "Costs & Value:", value = 400, min = 50, max = 2000, step = 50))
      )
    ),
    fluidRow(
      box(
        title = "14. Team and Capability",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Team and Capability"),
        div(class = "question-help",
            "Who is in your team and how will you fill any gaps? Describe senior buy-in, team skills, capability gaps, and resource capacity."
        ),
        textAreaInput(ns("ideasti1"), "Main Ideas:", height = "120px", width = "100%"),
        actionButton(ns("genti1"), "Generate with Full Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
        textAreaInput(ns("team"), "Generated Response:", height = "250px", width = "100%"),
        div(class = "word-counter", textOutput(ns("countti1")))
      )
    ),
    fluidRow(
      box(
        title = "15. Finance and Risk Management",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Finance and Risk Management"),
        div(class = "question-help",
            "How will you manage finances and risks? Explain financial resilience, key risks, and mitigation strategies."
        ),
        textAreaInput(ns("ideasti2"), "Main Ideas:", height = "120px", width = "100%"),
        actionButton(ns("genti2"), "Generate with Full Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
        textAreaInput(ns("finance"), "Generated Response:", height = "250px", width = "100%"),
        div(class = "word-counter", textOutput(ns("countti2")))
      )
    ),
    fluidRow(
      box(
        title = "16. Impact on UK Economy and Society",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Impact on UK Economy and Society"),
        div(class = "question-help",
            "What impact will your proposal have? Quantify UK jobs, innovation centers, CO₂ reduction, and capability building."
        ),
        textAreaInput(ns("ideasti3"), "Main Ideas:", height = "120px", width = "100%"),
        actionButton(ns("genti3"), "Generate with Full Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
        textAreaInput(ns("impact"), "Generated Response:", height = "250px", width = "100%"),
        div(class = "word-counter", textOutput(ns("countti3")))
      )
    ),
    fluidRow(
      box(
        title = "17. Costs and Value for Money",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Costs and Value for Money"),
        div(class = "question-help",
            "How do your costs represent value for money? Justify costs and explain funding necessity."
        ),
        textAreaInput(ns("ideasti4"), "Main Ideas:", height = "120px", width = "100%"),
        actionButton(ns("genti4"), "Generate with Full Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
        textAreaInput(ns("costs"), "Generated Response:", height = "250px", width = "100%"),
        div(class = "word-counter", textOutput(ns("countti4")))
      )
    ),
    fluidRow(
      box(
        title = "Save Team & Impact to Excel",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        p("This will save the Team & Impact data to the same Excel file."),
        actionButton(ns("save"), "Save Team & Impact to Excel", class = "save-btn", icon = icon("file-excel")),
        br(), br(),
        uiOutput(ns("save_status"))
      )
    )
  )
}