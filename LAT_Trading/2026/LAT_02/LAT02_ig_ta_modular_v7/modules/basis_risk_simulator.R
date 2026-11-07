# modules/basis_risk_simulator.R

basis_risk_simulator_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Short Hedge \u2014 Wheat/Barley Farmer Example", status = "primary", solidHeader = TRUE, width = 4,
        tags$p(HTML(paste0(
          "Hedging removes most price risk but not all of it, because the gap between the futures price and ",
          "cash price (the <strong>basis</strong>) is not guaranteed to stay constant. This simulator ",
          "reproduces the manual's farmer example: production cost \u00a370/tonne, short hedge sold at \u00a380/tonne."
        )), style = "font-size:12px; color:#444; line-height:1.6;"),
        numericInput(ns("basisProductionCost"), "Production Cost (\u00a3/tonne):", value = 70, min = 0, step = 1),
        numericInput(ns("basisFuturesEntry"), "Futures Entry (Short Sale) Price:", value = 80, min = 0, step = 1),
        tags$hr(),
        radioButtons(ns("basisScenario"), "Scenario:",
                     choices = c("Basis Unchanged (Perfect Hedge)" = "unchanged",
                                 "Basis Weakens"                   = "weakens",
                                 "Basis Strengthens"                = "strengthens",
                                 "Custom"                            = "custom"),
                     selected = "unchanged"),
        numericInput(ns("basisCashSale"), "Cash Price at Sale:", value = 60, min = 0, step = 1),
        numericInput(ns("basisFuturesClose"), "Futures Price at Close:", value = 70, min = 0, step = 1)
      ),
      box(
        title = "Outcome", status = "info", solidHeader = TRUE, width = 8,
        uiOutput(ns("basisRiskResult")),
        tags$hr(),
        withSpinner(plotlyOutput(ns("basisRiskChart"), height = "320px")),
        tags$p(paste0(
          "Conclusion from the manual: for a short hedge, a strengthening basis produces a gain and a ",
          "weakening basis produces a loss (the mirror image applies to a long hedge). Basis risk is why ",
          "hedging reduces, but never fully eliminates, price risk."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    )
  )
}

basis_risk_simulator_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$basisScenario, {
      vals <- switch(input$basisScenario,
        unchanged   = list(cash = 60, futures = 70),
        weakens     = list(cash = 60, futures = 71),
        strengthens = list(cash = 60, futures = 69),
        custom      = NULL
      )
      if (!is.null(vals)) {
        updateNumericInput(session, "basisCashSale", value = vals$cash)
        updateNumericInput(session, "basisFuturesClose", value = vals$futures)
      }
    }, ignoreInit = TRUE)
    
    basis_outcome <- reactive({
      req(input$basisProductionCost, input$basisFuturesEntry, input$basisCashSale, input$basisFuturesClose)
      
      cash_pnl    <- input$basisCashSale - input$basisProductionCost
      futures_pnl <- input$basisFuturesEntry - input$basisFuturesClose
      net_pnl     <- cash_pnl + futures_pnl
      basis_t1    <- input$basisCashSale - input$basisFuturesClose
      
      classification <- if (net_pnl > 0) "Basis Strengthened (net gain on the short hedge)"
                         else if (net_pnl < 0) "Basis Weakened (net loss on the short hedge)"
                         else "Basis Unchanged (perfect hedge \u2014 loss on cash exactly offset by futures profit)"
      class_color <- if (net_pnl > 0) "#27ae60" else if (net_pnl < 0) "#e74c3c" else "#7f8c8d"
      
      list(cash_pnl = cash_pnl, futures_pnl = futures_pnl, net_pnl = net_pnl,
           basis_t1 = basis_t1, classification = classification, class_color = class_color)
    })
    
    output$basisRiskResult <- renderUI({
      bo <- basis_outcome()
      
      tagList(
        fluidRow(
          column(3, div(style = "text-align:center; padding:8px;",
                        tags$div("Cash P&L (per tonne)", style = "font-size:11px; color:#666;"),
                        tags$h4(paste0("\u00a3", round(bo$cash_pnl, 2)), style = "color:#e74c3c; margin:2px 0;"))),
          column(3, div(style = "text-align:center; padding:8px;",
                        tags$div("Futures P&L (per tonne)", style = "font-size:11px; color:#666;"),
                        tags$h4(paste0("\u00a3", round(bo$futures_pnl, 2)), style = "color:#27ae60; margin:2px 0;"))),
          column(3, div(style = "text-align:center; padding:8px;",
                        tags$div("Net P&L (per tonne)", style = "font-size:11px; color:#666;"),
                        tags$h4(paste0("\u00a3", round(bo$net_pnl, 2)),
                                style = paste0("color:", bo$class_color, "; margin:2px 0; font-weight:800;")))),
          column(3, div(style = "text-align:center; padding:8px;",
                        tags$div("Basis at Sale (Cash \u2212 Futures)", style = "font-size:11px; color:#666;"),
                        tags$h4(round(bo$basis_t1, 2), style = "color:#002C3C; margin:2px 0;")))
        ),
        div(style = paste0("text-align:center; margin-top:10px; padding:10px; border-radius:8px; background:", bo$class_color, "22;"),
            tags$strong(bo$classification, style = paste0("color:", bo$class_color, "; font-size:13px;"))
        )
      )
    })
    
    output$basisRiskChart <- renderPlotly({
      bo <- basis_outcome()
      
      df <- data.frame(
        Component = factor(c("Cash P&L", "Futures P&L", "Net P&L"), levels = c("Cash P&L", "Futures P&L", "Net P&L")),
        Value = c(bo$cash_pnl, bo$futures_pnl, bo$net_pnl)
      )
      df$Color <- ifelse(df$Value >= 0, "#27ae60", "#e74c3c")
      
      plot_ly(df, x = ~Component, y = ~Value, type = "bar", marker = list(color = ~Color)) %>%
        layout(
          title = "Cash vs Futures vs Net Outcome (per tonne)",
          xaxis = list(title = ""),
          yaxis = list(title = "\u00a3 per tonne"),
          shapes = list(list(type = "line", x0 = -0.5, x1 = 2.5, y0 = 0, y1 = 0,
                              line = list(color = "#bdc3c7", width = 1, dash = "dash"))),
          plot_bgcolor = "white", paper_bgcolor = "white"
        )
    })
    
    session$onSessionEnded(function() {})
  })
}
