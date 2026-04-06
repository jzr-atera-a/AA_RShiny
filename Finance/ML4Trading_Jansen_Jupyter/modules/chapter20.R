# modules/chapter20.R — Autoencoders for Conditional Risk Factors and Asset Pricing

chapter20_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(20, "🔀", "Autoencoders",
      "Conditional Risk Factors - Unsupervised dimensionality reduction, anomaly detection, and data-driven feature extraction with autoencoders.",
      c("Autoencoder", "Encoder", "Decoder", "Latent Space", "VAE", "Denoising")),

    stats_row(
      list("Encoder", "Compress Data"),
      list("Latent", "Bottleneck"), 
      list("Decoder", "Reconstruct"),
      list("VAE", "Variational")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),
        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🔀 Autoencoder Architecture", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Unsupervised Learning",
                  tagList(
                    tags$p("Learn compressed representation by reconstructing input:"),
                    tags$h5("Architecture:"),
                    tags$ul(
                      tags$li(tags$strong("Encoder:"), " X → Z (compress to latent space)"),
                      tags$li(tags$strong("Latent Space:"), " Low-dimensional bottleneck representation"),
                      tags$li(tags$strong("Decoder:"), " Z → X' (reconstruct from latent)"),
                      tags$li(tags$strong("Loss:"), " ||X - X'||² (reconstruction error)")
                    )
                  )
                ),
                plotlyOutput(ns("autoencoder_arch"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "📊 Reconstruction Quality", status = "success", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("reconstruction_error"), height = "300px")
            ),
            
            box(title = "🎨 Latent Space Visualization", status = "warning", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("latent_space"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "🎯 Trading Applications", status = "info", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Application"), 
                    tags$th("Input"), 
                    tags$th("Use Case"),
                    tags$th("Latent Dimension")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Risk Factor Extraction")),
                      tags$td("Asset returns matrix"),
                      tags$td("Data-driven risk factors"),
                      tags$td("5-20 factors")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Anomaly Detection")),
                      tags$td("Portfolio positions/returns"),
                      tags$td("Detect unusual market conditions"),
                      tags$td("10-50")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Denoising")),
                      tags$td("Noisy price signals"),
                      tags$td("Clean signal extraction"),
                      tags$td("Same as input")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Feature Engineering")),
                      tags$td("High-dimensional features"),
                      tags$td("Compressed features for ML"),
                      tags$td("20-100")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🔬 Variational Autoencoders (VAE)", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Probabilistic Encoding",
                  tagList(
                    tags$p("VAE encodes to distribution instead of point:"),
                    tags$ul(
                      tags$li(tags$strong("Encoder Output:"), " Mean μ and variance σ² of latent distribution"),
                      tags$li(tags$strong("Sampling:"), " z ~ N(μ, σ²) - reparameterization trick"),
                      tags$li(tags$strong("Loss:"), " Reconstruction + KL divergence"),
                      tags$li(tags$strong("KL Term:"), " Regularizes latent space to be N(0,1)"),
                      tags$li(tags$strong("Advantage:"), " Can generate new samples by sampling from latent space")
                    )
                  )
                ),
                plotlyOutput(ns("vae_loss"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "⚠️ Anomaly Detection Example", status = "warning", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("anomaly_detection"), height = "350px"),
                framework_card("Threshold Selection",
                  "Set threshold at 95th/99th percentile of training reconstruction errors. Points exceeding threshold in test = anomalies."
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

chapter20_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$autoencoder_arch <- renderPlotly({
      layers <- c("Input\n100", "Encode1\n50", "Encode2\n25", "Latent\n10", "Decode1\n25", "Decode2\n50", "Output\n100")
      x_pos <- 1:7
      sizes <- c(50, 45, 40, 30, 40, 45, 50)
      
      plot_ly(x = x_pos, y = rep(1, 7), text = layers, mode = "markers+text",
              marker = list(size = sizes, color = generate_palette(7), line = list(color = "white", width = 2)),
              textposition = "middle center", textfont = list(size = 9, color = "white"), hoverinfo = "none") %>%
        add_trace(x = x_pos, y = rep(1, 7), mode = "lines", line = list(color = ml_colors$primary, width = 2),
                  showlegend = FALSE, hoverinfo = "none") %>%
        layout(
          title = list(text = "Autoencoder Architecture", font = list(color = "#E6EDF3")),
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3")
        )
    })
    
    output$reconstruction_error <- renderPlotly({
      epochs <- 1:100
      train_loss <- 100 * exp(-epochs/20) + 5 + rnorm(100, 0, 2)
      val_loss <- 100 * exp(-epochs/22) + 8 + rnorm(100, 0, 3)
      
      plot_ly() %>%
        add_trace(x = epochs, y = train_loss, name = "Train", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$success, width = 2)) %>%
        add_trace(x = epochs, y = val_loss, name = "Validation", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2)) %>%
        layout(
          title = list(text = "Reconstruction Error During Training", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Epoch", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "MSE Loss", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$latent_space <- renderPlotly({
      set.seed(42)
      n <- 200
      z1 <- c(rnorm(50, -2, 0.5), rnorm(50, 2, 0.5), rnorm(50, 0, 0.3), rnorm(50, 0, 2))
      z2 <- c(rnorm(50, 2, 0.5), rnorm(50, -2, 0.5), rnorm(50, 0, 2), rnorm(50, 0, 0.3))
      clusters <- factor(rep(1:4, each = 50))
      
      plot_ly(x = z1, y = z2, color = clusters, colors = generate_palette(4),
              type = "scatter", mode = "markers", marker = list(size = 8)) %>%
        layout(
          title = list(text = "2D Latent Space Representation", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Latent Dim 1", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Latent Dim 2", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          showlegend = TRUE, legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$vae_loss <- renderPlotly({
      epochs <- 1:100
      recon_loss <- 50 * exp(-epochs/25) + 10
      kl_loss <- 5 * (1 - exp(-epochs/15))
      total_loss <- recon_loss + kl_loss
      
      plot_ly() %>%
        add_trace(x = epochs, y = recon_loss, name = "Reconstruction", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2)) %>%
        add_trace(x = epochs, y = kl_loss, name = "KL Divergence", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$secondary, width = 2)) %>%
        add_trace(x = epochs, y = total_loss, name = "Total Loss", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 2, dash = "dash")) %>%
        layout(
          title = list(text = "VAE Loss Components", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Epoch", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Loss", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$anomaly_detection <- renderPlotly({
      set.seed(123)
      dates <- seq(as.Date("2020-01-01"), as.Date("2023-12-31"), by = "day")
      recon_error <- abs(rnorm(length(dates), 0.5, 0.2))
      threshold <- quantile(recon_error, 0.95)
      anomalies <- recon_error > threshold
      
      plot_ly() %>%
        add_trace(x = dates, y = recon_error, name = "Reconstruction Error", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 1)) %>%
        add_trace(x = dates[anomalies], y = recon_error[anomalies], name = "Anomalies", 
                  type = "scatter", mode = "markers",
                  marker = list(size = 8, color = ml_colors$danger, symbol = "x")) %>%
        layout(
          title = list(text = "Anomaly Detection via Reconstruction Error", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "Reconstruction Error", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)"),
          shapes = list(
            list(type = "line", x0 = min(dates), x1 = max(dates), y0 = threshold, y1 = threshold,
                 line = list(color = ml_colors$warning, width = 2, dash = "dash"))
          )
        )
    })
    
  })
}
