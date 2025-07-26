library(networkD3)
data(MisLinks)
data(MisNodes)

# library(RODBC)
# 
# conn <- odbcConnect('ctx-hp1-impala') # Specify ODBC connection name
# #IF TABLE IS ONLY VISIBLE FROM SPARK, you can invalidate its metadata from here USING ONLY IMPALA from hue
# 
# subcat_strength <- sqlQuery(conn, 'SELECT * FROM ctx_ai_test.fz_network_subcats_strength order by name')
# subcat_strength$group <- round(runif(nrow(subcat_strength),1,10),0)
# subcat_coocurrence <- sqlQuery(conn, 'SELECT * FROM ctx_ai_test.fz_network_subcats_coocurrence order by value desc')
# 
  # write.csv2(LinksCompleted,'D:/Data/SourceSafe/BitBucket/spark-testing/spark_network/data_samples/LinksCompleted.csv',row.names=FALSE)
  # write.csv2(NodesCompleted,'D:/Data/SourceSafe/BitBucket/spark-testing/spark_network/data_samples/NodesCompleted.csv',row.names=FALSE)

LinksCompleted2 = read.csv2('D:/Data/SourceSafe/BitBucket/spark-testing/spark_network/data_samples/LinksCompleted.csv',sep=';')
NodesCompleted2 = read.csv2('D:/Data/SourceSafe/BitBucket/spark-testing/spark_network/data_samples/NodesCompleted.csv')


# Nodes$code = as.numeric(rownames(Nodes))-1
# 
# SubcatsDict = Nodes[,c('name','code')]
# 
# NodesCompleted = subcat_strength[,c(1,3,2)]
# NodesComp<- NodesCompleted[NodesCompleted$size > 1,]
# 
# subcat_coocurrence

# LinksMerged <- merge(Links,SubcatsDict,by.x = "source", by.y= "name")
# LinksMerged$source = LinksMerged$code
# LinksMerged <- merge(LinksMerged,SubcatsDict,by.x = "target", by.y= "name")
# LinksMerged$target = LinksMerged$code.y
# LinksCompleted <- LinksMerged[,c('source','target','value')]


#UI_Tab_NetworkMarvel<-tabPanel("Network3D",
UI_Tab_NetworkMarvel <-tabItem(tabName = "NetworkD3", 
           sidebarPanel(
             sliderInput("opacity", h3("select opacity"), 0, 2, 1, step = 0.1),
             sliderInput("link_distance", h3("select link distance"), 200, 400, 1, step = 20)
           ),
            mainPanel( forceNetworkOutput("force", height = 600) )
        )

Server_Tab_NetworkMarvel<- function(input, output) { 
    
  
  
    output$force <- renderForceNetwork({
      # forceNetwork(Links = marvel_coocurrence, Nodes = char_strength[,c(1,3,2)],
      #              #Links = MisLinks, Nodes = MisNodes,
      #              Source = "source", Target = "target",
      #              Value = "value", NodeID = "name",
      #              Group = "group", opacity = input$opacity)
      # forceNetwork(Links = LinksCompleted2, Nodes = NodesCompleted2,
      #              #Links = MisLinks, Nodes = MisNodes,
      #              Source = "source", Target = "target",
      #              Value = "value", NodeID = "name", Nodesize="size", linkDistance = input$link_distance, fontSize = 20,
      #              Group = "group", opacity = input$opacity, height=600, width=600)
      forceNetwork(Links = LinksCompleted2, Nodes = NodesCompleted2,
                   #Links = MisLinks, Nodes = MisNodes,
                   Source = "source", Target = "target",
                   Value = "value", NodeID = "name", Nodesize="size", linkDistance = 300, fontSize = 20,
                   Group = "group", opacity =1, height=600, width=600)
      #write.table(MisLinks, 'D:/Data/SourceSafe/BitBucket/spark-testing/spark_network/data_samples/MisLinks.csv',sep=',',row.names = FALSE)
      #write.table(MisNodes, 'D:/Data/SourceSafe/BitBucket/spark-testing/spark_network/data_samples/MisNodes.csv',sep=',',row.names = FALSE)
      
      })  
  
}