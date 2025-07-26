UI_Tab_Dashboard     <-tabItem(tabName = "dashboard", 
                               #h2("Dashboard tab content")
                               fluidRow(
                                 box(plotOutput("plot1", height = 250)),
                                 
                                 box(
                                   title = "Controls",
                                   sliderInput("slider", "Number of observations:", 1, 100, 50)
                                 )
                               )
                               )


Server_Tab_DashboardSimple <- function(input, output) {
  set.seed(122)
  histdata <- rnorm(500)
  
  output$plot1 <- renderPlot({
    data <- histdata[seq_len(input$slider)]
    hist(data)
  })
}