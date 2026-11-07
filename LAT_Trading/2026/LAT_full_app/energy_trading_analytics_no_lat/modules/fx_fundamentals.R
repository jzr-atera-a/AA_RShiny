# modules/fx_fundamentals.R

fx_fundamentals_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Pip Value & Margin Calculator", status = "primary", solidHeader = TRUE, width = 4,
        tags$p(HTML(paste0(
          "Currency pairs are quoted <strong>XXX/YYY</strong>, where XXX (the base currency) is priced in ",
          "units of YYY (the counter currency). A <strong>pip</strong> is typically the fourth decimal ",
          "place (second for JPY pairs). Retail FX is highly <strong>leveraged</strong> — margin is the ",
          "deposit required to control a much larger notional position."
        )), style = "font-size:12px; color:#444; line-height:1.6;"),
        selectInput(ns("fxPair"), "Currency Pair:",
                    choices = c("EUR/USD", "GBP/USD", "USD/JPY", "AUD/USD",
                                "USD/CHF", "USD/CAD", "EUR/GBP", "EUR/JPY"),
                    selected = "EUR/USD"),
        selectInput(ns("fxLotType"), "Position Size:",
                    choices = c("Standard Lot (100,000)" = "100000",
                                "Mini Lot (10,000)"      = "10000",
                                "Micro Lot (1,000)"      = "1000"),
                    selected = "100000"),
        numericInput(ns("fxLeverage"), "Leverage (e.g. 100 = 100:1):", value = 100, min = 1, max = 500, step = 1)
      ),
      box(
        title = "Calculated Exposure", status = "info", solidHeader = TRUE, width = 8,
        uiOutput(ns("fxCalcResult")),
        tags$p(paste0(
          "Pip value depends on which currency is the counter (quote) currency of the pair. Margin required ",
          "= Notional Value / Leverage. Higher leverage reduces the margin needed to control the same ",
          "notional exposure, but increases the impact of adverse price moves on the account."
        ), style = "font-size:12px; color:#666; margin:14px 0 0 0; line-height:1.5;")
      )
    ),
    fluidRow(
      box(
        title = "Cross-Rate Calculator", status = "primary", solidHeader = TRUE, width = 6,
        tags$p(HTML(paste0(
          "Currency pairs move mostly independently of one another, though pairs sharing a common currency ",
          "can be affected by the same news. This calculator reproduces the FX manual's worked example: ",
          "EUR/USD and GBP/USD (\u201cCable\u201d) are both quoted against USD, so EUR/GBP &mdash; quoted as the number ",
          "of GBP per EUR &mdash; can be derived by dividing EUR/USD by GBP/USD."
        )), style = "font-size:12px; color:#444; line-height:1.6;"),
        fluidRow(
          column(6, numericInput(ns("crEurUsdBefore"), "EUR/USD Before:", value = 1.3000, step = 0.0001)),
          column(6, numericInput(ns("crEurUsdAfter"),  "EUR/USD After:",  value = 1.3130, step = 0.0001))
        ),
        fluidRow(
          column(6, numericInput(ns("crGbpUsdBefore"), "GBP/USD Before:", value = 1.4500, step = 0.0001)),
          column(6, numericInput(ns("crGbpUsdAfter"),  "GBP/USD After:",  value = 1.4355, step = 0.0001))
        ),
        uiOutput(ns("crossRateResult"))
      ),
      box(
        title = "Global Trading Sessions (GMT)", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("fxSessionChart"), height = "380px")),
        tags$p(paste0(
          "FX trades 24 hours a day as the Asian, European, and North American sessions hand over to one ",
          "another. Overlapping sessions (e.g. London/New York) typically see the highest liquidity."
        ), style = "font-size:11px; color:#666; margin:10px 0 0 0; line-height:1.4;")
      )
    )
  )
}

