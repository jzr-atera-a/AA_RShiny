# modules/about/ui.R

about_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "About This Application",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        
        h3("Book Summary Complete Suite - Enhanced Edition v3.0"),
        p("An integrated platform combining AI-powered book summary generation with cloud database storage and rich data visualization."),
        
        hr(),
        
        h4("Features:"),
        tags$ul(
          tags$li(tags$strong("AI Summary Generation:"), " Claude AI for automatic structured summaries"),
          tags$li(tags$strong("BigQuery Integration:"), " Cloud database storage (atera-2.Wonderfulp_March.book_summaries_test3)"),
          tags$li(tags$strong("Mathematical Formulas:"), " LaTeX/MathJax expressions with explanations"),
          tags$li(tags$strong("Reference Resources:"), " URLs with descriptions"),
          tags$li(tags$strong("Enhanced Metrics:"), " Detailed numeric data with descriptions"),
          tags$li(tags$strong("Rich Visualizations:"), " Interactive HTML dashboards with Plotly")
        ),
        
        hr(),
        
        h4("Data Schema (BigQuery):"),
        p("Table: atera-2.Wonderfulp_March.book_summaries_test3"),
        tags$pre("Fields:\n  - id (INTEGER)\n  - created_at (TIMESTAMP)\n  - book_name (STRING)\n  - author (STRING)\n  - genre (STRING)\n  - topic (STRING)\n  - chapter (STRING)\n  - section (STRING)\n  - main_details (STRING)\n  - formula (STRING)\n  - formula_explanation (STRING)\n  - reference_url (STRING)\n  - reference_description (STRING)\n  - numeric_data (STRING)\n  - numeric_data_description (STRING)"),
        
        hr(),
        
        h4("Modular Architecture:"),
        p("This application uses a modern modular architecture where each feature is a self-contained module."),
        tags$ul(
          tags$li("Enable/disable modules by editing modules/_module_registry.yml"),
          tags$li("Each module has its own UI, server, manifest, and README"),
          tags$li("Zero namespace conflicts with proper NS() usage"),
          tags$li("Reactive state sharing via api_manager$state_trigger()")
        ),
        
        hr(),
        
        p("Version 3.0.0 - Modular Architecture | Enhanced Schema with Formulas & References", 
          style = "text-align: center; color: #999; font-size: 12px;")
      )
    )
  )
}
