# modules/volume_indicators.R

volume_indicators_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "About On-Balance Volume", status = "primary", solidHeader = TRUE, width = 12,
        tags$p(HTML(paste0(
          "<strong>On-Balance Volume (OBV)</strong> is a cumulative total: today's volume is added if the ",
          "close is higher than yesterday's, subtracted if lower, and unchanged if equal. ",
          "<strong>Weighted OBV (WOBV)</strong> scales each day's contribution by the size of the price move ",
          "(WOBV<sub>t</sub> = WOBV<sub>t-1</sub> + V<sub>t</sub> &times; (C<sub>t</sub> &minus; C<sub>t-1</sub>)), ",
          "so a large price move on high volume carries proportionally more weight than a small move on the ",
          "same volume. Both indicators aim to reveal whether volume is confirming or diverging from price."
        )), style = "font-size:12px; color:#444; line-height:1.6;")
      )
    ),
    fluidRow(
      box(
        title = "OBV & Weighted OBV", status = "primary", solidHeader = TRUE, width = 12,
        withSpinner(plotlyOutput(ns("obvChart"), height = "450px")),
        tags$p(paste0(
          "If volume data is unavailable or zero for the selected asset (common for some futures and crypto ",
          "feeds), OBV and WOBV will be flat and are not meaningful — try switching to an equity ticker."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    )
  )
}

volume_indicators_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    output$obvChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% arrange(Date)
      
      delta <- c(0, diff(data$Close))
      obv_incr  <- ifelse(delta > 0, data$Volume, ifelse(delta < 0, -data$Volume, 0))
      data$OBV  <- cumsum(ifelse(is.na(obv_incr), 0, obv_incr))
      wobv_incr <- data$Volume * delta
      data$WOBV <- cumsum(ifelse(is.na(wobv_incr), 0, wobv_incr))
      
      p1 <- plot_ly(data, x = ~Date, y = ~OBV, type = "scatter", mode = "lines",
                    name = "OBV", line = list(color = "#3498db", width = 2)) %>%
        layout(yaxis = list(title = "OBV"))
      p2 <- plot_ly(data, x = ~Date, y = ~WOBV, type = "scatter", mode = "lines",
                    name = "Weighted OBV", line = list(color = "#9b59b6", width = 2)) %>%
        layout(yaxis = list(title = "Weighted OBV"))
      
      subplot(p1, p2, nrows = 2, shareX = TRUE, titleY = TRUE) %>%
        layout(title = paste("On-Balance Volume —", data_manager$current_asset),
               plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    session$onSessionEnded(function() {})
  })
}
