# modules/framing.R
# Tab 2: Problem Framing — Ch. 2 Business → ML Objective

framing_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Problem Framing"),
        tags$h2("Chapter 2 — Converting Business Objectives into Well-Defined ML Problems"),
        div(
          span(class = "hero-badge", "Business → ML"),
          span(class = "hero-badge", "Objective Alignment"),
          span(class = "hero-badge", "Constraints"),
          span(class = "hero-badge", "Baselines")
        )
    ),

    fluidRow(
      box(title = "🎯 The Framing Process — 4 Steps (Ch. 2)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
              HTML("<strong>Huyen's insight:</strong> Most ML system failures come from poor problem framing — not poor model choice. Spend 20–25% of interview time here. It's the highest ROI use of minutes.")),
          br(),

          div(class = "framework-card",
              tags$h5("Step 1: Define ML Objective from Business Objective"),
              tags$p("Business: 'Increase ad revenue' → ML: 'Maximise E[revenue] = P(click) × bid × P(conversion | click)'. Always ask: What exactly are we predicting? What is the label?")),
          div(class = "framework-card",
              tags$h5("Step 2: Identify System Constraints"),
              tags$p("Latency budget (p99 SLO), throughput (QPS), memory footprint, interpretability requirements, batch vs online, compute budget. These DICTATE your model choices — not personal preference.")),
          div(class = "framework-card",
              tags$h5("Step 3: Define Decoupled Objectives"),
              tags$p("Multi-objective systems (relevance + diversity + freshness) should train SEPARATE models and combine at serving time. Don't train one model to predict multiple conflicting objectives simultaneously. Key Huyen principle.")),
          div(class = "framework-card",
              tags$h5("Step 4: Establish a Baseline"),
              tags$p("What's the simplest thing that could work? Random baseline, most-frequent class, heuristic rules. Set a clear bar before jumping to neural networks. 'Good enough' is business-context dependent."))
      ),

      box(title = "💬 Clarifying Questions to Ask", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "section-heading-dark", "Business Context"),
          tags$ul(
            tags$li("What is the business objective and how is it currently measured?"),
            tags$li("What does success look like in 6 months? 1 year?"),
            tags$li("Who are the end users and what do they care about?"),
            tags$li("What is the cost of a false positive vs false negative?"),
            tags$li("Are there regulatory or privacy constraints (GDPR, CCPA, HIPAA)?")
          ),
          div(class = "section-heading-dark", "Scale & Performance"),
          tags$ul(
            tags$li("What is the expected QPS / DAU at launch and at peak?"),
            tags$li("What is the latency budget? (p50, p99 SLO)"),
            tags$li("Batch prediction or real-time inference? Mixed workload?"),
            tags$li("What compute resources are available?")
          ),
          div(class = "section-heading-dark", "Data & Labels"),
          tags$ul(
            tags$li("What labelled data exists today? Volume? Quality?"),
            tags$li("Are natural labels available (implicit feedback)?"),
            tags$li("What is the label collection cadence and cost?"),
            tags$li("Are there cold-start scenarios (new users / new items)?")
          ),
          div(class = "tip-box",
              HTML("<strong>💡 Pro tip:</strong> Ask one focused clarifying question at a time. Pause for the answer, then proceed. Don't interrogate the interviewer with 10 questions at once."))
      )
    ),

    fluidRow(
      box(title = "🔀 ML Task Type Decision Matrix", status = "warning",
          solidHeader = TRUE, width = 12,

          tags$table(class = "table table-hover",
            tags$thead(tags$tr(
              tags$th("Problem Type"), tags$th("Output"), tags$th("Loss Function"),
              tags$th("Classic Examples"), tags$th("Ch. Reference")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$span(class="stage-pill","Classification")), tags$td("Class label"), tags$td("Cross-entropy, focal loss"), tags$td("Spam, content moderation, intent classification"), tags$td("Ch. 2, 6")),
              tags$tr(tags$td(tags$span(class="stage-pill","Regression")),     tags$td("Continuous score"), tags$td("MSE, MAE, Huber"), tags$td("Price prediction, demand forecasting, engagement time"), tags$td("Ch. 2, 6")),
              tags$tr(tags$td(tags$span(class="stage-pill","Ranking")),        tags$td("Ordered list"), tags$td("LambdaRank, ListNet, BPR"), tags$td("Search, news feed, recommendations"), tags$td("Ch. 2, 7")),
              tags$tr(tags$td(tags$span(class="stage-pill","Generation")),     tags$td("Text/image/code"), tags$td("Next-token CE, RLHF"), tags$td("Chatbots, ad copy, code completion"), tags$td("Ch. 6, 12")),
              tags$tr(tags$td(tags$span(class="stage-pill","Multi-task")),     tags$td("Multiple outputs"), tags$td("Weighted sum of losses"), tags$td("Feed ranking (clicks+shares+saves), ads (CTR+CVR)"), tags$td("Ch. 2, 6")),
              tags$tr(tags$td(tags$span(class="stage-pill","Anomaly Det.")),   tags$td("Anomaly score"), tags$td("Reconstruction error, isolation forest"), tags$td("Fraud detection, system health, content safety"), tags$td("Ch. 8"))
            )
          )
      )
    ),

    fluidRow(
      box(title = "✍️ Practice: Write Your Framing", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   selectInput(ns("framing_topic"), "Choose a System to Frame:",
                               choices = c("Video Recommendation System","Product Search Ranking",
                                           "Real-time Fraud Detection","LLM Customer Support (RAG)",
                                           "News Feed Ranking","Ad CTR Prediction",
                                           "Content Moderation","Supply Demand Forecasting")),
                   sliderInput(ns("framing_conf"), "Confidence in framing (1–10):", 1, 10, 5),
                   actionButton(ns("save_framing"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8,
                   div(class = "practice-area",
                       tags$b("Practice: Frame the selected system using the 4-step process."),
                       textAreaInput(ns("framing_notes"), label = NULL, rows = 10, width = "100%",
                                     placeholder = "## 1. Business Objective\n\n## 2. ML Objective (what exactly are we predicting?)\n\n## 3. System Constraints (latency, scale, interpretability)\n\n## 4. Decoupled Objectives (if multi-objective)\n\n## 5. Baseline Approach"),
                       uiOutput(ns("framing_feedback"))
                   )
            )
          )
      )
    )
  )
}

framing_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_framing, {
      notes <- input$framing_notes
      conf  <- input$framing_conf
      score <- 0
      if (grepl("business|objective|goal|metric|success", notes, ignore.case = TRUE))  score <- score + 20
      if (grepl("latency|qps|scale|constraint|slo|budget", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("label|predict|classif|regress|rank",       notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("decouple|multi.task|separate|independent",  notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("baseline|simple|heuristic|rule",            notes, ignore.case = TRUE)) score <- score + 20

      prep_manager$update_progress("framing", min(score + conf * 3, 100))
      prep_manager$save_note("framing_notes", notes)

      output$framing_feedback <- renderUI({
        div(class = if (score >= 80) "success-box" else "tip-box",
            tags$h5(paste0("Framing Score: ", score, "/100")),
            if (score < 20) tags$p("⚠️ Missing: business → ML objective translation"),
            if (score < 40) tags$p("⚠️ Missing: system constraints (latency, scale, QPS)"),
            if (score < 60) tags$p("⚠️ Missing: label / task type definition"),
            if (score < 80) tags$p("⚠️ Missing: decoupled objectives or baseline"),
            if (score >= 80) tags$p("✅ All framing steps covered! Strong setup for the architecture discussion.")
        )
      })
      showNotification("Framing practice saved!", type = "message")
    })
  })
}
