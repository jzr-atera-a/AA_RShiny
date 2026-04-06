# app.R
# Machine Learning for Algorithmic Trading — Stefan Jansen (Second Edition)
# Interactive R Shiny Learning Platform · ALL 25 CHAPTERS COMPLETE

source("global.R", local = TRUE)

# Source all module files
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) {
  source(f, local = TRUE)
}

ui <- dashboardPage(
  skin = "black",

  dashboardHeader(title = "ML Trading Lab"),

  dashboardSidebar(
    tags$div(class = "sidebar-book-badge",
             tags$div(class = "book-chip", "MACHINE LEARNING FOR TRADING"),
             tags$div(class = "book-authors", "Stefan Jansen"),
             tags$div(class = "book-pub", "Packt Publishing · Second Edition · 2020")
    ),

    sidebarMenu(
      id = "tabs",
      menuItem("📓 Jupyter Notebook Runner", tabName = "jupyter", icon = icon("file-code")),
      menuItem("📚 Overview", tabName = "overview", icon = icon("home")),
      
      # Part 1: From Data to Strategy (Ch 1-5)
      menuItem("Part 1: Data to Strategy", icon = icon("database"),
        menuSubItem("Ch 1 · ML for Trading", tabName = "ch1"),
        menuSubItem("Ch 2 · Market Data", tabName = "ch2"),
        menuSubItem("Ch 3 · Alternative Data", tabName = "ch3"),
        menuSubItem("Ch 4 · Feature Engineering", tabName = "ch4"),
        menuSubItem("Ch 5 · Portfolio Optimization", tabName = "ch5")
      ),
      
      # Part 2: ML Fundamentals (Ch 6-7)
      menuItem("Part 2: ML Fundamentals", icon = icon("robot"),
        menuSubItem("Ch 6 · ML Process", tabName = "ch6"),
        menuSubItem("Ch 7 · Linear Models", tabName = "ch7")
      ),
      
      # Part 3: Advanced Models (Ch 8-12)
      menuItem("Part 3: Advanced Models", icon = icon("tree"),
        menuSubItem("Ch 8 · ML4T Workflow", tabName = "ch8"),
        menuSubItem("Ch 9 · Time-Series Models", tabName = "ch9"),
        menuSubItem("Ch 10 · Bayesian ML", tabName = "ch10"),
        menuSubItem("Ch 11 · Random Forests", tabName = "ch11"),
        menuSubItem("Ch 12 · Boosting", tabName = "ch12")
      ),
      
      # Part 4: NLP & Deep Learning (Ch 13-17)
      menuItem("Part 4: NLP & Deep Learning", icon = icon("comment"),
        menuSubItem("Ch 13 · Unsupervised Learning", tabName = "ch13"),
        menuSubItem("Ch 14 · Sentiment Analysis", tabName = "ch14"),
        menuSubItem("Ch 15 · Topic Modeling", tabName = "ch15"),
        menuSubItem("Ch 16 · Word Embeddings", tabName = "ch16"),
        menuSubItem("Ch 17 · Deep Learning", tabName = "ch17")
      ),
      
      # Part 5: Advanced DL & RL (Ch 18-22)
      menuItem("Part 5: Advanced DL & RL", icon = icon("brain"),
        menuSubItem("Ch 18 · CNNs", tabName = "ch18"),
        menuSubItem("Ch 19 · RNNs & LSTMs", tabName = "ch19"),
        menuSubItem("Ch 20 · Autoencoders", tabName = "ch20"),
        menuSubItem("Ch 21 · GANs", tabName = "ch21"),
        menuSubItem("Ch 22 · Reinforcement Learning", tabName = "ch22")
      ),
      
      # Part 6: Production ML (Ch 23-25)
      menuItem("Part 6: Production ML", icon = icon("gears"),
        menuSubItem("Ch 23 · Interpretability", tabName = "ch23"),
        menuSubItem("Ch 24 · Meta-Labeling", tabName = "ch24"),
        menuSubItem("Ch 25 · Complete Workflow", tabName = "ch25")
      )
    )
  ),

  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
      # For future Python code highlighting
      tags$link(rel = "stylesheet",
                href = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css"),
      tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js")
    ),

    tabItems(
      # Jupyter Notebook Runner
      tabItem(tabName = "jupyter", jupyter_runner_ui("jupyter")),
      
      # Overview Tab
      tabItem(tabName = "overview", overview_ui("overview")),
      
      # Chapter Tabs
      tabItem(tabName = "ch1", chapter1_ui("ch1")),
      tabItem(tabName = "ch2", chapter2_ui("ch2")),
      tabItem(tabName = "ch3", chapter3_ui("ch3")),
      tabItem(tabName = "ch4", chapter4_ui("ch4")),
      tabItem(tabName = "ch5", chapter5_ui("ch5")),
      tabItem(tabName = "ch6", chapter6_ui("ch6")),
      tabItem(tabName = "ch7", chapter7_ui("ch7")),
      tabItem(tabName = "ch8", chapter8_ui("ch8")),
      tabItem(tabName = "ch9", chapter9_ui("ch9")),
      tabItem(tabName = "ch10", chapter10_ui("ch10")),
      tabItem(tabName = "ch11", chapter11_ui("ch11")),
      tabItem(tabName = "ch12", chapter12_ui("ch12")),
      tabItem(tabName = "ch13", chapter13_ui("ch13")),
      tabItem(tabName = "ch14", chapter14_ui("ch14")),
      tabItem(tabName = "ch15", chapter15_ui("ch15")),
      tabItem(tabName = "ch16", chapter16_ui("ch16")),
      tabItem(tabName = "ch17", chapter17_ui("ch17")),
      tabItem(tabName = "ch18", chapter18_ui("ch18")),
      tabItem(tabName = "ch19", chapter19_ui("ch19")),
      tabItem(tabName = "ch20", chapter20_ui("ch20")),
      tabItem(tabName = "ch21", chapter21_ui("ch21")),
      tabItem(tabName = "ch22", chapter22_ui("ch22")),
      tabItem(tabName = "ch23", chapter23_ui("ch23")),
      tabItem(tabName = "ch24", chapter24_ui("ch24")),
      tabItem(tabName = "ch25", chapter25_ui("ch25"))
    )
  )
)

server <- function(input, output, session) {
  # Module servers
  jupyter_runner_server("jupyter")
  overview_server("overview")
  chapter1_server("ch1")
  chapter2_server("ch2")
  chapter3_server("ch3")
  chapter4_server("ch4")
  chapter5_server("ch5")
  chapter6_server("ch6")
  chapter7_server("ch7")
  chapter8_server("ch8")
  chapter9_server("ch9")
  chapter10_server("ch10")
  chapter11_server("ch11")
  chapter12_server("ch12")
  chapter13_server("ch13")
  chapter14_server("ch14")
  chapter15_server("ch15")
  chapter16_server("ch16")
  chapter17_server("ch17")
  chapter18_server("ch18")
  chapter19_server("ch19")
  chapter20_server("ch20")
  chapter21_server("ch21")
  chapter22_server("ch22")
  chapter23_server("ch23")
  chapter24_server("ch24")
  chapter25_server("ch25")
}

shinyApp(ui, server)
