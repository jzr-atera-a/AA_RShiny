analytics_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive values for transcriptions
    values <- reactiveValues(
      transcriptions = data.frame(
        timestamp = character(),
        filename = character(),
        word_count = numeric(),
        processing_time = numeric(),
        file_size = numeric(),
        stringsAsFactors = FALSE
      )
    )
    
    # Value boxes
    output$totalFiles <- renderValueBox({
      valueBox(
        value = nrow(values$transcriptions),
        subtitle = "Total Files Processed",
        icon = icon("file-audio"),
        color = "purple"
      )
    })
    
    output$totalWords <- renderValueBox({
      total_words <- sum(values$transcriptions$word_count, na.rm = TRUE)
      valueBox(
        value = total_words,
        subtitle = "Total Words Transcribed",
        icon = icon("font"),
        color = "green"
      )
    })
    
    output$avgDuration <- renderValueBox({
      avg_time <- mean(values$transcriptions$processing_time, na.rm = TRUE)
      valueBox(
        value = paste(round(avg_time, 2), "s"),
        subtitle = "Avg Processing Time",
        icon = icon("clock"),
        color = "yellow"
      )
    })
    
    # Word count plot
    output$wordCountPlot <- renderPlotly({
      req(nrow(values$transcriptions) > 0)
      
      plot_ly(
        x = seq_len(nrow(values$transcriptions)),
        y = values$transcriptions$word_count,
        type = "scatter",
        mode = "lines+markers",
        line = list(color = "#667eea"),
        marker = list(color = "#764ba2")
      ) %>%
        layout(
          title = "Word Count Over Time",
          xaxis = list(title = "File Number"),
          yaxis = list(title = "Word Count")
        )
    })
    
    # Processing time plot
    output$processingTimePlot <- renderPlotly({
      req(nrow(values$transcriptions) > 0)
      
      plot_ly(
        x = seq_len(nrow(values$transcriptions)),
        y = values$transcriptions$processing_time,
        type = "bar",
        marker = list(color = "#11998e")
      ) %>%
        layout(
          title = "Processing Time by File",
          xaxis = list(title = "File Number"),
          yaxis = list(title = "Time (seconds)")
        )
    })
    
    # History table
    output$historyTable <- DT::renderDataTable({
      req(nrow(values$transcriptions) > 0)
      DT::datatable(values$transcriptions, options = list(pageLength = 10))
    })
  })
}
