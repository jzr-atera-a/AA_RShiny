#Based on https://cran.r-project.org/web/packages/plotROC/vignettes/examples.html
library(plotROC)       

ui <- shinyUI(
  plotOutput('myplot')
)

UI_Tab_Plot_ROC<-tabPanel("Plot_ROC", 
                         mainPanel( plotOutput("plot_ROC", height = 600) )
)

Server_Tab_Plot_ROC<- function(input, output) { 

  output$plot_ROC <- renderPlot({
    set.seed(2529)
    D.ex <- rbinom(200, size = 1, prob = .5)
    M1 <- rnorm(200, mean = D.ex, sd = .65)
    M2 <- rnorm(200, mean = D.ex, sd = 1.5)
    
    test <- data.frame(D = D.ex, D.str = c("Healthy", "Ill")[D.ex + 1], 
                       M1 = M1, M2 = M2, stringsAsFactors = FALSE)
    longtest <- melt_roc(test, "D", c("M1", "M2"))
    
    ggplot(longtest, aes(d = D, m = M, color = name)) + geom_roc(n.cuts = 0) +
      geom_rocci(ci.at = quantile(M1, c(.1, .4, .5, .6, .9))) + style_roc()
    #plot(my_roc)
  })
}