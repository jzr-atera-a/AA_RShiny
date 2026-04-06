# modules/chapter21.R — Generative Adversarial Networks for Synthetic Financial Data

chapter21_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(21, "🎭", "Generative Adversarial Networks",
      "GANs for Synthetic Data - Adversarial training for realistic market scenarios, stress testing, and privacy-preserving data generation.",
      c("GAN", "Generator", "Discriminator", "Adversarial", "Synthetic Data", "WGAN")),

    stats_row(
      list("2 Networks", "G vs D"),
      list("MinMax", "Game Theory"), 
      list("Nash", "Equilibrium"),
      list("Synthetic", "Data Gen")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),
        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🎭 GAN Framework", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Adversarial Training",
                  tagList(
                    tags$p("Two neural networks compete in a zero-sum game:"),
                    tags$ul(
                      tags$li(tags$strong("Generator G:"), " Creates fake samples from random noise z ~ N(0,1)"),
                      tags$li(tags$strong("Discriminator D:"), " Classifies samples as real or fake"),
                      tags$li(tags$strong("G's Goal:"), " Fool D by generating realistic samples"),
                      tags$li(tags$strong("D's Goal:"), " Correctly identify real vs fake"),
                      tags$li(tags$strong("Training:"), " Alternate updating D and G until equilibrium")
                    ),
                    tags$p(tags$strong("Objective:")),
                    tags$p("min_G max_D E[log D(x)] + E[log(1 - D(G(z)))]")
                  )
                ),
                plotlyOutput(ns("gan_architecture"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "📊 Training Dynamics", status = "success", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("training_dynamics"), height = "300px"),
                framework_card("Training Process",
                  tagList(
                    tags$ol(
                      tags$li("Train D on real data → label 1"),
                      tags$li("Train D on G(z) fake data → label 0"),
                      tags$li("Train G to maximize D(G(z))"),
                      tags$li("Repeat until D can't distinguish real from fake")
                    )
                  )
                )
            ),
            
            box(title = "⚠️ Training Challenges", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Common Issues",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Mode Collapse:"), " G produces limited variety"),
                      tags$li(tags$strong("Training Instability:"), " D and G oscillate, don't converge"),
                      tags$li(tags$strong("Vanishing Gradients:"), " D too strong → G can't learn"),
                      tags$li(tags$strong("Evaluation:"), " Hard to measure generation quality")
                    )
                  )
                ),
                plotlyOutput(ns("mode_collapse"), height = "200px")
            )
          ),
          
          fluidRow(
            box(title = "🔧 GAN Variants & Solutions", status = "info", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Variant"), 
                    tags$th("Innovation"), 
                    tags$th("Advantage"),
                    tags$th("Use Case")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("DCGAN")),
                      tags$td("Deep convolutional architecture"),
                      tags$td("Stable training, better images"),
                      tags$td("Image generation")
                    ),
                    tags$tr(
                      tags$td(tags$strong("WGAN")),
                      tags$td("Wasserstein distance loss"),
                      tags$td("Fixes mode collapse, stable training"),
                      tags$td("Continuous data, finance")
                    ),
                    tags$tr(
                      tags$td(tags$strong("CGAN")),
                      tags$td("Conditional generation"),
                      tags$td("Control output class/features"),
                      tags$td("Generate specific market conditions")
                    ),
                    tags$tr(
                      tags$td(tags$strong("StyleGAN")),
                      tags$td("Style-based generator"),
                      tags$td("High quality, controllable"),
                      tags$td("Realistic scenarios")
                    ),
                    tags$tr(
                      tags$td(tags$strong("CycleGAN")),
                      tags$td("Unpaired translation"),
                      tags$td("No paired training data needed"),
                      tags$td("Domain adaptation")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "💼 Financial Applications", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Use Cases",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Synthetic Market Data:"), " Generate realistic price paths for backtesting"),
                      tags$li(tags$strong("Stress Testing:"), " Create tail risk scenarios (crashes, flash events)"),
                      tags$li(tags$strong("Privacy:"), " Share synthetic data instead of real client data"),
                      tags$li(tags$strong("Data Augmentation:"), " Expand limited training sets"),
                      tags$li(tags$strong("Scenario Analysis:"), " What-if simulations for risk management"),
                      tags$li(tags$strong("Missing Data:"), " Fill gaps in historical data")
                    )
                  )
                ),
                plotlyOutput(ns("real_vs_synthetic"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "📈 Quality Metrics", status = "warning", solidHeader = TRUE, width = 12,
                framework_card("Evaluation Methods",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Inception Score (IS):"), " Measures quality & diversity"),
                      tags$li(tags$strong("Frechet Inception Distance (FID):"), " Distance between real & fake distributions"),
                      tags$li(tags$strong("Visual Inspection:"), " Manual review of samples"),
                      tags$li(tags$strong("Statistical Tests:"), " Compare moments, correlations, distributions"),
                      tags$li(tags$strong("Downstream Performance:"), " Train model on synthetic, test on real")
                    )
                  )
                ),
                plotlyOutput(ns("quality_metrics"), height = "250px")
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

