# modules/parabolic_sar.R

parabolic_sar_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Configuration", status = "primary", solidHeader = TRUE, width = 3,
        tags$p(HTML(paste0(
          "Wilder's <strong>Parabolic SAR</strong> (Stop and Reverse) trails price to flag potential trend ",
          "reversals. SAR<sub>t</sub> = SAR<sub>t-1</sub> + &alpha;(EP &minus; SAR<sub>t-1</sub>), where EP is ",
          "the Extreme Point of the current trend and &alpha; is an acceleration factor that increases each ",
          "time a new extreme is reached, up to a maximum."
        )), style = "font-size:12px; color:#444; line-height:1.6;"),
        numericInput(ns("sarAccelStart"), "Acceleration Start:", value = 0.02, min = 0.01, max = 0.2, step = 0.01),
        numericInput(ns("sarAccelMax"), "Acceleration Max:", value = 0.2, min = 0.05, max = 0.5, step = 0.01)
      ),
      box(
        title = "Price with Parabolic SAR", status = "primary", solidHeader = TRUE, width = 9,
        withSpinner(plotlyOutput(ns("sarChart"), height = "450px")),
        tags$p(paste0(
          "SAR dots plotted below price indicate an uptrend (potential long bias); dots above price indicate ",
          "a downtrend. A flip from below to above price (or vice versa) is the 'stop and reverse' signal."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    )
  )
}

parabolic_sar_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    output$sarChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data, input$sarAccelStart, input$sarAccelMax)
      data <- data %>% arrange(Date)
      req(nrow(data) > 5)
      
      hl <- data.frame(High = data$High, Low = data$Low)
      sar_vals <- tryCatch(
        SAR(hl, accel = c(input$sarAccelStart, input$sarAccelMax)),
        error = function(e) rep(NA_real_, nrow(data))
      )
      data$SAR <- as.numeric(sar_vals)
      
      plot_ly() %>%
        add_trace(data = data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                  name = "Close", line = list(color = "#002C3C", width = 1.5)) %>%
        add_trace(data = data, x = ~Date, y = ~SAR, type = "scatter", mode = "markers",
                  name = "Parabolic SAR", marker = list(color = "#e67e22", size = 4)) %>%
        layout(
          title = paste("Parabolic SAR —", data_manager$current_asset),
          xaxis = list(title = "Date"), yaxis = list(title = "Price"),
          plot_bgcolor = "white", paper_bgcolor = "white"
        )
    })
    
    session$onSessionEnded(function() {})
  })
}
