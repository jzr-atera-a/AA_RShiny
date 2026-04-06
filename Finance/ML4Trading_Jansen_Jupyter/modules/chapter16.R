# modules/chapter16.R — Word Embeddings for Earnings Calls and SEC Filings

chapter16_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(16, "🔤", "Word Embeddings",
      "Earnings Calls and SEC Filings - word2vec, doc2vec, and distributed representations for semantic analysis.",
      c("word2vec", "doc2vec", "Skip-gram", "CBOW", "Embeddings")),

    stats_row(
      list("word2vec", "Word Vectors"),
      list("300", "Dimensions"), 
      list("CBOW", "Context→Word"),
      list("doc2vec", "Document Vectors")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🔤 Word Embeddings", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Distributed Representations",
                  tagList(
                    tags$p("Map words to dense vectors where semantic similarity = vector proximity."),
                    tags$p(tags$strong("Properties:")),
                    tags$ul(
                      tags$li("king - man + woman ≈ queen"),
                      tags$li("profit - loss ≈ gain - deficit"),
                      tags$li("Captures analogies and relationships")
                    )
                  )
                ),
                plotlyOutput(ns("embedding_viz"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "🎯 word2vec Architectures", status = "warning", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Model"), 
                    tags$th("Input"), 
                    tags$th("Output"),
                    tags$th("Training")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("CBOW")),
                      tags$td("Context words"),
                      tags$td("Target word"),
                      tags$td("Predict word from context")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Skip-gram")),
                      tags$td("Target word"),
                      tags$td("Context words"),
                      tags$td("Predict context from word")
                    )
                  )
                ),
                framework_card("Which to Use?",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("CBOW:"), " Faster, better for frequent words, smaller datasets"),
                      tags$li(tags$strong("Skip-gram:"), " Better for rare words, larger datasets, more accurate")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📄 doc2vec: Document Embeddings", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Paragraph Vector",
                  tagList(
                    tags$p("Extends word2vec to entire documents. Each document gets its own vector."),
                    tags$p(tags$strong("Applications:")),
                    tags$ul(
                      tags$li("Compare earnings call transcripts across quarters"),
                      tags$li("Find similar SEC filings (10-K, 10-Q)"),
                      tags$li("Cluster companies by language/disclosure style"),
                      tags$li("Sentiment tracking over time")
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

chapter16_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$embedding_viz <- renderPlotly({
      set.seed(42)
      words <- c("profit", "loss", "gain", "revenue", "earnings", "stock", "market")
      x <- c(2, -2, 1.8, 0.5, 0.3, -0.5, -0.3)
      y <- c(1.5, -1.5, 1.3, 2, 1.8, 0, 0.2)
      
      plot_ly(x = x, y = y, text = words, type = "scatter", mode = "markers+text",
              marker = list(size = 15, color = ml_colors$primary, line = list(color = "white", width = 2)),
              textposition = "top center", textfont = list(size = 12, color = "#E6EDF3")) %>%
        layout(
          title = list(text = "Word Embeddings in 2D Space", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Dimension 1", color = "#8B949E", gridcolor = "#30363D", zeroline = FALSE),
          yaxis = list(title = "Dimension 2", color = "#8B949E", gridcolor = "#30363D", zeroline = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
  })
}
