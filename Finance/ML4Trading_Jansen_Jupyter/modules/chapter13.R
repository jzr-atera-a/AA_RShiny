# modules/chapter13.R — Data-Driven Risk Factors and Asset Allocation with Unsupervised Learning

chapter13_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(13, "🔍", "Unsupervised Learning",
      "Data-Driven Risk Factors and Asset Allocation - PCA, clustering, and hierarchical risk parity for portfolio construction.",
      c("PCA", "K-Means", "Hierarchical Clustering", "t-SNE", "HRP")),

    stats_row(
      list("PCA", "Dim Reduction"),
      list("K-Means", "Clustering"), 
      list("HRP", "Portfolio Method"),
      list("t-SNE", "Visualization")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "📉 Principal Component Analysis", status = "info", solidHeader = TRUE, width = 6,
                framework_card("PCA for Risk Factors",
                  tagList(
                    tags$p("Extract orthogonal factors explaining stock returns:"),
                    tags$ol(
                      tags$li("Standardize return matrix"),
                      tags$li("Compute covariance matrix"),
                      tags$li("Eigen decomposition"),
                      tags$li("Sort by eigenvalues (explained variance)"),
                      tags$li("Keep top K components")
                    ),
                    tags$p(tags$strong("Eigenportfolios:"), " Principal components as risk factors")
                  )
                ),
                plotlyOutput(ns("pca_variance"), height = "200px")
            ),
            
            box(title = "🎯 K-Means Clustering", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Algorithm",
                  tagList(
                    tags$ol(
                      tags$li("Initialize K centroids randomly"),
                      tags$li("Assign points to nearest centroid"),
                      tags$li("Update centroids (cluster means)"),
                      tags$li("Repeat 2-3 until convergence")
                    ),
                    tags$p(tags$strong("Elbow Method:"), " Choose K where inertia plateaus"),
                    tags$p(tags$strong("Applications:"), " Stock grouping, regime detection")
                  )
                ),
                plotlyOutput(ns("clusters"), height = "200px")
            )
          ),
          
          fluidRow(
            box(title = "🌳 Hierarchical Risk Parity", status = "success", solidHeader = TRUE, width = 12,
                framework_card("HRP Algorithm",
                  tagList(
                    tags$p("Modern portfolio construction using ML:"),
                    tags$ol(
                      tags$li(tags$strong("Clustering:"), " Hierarchical clustering on correlation matrix"),
                      tags$li(tags$strong("Quasi-Diagonalization:"), " Reorder assets by dendrogram"),
                      tags$li(tags$strong("Recursive Bisection:"), " Split clusters, allocate inversely to variance")
                    ),
                    tags$p(tags$strong("Advantages:"), " Robust, no optimization, accounts for structure")
                  )
                ),
                plotlyOutput(ns("hrp_weights"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "📊 Dimensionality Reduction Methods", status = "info", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Method"), 
                    tags$th("Type"), 
                    tags$th("Use Case"),
                    tags$th("Preserves")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("PCA")),
                      tags$td("Linear"),
                      tags$td("Risk factors, feature compression"),
                      tags$td("Variance")
                    ),
                    tags$tr(
                      tags$td(tags$strong("ICA")),
                      tags$td("Linear"),
                      tags$td("Independent components, blind source separation"),
                      tags$td("Independence")
                    ),
                    tags$tr(
                      tags$td(tags$strong("t-SNE")),
                      tags$td("Non-linear"),
                      tags$td("Visualization, cluster discovery"),
                      tags$td("Local structure")
                    ),
                    tags$tr(
                      tags$td(tags$strong("UMAP")),
                      tags$td("Non-linear"),
                      tags$td("Faster than t-SNE, scalable"),
                      tags$td("Global + local")
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

chapter13_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$pca_variance <- renderPlotly({
      components <- 1:10
      variance_explained <- c(0.35, 0.18, 0.12, 0.09, 0.07, 0.05, 0.04, 0.03, 0.03, 0.02)
      cumulative <- cumsum(variance_explained)
      
      plot_ly() %>%
        add_trace(x = components, y = variance_explained, name = "Variance", type = "bar",
                  marker = list(color = ml_colors$primary)) %>%
        add_trace(x = components, y = cumulative, name = "Cumulative", type = "scatter", mode = "lines+markers",
                  line = list(color = ml_colors$accent1, width = 2), yaxis = "y2") %>%
        layout(
          title = list(text = "PCA Explained Variance", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Component", color = "#8B949E"),
          yaxis = list(title = "Variance", color = "#8B949E", gridcolor = "#30363D"),
          yaxis2 = list(overlaying = "y", side = "right", title = "Cumulative", color = ml_colors$accent1),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$clusters <- renderPlotly({
      set.seed(42)
      n <- 100
      x <- c(rnorm(30, 2, 0.5), rnorm(40, 5, 0.6), rnorm(30, 8, 0.5))
      y <- c(rnorm(30, 3, 0.5), rnorm(40, 6, 0.6), rnorm(30, 3, 0.5))
      cluster <- factor(c(rep(1, 30), rep(2, 40), rep(3, 30)))
      
      plot_ly(x = x, y = y, color = cluster, colors = generate_palette(3),
              type = "scatter", mode = "markers", marker = list(size = 8)) %>%
        layout(
          title = list(text = "K-Means Clustering (K=3)", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Feature 1", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Feature 2", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          showlegend = TRUE,
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$hrp_weights <- renderPlotly({
      assets <- paste0("Asset_", 1:15)
      hrp_weights <- c(0.12, 0.08, 0.10, 0.06, 0.09, 0.07, 0.05, 0.08, 0.06, 0.07, 0.05, 0.06, 0.04, 0.04, 0.03)
      
      plot_ly(x = hrp_weights, y = assets, type = "bar", orientation = "h",
              marker = list(color = ml_colors$primary, line = list(color = "white", width = 1))) %>%
        layout(
          title = list(text = "HRP Portfolio Weights", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Weight", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "", color = "#8B949E"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
  })
}
