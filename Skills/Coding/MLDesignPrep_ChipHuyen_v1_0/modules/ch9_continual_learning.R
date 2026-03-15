# modules/ch9_continual_learning.R
# Chapter 9: Continual Learning and Test in Production — Chip Huyen

ch9_continual_learning_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
      tags$h1("Ch.9 — Continual Learning and Test in Production"),
      tags$h2("Keeping models fresh: stateless vs stateful retraining, and how to safely test in live traffic"),
      div(span(class="hero-badge","Continual Learning"),span(class="hero-badge","Stateless Retraining"),
          span(class="hero-badge","Shadow Deployment"),span(class="hero-badge","A/B Testing"),
          span(class="hero-badge","Bandits"))
    ),

    # ── Section 1: Continual Learning ────────────────────────────────────────
    fluidRow(
      box(title="🔄 Continual Learning", status="primary", solidHeader=TRUE, width=12,
        div(class="success-box", HTML("<strong>Huyen's definition:</strong> Continual learning (also called online learning or lifelong learning) is the ability of a model to continue learning from new data in production, without forgetting what it already knows. The goal: <em>models that stay current with minimal human intervention</em>.")),
        br(),
        fluidRow(
          column(6,
            div(class="section-heading-dark","Stateless vs Stateful Retraining"),
            div(class="framework-card",
              tags$h5("Stateless Retraining (Train from Scratch)"),
              tags$p("The model is retrained from random initialisation on a fresh dataset each time. Previous model weights are discarded."),
              tags$ul(
                tags$li(tags$b("Pros:"), " No catastrophic forgetting. Clean slate. Reproducible."),
                tags$li(tags$b("Cons:"), " Expensive — must process all historical data every time. Slow. Cannot keep up with high-velocity data."),
                tags$li(tags$b("Best for:"), " When training is cheap, data volume is manageable, or when the entire distribution has shifted.")
              )
            ),
            div(class="framework-card",
              tags$h5("Stateful Retraining (Fine-tuning / Incremental)"),
              tags$p("The existing model is updated on new data only. Weights are initialised from the previous model."),
              tags$ul(
                tags$li(tags$b("Pros:"), " Much cheaper — only process new data. Faster update cycles. Can keep up with real-time data."),
                tags$li(tags$b("Cons:"), " Risk of catastrophic forgetting (old knowledge overwritten). Requires careful learning rate tuning. Error accumulation over time."),
                tags$li(tags$b("Best for:"), " Large models (LLMs), high-frequency updates (hourly), when historical data is expensive to store.")
              )
            ),
            div(class="tip-box", HTML("<strong>Catastrophic forgetting mitigation:</strong> Elastic Weight Consolidation (EWC) — penalise changes to weights important for previous tasks. Replay buffers — mix new data with a sample of old data. Progressive Neural Networks — freeze old columns, add new lateral connections."))
          ),
          column(6,
            div(class="section-heading-dark","Why Continual Learning?"),
            div(class="framework-card",
              tags$h5("The Cost of Stale Models"),
              tags$p("Huyen argues that for most production ML systems, a model trained 6 months ago is significantly worse than one trained last week — even if the architecture is identical. Staleness compounds:"),
              tags$ul(
                tags$li("User behaviour evolves (new features, trends, terminology)"),
                tags$li("New entities emerge (new products, new users, new fraud patterns)"),
                tags$li("External world changes (regulation, competition, economics)"),
                tags$li("Training data distribution shifts away from production distribution")
              )
            ),
            div(class="framework-card",
              tags$h5("Continual Learning Challenges"),
              tags$ul(
                tags$li(tags$b("Fresh data access:"), " need a continuous pipeline of labelled or naturally-labelled data"),
                tags$li(tags$b("Evaluation:"), " how do you know if the updated model is better without A/B testing every update?"),
                tags$li(tags$b("Training infrastructure:"), " fast retraining requires efficient data pipelines, distributed training, model versioning"),
                tags$li(tags$b("Regulatory compliance:"), " some domains (finance, healthcare) require audit trails — stateful updates complicate this"),
                tags$li(tags$b("Concept drift vs noise:"), " distinguishing genuine distribution change from temporary noise before triggering retraining")
              )
            )
          )
        ),
        br(),
        div(class="section-heading-dark","Four Stages of Continual Learning"),
        fluidRow(
          column(3,
            div(class="framework-card",
              tags$h5("Stage 1 — Manual, Stateless"),
              tags$p("Retrain manually when someone notices degradation. Stateless. Ad hoc. Most teams start here."),
              tags$p(tags$b("Bottleneck:"), " human in the loop. Slow response to drift. Model can be stale for weeks."),
              div(class="stage-pill","Baseline")
            )
          ),
          column(3,
            div(class="framework-card",
              tags$h5("Stage 2 — Automated, Stateless"),
              tags$p("Scheduled retraining pipeline (e.g., weekly). Automated data pull, training, evaluation, deployment. Still stateless."),
              tags$p(tags$b("Bottleneck:"), " fixed schedule. May miss sudden shifts. May retrain unnecessarily."),
              div(class="stage-pill","Standard")
            )
          ),
          column(3,
            div(class="framework-card",
              tags$h5("Stage 3 — Automated, Stateful"),
              tags$p("Triggered retraining on drift signals. Stateful fine-tuning on new data window. Model registry with versioning."),
              tags$p(tags$b("Bottleneck:"), " risk of catastrophic forgetting. Requires careful evaluation after each update."),
              div(class="stage-pill","Advanced")
            )
          ),
          column(3,
            div(class="framework-card",
              tags$h5("Stage 4 — Continual with Context"),
              tags$p("Model updates on each mini-batch in production. Meta-learning (MAML) enables rapid adaptation. Edge models adapt locally."),
              tags$p(tags$b("Bottleneck:"), " very complex. Only justified for highest-velocity, highest-value use cases."),
              div(class="stage-pill","Expert")
            )
          )
        ),
        br(),
        div(class="framework-card",
          tags$h5("How Often to Update Your Models"),
          tags$p("Huyen frames update frequency as a function of: (1) how quickly the data distribution shifts, (2) the cost of retraining, and (3) the impact of staleness on business metrics."),
          tags$table(class="table table-hover",
            tags$thead(tags$tr(tags$th("Domain"),tags$th("Typical Update Frequency"),tags$th("Reason"))),
            tags$tbody(
              tags$tr(tags$td("Ad click prediction"),   tags$td("Daily or hourly"), tags$td("User intent changes rapidly; high revenue impact")),
              tags$tr(tags$td("News feed ranking"),     tags$td("Daily"),           tags$td("News cycle drives rapid topic shift")),
              tags$tr(tags$td("Fraud detection"),       tags$td("Daily-Weekly"),    tags$td("Fraud patterns evolve constantly; adversarial")),
              tags$tr(tags$td("Recommendation (large"),tags$td("Weekly"),           tags$td("User preferences shift slowly; training expensive")),
              tags$tr(tags$td("Medical imaging"),       tags$td("Monthly-Quarterly"),tags$td("Strict validation required; distribution stable")),
              tags$tr(tags$td("Satellite imagery"),     tags$td("Annually"),        tags$td("World changes slowly; data acquisition expensive"))
            )
          )
        )
      )
    ),

    # ── Section 2: Test in Production ────────────────────────────────────────
    fluidRow(
      box(title="🧪 Test in Production", status="warning", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Why test in production?</strong> Offline evaluation is necessary but not sufficient. The gap between offline metrics (AUC, NDCG) and online business metrics (revenue, engagement) can be large. The only way to know if a model change is truly better is to test it with real users.")),
        br(),
        fluidRow(
          column(4,
            div(class="framework-card",
              tags$h5("Shadow Deployment"),
              div(class="stage-pill","Lowest Risk"),
              tags$p("Deploy the new model alongside the production model. Both receive the same requests. The new model's predictions are logged but NOT served to users."),
              tags$p(tags$b("Use for:"), " Validating that the new model infrastructure works. Comparing output distributions between old and new model. Catching bugs before any user exposure."),
              tags$p(tags$b("Limitation:"), " Cannot measure business metric impact (predictions never shown). Expensive — run two models simultaneously."),
              tags$p(tags$b("Duration:"), " Short — hours to days. Once infrastructure validated, move to canary.")
            )
          ),
          column(4,
            div(class="framework-card",
              tags$h5("A/B Testing"),
              div(class="stage-pill","Gold Standard"),
              tags$p("Split user traffic randomly between control (model A) and treatment (model B). Measure business metric impact with statistical significance."),
              tags$p(tags$b("Requirements:"),),
              tags$ul(
                tags$li("Random user assignment (same user always sees same model)"),
                tags$li("Statistical power analysis before launch"),
                tags$li("Minimum detectable effect (MDE) defined upfront"),
                tags$li("Primary metric + guardrail metrics"),
                tags$li("No peeking — decide duration in advance"),
                tags$li("Run for ≥2 weeks to avoid novelty effect")
              ),
              tags$p(tags$b("Limitation:"), " Slow — weeks to reach significance. Cannot test many models simultaneously.")
            )
          ),
          column(4,
            div(class="framework-card",
              tags$h5("Canary Release"),
              div(class="stage-pill","Incremental"),
              tags$p("Route a small percentage (1–5%) of traffic to the new model. Gradually increase as confidence grows. Roll back immediately if guardrails are violated."),
              tags$p(tags$b("Process:"),),
              tags$ul(
                tags$li("1% traffic → monitor for 24h"),
                tags$li("5% traffic → monitor for 48h"),
                tags$li("25% → 50% → 100% with monitoring gates"),
                tags$li("Automated rollback if p99 latency or error rate spikes")
              ),
              tags$p(tags$b("Best for:"), " When you're confident the model is better but want gradual exposure. Complement with A/B test at the 50% split stage.")
            )
          )
        ),
        br(),
        fluidRow(
          column(4,
            div(class="framework-card",
              tags$h5("Interleaving Experiments"),
              tags$p("Instead of routing users to either model A or model B, show both models' recommendations interleaved in the same response (e.g., two ranking systems' results mixed in one list)."),
              tags$p(tags$b("Advantage:"), " Same user sees both — eliminates between-user variance. Much more statistically efficient than A/B testing. Can detect differences with 100× fewer samples."),
              tags$p(tags$b("Used by:"), " Netflix, YouTube for ranking evaluation."),
              tags$p(tags$b("Limitation:"), " Not applicable to all ML problems. Items must be rankable and comparable.")
            )
          ),
          column(4,
            div(class="framework-card",
              tags$h5("Bandits"),
              tags$p("Multi-armed bandit algorithms dynamically allocate traffic to models based on their observed performance. Unlike A/B testing (fixed split), bandits adapt allocation in real time."),
              tags$p(tags$b("Epsilon-greedy:"), " with probability ε explore (random model), with probability 1-ε exploit (best known model). Simple but effective."),
              tags$p(tags$b("Thompson Sampling:"), " Bayesian approach — sample from posterior distribution over model performance. Naturally balances exploration/exploitation."),
              tags$p(tags$b("UCB (Upper Confidence Bound):"), " optimistic strategy — prefer models with high uncertainty. Regret-optimal."),
              tags$p(tags$b("Contextual bandits:"), " select model based on context (user features, time of day). More powerful — personalised model selection per request.")
            )
          ),
          column(4,
            div(class="framework-card",
              tags$h5("Choosing a Testing Strategy"),
              tags$table(class="table",
                tags$thead(tags$tr(tags$th("Strategy"),tags$th("Speed"),tags$th("Risk"),tags$th("Best For"))),
                tags$tbody(
                  tags$tr(tags$td("Shadow"),       tags$td("Fast"),  tags$td("Zero"),   tags$td("Infra validation")),
                  tags$tr(tags$td("Canary"),        tags$td("Medium"),tags$td("Low"),    tags$td("Gradual rollout")),
                  tags$tr(tags$td("A/B Test"),      tags$td("Slow"), tags$td("Medium"), tags$td("Business metric test")),
                  tags$tr(tags$td("Interleaving"),  tags$td("Fast"), tags$td("Low"),    tags$td("Ranking problems")),
                  tags$tr(tags$td("Bandit"),        tags$td("Fast"), tags$td("Low"),    tags$td("Many model variants"))
                )
              ),
              div(class="tip-box", HTML("<strong>Recommended sequence:</strong> Shadow → Canary → A/B Test → 100% rollout. Each stage gates the next."))
            )
          )
        )
      )
    ),

    fluidRow(
      box(title="📊 Self-Assessment: Ch.9", status="success", solidHeader=TRUE, width=12,
        fluidRow(
          column(4,
            sliderInput(ns("sc_cl"),      "Continual learning concepts",  0,10,5),
            sliderInput(ns("sc_stages"),  "4 stages of CL",               0,10,5),
            sliderInput(ns("sc_shadow"),  "Shadow / canary / A/B",        0,10,5),
            sliderInput(ns("sc_bandits"), "Bandits and interleaving",     0,10,5),
            actionButton(ns("save_ch9"), "Save Assessment", class="btn-meta", width="100%")
          ),
          column(8, br(), uiOutput(ns("ch9_result")))
        )
      )
    )
  )
}

ch9_continual_learning_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_ch9, {
      avg <- mean(c(input$sc_cl, input$sc_stages, input$sc_shadow, input$sc_bandits))
      pct <- round(avg * 10)
      prep_manager$update_progress("ch9_continual_learning", pct)
      output$ch9_result <- renderUI({
        div(class=if(pct>=70)"success-box"else"tip-box",
          tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
          if(pct>=80) tags$p("Strong Ch.9 knowledge. In interviews: propose shadow → canary → A/B test as your rollout strategy. Name stateless vs stateful trade-offs explicitly.")
          else tags$p("Review: stateless vs stateful retraining trade-offs, the 4 stages, and the 5 testing strategies.")
        )
      })
      showNotification(paste0("Ch.9: ",pct,"% saved"), type="message")
    })
  })
}
