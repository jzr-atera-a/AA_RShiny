# app.R - Serendipity: David Cleevely
# Cambridge University Press
# Structure and design system reused from the Compelling Communication (Simon Hall) template.

library(shiny)
library(shinydashboard)

source("global.R", local = TRUE)
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Serendipity"),
  dashboardSidebar(
    tags$div(class = "sidebar-book-badge",
      tags$div(class = "book-chip",    "SERENDIPITY"),
      tags$div(class = "book-authors", "David Cleevely"),
      tags$div(class = "book-pub",     "Cambridge University Press")),
    sidebarMenu(id = "tabs",
      menuItem("\U0001f9ed App Guide",              tabName = "app_guide",  icon = icon("compass")),
      menuItem("\U0001f4da Overview",                tabName = "overview",   icon = icon("home")),
      menuItem("1 \u00b7 The Entangled Bank",        tabName = "ch1",        icon = icon("project-diagram")),
      menuItem("2 \u00b7 Mad About The Moon",        tabName = "ch2",        icon = icon("moon")),
      menuItem("3 \u00b7 How Networks Work",         tabName = "ch3",        icon = icon("share-nodes")),
      menuItem("4 \u00b7 Closer To Home",            tabName = "ch4",        icon = icon("map-location-dot")),
      menuItem("5 \u00b7 The Prepared Mind",         tabName = "ch5",        icon = icon("brain")),
      menuItem("6 \u00b7 Technology May Not Save Us",tabName = "ch6",        icon = icon("microchip")),
      menuItem("7 \u00b7 Too Well Organised",        tabName = "ch7",        icon = icon("sitemap")),
      menuItem("8 \u00b7 Ministry of Predictable",   tabName = "ch8",        icon = icon("landmark")),
      menuItem("9 \u00b7 The Road Most Travelled",   tabName = "ch9",        icon = icon("route")),
      menuItem("10 \u00b7 The Edge Of Chaos",        tabName = "ch10",       icon = icon("atom")),
      menuItem("\u2605 Conclusion",                  tabName = "conclusion", icon = icon("flag-checkered"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
      tags$script(src = "https://d3js.org/d3.v7.min.js"),
      tags$script(src = "js/interactive.js")
    ),
    tabItems(
      tabItem(tabName = "app_guide",  app_guide_ui("app_guide")),
      tabItem(tabName = "overview",   overview_ui("overview")),
      tabItem(tabName = "ch1",        ch1_entangled_bank_ui("ch1")),
      tabItem(tabName = "ch2",        ch2_mad_about_moon_ui("ch2")),
      tabItem(tabName = "ch3",        ch3_how_networks_work_ui("ch3")),
      tabItem(tabName = "ch4",        ch4_closer_to_home_ui("ch4")),
      tabItem(tabName = "ch5",        ch5_prepared_mind_ui("ch5")),
      tabItem(tabName = "ch6",        ch6_technology_ui("ch6")),
      tabItem(tabName = "ch7",        ch7_too_organised_ui("ch7")),
      tabItem(tabName = "ch8",        ch8_ministry_ui("ch8")),
      tabItem(tabName = "ch9",        ch9_road_travelled_ui("ch9")),
      tabItem(tabName = "ch10",       ch10_edge_of_chaos_ui("ch10")),
      tabItem(tabName = "conclusion", conclusion_ui("conclusion"))
    )
  )
)

server <- function(input, output, session) {
  app_guide_server("app_guide")
  overview_server("overview")
  ch1_entangled_bank_server("ch1");    ch2_mad_about_moon_server("ch2");  ch3_how_networks_work_server("ch3")
  ch4_closer_to_home_server("ch4");    ch5_prepared_mind_server("ch5");   ch6_technology_server("ch6")
  ch7_too_organised_server("ch7");     ch8_ministry_server("ch8");       ch9_road_travelled_server("ch9")
  ch10_edge_of_chaos_server("ch10");   conclusion_server("conclusion")
}

shinyApp(ui, server)
