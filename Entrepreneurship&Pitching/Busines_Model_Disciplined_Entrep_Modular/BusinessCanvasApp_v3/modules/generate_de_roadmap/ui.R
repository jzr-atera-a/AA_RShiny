generate_de_roadmap_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Generate Disciplined Entrepreneurship Roadmap with Claude", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        h4("AI-Powered 24-Step Roadmap Generation"),
        p("Provide your business details and let Claude generate all 24 steps of the Disciplined Entrepreneurship Roadmap."),
        
        fluidRow(
          column(3, textInput(ns("roadmap_business_area"), "Business Area (max 32 chars):", placeholder = "e.g., Technology")),
          column(3, textInput(ns("roadmap_project"), "Project (max 32 chars):", placeholder = "e.g., Mobile App")),
          column(3, textInput(ns("roadmap_business_focus"), "Business Focus (max 32 chars):", placeholder = "e.g., B2B SaaS")),
          column(3, 
                 sliderInput(ns("words_per_step"), 
                             "Words per Step:", 
                             min = 10, max = 100, value = 30, step = 5,
                             post = " words")
          )
        ),
        
        fluidRow(
          column(9, textAreaInput(ns("roadmap_business_description"), "Business Idea Description:", height = "100px", placeholder = "Describe your business idea...")),
          column(3, br(), actionButton(ns("generate_roadmap"), "Generate with Claude", class = "btn btn-warning btn-lg", icon = icon("magic"), width = "100%"))
        ),
        
        br(),
        htmlOutput(ns("roadmap_generate_status")),
        
        hr(),
        div(class = "alert alert-info",
            tags$strong("IMPORTANT:"), 
            tags$ul(
              tags$li("Lower word counts ensure ALL 24 steps are generated"),
              tags$li("Recommended: 20-40 words per step for complete generation"),
              tags$li("Higher counts may cause Claude to stop before completing all steps")
            )
        ),
        
        h5("Claude Generated Content:"),
        textAreaInput(ns("roadmap_claude_output"), "Generated Roadmap:", height = "300px", placeholder = "Claude's output will appear here..."),
        
        hr(),
        textAreaInput(ns("roadmap_bulk_text"), "Review and Edit Roadmap Content:", height = "300px", placeholder = "Review generated content or paste your own..."),
        
        fluidRow(
          column(4, actionButton(ns("parseRoadmap"), "Parse Roadmap Data", class = "btn btn-info btn-lg", icon = icon("cogs"), width = "100%")),
          column(4, actionButton(ns("submitRoadmap"), "Submit to BigQuery", class = "btn btn-success btn-lg", icon = icon("cloud-upload-alt"), width = "100%")),
          column(4, actionButton(ns("clearRoadmap"), "Clear All", class = "btn btn-danger", icon = icon("trash"), width = "100%"))
        ),
        
        br(),
        htmlOutput(ns("roadmapBulkStatus"))
      )
    ),
    
    fluidRow(
      box(
        title = "Parsed Roadmap Preview", 
        status = "info", 
        solidHeader = TRUE, 
        width = 12,
        htmlOutput(ns("roadmapParseInfo"))
      )
    )
  )
}