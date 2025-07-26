library(shiny)
library(networkD3)

subcat_strength = read.csv("Tabs/data/subcat_strength_o.csv", sep=";")
subcat_coocurrence = read.csv("Tabs/data/subcat_coocurrence.csv",sep=',')

library(readxl)


#UI_Tab_NetworkMarvel<-tabPanel("Network3D",
UI_Tab_NetworkMarvel <-tabItem(tabName = "NetworkD3", 
           sidebarPanel(
             sliderInput("opacity", h3("Select affinity threshold"), 1, 2, 1, step = 0.1),
             sliderInput("cluster", h3("Select Customer cluster"), 1, 5, 1, step = 1),
             sliderInput("link_distance", h3("Select link strength"), 200, 400, 300, step = 20)
           ),
             mainPanel( forceNetworkOutput("force", height = 600) )
)


Server_Tab_NetworkMarvel<- function(input, output) { 
    
      output$force <- renderForceNetwork({
        NodesCompleted  = subcat_strength[subcat_strength$cluster==input$cluster,c(2,4,3)]
        #NodesCompleted = subcat_strength[subcat_strength$cluster==1,c(2,4,3)]
        NodesCompleted$size <- NodesCompleted$size/50
        rownames(NodesCompleted) <- NULL
        NodesComp<- NodesCompleted[NodesCompleted$size > 0,]  #> 1 more than 1 link between categories
        
        NodesComp$code  = as.numeric(rownames(NodesComp))-1
        NodesComp$group = as.numeric(substring(NodesComp$name,1,2))
        #NodesComp$name2 = nodes[1:28,1]
        print('nodes comp')
        print(NodesComp)
        SubcatsDict = NodesComp[,c('name','code')]
        print('subcat_coocurrence')
        print(subcat_coocurrence)
        LinksMerged <- merge(subcat_coocurrence[subcat_coocurrence$cluster==input$cluster,c(2,3,4)],SubcatsDict,by.x = "source", by.y= "name")
        LinksMerged$source = LinksMerged$code
        LinksMerged <- merge(LinksMerged,SubcatsDict,by.x = "target", by.y= "name")
        LinksMerged$target = LinksMerged$code.y
        LinksMerged
        LinksMerged$value = log(LinksMerged$size)
        LinksCompleted <- LinksMerged[,c('source','target','value')]
        
        forceNetwork(Links = LinksCompleted, Nodes = NodesComp,
                     Source = "source", Target = "target",
                     Value = "value", NodeID = "name",
                     #NodeID = "name2",
                     Nodesize="size", linkDistance = input$link_distance, fontSize = 20, #input$link_distance
                     Group = "group", opacity = input$opacity, height=600, width=600)
      })
      
  
}