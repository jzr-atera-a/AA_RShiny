image_generation_ui <- function(id) {
  ns <- NS(id)
  
  fluidRow(
    # Left Panel - Controls
    column(
      width = 4,
      box(
        title = "Image Generation Controls",
        status = "primary",
        solidHeader = TRUE,
        width = NULL,
        
        textAreaInput(
          ns("description"),
          "Image Description:",
          placeholder = "Describe the image you want to generate...",
          rows = 12,
          width = "100%"
        ),
        
        actionButton(
          ns("transferBtn"),
          "Transfer to Further Context Tab",
          class = "btn-info",
          style = "width: 100%; margin-bottom: 15px;",
          icon = icon("arrow-right")
        ),
        
        selectInput(
          ns("style"),
          "Image Style:",
          choices = c(
            "Art-like (Digital Art)" = "art",
            "Photograph-like (Realistic)" = "photo"
          ),
          selected = "art"
        ),
        
        selectInput(
          ns("aspectRatio"),
          "Aspect Ratio:",
          choices = c(
            "1:1 (Square)" = "1:1",
            "4:3 (Standard)" = "4:3",
            "3:4 (Portrait)" = "3:4",
            "16:9 (Widescreen)" = "16:9",
            "9:16 (Tall Portrait)" = "9:16"
          ),
          selected = "1:1"
        ),
        
        h4("Dimensions", style = "margin-top: 20px; color: #667eea;"),
        
        fluidRow(
          column(
            width = 6,
            numericInput(
              ns("height"),
              "Height:",
              value = 10,
              min = 1,
              max = 200,
              step = 0.5
            )
          ),
          column(
            width = 6,
            selectInput(
              ns("unit"),
              "Unit:",
              choices = c("cm", "inches"),
              selected = "cm"
            )
          )
        ),
        
        div(
          class = "dimension-display",
          textOutput(ns("calculatedWidth"))
        ),
        
        br(),
        actionButton(
          ns("generateBtn"),
          "Generate Image",
          class = "btn-success",
          style = "width: 100%; font-size: 16px; padding: 12px;",
          icon = icon("magic")
        ),
        
        br(), br(),
        
        conditionalPanel(
          condition = "output.imageGenerated",
          ns = ns,
          
          h4("Download Options", style = "color: #667eea;"),
          
          selectInput(
            ns("downloadFormat"),
            "Download Format:",
            choices = c(
              "JPG (High Quality)" = "jpg",
              "PNG (Lossless)" = "png",
              "TIFF (Professional)" = "tiff",
              "GIF (Compatible)" = "gif",
              "PDF (Document)" = "pdf",
              "SVG (Scalable)" = "svg"
            ),
            selected = "jpg"
          ),
          
          textInput(
            ns("filename"),
            "Filename (without extension):",
            value = paste0("dalle_image_", format(Sys.time(), "%Y%m%d_%H%M%S"))
          ),
          
          shinyFiles::shinyDirButton(
            ns("downloadDir"),
            "Choose Download Folder",
            "Select folder to save image",
            class = "btn-info",
            style = "width: 100%; margin-bottom: 10px;"
          ),
          
          verbatimTextOutput(ns("selectedPath")),
          
          br(),
          actionButton(
            ns("downloadBtn"),
            "Download Image",
            class = "btn-primary",
            style = "width: 100%;",
            icon = icon("download")
          )
        )
      )
    ),
    
    # Right Panel - Image Display
    column(
      width = 8,
      box(
        title = "Generated Image",
        status = "primary",
        solidHeader = TRUE,
        width = NULL,
        
        div(
          class = "image-preview-box",
          uiOutput(ns("imageDisplay"))
        ),
        
        br(),
        
        conditionalPanel(
          condition = "output.imageGenerated",
          ns = ns,
          
          div(
            class = "prompt-box",
            h5(style = "margin-top: 0;", "📝 Revised Prompt:"),
            textOutput(ns("revisedPrompt"))
          )
        )
      ),
      
      box(
        title = "Generation Log",
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
