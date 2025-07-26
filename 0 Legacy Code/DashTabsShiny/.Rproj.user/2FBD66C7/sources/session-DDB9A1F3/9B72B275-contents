#library(caret)
library(e1071)
library(MASS)


UI_Tab_PlotSVM<-tabPanel("PlotSimple", 
                            sidebarPanel(
                                sliderInput("svm_cost", h3("select cost value"), 0.5, 7, 5, step = 0.5),
                                sliderInput("svm_gamma", h3("select gamma value"), 0.2, 4, 1, step = 0.2)
                                ),
                            mainPanel( plotOutput("plotSvm", height = 600) )
                        )

Server_Tab_PlotSVM<- function(input, output) { 
  output$plotSvm<- renderPlot({
    
    
    set.seed (1)
    x <- matrix(rnorm(200*2), ncol=2)
    x[1:100,]=x[1:100,]+2
    x[101:150,]=x[101:150,]-2
    
    y <- c(rep(1,150),rep(2,50))
    dat <- data.frame(x=x,y=as.factor(y))
    
    #plot(x, col=y)
    train <- sample(200, 100)

    cost_s=10^input$svm_cost
    #overfitting
    svm.fit <- svm(y ~., dat[train,], kernel='radial', gamma=input$svm_gamma, cost=cost_s)
    plot(svm.fit, dat[train,])
  })
}