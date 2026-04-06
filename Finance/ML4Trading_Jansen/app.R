# app.R
# Machine Learning for Algorithmic Trading — Stefan Jansen
# Interactive R Shiny Learning Platform · Part I Chapters 1–5

source("global.R", local = TRUE)

for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) {
  source(f, local = TRUE)
}

ui <- dashboardPage(
  skin = "black",

  dashboardHeader(title = "ML4Trading Lab"),

  dashboardSidebar(
    tags$div(class = "sidebar-book-badge",
             tags$div(class = "book-chip",    "MACHINE LEARNING FOR TRADING"),
             tags$div(class = "book-authors", "Stefan Jansen"),
             tags$div(class = "book-pub",     "Packt Publishing · 2nd Edition")
    ),

    sidebarMenu(
      id = "tabs",
      menuItem("📚 Overview",                          tabName = "overview", icon = icon("book")),
      
      # Part I: From Idea to Execution
      menuItem("Part I: Idea to Execution", icon = icon("rocket"),
               menuSubItem("Ch 1 · ML for Trading", tabName = "ch1",  icon = icon("chart-line")),
               menuSubItem("Ch 2 · Market Data", tabName = "ch2",  icon = icon("database")),
               menuSubItem("Ch 3 · Alternative Data", tabName = "ch3",  icon = icon("satellite")),
               menuSubItem("Ch 4 · Alpha Factors", tabName = "ch4",  icon = icon("flask")),
               menuSubItem("Ch 5 · Portfolio Optimization", tabName = "ch5",  icon = icon("balance-scale"))
      )
    )
  ),

  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
      # highlight.js for Python syntax highlighting
      tags$link(rel = "stylesheet",
                href = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css"),
      tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"),
      tags$script(HTML("
        // Re-highlight after Shiny updates
        $(document).on('shiny:value', function(e) {
          setTimeout(function() { document.querySelectorAll('pre code').forEach(el => hljs.highlightElement(el)); }, 50);
        });
        // Copy to clipboard handler
        Shiny.addCustomMessageHandler('copy_to_clipboard', function(text) {
          navigator.clipboard.writeText(text).then(function() {
            // brief visual feedback handled server-side via notification
          });
        });
      "))
    ),

    tabItems(
      tabItem(tabName = "overview", overview_ui("overview")),
      tabItem(tabName = "ch1",      chapter1_ui("ch1")),
      tabItem(tabName = "ch2",      chapter2_ui("ch2")),
      tabItem(tabName = "ch3",      chapter3_ui("ch3")),
      tabItem(tabName = "ch4",      chapter4_ui("ch4")),
      tabItem(tabName = "ch5",      chapter5_ui("ch5"))
    )
  )
)

server <- function(input, output, session) {
  overview_server("overview")
  chapter1_server("ch1")
  chapter2_server("ch2")
  chapter3_server("ch3")
  chapter4_server("ch4")
  chapter5_server("ch5")
}

shinyApp(ui, server)
