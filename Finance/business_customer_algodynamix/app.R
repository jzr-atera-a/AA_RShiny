# AlgoDynamix Business Model Dashboard
# R Shiny Application with shinydashboard

# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(
    title = "Trading Platform B Model Canvas",
    titleWidth = 350
  ),
  
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      menuItem("Introduction", tabName = "intro", icon = icon("home")),
      menuItem("Disciplined Entrepreneurship", tabName = "book1_overview", icon = icon("book")),
      menuItem("Business Model Generation", tabName = "book2_overview", icon = icon("book-open")),
      menuItem("DE: Phase 1A - Retail", tabName = "de_phase1a", icon = icon("users")),
      menuItem("DE: Phase 1B - Exchange", tabName = "de_phase1b", icon = icon("building")),
      menuItem("BMG: Phase 1A - Retail", tabName = "bmg_phase1a", icon = icon("chart-line")),
      menuItem("BMG: Phase 1B - Exchange", tabName = "bmg_phase1b", icon = icon("handshake"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .skin-blue .main-header .navbar {
          background: linear-gradient(90deg, #1e3c72 0%, #2a5298 50%, #4a90e2 100%) !important;
        }
        .skin-blue .main-sidebar {
          background: linear-gradient(180deg, #0a1128 0%, #1e3c72 50%, #2a5298 100%) !important;
        }
        .content-wrapper { 
          background: linear-gradient(135deg, #0a1128 0%, #1a2744 100%) !important; 
        }
        .box { 
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important; 
          border: 2px solid #4a90e2 !important; 
          border-radius: 12px !important; 
        }
        .box-body { 
          background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%) !important; 
          color: #e0e7ff !important; 
          padding: 20px !important;
        }
        p { color: #c7d2fe !important; line-height: 1.7 !important; }
        strong { color: #7ec8e3 !important; font-weight: 600; }
        h3, h4, h5, h6 { color: #ffffff !important; }
        .alert-info { 
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%); 
          border: 2px solid #7ec8e3; 
          color: #fff; 
          padding: 20px; 
          border-radius: 8px; 
          margin: 15px 0;
        }
        .calculo-box {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%);
          border: 2px solid #667eea;
          border-radius: 8px;
          padding: 20px;
          margin-top: 20px;
        }
        .calculo-box h5 {
          color: #7ec8e3 !important;
          border-bottom: 2px solid #4a90e2;
          padding-bottom: 10px;
          margin-bottom: 15px;
        }
        .formula {
          background: #0a1128;
          padding: 10px;
          border-left: 4px solid #667eea;
          margin: 10px 0;
          font-family: monospace;
        }
        table.dataTable { 
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important; 
          color: #e0e7ff !important; 
        }
        table.dataTable thead th { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
          color: #ffffff !important; 
          border-bottom: 2px solid #4a90e2 !important;
        }
        table.dataTable tbody tr {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #e0e7ff !important;
        }
        table.dataTable tbody tr:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        }
        .value-box {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          border-radius: 8px;
          padding: 15px;
          margin: 10px 0;
        }
        .small-box {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          border-radius: 8px;
        }
        .small-box h3, .small-box p {
          color: #ffffff !important;
        }
      "))
    ),
    
    tabItems(
      # Introduction Tab
      tabItem(
        tabName = "intro",
        fluidRow(
          box(
            width = 12,
            title = "Welcome to AlgoDynamix Business Model Dashboard",
            status = "primary",
            solidHeader = TRUE,
            HTML("
              <h3>Overview</h3>
              <p>
                <strong>AlgoDynamix</strong> is a Cambridge-based fintech pioneer in behavioral-based price forecasting 
                for financial markets. This interactive dashboard presents comprehensive business model analysis 
                using two proven frameworks:
              </p>
              <ul style='color: #c7d2fe; line-height: 1.8;'>
                <li><strong>Disciplined Entrepreneurship (Bill Aulet)</strong> - 24-step methodology for startup success</li>
                <li><strong>Business Model Generation (Osterwalder & Pigneur)</strong> - Canvas framework for value creation</li>
              </ul>
              
              <div class='alert-info'>
                <h4>🎯 Core Innovation</h4>
                <p>
                  AlgoDynamix uses <strong>unsupervised machine learning</strong> to analyze real-time market participant 
                  behavior (not historical data) through proprietary 'Flag' analytics powered by quantum computing.
                </p>
              </div>
              
              <h4>Two Strategic Pathways:</h4>
            ")
          )
        ),
        
        fluidRow(
          valueBox(
            value = "Phase 1A",
            subtitle = "Retail Trading Platform",
            icon = icon("users"),
            color = "blue",
            width = 6
          ),
          valueBox(
            value = "Phase 1B",
            subtitle = "Exchange White-Label",
            icon = icon("building"),
            color = "purple",
            width = 6
          )
        ),
        
        fluidRow(
          box(
            width = 6,
            title = "Phase 1A: Retail Platform",
            status = "info",
            HTML("
              <p><strong>Target Customer:</strong> Failed crypto day traders</p>
              <p><strong>Value Proposition:</strong> Transform emotional gambling into systematic trading</p>
              <p><strong>Revenue Model:</strong> $49-299/month SaaS subscription</p>
              <p><strong>Year 1 Goal:</strong> 500 customers, $450K ARR</p>
            ")
          ),
          box(
            width = 6,
            title = "Phase 1B: Exchange Partnership",
            status = "warning",
            HTML("
              <p><strong>Target Customer:</strong> Tier-2 regional crypto exchanges</p>
              <p><strong>Value Proposition:</strong> Increase exchange revenue by $4.5M+/year</p>
              <p><strong>Revenue Model:</strong> Base license + 50% revenue share</p>
              <p><strong>Year 1 Goal:</strong> 3 partners, $4.5M revenue</p>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            title = "Key Differentiators",
            status = "success",
            HTML("
              <div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px;'>
                <div class='calculo-box'>
                  <h5>🧠 No Historical Data</h5>
                  <p>Works in 'never seen before' market conditions</p>
                </div>
                <div class='calculo-box'>
                  <h5>⚡ Real-Time Behavioral</h5>
                  <p>Analyzes live market participant clusters</p>
                </div>
                <div class='calculo-box'>
                  <h5>🏆 Academic Pedigree</h5>
                  <p>Cambridge research + Nobel Prize validated</p>
                </div>
                <div class='calculo-box'>
                  <h5>💎 Quantum Powered</h5>
                  <p>Partnership with D-Wave for computation</p>
                </div>
              </div>
            ")
          )
        )
      ),
      
      # Book 1 Overview: Disciplined Entrepreneurship
      tabItem(
        tabName = "book1_overview",
        fluidRow(
          box(
            width = 12,
            title = "Disciplined Entrepreneurship: 24 Steps Framework",
            status = "primary",
            solidHeader = TRUE,
            HTML("
              <h3>Bill Aulet's Methodology</h3>
              <p>
                <strong>Disciplined Entrepreneurship</strong> provides a rigorous, step-by-step framework for building 
                successful startups through customer-centric validation and quantified value propositions.
              </p>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 4,
            title = "Phase 1: Who is Your Customer?",
            status = "info",
            solidHeader = TRUE,
            HTML("
              <h5>Steps 1-7:</h5>
              <ul style='color: #c7d2fe;'>
                <li><strong>Step 1:</strong> Market Segmentation</li>
                <li><strong>Step 2:</strong> Select Beachhead Market</li>
                <li><strong>Step 3:</strong> Build End User Profile</li>
                <li><strong>Step 4:</strong> Calculate TAM</li>
                <li><strong>Step 5:</strong> Profile the Persona</li>
                <li><strong>Step 6:</strong> Full Life Cycle Use Case</li>
                <li><strong>Step 7:</strong> High-Level Product Spec</li>
              </ul>
            ")
          ),
          box(
            width = 4,
            title = "Phase 2: What Can You Do?",
            status = "warning",
            solidHeader = TRUE,
            HTML("
              <h5>Steps 8-14:</h5>
              <ul style='color: #c7d2fe;'>
                <li><strong>Step 8:</strong> Quantify Value Proposition</li>
                <li><strong>Step 9:</strong> Identify Next 10 Customers</li>
                <li><strong>Step 10:</strong> Define Core</li>
                <li><strong>Step 11-12:</strong> Competitive Analysis</li>
                <li><strong>Step 13-14:</strong> Customer Decision Making</li>
              </ul>
            ")
          ),
          box(
            width = 4,
            title = "Phase 3: How to Get & Keep?",
            status = "success",
            solidHeader = TRUE,
            HTML("
              <h5>Steps 15-24:</h5>
              <ul style='color: #c7d2fe;'>
                <li><strong>Step 15:</strong> Customer Acquisition Process</li>
                <li><strong>Step 16-18:</strong> Pricing Framework</li>
                <li><strong>Step 19:</strong> Sales Strategy</li>
                <li><strong>Step 20-24:</strong> Execution Planning</li>
              </ul>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            title = "Core Principles Applied to AlgoDynamix",
            status = "primary",
            HTML("
              <div class='calculo-box'>
                <h5>1. Focus on Beachhead Market</h5>
                <p><strong>Phase 1A:</strong> Failed crypto day traders (not 'all retail investors')</p>
                <p><strong>Phase 1B:</strong> Tier-2 regional exchanges (not 'all exchanges')</p>
                <div class='formula'>
                  Narrow focus = Deep customer understanding = Product-market fit
                </div>
              </div>
              
              <div class='calculo-box'>
                <h5>2. Quantify Value Relentlessly</h5>
                <p><strong>Retail Customer (Sarah):</strong> Saves $4,572/year for $588 investment</p>
                <div class='formula'>
                  ROI = $4,572 / $588 = 7.8x return
                </div>
                <p><strong>Exchange Partner (CryptoNova):</strong> Gains $4.5M/year for $50K + rev share</p>
                <div class='formula'>
                  ROI = $4,500,000 / $50,000 = 90x return
                </div>
              </div>
              
              <div class='calculo-box'>
                <h5>3. Get First 10 Customers Before Scaling</h5>
                <p><strong>Phase 1A:</strong> 10 beta testers with intensive feedback loops</p>
                <p><strong>Phase 1B:</strong> 3 exchange pilots with detailed case studies</p>
                <div class='formula'>
                  Validation > Assumptions | Customer feedback > Internal opinions
                </div>
              </div>
              
              <div class='calculo-box'>
                <h5>4. Price on Value, Not Cost</h5>
                <p>Don't calculate: Cost + Margin = Price</p>
                <p>Instead calculate: Customer Value × % Capture = Price</p>
                <div class='formula'>
                  Retail: $49/mo (9% of $588 annual benefit)<br>
                  Exchange: 50% rev share (aligned incentives)
                </div>
              </div>
            ")
          )
        )
      ),
      
      # Book 2 Overview: Business Model Generation
      tabItem(
        tabName = "book2_overview",
        fluidRow(
          box(
            width = 12,
            title = "Business Model Generation: Canvas Framework",
            status = "primary",
            solidHeader = TRUE,
            HTML("
              <h3>Osterwalder & Pigneur's 9 Building Blocks</h3>
              <p>
                The <strong>Business Model Canvas</strong> provides a visual framework for describing, designing, 
                and analyzing how organizations create, deliver, and capture value.
              </p>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            title = "The 9 Building Blocks",
            status = "info",
            HTML("
              <div style='display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin: 20px 0;'>
                <div class='calculo-box'>
                  <h5>1. Customer Segments</h5>
                  <p>Who are we creating value for?</p>
                  <ul style='color: #c7d2fe;'>
                    <li>Mass market</li>
                    <li>Niche market</li>
                    <li>Segmented</li>
                    <li>Multi-sided</li>
                  </ul>
                </div>
                
                <div class='calculo-box'>
                  <h5>2. Value Propositions</h5>
                  <p>What value do we deliver?</p>
                  <ul style='color: #c7d2fe;'>
                    <li>Newness</li>
                    <li>Performance</li>
                    <li>Customization</li>
                    <li>Risk reduction</li>
                  </ul>
                </div>
                
                <div class='calculo-box'>
                  <h5>3. Channels</h5>
                  <p>How do we reach customers?</p>
                  <ul style='color: #c7d2fe;'>
                    <li>Awareness</li>
                    <li>Evaluation</li>
                    <li>Purchase</li>
                    <li>Delivery</li>
                    <li>After-sales</li>
                  </ul>
                </div>
                
                <div class='calculo-box'>
                  <h5>4. Customer Relationships</h5>
                  <p>How do we interact?</p>
                  <ul style='color: #c7d2fe;'>
                    <li>Personal assistance</li>
                    <li>Self-service</li>
                    <li>Communities</li>
                    <li>Co-creation</li>
                  </ul>
                </div>
                
                <div class='calculo-box'>
                  <h5>5. Revenue Streams</h5>
                  <p>How do we earn money?</p>
                  <ul style='color: #c7d2fe;'>
                    <li>Asset sale</li>
                    <li>Usage fee</li>
                    <li>Subscription</li>
                    <li>Licensing</li>
                  </ul>
                </div>
                
                <div class='calculo-box'>
                  <h5>6. Key Resources</h5>
                  <p>What assets are essential?</p>
                  <ul style='color: #c7d2fe;'>
                    <li>Physical</li>
                    <li>Intellectual</li>
                    <li>Human</li>
                    <li>Financial</li>
                  </ul>
                </div>
                
                <div class='calculo-box'>
                  <h5>7. Key Activities</h5>
                  <p>What do we need to do?</p>
                  <ul style='color: #c7d2fe;'>
                    <li>Production</li>
                    <li>Problem solving</li>
                    <li>Platform/network</li>
                  </ul>
                </div>
                
                <div class='calculo-box'>
                  <h5>8. Key Partnerships</h5>
                  <p>Who are our partners?</p>
                  <ul style='color: #c7d2fe;'>
                    <li>Strategic alliances</li>
                    <li>Joint ventures</li>
                    <li>Supplier relationships</li>
                  </ul>
                </div>
                
                <div class='calculo-box'>
                  <h5>9. Cost Structure</h5>
                  <p>What are our costs?</p>
                  <ul style='color: #c7d2fe;'>
                    <li>Fixed costs</li>
                    <li>Variable costs</li>
                    <li>Economies of scale</li>
                  </ul>
                </div>
              </div>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 6,
            title = "Business Model Patterns",
            status = "warning",
            HTML("
              <h5>Phase 1A Patterns:</h5>
              <ul style='color: #c7d2fe; line-height: 1.8;'>
                <li><strong>Freemium:</strong> Free tier → paid conversion</li>
                <li><strong>Subscription:</strong> Recurring revenue (SaaS)</li>
                <li><strong>Long Tail:</strong> Serve many small customers</li>
                <li><strong>Multi-Sided Platform:</strong> (Future expansion)</li>
              </ul>
              
              <h5>Phase 1B Patterns:</h5>
              <ul style='color: #c7d2fe; line-height: 1.8;'>
                <li><strong>White-Label/OEM:</strong> Tech provider to distributor</li>
                <li><strong>Revenue Sharing:</strong> Aligned incentives</li>
                <li><strong>B2B2C:</strong> Serve businesses who serve consumers</li>
                <li><strong>Licensing:</strong> IP commercialization</li>
              </ul>
            ")
          ),
          box(
            width = 6,
            title = "Strategic Synergies (1A + 1B)",
            status = "success",
            HTML("
              <div class='calculo-box'>
                <h5>🔄 Virtuous Cycle</h5>
                <ol style='color: #c7d2fe; line-height: 1.8;'>
                  <li>Retail platform builds brand awareness</li>
                  <li>Exchanges see traction, sign white-label deal</li>
                  <li>Exchange promotes to millions of users</li>
                  <li>Some want standalone → return to retail</li>
                  <li>Both channels grow together</li>
                </ol>
              </div>
              
              <div class='calculo-box'>
                <h5>💪 Combined Strengths</h5>
                <ul style='color: #c7d2fe;'>
                  <li><strong>Data network effects:</strong> More users = better algorithms</li>
                  <li><strong>Cost efficiency:</strong> Shared engineering/marketing</li>
                  <li><strong>Risk diversification:</strong> Two revenue streams</li>
                  <li><strong>Brand amplification:</strong> B2C + B2B2C reach</li>
                </ul>
              </div>
            ")
          )
        )
      ),
      
      # Disciplined Entrepreneurship: Phase 1A
      tabItem(
        tabName = "de_phase1a",
        fluidRow(
          box(
            width = 12,
            title = "Disciplined Entrepreneurship: Phase 1A - Retail Platform",
            status = "primary",
            solidHeader = TRUE,
            HTML("<h3>AlgoDynamix Trader Academy - 24 Steps Analysis</h3>")
          )
        ),
        
        fluidRow(
          valueBoxOutput("de1a_tam", width = 3),
          valueBoxOutput("de1a_customers_y1", width = 3),
          valueBoxOutput("de1a_arr_y1", width = 3),
          valueBoxOutput("de1a_roi", width = 3)
        ),
        
        fluidRow(
          box(
            width = 6,
            title = "Steps 1-7: Who is Your Customer?",
            status = "info",
            collapsible = TRUE,
            HTML("
              <div class='calculo-box'>
                <h5>Step 2: Beachhead Market</h5>
                <p><strong>Chosen:</strong> Failed Crypto Day Traders</p>
                <p><strong>Rationale:</strong></p>
                <ul style='color: #c7d2fe;'>
                  <li>Highest pain (lost money, motivated to change)</li>
                  <li>Proven willingness to pay (bought courses before)</li>
                  <li>Education receptive (acknowledge need to learn)</li>
                  <li>Accessible (Reddit, TradingView, YouTube)</li>
                </ul>
                <div class='formula'>
                  Market Size: 3-5M globally
                </div>
              </div>
              
              <div class='calculo-box'>
                <h5>Step 3: End User Profile - 'Sarah'</h5>
                <p><strong>Demographics:</strong> 32, urban, $75K income, marketing manager</p>
                <p><strong>Trading History:</strong> Lost $8,500 (2021-2023)</p>
                <p><strong>Behavior:</strong> Emotional trader, FOMO-driven, checks portfolio 15x/day</p>
                <p><strong>Goals:</strong> Recover losses, develop discipline, build confidence</p>
              </div>
              
              <div class='calculo-box'>
                <h5>Step 4: TAM Calculation</h5>
                <div class='formula'>
                  Top-Down:<br>
                  Global crypto traders: 420M<br>
                  Active monthly: 50M (12%)<br>
                  Experienced losses: 35M (70%)<br>
                  Seeking systematic solution: 10M (30%)<br>
                  <strong>TAM: 10M × $588/year = $5.88B</strong>
                </div>
                <div class='formula'>
                  Bottom-Up (Realistic):<br>
                  Year 1: 500 customers = $450K ARR<br>
                  Year 3: 10,000 customers = $10.8M ARR<br>
                  Year 5: 75,000 customers = $90M ARR
                </div>
              </div>
            ")
          ),
          box(
            width = 6,
            title = "Steps 8-14: What Can You Do?",
            status = "warning",
            collapsible = TRUE,
            HTML("
              <div class='calculo-box'>
                <h5>Step 8: Quantified Value Proposition</h5>
                <p><strong>Sarah's Annual Economics:</strong></p>
                <table style='width: 100%; color: #c7d2fe; border-collapse: collapse;'>
                  <tr style='border-bottom: 2px solid #4a90e2;'>
                    <th style='padding: 8px; text-align: left;'>Metric</th>
                    <th style='padding: 8px; text-align: right;'>Before</th>
                    <th style='padding: 8px; text-align: right;'>After</th>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Trading Return</td>
                    <td style='padding: 8px; text-align: right; color: #f87171;'>-15%</td>
                    <td style='padding: 8px; text-align: right; color: #4ade80;'>+28%</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Dollar Gain/Loss</td>
                    <td style='padding: 8px; text-align: right; color: #f87171;'>-$1,800</td>
                    <td style='padding: 8px; text-align: right; color: #4ade80;'>+$3,360</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Time Spent</td>
                    <td style='padding: 8px; text-align: right;'>20 hrs/wk</td>
                    <td style='padding: 8px; text-align: right;'>7 hrs/wk</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Platform Cost</td>
                    <td style='padding: 8px; text-align: right;'>$0</td>
                    <td style='padding: 8px; text-align: right;'>$588/yr</td>
                  </tr>
                  <tr style='border-top: 2px solid #4a90e2; font-weight: bold;'>
                    <td style='padding: 8px;'>Net Benefit</td>
                    <td style='padding: 8px; text-align: right; color: #f87171;'>-$1,800</td>
                    <td style='padding: 8px; text-align: right; color: #4ade80;'>+$2,772</td>
                  </tr>
                </table>
                <div class='formula'>
                  ROI = $4,572 benefit ÷ $588 cost = <strong>7.8x return</strong><br>
                  Payback period: < 2 months
                </div>
              </div>
              
              <div class='calculo-box'>
                <h5>Step 10: Define Core</h5>
                <p><strong>What AlgoDynamix IS:</strong></p>
                <ul style='color: #c7d2fe;'>
                  <li>Educational-first trading platform</li>
                  <li>Systematic approach (behavioral economics)</li>
                  <li>Learn → Simulate → Trade journey</li>
                  <li>Explainable AI (teaches, not just executes)</li>
                </ul>
                <p><strong>What AlgoDynamix IS NOT:</strong></p>
                <ul style='color: #c7d2fe;'>
                  <li>Not a 'get rich quick' scheme</li>
                  <li>Not a Telegram signal service</li>
                  <li>Not a copy-trading platform</li>
                  <li>Not a TradingView competitor</li>
                </ul>
                <div class='formula'>
                  Core Focus: Transform emotional traders into systematic traders
                </div>
              </div>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            title = "Steps 15-24: How to Get & Keep Customers",
            status = "success",
            collapsible = TRUE,
            HTML("
              <div style='display: grid; grid-template-columns: 1fr 1fr; gap: 20px;'>
                <div class='calculo-box'>
                  <h5>Step 16-18: Pricing Framework</h5>
                  <table style='width: 100%; color: #c7d2fe; margin-top: 10px;'>
                    <tr style='background: #0a1128;'>
                      <th style='padding: 10px;'>Tier</th>
                      <th style='padding: 10px;'>Price</th>
                      <th style='padding: 10px;'>Features</th>
                    </tr>
                    <tr>
                      <td style='padding: 8px;'>Free</td>
                      <td style='padding: 8px;'>$0</td>
                      <td style='padding: 8px;'>3 modules (lead gen)</td>
                    </tr>
                    <tr>
                      <td style='padding: 8px;'><strong>Starter</strong></td>
                      <td style='padding: 8px;'><strong>$49/mo</strong></td>
                      <td style='padding: 8px;'>Full Academy + Paper trading</td>
                    </tr>
                    <tr>
                      <td style='padding: 8px;'><strong>Pro</strong></td>
                      <td style='padding: 8px;'><strong>$99/mo</strong></td>
                      <td style='padding: 8px;'>+ Live trading + AI insights</td>
                    </tr>
                    <tr>
                      <td style='padding: 8px;'><strong>Elite</strong></td>
                      <td style='padding: 8px;'><strong>$299/mo</strong></td>
                      <td style='padding: 8px;'>+ Monthly coaching</td>
                    </tr>
                  </table>
                  <div class='formula' style='margin-top: 15px;'>
                    Pricing Psychology:<br>
                    - Anchor: Elite at $299 makes Pro seem reasonable<br>
                    - Decoy: Starter vs Pro → most choose Pro<br>
                    - Annual: 17% discount (lock-in)
                  </div>
                </div>
                
                <div class='calculo-box'>
                  <h5>Step 15: Customer Acquisition Funnel</h5>
                  <div class='formula'>
                    AWARENESS (100,000 impressions)<br>
                    ↓ 2% CTR<br>
                    INTEREST (2,000 landing page visits)<br>
                    ↓ 15% webinar signup<br>
                    EVALUATION (300 webinar attendees)<br>
                    ↓ 40% start trial<br>
                    TRIAL (120 trial users)<br>
                    ↓ 25% convert<br>
                    CUSTOMER (30 paying)<br><br>
                    
                    <strong>CAC = $250/customer</strong><br>
                    <strong>LTV = $4,752</strong><br>
                    <strong>LTV:CAC = 19:1</strong> ✅
                  </div>
                </div>
              </div>
              
              <div class='calculo-box' style='margin-top: 20px;'>
                <h5>Break-Even Analysis</h5>
                <table style='width: 100%; color: #c7d2fe;'>
                  <tr style='background: #0a1128;'>
                    <th style='padding: 10px;'>Milestone</th>
                    <th style='padding: 10px;'>Customers</th>
                    <th style='padding: 10px;'>Monthly Revenue</th>
                    <th style='padding: 10px;'>Monthly Costs</th>
                    <th style='padding: 10px;'>Status</th>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Month 1</td>
                    <td style='padding: 8px;'>50</td>
                    <td style='padding: 8px;'>$2,450</td>
                    <td style='padding: 8px;'>$160,200</td>
                    <td style='padding: 8px; color: #f87171;'>-$157,750</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Month 12</td>
                    <td style='padding: 8px;'>500</td>
                    <td style='padding: 8px;'>$37,500</td>
                    <td style='padding: 8px;'>$162,000</td>
                    <td style='padding: 8px; color: #f87171;'>-$124,500</td>
                  </tr>
                  <tr style='background: #1a2f5a;'>
                    <td style='padding: 8px;'><strong>Month 24</strong></td>
                    <td style='padding: 8px;'><strong>2,500</strong></td>
                    <td style='padding: 8px;'><strong>$212,500</strong></td>
                    <td style='padding: 8px;'><strong>$190,000</strong></td>
                    <td style='padding: 8px; color: #4ade80;'><strong>+$22,500 ✅</strong></td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Month 36</td>
                    <td style='padding: 8px;'>10,000</td>
                    <td style='padding: 8px;'>$900,000</td>
                    <td style='padding: 8px;'>$290,000</td>
                    <td style='padding: 8px; color: #4ade80;'>+$610,000 🚀</td>
                  </tr>
                </table>
                <div class='formula' style='margin-top: 15px;'>
                  <strong>Funding Needed:</strong> $1.5M seed (18-month runway)<br>
                  <strong>Break-even:</strong> Month 24 (2,500 customers)
                </div>
              </div>
            ")
          )
        )
      ),
      
      # Disciplined Entrepreneurship: Phase 1B
      tabItem(
        tabName = "de_phase1b",
        fluidRow(
          box(
            width = 12,
            title = "Disciplined Entrepreneurship: Phase 1B - Exchange White-Label",
            status = "primary",
            solidHeader = TRUE,
            HTML("<h3>AlgoDynamix Exchange Partner Program - 24 Steps Analysis</h3>")
          )
        ),
        
        fluidRow(
          valueBoxOutput("de1b_tam", width = 3),
          valueBoxOutput("de1b_partners_y1", width = 3),
          valueBoxOutput("de1b_revenue_y1", width = 3),
          valueBoxOutput("de1b_roi", width = 3)
        ),
        
        fluidRow(
          box(
            width = 6,
            title = "Steps 1-7: Who is Your Customer? (B2B)",
            status = "info",
            collapsible = TRUE,
            HTML("
              <div class='calculo-box'>
                <h5>Step 2: Beachhead Market</h5>
                <p><strong>Chosen:</strong> Tier-2 Regional Crypto Exchanges</p>
                <p><strong>Examples:</strong> Bitso (LatAm), Luno (Africa), Coinhako (Asia)</p>
                <p><strong>Characteristics:</strong></p>
                <ul style='color: #c7d2fe;'>
                  <li>1-10M registered users</li>
                  <li>$500M-5B monthly trading volume</li>
                  <li>Growth-focused, need differentiation</li>
                  <li>Budget: $500K-2M for new products</li>
                </ul>
                <div class='formula'>
                  Market Size: ~30 exchanges globally
                </div>
              </div>
              
              <div class='calculo-box'>
                <h5>Step 3: End User Profile - 'David Chen'</h5>
                <p><strong>Role:</strong> VP of Product at CryptoNova Exchange</p>
                <p><strong>Demographics:</strong> 38, Singapore, ex-Google PM</p>
                <p><strong>Goals:</strong></p>
                <ul style='color: #c7d2fe;'>
                  <li>Increase MAU by 25%</li>
                  <li>Reduce churn from 8% to 5%</li>
                  <li>Launch differentiating feature by Q3</li>
                </ul>
                <p><strong>Pain Points:</strong></p>
                <ul style='color: #c7d2fe;'>
                  <li>Users lose money → blame platform → churn</li>
                  <li>Competitors adding AI, feeling behind</li>
                  <li>Engineering backlog 9+ months</li>
                  <li>CEO pressure: 'Where's our AI strategy?'</li>
                </ul>
              </div>
              
              <div class='calculo-box'>
                <h5>Step 4: TAM Calculation</h5>
                <div class='formula'>
                  Top-Down:<br>
                  Tier-2 exchanges: 30<br>
                  Avg users/exchange: 3M<br>
                  Adoption rate: 10%<br>
                  Revenue/user: $15/month<br>
                  AlgoDynamix share: 50%<br>
                  <strong>Per exchange: $27M/year</strong><br>
                  <strong>Total TAM: $810M/year</strong>
                </div>
                <div class='formula'>
                  Realistic (5 years):<br>
                  10 partners × $27M = <strong>$270M/year</strong>
                </div>
              </div>
            ")
          ),
          box(
            width = 6,
            title = "Steps 8-14: What Can You Do? (B2B)",
            status = "warning",
            collapsible = TRUE,
            HTML("
              <div class='calculo-box'>
                <h5>Step 8: Quantified Value (CryptoNova Example)</h5>
                <table style='width: 100%; color: #c7d2fe; border-collapse: collapse;'>
                  <tr style='border-bottom: 2px solid #4a90e2;'>
                    <th style='padding: 8px; text-align: left;'>Metric</th>
                    <th style='padding: 8px; text-align: right;'>Before</th>
                    <th style='padding: 8px; text-align: right;'>After</th>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Monthly Active Users</td>
                    <td style='padding: 8px; text-align: right;'>400K</td>
                    <td style='padding: 8px; text-align: right; color: #4ade80;'>470K (+17.5%)</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Churn Rate</td>
                    <td style='padding: 8px; text-align: right;'>8%</td>
                    <td style='padding: 8px; text-align: right; color: #4ade80;'>5.5% (-2.5pp)</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Trades/User/Month</td>
                    <td style='padding: 8px; text-align: right;'>12</td>
                    <td style='padding: 8px; text-align: right; color: #4ade80;'>15 (+25%)</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Trading Volume</td>
                    <td style='padding: 8px; text-align: right;'>$2B</td>
                    <td style='padding: 8px; text-align: right; color: #4ade80;'>$2.5B</td>
                  </tr>
                  <tr style='border-top: 2px solid #4a90e2;'>
                    <td style='padding: 8px;'>Exchange Revenue (0.15%)</td>
                    <td style='padding: 8px; text-align: right;'>$3M/mo</td>
                    <td style='padding: 8px; text-align: right; color: #4ade80;'>$3.75M/mo</td>
                  </tr>
                  <tr style='background: #1a2f5a; font-weight: bold;'>
                    <td style='padding: 8px;'>Incremental Revenue</td>
                    <td style='padding: 8px; text-align: right;'>-</td>
                    <td style='padding: 8px; text-align: right; color: #4ade80;'>+$750K/mo</td>
                  </tr>
                </table>
                <div class='formula' style='margin-top: 15px;'>
                  Annual Impact:<br>
                  Incremental revenue: $9M/year<br>
                  AlgoDynamix share (50%): $4.5M<br>
                  Base license: $100K<br>
                  <strong>Total: $4.6M/year from one partner</strong><br><br>
                  
                  Exchange ROI: $4.5M ÷ $50K = <strong>90x return</strong>
                </div>
              </div>
              
              <div class='calculo-box'>
                <h5>Step 10: Define Core (B2B)</h5>
                <p><strong>Positioning Statement:</strong></p>
                <div class='formula'>
                  'AlgoDynamix is the only white-label AI trading platform 
                  that combines Cambridge behavioral economics with explainable AI, 
                  enabling exchanges to differentiate, reduce churn, and increase 
                  volume through education and systematic decision support.'
                </div>
                <p style='margin-top: 15px;'><strong>Why Partners Choose AlgoDynamix:</strong></p>
                <ul style='color: #c7d2fe;'>
                  <li>4-week launch vs. 18-month build</li>
                  <li>Proven 18% retention improvement</li>
                  <li>Revenue-aligned pricing (success fees)</li>
                  <li>Marketing assets included</li>
                </ul>
              </div>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            title = "Steps 15-24: B2B Sales & Execution",
            status = "success",
            collapsible = TRUE,
            HTML("
              <div style='display: grid; grid-template-columns: 1fr 1fr; gap: 20px;'>
                <div class='calculo-box'>
                  <h5>Step 15: B2B Sales Cycle (6-9 months)</h5>
                  <div class='formula'>
                    <strong>Month 1-2: Discovery</strong><br>
                    - Initial call with VP Product<br>
                    - Demo to product team<br>
                    - Share competitor case study<br><br>
                    
                    <strong>Month 3-4: Technical Evaluation</strong><br>
                    - API documentation review<br>
                    - Pilot proposal (10K users, 90 days)<br>
                    - Legal/compliance review<br><br>
                    
                    <strong>Month 5-6: Pilot Execution</strong><br>
                    - Engineering integration (4 weeks)<br>
                    - A/B test vs. control group<br>
                    - Gather metrics<br><br>
                    
                    <strong>Month 7-8: Results Analysis</strong><br>
                    - Present impact: +18% retention, +23% volume<br>
                    - Calculate annual revenue projection<br>
                    - Negotiate full contract<br><br>
                    
                    <strong>Month 9: Launch</strong><br>
                    - Legal finalization<br>
                    - Full rollout to all users<br>
                    - Co-marketing campaign
                  </div>
                </div>
                
                <div class='calculo-box'>
                  <h5>Step 16-18: B2B Pricing Structure</h5>
                  <table style='width: 100%; color: #c7d2fe; margin-top: 10px;'>
                    <tr style='background: #0a1128;'>
                      <th style='padding: 10px;'>Exchange Tier</th>
                      <th style='padding: 10px;'>Base</th>
                      <th style='padding: 10px;'>Rev Share</th>
                    </tr>
                    <tr>
                      <td style='padding: 8px;'>Tier-3 (<1M)</td>
                      <td style='padding: 8px;'>$50K/yr</td>
                      <td style='padding: 8px;'>40%</td>
                    </tr>
                    <tr style='background: #1a2f5a;'>
                      <td style='padding: 8px;'><strong>Tier-2 (1-10M)</strong></td>
                      <td style='padding: 8px;'><strong>$100K/yr</strong></td>
                      <td style='padding: 8px;'><strong>50%</strong></td>
                    </tr>
                    <tr>
                      <td style='padding: 8px;'>Tier-1 (10M+)</td>
                      <td style='padding: 8px;'>Custom</td>
                      <td style='padding: 8px;'>30-40%</td>
                    </tr>
                  </table>
                  
                  <div class='formula' style='margin-top: 15px;'>
                    <strong>Revenue Share Calculation:</strong><br>
                    1. Baseline: Exchange revenue (Month 0)<br>
                    2. Track: Users engaging with AlgoDynamix<br>
                    3. Attribute: Incremental fees to AlgoDynamix<br>
                    4. Split: 50% to each party<br><br>
                    
                    <strong>Contract Terms:</strong><br>
                    - Initial: 3-year commitment<br>
                    - Auto-renew unless 90-day notice<br>
                    - Payment: Annual base, monthly rev share
                  </div>
                </div>
              </div>
              
              <div class='calculo-box' style='margin-top: 20px;'>
                <h5>Profitability Analysis (Phase 1B Only)</h5>
                <table style='width: 100%; color: #c7d2fe;'>
                  <tr style='background: #0a1128;'>
                    <th style='padding: 10px;'>Year</th>
                    <th style='padding: 10px;'>Partners</th>
                    <th style='padding: 10px;'>Revenue</th>
                    <th style='padding: 10px;'>Costs</th>
                    <th style='padding: 10px;'>Profit</th>
                  </tr>
                  <tr style='background: #1a2f5a;'>
                    <td style='padding: 8px;'><strong>Year 1</strong></td>
                    <td style='padding: 8px;'>3</td>
                    <td style='padding: 8px;'>$4.5M</td>
                    <td style='padding: 8px;'>$1.785M</td>
                    <td style='padding: 8px; color: #4ade80;'><strong>+$2.715M ✅</strong></td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Year 2</td>
                    <td style='padding: 8px;'>8</td>
                    <td style='padding: 8px;'>$16M</td>
                    <td style='padding: 8px;'>$2.5M</td>
                    <td style='padding: 8px; color: #4ade80;'>+$13.5M</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Year 3</td>
                    <td style='padding: 8px;'>15</td>
                    <td style='padding: 8px;'>$37.5M</td>
                    <td style='padding: 8px;'>$3.5M</td>
                    <td style='padding: 8px; color: #4ade80;'>+$34M</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Year 5</td>
                    <td style='padding: 8px;'>35</td>
                    <td style='padding: 8px;'>$122.5M</td>
                    <td style='padding: 8px;'>$6M</td>
                    <td style='padding: 8px; color: #4ade80;'>+$116.5M 🚀</td>
                  </tr>
                </table>
                <div class='formula' style='margin-top: 15px;'>
                  <strong>Why Faster to Profitability than 1A?</strong><br>
                  ✅ Larger deal sizes ($1.5M vs. $588/year)<br>
                  ✅ Fewer customers to serve (3 vs. 500)<br>
                  ✅ Revenue share = built-in scalability<br>
                  ✅ Profitable from Year 1
                </div>
              </div>
            ")
          )
        )
      ),
      
      # Business Model Canvas: Phase 1A
      tabItem(
        tabName = "bmg_phase1a",
        fluidRow(
          box(
            width = 12,
            title = "Business Model Canvas: Phase 1A - Retail Platform",
            status = "primary",
            solidHeader = TRUE,
            HTML("<h3>AlgoDynamix Trader Academy - 9 Building Blocks</h3>")
          )
        ),
        
        fluidRow(
          box(
            width = 4,
            title = "1. Customer Segments",
            status = "info",
            solidHeader = TRUE,
            HTML("
              <p><strong>Primary Beachhead:</strong></p>
              <div class='calculo-box'>
                <h5>Failed Crypto Day Traders</h5>
                <ul style='color: #c7d2fe;'>
                  <li>Lost $5K-50K trading</li>
                  <li>Education-receptive</li>
                  <li>3-5M globally</li>
                  <li>Age: 25-45</li>
                </ul>
              </div>
              
              <p style='margin-top: 15px;'><strong>Segment Type:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>✅ Niche market (specific pain)</li>
                <li>✅ Segmented (Starter/Pro/Elite)</li>
                <li>❌ Not multi-sided (yet)</li>
              </ul>
            ")
          ),
          box(
            width = 4,
            title = "2. Value Propositions",
            status = "warning",
            solidHeader = TRUE,
            HTML("
              <div class='calculo-box'>
                <h5>Unique Value Proposition</h5>
                <p style='font-style: italic; color: #7ec8e3;'>
                  'Transform from emotional gambler to systematic trader through 
                  Cambridge-backed AI education—recover losses within 18 months 
                  or money back.'
                </p>
              </div>
              
              <p><strong>Value Elements:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li><strong>Newness:</strong> Behavioral economics approach</li>
                <li><strong>Performance:</strong> 7.8x ROI</li>
                <li><strong>Risk Reduction:</strong> Paper trading first</li>
                <li><strong>Accessibility:</strong> No coding required</li>
                <li><strong>Brand:</strong> Cambridge credibility</li>
              </ul>
            ")
          ),
          box(
            width = 4,
            title = "3. Channels",
            status = "success",
            solidHeader = TRUE,
            HTML("
              <p><strong>Awareness:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>YouTube (owned)</li>
                <li>SEO/Blog (owned)</li>
                <li>Paid ads (Facebook/Instagram)</li>
                <li>Reddit organic (earned)</li>
              </ul>
              
              <p><strong>Evaluation:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Weekly webinars</li>
                <li>Free 3 modules</li>
                <li>Case studies</li>
              </ul>
              
              <p><strong>Purchase:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>14-day free trial</li>
                <li>Stripe checkout</li>
              </ul>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 4,
            title = "4. Customer Relationships",
            status = "info",
            HTML("
              <table style='width: 100%; color: #c7d2fe;'>
                <tr style='background: #0a1128;'>
                  <th style='padding: 8px;'>Tier</th>
                  <th style='padding: 8px;'>Relationship</th>
                </tr>
                <tr>
                  <td style='padding: 8px;'>Starter</td>
                  <td style='padding: 8px;'>Self-service + Community</td>
                </tr>
                <tr>
                  <td style='padding: 8px;'>Pro</td>
                  <td style='padding: 8px;'>Personal assistance</td>
                </tr>
                <tr>
                  <td style='padding: 8px;'>Elite</td>
                  <td style='padding: 8px;'>Dedicated 1-on-1 coaching</td>
                </tr>
              </table>
              
              <div class='calculo-box' style='margin-top: 15px;'>
                <h5>Retention Mechanisms</h5>
                <ul style='color: #c7d2fe;'>
                  <li>7-day onboarding sequence</li>
                  <li>Daily engagement hooks</li>
                  <li>Gamification (badges)</li>
                  <li>Community forum</li>
                  <li>Referral rewards</li>
                </ul>
              </div>
            ")
          ),
          box(
            width = 4,
            title = "5. Revenue Streams",
            status = "warning",
            HTML("
              <div class='calculo-box'>
                <h5>Recurring Subscription (SaaS)</h5>
                <table style='width: 100%; color: #c7d2fe; margin-top: 10px;'>
                  <tr style='background: #0a1128;'>
                    <th style='padding: 8px;'>Tier</th>
                    <th style='padding: 8px;'>Monthly</th>
                    <th style='padding: 8px;'>Annual</th>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Starter</td>
                    <td style='padding: 8px;'>$49</td>
                    <td style='padding: 8px;'>$490</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Pro</td>
                    <td style='padding: 8px;'>$99</td>
                    <td style='padding: 8px;'>$990</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Elite</td>
                    <td style='padding: 8px;'>$299</td>
                    <td style='padding: 8px;'>$2,990</td>
                  </tr>
                </table>
              </div>
              
              <div class='calculo-box' style='margin-top: 15px;'>
                <h5>Revenue Projections</h5>
                <ul style='color: #c7d2fe;'>
                  <li>Year 1: $450K (500 customers)</li>
                  <li>Year 3: $10.8M (10K customers)</li>
                  <li>Year 5: $90M (75K customers)</li>
                </ul>
              </div>
            ")
          ),
          box(
            width = 4,
            title = "6. Key Resources",
            status = "success",
            HTML("
              <p><strong>Intellectual:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>10-year Flag database</li>
                <li>Behavioral algorithms</li>
                <li>Cambridge brand</li>
                <li>100+ educational videos</li>
              </ul>
              
              <p><strong>Human:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Founders (Cambridge PhDs)</li>
                <li>3 engineers (R Shiny)</li>
                <li>2 data scientists</li>
                <li>1 content creator</li>
                <li>1 growth marketer</li>
              </ul>
              
              <p><strong>Financial:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>$1.5M seed funding</li>
                <li>18-month runway</li>
              </ul>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 4,
            title = "7. Key Activities",
            status = "info",
            HTML("
              <p><strong>Product Development:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>R Shiny platform (Months 1-3)</li>
                <li>Flag Academy modules</li>
                <li>Backtesting engine</li>
                <li>Exchange API integrations</li>
              </ul>
              
              <p><strong>Marketing:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>2 YouTube videos/week</li>
                <li>3 blog posts/week</li>
                <li>Weekly webinars</li>
                <li>Paid ad optimization</li>
              </ul>
              
              <p><strong>Customer Success:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Onboarding sequences</li>
                <li>Email support (24hr SLA)</li>
                <li>Community management</li>
              </ul>
            ")
          ),
          box(
            width = 4,
            title = "8. Key Partnerships",
            status = "warning",
            HTML("
              <p><strong>Strategic Alliances:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li><strong>Exchanges:</strong> Coinbase, Binance (API + affiliates)</li>
                <li><strong>Data:</strong> CryptoCompare ($5K/mo)</li>
                <li><strong>Cambridge:</strong> Brand licensing (2% revenue)</li>
                <li><strong>Influencers:</strong> YouTubers (20% commission)</li>
              </ul>
              
              <p><strong>Key Suppliers:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>AWS (hosting): $10K/mo</li>
                <li>Stripe (payments): 2.9% + $0.30</li>
                <li>SendGrid (email): $500/mo</li>
                <li>Intercom (support): $1K/mo</li>
              </ul>
            ")
          ),
          box(
            width = 4,
            title = "9. Cost Structure",
            status = "success",
            HTML("
              <div class='calculo-box'>
                <h5>Fixed Costs (Monthly)</h5>
                <ul style='color: #c7d2fe;'>
                  <li>Personnel: $100K (10 employees)</li>
                  <li>Office: $5K</li>
                  <li>Software/Infrastructure: $15K</li>
                  <li>Data feeds: $5K</li>
                  <li>Marketing: $30K</li>
                  <li>Legal/Insurance: $5K</li>
                </ul>
                <div class='formula'>
                  <strong>Total Fixed: $160K/mo ($1.92M/year)</strong>
                </div>
              </div>
              
              <div class='calculo-box' style='margin-top: 15px;'>
                <h5>Variable Costs (Per Customer)</h5>
                <ul style='color: #c7d2fe;'>
                  <li>Payment processing: $1.50/mo</li>
                  <li>Server: $0.50/mo</li>
                  <li>Support: $2/mo</li>
                </ul>
                <div class='formula'>
                  <strong>Total Variable: $4/customer/mo</strong>
                </div>
              </div>
              
              <div class='calculo-box' style='margin-top: 15px;'>
                <h5>Break-Even</h5>
                <p style='color: #4ade80;'><strong>Month 24: 2,500 customers</strong></p>
              </div>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            title = "Business Model Patterns",
            status = "primary",
            HTML("
              <div style='display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px;'>
                <div class='calculo-box'>
                  <h5>Freemium</h5>
                  <p>Free tier (3 modules) converts 5% to paid</p>
                </div>
                <div class='calculo-box'>
                  <h5>Subscription</h5>
                  <p>Recurring SaaS revenue model</p>
                </div>
                <div class='calculo-box'>
                  <h5>Long Tail</h5>
                  <p>Serve many small customers at scale</p>
                </div>
                <div class='calculo-box'>
                  <h5>Value-Driven</h5>
                  <p>Premium pricing justified by 7.8x ROI</p>
                </div>
              </div>
            ")
          )
        )
      ),
      
      # Business Model Canvas: Phase 1B
      tabItem(
        tabName = "bmg_phase1b",
        fluidRow(
          box(
            width = 12,
            title = "Business Model Canvas: Phase 1B - Exchange White-Label",
            status = "primary",
            solidHeader = TRUE,
            HTML("<h3>AlgoDynamix Exchange Partner Program - 9 Building Blocks</h3>")
          )
        ),
        
        fluidRow(
          box(
            width = 4,
            title = "1. Customer Segments (B2B)",
            status = "info",
            solidHeader = TRUE,
            HTML("
              <p><strong>Primary Beachhead:</strong></p>
              <div class='calculo-box'>
                <h5>Tier-2 Regional Exchanges</h5>
                <ul style='color: #c7d2fe;'>
                  <li>1-10M registered users</li>
                  <li>$500M-5B monthly volume</li>
                  <li>Growth-focused</li>
                  <li>~30 exchanges globally</li>
                </ul>
              </div>
              
              <p style='margin-top: 15px;'><strong>Decision-Making Unit:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li><strong>Economic Buyer:</strong> CEO/CFO</li>
                <li><strong>Technical Buyer:</strong> CTO</li>
                <li><strong>Champion:</strong> VP Product</li>
                <li><strong>Influencers:</strong> Marketing, Legal</li>
              </ul>
              
              <p><strong>Segment Type:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>✅ Niche B2B market</li>
                <li>✅ Multi-sided (B2B2C)</li>
                <li>✅ Segmented by tier</li>
              </ul>
            ")
          ),
          box(
            width = 4,
            title = "2. Value Propositions (B2B)",
            status = "warning",
            solidHeader = TRUE,
            HTML("
              <div class='calculo-box'>
                <h5>B2B Value Proposition</h5>
                <p style='font-style: italic; color: #7ec8e3;'>
                  'White-label AI trading platform that increases exchange revenue 
                  by $4.5M+/year through higher retention and volume—without the 
                  18-month dev cycle or $2M+ in-house cost.'
                </p>
              </div>
              
              <p><strong>Value Drivers:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li><strong>Speed:</strong> 4-week launch vs. 18-month build</li>
                <li><strong>Proven:</strong> +18% retention case studies</li>
                <li><strong>Risk-Free:</strong> 90-day pilot program</li>
                <li><strong>Aligned:</strong> Revenue share pricing</li>
                <li><strong>Turnkey:</strong> Marketing assets included</li>
                <li><strong>Innovation:</strong> Cambridge AI differentiation</li>
              </ul>
              
              <div class='calculo-box' style='margin-top: 15px;'>
                <h5>Quantified Impact</h5>
                <p style='color: #4ade80;'>90x ROI for exchange partners</p>
              </div>
            ")
          ),
          box(
            width = 4,
            title = "3. Channels (B2B)",
            status = "success",
            solidHeader = TRUE,
            HTML("
              <p><strong>Awareness:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Conferences (TOKEN2049, Consensus)</li>
                <li>Industry press (CoinDesk, The Block)</li>
                <li>LinkedIn thought leadership</li>
                <li>Trade publication ads</li>
              </ul>
              
              <p><strong>Evaluation:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Enterprise landing page + ROI calculator</li>
                <li>Demo videos (3 min)</li>
                <li>Case study PDFs</li>
                <li>Reference customer calls</li>
              </ul>
              
              <p><strong>Purchase:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Direct enterprise sales</li>
                <li>90-day pilot program</li>
                <li>Legal review + DocuSign</li>
              </ul>
              
              <p><strong>Delivery:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>API/SDK integration (4 weeks)</li>
                <li>White-label UI components</li>
                <li>Solutions engineer support</li>
              </ul>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 4,
            title = "4. Customer Relationships (B2B)",
            status = "info",
            HTML("
              <div class='calculo-box'>
                <h5>High-Touch Enterprise Model</h5>
              </div>
              
              <p><strong>Pre-Sales (Months 1-6):</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Discovery call with founder</li>
                <li>Custom demo for exchange</li>
                <li>Weekly check-ins</li>
                <li>Economic modeling</li>
              </ul>
              
              <p><strong>Pilot (Months 7-9):</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Dedicated solutions engineer</li>
                <li>Daily standups during integration</li>
                <li>Slack channel</li>
                <li>Joint A/B test analysis</li>
              </ul>
              
              <p><strong>Post-Launch:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Named Customer Success Manager</li>
                <li>Quarterly Business Reviews</li>
                <li>Annual strategic planning</li>
                <li>Co-marketing initiatives</li>
                <li>Partner forum community</li>
              </ul>
            ")
          ),
          box(
            width = 4,
            title = "5. Revenue Streams (B2B)",
            status = "warning",
            HTML("
              <div class='calculo-box'>
                <h5>Hybrid: Base + Revenue Share</h5>
                <table style='width: 100%; color: #c7d2fe; margin-top: 10px;'>
                  <tr style='background: #0a1128;'>
                    <th style='padding: 8px;'>Tier</th>
                    <th style='padding: 8px;'>Base</th>
                    <th style='padding: 8px;'>Rev Share</th>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Tier-3</td>
                    <td style='padding: 8px;'>$50K/yr</td>
                    <td style='padding: 8px;'>40%</td>
                  </tr>
                  <tr style='background: #1a2f5a;'>
                    <td style='padding: 8px;'><strong>Tier-2</strong></td>
                    <td style='padding: 8px;'><strong>$100K/yr</strong></td>
                    <td style='padding: 8px;'><strong>50%</strong></td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Tier-1</td>
                    <td style='padding: 8px;'>Custom</td>
                    <td style='padding: 8px;'>30-40%</td>
                  </tr>
                </table>
              </div>
              
              <div class='calculo-box' style='margin-top: 15px;'>
                <h5>Revenue Projections</h5>
                <ul style='color: #c7d2fe;'>
                  <li>Year 1: $4.5M (3 partners)</li>
                  <li>Year 3: $37.5M (15 partners)</li>
                  <li>Year 5: $122.5M (35 partners)</li>
                </ul>
              </div>
              
              <div class='calculo-box' style='margin-top: 15px;'>
                <h5>Typical Partner Revenue</h5>
                <p style='color: #4ade80;'>$1.5M - $5M per year</p>
              </div>
            ")
          ),
          box(
            width = 4,
            title = "6. Key Resources (B2B)",
            status = "success",
            HTML("
              <p><strong>Intellectual:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Flag algorithms (same as 1A)</li>
                <li>White-label SDK</li>
                <li>API documentation</li>
                <li>Partner Success Playbook</li>
                <li>Master Service Agreement</li>
              </ul>
              
              <p><strong>Human (Incremental):</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>1 Head of Partnerships</li>
                <li>1 Solutions Engineer</li>
                <li>1 VP Customer Success</li>
                <li>2 Customer Success Managers</li>
              </ul>
              
              <p><strong>Financial:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>+$1M seed extension</li>
                <li>Sales/legal/conferences</li>
              </ul>
              
              <p><strong>Network:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Exchange industry connections</li>
                <li>Regulatory expertise (law firms)</li>
              </ul>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 4,
            title = "7. Key Activities (B2B)",
            status = "info",
            HTML("
              <p><strong>Enterprise Sales:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Exchange prospecting (LinkedIn)</li>
                <li>Conference networking</li>
                <li>Custom demos (weekly)</li>
                <li>Pilot negotiations</li>
                <li>Contract closing</li>
              </ul>
              
              <p><strong>Product (White-Label):</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>API/SDK development</li>
                <li>White-label UI components</li>
                <li>Admin dashboard</li>
                <li>Integration tools</li>
              </ul>
              
              <p><strong>Customer Success:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>4-week onboarding</li>
                <li>Technical support (Slack)</li>
                <li>Quarterly Business Reviews</li>
                <li>ROI tracking</li>
              </ul>
              
              <p><strong>Co-Marketing:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Press releases</li>
                <li>Case study videos</li>
                <li>Co-branded webinars</li>
              </ul>
            ")
          ),
          box(
            width = 4,
            title = "8. Key Partnerships (B2B)",
            status = "warning",
            HTML("
              <p><strong>Technology Partners:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li><strong>AWS:</strong> Enterprise support, co-selling</li>
                <li><strong>Cloudflare:</strong> DDoS protection, CDN</li>
                <li><strong>Twilio:</strong> SMS notifications</li>
              </ul>
              
              <p><strong>Channel Partners:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li><strong>Consultancies:</strong> Deloitte, Accenture (20% commission)</li>
                <li><strong>Infrastructure:</strong> Fireblocks, Anchorage</li>
              </ul>
              
              <p><strong>Legal/Compliance:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Ropes & Gray ($50K/yr retainer)</li>
                <li>Lloyd's E&O insurance ($10M policy)</li>
                <li>HackerOne bug bounty ($100K/yr)</li>
              </ul>
              
              <p><strong>Industry Associations:</strong></p>
              <ul style='color: #c7d2fe;'>
                <li>Crypto Exchange Alliance</li>
                <li>Blockchain Association</li>
              </ul>
            ")
          ),
          box(
            width = 4,
            title = "9. Cost Structure (B2B)",
            status = "success",
            HTML("
              <div class='calculo-box'>
                <h5>Fixed Costs (Incremental)</h5>
                <ul style='color: #c7d2fe;'>
                  <li>Personnel: +$70K/mo (7 employees)</li>
                  <li>Sales/Marketing: $20K/mo</li>
                  <li>Infrastructure (Enterprise): +$10K/mo</li>
                  <li>Legal/Compliance: $10K/mo</li>
                  <li>Insurance: $5K/mo</li>
                </ul>
                <div class='formula'>
                  <strong>Total Incremental: $115K/mo ($1.38M/year)</strong>
                </div>
              </div>
              
              <div class='calculo-box' style='margin-top: 15px;'>
                <h5>Variable Costs (Per Partner)</h5>
                <ul style='color: #c7d2fe;'>
                  <li>Onboarding: $25K (one-time)</li>
                  <li>Ongoing support: $5K/mo</li>
                </ul>
              </div>
              
              <div class='calculo-box' style='margin-top: 15px;'>
                <h5>Profitability</h5>
                <p style='color: #4ade80;'><strong>Profitable Year 1 with 3 partners</strong></p>
                <p>Year 1: $4.5M revenue - $1.785M costs = <strong>+$2.715M profit</strong></p>
              </div>
              
              <div class='calculo-box' style='margin-top: 15px;'>
                <h5>Cost Structure Type</h5>
                <p>Value-driven + Economies of scale</p>
              </div>
            ")
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            title = "Business Model Patterns & Strategic Synergies",
            status = "primary",
            HTML("
              <div style='display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px;'>
                <div class='calculo-box'>
                  <h5>Phase 1B Patterns</h5>
                  <ul style='color: #c7d2fe; line-height: 1.8;'>
                    <li><strong>White-Label/OEM:</strong> Tech provider to distributor</li>
                    <li><strong>Revenue Sharing:</strong> Aligned incentives (success fees)</li>
                    <li><strong>B2B2C:</strong> Serve businesses who serve consumers</li>
                    <li><strong>Licensing:</strong> IP commercialization</li>
                  </ul>
                </div>
                
                <div class='calculo-box'>
                  <h5>Integrated Strategy (1A + 1B)</h5>
                  <ol style='color: #c7d2fe; line-height: 1.8;'>
                    <li>Retail builds brand awareness</li>
                    <li>Exchanges see traction → sign deals</li>
                    <li>Exchange promotes to millions</li>
                    <li>End users want standalone → retail</li>
                    <li><strong>Virtuous cycle</strong> 🔄</li>
                  </ol>
                </div>
              </div>
              
              <div class='calculo-box' style='margin-top: 20px;'>
                <h5>Combined Economics (1A + 1B)</h5>
                <table style='width: 100%; color: #c7d2fe; margin-top: 10px;'>
                  <tr style='background: #0a1128;'>
                    <th style='padding: 10px;'>Year</th>
                    <th style='padding: 10px;'>1A Revenue</th>
                    <th style='padding: 10px;'>1B Revenue</th>
                    <th style='padding: 10px;'>Total</th>
                    <th style='padding: 10px;'>Profit Margin</th>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Year 1</td>
                    <td style='padding: 8px;'>$450K</td>
                    <td style='padding: 8px;'>$4.5M</td>
                    <td style='padding: 8px;'><strong>$4.95M</strong></td>
                    <td style='padding: 8px; color: #4ade80;'>25%</td>
                  </tr>
                  <tr>
                    <td style='padding: 8px;'>Year 2</td>
                    <td style='padding: 8px;'>$2.55M</td>
                    <td style='padding: 8px;'>$16M</td>
                    <td style='padding: 8px;'><strong>$18.55M</strong></td>
                    <td style='padding: 8px; color: #4ade80;'>75%</td>
                  </tr>
                  <tr style='background: #1a2f5a;'>
                    <td style='padding: 8px;'><strong>Year 3</strong></td>
                    <td style='padding: 8px;'>$10.8M</td>
                    <td style='padding: 8px;'>$37.5M</td>
                    <td style='padding: 8px;'><strong>$48.3M</strong></td>
                    <td style='padding: 8px; color: #4ade80;'><strong>86%</strong></td>
                  </tr>
                </table>
                <div class='formula' style='margin-top: 15px;'>
                  <strong>Key Insight:</strong> Phase 1B (exchanges) is the cash cow that funds Phase 1A (retail) growth
                </div>
              </div>
            ")
          )
        )
      )
    )
  )
)

# Server logic
server <- function(input, output, session) {
  
  # Value boxes for DE Phase 1A
  output$de1a_tam <- renderValueBox({
    valueBox(
      value = "10M",
      subtitle = "Total Addressable Market",
      icon = icon("users"),
      color = "blue"
    )
  })
  
  output$de1a_customers_y1 <- renderValueBox({
    valueBox(
      value = "500",
      subtitle = "Year 1 Customers",
      icon = icon("user-check"),
      color = "green"
    )
  })
  
  output$de1a_arr_y1 <- renderValueBox({
    valueBox(
      value = "$450K",
      subtitle = "Year 1 ARR",
      icon = icon("dollar-sign"),
      color = "yellow"
    )
  })
  
  output$de1a_roi <- renderValueBox({
    valueBox(
      value = "7.8x",
      subtitle = "Customer ROI",
      icon = icon("chart-line"),
      color = "purple"
    )
  })
  
  # Value boxes for DE Phase 1B
  output$de1b_tam <- renderValueBox({
    valueBox(
      value = "$810M",
      subtitle = "Total Addressable Market",
      icon = icon("building"),
      color = "blue"
    )
  })
  
  output$de1b_partners_y1 <- renderValueBox({
    valueBox(
      value = "3",
      subtitle = "Year 1 Partners",
      icon = icon("handshake"),
      color = "green"
    )
  })
  
  output$de1b_revenue_y1 <- renderValueBox({
    valueBox(
      value = "$4.5M",
      subtitle = "Year 1 Revenue",
      icon = icon("dollar-sign"),
      color = "yellow"
    )
  })
  
  output$de1b_roi <- renderValueBox({
    valueBox(
      value = "90x",
      subtitle = "Exchange Partner ROI",
      icon = icon("rocket"),
      color = "purple"
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)