# Fintech Balanced Scorecard Dashboard
# Six Sigma Methodology Implementation

# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
library(scales)

# Generate sample data for the fintech company
set.seed(123)

# Financial Perspective Data
financial_data <- data.frame(
  Month = month.abb[1:12],
  Revenue = c(2.5, 2.8, 3.1, 2.9, 3.3, 3.7, 4.1, 3.9, 4.3, 4.6, 4.8, 5.2) * 1000000,
  Cost_Reduction = c(150, 175, 200, 180, 220, 250, 280, 260, 300, 320, 340, 380) * 1000,
  ROI = c(12.5, 14.2, 15.8, 13.9, 16.5, 18.2, 19.8, 18.5, 20.1, 21.3, 22.5, 24.1),
  NPL_Ratio = c(2.1, 1.9, 1.7, 1.8, 1.5, 1.3, 1.1, 1.2, 0.9, 0.8, 0.7, 0.6)
)

# Customer Perspective Data
customer_data <- data.frame(
  Month = month.abb[1:12],
  Customer_Satisfaction = c(78, 79, 81, 80, 83, 85, 87, 86, 89, 90, 92, 94),
  Customer_Acquisition = c(1250, 1380, 1520, 1450, 1680, 1850, 2100, 1950, 2280, 2450, 2680, 2950),
  Customer_Retention = c(85, 86, 87, 86, 88, 89, 91, 90, 92, 93, 94, 95),
  NPS_Score = c(35, 38, 42, 40, 45, 48, 52, 50, 55, 58, 61, 65)
)

# Internal Process Data
process_data <- data.frame(
  Month = month.abb[1:12],
  Loan_Processing_Time = c(72, 68, 65, 67, 62, 58, 55, 57, 52, 49, 46, 43),
  Digital_Adoption = c(65, 68, 71, 69, 74, 77, 80, 78, 83, 85, 88, 91),
  System_Uptime = c(99.2, 99.4, 99.6, 99.3, 99.7, 99.8, 99.9, 99.8, 99.9, 99.9, 99.9, 99.95),
  Defect_Rate = c(3.2, 2.8, 2.5, 2.7, 2.1, 1.8, 1.5, 1.6, 1.2, 1.0, 0.8, 0.6)
)

