# modules/chapter14.R
# Chapter 14: The Future of Recommender Systems
# Theory + Concept Explorer (no new algorithm — forward-looking chapter)

chapter14_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class = "meta-hero",
        tags$h1("Chapter 14: The Future of Recommender Systems"),
        tags$h2("What Comes Next — Context, Deep Learning, and Responsible RecSys"),
        div(
          span(class = "hero-badge", "Context-Aware"),
          span(class = "hero-badge", "Deep Learning"),
          span(class = "hero-badge", "Fairness"),
          span(class = "hero-badge", "Next Steps")
        )
    ),

    fluidRow(
      box(title = "🎯 Chapter Overview", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, div(class="metric-card", span(class="metric-value","5+"),
                          span(class="metric-label","Future Directions"))),
            column(3, div(class="metric-card", span(class="metric-value","DL"),
                          span(class="metric-label","Neural CF & Transformers"))),
            column(3, div(class="metric-card", span(class="metric-value","Ethics"),
                          span(class="metric-label","Fairness & Filter Bubbles"))),
            column(3, div(class="metric-card", span(class="metric-value","RL"),
                          span(class="metric-label","Reinforcement Learning"))  )
          )
      )
    ),

    fluidRow(
      tabBox(width = 12, id = ns("ch14_tabs"),

        # ── THEORY ─────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "🌍 Context-Aware Recommendations", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "success-box",
                    HTML("<strong>✅ Next frontier:</strong> The same user wants different
                    recommendations depending on <em>context</em> — time of day, location,
                    device, companion, mood.")),
                br(),
                div(class = "framework-card",
                    tags$h5("Context Dimensions"),
                    tags$p(HTML("<strong>Temporal:</strong> Morning news vs evening entertainment")),
                    tags$p(HTML("<strong>Location:</strong> Restaurant recs at home vs near office")),
                    tags$p(HTML("<strong>Social:</strong> Alone vs with partner vs with kids")),
                    tags$p(HTML("<strong>Device:</strong> Phone (quick) vs TV (lean-back)")),
                    tags$p(HTML("<strong>Mood:</strong> Energetic vs relaxed"))
                ),
                div(class = "framework-card",
                    tags$h5("Tensor Factorization"),
                    tags$p("Extend matrix factorization from R (users × items) to a 3D tensor
                           (users × items × context). Each context gets its own factor slice."),
                    tags$p("Example: Netflix uses time-of-day as a context signal for recommendations.")
                )
            ),

            box(title = "🧠 Deep Learning Approaches", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Neural Collaborative Filtering (NCF)"),
                    tags$p("Replace the dot product P_u·Q_i with a multi-layer neural network."),
                    tags$p("Learns non-linear user-item interactions. Used at Pinterest, YouTube."),
                    tags$p(HTML("<strong>Key paper:</strong> He et al. (2017) — NeuMF"))
                ),
                div(class = "framework-card",
                    tags$h5("Autoencoders for CF"),
                    tags$p("Encode user rating vector to latent space, decode to full rating prediction."),
                    tags$p("Better at handling sparsity than SVD. Netflix research showed strong results.")
                ),
                div(class = "framework-card",
                    tags$h5("Sequential / Session Recommendations"),
                    tags$p("Use RNNs or Transformers (BERT4Rec, SASRec) to model user intent
                           as a sequence of interactions."),
                    tags$p("'You searched X, then viewed Y, then added Z — next recommendation is...'"),
                    tags$p(HTML("<strong>Key model:</strong> BERT4Rec, GRU4Rec, SASRec"))
                )
            )
          ),

          fluidRow(
            box(title = "⚖️ Ethics, Fairness, and Responsible RecSys",
                status = "danger", solidHeader = TRUE, width = 6,
                div(class = "warn-box",
                    HTML("<strong>⚠️ Real Harms:</strong> RecSys are not neutral. They shape what
                    people see, buy, watch, and believe. Ethical considerations are not optional.")),
                br(),
                div(class = "framework-card",
                    tags$h5("Filter Bubbles"),
                    tags$p("Collaborative filtering naturally amplifies popular items and like-minded groups."),
                    tags$p("Users see less diverse content over time → polarisation."),
                    tags$p(HTML("<strong>Solution:</strong> Intentional diversity injection, serendipity metrics"))
                ),
                div(class = "framework-card",
                    tags$h5("Popularity Bias"),
                    tags$p("CF inherently favours already-popular items.
                           Long-tail creators get less exposure."),
                    tags$p(HTML("<strong>Solution:</strong> Reranking with diversity constraints, inverse propensity scoring"))
                ),
                div(class = "framework-card",
                    tags$h5("Algorithmic Fairness"),
                    tags$p("Should the system treat all users equally? All items equally?"),
                    tags$p("Fairness for users (equal quality) vs fairness for items (equal exposure) can conflict.")
                )
            ),

            box(title = "🚀 Reinforcement Learning for RecSys",
                status = "success", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("The Exploration–Exploitation Trade-off"),
                    tags$p("Pure CF: exploit known preferences. Always recommend the same genres."),
                    tags$p("RL framing: occasionally explore unknown territories to discover new preferences."),
                    tags$p(HTML("<strong>Bandit algorithms:</strong> Thompson sampling, UCB for exploration"))
                ),
                div(class = "framework-card",
                    tags$h5("Contextual Bandits"),
                    tags$p("Multi-armed bandit where each 'arm' is a recommendation."),
                    tags$p("Context (user features, time, device) informs which arm to pull."),
                    tags$p("Used by Netflix, LinkedIn, Twitter for feed ranking.")
                ),
                div(class = "framework-card",
                    tags$h5("Deep RL for Long-Term Engagement"),
                    tags$p("Optimise not just immediate clicks but long-term user satisfaction."),
                    tags$p("YouTube's 2019 paper showed DRL improved watch time significantly."),
                    tags$p(HTML("<strong>Challenge:</strong> Reward shaping — what should the agent optimise?"))
                )
            )
          ),

          fluidRow(
            box(title = "📚 What to Study Next", status = "primary",
                solidHeader = TRUE, width = 12,
                div(class = "section-heading-dark", "Kim Falk's Recommended Path Forward"),
                fluidRow(
                  column(3, div(class="framework-card",
                                tags$h5("📖 Books"),
                                tags$p("Recommender Systems Handbook — Ricci et al."),
                                tags$p("Programming Collective Intelligence — Toby Segaran"),
                                tags$p("Hands-On Machine Learning — Aurélien Géron"))),
                  column(3, div(class="framework-card",
                                tags$h5("🎓 Courses"),
                                tags$p("Stanford CS246 — Mining Massive Datasets"),
                                tags$p("Coursera ML Specialisation — Andrew Ng"),
                                tags$p("fast.ai Practical Deep Learning"))),
                  column(3, div(class="framework-card",
                                tags$h5("🔬 Research Venues"),
                                tags$p("ACM RecSys Conference (annual)"),
                                tags$p("WWW, KDD, SIGIR — RecSys tracks"),
                                tags$p("arXiv cs.IR — Information Retrieval"))),
                  column(3, div(class="framework-card",
                                tags$h5("🛠️ Frameworks"),
                                tags$p("Surprise (Python) — classic CF"),
                                tags$p("LightFM — hybrid MF + content"),
                                tags$p("TensorFlow Recommenders (TFRS)"),
                                tags$p("RecBole — unified benchmark")))
                )
            )
          )
        ), # end Theory

        # ── CODE LAB ───────────────────────────────────────
        tabPanel(title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            title    = "RecSys Journey: What You've Built",
            subtitle = "A complete summary of every algorithm implemented across the course, with live comparisons between all methods on the same dataset.",
            badges   = c("R", "Full Pipeline", "All Algorithms")
          ),

          # ── Journey summary ─────────────────────────────
          fluidRow(
            box(title = "🗺️ Your RecSys Journey", status = "primary",
                solidHeader = TRUE, width = 12,
                div(class = "section-heading-dark", "Every algorithm you built, in order"),
                fluidRow(
                  column(2, div(class="metric-card",
                                span(class="metric-value","Ch4"),
                                span(class="metric-label","Implicit Ratings"))),
                  column(2, div(class="metric-card",
                                span(class="metric-value","Ch5"),
                                span(class="metric-label","Popularity"))),
                  column(2, div(class="metric-card",
                                span(class="metric-value","Ch6"),
                                span(class="metric-label","Assoc. Rules"))),
                  column(2, div(class="metric-card",
                                span(class="metric-value","Ch8"),
                                span(class="metric-label","CF Item-Item"))),
                  column(2, div(class="metric-card",
                                span(class="metric-value","Ch10"),
                                span(class="metric-label","TF-IDF Content"))),
                  column(2, div(class="metric-card",
                                span(class="metric-value","Ch11"),
                                span(class="metric-label","FunkSVD MF")))
                ),
                br(),
                fluidRow(
                  column(2),
                  column(2, div(class="metric-card",
                                span(class="metric-value","Ch12"),
                                span(class="metric-label","FWLS Hybrid"))),
                  column(2, div(class="metric-card",
                                span(class="metric-value","Ch13"),
                                span(class="metric-label","BPR Ranking"))),
                  column(2, div(class="metric-card",
                                span(class="metric-value","Ch9"),
                                span(class="metric-label","Evaluation Suite"))),
                  column(2, div(class="metric-card",
                                span(class="metric-value","🏆"),
                                span(class="metric-label","Production Ready!"))),
                  column(2)
                )
            )
          ),

          # ── Algorithm comparison ─────────────────────────
          fluidRow(
            box(title = "⚖️ Algorithm Comparison Reference", status = "success",
                solidHeader = TRUE, width = 12,
                div(class = "section-heading-dark",
                    "When to use each algorithm — practical guide"),
                DTOutput(ns("algo_comparison_table"))
            )
          ),

          # ── Production checklist ─────────────────────────
          fluidRow(
            box(title = "✅ Production Deployment Checklist", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class="section-heading-dark","Before you ship a recommender"),
                uiOutput(ns("checklist")),
                br(),
                div(class="tip-box",
                    HTML("<strong>💡 Kim Falk's Final Advice:</strong>
                    Start simple. A well-tuned popularity baseline often beats a poorly-tuned
                    matrix factorisation. Measure everything. Iterate."))
            ),

            box(title = "🔬 Next Steps: Context-Aware Demo",
                status = "info", solidHeader = TRUE, width = 6,
                div(class="section-heading-dark",
                    "Simple context-aware popularity — time-of-day weighting"),
                div(class="control-panel",
                    selectInput(ns("ctx_time"),   "Time of day:",
                                choices=c("Morning (6-12)"="morning",
                                          "Afternoon (12-18)"="afternoon",
                                          "Evening (18-24)"="evening")),
                    selectInput(ns("ctx_device"),  "Device:",
                                choices=c("Mobile"="mobile",
                                          "Desktop"="desktop",
                                          "TV"="tv")),
                    numericInput(ns("ctx_user"),   "User ID:", value=1, min=1, max=50),
                    run_button(ns("run_context"), "▶  Get Context-Aware Recs")
                ),
                uiOutput(ns("context_recs_result")),
                br(),
                r_code_block(
'# Simple context weighting
# Time × genre affinity heuristic

genre_ctx <- list(
  morning  = c(Drama=0.8, Documentary=1.2,
               Comedy=1.0, Action=0.6),
  afternoon= c(Drama=1.0, Comedy=1.2,
               Action=1.1, Family=1.3),
  evening  = c(Drama=1.2, Action=1.3,
               `Sci-Fi`=1.4, Thriller=1.2)
)

# Weight popularity scores by
# genre affinity for current context
ctx_recs <- pop_recs %>%
  mutate(
    ctx_weight = genre_ctx[[time]][genre],
    ctx_score  = bayes_avg * ctx_weight
  ) %>% arrange(desc(ctx_score))'
                )
            )
          )
        ) # end Code Lab
      )
    )
  )
}

