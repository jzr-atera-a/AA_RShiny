# modules/Strategy Canvases/de_roadmap_view.R
# Subtab: Disciplined Ent. Roadmap (view)
#
# NOTE ON FIDELITY: in the source app, this tab's "Load Data" button only
# showed a placeholder notification ("...requires data in BigQuery table")
# and never actually rendered anything - the 24 boxes always showed the
# static framework description, regardless of selection. That was a stub,
# not a design choice (the equivalent BM Canvas and DE Canvas view tabs WERE
# fully wired). This version completes it: selecting a saved roadmap and
# clicking "Load Data" now renders each step's actual generated content,
# using the exact same query/render pattern as the other two view tabs.

de_roadmap_view_ui <- function(id) {
  ns <- NS(id)

  step_box <- function(step_num) {
    cat_class <- paste0("roadmap-cat", ROADMAP_STEP_CATEGORY[step_num])
    div(class = paste("de-roadmap-box", cat_class),
        div(class = "de-roadmap-number", as.character(step_num)),
        div(class = "de-roadmap-title", ROADMAP_STEP_TITLES[step_num]),
        htmlOutput(ns(paste0("step", sprintf("%02d", step_num), "_content"))))
  }

  tagList(
    fluidRow(
      column(12,
             div(class = "selection-controls-box",
                 h3("Select Disciplined Entrepreneurship Roadmap", style = "margin-top: 0; color: #002C3C;"),
                 fluidRow(
                   column(3, selectInput(ns("business_area"), "Business Area:", choices = NULL, width = "100%")),
                   column(3, selectInput(ns("project"), "Project:", choices = NULL, width = "100%")),
                   column(3, selectInput(ns("business_focus"), "Business Focus:", choices = NULL, width = "100%")),
                   column(3, br(), actionButton(ns("load_btn"), "Load Data", class = "btn btn-success btn-lg", icon = icon("download"), width = "100%"))
                 )))
    ),
    fluidRow(
      column(12,
             h2("Disciplined Entrepreneurship Roadmap", style = "text-align: center; color: white; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
             div(class = "de-roadmap-container",
                 div(class = "de-roadmap-grid", lapply(1:4, step_box)),
                 div(class = "de-roadmap-grid", lapply(5:8, step_box)),
                 div(class = "de-roadmap-grid", lapply(9:12, step_box)),
                 div(class = "de-roadmap-grid", lapply(13:16, step_box)),
                 div(class = "de-roadmap-grid", lapply(17:20, step_box)),
                 div(class = "de-roadmap-grid", lapply(21:24, step_box)),
                 div(class = "roadmap-legend",
                     div(class = "roadmap-legend-item", div(class = "roadmap-legend-line legend-line1"), span("WHO IS YOUR CUSTOMER?")),
                     div(class = "roadmap-legend-item", div(class = "roadmap-legend-line legend-line2"), span("WHAT CAN YOU DO FOR YOUR CUSTOMER?")),
                     div(class = "roadmap-legend-item", div(class = "roadmap-legend-line legend-line3"), span("HOW DOES YOUR CUSTOMER ACQUIRE YOUR PRODUCT?")),
                     div(class = "roadmap-legend-item", div(class = "roadmap-legend-line legend-line4"), span("HOW DO YOU MAKE MONEY OFF YOUR PRODUCT?")),
                     div(class = "roadmap-legend-item", div(class = "roadmap-legend-line legend-line5"), span("HOW DO YOU DESIGN & BUILD YOUR PRODUCT? / HOW DO YOU SCALE YOUR BUSINESS?"))
                 ))
      )
    )
  )
}

de_roadmap_view_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    render_defaults <- function() {
      for (i in 1:24) {
        local({
          n <- i
          desc <- sprintf("<em>%s</em> - select a saved roadmap above and click 'Load Data' to see the generated content for this step.",
                           c("Identify broad market opportunities and segment into distinct groups",
                             "Choose the best target market to focus initial resources",
                             "Define the characteristics of your target end user",
                             "Quantify the Total Addressable Market revenue opportunity",
                             "Create detailed persona including demographics and behaviors",
                             "Map complete customer journey with your product",
                             "Define key features and specifications of your product",
                             "Calculate tangible value delivered to customers",
                             "List specific target customers for initial sales",
                             "Identify unique capabilities that differentiate you",
                             "Analyze competitive landscape and your positioning",
                             "Identify all stakeholders involved in purchase decision",
                             "Document steps to convert prospect to paying customer",
                             "Quantify opportunities in adjacent market segments",
                             "Define how you create, deliver, and capture value",
                             "Establish pricing strategy aligned with value delivered",
                             "Determine total revenue from average customer relationship",
                             "Document complete sales cycle and touchpoints",
                             "Determine total cost to acquire one customer",
                             "List critical assumptions that must be validated",
                             "Run experiments to validate or invalidate assumptions",
                             "Create simplest product that delivers core value proposition",
                             "Prove customers will actually pay for your product",
                             "Create roadmap for product development and scaling")[n])
          output[[paste0("step", sprintf("%02d", n), "_content")]] <- renderUI(HTML(paste0('<div class="de-roadmap-description">', desc, '</div>')))
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
        result <- api_manager$bq_load_de_roadmap(input$business_area, input$project, input$business_focus)

        if (nrow(result) > 0) {
          roadmap_cols <- names(result)[grepl("^step_", names(result))]
          # roadmap_cols are already in step_01_.../step_24_... order from the table schema
          for (i in seq_along(ROADMAP_STEP_FIELDS)) {
            local({
              n <- i
              col <- roadmap_cols[n]
              output[[paste0("step", sprintf("%02d", n), "_content")]] <- renderUI(
                HTML(paste0('<div class="de-roadmap-description" style="display:block;">', gsub("\n", "<br>", result[[col]][1]), '</div>'))
              )
            })
          }
          showNotification("✓ Roadmap loaded successfully!", type = "message")
        } else {
          showNotification("No roadmap found for this selection.", type = "warning")
        }
      }, error = function(e) {
        showNotification(paste("Error loading roadmap:", e$message), type = "error")
      })
    })
  })
}
