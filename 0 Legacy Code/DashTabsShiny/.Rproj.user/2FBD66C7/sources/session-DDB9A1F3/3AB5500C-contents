library(networkD3)
jsonfile = './Tabs/Mod_Tab_Sankey/customers.json'
#jsonfile = './Tabs/Mod_Tab_Sankey/energy.json'

Energy <- jsonlite::fromJSON(jsonfile) #URL)
# Plot

UI_Tab_Network3DSankey<-tabPanel("Sankey", 
                           sidebarPanel(
                             sliderInput("node_width", h3("select node width"), 0, 50, 10, step = 5)
                           ),
                            mainPanel( sankeyNetworkOutput("sankey", width=750 , height = 600) )
                        )

Server_Tab_Network3DSankey<- function(input, output) { 
    
    output$sankey <- renderSankeyNetwork({
      
      sankeyNetwork(Links = Energy$links, Nodes = Energy$nodes, Source = "source",
                    Target = "target", Value = "value", NodeID = "name",
                    units = "TWh", fontSize = 12, nodeWidth = input$node_width)
    })  
  
}