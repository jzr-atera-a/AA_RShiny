# Startup Business Model Financial Spreadsheet - R Shiny Application
# Complete financial modeling tool with Monte Carlo simulations and DCF analysis

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
library(viridis)
library(shinycssloaders)

# Define CSS
css <- "
  .main-header .navbar { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.1) !important;
  }
  .main-header .navbar-brand { 
    color: white !important; 
    font-weight: 700 !important; 
    font-size: 18px !important;
  }
  .main-sidebar { 
    background: linear-gradient(180deg, #2c3e50 0%, #34495e 100%) !important; 
  }
  .sidebar-menu > li > a { 
    color: #ecf0f1 !important; 
    border-left: 3px solid transparent; 
    transition: all 0.3s ease !important;
    font-weight: 500 !important;
  }
  .sidebar-menu > li.active > a { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border-left: 3px solid #f39c12 !important; 
    color: white !important; 
    box-shadow: inset 0 0 10px rgba(0,0,0,0.2) !important;
  }
  .sidebar-menu > li:hover > a { 
    background-color: #3e5771 !important; 
    color: white !important; 
  }
  .content-wrapper { 
    background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%) !important; 
  }
  .box { 
    border: none !important; 
    border-radius: 12px !important; 
    box-shadow: 0 4px 20px rgba(0,0,0,0.08) !important;
    background: white !important;
  }
  .box-header { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    color: white !important;
    border-radius: 12px 12px 0 0 !important; 
    font-weight: 600 !important;
  }
  .data-source-box { 
    background: linear-gradient(135deg, #ffffff 0%, #f8f9ff 100%);
    border: none;
    border-left: 5px solid #667eea; 
    padding: 25px; 
    margin-bottom: 25px; 
    border-radius: 12px; 
    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.1);
  }
  .reference-box {
    background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);
    border: 1px solid #e3e8ff;
    border-left: 5px solid #4f46e5;
    padding: 20px;
    margin-top: 25px;
    border-radius: 12px;
    box-shadow: 0 2px 10px rgba(79, 70, 229, 0.1);
  }
  .small-box { 
    border-radius: 12px !important; 
    box-shadow: 0 4px 15px rgba(0,0,0,0.1) !important;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  }
  .small-box .icon { opacity: 0.8 !important; }
  .plotly { 
    border-radius: 12px !important; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.05) !important;
  }
  .dataTables_wrapper { 
    background: white; 
    border-radius: 12px; 
    padding: 20px; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
  }
  .btn-primary { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    border-radius: 8px !important;
    font-weight: 600 !important;
  }
  .btn-danger { 
    background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important; 
    border: none !important; 
    border-radius: 8px !important;
    font-weight: 600 !important;
  }
  h4 { color: #2c3e50; font-weight: 600; }
  .reference-box h4 { color: #4f46e5; }
"

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Startup Financial Model", titleWidth = 300),
  
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      menuItem("Revenue Model", tabName = "revenue", icon = icon("chart-line")),
      menuItem("Cost Analysis", tabName = "costs", icon = icon("coins")),
      menuItem("DCF Valuation", tabName = "dcf", icon = icon("calculator")),
      menuItem("Monte Carlo Sim", tabName = "montecarlo", icon = icon("dice"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML(css))
    ),
    
    tabItems(
      # Revenue Model Tab
      tabItem(tabName = "revenue",
              fluidRow(
                box(
                  title = "Revenue Parameters", status = "primary", solidHeader = TRUE,
                  width = 4, height = 500,
                  numericInput("initial_customers", "Initial Customers", value = 100, min = 1),
                  numericInput("monthly_growth", "Monthly Growth Rate (%)", value = 15, min = 0, max = 100),
                  numericInput("avg_revenue_per_user", "ARPU (Monthly)", value = 50, min = 1),
                  numericInput("churn_rate", "Monthly Churn Rate (%)", value = 5, min = 0, max = 50),
                  numericInput("price_increase", "Annual Price Increase (%)", value = 5, min = 0, max = 30),
                  br(),
                  h4("Customer Acquisition"),
                  numericInput("cac", "Customer Acquisition Cost", value = 75, min = 0),
                  numericInput("cac_trend", "CAC Annual Increase (%)", value = 10, min = 0, max = 50)
                ),
                
                box(
                  title = "Revenue Projections (5 Years)", status = "primary", solidHeader = TRUE,
                  width = 8, height = 500,
                  withSpinner(plotlyOutput("revenue_plot", height = "350px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Key Metrics Dashboard", status = "info", solidHeader = TRUE,
                  width = 6,
                  withSpinner(DT::dataTableOutput("revenue_metrics"))
                ),
                
                box(
                  title = "Unit Economics", status = "info", solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("unit_economics_plot"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Academic References", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
            <h4>References:</h4>
            <p><strong>Forecastr</strong> (2024). <em>Financial Modeling Spreadsheet Templates for Startups</em>. Available at: https://www.forecastr.co/templates (Accessed: 16 September 2025).</p>
            <p><strong>Slidebean</strong> (2024). <em>A FREE Startup Financial Model Template</em>. Available at: https://slidebean.com/free-startup-financial-model-template (Accessed: 16 September 2025).</p>
            <p><strong>EY Netherlands</strong> (2025). <em>The ultimate guide to financial modeling for startups</em>. Available at: https://www.ey.com/en_nl/services/finance-navigator/the-ultimate-guide-to-financial-modeling-for-startups (Accessed: 16 September 2025).</p>
            ")
                )
              )
      ),
      
      # Cost Analysis Tab
      tabItem(tabName = "costs",
              fluidRow(
                box(
                  title = "Operating Expenses", status = "primary", solidHeader = TRUE,
                  width = 4, height = 550,
                  h4("Personnel Costs"),
                  numericInput("initial_headcount", "Initial Headcount", value = 10, min = 1),
                  numericInput("avg_salary", "Average Annual Salary", value = 75000, min = 30000),
                  numericInput("headcount_growth", "Monthly Headcount Growth (%)", value = 8, min = 0, max = 50),
                  numericInput("salary_inflation", "Annual Salary Inflation (%)", value = 4, min = 0, max = 15),
                  
                  br(),
                  h4("Other Operating Costs"),
                  numericInput("office_rent", "Monthly Office Rent", value = 15000, min = 0),
                  numericInput("marketing_budget", "Monthly Marketing Budget", value = 25000, min = 0),
                  numericInput("tech_infrastructure", "Monthly Tech Costs", value = 8000, min = 0),
                  numericInput("other_opex", "Other Monthly OpEx", value = 12000, min = 0)
                ),
                
                box(
                  title = "Cost Structure Analysis", status = "primary", solidHeader = TRUE,
                  width = 8, height = 550,
                  withSpinner(plotlyOutput("cost_breakdown_plot", height = "400px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Cost Projections", status = "info", solidHeader = TRUE,
                  width = 6,
                  withSpinner(DT::dataTableOutput("cost_table"))
                ),
                
                box(
                  title = "Revenue vs Costs", status = "info", solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("revenue_cost_comparison"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Academic References", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
            <h4>References:</h4>
            <p><strong>Zeni</strong> (2024). <em>Free Startup Financial Model Template: Excel/Sheets Download</em>. Available at: https://www.zeni.ai/template/startup-financial-model-template (Accessed: 16 September 2025).</p>
            <p><strong>HubSpot</strong> (2024). <em>How To Create Startup Financial Projections [+Template]</em>. Available at: https://www.hubspot.com/startups/fundraising/startup-financial-projections-template/ (Accessed: 16 September 2025).</p>
            <p><strong>Ramp</strong> (2024). <em>Startup financial model overview and free template</em>. Available at: https://ramp.com/tools/startup-financial-model (Accessed: 16 September 2025).</p>
            ")
                )
              )
      ),
      
      # DCF Valuation Tab
      tabItem(tabName = "dcf",
              fluidRow(
                box(
                  title = "Valuation Parameters", status = "primary", solidHeader = TRUE,
                  width = 4, height = 600,
                  h4("Discount Rate Components"),
                  numericInput("risk_free_rate", "Risk-Free Rate (%)", value = 2.5, min = 0, max = 10, step = 0.1),
                  numericInput("market_risk_premium", "Market Risk Premium (%)", value = 6, min = 0, max = 15, step = 0.1),
                  numericInput("beta", "Beta", value = 1.5, min = 0.5, max = 3, step = 0.1),
                  numericInput("company_risk_premium", "Company Risk Premium (%)", value = 5, min = 0, max = 20, step = 0.5),
                  
                  br(),
                  h4("Terminal Value"),
                  numericInput("terminal_growth", "Terminal Growth Rate (%)", value = 2.5, min = 0, max = 5, step = 0.1),
                  numericInput("exit_multiple", "Exit Revenue Multiple", value = 8, min = 1, max = 20, step = 0.5),
                  
                  br(),
                  h4("Projection Horizon"),
                  sliderInput("projection_years", "Projection Years", min = 5, max = 10, value = 5, step = 1),
                  
                  br(),
                  actionButton("calculate_dcf", "Calculate Valuation", class = "btn-primary", style = "width: 100%;")
                ),
                
                box(
                  title = "DCF Valuation Results", status = "primary", solidHeader = TRUE,
                  width = 8, height = 600,
                  withSpinner(plotlyOutput("dcf_waterfall", height = "250px")),
                  br(),
                  withSpinner(DT::dataTableOutput("dcf_table"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Sensitivity Analysis", status = "info", solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("sensitivity_heatmap"))
                ),
                
                box(
                  title = "Exit Scenarios", status = "info", solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("exit_scenarios"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Academic References", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
            <h4>References:</h4>
            <p><strong>Shestopalov, I.</strong> (2022). <em>Integrating Monte Carlo Simulation into DCF Modeling</em>. Medium. Available at: https://medium.com/@igorshestopalov/integrating-monte-carlo-simulation-into-dcf-modeling-131784fa7db (Accessed: 16 September 2025).</p>
            <p><strong>Cole, A.</strong> (2021). <em>Automating the DCF Valuation: Using a Monte Carlo Simulation to forecast Financials</em>. Medium. Available at: https://medium.com/data-science/automating-the-dcf-valuation-35abde04cdb9 (Accessed: 16 September 2025).</p>
            <p><strong>CBS Research Portal</strong> (2023). <em>Increased Transparency in Valuation: Extending the DCF Model with Monte Carlo Simulation</em>. Available at: https://research.cbs.dk/en/studentProjects/9b490b45-80d0-44f0-87e5-208203c37e41 (Accessed: 16 September 2025).</p>
            ")
                )
              )
      ),
      
      # Monte Carlo Simulation Tab
      tabItem(tabName = "montecarlo",
              fluidRow(
                box(
                  title = "Simulation Parameters", status = "primary", solidHeader = TRUE,
                  width = 4, height = 750,  # Increased height to accommodate button
                  numericInput("num_simulations", "Number of Simulations", value = 10000, min = 1000, max = 50000, step = 1000),
                  
                  h4("Revenue Uncertainty"),
                  numericInput("growth_volatility", "Growth Rate Volatility (%)", value = 25, min = 5, max = 100),
                  numericInput("arpu_volatility", "ARPU Volatility (%)", value = 15, min = 5, max = 50),
                  
                  h4("Cost Uncertainty"),
                  numericInput("salary_volatility", "Salary Volatility (%)", value = 10, min = 5, max = 30),
                  numericInput("opex_volatility", "OpEx Volatility (%)", value = 20, min = 5, max = 50),
                  
                  h4("Market Uncertainty"),
                  numericInput("discount_volatility", "Discount Rate Volatility (%)", value = 15, min = 5, max = 50),
                  numericInput("exit_multiple_volatility", "Exit Multiple Volatility (%)", value = 30, min = 10, max = 80),
                  
                  br(),
                  # Run Monte Carlo Button
                  actionButton("run_simulation", "Run Monte Carlo", 
                               class = "btn-danger", 
                               style = "width: 100%; padding: 10px; font-size: 14px; font-weight: bold;"),
                  
                  br(), br(),
                  h4("Confidence Intervals"),
                  verbatimTextOutput("confidence_intervals")
                ),
                
                box(
                  title = "Valuation Distribution", status = "primary", solidHeader = TRUE,
                  width = 8, height = 750,  # Increased height to match
                  withSpinner(plotlyOutput("valuation_distribution", height = "300px")),
                  br(),
                  withSpinner(plotlyOutput("scenario_analysis", height = "300px"))  # Increased height
                )
              ),
              
              fluidRow(
                box(
                  title = "Risk Metrics", status = "info", solidHeader = TRUE,
                  width = 6,
                  withSpinner(DT::dataTableOutput("risk_metrics"))
                ),
                
                box(
                  title = "Correlation Analysis", status = "info", solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("correlation_matrix"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Academic References", status = "warning", solidHeader = TRUE,
                  width = 12, class = "reference-box",
                  HTML("
      <h4>References:</h4>
      <p><strong>Toptal</strong> (2018). <em>Comprehensive Monte Carlo Simulation Tutorial</em>. Available at: https://www.toptal.com/finance/financial-forecasting/monte-carlo-simulation (Accessed: 16 September 2025).</p>
      <p><strong>Private Equity Bro</strong> (2025). <em>Monte Carlo Simulations in M&A and Private Equity</em>. Available at: https://privateequitybro.com/monte-carlo-simulations-in-ma-and-private-equity/ (Accessed: 16 September 2025).</p>
      <p><strong>WIPO</strong> (2025). <em>Intellectual Property Valuation Basics for Technology Transfer Professionals - Monte Carlo simulation</em>. Available at: https://www.wipo.int/web-publications/intellectual-property-valuation-basics-for-technology-transfer-professionals/en/8-monte-carlo-simulations.html (Accessed: 16 September 2025).</p>
      <p><strong>ScienceDirect</strong> (2007). <em>Real Options and Monte Carlo Simulation versus Traditional DCF Valuation in Layman's Terms</em>. Available at: https://www.sciencedirect.com/science/article/abs/pii/B9780080449494500398 (Accessed: 16 September 2025).</p>
      ")
                )
              )
      )
    )
  )
)

# Define Server Logic
server <- function(input, output, session) {
  
  # Reactive values for storing data
  values <- reactiveValues(
    revenue_data = NULL,
    cost_data = NULL,
    dcf_results = NULL,
    monte_carlo_results = NULL
  )
  
  # Revenue Model Calculations
  observe({
    years <- 1:60  # 5 years monthly
    customers <- numeric(60)
    revenue <- numeric(60)
    cac_costs <- numeric(60)
    
    customers[1] <- input$initial_customers
    current_arpu <- input$avg_revenue_per_user
    current_cac <- input$cac
    
    for(i in 2:60) {
      # Customer growth with churn
      new_customers <- customers[i-1] * (input$monthly_growth/100)
      churned_customers <- customers[i-1] * (input$churn_rate/100)
      customers[i] <- customers[i-1] + new_customers - churned_customers
      
      # Annual price increases
      if(i %% 12 == 1 && i > 1) {
        current_arpu <- current_arpu * (1 + input$price_increase/100)
        current_cac <- current_cac * (1 + input$cac_trend/100)
      }
      
      revenue[i] <- customers[i] * current_arpu
      cac_costs[i] <- new_customers * current_cac
    }
    
    values$revenue_data <- data.frame(
      Month = years,
      Year = ceiling(years/12),
      Customers = customers,
      Revenue = revenue,
      CAC_Costs = cac_costs,
      ARPU = rep(current_arpu, 60),
      LTV = (current_arpu * 12) / (input$churn_rate/100)
    )
  })
  
  # Cost Model Calculations
  observe({
    years <- 1:60
    headcount <- numeric(60)
    personnel_costs <- numeric(60)
    total_costs <- numeric(60)
    
    headcount[1] <- input$initial_headcount
    current_salary <- input$avg_salary
    
    for(i in 2:60) {
      headcount[i] <- headcount[i-1] * (1 + input$headcount_growth/100)
      
      if(i %% 12 == 1 && i > 1) {
        current_salary <- current_salary * (1 + input$salary_inflation/100)
      }
      
      personnel_costs[i] <- headcount[i] * current_salary / 12
      other_costs <- input$office_rent + input$marketing_budget + 
        input$tech_infrastructure + input$other_opex
      total_costs[i] <- personnel_costs[i] + other_costs
    }
    
    values$cost_data <- data.frame(
      Month = years,
      Year = ceiling(years/12),
      Headcount = headcount,
      Personnel_Costs = personnel_costs,
      Other_Costs = rep(input$office_rent + input$marketing_budget + 
                          input$tech_infrastructure + input$other_opex, 60),
      Total_Costs = total_costs
    )
  })
  
  # Revenue Plot
  output$revenue_plot <- renderPlotly({
    req(values$revenue_data)
    
    annual_data <- values$revenue_data %>%
      group_by(Year) %>%
      summarise(
        Annual_Revenue = sum(Revenue),
        End_Customers = last(Customers),
        Total_CAC = sum(CAC_Costs)
      )
    
    p <- ggplot(annual_data, aes(x = Year)) +
      geom_bar(aes(y = Annual_Revenue/1000), stat = "identity", 
               fill = "#667eea", alpha = 0.7) +
      geom_line(aes(y = End_Customers*100), color = "#764ba2", size = 2) +
      scale_y_continuous(
        name = "Annual Revenue (K$)",
        sec.axis = sec_axis(~./100, name = "Customers")
      ) +
      labs(title = "Revenue Growth & Customer Acquisition",
           x = "Year") +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, size = 16),
        axis.title = element_text(size = 12)
      )
    
    ggplotly(p) %>%
      layout(showlegend = FALSE)
  })
  
  # Revenue Metrics Table
  output$revenue_metrics <- DT::renderDataTable({
    req(values$revenue_data)
    
    annual_summary <- values$revenue_data %>%
      group_by(Year) %>%
      summarise(
        `Revenue ($K)` = round(sum(Revenue)/1000, 0),
        `Customers` = round(last(Customers), 0),
        `ARPU ($)` = round(last(ARPU), 0),
        `CAC ($)` = round(mean(CAC_Costs/pmax(1, diff(c(0, Customers)))), 0),
        `LTV ($)` = round(last(LTV), 0),
        `LTV/CAC` = round(last(LTV) / round(mean(CAC_Costs/pmax(1, diff(c(0, Customers)))), 0), 1)
      )
    
    DT::datatable(annual_summary, 
                  options = list(pageLength = 10, searching = FALSE),
                  rownames = FALSE) %>%
      formatStyle(columns = 1:7, backgroundColor = "#f8f9fa")
  })
  
  # Unit Economics Plot
  output$unit_economics_plot <- renderPlotly({
    req(values$revenue_data)
    
    metrics_data <- data.frame(
      Metric = c("ARPU", "CAC", "LTV"),
      Value = c(input$avg_revenue_per_user, input$cac, 
                input$avg_revenue_per_user * 12 / (input$churn_rate/100)),
      Color = c("#667eea", "#e74c3c", "#2ecc71")
    )
    
    p <- ggplot(metrics_data, aes(x = Metric, y = Value, fill = Color)) +
      geom_bar(stat = "identity", alpha = 0.8) +
      scale_fill_identity() +
      labs(title = "Unit Economics", y = "Value ($)") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, size = 14))
    
    ggplotly(p) %>%
      layout(showlegend = FALSE)
  })
  
  # Cost Breakdown Plot
  output$cost_breakdown_plot <- renderPlotly({
    req(values$cost_data)
    
    annual_costs <- values$cost_data %>%
      group_by(Year) %>%
      summarise(
        Personnel = sum(Personnel_Costs)/1000,
        Other_OpEx = sum(Other_Costs)/1000,
        Total = sum(Total_Costs)/1000
      ) %>%
      tidyr::pivot_longer(cols = c(Personnel, Other_OpEx), 
                          names_to = "Cost_Type", values_to = "Amount")
    
    p <- ggplot(annual_costs, aes(x = Year, y = Amount, fill = Cost_Type)) +
      geom_bar(stat = "identity", position = "stack") +
      scale_fill_manual(values = c("#667eea", "#764ba2")) +
      labs(title = "Annual Cost Breakdown", 
           y = "Cost ($K)", x = "Year", fill = "Cost Type") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, size = 14))
    
    ggplotly(p)
  })
  
  # Cost Table
  output$cost_table <- DT::renderDataTable({
    req(values$cost_data)
    
    cost_summary <- values$cost_data %>%
      group_by(Year) %>%
      summarise(
        `Headcount` = round(last(Headcount), 0),
        `Personnel ($K)` = round(sum(Personnel_Costs)/1000, 0),
        `Other OpEx ($K)` = round(sum(Other_Costs)/1000, 0),
        `Total Costs ($K)` = round(sum(Total_Costs)/1000, 0),
        `Cost per Employee ($K)` = round(sum(Total_Costs)/last(Headcount)/1000, 0)
      )
    
    DT::datatable(cost_summary,
                  options = list(pageLength = 10, searching = FALSE),
                  rownames = FALSE) %>%
      formatStyle(columns = 1:6, backgroundColor = "#f8f9fa")
  })
  
  # Revenue vs Costs Comparison
  output$revenue_cost_comparison <- renderPlotly({
    req(values$revenue_data, values$cost_data)
    
    combined_data <- values$revenue_data %>%
      left_join(values$cost_data, by = c("Month", "Year")) %>%
      group_by(Year) %>%
      summarise(
        Revenue = sum(Revenue)/1000,
        Costs = sum(Total_Costs)/1000,
        Profit = Revenue - Costs
      ) %>%
      tidyr::pivot_longer(cols = c(Revenue, Costs, Profit),
                          names_to = "Type", values_to = "Amount")
    
    p <- ggplot(combined_data, aes(x = Year, y = Amount, color = Type)) +
      geom_line(size = 2) +
      geom_point(size = 3) +
      scale_color_manual(values = c("#2ecc71", "#e74c3c", "#667eea")) +
      labs(title = "Revenue vs Costs Analysis", 
           y = "Amount ($K)", x = "Year") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, size = 14))
    
    ggplotly(p)
  })
  
  # DCF Calculation - Fixed to auto-calculate when data is available
  observe({
    req(values$revenue_data, values$cost_data)
    
    # Calculate WACC
    wacc <- input$risk_free_rate + input$beta * input$market_risk_premium + 
      input$company_risk_premium
    
    # Prepare annual cash flows
    years <- 1:input$projection_years
    annual_revenue <- sapply(years, function(y) {
      if(y <= 5) {
        sum(values$revenue_data$Revenue[values$revenue_data$Year == y])
      } else {
        # Extrapolate for years beyond 5
        last_revenue <- sum(values$revenue_data$Revenue[values$revenue_data$Year == 5])
        last_revenue * (1.1)^(y-5)
      }
    })
    annual_costs <- sapply(years, function(y) {
      if(y <= 5) {
        sum(values$cost_data$Total_Costs[values$cost_data$Year == y])
      } else {
        # Extrapolate for years beyond 5
        last_cost <- sum(values$cost_data$Total_Costs[values$cost_data$Year == 5])
        last_cost * (1.08)^(y-5)  # Assume 8% cost inflation
      }
    })
    
    free_cash_flow <- annual_revenue - annual_costs
    
    # Terminal value calculation
    terminal_fcf <- free_cash_flow[length(free_cash_flow)] * (1 + input$terminal_growth/100)
    terminal_value <- terminal_fcf / (wacc/100 - input$terminal_growth/100)
    
    # Discount factors
    discount_factors <- (1 + wacc/100)^(-years)
    terminal_discount <- (1 + wacc/100)^(-input$projection_years)
    
    # Present values
    pv_fcf <- free_cash_flow * discount_factors
    pv_terminal <- terminal_value * terminal_discount
    
    enterprise_value <- sum(pv_fcf) + pv_terminal
    
    # Exit scenario based on revenue multiple
    exit_revenue <- annual_revenue[length(annual_revenue)]
    exit_value_multiple <- exit_revenue * input$exit_multiple
    
    values$dcf_results <- data.frame(
      Year = years,
      Revenue = annual_revenue,
      Costs = annual_costs,
      FCF = free_cash_flow,
      PV_FCF = pv_fcf,
      WACC = wacc,
      Enterprise_Value = enterprise_value,
      Exit_Multiple_Value = exit_value_multiple,
      Terminal_Value = terminal_value
    )
  })
  
  # DCF Waterfall Chart
  output$dcf_waterfall <- renderPlotly({
    req(values$dcf_results)
    
    waterfall_data <- data.frame(
      Component = c("PV of FCF", "Terminal Value", "Enterprise Value"),
      Value = c(sum(values$dcf_results$PV_FCF), 
                values$dcf_results$Terminal_Value[1],
                values$dcf_results$Enterprise_Value[1])
    )
    
    p <- ggplot(waterfall_data, aes(x = Component, y = Value/1e6)) +
      geom_bar(stat = "identity", fill = "#667eea", alpha = 0.8) +
      labs(title = "DCF Valuation Waterfall", 
           y = "Value ($M)", x = "") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, size = 14),
            axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # DCF Results Table
  output$dcf_table <- DT::renderDataTable({
    req(values$dcf_results)
    
    dcf_display <- values$dcf_results %>%
      select(Year, `Revenue ($K)` = Revenue, `Costs ($K)` = Costs, 
             `FCF ($K)` = FCF, `PV FCF ($K)` = PV_FCF) %>%
      mutate(across(2:5, ~ round(./1000, 0)))
    
    DT::datatable(dcf_display,
                  options = list(pageLength = 10, searching = FALSE),
                  rownames = FALSE) %>%
      formatStyle(columns = 1:5, backgroundColor = "#f8f9fa")
  })
  
  # Sensitivity Analysis Heatmap
  # Sensitivity Analysis Heatmap
  output$sensitivity_heatmap <- renderPlotly({
    req(values$dcf_results)
    
    base_ev <- values$dcf_results$Enterprise_Value[1]
    growth_rates <- seq(-1.5, 1.5, 0.3)  # Reduced range to avoid extreme values
    wacc_rates <- seq(-1.5, 1.5, 0.3)    # Reduced range to avoid extreme values
    
    # Create empty matrix
    sensitivity_matrix <- matrix(NA, nrow = length(growth_rates), ncol = length(wacc_rates))
    
    # Fill matrix with careful error handling
    for(i in 1:length(growth_rates)) {
      for(j in 1:length(wacc_rates)) {
        adjusted_growth <- input$terminal_growth + growth_rates[i]
        adjusted_wacc <- values$dcf_results$WACC[1] + wacc_rates[j]
        
        # Only calculate if mathematically valid
        if(adjusted_wacc > adjusted_growth + 0.5 && adjusted_wacc > 1 && adjusted_growth >= 0) {
          tryCatch({
            terminal_fcf <- values$dcf_results$FCF[length(values$dcf_results$FCF)] * 
              (1 + adjusted_growth/100)
            terminal_value <- terminal_fcf / (adjusted_wacc/100 - adjusted_growth/100)
            
            pv_terminal <- terminal_value / (1 + adjusted_wacc/100)^input$projection_years
            new_ev <- sum(values$dcf_results$PV_FCF) + pv_terminal
            
            sensitivity_matrix[i, j] <- (new_ev - base_ev) / base_ev * 100
          }, error = function(e) {
            sensitivity_matrix[i, j] <<- NA
          })
        }
      }
    }
    
    # Cap extreme values for better visualization
    sensitivity_matrix[sensitivity_matrix > 200] <- 200
    sensitivity_matrix[sensitivity_matrix < -200] <- -200
    
    plot_ly(z = sensitivity_matrix, type = "heatmap",
            x = wacc_rates, y = growth_rates,
            colorscale = "RdYlBu",
            hovertemplate = "WACC Change: %{x}%<br>Growth Change: %{y}%<br>EV Change: %{z:.1f}%<extra></extra>") %>%
      layout(title = "Sensitivity Analysis (% Change in EV)",
             xaxis = list(title = "WACC Change (%)"),
             yaxis = list(title = "Growth Rate Change (%)"))
  })
  
  # Exit Scenarios Plot
  output$exit_scenarios <- renderPlotly({
    req(values$dcf_results)
    
    multiples <- seq(4, 16, 2)
    if(length(values$dcf_results$Revenue) >= 5) {
      exit_year_5_revenue <- values$dcf_results$Revenue[5]
    } else {
      exit_year_5_revenue <- values$dcf_results$Revenue[length(values$dcf_results$Revenue)]
    }
    exit_values <- exit_year_5_revenue * multiples / 1e6
    
    scenarios_data <- data.frame(
      Multiple = multiples,
      Exit_Value = exit_values,
      Scenario = c("Conservative", "Base Case", "Optimistic", "Aggressive", 
                   "Unicorn", "Decacorn", "Mega")
    )
    
    p <- ggplot(scenarios_data, aes(x = Multiple, y = Exit_Value, fill = Scenario)) +
      geom_bar(stat = "identity", alpha = 0.8) +
      scale_fill_viridis_d() +
      labs(title = "Exit Valuation Scenarios (Year 5)", 
           x = "Revenue Multiple", y = "Exit Value ($M)") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, size = 14))
    
    ggplotly(p)
  })
  
  # Monte Carlo Simulation
  observeEvent(input$run_simulation, {
    req(values$revenue_data, values$cost_data)
    
    n_sims <- input$num_simulations
    results <- matrix(0, nrow = n_sims, ncol = 8)
    colnames(results) <- c("Revenue_Y5", "Costs_Y5", "FCF_Y5", "WACC", 
                           "Terminal_Growth", "Exit_Multiple", "DCF_Value", "Exit_Value")
    
    withProgress(message = 'Running Monte Carlo Simulation...', value = 0, {
      for(i in 1:n_sims) {
        # Random parameters
        growth_shock <- rnorm(1, 0, input$growth_volatility/100)
        arpu_shock <- rnorm(1, 0, input$arpu_volatility/100)
        salary_shock <- rnorm(1, 0, input$salary_volatility/100)
        opex_shock <- rnorm(1, 0, input$opex_volatility/100)
        wacc_shock <- rnorm(1, 0, input$discount_volatility/100)
        exit_shock <- rnorm(1, 0, input$exit_multiple_volatility/100)
        
        # Adjusted parameters
        adj_monthly_growth <- input$monthly_growth * (1 + growth_shock)
        adj_arpu <- input$avg_revenue_per_user * (1 + arpu_shock)
        adj_salary <- input$avg_salary * (1 + salary_shock)
        adj_opex_multiplier <- 1 + opex_shock
        
        # Simulate 5-year revenue
        customers_sim <- input$initial_customers
        revenue_y5 <- 0
        costs_y5 <- 0
        
        for(year in 1:5) {
          for(month in 1:12) {
            customers_sim <- customers_sim * (1 + adj_monthly_growth/100) * 
              (1 - input$churn_rate/100)
            monthly_revenue <- customers_sim * adj_arpu
            revenue_y5 <- revenue_y5 + monthly_revenue
            
            # Costs simulation
            headcount_month <- input$initial_headcount * 
              (1 + input$headcount_growth/100)^((year-1)*12 + month)
            monthly_personnel <- headcount_month * adj_salary / 12
            monthly_other <- (input$office_rent + input$marketing_budget + 
                                input$tech_infrastructure + input$other_opex) * adj_opex_multiplier
            costs_y5 <- costs_y5 + monthly_personnel + monthly_other
          }
        }
        
        fcf_y5 <- revenue_y5 - costs_y5
        
        # Valuation calculations
        adj_wacc <- (input$risk_free_rate + input$beta * input$market_risk_premium + 
                       input$company_risk_premium) * (1 + wacc_shock)
        adj_terminal_growth <- input$terminal_growth
        adj_exit_multiple <- input$exit_multiple * (1 + exit_shock)
        
        # Simple DCF calculation with error handling
        if(adj_wacc > adj_terminal_growth && adj_wacc > 0) {
          terminal_value <- fcf_y5 * (1 + adj_terminal_growth/100) / 
            (adj_wacc/100 - adj_terminal_growth/100)
          dcf_value <- fcf_y5 + terminal_value / (1 + adj_wacc/100)^5
        } else {
          dcf_value <- fcf_y5 * 10  # Fallback value
        }
        
        exit_value <- revenue_y5 * adj_exit_multiple
        
        results[i, ] <- c(revenue_y5, costs_y5, fcf_y5, adj_wacc, 
                          adj_terminal_growth, adj_exit_multiple, dcf_value, exit_value)
        
        if(i %% 1000 == 0) {
          incProgress(0.1, detail = paste("Simulation", i, "of", n_sims))
        }
      }
    })
    
    values$monte_carlo_results <- as.data.frame(results)
  })
  
  # Confidence Intervals Output
  output$confidence_intervals <- renderText({
    req(values$monte_carlo_results)
    
    dcf_percentiles <- quantile(values$monte_carlo_results$DCF_Value, 
                                c(0.05, 0.25, 0.5, 0.75, 0.95), na.rm = TRUE)
    exit_percentiles <- quantile(values$monte_carlo_results$Exit_Value, 
                                 c(0.05, 0.25, 0.5, 0.75, 0.95), na.rm = TRUE)
    
    paste0(
      "DCF Valuation:\n",
      "95% CI: $", round(dcf_percentiles[1]/1e6, 1), "M - $", round(dcf_percentiles[5]/1e6, 1), "M\n",
      "Median: $", round(dcf_percentiles[3]/1e6, 1), "M\n\n",
      "Exit Valuation:\n",
      "95% CI: $", round(exit_percentiles[1]/1e6, 1), "M - $", round(exit_percentiles[5]/1e6, 1), "M\n",
      "Median: $", round(exit_percentiles[3]/1e6, 1), "M"
    )
  })
  
  # Valuation Distribution Plot
  output$valuation_distribution <- renderPlotly({
    req(values$monte_carlo_results)
    
    # Remove extreme outliers for better visualization
    dcf_clean <- values$monte_carlo_results$DCF_Value[values$monte_carlo_results$DCF_Value > 0 & 
                                                        values$monte_carlo_results$DCF_Value < quantile(values$monte_carlo_results$DCF_Value, 0.99, na.rm = TRUE)]
    exit_clean <- values$monte_carlo_results$Exit_Value[values$monte_carlo_results$Exit_Value > 0 &
                                                          values$monte_carlo_results$Exit_Value < quantile(values$monte_carlo_results$Exit_Value, 0.99, na.rm = TRUE)]
    
    dist_data <- data.frame(
      Value = c(dcf_clean / 1e6, exit_clean / 1e6),
      Method = c(rep("DCF", length(dcf_clean)), rep("Exit", length(exit_clean)))
    )
    
    p <- ggplot(dist_data, aes(x = Value, fill = Method)) +
      geom_histogram(alpha = 0.7, bins = 50, position = "identity") +
      scale_fill_manual(values = c("#667eea", "#764ba2")) +
      labs(title = "Valuation Distribution", 
           x = "Valuation ($M)", y = "Frequency") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, size = 14))
    
    ggplotly(p)
  })
  
  # Scenario Analysis Plot
  output$scenario_analysis <- renderPlotly({
    req(values$monte_carlo_results)
    
    scenarios <- data.frame(
      Percentile = c("P10", "P25", "P50", "P75", "P90"),
      DCF = quantile(values$monte_carlo_results$DCF_Value, c(0.1, 0.25, 0.5, 0.75, 0.9), na.rm = TRUE)/1e6,
      Exit = quantile(values$monte_carlo_results$Exit_Value, c(0.1, 0.25, 0.5, 0.75, 0.9), na.rm = TRUE)/1e6
    ) %>%
      tidyr::pivot_longer(cols = c(DCF, Exit), names_to = "Method", values_to = "Value")
    
    p <- ggplot(scenarios, aes(x = Percentile, y = Value, color = Method, group = Method)) +
      geom_line(size = 2) +
      geom_point(size = 4) +
      scale_color_manual(values = c("#667eea", "#764ba2")) +
      labs(title = "Scenario Analysis", 
           x = "Probability Percentile", y = "Valuation ($M)") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, size = 14))
    
    ggplotly(p)
  })
  
  # Risk Metrics Table
  output$risk_metrics <- DT::renderDataTable({
    req(values$monte_carlo_results)
    
    risk_stats <- data.frame(
      Metric = c("Mean DCF ($M)", "Std Dev DCF ($M)", "VaR 5% DCF ($M)", 
                 "Mean Exit ($M)", "Std Dev Exit ($M)", "VaR 5% Exit ($M)",
                 "Probability DCF > $50M", "Probability Exit > $100M"),
      Value = c(
        round(mean(values$monte_carlo_results$DCF_Value, na.rm = TRUE)/1e6, 1),
        round(sd(values$monte_carlo_results$DCF_Value, na.rm = TRUE)/1e6, 1),
        round(quantile(values$monte_carlo_results$DCF_Value, 0.05, na.rm = TRUE)/1e6, 1),
        round(mean(values$monte_carlo_results$Exit_Value, na.rm = TRUE)/1e6, 1),
        round(sd(values$monte_carlo_results$Exit_Value, na.rm = TRUE)/1e6, 1),
        round(quantile(values$monte_carlo_results$Exit_Value, 0.05, na.rm = TRUE)/1e6, 1),
        paste0(round(mean(values$monte_carlo_results$DCF_Value > 50e6, na.rm = TRUE) * 100, 1), "%"),
        paste0(round(mean(values$monte_carlo_results$Exit_Value > 100e6, na.rm = TRUE) * 100, 1), "%")
      )
    )
    
    DT::datatable(risk_stats,
                  options = list(pageLength = 10, searching = FALSE, paging = FALSE),
                  rownames = FALSE) %>%
      formatStyle(columns = 1:2, backgroundColor = "#f8f9fa")
  })
  
  # Correlation Matrix
  output$correlation_matrix <- renderPlotly({
    req(values$monte_carlo_results)
    
    cor_data <- values$monte_carlo_results %>%
      select(Revenue_Y5, Costs_Y5, WACC, Exit_Multiple, DCF_Value, Exit_Value) %>%
      na.omit()
    
    cor_matrix <- cor(cor_data)
    
    plot_ly(z = cor_matrix, type = "heatmap",
            x = colnames(cor_matrix), y = colnames(cor_matrix),
            colorscale = list(c(0, "red"), c(0.5, "white"), c(1, "blue"))) %>%
      layout(title = "Variable Correlation Matrix",
             xaxis = list(title = ""),
             yaxis = list(title = ""))
  })
}

# Run the application
shinyApp(ui = ui, server = server)