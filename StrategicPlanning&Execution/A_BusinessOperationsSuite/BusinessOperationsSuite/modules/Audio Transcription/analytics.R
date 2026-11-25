# modules/Audio Transcription/analytics.R
# Subtab: Analytics Dashboard
#
# NOTE ON FIDELITY: in the source app, api_manager$transcriptions was a plain
# (non-reactive) data.frame field, and this dashboard read it directly in each
# render*() call. Since mutating a plain R6 field doesn't invalidate any Shiny
# reactive context, the dashboard would only reflect whatever the field held
# at the moment each output first rendered - new transcriptions wouldn't show
# up without a manual page/session refresh. This version depends on
# api_manager$state_trigger_audio() (incremented by add_transcription_record()
# whenever a new row is logged), so it updates live - the same pattern already
# used elsewhere in this app (state_trigger_contacts, state_trigger_funding, etc).

analytics_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      valueBoxOutput(ns("totalFiles")),
      valueBoxOutput(ns("totalWords")),
      valueBoxOutput(ns("avgTime"))
    ),
    fluidRow(
      box(title = "Word Count Distribution", status = "primary", solidHeader = TRUE, width = 6,
          plotlyOutput(ns("wordPlot")),
          diagram_save_ui(ns("save_word"), formats = c("html", DIAGRAM_IMAGE_FORMATS, "csv"))),
      box(title = "Processing Time", status = "primary", solidHeader = TRUE, width = 6,
          plotlyOutput(ns("timePlot")),
          diagram_save_ui(ns("save_time"), formats = c("html", DIAGRAM_IMAGE_FORMATS, "csv")))
    ),
    fluidRow(
      box(title = "Transcription History", status = "info", solidHeader = TRUE, width = 12,
          DTOutput(ns("historyTable")))
    )
  )
}

analytics_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    transcriptions <- reactive({
      api_manager$state_trigger_audio()
      api_manager$transcriptions %||% api_manager$empty_transcriptions_df()
    })

    output$totalFiles <- renderValueBox({
      total <- nrow(transcriptions())
      valueBox(if (total > 0) total else "0", "Total Files", icon = icon("file-audio"), color = "purple")
    })

    output$totalWords <- renderValueBox({
      total <- sum(transcriptions()$word_count, na.rm = TRUE)
      valueBox(if (total > 0) format(total, big.mark = ",") else "0", "Total Words", icon = icon("font"), color = "green")
    })

    output$avgTime <- renderValueBox({
      avg <- mean(transcriptions()$processing_time, na.rm = TRUE)
      valueBox(if (!is.nan(avg)) paste(round(avg, 2), "s") else "0 s", "Avg Time", icon = icon("clock"), color = "yellow")
    })

    word_plot <- reactive({
      data <- transcriptions()
      if (nrow(data) > 0) {
        plot_ly(x = seq_len(nrow(data)), y = data$word_count, type = "scatter", mode = "lines+markers",
                line = list(color = "#008A82"), marker = list(color = "#00A39A")) %>%
          layout(xaxis = list(title = "File"), yaxis = list(title = "Words"))
      } else {
        plot_ly() %>% layout(annotations = list(text = "No data yet", showarrow = FALSE))
      }
    })
    output$wordPlot <- renderPlotly(word_plot())

    time_plot <- reactive({
      data <- transcriptions()
      if (nrow(data) > 0) {
        plot_ly(x = seq_len(nrow(data)), y = data$processing_time, type = "bar", marker = list(color = "#11998e")) %>%
          layout(xaxis = list(title = "File"), yaxis = list(title = "Seconds"))
      } else {
        plot_ly() %>% layout(annotations = list(text = "No data yet", showarrow = FALSE))
      }
    })
    output$timePlot <- renderPlotly(time_plot())

    # Save diagram bars (Google Drive / zip): the chart itself + the numbers behind it
    analytics_spec <- function(title, plot, sub) function() {
      d <- isolate(transcriptions())
      if (!nrow(d)) return(list(ready = FALSE, why = "No transcriptions yet - nothing to save."))
      list(title = title, subtitle = sub(d), plot = isolate(plot()), data = data.frame(file_no = seq_len(nrow(d)), as.data.frame(d), check.names = FALSE))
    }
    diagram_save_server("save_word", "analytics", session$ns("wordPlot"), "plotly",
                        analytics_spec("Word Count Distribution", word_plot, function(d) sprintf("%d file(s), %s words", nrow(d), format(sum(d$word_count, na.rm = TRUE), big.mark = ","))))
    diagram_save_server("save_time", "analytics", session$ns("timePlot"), "plotly",
                        analytics_spec("Processing Time", time_plot, function(d) sprintf("Average %.2f s per file", mean(d$processing_time, na.rm = TRUE))))

    output$historyTable <- renderDT({
      data <- transcriptions()
      if (nrow(data) > 0) datatable(data, options = list(pageLength = 10))
      else datatable(data.frame(Message = "No transcription history yet"), options = list(dom = 't'), rownames = FALSE)
    })
  })
}
