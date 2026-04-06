# modules/chapter18.R — Convolutional Neural Networks for Financial Time Series

chapter18_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(18, "🖼️", "Convolutional Neural Networks",
      "CNNs for Financial Time Series - Spatial pattern recognition in price charts, correlation matrices, and order book data.",
      c("CNN", "Convolution", "Pooling", "Filters", "Feature Maps", "Transfer Learning")),

    stats_row(
      list("Conv2D", "Convolution Layer"),
      list("3x3", "Typical Filter Size"), 
      list("MaxPool", "Pooling"),
      list("VGG/ResNet", "Architectures")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),
        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🔲 Convolutional Layers", status = "info", solidHeader = TRUE, width = 6,
                framework_card("How Convolution Works",
                  tagList(
                    tags$p("Slide filter kernel over input, computing dot products at each position:"),
                    tags$ul(
                      tags$li(tags$strong("Input:"), " 2D matrix (image, price chart, correlation matrix)"),
                      tags$li(tags$strong("Filter/Kernel:"), " Small learnable matrix (3x3, 5x5, 7x7)"),
                      tags$li(tags$strong("Stride:"), " Step size - usually 1 or 2"),
                      tags$li(tags$strong("Padding:"), " Add zeros around edges (same/valid)"),
                      tags$li(tags$strong("Output:"), " Feature map detecting local patterns")
                    )
                  )
                ),
                framework_card("Key Advantages",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Parameter Sharing:"), " Same filter across entire input → fewer params"),
                      tags$li(tags$strong("Translation Invariance:"), " Detect pattern anywhere in input"),
                      tags$li(tags$strong("Hierarchical Features:"), " Low-level → high-level abstractions"),
                      tags$li(tags$strong("Spatial Structure:"), " Preserve local relationships")
                    )
                  )
                )
            ),
            
            box(title = "📊 Pooling Layers", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Downsampling Operations",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Max Pooling:"), " Take maximum value in region (most common)"),
                      tags$li(tags$strong("Average Pooling:"), " Take mean of region"),
                      tags$li(tags$strong("Global Pooling:"), " Reduce entire feature map to single value"),
                      tags$li(tags$strong("Purpose:"), " Reduce dimensions, add invariance, prevent overfitting"),
                      tags$li(tags$strong("Typical:"), " 2x2 pooling with stride 2 (halves dimensions)")
                    )
                  )
                ),
                plotlyOutput(ns("pooling_effect"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "🏗️ CNN Architecture Example", status = "success", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("cnn_architecture"), height = "250px"),
                framework_card("Typical Architecture Pattern",
                  tagList(
                    tags$p(tags$strong("Conv → ReLU → Pool → Conv → ReLU → Pool → Flatten → Dense → Output")),
                    tags$ul(
                      tags$li("Multiple conv-pool blocks extract hierarchical features"),
                      tags$li("Filters increase in depth as spatial dimensions decrease"),
                      tags$li("Final dense layers for classification/regression"),
                      tags$li("Common: VGG (3x3 filters), ResNet (skip connections), Inception (multi-scale)")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "💼 Financial Applications", status = "info", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Application"), 
                    tags$th("Input Format"), 
                    tags$th("What CNN Learns"),
                    tags$th("Use Case")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Chart Patterns")),
                      tags$td("OHLC as image (time × price)"),
                      tags$td("Head-shoulders, triangles, flags"),
                      tags$td("Technical analysis automation")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Limit Order Book")),
                      tags$td("Order book depth snapshot"),
                      tags$td("Spatial patterns in supply/demand"),
                      tags$td("Short-term price prediction")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Correlation Matrices")),
                      tags$td("Asset correlation heatmap"),
                      tags$td("Cluster structure, regime changes"),
                      tags$td("Portfolio construction, risk management")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Candlestick Charts")),
                      tags$td("Multi-timeframe OHLC images"),
                      tags$td("Price patterns across scales"),
                      tags$td("Entry/exit signal generation")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Tick Data Heatmaps")),
                      tags$td("Volume/trades in time-price grid"),
                      tags$td("Microstructure patterns"),
                      tags$td("High-frequency trading")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📈 CNN for Price Chart Recognition", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Implementation Strategy",
                  tagList(
                    tags$ol(
                      tags$li(tags$strong("Data Prep:"), " Convert OHLC to 2D image (pixel intensity = price)"),
                      tags$li(tags$strong("Labeling:"), " Classify patterns or predict next-day return"),
                      tags$li(tags$strong("Augmentation:"), " Random crops, flips, noise for robustness"),
                      tags$li(tags$strong("Architecture:"), " 3-4 conv layers, 2x2 pooling, dense output"),
                      tags$li(tags$strong("Training:"), " Adam optimizer, dropout regularization"),
                      tags$li(tags$strong("Validation:"), " Time-series split, test on unseen periods")
                    )
                  )
                ),
                plotlyOutput(ns("chart_pattern_examples"), height = "200px")
            ),
            
            box(title = "🔄 Transfer Learning", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Leveraging Pretrained Models",
                  tagList(
                    tags$p("Use CNNs pretrained on ImageNet for financial charts:"),
                    tags$ul(
                      tags$li(tags$strong("VGG16/ResNet50:"), " Pretrained on millions of images"),
                      tags$li(tags$strong("Strategy:"), " Freeze early layers, fine-tune later layers"),
                      tags$li(tags$strong("Benefits:"), " Fewer training samples needed, faster convergence"),
                      tags$li(tags$strong("Trade-off:"), " Features learned on natural images may not transfer perfectly")
                    )
                  )
                ),
                plotlyOutput(ns("transfer_learning_perf"), height = "200px")
            )
          ),
          
          fluidRow(
            box(title = "🎯 Hyperparameter Impact", status = "info", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("hyperparameter_sensitivity"), height = "350px"),
                framework_card("Key Hyperparameters",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Filter Size:"), " 3x3 standard, 5x5 or 7x7 for larger receptive field"),
                      tags$li(tags$strong("Number of Filters:"), " Start 32-64, double each layer (32→64→128→256)"),
                      tags$li(tags$strong("Depth:"), " More layers = more abstraction but harder to train"),
                      tags$li(tags$strong("Pooling Size:"), " 2x2 most common, larger = more aggressive downsampling"),
                      tags$li(tags$strong("Dropout:"), " 0.25-0.5 after pooling to prevent overfitting")
                    )
                  )
                )
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

