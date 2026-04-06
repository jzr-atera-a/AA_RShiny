# modules/ch11_human_side.R
# Chapter 11: The Human Side of Machine Learning — Chip Huyen

ch11_human_side_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
      tags$h1("Ch.11 — The Human Side of Machine Learning"),
      tags$h2("User experience, team structure, and responsible AI — the non-technical pillars that determine production success"),
      div(span(class="hero-badge","User Experience"),span(class="hero-badge","Team Structure"),
          span(class="hero-badge","Responsible AI"),span(class="hero-badge","Fairness"),
          span(class="hero-badge","Privacy"))
    ),

    # ── 1. User Experience ───────────────────────────────────────────────────
    fluidRow(
      box(title="👥 User Experience", status="primary", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Huyen's framing:</strong> ML systems are built for humans to use. The best model in the world fails if the UX makes it difficult to interact with, or if users cannot understand or trust its outputs. UX is not an afterthought — it shapes what data you collect, what labels mean, and how you measure success.")),
        br(),
        fluidRow(
          column(4,
            div(class="framework-card",
              tags$h5("Ensuring User Experience"),
              tags$p("Users interact with ML systems through interfaces, not models directly. Key UX considerations:"),
              tags$ul(
                tags$li(tags$b("Predictability:"), " users develop mental models of how a system works. Sudden model changes (even improvements) can break trust if behaviour changes unexpectedly."),
                tags$li(tags$b("Latency perception:"), " >200ms feels slow; >1s is frustrating. Users attribute slow responses to unreliability. Perceived latency matters as much as actual latency."),
                tags$li(tags$b("Graceful degradation:"), " when the model is uncertain or fails, the UX should degrade gracefully — not crash. Show fallback, ask for clarification, or surface the uncertainty."),
                tags$li(tags$b("Error recovery:"), " make it easy for users to correct model errors. Thumbs up/down, edit suggestions, explicit feedback mechanisms.")
              )
            )
          ),
          column(4,
            div(class="framework-card",
              tags$h5("Dealing with Natural Language Ambiguity"),
              tags$p("NLP systems face a fundamental challenge: the same text can mean different things to different people. Key design considerations:"),
              tags$ul(
                tags$li(tags$b("Clarification dialogues:"), " when intent is ambiguous, ask — don't guess. One clarifying question is better than a wrong answer."),
                tags$li(tags$b("Confidence thresholds:"), " surface model confidence to users. Low-confidence outputs should be flagged differently from high-confidence ones."),
                tags$li(tags$b("Tone and persona:"), " the way a system communicates shapes user expectations. Formal vs casual tone affects whether users trust outputs."),
                tags$li(tags$b("Multi-turn context:"), " users expect the system to remember prior conversation context. State management is a core engineering challenge.")
              )
            )
          ),
          column(4,
            div(class="framework-card",
              tags$h5("Prediction Explainability"),
              tags$p("Users and regulators increasingly demand explanations for model decisions. Explainability is now a product requirement, not just a debugging tool."),
              tags$ul(
                tags$li(tags$b("LIME:"), " locally approximate the model with an interpretable model around a specific prediction."),
                tags$li(tags$b("SHAP:"), " Shapley values — theoretically grounded attribution of each feature's contribution. Model-agnostic."),
                tags$li(tags$b("Attention visualisation:"), " for transformers, show which tokens the model attended to."),
                tags$li(tags$b("Counterfactual explanations:"), " 'Your loan was denied; if your income were £5k higher it would be approved.' Actionable for users."),
                tags$li(tags$b("Decision trees:"), " inherently interpretable. Use when regulators require full transparency (GDPR Article 22).")
              )
            )
          )
        )
      )
    ),

    # ── 2. Team Structure ────────────────────────────────────────────────────
    fluidRow(
      box(title="🏢 Team Structure", status="warning", solidHeader=TRUE, width=7,
        div(class="section-heading-dark","ML Team Roles and Responsibilities"),
        fluidRow(
          column(6,
            div(class="framework-card",
              tags$h5("ML Engineer"),
              tags$p("Owns the full ML lifecycle. Feature engineering, model development, evaluation, deployment, and monitoring. Increasingly expected to be full-stack — from data pipeline to serving infrastructure."),
              tags$p(tags$b("Key skill gap:"), " Traditional data scientists focus on model accuracy; ML engineers must also own reliability, latency, and cost.")
            ),
            div(class="framework-card",
              tags$h5("ML Platform / MLOps Engineer"),
              tags$p("Builds and maintains the infrastructure that ML engineers use — feature stores, training clusters, model registries, monitoring systems. Enables other teams to move faster."),
              tags$p(tags$b("Often undervalued:"), " Huyen argues this is one of the highest-leverage roles in an ML organisation.")
            ),
            div(class="framework-card",
              tags$h5("Data Engineer"),
              tags$p("Designs and maintains data pipelines. ETL/ELT, data quality, schema management. Owns the data that ML models train on. Close collaboration with ML engineers is critical.")
            )
          ),
          column(6,
            div(class="framework-card",
              tags$h5("Subject Matter Expert (SME)"),
              tags$p("Domain expert who provides labelling guidelines, validates model outputs, and helps define success criteria. Critical for high-stakes domains (medical, legal, finance)."),
              tags$p(tags$b("Bottleneck:"), " SME availability is often the limiting factor for labelling throughput.")
            ),
            div(class="framework-card",
              tags$h5("Research Scientist vs Applied ML"),
              tags$p(tags$b("Research:"), " pushes state-of-the-art. Publishes. Optimises for novelty and accuracy. Long time horizons."),
              tags$p(tags$b("Applied:"), " deploys to production. Optimises for reliability, latency, cost, and business impact. Short iteration cycles."),
              tags$p("Most production ML work is applied — Huyen argues the industry needs more ML engineers who can take research and make it production-ready.")
            ),
            div(class="framework-card",
              tags$h5("Product Manager for ML"),
              tags$p("Defines success metrics, manages stakeholder expectations, prioritises feature requests. Must understand ML limitations — 'just add more data' is not always a solution.")
            )
          )
        ),
        br(),
        div(class="section-heading-dark","Organisational Structures"),
        div(class="framework-card",
          tags$h5("Centralised vs Embedded ML Teams"),
          tags$table(class="table table-hover",
            tags$thead(tags$tr(tags$th("Model"),tags$th("Structure"),tags$th("Pros"),tags$th("Cons"))),
            tags$tbody(
              tags$tr(tags$td("Centralised"),  tags$td("One ML team serves all product teams"),    tags$td("Shared infrastructure, expertise concentration"),tags$td("Bottleneck, misaligned incentives, slow")),
              tags$tr(tags$td("Embedded"),     tags$td("ML engineers sit in product teams"),       tags$td("Domain context, fast iteration"),              tags$td("Duplicated infra, inconsistent practices")),
              tags$tr(tags$td("Centre of Excellence"),tags$td("Central platform + embedded applied"),tags$td("Best of both worlds"),                   tags$td("Complex coordination, dual reporting lines"))
            )
          )
        )
      ),

      box(title="⚖️ Responsible AI", status="danger", solidHeader=TRUE, width=5,
        div(class="section-heading-dark","Fairness in ML"),
        div(class="framework-card",
          tags$h5("Types of Bias"),
          tags$ul(
            tags$li(tags$b("Historical bias:"), " training data encodes historical human decisions that were biased. Model learns and perpetuates the bias. Example: hiring models trained on historical hires that favoured certain demographics."),
            tags$li(tags$b("Representation bias:"), " certain groups underrepresented in training data. Model performs poorly on those groups. Example: face recognition failing on darker skin tones."),
            tags$li(tags$b("Measurement bias:"), " proxy labels introduce bias. Using arrest rates as a proxy for crime introduces policing bias into the data."),
            tags$li(tags$b("Aggregation bias:"), " single model applied to heterogeneous groups. A diabetes prediction model trained on average patient behaviour performs poorly for specific subpopulations.")
          )
        ),
        div(class="framework-card",
          tags$h5("Fairness Metrics (Mutually Exclusive)"),
          tags$p("Chouldechova (2017) proved that group fairness criteria are mathematically incompatible when base rates differ across groups. You must choose:"),
          tags$ul(
            tags$li(tags$b("Demographic parity:"), " P(Y_hat=1|A=0) = P(Y_hat=1|A=1). Equal positive prediction rates across groups."),
            tags$li(tags$b("Equal opportunity:"), " equal true positive rate across groups. Equal chance of being correctly predicted positive."),
            tags$li(tags$b("Predictive parity:"), " equal precision across groups. PPV same for all groups."),
            tags$li(tags$b("Calibration:"), " predicted probabilities match actual rates for all groups.")
          ),
          div(class="warn-box", HTML("<strong>No free lunch:</strong> optimising for one fairness criterion often violates another. The choice of fairness metric is a <em>value judgment</em>, not a technical decision."))
        ),
        div(class="framework-card",
          tags$h5("Privacy"),
          tags$ul(
            tags$li(tags$b("Differential Privacy:"), " add calibrated noise to training or outputs. Provides mathematical guarantee that no individual's data is leaked."),
            tags$li(tags$b("Federated Learning:"), " train on device, share only gradients (not raw data). Used by Google Keyboard, Apple's on-device models."),
            tags$li(tags$b("Data anonymisation:"), " k-anonymity, l-diversity. Necessary but often insufficient — re-identification attacks work on aggregated data."),
            tags$li(tags$b("GDPR / CCPA:"), " right to erasure requires ability to unlearn a data point. Machine unlearning is an active research area.")
          )
        ),
        div(class="framework-card",
          tags$h5("Responsible AI in Practice"),
          tags$ul(
            tags$li(tags$b("Model cards:"), " document model intended use, performance on subgroups, known limitations. Google standard."),
            tags$li(tags$b("Datasheets for datasets:"), " document dataset provenance, collection method, known biases. Gebru et al. (2018)."),
            tags$li(tags$b("Impact assessments:"), " before deploying high-stakes models, assess potential harms systematically."),
            tags$li(tags$b("Human-in-the-loop:"), " for high-stakes decisions (credit, healthcare, criminal justice), require human review of model outputs above a risk threshold.")
          )
        )
      )
    ),

    fluidRow(
      box(title="📊 Self-Assessment: Ch.11", status="success", solidHeader=TRUE, width=12,
        fluidRow(
          column(4,
            sliderInput(ns("sc_ux"),      "User experience design for ML", 0,10,5),
            sliderInput(ns("sc_team"),    "Team structures and roles",     0,10,5),
            sliderInput(ns("sc_bias"),    "Bias types and fairness metrics",0,10,5),
            sliderInput(ns("sc_privacy"), "Privacy and responsible AI",    0,10,5),
            actionButton(ns("save_ch11"), "Save Assessment", class="btn-meta", width="100%")
          ),
          column(8, br(), uiOutput(ns("ch11_result")))
        )
      )
    )
  )
}

ch11_human_side_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_ch11, {
      avg <- mean(c(input$sc_ux, input$sc_team, input$sc_bias, input$sc_privacy))
      pct <- round(avg * 10)
      prep_manager$update_progress("ch11_human_side", pct)
      output$ch11_result <- renderUI({
        div(class=if(pct>=70)"success-box"else"tip-box",
          tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
          if(pct>=80) tags$p("Strong Ch.11 knowledge. In interviews: proactively raise fairness, explainability, and privacy as design requirements — not afterthoughts.")
          else tags$p("Review: the four bias types, why fairness metrics are mutually exclusive, and how differential privacy and federated learning address privacy.")
        )
      })
      showNotification(paste0("Ch.11: ",pct,"% saved"), type="message")
    })
  })
}
