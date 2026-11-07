dalle_settings_ui <- function(id) {
  ns <- NS(id)
  
  fluidRow(
    column(
      width = 8,
      box(
        title = "OpenAI API Configuration (Image & Text Processing)",
        status = "primary",
        solidHeader = TRUE,
        width = NULL,
        
        passwordInput(
          ns("apiKey"), 
          "OpenAI API Key:", 
          placeholder = "sk-..."
        ),
        
        selectInput(
          ns("model"), 
          "DALL-E Model:", 
          choices = c(
            "DALL-E 3 (Latest, Best Quality)" = "dall-e-3",
            "DALL-E 2 (Faster, Lower Cost)" = "dall-e-2"
          ),
          selected = "dall-e-3"
        ),
        
        conditionalPanel(
          condition = "input.model == 'dall-e-3'",
          ns = ns,
          
          selectInput(
            ns("quality"),
            "Image Quality:",
            choices = c(
              "Standard" = "standard",
              "HD (Higher Quality)" = "hd"
            ),
            selected = "standard"
          ),
          
          selectInput(
            ns("style"),
            "Image Style:",
            choices = c(
              "Vivid (Hyper-real and dramatic)" = "vivid",
              "Natural (More natural, less hyper-real)" = "natural"
            ),
            selected = "vivid"
          )
        ),
        
        br(),
        actionButton(
          ns("saveBtn"), 
          "Save Settings", 
          class = "btn-primary", 
          style = "width: 100%;"
        ),
        br(), br(),
        actionButton(
          ns("testBtn"), 
          "Test Connection", 
          class = "btn-info"
        ),
        br(), br(),
        verbatimTextOutput(ns("status"))
      )
    ),
    
    column(
      width = 4,
      box(
        title = "Information",
        status = "info",
        solidHeader = TRUE,
        width = NULL,
        
        div(
          class = "info-box",
          h4(style = "margin-top: 0; color: #667eea;", "📝 Setup Instructions"),
          tags$ol(
            tags$li("Get your API key from ", tags$a(href = "https://platform.openai.com/api-keys", target = "_blank", "OpenAI Platform")),
            tags$li("Paste your API key above"),
            tags$li("Select your preferred model"),
            tags$li("Configure quality and style (DALL-E 3 only)"),
            tags$li("Click 'Save Settings'"),
            tags$li("Test the connection")
          )
        ),
        
        div(
          class = "reference-box",
          h4(style = "margin-top: 0; color: #4f46e5;", "🎨 Model Comparison"),
          tags$strong("DALL-E 3:"),
          tags$ul(
            tags$li("Latest model with best quality"),
            tags$li("Supports 1024x1024, 1024x1792, 1792x1024"),
            tags$li("HD quality option available"),
            tags$li("Better prompt understanding")
          ),
          tags$strong("DALL-E 2:"),
          tags$ul(
            tags$li("Faster generation"),
            tags$li("Lower cost"),
            tags$li("Supports 256x256, 512x512, 1024x1024"),
            tags$li("Good for quick iterations")
          )
        )
      )
    )
  )
}
