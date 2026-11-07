# modules/practice.R
# Tab 10: Timed Practice — 45-min simulation with K&B 6-step framework scoring

practice_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Timed Design Practice"),
        tags$h2("45-Minute Interview Simulation — K&B's 6-Step Production ML Design Framework"),
        div(span(class="hero-badge","45 Min Timer"), span(class="hero-badge","6-Step Framework"),
            span(class="hero-badge","Auto-Score"), span(class="hero-badge","Gap Analysis"))
    ),

    fluidRow(
      box(title="⚙️ Session Setup", status="primary", solidHeader=TRUE, width=4,
          selectInput(ns("system_topic"), "Choose System to Design:",
                      choices=c(
                        "Content Recommendation Feed (Social Platform)",
                        "Product Search Ranking (E-Commerce)",
                        "Real-Time Fraud Detection (Payments)",
                        "Customer Support Chatbot (RAG + LLM)",
                        "Job Recommendation System (Marketplace)",
                        "Ad CTR Prediction System",
                        "Medical Image Classification",
                        "Ride-Sharing Demand Forecasting",
                        "Content Moderation at Scale",
                        "Entity Resolution (Product Catalogue)"
                      )),
          br(),
          div(class="timer-card", uiOutput(ns("timer_display"))),
          br(),
          fluidRow(
            column(6, actionButton(ns("start_timer"),  "▶ Start", class="btn-meta", width="100%", icon=icon("play"))),
            column(6, actionButton(ns("reset_timer"),  "↺ Reset", class="btn-meta", width="100%"))
          ),
          br(),
          sliderInput(ns("self_conf"),"Self-assessed confidence (1-10):", 1, 10, 5),
          br(),
          actionButton(ns("score_design"), "📊 Score My Design", class="btn-meta", width="100%", icon=icon("chart-bar")),
          br(), br(),
          uiOutput(ns("score_output")),
          br(),
          uiOutput(ns("score_history_ui"))
      ),

      box(title="✍️ Design Notes — K&B 6-Step Framework", status="success", solidHeader=TRUE, width=8,
          div(class="practice-area",
              tags$b("Instructions:"), " Work through all 6 steps. The auto-scorer checks keyword coverage across each step. Aim to finish all 6 within 45 minutes."),
          textAreaInput(ns("design_text"), label=NULL, rows=25, width="100%",
                        placeholder=
"## STEP 1: REQUIREMENTS & SCOPING (0–5 min)
### Functional requirements:
- Primary task (predicting what?):
- Input format + source:
- Output format:
### Non-functional SLOs:
- Latency (p99 SLO):
- Throughput (peak QPS):
- Freshness requirement:
### Scale: (users, items, events/sec)
### Constraints: (cold start, label delay, privacy, compute budget)

## STEP 2: DATA PIPELINE (5–15 min)
- Ingestion: batch (Spark) vs streaming (Kafka+Flink)? Justify.
- Format: Parquet for training. Schema: event schema definition.
- Data quality: validation checks, schema evolution handling.
- Labelling: natural labels / hand labels / programmatic. Label delay?

## STEP 3: FEATURE ENGINEERING & STORE (15–22 min)
- Features: list key features (user, item, context, cross features).
- Encoding: numerical transforms, categorical encoding, embeddings.
- Feature store: offline store (Parquet) + online store (Redis). Point-in-time joins.
- Train/serve skew prevention: single canonical feature computation function.

## STEP 4: MODEL ARCHITECTURE & TRAINING (22–30 min)
- Architecture choice + justification (constraints-driven!):
- Loss function + why:
- Training setup: batch size, optimizer, distributed training (if needed):
- Embeddings: dimensions, initialisation, update strategy:
- Multi-task: separate models or joint? (K&B recommendation: separate):

## STEP 5: EVALUATION & TESTING (30–38 min)
- Offline metric + why appropriate for this task:
- Sliced evaluation: which subgroups, automated discovery:
- Testing strategy: shadow mode → canary (1%) → ramp:
- A/B test design: randomisation unit, guardrail metrics, duration:

## STEP 6: SERVING & MONITORING (38–45 min)
- Serving architecture: online vs batch. Model server (Triton/vLLM?).
- Compression: quantisation / distillation / LoRA if applicable.
- Monitoring: data drift (PSI), prediction distribution, latency SLO.
- Retraining triggers: time-based / drift-based / performance-based.
- Rollback strategy: automated rollback condition.")
      )
    ),

    fluidRow(
      box(title="📖 Interview Principles — K&B Production-First Mindset", status="warning", solidHeader=TRUE, width=12,
          fluidRow(
            column(3, div(class="framework-card",
                tags$h5("Requirements Before Architecture"),
                tags$p("NEVER jump to model selection. Spend the first 5 minutes clarifying. Show you think in systems: SLOs, scale, constraints, stakeholders."))),
            column(3, div(class="framework-card",
                tags$h5("Constraints Drive Decisions"),
                tags$p("Every choice must be justified: 'I chose LightGBM because: tabular data, latency SLO of 30ms p99, and the team's existing infrastructure is Python-based.'"))),
            column(3, div(class="framework-card",
                tags$h5("Failure Modes First"),
                tags$p("Proactively name what can break: data drift, train/serve skew, cold start, label delay, position bias. K&B call this 'production thinking'."))),
            column(3, div(class="framework-card",
                tags$h5("Close the Loop"),
                tags$p("Every design must include: monitoring strategy, retraining triggers, rollback plan. K&B: 'Shipping is not deploying — deploying is running it reliably for 2 years.'")))
          )
      )
    )
  )
}

