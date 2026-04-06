# modules/chapter19.R — Recurrent Neural Networks for Financial Time Series and Sentiment Analysis

chapter19_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(19, "🔄", "Recurrent Neural Networks",
      "RNNs for Sequential Data - LSTM, GRU, attention mechanisms for time series forecasting and text analysis.",
      c("RNN", "LSTM", "GRU", "Sequence", "Attention", "Backprop Through Time")),

    stats_row(
      list("RNN", "Sequential Learning"),
      list("LSTM", "Long Memory"), 
      list("3 Gates", "Forget/Input/Output"),
      list("Attention", "Focus Mechanism")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),
        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🔄 RNN Architecture", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Recurrent Connections",
                  tagList(
                    tags$p("Process sequences by maintaining hidden state:"),
                    tags$p(tags$strong("h_t = tanh(W_h·h_{t-1} + W_x·x_t + b)")),
                    tags$ul(
                      tags$li(tags$strong("h_t:"), " Hidden state at time t (memory)"),
                      tags$li(tags$strong("x_t:"), " Input at time t"),
                      tags$li(tags$strong("W_h, W_x:"), " Weight matrices (shared across time)"),
                      tags$li(tags$strong("Advantages:"), " Variable-length sequences, parameter sharing"),
                      tags$li(tags$strong("Problem:"), " Vanishing gradients for long sequences (>10-20 steps)")
                    )
                  )
                ),
                plotlyOutput(ns("rnn_unrolled"), height = "200px")
            ),
            
            box(title = "⚠️ Vanishing Gradient Problem", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Why RNNs Struggle",
                  tagList(
                    tags$p("During backpropagation through time (BPTT):"),
                    tags$ul(
                      tags$li("Gradients multiply at each timestep"),
                      tags$li("If |gradient| < 1: exponential decay (vanishing)"),
                      tags$li("If |gradient| > 1: exponential growth (exploding)"),
                      tags$li("Result: Can't learn long-range dependencies"),
                      tags$li("Solution: LSTM and GRU architectures")
                    )
                  )
                ),
                plotlyOutput(ns("gradient_flow"), height = "200px")
            )
          ),
          
          fluidRow(
            box(title = "🧠 LSTM: Long Short-Term Memory", status = "success", solidHeader = TRUE, width = 12,
                framework_card("The LSTM Cell",
                  tagList(
                    tags$p("LSTM solves vanishing gradients with gating mechanism:"),
                    tags$h5("Three Gates Control Information Flow:"),
                    tags$ul(
                      tags$li(tags$strong("Forget Gate (f_t):"), " What to discard from cell state"),
                      tags$li(tags$strong("Input Gate (i_t):"), " What new info to add"),
                      tags$li(tags$strong("Output Gate (o_t):"), " What to output from cell state")
                    ),
                    tags$h5("Cell State Update:"),
                    tags$p("C_t = f_t ⊙ C_{t-1} + i_t ⊙ tanh(W_C·[h_{t-1}, x_t])"),
                    tags$p(tags$strong("Key Innovation:"), " Cell state C_t acts as highway for gradient flow")
                  )
                ),
                plotlyOutput(ns("lstm_gates"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "⚡ GRU: Gated Recurrent Unit", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Simplified LSTM",
                  tagList(
                    tags$p("GRU combines forget and input gates into update gate:"),
                    tags$ul(
                      tags$li(tags$strong("Reset Gate (r_t):"), " How much past to forget"),
                      tags$li(tags$strong("Update Gate (z_t):"), " How much to update"),
                      tags$li(tags$strong("Fewer Parameters:"), " Faster training than LSTM"),
                      tags$li(tags$strong("Performance:"), " Often comparable to LSTM")
                    )
                  )
                )
            ),
            
            box(title = "📊 LSTM vs GRU Comparison", status = "warning", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("lstm_vs_gru"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "🎯 Attention Mechanisms", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Beyond Fixed-Length Context",
                  tagList(
                    tags$p("Attention lets model focus on relevant parts of sequence:"),
                    tags$ul(
                      tags$li(tags$strong("Problem:"), " LSTM bottleneck - entire sequence compressed to fixed vector"),
                      tags$li(tags$strong("Solution:"), " Compute weighted average of all hidden states"),
                      tags$li(tags$strong("Weights:"), " Learned based on query-key similarity"),
                      tags$li(tags$strong("Result:"), " Model can attend to any position in sequence")
                    )
                  )
                ),
                plotlyOutput(ns("attention_weights"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "💼 Financial Applications", status = "info", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Application"), 
                    tags$th("Input Sequence"), 
                    tags$th("Output"),
                    tags$th("Architecture")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Price Prediction")),
                      tags$td("Historical returns (50-200 days)"),
                      tags$td("Next day/week return"),
                      tags$td("Stacked LSTM (2-3 layers)")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Volatility Forecasting")),
                      tags$td("Past realized volatility"),
                      tags$td("Future volatility"),
                      tags$td("LSTM + dense output")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Sentiment Time Series")),
                      tags$td("Daily news sentiment scores"),
                      tags$td("Asset returns correlation"),
                      tags$td("Bidirectional LSTM")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Order Book Dynamics")),
                      tags$td("Tick-level order flow"),
                      tags$td("Price direction"),
                      tags$td("GRU (fast inference)")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📈 LSTM Price Prediction Example", status = "success", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("lstm_prediction"), height = "350px")
            )
          )
        ),
        tabPanel(title = tagList(icon("code"), " Python Code"),
          python_code_tab()
        )
      )
    )
  )
}

