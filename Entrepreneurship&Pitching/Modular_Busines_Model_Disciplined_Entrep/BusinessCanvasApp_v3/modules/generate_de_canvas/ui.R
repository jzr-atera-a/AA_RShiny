# Generate DE Canvas Module - UI

generate_de_canvas_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Generate Disciplined Entrepreneurship Canvas with Claude", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        h4("AI-Powered Disciplined Entrepreneurship Canvas Generation"),
        p("Provide your business details and let Claude generate a comprehensive Disciplined Entrepreneurship Canvas."),
        
        fluidRow(
          column(3,
                 textInput(ns("de_business_area"), 
                           "Business Area (max 32 chars):", 
                           placeholder = "e.g., Technology, Healthcare",
                           width = "100%")
          ),
          column(3,
                 textInput(ns("de_project"), 
                           "Project (max 32 chars):", 
                           placeholder = "e.g., Mobile App Development",
                           width = "100%")
          ),
          column(3,
                 textInput(ns("de_business_focus"), 
                           "Business Focus (max 32 chars):", 
                           placeholder = "e.g., B2B SaaS",
                           width = "100%")
          ),
          column(3,
                 br(),
                 actionButton(ns("generate_de_canvas"), 
                              "Generate with Claude", 
                              class = "btn btn-warning btn-lg",
                              icon = icon("magic"),
                              width = "100%")
          )
        ),
        
        fluidRow(
          column(12,
                 textAreaInput(ns("de_business_description"), 
                               "Business Idea Description:",
                               height = "150px",
                               width = "100%",
                               placeholder = "Describe your business idea in detail for the Disciplined Entrepreneurship Canvas...")
          )
        ),
        
        br(),
        htmlOutput(ns("de_generate_status")),
        
        hr(),
        h5("Claude Generated Content:"),
        textAreaInput(ns("de_claude_output"), 
                      "Generated DE Canvas:",
                      height = "300px",
                      width = "100%",
                      placeholder = "Claude's generated content will appear here..."),
        
        hr(),
        
        div(class = "alert alert-info",
            tags$strong("Format Requirements:"),
            tags$ul(
              tags$li("Review the generated content above"),
              tags$li("You can edit it or paste your own content below"),
              tags$li("Required sections: [Raison d'Être], [Initial Market], etc.")
            )
        ),
        
        textAreaInput(ns("de_bulk_text"), 
                      "Paste or Edit DE Canvas Content:",
                      height = "300px",
                      width = "100%",
                      placeholder = "[Raison d'Être]\nMission: ...\nPassion: ...\nValues: ...\n\n[Initial Market]\nBeachhead: ...\nEnd User Profile: ..."),
        
        fluidRow(
          column(4,
                 actionButton(ns("parseDECanvas"), 
                              "Parse Canvas Data", 
                              class = "btn btn-info btn-lg",
                              icon = icon("cogs"),
                              width = "100%")
          ),
          column(4,
                 actionButton(ns("submitDECanvas"), 
                              "Submit to BigQuery", 
                              class = "btn btn-success btn-lg",
                              icon = icon("cloud-upload-alt"),
                              width = "100%")
          ),
          column(4,
                 actionButton(ns("clearDECanvas"), 
                              "Clear All", 
                              class = "btn btn-danger",
                              icon = icon("trash"),
                              width = "100%")
          )
        ),
        
        br(),
        htmlOutput(ns("deBulkStatus"))
      )
    ),
    
    fluidRow(
      box(
        title = "Parsed DE Canvas Preview", 
        status = "info", 
        solidHeader = TRUE, 
        width = 12,
        
        htmlOutput(ns("deParseInfo")),
        br(),
        
        div(class = "preview-section",
            verbatimTextOutput(ns("deParsedPreview")))
      )
    )
  )
}
