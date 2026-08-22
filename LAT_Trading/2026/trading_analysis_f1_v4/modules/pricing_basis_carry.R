# modules/pricing_basis_carry.R

pricing_basis_carry_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Fair Value Calculator", status = "primary", solidHeader = TRUE, width = 4,
        tags$p(HTML(paste0(
          "<strong>Fair value = Cash price + Net cost of carry.</strong> Cost of carry includes lost ",
          "interest and storage/insurance costs, less any benefit of holding the asset (e.g. dividend or ",
          "convenience yield). When a future trades above fair value, a <strong>Cash &amp; Carry</strong> ",
          "arbitrage is possible; below fair value, a <strong>Reverse Cash &amp; Carry</strong> arbitrage ",
          "is possible. As expiry nears, cost of carry shrinks to zero and cash/futures prices <em>converge</em>."
        )), style = "font-size:12px; color:#444; line-height:1.6;"),
        numericInput(ns("fvCashPrice"), "Cash / Spot Price:", value = 100, min = 0.01, step = 0.01),
        numericInput(ns("fvInterestRate"), "Interest Rate (% p.a.):", value = 5, min = 0, max = 30, step = 0.25),
        numericInput(ns("fvStorageCost"), "Storage/Insurance (absolute, over period):", value = 0, min = 0, step = 0.1),
        numericInput(ns("fvDividendYield"), "Dividend/Convenience Yield (% p.a.):", value = 0, min = 0, max = 30, step = 0.25),
        numericInput(ns("fvDaysToExpiry"), "Days to Expiry:", value = 90, min = 1, max = 720, step = 1)
      ),
      box(
        title = "Fair Value, Basis & Market State", status = "info", solidHeader = TRUE, width = 8,
        uiOutput(ns("fairValueResult")),
        tags$hr(),
        withSpinner(plotlyOutput(ns("convergenceChart"), height = "300px")),
        tags$p(paste0(
          "Convergence: as time to expiry falls to zero, the cost of carry falls to zero and the future's ",
          "price converges onto the cash price. This chart assumes the cash price itself stays constant."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    )
  )
}

pricing_basis_carry_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(data_manager$state_trigger(), {
      data <- data_manager$get_data()
      req(data)
      latest_close <- round(tail(data$Close, 1), 4)
      if (!is.na(latest_close) && latest_close > 0) {
        updateNumericInput(session, "fvCashPrice", value = latest_close)
      }
    })
    
    output$fairValueResult <- renderUI({
      req(input$fvCashPrice, input$fvInterestRate, input$fvDaysToExpiry)
      
      cash     <- input$fvCashPrice
      rate     <- input$fvInterestRate / 100
      storage  <- if (is.null(input$fvStorageCost)) 0 else input$fvStorageCost
      div_yld  <- (if (is.null(input$fvDividendYield)) 0 else input$fvDividendYield) / 100
      days     <- input$fvDaysToExpiry
      
      lost_interest     <- cash * rate * (days / 365)
      dividend_benefit  <- cash * div_yld * (days / 365)
      net_cost_of_carry <- lost_interest + storage - dividend_benefit
      fair_value        <- cash + net_cost_of_carry
      basis             <- cash - fair_value
      
      state <- if (net_cost_of_carry > 0) "Contango (basis negative)" else
               if (net_cost_of_carry < 0) "Backwardation (basis positive)" else "At Fair Value"
      state_color <- if (net_cost_of_carry > 0) "#008A82" else
                     if (net_cost_of_carry < 0) "#e67e22" else "#7f8c8d"
      
      tagList(
        fluidRow(
          column(4, div(style = "text-align:center;", tags$h5("Cost of Carry"),
                        tags$h3(round(net_cost_of_carry, 4), style = paste0("color:", state_color, ";")))),
          column(4, div(style = "text-align:center;", tags$h5("Fair Value"),
                        tags$h3(round(fair_value, 4), style = "color:#002C3C;"))),
          column(4, div(style = "text-align:center;", tags$h5("Basis"),
                        tags$h3(round(basis, 4), style = "color:#002C3C;")))
        ),
        div(style = paste0("text-align:center; margin-top:10px; padding:10px; border-radius:8px; background:", state_color, "22;"),
            tags$strong(paste("Market State:", state), style = paste0("color:", state_color, ";"))
        )
      )
    })
    
    output$convergenceChart <- renderPlotly({
      req(input$fvCashPrice, input$fvInterestRate, input$fvDaysToExpiry)
      cash       <- input$fvCashPrice
      rate       <- input$fvInterestRate / 100
      storage    <- if (is.null(input$fvStorageCost)) 0 else input$fvStorageCost
      div_yld    <- (if (is.null(input$fvDividendYield)) 0 else input$fvDividendYield) / 100
      total_days <- max(input$fvDaysToExpiry, 1)
      
      days_remaining <- seq(total_days, 0, length.out = 50)
      carry <- cash * rate * (days_remaining / 365) +
               storage * (days_remaining / total_days) -
               cash * div_yld * (days_remaining / 365)
      future_price <- cash + carry
      
      plot_ly() %>%
        add_trace(x = total_days - days_remaining, y = future_price, type = "scatter", mode = "lines",
                  name = "Future's Fair Value", line = list(color = "#008A82", width = 3)) %>%
        add_trace(x = c(0, total_days), y = c(cash, cash), type = "scatter", mode = "lines",
                  name = "Constant Cash Price", line = list(color = "#e67e22", width = 2, dash = "dash")) %>%
        layout(title = "Convergence to Expiry",
               xaxis = list(title = "Days Elapsed"), yaxis = list(title = "Price"),
               plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    session$onSessionEnded(function() {})
  })
}