chapter21_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$gan_architecture <- renderPlotly({
      components <- c("Noise z", "Generator\nG(z)", "Fake\nSample", "Discriminator\nD(x)", "Real/Fake")
      x_pos <- c(1, 2.5, 4, 5.5, 7)
      
      plot_ly(x = x_pos, y = rep(1, 5), text = components, mode = "markers+text",
              marker = list(size = c(40, 55, 45, 55, 40), color = generate_palette(5), 
                            line = list(color = "white", width = 2)),
              textposition = "middle center", textfont = list(size = 9, color = "white"),
              hoverinfo = "none") %>%
        add_trace(x = x_pos[1:4], y = rep(1, 4), mode = "lines", 
                  line = list(color = ml_colors$primary, width = 2),
                  showlegend = FALSE, hoverinfo = "none") %>%
        layout(
          title = list(text = "GAN Architecture", font = list(color = "#E6EDF3")),
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3")
        )
    })
    
    output$training_dynamics <- renderPlotly({
      epochs <- 1:100
      d_loss <- 0.7 - 0.5 * (1 - exp(-epochs/20)) + rnorm(100, 0, 0.05)
      g_loss <- 2 - 1.3 * (1 - exp(-epochs/25)) + rnorm(100, 0, 0.08)
      
      plot_ly() %>%
        add_trace(x = epochs, y = d_loss, name = "Discriminator Loss", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2)) %>%
        add_trace(x = epochs, y = g_loss, name = "Generator Loss", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$secondary, width = 2)) %>%
        layout(
          title = list(text = "GAN Training Convergence", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Epoch", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Loss", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$mode_collapse <- renderPlotly({
      set.seed(42)
      healthy <- data.frame(x = rnorm(100, 0, 2), y = rnorm(100, 0, 2), type = "Healthy")
      collapsed <- data.frame(x = rnorm(100, 0, 0.3), y = rnorm(100, 0, 0.3), type = "Mode Collapse")
      data <- rbind(healthy, collapsed)
      
      plot_ly(data, x = ~x, y = ~y, color = ~type, colors = c(ml_colors$success, ml_colors$danger),
              type = "scatter", mode = "markers", marker = list(size = 6)) %>%
        layout(
          title = list(text = "Mode Collapse Visualization", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Feature 1", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Feature 2", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$real_vs_synthetic <- renderPlotly({
      x <- seq(-3, 3, length.out = 200)
      real_dist <- dnorm(x, 0, 1)
      synthetic_dist <- dnorm(x, 0.1, 1.05)
      
      plot_ly() %>%
        add_trace(x = x, y = real_dist, name = "Real Data", type = "scatter", mode = "lines",
                  fill = "tozeroy", line = list(color = ml_colors$primary, width = 2)) %>%
        add_trace(x = x, y = synthetic_dist, name = "GAN Synthetic", type = "scatter", mode = "lines",
                  fill = "tozeroy", line = list(color = ml_colors$accent1, width = 2, dash = "dash")) %>%
        layout(
          title = list(text = "Real vs Synthetic Data Distribution", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Returns", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Density", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$quality_metrics <- renderPlotly({
      models <- c("Vanilla GAN", "DCGAN", "WGAN", "WGAN-GP")
      fid_scores <- c(85, 45, 25, 15)
      
      plot_ly(x = models, y = fid_scores, type = "bar",
              marker = list(color = ml_colors$primary, line = list(color = "white", width = 1)),
              text = fid_scores, textposition = "outside") %>%
        layout(
          title = list(text = "FID Score Comparison (Lower = Better)", font = list(color = "#E6EDF3")),
          xaxis = list(title = "", color = "#8B949E"),
          yaxis = list(title = "Fréchet Inception Distance", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3")
        )
    })
    
  })
}
