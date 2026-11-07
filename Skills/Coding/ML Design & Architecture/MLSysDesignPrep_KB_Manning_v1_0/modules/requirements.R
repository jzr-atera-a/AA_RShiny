# modules/requirements.R
# Tab 2: Requirements Engineering — Ch. 1 & 2

requirements_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Requirements Engineering & Problem Scoping"),
        tags$h2("Chapters 1–2 — Translating Business Problems into Concrete ML Specifications"),
        div(span(class="hero-badge","Functional vs Non-Functional"),
            span(class="hero-badge","SLOs"), span(class="hero-badge","Stakeholders"),
            span(class="hero-badge","Constraints"))
    ),

    fluidRow(
      box(title="🎯 Why Requirements Come First (Ch. 1–2)", status="primary", solidHeader=TRUE, width=6,
          div(class="success-box",
              HTML("<strong>K&B's opening principle:</strong> The #1 source of failed ML projects is misaligned requirements — shipping a technically excellent model that solves the wrong problem. Spend 20–25% of your interview time here.")),
          br(),
          div(class="section-heading-dark","Functional Requirements"),
          div(class="framework-card",
              tags$h5("What the system must DO"),
              tags$ul(
                tags$li("Primary task: what are we predicting / generating / ranking?"),
                tags$li("Input format and source: real-time API call, batch file, user event stream?"),
                tags$li("Output format: score, label, ranked list, generated text, bounding box?"),
                tags$li("User-facing contract: what does the end-user see and interact with?"),
                tags$li("Feedback loop: how does user behaviour feed back into the system?")
              )),
          div(class="section-heading-dark","Non-Functional Requirements"),
          div(class="framework-card",
              tags$h5("How the system must PERFORM"),
              tags$ul(
                tags$li(tags$b("Latency:"), " p50 / p95 / p99 SLO. Online inference vs batch."),
                tags$li(tags$b("Throughput:"), " QPS at peak, expected growth, burst capacity."),
                tags$li(tags$b("Freshness:"), " How stale is acceptable? Real-time vs hourly vs daily."),
                tags$li(tags$b("Consistency:"), " Are exact reproducible results needed? (e.g., audit logs)"),
                tags$li(tags$b("Availability:"), " 99.9% vs 99.99% — implications for infra cost."),
                tags$li(tags$b("Privacy / compliance:"), " GDPR, CCPA, HIPAA, sector regulations.")
              ))
      ),

      box(title="💬 The Right Clarifying Questions (K&B Framework)", status="info", solidHeader=TRUE, width=6,
          div(class="tip-box",
              HTML("<strong>💡 K&B interview technique:</strong> Never jump into architecture. Spend the first 5 minutes asking structured clarifying questions. Show you think in systems, not just models.")),
          br(),
          div(class="section-heading-dark","Business Context Questions"),
          tags$ul(
            tags$li("What is the primary business metric we're trying to move?"),
            tags$li("What is the cost of a false positive vs false negative in business terms?"),
            tags$li("Who are the stakeholders? (Product, Engineering, Legal, Finance, Operations)"),
            tags$li("What does the current system do? (rule-based, manual, nothing?)"),
            tags$li("What's the launch timeline and MVP scope?")
          ),
          div(class="section-heading-dark","Scale & Performance Questions"),
          tags$ul(
            tags$li("How many users / events / items at launch? At 2× scale?"),
            tags$li("What's the latency SLO? (p99 acceptable bound)"),
            tags$li("Batch inference or online real-time? Or both?"),
            tags$li("What's the training data cadence and volume?"),
            tags$li("Any geographic or device constraints? (edge ML?)")
          ),
          div(class="section-heading-dark","Data & Label Questions"),
          tags$ul(
            tags$li("What labelled data exists today? Volume? Age? Quality?"),
            tags$li("Are natural labels available? (implicit feedback, click data)"),
            tags$li("What is the label collection delay? (e.g., conversions measured 7 days later)"),
            tags$li("Are there known biases in the existing data pipeline?")
          ),
          div(class="warn-box",
              HTML("<strong>⚠️ K&B warning:</strong> Don't interrogate. Ask 3–5 focused questions, then say 'I'll make some assumptions and flag them as we go.' This shows maturity."))
      )
    ),

    fluidRow(
      box(title="📊 SLO Design — The Non-Functional Spec (Ch. 2)", status="warning", solidHeader=TRUE, width=12,
          fluidRow(
            column(4,
                   div(class="section-heading-dark","Latency SLOs"),
                   tags$table(class="table table-hover",
                     tags$thead(tags$tr(tags$th("System Type"), tags$th("p50"), tags$th("p99"))),
                     tags$tbody(
                       tags$tr(tags$td("Real-time feed ranking"),  tags$td("30ms"),  tags$td("100ms")),
                       tags$tr(tags$td("Search ranking"),          tags$td("50ms"),  tags$td("200ms")),
                       tags$tr(tags$td("Ad auction (bidding)"),    tags$td("5ms"),   tags$td("20ms")),
                       tags$tr(tags$td("LLM chat completion"),     tags$td("500ms"), tags$td("3s (TTFT)")),
                       tags$tr(tags$td("Fraud detection"),         tags$td("20ms"),  tags$td("60ms")),
                       tags$tr(tags$td("Batch recommendation"),    tags$td("N/A"),   tags$td("<1hr total")),
                       tags$tr(tags$td("Document classification"), tags$td("100ms"), tags$td("500ms"))
                     )
                   )
            ),
            column(4,
                   div(class="section-heading-dark","Freshness Requirements"),
                   div(class="framework-card",
                       tags$h5("Real-time (< 1 second)"),
                       tags$p("Fraud signals, ad auction context, search personalisation. Requires online feature serving (Redis, DynamoDB). Cannot use batch-computed features.")),
                   div(class="framework-card",
                       tags$h5("Near-real-time (minutes)"),
                       tags$p("Social feed engagement, trending content. Can use micro-batch streaming (Spark Structured Streaming) or Kafka consumers.")),
                   div(class="framework-card",
                       tags$h5("Batch (hours/daily)"),
                       tags$p("Product recommendations, email campaigns, periodic scoring. Cheaper, simpler, but stale. Pre-compute and cache results."))
            ),
            column(4,
                   div(class="section-heading-dark","K&B's Constraint Taxonomy"),
                   div(class="framework-card",
                       tags$h5("Data Constraints"),
                       tags$p("Cold start (new user/item), data sparsity, label noise, class imbalance, feedback bias (position bias, exposure bias), label delay.")),
                   div(class="framework-card",
                       tags$h5("Compute Constraints"),
                       tags$p("Training budget (GPU hours/cost), serving cost (inference per request), memory footprint, edge device limits (mobile, embedded).")),
                   div(class="framework-card",
                       tags$h5("Regulatory Constraints"),
                       tags$p("GDPR right to explanation, CCPA data deletion, HIPAA PHI handling, EU AI Act risk classification, model card requirements, audit logging."))
            )
          )
      )
    ),

    fluidRow(
      box(title="✍️ Practice: Scope a System", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(4,
                   selectInput(ns("scope_system"),"Choose a system to scope:",
                               choices=c("Social Media Feed Ranking","E-Commerce Recommendation",
                                         "Real-time Fraud Detection","Ride-Share Demand Forecasting",
                                         "Medical Image Diagnosis","Job Posting Matching",
                                         "Email Spam Filter","Customer Support Chatbot (LLM)")),
                   sliderInput(ns("scope_conf"),"Requirements confidence (1–10):",1,10,5),
                   actionButton(ns("save_scope"),"Assess My Requirements", class="btn-meta", width="100%"),
                   br(), br(),
                   uiOutput(ns("scope_feedback"))
            ),
            column(8,
                   div(class="practice-area",
                       tags$b("Exercise: Write a complete requirements specification using the K&B template.")),
                   textAreaInput(ns("scope_notes"), label=NULL, rows=14, width="100%",
                                 placeholder=
"## Functional Requirements
- Primary task (what are we predicting/ranking/generating?):
- Input: (format, source, real-time or batch?)
- Output: (score, label, ranked list, text?)
- User-facing contract:
- Feedback loop:

## Non-Functional Requirements
- Latency SLO (p50/p99):
- Throughput (peak QPS):
- Freshness requirement:
- Availability SLO:

## Scale
- Users/items at launch:
- Growth expectation:
- Training data volume:

## Constraints
- Data constraints (cold start? label delay? class imbalance?):
- Compute budget:
- Regulatory / privacy:
- Timeline / MVP scope:")
            )
          )
      )
    )
  )
}