fx_fundamentals_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    output$fxCalcResult <- renderUI({
      req(input$fxPair, input$fxLotType, input$fxLeverage)
      
      pair        <- input$fxPair
      lot_size    <- as.numeric(input$fxLotType)
      leverage    <- input$fxLeverage
      counter_ccy <- strsplit(pair, "/")[[1]][2]
      
      pip_size <- if (counter_ccy == "JPY") 0.01 else 0.0001
      pip_value_usd <- if (counter_ccy == "USD") {
        lot_size * pip_size
      } else if (counter_ccy == "JPY") {
        round(lot_size * pip_size / 150, 2)
      } else {
        round(lot_size * pip_size, 2)
      }
      
      notional        <- lot_size
      margin_required <- notional / leverage
      
      tagList(
        fluidRow(
          column(4, div(style = "text-align:center;", tags$h5("Notional Value"),
                        tags$h3(format(notional, big.mark = ","), style = "color:#002C3C;"))),
          column(4, div(style = "text-align:center;", tags$h5("Margin Required"),
                        tags$h3(paste0("$", format(round(margin_required, 2), big.mark = ",")), style = "color:#008A82;"))),
          column(4, div(style = "text-align:center;", tags$h5("Approx. Pip Value"),
                        tags$h3(paste0("$", pip_value_usd), style = "color:#002C3C;")))
        ),
        tags$p(paste0(
          "At ", leverage, ":1 leverage on a ", format(lot_size, big.mark = ","), "-unit position in ", pair,
          ", you control $", format(notional, big.mark = ","), " of notional exposure for a deposit of $",
          format(round(margin_required, 2), big.mark = ","), ". Pip value is illustrative and approximated to USD."
        ), style = "font-size:11px; color:#888; text-align:center; margin-top:10px; font-style:italic;")
      )
    })
    
    output$crossRateResult <- renderUI({
      req(input$crEurUsdBefore, input$crEurUsdAfter, input$crGbpUsdBefore, input$crGbpUsdAfter)
      
      eur_before <- input$crEurUsdBefore; eur_after <- input$crEurUsdAfter
      gbp_before <- input$crGbpUsdBefore; gbp_after <- input$crGbpUsdAfter
      req(gbp_before != 0, gbp_after != 0)
      
      eur_move_pct <- (eur_after - eur_before) / eur_before * 100
      gbp_move_pct <- (gbp_after - gbp_before) / gbp_before * 100
      
      eurgbp_before <- eur_before / gbp_before
      eurgbp_after  <- eur_after / gbp_after
      eurgbp_move_pct <- (eurgbp_after - eurgbp_before) / eurgbp_before * 100
      
      tagList(
        tags$hr(),
        fluidRow(
          column(4, div(style = "text-align:center;", tags$h6("EUR/USD Move"),
                        tags$h4(paste0(ifelse(eur_move_pct >= 0, "+", ""), round(eur_move_pct, 2), "%"),
                                style = paste0("color:", ifelse(eur_move_pct >= 0, "#27ae60", "#e74c3c"), ";")))),
          column(4, div(style = "text-align:center;", tags$h6("GBP/USD Move"),
                        tags$h4(paste0(ifelse(gbp_move_pct >= 0, "+", ""), round(gbp_move_pct, 2), "%"),
                                style = paste0("color:", ifelse(gbp_move_pct >= 0, "#27ae60", "#e74c3c"), ";")))),
          column(4, div(style = "text-align:center;", tags$h6("Implied EUR/GBP Move"),
                        tags$h4(paste0(ifelse(eurgbp_move_pct >= 0, "+", ""), round(eurgbp_move_pct, 2), "%"),
                                style = paste0("color:", ifelse(eurgbp_move_pct >= 0, "#27ae60", "#e74c3c"), "; font-weight:800;"))))
        ),
        div(style = "text-align:center; margin-top:8px; padding:8px; border-radius:6px; background:#f1f9f8;",
            tags$span(paste0("EUR/GBP: ", round(eurgbp_before, 4), " \u2192 ", round(eurgbp_after, 4)),
                      style = "font-size:12px; color:#002C3C; font-weight:600;")
        ),
        tags$p(paste0(
          "Because EUR/GBP is derived by dividing two USD-quoted pairs, opposing moves in EUR/USD and GBP/USD ",
          "compound rather than cancel — this is why the derived cross-rate move is often larger than either ",
          "individual pair's move."
        ), style = "font-size:11px; color:#888; font-style:italic; margin-top:8px; line-height:1.4;")
      )
    })
    
    output$fxSessionChart <- renderPlotly({
      sessions <- data.frame(
        Center = c("Sydney", "Tokyo", "Singapore/HK", "Bahrain", "Frankfurt",
                   "London", "New York", "Chicago", "San Francisco"),
        Start  = c(-2, 0, 0, 7, 7, 8, 13, 14, 15),
        End    = c(6, 9, 9, 16, 16, 17, 22, 23, 24)
      )
      sessions$Center   <- factor(sessions$Center, levels = rev(sessions$Center))
      sessions$Duration <- sessions$End - sessions$Start
      
      plot_ly(sessions, y = ~Center, x = ~Duration, base = ~Start, type = "bar", orientation = "h",
              marker = list(color = "#008A82")) %>%
        layout(
          title = "FX Trading Sessions (GMT)",
          xaxis = list(title = "GMT Hour", range = c(-2, 24), dtick = 4),
          yaxis = list(title = ""),
          plot_bgcolor = "white", paper_bgcolor = "white"
        )
    })
    
    session$onSessionEnded(function() {})
  })
}
