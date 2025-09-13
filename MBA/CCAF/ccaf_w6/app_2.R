# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(htmltools)

# Define UI
ui <- dashboardPage(
  # Dashboard Header
  dashboardHeader(
    title = "AI Energy Methodology Analysis",
    titleWidth = 350
  ),
  
  # Dashboard Sidebar
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      menuItem("Methodology Contrast", 
               tabName = "methodology", 
               icon = icon("chart-line")),
      menuItem("Azure vs CoreWeave", 
               tabName = "comparison", 
               icon = icon("server")),
      menuItem("Enhancement Opportunities", 
               tabName = "enhancement", 
               icon = icon("tools")),
      menuItem("Strategic Implications", 
               tabName = "strategic", 
               icon = icon("chart-area"))
    )
  ),
  
  # Dashboard Body
  dashboardBody(
    # Custom CSS for 9:16 landscape layout
    tags$head(
      tags$style(HTML("
        /* Force 9:16 landscape container */
        .content-wrapper {
          height: 100vh !important;
          overflow: hidden;
        }
        
        .main-container {
          width: 100%;
          max-width: 1600px;
          height: 900px;
          margin: 0 auto;
          display: flex;
          flex-direction: column;
          gap: 20px;
          padding: 15px;
          box-sizing: border-box;
        }
        
        /* Title section */
        .title-section {
          height: 80px;
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
          text-align: center;
          flex-shrink: 0;
        }
        
        .main-title {
          font-size: 2.2rem;
          color: #2c3e50;
          font-weight: 700;
          margin-bottom: 5px;
          line-height: 1.1;
        }
        
        .subtitle {
          font-size: 1.0rem;
          color: #7f8c8d;
        }
        
        /* Content wrapper */
        .content-container {
          flex: 1;
          display: flex;
          flex-direction: column;
          gap: 20px;
          min-height: 0;
        }
        
        /* Row 1: Methodology Overview */
        .methodology-overview {
          height: 100px;
          display: flex;
          gap: 15px;
          flex-shrink: 0;
        }
        
        .method-card {
          flex: 1;
          border-radius: 8px;
          padding: 12px;
          color: white;
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
          text-align: center;
          min-width: 0;
        }
        
        .topdown-card { background: linear-gradient(135deg, #3498DB, #2980B9); }
        .bottomup-card { background: linear-gradient(135deg, #E74C3C, #C0392B); }
        .variance-card { background: linear-gradient(135deg, #28B463, #239B56); }
        .accuracy-card { background: linear-gradient(135deg, #F39C12, #E67E22); }
        
        .method-title {
          font-size: 1.1rem;
          font-weight: bold;
          margin-bottom: 6px;
          line-height: 1.2;
        }
        
        .method-desc {
          font-size: 0.8rem;
          opacity: 0.95;
          line-height: 1.2;
        }
        
        /* Row 2: Comparison Chart */
        .comparison-chart {
          height: 160px;
          background: white;
          border: 2px solid #ECF0F1;
          border-radius: 8px;
          padding: 15px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.05);
          flex-shrink: 0;
          overflow: hidden;
        }
        
        .chart-header {
          font-size: 1.2rem;
          font-weight: bold;
          color: #2c3e50;
          text-align: center;
          margin-bottom: 12px;
        }
        
        .comparison-grid {
          display: grid;
          grid-template-columns: 180px 1fr 1fr;
          gap: 12px;
          height: calc(100% - 40px);
        }
        
        .provider-labels {
          display: flex;
          flex-direction: column;
          justify-content: space-around;
          gap: 8px;
        }
        
        .provider-label {
          font-size: 0.95rem;
          font-weight: 600;
          color: #2c3e50;
          padding: 6px 10px;
          background: #F8F9FA;
          border-radius: 6px;
          text-align: center;
          flex: 1;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        
        .methodology-column {
          display: flex;
          flex-direction: column;
          gap: 6px;
        }
        
        .topdown-column {
          border-left: 4px solid #3498DB;
          padding-left: 12px;
        }
        
        .bottomup-column {
          border-left: 4px solid #E74C3C;
          padding-left: 12px;
        }
        
        .column-title {
          font-size: 0.9rem;
          font-weight: bold;
          text-align: center;
          margin-bottom: 6px;
        }
        
        .topdown-column .column-title { color: #3498DB; }
        .bottomup-column .column-title { color: #E74C3C; }
        
        .data-row {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 4px 8px;
          background: #F8F9FA;
          border-radius: 4px;
          font-size: 0.8rem;
        }
        
        .data-value {
          font-weight: bold;
        }
        
        /* Row 3: Variance Analysis */
        .variance-analysis {
          height: 56px;
          margin-top: 40px;
          display: flex;
          gap: 15px;
          flex-shrink: 0;
        }
        
        .variance-panel {
          flex: 1;
          border-radius: 8px;
          padding: 8px;
          display: flex;
          flex-direction: column;
          min-width: 0;
          justify-content: center;
        }
        
        .azure-variance {
          background: linear-gradient(135deg, #E8F6F3, #D5F4E6);
          border: 2px solid #27AE60;
        }
        
        .coreweave-variance {
          background: linear-gradient(135deg, #FEF9E7, #FCF3CF);
          border: 2px solid #F39C12;
        }
        
        .insights-panel {
          background: linear-gradient(135deg, #EBF5FB, #D6EAF8);
          border: 2px solid #3498DB;
        }
        
        .panel-header {
          font-size: 0.8rem;
          font-weight: bold;
          text-align: center;
          margin-bottom: 4px;
        }
        
        .azure-variance .panel-header { color: #27AE60; }
        .coreweave-variance .panel-header { color: #F39C12; }
        .insights-panel .panel-header { color: #3498DB; }
        
        .variance-display {
          text-align: center;
          margin-bottom: 2px;
        }
        
        .variance-number {
          font-size: 1.3rem;
          font-weight: bold;
          line-height: 1;
        }
        
        .azure-variance .variance-number { color: #27AE60; }
        .coreweave-variance .variance-number { color: #F39C12; }
        
        .variance-label {
          font-size: 0.6rem;
          color: #2c3e50;
          margin-top: 2px;
        }
        
        .insights-list {
          display: flex;
          flex-direction: column;
          gap: 2px;
        }
        
        .insight-item {
          font-size: 0.55rem;
          color: #2c3e50;
          padding: 2px 4px;
          background: rgba(52, 152, 219, 0.1);
          border-radius: 3px;
          border-left: 2px solid #3498DB;
          line-height: 1.1;
        }
        
        .insight-label {
          font-weight: bold;
          color: #3498DB;
        }
        
        /* Remove default Shiny padding */
        .tab-content {
          padding: 0 !important;
          margin: 0 !important;
        }
        
        .content {
          padding: 0 !important;
          margin: 0 !important;
        }
      "))
    ),
    
    # Tab Items
    tabItems(
      # First tab: Methodology Contrast
      tabItem(
        tabName = "methodology",
        div(class = "main-container",
            # Title Section
            div(class = "title-section",
                h1("Top-Down vs Bottom-Up Methodology Contrast", 
                   class = "main-title"),
                p("Quantitative Variance Analysis & Capacity Planning Accuracy", 
                  class = "subtitle")
            ),
            
            # Content Container
            div(class = "content-container",
                # Row 1: Methodology Overview
                div(class = "methodology-overview",
                    div(class = "method-card topdown-card",
                        div(class = "method-title", "Top-Down Approach"),
                        div(class = "method-desc", 
                            "Infrastructure capacity × AI allocation = Energy estimate")
                    ),
                    div(class = "method-card bottomup-card",
                        div(class = "method-title", "Bottom-Up Approach"),
                        div(class = "method-desc", 
                            "Model deployments aggregated to provider totals")
                    ),
                    div(class = "method-card variance-card",
                        div(class = "method-title", "Variance Analysis"),
                        div(class = "method-desc", 
                            "Cross-validation between methodologies")
                    ),
                    div(class = "method-card accuracy-card",
                        div(class = "method-title", "Planning Accuracy"),
                        div(class = "method-desc", 
                            "Implications for capacity forecasting")
                    )
                ),
                
                # Row 2: Comparison Chart
                div(class = "comparison-chart",
                    div(class = "chart-header", 
                        "Monthly Energy Consumption Comparison (GWh)"),
                    div(class = "comparison-grid",
                        div(class = "provider-labels",
                            div(class = "provider-label", "Microsoft Azure"),
                            div(class = "provider-label", "CoreWeave")
                        ),
                        div(class = "methodology-column topdown-column",
                            div(class = "column-title", "Top-Down Infrastructure"),
                            div(class = "data-row",
                                span("Total AI Allocation:"),
                                span("837 GWh", class = "data-value")
                            ),
                            div(class = "data-row",
                                span("GenAI Inference (45%):"),
                                span("377 GWh", class = "data-value")
                            ),
                            div(class = "data-row",
                                span("Total AI Allocation:"),
                                span("272 GWh", class = "data-value")
                            ),
                            div(class = "data-row",
                                span("GenAI Inference (45%):"),
                                span("122 GWh", class = "data-value")
                            )
                        ),
                        div(class = "methodology-column bottomup-column",
                            div(class = "column-title", "Bottom-Up Model Data"),
                            div(class = "data-row",
                                span("Model Aggregation:"),
                                span("373 GWh", class = "data-value")
                            ),
                            div(class = "data-row",
                                span("Daily × 30.44 days:"),
                                span("12.3M kWh/day", class = "data-value")
                            ),
                            div(class = "data-row",
                                span("Model Aggregation:"),
                                span("153 GWh", class = "data-value")
                            ),
                            div(class = "data-row",
                                span("Daily × 30.44 days:"),
                                span("5.0M kWh/day", class = "data-value")
                            )
                        )
                    )
                ),
                
                # Row 3: Variance Analysis
                div(class = "variance-analysis",
                    div(class = "variance-panel azure-variance",
                        div(class = "panel-header", "Azure Variance"),
                        div(class = "variance-display",
                            div(class = "variance-number", "-0.9%"),
                            div(class = "variance-label", "Remarkable Alignment")
                        )
                    ),
                    div(class = "variance-panel coreweave-variance",
                        div(class = "panel-header", "CoreWeave Variance"),
                        div(class = "variance-display",
                            div(class = "variance-number", "+25.2%"),
                            div(class = "variance-label", "Higher Utilization")
                        )
                    ),
                    div(class = "variance-panel insights-panel",
                        div(class = "panel-header", "Key Insights"),
                        div(class = "insights-list",
                            div(class = "insight-item",
                                span(class = "insight-label", "Validation:"),
                                " Azure's alignment confirms methodology accuracy"
                            ),
                            div(class = "insight-item",
                                span(class = "insight-label", "Specialization:"),
                                " CoreWeave exceeds industry GenAI baseline"
                            ),
                            div(class = "insight-item",
                                span(class = "insight-label", "Planning:"),
                                " Provider specialization affects allocation assumptions"
                            ),
                            div(class = "insight-item",
                                span(class = "insight-label", "Framework:"),
                                " Cross-validation essential for accuracy"
                            )
                        )
                    )
                )
            )
        )
      ),
      
      # Placeholder tabs for future implementation
      tabItem(tabName = "comparison",
              h2("Azure vs CoreWeave Deep Dive"),
              p("Content for tab 2 will be added next...")
      ),
      
      tabItem(tabName = "enhancement",
              h2("Enhancement Opportunities"),
              p("Content for tab 3 will be added next...")
      ),
      
      tabItem(tabName = "strategic",
              h2("Strategic Implications"),
              p("Content for tab 4 will be added next...")
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  # Server logic will be added here as needed
  # Currently no reactive elements needed for the first tab
}

# Run the application
shinyApp(ui = ui, server = server)