# modules/overview.R
# Overview & Book Guide — Practical Recommender Systems Code Lab Edition

overview_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class = "meta-hero",
        tags$h1("Practical Recommender Systems · Code Lab"),
        tags$h2("Theory + Interactive R Implementations — Kim Falk · Manning 2019"),
        div(
          span(class = "hero-badge", "Netflix-Style Algorithms"),
          span(class = "hero-badge", "R Implementations"),
          span(class = "hero-badge", "Interactive Code Labs"),
          span(class = "hero-badge", "MovieGEEK Concepts")
        )
    ),

    fluidRow(
      box(title = "📊 App Statistics", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(2, div(class = "metric-card", span(class = "metric-value", "14"),
                          span(class = "metric-label", "Total Chapters"))),
            column(2, div(class = "metric-card", span(class = "metric-value", "14"),
                          span(class = "metric-label", "Code Labs"))),
            column(2, div(class = "metric-card", span(class = "metric-value", "R"),
                          span(class = "metric-label", "Primary Language"))),
            column(2, div(class = "metric-card", span(class = "metric-value", "Py"),
                          span(class = "metric-label", "Bridge for LDA/BPR"))),
            column(2, div(class = "metric-card", span(class = "metric-value", "450+"),
                          span(class = "metric-label", "Sample Ratings"))),
            column(2, div(class = "metric-card", span(class = "metric-value", "600"),
                          span(class = "metric-label", "Sample Events")))
          )
      )
    ),

    fluidRow(
      # Left: book structure
      box(title = "📚 Complete Book Structure", status = "primary", solidHeader = TRUE, width = 7,
          div(class = "success-box",
              HTML("<strong>✅ This App:</strong> Each chapter has a <strong>Theory</strong> tab
               (the full KB content) and a <strong>Code Lab</strong> tab with live, runnable R
               implementations that mirror the MovieGEEK Python codebase.")),
          br(),
          div(class = "scroll-pane",
              tags$div(style = "margin-bottom:18px;",
                       tags$div(class = "section-heading-dark",
                                "PART 1 · GETTING READY FOR RECOMMENDER SYSTEMS")),
              chapter_card("CH 1", "What is a Recommender?",
                           "Long tail, Netflix Prize, recommendation types.",
                           c("Foundations", "Long Tail", "Types")),
              chapter_card("CH 2", "User Behavior and How to Collect It",
                           "Data collection, tracking, implicit vs explicit feedback.",
                           c("Data Collection", "Events", "Behavior")),
              chapter_card("CH 3", "Monitoring the System",
                           "Analytics, A/B testing, dashboards.",
                           c("Analytics", "A/B Testing", "Monitoring")),
              chapter_card("CH 4", "Ratings and How to Calculate Them",
                           "Event → rating transformation, normalisation.",
                           c("Ratings", "Implicit", "Normalisation")),
              chapter_card("CH 5", "Non-Personalized Recommendations",
                           "Popularity, trending, seeded recs.",
                           c("Popularity", "Trending", "Baseline")),
              chapter_card("CH 6", "The Cold-Start Problem",
                           "Association rules, bootstrapping.",
                           c("Cold Start", "Assoc. Rules", "Bootstrapping")),
              tags$div(style = "margin:18px 0;",
                       tags$div(class = "section-heading-dark",
                                "PART 2 · RECOMMENDER ALGORITHMS")),
              chapter_card("CH 7", "Finding Similarities",
                           "Cosine, Euclidean, Pearson, Jaccard, adjusted cosine.",
                           c("Cosine", "Pearson", "Clustering")),
              chapter_card("CH 8", "Collaborative Filtering",
                           "User-based CF, item-based CF, neighborhoods, Amazon.",
                           c("CF", "Item-Item", "Neighborhoods")),
              chapter_card("CH 9", "Evaluating and Testing",
                           "Offline metrics, precision/recall, RMSE, A/B testing.",
                           c("MAE", "Precision@K", "MAP")),
              chapter_card("CH 10", "Content-Based Filtering",
                           "TF-IDF, LDA, genre-based similarity.",
                           c("TF-IDF", "LDA", "Content")),
              chapter_card("CH 11", "Matrix Factorization",
                           "SVD, Funk SVD, latent factors, SGD.",
                           c("SVD", "FunkSVD", "Latent Factors")),
              chapter_card("CH 12", "Hybrid Recommenders",
                           "Ensemble methods, FWLS, combining algorithms.",
                           c("Hybrid", "FWLS", "Ensemble")),
              chapter_card("CH 13", "Learning to Rank",
                           "BPR, re-ranking, pairwise ranking.",
                           c("BPR", "LTR", "Pairwise")),
              chapter_card("CH 14", "Future of RecSys",
                           "Context-aware, deep learning, next steps.",
                           c("Future", "Deep Learning", "Trends"))
          )
      ),

      # Right: Code Lab guide + learning path
      column(5,
             box(title = "💻 Code Lab Guide", status = "info", solidHeader = TRUE, width = 12,
                 div(class = "section-heading-dark", "How the Code Lab Works"),
                 div(class = "framework-card",
                     tags$h5("Two Tabs Per Chapter"),
                     tags$p(HTML("<strong>📚 Theory:</strong> Full conceptual content from the Knowledge Base.")),
                     tags$p(HTML("<strong>💻 Code Lab:</strong> Live R implementation. Adjust inputs, hit Run, see results instantly.")),
                     tags$p(HTML("<strong>Python Bridge:</strong> Ch 10, 11, 13 optionally call Python via <code>reticulate</code> for LDA, full-scale FunkSVD, and BPR."))
                 ),
                 div(class = "tip-box",
                     HTML("<strong>💡 Sample Data:</strong> All Code Labs use a built-in dataset:
                     <strong>50 users · 30 movies · ~450 ratings · 600 events</strong>. Upload your own CSV
                     in relevant chapters for larger experiments.")),
                 br(),
                 div(class = "section-heading-dark", "Python Bridge (Optional)"),
                 div(class = "framework-card",
                     tags$h5("When Python is Needed"),
                     tags$p(HTML("<strong>LDA (Ch 10):</strong> <code>gensim</code> topic modelling")),
                     tags$p(HTML("<strong>Full FunkSVD (Ch 11):</strong> NumPy SGD at scale")),
                     tags$p(HTML("<strong>Full BPR (Ch 13):</strong> Pairwise ranking with NumPy")),
                     tags$p(HTML("<strong>Setup:</strong> <code>pip install gensim numpy pandas</code>")),
                     tags$p(HTML("R implementations are always available as fallback."))
                 ),
                 br(),
                 div(class = "section-heading-dark", "Code Lab Status"),
                 tags$table(class = "algo-table",
                            tags$thead(tags$tr(tags$th("Chapter"), tags$th("Status"), tags$th("Language"))),
                            tags$tbody(
                              tags$tr(tags$td("Ch 1 · Long Tail"),          tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 2 · Event Log"),          tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 3 · A/B Testing"),        tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 4 · Rating Calculator"),  tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 5 · Popularity Recs"),    tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 6 · Assoc. Rules"),       tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 7 · Similarity"),         tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 8 · CF Recommender"),     tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 9 · Evaluation"),         tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 10 · TF-IDF + LDA"),     tags$td("✅ Live"), tags$td("R + Py")),
                              tags$tr(tags$td("Ch 11 · FunkSVD"),           tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 12 · FWLS Hybrid"),       tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 13 · BPR"),               tags$td("✅ Live"), tags$td("R")),
                              tags$tr(tags$td("Ch 14 · Future + Context"),  tags$td("✅ Live"), tags$td("R"))
                            )
                 )
             ),

             box(title = "🎯 Recommended Learning Path", status = "success",
                 solidHeader = TRUE, width = 12,
                 timeline_entry("1",   "Start Here",       "Ch 1: Explore the long tail and compare rec types interactively."),
                 timeline_entry("2",   "Collect Data",     "Ch 2: Generate event logs, understand implicit signals."),
                 timeline_entry("3",   "Monitor",          "Ch 3: A/B test significance, sample size planning, CTR dashboards."),
                 timeline_entry("4",   "Rate It",          "Ch 4: Transform raw events into ratings — full audit trail."),
                 timeline_entry("5",   "First Recs",       "Ch 5: Popularity, Bayesian average, trending, seeded recs."),
                 timeline_entry("6",   "Cold Start",       "Ch 6: Mine association rules, handle new users and new items."),
                 timeline_entry("7",   "Similarity",       "Ch 7: Live metric calculator, item-item similarity matrix builder."),
                 timeline_entry("8",   "CF",               "Ch 8: Full NeighborhoodBasedRecs — recommend and predict."),
                 timeline_entry("9",   "Evaluate",         "Ch 9: MAE, MAP@K, coverage — evaluate all three algorithms."),
                 timeline_entry("10",  "Content",          "Ch 10: TF-IDF from scratch, LDA bridge, ContentBasedRecs."),
                 timeline_entry("11",  "Matrix Factor.",   "Ch 11: FunkSVD SGD training loop, loss curve, latent factors."),
                 timeline_entry("12",  "Hybrid",           "Ch 12: FWLS — blend CF + content with a learned GLM."),
                 timeline_entry("13",  "Ranking",          "Ch 13: BPR triples sampling, AUC curve, vs popularity baseline."),
                 timeline_entry("14",  "Production",       "Ch 14: Context-aware demo, algorithm comparison, deployment checklist.")
             )
      )
    )
  )
}

overview_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Overview is static — no reactive outputs needed
  })
}
