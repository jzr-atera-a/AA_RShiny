# modules/Strategy Canvases/bm_canvas_view.R
# Subtab: Business Model Canvas (view)

bm_canvas_view_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
             div(class = "selection-controls-box",
                 h3("Select Business Model Canvas", style = "margin-top: 0; color: #002C3C;"),
                 fluidRow(
                   column(3, selectInput(ns("business_area"), "Business Area:", choices = NULL, width = "100%")),
                   column(3, selectInput(ns("project"), "Project:", choices = NULL, width = "100%")),
                   column(3, selectInput(ns("business_focus"), "Business Focus:", choices = NULL, width = "100%")),
                   column(3, br(), actionButton(ns("load_btn"), "Load Canvas", class = "btn btn-success btn-lg", icon = icon("download"), width = "100%"))
                 )))
    ),
    fluidRow(
      column(12,
             h2("Business Model Canvas", style = "text-align: center; color: white; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
             div(class = "canvas-grid",
                 div(class = "canvas-section key-partners partners",
                     div(class = "section-title", span(class = "section-icon", "🤝"), "Key Partners"), htmlOutput(ns("f_key_partners"))),
                 div(class = "canvas-section key-activities activities",
                     div(class = "section-title", span(class = "section-icon", "⚡"), "Key Activities"), htmlOutput(ns("f_key_activities"))),
                 div(class = "canvas-section key-resources resources",
                     div(class = "section-title", span(class = "section-icon", "🏗️"), "Key Resources"), htmlOutput(ns("f_key_resources"))),
                 div(class = "canvas-section value-propositions value-prop",
                     div(class = "section-title", span(class = "section-icon", "🎁"), "Value Propositions"), htmlOutput(ns("f_value_propositions"))),
                 div(class = "canvas-section customer-relationships relationships",
                     div(class = "section-title", span(class = "section-icon", "💝"), "Customer Relationships"), htmlOutput(ns("f_customer_relationships"))),
                 div(class = "canvas-section channels channels-grid",
                     div(class = "section-title", span(class = "section-icon", "📢"), "Channels"), htmlOutput(ns("f_channels"))),
                 div(class = "canvas-section customer-segments segments",
                     div(class = "section-title", span(class = "section-icon", "👥"), "Customer Segments"), htmlOutput(ns("f_customer_segments"))),
                 div(class = "canvas-section cost-structure costs",
                     div(class = "section-title", span(class = "section-icon", "💰"), "Cost Structure"), htmlOutput(ns("f_cost_structure"))),
                 div(class = "canvas-section revenue-streams revenue",
                     div(class = "section-title", span(class = "section-icon", "💵"), "Revenue Streams"), htmlOutput(ns("f_revenue_streams")))
             ))
    )
  )
}

