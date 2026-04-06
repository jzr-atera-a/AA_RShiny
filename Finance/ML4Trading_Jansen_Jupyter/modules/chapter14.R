# modules/chapter14.R — Text Data for Trading: Sentiment Analysis

chapter14_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(14, "💬", "Sentiment Analysis",
      "Text Data for Trading - NLP pipelines, document-term matrices, and sentiment classification for financial text.",
      c("NLP", "spaCy", "Bag-of-Words", "TF-IDF", "Naive Bayes")),

    stats_row(
      list("NLP", "Text Processing"),
      list("TF-IDF", "Weighting"), 
      list("spaCy", "Library"),
      list("Naive Bayes", "Classifier")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "📝 NLP Pipeline", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Processing Steps",
                  tagList(
                    tags$ol(
                      tags$li(tags$strong("Tokenization:"), " Split text into words/sentences"),
                      tags$li(tags$strong("Lowercasing:"), " Normalize case"),
                      tags$li(tags$strong("Stop Word Removal:"), " Remove 'the', 'is', 'and'"),
                      tags$li(tags$strong("Stemming/Lemmatization:"), " 'running' → 'run'"),
                      tags$li(tags$strong("POS Tagging:"), " Noun, verb, adjective"),
                      tags$li(tags$strong("Named Entity Recognition:"), " Companies, people, locations"),
                      tags$li(tags$strong("Vectorization:"), " Text → numbers")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📊 Bag-of-Words Model", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Document-Term Matrix",
                  tagList(
                    tags$p("Represent documents as word count vectors:"),
                    tags$p(tags$strong("Doc 1:"), " 'stock market rises'"),
                    tags$p(tags$strong("Doc 2:"), " 'stock prices fall'"),
                    tags$p(tags$strong("Vocabulary:"), " {stock, market, rises, prices, fall}"),
                    tags$p(tags$strong("Matrix:")),
                    tags$ul(
                      tags$li("Doc 1: [1, 1, 1, 0, 0]"),
                      tags$li("Doc 2: [1, 0, 0, 1, 1]")
                    )
                  )
                )
            ),
            
            box(title = "⚖️ TF-IDF Weighting", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Formula",
                  tagList(
                    tags$p(tags$strong("TF-IDF = TF × IDF")),
                    tags$ul(
                      tags$li(tags$strong("TF:"), " Term Frequency = count in document"),
                      tags$li(tags$strong("IDF:"), " Inverse Document Frequency = log(N / df)"),
                      tags$li(tags$strong("N:"), " Total documents"),
                      tags$li(tags$strong("df:"), " Documents containing term")
                    ),
                    tags$p(tags$strong("Effect:"), " Downweight common words, upweight rare informative terms")
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🎯 Naive Bayes Classifier", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Bayes for Text Classification",
                  tagList(
                    tags$p(tags$strong("P(class|doc) ∝ P(class) × ∏ P(word|class)")),
                    tags$p("Assumes word independence (naive). Fast, works well despite assumption."),
                    tags$p(tags$strong("Applications:")),
                    tags$ul(
                      tags$li("News sentiment: positive/negative/neutral"),
                      tags$li("Topic classification: earnings, M&A, regulation"),
                      tags$li("Spam detection"),
                      tags$li("Author attribution")
                    )
                  )
                ),
                plotlyOutput(ns("sentiment_dist"), height = "250px")
            )
          ),
          
          fluidRow(
            box(title = "💼 Financial Sentiment Dictionaries", status = "warning", solidHeader = TRUE, width = 12,
                framework_card("Loughran-McDonald Dictionary",
                  tagList(
                    tags$p("Financial-specific sentiment lexicon (general sentiment fails for finance):"),
                    tags$ul(
                      tags$li(tags$strong("Negative:"), " litigation, loss, adverse, decline"),
                      tags$li(tags$strong("Positive:"), " profit, gain, innovative, efficient"),
                      tags$li(tags$strong("Uncertainty:"), " may, might, could, approximately"),
                      tags$li(tags$strong("Litigious:"), " lawsuit, plaintiff, defendant"),
                      tags$li(tags$strong("Constraining:"), " must, shall, required")
                    ),
                    tags$p(tags$strong("Usage:"), " Count word categories, compute sentiment score = (pos - neg) / total")
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

chapter14_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$sentiment_dist <- renderPlotly({
      sentiment <- c("Positive", "Neutral", "Negative")
      counts <- c(350, 500, 150)
      
      plot_ly(labels = sentiment, values = counts, type = "pie",
              marker = list(colors = c(ml_colors$success, ml_colors$secondary, ml_colors$danger),
                            line = list(color = "white", width = 2))) %>%
        layout(
          title = list(text = "Financial News Sentiment Distribution", font = list(color = "#E6EDF3")),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          showlegend = TRUE,
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
  })
}
