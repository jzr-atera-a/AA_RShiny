# app.R — DSA in Python Vol.2, Jay Wengrow (Pragmatic Programmers)
# Complete: Chapters 1–13

source("global.R", local = TRUE)
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "DSA Vol.2 Lab"),
  dashboardSidebar(
    tags$div(class = "sidebar-book-badge",
      tags$div(class = "book-chip",    "DSA IN PYTHON \u00b7 VOLUME 2"),
      tags$div(class = "book-authors", "Jay Wengrow"),
      tags$div(class = "book-pub",     "Pragmatic Programmers \u00b7 2025")),
    sidebarMenu(id = "tabs",
      menuItem("\U0001f4da Overview",                                   tabName = "overview", icon = icon("book")),
      menuItem("Ch 1 \u00b7 Mergesort",                                tabName = "ch1",  icon = icon("sort-amount-down")),
      menuItem("Ch 2 \u00b7 Benchmarking Code",                        tabName = "ch2",  icon = icon("stopwatch")),
      menuItem("Ch 3 \u00b7 How Random Is That?",                      tabName = "ch3",  icon = icon("dice")),
      menuItem("Ch 4 \u00b7 Cache Is King",                            tabName = "ch4",  icon = icon("memory")),
      menuItem("Ch 5 \u00b7 Red-Black Trees",                          tabName = "ch5",  icon = icon("sitemap")),
      menuItem("Ch 6 \u00b7 Randomized Treaps",                        tabName = "ch6",  icon = icon("tree")),
      menuItem("Ch 7 \u00b7 B-Trees",                                  tabName = "ch7",  icon = icon("folder-open")),
      menuItem("Ch 8 \u00b7 M/B-Way Mergesort",                        tabName = "ch8",  icon = icon("layer-group")),
      menuItem("Ch 9 \u00b7 Monte Carlo Algorithms",                   tabName = "ch9",  icon = icon("dice-d6")),
      menuItem("Ch 10 \u00b7 Hash Tables + Randomization",             tabName = "ch10", icon = icon("hashtag")),
      menuItem("Ch 11 \u00b7 Rabin-Karp Substring Search",             tabName = "ch11", icon = icon("search")),
      menuItem("Ch 12 \u00b7 Saving Space with Bit Vectors",           tabName = "ch12", icon = icon("microchip")),
      menuItem("Ch 13 \u00b7 Cultivating a Bloom Filter",              tabName = "ch13", icon = icon("filter"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
      tags$script(HTML("Shiny.addCustomMessageHandler('copy_to_clipboard',function(t){navigator.clipboard.writeText(t)});"))
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
      tabItem(tabName = "ch13",     chapter13_ui("ch13"))
    )
  )
)

server <- function(input, output, session) {
  overview_server("overview")
  chapter1_server("ch1");   chapter2_server("ch2");   chapter3_server("ch3")
  chapter4_server("ch4");   chapter5_server("ch5");   chapter6_server("ch6")
  chapter7_server("ch7");   chapter8_server("ch8");   chapter9_server("ch9")
  chapter10_server("ch10"); chapter11_server("ch11"); chapter12_server("ch12")
  chapter13_server("ch13")
}

shinyApp(ui, server)
