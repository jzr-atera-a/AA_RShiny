# modules/route_map/ui.R

route_map_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Interactive Route Map", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        leafletOutput(ns("routeMap"), height = "600px"),
        
        br(),
        
        div(style = "text-align: center;",
            h5("Map Legend:"),
            p(HTML("<span style='color: green;'>●</span> Start | 
                   <span style='color: orange;'>●</span> Charging Points | 
                   <span style='color: red;'>●</span> End | 
                   <span style='color: blue;'>―</span> Route"))
        )
      )
    )
  )
}
