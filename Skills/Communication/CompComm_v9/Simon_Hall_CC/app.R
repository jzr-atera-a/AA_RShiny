# app.R - Compelling Communication: Simon Hall
# Cambridge University Press
# Version 7.0

library(shiny)
library(shinydashboard)

source("global.R", local = TRUE)
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Compelling Comm."),
  dashboardSidebar(
    tags$div(class = "sidebar-book-badge",
      tags$div(class = "book-chip",    "COMPELLING COMMUNICATION"),
      tags$div(class = "book-authors", "Simon Hall"),
      tags$div(class = "book-pub",     "Cambridge University Press")),
    sidebarMenu(id = "tabs",
      menuItem("\U0001f9ed App Guide",               tabName = "app_guide",  icon = icon("compass")),
      menuItem("\U0001f4da Overview",                tabName = "overview",   icon = icon("home")),
      menuItem("1 \u00b7 Foundations",              tabName = "ch1",        icon = icon("lightbulb")),
      menuItem("2 \u00b7 Writing",                  tabName = "ch2",        icon = icon("pen")),
      menuItem("3 \u00b7 Trade Tricks",             tabName = "ch3",        icon = icon("tools")),
      menuItem("4 \u00b7 Storytelling",             tabName = "ch4",        icon = icon("book-open")),
      menuItem("5 \u00b7 Strategic Stories",        tabName = "ch5",        icon = icon("chess")),
      menuItem("6 \u00b7 Public Speaking",          tabName = "ch6",        icon = icon("microphone")),
      menuItem("7 \u00b7 Powerful Speaking",        tabName = "ch7",        icon = icon("comments")),
      menuItem("8 \u00b7 Online World",             tabName = "ch8",        icon = icon("globe")),
      menuItem("9 \u00b7 Media",                    tabName = "ch9",        icon = icon("newspaper")),
      menuItem("10 \u00b7 Strategic Comms",         tabName = "ch10",       icon = icon("chess-king")),
      menuItem("\u2605 Conclusion",                 tabName = "conclusion", icon = icon("flag-checkered"))
    )
  ),
  dashboardBody(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css")),
    tabItems(
      tabItem(tabName = "app_guide",  app_guide_ui("app_guide")),
      tabItem(tabName = "overview",   overview_ui("overview")),
      tabItem(tabName = "ch1",        ch1_foundations_ui("ch1")),
      tabItem(tabName = "ch2",        ch2_writing_ui("ch2")),
      tabItem(tabName = "ch3",        ch3_tricks_ui("ch3")),
      tabItem(tabName = "ch4",        ch4_storytelling_ui("ch4")),
      tabItem(tabName = "ch5",        ch5_strategic_stories_ui("ch5")),
      tabItem(tabName = "ch6",        ch6_public_speaking_ui("ch6")),
      tabItem(tabName = "ch7",        ch7_powerful_speaking_ui("ch7")),
      tabItem(tabName = "ch8",        ch8_online_world_ui("ch8")),
      tabItem(tabName = "ch9",        ch9_media_ui("ch9")),
      tabItem(tabName = "ch10",       ch10_strategic_comm_ui("ch10")),
      tabItem(tabName = "conclusion", conclusion_ui("conclusion"))
    )
  )
)

server <- function(input, output, session) {
  app_guide_server("app_guide")
  overview_server("overview")
  ch1_foundations_server("ch1");  ch2_writing_server("ch2");  ch3_tricks_server("ch3")
  ch4_storytelling_server("ch4"); ch5_strategic_stories_server("ch5"); ch6_public_speaking_server("ch6")
  ch7_powerful_speaking_server("ch7"); ch8_online_world_server("ch8"); ch9_media_server("ch9")
  ch10_strategic_comm_server("ch10"); conclusion_server("conclusion")
}

shinyApp(ui, server)
