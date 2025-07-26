
library(readr)
library(htmltools)
library(shiny)
library(leaflet)

Sites_Group <- list("All","Wind_Farm","Weather_Station")
md_stores <- read_csv('./Tabs/Mod_Tab_Map_Wind/OZWindfarms&WeatherStations.csv')

#UI_Tab_Map_Wind <-tabPanel("EnergyWeatherMap",
UI_Tab_Map_Wind   <-tabItem(tabName = "EnergyWeatherMap", 
         fluidRow(
           column(3,  selectInput("select42", h3("Select Site Group")  ,  Sites_Group, selected = "All" ))
         ), 
         leafletOutput("energyMap1",height = 600) )


#https://rstudio-pubs-static.s3.amazonaws.com/235934_2fe3cd33465548a8aa4f09de635a2f6e.html
#bbb 

Server_Tab_Map_Wind<- function(input, output) { 
  output$energyMap1 <- renderLeaflet({
    
    if (input$select42!='All'){
      md_stores_set<-md_stores[md_stores[,'Group']==input$select42,]
    } else {md_stores_set<-md_stores }
    
    md_stores_set$map_message <- paste0(as.character(md_stores_set$name),'-', 
                                        md_stores_set$Group,'-', md_stores_set$State
                                        ,'-', md_stores_set$detail )
    
    md_stores_set<-md_stores_set[,c("map_message","lat","lng","Group")]
    md_stores_set <- as.data.frame(md_stores_set)
    #factpal <- colorFactor(topo.colors(5), md_stores_set$Cluster_2)
    
    getColor <- function(df) {
      sapply(df$Group, function(Group) {
        if(Group == 'Wind_Farm') {
          "green"
        } else if(Group == 'Weather_Station') {
          "blue"
        } else {
          "black"
        } })
    }
    
    md_stores_set$Group <- as.factor(md_stores_set$Group)
    
    icons <- awesomeIcons(
      icon = 'ios-close',
      iconColor = 'black',
      library = 'ion',
      markerColor = getColor(md_stores_set)
    )
    
    
    md_stores_set %>%
      leaflet() %>%
      addTiles() %>%
      #addCircles(weight = 1, radius = 10000)
      addAwesomeMarkers(~lng, ~lat, icon=icons, popup = ~htmlEscape(map_message))%>%
      
      addLegend("bottomright",colors = c('orange','blue')#, pal = pal, 
                ,values = ~Cluster_2
                ,labels = c('Wind_Farm',
                            'Weather_Station')
                ,title = "Wind Farms and Weather Stations"#,
                #labFormat = labelFormat(prefix = "$"),
                #opacity = 1
      )
  })
}
