# modules/Strategy Canvases/de_canvas_view.R
# Subtab: Disciplined Ent. Canvas (view)

DE_BOX_META <- list(
  list(num = 1, field = "raison_detre", title = "Raison d'Être", subtitle = "Why do you in business?",
       default = "Mission, Passion, Values, Initial Assets, Initial Idea"),
  list(num = 2, field = "initial_market", title = "Initial Market", subtitle = "Who is your customer?",
       default = "Beachhead, End User Profile, TAM, Persona, First 10 Customers"),
  list(num = 3, field = "value_creation", title = "Value Creation", subtitle = "What can you do for your customer?",
       default = "Use Case, Product Description, Problem Being Solved, Quantified Value Proposition"),
  list(num = 4, field = "competitive_advantage", title = "Competitive Advantage", subtitle = "Why you?",
       default = "Moats, Core, Competitive Positioning"),
  list(num = 5, field = "customer_acquisition", title = "Customer Acquisition", subtitle = "How does your customer acquire your product?",
       default = "DMU, Process to Acquire Customer, Windows of Opportunity, Possible Triggers"),
  list(num = 6, field = "product_unit_economics", title = "Product Unit Economics", subtitle = "Can you make money?",
       default = "Business Model, Estimated Pricing, Short/Medium/Long Term LTV and COCA"),
  list(num = 7, field = "sales", title = "Sales", subtitle = "How do you sell your product?",
       default = "Preferred Sales Channel, Sales Funnel, Short/Medium/Long Term Mix"),
  list(num = 8, field = "overall_economics", title = "Overall Economics", subtitle = "Does your product make money?",
       default = "Estimated R&D Expenses, Estimated G&A Expenses, LTV/COCA Ratio High Enough"),
  list(num = 9, field = "design_build", title = "Design & Build", subtitle = "How do you produce the product?",
       default = "Identify Key Assumptions, Test Key Assumptions, MVBP, Tracking Metrics"),
  list(num = 10, field = "scaling", title = "Scaling", subtitle = "How do you scale?",
       default = "Product Plan for Beachhead, Next Market, Product Plan Beyond Beachhead, Follow-on TAM")
)

de_canvas_view_ui <- function(id) {
  ns <- NS(id)

  box_div <- function(meta) {
    div(class = paste0("de-box de-box", meta$num),
        div(class = "de-box-number", as.character(meta$num)),
        div(class = "de-box-title", meta$title),
        div(class = "de-box-subtitle", meta$subtitle),
        htmlOutput(ns(paste0("box", meta$num, "_content"))))
  }

  tagList(
    fluidRow(
      column(12,
             div(class = "selection-controls-box",
                 h3("Select Disciplined Entrepreneurship Canvas", style = "margin-top: 0; color: #002C3C;"),
                 fluidRow(
                   column(3, selectInput(ns("business_area"), "Business Area:", choices = NULL, width = "100%")),
                   column(3, selectInput(ns("project"), "Project:", choices = NULL, width = "100%")),
                   column(3, selectInput(ns("business_focus"), "Business Focus:", choices = NULL, width = "100%")),
                   column(3, br(), actionButton(ns("load_btn"), "Load Data", class = "btn btn-success btn-lg", icon = icon("download"), width = "100%"))
                 )))
    ),
    fluidRow(
      column(12,
             h2("The Disciplined Entrepreneurship Canvas", style = "text-align: center; color: white; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
             div(class = "de-canvas-grid", lapply(DE_BOX_META, box_div)))
    )
  )
}

de_canvas_view_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    render_defaults <- function() {
      for (meta in DE_BOX_META) {
        local({
          m <- meta
          output[[paste0("box", m$num, "_content")]] <- renderUI(de_box_html_field(m$default))
        })
      }
    }
    render_defaults()

    setup_canvas_selection_cascade(input, output, session, api_manager)

    observeEvent(input$load_btn, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate first (API Settings > BigQuery Config)", type = "error"); return() }
      if (nchar(input$business_area %||% "") == 0 || nchar(input$project %||% "") == 0 || nchar(input$business_focus %||% "") == 0) {
        showNotification("Please select Business Area, Project, and Business Focus", type = "warning")
        return()
      }

      tryCatch({
        result <- api_manager$bq_load_de_canvas(input$business_area, input$project, input$business_focus)

        if (nrow(result) > 0) {
          for (meta in DE_BOX_META) {
            local({
              m <- meta
              output[[paste0("box", m$num, "_content")]] <- renderUI(de_box_html_field(result[[m$field]][1]))
            })
          }
          showNotification("✓ DE Canvas loaded successfully!", type = "message")
        } else {
          showNotification("No DE Canvas found for this selection.", type = "warning")
        }
      }, error = function(e) {
        showNotification(paste("Error loading DE Canvas:", e$message), type = "error")
      })
    })
  })
}
