# modules/options_pnl.R

options_pnl_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Options Configuration", status = "primary", solidHeader = TRUE, width = 4,
        tags$p(HTML(paste0(
          "An <strong>option</strong> gives the buyer the right, but not the obligation, to buy (call) or ",
          "sell (put) the underlying at the <strong>strike price</strong> on or before expiry, in exchange ",
          "for a <strong>premium</strong> paid to the seller (writer). The four basic positions — long call, ",
          "short call, long put, short put — each carry a distinct risk/reward profile."
        )), style = "font-size:12px; color:#444; line-height:1.6;"),
        radioButtons(ns("optType"), "Position:",
                     choices = c("Long Call (Bullish)"          = "long_call",
                                 "Short Call (Bearish/Neutral)" = "short_call",
                                 "Long Put (Bearish)"           = "long_put",
                                 "Short Put (Bullish/Neutral)"  = "short_put",
                                 "All Four Positions"           = "all_four"),
                     selected = "long_call"),
        numericInput(ns("optStrike"), "Strike Price:", value = 100, min = 0.01, step = 0.01),
        numericInput(ns("optPremium"), "Premium:", value = 5, min = 0.01, step = 0.01)
      ),
      box(
        title = "Payoff Diagram at Expiry", status = "primary", solidHeader = TRUE, width = 8,
        withSpinner(plotlyOutput(ns("optionsPnLChart"), height = "400px")),
        tags$p(paste0(
          "Buying options (long call/long put) caps the maximum loss at the premium paid, while the seller ",
          "on the other side of the trade carries the mirror-image, and typically larger, risk."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    fluidRow(
      box(
        title = "Max Gain / Max Loss / Breakeven", status = "info", solidHeader = TRUE, width = 7,
        withSpinner(DT::dataTableOutput(ns("optionsSummaryTable")))
      ),
      box(
        title = "Contingent Liability Classifier", status = "info", solidHeader = TRUE, width = 5,
        tags$p(HTML(paste0(
          "A <strong>contingent liability transaction</strong> is a derivative position where the investor ",
          "may lose more money than originally invested. Selling/writing options and all futures positions ",
          "are contingent liability transactions; buying/holding options is not, since the maximum loss is ",
          "capped at the premium paid."
        )), style = "font-size:11.5px; color:#444; line-height:1.6;"),
        uiOutput(ns("contingentLiabilityResult"))
      )
    )
  )
}

options_pnl_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(data_manager$state_trigger(), {
      data <- data_manager$get_data()
      req(data)
      latest_close <- round(tail(data$Close, 1), 4)
      if (!is.na(latest_close) && latest_close > 0) {
        updateNumericInput(session, "optStrike", value = latest_close)
        updateNumericInput(session, "optPremium", value = round(latest_close * 0.05, 4))
      }
    })
    
    options_payoff <- function(S, K, premium, type) {
      switch(type,
        long_call  = pmax(S - K, 0) - premium,
        short_call = premium - pmax(S - K, 0),
        long_put   = pmax(K - S, 0) - premium,
        short_put  = premium - pmax(K - S, 0)
      )
    }
    
    output$optionsPnLChart <- renderPlotly({
      req(input$optStrike, input$optPremium, input$optType)
      K <- input$optStrike
      premium <- input$optPremium
      S <- seq(K * 0.5, K * 1.5, length.out = 150)
      
      types_to_plot <- if (input$optType == "all_four") {
        c("long_call", "short_call", "long_put", "short_put")
      } else {
        input$optType
      }
      
      labels <- c(long_call = "Long Call", short_call = "Short Call",
                  long_put = "Long Put", short_put = "Short Put")
      colors <- c(long_call = "#27ae60", short_call = "#e74c3c",
                  long_put = "#3498db", short_put = "#9b59b6")
      
      p <- plot_ly()
      for (t in types_to_plot) {
        payoff <- options_payoff(S, K, premium, t)
        p <- p %>% add_trace(x = S, y = payoff, type = "scatter", mode = "lines",
                              name = labels[[t]], line = list(color = colors[[t]], width = 3))
      }
      p %>% layout(
        title = "Option Payoff at Expiry",
        xaxis = list(title = "Underlying Price at Expiry"),
        yaxis = list(title = "Profit / Loss"),
        shapes = list(
          list(type = "line", x0 = min(S), x1 = max(S), y0 = 0, y1 = 0,
               line = list(color = "#bdc3c7", width = 1, dash = "dash")),
          list(type = "line", x0 = K, x1 = K, y0 = -premium * 3, y1 = premium * 3,
               line = list(color = "#95a5a6", width = 1, dash = "dot"))
        ),
        plot_bgcolor = "white", paper_bgcolor = "white"
      )
    })
    
    output$optionsSummaryTable <- renderDT({
      req(input$optStrike, input$optPremium, input$optType)
      K <- input$optStrike
      premium <- input$optPremium
      
      types_to_plot <- if (input$optType == "all_four") {
        c("long_call", "short_call", "long_put", "short_put")
      } else {
        input$optType
      }
      
      labels    <- c(long_call = "Long Call", short_call = "Short Call",
                     long_put = "Long Put", short_put = "Short Put")
      strategy  <- c(long_call = "Bullish", short_call = "Bearish/Neutral",
                     long_put = "Bearish", short_put = "Bullish/Neutral")
      max_loss  <- c(long_call = as.character(round(premium, 2)), short_call = "Unlimited",
                     long_put = as.character(round(premium, 2)), short_put = as.character(round(K - premium, 2)))
      max_gain  <- c(long_call = "Unlimited", short_call = as.character(round(premium, 2)),
                     long_put = as.character(round(K - premium, 2)), short_put = as.character(round(premium, 2)))
      breakeven <- c(long_call = as.character(round(K + premium, 2)), short_call = as.character(round(K + premium, 2)),
                     long_put = as.character(round(K - premium, 2)), short_put = as.character(round(K - premium, 2)))
      
      df <- data.frame(
        Position    = unname(labels[types_to_plot]),
        Strategy    = unname(strategy[types_to_plot]),
        `Max Loss`  = unname(max_loss[types_to_plot]),
        `Max Gain`  = unname(max_gain[types_to_plot]),
        Breakeven   = unname(breakeven[types_to_plot]),
        check.names = FALSE
      )
      datatable(df, options = list(dom = 't'), rownames = FALSE)
    })
    
    output$contingentLiabilityResult <- renderUI({
      req(input$optType)
      
      is_liability <- c(long_call = FALSE, short_call = TRUE, long_put = FALSE, short_put = TRUE)
      labels <- c(long_call = "Long Call", short_call = "Short Call",
                  long_put = "Long Put", short_put = "Short Put")
      
      types <- if (input$optType == "all_four") names(is_liability) else input$optType
      
      rows <- lapply(types, function(t) {
        liable <- is_liability[[t]]
        col <- if (liable) "#e74c3c" else "#27ae60"
        div(style = paste0("display:flex; justify-content:space-between; align-items:center; padding:8px 10px; ",
                            "border-radius:6px; background:", col, "15; margin-bottom:6px;"),
            tags$span(labels[[t]], style = "font-weight:600; font-size:12.5px; color:#002C3C;"),
            tags$span(if (liable) "Contingent Liability" else "Not Contingent Liability",
                      style = paste0("font-size:11.5px; font-weight:700; color:", col, ";"))
        )
      })
      
      tagList(rows)
    })
    
    session$onSessionEnded(function() {})
  })
}
