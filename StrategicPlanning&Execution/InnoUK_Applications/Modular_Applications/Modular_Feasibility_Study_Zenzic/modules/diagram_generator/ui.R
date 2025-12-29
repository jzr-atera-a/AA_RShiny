diagram_generator_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Upload Reference File",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        p("Upload a reference file (optional) that ChatGPT will analyze to generate your diagram."),
        fileInput(ns("ref_file"), "Select File:",
                  accept = c(".jpg", ".jpeg", ".png", ".svg", ".pdf", ".docx", ".xlsx", ".csv")),
        verbatimTextOutput(ns("file_info")),
        hr(),
        checkboxInput(ns("include_context"), "Include full application context from all tabs", value = FALSE)
      )
    ),
    fluidRow(
      box(
        title = "Diagram Instructions",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p("Describe the diagram you want ChatGPT to generate."),
        textAreaInput(ns("instructions"), "Instructions:",
                      placeholder = "Example: Create a flowchart showing the 5 phases of our project implementation...",
                      height = "200px", width = "100%"),
        br(),
        selectInput(ns("type"), "Type of Diagram:",
                    choices = c("Flowchart" = "flowchart", "Timeline" = "timeline", 
                               "Org Chart" = "org_chart", "Mind Map" = "mindmap",
                               "Sequence" = "sequence", "Network" = "network",
                               "Pie Chart" = "pie", "Bar Chart" = "bar", "Custom" = "custom"),
                    selected = "flowchart")
      )
    ),
    fluidRow(
      box(
        title = "Output Format",
        status = "warning",
        solidHeader = TRUE,
        width = 12,
        selectInput(ns("format"), "Select Output Format:",
                    choices = c("SVG" = "svg", "HTML" = "html", "Mermaid Code" = "mermaid",
                               "PNG" = "png", "PDF" = "pdf"),
                    selected = "svg"),
        p(tags$small("Note: PNG and PDF require conversion from SVG.")),
        hr(),
        actionButton(ns("generate"), "Generate Diagram with ChatGPT", 
                     class = "generate-btn", icon = icon("wand-magic-sparkles"),
                     style = "font-size: 16px; padding: 12px 30px;")
      )
    ),
    fluidRow(
      box(
        title = "Generated Diagram",
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
        uiOutput(ns("status"))
      )
    )
  )
}