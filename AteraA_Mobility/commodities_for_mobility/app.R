# Load required libraries (NO TERRA)
library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(ggplot2)
library(networkD3)
library(timevis)
library(visNetwork)

# Define UI (same as before)
ui <- dashboardPage(title = "Commodities for Mobility",
                    skin = "blue",
                    dashboardHeader(
                      title = div(
                        img(src = "logo.jpeg", height = "40px", style = "margin-right: 10px;"),
                        "Commodities - Mobility Trading Intelligence"
                      )
                    ),
                    
                    dashboardSidebar(
                      width = 280,
                      sidebarMenu(
                        menuItem("Electric Energy Markets", tabName = "electric", icon = icon("bolt")),
                        menuItem("Hydrocarbons Trading", tabName = "hydrocarbons", icon = icon("oil-can")),
                        menuItem("Battery Materials", tabName = "battery", icon = icon("battery-half")),
                        menuItem("Critical Metals", tabName = "metals", icon = icon("industry")),
                        menuItem("AI Hedging & FX", tabName = "forex", icon = icon("chart-line")),
                        menuItem("Strategic Alignment", tabName = "company", icon = icon("building"))
                      )
                    ),
                    
                    dashboardBody(
                      tags$head(
                        tags$style(HTML("
        .skin-blue .main-header .navbar {
          background-color: #008A82 !important;
        }
        
        .skin-blue .main-header .logo {
          background-color: #002C3C !important;
        }
        
        .skin-blue .main-header .logo:hover {
          background-color: #008A82 !important;
        }
        
        .skin-blue .main-sidebar {
          background-color: #00A39A !important;
        }
        
        .skin-blue .sidebar-menu > li.header {
          background: #008A82 !important;
          color: white !important;
        }
        
        .skin-blue .sidebar-menu > li > a {
          color: white !important;
        }
        
        .skin-blue .sidebar-menu > li:hover > a,
        .skin-blue .sidebar-menu > li.active > a {
          background-color: #008A82 !important;
          color: white !important;
        }
        
        .content-wrapper, .right-side {
          background-color: #002C3C !important;
        }
        
        .box {
          background: #00A39A !important;
          border-top: none !important;
          color: white !important;
        }
        
        .box-header {
          background: #00A39A !important;
          color: white !important;
        }
        
        .box-body {
          background: white !important;
          color: #2c3e50 !important;
        }
        
        .box-title {
          color: white !important;
        }
        
        .metric-box {
          background: white;
          border-radius: 8px;
          padding: 15px;
          margin: 10px 0;
          border-left: 4px solid #00A39A;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          color: #2c3e50 !important;
        }
        
        .network-container {
          height: 600px;
          border: 1px solid #ddd;
          border-radius: 8px;
          background: white;
        }
        
        .form-control {
          background-color: rgba(255,255,255,0.9) !important;
          border: 1px solid #bdc3c7 !important;
          color: #2c3e50 !important;
        }
        
        .form-control:focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 0.2rem rgba(0, 163, 154, 0.25) !important;
        }
        
        .reference-box {
          background: #f8f9fa;
          border: 1px solid #dee2e6;
          border-radius: 8px;
          padding: 15px;
          margin: 20px 0;
          font-size: 0.9em;
          color: #495057;
        }
        
        .reference-box h5 {
          color: #00A39A;
          margin-bottom: 10px;
          font-weight: bold;
        }
      "))
                      ),
                      
                      tabItems(
                        # Electric Energy Tab
                        tabItem(tabName = "electric",
                                fluidRow(
                                  box(
                                    title = "Get In Contact with Atera Analytics", status = "primary", solidHeader = TRUE, width = 12,
                                    div(class = "metric-box",
                                        p("For a full demo of this application on Commodities Modelling in Trading Get In Touch via atera-analytics.co.uk", 
                                          style = "font-size: 14px; margin: 0;")
                                    )
                                  )
                                ),
                                fluidRow(
                                  box(
                                    title = "Electric Energy Markets Intelligence", status = "primary", solidHeader = TRUE, width = 12,
                                    div(class = "metric-box",
                                        p("Advanced real-time analytics for EV charging infrastructure, smart grid optimization, and renewable energy integration. Dynamic pricing models and grid congestion arbitrage opportunities driven by IoT telemetry and machine learning forecasting algorithms.", 
                                          style = "font-size: 14px; margin: 0;")
                                    )
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "UK Regional EV Demand Heatmap", status = "primary", solidHeader = TRUE, width = 6,
                                    plotlyOutput("ev_heatmap_plot", height = "400px")
                                  ),
                                  box(
                                    title = "Electricity Price Forecast Model", status = "primary", solidHeader = TRUE, width = 6,
                                    plotlyOutput("electricity_forecast", height = "400px")
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "Market Analysis Controls", status = "primary", solidHeader = TRUE, width = 4,
                                    selectInput("region", "UK Region:", 
                                                choices = c("London", "South East", "South West", "Midlands", "North West", "North East", "Scotland", "Wales")),
                                    sliderInput("volatility", "Volatility Threshold:", min = 0.1, max = 2.0, value = 0.8, step = 0.1),
                                    numericInput("position", "Analysis Size (MW):", value = 50, min = 10, max = 500)
                                  ),
                                  box(
                                    title = "Real-Time Grid Analytics", status = "primary", solidHeader = TRUE, width = 4,
                                    plotlyOutput("grid_3d_plot", height = "350px")
                                  ),
                                  box(
                                    title = "Renewable Correlation Matrix", status = "primary", solidHeader = TRUE, width = 4,
                                    plotlyOutput("renewable_matrix", height = "350px")
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "References", status = "info", solidHeader = TRUE, width = 12,
                                    div(class = "reference-box",
                                        h5("Academic & Industry Sources"),
                                        p("National Grid ESO. (2024). Future Energy Scenarios: Electric Vehicle Integration. Available at: https://www.nationalgrideso.com/future-energy/future-energy-scenarios"),
                                        p("Zhang, L. et al. (2024). 'Machine Learning Applications in Smart Grid Trading Systems', IEEE Transactions on Smart Grid, 15(2), pp. 234-248.")
                                    )
                                  )
                                )
                        ),
                        
                        # Hydrocarbons Tab
                        tabItem(tabName = "hydrocarbons",
                                fluidRow(
                                  box(
                                    title = "Hydrocarbons Market Intelligence", status = "primary", solidHeader = TRUE, width = 12,
                                    div(class = "metric-box",
                                        p("Comprehensive supply chain analytics integrating autonomous logistics, transport telemetry, and demand displacement modeling. Real-time freight optimization and geopolitical risk assessment for strategic oil and gas derivatives positioning.", 
                                          style = "font-size: 14px; margin: 0;")
                                    )
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "Global Supply Chain Network", status = "primary", solidHeader = TRUE, width = 6,
                                    div(class = "network-container",
                                        visNetworkOutput("supply_network", height = "550px")
                                    )
                                  ),
                                  box(
                                    title = "Oil Price Forecast", status = "primary", solidHeader = TRUE, width = 6,
                                    plotlyOutput("oil_price_forecast", height = "550px")
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "Market Parameters", status = "primary", solidHeader = TRUE, width = 4,
                                    selectInput("commodity", "Commodity:", 
                                                choices = c("WTI Crude", "Brent Crude", "Natural Gas", "RBOB Gasoline")),
                                    sliderInput("risk_appetite", "Risk Analysis Level:", min = 1, max = 10, value = 5),
                                    checkboxGroupInput("strategies", "Analysis Focus:",
                                                       choices = c("Contango Analysis", "Backwardation Trends", "Crack Spread", "Location Differentials"),
                                                       selected = c("Contango Analysis"))
                                  ),
                                  box(
                                    title = "Displacement Analytics", status = "primary", solidHeader = TRUE, width = 4,
                                    plotlyOutput("displacement_surface", height = "350px")
                                  ),
                                  box(
                                    title = "Freight Cost Dynamics", status = "primary", solidHeader = TRUE, width = 4,
                                    plotlyOutput("freight_bubble", height = "350px")
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "References", status = "info", solidHeader = TRUE, width = 12,
                                    div(class = "reference-box",
                                        h5("Market Intelligence Sources"),
                                        p("IEA. (2024). Oil Market Report: Digital Transformation in Energy Trading. International Energy Agency. Available at: https://www.iea.org/reports/oil-market-report"),
                                        p("Santos, M. & Chen, K. (2024). 'Autonomous Logistics Impact on Energy Commodities', Energy Economics, 128, pp. 106-119.")
                                    )
                                  )
                                )
                        ),
                        
                        # Battery Materials Tab
                        tabItem(tabName = "battery",
                                fluidRow(
                                  box(
                                    title = "Battery Materials Market Intelligence", status = "primary", solidHeader = TRUE, width = 12,
                                    div(class = "metric-box",
                                        p("Advanced materials flow analytics covering lithium, cobalt, nickel, and graphite markets. Recycling optimization models and production risk assessment with real-time mining telemetry and urban materials recovery tracking systems.", 
                                          style = "font-size: 14px; margin: 0;")
                                    )
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "Complex Materials Flow Network", status = "primary", solidHeader = TRUE, width = 6,
                                    div(class = "network-container",
                                        visNetworkOutput("materials_network", height = "550px")
                                    )
                                  ),
                                  box(
                                    title = "Lithium Price Forecast", status = "primary", solidHeader = TRUE, width = 6,
                                    plotlyOutput("lithium_forecast", height = "550px")
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "Materials Analytics", status = "primary", solidHeader = TRUE, width = 4,
                                    selectInput("material", "Select Material:", 
                                                choices = c("Lithium Carbonate", "Cobalt Sulfate", "Nickel Sulfate", "Synthetic Graphite")),
                                    dateRangeInput("forecast_period", "Analysis Period:", 
                                                   start = Sys.Date(), end = Sys.Date() + 365),
                                    sliderInput("recycling_rate", "Recycling Efficiency:", min = 0.1, max = 0.9, value = 0.6, step = 0.05)
                                  ),
                                  box(
                                    title = "Price Volatility Surface", status = "primary", solidHeader = TRUE, width = 4,
                                    plotlyOutput("volatility_surface", height = "350px")
                                  ),
                                  box(
                                    title = "Supply-Demand Dynamics", status = "primary", solidHeader = TRUE, width = 4,
                                    plotlyOutput("supply_demand_radar", height = "350px")
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "References", status = "info", solidHeader = TRUE, width = 12,
                                    div(class = "reference-box",
                                        h5("Materials Research Sources"),
                                        p("USGS. (2024). Critical Minerals Supply Chains and Battery Materials. U.S. Geological Survey. Available at: https://www.usgs.gov/centers/national-minerals-information-center"),
                                        p("Liu, H. et al. (2024). 'Advanced Materials Flow Analysis in Battery Supply Chains', Nature Energy, 9(4), pp. 287-295.")
                                    )
                                  )
                                )
                        ),
                        
                        # Metals Tab
                        tabItem(tabName = "metals",
                                fluidRow(
                                  box(
                                    title = "Critical Metals Infrastructure Analytics", status = "primary", solidHeader = TRUE, width = 12,
                                    div(class = "metric-box",
                                        p("Comprehensive infrastructure deployment monitoring for copper, aluminum, and rare earth elements. IoT-enabled mining fleet analytics and smart grid expansion tracking with predictive demand modeling for strategic metals positioning.", 
                                          style = "font-size: 14px; margin: 0;")
                                    )
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "Infrastructure Deployment Timeline", status = "primary", solidHeader = TRUE, width = 8,
                                    timevisOutput("advanced_timeline", height = "400px")
                                  ),
                                  box(
                                    title = "Analysis Parameters", status = "primary", solidHeader = TRUE, width = 4,
                                    selectInput("metal_portfolio", "Metal Focus:", 
                                                choices = c("Copper", "Aluminum", "Rare Earth Elements", "Steel", "Zinc"),
                                                multiple = TRUE, selected = c("Copper", "Aluminum")),
                                    sliderInput("infrastructure_weight", "Infrastructure Weight:", min = 0.1, max = 1.0, value = 0.7),
                                    numericInput("capital_allocation", "Analysis Scale ($ millions):", value = 10, min = 1, max = 100)
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "Multi-Metal Correlation Analysis", status = "primary", solidHeader = TRUE, width = 6,
                                    plotlyOutput("metals_correlation_3d", height = "350px")
                                  ),
                                  box(
                                    title = "Inventory Analytics Dashboard", status = "primary", solidHeader = TRUE, width = 6,
                                    DT::dataTableOutput("advanced_inventory_table")
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "References", status = "info", solidHeader = TRUE, width = 12,
                                    div(class = "reference-box",
                                        h5("Metals Market Intelligence"),
                                        p("LME. (2024). Critical Metals Market Analysis and Infrastructure Trends. London Metal Exchange. Available at: https://www.lme.com/en/market-data/reports"),
                                        p("Thompson, R. & Kumar, S. (2024). 'IoT Applications in Mining Operations and Metals Trading', Resources Policy, 82, pp. 103-115.")
                                    )
                                  )
                                )
                        ),
                        
                        # AI Hedging & FX Tab
                        tabItem(tabName = "forex",
                                fluidRow(
                                  box(
                                    title = "AI-Powered FX Hedging Intelligence", status = "primary", solidHeader = TRUE, width = 12,
                                    div(class = "metric-box",
                                        p("Advanced machine learning models for currency hedging with commodity correlation analysis. Multi-factor risk models incorporating infrastructure deployment patterns, resource trade flows, and automated execution algorithms for optimal hedging strategies.", 
                                          style = "font-size: 14px; margin: 0;")
                                    )
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "AI Model Performance Matrix", status = "primary", solidHeader = TRUE, width = 8,
                                    plotlyOutput("ai_performance_matrix", height = "400px")
                                  ),
                                  box(
                                    title = "Model Configuration", status = "primary", solidHeader = TRUE, width = 4,
                                    selectInput("currency_pair", "Currency Pair:", 
                                                choices = c("EUR/USD", "GBP/NOK", "AUD/USD", "CAD/USD", "USD/CNY")),
                                    selectInput("ai_model", "AI Model:", 
                                                choices = c("Deep LSTM", "Transformer", "Random Forest", "XGBoost", "Ensemble")),
                                    sliderInput("hedge_ratio", "Analysis Ratio:", min = 0.1, max = 1.0, value = 0.75, step = 0.05),
                                    numericInput("exposure", "Exposure Analysis ($ millions):", value = 25, min = 1, max = 200)
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "Risk Decomposition Analysis", status = "primary", solidHeader = TRUE, width = 6,
                                    plotlyOutput("risk_decomposition", height = "350px")
                                  ),
                                  box(
                                    title = "Real-Time P&L Attribution", status = "primary", solidHeader = TRUE, width = 6,
                                    plotlyOutput("pnl_attribution", height = "350px")
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "References", status = "info", solidHeader = TRUE, width = 12,
                                    div(class = "reference-box",
                                        h5("AI & Financial Engineering Sources"),
                                        p("BIS. (2024). Machine Learning Applications in Foreign Exchange Markets. Bank for International Settlements. Available at: https://www.bis.org/publ/qtrpdf/r_qt2404.htm"),
                                        p("Patel, N. et al. (2024). 'Deep Learning for Currency Hedging in Commodity Markets', Journal of Financial Data Science, 6(2), pp. 78-94.")
                                    )
                                  )
                                )
                        ),
                        
                        # Company Alignment Tab
                        tabItem(tabName = "company",
                                fluidRow(
                                  box(
                                    title = "Get In Contact with Atera Analytics", status = "primary", solidHeader = TRUE, width = 12,
                                    div(class = "metric-box",
                                        p("For a full demo of this application on Commodities Modelling in Trading Get In Touch via atera-analytics.co.uk", 
                                          style = "font-size: 14px; margin: 0;")
                                    )
                                  )
                                ),
                                fluidRow(
                                  box(
                                    title = "Strategic Alignment & Market Positioning", status = "primary", solidHeader = TRUE, width = 12,
                                    div(class = "metric-box",
                                        p("Comprehensive capability assessment and strategic roadmap for energy commodities trading excellence. Technology stack evaluation, market opportunity analysis, and investment planning framework for next-generation trading infrastructure development.", 
                                          style = "font-size: 14px; margin: 0;")
                                    )
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "Strategic Capability Radar", status = "primary", solidHeader = TRUE, width = 8,
                                    plotlyOutput("strategy_radar", height = "400px")
                                  ),
                                  box(
                                    title = "Investment Planning", status = "primary", solidHeader = TRUE, width = 4,
                                    selectInput("focus_area", "Strategic Focus:", 
                                                choices = c("Data Analytics", "Trading Infrastructure", "Risk Management", 
                                                            "AI/ML Capabilities", "Market Intelligence")),
                                    sliderInput("investment_horizon", "Investment Timeline (years):", min = 1, max = 5, value = 3),
                                    numericInput("budget", "Annual Budget ($ millions):", value = 15, min = 5, max = 100)
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "Market Opportunity Matrix", status = "primary", solidHeader = TRUE, width = 12,
                                    plotlyOutput("opportunity_matrix", height = "400px")
                                  )
                                ),
                                
                                fluidRow(
                                  box(
                                    title = "References", status = "info", solidHeader = TRUE, width = 12,
                                    div(class = "reference-box",
                                        h5("Strategic Management & Technology Sources"),
                                        p("McKinsey. (2024). Digital Transformation in Energy Trading: Strategic Framework. Available at: https://www.mckinsey.com/industries/oil-and-gas/our-insights/digital-transformation-energy-trading"),
                                        p("Deloitte. (2024). Future of Commodity Trading: Technology and Market Evolution. Available at: https://www2.deloitte.com/global/en/insights/industry/oil-and-gas/future-commodity-trading.html")
                                    )
                                  )
                                )
                        )
                      )
                    )
)

# Define Server Logic (FIXED VERSION)
server <- function(input, output, session) {
  
  # Electric Energy Visualizations
  output$ev_heatmap_plot <- renderPlotly({
    uk_regions <- c("London", "South East", "South West", "Midlands", "North West", "North East", "Scotland", "Wales")
    hours <- 0:23
    
    demand_matrix <- matrix(
      abs(rnorm(192, 40, 15) + 
            rep(c(25, 20, 18, 15, 12, 18, 30, 55, 50, 45, 40, 42, 48, 52, 58, 68, 85, 95, 80, 65, 55, 48, 40, 30), 8)),
      nrow = 8, ncol = 24
    )
    
    demand_matrix[1, ] <- demand_matrix[1, ] * 1.3
    
    plot_ly(z = demand_matrix, x = hours, y = uk_regions, type = "heatmap",
            colorscale = list(c(0, "#1e3a8a"), c(0.25, "#3b82f6"), c(0.5, "#60a5fa"), c(0.75, "#fbbf24"), c(1, "#dc2626")),
            hovertemplate = "Hour: %{x}<br>Region: %{y}<br>Demand: %{z:.1f} MW<extra></extra>") %>%
      layout(title = "UK Regional EV Charging Demand - 24 Hour Profile",
             xaxis = list(title = "Hour of Day"),
             yaxis = list(title = "UK Region"),
             plot_bgcolor = "white",
             paper_bgcolor = "white")
  })
  
  # Simple Electricity Price Forecast (without forecast package)
  output$electricity_forecast <- renderPlotly({
    # Generate sample electricity price data
    dates <- seq(as.Date("2020-01-01"), as.Date("2024-06-01"), by = "month")
    n <- length(dates)
    
    # Create realistic electricity price time series
    trend <- seq(50, 80, length.out = n)
    seasonal <- 10 * sin(2 * pi * (1:n) / 12)
    noise <- rnorm(n, 0, 5)
    prices <- trend + seasonal + noise
    
    # Simple forecast using linear trend + seasonality
    forecast_dates <- seq(max(dates) + 30, by = "month", length.out = 12)
    last_trend <- tail(trend, 1)
    forecast_trend <- seq(last_trend, last_trend + 5, length.out = 12)
    forecast_seasonal <- 10 * sin(2 * pi * (1:12) / 12)
    forecast_prices <- forecast_trend + forecast_seasonal
    
    # Confidence intervals
    lower_ci <- forecast_prices - 8
    upper_ci <- forecast_prices + 8
    
    plot_ly() %>%
      add_trace(x = dates, y = prices, 
                type = "scatter", mode = "lines+markers", name = "Historical Prices",
                line = list(color = "#1e3a8a", width = 3),
                marker = list(color = "#1e3a8a", size = 4)) %>%
      add_trace(x = forecast_dates, y = forecast_prices, 
                type = "scatter", mode = "lines+markers", name = "Forecast",
                line = list(color = "#dc2626", width = 3, dash = "dash"),
                marker = list(color = "#dc2626", size = 5)) %>%
      add_ribbons(x = forecast_dates, 
                  ymin = lower_ci, 
                  ymax = upper_ci,
                  name = "95% CI", fillcolor = "rgba(220, 38, 38, 0.2)",
                  line = list(color = "transparent")) %>%
      layout(title = "UK Electricity Price Forecast",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Price (£/MWh)"),
             plot_bgcolor = "white",
             paper_bgcolor = "white")
  })
  
  output$grid_3d_plot <- renderPlotly({
    x <- seq(0, 24, 0.5)
    y <- seq(0, 100, 2)
    z <- outer(x, y, function(x, y) sin(x/4) * cos(y/20) * 50 + 75)
    
    plot_ly(z = z, type = "surface", 
            colorscale = list(c(0, "#1e3a8a"), c(0.2, "#3b82f6"), c(0.4, "#60a5fa"), 
                              c(0.6, "#fbbf24"), c(0.8, "#f59e0b"), c(1, "#dc2626"))) %>%
      layout(title = "3D Grid Load Surface",
             scene = list(xaxis = list(title = "Time"),
                          yaxis = list(title = "Capacity"),
                          zaxis = list(title = "Load")),
             plot_bgcolor = "white",
             paper_bgcolor = "white")
  })
  
  output$renewable_matrix <- renderPlotly({
    correlations <- matrix(c(1, -0.7, 0.3, 0.5,
                             -0.7, 1, -0.2, -0.6,
                             0.3, -0.2, 1, 0.4,
                             0.5, -0.6, 0.4, 1), nrow = 4)
    variables <- c("Solar", "Wind", "Price", "Demand")
    
    plot_ly(z = correlations, x = variables, y = variables, type = "heatmap",
            colorscale = list(c(0, "#dc2626"), c(0.25, "#f97316"), c(0.5, "#fbbf24"), 
                              c(0.75, "#22d3ee"), c(1, "#1e3a8a")), 
            zmin = -1, zmax = 1) %>%
      layout(title = "Renewable Energy Correlation Matrix",
             plot_bgcolor = "white",
             paper_bgcolor = "white")
  })
  
  # Oil Price Forecast (simplified)
  output$oil_price_forecast <- renderPlotly({
    dates <- seq(as.Date("2020-01-01"), as.Date("2024-06-01"), by = "week")
    n <- length(dates)
    
    # Create realistic oil price time series with volatility
    trend <- seq(60, 85, length.out = n)
    volatility <- cumsum(rnorm(n, 0, 2))
    prices <- trend + volatility + rnorm(n, 0, 3)
    
    # Simple forecast
    forecast_dates <- seq(max(dates) + 7, by = "week", length.out = 26)
    last_price <- tail(prices, 1)
    forecast_prices <- last_price + cumsum(rnorm(26, 0.1, 2))
    lower_ci <- forecast_prices - 6
    upper_ci <- forecast_prices + 6
    
    plot_ly() %>%
      add_trace(x = dates, y = prices, 
                type = "scatter", mode = "lines", name = "Historical Prices",
                line = list(color = "#166534", width = 3)) %>%
      add_trace(x = forecast_dates, y = forecast_prices, 
                type = "scatter", mode = "lines+markers", name = "Forecast",
                line = list(color = "#ea580c", width = 3, dash = "dash"),
                marker = list(color = "#ea580c", size = 5)) %>%
      add_ribbons(x = forecast_dates, 
                  ymin = lower_ci, 
                  ymax = upper_ci,
                  name = "95% CI", fillcolor = "rgba(234, 88, 12, 0.2)",
                  line = list(color = "transparent")) %>%
      layout(title = "Brent Crude Oil Price Forecast",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Price ($/barrel)"),
             plot_bgcolor = "white",
             paper_bgcolor = "white")
  })
  
  # Hydrocarbons Network
  output$supply_network <- renderVisNetwork({
    nodes <- data.frame(
      id = 1:12,
      label = c("Refineries", "Terminals", "Pipelines", "Tankers", "Ports", "Distribution",
                "Retail", "Industrial", "Transport", "Storage", "Trading Hubs", "Exchanges"),
      size = c(40, 35, 30, 25, 35, 30, 20, 25, 20, 30, 45, 40),
      color = c("#dc2626", "#ea580c", "#16a34a", "#ca8a04", "#8b5cf6", "#0891b2",
                "#1e40af", "#be185d", "#059669", "#c2410c", "#7c3aed", "#0369a1")
    )
    
    edges <- data.frame(
      from = c(1,1,2,2,3,3,4,4,5,5,6,6,7,8,9,10,11,11),
      to = c(2,3,6,10,4,5,9,11,5,11,7,8,11,11,10,11,12,12),
      width = c(8,6,7,5,9,7,4,6,8,7,5,6,3,4,5,6,8,9),
      color = "#1e3a8a"
    )
    
    visNetwork(nodes, edges) %>%
      visOptions(highlightNearest = TRUE) %>%
      visPhysics(stabilization = FALSE)
  })
  
  output$displacement_surface <- renderPlotly({
    years <- seq(2024, 2035, 0.5)
    adoption <- seq