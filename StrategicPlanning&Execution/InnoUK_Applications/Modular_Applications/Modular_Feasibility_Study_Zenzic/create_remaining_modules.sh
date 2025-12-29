#!/bin/bash
# Create ALL remaining modules with COMPLETE functionality

BASE="/mnt/user-data/outputs/Complete_Full_App/modules"

# ========================================
# BUSINESS_CASE MODULE - COMPLETE
# ========================================

cat > "$BASE/business_case/ui.R" << 'EOF'
business_case_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Word Limits Configuration - Business Case",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        p("Set the word limit for each business case section."),
        column(3, numericInput(ns("limitbc1"), "Problem & Market:", value = 500, min = 50, max = 2000, step = 50)),
        column(3, numericInput(ns("limitbc2"), "CAM Service:", value = 500, min = 50, max = 2000, step = 50)),
        column(3, numericInput(ns("limitbc3"), "Readiness:", value = 500, min = 50, max = 2000, step = 50)),
        column(3, numericInput(ns("limitbc4"), "Feasibility:", value = 500, min = 50, max = 2000, step = 50))
      )
    ),
    fluidRow(
      box(
        title = "Additional Word Limit",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        column(4, numericInput(ns("limitbc5"), "Commercialisation:", value = 400, min = 50, max = 2000, step = 50))
      )
    ),
    fluidRow(
      box(
        title = "9. Problem, Opportunity and Market Potential",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Problem, Opportunity and Market Potential"),
        div(class = "question-help",
            "What mobility challenge or gap are you addressing, and what is the size and timing of the opportunity which this business case can unlock?"
        ),
        div(class = "main-ideas-input",
            textAreaInput(ns("ideasbc1"), "Main Ideas / Key Points:", 
                          placeholder = "Enter the key points about the problem, opportunity, and market potential...",
                          height = "120px", width = "100%")
        ),
        div(class = "generate-container",
            actionButton(ns("genbc1"), "Generate with ChatGPT (with context)", 
                         class = "generate-btn", icon = icon("wand-magic-sparkles"))
        ),
        textAreaInput(ns("problem"), "Generated Response:", 
                      placeholder = "Your AI-generated response will appear here...",
                      height = "250px", width = "100%"),
        div(class = "word-counter", textOutput(ns("countbc1")))
      )
    ),
    fluidRow(
      box(
        title = "10. Proposed CAM Service, Value Proposition and Location Context",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Proposed CAM Service"),
        div(class = "question-help",
            "What CAM service or solution are you proposing, and why is this the right service in the right location?"
        ),
        textAreaInput(ns("ideasbc2"), "Main Ideas:", height = "120px", width = "100%"),
        actionButton(ns("genbc2"), "Generate with Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
        textAreaInput(ns("cam"), "Generated Response:", height = "250px", width = "100%"),
        div(class = "word-counter", textOutput(ns("countbc2")))
      )
    ),
    fluidRow(
      box(
        title = "11. Readiness, Stakeholders and Regulatory Compliance",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Readiness, Stakeholders and Regulatory Compliance"),
        div(class = "question-help",
            "How ready is your current business case? Identify areas where you have complete knowledge and what gaps your feasibility study will address."
        ),
        textAreaInput(ns("ideasbc3"), "Main Ideas:", height = "120px", width = "100%"),
        actionButton(ns("genbc3"), "Generate with Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
        textAreaInput(ns("readiness"), "Generated Response:", height = "250px", width = "100%"),
        div(class = "word-counter", textOutput(ns("countbc3")))
      )
    ),
    fluidRow(
      box(
        title = "12. Feasibility Study Plan, Business Case Development and Gateway",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Feasibility Study Plan"),
        div(class = "question-help", "What will your feasibility study deliver, and how will you know if it is successful?"),
        textAreaInput(ns("ideasbc4"), "Main Ideas:", height = "120px", width = "100%"),
        actionButton(ns("genbc4"), "Generate with Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
        textAreaInput(ns("feasibility"), "Generated Response:", height = "250px", width = "100%"),
        div(class = "word-counter", textOutput(ns("countbc4")))
      )
    ),
    fluidRow(
      box(
        title = "13. Commercialisation Roadmap and Key Performance Indicators (KPIs)",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Commercialisation Roadmap and KPIs"),
        div(class = "question-help", "What happens after the feasibility study, and how will you measure progress?"),
        textAreaInput(ns("ideasbc5"), "Main Ideas:", height = "120px", width = "100%"),
        actionButton(ns("genbc5"), "Generate with Context", class = "generate-btn", icon = icon("wand-magic-sparkles")),
        textAreaInput(ns("commercialisation"), "Generated Response:", height = "250px", width = "100%"),
        div(class = "word-counter", textOutput(ns("countbc5")))
      )
    ),
    fluidRow(
      box(
        title = "Save Business Case to Excel",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        p("This will save the business case data to the same Excel file configured in the Project Details tab."),
        p(tags$strong("Note: "), "Make sure you have configured the file path in the Project Details tab first."),
        br(),
        actionButton(ns("save"), "Save Business Case to Excel", class = "save-btn", icon = icon("file-excel")),
        br(), br(),
        uiOutput(ns("save_status"))
      )
    )
  )
}
EOF

echo "✓ business_case/ui.R created"

# Due to length, I'll create the server in multiple parts...

