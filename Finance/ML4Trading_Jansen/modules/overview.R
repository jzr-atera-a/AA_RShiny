# modules/overview.R — Book Overview

overview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "chapter-hero",
        div(class = "hero-chapter-num", "EXPERT INSIGHT"),
        tags$h1(class = "hero-title", "📈 Machine Learning for Algorithmic Trading"),
        tags$p(class = "hero-subtitle", 
               "Predictive models to extract signals from market and alternative data for systematic trading strategies with Python. This interactive guide covers the complete ML4T workflow from data sourcing to strategy backtesting."),
        div(class = "badge-row",
            span(class = "hero-badge", "Stefan Jansen"),
            span(class = "hero-badge", "Second Edition"),
            span(class = "hero-badge", "Packt Publishing")
        )
    ),

    stats_row(
      list("6", "Parts"),
      list("23", "Chapters"),
      list("Python", "Primary Language"),
      list("ML4T", "Complete Workflow")
    ),

    fluidRow(
      box(title = "📚 Part I: From Idea to Execution", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "chapter-card",
              div(class = "ch-num", "Chapter 1"),
              div(class = "ch-title", "Machine Learning for Trading: From Idea to Execution"),
              div(class = "ch-desc", "Overview of ML in investment industry, from electronic to high-frequency trading, factor investing, algorithmic pioneers, and designing ML-driven strategies."),
              div(class = "ch-tags",
                  span(class = "topic-tag", "ML Overview"),
                  span(class = "topic-tag", "Strategy Design"),
                  span(class = "topic-tag", "Alpha Factors")
              )
          ),
          div(class = "chapter-card",
              div(class = "ch-num", "Chapter 2"),
              div(class = "ch-title", "Market and Fundamental Data: Sources and Techniques"),
              div(class = "ch-desc", "Market microstructure, high-frequency data, Nasdaq order book, FIX protocol, tick-to-bar conversion, and fundamental data processing with XBRL."),
              div(class = "ch-tags",
                  span(class = "topic-tag", "Market Data"),
                  span(class = "topic-tag", "Order Book"),
                  span(class = "topic-tag", "XBRL")
              )
          ),
          div(class = "chapter-card",
              div(class = "ch-num", "Chapter 3"),
              div(class = "ch-title", "Alternative Data for Finance: Categories and Use Cases"),
              div(class = "ch-desc", "The alternative data revolution including sources from individuals, business processes, sensors, satellites, and geolocation data with web scraping techniques."),
              div(class = "ch-tags",
                  span(class = "topic-tag", "Alternative Data"),
                  span(class = "topic-tag", "Web Scraping"),
                  span(class = "topic-tag", "Selenium")
              )
          ),
          div(class = "chapter-card",
              div(class = "ch-num", "Chapter 4"),
              div(class = "ch-title", "Financial Feature Engineering: How to Research Alpha Factors"),
              div(class = "ch-desc", "Building on decades of factor research including momentum, sentiment, value, volatility, size, and quality factors with pandas, NumPy, and TA-Lib."),
              div(class = "ch-tags",
                  span(class = "topic-tag", "Alpha Factors"),
                  span(class = "topic-tag", "Feature Engineering"),
                  span(class = "topic-tag", "Alphalens")
              )
          ),
          div(class = "chapter-card",
              div(class = "ch-num", "Chapter 5"),
              div(class = "ch-title", "Portfolio Optimization and Performance Evaluation"),
              div(class = "ch-desc", "Measuring performance with Sharpe ratio, mean-variance optimization, Kelly criterion, risk parity, and backtesting with Zipline and pyfolio."),
              div(class = "ch-tags",
                  span(class = "topic-tag", "Portfolio Optimization"),
                  span(class = "topic-tag", "Sharpe Ratio"),
                  span(class = "topic-tag", "Backtesting")
              )
          )
      )
    ),

    fluidRow(
      box(title = "🎯 Key Learning Objectives", status = "info", solidHeader = TRUE, width = 6,
          tags$ul(
            tags$li(strong("ML Workflow:"), " Master the complete pipeline from data sourcing to strategy deployment"),
            tags$li(strong("Data Processing:"), " Handle market, fundamental, and alternative data sources"),
            tags$li(strong("Alpha Research:"), " Engineer and validate alpha factors using established methodologies"),
            tags$li(strong("Model Development:"), " Build predictive models using classical ML and deep learning"),
            tags$li(strong("Backtesting:"), " Properly evaluate strategies while avoiding common pitfalls"),
            tags$li(strong("Production:"), " Deploy models in real-world trading environments")
          )
      ),
      box(title = "🛠 Technologies Covered", status = "success", solidHeader = TRUE, width = 6,
          div(class = "framework-card",
              tags$h5("Data & Analysis"),
              tags$p("pandas, NumPy, TA-Lib, Alphalens, Quantopian, Zipline, Quandl, XBRL")
          ),
          div(class = "framework-card",
              tags$h5("Machine Learning"),
              tags$p("scikit-learn, TensorFlow 2, PyTorch, XGBoost, LightGBM, CatBoost")
          ),
          div(class = "framework-card",
              tags$h5("Natural Language Processing"),
              tags$p("spaCy, Gensim, word2vec, BERT, transformers")
          ),
          div(class = "framework-card",
              tags$h5("Backtesting & Evaluation"),
              tags$p("backtrader, Zipline, pyfolio, PyPortfolioOpt")
          )
      )
    ),

    fluidRow(
      box(title = "📖 How to Use This Guide", status = "warning", solidHeader = TRUE, width = 12,
          div(class = "info-box-plain",
              HTML("<strong>Structure:</strong> Each chapter contains two tabs — <strong>Concepts</strong> for theory with diagrams and <strong>Code Lab</strong> for hands-on Python examples.")
          ),
          div(class = "tip-box",
              HTML("<strong>💡 Learning Path:</strong> Chapters build progressively. Start with Part I for foundations, then explore ML techniques in later parts based on your interest.")
          ),
          div(class = "success-box",
              HTML("<strong>✅ Interactive Code:</strong> All Python examples are executable. Modify parameters and run code directly to deepen understanding.")
          )
      )
    )
  )
}

overview_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Overview has no reactive logic
  })
}
