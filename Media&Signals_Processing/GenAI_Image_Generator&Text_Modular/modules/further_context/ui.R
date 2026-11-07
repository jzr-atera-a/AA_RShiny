further_context_ui <- function(id) {
  ns <- NS(id)
  
  fluidRow(
    column(
      width = 8,
      box(
        title = "Text Enrichment with ChatGPT",
        status = "primary",
        solidHeader = TRUE,
        width = NULL,
        
        textAreaInput(
          ns("contextText"),
          "Edit and Enrich Your Context:",
          placeholder = "Transfer text from Image Generation tab or write your own content here...",
          rows = 18,
          width = "100%"
        ),
        
        fluidRow(
          column(
            width = 6,
            selectInput(
              ns("wordCount"),
              "Target Word Count:",
              choices = c(
                "10 words" = "10",
                "20 words" = "20",
                "30 words" = "30",
                "50 words" = "50",
                "80 words" = "80",
                "130 words" = "130",
                "210 words" = "210",
                "340 words" = "340"
              ),
              selected = "80"
            )
          ),
          column(
            width = 6,
            selectInput(
              ns("textStyle"),
              "Writing Style:",
              choices = c(
                "Pitch Deck" = "pitch deck",
                "Informative" = "informative",
                "Academic Report" = "academic report",
                "Technical Report" = "technical report",
                "Email Like" = "email like"
              ),
              selected = "pitch deck"
            )
          )
        ),
        
        br(),
        actionButton(
          ns("enrichBtn"),
          "Enrich with ChatGPT",
          class = "btn-success",
          style = "width: 100%; font-size: 16px; padding: 12px;",
          icon = icon("magic")
        ),
        
        br(), br(),
        
        div(
          class = "info-box",
          h5(style = "margin-top: 0;", "ℹ️ How it works:"),
          p("Your text will be sent to ChatGPT with instructions to rewrite it in the selected style and word count. The enriched version will appear in the output box below.")
        )
      )
    ),
    
    column(
      width = 4,
      box(
        title = "Enriched Output",
        status = "success",
        solidHeader = TRUE,
        width = NULL,
        
        verbatimTextOutput(ns("enrichedText")),
        
        br(),
        
        conditionalPanel(
          condition = "output.hasEnrichedText",
          ns = ns,
          
          actionButton(
            ns("copyBtn"),
            "Copy to Clipboard",
            class = "btn-info",
            style = "width: 100%;",
            icon = icon("copy")
          ),
          
          br(), br(),
          
          actionButton(
            ns("replaceBtn"),
            "Replace Input with This",
            class = "btn-warning",
            style = "width: 100%;",
            icon = icon("exchange-alt")
          )
        )
      ),
      
      box(
        title = "Processing Log",
        status = "info",
        solidHeader = TRUE,
        width = NULL,
        collapsible = TRUE,
        collapsed = TRUE,
        
        verbatimTextOutput(ns("log"))
      )
    )
  )
}
