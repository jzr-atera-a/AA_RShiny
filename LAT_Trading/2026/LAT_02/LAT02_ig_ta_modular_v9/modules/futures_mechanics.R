# modules/futures_mechanics.R

futures_mechanics_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Long vs Short Futures Position", status = "primary", solidHeader = TRUE, width = 4,
        tags$p(HTML(paste0(
          "A <strong>futures contract</strong> is a binding agreement to buy (long) or sell (short) an ",
          "underlying asset at an agreed price on a future date. A <strong>long</strong> position profits ",
          "if the price rises above the entry price at expiry; a <strong>short</strong> position profits ",
          "if the price falls below it. The two profiles are exact mirror images — maximum gain for one ",
          "equals maximum loss for the other, which is why futures are described as a zero-sum game."
        )), style = "font-size:13px; color:#444; line-height:1.7;"),
        numericInput(ns("futuresEntryPrice"), "Entry / Agreed Price:", value = 100, min = 0.01, step = 0.01),
        tags$p("Defaults to the current asset's latest close price and updates automatically when you change asset in the sidebar.",
               style = "font-size:11px; color:#888; font-style:italic;")
      ),
      box(
        title = "Profit & Loss at Expiry", status = "primary", solidHeader = TRUE, width = 8,
        withSpinner(plotlyOutput(ns("futuresPnLChart"), height = "400px")),
        tags$p(paste0(
          "The diagonal lines show profit/loss per unit at expiry across a range of underlying prices. ",
          "Long (green) has unlimited upside and downside capped at the entry price; short (red) has the ",
          "opposite profile — capped gain, unlimited loss."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    fluidRow(
      box(
        title = "Position Summary", status = "info", solidHeader = TRUE, width = 12,
        withSpinner(DT::dataTableOutput(ns("futuresPnLSummaryTable")))
      )
    )
  )
}

futures_mechanics_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(data_manager$state_trigger(), {
      data <- data_manager$get_data()
      req(data)
      latest_close <- round(tail(data$Close, 1), 4)
      if (!is.na(latest_close) && latest_close > 0) {
        updateNumericInput(session, "futuresEntryPrice", value = latest_close)
      }
    })
    
    output$futuresPnLChart <- renderPlotly({
      req(input$futuresEntryPrice)
      entry <- input$futuresEntryPrice
      price_range <- seq(entry * 0.7, entry * 1.3, length.out = 100)
      long_pnl  <- price_range - entry
      short_pnl <- entry - price_range
      
      plot_ly() %>%
        add_trace(x = price_range, y = long_pnl, type = "scatter", mode = "lines",
                  name = "Long Futures", line = list(color = "#27ae60", width = 3)) %>%
        add_trace(x = price_range, y = short_pnl, type = "scatter", mode = "lines",
                  name = "Short Futures", line = list(color = "#e74c3c", width = 3)) %>%
        layout(
          title = "Futures P&L at Expiry",
          xaxis = list(title = "Underlying Price at Expiry"),
          yaxis = list(title = "Profit / Loss per Unit"),
          shapes = list(
            list(type = "line", x0 = min(price_range), x1 = max(price_range), y0 = 0, y1 = 0,
                 line = list(color = "#bdc3c7", width = 1, dash = "dash")),
            list(type = "line", x0 = entry, x1 = entry,
                 y0 = min(c(long_pnl, short_pnl)), y1 = max(c(long_pnl, short_pnl)),
                 line = list(color = "#7f8c8d", width = 1, dash = "dot"))
          ),
          plot_bgcolor = "white", paper_bgcolor = "white"
        )
    })
    
    output$futuresPnLSummaryTable <- renderDT({
      req(input$futuresEntryPrice)
      entry <- round(input$futuresEntryPrice, 2)
      df <- data.frame(
        Position   = c("Long Futures", "Short Futures"),
        `Max Gain` = c("Unlimited", paste0("Limited to entry price (", entry, ")")),
        `Max Loss` = c(paste0("Limited to entry price (", entry, ")"), "Unlimited"),
        Breakeven  = c(entry, entry),
        check.names = FALSE
      )
      datatable(df, options = list(dom = 't'), rownames = FALSE)
    })
    
    session$onSessionEnded(function() {})
  })
}
