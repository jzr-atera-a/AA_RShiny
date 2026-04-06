# modules/overview.R — Overview and Introduction

overview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "chapter-hero",
        div(class = "hero-chapter-num", "Packt Publishing · Second Edition · 2020"),
        tags$h1(class = "hero-title", "📚 Machine Learning for Algorithmic Trading"),
        tags$p(class = "hero-subtitle",
               "An interactive learning platform for Stefan Jansen's comprehensive guide to building ",
               "profitable trading strategies using machine learning, alternative data, and modern ",
               "portfolio optimization techniques."),
        div(class = "badge-row",
            span(class = "hero-badge", "25 Chapters"),
            span(class = "hero-badge", "Python 3"),
            span(class = "hero-badge", "ML & Deep Learning"),
            span(class = "hero-badge", "Backtesting"),
            span(class = "hero-badge", "Alternative Data")
        )
    ),

    fluidRow(
      box(title = "📖 About This Learning Platform", status = "info", solidHeader = TRUE, width = 6,
          div(class = "framework-card",
              tags$h5("Interactive Companion"),
              tags$p("This R Shiny application serves as an interactive companion to Stefan Jansen's",
                     tags$em("Machine Learning for Algorithmic Trading (Second Edition)"),
                     ". Each chapter contains:"),
              tags$ul(
                tags$li(tags$strong("Theory & Concepts tab"), " — Core ideas, frameworks, and detailed explanations with visualizations"),
                tags$li(tags$strong("Python Code tab"), " — Code examples and implementations (coming soon)")
              )
          ),
          div(class = "tip-box",
              HTML("<strong>💡 Current Status:</strong> First 3 chapters are implemented with comprehensive theory and interactive visualizations. Python code execution will be added in future updates.")
          )
      ),
      
      box(title = "🎯 What You'll Learn", status = "success", solidHeader = TRUE, width = 6,
          framework_card(
              "Complete ML Trading Workflow",
              tags$ul(
                tags$li("Source and process market, fundamental, and alternative data"),
                tags$li("Engineer alpha factors using traditional and ML techniques"),
                tags$li("Build supervised, unsupervised, and reinforcement learning models"),
                tags$li("Optimize portfolios using modern and classical approaches"),
                tags$li("Backtest strategies with realistic assumptions"),
                tags$li("Deploy and monitor models in production")
              )
          )
      )
    ),
    
    fluidRow(
      box(title = "📚 Book Structure - 7 Parts, 25 Chapters", status = "warning", solidHeader = TRUE, width = 12,
          tags$div(class = "framework-card",
            tags$h5("Part 1: From Data to Strategy (Chapters 1-5)"),
            tags$p(tags$strong("Status: ✅ Chapters 1-3 Implemented")),
            tags$ul(
              tags$li(tags$strong("Ch 1:"), " Machine Learning for Trading — From Idea to Execution"),
              tags$li(tags$strong("Ch 2:"), " Market and Fundamental Data — Sources and Techniques"),
              tags$li(tags$strong("Ch 3:"), " Alternative Data for Finance — Categories and Use Cases"),
              tags$li(tags$strong("Ch 4:"), " Financial Feature Engineering — How to Research Alpha Factors"),
              tags$li(tags$strong("Ch 5:"), " Portfolio Optimization and Performance Evaluation")
            )
          ),
          
          tags$div(class = "framework-card",
            tags$h5("Part 2: Machine Learning Fundamentals (Chapters 6-7)"),
            tags$p(tags$strong("Status: ⬜ Coming Soon")),
            tags$ul(
              tags$li(tags$strong("Ch 6:"), " The Machine Learning Process"),
              tags$li(tags$strong("Ch 7:"), " Linear Models — From Risk Factors to Return Forecasts")
            )
          ),
          
          tags$div(class = "framework-card",
            tags$h5("Part 3: Tree-Based Models (Chapters 8-9)"),
            tags$p(tags$strong("Status: ⬜ Coming Soon")),
            tags$ul(
              tags$li(tags$strong("Ch 8:"), " The ML4T Workflow — From Model to Strategy Backtesting"),
              tags$li(tags$strong("Ch 9:"), " Boosting Your Trading Strategy")
            )
          ),
          
          tags$div(class = "framework-card",
            tags$h5("Part 4: Natural Language Processing (Chapters 10-11)"),
            tags$p(tags$strong("Status: ⬜ Coming Soon")),
            tags$ul(
              tags$li(tags$strong("Ch 10:"), " Volatility Forecasts and Statistical Arbitrage"),
              tags$li(tags$strong("Ch 11:"), " Text Data for Trading — Sentiment Analysis")
            )
          ),
          
          tags$div(class = "framework-card",
            tags$h5("Part 5: Deep Learning (Chapters 12-16)"),
            tags$p(tags$strong("Status: ⬜ Coming Soon")),
            tags$ul(
              tags$li(tags$strong("Ch 12:"), " Deep Learning for Trading"),
              tags$li(tags$strong("Ch 13:"), " Data-Driven Risk Factors and Asset Pricing with Unsupervised Learning"),
              tags$li(tags$strong("Ch 14:"), " Text Data for Trading — Topic Modeling"),
              tags$li(tags$strong("Ch 15:"), " Word Embeddings for Earnings Calls and SEC Filings"),
              tags$li(tags$strong("Ch 16:"), " Deep Learning for Trading")
            )
          ),
          
          tags$div(class = "framework-card",
            tags$h5("Part 6: Reinforcement Learning (Chapters 17-18)"),
            tags$p(tags$strong("Status: ⬜ Coming Soon")),
            tags$ul(
              tags$li(tags$strong("Ch 17:"), " Deep Reinforcement Learning"),
              tags$li(tags$strong("Ch 18:"), " Convolutional Neural Networks")
            )
          ),
          
          tags$div(class = "framework-card",
            tags$h5("Part 7: Advanced Topics (Chapters 19-25)"),
            tags$p(tags$strong("Status: ⬜ Coming Soon")),
            tags$ul(
              tags$li(tags$strong("Ch 19-25:"), " RNNs, Autoencoders, GANs, Meta-Labeling, and ML Strategy Workflow")
            )
          )
      )
    ),
    
    fluidRow(
      box(title = "🔧 Technologies & Tools", status = "info", solidHeader = TRUE, width = 6,
          framework_card(
              "Python Ecosystem",
              tags$ul(
                tags$li(tags$strong("Data:"), " pandas, NumPy, yfinance, pandas-datareader, Quandl"),
                tags$li(tags$strong("ML:"), " scikit-learn, LightGBM, XGBoost, CatBoost"),
                tags$li(tags$strong("DL:"), " TensorFlow, Keras, PyTorch"),
                tags$li(tags$strong("NLP:"), " NLTK, spaCy, gensim, transformers"),
                tags$li(tags$strong("Backtesting:"), " Zipline, backtrader, pyfolio, Alphalens"),
                tags$li(tags$strong("Visualization:"), " matplotlib, seaborn, plotly")
              )
          )
      ),
      
      box(title = "👨‍💼 About the Author", status = "success", solidHeader = TRUE, width = 6,
          framework_card(
              "Stefan Jansen",
              tagList(
                tags$p(tags$strong("Stefan Jansen"), " is a data scientist, investment professional, and educator with extensive experience in algorithmic trading and machine learning for finance."),
                tags$p("He has worked across London, New York, and San Francisco in roles spanning quantitative research, portfolio management, and ML strategy development."),
                tags$p("Stefan holds advanced degrees in economics and computer science and actively contributes to the ML for finance community through writing, speaking, and open-source projects.")
              )
          )
      )
    ),
    
    fluidRow(
      box(title = "🚀 Getting Started", status = "warning", solidHeader = TRUE, width = 6,
          framework_card(
              "Navigation",
              tags$ol(
                tags$li(tags$strong("Use the sidebar"), " to navigate between chapters"),
                tags$li(tags$strong("Each chapter has two tabs:"), " Theory & Concepts, and Python Code"),
                tags$li(tags$strong("Interactive visualizations"), " help illustrate key concepts"),
                tags$li(tags$strong("Start with Chapter 1"), " and progress sequentially for best results")
              )
          ),
          tip_box("Best Practice", "Chapters build on previous concepts. For the best learning experience, work through them in order.")
      ),
      
      box(title = "📊 Features", status = "info", solidHeader = TRUE, width = 6,
          tags$ul(
            tags$li("✅ Comprehensive theory coverage for each chapter"),
            tags$li("✅ Interactive Plotly visualizations"),
            tags$li("✅ Professional dark theme with teal/turquoise styling"),
            tags$li("✅ Modular architecture for easy extension"),
            tags$li("✅ Responsive design for different devices"),
            tags$li("⬜ Python code execution (coming soon)"),
            tags$li("⬜ Interactive coding exercises (coming soon)")
          )
      )
    ),
    
    fluidRow(
      box(title = "📈 Implementation Progress", status = "success", solidHeader = TRUE, width = 12,
          plotlyOutput(ns("progress_chart"), height = "200px"),
          tags$p(style = "text-align: center; margin-top: 15px; color: #8B949E;",
                 "3 of 25 chapters implemented (12% complete)")
      )
    )
  )
}

overview_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$progress_chart <- renderPlotly({
      data <- data.frame(
        Status = c("Implemented", "Coming Soon"),
        Chapters = c(3, 22),
        Color = c("#008A82", "#30363D")
      )
      
      plot_ly(
        data = data,
        x = ~Chapters,
        y = ~Status,
        type = "bar",
        orientation = "h",
        marker = list(
          color = ~Color,
          line = list(color = "white", width = 1.5)
        ),
        text = ~paste(Chapters, "chapters"),
        textposition = "inside",
        textfont = list(color = "white", size = 14),
        hovertemplate = "<b>%{y}</b><br>%{x} chapters<extra></extra>"
      ) %>%
        layout(
          xaxis = list(
            title = "Number of Chapters",
            color = "#8B949E",
            gridcolor = "#30363D",
            range = c(0, 25)
          ),
          yaxis = list(
            title = "",
            color = "#8B949E",
            categoryorder = "array",
            categoryarray = c("Coming Soon", "Implemented")
          ),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          showlegend = FALSE,
          margin = list(l = 100, r = 20, t = 20, b = 60)
        )
    })
    
  })
}
