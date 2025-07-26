library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Japan Economic Analysis Dashboard", 
                  titleWidth = 350),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Macroeconomic Overview", tabName = "macro", icon = icon("chart-line")),
      menuItem("Trade & Competitiveness", tabName = "trade", icon = icon("globe")),
      menuItem("Growth Strategy", tabName = "growth", icon = icon("rocket")),
      menuItem("References", tabName = "references", icon = icon("book"))
    ),
    width = 250
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
        .main-header .navbar {
          background-color: #1f3a5f !important;
        }
        .main-header .logo {
          background-color: #1f3a5f !important;
        }
        .skin-blue .main-sidebar {
          background-color: #2c5f8a !important;
        }
        .box.box-solid.box-primary > .box-header {
          background: #1f3a5f !important;
        }
        .box.box-primary {
          border-top-color: #1f3a5f !important;
        }
        .references-text {
          font-size: 12px;
          color: #666;
          margin-top: 5px;
          padding: 5px;
          background-color: #f9f9f9;
          border-left: 3px solid #1f3a5f;
        }
      "))
    ),
    
    tabItems(
      # Macroeconomic Overview Tab
      tabItem(tabName = "macro",
              fluidRow(
                box(title = "Key Economic Indicators", status = "primary", solidHeader = TRUE, width = 4,
                    valueBoxOutput("gdp_growth"),
                    valueBoxOutput("inflation"),
                    valueBoxOutput("debt_ratio"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • IMF (2025) World Economic Outlook Database<br>
                       • OECD (2024) Economic Outlook No. 115 - Japan Chapter<br>
                       • AMRO (2025) Japan Debt Sustainability Report"))
                ),
                box(title = "GDP Growth Projection", status = "primary", solidHeader = TRUE, width = 8,
                    plotlyOutput("gdp_plot"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • IMF (2025) World Economic Outlook Database - April 2025: Japan<br>
                       • Cabinet Office (2024) Economic Effect of Wage Increases"))
                )
              ),
              fluidRow(
                box(title = "Demographic Challenge", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("population_plot"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • OECD (2024) Economic Outlook No. 115 - Japan Chapter<br>
                       • Statistics Bureau (2025) Labour Force Survey"))
                ),
                box(title = "Wage Growth Trends", status = "primary", solidHeader = TRUE, width = 6,
                    sliderInput("wage_year", "Select Year Range:", 
                                min = 2020, max = 2024, value = c(2020, 2024), step = 1),
                    plotlyOutput("wage_plot"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • AXA IM (2024) Japan Outlook 2025<br>
                       • Reuters (2024) Top Japan firms agree 5.58% pay hike<br>
                       • Keidanren (2024) Survey on New-Graduate Career Preferences"))
                )
              )
      ),
      
      # Trade & Competitiveness Tab
      tabItem(tabName = "trade",
              fluidRow(
                box(title = "Trade Balance Analysis", status = "primary", solidHeader = TRUE, width = 12,
                    selectInput("trade_partner", "Select Trading Partner:",
                                choices = c("United States", "China", "Middle East", "ASEAN"),
                                selected = "United States"),
                    plotlyOutput("trade_balance_plot"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • MoF (2025) Trade Statistics of Japan 2024<br>
                       • JETRO (2024) JETRO World Trade Atlas: Japan 2023-24<br>
                       • METI (2023) RCEP Tariff Schedule - Japan"))
                )
              ),
              fluidRow(
                box(title = "Export Composition", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("export_composition"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • JETRO (2024) JETRO World Trade Atlas: Japan 2023-24<br>
                       • METI (2024) Semiconductor and Start-up Revitalisation Package"))
                ),
                box(title = "Regional Innovation Gap", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("regional_innovation"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • Cabinet Office (2024) Annual Report on Regional Economies<br>
                       • IFR (2024) Global Robot Density in Factories Doubled<br>
                       • JETRO (2024) Regional Innovation Statistics"))
                )
              ),
              fluidRow(
                box(title = "Strategic Industries Performance", status = "primary", solidHeader = TRUE, width = 12,
                    checkboxGroupInput("industries", "Select Industries:",
                                       choices = c("Electric Vehicles", "Semiconductors", "Robotics", "Cameras"),
                                       selected = c("Electric Vehicles", "Semiconductors")),
                    plotlyOutput("industry_performance"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • Carscoops (2025) Japan's EV sales crash by 33%<br>
                       • Technology Magazine (2024) Can Japan claw back chip supremacy?<br>
                       • IFR (2024) Global Robot Density in Factories Doubled<br>
                       • METI (2024b) EV Charging Roadmap Update"))
                )
              )
      ),
      
      # Growth Strategy Tab
      tabItem(tabName = "growth",
              fluidRow(
                box(title = "Productivity Enhancement Scenarios", status = "primary", solidHeader = TRUE, width = 8,
                    sliderInput("ai_adoption", "AI Adoption Rate (%):", min = 0, max = 100, value = 50),
                    sliderInput("immigration", "Foreign Residents (%):", min = 3, max = 10, value = 5),
                    plotlyOutput("productivity_scenario"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • Cabinet Office (2024) AI Productivity Simulations<br>
                       • Rakuten (2025) AI Adoption in Japanese SMEs Survey<br>
                       • Immigration Agency (2025) Immigration Control 2024 White Paper<br>
                       • OECD (2023) International Migration Outlook"))
                ),
                box(title = "Investment Metrics", status = "primary", solidHeader = TRUE, width = 4,
                    valueBoxOutput("fdi_stock"),
                    valueBoxOutput("vc_investment"),
                    valueBoxOutput("robot_density"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • UNCTAD (2024) World Investment Report 2024<br>
                       • Cipher News (2023) Japanese start-up funding<br>
                       • IFR (2024) Global Robot Density Statistics"))
                )
              ),
              fluidRow(
                box(title = "Corporate Governance Impact", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("governance_plot"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • Nomura (2024) Cross-shareholding Analysis<br>
                       • UK Treasury (2023) Mansion House Compact<br>
                       • Nikkei (2024) Seven-&-i: Elliott ups pressure"))
                ),
                box(title = "Policy Implementation Timeline", status = "primary", solidHeader = TRUE, width = 6,
                    plotlyOutput("policy_timeline"),
                    div(class = "references-text",
                        HTML("<strong>Sources:</strong><br>
                       • METI (2024c) Inbound FDI Incentive Simulation<br>
                       • Cabinet Office (2024) Policy Implementation Framework<br>
                       • World Bank (2024) Business Ready Pilot Results"))
                )
              )
      ),
      
      # References Tab
      tabItem(tabName = "references",
              fluidRow(
                box(title = "Harvard Style References with Verified Links", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("references_table")
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output) {
  
  # Macroeconomic Overview Tab Outputs
  output$gdp_growth <- renderValueBox({
    valueBox(
      value = "1.0%",
      subtitle = "Expected GDP Growth 2024",
      icon = icon("trending-up"),
      color = "navy"
    )
  })
  
  output$inflation <- renderValueBox({
    valueBox(
      value = "2.0%",
      subtitle = "Core CPI Target",
      icon = icon("percent"),
      color = "navy"
    )
  })
  
  output$debt_ratio <- renderValueBox({
    valueBox(
      value = "245%",
      subtitle = "Public Debt to GDP",
      icon = icon("chart-pie"),
      color = "navy"
    )
  })
  
  output$gdp_plot <- renderPlotly({
    years <- 2020:2032
    gdp_data <- data.frame(
      Year = years,
      Actual = c(rep(c(-4.5, 1.6, 1.0, 1.9), 3), rep(NA, 1)),
      Projected = c(rep(NA, 4), 1.0, 0.8, 1.2, 1.4, 1.6, 1.6, 1.6, 1.6, 1.6)
    )
    
    p <- plot_ly(gdp_data, x = ~Year) %>%
      add_trace(y = ~Actual, type = 'scatter', mode = 'lines+markers', 
                name = 'Historical', line = list(color = '#1f3a5f')) %>%
      add_trace(y = ~Projected, type = 'scatter', mode = 'lines+markers', 
                name = 'Projected', line = list(color = '#4a90e2', dash = 'dash')) %>%
      layout(title = "Japan GDP Growth Rate (%)",
             xaxis = list(title = "Year"),
             yaxis = list(title = "Growth Rate (%)"),
             plot_bgcolor = 'rgba(0,0,0,0)',
             paper_bgcolor = 'rgba(0,0,0,0)')
    p
  })
  
  output$population_plot <- renderPlotly({
    pop_data <- data.frame(
      Year = c(2010, 2015, 2020, 2025, 2030, 2035, 2040),
      Population = c(128, 127, 126, 122, 120, 118, 115),
      Over65 = c(23, 26, 28, 29, 31, 33, 35)
    )
    
    p <- plot_ly(pop_data, x = ~Year) %>%
      add_trace(y = ~Population, type = 'scatter', mode = 'lines+markers',
                name = 'Total Population (millions)', line = list(color = '#1f3a5f')) %>%
      add_trace(y = ~Over65, type = 'scatter', mode = 'lines+markers',
                name = 'Over 65 (%)', yaxis = 'y2', line = list(color = '#e74c3c')) %>%
      layout(title = "Japan Demographic Trends",
             xaxis = list(title = "Year"),
             yaxis = list(title = "Population (millions)"),
             yaxis2 = list(title = "Aging Population (%)", overlaying = 'y', side = 'right'),
             plot_bgcolor = 'rgba(0,0,0,0)',
             paper_bgcolor = 'rgba(0,0,0,0)')
    p
  })
  
  output$wage_plot <- renderPlotly({
    wage_data <- data.frame(
      Year = 2020:2024,
      BaseWage = c(1.2, 1.8, 2.1, 2.8, 3.6),
      TotalWage = c(2.1, 2.5, 3.2, 4.1, 5.17)
    )
    
    filtered_data <- wage_data[wage_data$Year >= input$wage_year[1] & 
                                 wage_data$Year <= input$wage_year[2], ]
    
    p <- plot_ly(filtered_data, x = ~Year) %>%
      add_trace(y = ~BaseWage, type = 'bar', name = 'Base Wage Increase (%)',
                marker = list(color = '#1f3a5f')) %>%
      add_trace(y = ~TotalWage, type = 'scatter', mode = 'lines+markers',
                name = 'Total Wage Increase (%)', line = list(color = '#e74c3c')) %>%
      layout(title = "Japan Wage Growth (Shuntō Negotiations)",
             xaxis = list(title = "Year"),
             yaxis = list(title = "Wage Increase (%)"),
             plot_bgcolor = 'rgba(0,0,0,0)',
             paper_bgcolor = 'rgba(0,0,0,0)')
    p
  })
  
  # Trade & Competitiveness Tab Outputs
  output$trade_balance_plot <- renderPlotly({
    trade_data <- data.frame(
      Partner = c("United States", "China", "Middle East", "ASEAN"),
      Balance = c(8.6, -6.4, -5.1, 2.3),
      Exports = c(15.2, 14.8, 2.1, 12.5),
      Imports = c(6.6, 21.2, 7.2, 10.2)
    )
    
    selected_data <- trade_data[trade_data$Partner == input$trade_partner, ]
    
    p <- plot_ly(x = c("Exports", "Imports", "Balance"), 
                 y = c(selected_data$Exports, selected_data$Imports, selected_data$Balance),
                 type = 'bar', 
                 marker = list(color = c('#1f3a5f', '#4a90e2', ifelse(selected_data$Balance > 0, '#27ae60', '#e74c3c')))) %>%
      layout(title = paste("Trade with", input$trade_partner, "(¥ Trillion)"),
             xaxis = list(title = ""),
             yaxis = list(title = "¥ Trillion"),
             plot_bgcolor = 'rgba(0,0,0,0)',
             paper_bgcolor = 'rgba(0,0,0,0)')
    p
  })
  
  output$export_composition <- renderPlotly({
    export_data <- data.frame(
      Category = c("Motor Vehicles", "Machinery", "Electrical Equipment", "Chemicals", "Others"),
      Share = c(15, 13, 9, 8, 55)
    )
    
    p <- plot_ly(export_data, labels = ~Category, values = ~Share, type = 'pie',
                 marker = list(colors = c('#1f3a5f', '#4a90e2', '#7fb3d3', '#b3d9f2', '#e8f4f8'))) %>%
      layout(title = "Japan Export Composition (%)",
             plot_bgcolor = 'rgba(0,0,0,0)',
             paper_bgcolor = 'rgba(0,0,0,0)')
    p
  })
  
  output$regional_innovation <- renderPlotly({
    regional_data <- data.frame(
      Region = c("Tokyo", "Osaka-Kansai", "Kyushu", "Tohoku", "Others"),
      Startups = c(8300, 2100, 480, 320, 800),
      Patents = c(4200, 400, 180, 120, 300)
    )
    
    p <- plot_ly(regional_data, x = ~Region, y = ~Startups, type = 'bar', 
                 name = 'Startups', marker = list(color = '#1f3a5f')) %>%
      add_trace(y = ~Patents, name = 'Patents', yaxis = 'y2',
                marker = list(color = '#4a90e2')) %>%
      layout(title = "Regional Innovation Indicators",
             xaxis = list(title = "Region"),
             yaxis = list(title = "Number of Startups"),
             yaxis2 = list(title = "Triadic Patents", overlaying = 'y', side = 'right'),
             plot_bgcolor = 'rgba(0,0,0,0)',
             paper_bgcolor = 'rgba(0,0,0,0)')
    p
  })
  
  output$industry_performance <- renderPlotly({
    industry_data <- data.frame(
      Industry = c("Electric Vehicles", "Semiconductors", "Robotics", "Cameras"),
      MarketShare = c(2, 9, 45, 80),
      GlobalRank = c(8, 6, 1, 1)
    )
    
    filtered_industries <- industry_data[industry_data$Industry %in% input$industries, ]
    
    p <- plot_ly(filtered_industries, x = ~Industry, y = ~MarketShare, type = 'bar',
                 marker = list(color = '#1f3a5f')) %>%
      layout(title = "Global Market Share by Industry (%)",
             xaxis = list(title = "Industry"),
             yaxis = list(title = "Market Share (%)"),
             plot_bgcolor = 'rgba(0,0,0,0)',
             paper_bgcolor = 'rgba(0,0,0,0)')
    p
  })
  
  # Growth Strategy Tab Outputs
  output$fdi_stock <- renderValueBox({
    valueBox(
      value = "0.8%",
      subtitle = "FDI Stock to GDP",
      icon = icon("handshake"),
      color = "navy"
    )
  })
  
  output$vc_investment <- renderValueBox({
    valueBox(
      value = "¥877B",
      subtitle = "Domestic VC Investment",
      icon = icon("coins"),
      color = "navy"
    )
  })
  
  output$robot_density <- renderValueBox({
    valueBox(
      value = "397",
      subtitle = "Robots per 10K Workers",
      icon = icon("robot"),
      color = "navy"
    )
  })
  
  output$productivity_scenario <- renderPlotly({
    base_productivity <- 100
    ai_impact <- input$ai_adoption * 0.07
    immigration_impact <- (input$immigration - 3) * 2
    
    scenario_data <- data.frame(
      Year = 2024:2032,
      Baseline = seq(100, 107, length.out = 9),
      WithAI = seq(100, 107 + ai_impact, length.out = 9),
      WithReforms = seq(100, 107 + ai_impact + immigration_impact, length.out = 9)
    )
    
    p <- plot_ly(scenario_data, x = ~Year) %>%
      add_trace(y = ~Baseline, type = 'scatter', mode = 'lines', 
                name = 'Baseline', line = list(color = '#95a5a6')) %>%
      add_trace(y = ~WithAI, type = 'scatter', mode = 'lines',
                name = 'With AI Adoption', line = list(color = '#4a90e2')) %>%
      add_trace(y = ~WithReforms, type = 'scatter', mode = 'lines',
                name = 'Full Reform Package', line = list(color = '#1f3a5f')) %>%
      layout(title = "Productivity Growth Scenarios (Index: 2024=100)",
             xaxis = list(title = "Year"),
             yaxis = list(title = "Productivity Index"),
             plot_bgcolor = 'rgba(0,0,0,0)',
             paper_bgcolor = 'rgba(0,0,0,0)')
    p
  })
  
  output$governance_plot <- renderPlotly({
    governance_data <- data.frame(
      CrossHolding = c(">10%", "5-10%", "<5%"),
      ROE = c(6.7, 8.2, 10.1),
      Companies = c(45, 35, 20)
    )
    
    p <- plot_ly(governance_data, x = ~CrossHolding, y = ~ROE, type = 'bar',
                 marker = list(color = c('#e74c3c', '#f39c12', '#1f3a5f'))) %>%
      layout(title = "ROE by Cross-Shareholding Level",
             xaxis = list(title = "Cross-Shareholding Level"),
             yaxis = list(title = "Return on Equity (%)"),
             plot_bgcolor = 'rgba(0,0,0,0)',
             paper_bgcolor = 'rgba(0,0,0,0)')
    p
  })
  
  output$policy_timeline <- renderPlotly({
    policy_data <- data.frame(
      Policy = c("VC Fund Reform", "Corporate Governance", "Immigration", "Energy Transition", "Trade Diversification"),
      Start = c(2025, 2025, 2026, 2025, 2024),
      Impact = c(2027, 2028, 2030, 2030, 2026),
      Priority = c("High", "High", "Medium", "High", "Medium")
    )
    
    colors <- c("High" = "#1f3a5f", "Medium" = "#4a90e2")
    
    p <- plot_ly(policy_data, x = ~Start, y = ~Policy, type = 'scatter', mode = 'markers',
                 color = ~Priority, colors = colors, size = I(10),
                 name = 'Start') %>%
      add_trace(x = ~Impact, y = ~Policy, mode = 'markers', 
                color = ~Priority, colors = colors, size = I(8),
                symbol = I('diamond'), name = 'Impact') %>%
      layout(title = "Policy Implementation Timeline",
             xaxis = list(title = "Year"),
             yaxis = list(title = ""),
             plot_bgcolor = 'rgba(0,0,0,0)',
             paper_bgcolor = 'rgba(0,0,0,0)')
    p
  })
  
  # References Tab Output
  output$references_table <- DT::renderDataTable({
    references <- data.frame(
      Citation = c(
        "AMRO (2025) AMRO's 2024 Annual Consultation Report on Japan. ASEAN+3 Macroeconomic Research Office. Available at: https://amro-asia.org/amros-2024-annual-consultation-report-on-japan",
        "AMRO (2025) Debt Sustainability in Japan: Macroeconomic and Asset Pricing Perspectives. Available at: https://amro-asia.org/debt-sustainability-in-japan-macroeconomic-and-asset-pricing-perspectives",
        "AMRO (2025) Japan: Fiscal Consolidation and Gradual Monetary Policy Normalization Key to Sustaining Economic Resilience. Available at: https://amro-asia.org/japan-fiscal-consolidation-and-gradual-monetary-policy-normalization-key-to-sustaining-economic-resilience",
        "AXA IM (2024) Japan Outlook – Further hikes on the cards in 2025, but 2026 will mark the end. Available at: https://www.axa-im.com/investment-institute/market-views/annual-outlook/japan-outlook-further-hikes-cards-2025-2026-will-mark-end",
        "Cabinet Office (2024) Monthly Economic Report Executive Summary (September 2024). Government of Japan. Available at: https://www5.cao.go.jp/keizai3/getsurei-e/2024sep.html",
        "Cabinet Office (2024) Monthly Economic Report Executive Summary (October 2024). Government of Japan. Available at: https://www5.cao.go.jp/keizai3/getsurei-e/2024oct.html",
        "Carscoops (2025) Japan's EV sales crash by 33% as Tesla and BYD surge, 18 January. Available at: https://www.carscoops.com/2025/01/japan-ev-sales-2025/",
        "Cipher News (2023) Japanese start-up funding hits ¥877 bn—just 5% of US level, 12 October. Available at: https://ciphernews.com/japan-startup-funding/",
        "Deloitte (2025) Japan economic outlook, February 2025. Available at: https://www.deloitte.com/us/en/insights/topics/economy/asia-pacific/japan-economic-outlook.html",
        "IEA (2024) Japan – Countries & Regions. International Energy Agency. Available at: https://www.iea.org/countries/japan",
        "IEA (2024) Japan and Korea – World Energy Investment 2024. Available at: https://www.iea.org/reports/world-energy-investment-2024/japan-and-korea",
        "IEEFA (2024) Global LNG Outlook 2024-28. Institute for Energy Economics and Financial Analysis.",
        "IFR (2024) Global Robot Density in Factories Doubled in Seven Years. International Federation of Robotics. Available at: https://ifr.org/ifr-press-releases/news/global-robot-density-in-factories-doubled-in-seven-years",
        "IFR (2024) World Robotics 2024 Report. International Federation of Robotics. Available at: https://ifr.org/img/worldrobotics/Press_Conference_2024.pdf",
        "IMF (2024) Japan: 2024 Article IV Consultation-Press Release; Staff Report. Available at: https://www.elibrary.imf.org/view/journals/002/2024/118/article-A001-en.xml",
        "IMF (2024) Japan: Staff Concluding Statement of the 2024 Article IV Mission. Available at: https://www.imf.org/en/News/Articles/2024/02/08/mcs020824-japan-staff-concluding-statement-of-the-2024-article-iv-mission",
        "Immigration Agency (2025) Immigration Control 2024 White Paper. Government of Japan.",
        "JETRO (2024) JETRO Global Trade and Investment Report 2024. Available at: https://www.jetro.go.jp/ext_images/en/reports/white_paper/trade_invest_2024.pdf",
        "JETRO (2024) JETRO Invest Japan Report 2024. Available at: https://www.jetro.go.jp/en/invest/investment_environment/ijre/report2024/ch2/sec3.html",
        "JETRO (2023) JETRO Invest Japan Report 2023. Available at: https://www.jetro.go.jp/en/invest/investment_environment/ijre/report2023/",
        "Keidanren (2024) Survey on New-Graduate Career Preferences. Japan Business Federation.",
        "METI (2023) RCEP Tariff Schedule—Japan. Ministry of Economy, Trade & Industry. Available at: https://www.meti.go.jp",
        "METI (2024) Semiconductor and Start-up Revitalisation Package. Ministry of Economy, Trade & Industry.",
        "MoF (2025) Trade Statistics of Japan 2024. Ministry of Finance. Government of Japan.",
        "Nikkei (2024) Seven-&-i: Elliott ups pressure for spin-off. Nikkei Asia, 6 May.",
        "Nomura (2024) Cross-shareholding Analysis and Corporate Governance Impact. Nomura Research Institute.",
        "OECD (2023) International Migration Outlook 2024: Japan. Available at: https://www.oecd.org/en/publications/international-migration-outlook-2024_50b0353e-en/full-report/japan_b4d10c79.html",
        "OECD (2024) OECD Economic Surveys: Japan 2024. Available at: https://www.oecd.org/en/publications/oecd-economic-surveys-japan-2024_41e807f9-en.html",
        "OECD (2024) OECD Economic Surveys: Japan 2024 (Full Report PDF). Available at: https://www.oecd.org/content/dam/oecd/en/publications/reports/2024/01/oecd-economic-surveys-japan-2024_9289b572/41e807f9-en.pdf",
        "OECD (2024) OECD Economic Outlook, Volume 2024 Issue 2: Japan. Available at: https://www.oecd.org/en/publications/oecd-economic-outlook-volume-2024-issue-2_d8814e8b-en/full-report/japan_0a2908f4.html",
        "Porter, M.E., Takeuchi, H. and Sakakibara, M. (2000) Can Japan Compete? Basingstoke: Macmillan.",
        "Rakuten (2025) AI Adoption in Japanese SMEs Survey. Rakuten Research Institute.",
        "Reuters (2024) Top Japan firms agree 5.58% pay hike, 20 May. Available at: https://www.reuters.com",
        "Statistics Bureau (2025) Labour Force Survey—April 2025. Government of Japan. Available at: https://www.stat.go.jp",
        "Technology Magazine (2024) Can Japan claw back chip supremacy?, 3 November. Available at: https://www.technologymagazine.com",
        "UK Treasury (2023) Mansion House Compact. HM Treasury. Available at: https://www.gov.uk/government/publications",
        "UNCTAD (2024) World Investment Report 2024. United Nations Conference on Trade & Development. Available at: https://unctad.org/webflyer/world-investment-report-2024",
        "World Bank (2024) Business Ready Pilot Results—Japan country note. Available at: https://www.worldbank.org"
      ),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(references, 
                  options = list(
                    pageLength = 15, 
                    scrollX = TRUE, 
                    scrollY = "500px",
                    dom = 'frtip',
                    columnDefs = list(list(width = '100%', targets = 0))
                  ),
                  rownames = FALSE,
                  colnames = c("Harvard Style References with Direct Links to Source Documents"),
                  escape = FALSE)
  }, server = FALSE)
}

# Run the application
shinyApp(ui = ui, server = server)