chapter14_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    output$algo_comparison_table <- renderDT({
      df <- data.frame(
        Algorithm     = c("Popularity","Item-Item CF","Content (TF-IDF)",
                          "FunkSVD MF","FWLS Hybrid","BPR"),
        Chapter       = c("Ch5","Ch8","Ch10","Ch11","Ch12","Ch13"),
        `Feedback`    = c("Explicit/Implicit","Explicit","Content","Explicit",
                          "Both","Implicit"),
        `Cold Start`  = c("✅ New user OK","❌ Needs history",
                          "✅ New item OK","❌ Needs ratings",
                          "⚠️ Partial","❌ Needs interactions"),
        `Scalability` = c("✅ O(1)","⚠️ O(items×users)",
                          "✅ Pre-compute","✅ SGD","⚠️ Train both","✅ SGD"),
        `Explainability`=c("✅ 'It's popular'","✅ 'Because you liked X'",
                           "✅ 'Similar description'","❌ Black box",
                           "⚠️ Partial","❌ Ranking score"),
        `Best For`    = c("Cold start, baseline","Explicit ratings, e-commerce",
                          "New items, content-rich","Large-scale explicit ratings",
                          "Production blend","Implicit feedback, ranking"),
        check.names   = FALSE
      )
      datatable(df, options=list(dom="t",pageLength=10,scrollX=TRUE), rownames=FALSE) %>%
        formatStyle(columns=1:7,fontSize="12px") %>%
        formatStyle("Algorithm", fontWeight="bold", color="#002C3C")
    })

    output$checklist <- renderUI({
      items <- list(
        list(done=TRUE,  text="✅ Baseline measured (popularity/random)"),
        list(done=TRUE,  text="✅ Offline metrics computed (MAE, MAP@K, Coverage)"),
        list(done=TRUE,  text="✅ Train/test split implemented (no data leakage)"),
        list(done=FALSE, text="🔲 A/B test designed with correct sample size"),
        list(done=FALSE, text="🔲 Cold-start fallback implemented"),
        list(done=FALSE, text="🔲 Coverage/diversity checked (not just accuracy)"),
        list(done=FALSE, text="🔲 Latency budget met (recs served in <100ms)"),
        list(done=FALSE, text="🔲 Monitoring dashboard deployed (CTR, conversion)"),
        list(done=FALSE, text="🔲 Popularity bias assessed"),
        list(done=FALSE, text="🔲 Model refresh schedule defined")
      )
      tagList(
        lapply(items, function(it) {
          div(style = paste0("padding:7px 0; border-bottom:1px solid #e0f4f2;",
                             "font-size:12.5px; color:",
                             if(it$done) "#008A82" else "#546e7a",";"),
              it$text)
        })
      )
    })

    context_recs <- eventReactive(input$run_context, {
      ctx_time   <- input$ctx_time
      ctx_device <- input$ctx_device
      uid        <- input$ctx_user

      # Genre affinity by time of day
      genre_weights <- list(
        morning   = c(Drama=0.8, `Sci-Fi`=0.9, Action=0.7, Comedy=1.0,
                      Family=1.3, Adventure=1.1, Crime=0.7,
                      Romance=0.8, Horror=0.5, Thriller=0.7),
        afternoon = c(Drama=1.0, `Sci-Fi`=1.1, Action=1.1, Comedy=1.2,
                      Family=1.3, Adventure=1.2, Crime=1.0,
                      Romance=1.0, Horror=0.8, Thriller=1.0),
        evening   = c(Drama=1.3, `Sci-Fi`=1.4, Action=1.3, Comedy=1.0,
                      Family=0.8, Adventure=1.1, Crime=1.3,
                      Romance=1.2, Horror=1.4, Thriller=1.3)
      )
      device_mult <- c(mobile=0.95, desktop=1.0, tv=1.1)

      rated_ids <- sample_ratings %>% filter(user_id==uid) %>% pull(movie_id)
      m_global  <- mean(sample_ratings$rating); C <- 10

      pop_base <- sample_ratings %>%
        filter(!movie_id %in% rated_ids) %>%
        group_by(movie_id) %>%
        summarise(n=n(), avg=mean(rating), .groups="drop") %>%
        mutate(bayes=(C*m_global+avg*n)/(C+n)) %>%
        left_join(sample_movies%>%select(movie_id,title,genre),by="movie_id")

      gw <- genre_weights[[ctx_time]]
      dm <- device_mult[[ctx_device]]

      pop_base <- pop_base %>%
        mutate(
          genre_w  = sapply(genre, function(g) {
            w <- gw[g]; if(is.na(w)) 1.0 else w }),
          ctx_score = bayes * genre_w * dm
        ) %>%
        arrange(desc(ctx_score)) %>%
        head(8)

      pop_base
    }, ignoreNULL=FALSE)

    output$context_recs_result <- renderUI({
      r <- context_recs()
      rows <- lapply(seq_len(nrow(r)), function(i)
        tags$tr(tags$td(paste0("#",i)),
                tags$td(r$title[i]),
                tags$td(r$genre[i]),
                tags$td(round(r$ctx_score[i],3)),
                tags$td(round(r$genre_w[i],2))))
      div(class="result-card",
          tags$h5(paste0("Context-Aware Recs: ",
                         input$ctx_time," · ",input$ctx_device," · User ",input$ctx_user)),
          tags$table(class="algo-table",
                     tags$thead(tags$tr(tags$th("#"),tags$th("Movie"),tags$th("Genre"),
                                        tags$th("Ctx Score"),tags$th("Genre Weight"))),
                     tags$tbody(rows)))
    })
  })
}
