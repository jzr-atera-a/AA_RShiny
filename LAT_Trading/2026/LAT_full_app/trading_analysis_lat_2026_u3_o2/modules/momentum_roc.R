# modules/momentum_roc.R

momentum_roc_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Configuration", status = "primary", solidHeader = TRUE, width = 3,
        tags$p(HTML(paste0(
          "<strong>Momentum(n)</strong> = C<sub>t</sub> &minus; C<sub>t-n</sub>. <strong>Rate of Change(n)</strong> ",
          "= [Momentum(n) / C<sub>t-n</sub>] &times; 100 — the same idea expressed as a percentage, which ",
          "makes it comparable across assets trading at very different price levels."
        )), style = "font-size:12px; color:#444; line-height:1.6;"),
        numericInput(ns("momPeriod"), "Period (n):", value = 10, min = 1, max = 100, step = 1)
      ),
      box(
        title = "Momentum & Rate of Change", status = "primary", solidHeader = TRUE, width = 9,
        withSpinner(plotlyOutput(ns("momentumROCChart"), height = "450px")),
        tags$p(paste0(
          "Both oscillate around zero. Positive values indicate the price is higher than n periods ago ",
          "(upward momentum); negative values indicate the price has fallen over the period."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    )
  )
}

momentum_roc_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    output$momentumROCChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data, input$momPeriod)
      n <- input$momPeriod
      data <- data %>%
        arrange(Date) %>%
        mutate(
          MOM = Close - lag(Close, n),
          ROC = (MOM / lag(Close, n)) * 100
        )
      req(nrow(data) > n)
      
      p1 <- plot_ly(data, x = ~Date, y = ~MOM, type = "scatter", mode = "lines",
                    name = paste0("Momentum(", n, ")"), line = list(color = "#3498db", width = 2)) %>%
        layout(yaxis = list(title = "Momentum"))
      p2 <- plot_ly(data, x = ~Date, y = ~ROC, type = "scatter", mode = "lines",
                    name = paste0("ROC(", n, ")"), line = list(color = "#e67e22", width = 2)) %>%
        layout(yaxis = list(title = "ROC (%)"))
      
      subplot(p1, p2, nrows = 2, shareX = TRUE, titleY = TRUE) %>%
        layout(title = paste("Momentum & Rate of Change —", data_manager$current_asset),
               plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    session$onSessionEnded(function() {})
  })
}
