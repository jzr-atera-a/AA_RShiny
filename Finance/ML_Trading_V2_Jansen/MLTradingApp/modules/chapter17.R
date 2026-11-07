# modules/chapter17.R — Deep Learning for Trading

chapter17_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(17, "🧠", "Deep Learning for Trading",
      "Neural Networks Fundamentals - Feedforward networks, backpropagation, activation functions, and deep learning for return prediction.",
      c("Neural Networks", "Backpropagation", "TensorFlow", "Keras", "Dropout")),

    stats_row(
      list("MLP", "Architecture"),
      list("ReLU", "Activation"), 
      list("Adam", "Optimizer"),
      list("Dropout", "Regularization")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🧠 Neural Network Basics", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Feedforward Network",
                  tagList(
                    tags$p("Layers of neurons connected by weights:"),
                    tags$ul(
                      tags$li(tags$strong("Input Layer:"), " Features (x)"),
                      tags$li(tags$strong("Hidden Layers:"), " z = σ(Wx + b)"),
                      tags$li(tags$strong("Output Layer:"), " Predictions (ŷ)")
                    ),
                    tags$p(tags$strong("Forward Pass:"), " Input → Hidden → Output"),
                    tags$p(tags$strong("Backward Pass:"), " Compute gradients, update weights")
                  )
                ),
                plotlyOutput(ns("nn_architecture"), height = "200px")
            )
          ),
          
          fluidRow(
            box(title = "⚡ Activation Functions", status = "warning", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Function"), 
                    tags$th("Formula"), 
                    tags$th("Range"),
                    tags$th("Use")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Sigmoid")),
                      tags$td("σ(x) = 1/(1+e⁻ˣ)"),
                      tags$td("[0, 1]"),
                      tags$td("Output layer (binary)")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Tanh")),
                      tags$td("tanh(x)"),
                      tags$td("[-1, 1]"),
                      tags$td("Hidden layers")
                    ),
                    tags$tr(
                      tags$td(tags$strong("ReLU")),
                      tags$td("max(0, x)"),
                      tags$td("[0, ∞)"),
                      tags$td("Hidden (default choice)")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Leaky ReLU")),
                      tags$td("max(0.01x, x)"),
                      tags$td("(-∞, ∞)"),
                      tags$td("Avoid dying ReLU")
                    )
                  )
                ),
                plotlyOutput(ns("activations"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "🎯 Training Deep Networks", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Backpropagation",
                  tagList(
                    tags$ol(
                      tags$li("Forward pass: compute predictions"),
                      tags$li("Compute loss: L(ŷ, y)"),
                      tags$li("Backward pass: ∂L/∂w via chain rule"),
                      tags$li("Update weights: w -= η·∇L"),
                      tags$li("Repeat for mini-batches")
                    )
                  )
                )
            ),
            
            box(title = "⚙️ Optimizers", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Algorithms",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("SGD:"), " w -= η·∇L"),
                      tags$li(tags$strong("Momentum:"), " Accelerate in consistent direction"),
                      tags$li(tags$strong("RMSprop:"), " Adaptive learning rates"),
                      tags$li(tags$strong("Adam:"), " Combines momentum + RMSprop (default)")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🛡️ Regularization", status = "warning", solidHeader = TRUE, width = 12,
                framework_card("Preventing Overfitting",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Dropout:"), " Randomly drop neurons during training (p=0.5)"),
                      tags$li(tags$strong("L1/L2:"), " Weight decay penalties"),
                      tags$li(tags$strong("Early Stopping:"), " Stop when validation error increases"),
                      tags$li(tags$strong("Batch Normalization:"), " Normalize layer inputs"),
                      tags$li(tags$strong("Data Augmentation:"), " Expand training set")
                    )
                  )
                ),
                plotlyOutput(ns("training_curves"), height = "300px")
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

chapter17_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$nn_architecture <- renderPlotly({
      layers <- c("Input\n(10)", "Hidden 1\n(64)", "Hidden 2\n(32)", "Output\n(1)")
      x_pos <- 1:4
      
      plot_ly(x = x_pos, y = rep(1, 4), text = layers, mode = "markers+text",
              marker = list(size = c(40, 60, 50, 40), color = generate_palette(4), line = list(color = "white", width = 2)),
              textposition = "middle center", textfont = list(size = 10, color = "white"),
              hoverinfo = "none") %>%
        add_trace(x = x_pos, y = rep(1, 4), mode = "lines", 
                  line = list(color = ml_colors$primary, width = 2),
                  showlegend = FALSE, hoverinfo = "none") %>%
        layout(
          title = list(text = "Feedforward Neural Network", font = list(color = "#E6EDF3")),
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
    output$activations <- renderPlotly({
      x <- seq(-3, 3, length.out = 100)
      sigmoid <- 1 / (1 + exp(-x))
      tanh_v <- tanh(x)
      relu <- pmax(0, x)
      
      plot_ly() %>%
        add_trace(x = x, y = sigmoid, name = "Sigmoid", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2)) %>%
        add_trace(x = x, y = tanh_v, name = "Tanh", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$secondary, width = 2)) %>%
        add_trace(x = x, y = relu, name = "ReLU", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 2)) %>%
        layout(
          title = list(text = "Activation Functions", font = list(color = "#E6EDF3")),
          xaxis = list(title = "x", color = "#8B949E", gridcolor = "#30363D", zeroline = TRUE),
          yaxis = list(title = "f(x)", color = "#8B949E", gridcolor = "#30363D", zeroline = TRUE),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$training_curves <- renderPlotly({
      epochs <- 1:100
      train_loss <- exp(-epochs/20) + 0.1 + rnorm(100, 0, 0.02)
      val_loss <- exp(-epochs/25) + 0.15 + rnorm(100, 0, 0.03)
      val_loss[50:100] <- val_loss[50:100] + seq(0, 0.1, length.out = 51)
      
      plot_ly() %>%
        add_trace(x = epochs, y = train_loss, name = "Train Loss", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$success, width = 2)) %>%
        add_trace(x = epochs, y = val_loss, name = "Val Loss", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 2)) %>%
        layout(
          title = list(text = "Training Curves: Early Stopping at Epoch 50", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Epoch", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Loss", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)"),
          shapes = list(
            list(type = "line", x0 = 50, x1 = 50, y0 = 0, y1 = 1,
                 yref = "paper", line = list(color = ml_colors$danger, width = 2, dash = "dash"))
          )
        )
    })
    
  })
}