practice_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    timer_start  <- reactiveVal(NULL)
    timer_active <- reactiveVal(FALSE)

    output$timer_display <- renderUI({
      invalidateLater(1000)
      if (!timer_active() || is.null(timer_start())) {
        return(tagList(
          span(class="timer-value", "45:00"),
          div(class="timer-label","Ready — select system and start")))
      }
      elapsed   <- as.numeric(difftime(Sys.time(), timer_start(), units="secs"))
      remaining <- max(0, 45*60 - elapsed)
      mins      <- floor(remaining / 60)
      secs      <- floor(remaining %% 60)
      phase <- if (remaining > 40*60) "Step 1: Requirements & Scoping" else
               if (remaining > 30*60) "Step 2–3: Data Pipeline & Features" else
               if (remaining > 22*60) "Step 4: Model Architecture" else
               if (remaining > 15*60) "Step 5: Evaluation & Testing" else
               if (remaining > 7*60)  "Step 6: Serving & Monitoring" else
               "Wrap up!"
      col <- if (remaining < 300) "#ef4444" else if (remaining < 600) "#f59e0b" else "#ffb49a"
      tagList(
        span(style=paste0("font-size:2.8em;font-weight:800;font-family:'JetBrains Mono',monospace;display:block;line-height:1;color:",col,";"),
             sprintf("%02d:%02d", mins, secs)),
        div(class="timer-label", phase)
      )
    })

    observeEvent(input$start_timer, {
      timer_start(Sys.time()); timer_active(TRUE)
      showNotification(paste0("⏱ Timer started — ", input$system_topic), type="message")
    })
    observeEvent(input$reset_timer, {
      timer_active(FALSE); timer_start(NULL)
      showNotification("Timer reset.", type="message")
    })

    observeEvent(input$score_design, {
      text <- input$design_text
      conf <- input$self_conf
      timer_active(FALSE)

      criteria <- list(
        list(label="Step 1: Requirements & SLOs",
             kw=c("latency","slo","qps","throughput","freshness","scale","constraint","functional","cold start","label delay"),
             weight=18),
        list(label="Step 2: Data Pipeline",
             kw=c("kafka","spark","batch","streaming","parquet","schema","quality","flink","ingestion","lineage"),
             weight=17),
        list(label="Step 3: Feature Engineering & Store",
             kw=c("feature store","embedding","encoding","offline","online","redis","point-in-time","skew","backfill","categorical"),
             weight=17),
        list(label="Step 4: Model & Training",
             kw=c("model","architecture","loss","train","distributed","embedding","lightgbm","transformer","two-tower","multi-task"),
             weight=17),
        list(label="Step 5: Evaluation",
             kw=c("ndcg","auc","recall","sliced","shadow","canary","a/b","guardrail","offline metric","evaluation"),
             weight=16),
        list(label="Step 6: Serving & Monitoring",
             kw=c("serving","monitor","drift","psi","retrain","rollback","triton","compression","quantis","canary"),
             weight=15)
      )

      total <- 0
      breakdown <- lapply(criteria, function(c) {
        hits <- sum(sapply(c$kw, function(kw) grepl(kw, text, ignore.case=TRUE)))
        s    <- min(c$weight, round((hits / length(c$kw)) * c$weight * 2.2))
        total <<- total + s
        list(label=c$label, score=s, max=c$weight, hits=hits, kw_count=length(c$kw))
      })
      total <- min(100, total)

      prep_manager$add_practice_score("practice", total, input$system_topic)
      prep_manager$update_progress("practice", min(total + conf * 2, 100))

      output$score_output <- renderUI({
        breakdown_ui <- lapply(breakdown, function(b) {
          pct_step <- b$score / b$max
          cls <- if(pct_step >= 0.7) "success-box" else if(pct_step > 0.3) "tip-box" else "warn-box"
          icon_str <- if(pct_step >= 0.7) "✅" else if(pct_step > 0.3) "💡" else "⚠️"
          div(class=cls,
              tags$b(paste0(icon_str," ",b$label,": ",b$score,"/",b$max)),
              if(pct_step < 0.3) tags$small(paste0(" — Low coverage. Expand this step.")) else
              if(pct_step < 0.7) tags$small(paste0(" — Good start. Add more detail.")) else
                                  tags$small(paste0(" — Well covered.")))
        })
        overall_cls <- if(total >= 80) "success-box" else if(total >= 60) "tip-box" else "warn-box"
        tagList(
          div(style="text-align:center;padding:14px;",
              tags$h2(style=paste0("color:",progress_colour(total)), paste0(total, " / 100")),
              tags$p(tags$b(paste0("System: ",input$system_topic)))
          ),
          do.call(tagList, breakdown_ui),
          div(class=overall_cls,
              tags$b("Overall: "),
              if(total>=80) "✅ Excellent production-quality design! All K&B steps covered." else
              if(total>=60) "💡 Good structure. Focus on the lower-scoring sections above." else
                            "⚠️ Review K&B's 6-step framework. Several sections have low coverage.")
        )
      })

      output$score_history_ui <- renderUI({
        scores <- prep_manager$get_scores("practice")
        if (!length(scores)) return(NULL)
        recent <- tail(scores, 5)
        div(class="framework-card",
            tags$h5("Score History (last 5 sessions)"),
            do.call(tagList, lapply(rev(recent), function(s) {
              col <- progress_colour(s$score)
              tags$p(style="margin:3px 0;font-size:11px;",
                     tags$b(style=paste0("color:",col), paste0(s$score,"/100")),
                     " — ", s$label,
                     tags$small(style="color:#3a4b5c;margin-left:6px;",
                                format(s$timestamp,"%b %d %H:%M")))
            }))
        )
      })

      showNotification(paste0("Design scored: ", total, "/100"), type="message")
    })
  })
}
