# modules/moving_averages.R

moving_averages_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "warning",
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$strong("About this tab:", style = "color:#7d4a00; font-size:14px;"),
            tags$p("Part of the Technical Analysis Indicator Formulae reference manual, computed live from the asset currently selected in the sidebar.",
                   style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    fluidRow(
      box(
        title = "Configuration", status = "primary", solidHeader = TRUE, width = 3,
        tags$p(HTML(paste0(
          "<strong>SMA</strong> weights every price in the window equally. <strong>WMA</strong> applies ",
          "linearly increasing weights, favouring recent prices. <strong>EMA</strong> applies exponentially ",
          "decaying weights via EMA<sub>t</sub> = EMA<sub>t-1</sub> + (C<sub>t</sub> &minus; EMA<sub>t-1</sub>) ",
          "&times; 2/(n+1), making it the most responsive of the three to new information."
        )), style = "font-size:12px; color:#444; line-height:1.6;"),
        numericInput(ns("maPeriod"), "Period (n):", value = 20, min = 2, max = 200, step = 1),
        checkboxGroupInput(ns("maTypes"), "Show:",
                           choices = c("SMA" = "sma", "WMA" = "wma", "EMA" = "ema"),
                           selected = c("sma", "wma", "ema"))
      ),
      box(
        title = "Moving Average Comparison", status = "primary", solidHeader = TRUE, width = 9,
        withSpinner(plotlyOutput(ns("maComparisonChart"), height = "450px")),
        tags$p(paste0(
          "All three moving averages use the same lookback period, so any separation between the lines is ",
          "purely a function of how they weight recent versus older prices. EMA typically hugs price most ",
          "closely; SMA the least."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    )
  )
}

moving_averages_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    output$maComparisonChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data, input$maPeriod)
      data <- data %>% arrange(Date)
      n <- input$maPeriod
      req(nrow(data) > n)
      
      p <- plot_ly() %>%
        add_trace(x = data$Date, y = data$Close, type = "scatter", mode = "lines",
                  name = "Close", line = list(color = "#95a5a6", width = 1.5))
      
      if ("sma" %in% input$maTypes) {
        p <- p %>% add_trace(x = data$Date, y = as.numeric(SMA(data$Close, n = n)), type = "scatter", mode = "lines",
                              name = paste0("SMA(", n, ")"), line = list(color = "#3498db", width = 2))
      }
      if ("wma" %in% input$maTypes) {
        p <- p %>% add_trace(x = data$Date, y = as.numeric(WMA(data$Close, n = n)), type = "scatter", mode = "lines",
                              name = paste0("WMA(", n, ")"), line = list(color = "#f39c12", width = 2))
      }
      if ("ema" %in% input$maTypes) {
        p <- p %>% add_trace(x = data$Date, y = as.numeric(EMA(data$Close, n = n)), type = "scatter", mode = "lines",
                              name = paste0("EMA(", n, ")"), line = list(color = "#e74c3c", width = 2))
      }
      
      p %>% layout(
        title = paste("Moving Average Comparison —", data_manager$current_asset),
        xaxis = list(title = "Date"), yaxis = list(title = "Price"),
        plot_bgcolor = "white", paper_bgcolor = "white"
      )
    })
    
    session$onSessionEnded(function() {})
  })
}
