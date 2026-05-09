analytics_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    output$totalFiles <- renderValueBox({
      total <- nrow(api_manager$transcriptions)
      valueBox(if(total > 0) total else "0", "Total Files", icon = icon("file-audio"), color = "purple")
    })
    
    output$totalWords <- renderValueBox({
      total <- sum(api_manager$transcriptions$word_count, na.rm = TRUE)
      valueBox(if(total > 0) format(total, big.mark = ",") else "0", "Total Words", icon = icon("font"), color = "green")
    })
    
    output$avgTime <- renderValueBox({
      avg <- mean(api_manager$transcriptions$processing_time, na.rm = TRUE)
      valueBox(if(!is.nan(avg)) paste(round(avg, 2), "s") else "0 s", "Avg Time", icon = icon("clock"), color = "yellow")
    })
    
    output$wordPlot <- renderPlotly({
      if (nrow(api_manager$transcriptions) > 0) {
        plot_ly(
          x = seq_len(nrow(api_manager$transcriptions)),
          y = api_manager$transcriptions$word_count,
          type = "scatter",
          mode = "lines+markers",
          line = list(color = "#667eea"),
          marker = list(color = "#764ba2")
        ) %>% layout(xaxis = list(title = "File"), yaxis = list(title = "Words"))
      } else {
        plot_ly() %>% layout(annotations = list(text = "No data yet", showarrow = FALSE))
      }
    })
    
    output$timePlot <- renderPlotly({
      if (nrow(api_manager$transcriptions) > 0) {
        plot_ly(
          x = seq_len(nrow(api_manager$transcriptions)),
          y = api_manager$transcriptions$processing_time,
          type = "bar",
          marker = list(color = "#11998e")
        ) %>% layout(xaxis = list(title = "File"), yaxis = list(title = "Seconds"))
      } else {
        plot_ly() %>% layout(annotations = list(text = "No data yet", showarrow = FALSE))
      }
    })
    
    output$historyTable <- renderDT({
      if (nrow(api_manager$transcriptions) > 0) {
        datatable(api_manager$transcriptions, options = list(pageLength = 10))
      } else {
        datatable(data.frame(Message = "No transcription history yet"), options = list(dom = 't'), rownames = FALSE)
      }
    })
  })
}