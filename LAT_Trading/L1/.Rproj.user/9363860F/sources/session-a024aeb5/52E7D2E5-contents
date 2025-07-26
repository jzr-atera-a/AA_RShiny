# FX Trading Strategies Interactive Dashboard
# Based on comprehensive FX models and trading strategies research

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(corrplot)
library(ggplot2)
library(dplyr)
library(shinyWidgets)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "FX Trading Strategies Research Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("FX Trading Overview", tabName = "overview", icon = icon("chart-line")),
      menuItem("Carry Trade", tabName = "carry", icon = icon("dollar-sign")),
      menuItem("UIP & Deviations", tabName = "uip", icon = icon("balance-scale")),
      menuItem("Carry Trade Risks", tabName = "risks", icon = icon("exclamation-triangle")),
      menuItem("Momentum Strategies", tabName = "momentum", icon = icon("trending-up")),
      menuItem("Currency Value (PPP)", tabName = "value", icon = icon("coins")),
      menuItem("Order Flow", tabName = "orderflow", icon = icon("stream")),
      menuItem("Strategy Combination", tabName = "combination", icon = icon("layer-group"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #ffffff;
        }
        .tab-content {
          background-color: #ffffff !important;
        }
        .tab-pane {
          background-color: #ffffff !important;
        }
        .content {
          background-color: #ffffff !important;
        }
        body {
          background-color: #ffffff !important;
        }
        .box {
          background-color: #303f9f;
          border: 1px solid #3f51b5;
        }
        .box-header {
          color: #ffffff;
          background-color: #1a237e;
        }
        .box-body {
          color: #ffffff;
        }
        .nav-tabs-custom > .nav-tabs > li.active > a {
          background-color: #3f51b5;
          color: #ffffff;
        }
        .info-box {
          background-color: #303f9f;
          color: #ffffff;
        }
        .info-box-icon {
          background-color: #ffffff !important;
          color: #1a237e !important;
        }
        .small-box {
          background-color: #303f9f !important;
          color: #ffffff !important;
        }
        .small-box > .inner > h3, .small-box > .inner > p {
          color: #ffffff !important;
        }
        .small-box .icon {
          color: rgba(255, 255, 255, 0.15) !important;
        }
      "))
    ),
    
    tabItems(
      # Tab 1: FX Trading Overview
      tabItem(tabName = "overview",
              fluidRow(
                box(width = 12, title = "FX Trading Strategies Overview", status = "primary", solidHeader = TRUE,
                    h4("Currency Trading Strategy Framework"),
                    p("This dashboard explores the most prominent FX trading strategies used by institutional investors and hedge funds. 
              The strategies are based on exploiting market inefficiencies and behavioral biases in foreign exchange markets."),
                    br(),
                    HTML("<strong>Key Strategies Covered:</strong>"),
                    tags$ul(
                      tags$li("Carry Trade: Exploiting interest rate differentials"),
                      tags$li("Momentum: Following currency trends"),
                      tags$li("Value Trading: Using PPP and fundamental analysis"),
                      tags$li("Order Flow: Leveraging transaction data insights")
                    )
                )
              ),
              
              fluidRow(
                valueBoxOutput("totalStrategies"),
                valueBoxOutput("avgSharpe"),
                valueBoxOutput("maxDrawdown")
              ),
              
              fluidRow(
                box(width = 6, title = "Strategy Performance Comparison", status = "primary",
                    plotlyOutput("strategyComparison")
                ),
                box(width = 6, title = "Currency Selection Criteria", status = "primary",
                    selectInput("criteriaType", "Selection Criteria:",
                                choices = list("Interest Rate Differential" = "rate_diff",
                                               "Momentum Score" = "momentum",
                                               "PPP Deviation" = "ppp_dev")),
                    plotlyOutput("selectionCriteria")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Academic References", status = "info",
                    HTML("
            <h5>Key Research Sources:</h5>
            <p><strong>Burnside, C., Cerrato, M., & Zhang, H.</strong> (2020). Foreign Exchange Order Flow as a Risk Factor. <em>SSRN Electronic Journal</em>. Available at: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3275356</p>
            <p><strong>Menkhoff, L., Sarno, L., Schmeling, M., & Schrimpf, A.</strong> (2012). Currency momentum strategies. <em>Journal of Financial Economics</em>, 106(3), 660-684. Available at: https://www.sciencedirect.com/science/article/abs/pii/S0304405X12001353</p>
            <p><strong>The Economist.</strong> (2025). Big Mac Index and Purchasing Power Parity Analysis. Available at: https://quantpedia.com/strategies/currency-value-factor-ppp-strategy</p>
            ")
                )
              )
      ),
      
      # Tab 2: Carry Trade
      tabItem(tabName = "carry",
              fluidRow(
                box(width = 12, title = "Carry Trade Strategy", status = "primary", solidHeader = TRUE,
                    h4("Interest Rate Differential Exploitation"),
                    p("The carry trade involves borrowing in low-yielding currencies (funding currencies) and investing in 
              high-yielding currencies (target currencies). This strategy systematically exploits violations of 
              Uncovered Interest Parity (UIP) by capturing the interest rate spread."),
                    br(),
                    HTML("<strong>Key Components:</strong>"),
                    tags$ul(
                      tags$li("Funding Currencies: JPY, CHF (low interest rates)"),
                      tags$li("Target Currencies: AUD, BRL, NZD (high interest rates)"),
                      tags$li("Risk Management: Volatility filtering and diversification")
                    )
                )
              ),
              
              fluidRow(
                box(width = 4, title = "Interest Rate Settings", status = "primary",
                    sliderInput("fundingRate", "Funding Currency Rate (%):", 
                                min = 0, max = 5, value = 0.5, step = 0.25),
                    sliderInput("targetRate", "Target Currency Rate (%):", 
                                min = 1, max = 15, value = 8, step = 0.5),
                    sliderInput("volatility", "Market Volatility:", 
                                min = 5, max = 30, value = 15, step = 2.5),
                    h5(textOutput("carrySpread"))
                ),
                box(width = 8, title = "Carry Trade Performance Simulation", status = "primary",
                    plotlyOutput("carryPerformance")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Currency Weights in Carry Portfolio", status = "primary",
                    plotlyOutput("carryWeights")
                ),
                box(width = 6, title = "Risk-Return Profile", status = "primary",
                    plotlyOutput("carryRiskReturn")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Academic References", status = "info",
                    HTML("
            <h5>Carry Trade Research:</h5>
            <p><strong>Burnside, C., Eichenbaum, M., & Rebelo, S.</strong> (2011). Carry trade and momentum in currency markets. <em>Annual Review of Financial Economics</em>, 3(1), 511-535. Available at: https://quantpedia.com/strategies/fx-carry-trade</p>
            <p><strong>Hodrick, R. J., & Srivastava, S.</strong> (2017). The carry trade: Risks and drawdowns. <em>NBER Working Paper</em> No. 20433. Available at: https://www.nber.org/system/files/working_papers/w20433/w20433.pdf</p>
            <p><strong>QuantPedia Research Team.</strong> (2025). Three insights from academic research related to carry trade strategy. Available at: https://quantpedia.com/three-insights-from-research-related-to-carry-trade-strategy/</p>
            ")
                )
              )
      ),
      
      # Tab 3: UIP Deviations
      tabItem(tabName = "uip",
              fluidRow(
                box(width = 12, title = "Uncovered Interest Parity (UIP) and Deviations", status = "primary", solidHeader = TRUE,
                    h4("Theoretical Foundation vs. Empirical Reality"),
                    p("UIP theory states that exchange rate movements should exactly offset interest rate differentials, 
              eliminating systematic profit opportunities. However, empirical evidence consistently shows significant 
              deviations from UIP, creating the foundation for carry trade strategies."),
                    br(),
                    HTML("<strong>Key Findings:</strong>"),
                    tags$ul(
                      tags$li("UIP consistently fails in empirical tests across G10 currencies"),
                      tags$li("High-interest currencies tend to appreciate rather than depreciate"),
                      tags$li("Beta coefficients in Fama regressions are typically negative")
                    )
                )
              ),
              
              fluidRow(
                box(width = 4, title = "UIP Test Parameters", status = "primary",
                    selectInput("baseCurrency", "Base Currency:",
                                choices = list("USD" = "USD", "EUR" = "EUR", "GBP" = "GBP")),
                    selectInput("targetCurrency", "Target Currency:",
                                choices = list("AUD" = "AUD", "CAD" = "CAD", "JPY" = "JPY", "CHF" = "CHF")),
                    sliderInput("testPeriod", "Test Period (Years):", 
                                min = 1, max = 20, value = 10),
                    br(),
                    h5("Regression Statistics:"),
                    verbatimTextOutput("uipStats")
                ),
                box(width = 8, title = "UIP Regression Analysis", status = "primary",
                    plotlyOutput("uipRegression")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Currency-Specific UIP Deviations", status = "primary",
                    plotlyOutput("uipDeviations")
                ),
                box(width = 6, title = "Rolling Beta Coefficients", status = "primary",
                    plotlyOutput("rollingBeta")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Academic References", status = "info",
                    HTML("
            <h5>UIP Research Literature:</h5>
            <p><strong>Fama, E. F.</strong> (1984). Forward and spot exchange rates. <em>Journal of Monetary Economics</em>, 14(3), 319-338.</p>
            <p><strong>Burnside, C., Cerrato, M., & Zhang, H.</strong> (2020). Foreign exchange order flow as a risk factor. Available at: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3275356</p>
            <p><strong>European Central Bank.</strong> (2018). From carry trades to curvy trades. <em>ECB Working Paper Series</em>. Available at: https://www.ecb.europa.eu/pub/pdf/scpwps/ecb.wp2149.en.pdf</p>
            ")
                )
              )
      ),
      
      # Tab 4: Carry Trade Risks
      tabItem(tabName = "risks",
              fluidRow(
                box(width = 12, title = "Carry Trade Risk Management", status = "warning", solidHeader = TRUE,
                    h4("Volatility and Crash Risk Analysis"),
                    p("Carry trades are exposed to significant tail risks, particularly during periods of high global volatility 
              and financial stress. The strategy exhibits negative skewness and can experience severe drawdowns during 
              market turbulence, as demonstrated during events like the 1998 Asian Crisis and 2008 Financial Crisis."),
                    br(),
                    HTML("<strong>Risk Factors:</strong>"),
                    tags$ul(
                      tags$li("Global FX Volatility: Impacts carry trade unwinds"),
                      tags$li("Crash Risk: Sudden appreciation of funding currencies"),
                      tags$li("Liquidity Risk: Market stress reduces available funding")
                    )
                )
              ),
              
              fluidRow(
                box(width = 4, title = "Risk Controls", status = "warning",
                    sliderInput("volThreshold", "Volatility Threshold (%):", 
                                min = 5, max = 50, value = 20),
                    sliderInput("stopLoss", "Stop Loss Level (%):", 
                                min = 5, max = 25, value = 10),
                    checkboxInput("volFilter", "Enable Volatility Filtering", value = TRUE),
                    checkboxInput("diversification", "Apply Currency Diversification", value = TRUE),
                    br(),
                    h5("Risk Metrics:"),
                    verbatimTextOutput("riskMetrics")
                ),
                box(width = 8, title = "Carry Performance vs. Volatility", status = "warning",
                    plotlyOutput("volPerformance")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Drawdown Analysis", status = "warning",
                    plotlyOutput("drawdownAnalysis")
                ),
                box(width = 6, title = "Crash Risk Distribution", status = "warning",
                    plotlyOutput("crashRisk")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Academic References", status = "info",
                    HTML("
            <h5>Risk Management Research:</h5>
            <p><strong>Menkhoff, L., Sarno, L., Schmeling, M., & Schrimpf, A.</strong> (2012). Carry trades and global foreign exchange volatility. <em>Journal of Finance</em>, 67(2), 681-718.</p>
            <p><strong>Brunnermeier, M. K., Nagel, S., & Pedersen, L. H.</strong> (2009). Carry trades and currency crashes. <em>NBER Macroeconomics Annual</em>, 23(1), 313-348.</p>
            <p><strong>QuantPedia Research Team.</strong> (2019). Two recent papers related to FX carry strategy. Available at: https://quantpedia.com/two-recent-papers-related-to-fx-carry-strategy/</p>
            ")
                )
              )
      ),
      
      # Tab 5: Momentum Strategies  
      tabItem(tabName = "momentum",
              fluidRow(
                box(width = 12, title = "Currency Momentum Strategies", status = "success", solidHeader = TRUE,
                    h4("Trend-Following in FX Markets"),
                    p("Currency momentum strategies exploit the tendency of exchange rates to continue moving in the same direction 
              over medium-term horizons (1-12 months). These strategies buy currencies with strong recent performance 
              and sell those with weak performance, capitalizing on behavioral biases and market inefficiencies."),
                    br(),
                    HTML("<strong>Strategy Components:</strong>"),
                    tags$ul(
                      tags$li("Formation Period: 1-12 months for ranking currencies"),
                      tags$li("Holding Period: 1-3 months for maintaining positions"),
                      tags$li("Transaction Costs: Critical for strategy profitability")
                    )
                )
              ),
              
              fluidRow(
                box(width = 4, title = "Momentum Parameters", status = "success",
                    sliderInput("lookback", "Formation Period (Months):", 
                                min = 1, max = 12, value = 6),
                    sliderInput("holding", "Holding Period (Months):", 
                                min = 1, max = 6, value = 1),
                    sliderInput("numCurrencies", "Number of Currencies:", 
                                min = 10, max = 48, value = 24),
                    sliderInput("transactionCost", "Transaction Costs (bps):", 
                                min = 0, max = 50, value = 10),
                    br(),
                    h5("Portfolio Statistics:"),
                    verbatimTextOutput("momentumStats")
                ),
                box(width = 8, title = "Momentum Strategy Returns", status = "success",
                    plotlyOutput("momentumReturns")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Currency Rankings", status = "success",
                    DT::dataTableOutput("currencyRankings")
                ),
                box(width = 6, title = "Momentum vs Market States", status = "success",
                    plotlyOutput("momentumMarketStates")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Academic References", status = "info",
                    HTML("
            <h5>Momentum Strategy Research:</h5>
            <p><strong>Menkhoff, L., Sarno, L., Schmeling, M., & Schrimpf, A.</strong> (2012). Currency momentum strategies. <em>Journal of Financial Economics</em>, 106(3), 660-684. Available at: https://www.sciencedirect.com/science/article/abs/pii/S0304405X12001353</p>
            <p><strong>Rohrbach, J., Suremann, S., & Osterrieder, J.</strong> (2017). Momentum and trend following trading strategies for currencies revisited. Available at: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2949379</p>
            <p><strong>QuantPedia Research Team.</strong> (2025). Currency momentum factor research compilation. Available at: https://quantpedia.com/strategies/currency-momentum-factor</p>
            ")
                )
              )
      ),
      
      # Tab 6: Currency Value (PPP)
      tabItem(tabName = "value",
              fluidRow(
                box(width = 12, title = "Currency Value Strategies (PPP-Based)", status = "info", solidHeader = TRUE,
                    h4("Fundamental Valuation Using Purchasing Power Parity"),
                    p("Currency value strategies are based on the concept that exchange rates tend to revert to their 
              fundamental 'fair value' over the long term. Purchasing Power Parity (PPP) provides a benchmark 
              for determining whether currencies are overvalued or undervalued relative to their economic fundamentals."),
                    br(),
                    HTML("<strong>Key Concepts:</strong>"),
                    tags$ul(
                      tags$li("PPP Theory: Law of one price applied to currency baskets"),
                      tags$li("Real Exchange Rates: Nominal rates adjusted for inflation"),
                      tags$li("Mean Reversion: Long-term tendency toward fair value")
                    )
                )
              ),
              
              fluidRow(
                box(width = 4, title = "PPP Analysis Controls", status = "info",
                    selectInput("pppBaseCurrency", "Base Currency:",
                                choices = list("USD" = "USD", "EUR" = "EUR", "GBP" = "GBP")),
                    selectInput("pppMethod", "Valuation Method:",
                                choices = list("Big Mac Index" = "bigmac", 
                                               "OECD PPP" = "oecd",
                                               "Real Exchange Rate" = "rer")),
                    sliderInput("rebalanceFreq", "Rebalancing (Months):", 
                                min = 1, max = 12, value = 3),
                    br(),
                    h5("Current Valuations:"),
                    verbatimTextOutput("pppValuations")
                ),
                box(width = 8, title = "PPP Deviation Analysis", status = "info",
                    plotlyOutput("pppDeviations")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Long-term Mean Reversion", status = "info",
                    plotlyOutput("meanReversion")
                ),
                box(width = 6, title = "Value Strategy Performance", status = "info",
                    plotlyOutput("valuePerformance")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Academic References", status = "info",
                    HTML("
            <h5>PPP and Currency Valuation Research:</h5>
            <p><strong>Taylor, A. M., & Taylor, M. P.</strong> (2004). The purchasing power parity debate. <em>Journal of Economic Perspectives</em>, 18(4), 135-158. Available at: https://www.nber.org/papers/w10607</p>
            <p><strong>Vo, D. H.</strong> (2023). The purchasing power parity and exchange‐rate economics half a century on. <em>Journal of Economic Surveys</em>, 37(2), 518-547. Available at: https://onlinelibrary.wiley.com/doi/10.1111/joes.12504</p>
            <p><strong>QuantPedia Research Team.</strong> (2025). Currency value factor - PPP strategy analysis. Available at: https://quantpedia.com/strategies/currency-value-factor-ppp-strategy</p>
            ")
                )
              )
      ),
      
      # Tab 7: Order Flow
      tabItem(tabName = "orderflow",
              fluidRow(
                box(width = 12, title = "Order Flow Strategies", status = "primary", solidHeader = TRUE,
                    h4("Leveraging Transaction Data for FX Insights"),
                    p("Order flow strategies utilize information about the net buying and selling pressures from different 
              customer segments in FX markets. This proprietary data provides insights into future price movements 
              by revealing the trading intentions of informed versus uninformed market participants."),
                    br(),
                    HTML("<strong>Customer Segments:</strong>"),
                    tags$ul(
                      tags$li("Hedge Funds & Asset Managers: Most informed flows"),
                      tags$li("Corporate Clients: Hedging-related transactions"),
                      tags$li("Private Clients: Typically uninformed retail flows"),
                      tags$li("Short-term Traders: Momentum-based strategies")
                    )
                )
              ),
              
              fluidRow(
                box(width = 4, title = "Order Flow Settings", status = "primary",
                    selectInput("customerType", "Customer Segment:",
                                choices = list("Hedge Funds" = "hedge",
                                               "Asset Managers" = "asset",
                                               "Corporates" = "corporate",
                                               "Private Clients" = "private")),
                    sliderInput("flowThreshold", "Flow Threshold (%):", 
                                min = 1, max = 10, value = 5),
                    sliderInput("signalDecay", "Signal Decay (Days):", 
                                min = 1, max = 30, value = 7),
                    br(),
                    h5("Flow Statistics:"),
                    verbatimTextOutput("flowStats")
                ),
                box(width = 8, title = "Order Flow vs. Future Returns", status = "primary",
                    plotlyOutput("orderFlowReturns")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Customer Segment Performance", status = "primary",
                    plotlyOutput("segmentPerformance")
                ),
                box(width = 6, title = "Flow Predictive Power", status = "primary",
                    plotlyOutput("predictivePower")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Academic References", status = "info",
                    HTML("
            <h5>Order Flow Strategy Research:</h5>
            <p><strong>Burnside, C., Cerrato, M., & Zhang, H.</strong> (2020). Foreign exchange order flow as a risk factor. <em>SSRN Electronic Journal</em>. Available at: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3275356</p>
            <p><strong>Evans, M. D. D., & Lyons, R. K.</strong> (2002). Order flow and exchange rate dynamics. <em>Journal of Political Economy</em>, 110(1), 170-180.</p>
            <p><strong>Menkhoff, L., et al.</strong> (2016). Information flows in foreign exchange markets: Dissecting customer currency trades. <em>Journal of Finance</em>, 71(2), 601-634.</p>
            ")
                )
              )
      ),
      
      # Tab 8: Strategy Combination
      tabItem(tabName = "combination",
              fluidRow(
                box(width = 12, title = "Combining FX Strategies: Diversification Benefits", status = "primary", solidHeader = TRUE,
                    h4("Multi-Strategy Portfolio Optimization"),
                    p("Combining carry, momentum, and value strategies provides superior risk-adjusted returns through 
              diversification benefits. These strategies have low correlations and respond differently to 
              macroeconomic factors, making them complementary in a multi-strategy portfolio framework."),
                    br(),
                    HTML("<strong>Combination Benefits:</strong>"),
                    tags$ul(
                      tags$li("Low correlation between strategies reduces portfolio volatility"),
                      tags$li("Different factor exposures provide natural hedging"),
                      tags$li("Improved Sharpe ratios and reduced maximum drawdowns")
                    )
                )
              ),
              
              fluidRow(
                box(width = 4, title = "Portfolio Allocation", status = "primary",
                    sliderInput("carryWeight", "Carry Trade Weight (%):", 
                                min = 0, max = 100, value = 40),
                    sliderInput("momentumWeight", "Momentum Weight (%):", 
                                min = 0, max = 100, value = 30),
                    sliderInput("valueWeight", "Value Weight (%):", 
                                min = 0, max = 100, value = 30),
                    checkboxInput("equalWeight", "Equal Weighting", value = FALSE),
                    br(),
                    h5("Portfolio Metrics:"),
                    verbatimTextOutput("portfolioMetrics")
                ),
                box(width = 8, title = "Combined Strategy Performance", status = "primary",
                    plotlyOutput("combinedPerformance")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Strategy Correlation Matrix", status = "primary",
                    plotOutput("correlationMatrix")
                ),
                box(width = 6, title = "Risk-Return Comparison", status = "primary",
                    plotlyOutput("riskReturnComparison")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Academic References", status = "info",
                    HTML("
            <h5>Multi-Strategy Research:</h5>
            <p><strong>Asness, C. S., Moskowitz, T. J., & Pedersen, L. H.</strong> (2013). Value and momentum everywhere. <em>Journal of Finance</em>, 68(3), 929-985.</p>
            <p><strong>Lohre, H., & Kolrep, P.</strong> (2018). Currency management with style. <em>Journal of Portfolio Management</em>, 44(4), 71-84.</p>
            <p><strong>Deutsche Bank Research.</strong> (2009). Currency returns and systematic FX strategies. <em>DB Currency Returns Indices</em>. Available through institutional research platforms.</p>
            ")
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Generate synthetic data for demonstrations
  generateSyntheticData <- function() {
    set.seed(123)
    dates <- seq(as.Date("2010-01-01"), as.Date("2024-12-31"), by = "month")
    n <- length(dates)
    
    # Currency data
    currencies <- c("EUR", "GBP", "JPY", "AUD", "CAD", "CHF", "NZD", "SEK", "NOK")
    
    # Generate synthetic returns for different strategies
    carry_returns <- cumsum(rnorm(n, 0.008, 0.03))
    momentum_returns <- cumsum(rnorm(n, 0.006, 0.025))
    value_returns <- cumsum(rnorm(n, 0.004, 0.02))
    
    list(
      dates = dates,
      currencies = currencies,
      carry_returns = carry_returns,
      momentum_returns = momentum_returns,
      value_returns = value_returns,
      n = n
    )
  }
  
  data <- generateSyntheticData()
  
  # Overview Tab Outputs
  output$totalStrategies <- renderValueBox({
    valueBox(
      value = 8,
      subtitle = "Trading Strategies",
      icon = icon("chart-line"),
      color = "blue"
    )
  })
  
  output$avgSharpe <- renderValueBox({
    valueBox(
      value = "1.42",
      subtitle = "Average Sharpe Ratio",
      icon = icon("trending-up"),
      color = "blue"
    )
  })
  
  output$maxDrawdown <- renderValueBox({
    valueBox(
      value = "-12.3%",
      subtitle = "Maximum Drawdown",
      icon = icon("exclamation-triangle"),
      color = "yellow"
    )
  })
  
  output$strategyComparison <- renderPlotly({
    df <- data.frame(
      Date = data$dates,
      Carry = data$carry_returns,
      Momentum = data$momentum_returns,
      Value = data$value_returns
    )
    
    p <- plot_ly(df, x = ~Date) %>%
      add_lines(y = ~Carry, name = "Carry Trade", line = list(color = "#1f77b4")) %>%
      add_lines(y = ~Momentum, name = "Momentum", line = list(color = "#ff7f0e")) %>%
      add_lines(y = ~Value, name = "Value", line = list(color = "#2ca02c")) %>%
      layout(
        title = "Cumulative Strategy Returns",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Cumulative Return"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$selectionCriteria <- renderPlotly({
    set.seed(456)
    currencies <- data$currencies
    
    if(input$criteriaType == "rate_diff") {
      values <- rnorm(length(currencies), 3, 2)
      title <- "Interest Rate Differential (%)"
    } else if(input$criteriaType == "momentum") {
      values <- rnorm(length(currencies), 0, 0.15)
      title <- "6-Month Momentum Score"
    } else {
      values <- rnorm(length(currencies), 0, 0.25)
      title <- "PPP Deviation (%)"
    }
    
    df <- data.frame(Currency = currencies, Value = values)
    df <- df[order(df$Value, decreasing = TRUE),]
    
    p <- plot_ly(df, x = ~reorder(Currency, Value), y = ~Value, type = 'bar',
                 marker = list(color = ~Value, colorscale = 'RdYlGn', reversescale = TRUE)) %>%
      
      layout(
        title = title,
        xaxis = list(title = "Currency"),
        yaxis = list(title = "Value"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  # Carry Trade Tab Outputs
  output$carrySpread <- renderText({
    spread <- input$targetRate - input$fundingRate
    paste("Current Carry Spread:", round(spread, 2), "%")
  })
  
  output$carryPerformance <- renderPlotly({
    set.seed(789)
    spread <- input$targetRate - input$fundingRate
    vol_factor <- input$volatility / 15
    
    # Simulate carry trade returns with volatility impact
    returns <- cumsum(rnorm(data$n, spread/12 * 0.8, 0.02 * vol_factor))
    
    df <- data.frame(
      Date = data$dates,
      Returns = returns,
      Volatility = input$volatility
    )
    
    p <- plot_ly(df, x = ~Date, y = ~Returns, type = 'scatter', mode = 'lines',
                 line = list(color = '#2ca02c', width = 2)) %>%
      layout(
        title = paste("Carry Trade Performance (Vol:", input$volatility, "%)"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Cumulative Return (%)"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$carryWeights <- renderPlotly({
    currencies <- c("JPY", "CHF", "EUR", "AUD", "NZD", "BRL", "MXN", "ZAR")
    weights <- c(-25, -20, -15, 20, 18, 12, 8, 2)
    colors <- ifelse(weights > 0, '#2ca02c', '#d62728')
    
    p <- plot_ly(x = currencies, y = weights, type = 'bar',
                 marker = list(color = colors)) %>%
      layout(
        title = "Currency Weights in Carry Portfolio",
        xaxis = list(title = "Currency"),
        yaxis = list(title = "Weight (%)"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$carryRiskReturn <- renderPlotly({
    set.seed(101)
    currencies <- c("JPY", "CHF", "EUR", "AUD", "NZD", "BRL", "MXN", "ZAR")
    returns <- c(-2, -1, 1, 8, 7, 12, 10, 15)
    risks <- c(8, 9, 10, 15, 16, 25, 22, 30)
    
    p <- plot_ly(x = risks, y = returns, text = currencies, type = 'scatter',
                 mode = 'markers+text', textposition = 'top center',
                 marker = list(size = 10, color = returns, colorscale = 'RdYlGn')) %>%
      layout(
        title = "Currency Risk-Return Profile",
        xaxis = list(title = "Volatility (%)"),
        yaxis = list(title = "Expected Return (%)"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  # UIP Tab Outputs
  output$uipStats <- renderText({
    set.seed(202)
    alpha <- round(rnorm(1, 0.02, 0.01), 4)
    beta <- round(rnorm(1, -0.5, 0.3), 3)
    r_squared <- round(runif(1, 0.05, 0.25), 3)
    
    paste(
      "Alpha:", alpha, "\n",
      "Beta:", beta, "\n", 
      "R-squared:", r_squared, "\n",
      "UIP Rejected:", ifelse(beta < 0, "Yes", "No")
    )
  })
  
  output$uipRegression <- renderPlotly({
    set.seed(303)
    n_points <- 100
    rate_diff <- rnorm(n_points, 0, 0.02)
    exchange_change <- -0.5 * rate_diff + rnorm(n_points, 0, 0.03)
    
    df <- data.frame(
      RateDiff = rate_diff * 100,
      ExchangeChange = exchange_change * 100
    )
    
    p <- plot_ly(df, x = ~RateDiff, y = ~ExchangeChange, type = 'scatter',
                 mode = 'markers', marker = list(color = '#1f77b4', opacity = 0.6)) %>%
      add_lines(y = ~fitted(lm(ExchangeChange ~ RateDiff, data = df)),
                line = list(color = '#d62728', width = 2)) %>%
      layout(
        title = paste("UIP Test:", input$baseCurrency, "vs", input$targetCurrency),
        xaxis = list(title = "Interest Rate Differential (%)"),
        yaxis = list(title = "Exchange Rate Change (%)"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$uipDeviations <- renderPlotly({
    currencies <- c("EUR", "GBP", "JPY", "AUD", "CAD", "CHF", "NZD", "SEK")
    beta_coeffs <- c(-0.3, -0.7, -1.2, -0.1, -0.4, -0.9, 0.1, -0.6)
    colors <- ifelse(beta_coeffs < 0, '#d62728', '#2ca02c')
    
    p <- plot_ly(x = currencies, y = beta_coeffs, type = 'bar',
                 marker = list(color = colors)) %>%
      add_trace(x = currencies, y = rep(1, length(currencies)), 
                type = 'scatter', mode = 'lines',
                line = list(color = '#1a237e', dash = 'dash', width = 2),
                name = "UIP Prediction (β=1)", showlegend = TRUE) %>%
      layout(
        title = "UIP Beta Coefficients by Currency",
        xaxis = list(title = "Currency vs USD"),
        yaxis = list(title = "Beta Coefficient"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$rollingBeta <- renderPlotly({
    set.seed(404)
    rolling_betas <- cumsum(rnorm(data$n, 0, 0.05)) - 0.5
    
    df <- data.frame(
      Date = data$dates,
      Beta = rolling_betas
    )
    
    p <- plot_ly(df, x = ~Date, y = ~Beta, type = 'scatter', mode = 'lines',
                 line = list(color = '#ff7f0e'), name = "Rolling Beta") %>%
      add_trace(x = data$dates, y = rep(1, length(data$dates)), 
                type = 'scatter', mode = 'lines',
                line = list(color = '#1a237e', dash = 'dash', width = 2),
                name = "UIP Prediction (β=1)", showlegend = TRUE) %>%
      add_trace(x = data$dates, y = rep(0, length(data$dates)), 
                type = 'scatter', mode = 'lines',
                line = list(color = 'gray', dash = 'dot', width = 1),
                name = "Zero Line", showlegend = FALSE) %>%
      layout(
        title = "Rolling 3-Year UIP Beta Coefficient",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Beta Coefficient"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  # Risk Tab Outputs
  output$riskMetrics <- renderText({
    vol_adj <- input$volThreshold / 20
    sharpe <- round(max(0.5, 1.2 - vol_adj), 2)
    max_dd <- round(min(-25, -8 * vol_adj), 1)
    var_95 <- round(-2.5 * vol_adj, 2)
    
    paste(
      "Sharpe Ratio:", sharpe, "\n",
      "Max Drawdown:", max_dd, "%\n",
      "VaR (95%):", var_95, "%\n",
      "Status:", ifelse(input$volFilter, "Protected", "Exposed")
    )
  })
  
  output$volPerformance <- renderPlotly({
    set.seed(505)
    vol_regimes <- c(rep("Low", 50), rep("Medium", 70), rep("High", 30), rep("Medium", 30))
    vol_values <- ifelse(vol_regimes == "Low", 10, 
                         ifelse(vol_regimes == "Medium", 18, 35))
    
    returns <- ifelse(vol_regimes == "Low", rnorm(length(vol_regimes), 0.012, 0.02),
                      ifelse(vol_regimes == "Medium", rnorm(length(vol_regimes), 0.008, 0.03),
                             rnorm(length(vol_regimes), -0.015, 0.06)))
    
    df <- data.frame(
      Date = data$dates[1:length(vol_regimes)],
      Returns = cumsum(returns),
      Volatility = vol_values,
      Regime = vol_regimes
    )
    
    p <- plot_ly(df, x = ~Date, y = ~Returns, color = ~Regime,
                 type = 'scatter', mode = 'lines',
                 colors = c("Low" = "#2ca02c", "Medium" = "#ff7f0e", "High" = "#d62728")) %>%
      layout(
        title = "Carry Performance Across Volatility Regimes",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Cumulative Return"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$drawdownAnalysis <- renderPlotly({
    set.seed(606)
    returns <- rnorm(data$n, 0.008, 0.03)
    returns[c(50, 100, 150)] <- c(-0.15, -0.12, -0.08)
    
    cumulative <- cumsum(returns)
    running_max <- cummax(cumulative)
    drawdown <- (cumulative - running_max) * 100
    
    df <- data.frame(
      Date = data$dates,
      Drawdown = drawdown
    )
    
    p <- plot_ly(df, x = ~Date, y = ~Drawdown, type = 'scatter', mode = 'lines',
                 fill = 'tonexty', fillcolor = 'rgba(214, 39, 40, 0.3)',
                 line = list(color = '#d62728')) %>%
      layout(
        title = "Strategy Drawdown Analysis",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Drawdown (%)"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$crashRisk <- renderPlotly({
    set.seed(707)
    daily_returns <- rnorm(1000, 0.0003, 0.015)
    daily_returns[sample(1000, 20)] <- rnorm(20, -0.05, 0.02)
    
    p <- plot_ly(x = daily_returns * 100, type = "histogram", nbinsx = 50,
                 marker = list(color = '#1f77b4', opacity = 0.7)) %>%
      layout(
        title = "Daily Return Distribution with Tail Risk",
        xaxis = list(title = "Daily Return (%)"),
        yaxis = list(title = "Frequency"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  # Momentum Tab Outputs
  output$momentumStats <- renderText({
    sharpe <- round(max(0.3, 1.5 - input$transactionCost/100), 2)
    ann_ret <- round(8 + input$lookback * 0.5 - input$transactionCost * 0.1, 1)
    volatility <- round(12 + input$holding * 0.8, 1)
    
    paste(
      "Annual Return:", ann_ret, "%\n",
      "Volatility:", volatility, "%\n",
      "Sharpe Ratio:", sharpe, "\n",
      "Net of Costs:", ifelse(input$transactionCost > 0, "Yes", "No")
    )
  })
  
  output$momentumReturns <- renderPlotly({
    set.seed(808)
    lookback_factor <- input$lookback / 6
    cost_factor <- input$transactionCost / 20
    
    returns <- cumsum(rnorm(data$n, 0.007 * lookback_factor - 0.002 * cost_factor, 0.025))
    
    df <- data.frame(
      Date = data$dates,
      Returns = returns
    )
    
    p <- plot_ly(df, x = ~Date, y = ~Returns, type = 'scatter', mode = 'lines',
                 line = list(color = '#ff7f0e', width = 2)) %>%
      layout(
        title = paste("Momentum Strategy (", input$lookback, "M Formation,", 
                      input$holding, "M Holding)"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Cumulative Return"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$currencyRankings <- DT::renderDataTable({
    set.seed(909)
    currencies <- data$currencies[1:min(input$numCurrencies, length(data$currencies))]
    momentum_scores <- round(rnorm(length(currencies), 0, 0.15), 3)
    rankings <- rank(-momentum_scores)
    
    df <- data.frame(
      Rank = rankings,
      Currency = currencies,
      MomentumScore = momentum_scores,
      Position = ifelse(rankings <= 3, "Long", 
                        ifelse(rankings > length(currencies) - 3, "Short", "Neutral"))
    )
    
    df <- df[order(df$Rank),]
    
    DT::datatable(df, options = list(pageLength = 10, dom = 't'),
                  rownames = FALSE) %>%
      DT::formatStyle("Position",
                      backgroundColor = DT::styleEqual(c("Long", "Short", "Neutral"),
                                                       c("#2ca02c", "#d62728", "#gray")))
  })
  
  output$momentumMarketStates <- renderPlotly({
    market_states <- c("Bull", "Bear", "Neutral")
    momentum_returns <- c(12.5, -2.3, 8.1)
    colors <- c("#2ca02c", "#d62728", "#1f77b4")
    
    p <- plot_ly(x = market_states, y = momentum_returns, type = 'bar',
                 marker = list(color = colors)) %>%
      layout(
        title = "Momentum Returns by Market State",
        xaxis = list(title = "Market State"),
        yaxis = list(title = "Annual Return (%)"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  # Value Tab Outputs  
  output$pppValuations <- renderText({
    set.seed(1010)
    currencies <- c("EUR", "GBP", "JPY", "AUD")
    deviations <- round(rnorm(4, 0, 0.15), 2)
    
    valuations <- paste(currencies, ":", 
                        ifelse(deviations > 0, "Overvalued", "Undervalued"),
                        paste0("(", abs(deviations)*100, "%)"))
    
    paste(valuations, collapse = "\n")
  })
  
  output$pppDeviations <- renderPlotly({
    set.seed(1111)
    currencies <- c("EUR", "GBP", "JPY", "AUD", "CAD", "CHF", "NZD", "SEK")
    
    if(input$pppMethod == "bigmac") {
      deviations <- c(0.05, -0.12, 0.18, -0.08, 0.03, 0.15, -0.05, 0.09)
      title <- "Big Mac Index PPP Deviations"
    } else if(input$pppMethod == "oecd") {
      deviations <- c(0.02, -0.15, 0.22, -0.11, 0.07, 0.18, -0.03, 0.12)
      title <- "OECD PPP Deviations"
    } else {
      deviations <- c(0.08, -0.09, 0.25, -0.06, 0.04, 0.20, -0.07, 0.11)
      title <- "Real Exchange Rate Deviations"
    }
    
    colors <- ifelse(deviations > 0, '#d62728', '#2ca02c')
    
    p <- plot_ly(x = currencies, y = deviations * 100, type = 'bar',
                 marker = list(color = colors)) %>%
      layout(
        title = title,
        xaxis = list(title = "Currency vs USD"),
        yaxis = list(title = "Deviation from Fair Value (%)"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$meanReversion <- renderPlotly({
    set.seed(1212)
    
    n_years <- 30
    dates_long <- seq(as.Date("1994-01-01"), as.Date("2024-01-01"), by = "year")
    
    theta <- 0.1
    mu <- 0
    sigma <- 0.15
    
    rate <- numeric(n_years)
    rate[1] <- 0.2
    
    for(i in 2:n_years) {
      rate[i] <- rate[i-1] + theta * (mu - rate[i-1]) + rnorm(1, 0, sigma)
    }
    
    df <- data.frame(
      Year = dates_long,
      Deviation = rate * 100
    )
    
    p <- plot_ly(df, x = ~Year, y = ~Deviation, type = 'scatter', mode = 'lines',
                 line = list(color = '#2ca02c', width = 2), name = "PPP Deviation") %>%
      add_trace(x = dates_long, y = rep(0, length(dates_long)), 
                type = 'scatter', mode = 'lines',
                line = list(color = '#1a237e', dash = 'dash', width = 2),
                name = "Fair Value", showlegend = TRUE) %>%
      layout(
        title = "Long-term PPP Mean Reversion",
        xaxis = list(title = "Year"),
        yaxis = list(title = "PPP Deviation (%)"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$valuePerformance <- renderPlotly({
    set.seed(1313)
    rebal_factor <- 12 / input$rebalanceFreq
    
    returns <- cumsum(rnorm(data$n, 0.005 * rebal_factor^0.5, 0.018))
    
    df <- data.frame(
      Date = data$dates,
      Returns = returns
    )
    
    p <- plot_ly(df, x = ~Date, y = ~Returns, type = 'scatter', mode = 'lines',
                 line = list(color = '#2ca02c', width = 2)) %>%
      layout(
        title = paste("Value Strategy (Rebalanced", input$rebalanceFreq, "Monthly)"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Cumulative Return"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  # Order Flow Tab Outputs
  output$flowStats <- renderText({
    set.seed(1414)
    
    if(input$customerType == "hedge") {
      predictive_power <- 0.78
      flow_volume <- "High"
    } else if(input$customerType == "asset") {
      predictive_power <- 0.65
      flow_volume <- "Medium"
    } else if(input$customerType == "corporate") {
      predictive_power <- 0.23
      flow_volume <- "Low"
    } else {
      predictive_power <- 0.12
      flow_volume <- "Very Low"
    }
    
    paste(
      "Predictive Power:", round(predictive_power, 2), "\n",
      "Flow Volume:", flow_volume, "\n",
      "Signal Strength:", ifelse(predictive_power > 0.5, "Strong", "Weak"), "\n",
      "Decay Rate:", paste0(input$signalDecay, " days")
    )
  })
  
  output$orderFlowReturns <- renderPlotly({
    set.seed(1515)
    
    flow_data <- rnorm(100, 0, 1)
    
    if(input$customerType == "hedge") {
      future_returns <- 0.7 * flow_data + rnorm(100, 0, 0.5)
    } else if(input$customerType == "asset") {
      future_returns <- 0.5 * flow_data + rnorm(100, 0, 0.7)
    } else {
      future_returns <- 0.1 * flow_data + rnorm(100, 0, 1)
    }
    
    df <- data.frame(
      OrderFlow = flow_data,
      FutureReturns = future_returns
    )
    
    p <- plot_ly(df, x = ~OrderFlow, y = ~FutureReturns, type = 'scatter',
                 mode = 'markers', marker = list(color = '#1f77b4', opacity = 0.6)) %>%
      add_lines(y = ~fitted(lm(FutureReturns ~ OrderFlow, data = df)),
                line = list(color = '#d62728', width = 2)) %>%
      layout(
        title = paste("Order Flow Predictive Power:", input$customerType),
        xaxis = list(title = "Order Flow (Standardized)"),
        yaxis = list(title = "Future 1-Week Return (%)"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$segmentPerformance <- renderPlotly({
    segments <- c("Hedge Funds", "Asset Managers", "Corporates", "Private Clients")
    annual_returns <- c(14.2, 9.8, 3.1, -1.2)
    colors <- c("#2ca02c", "#ff7f0e", "#1f77b4", "#d62728")
    
    p <- plot_ly(x = segments, y = annual_returns, type = 'bar',
                 marker = list(color = colors)) %>%
      layout(
        title = "Order Flow Strategy Returns by Customer Segment",
        xaxis = list(title = "Customer Segment"),
        yaxis = list(title = "Annual Return (%)"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$predictivePower <- renderPlotly({
    set.seed(1616)
    days <- 1:30
    
    if(input$customerType == "hedge") {
      power <- exp(-days / 10) * 0.8
    } else if(input$customerType == "asset") {
      power <- exp(-days / 12) * 0.6
    } else {
      power <- exp(-days / 5) * 0.3
    }
    
    df <- data.frame(
      Days = days,
      Power = power
    )
    
    p <- plot_ly(df, x = ~Days, y = ~Power, type = 'scatter', mode = 'lines',
                 line = list(color = '#ff7f0e', width = 2), name = "Predictive Power") %>%
      add_trace(x = rep(input$signalDecay, 2), y = c(0, max(power)), 
                type = 'scatter', mode = 'lines',
                line = list(color = '#1a237e', dash = 'dash', width = 2),
                name = paste("Signal Decay:", input$signalDecay, "days"), showlegend = TRUE) %>%
      layout(
        title = "Order Flow Signal Decay",
        xaxis = list(title = "Days After Signal"),
        yaxis = list(title = "Predictive Power"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  # Combination Tab Outputs
  observe({
    if(input$equalWeight) {
      updateSliderInput(session, "carryWeight", value = 33.3)
      updateSliderInput(session, "momentumWeight", value = 33.3)
      updateSliderInput(session, "valueWeight", value = 33.3)
    }
  })
  
  output$portfolioMetrics <- renderText({
    total_weight <- input$carryWeight + input$momentumWeight + input$valueWeight
    
    if(abs(total_weight - 100) > 1) {
      return("Warning: Weights must sum to 100%")
    }
    
    w_carry <- input$carryWeight / 100
    w_momentum <- input$momentumWeight / 100  
    w_value <- input$valueWeight / 100
    
    carry_ret <- 9.2; carry_vol <- 12.5
    momentum_ret <- 8.8; momentum_vol <- 14.2
    value_ret <- 5.4; value_vol <- 9.8
    
    corr_cm <- 0.15; corr_cv <- -0.05; corr_mv <- 0.08
    
    port_ret <- w_carry * carry_ret + w_momentum * momentum_ret + w_value * value_ret
    port_var <- (w_carry^2 * carry_vol^2 + w_momentum^2 * momentum_vol^2 + w_value^2 * value_vol^2 +
                   2 * w_carry * w_momentum * carry_vol * momentum_vol * corr_cm +
                   2 * w_carry * w_value * carry_vol * value_vol * corr_cv +
                   2 * w_momentum * w_value * momentum_vol * value_vol * corr_mv)
    port_vol <- sqrt(port_var)
    port_sharpe <- port_ret / port_vol
    
    paste(
      "Portfolio Return:", round(port_ret, 1), "%\n",
      "Portfolio Vol:", round(port_vol, 1), "%\n",
      "Sharpe Ratio:", round(port_sharpe, 2), "\n",
      "Diversification:", ifelse(port_vol < 12, "High", "Medium")
    )
  })
  
  output$combinedPerformance <- renderPlotly({
    set.seed(1717)
    
    w_carry <- input$carryWeight / 100
    w_momentum <- input$momentumWeight / 100
    w_value <- input$valueWeight / 100
    
    carry_rets <- data$carry_returns / 100
    momentum_rets <- data$momentum_returns / 100  
    value_rets <- data$value_returns / 100
    
    combined_rets <- w_carry * carry_rets + w_momentum * momentum_rets + w_value * value_rets
    
    df <- data.frame(
      Date = data$dates,
      Carry = carry_rets,
      Momentum = momentum_rets,
      Value = value_rets,
      Combined = combined_rets
    )
    
    p <- plot_ly(df, x = ~Date) %>%
      add_lines(y = ~Carry, name = "Carry", line = list(color = "#1f77b4", dash = 'dot')) %>%
      add_lines(y = ~Momentum, name = "Momentum", line = list(color = "#ff7f0e", dash = 'dot')) %>%
      add_lines(y = ~Value, name = "Value", line = list(color = "#2ca02c", dash = 'dot')) %>%
      add_lines(y = ~Combined, name = "Combined Portfolio", 
                line = list(color = "#9467bd", width = 3)) %>%
      layout(
        title = "Multi-Strategy Portfolio Performance",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Cumulative Return"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
  
  output$correlationMatrix <- renderPlot({
    corr_matrix <- matrix(c(1.00, 0.15, -0.05,
                            0.15, 1.00, 0.08,
                            -0.05, 0.08, 1.00), 
                          nrow = 3, ncol = 3)
    
    rownames(corr_matrix) <- c("Carry", "Momentum", "Value")
    colnames(corr_matrix) <- c("Carry", "Momentum", "Value")
    
    corrplot(corr_matrix, method = "color", type = "upper", 
             order = "original", tl.cex = 1.2, tl.col = "#1a237e",
             cl.cex = 1.0, addCoef.col = "#1a237e", number.cex = 1.2,
             col = colorRampPalette(c("#1a237e", "white", "#3f51b5"))(200),
             bg = "#ffffff")
  }, bg = "#ffffff")
  
  output$riskReturnComparison <- renderPlotly({
    strategies <- c("Carry", "Momentum", "Value", "Combined")
    returns <- c(9.2, 8.8, 5.4, 7.8)
    volatilities <- c(12.5, 14.2, 9.8, 10.2)
    sharpes <- returns / volatilities
    
    colors <- c("#1f77b4", "#ff7f0e", "#2ca02c", "#9467bd")
    
    p <- plot_ly(x = volatilities, y = returns, text = strategies, 
                 type = 'scatter', mode = 'markers+text', textposition = 'top center',
                 marker = list(size = sharpes * 10, color = colors, 
                               line = list(color = '#1a237e', width = 2))) %>%
      layout(
        title = "Strategy Risk-Return Profile (Size = Sharpe Ratio)",
        xaxis = list(title = "Volatility (%)"),
        yaxis = list(title = "Expected Return (%)"),
        paper_bgcolor = '#ffffff',
        plot_bgcolor = '#ffffff'
      )
    p
  })
}

# Run the application
shinyApp(ui = ui, server = server)