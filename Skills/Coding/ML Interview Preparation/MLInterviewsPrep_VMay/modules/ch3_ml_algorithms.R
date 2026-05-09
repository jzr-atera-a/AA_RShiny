# modules/ch3_ml_algorithms.R
# Ch.3: Technical Interview — Machine Learning Algorithms

ch3_ml_algorithms_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
      tags$h1("Chapter 3 — ML Algorithms"),
      tags$h2("Technical Interview: Machine Learning Algorithms — Susan Shu Chang"),
      div(
        span(class = "hero-badge", "Foundations"),
        span(class = "hero-badge", "NLP & Transformers"),
        span(class = "hero-badge", "Recommender Systems"),
        span(class = "hero-badge", "Computer Vision"),
        span(class = "hero-badge", "Reinforcement Learning")
      )
    ),

    fluidRow(
      box(title = "📐 Statistical & Foundational Techniques (Ch.3)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
            HTML("<strong>Chang's framing:</strong> Before naming any algorithm, interviewers want to
                 hear you define the problem type — supervised vs unsupervised, classification vs
                 regression — and justify your choice against the constraints.")),
          br(),

          div(class = "framework-card",
            tags$h5("Linear Regression — Key Properties"),
            tags$p("Predicts a continuous target Y as a weighted sum of inputs X."),
            tags$ul(
              tags$li(tags$b("Loss:"), " Mean Squared Error — penalises large errors quadratically"),
              tags$li(tags$b("Optimisation:"), " closed-form normal equation or gradient descent"),
              tags$li(tags$b("Assumption:"), " linear relationship; independent features"),
              tags$li(tags$b("Failure mode:"), " multicollinearity inflates coefficient variance")
            )),

          div(class = "framework-card",
            tags$h5("Bias-Variance Trade-off"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Problem"), tags$th("Train Error"), tags$th("Test Error"), tags$th("Fix"))),
              tags$tbody(
                tags$tr(tags$td(tags$span(class = "stage-pill", "Underfitting")), tags$td("High"), tags$td("High"), tags$td("More complex model")),
                tags$tr(tags$td(tags$span(class = "stage-pill", "Overfitting")),  tags$td("Low"),  tags$td("High"), tags$td("Regularisation, more data")),
                tags$tr(tags$td(tags$span(class = "stage-pill", "Good fit")),     tags$td("Low"),  tags$td("Low"),  tags$td("Validate on held-out set"))
              )
            )),

          div(class = "framework-card",
            tags$h5("Regularisation — L1 vs L2"),
            tags$ul(
              tags$li(tags$b("L1 (Lasso):"), " adds |w| penalty — drives sparse weights, automatic feature selection"),
              tags$li(tags$b("L2 (Ridge):"), " adds w² penalty — shrinks all weights, handles multicollinearity"),
              tags$li(tags$b("Elastic Net:"), " combines both — balances sparsity with stability")
            )),

          div(class = "warn-box",
            HTML("<strong>⚠️ Common mistake:</strong> Saying regularisation 'prevents overfitting' without
                 explaining the mechanism. The correct answer: regularisation adds a penalty term
                 to the loss that discourages large weights, reducing effective model complexity."))
      ),

      box(title = "🏷️ Learning Paradigms (Ch.3)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Supervised Learning"),
            tags$p("Training data has labelled (X, Y) pairs."),
            tags$ul(
              tags$li(tags$b("Classification:"), " predict discrete class — spam, fraud, sentiment"),
              tags$li(tags$b("Regression:"), " predict continuous value — price, demand, score"),
              tags$li(tags$b("Key constraint:"), " labelling is expensive — often the real bottleneck")
            )),

          div(class = "framework-card",
            tags$h5("Unsupervised Learning"),
            tags$p("No labels — model discovers structure in X alone."),
            tags$ul(
              tags$li(tags$b("Clustering:"), " k-means, DBSCAN — group similar examples"),
              tags$li(tags$b("Dimensionality reduction:"), " PCA, t-SNE, UMAP"),
              tags$li(tags$b("Semi-supervised:"), " small labelled set + large unlabelled — pseudo-labelling"),
              tags$li(tags$b("Self-supervised:"), " model generates its own supervision signal (masked tokens, contrastive)")
            )),

          div(class = "framework-card",
            tags$h5("Reinforcement Learning"),
            tags$p("Agent learns by interacting with environment and receiving rewards."),
            tags$ul(
              tags$li(tags$b("Agent, Environment, State, Action, Reward, Policy")),
              tags$li(tags$b("Exploration vs exploitation:"), " epsilon-greedy balances the trade-off"),
              tags$li(tags$b("Interview anchor:"), " ground in a use case — recommender system where action = which item to show, reward = click/conversion")
            )),

          div(class = "tip-box",
            HTML("<strong>💡 Pro tip:</strong> For any algorithm question, Chang recommends the
                 4-point structure: (1) what it does, (2) when to use it,
                 (3) one limitation, (4) one real-world example."))
      )
    ),

    fluidRow(
      box(title = "💬 NLP Algorithms — LSTM to GPT (Ch.3)", status = "primary",
          solidHeader = TRUE, width = 7,

          div(class = "framework-card",
            tags$h5("LSTM — Long Short-Term Memory"),
            tags$p("Solves vanishing gradient problem in RNNs for long sequences."),
            tags$ul(
              tags$li(tags$b("Forget gate:"), " decides what to discard from cell state"),
              tags$li(tags$b("Input gate:"), " decides what new information to store"),
              tags$li(tags$b("Output gate:"), " controls what to pass to next step"),
              tags$li(tags$b("Limitation:"), " sequential — cannot parallelise across time steps")
            )),

          div(class = "framework-card",
            tags$h5("Transformer — Self-Attention"),
            tags$ul(
              tags$li(tags$b("Self-attention:"), " each token attends to all others, computing weighted sum via Q/K/V matrices"),
              tags$li(tags$b("Multi-head attention:"), " multiple heads capture different relationship types"),
              tags$li(tags$b("Positional encoding:"), " injects sequence order — attention is permutation-invariant without it"),
              tags$li(tags$b("Complexity:"), " O(n²) in sequence length — costly for long documents"),
              tags$li(tags$b("Advantage over LSTM:"), " fully parallelisable; captures long-range dependencies better")
            )),

          div(class = "framework-card",
            tags$h5("BERT vs GPT"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Property"), tags$th("BERT"), tags$th("GPT"))),
              tags$tbody(
                tags$tr(tags$td("Architecture"),     tags$td("Encoder only"),            tags$td("Decoder only")),
                tags$tr(tags$td("Training task"),    tags$td("Masked language model"),   tags$td("Next token prediction")),
                tags$tr(tags$td("Directionality"),   tags$td("Bidirectional"),            tags$td("Left-to-right (causal)")),
                tags$tr(tags$td("Best for"),         tags$td("Classification, NER, QA"), tags$td("Generation, completion")),
                tags$tr(tags$td("Fine-tuning"),      tags$td("Add classification head"), tags$td("Prompt or fine-tune"))
              )
            ))
      ),

      box(title = "🎯 NLP Sample Questions (Ch.3)", status = "info",
          solidHeader = TRUE, width = 5,

          div(class = "section-heading-dark", "Sample Questions from Ch.3"),
          div(class = "framework-card",
            tags$ul(
              tags$li("Why did transformers replace LSTMs for most NLP tasks?"),
              tags$li("What problem does positional encoding solve?"),
              tags$li("When would you choose BERT over GPT?"),
              tags$li("Explain attention — describe the Q, K, V matrices."),
              tags$li("How does masked language modelling work as a pre-training objective?")
            )),
          div(class = "success-box",
            HTML("<strong>✅ Chang's structure:</strong> For each NLP model state:
                 (1) architecture, (2) training objective, (3) a real use case where it excels,
                 (4) one limitation. This demonstrates fluency, not just recall.")),
          div(class = "tip-box",
            HTML("<strong>💡 ELI5 attention:</strong> Each word looks at all other words and decides
                 which are relevant — it computes a weighted sum of values based on
                 query-key similarity."))
      )
    ),

    fluidRow(
      box(title = "🎬 Recommender Systems (Ch.3)", status = "warning",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              div(class = "framework-card",
                tags$h5("Collaborative Filtering"),
                tags$ul(
                  tags$li(tags$b("User-based:"), " find similar users, recommend what they liked"),
                  tags$li(tags$b("Item-based:"), " find similar items to what user engaged with"),
                  tags$li(tags$b("Explicit ratings:"), " star ratings — high signal, sparse"),
                  tags$li(tags$b("Implicit ratings:"), " clicks, views, time — abundant but noisy"),
                  tags$li(tags$b("Cold start:"), " fails for new users / new items — key interview trap")
                ))),
            column(4,
              div(class = "framework-card",
                tags$h5("Content-Based Filtering"),
                tags$ul(
                  tags$li(tags$b("Item features:"), " genre, keywords, embeddings, metadata"),
                  tags$li(tags$b("User profile:"), " built from features of items they engaged with"),
                  tags$li(tags$b("Advantage:"), " no item cold start — content always available"),
                  tags$li(tags$b("Limitation:"), " over-specialises — misses serendipitous discovery")
                ),
                div(class = "tip-box", HTML("<strong>💡</strong> Most production systems are hybrid — combine both signals."))
              )),
            column(4,
              div(class = "framework-card",
                tags$h5("Matrix Factorisation"),
                tags$ul(
                  tags$li(tags$b("Core idea:"), " decompose user-item matrix R ≈ U × V^T"),
                  tags$li(tags$b("Latent factors:"), " learned embeddings capturing taste/style"),
                  tags$li(tags$b("ALS:"), " alternating least squares — scalable training"),
                  tags$li(tags$b("Used in:"), " Netflix, Spotify, YouTube recommendation layers")
                )
              ))
          ),
          div(class = "warn-box",
            HTML("<strong>⚠️ Interview trap:</strong> Don't say collaborative filtering is better than
                 content-based without naming the cold start trade-off. Always pair each approach
                 with its failure mode."))
      )
    ),

    fluidRow(
      box(title = "👁️ Computer Vision (Ch.3)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("CNNs — Convolutional Neural Networks"),
            tags$ul(
              tags$li(tags$b("Convolution:"), " learned filter slides over image, detecting local features"),
              tags$li(tags$b("Pooling:"), " reduces spatial size, adds translation invariance"),
              tags$li(tags$b("Depth:"), " early layers = edges; later layers = objects"),
              tags$li(tags$b("Architectures:"), " VGG, ResNet (skip connections), EfficientNet, ViT")
            )),

          div(class = "framework-card",
            tags$h5("Transfer Learning Decision Rule"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Data available"), tags$th("Strategy"), tags$th("What to do"))),
              tags$tbody(
                tags$tr(tags$td("Very little"),   tags$td("Feature extraction"), tags$td("Freeze all; add new head")),
                tags$tr(tags$td("Moderate"),      tags$td("Partial fine-tune"),  tags$td("Unfreeze top layers; small LR")),
                tags$tr(tags$td("Large dataset"), tags$td("Full fine-tune"),     tags$td("Unfreeze all; risk forgetting"))
              )
            )),

          div(class = "framework-card",
            tags$h5("GANs — Generative Adversarial Networks"),
            tags$ul(
              tags$li(tags$b("Generator:"), " creates fake images from noise"),
              tags$li(tags$b("Discriminator:"), " learns to tell real from fake"),
              tags$li(tags$b("Training:"), " minimax game — generator improves until discriminator can't distinguish"),
              tags$li(tags$b("Mode collapse:"), " generator produces limited variety — key failure mode to name")
            ))
      ),

      box(title = "🤖 Reinforcement Learning Algorithms (Ch.3)", status = "warning",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Q-Learning (Value-Based)"),
            tags$ul(
              tags$li(tags$b("Q(s,a):"), " expected cumulative reward from state s, taking action a"),
              tags$li(tags$b("Bellman equation:"), " Q(s,a) = r + γ × max Q(s', a')"),
              tags$li(tags$b("DQN:"), " neural network approximates Q for large state spaces"),
              tags$li(tags$b("Epsilon-greedy:"), " explore with prob ε, exploit with prob 1-ε")
            )),

          div(class = "framework-card",
            tags$h5("Policy Methods & Comparisons"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Type"), tags$th("Optimises"), tags$th("Best for"))),
              tags$tbody(
                tags$tr(tags$td("Value-based"),   tags$td("Q(s,a)"),         tags$td("Discrete actions — games")),
                tags$tr(tags$td("Policy-based"),  tags$td("π(a|s) directly"), tags$td("Continuous actions — robotics")),
                tags$tr(tags$td("Actor-Critic"),  tags$td("Policy + value"),  tags$td("Most production RL"))
              )
            )),

          div(class = "framework-card",
            tags$h5("On-Policy vs Off-Policy"),
            tags$ul(
              tags$li(tags$b("On-policy (PPO, SARSA):"), " learns from current policy's own experience — stable"),
              tags$li(tags$b("Off-policy (Q-learning, DQN):"), " learns from experience replay — sample efficient")
            ))
      )
    ),

    fluidRow(
      box(title = "✍️ Practice: Algorithm Explanation", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              selectInput(ns("algo_topic"), "Choose an algorithm to explain:",
                choices = c(
                  "Linear Regression vs Logistic Regression",
                  "L1 vs L2 Regularisation",
                  "Random Forest vs XGBoost",
                  "BERT vs GPT",
                  "Collaborative Filtering cold start problem",
                  "CNN transfer learning decision",
                  "Q-Learning Bellman equation",
                  "Transformer self-attention mechanism"
                )),
              sliderInput(ns("algo_conf"), "Confidence in this topic (1–10):", 1, 10, 5),
              actionButton(ns("save_algo"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8,
              div(class = "practice-area",
                tags$b("Practice: Explain the selected topic using Chang's 4-point structure."),
                textAreaInput(ns("algo_notes"), label = NULL, rows = 8, width = "100%",
                  placeholder = "## What it does\n\n## When to use it\n\n## One failure mode / limitation\n\n## Comparison to an alternative"),
                uiOutput(ns("algo_feedback"))
              )
            )
          )
      )
    )
  )
}

ch3_ml_algorithms_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_algo, {
      notes <- input$algo_notes
      conf  <- input$algo_conf
      score <- 0
      if (grepl("what|does|predict|classif|regress|output",    notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("when|use|scenario|appropriate|suitable",      notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("limit|fail|problem|disadvantage|weakness",    notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("compare|vs|alternative|instead|better|worse", notes, ignore.case = TRUE)) score <- score + 25

      prep_manager$update_progress("ch3_ml_algorithms", min(score + conf * 3, 100))
      prep_manager$save_note("ch3_notes", notes)

      output$algo_feedback <- renderUI({
        div(class = if (score >= 75) "success-box" else "tip-box",
          tags$h5(paste0("Structure Score: ", score, "/100")),
          if (score < 25) tags$p("⚠️ Missing: what the algorithm does / its output"),
          if (score < 50) tags$p("⚠️ Missing: when to use it / appropriate scenario"),
          if (score < 75) tags$p("⚠️ Missing: a limitation or failure mode"),
          if (score < 100) tags$p("⚠️ Missing: comparison to an alternative approach"),
          if (score >= 75) tags$p("✅ All 4 structure points covered — strong algorithm communication!")
        )
      })
      showNotification("Ch.3 assessment saved!", type = "message")
    })
  })
}
