# app.R
# A Common-Sense Guide to Data Structures & Algorithms — Jay Wengrow
# Interactive R Shiny Code Lab · Chapters 1–20 (Complete)

source("global.R", local = TRUE)

for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) {
  source(f, local = TRUE)
}

ui <- dashboardPage(
  skin = "black",

  dashboardHeader(title = "DSA Code Lab"),

  dashboardSidebar(
    tags$div(class = "sidebar-book-badge",
             tags$div(class = "book-chip",    "A COMMON-SENSE GUIDE TO DSA"),
             tags$div(class = "book-authors", "Jay Wengrow"),
             tags$div(class = "book-pub",     "Manning Publications · 2nd Edition")
    ),

    sidebarMenu(
      id = "tabs",
      menuItem("📚 Overview",                         tabName = "overview", icon = icon("book")),
      menuItem("Ch 1 · Why Data Structures Matter",   tabName = "ch1",  icon = icon("database")),
      menuItem("Ch 2 · Why Algorithms Matter",        tabName = "ch2",  icon = icon("search")),
      menuItem("Ch 3 · Oh Yes! Big O Notation",       tabName = "ch3",  icon = icon("chart-line")),
      menuItem("Ch 4 · Speeding Up with Big O",       tabName = "ch4",  icon = icon("bolt")),
      menuItem("Ch 5 · Optimising Code",              tabName = "ch5",  icon = icon("tachometer-alt")),
      menuItem("Ch 6 · Optimistic Scenarios",         tabName = "ch6",  icon = icon("star")),
      menuItem("Ch 7 · Big O in Everyday Code",       tabName = "ch7",  icon = icon("code")),
      menuItem("Ch 8 · Blazing Fast Lookup",          tabName = "ch8",  icon = icon("hashtag")),
      menuItem("Ch 9 · Crafting Elegant Code",        tabName = "ch9",  icon = icon("layer-group")),
      menuItem("Ch 10 · Recursively Recurse",         tabName = "ch10", icon = icon("sync")),
      menuItem("Ch 11 · Learning to Write Recursion", tabName = "ch11", icon = icon("project-diagram")),
      menuItem("Ch 12 · Dynamic Programming",         tabName = "ch12", icon = icon("rocket")),
      menuItem("Ch 13 · Quicksort",                   tabName = "ch13", icon = icon("sort-amount-down")),
      menuItem("Ch 14 · Linked Lists",                tabName = "ch14", icon = icon("link")),
      menuItem("Ch 15 · Binary Search Trees",         tabName = "ch15", icon = icon("sitemap")),
      menuItem("Ch 16 · Heaps",                       tabName = "ch16", icon = icon("mountain")),
      menuItem("Ch 17 · Tries",                       tabName = "ch17", icon = icon("leaf")),
      menuItem("Ch 18 · Graphs",                      tabName = "ch18", icon = icon("project-diagram")),
      menuItem("Ch 19 · Space Constraints",           tabName = "ch19", icon = icon("memory")),
      menuItem("Ch 20 · Code Optimisation",           tabName = "ch20", icon = icon("trophy"))
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
      tabItem(tabName = "ch5",      chapter5_ui("ch5")),
      tabItem(tabName = "ch6",      chapter6_ui("ch6")),
      tabItem(tabName = "ch7",      chapter7_ui("ch7")),
      tabItem(tabName = "ch8",      chapter8_ui("ch8")),
      tabItem(tabName = "ch9",      chapter9_ui("ch9")),
      tabItem(tabName = "ch10",     chapter10_ui("ch10")),
      tabItem(tabName = "ch11",     chapter11_ui("ch11")),
      tabItem(tabName = "ch12",     chapter12_ui("ch12")),
      tabItem(tabName = "ch13",     chapter13_ui("ch13")),
      tabItem(tabName = "ch14",     chapter14_ui("ch14")),
      tabItem(tabName = "ch15",     chapter15_ui("ch15")),
      tabItem(tabName = "ch16",     chapter16_ui("ch16")),
      tabItem(tabName = "ch17",     chapter17_ui("ch17")),
      tabItem(tabName = "ch18",     chapter18_ui("ch18")),
      tabItem(tabName = "ch19",     chapter19_ui("ch19")),
      tabItem(tabName = "ch20",     chapter20_ui("ch20"))
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
}

shinyApp(ui, server)
