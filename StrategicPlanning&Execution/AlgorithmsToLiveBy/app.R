# app.R — Algorithms to Live By: The Computer Science of Human Decisions
# Brian Christian & Tom Griffiths | William Morrow, 2016
# Interactive R Shiny Companion — All 11 Chapters + Conclusion

source("global.R", local = TRUE)
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Algorithms to Live By"),
  dashboardSidebar(
    tags$div(class="sidebar-book-badge",
      tags$div(class="book-chip","ALGORITHMS TO LIVE BY"),
      tags$div(class="book-authors","Brian Christian & Tom Griffiths"),
      tags$div(class="book-pub","William Morrow \u00b7 2016")),
    sidebarMenu(id="tabs",
      menuItem("\U0001f4da Overview",                      tabName="overview",    icon=icon("book")),
      menuItem("1 \u00b7 Optimal Stopping",               tabName="ch1",         icon=icon("stop-circle")),
      menuItem("2 \u00b7 Explore / Exploit",              tabName="ch2",         icon=icon("compass")),
      menuItem("3 \u00b7 Sorting",                        tabName="ch3",         icon=icon("sort")),
      menuItem("4 \u00b7 Caching",                        tabName="ch4",         icon=icon("memory")),
      menuItem("5 \u00b7 Scheduling",                     tabName="ch5",         icon=icon("calendar-check")),
      menuItem("6 \u00b7 Bayes' Rule",                    tabName="ch6",         icon=icon("chart-line")),
      menuItem("7 \u00b7 Overfitting",                    tabName="ch7",         icon=icon("brain")),
      menuItem("8 \u00b7 Relaxation",                     tabName="ch8",         icon=icon("couch")),
      menuItem("9 \u00b7 Randomness",                     tabName="ch9",         icon=icon("dice")),
      menuItem("10 \u00b7 Networking",                    tabName="ch10",        icon=icon("network-wired")),
      menuItem("11 \u00b7 Game Theory",                   tabName="ch11",        icon=icon("chess")),
      menuItem("\u2605 Computational Kindness",            tabName="conclusion",  icon=icon("heart"))
    )
  ),
  dashboardBody(
    tags$head(tags$link(rel="stylesheet", type="text/css", href="css/global.css")),
    tabItems(
      tabItem(tabName="overview",    overview_ui("overview")),
      tabItem(tabName="ch1",         chapter1_ui("ch1")),
      tabItem(tabName="ch2",         chapter2_ui("ch2")),
      tabItem(tabName="ch3",         chapter3_ui("ch3")),
      tabItem(tabName="ch4",         chapter4_ui("ch4")),
      tabItem(tabName="ch5",         chapter5_ui("ch5")),
      tabItem(tabName="ch6",         chapter6_ui("ch6")),
      tabItem(tabName="ch7",         chapter7_ui("ch7")),
      tabItem(tabName="ch8",         chapter8_ui("ch8")),
      tabItem(tabName="ch9",         chapter9_ui("ch9")),
      tabItem(tabName="ch10",        chapter10_ui("ch10")),
      tabItem(tabName="ch11",        chapter11_ui("ch11")),
      tabItem(tabName="conclusion",  conclusion_ui("conclusion"))
    )
  )
)

server <- function(input, output, session) {
  overview_server("overview")
  chapter1_server("ch1");  chapter2_server("ch2");  chapter3_server("ch3")
  chapter4_server("ch4");  chapter5_server("ch5");  chapter6_server("ch6")
  chapter7_server("ch7");  chapter8_server("ch8");  chapter9_server("ch9")
  chapter10_server("ch10"); chapter11_server("ch11")
  conclusion_server("conclusion")
}

shinyApp(ui, server)
