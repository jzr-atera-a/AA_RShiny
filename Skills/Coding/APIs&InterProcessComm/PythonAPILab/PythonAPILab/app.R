# app.R — Python API Development Fundamentals Lab
# Jack Chan, Ray Chung, Jack Huang (Packt, 2019)
# Chapters 1–3 interactive companion

source("global.R", local = TRUE)
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Python API Lab"),
  dashboardSidebar(
    tags$div(class = "sidebar-book-badge",
      tags$div(class = "book-chip",    "PYTHON API DEV \u00b7 FUNDAMENTALS"),
      tags$div(class = "book-authors", "Chan \u00b7 Chung \u00b7 Huang"),
      tags$div(class = "book-pub",     "Packt Publishing \u00b7 2019")),
    sidebarMenu(id = "tabs",
      menuItem("\U0001f4da Overview",                         tabName = "overview", icon = icon("book")),
      menuItem("Ch 1 \u00b7 Your First Step",                 tabName = "ch1",      icon = icon("globe")),
      menuItem("Ch 2 \u00b7 Building Our Project",            tabName = "ch2",      icon = icon("wrench")),
      menuItem("Ch 3 \u00b7 Database + SQLAlchemy",           tabName = "ch3",      icon = icon("database")),
      menuItem("Ch 4 \u00b7 JWT Authentication",              tabName = "ch4",      icon = icon("lock")),
      menuItem("Ch 5 \u00b7 marshmallow Serialization",       tabName = "ch5",      icon = icon("exchange-alt")),
      menuItem("Ch 6 \u00b7 Email Confirmation",              tabName = "ch6",      icon = icon("envelope")),
      menuItem("Ch 7 \u00b7 Working with Images",             tabName = "ch7",      icon = icon("image")),
      menuItem("Ch 8 \u00b7 Pagination + Search",             tabName = "ch8",      icon = icon("list")),
      menuItem("Ch 9 \u00b7 Caching + Rate Limiting",         tabName = "ch9",      icon = icon("bolt"))
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
      tabItem(tabName = "ch9",      chapter9_ui("ch9"))
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
}

shinyApp(ui, server)
