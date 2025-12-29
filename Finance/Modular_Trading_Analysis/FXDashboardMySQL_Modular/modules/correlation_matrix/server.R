correlation_matrix_server <- function(id, shared_values) {
  moduleServer(id, function(input, output, session) {
    
    output$dataLoaded <- reactive({
      !is.null(shared_values$fx_data) && 
        shared_values$data_loaded && 
        shared_values$source_table == "daily"
    })
    outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
    
    output$corrHeatmap <- renderPlotly({
      req(shared_values$data_loaded)
      req(shared_values$source_table == "daily")
      
      data <- shared_values$fx_data %>%
        select(Date, CurrencyPair, Mid) %>%
        pivot_wider(names_from = CurrencyPair, values_from = Mid)
      
      price_matrix <- as.matrix(data[, -1])
      returns_matrix <- apply(price_matrix, 2, function(x) diff(x) / x[-length(x)])
      corr_matrix <- cor(returns_matrix, use = "pairwise.complete.obs")
      
      plot_ly(z = corr_matrix, 
              x = colnames(corr_matrix), 
              y = rownames(corr_matrix), 
              type = "heatmap",
              colorscale = list(c(0, "rgb(228,26,28)"), 
                               c(0.5, "rgb(255,255,255)"), 
                               c(1, "rgb(0,163,154)"))) %>%
        layout(title = "Correlation Matrix",
               xaxis = list(title = ""),
               yaxis = list(title = ""))
    })
  })
}