# Learning & Growth Data
learning_data <- data.frame(
  Month = month.abb[1:12],
  Employee_Satisfaction = c(72, 74, 76, 75, 78, 80, 82, 81, 84, 86, 88, 90),
  Training_Hours = c(25, 28, 32, 30, 35, 38, 42, 40, 45, 48, 52, 55),
  Innovation_Index = c(60, 63, 66, 64, 69, 72, 75, 73, 78, 81, 84, 87),
  Skills_Gap = c(25, 23, 21, 22, 19, 17, 15, 16, 13, 11, 9, 7)
)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "FinTech Balanced Scorecard Dashboard"),
  
  skin = "yellow",
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("tachometer-alt")),
      menuItem("Financial", tabName = "financial", icon = icon("dollar-sign")),
      menuItem("Customer", tabName = "customer", icon = icon("users")),
      menuItem("Internal Process", tabName = "process", icon = icon("cogs")),
      menuItem("Learning & Growth", tabName = "learning", icon = icon("graduation-cap")),
      menuItem("Six Sigma Metrics", tabName = "sixsigma", icon = icon("chart-line"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* Header styling */
        .skin-yellow .main-header .navbar {
          background-color: #FF8C00 !important;
        }
        .skin-yellow .main-header .logo {
          background-color: #FF8C00 !important;
          color: #000000 !important;
          border-bottom: 0 solid transparent;
        }
        .skin-yellow .main-header .logo:hover {
          background-color: #FF7F00 !important;
        }
        
        /* Sidebar styling */
        .skin-yellow .main-sidebar {
          background-color: #B8860B !important;
        }
        .skin-yellow .main-sidebar .sidebar .sidebar-menu .active a {
          background-color: #FFD700 !important;
          color: #000000 !important;
          font-weight: bold;
        }
        .skin-yellow .main-sidebar .sidebar .sidebar-menu a {
          color: #000000 !important;
        }
        .skin-yellow .main-sidebar .sidebar .sidebar-menu a:hover {
          background-color: #DAA520 !important;
          color: #000000 !important;
        }
        
        /* Content wrapper styling */
        .content-wrapper, .right-side {
          background-color: #FFF8DC !important;
        }
        
        /* Box styling */
        .box {
          background-color: #FFFFE0 !important;
          border: 2px solid #DAA520 !important;
          border-radius: 8px !important;
          box-shadow: 0 4px 8px rgba(218, 165, 32, 0.3) !important;
        }
        .box.box-warning {
          border-top-color: #FF8C00 !important;
          border-top-width: 4px !important;
        }
        .box.box-warning .box-header {
          color: #000000 !important;
          background: linear-gradient(135deg, #FF8C00, #FFD700) !important;
          border-radius: 6px 6px 0 0 !important;
          border-bottom: 2px solid #DAA520 !important;
        }
        .box.box-warning .box-header .box-title {
          font-size: 18px !important;
          font-weight: bold !important;
          text-shadow: 1px 1px 2px rgba(0,0,0,0.1) !important;
        }
        .box-body {
          background-color: #FFFACD !important;
          color: #333333 !important;
          padding: 20px !important;
        }
        
        /* Small box (value box) styling */
        .small-box {
          border-radius: 8px !important;
          box-shadow: 0 4px 8px rgba(218, 165, 32, 0.3) !important;
          border: 2px solid #DAA520 !important;
        }
        .small-box .inner {
          color: #000000 !important;
        }
        .small-box.bg-yellow {
          background-color: #FFD700 !important;
          background: linear-gradient(135deg, #FFD700, #FFFF99) !important;
        }
        .small-box.bg-orange {
          background-color: #FF8C00 !important;
          background: linear-gradient(135deg, #FF8C00, #FFA500) !important;
        }
        
        /* Text styling */
        p {
          color: #2F4F4F !important;
          line-height: 1.6 !important;
        }
        strong {
          color: #B8860B !important;
        }
        li {
          color: #2F4F4F !important;
          margin-bottom: 5px !important;
        }
        h4 {
          color: #B8860B !important;
          font-weight: bold !important;
        }
        
        /* Data table styling */
        .dataTables_wrapper {
          color: #333333 !important;
        }
        .table {
          color: #333333 !important;
          background-color: #FFFACD !important;
        }
        .table thead th {
          background-color: #DAA520 !important;
          color: #000000 !important;
          border-bottom: 2px solid #B8860B !important;
        }
        .table tbody tr:nth-child(even) {
          background-color: #FFF8DC !important;
        }
        .table tbody tr:hover {
          background-color: #F0E68C !important;
        }
        
        /* Link styling */
        a {
          color: #FF8C00 !important;
          text-decoration: none !important;
        }
        a:hover {
          color: #FF7F00 !important;
          text-decoration: underline !important;
        }
        
        /* Page title styling */
        .main-header .navbar-brand {
          color: #000000 !important;
          font-weight: bold !important;
        }
        
        /* Content area */
        .content {
          background-color: #FFF8DC !important;
        }
        body {
          background-color: #FFF8DC !important;
          color: #333333 !important;
        }
        
        /* Scrollbar styling */
        ::-webkit-scrollbar {
          width: 12px;
        }
        ::-webkit-scrollbar-track {
          background: #FFF8DC;
        }
        ::-webkit-scrollbar-thumb {
          background: #DAA520;
          border-radius: 6px;
        }
        ::-webkit-scrollbar-thumb:hover {
          background: #B8860B;
        }
        
        /* Menu items styling */
        .skin-yellow .main-sidebar .sidebar .sidebar-menu > li > a {
          border-left: 3px solid transparent;
        }
        .skin-yellow .main-sidebar .sidebar .sidebar-menu > li.active > a {
          border-left-color: #FF8C00 !important;
        }
        
        /* Tab styling */
        .nav-tabs-custom > .nav-tabs > li.active {
          border-top-color: #FF8C00 !important;
        }
        .nav-tabs-custom > .nav-tabs > li.active > a {
          background-color: #FFD700 !important;
          color: #000000 !important;
        }
      "))
    ),
    
    tabItems(
      # Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "Balanced Scorecard Framework", status = "warning", solidHeader = TRUE,
                  width = 12, height = 200,
                  h4("Six Sigma Balanced Scorecard for FinTech Excellence"),
                  p("This dashboard implements a comprehensive balanced scorecard framework following Six Sigma methodology 
              to measure and improve performance across four critical perspectives:"),
                  tags$ul(
                    tags$li(strong("Financial:"), "Revenue growth, cost reduction, ROI, and risk metrics"),
                    tags$li(strong("Customer:"), "Satisfaction, acquisition, retention, and loyalty indicators"),
                    tags$li(strong("Internal Process:"), "Operational efficiency, quality, and digital transformation"),
                    tags$li(strong("Learning & Growth:"), "Employee development, innovation, and capability building")
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("revenue_box"),
                valueBoxOutput("satisfaction_box"),
                valueBoxOutput("efficiency_box")
              ),
              
              fluidRow(
                box(
                  title = "Key Performance Indicators Trend", status = "warning", solidHeader = TRUE,
                  width = 12, height = 400,
                  plotlyOutput("overview_chart")
                )
              )
      ),
      
      # Financial Tab
      tabItem(tabName = "financial",
              fluidRow(
                valueBoxOutput("revenue_current"),
                valueBoxOutput("roi_current"),
                valueBoxOutput("npl_current")
              ),
              
              fluidRow(
                box(
                  title = "Revenue Growth Trend", status = "warning", solidHeader = TRUE,
                  width = 6, height = 350,
                  plotlyOutput("revenue_chart")
                ),
                box(
                  title = "ROI vs Cost Reduction", status = "warning", solidHeader = TRUE,
                  width = 6, height = 350,
                  plotlyOutput("roi_chart")
                )
              ),
              
              fluidRow(
                box(
                  title = "Financial Metrics Table", status = "warning", solidHeader = TRUE,
                  width = 12,
                  DT::dataTableOutput("financial_table")
                )
              )
      ),
      
      # Customer Tab
      tabItem(tabName = "customer",
              fluidRow(
                valueBoxOutput("csat_current"),
                valueBoxOutput("acquisition_current"),
                valueBoxOutput("nps_current")
              ),
              
              fluidRow(
                box(
                  title = "Customer Satisfaction & NPS", status = "warning", solidHeader = TRUE,
                  width = 6, height = 350,
                  plotlyOutput("satisfaction_chart")
                ),
                box(
                  title = "Customer Acquisition vs Retention", status = "warning", solidHeader = TRUE,
                  width = 6, height = 350,
                  plotlyOutput("acquisition_chart")
                )
              ),
              
              fluidRow(
                box(
                  title = "Customer Metrics Table", status = "warning", solidHeader = TRUE,
                  width = 12,
                  DT::dataTableOutput("customer_table")
                )
              )
      ),
      
      # Internal Process Tab
      tabItem(tabName = "process",
              fluidRow(
                valueBoxOutput("processing_time"),
                valueBoxOutput("digital_adoption"),
                valueBoxOutput("uptime_current")
              ),
              
              fluidRow(
                box(
                  title = "Process Efficiency Metrics", status = "warning", solidHeader = TRUE,
                  width = 6, height = 350,
                  plotlyOutput("process_chart")
                ),
                box(
                  title = "Quality Improvement (Six Sigma)", status = "warning", solidHeader = TRUE,
                  width = 6, height = 350,
                  plotlyOutput("quality_chart")
                )
              ),
              
              fluidRow(
                box(
                  title = "Process Metrics Table", status = "warning", solidHeader = TRUE,
                  width = 12,
                  DT::dataTableOutput("process_table")
                )
              )
      ),
      
      # Learning & Growth Tab
      tabItem(tabName = "learning",
              fluidRow(
                valueBoxOutput("emp_satisfaction"),
                valueBoxOutput("training_hours"),
                valueBoxOutput("innovation_current")
              ),
              
              fluidRow(
                box(
                  title = "Employee Development Metrics", status = "warning", solidHeader = TRUE,
                  width = 6, height = 350,
                  plotlyOutput("learning_chart")
                ),
                box(
                  title = "Skills Gap Reduction", status = "warning", solidHeader = TRUE,
                  width = 6, height = 350,
                  plotlyOutput("skills_chart")
                )
              ),
              
              fluidRow(
                box(
                  title = "Learning & Growth Metrics Table", status = "warning", solidHeader = TRUE,
                  width = 12,
                  DT::dataTableOutput("learning_table")
                )
              )
      ),
      
      # Six Sigma Tab
      tabItem(tabName = "sixsigma",
              fluidRow(
                box(
                  title = "Six Sigma DMAIC Framework Implementation", status = "warning", solidHeader = TRUE,
                  width = 12,
                  h4("Define - Measure - Analyze - Improve - Control"),
                  p("Our Six Sigma approach focuses on continuous improvement across all balanced scorecard perspectives:"),
                  tags$ul(
                    tags$li(strong("Define:"), "Critical-to-Quality metrics identified for each perspective"),
                    tags$li(strong("Measure:"), "Baseline performance established with statistical control"),
                    tags$li(strong("Analyze:"), "Root cause analysis for performance gaps"),
                    tags$li(strong("Improve:"), "Data-driven solutions implemented"),
                    tags$li(strong("Control:"), "Monitoring systems to sustain improvements")
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("sigma_level"),
                valueBoxOutput("defect_rate"),
                valueBoxOutput("process_capability")
              ),
              
              fluidRow(
                box(
                  title = "Six Sigma Performance Dashboard", status = "warning", solidHeader = TRUE,
                  width = 12, height = 450,
                  plotlyOutput("sixsigma_chart")
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output) {
  
  # Overview Value Boxes
  output$revenue_box <- renderValueBox({
    valueBox(
      value = paste0("$", round(tail(financial_data$Revenue, 1) / 1000000, 1), "M"),
      subtitle = "Current Revenue",
      icon = icon("dollar-sign"),
      color = "yellow"
    )
  })
  
  output$satisfaction_box <- renderValueBox({
    valueBox(
      value = paste0(tail(customer_data$Customer_Satisfaction, 1), "%"),
      subtitle = "Customer Satisfaction",
      icon = icon("smile"),
      color = "yellow"
    )
  })
  
  output$efficiency_box <- renderValueBox({
    valueBox(
      value = paste0(tail(process_data$Loan_Processing_Time, 1), " hrs"),
      subtitle = "Processing Time",
      icon = icon("clock"),
      color = "yellow"
    )
  })
  
  # Overview Chart
  output$overview_chart <- renderPlotly({
    p <- ggplot() +
      geom_line(data = financial_data, aes(x = 1:12, y = Revenue/1000000, color = "Revenue ($M)"), size = 1.2) +
      geom_line(data = customer_data, aes(x = 1:12, y = Customer_Satisfaction, color = "Customer Satisfaction (%)"), size = 1.2) +
      geom_line(data = process_data, aes(x = 1:12, y = Digital_Adoption, color = "Digital Adoption (%)"), size = 1.2) +
      geom_line(data = learning_data, aes(x = 1:12, y = Employee_Satisfaction, color = "Employee Satisfaction (%)"), size = 1.2) +
      scale_x_continuous(breaks = 1:12, labels = month.abb[1:12]) +
      labs(title = "Key Performance Indicators Across All Perspectives",
           x = "Month", y = "Performance Index", color = "Metrics") +
      theme_minimal() +
      theme(legend.position = "bottom")
    
    ggplotly(p)
  })
  
  # Financial Value Boxes
  output$revenue_current <- renderValueBox({
    valueBox(
      value = paste0("$", round(tail(financial_data$Revenue, 1) / 1000000, 1), "M"),
      subtitle = "Current Revenue",
      icon = icon("chart-line"),
      color = "yellow"
    )
  })
  
  output$roi_current <- renderValueBox({
    valueBox(
      value = paste0(tail(financial_data$ROI, 1), "%"),
      subtitle = "Return on Investment",
      icon = icon("percentage"),
      color = "yellow"
    )
  })
  
  output$npl_current <- renderValueBox({
    valueBox(
      value = paste0(tail(financial_data$NPL_Ratio, 1), "%"),
      subtitle = "Non-Performing Loans",
      icon = icon("exclamation-triangle"),
      color = "orange"
    )
  })
  
  # Financial Charts
  output$revenue_chart <- renderPlotly({
    p <- ggplot(financial_data, aes(x = factor(Month, levels = month.abb[1:12]), y = Revenue/1000000)) +
      geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
      geom_line(aes(group = 1), color = "darkblue", size = 1.2) +
      geom_point(color = "darkblue", size = 2) +
      labs(title = "Monthly Revenue Growth", x = "Month", y = "Revenue ($ Millions)") +
      theme_minimal()
    ggplotly(p)
  })
  
  output$roi_chart <- renderPlotly({
    p <- ggplot(financial_data, aes(x = Cost_Reduction/1000, y = ROI)) +
      geom_point(color = "red", size = 3, alpha = 0.7) +
      geom_smooth(method = "lm", se = FALSE, color = "darkred") +
      labs(title = "ROI vs Cost Reduction", x = "Cost Reduction ($K)", y = "ROI (%)") +
      theme_minimal()
    ggplotly(p)
  })
  
  # Customer Value Boxes
  output$csat_current <- renderValueBox({
    valueBox(
      value = paste0(tail(customer_data$Customer_Satisfaction, 1), "%"),
      subtitle = "Customer Satisfaction",
      icon = icon("heart"),
      color = "yellow"
    )
  })
  
  output$acquisition_current <- renderValueBox({
    valueBox(
      value = format(tail(customer_data$Customer_Acquisition, 1), big.mark = ","),
      subtitle = "New Customers",
      icon = icon("user-plus"),
      color = "yellow"
    )
  })
  
  output$nps_current <- renderValueBox({
    valueBox(
      value = tail(customer_data$NPS_Score, 1),
      subtitle = "Net Promoter Score",
      icon = icon("thumbs-up"),
      color = "yellow"
    )
  })
  
  # Customer Charts
  output$satisfaction_chart <- renderPlotly({
    p <- ggplot(customer_data, aes(x = factor(Month, levels = month.abb[1:12]))) +
      geom_line(aes(y = Customer_Satisfaction, group = 1, color = "Customer Satisfaction"), size = 1.2) +
      geom_line(aes(y = NPS_Score, group = 1, color = "NPS Score"), size = 1.2) +
      geom_point(aes(y = Customer_Satisfaction, color = "Customer Satisfaction"), size = 2) +
      geom_point(aes(y = NPS_Score, color = "NPS Score"), size = 2) +
      labs(title = "Customer Satisfaction & NPS Trends", x = "Month", y = "Score", color = "Metric") +
      theme_minimal()
    ggplotly(p)
  })
  
  output$acquisition_chart <- renderPlotly({
    p <- ggplot(customer_data, aes(x = factor(Month, levels = month.abb[1:12]))) +
      geom_bar(aes(y = Customer_Acquisition/1000), stat = "identity", fill = "lightgreen", alpha = 0.7) +
      geom_line(aes(y = Customer_Retention, group = 1), color = "darkgreen", size = 1.2) +
      geom_point(aes(y = Customer_Retention), color = "darkgreen", size = 2) +
      labs(title = "Customer Acquisition (K) vs Retention (%)", x = "Month", y = "Value") +
      theme_minimal()
    ggplotly(p)
  })
  
  # Process Value Boxes
  output$processing_time <- renderValueBox({
    valueBox(
      value = paste0(tail(process_data$Loan_Processing_Time, 1), " hrs"),
      subtitle = "Avg Processing Time",
      icon = icon("stopwatch"),
      color = "yellow"
    )
  })
  
  output$digital_adoption <- renderValueBox({
    valueBox(
      value = paste0(tail(process_data$Digital_Adoption, 1), "%"),
      subtitle = "Digital Adoption",
      icon = icon("mobile-alt"),
      color = "yellow"
    )
  })
  
  output$uptime_current <- renderValueBox({
    valueBox(
      value = paste0(tail(process_data$System_Uptime, 1), "%"),
      subtitle = "System Uptime",
      icon = icon("server"),
      color = "yellow"
    )
  })
  
  # Process Charts
  output$process_chart <- renderPlotly({
    p <- ggplot(process_data, aes(x = factor(Month, levels = month.abb[1:12]))) +
      geom_line(aes(y = Loan_Processing_Time, group = 1, color = "Processing Time (hrs)"), size = 1.2) +
      geom_line(aes(y = Digital_Adoption, group = 1, color = "Digital Adoption (%)"), size = 1.2) +
      geom_point(aes(y = Loan_Processing_Time, color = "Processing Time (hrs)"), size = 2) +
      geom_point(aes(y = Digital_Adoption, color = "Digital Adoption (%)"), size = 2) +
      labs(title = "Process Efficiency Metrics", x = "Month", y = "Value", color = "Metric") +
      theme_minimal()
    ggplotly(p)
  })
  
  output$quality_chart <- renderPlotly({
    p <- ggplot(process_data, aes(x = factor(Month, levels = month.abb[1:12]), y = Defect_Rate)) +
      geom_bar(stat = "identity", fill = "coral", alpha = 0.7) +
      geom_line(aes(group = 1), color = "darkred", size = 1.2) +
      geom_point(color = "darkred", size = 2) +
      labs(title = "Six Sigma Quality Improvement (Defect Rate Reduction)", 
           x = "Month", y = "Defect Rate (%)") +
      theme_minimal()
    ggplotly(p)
  })
  
  # Learning Value Boxes
  output$emp_satisfaction <- renderValueBox({
    valueBox(
      value = paste0(tail(learning_data$Employee_Satisfaction, 1), "%"),
      subtitle = "Employee Satisfaction",
      icon = icon("smile"),
      color = "yellow"
    )
  })
  
  output$training_hours <- renderValueBox({
    valueBox(
      value = tail(learning_data$Training_Hours, 1),
      subtitle = "Training Hours/Month",
      icon = icon("book"),
      color = "yellow"
    )
  })
  
  output$innovation_current <- renderValueBox({
    valueBox(
      value = tail(learning_data$Innovation_Index, 1),
      subtitle = "Innovation Index",
      icon = icon("lightbulb"),
      color = "yellow"
    )
  })
  
  # Learning Charts
  output$learning_chart <- renderPlotly({
    p <- ggplot(learning_data, aes(x = factor(Month, levels = month.abb[1:12]))) +
      geom_line(aes(y = Employee_Satisfaction, group = 1, color = "Employee Satisfaction"), size = 1.2) +
      geom_line(aes(y = Training_Hours, group = 1, color = "Training Hours"), size = 1.2) +
      geom_line(aes(y = Innovation_Index, group = 1, color = "Innovation Index"), size = 1.2) +
      geom_point(aes(y = Employee_Satisfaction, color = "Employee Satisfaction"), size = 2) +
      geom_point(aes(y = Training_Hours, color = "Training Hours"), size = 2) +
      geom_point(aes(y = Innovation_Index, color = "Innovation Index"), size = 2) +
      labs(title = "Learning & Growth Metrics", x = "Month", y = "Score/Hours", color = "Metric") +
      theme_minimal()
    ggplotly(p)
  })
  
  output$skills_chart <- renderPlotly({
    p <- ggplot(learning_data, aes(x = factor(Month, levels = month.abb[1:12]), y = Skills_Gap)) +
      geom_bar(stat = "identity", fill = "lightcoral", alpha = 0.7) +
      geom_line(aes(group = 1), color = "darkred", size = 1.2) +
      geom_point(color = "darkred", size = 2) +
      labs(title = "Skills Gap Reduction Over Time", x = "Month", y = "Skills Gap (%)") +
      theme_minimal()
    ggplotly(p)
  })
  
  # Six Sigma Value Boxes
  output$sigma_level <- renderValueBox({
    valueBox(
      value = "4.2σ",
      subtitle = "Current Sigma Level",
      icon = icon("award"),
      color = "yellow"
    )
  })
  
  output$defect_rate <- renderValueBox({
    valueBox(
      value = paste0(tail(process_data$Defect_Rate, 1), "%"),
      subtitle = "Current Defect Rate",
      icon = icon("bug"),
      color = "orange"
    )
  })
  
  output$process_capability <- renderValueBox({
    valueBox(
      value = "1.4",
      subtitle = "Process Capability (Cpk)",
      icon = icon("cogs"),
      color = "yellow"
    )
  })
  
  # Six Sigma Chart
  output$sixsigma_chart <- renderPlotly({
    # Create comprehensive Six Sigma metrics chart
    sixsigma_data <- data.frame(
      Month = month.abb[1:12],
      Defect_Rate = process_data$Defect_Rate,
      Process_Capability = c(0.8, 0.85, 0.9, 0.88, 0.95, 1.0, 1.05, 1.03, 1.1, 1.15, 1.25, 1.4),
      Sigma_Level = c(2.8, 3.0, 3.2, 3.1, 3.4, 3.6, 3.8, 3.7, 4.0, 4.1, 4.2, 4.3)
    )
    
    p <- ggplot(sixsigma_data, aes(x = factor(Month, levels = month.abb[1:12]))) +
      geom_bar(aes(y = Defect_Rate), stat = "identity", fill = "red", alpha = 0.3) +
      geom_line(aes(y = Sigma_Level, group = 1, color = "Sigma Level"), size = 1.5) +
      geom_line(aes(y = Process_Capability * 3, group = 1, color = "Process Capability"), size = 1.5) +
      geom_point(aes(y = Sigma_Level, color = "Sigma Level"), size = 3) +
      geom_point(aes(y = Process_Capability * 3, color = "Process Capability"), size = 3) +
      scale_y_continuous(
        name = "Defect Rate (%) / Sigma Level",
        sec.axis = sec_axis(~ . / 3, name = "Process Capability (Cpk)")
      ) +
      labs(title = "Six Sigma Performance Improvement Journey", 
           x = "Month", color = "Metrics") +
      theme_minimal() +
      theme(legend.position = "bottom")
    ggplotly(p)
  })
  
  # Data Tables
  output$financial_table <- DT::renderDataTable({
    financial_data %>%
      mutate(
        Revenue = paste0("$", round(Revenue/1000000, 2), "M"),
        Cost_Reduction = paste0("$", round(Cost_Reduction/1000, 0), "K"),
        ROI = paste0(ROI, "%"),
        NPL_Ratio = paste0(NPL_Ratio, "%")
      )
  }, options = list(pageLength = 12, scrollX = TRUE))
  
  output$customer_table <- DT::renderDataTable({
    customer_data %>%
      mutate(
        Customer_Satisfaction = paste0(Customer_Satisfaction, "%"),
        Customer_Acquisition = format(Customer_Acquisition, big.mark = ","),
        Customer_Retention = paste0(Customer_Retention, "%")
      )
  }, options = list(pageLength = 12, scrollX = TRUE))
  
  output$process_table <- DT::renderDataTable({
    process_data %>%
      mutate(
        Loan_Processing_Time = paste0(Loan_Processing_Time, " hrs"),
        Digital_Adoption = paste0(Digital_Adoption, "%"),
        System_Uptime = paste0(System_Uptime, "%"),
        Defect_Rate = paste0(Defect_Rate, "%")
      )
  }, options = list(pageLength = 12, scrollX = TRUE))
  
  output$learning_table <- DT::renderDataTable({
    learning_data %>%
      mutate(
        Employee_Satisfaction = paste0(Employee_Satisfaction, "%"),
        Skills_Gap = paste0(Skills_Gap, "%")
      )
  }, options = list(pageLength = 12, scrollX = TRUE))
}

# Run the application
shinyApp(ui = ui, server = server)