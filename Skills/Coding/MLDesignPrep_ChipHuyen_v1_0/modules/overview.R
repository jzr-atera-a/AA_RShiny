# modules/overview.R
# Tab 1: Overview & Framework — Chip Huyen's Iterative ML System Design

overview_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("ML System Design Interview Prep"),
        tags$h2("Chip Huyen's Production-First Framework — Designing ML Systems (O'Reilly)"),
        div(
          span(class = "hero-badge", "Iterative Process"),
          span(class = "hero-badge", "Production-Ready"),
          span(class = "hero-badge", "10 Modules"),
          span(class = "hero-badge", "Timed Practice")
        )
    ),

    fluidRow(
      column(2, div(class = "metric-card", span(class = "metric-value", textOutput(ns("pct_overall"))), span(class = "metric-label", "Overall Readiness"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "12"),     span(class = "metric-label", "Book Chapters"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "7"),      span(class = "metric-label", "Design Pillars"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "45m"),    span(class = "metric-label", "Interview Slot"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "4"),      span(class = "metric-label", "System Properties"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "Staff+"), span(class = "metric-label", "Target Level")))
    ),

    fluidRow(
      box(title = "🔄 The Iterative ML System Design Loop (Ch. 1–2)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
              HTML("<strong>Huyen's core principle:</strong> ML system design is NOT a one-shot activity. It's an iterative, production-aware process involving constant feedback loops between data, models, and business objectives.")),
          br(),

          fluidRow(
            column(2, div(class = "metric-card", span(class = "metric-value", "①"), span(class = "metric-label", "Scope"))),
            column(2, div(class = "metric-card", span(class = "metric-value", "②"), span(class = "metric-label", "Data"))),
            column(2, div(class = "metric-card", span(class = "metric-value", "③"), span(class = "metric-label", "Model"))),
            column(2, div(class = "metric-card", span(class = "metric-value", "④"), span(class = "metric-label", "Eval"))),
            column(2, div(class = "metric-card", span(class = "metric-value", "⑤"), span(class = "metric-label", "Serve")))
          ),
          br(),

          timeline_entry("0–5m",   "Problem Scoping",       "Business → ML objective. Constraints, scale, latency SLO, success metrics."),
          timeline_entry("5–15m",  "Data Strategy",         "Sources, labelling, format, pipeline (batch vs streaming), class balance, feature store."),
          timeline_entry("15–30m", "Model Architecture",    "Feature engineering, model selection + WHY, training setup, embeddings, loss function."),
          timeline_entry("30–40m", "Evaluation",            "Offline metrics, sliced evaluation, A/B test design, guardrail metrics."),
          timeline_entry("40–45m", "Deployment & Ops",      "Batch vs online, serving infra, monitoring, drift detection, retraining triggers."),

          div(class = "tip-box",
              HTML("<strong>💡 Interview move:</strong> After proposing any design choice, explicitly state which of the 4 system properties it optimises and what trade-off it makes."))
      ),

      box(title = "🏗️ The 4 Properties of Production ML Systems (Ch. 1)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "warn-box",
              HTML("<strong>⚠️ Critical framing:</strong> Every design decision you make in the interview should be justified against these four properties. Stating them proactively is a strong L6+ signal.")),
          br(),

          div(class = "framework-card",
              tags$h5("✅ Reliability"),
              tags$p("System performs correctly even under adversarial conditions. Model accuracy degrades gracefully. Handles malformed inputs, distribution shifts, hardware failures. Discuss: fallback strategies, input validation, circuit breakers.")),
          div(class = "framework-card",
              tags$h5("📈 Scalability"),
              tags$p("Grows with data and traffic without degrading. Think about artifact management, model versioning, experiment tracking at scale, multi-model serving. Horizontal vs vertical scaling.")),
          div(class = "framework-card",
              tags$h5("🔧 Maintainability"),
              tags$p("Code, data, and models should all be versioned. Different contributors (ML engineers, data engineers, DevOps) should coexist. Documentation, reproducibility, feature store ownership.")),
          div(class = "framework-card",
              tags$h5("🔄 Adaptability"),
              tags$p("System updates to changing data distributions and business requirements with minimal disruption. Continual learning, online evaluation, retraining pipelines, model refresh cadence."))
      )
    ),

    fluidRow(
      box(title = "📊 Your Section Readiness", status = "primary", solidHeader = TRUE, width = 12,
          uiOutput(ns("tab_progress_bars"))
      )
    ),

    fluidRow(
      box(title = "⚡ ML Systems vs Traditional Software — Key Differences (Ch. 1)", status = "warning",
          solidHeader = TRUE, width = 12,

          tags$table(class = "table table-hover",
            tags$thead(tags$tr(
              tags$th("Dimension"), tags$th("Traditional Software"), tags$th("ML System"), tags$th("Interview Implication")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$b("Code vs Data")), tags$td("Logic in code; data is input"), tags$td("Data shapes behaviour; code is scaffolding"), tags$td("Data strategy = as important as model choice")),
              tags$tr(tags$td(tags$b("Debugging")),    tags$td("Deterministic stack traces"),    tags$td("Stochastic; data-dependent failures"),    tags$td("Discuss data validation, sliced eval, ablation")),
              tags$tr(tags$td(tags$b("Testing")),      tags$td("Unit / integration tests"),       tags$td("Shadow mode, A/B tests, canary deploys"),  tags$td("Always propose gradual rollout + guardrails")),
              tags$tr(tags$td(tags$b("Versioning")),   tags$td("Code (git)"),                     tags$td("Code + Data + Model + Hyperparams"),       tags$td("Mention MLflow, DVC, model registry")),
              tags$tr(tags$td(tags$b("Failure")),      tags$td("Crashes, exceptions"),             tags$td("Silent degradation, data drift, loops"),  tags$td("Design monitoring pipeline, retraining triggers")),
              tags$tr(tags$td(tags$b("Stakeholders")), tags$td("Eng + PM"),                       tags$td("Eng + PM + Data + Legal + Ethics + Business"), tags$td("Show cross-functional awareness"))
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
        list(id = "framing",             label = "Problem Framing"),
        list(id = "data_engineering",    label = "Data Engineering"),
        list(id = "feature_engineering", label = "Feature Engineering"),
        list(id = "model_development",   label = "Model Development"),
        list(id = "evaluation",          label = "Evaluation & Metrics"),
        list(id = "deployment",          label = "Deployment & Serving"),
        list(id = "monitoring",          label = "Monitoring & Drift"),
        list(id = "design_questions",    label = "Design Questions"),
        list(id = "practice",            label = "Timed Practice")
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