requirements_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_scope, {
      n <- input$scope_notes
      score <- 0
      if (grepl("functional|task|predict|input|output", n, ignore.case=TRUE))    score <- score + 20
      if (grepl("latency|slo|p99|throughput|qps",        n, ignore.case=TRUE))   score <- score + 20
      if (grepl("freshness|real.time|batch|stale",        n, ignore.case=TRUE))  score <- score + 20
      if (grepl("cold start|label|constraint|bias|imbalance",n,ignore.case=TRUE))score <- score + 20
      if (grepl("privacy|gdpr|regulatory|compliance|budget",  n,ignore.case=TRUE))score <- score+20
      prep_manager$update_progress("requirements", min(score + input$scope_conf*2, 100))
      prep_manager$save_note("requirements_notes", n)
      output$scope_feedback <- renderUI({
        col <- progress_colour(score)
        div(class=if(score>=80)"success-box" else "tip-box",
            tags$h5(style=paste0("color:",col), paste0("Score: ",score,"/100")),
            if(score<20)  tags$p("⚠️ Missing: functional requirements (task, input, output)"),
            if(score<40)  tags$p("⚠️ Missing: latency/throughput SLOs"),
            if(score<60)  tags$p("⚠️ Missing: freshness specification"),
            if(score<80)  tags$p("⚠️ Missing: data/compute constraints"),
            if(score>=80) tags$p("✅ Comprehensive requirements spec — strong interview foundation!")
        )
      })
      showNotification("Requirements saved!", type="message")
    })
  })
}
