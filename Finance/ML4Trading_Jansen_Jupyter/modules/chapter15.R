# modules/chapter15.R — Topic Modeling: Summarizing Financial News

chapter15_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(15, "📰", "Topic Modeling",
      "Summarizing Financial News - Latent Dirichlet Allocation and probabilistic topic discovery for large document collections.",
      c("LDA", "LSI", "Topics", "gensim", "Coherence")),

    stats_row(
      list("LDA", "Topic Model"),
      list("K", "Num Topics"), 
      list("α", "Doc-Topic"),
      list("β", "Topic-Word")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🎯 Latent Dirichlet Allocation", status = "info", solidHeader = TRUE, width = 12,
                framework_card("LDA Generative Process",
                  tagList(
                    tags$p("Each document is a mixture of topics; each topic is a distribution over words."),
                    tags$ol(
                      tags$li("For each document: sample topic distribution θ ~ Dir(α)"),
                      tags$li("For each topic: sample word distribution φ ~ Dir(β)"),
                      tags$li("For each word in document:"),
                      tags$ul(
                        tags$li("Sample topic z ~ Multinomial(θ)"),
                        tags$li("Sample word w ~ Multinomial(φ_z)")
                      )
                    ),
                    tags$p(tags$strong("Inference:"), " Reverse process - given words, infer topics")
                  )
                ),
                plotlyOutput(ns("topic_dist"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "⚙️ Hyperparameters", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("α and β",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("α (alpha):"), " Doc-topic Dirichlet prior. Low α → sparse (few topics per doc)"),
                      tags$li(tags$strong("β (beta):"), " Topic-word Dirichlet prior. Low β → sparse (few words per topic)"),
                      tags$li(tags$strong("K:"), " Number of topics (user choice, validate with coherence)")
                    )
                  )
                )
            ),
            
            box(title = "📊 Topic Coherence", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Evaluation",
                  "Coherence measures semantic similarity of top words in topic. Higher = more interpretable. Use C_v or U_mass metrics to select optimal K."
                ),
                plotlyOutput(ns("coherence"), height = "150px")
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

chapter15_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$topic_dist <- renderPlotly({
      topics <- paste0("Topic ", 1:5)
      doc1 <- c(0.5, 0.3, 0.1, 0.05, 0.05)
      doc2 <- c(0.1, 0.1, 0.6, 0.1, 0.1)
      
      plot_ly() %>%
        add_trace(x = topics, y = doc1, name = "Doc 1", type = "bar", marker = list(color = ml_colors$primary)) %>%
        add_trace(x = topics, y = doc2, name = "Doc 2", type = "bar", marker = list(color = ml_colors$secondary)) %>%
        layout(
          title = list(text = "Document-Topic Distributions", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Topic", color = "#8B949E"),
          yaxis = list(title = "Probability", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          barmode = "group",
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$coherence <- renderPlotly({
      k_values <- c(5, 10, 15, 20, 25)
      coherence_scores <- c(0.42, 0.51, 0.58, 0.55, 0.48)
      
      plot_ly(x = k_values, y = coherence_scores, type = "scatter", mode = "lines+markers",
              line = list(color = ml_colors$primary, width = 2), marker = list(size = 10)) %>%
        layout(
          title = list(text = "Topic Coherence vs K", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Number of Topics (K)", color = "#8B949E"),
          yaxis = list(title = "Coherence Score", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
  })
}
