# modules/hedge_ratio_calculator.R

hedge_ratio_calculator_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Short Hedge \u2014 Protecting a Portfolio", status = "primary", solidHeader = TRUE, width = 4,
        tags$p(HTML(paste0(
          "A <strong>short hedge</strong> removes the uncertainty of owning an asset by selling futures ",
          "against it: if the market falls, losses on the portfolio are offset by profits on the short ",
          "futures position. The number of contracts needed is the <strong>hedge ratio</strong>:"
        )), style = "font-size:12px; color:#444; line-height:1.6;"),
        div(style = "background:#f1f9f8; border-radius:8px; padding:10px; text-align:center; margin-bottom:12px;",
            tags$code("Hedge Ratio = Value of Exposure / (Spot Level \u00d7 Index Point Value)",
                      style = "font-size:11.5px; color:#002C3C;")
        ),
        numericInput(ns("hedgePortfolioValue"), "Portfolio Value (\u00a3):", value = 110000, min = 0, step = 1000),
        numericInput(ns("hedgeSpotLevel"), "Current Index/Spot Level:", value = 5300, min = 0.01, step = 1),
        numericInput(ns("hedgeFuturesPrice"), "Futures Price:", value = 5310, min = 0.01, step = 1),
        numericInput(ns("hedgePointValue"), "Index Point Value (\u00a3):", value = 10, min = 0.01, step = 0.5),
        tags$p("Defaults reproduce the manual's FTSE 100 example: a \u00a3110,000 portfolio hedged with the index at 5300 and the future at 5310.",
               style = "font-size:10.5px; color:#888; font-style:italic;")
      ),
      box(
        title = "Hedge Ratio", status = "info", solidHeader = TRUE, width = 8,
        uiOutput(ns("hedgeRatioResult")),
        tags$hr(),
        tags$h5("Simulate the Outcome at Expiry", style = "color:#002C3C;"),
        numericInput(ns("hedgeEDSP"), "Exchange Delivery Settlement Price (EDSP):", value = 5061, min = 0.01, step = 1),
        uiOutput(ns("hedgeOutcomeResult")),
        tags$p(paste0(
          "The Exchange Delivery Settlement Price (EDSP) is the final price the futures contract settles ",
          "against at expiry. With defaults unchanged, this reproduces the manual's outcome almost exactly: ",
          "roughly \u00a34,950\u2013\u00a34,960 portfolio loss offset by \u00a34,980 futures profit \u2014 a near-fully hedged position ",
          "with a small residual gain."
        ), style = "font-size:11px; color:#888; font-style:italic; margin-top:10px; line-height:1.5;")
      )
    )
  )
}

hedge_ratio_calculator_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    hedge_ratio <- reactive({
      req(input$hedgePortfolioValue, input$hedgeSpotLevel, input$hedgePointValue)
      req(input$hedgeSpotLevel > 0, input$hedgePointValue > 0)
      raw <- input$hedgePortfolioValue / (input$hedgeSpotLevel * input$hedgePointValue)
      list(raw = raw, contracts = round(raw))
    })
    
    output$hedgeRatioResult <- renderUI({
      hr <- hedge_ratio()
      req(input$hedgeSpotLevel, input$hedgePointValue)
      
      tagList(
        fluidRow(
          column(4, div(style = "text-align:center;", tags$h5("Value of Exposure"),
                        tags$h3(paste0("\u00a3", format(input$hedgePortfolioValue, big.mark = ",")), style = "color:#002C3C;"))),
          column(4, div(style = "text-align:center;", tags$h5("Contract Value"),
                        tags$h3(paste0("\u00a3", format(round(input$hedgeSpotLevel * input$hedgePointValue), big.mark = ",")),
                                style = "color:#002C3C;"))),
          column(4, div(style = "text-align:center;", tags$h5("Hedge Ratio"),
                        tags$h3(round(hr$raw, 3), style = "color:#008A82;")))
        ),
        div(style = "text-align:center; margin-top:8px; padding:10px; border-radius:8px; background:#e8f6f5;",
            tags$strong(paste0("Sell ", hr$contracts, " futures contract", if (hr$contracts != 1) "s" else "",
                               " to hedge this portfolio."),
                       style = "color:#002C3C; font-size:14px;")
        )
      )
    })
    
    output$hedgeOutcomeResult <- renderUI({
      hr <- hedge_ratio()
      req(input$hedgeEDSP, input$hedgeSpotLevel, input$hedgeFuturesPrice, input$hedgePointValue, input$hedgePortfolioValue)
      
      pct_change     <- (input$hedgeEDSP - input$hedgeSpotLevel) / input$hedgeSpotLevel
      portfolio_pnl  <- input$hedgePortfolioValue * pct_change
      futures_pnl    <- (input$hedgeFuturesPrice - input$hedgeEDSP) * hr$contracts * input$hedgePointValue
      net_pnl        <- portfolio_pnl + futures_pnl
      
      net_color <- if (net_pnl >= 0) "#27ae60" else "#e74c3c"
      
      tagList(
        fluidRow(
          column(4, div(style = "text-align:center; padding:8px;",
                        tags$div("Portfolio P&L", style = "font-size:11px; color:#666;"),
                        tags$h4(paste0("\u00a3", format(round(portfolio_pnl), big.mark = ",")),
                                style = "color:#e74c3c; margin:2px 0;"))),
          column(4, div(style = "text-align:center; padding:8px;",
                        tags$div("Futures P&L", style = "font-size:11px; color:#666;"),
                        tags$h4(paste0("\u00a3", format(round(futures_pnl), big.mark = ",")),
                                style = "color:#27ae60; margin:2px 0;"))),
          column(4, div(style = "text-align:center; padding:8px; background:#f7fbfb; border-radius:8px;",
                        tags$div("Net Outcome", style = "font-size:11px; color:#666;"),
                        tags$h4(paste0("\u00a3", format(round(net_pnl), big.mark = ",")),
                                style = paste0("color:", net_color, "; margin:2px 0; font-weight:800;"))))
        )
      )
    })
    
    session$onSessionEnded(function() {})
  })
}
