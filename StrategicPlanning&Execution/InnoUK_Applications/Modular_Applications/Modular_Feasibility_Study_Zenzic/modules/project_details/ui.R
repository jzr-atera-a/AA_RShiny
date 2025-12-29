project_details_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Word Limits Configuration",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        p("Set the word limit for each section. The AI will generate content according to these limits."),
        column(4, 
               numericInput(ns("limit1"), 
                            "Project Summary Word Limit:", 
                            value = 400, 
                            min = 50, 
                            max = 2000,
                            step = 50)),
        column(4, 
               numericInput(ns("limit2"), 
                            "Public Description Word Limit:", 
                            value = 400, 
                            min = 50, 
                            max = 2000,
                            step = 50)),
        column(4, 
               numericInput(ns("limit3"), 
                            "Scope Word Limit:", 
                            value = 400, 
                            min = 50, 
                            max = 2000,
                            step = 50))
      )
    ),
    
    fluidRow(
      box(
        title = "1. Project Summary",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Project Summary"),
        div(class = "question-help",
            "What should I include in the project summary? Describe your project briefly and be clear about what makes it innovative. We use this section to assign the right experts to assess your application."
        ),
        div(class = "main-ideas-input",
            textAreaInput(ns("ideas1"), 
                          "Main Ideas / Key Points for Project Summary:", 
                          placeholder = "Enter the key points, main concepts, and innovative aspects you want to include in your project summary...",
                          height = "120px", 
                          width = "100%")
        ),
        div(class = "generate-container",
            actionButton(ns("gen1"), 
                         "Generate with ChatGPT", 
                         class = "generate-btn",
                         icon = icon("wand-magic-sparkles"))
        ),
        textAreaInput(ns("summary"), 
                      "Generated Project Summary:", 
                      placeholder = "Your AI-generated project summary will appear here after clicking the Generate button...",
                      height = "250px", 
                      width = "100%"),
        div(class = "word-counter", 
            textOutput(ns("count1")))
      )
    ),
    
    fluidRow(
      box(
        title = "2. Public Description",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Public Description"),
        div(class = "question-help",
            "What should I include in the project public description? Describe your project in detail and in a way that you are happy to see published. Do not include any commercially sensitive information. If we award your project funding, we will publish this description. This can happen before you start your project."
        ),
        div(class = "main-ideas-input",
            textAreaInput(ns("ideas2"), 
                          "Main Ideas / Key Points for Public Description:", 
                          placeholder = "Enter the detailed information you want to include in your public description. Remember: this will be published publicly...",
                          height = "120px", 
                          width = "100%")
        ),
        div(class = "generate-container",
            actionButton(ns("gen2"), 
                         "Generate with ChatGPT", 
                         class = "generate-btn",
                         icon = icon("wand-magic-sparkles"))
        ),
        textAreaInput(ns("description"), 
                      "Generated Public Description:", 
                      placeholder = "Your AI-generated public description will appear here after clicking the Generate button...",
                      height = "250px", 
                      width = "100%"),
        div(class = "word-counter", 
            textOutput(ns("count2")))
      )
    ),
    
    fluidRow(
      box(
        title = "3. Scope",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        div(class = "question-label", "Scope"),
        div(class = "question-help",
            "What should I include in the project scope? Describe how your project fits the scope of the competition. If your project is not in scope, it will not be sent for assessment. We will tell you the reason why."
        ),
        div(class = "main-ideas-input",
            textAreaInput(ns("ideas3"), 
                          "Main Ideas / Key Points for Scope:", 
                          placeholder = "Enter how your project aligns with the competition scope, eligibility criteria, and requirements...",
                          height = "120px", 
                          width = "100%")
        ),
        div(class = "generate-container",
            actionButton(ns("gen3"), 
                         "Generate with ChatGPT", 
                         class = "generate-btn",
                         icon = icon("wand-magic-sparkles"))
        ),
        textAreaInput(ns("scope"), 
                      "Generated Scope Description:", 
                      placeholder = "Your AI-generated scope description will appear here after clicking the Generate button...",
                      height = "250px", 
                      width = "100%"),
        div(class = "word-counter", 
            textOutput(ns("count3")))
      )
    ),
    
    fluidRow(
      box(
        title = "Save to Excel",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        p("Save your application data to an Excel file. You can create a new file or append to an existing one."),
        fluidRow(
          column(6,
                 textInput(ns("version"), 
                           "Version Name:", 
                           value = "AVs+AIAgentsV1", 
                           placeholder = "e.g., AVs+AIAgentsV1")),
          column(6,
                 textInput(ns("sheet"), 
                           "Sheet Name:", 
                           value = "Project_V1", 
                           placeholder = "Name for the Excel sheet"))
        ),
        fluidRow(
          column(12,
                 textInput(ns("filepath"), 
                           "Excel File Path:", 
                           value = "project_application.xlsx",
                           placeholder = "e.g., /path/to/your/file.xlsx or C:/Users/YourName/Documents/project.xlsx"))
        ),
        p(tags$small("Tip: Use absolute paths. On Windows: C:/Users/YourName/Documents/file.xlsx. On Mac/Linux: /home/username/file.xlsx")),
        br(),
        actionButton(ns("save"), 
                     "Save to Excel", 
                     class = "save-btn", 
                     icon = icon("file-excel")),
        br(), br(),
        uiOutput(ns("save_status"))
      )
    )
  )
}