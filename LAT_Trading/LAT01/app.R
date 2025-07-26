# Trading Analytics Dashboard - London Academy of Trading
# R Shiny Application

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(ggplot2)
library(scales)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "TA Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("FX Market Overview", tabName = "fx_overview", icon = icon("chart-line")),
      menuItem("Currency Analysis", tabName = "currency", icon = icon("coins")),
      menuItem("Trading Performance", tabName = "performance", icon = icon("trophy")),
      menuItem("Risk Management", tabName = "risk", icon = icon("shield-alt")),
      menuItem("Technical Analysis", tabName = "technical", icon = icon("chart-area")),
      menuItem("Market Participants", tabName = "participants", icon = icon("users")),
      menuItem("Economic Calendar", tabName = "economic", icon = icon("calendar")),
      menuItem("Support & Resistance", tabName = "support", icon = icon("layer-group"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
        .main-header .navbar {
          background-color: #228B22 !important;
        }
        .main-header .logo {
          background-color: #228B22 !important;
        }
        .skin-blue .main-sidebar {
          background-color: #2c3e50;
        }
        .value-box-icon {
          background-color: #228B22 !important;
        }
        .bg-green {
          background-color: #228B22 !important;
        }
        .box.box-solid.box-primary > .box-header {
          background: #228B22;
        }
        .box.box-solid.box-primary {
          border: 1px solid #228B22;
        }
      "))
    ),
    
    tabItems(
      # FX Market Overview Tab
      tabItem(tabName = "fx_overview",
              fluidRow(
                valueBoxOutput("daily_volume"),
                valueBoxOutput("market_share"),
                valueBoxOutput("active_hours")
              ),
              fluidRow(
                box(
                  title = "FX Turnover by Currency", status = "primary", solidHeader = TRUE,
                  width = 6, height = 400,
                  plotlyOutput("currency_turnover")
                ),
                box(
                  title = "Trading Hours Activity", status = "primary", solidHeader = TRUE,
                  width = 6, height = 400,
                  plotlyOutput("trading_hours")
                )
              ),
              fluidRow(
                box(
                  title = "Global Financial Centres Index (GFCI)", status = "primary", solidHeader = TRUE,
                  width = 12,
                  DT::dataTableOutput("gfci_table")
                )
              )
      ),
      
      # Currency Analysis Tab
      tabItem(tabName = "currency",
              fluidRow(
                box(
                  title = "Currency Controls", status = "primary", solidHeader = TRUE,
                  width = 3,
                  selectInput("base_currency", "Base Currency:",
                              choices = c("USD", "EUR", "GBP", "JPY", "AUD", "CAD", "CHF"),
                              selected = "EUR"),
                  selectInput("term_currency", "Term Currency:",
                              choices = c("USD", "EUR", "GBP", "JPY", "AUD", "CAD", "CHF"),
                              selected = "USD"),
                  numericInput("exchange_rate", "Exchange Rate:", value = 1.1865, step = 0.0001),
                  numericInput("spread_pips", "Spread (Pips):", value = 2, min = 0.1, max = 50)
                ),
                box(
                  title = "Currency Pair Analysis", status = "primary", solidHeader = TRUE,
                  width = 9,
                  plotlyOutput("currency_chart")
                )
              ),
              fluidRow(
                box(
                  title = "USD Index Components", status = "primary", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("usd_index")
                ),
                box(
                  title = "FX Reserves by Country", status = "primary", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("fx_reserves")
                )
              )
      ),
      
      # Trading Performance Tab
      tabItem(tabName = "performance",
              fluidRow(
                box(
                  title = "Performance Metrics Controls", status = "primary", solidHeader = TRUE,
                  width = 3,
                  numericInput("hit_rate", "Hit Rate (%):", value = 60, min = 0, max = 100),
                  numericInput("reward_risk", "Reward-to-Risk Ratio:", value = 2.0, min = 0.1, max = 5.0, step = 0.1),
                  numericInput("total_trades", "Total Trades:", value = 100, min = 10, max = 1000),
                  numericInput("initial_capital", "Initial Capital (£):", value = 50000, min = 1000, max = 1000000)
                ),
                valueBoxOutput("profit_loss"),
                valueBoxOutput("breakeven_rate"),
                valueBoxOutput("max_drawdown")
              ),
              fluidRow(
                box(
                  title = "Hit Rate vs Reward-to-Risk Analysis", status = "primary", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("hit_rate_analysis")
                ),
                box(
                  title = "Drawdown Recovery Analysis", status = "primary", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("drawdown_recovery")
                )
              ),
              fluidRow(
                box(
                  title = "Equity Curve Simulation", status = "primary", solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("equity_curve")
                )
              )
      ),
      
      # Risk Management Tab
      tabItem(tabName = "risk",
              fluidRow(
                box(
                  title = "Risk Parameters", status = "primary", solidHeader = TRUE,
                  width = 3,
                  numericInput("position_size", "Position Size (£):", value = 10000, min = 100, max = 100000),
                  numericInput("stop_loss_pips", "Stop Loss (Pips):", value = 50, min = 5, max = 500),
                  numericInput("take_profit_pips", "Take Profit (Pips):", value = 100, min = 10, max = 1000),
                  sliderInput("max_risk_percent", "Max Risk per Trade (%):", min = 0.5, max = 10, value = 2, step = 0.5)
                ),
                valueBoxOutput("risk_amount"),
                valueBoxOutput("rrr_ratio"),
                valueBoxOutput("position_sizing")
              ),
              fluidRow(
                box(
                  title = "Central Bank Interventions Timeline", status = "primary", solidHeader = TRUE,
                  width = 12,
                  plotlyOutput("cb_interventions")
                )
              ),
              fluidRow(
                box(
                  title = "Risk Scenarios Analysis", status = "primary", solidHeader = TRUE,
                  width = 6,
                  DT::dataTableOutput("risk_scenarios")
                ),
                box(
                  title = "Portfolio Risk Distribution", status = "primary", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("risk_distribution")
                )
              )
      ),
      
      # Technical Analysis Tab
      tabItem(tabName = "technical",
              fluidRow(
                box(
                  title = "Technical Indicators", status = "primary", solidHeader = TRUE,
                  width = 3,
                  selectInput("chart_type", "Chart Type:",
                              choices = c("Candlestick", "Line", "Bar"),
                              selected = "Candlestick"),
                  selectInput("timeframe", "Timeframe:",
                              choices = c("1H", "4H", "1D", "1W"),
                              selected = "1D"),
                  checkboxInput("show_ma", "Moving Average", value = TRUE),
                  checkboxInput("show_support", "Support/Resistance", value = TRUE)
                ),
                box(
                  title = "Price Chart with Technical Analysis", status = "primary", solidHeader = TRUE,
                  width = 9,
                  plotlyOutput("technical_chart")
                )
              ),
              fluidRow(
                box(
                  title = "Candlestick Patterns Guide", status = "primary", solidHeader = TRUE,
                  width = 6,
                  DT::dataTableOutput("candlestick_patterns")
                ),
                box(
                  title = "Support & Resistance Levels", status = "primary", solidHeader = TRUE,
                  width = 6,
                  DT::dataTableOutput("support_resistance")
                )
              )
      ),
      
      # Market Participants Tab
      tabItem(tabName = "participants",
              fluidRow(
                box(
                  title = "Top 10 FX Providers Market Share", status = "primary", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("fx_providers")
                ),
                box(
                  title = "Hedge Fund Assets Under Management", status = "primary", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("hedge_funds")
                )
              ),
              fluidRow(
                box(
                  title = "Financial Institutions Overview", status = "primary", solidHeader = TRUE,
                  width = 12,
                  DT::dataTableOutput("institutions_table")
                )
              ),
              fluidRow(
                box(
                  title = "Central Banks Information", status = "primary", solidHeader = TRUE,
                  width = 6,
                  DT::dataTableOutput("central_banks")
                ),
                box(
                  title = "Market Participant Distribution", status = "primary", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("participant_distribution")
                )
              )
      ),
      
      # Economic Calendar Tab
      tabItem(tabName = "economic",
              fluidRow(
                box(
                  title = "Economic Data Filter", status = "primary", solidHeader = TRUE,
                  width = 3,
                  selectInput("impact_level", "Impact Level:",
                              choices = c("All", "High", "Medium", "Low"),
                              selected = "All"),
                  selectInput("country_filter", "Country:",
                              choices = c("All", "US", "UK", "EU", "JP", "AU", "CA"),
                              selected = "All"),
                  dateInput("event_date", "Event Date:", value = Sys.Date())
                ),
                box(
                  title = "Economic Calendar", status = "primary", solidHeader = TRUE,
                  width = 9,
                  DT::dataTableOutput("economic_calendar")
                )
              ),
              fluidRow(
                box(
                  title = "Data Source Information", status = "primary", solidHeader = TRUE,
                  width = 6,
                  DT::dataTableOutput("data_sources")
                ),
                box(
                  title = "Economic Indicators Impact", status = "primary", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("indicator_impact")
                )
              )
      ),
      
      # Support & Resistance Tab
      tabItem(tabName = "support",
              fluidRow(
                box(
                  title = "Level Settings", status = "primary", solidHeader = TRUE,
                  width = 3,
                  numericInput("current_price", "Current Price:", value = 1.1865, step = 0.0001),
                  numericInput("resistance_1", "Resistance 1:", value = 1.1920, step = 0.0001),
                  numericInput("support_1", "Support 1:", value = 1.1800, step = 0.0001),
                  sliderInput("strength", "Level Strength:", min = 1, max = 10, value = 5)
                ),
                box(
                  title = "Support & Resistance Chart", status = "primary", solidHeader = TRUE,
                  width = 9,
                  plotlyOutput("sr_chart")
                )
              ),
              fluidRow(
                box(
                  title = "Key Levels Analysis", status = "primary", solidHeader = TRUE,
                  width = 6,
                  DT::dataTableOutput("key_levels")
                ),
                box(
                  title = "Trend Analysis", status = "primary", solidHeader = TRUE,
                  width = 6,
                  verbatimTextOutput("trend_analysis"),
                  plotlyOutput("trend_chart")
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Sample data creation functions
  create_sample_data <- function() {
    dates <- seq(from = Sys.Date() - 30, to = Sys.Date(), by = "day")
    n <- length(dates)
    
    # Generate realistic price data
    set.seed(123)
    returns <- rnorm(n, 0, 0.01)
    prices <- cumprod(c(1.1865, 1 + returns[-1]))
    
    # Ensure we have correct length
    if(length(prices) != n) {
      prices <- c(1.1865, cumprod(1 + returns[-1]))
    }
    
    opens <- prices + rnorm(n, 0, 0.002)
    highs <- pmax(opens, prices) + abs(rnorm(n, 0.004, 0.002))
    lows <- pmin(opens, prices) - abs(rnorm(n, 0.004, 0.002))
    
    data.frame(
      Date = dates,
      Open = opens,
      High = highs,
      Low = lows,
      Close = prices,
      Volume = sample(500:2000, n, replace = TRUE)
    )
  }
  
  # FX Market Overview Outputs
  output$daily_volume <- renderValueBox({
    valueBox(
      value = "£6.6 Trillion",
      subtitle = "Daily FX Volume",
      icon = icon("chart-line"),
      color = "green"
    )
  })
  
  output$market_share <- renderValueBox({
    valueBox(
      value = "54.2%",
      subtitle = "UK Market Share",
      icon = icon("pound-sign"),
      color = "green"
    )
  })
  
  output$active_hours <- renderValueBox({
    valueBox(
      value = "07:00-18:00",
      subtitle = "Active Trading Hours (London Time)",
      icon = icon("clock"),
      color = "green"
    )
  })
  
  output$currency_turnover <- renderPlotly({
    currencies <- c("USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "CNY")
    percentages <- c(88.3, 32.3, 16.8, 12.8, 6.8, 5.0, 5.0, 4.3)
    
    p <- ggplot(data.frame(Currency = currencies, Percentage = percentages),
                aes(x = reorder(Currency, Percentage), y = Percentage)) +
      geom_bar(stat = "identity", fill = "#228B22") +
      coord_flip() +
      labs(title = "FX Turnover by Currency", x = "Currency", y = "Percentage (%)") +
      theme_minimal() +
      theme(
        axis.text.x = element_text(size = 10),
        axis.text.y = element_text(size = 10),
        plot.margin = margin(10, 10, 30, 10)
      )
    
    ggplotly(p, height = 350) %>%
      layout(margin = list(l = 80, r = 50, b = 50, t = 50))
  })
  
  output$trading_hours <- renderPlotly({
    hours <- 0:23
    volume <- c(100, 80, 60, 50, 60, 80, 120, 200, 350, 450, 500, 480, 420, 380, 400, 380, 350, 300, 250, 200, 180, 150, 120, 100)
    
    p <- ggplot(data.frame(Hour = hours, Volume = volume),
                aes(x = Hour, y = Volume)) +
      geom_area(fill = "#228B22", alpha = 0.7) +
      geom_line(color = "#1a5e1a", size = 1) +
      scale_x_continuous(breaks = seq(0, 23, 3), labels = seq(0, 23, 3)) +
      labs(title = "Intraday Volume Distribution", x = "Hour (London Time)", y = "Volume (Billions)") +
      theme_minimal() +
      theme(
        axis.text.x = element_text(size = 10),
        axis.text.y = element_text(size = 10),
        plot.margin = margin(10, 10, 30, 10)
      )
    
    ggplotly(p, height = 350) %>%
      layout(margin = list(l = 50, r = 50, b = 50, t = 50))
  })
  
  output$gfci_table <- DT::renderDataTable({
    gfci_data <- data.frame(
      Rank = 1:10,
      City = c("New York", "London", "Hong Kong", "Singapore", "San Francisco", "Zurich", "Tokyo", "Toronto", "Frankfurt", "Sydney"),
      Country = c("United States", "United Kingdom", "Hong Kong", "Singapore", "United States", "Switzerland", "Japan", "Canada", "Germany", "Australia"),
      Rating = c(760, 743, 718, 691, 629, 627, 620, 618, 597, 593)
    )
    DT::datatable(gfci_data, options = list(pageLength = 10, searching = FALSE))
  })
  
  # Currency Analysis Outputs
  output$currency_chart <- renderPlotly({
    tryCatch({
      # Generate more realistic price data based on inputs
      set.seed(42)
      n_days <- 30
      dates <- seq(from = Sys.Date() - n_days + 1, to = Sys.Date(), by = "day")
      
      # Create price series around the input exchange rate
      base_price <- input$exchange_rate
      returns <- rnorm(n_days, 0, 0.008) # Daily volatility
      
      # Generate OHLC data
      opens <- numeric(n_days)
      highs <- numeric(n_days)
      lows <- numeric(n_days)
      closes <- numeric(n_days)
      
      opens[1] <- base_price
      for(i in 1:n_days) {
        if(i > 1) opens[i] <- closes[i-1]
        
        closes[i] <- opens[i] * (1 + returns[i])
        highs[i] <- max(opens[i], closes[i]) + abs(rnorm(1, 0, 0.003))
        lows[i] <- min(opens[i], closes[i]) - abs(rnorm(1, 0, 0.003))
      }
      
      price_data <- data.frame(
        Date = dates,
        Open = opens,
        High = highs,
        Low = lows,
        Close = closes
      )
      
      p <- plot_ly(price_data, x = ~Date, type = "candlestick",
                   open = ~Open, high = ~High, low = ~Low, close = ~Close,
                   increasing = list(line = list(color = "#228B22")),
                   decreasing = list(line = list(color = "#dc3545"))) %>%
        layout(title = paste(input$base_currency, "/", input$term_currency, "Exchange Rate"),
               xaxis = list(title = "Date"),
               yaxis = list(title = "Price"),
               margin = list(l = 50, r = 50, b = 50, t = 50))
      
      return(p)
    }, error = function(e) {
      # Fallback simple chart
      dates <- seq(from = Sys.Date() - 29, to = Sys.Date(), by = "day")
      prices <- rep(input$exchange_rate, 30) + cumsum(rnorm(30, 0, 0.005))
      
      plot_ly(x = dates, y = prices, type = "scatter", mode = "lines",
              line = list(color = "#228B22")) %>%
        layout(title = paste(input$base_currency, "/", input$term_currency, "Exchange Rate"),
               xaxis = list(title = "Date"),
               yaxis = list(title = "Price"))
    })
  })
  
  output$usd_index <- renderPlotly({
    components <- c("EUR", "JPY", "GBP", "CAD", "SEK", "CHF")
    weights <- c(57.6, 13.6, 11.9, 9.1, 4.2, 3.6)
    
    p <- plot_ly(labels = ~components, values = ~weights, type = 'pie',
                 marker = list(colors = c("#228B22", "#2e8b57", "#32cd32", "#90ee90", "#98fb98", "#f0fff0"))) %>%
      layout(title = "USD Index Components (%)")
    
    p
  })
  
  output$fx_reserves <- renderPlotly({
    countries <- c("China", "Japan", "Switzerland", "India", "Russia", "Taiwan", "Hong Kong", "Saudi Arabia")
    reserves <- c(3301, 1322, 1064, 593, 585, 545, 465, 451)
    
    p <- ggplot(data.frame(Country = countries, Reserves = reserves),
                aes(x = reorder(Country, Reserves), y = Reserves, fill = Country)) +
      geom_bar(stat = "identity", fill = "#228B22") +
      coord_flip() +
      labs(title = "FX Reserves by Country ($ Billions)", x = "Country", y = "Reserves ($ Billions)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Trading Performance Outputs
  output$profit_loss <- renderValueBox({
    wins <- round(input$total_trades * input$hit_rate / 100)
    losses <- input$total_trades - wins
    profit <- wins * input$reward_risk - losses
    profit_percent <- round((profit / input$total_trades) * 100, 2)
    
    valueBox(
      value = paste0(ifelse(profit > 0, "+", ""), profit_percent, "%"),
      subtitle = "Expected Return per Trade",
      icon = icon("percentage"),
      color = if(profit > 0) "green" else "red"
    )
  })
  
  output$breakeven_rate <- renderValueBox({
    breakeven <- round(100 / (1 + input$reward_risk), 1)
    
    valueBox(
      value = paste0(breakeven, "%"),
      subtitle = "Breakeven Hit Rate",
      icon = icon("balance-scale"),
      color = "green"
    )
  })
  
  output$max_drawdown <- renderValueBox({
    # Simple drawdown calculation
    expected_loss_streak <- round(log(0.05) / log(1 - input$hit_rate/100))
    max_dd <- round(expected_loss_streak * (100 / input$total_trades) * input$max_risk_percent, 1)
    
    valueBox(
      value = paste0(max_dd, "%"),
      subtitle = "Estimated Max Drawdown",
      icon = icon("arrow-down"),
      color = "yellow"
    )
  })
  
  output$hit_rate_analysis <- renderPlotly({
    hit_rates <- seq(20, 80, 5)
    rrr_values <- seq(0.5, 4, 0.1)
    
    # Create grid for profitability analysis
    grid_data <- expand.grid(HitRate = hit_rates, RRR = rrr_values)
    grid_data$Profit <- (grid_data$HitRate/100) * grid_data$RRR - (1 - grid_data$HitRate/100)
    
    p <- plot_ly(grid_data, x = ~HitRate, y = ~RRR, z = ~Profit, type = "contour",
                 colorscale = list(c(0, "red"), c(0.5, "white"), c(1, "#228B22"))) %>%
      layout(title = "Profitability Heat Map",
             xaxis = list(title = "Hit Rate (%)"),
             yaxis = list(title = "Reward-to-Risk Ratio"))
    
    p
  })
  
  output$drawdown_recovery <- renderPlotly({
    drawdown_pct <- seq(5, 90, 5)
    recovery_pct <- round(drawdown_pct / (100 - drawdown_pct) * 100, 1)
    
    p <- ggplot(data.frame(Drawdown = drawdown_pct, Recovery = recovery_pct),
                aes(x = Drawdown, y = Recovery)) +
      geom_line(color = "#228B22", size = 2) +
      geom_area(fill = "#228B22", alpha = 0.3) +
      labs(title = "Drawdown vs Recovery Required", 
           x = "Drawdown (%)", y = "Recovery Required (%)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$equity_curve <- renderPlotly({
    set.seed(42)
    trades <- input$total_trades
    hit_rate <- input$hit_rate / 100
    rrr <- input$reward_risk
    
    # Simulate trades
    results <- ifelse(runif(trades) < hit_rate, rrr, -1)
    cumulative <- cumsum(results)
    equity <- input$initial_capital * (1 + cumulative * 0.02) # 2% risk per trade
    
    p <- plot_ly(x = 1:trades, y = equity, type = "scatter", mode = "lines",
                 line = list(color = "#228B22", width = 2)) %>%
      layout(title = "Simulated Equity Curve",
             xaxis = list(title = "Trade Number"),
             yaxis = list(title = "Account Value (£)"))
    
    p
  })
  
  # Risk Management Outputs
  output$risk_amount <- renderValueBox({
    pip_value <- input$position_size / 10000 # Assuming EUR/USD
    risk_amount <- input$stop_loss_pips * pip_value
    
    valueBox(
      value = paste0("£", round(risk_amount, 2)),
      subtitle = "Risk Amount",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$rrr_ratio <- renderValueBox({
    rrr <- round(input$take_profit_pips / input$stop_loss_pips, 2)
    
    valueBox(
      value = paste0("1:", rrr),
      subtitle = "Risk:Reward Ratio",
      icon = icon("balance-scale"),
      color = "green"
    )
  })
  
  output$position_sizing <- renderValueBox({
    account_risk <- input$initial_capital * (input$max_risk_percent / 100)
    pip_value <- input$position_size / 10000
    max_position <- account_risk / (input$stop_loss_pips * pip_value) * input$position_size
    
    valueBox(
      value = paste0("£", scales::comma(round(max_position, 0))),
      subtitle = "Max Position Size",
      icon = icon("calculator"),
      color = "blue"
    )
  })
  
  output$cb_interventions <- renderPlotly({
    interventions <- data.frame(
      Date = as.Date(c("2012-01-15", "2015-01-15", "2016-06-23", "2020-03-15")),
      Event = c("SNB EUR/CHF Peg", "SNB Removes Peg", "Brexit Vote", "COVID-19 Response"),
      Impact = c(2.5, -3.8, -2.1, 1.9)
    )
    
    p <- plot_ly(interventions, x = ~Date, y = ~Impact, type = "scatter", mode = "markers+text",
                 text = ~Event, textposition = "top center", 
                 marker = list(size = 15, color = "#228B22")) %>%
      layout(title = "Major Central Bank Interventions",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Market Impact (%)"))
    
    p
  })
  
  output$risk_scenarios <- DT::renderDataTable({
    scenarios <- data.frame(
      Scenario = c("Best Case", "Expected", "Worst Case", "Black Swan"),
      Probability = c("10%", "60%", "25%", "5%"),
      Return = c("+15%", "+5%", "-8%", "-25%"),
      Action = c("Take Profits", "Hold", "Review", "Emergency Stop")
    )
    DT::datatable(scenarios, options = list(pageLength = 5, searching = FALSE))
  })
  
  output$risk_distribution <- renderPlotly({
    categories <- c("Currency Risk", "Interest Rate Risk", "Credit Risk", "Operational Risk", "Liquidity Risk")
    weights <- c(35, 25, 20, 15, 5)
    
    p <- plot_ly(labels = ~categories, values = ~weights, type = 'pie',
                 marker = list(colors = c("#228B22", "#2e8b57", "#32cd32", "#90ee90", "#98fb98"))) %>%
      layout(title = "Portfolio Risk Distribution")
    
    p
  })
  
  # Technical Analysis Outputs
  output$technical_chart <- renderPlotly({
    tryCatch({
      # Simple approach - create all data first, then build chart
      n_days <- 60
      base_price <- 1.1865
      
      # Create sequential dates
      dates <- seq.Date(from = as.Date(Sys.Date()) - 59, to = as.Date(Sys.Date()), by = "day")
      
      # Generate price data
      set.seed(123)
      price_changes <- cumsum(rnorm(n_days, 0, 0.008))
      closes <- base_price + price_changes
      
      # Create OHLC from closes
      opens <- c(base_price, closes[-n_days])
      highs <- pmax(opens, closes) + abs(rnorm(n_days, 0, 0.003))
      lows <- pmin(opens, closes) - abs(rnorm(n_days, 0, 0.003))
      
      # Build the basic chart first
      p <- plot_ly() %>%
        add_trace(x = dates, open = opens, high = highs, low = lows, close = closes,
                  type = "candlestick", name = "Price",
                  increasing = list(line = list(color = "#228B22")),
                  decreasing = list(line = list(color = "#dc3545")))
      
      # Add moving average if requested
      if(input$show_ma && n_days >= 20) {
        ma20 <- stats::filter(closes, rep(1/20, 20), sides = 1)
        ma20 <- as.numeric(ma20)
        p <- p %>% add_trace(x = dates, y = ma20, type = "scatter", mode = "lines",
                             line = list(color = "blue", width = 2), name = "MA20")
      }
      
      # Add support/resistance lines using shapes if requested
      if(input$show_support) {
        support_level <- min(lows, na.rm = TRUE)
        resistance_level <- max(highs, na.rm = TRUE)
        
        p <- p %>% layout(
          shapes = list(
            list(type = "line", x0 = min(dates), x1 = max(dates),
                 y0 = support_level, y1 = support_level,
                 line = list(color = "red", width = 2, dash = "dash")),
            list(type = "line", x0 = min(dates), x1 = max(dates),
                 y0 = resistance_level, y1 = resistance_level,
                 line = list(color = "green", width = 2, dash = "dash"))
          ),
          annotations = list(
            list(x = max(dates), y = support_level, text = "Support",
                 showarrow = FALSE, xanchor = "left", font = list(color = "red")),
            list(x = max(dates), y = resistance_level, text = "Resistance",
                 showarrow = FALSE, xanchor = "left", font = list(color = "green"))
          )
        )
      }
      
      p %>% layout(title = "Technical Analysis Chart",
                   xaxis = list(title = "Date"),
                   yaxis = list(title = "Price"))
      
    }, error = function(e) {
      # Ultra-simple fallback
      x_vals <- 1:60
      y_vals <- 1.1865 + cumsum(rnorm(60, 0, 0.005))
      
      plot_ly(x = x_vals, y = y_vals, type = "scatter", mode = "lines",
              line = list(color = "#228B22")) %>%
        layout(title = "Technical Analysis Chart",
               xaxis = list(title = "Period"),
               yaxis = list(title = "Price"))
    })
  })
  
  output$candlestick_patterns <- DT::renderDataTable({
    patterns <- data.frame(
      Pattern = c("Doji", "Hammer", "Shooting Star", "Engulfing", "Piercing"),
      Type = c("Reversal", "Reversal", "Reversal", "Reversal", "Reversal"),
      Reliability = c("Medium", "High", "High", "Very High", "High"),
      Confirmation = c("Required", "Preferred", "Required", "Strong", "Required")
    )
    DT::datatable(patterns, options = list(pageLength = 10, searching = FALSE))
  })
  
  output$support_resistance <- DT::renderDataTable({
    levels <- data.frame(
      Level = c(1.1920, 1.1865, 1.1800, 1.1750, 1.1680),
      Type = c("Resistance", "Current", "Support", "Support", "Strong Support"),
      Strength = c(7, 0, 8, 6, 9),
      Distance = c(55, 0, -65, -115, -185)
    )
    DT::datatable(levels, options = list(pageLength = 10, searching = FALSE))
  })
  
  # Market Participants Outputs
  output$fx_providers <- renderPlotly({
    providers <- c("JPMorgan", "UBS", "Deutsche Bank", "XTX Markets", "Citi", "Jump Trading", "Goldman Sachs", "BofA", "State Street", "HSBC")
    market_share <- c(10.8, 8.1, 7.9, 6.2, 5.1, 4.9, 4.5, 4.2, 4.0, 3.8)
    
    p <- ggplot(data.frame(Provider = providers, Share = market_share),
                aes(x = reorder(Provider, Share), y = Share, fill = Provider)) +
      geom_bar(stat = "identity", fill = "#228B22") +
      coord_flip() +
      labs(title = "Top 10 FX Providers Market Share", x = "Provider", y = "Market Share (%)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$hedge_funds <- renderPlotly({
    funds <- c("Bridgewater", "AQR", "Renaissance", "Two Sigma", "Millennium", "Citadel", "Elliott", "DE Shaw", "Baupost", "Viking")
    aum <- c(140, 71, 65, 60, 55, 52, 48, 47, 40, 39)
    
    p <- ggplot(data.frame(Fund = funds, AUM = aum),
                aes(x = reorder(Fund, AUM), y = AUM, fill = Fund)) +
      geom_bar(stat = "identity", fill = "#228B22") +
      coord_flip() +
      labs(title = "Top Hedge Funds by AUM ($ Billions)", x = "Hedge Fund", y = "AUM ($ Billions)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$institutions_table <- DT::renderDataTable({
    institutions <- data.frame(
      Category = c("Investment Banks", "Commercial Banks", "Hedge Funds", "Asset Managers", "Central Banks", "Retail Brokers"),
      Function = c("Market Making", "Commercial Banking", "Alternative Investments", "Portfolio Management", "Monetary Policy", "Retail Trading"),
      Assets = c("Multi-Trillion", "Multi-Trillion", "$4 Trillion", "$100+ Trillion", "Variable", "Billions"),
      Examples = c("Goldman Sachs, JPMorgan", "HSBC, Citi", "Bridgewater, Citadel", "BlackRock, Vanguard", "Fed, ECB, BoE", "IG Index, FXCM")
    )
    DT::datatable(institutions, options = list(pageLength = 10, searching = FALSE))
  })
  
  output$central_banks <- DT::renderDataTable({
    cb_data <- data.frame(
      Abbreviation = c("FED", "ECB", "BOE", "BOJ", "RBA", "RBNZ", "BOC", "SNB"),
      Bank = c("Federal Reserve", "European Central Bank", "Bank of England", "Bank of Japan", "Reserve Bank of Australia", "Reserve Bank of New Zealand", "Bank of Canada", "Swiss National Bank"),
      Currency = c("USD", "EUR", "GBP", "JPY", "AUD", "NZD", "CAD", "CHF"),
      Rate = c("5.25-5.50%", "4.50%", "5.25%", "-0.10%", "4.35%", "5.50%", "5.00%", "1.75%")
    )
    DT::datatable(cb_data, options = list(pageLength = 10, searching = FALSE))
  })
  
  output$participant_distribution <- renderPlotly({
    participants <- c("Banks", "Hedge Funds", "Asset Managers", "Corporations", "Retail", "Central Banks")
    volume_share <- c(42, 18, 15, 12, 8, 5)
    
    p <- plot_ly(labels = ~participants, values = ~volume_share, type = 'pie',
                 marker = list(colors = c("#228B22", "#2e8b57", "#32cd32", "#90ee90", "#98fb98", "#f0fff0"))) %>%
      layout(title = "FX Market Participants by Volume Share")
    
    p
  })
  
  # Economic Calendar Outputs
  output$economic_calendar <- DT::renderDataTable({
    economic_events <- data.frame(
      Time = c("08:30", "10:00", "14:30", "16:00", "20:00"),
      Country = c("GBP", "EUR", "USD", "USD", "USD"),
      Event = c("GDP QoQ", "CPI YoY", "Non-Farm Payrolls", "Fed Interest Rate Decision", "FOMC Press Conference"),
      Impact = c("High", "High", "High", "High", "High"),
      Forecast = c("0.2%", "2.1%", "203K", "5.50%", ""),
      Previous = c("0.1%", "2.4%", "150K", "5.25%", "")
    )
    
    # Filter based on inputs
    if(input$impact_level != "All") {
      economic_events <- economic_events[economic_events$Impact == input$impact_level, ]
    }
    if(input$country_filter != "All") {
      economic_events <- economic_events[economic_events$Country == input$country_filter, ]
    }
    
    DT::datatable(economic_events, options = list(pageLength = 10, searching = TRUE))
  })
  
  output$data_sources <- DT::renderDataTable({
    sources <- data.frame(
      Category = c("Economic Calendars", "Historical Data", "News Feeds", "Central Banks", "Market Data"),
      Sources = c("FXStreet, ForexFactory", "Trading Economics", "Bloomberg, Reuters", "Fed, ECB, BoE", "MetaTrader, TradingView"),
      Update_Frequency = c("Real-time", "Daily/Monthly", "Real-time", "As Scheduled", "Real-time"),
      Reliability = c("High", "Very High", "High", "Excellent", "High")
    )
    DT::datatable(sources, options = list(pageLength = 10, searching = FALSE))
  })
  
  output$indicator_impact <- renderPlotly({
    indicators <- c("Interest Rates", "NFP", "GDP", "CPI", "Retail Sales", "PMI")
    impact_score <- c(10, 9, 8, 7, 6, 5)
    
    p <- ggplot(data.frame(Indicator = indicators, Impact = impact_score),
                aes(x = reorder(Indicator, Impact), y = Impact, fill = Indicator)) +
      geom_bar(stat = "identity", fill = "#228B22") +
      coord_flip() +
      labs(title = "Economic Indicators Market Impact", x = "Indicator", y = "Impact Score (1-10)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Support & Resistance Outputs
  output$sr_chart <- renderPlotly({
    tryCatch({
      # Simple approach - create all data first, then build chart
      n_days <- 30
      
      # Create sequential dates
      dates <- seq.Date(from = as.Date(Sys.Date()) - 29, to = as.Date(Sys.Date()), by = "day")
      
      # Generate price data around current price
      set.seed(456)
      price_changes <- cumsum(rnorm(n_days, 0, 0.005))
      closes <- input$current_price + price_changes
      
      # Ensure prices respect S/R levels
      closes <- pmax(closes, input$support_1 + 0.001)
      closes <- pmin(closes, input$resistance_1 - 0.001)
      
      # Create OHLC from closes
      opens <- c(input$current_price, closes[-n_days])
      highs <- pmax(opens, closes) + abs(rnorm(n_days, 0, 0.002))
      lows <- pmin(opens, closes) - abs(rnorm(n_days, 0, 0.002))
      
      # Respect S/R on highs and lows
      highs <- pmin(highs, input$resistance_1)
      lows <- pmax(lows, input$support_1)
      
      # Build the chart
      p <- plot_ly() %>%
        add_trace(x = dates, open = opens, high = highs, low = lows, close = closes,
                  type = "candlestick", name = "Price",
                  increasing = list(line = list(color = "#228B22")),
                  decreasing = list(line = list(color = "#dc3545"))) %>%
        # Add horizontal lines using shapes
        layout(title = "Support & Resistance Analysis",
               xaxis = list(title = "Date"),
               yaxis = list(title = "Price"),
               shapes = list(
                 # Resistance line
                 list(type = "line", x0 = min(dates), x1 = max(dates),
                      y0 = input$resistance_1, y1 = input$resistance_1,
                      line = list(color = "red", width = 2, dash = "dash")),
                 # Current price line
                 list(type = "line", x0 = min(dates), x1 = max(dates),
                      y0 = input$current_price, y1 = input$current_price,
                      line = list(color = "blue", width = 2)),
                 # Support line
                 list(type = "line", x0 = min(dates), x1 = max(dates),
                      y0 = input$support_1, y1 = input$support_1,
                      line = list(color = "green", width = 2, dash = "dash"))
               ),
               annotations = list(
                 list(x = max(dates), y = input$resistance_1, text = paste("R1:", input$resistance_1),
                      showarrow = FALSE, xanchor = "left", font = list(color = "red")),
                 list(x = max(dates), y = input$current_price, text = paste("Current:", input$current_price),
                      showarrow = FALSE, xanchor = "left", font = list(color = "blue")),
                 list(x = max(dates), y = input$support_1, text = paste("S1:", input$support_1),
                      showarrow = FALSE, xanchor = "left", font = list(color = "green"))
               ))
      
      return(p)
      
    }, error = function(e) {
      # Ultra-simple fallback
      x_vals <- 1:30
      y_vals <- input$current_price + cumsum(rnorm(30, 0, 0.003))
      
      plot_ly(x = x_vals, y = y_vals, type = "scatter", mode = "lines",
              line = list(color = "#228B22")) %>%
        layout(title = "Support & Resistance Analysis",
               xaxis = list(title = "Period"),
               yaxis = list(title = "Price"),
               shapes = list(
                 list(type = "line", x0 = 1, x1 = 30,
                      y0 = input$resistance_1, y1 = input$resistance_1,
                      line = list(color = "red", dash = "dash")),
                 list(type = "line", x0 = 1, x1 = 30,
                      y0 = input$support_1, y1 = input$support_1,
                      line = list(color = "green", dash = "dash"))
               ))
    })
  })
  
  output$key_levels <- DT::renderDataTable({
    levels_data <- data.frame(
      Level = c(input$resistance_1, input$current_price, input$support_1),
      Type = c("Resistance", "Current Price", "Support"),
      Distance_Pips = c(
        round((input$resistance_1 - input$current_price) * 10000, 0),
        0,
        round((input$support_1 - input$current_price) * 10000, 0)
      ),
      Strength = c(input$strength, 0, input$strength),
      Status = c("Active", "Market", "Active")
    )
    DT::datatable(levels_data, options = list(pageLength = 5, searching = FALSE))
  })
  
  output$trend_analysis <- renderText({
    if(input$current_price > input$support_1 && input$current_price < input$resistance_1) {
      trend <- "Sideways/Consolidation"
      bias <- "Neutral - Price trading between key levels"
    } else if(input$current_price > input$resistance_1) {
      trend <- "Bullish"
      bias <- "Upward - Price above resistance, potential continuation"
    } else {
      trend <- "Bearish"  
      bias <- "Downward - Price below support, potential continuation"
    }
    
    paste0("Current Trend: ", trend, "\n",
           "Market Bias: ", bias, "\n",
           "Volatility: ", ifelse(input$strength > 7, "Low", ifelse(input$strength > 4, "Medium", "High")), "\n",
           "Trade Setup: ", ifelse(trend == "Sideways/Consolidation", "Range Trading", "Trend Following"))
  })
  
  output$trend_chart <- renderPlotly({
    # Simple trend visualization
    x <- 1:10
    if(input$current_price > input$resistance_1) {
      y <- seq(input$support_1, input$resistance_1 + 0.01, length.out = 10)
      color <- "#228B22"
      title <- "Bullish Trend"
    } else if(input$current_price < input$support_1) {
      y <- seq(input$resistance_1, input$support_1 - 0.01, length.out = 10)
      color <- "#dc3545"
      title <- "Bearish Trend"
    } else {
      y <- rep(input$current_price, 10) + sin(x) * 0.002
      color <- "#ffc107"
      title <- "Sideways Trend"
    }
    
    p <- plot_ly(x = x, y = y, type = "scatter", mode = "lines+markers",
                 line = list(color = color, width = 3),
                 marker = list(size = 8, color = color)) %>%
      layout(title = title,
             xaxis = list(title = "Time", showticklabels = FALSE),
             yaxis = list(title = "Price"))
    
    p
  })
}

# Run the application
shinyApp(ui = ui, server = server)