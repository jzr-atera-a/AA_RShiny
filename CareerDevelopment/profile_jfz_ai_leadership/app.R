# Executive AI Leadership Portfolio - Interactive Dashboard
# Showcasing Technical Leadership in AI Infrastructure & Large Team Management

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(tidyr)
library(lubridate)
library(shinycssloaders)
library(stringr)

# Enhanced CSS with specified gradient colors
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
    margin-bottom: 25px !important;
  }
  .box-header { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    color: white !important;
    border-radius: 12px 12px 0 0 !important; 
    font-weight: 600 !important;
    padding: 20px !important;
    font-size: 16px !important;
  }
  .executive-summary-box { 
    background: linear-gradient(135deg, #ffffff 0%, #f8f9ff 100%);
    border: none;
    border-left: 5px solid #667eea; 
    padding: 30px; 
    margin-bottom: 30px; 
    border-radius: 12px; 
    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.1);
  }
  .achievement-box {
    background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);
    border: 1px solid #e3e8ff;
    border-left: 5px solid #4f46e5;
    padding: 25px;
    margin: 20px 0;
    border-radius: 12px;
    box-shadow: 0 2px 10px rgba(79, 70, 229, 0.1);
  }
  .leadership-highlight {
    background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);
    border: 1px solid #e3e8ff;
    border-left: 5px solid #667eea;
    padding: 25px;
    margin: 20px 0;
    border-radius: 12px;
    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.1);
  }
  .small-box { 
    border-radius: 12px !important; 
    box-shadow: 0 4px 15px rgba(0,0,0,0.1) !important;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
    margin-bottom: 25px !important;
  }
  .small-box .icon { opacity: 0.8 !important; font-size: 60px !important; }
  .small-box h3 { font-weight: 700 !important; font-size: 28px !important; }
  .small-box p { font-size: 14px !important; font-weight: 600 !important; }
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
    padding: 12px 25px !important;
    transition: all 0.3s ease !important;
  }
  .btn-primary:hover {
    transform: translateY(-2px) !important;
    box-shadow: 0 8px 20px rgba(102, 126, 234, 0.3) !important;
  }
  h3, h4 { color: #2c3e50; font-weight: 600; }
  .executive-title { 
    color: #667eea; 
    font-size: 24px; 
    font-weight: 800; 
    margin-bottom: 10px;
    text-transform: uppercase;
    letter-spacing: 1px;
  }
  .role-description { 
    color: #475569; 
    font-size: 16px; 
    font-style: italic; 
    margin-bottom: 20px;
    line-height: 1.6;
  }
  .metric-highlight {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 8px 15px;
    border-radius: 20px;
    font-weight: 700;
    display: inline-block;
    margin: 5px;
    box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
  }
  .team-size {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 10px 20px;
    border-radius: 25px;
    font-weight: 700;
    font-size: 18px;
    display: inline-block;
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
  }
  .ai-focus {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 8px 16px;
    border-radius: 20px;
    font-weight: 600;
    display: inline-block;
    margin: 5px;
  }
"

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "Executive AI Leadership Portfolio - J.-Francisco ZUBIZARRETA"),
  
  dashboardSidebar(
    tags$head(tags$style(HTML(css))),
    sidebarMenu(
      menuItem("Education & Qualifications", tabName = "education", icon = icon("graduation-cap")),
      menuItem("Atera Analytics (2023-2025)", tabName = "atera", icon = icon("brain")),
      menuItem("Santander Bank (2019-2023)", tabName = "santander", icon = icon("building")),
      menuItem("Caltex-Ampol (2017-2019)", tabName = "caltex", icon = icon("industry")),
      menuItem("BCG Consulting (2015-2017)", tabName = "bcg", icon = icon("chart-line")),
      menuItem("Rio Tinto (2009-2015)", tabName = "rio", icon = icon("mountain")),
      menuItem("Leadership Analytics", tabName = "analytics", icon = icon("users"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # Education Tab
      tabItem(tabName = "education",
              fluidRow(
                box(
                  title = "Executive Summary - AI Technical Leadership", status = "primary", solidHeader = TRUE,
                  width = 12, collapsible = TRUE,
                  div(class = "executive-summary-box",
                      div(class = "executive-title", "J.-Francisco Zubizarreta-R. Senior Director - AI Platform Engineering"),
                      div(class = "role-description", 
                          "Technical leader with 15+ years building and scaling AI infrastructure in production environments. 
                          Proven track record leading 50+ person engineering teams across AI, infrastructure, and backend systems. 
                          Deep expertise in LLM pipelines, ML systems at enterprise scale, and fault-tolerant architectures."),
                      br(),
                      h4("Key Differentiators for This Role"),
                      div(class = "leadership-highlight",
                          tags$ul(
                            tags$li(HTML("<strong>Built, Not Advised:</strong> Direct ownership of LLM pipelines and ML systems in production environments")),
                            tags$li(HTML("<strong>Scale Leadership:</strong> Managed 50+ engineers across distributed teams in UK, Europe, and Americas")),
                            tags$li(HTML("<strong>Enterprise Production:</strong> Deployed AI systems serving 30M+ customers in regulated financial environments")),
                            tags$li(HTML("<strong>Technical Judgment:</strong> Deep Python/ML foundations with strategic architecture decisions")),
                            tags$li(HTML("<strong>Product-First:</strong> Built systems in product companies, not consulting or services"))
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("total_experience"),
                valueBoxOutput("team_leadership_scale"),
                valueBoxOutput("ai_systems_built")
              ),
              
              fluidRow(
                box(
                  title = "Educational Foundation - Advanced AI & Management", status = "primary", solidHeader = TRUE,
                  width = 6,
                  div(class = "achievement-box",
                      h4("University of Cambridge, UK"),
                      div(class = "ai-focus", "Master of Business Administration"),
                      p(HTML("<strong>Concentration:</strong> Advanced Finance & Management of Large AI Teams")),
                      p(HTML("<strong>Relevance:</strong> Strategic leadership training specifically focused on AI team management and technical decision-making at scale"))
                  ),
                  div(class = "achievement-box",
                      h4("University of Sydney, Australia"),
                      div(class = "ai-focus", "Postgraduate by Research - High Distinction"),
                      p(HTML("<strong>Thesis:</strong> Bayesian Learning - Led to Post-Doc Position in AI")),
                      p(HTML("<strong>Relevance:</strong> Deep theoretical foundation in AI/ML methodologies, research-to-production experience"))
                  )
                ),
                box(
                  title = "Technical Foundation", status = "success", solidHeader = TRUE,
                  width = 6,
                  div(class = "achievement-box",
                      h4("RMIT University & ITESM"),
                      div(class = "ai-focus", "Bachelor of Science - High Distinction"),
                      p(HTML("<strong>Dual Major:</strong> Computer Science & Mechanical Engineering")),
                      p(HTML("<strong>GPA:</strong> 4.6/5 (92/100)")),
                      p(HTML("<strong>Relevance:</strong> Strong algorithmic and systems engineering foundation essential for AI infrastructure"))
                  ),
                  br(),
                  h4("Core Technical Competencies"),
                  div(class = "metric-highlight", "Python & ML Frameworks"),
                  div(class = "metric-highlight", "Distributed Systems"),
                  div(class = "metric-highlight", "Cloud Architecture"),
                  div(class = "metric-highlight", "LLM Pipeline Design")
                )
              ),
              
              fluidRow(
                box(
                  title = "Career Progression - Technical Leadership Scale", status = "warning", solidHeader = TRUE,
                  width = 12,
                  withSpinner(plotlyOutput("career_progression_plot"), color = "#667eea")
                )
              )
      ),
      
      # Atera Analytics Tab
      tabItem(tabName = "atera",
              fluidRow(
                box(
                  title = "Atera Analytics & Cybernet - Director (2023-2025)", status = "primary", solidHeader = TRUE,
                  width = 12,
                  div(class = "executive-summary-box",
                      div(class = "executive-title", "AI-Driven Infrastructure & LLM Architecture"),
                      div(class = "role-description", 
                          "UK Government contractor specializing in digital products, infrastructure, and Large Language Models. 
                          Led advanced AI system development with focus on real-time applications and ethical AI implementation."),
                      br(),
                      div(class = "leadership-highlight",
                          h4("Direct Relevance on Large Scale AI Products"),
                          tags$ul(
                            tags$li(HTML("<strong>LLM Architectures:</strong> Built complex LLM systems for real-time geographical applications")),
                            tags$li(HTML("<strong>Enterprise Production:</strong> Deployed systems for UK Government - high regulation, high stakes")),
                            tags$li(HTML("<strong>Digital Twin Infrastructure:</strong> Advanced real-time processing systems with AI integration")),
                            tags$li(HTML("<strong>Business Strategy:</strong> Worked with VCs on business plans - understanding commercial viability"))
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("atera_ai_systems"),
                valueBoxOutput("atera_government_awards"),
                valueBoxOutput("atera_business_impact")
              ),
              
              fluidRow(
                box(
                  title = "Key Technical Achievements", status = "success", solidHeader = TRUE,
                  width = 8,
                  div(class = "achievement-box",
                      h4("Advanced Digital Twins & LLM Integration"),
                      p(HTML("<strong>Technical Challenge:</strong> Real-time Geographical Information Systems with AI processing")),
                      p(HTML("<strong>Solution:</strong> Built fault-tolerant architecture processing geographic data with LLM-enhanced analysis")),
                      p(HTML("<strong>Scale:</strong> Real-time processing with government-level reliability requirements"))
                  ),
                  div(class = "achievement-box",
                      h4("AI & Blockchain Optimization Solutions"),
                      p(HTML("<strong>Business Impact:</strong> Complex profit optimization scenarios for leading UK clients")),
                      p(HTML("<strong>Technical Innovation:</strong> Hybrid AI/blockchain systems for optimization problems")),
                      p(HTML("<strong>Client Validation:</strong> Deployed solutions with measurable business outcomes"))
                  )
                ),
                box(
                  title = "Recognition & Validation", status = "warning", solidHeader = TRUE,
                  width = 4,
                  div(class = "achievement-box",
                      h4("UK Government Awards"),
                      div(class = "metric-highlight", "Ethical AI Usage"),
                      div(class = "metric-highlight", "Innovation Excellence"),
                      br(), br(),
                      p(HTML("<strong>Significance:</strong> Government recognition validates ability to build AI systems meeting regulatory and ethical standards"))
                  ),
                  div(class = "achievement-box",
                      h4("Venture Capital Collaboration"),
                      p("Developed business plans with leading VC firms - demonstrates understanding of commercial viability and market positioning")
                  )
                )
              )
      ),
      
      # Santander Tab
      tabItem(tabName = "santander",
              fluidRow(
                box(
                  title = "Santander Bank - Head of Digital Transformation AI & Data Science (2019-2023)", status = "primary", solidHeader = TRUE,
                  width = 12,
                  div(class = "executive-summary-box",
                      div(class = "executive-title", "Enterprise AI at Global Scale"),
                      div(class = "role-description", 
                          "Led AI transformation at one of the world's largest banks by market capitalization. 
                          Managed 50+ staff across UK, Europe, and Americas. Delivered production AI systems serving 30M+ customers."),
                      br(),
                      div(class = "leadership-highlight",
                          h4("Strong focus large LLM and AI projects deployment"),
                          tags$ul(
                            tags$li(HTML("<strong>Team Scale:</strong> Managed 50+ engineers - exceeds 20-30 person requirement")),
                            tags$li(HTML("<strong>Enterprise Production:</strong> LLM AI systems serving 30M customers in regulated environment")),
                            tags$li(HTML("<strong>Multi-Region:</strong> Led teams across UK, Europe, Americas - global orchestration experience")),
                            tags$li(HTML("<strong>High-Stakes Environment:</strong> Financial services - ultimate in regulatory compliance")),
                            tags$li(HTML("<strong>Business Impact:</strong> Generated £20M through AI initiatives"))
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("santander_team_size"),
                valueBoxOutput("santander_revenue_impact"),
                valueBoxOutput("santander_customer_scale")
              ),
              
              fluidRow(
                box(
                  title = "Large Team Leadership - Multi-Region Coordination", status = "primary", solidHeader = TRUE,
                  width = 6,
                  div(class = "achievement-box",
                      div(class = "team-size", "50+ Staff Managed"),
                      h4("Distributed Team Management"),
                      p(HTML("<strong>Geographic Span:</strong> UK, Europe, Americas")),
                      p(HTML("<strong>Disciplines:</strong> Data Science, AI Engineering, Backend Systems")),
                      p(HTML("<strong>Coordination:</strong> Cross-timezone collaboration and project delivery")),
                      br(),
                      h4("Technical Leadership Approach"),
                      p(HTML("<strong>Strategic Direction:</strong> Defined AI strategy across multiple product lines")),
                      p(HTML("<strong>Technical Decisions:</strong> Architecture choices for enterprise-scale systems")),
                      p(HTML("<strong>Performance Management:</strong> C-Level reporting on critical decision making"))
                  )
                ),
                box(
                  title = "Production AI Systems at Enterprise Scale", status = "success", solidHeader = TRUE,
                  width = 6,
                  div(class = "achievement-box",
                      h4("AI-Powered Investment Hub"),
                      p(HTML("<strong>Scale:</strong> 30 million customer behavioral analysis")),
                      p(HTML("<strong>Real-time Processing:</strong> Investment recommendations and behavioral insights")),
                      p(HTML("<strong>Enterprise Integration:</strong> Across payments, mortgages, lending, credit cards"))
                  ),
                  div(class = "achievement-box",
                      h4("Mortgage Strategy AI System"),
                      p(HTML("<strong>Technical Challenge:</strong> Real estate valuation with socio-demographic analysis")),
                      p(HTML("<strong>Business Impact:</strong> Strategic decision-making for mortgage products")),
                      p(HTML("<strong>Stakeholder Management:</strong> Direct C-Level reporting"))
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Revenue Generation Through AI Innovation", status = "warning", solidHeader = TRUE,
                  width = 12,
                  withSpinner(plotlyOutput("santander_impact_chart"), color = "#667eea")
                )
              )
      ),
      
      # Caltex Tab
      tabItem(tabName = "caltex",
              fluidRow(
                box(
                  title = "Caltex-Ampol - Lead Data Science & Actionable Insights Manager (2017-2019)", status = "primary", solidHeader = TRUE,
                  width = 12,
                  div(class = "executive-summary-box",
                      div(class = "executive-title", "AI Systems for Physical Infrastructure"),
                      div(class = "role-description", 
                          "Led AI initiatives at major oil & gas distribution company operating 2000+ centres across Asia Pacific. 
                          Delivered $20M revenue increase through energy trading AI systems."),
                      br(),
                      div(class = "leadership-highlight",
                          h4("Infrastructure Scale & Team Leadership"),
                          tags$ul(
                            tags$li(HTML("<strong>Physical Scale:</strong> AI systems optimizing 2000+ distribution centers")),
                            tags$li(HTML("<strong>Revenue Impact:</strong> $20M increase through AI-driven energy trading")),
                            tags$li(HTML("<strong>Large Team Management:</strong> Led teams for C-level stakeholder projects")),
                            tags$li(HTML("<strong>Real-time Systems:</strong> Energy trading requires millisecond decision-making"))
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("caltex_revenue_impact"),
                valueBoxOutput("caltex_distribution_centers"),
                valueBoxOutput("caltex_region_span")
              ),
              
              fluidRow(
                box(
                  title = "AI-Driven Energy Trading Systems", status = "success", solidHeader = TRUE,
                  width = 8,
                  div(class = "achievement-box",
                      h4("Commercial AI Projects - $20M Revenue Impact"),
                      p(HTML("<strong>Technical Challenge:</strong> Real-time energy trading optimization across APAC markets")),
                      p(HTML("<strong>System Requirements:</strong> Low-latency, high-reliability AI inference for trading decisions")),
                      p(HTML("<strong>Business Validation:</strong> Measurable $20M revenue increase demonstrates production success")),
                      br(),
                      h4("Infrastructure Optimization at Scale"),
                      p(HTML("<strong>Physical Infrastructure:</strong> 2000+ distribution and retail centers across APAC")),
                      p(HTML("<strong>Optimization Scope:</strong> Supply chain, inventory, pricing, and operational efficiency")),
                      p(HTML("<strong>Stakeholder Management:</strong> Senior C-level reporting with P&L accountability"))
                  )
                ),
                box(
                  title = "Leadership & Business Impact", status = "warning", solidHeader = TRUE,
                  width = 4,
                  div(class = "achievement-box",
                      h4("Team Leadership"),
                      p(HTML("<strong>Large Teams:</strong> Managed multidisciplinary teams for enterprise projects")),
                      p(HTML("<strong>C-Level Reporting:</strong> Direct accountability to senior stakeholders")),
                      p(HTML("<strong>Focus Areas:</strong> Loyalty systems and P&L optimization"))
                  ),
                  div(class = "metric-highlight", "$20M Revenue"),
                  div(class = "metric-highlight", "2000+ Centers"),
                  div(class = "metric-highlight", "APAC Scale")
                )
              )
      ),
      
      # BCG Tab
      tabItem(tabName = "bcg",
              fluidRow(
                box(
                  title = "Boston Consulting Group - Lead Data Scientist Consultant (2015-2017)", status = "primary", solidHeader = TRUE,
                  width = 12,
                  div(class = "executive-summary-box",
                      div(class = "executive-title", "Strategic AI Implementation Across Industries"),
                      div(class = "role-description", 
                          "Led analytical strategies for Fortune 500 companies across Banking, Finance, Private Equity, and Energy sectors. 
                          Delivered 10x performance improvements and £15M in measurable value."),
                      br(),
                      div(class = "leadership-highlight",
                          h4("Distributed Team Leadership & Strategic Impact"),
                          tags$ul(
                            tags$li(HTML("<strong>Global Team Coordination:</strong> Led 4 multidisciplinary teams across East Asia, Europe, Americas")),
                            tags$li(HTML("<strong>Fortune 500 Scale:</strong> Delivered 10x performance improvements for major enterprises")),
                            tags$li(HTML("<strong>Executive Training:</strong> Trained senior executives and partners in AI implementation")),
                            tags$li(HTML("<strong>Multi-Sector Expertise:</strong> Banking, Finance, Private Equity, Energy - diverse technical challenges"))
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("bcg_value_delivered"),
                valueBoxOutput("bcg_team_coordination"),
                valueBoxOutput("bcg_performance_improvement")
              ),
              
              fluidRow(
                box(
                  title = "Strategic AI Implementation Expertise", status = "success", solidHeader = TRUE,
                  width = 8,
                  div(class = "achievement-box",
                      h4("Fortune 500 Performance Transformations"),
                      p(HTML("<strong>Scale of Impact:</strong> 10x performance improvements across multiple companies")),
                      p(HTML("<strong>Value Creation:</strong> £15M in measurable analytical strategy value")),
                      p(HTML("<strong>Sector Diversity:</strong> Banking, Finance, Private Equity, Energy - demonstrates adaptability"))
                  ),
                  div(class = "achievement-box",
                      h4("Global Team Leadership Experience"),
                      p(HTML("<strong>Geographic Distribution:</strong> East Asia, Europe, Americas")),
                      p(HTML("<strong>Team Structure:</strong> 4 multidisciplinary teams with cross-cultural coordination")),
                      p(HTML("<strong>Stakeholder Management:</strong> Direct interface with Fortune 500 C-level executives"))
                  )
                ),
                box(
                  title = "Leadership Development", status = "warning", solidHeader = TRUE,
                  width = 4,
                  div(class = "achievement-box",
                      h4("Executive Training"),
                      p(HTML("<strong>Audience:</strong> Senior executives and partners")),
                      p(HTML("<strong>Focus:</strong> AI implementation strategies")),
                      p(HTML("<strong>Impact:</strong> Enabled AI adoption at board level"))
                  ),
                  div(class = "metric-highlight", "10x Performance"),
                  div(class = "metric-highlight", "£15M Value"),
                  div(class = "metric-highlight", "4 Teams Led")
                )
              )
      ),
      
      # Rio Tinto Tab
      tabItem(tabName = "rio",
              fluidRow(
                box(
                  title = "Rio Tinto - Project Leader & Research Manager (2009-2015)", status = "primary", solidHeader = TRUE,
                  width = 12,
                  div(class = "executive-summary-box",
                      div(class = "executive-title", "Foundation in Large-Scale Operations & Research Leadership"),
                      div(class = "role-description", 
                          "6-year tenure at one of the world's two largest mining organizations. 
                          Led transformational projects in operations optimization and supply chain management."),
                      br(),
                      div(class = "leadership-highlight",
                          h4("Research-to-Production Pipeline Experience"),
                          tags$ul(
                            tags$li(HTML("<strong>Transformational Projects:</strong> Mining innovation and operations forecasting")),
                            tags$li(HTML("<strong>Research Excellence:</strong> Published in leading journals, received awards")),
                            tags$li(HTML("<strong>Scale Understanding:</strong> Operations at global mining scale")),
                            tags$li(HTML("<strong>Foundation Building:</strong> Early leadership and project management experience"))
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("rio_tenure_years"),
                valueBoxOutput("rio_publications"),
                valueBoxOutput("rio_project_scale")
              ),
              
              fluidRow(
                box(
                  title = "Research & Innovation Leadership", status = "success", solidHeader = TRUE,
                  width = 8,
                  div(class = "achievement-box",
                      h4("Transformational Project Delivery"),
                      p(HTML("<strong>Focus Areas:</strong> Mining Innovation, Operations Forecasting, Supply Chain Optimization")),
                      p(HTML("<strong>Scale:</strong> Global mining operations - massive data processing and optimization challenges")),
                      p(HTML("<strong>Innovation Approach:</strong> Research-based solutions to operational problems"))
                  ),
                  div(class = "achievement-box",
                      h4("Research Excellence & Recognition"),
                      p(HTML("<strong>Publications:</strong> Leading journals and conferences in China and USA")),
                      p(HTML("<strong>Awards:</strong> Recognition for project deliveries and research contributions")),
                      p(HTML("<strong>Research-to-Practice:</strong> Translating research into operational improvements"))
                  )
                ),
                box(
                  title = "Foundation Experience", status = "info", solidHeader = TRUE,
                  width = 4,
                  div(class = "achievement-box",
                      h4("Early Leadership Development"),
                      p(HTML("<strong>Role Progression:</strong> Project Leader to Research Manager")),
                      p(HTML("<strong>Duration:</strong> 6 years of progressive responsibility")),
                      p(HTML("<strong>Foundation:</strong> Large-scale operations and team leadership"))
                  ),
                  div(class = "metric-highlight", "6 Years Tenure"),
                  div(class = "metric-highlight", "Research Manager"),
                  div(class = "metric-highlight", "Global Scale")
                )
              )
      ),
      
      # Analytics Tab
      tabItem(tabName = "analytics",
              fluidRow(
                box(
                  title = "Leadership Analytics - Why This Candidate Exceeds Requirements", status = "primary", solidHeader = TRUE,
                  width = 12,
                  div(class = "executive-summary-box",
                      div(class = "executive-title", "Quantified Leadership Excellence"),
                      div(class = "role-description", 
                          "Comprehensive analysis demonstrating how this candidate's experience directly addresses and exceeds 
                          the technical leadership requirements for Senior Director AI Platform Engineering."),
                      br(),
                      div(class = "leadership-highlight",
                          h4("Key Requirement Mapping"),
                          tags$ul(
                            tags$li(HTML("<strong>Team Size:</strong> Requirement 20-30 engineers → <span class='team-size'>Delivered: 50+ engineers</span>")),
                            tags$li(HTML("<strong>Production Systems:</strong> Requirement: Enterprise LLM deployment → Delivered: 30M+ customer systems")),
                            tags$li(HTML("<strong>Technical Background:</strong> Requirement: Deep AI platform engineering → Delivered: 15+ years progression")),
                            tags$li(HTML("<strong>Global Scale:</strong> Requirement: Multi-region deployment → Delivered: UK, Europe, Americas coordination"))
                          )
                      )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("total_team_members_led"),
                valueBoxOutput("total_revenue_generated"),
                valueBoxOutput("years_ai_leadership")
              ),
              
              fluidRow(
                box(
                  title = "Team Leadership Progression Over Time", status = "primary", solidHeader = TRUE,
                  width = 8,
                  withSpinner(plotlyOutput("leadership_progression_chart"), color = "#667eea")
                ),
                box(
                  title = "Revenue Impact Analysis", status = "success", solidHeader = TRUE,
                  width = 4,
                  div(class = "achievement-box",
                      h4("Quantified Business Impact"),
                      div(class = "metric-highlight", "£20M - Santander"),
                      div(class = "metric-highlight", "$20M - Caltex"),
                      div(class = "metric-highlight", "£15M - BCG"),
                      br(),
                      p(HTML("<strong>Total Documented Impact:</strong> £55M+ USD equivalent")),
                      p(HTML("<strong>Consistency:</strong> Every role delivered measurable business value")),
                      p(HTML("<strong>Scale Progression:</strong> Increasing impact with seniority"))
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Technical Leadership Competency Matrix", status = "warning", solidHeader = TRUE,
                  width = 12,
                  withSpinner(plotlyOutput("competency_matrix_chart"), color = "#667eea")
                )
              ),
              
              fluidRow(
                box(
                  title = "Why This Candidate is the Perfect Fit", status = "success", solidHeader = TRUE,
                  width = 12,
                  div(class = "leadership-highlight",
                      h4("Requirement vs Reality Comparison"),
                      tags$div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 30px;",
                               tags$div(
                                 h4("Job Requirements"),
                                 tags$ul(
                                   tags$li("20-30 person engineering team"),
                                   tags$li("LLM pipelines in production"),
                                   tags$li("Enterprise-scale deployment"),
                                   tags$li("Multi-region orchestration"),
                                   tags$li("Python/Rust technical judgment"),
                                   tags$li("Fault-tolerant architectures"),
                                   tags$li("Product-first organization experience"),
                                   tags$li("High-regulation environments")
                                 )
                               ),
                               tags$div(
                                 h4("Candidate Delivers"),
                                 tags$ul(
                                   tags$li(HTML("<strong>50+ engineers managed</strong> - Exceeds requirement by 67%")),
                                   tags$li(HTML("<strong>LLM systems built</strong> - Real-time geographic AI processing")),
                                   tags$li(HTML("<strong>30M+ customer systems</strong> - Ultimate enterprise scale")),
                                   tags$li(HTML("<strong>UK/Europe/Americas</strong> - Global team coordination proven")),
                                   tags$li(HTML("<strong>Python/ML expertise</strong> - Deep technical foundation with strategic judgment")),
                                   tags$li(HTML("<strong>Financial services architecture</strong> - Fault-tolerant systems at banking scale")),
                                   tags$li(HTML("<strong>Santander/Caltex/Atera</strong> - Product companies, not consulting")),
                                   tags$li(HTML("<strong>Banking/Government</strong> - Highest possible regulatory environments"))
                                 )
                               )
                      )
                  )
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Education Tab Value Boxes
  output$total_experience <- renderValueBox({
    valueBox(
      value = "15+ Years",
      subtitle = "AI & Technical Leadership",
      icon = icon("clock"),
      color = "blue"
    )
  })
  
  output$team_leadership_scale <- renderValueBox({
    valueBox(
      value = "50+ Engineers",
      subtitle = "Peak Team Size Managed",
      icon = icon("users"),
      color = "green"
    )
  })
  
  output$ai_systems_built <- renderValueBox({
    valueBox(
      value = "6+ Systems",
      subtitle = "Production AI Platforms",
      icon = icon("robot"),
      color = "purple"
    )
  })
  
  # Career progression chart
  output$career_progression_plot <- renderPlotly({
    career_data <- data.frame(
      year = c(2009, 2015, 2017, 2019, 2023, 2025),
      position = c("Project Leader", "Research Manager", "Lead Data Scientist", 
                   "Lead Manager", "Head of AI", "Director"),
      company = c("Rio Tinto", "Rio Tinto", "BCG", "Caltex", "Santander", "Atera"),
      team_size = c(5, 15, 20, 25, 50, 30),
      seniority_level = c(1, 2, 3, 4, 5, 6)
    )
    
    p <- plot_ly(career_data, 
                 x = ~year, 
                 y = ~seniority_level,
                 size = ~team_size,
                 color = ~company,
                 text = ~paste('<b>', position, '</b><br>',
                               company, '<br>',
                               'Team Size:', team_size),
                 type = 'scatter',
                 mode = 'markers+lines',
                 line = list(width = 4, color = '#667eea'),
                 marker = list(
                   sizemode = 'diameter',
                   sizeref = max(career_data$team_size) / 200,
                   opacity = 0.8,
                   line = list(width = 3, color = 'white')
                 ),
                 colors = c('#667eea', '#764ba2', '#5e72e4', '#7c4dff', '#9c27b0', '#e91e63'),
                 hovertemplate = '%{text}<extra></extra>'
    ) %>%
      layout(
        title = list(text = "Career Progression & Team Leadership Scale", font = list(size = 16)),
        xaxis = list(title = "Year", titlefont = list(size = 14)),
        yaxis = list(title = "Seniority Level", titlefont = list(size = 14),
                     ticktext = c("Project Leader", "Research Manager", "Lead Consultant", 
                                  "Lead Manager", "Head/Director", "Senior Director"),
                     tickvals = c(1, 2, 3, 4, 5, 6)),
        plot_bgcolor = 'rgba(255,255,255,1)',
        paper_bgcolor = 'rgba(255,255,255,1)'
      )
    p
  })
  
  # Atera Analytics Value Boxes
  output$atera_ai_systems <- renderValueBox({
    valueBox(
      value = "Digital Twins",
      subtitle = "Advanced LLM Systems Built",
      icon = icon("brain"),
      color = "blue"
    )
  })
  
  output$atera_government_awards <- renderValueBox({
    valueBox(
      value = "Multiple",
      subtitle = "UK Government Awards",
      icon = icon("award"),
      color = "green"
    )
  })
  
  output$atera_business_impact <- renderValueBox({
    valueBox(
      value = "High Regulation",
      subtitle = "Government-Level Compliance",
      icon = icon("shield-alt"),
      color = "purple"
    )
  })
  
  # Santander Value Boxes
  output$santander_team_size <- renderValueBox({
    valueBox(
      value = "50+",
      subtitle = "Staff Managed Globally",
      icon = icon("users"),
      color = "blue"
    )
  })
  
  output$santander_revenue_impact <- renderValueBox({
    valueBox(
      value = "£20M",
      subtitle = "Revenue Generated",
      icon = icon("pound-sign"),
      color = "green"
    )
  })
  
  output$santander_customer_scale <- renderValueBox({
    valueBox(
      value = "30M+",
      subtitle = "Customers Served by AI",
      icon = icon("user-friends"),
      color = "purple"
    )
  })
  
  # Santander impact chart
  output$santander_impact_chart <- renderPlotly({
    products <- c("Payments", "Mortgages", "Lending", "Credit Cards", "Investment Hub")
    impact <- c(4.5, 6.2, 3.8, 2.7, 2.8)
    
    p <- plot_ly(
      x = products,
      y = impact,
      type = 'bar',
      marker = list(
        color = c('#667eea', '#764ba2', '#5e72e4', '#7c4dff', '#9c27b0'),
        line = list(color = 'white', width = 2)
      ),
      text = paste("£", impact, "M"),
      textposition = 'outside'
    ) %>%
      layout(
        title = list(text = "Revenue Impact by Product Line (£M)", font = list(size = 16)),
        xaxis = list(title = "Product Lines", titlefont = list(size = 14)),
        yaxis = list(title = "Revenue Impact (£M)", titlefont = list(size = 14)),
        plot_bgcolor = 'rgba(255,255,255,1)',
        paper_bgcolor = 'rgba(255,255,255,1)'
      )
    p
  })
  
  # Caltex Value Boxes
  output$caltex_revenue_impact <- renderValueBox({
    valueBox(
      value = "$20M",
      subtitle = "Revenue Increase Delivered",
      icon = icon("chart-line"),
      color = "blue"
    )
  })
  
  output$caltex_distribution_centers <- renderValueBox({
    valueBox(
      value = "2000+",
      subtitle = "Distribution Centers Optimized",
      icon = icon("warehouse"),
      color = "green"
    )
  })
  
  output$caltex_region_span <- renderValueBox({
    valueBox(
      value = "APAC",
      subtitle = "Regional Scale Coverage",
      icon = icon("globe-asia"),
      color = "purple"
    )
  })
  
  # BCG Value Boxes
  output$bcg_value_delivered <- renderValueBox({
    valueBox(
      value = "£15M",
      subtitle = "Analytical Strategy Value",
      icon = icon("pound-sign"),
      color = "blue"
    )
  })
  
  output$bcg_team_coordination <- renderValueBox({
    valueBox(
      value = "4 Teams",
      subtitle = "Multidisciplinary Teams Led",
      icon = icon("users-cog"),
      color = "green"
    )
  })
  
  output$bcg_performance_improvement <- renderValueBox({
    valueBox(
      value = "10x",
      subtitle = "Performance Improvements",
      icon = icon("rocket"),
      color = "purple"
    )
  })
  
  # Rio Tinto Value Boxes
  output$rio_tenure_years <- renderValueBox({
    valueBox(
      value = "6 Years",
      subtitle = "Progressive Leadership Tenure",
      icon = icon("calendar"),
      color = "blue"
    )
  })
  
  output$rio_publications <- renderValueBox({
    valueBox(
      value = "Multiple",
      subtitle = "Research Publications",
      icon = icon("book"),
      color = "green"
    )
  })
  
  output$rio_project_scale <- renderValueBox({
    valueBox(
      value = "Global",
      subtitle = "Mining Operations Scale",
      icon = icon("globe"),
      color = "purple"
    )
  })
  
  # Analytics Tab Value Boxes
  output$total_team_members_led <- renderValueBox({
    valueBox(
      value = "100+",
      subtitle = "Total Engineers Led (Career)",
      icon = icon("users"),
      color = "blue"
    )
  })
  
  output$total_revenue_generated <- renderValueBox({
    valueBox(
      value = "£55M+",
      subtitle = "Total Documented Impact",
      icon = icon("chart-line"),
      color = "green"
    )
  })
  
  output$years_ai_leadership <- renderValueBox({
    valueBox(
      value = "10+ Years",
      subtitle = "AI Leadership Experience",
      icon = icon("brain"),
      color = "purple"
    )
  })
  
  # Leadership progression chart
  output$leadership_progression_chart <- renderPlotly({
    leadership_data <- data.frame(
      role = c("Rio Tinto", "BCG", "Caltex", "Santander", "Atera"),
      team_size = c(15, 20, 25, 50, 30),
      years = c("2009-2015", "2015-2017", "2017-2019", "2019-2023", "2023-2025"),
      revenue_impact = c(0, 15, 20, 20, 0) # in millions
    )
    
    p <- plot_ly(leadership_data, 
                 x = ~role, 
                 y = ~team_size,
                 type = 'scatter',
                 mode = 'markers+lines',
                 line = list(width = 4, color = '#667eea'),
                 marker = list(size = 15, color = '#764ba2', 
                               line = list(width = 3, color = 'white')),
                 text = ~paste('<b>', role, '</b><br>',
                               'Period:', years, '<br>',
                               'Team Size:', team_size, '<br>',
                               'Revenue Impact: £/$ ', revenue_impact, 'M'),
                 hovertemplate = '%{text}<extra></extra>'
    ) %>%
      layout(
        title = list(text = "Team Leadership Scale Progression", font = list(size = 16)),
        xaxis = list(title = "Company/Role", titlefont = list(size = 14)),
        yaxis = list(title = "Team Size (Engineers)", titlefont = list(size = 14)),
        plot_bgcolor = 'rgba(255,255,255,1)',
        paper_bgcolor = 'rgba(255,255,255,1)'
      )
    p
  })
  
  # Competency matrix chart
  output$competency_matrix_chart <- renderPlotly({
    competencies <- data.frame(
      skill = c("Team Leadership", "AI/ML Systems", "Enterprise Scale", "Production Deployment", 
                "Multi-Region Mgmt", "Technical Architecture", "Business Impact", "Regulatory Compliance"),
      requirement_level = c(8, 9, 8, 9, 7, 9, 7, 8),
      candidate_level = c(10, 9, 10, 10, 9, 9, 10, 10)
    )
    
    p <- plot_ly(competencies, 
                 x = ~skill, 
                 y = ~requirement_level,
                 type = 'bar',
                 name = 'Job Requirement',
                 marker = list(color = '#e2e8f0')) %>%
      add_trace(y = ~candidate_level, 
                name = 'Candidate Level',
                marker = list(color = '#667eea')) %>%
      layout(
        title = list(text = "Technical Leadership Competency Comparison", font = list(size = 16)),
        xaxis = list(title = "Core Competencies", titlefont = list(size = 14), 
                     tickangle = -45),
        yaxis = list(title = "Proficiency Level (1-10)", titlefont = list(size = 14)),
        plot_bgcolor = 'rgba(255,255,255,1)',
        paper_bgcolor = 'rgba(255,255,255,1)',
        barmode = 'group'
      )
    p
  })
}

# Run the application
shinyApp(ui = ui, server = server)