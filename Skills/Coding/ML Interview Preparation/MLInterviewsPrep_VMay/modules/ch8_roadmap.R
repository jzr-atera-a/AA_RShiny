# modules/ch8_roadmap.R
# Ch.8: Tying It All Together — Your Interview Roadmap

ch8_roadmap_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
      tags$h1("Chapter 8 — Your Interview Roadmap"),
      tags$h2("Tying It All Together: Prep Checklist, Efficient Learning & Mindset — Susan Shu Chang"),
      div(
        span(class = "hero-badge", "Prep Checklist"),
        span(class = "hero-badge", "Roadmap Template"),
        span(class = "hero-badge", "Efficient Learning"),
        span(class = "hero-badge", "Burnout Avoidance"),
        span(class = "hero-badge", "Impostor Syndrome")
      )
    ),

    # ── Checklist & Roadmap ───────────────────────────────────────────────────
    fluidRow(
      box(title = "✅ Interview Preparation Checklist (Ch.8)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
            HTML("<strong>Chang's synthesis:</strong> This chapter consolidates everything in the book
                 into a concrete, actionable checklist. Use it as your weekly tracker
                 during the 4–12 weeks before your first target interview.")),
          br(),

          div(class = "section-heading-dark", "Technical Foundations"),
          tags$ul(
            tags$li("ML algorithms — can explain each with 4-point structure (what, when, limitation, alternative)"),
            tags$li("Bias-variance trade-off and regularisation mechanics"),
            tags$li("Supervised / unsupervised / RL taxonomy — with examples"),
            tags$li("NLP: LSTM → Transformer → BERT vs GPT comparison"),
            tags$li("CV: CNN architecture, transfer learning decision rule"),
            tags$li("RecSys: CF vs content-based vs matrix factorisation trade-offs"),
            tags$li("RL: Q-learning, policy gradient, on-policy vs off-policy")
          ),

          div(class = "section-heading-dark", style = "margin-top:10px;", "Model Training & Evaluation"),
          tags$ul(
            tags$li("Loss function selection for each task type — with justification"),
            tags$li("Data preprocessing: missing data, scaling, encoding, leakage"),
            tags$li("Evaluation metrics: precision/recall, AUC, NDCG — and when to use each"),
            tags$li("Validation strategies: k-fold, walk-forward, stratified"),
            tags$li("Baseline-first principle and model versioning (MLflow)")
          ),

          div(class = "section-heading-dark", style = "margin-top:10px;", "Coding"),
          tags$ul(
            tags$li("15+ LeetCode Easy problems solved without hints"),
            tags$li("10+ LeetCode Medium problems in target domains"),
            tags$li("10+ SQL problems (window functions, aggregations, CTEs)"),
            tags$li("Implement linear regression, k-means, precision/recall from scratch in numpy"),
            tags$li("pandas fluency: groupby, merge, pivot, apply, vectorised operations")
          ),

          div(class = "section-heading-dark", style = "margin-top:10px;", "Deployment & MLOps"),
          tags$ul(
            tags$li("End-to-end ML pipeline — can describe all 7 stages"),
            tags$li("Serving patterns: real-time vs batch vs streaming vs on-device"),
            tags$li("Monitoring: data drift, prediction drift, retraining triggers"),
            tags$li("Cloud providers: know the ML platform for GCP, AWS, Azure")
          )
      ),

      box(title = "🗺️ Interview Roadmap Template (Ch.8)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "section-heading-dark", "Behavioural"),
          tags$ul(
            tags$li("8–10 STAR stories prepared and practised out loud"),
            tags$li("Each story usable for 3+ different question types"),
            tags$li("Specific results quantified in every story"),
            tags$li("Company research done — know their ML products and recent work"),
            tags$li("Big Tech LP/values alignment prepared (Amazon LPs, Google Googleyness)")
          ),
          br(),

          div(class = "framework-card",
            tags$h5("Roadmap Template — Weekly Sprint Structure"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Week"), tags$th("Focus"), tags$th("Deliverable"))),
              tags$tbody(
                tags$tr(tags$td("1–2"),  tags$td("ML Algorithms foundations"),      tags$td("Ch.3 complete + 4-point structures for 10 algorithms")),
                tags$tr(tags$td("3–4"),  tags$td("Model training & evaluation"),    tags$td("Ch.4 complete + 3 eval plans practised")),
                tags$tr(tags$td("5–6"),  tags$td("Coding — Python + SQL"),          tags$td("30 LeetCode + 10 SQL + 3 from-scratch implementations")),
                tags$tr(tags$td("7–8"),  tags$td("Deployment & system design"),     tags$td("Ch.6 complete + 3 design problems end-to-end")),
                tags$tr(tags$td("9–10"), tags$td("Behavioural stories"),            tags$td("8 STAR stories written, practised out loud and timed")),
                tags$tr(tags$td("11–12"), tags$td("Mock interviews"),               tags$td("2 technical + 2 behavioural mocks per week; record and review"))
              )
            )),

          div(class = "tip-box",
            HTML("<strong>💡 Chang's timing advice:</strong> Start mock interviews at week 9 minimum —
                 not earlier. Mock interviews without sufficient base knowledge build bad habits
                 and erode confidence. Build the knowledge first, then simulate the pressure.")),

          div(class = "framework-card",
            tags$h5("Checklist — Behavioural"),
            tags$ul(
              tags$li("8–10 STAR stories prepared covering: success, failure, conflict, learning, leadership"),
              tags$li("Each story timed to under 2 minutes"),
              tags$li("All results quantified"),
              tags$li("Company-specific research completed"),
              tags$li("Big Tech LP / values alignment prepared")
            ))
      )
    ),

    # ── Efficient Learning ────────────────────────────────────────────────────
    fluidRow(
      box(title = "🧠 Efficient Interview Preparation (Ch.8)", status = "warning",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              div(class = "framework-card",
                tags$h5("Become a Better Learner"),
                tags$ul(
                  tags$li(tags$b("Active recall:"), " close notes and retrieve from memory — more effective than re-reading"),
                  tags$li(tags$b("Spaced repetition:"), " review material at increasing intervals — 1 day, 3 days, 1 week, 2 weeks"),
                  tags$li(tags$b("The Feynman technique:"), " explain a concept in simple language as if teaching a 10-year-old — gaps become obvious"),
                  tags$li(tags$b("Interleaving:"), " mix different topic types in a single session — more effective than blocked practice"),
                  tags$li(tags$b("Teach it:"), " explaining to someone else is the highest-quality retention activity")
                ),
                div(class = "success-box",
                  HTML("<strong>✅ For ML interviews:</strong> After reading about each algorithm,
                       close the book and try to explain it out loud using the 4-point structure.
                       This is the single most effective prep activity."))
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Time Management and Accountability"),
                tags$ul(
                  tags$li(tags$b("Time-box sessions:"), " 90-minute deep work blocks with no phone — then break"),
                  tags$li(tags$b("Daily minimum:"), " 1 hour of focused prep every day beats 8 hours on weekends"),
                  tags$li(tags$b("Track progress:"), " mark completed topics — visible progress is motivating"),
                  tags$li(tags$b("Accountability partner:"), " pair with someone else interviewing — weekly check-ins"),
                  tags$li(tags$b("Prioritise ruthlessly:"), " interview prep is finite. Cut low-ROI topics — hardest LeetCode, obscure algorithms — and add time to communication practice")
                )
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Avoid Burnout: It Is Costly"),
                tags$p("Chang dedicates a section to this because burnout derails more candidates than gaps in technical knowledge."),
                tags$ul(
                  tags$li(tags$b("Set a daily stop time:"), " define when prep ends — and enforce it"),
                  tags$li(tags$b("Rest days:"), " take 1–2 rest days per week completely off prep"),
                  tags$li(tags$b("Physical health:"), " sleep, exercise, and nutrition directly affect cognitive performance"),
                  tags$li(tags$b("Watch for signs:"), " loss of motivation, dreading sessions, declining retention — rest, do not push through"),
                  tags$li(tags$b("Perspective:"), " one interview cycle is not your entire career. Rejection is information, not identity")
                ),
                div(class = "warn-box",
                  HTML("<strong>⚠️ Burnout signal:</strong> If you are doing 6+ hours of prep daily
                       and feel worse after each session, you are burning out — not getting better.
                       Quality over quantity, always."))
              )
            )
          )
      )
    ),

    # ── Impostor Syndrome ─────────────────────────────────────────────────────
    fluidRow(
      box(title = "🧘 Impostor Syndrome (Ch.8)", status = "primary",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(6,
              div(class = "framework-card",
                tags$h5("What Impostor Syndrome Looks Like in ML Interview Prep"),
                tags$ul(
                  tags$li("'I don't know enough to apply for this role yet' — the feeling of never being ready"),
                  tags$li("Comparing yourself to researchers and staff engineers when the role does not require that depth"),
                  tags$li("Attributing past successes to luck rather than skill and effort"),
                  tags$li("Over-preparing specific technical details while ignoring communication and framing"),
                  tags$li("Avoiding applying until conditions are 'perfect'")
                )
              ),
              div(class = "warn-box",
                HTML("<strong>⚠️ Chang's honest note:</strong> Impostor syndrome is especially
                     common in ML because the field is broad and fast-moving. No one knows
                     everything. Interviewers are not testing omniscience — they are testing
                     how you think, communicate, and learn."))
            ),
            column(6,
              div(class = "framework-card",
                tags$h5("How to Work Through It"),
                tags$ul(
                  tags$li(tags$b("Evidence journal:"), " list 3 concrete things you have accomplished each week of prep"),
                  tags$li(tags$b("Reframe 'not knowing':"), " 'I don't know yet' is different from 'I can't know'"),
                  tags$li(tags$b("Apply before you feel ready:"), " the interview process itself is a learning accelerator"),
                  tags$li(tags$b("Separate performance from identity:"), " a bad interview tells you about one interview — not your capability"),
                  tags$li(tags$b("Mentor conversations:"), " talking to someone 1–2 years ahead of you in career normalises the uncertainty")
                )
              ),
              div(class = "success-box",
                HTML("<strong>✅ Chang's reframe:</strong> Feeling uncertain is not evidence
                     that you are unqualified — it is evidence that you take the work seriously.
                     The most dangerous candidates are those who are overconfident, not those
                     who are working hard and feeling uncertain."))
            )
          )
      )
    ),

    # ── Self-Assessment ───────────────────────────────────────────────────────
    fluidRow(
      box(title = "✍️ Roadmap Self-Assessment", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              div(class = "section-heading-dark", "Rate your overall prep readiness"),
              sliderInput(ns("road_tech"),   "Technical foundations complete",      0, 10, 5),
              sliderInput(ns("road_code"),   "Coding practice complete",            0, 10, 5),
              sliderInput(ns("road_deploy"), "Deployment & MLOps knowledge",        0, 10, 5),
              sliderInput(ns("road_behav"),  "Behavioural stories prepared",        0, 10, 5),
              sliderInput(ns("road_mock"),   "Mock interviews completed",           0, 10, 5),
              actionButton(ns("save_road"), "Save Roadmap Assessment", class = "btn-meta", width = "100%")
            ),
            column(8,
              br(),
              uiOutput(ns("road_feedback")),
              br(),
              div(class = "info-box-plain",
                HTML("<strong>Using this app as your roadmap tracker:</strong> Complete each chapter module
                     (Ch.3 through Ch.9), submit the self-assessment on each, and return to the
                     Overview tab to see your overall readiness progress bar update in real time."))
            )
          )
      )
    )
  )
}

ch8_roadmap_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_road, {
      avg <- mean(c(input$road_tech, input$road_code, input$road_deploy,
                    input$road_behav, input$road_mock))
      pct <- round(avg * 10)
      prep_manager$update_progress("ch8_roadmap", min(pct + input$road_mock, 100))

      output$road_feedback <- renderUI({
        div(class = if (pct >= 70) "success-box" else "tip-box",
          tags$h3(style = paste0("color:", progress_colour(pct), ";font-size:2em;font-weight:800;"),
            paste0(pct, "% Interview Ready")),
          if (pct >= 80)
            tags$div(
              tags$p(tags$b("Strong across all dimensions. Focus on:")),
              tags$ul(
                tags$li("Running at least 2 mock interviews per week from now until your first interview"),
                tags$li("Timing your STAR stories — each must be under 2 minutes"),
                tags$li("Company-specific research for your top 3 target companies")
              )
            )
          else
            tags$div(
              tags$p(tags$b("Priority areas before you are interview-ready:")),
              tags$ul(
                if (input$road_tech   < 7) tags$li("Technical: complete Ch.3 and Ch.4 modules and practice explaining algorithms out loud"),
                if (input$road_code   < 7) tags$li("Coding: reach 30+ LeetCode problems solved + 10 SQL"),
                if (input$road_deploy < 7) tags$li("Deployment: complete Ch.6 module and design 2 production systems end-to-end"),
                if (input$road_behav  < 7) tags$li("Behavioural: write and time all 8 STAR stories"),
                if (input$road_mock   < 7) tags$li("Start mock interviews — even imperfect ones accelerate preparation")
              )
            )
        )
      })
      showNotification("Ch.8 roadmap assessment saved!", type = "message")
    })
  })
}
