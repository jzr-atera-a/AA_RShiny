rm(list = ls())

library("shinydashboard")
library(shiny)

source('./Tabs/Tab_DashboardSimple.R')
#source('./Tabs/Mod_Tab_Map_Wind/Tab_WindLocs.R')
#source('./Tabs/Mod_Tab_Map/Tab_Map.R')
#source('./Tabs/Tab_NetworkCtxBaskets.R')
source('./Tabs/Tab_NetworkCtxCustomerInteractions.R')
source('./Tabs/Tab_AB_Testing.R')
source('./Tabs/Tab_PlotSVM.R') 
source('./Tabs/Tab_PlotROC.R')
source('./Tabs/Mod_Tab_Sankey/UI_Tab_Net_Sankey.R')

tabPanel("Tab_Sankey", UI_Tab_Network3DSankey)
## ui.R ##
sidebar <- dashboardSidebar(
  sidebarMenu(
    #menuItem("ctMap",   tabName = "CtMap"),
     menuItem("Dashboard", tabName = "dashboard",        icon = icon("dashboard")),
     #menuItem("WindMap",   tabName = "EnergyWeatherMap"),
     menuItem("NetworkD3",   tabName = "NetworkD3"),
     menuItem("ABTesting", tabName = "ABTesting"),
     menuItem("Hyper parameters", tabName = "Plot_SVM"),
     menuItem("Performance", tabName = "Plot_ROC"),
     menuItem("Customer Journeys", tabName = "Tab_Sankey"),
     menuItem("Widgets", icon = icon("th"), tabName = "widgets",
              badgeLabel = "new", badgeColor = "green")
  )
)

body <- dashboardBody(
  tabItems( #tabItem(tabName = "dashboard", h2("Dashboard tab content")),
    #tabItem("CtMap",Tab_Map),        
     tabItem("dashboard",UI_Tab_Dashboard),
     tabItem("ABTesting",UI_Tab_AB_Testing),
     tabItem("Tab_Sankey", UI_Tab_Network3DSankey),
     tabItem("Plot_SVM", UI_Tab_PlotSVM),
     tabItem("Plot_ROC", UI_Tab_Plot_ROC),
     #tabItem("EnergyWeatherMap",UI_Tab_Map_Wind),
     tabItem("NetworkD3",UI_Tab_NetworkMarvel),
    #        #tabPanel("Gaussian Simple", UI_Tab_GaussianSimple) #original tabshiny format
    #        #UI_Tab_GaussianSimple<-tabPanel("Gaussian Simple", ....) #inside called file for Gaussian Simple
    # 
     tabItem(tabName = "widgets",  h2("Widgets tab content")
    )
  ),
  tags$head(tags$style(HTML(
    '.myClass { 
        font-size: 26px;
        line-height: 50px;
        text-align: left;
        font-family: "Verdana",Helvetica,Arial,sans-serif;
        font-weight:bold;
        padding: 0 15px;
        overflow: hidden;
        color: white;
      }
    '))),
  tags$script(HTML('
      $(document).ready(function() {
        $("header").find("nav").append(\'<span class="myClass"> Customer Modelling PoC </span>\');
      })
     '))
)

server_fx <- function(input, output, session) {
  # Empty reactive container
  values  <- reactiveValues()
  ##output$cMap <- Server_Tab_Map(input, output,session)
  output$plot1      <- Server_Tab_DashboardSimple(input, output )
  #output$energyMap1 <- Server_Tab_Map_Wind(input, output)
  output$force      <- Server_Tab_NetworkMarvel(input, output)
  output$sankey     <- Server_Tab_Network3DSankey(input, output )
  output$plotSvm    <- Server_Tab_PlotSVM(input, output)  
  output$plotly     <- Server_Tab_AB_Testing(input, output)
  output$plot_ROC   <- Server_Tab_Plot_ROC(input, output)
  
}

shinyApp(
  ui = dashboardPage(
    dashboardHeader(title = "UI Dashboard"),
    sidebar,
    body
  ),
  server = server_fx
)
