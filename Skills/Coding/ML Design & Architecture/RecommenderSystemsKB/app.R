# app.R
# Practical Recommender Systems — Code Lab Edition
# Kim Falk (Manning 2019) · Extended with interactive R implementations

library(shiny)
library(shinydashboard)
library(plotly)
library(ggplot2)
library(DT)
library(dplyr)
library(tidyr)

source("global.R", local = TRUE)

for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) {
  source(f, local = TRUE)
}

ui <- dashboardPage(
  skin = "black",

  dashboardHeader(title = "RecSys Code Lab"),

  dashboardSidebar(
    tags$div(class = "sidebar-book-badge",
             tags$div(class = "book-chip",  "PRACTICAL RECOMMENDER SYSTEMS"),
             tags$div(class = "book-authors", "Kim Falk"),
             tags$div(class = "book-pub",  "Manning Publications · 2019")),

    sidebarMenu(
      id = "tabs",
      menuItem("📚 Overview",                    tabName = "overview", icon = icon("book")),
      menuItem("Ch 1 · What is a Recommender?",  tabName = "ch1",      icon = icon("lightbulb")),
      menuItem("Ch 2 · User Behavior & Data",    tabName = "ch2",      icon = icon("users")),
      menuItem("Ch 3 · Monitoring Systems",      tabName = "ch3",      icon = icon("chart-line")),
      menuItem("Ch 4 · Ratings & Calculations",  tabName = "ch4",      icon = icon("star")),
      menuItem("Ch 5 · Non-Personalized Recs",   tabName = "ch5",      icon = icon("fire")),
      menuItem("Ch 6 · Cold-Start Problem",      tabName = "ch6",      icon = icon("snowflake")),
      menuItem("Ch 7 · Similarity Measures",     tabName = "ch7",      icon = icon("ruler")),
      menuItem("Ch 8 · Collaborative Filtering", tabName = "ch8",      icon = icon("people-arrows")),
      menuItem("Ch 9 · Evaluation & Testing",    tabName = "ch9",      icon = icon("vial")),
      menuItem("Ch 10 · Content-Based",          tabName = "ch10",     icon = icon("file-alt")),
      menuItem("Ch 11 · Matrix Factorization",   tabName = "ch11",     icon = icon("th")),
      menuItem("Ch 12 · Hybrid Recommenders",    tabName = "ch12",     icon = icon("layer-group")),
      menuItem("Ch 13 · Learning to Rank",       tabName = "ch13",     icon = icon("sort-amount-up")),
      menuItem("Ch 14 · Future of RecSys",       tabName = "ch14",     icon = icon("rocket"))
    )
  ),

  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css")
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
      tabItem(tabName = "ch14",     chapter14_ui("ch14"))
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
}

shinyApp(ui, server)
