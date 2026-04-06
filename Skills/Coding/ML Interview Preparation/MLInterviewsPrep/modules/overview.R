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
      column(2, div(class = "metric-card", span(class = "metric-value", "4"),    span(class = "metric-label", "Interview Types"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "9"),    span(class = "metric-label", "Book Chapters"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "14"),   span(class = "metric-label", "App Modules"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "4"),    span(class = "metric-label", "Use Cases"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "MLE"),  span(class = "metric-label", "Target Role")))
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
                tags$td("ML Roles and the Interview Process"),
                tags$td("All"),
                tags$td("✅ Ch.1 tab")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Ch.2")),
                tags$td("ML Job Application and Resume"),
                tags$td("All"),
                tags$td("✅ Ch.2 tab")
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
                tags$td("Technical Interview: Coding"),
                tags$td("Coding"),
                tags$td("✅ Ch.5 tab")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Ch.6")),
                tags$td("Model Deployment & End-to-End ML"),
                tags$td("MLOps"),
                tags$td("✅ Ch.6 tab")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Ch.7")),
                tags$td("Behavioral Interviews"),
                tags$td("Behavioural"),
                tags$td("✅ Ch.7 tab")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Ch.8")),
                tags$td("Your Interview Roadmap"),
                tags$td("All"),
                tags$td("✅ Ch.8 tab")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Ch.9")),
                tags$td("Post-Interview and Follow-up"),
                tags$td("All"),
                tags$td("✅ Ch.9 tab")
              )
            )
          ),
          div(class = "section-heading-dark", style = "margin-top:14px;", "Use Cases — Production Systems"),
          tags$table(class = "table table-hover",
            tags$thead(tags$tr(
              tags$th("Use Case"), tags$th("Domain"), tags$th("Key Algorithms"), tags$th("Chang Chapters")
            )),
            tags$tbody(
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Banking")),
                tags$td("UK Next-Best-Action (GCP + PEGA)"),
                tags$td("XGBoost, Thompson Sampling, Multi-class"),
                tags$td("Ch.3, Ch.4, Ch.6")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Social")),
                tags$td("Meta-Scale Recommender (Two-Tower + DLRM)"),
                tags$td("Two-Tower ANN, Wide-and-Deep, Multi-task"),
                tags$td("Ch.3, Ch.4, Ch.6")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "Quant")),
                tags$td("Systematic Equities Alpha Signals"),
                tags$td("LightGBM, Walk-Forward CV, Low-SNR"),
                tags$td("Ch.3, Ch.4, Ch.6")
              ),
              tags$tr(
                tags$td(tags$span(class = "stage-pill", "AV")),
                tags$td("Autonomous Vehicle Infrastructure"),
                tags$td("YOLOv8, XGBoost, Isaac Sim, Safety Slicing"),
                tags$td("Ch.3, Ch.4, Ch.6")
              )
            )
          ),
          div(class = "tip-box",
            HTML("<strong>💡 How to use the Use Cases:</strong> Each case study applies all 7 stages of the ML lifecycle
                 to a real production system — mapped directly to Chang's chapters. Work through them
                 <em>after</em> completing the chapter modules. Use them as mock system design practice:
                 cover the answer panels and try to design each stage before revealing.")
          )
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
        list(id = "ch1_ml_roles",                  label = "Ch.1 — ML Roles & Interview Process"),
        list(id = "ch2_job_application",            label = "Ch.2 — Job Application & Resume"),
        list(id = "ch3_ml_algorithms",              label = "Ch.3 — ML Algorithms"),
        list(id = "ch4_model_training",             label = "Ch.4 — Model Training & Evaluation"),
        list(id = "ch5_coding",                     label = "Ch.5 — Coding Interview"),
        list(id = "ch6_deployment",                 label = "Ch.6 — Deployment & MLOps"),
        list(id = "ch7_behavioural",                label = "Ch.7 — Behavioural Interviews"),
        list(id = "ch8_roadmap",                    label = "Ch.8 — Interview Roadmap"),
        list(id = "ch9_post_interview",             label = "Ch.9 — Post-Interview"),
        list(id = "banking_case_study",             label = "Use Case — Banking: Next-Best-Action"),
        list(id = "social_recommender_case_study",  label = "Use Case — Social Media Recommender"),
        list(id = "quant_trading_case_study",       label = "Use Case — Quant Trading: Alpha Signals"),
        list(id = "av_infrastructure_case_study",   label = "Use Case — AV Infrastructure")
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
