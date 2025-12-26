# Generate DE Roadmap Module - UI

generate_de_roadmap_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Generate Disciplined Entrepreneurship Roadmap with Claude", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        h4("AI-Powered Disciplined Entrepreneurship Roadmap Generation"),
        p("Generate all 24 steps of the Disciplined Entrepreneurship Roadmap."),
        
        fluidRow(
          column(3, textInput(ns("roadmap_business_area"), "Business Area:", placeholder = "e.g., Technology")),
          column(3, textInput(ns("roadmap_project"), "Project:", placeholder = "e.g., Mobile App")),
          column(3, textInput(ns("roadmap_business_focus"), "Business Focus:", placeholder = "e.g., B2B SaaS")),
          column(3, br(), actionButton(ns("generate_roadmap"), "Generate with Claude", class = "btn btn-warning btn-lg", icon = icon("magic"), width = "100%"))
        ),
        
        fluidRow(
          column(12, textAreaInput(ns("roadmap_business_description"), "Business Idea Description:", height = "150px", width = "100%"))
        ),
        
        br(),
        htmlOutput(ns("roadmap_generate_status")),
        hr(),
        h5("Claude Generated Content:"),
        textAreaInput(ns("roadmap_claude_output"), "Generated Roadmap:", height = "300px", width = "100%"),
        hr(),
        
        div(class = "alert alert-info",
            tags$strong("All 24 steps required")),
        
        textAreaInput(ns("roadmap_bulk_text"), "Paste or Edit Roadmap Content:", height = "300px", width = "100%"),
        
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
        htmlOutput(ns("roadmapParseInfo")),
        br(),
        div(class = "preview-section", verbatimTextOutput(ns("roadmapParsedPreview")))
      )
    )
  )
}
