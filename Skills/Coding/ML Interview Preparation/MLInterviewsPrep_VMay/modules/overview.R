# modules/overview.R
# ML Interviews Prep — Overview & Book Map
# Based on: Machine Learning Interviews — Susan Shu Chang (O'Reilly)

overview_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
      tags$h1("Machine Learning Interviews"),
      tags$h2("Susan Shu Chang (O'Reilly) — Kickstart Your ML and Data Career"),
      div(
        span(class = "hero-badge", "4 Interview Types"),
        span(class = "hero-badge", "6 Chapters"),
        span(class = "hero-badge", "Algorithms + Design"),
        span(class = "hero-badge", "Timed Practice")
      )
    ),

    fluidRow(
      column(2, div(class = "metric-card", span(class = "metric-value", textOutput(ns("pct_overall"))), span(class = "metric-label", "Overall Readiness"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "4"),     span(class = "metric-label", "Interview Types"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "6"),     span(class = "metric-label", "Book Chapters"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "103m"),  span(class = "metric-label", "Ch.3 Content"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "48m"),   span(class = "metric-label", "Ch.4 Content"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "MLE"),   span(class = "metric-label", "Target Role")))
    ),

    fluidRow(
      box(title = "📋 The Four ML Interview Types", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
            HTML("<strong>Chang's core principle:</strong> ML interviews are not one-size-fits-all.
                 Each round tests a different dimension. Know which type you are in — and switch
                 your communication style accordingly.")),
          br(),

          div(class = "framework-card",
            tags$h5("① Behavioural"),
            tags$p("Culture fit, past experience, cross-functional work. Use STAR: Situation, Task, Action, Result.
                   Always tie your ML work to measurable business outcomes — not just model accuracy.")),
          div(class = "framework-card",
            tags$h5("② Coding / Statistics"),
            tags$p("Python fluency (pandas, numpy, sklearn), probability, SQL window functions.
                   Practice implementing ML algorithms from scratch — not just calling library APIs.")),
          div(class = "framework-card",
            tags$h5("③ Technical / Algorithms"),
            tags$p("Deep dive on ML models — covered in Ch.3 and Ch.4. Know trade-offs for every algorithm:
                   when to use it, its failure modes, and how it compares to alternatives.")),
          div(class = "framework-card",
            tags$h5("④ ML System Design"),
            tags$p("Open-ended production design. Structure: requirements → data → model → serving → monitoring.
                   Ch.5 covers this. Every design choice must cite a trade-off, not just a preference."))
      ),

      box(title = "📚 Chapter Map — Full Book", status = "info",
          solidHeader = TRUE, width = 6,

          tags$table(class = "table table-hover",
            tags$thead(tags$tr(
              tags$th("Chapter"), tags$th("Topic"), tags$th("Type"), tags$th("In App")
            )),
            tags$tbody(
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Ch.1")),
                tags$td("Introduction & Interview Process"),
                tags$td("All"),
                tags$td("✅ This tab")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Ch.2")),
                tags$td("The Behavioural Interview"),
                tags$td("Behavioural"),
                tags$td("→ Coming next")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Ch.3")),
                tags$td("Technical: ML Algorithms"),
                tags$td("Technical"),
                tags$td("✅ Ch.3 tab")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Ch.4")),
                tags$td("Technical: Model Training & Eval"),
                tags$td("Technical"),
                tags$td("✅ Ch.4 tab")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Ch.5")),
                tags$td("ML System Design Interview"),
                tags$td("Design"),
                tags$td("→ Coming next")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Ch.6")),
                tags$td("Case Studies & Applications"),
                tags$td("Design + Tech"),
                tags$td("→ Coming next")
              )
            )
          ),
          div(class = "tip-box",
            HTML("<strong>💡 Chang's advice:</strong> Most candidates fail not from lack of knowledge
                 but from poor communication. Practice explaining your reasoning out loud,
                 not just getting the right answer silently."))
      )
    ),

    fluidRow(
      box(title = "📊 Your Section Readiness", status = "primary", solidHeader = TRUE, width = 12,
        uiOutput(ns("tab_progress_bars"))
      )
    ),

    fluidRow(
      box(title = "🧠 Algorithm Coverage Snapshot — Ch.3", status = "warning",
          solidHeader = TRUE, width = 12,

          tags$table(class = "table table-hover",
            tags$thead(tags$tr(
              tags$th("Domain"), tags$th("Key Algorithms"), tags$th("Core Interview Concept"), tags$th("Ch. Ref")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$b("Foundations")),      tags$td("Linear Regression, Logistic Regression"),        tags$td("Bias-variance trade-off, L1 vs L2 regularisation"),          tags$td("Ch.3")),
              tags$tr(tags$td(tags$b("Supervised")),       tags$td("Decision Trees, SVMs, XGBoost, Random Forest"), tags$td("When to ensemble; overfitting vs underfitting fixes"),          tags$td("Ch.3")),
              tags$tr(tags$td(tags$b("NLP")),              tags$td("LSTM, Transformer, BERT, GPT"),                  tags$td("BERT (encoder/bidirectional) vs GPT (decoder/causal)"),       tags$td("Ch.3")),
              tags$tr(tags$td(tags$b("RecSys")),           tags$td("Collaborative Filtering, Matrix Factorisation"), tags$td("Cold start trade-off; explicit vs implicit feedback"),        tags$td("Ch.3")),
              tags$tr(tags$td(tags$b("Computer Vision")), tags$td("CNN, ResNet, GAN, Transfer Learning"),           tags$td("Feature extraction vs fine-tuning; mode collapse in GANs"),   tags$td("Ch.3")),
              tags$tr(tags$td(tags$b("RL")),               tags$td("Q-Learning, Policy Gradient, Actor-Critic"),     tags$td("On-policy vs off-policy; model-free vs model-based"),        tags$td("Ch.3"))
            )
          )
      )
    ),

    fluidRow(
      box(title = "⚡ Prep Priority — Where to Focus First", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              timeline_entry("1", "Statistical Foundations (Ch.3)",
                "Linear regression, bias-variance, regularisation — asked in nearly every screen"),
              timeline_entry("2", "Model Evaluation (Ch.4)",
                "Precision/recall, AUC-ROC, cross-validation, loss functions — universal across all ML roles"),
              timeline_entry("3", "Domain Specialisation (Ch.3)",
                "Deepen one area based on target role: NLP / CV / RecSys")
            ),
            column(4,
              timeline_entry("4", "ML System Design (Ch.5)",
                "Practice 3–5 full design problems end-to-end with timing"),
              timeline_entry("5", "Behavioural Stories (Ch.2)",
                "Prepare 6–8 STAR stories from your past work tied to business metrics"),
              timeline_entry("6", "Mock Interviews",
                "Record yourself answering out loud — communication gaps only appear when spoken")
            ),
            column(4,
              div(class = "warn-box",
                HTML("<strong>⚠️ Common mistake:</strong> Over-indexing on deep learning theory while
                     neglecting model evaluation and system design questions — which dominate
                     senior-level interviews.")),
              div(class = "success-box",
                HTML("<strong>✅ Chang's rule:</strong> For every algorithm you study, be ready to state:
                     (1) what it does, (2) when to use it, (3) one failure mode, (4) an alternative."))
            )
          )
      )
    )
  )
}

overview_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    output$pct_overall <- renderText({
      prep_manager$progress_trigger()
      paste0(prep_manager$get_overall_progress(), "%")
    })

    output$tab_progress_bars <- renderUI({
      prep_manager$progress_trigger()
      tabs <- list(
        list(id = "ch3_ml_algorithms", label = "Ch.3 — ML Algorithms"),
        list(id = "ch4_model_training", label = "Ch.4 — Model Training & Evaluation")
      )
      bars <- lapply(tabs, function(t) {
        pct <- prep_manager$get_progress(t$id)
        col <- progress_colour(pct)
        fluidRow(
          column(3, tags$small(tags$b(t$label))),
          column(7, div(style = "background:rgba(14,165,233,0.1);border-radius:6px;height:12px;",
                        div(style = paste0("width:", pct, "%;background:", col,
                                           ";border-radius:6px;height:12px;transition:width 0.6s;")))),
          column(2, tags$small(style = paste0("color:", col, ";font-weight:700;"), paste0(pct, "%")))
        )
      })
      do.call(tagList, bars)
    })
  })
}
