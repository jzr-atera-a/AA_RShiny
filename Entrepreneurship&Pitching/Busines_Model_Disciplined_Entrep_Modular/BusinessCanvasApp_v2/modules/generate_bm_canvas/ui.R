# Generate Business Model Canvas Module - UI

generate_bm_canvas_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Generate Business Model Canvas with Claude", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        h4("AI-Powered Business Model Canvas Generation"),
        p("Provide your business details and let Claude generate a comprehensive Business Model Canvas based on Alexander Osterwalder's framework."),
        
        fluidRow(
          column(3,
                 textInput(ns("business_area"), 
                           "Business Area (max 32 chars):", 
                           placeholder = "e.g., Technology, Healthcare",
                           width = "100%")
          ),
          column(3,
                 textInput(ns("project"), 
                           "Project (max 32 chars):", 
                           placeholder = "e.g., Mobile App Development",
                           width = "100%")
          ),
          column(3,
                 textInput(ns("business_focus"), 
                           "Business Focus (max 32 chars):", 
                           placeholder = "e.g., B2B SaaS",
                           width = "100%")
          ),
          column(3,
                 br(),
                 actionButton(ns("generate_bm_canvas"), 
                              "Generate with Claude", 
                              class = "btn btn-warning btn-lg",
                              icon = icon("magic"),
                              width = "100%")
          )
        ),
        
        fluidRow(
          column(12,
                 textAreaInput(ns("business_description"), 
                               "Business Idea Description:",
                               height = "150px",
                               width = "100%",
                               placeholder = "Describe your business idea in detail. Include information about your target customers, the problem you're solving, your solution, competitive advantages, revenue model, and any other relevant details...")
          )
        ),
        
        br(),
        htmlOutput(ns("generate_status")),
        
        hr(),
        h5("Claude Generated Content:"),
        textAreaInput(ns("claude_output"), 
                      "Generated Business Model Canvas:",
                      height = "300px",
                      width = "100%",
                      placeholder = "Claude's generated content will appear here..."),
        
        hr(),
        
        div(class = "alert alert-info",
            tags$strong("Format Requirements:"),
            tags$ul(
              tags$li("Review the generated content above"),
              tags$li("You can edit it or paste your own content below"),
              tags$li("Content must follow the format: [Key Partners], [Key Activities], etc.")
            )
        ),
        
        textAreaInput(ns("bulk_text"), 
                      "Paste or Edit Business Model Canvas Content:",
                      height = "300px",
                      width = "100%",
                      placeholder = "[Key Partners]\nYour key partners content here...\n\n[Key Activities]\nYour key activities content here..."),
        
        fluidRow(
          column(4,
                 actionButton(ns("parseCanvas"), 
                              "Parse Canvas Data", 
                              class = "btn btn-info btn-lg",
                              icon = icon("cogs"),
                              width = "100%")
          ),
          column(4,
                 actionButton(ns("submitCanvas"), 
                              "Submit to BigQuery", 
                              class = "btn btn-success btn-lg",
                              icon = icon("cloud-upload-alt"),
                              width = "100%")
          ),
          column(4,
                 actionButton(ns("clearCanvas"), 
                              "Clear All", 
                              class = "btn btn-danger",
                              icon = icon("trash"),
                              width = "100%")
          )
        ),
        
        br(),
        htmlOutput(ns("bulkStatus"))
      )
    ),
    
    fluidRow(
      box(
        title = "Parsed Canvas Preview", 
        status = "info", 
        solidHeader = TRUE, 
        width = 12,
        
        htmlOutput(ns("parseInfo")),
        br(),
        
        div(class = "preview-section",
            verbatimTextOutput(ns("parsedPreview")))
      )
    )
  )
}