chapter19_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$rnn_unrolled <- renderPlotly({
      timesteps <- c("t-2", "t-1", "t", "t+1")
      x_pos <- 1:4
      
      plot_ly(x = x_pos, y = rep(1, 4), text = timesteps, mode = "markers+text",
              marker = list(size = 50, color = ml_colors$primary, line = list(color = "white", width = 2)),
              textposition = "middle center", textfont = list(size = 12, color = "white"),
              hoverinfo = "none") %>%
        add_trace(x = x_pos, y = rep(1, 4), mode = "lines", 
                  line = list(color = ml_colors$secondary, width = 3),
                  showlegend = FALSE, hoverinfo = "none") %>%
        layout(
          title = list(text = "RNN Unrolled Through Time", font = list(color = "#E6EDF3")),
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
    output$gradient_flow <- renderPlotly({
      timesteps <- 1:20
      vanilla_rnn <- exp(-timesteps * 0.3)
      lstm <- rep(0.9, 20) + rnorm(20, 0, 0.05)
      
      plot_ly() %>%
        add_trace(x = timesteps, y = vanilla_rnn, name = "Vanilla RNN", type = "scatter", mode = "lines+markers",
                  line = list(color = ml_colors$danger, width = 2), marker = list(size = 6)) %>%
        add_trace(x = timesteps, y = lstm, name = "LSTM", type = "scatter", mode = "lines+markers",
                  line = list(color = ml_colors$success, width = 2), marker = list(size = 6)) %>%
        layout(
          title = list(text = "Gradient Magnitude Over Time", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Timesteps Back", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Gradient Magnitude", color = "#8B949E", gridcolor = "#30363D", type = "log"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$lstm_gates <- renderPlotly({
      timesteps <- 1:50
      forget_gate <- 0.5 + 0.3 * sin(timesteps / 5) + rnorm(50, 0, 0.05)
      input_gate <- 0.6 + 0.2 * cos(timesteps / 7) + rnorm(50, 0, 0.05)
      output_gate <- 0.55 + 0.25 * sin(timesteps / 6 + 1) + rnorm(50, 0, 0.05)
      
      plot_ly() %>%
        add_trace(x = timesteps, y = forget_gate, name = "Forget Gate", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$danger, width = 2)) %>%
        add_trace(x = timesteps, y = input_gate, name = "Input Gate", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$success, width = 2)) %>%
        add_trace(x = timesteps, y = output_gate, name = "Output Gate", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2)) %>%
        layout(
          title = list(text = "LSTM Gate Activations Over Sequence", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Timestep", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Gate Value (0-1)", color = "#8B949E", gridcolor = "#30363D", range = c(0, 1)),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$lstm_vs_gru <- renderPlotly({
      metrics <- c("Accuracy", "Train Time", "Params", "Memory")
      lstm_scores <- c(0.85, 0.5, 0.7, 0.6)
      gru_scores <- c(0.83, 0.75, 0.85, 0.8)
      
      plot_ly() %>%
        add_trace(x = metrics, y = lstm_scores, name = "LSTM", type = "bar",
                  marker = list(color = ml_colors$primary)) %>%
        add_trace(x = metrics, y = gru_scores, name = "GRU", type = "bar",
                  marker = list(color = ml_colors$secondary)) %>%
        layout(
          title = list(text = "LSTM vs GRU Comparison", font = list(color = "#E6EDF3")),
          xaxis = list(title = "", color = "#8B949E"),
          yaxis = list(title = "Normalized Score", color = "#8B949E", gridcolor = "#30363D", range = c(0, 1)),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          barmode = "group",
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$attention_weights <- renderPlotly({
      words <- c("Fed", "raises", "interest", "rates", "by", "0.25%", "surprising", "markets")
      attention <- c(0.05, 0.08, 0.25, 0.30, 0.03, 0.15, 0.10, 0.04)
      
      plot_ly(x = words, y = attention, type = "bar",
              marker = list(color = attention, colorscale = "Viridis", 
                            line = list(color = "white", width = 1)),
              text = ~paste0(round(attention*100, 1), "%"),
              textposition = "outside") %>%
        layout(
          title = list(text = "Attention Weights for Sentiment Prediction", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Word", color = "#8B949E"),
          yaxis = list(title = "Attention Weight", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          showlegend = FALSE
        )
    })
    
    output$lstm_prediction <- renderPlotly({
      dates <- seq(as.Date("2020-01-01"), as.Date("2023-12-31"), by = "day")
      n <- length(dates)
      train_end <- floor(n * 0.8)
      
      actual <- cumprod(1 + rnorm(n, 0.0003, 0.015))
      lstm_pred <- actual[1:train_end]
      lstm_pred <- c(lstm_pred, actual[(train_end+1):n] + rnorm(n - train_end, 0, 0.8))
      
      plot_ly() %>%
        add_trace(x = dates[1:train_end], y = actual[1:train_end], name = "Train", 
                  type = "scatter", mode = "lines",
                  line = list(color = ml_colors$secondary, width = 2)) %>%
        add_trace(x = dates[(train_end+1):n], y = actual[(train_end+1):n], name = "Actual Test", 
                  type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2)) %>%
        add_trace(x = dates[(train_end+1):n], y = lstm_pred[(train_end+1):n], name = "LSTM Prediction", 
                  type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 2, dash = "dash")) %>%
        layout(
          title = list(text = "LSTM Multi-Step Price Prediction", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "Price", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)"),
          shapes = list(
            list(type = "line", x0 = dates[train_end], x1 = dates[train_end], 
                 y0 = 0, y1 = 1, yref = "paper",
                 line = list(color = "#8B949E", width = 2, dash = "dot"))
          )
        )
    })
    
  })
}