chapter18_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$cnn_architecture <- renderPlotly({
      layers <- c("Input\n32×32×3", "Conv1\n16 filters", "Pool\n16×16", "Conv2\n32 filters", 
                  "Pool\n8×8", "Conv3\n64 filters", "Pool\n4×4", "Dense\n128", "Output\n1")
      x_pos <- 1:9
      sizes <- c(35, 45, 40, 50, 45, 55, 50, 45, 35)
      
      plot_ly(x = x_pos, y = rep(1, 9), text = layers, mode = "markers+text",
              marker = list(size = sizes, color = generate_palette(9), 
                            line = list(color = "white", width = 2)),
              textposition = "middle center", textfont = list(size = 8, color = "white"),
              hoverinfo = "none") %>%
        add_trace(x = x_pos, y = rep(1, 9), mode = "lines", 
                  line = list(color = ml_colors$primary, width = 2),
                  showlegend = FALSE, hoverinfo = "none") %>%
        layout(
          title = list(text = "CNN Architecture for Price Chart Analysis", font = list(color = "#E6EDF3")),
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE, range = c(0.5, 9.5)),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE, range = c(0.5, 1.5)),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
    output$pooling_effect <- renderPlotly({
      x <- seq(1, 32, length.out = 100)
      original_dim <- rep(32, 100)
      after_pool1 <- rep(16, 100)
      after_pool2 <- rep(8, 100)
      
      plot_ly() %>%
        add_trace(x = x, y = original_dim, name = "Input", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 3), fill = "tozeroy") %>%
        add_trace(x = x, y = after_pool1, name = "After Pool 1", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$secondary, width = 3), fill = "tozeroy") %>%
        add_trace(x = x, y = after_pool2, name = "After Pool 2", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 3), fill = "tozeroy") %>%
        layout(
          title = list(text = "Dimension Reduction via Pooling", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Spatial Position", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Feature Map Size", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$chart_pattern_examples <- renderPlotly({
      patterns <- c("Head-Shoulders", "Triangle", "Flag", "Double Top", "Cup-Handle")
      detection_rate <- c(0.78, 0.82, 0.75, 0.71, 0.68)
      
      plot_ly(x = detection_rate, y = reorder(patterns, detection_rate), type = "bar", orientation = "h",
              marker = list(color = ml_colors$primary, line = list(color = "white", width = 1)),
              text = ~paste0(round(detection_rate*100, 1), "%"),
              textposition = "outside") %>%
        layout(
          title = list(text = "CNN Pattern Detection Accuracy", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Detection Rate", color = "#8B949E", gridcolor = "#30363D", range = c(0, 1)),
          yaxis = list(title = "", color = "#8B949E"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
    output$transfer_learning_perf <- renderPlotly({
      epochs <- 1:20
      scratch_acc <- 0.5 + (1 - exp(-epochs/10)) * 0.25 + rnorm(20, 0, 0.02)
      transfer_acc <- 0.65 + (1 - exp(-epochs/5)) * 0.25 + rnorm(20, 0, 0.02)
      
      plot_ly() %>%
        add_trace(x = epochs, y = scratch_acc, name = "From Scratch", type = "scatter", mode = "lines+markers",
                  line = list(color = ml_colors$accent1, width = 2), marker = list(size = 6)) %>%
        add_trace(x = epochs, y = transfer_acc, name = "Transfer Learning", type = "scatter", mode = "lines+markers",
                  line = list(color = ml_colors$success, width = 2), marker = list(size = 6)) %>%
        layout(
          title = list(text = "Transfer Learning Convergence", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Epoch", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Validation Accuracy", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$hyperparameter_sensitivity <- renderPlotly({
      filter_sizes <- c(3, 5, 7)
      num_filters <- c(16, 32, 64, 128)
      
      # Create matrix of accuracies
      acc_matrix <- matrix(c(
        0.72, 0.76, 0.78, 0.77,
        0.74, 0.79, 0.82, 0.81,
        0.71, 0.77, 0.80, 0.79
      ), nrow = 3, byrow = TRUE)
      
      plot_ly(x = num_filters, y = filter_sizes, z = acc_matrix, type = "heatmap",
              colorscale = list(c(0, ml_colors$danger), c(0.5, ml_colors$warning), c(1, ml_colors$success)),
              colorbar = list(title = "Accuracy", titlefont = list(color = "#E6EDF3"),
                              tickfont = list(color = "#E6EDF3")),
              hovertemplate = "Filters: %{x}<br>Size: %{y}x%{y}<br>Accuracy: %{z:.2f}<extra></extra>") %>%
        layout(
          title = list(text = "Hyperparameter Grid Search Results", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Number of Filters", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Filter Size", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
  })
}
