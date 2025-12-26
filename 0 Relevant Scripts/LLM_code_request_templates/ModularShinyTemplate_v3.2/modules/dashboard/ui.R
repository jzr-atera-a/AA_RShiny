# modules/dashboard/ui.R
# Dashboard Module UI

dashboard_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      valueBoxOutput(ns("box1"), width = 3),
      valueBoxOutput(ns("box2"), width = 3),
      valueBoxOutput(ns("box3"), width = 3),
      valueBoxOutput(ns("box4"), width = 3)
    ),
    
    fluidRow(
      box(
        title = "Welcome to Modular Shiny v3.0",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        h4("This is a simplified, production-ready template"),
        p("This template demonstrates:"),
        tags$ul(
          tags$li("✓ Proper tab and menu generation (no empty main body!)"),
          tags$li("✓ Modular architecture with enable/disable control"),
          tags$li("✓ Reactive state sharing across modules"),
          tags$li("✓ API configuration management"),
          tags$li("✓ Centralized CSS styling"),
          tags$li("✓ Example modules you can customize")
        ),
        
        hr(),
        
        h5("Quick Start:"),
        tags$ol(
          tags$li("Configure your API in the 'API Config' tab"),
          tags$li("Explore the 'Data Viewer' tab for filtering examples"),
          tags$li("Enable/disable modules in ", tags$code("modules/_module_registry.yml")),
          tags$li("Add your own modules following the example structure")
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Sample Chart",
        status = "info",
        solidHeader = TRUE,
        width = 6,
        plotOutput(ns("sample_plot"), height = 300)
      ),
      
      box(
        title = "System Status",
        status = "success",
        solidHeader = TRUE,
        width = 6,
        htmlOutput(ns("system_status"))
      )
    )
  )
}
