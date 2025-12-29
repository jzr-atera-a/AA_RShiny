claude_diagrams_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Context Management",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        p("Claude cannot access OpenAI content directly. Save your application context to CSV and load it here."),
        fluidRow(
          column(6,
                 actionButton(ns("save_context"), "Save Application Context to CSV", 
                             class = "btn-warning", icon = icon("download"),
                             style = "width: 100%; margin-bottom: 10px;"),
                 downloadButton(ns("download_context"), "Download Context CSV", 
                               class = "btn-info", style = "width: 100%;")
          ),
          column(6,
                 fileInput(ns("upload_context"), "Upload Context CSV:", accept = c(".csv")),
                 verbatimTextOutput(ns("context_info"))
          )
        )
      )
    ),
    fluidRow(
      box(
        title = "Upload Reference File for Claude",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        p("Upload a reference file. Claude supports images (JPG, PNG, GIF, WebP) and PDFs natively."),
        fileInput(ns("ref_file"), "Select File:",
                  accept = c(".jpg", ".jpeg", ".png", ".gif", ".webp", ".pdf", ".txt", ".csv")),
        verbatimTextOutput(ns("file_info")),
        p(tags$strong("Note:"), " Claude has native vision capabilities for images.")
      )
    ),
    fluidRow(
      box(
        title = "Diagram Instructions for Claude",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p("Describe the diagram you want Claude to generate."),
        textAreaInput(ns("instructions"), "Instructions:",
                      placeholder = "Example: Analyze the data and create a comprehensive flowchart...",
                      height = "200px", width = "100%"),
        br(),
        selectInput(ns("type"), "Type of Diagram:",
                    choices = c("Flowchart" = "flowchart", "Timeline" = "timeline",
                               "Org Chart" = "org_chart", "Mind Map" = "mindmap",
                               "Architecture" = "architecture", "Data Viz" = "data_viz", "Custom" = "custom"),
                    selected = "flowchart"),
        checkboxInput(ns("use_context"), "Include loaded context from CSV", value = TRUE)
      )
    ),
    fluidRow(
      box(
        title = "Output Format for Claude",
        status = "warning",
        solidHeader = TRUE,
        width = 12,
        selectInput(ns("format"), "Select Output Format:",
                    choices = c("SVG" = "svg", "HTML" = "html", "Mermaid Code" = "mermaid",
                               "D3.js" = "d3js", "PNG" = "png", "PDF" = "pdf"),
                    selected = "svg"),
        p(tags$small("Claude can generate sophisticated and complex diagrams.")),
        hr(),
        actionButton(ns("generate"), "Generate Diagram with Claude", 
                     class = "generate-btn", icon = icon("wand-magic-sparkles"),
                     style = "font-size: 16px; padding: 12px 30px;")
      )
    ),
    fluidRow(
      box(
        title = "Claude Generated Diagram",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        uiOutput(ns("preview")),
        hr(),
        h4("Download Options:"),
        fluidRow(
          column(4, downloadButton(ns("download_main"), "Download", class = "btn-success")),
          column(4, downloadButton(ns("download_svg"), "Download SVG", class = "btn-info")),
          column(4, downloadButton(ns("download_png"), "Download PNG", class = "btn-info"))
        ),
        br(),
        h4("Generated Code:"),
        verbatimTextOutput(ns("code_display")),
        br(),
        h4("Claude's Analysis:"),
        verbatimTextOutput(ns("analysis")),
        br(),
        uiOutput(ns("status"))
      )
    )
  )
}