# Default reference-framework content shown before any canvas is loaded
# (ported from the source app's loadDefaultCanvas()).
bm_canvas_default_html <- list(
  key_partners = '<p><strong>Who are our Key Partners?</strong></p><p><strong>Who are our key suppliers?</strong></p><p><strong>Which Key Resources are we acquiring from partners?</strong></p><p><strong>Which Key Activities do partners perform?</strong></p><hr><p><strong>Motivations for partnerships:</strong></p><ul><li>Optimization and economy of scale</li><li>Reduction of risk and uncertainty</li><li>Acquisition of particular resources and activities</li></ul>',
  key_activities = '<p><strong>What Key Activities does our Value Proposition require?</strong></p><p><strong>Our Distribution Channels?</strong></p><p><strong>Customer Relationships?</strong></p><p><strong>Revenue Streams?</strong></p><hr><p><strong>Categories:</strong></p><ul><li>Production</li><li>Problem Solving</li><li>Platform/Network</li></ul>',
  key_resources = '<p><strong>What Key Resources does our Value Proposition require?</strong></p><p><strong>Our Distribution Channels?</strong></p><p><strong>Customer Relationships?</strong></p><p><strong>Revenue Streams?</strong></p><hr><p><strong>Types of resources:</strong></p><ul><li>Physical</li><li>Intellectual</li><li>Human</li><li>Financial</li></ul>',
  value_propositions = "<p><strong>What value do we deliver to the customer?</strong></p><p><strong>Which one of our customer's problems are we helping to solve?</strong></p><p><strong>What bundles of products and services are we offering to each Customer Segment?</strong></p><p><strong>Which customer needs are we satisfying?</strong></p><hr><p><strong>Characteristics:</strong></p><ul><li>Newness</li><li>Performance</li><li>Customization</li><li>Getting the Job Done</li><li>Design</li><li>Brand/Status</li><li>Price</li><li>Cost Reduction</li><li>Risk Reduction</li><li>Accessibility</li><li>Convenience/Usability</li></ul>",
  customer_relationships = '<p><strong>What type of relationship does each Customer Segment expect?</strong></p><p><strong>Which ones have we established?</strong></p><p><strong>How are they integrated?</strong></p><p><strong>How costly are they?</strong></p><hr><p><strong>Categories:</strong></p><ul><li>Personal assistance</li><li>Dedicated assistance</li><li>Self-service</li><li>Automated services</li><li>Communities</li><li>Co-creation</li></ul>',
  channels = '<p><strong>Through which Channels do our Customer Segments want to be reached?</strong></p><p><strong>How are we reaching them now?</strong></p><p><strong>How are our Channels integrated?</strong></p><p><strong>Which ones work best?</strong></p><p><strong>Which ones are most cost-efficient?</strong></p><hr><p><strong>Channel phases:</strong></p><ul><li>1. Awareness</li><li>2. Evaluation</li><li>3. Purchase</li><li>4. Delivery</li><li>5. After sales</li></ul>',
  customer_segments = '<p><strong>For whom are we creating value?</strong></p><p><strong>Who are our most important customers?</strong></p><hr><p><strong>Groups of people or organizations:</strong></p><ul><li>Mass market</li><li>Niche market</li><li>Segmented</li><li>Diversified</li><li>Multi-sided platforms</li></ul><hr><p><strong>Customer characteristics:</strong></p><ul><li>Common needs</li><li>Common behaviors</li><li>Common attributes</li><li>Profitability</li><li>Distribution channels</li><li>Relationship types</li></ul>',
  cost_structure = '<p><strong>What are the most important costs inherent in our business model?</strong></p><p><strong>Which Key Resources are most expensive?</strong></p><p><strong>Which Key Activities are most expensive?</strong></p><hr><p><strong>Is your business more:</strong></p><ul><li>Cost Driven (leanest cost structure, low price value proposition, maximum automation, extensive outsourcing)</li><li>Value Driven (focused on value creation, premium value propositions)</li></ul><hr><p><strong>Sample characteristics:</strong></p><ul><li>Fixed Costs</li><li>Variable costs</li><li>Economies of scale</li><li>Economies of scope</li></ul>',
  revenue_streams = '<p><strong>What value are our customers really willing to pay for?</strong></p><p><strong>For what do they currently pay?</strong></p><p><strong>How are they currently paying?</strong></p><p><strong>How would they prefer to pay?</strong></p><p><strong>How much does each Revenue Stream contribute to overall revenues?</strong></p><hr><p><strong>Types:</strong></p><ul><li>Asset sale</li><li>Usage fee</li><li>Subscription fees</li><li>Lending/Renting/Leasing</li><li>Licensing</li><li>Brokerage fees</li><li>Advertising</li></ul><hr><p><strong>Fixed Menu Pricing:</strong></p><ul><li>List price</li><li>Product feature dependent</li><li>Customer segment dependent</li><li>Volume dependent</li></ul><hr><p><strong>Dynamic Pricing:</strong></p><ul><li>Negotiation</li><li>Yield management</li><li>Real-time-market</li></ul>'
)

bm_canvas_view_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    render_defaults <- function() {
      for (field in BM_CANVAS_FIELDS) {
        local({
          f <- field
          extra <- if (f %in% c("cost_structure", "revenue_streams")) "two-column-content" else ""
          output[[paste0("f_", f)]] <- renderUI(HTML(paste0('<div class="section-content ', extra, '">', bm_canvas_default_html[[f]], '</div>')))
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
        result <- api_manager$bq_load_bm_canvas(input$business_area, input$project, input$business_focus)

        if (nrow(result) > 0) {
          for (field in BM_CANVAS_FIELDS) {
            local({
              f <- field
              extra <- if (f %in% c("cost_structure", "revenue_streams")) "two-column-content" else ""
              output[[paste0("f_", f)]] <- renderUI(canvas_html_field(result[[f]][1], extra))
            })
          }
          showNotification("✓ Canvas loaded successfully!", type = "message")
        } else {
          showNotification("No canvas found for this selection. Showing default template.", type = "warning")
          render_defaults()
        }
      }, error = function(e) {
        showNotification(paste("Error loading canvas:", e$message), type = "error")
        render_defaults()
      })
    })
  })
}
