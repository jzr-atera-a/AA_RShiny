############################################################
# Shiny App Module - Map and Clustering
#
# Date: Feb 2018
# Author(s): Francisco Zubizarreta
############################################################



library(leaflet)
library(htmltools)
library(dplyr)
library(readr)
# library(RColorBrewer) #unnecesary library
# library(scales)#unnecesary library
# library(lattice)#unnecesary library

dat_for_curves <- read_csv('./Tabs/Mod_Tab_Map/data/dat_for_curves2.csv')
demog_features <- read_csv('./Tabs/Mod_Tab_Map/data/features_demographics.csv')

features_list <- colnames(demog_features)[2:length(demog_features)]

md_stores      <- dat_for_curves %>% select(., name=location_id, lat,lng= lon, customer_cluster, State= state ) %>% unique()

md_stores$customer_cluster <- as.character(md_stores$customer_cluster)

clusters_needs        <- list("All","1","2","3","4","5")

getColor <- function(df) {
  sapply(df$feature, function(feature) {
    if(feature == '1') {
      "green"
    } else if(feature == '2') {
      "orange"
    } else if(feature == '3') {
      "blue"
    } else if(feature == '4') {
      "yellow"
    } else {
      "red"
    } })
}

#UI_Tab_Map<-tabPanel("Map",
Tab_Map  <-tabItem(tabName = "CtMap", 
         fluidRow(
               column(4,  selectInput("selectCNeedsCluster", h3("Select Customer Needs")  ,  clusters_needs, selected = 'All')
                         ,selectInput("selectFeature", h3("SelectFeature")  ,  features_list)
                      )
              #,column(3,  selectInput("selectFeature", h3("SelectFeature")  ,  features_list))
              ,column(8,leafletOutput("cMap",height=350)))
           ) 
         # ,leafletOutput("cMap",height=300))


Server_Tab_Map<- function(input, output, session) {
  
  # output$cMap <- renderLeaflet({
  #   leaflet() %>%
  #   setView(lng = 133.77, lat = -25.27, zoom = 4)
  # })
  

  
  observe({
      selectedCNeedsCluster <- input$selectCNeedsCluster
    
      selectedFeature     <- input$selectFeature
      
      if (selectedCNeedsCluster!='All'){
        md_stores_set<-md_stores[md_stores[,'customer_cluster']==selectedCNeedsCluster,]
      } else {md_stores_set<-md_stores }
      md_stores_set$map_message <- paste0(as.character(md_stores_set$name),'-', md_stores_set$customer_cluster,'-', md_stores_set$State)
    
      #sel_store <- md_stores_set %>% select(name)
    
      # md_stores_set<-md_stores_set[,c("name","map_message","lat","lng","customer_cluster")]
      md_stores_set<-md_stores_set[,c("name","map_message","lat","lng","customer_cluster","State")]
    
      demog_features_sel <- demog_features[,c("Locn_No",selectedFeature)]
    
      feat_data <- md_stores_set %>% inner_join(demog_features_sel, by = c("name" = "Locn_No"), keep= TRUE)
      
      feat_data$map_message <- paste0(as.character(feat_data$name),'-', feat_data$customer_cluster,'-', feat_data$State,'-')
    
      #md_stores_set<-md_stores_set[,c("map_message","lat","lng","customer_cluster")]
      map_data <-feat_data[,c("map_message","lat","lng","customer_cluster",selectedFeature)]
    
      #md_stores_set$customer_cluster <- as.factor(md_stores_set$customer_cluster)
      map_data$customer_cluster <- as.factor(map_data$customer_cluster)
    
      map_data$feature <- map_data$name
      #colnames(map_data)[4] <- "feature"
      colnames(map_data)[5] <- "feature"
      #map_data$feature2 <- map_data[,selectedFeature]
    
      range01 <- function(x){(x-min(x))/(max(x)-min(x))}
    
      map_data$feature <- as.factor(as.integer(range01(map_data$feature)*5)+1)
    
      print(head(map_data))
    
      icons <- awesomeIcons(
        icon = 'ios-close',
        iconColor = 'black',
        library = 'ion',
        markerColor = getColor(map_data) #getColor(md_stores_set)
      )
      
      leafletProxy("cMap") %>%
        clearShapes() 
      
      # #md_stores_set %>%
      # #map_data %>%
      # #leaflet() %>%
      leafletProxy("cMap", data=map_data) %>%
        clearShapes() %>%
       # addTiles() %>%
        addAwesomeMarkers(~lng, ~lat, icon=icons, popup = ~htmlEscape(map_message), layerId=~map_message)%>%
        addLegend("bottomleft",colors = c('green','orange','blue','yellow','red')#, pal = pal,
                  ,values = ~feature
                  ,labels = c('1',
                              '2',
                              '3',
                              '4',
                              '5')
                  ,title = selectedFeature,
                  layerId="colorLegend"
      )
  })
  
  output$cMap <- renderLeaflet({
    leaflet() %>%
      
      addTiles(
        urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
        attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
      ) %>%
      setView(lng = 133.77, lat = -25.27, zoom = 4)
  })

}
