# app.R — ML Decision Engine
source("global.R")
source("modules/wizard.R")
source("modules/results.R")
source("modules/reference.R")

`%||%` <- function(x, y) if(is.null(x)) y else x

ui <- dashboardPage(
  skin = "green",
  dashboardHeader(title = "ML Decision Engine"),
  dashboardSidebar(
    tags$head(tags$link(rel="stylesheet", type="text/css", href="css/global.css")),
    sidebarMenu(
      menuItem("Decision Wizard",  tabName="wizard",    icon=icon("magic")),
      menuItem("Results",          tabName="results",   icon=icon("star")),
      menuItem("Methods Reference",tabName="reference", icon=icon("book"))
    ),
    div(style="padding:14px;color:rgba(255,255,255,0.6);font-size:10px;line-height:1.5;",
      tags$hr(style="border-color:rgba(255,255,255,0.15);"),
      tags$b(style="color:rgba(255,255,255,0.85);", "Based on:"),
      tags$p("Huyen — Designing ML Systems (O'Reilly 2022)"),
      tags$p("Kravchenko & Babushkin — ML System Design (Manning 2025)"),
      tags$hr(style="border-color:rgba(255,255,255,0.15);"),
      tags$p("12 Method Groups · 52 Methods · 150+ Use Cases")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName="wizard",    wizard_ui("wiz")),
      tabItem(tabName="results",   results_ui("res")),
      tabItem(tabName="reference", reference_ui("ref"))
    )
  )
)

server <- function(input, output, session) {
  wizard_inputs <- reactiveValues(run_count=0)
  wizard_server("wiz", wizard_inputs)
  results_server("res", wizard_inputs)
  reference_server("ref")
}

shinyApp(ui, server)
