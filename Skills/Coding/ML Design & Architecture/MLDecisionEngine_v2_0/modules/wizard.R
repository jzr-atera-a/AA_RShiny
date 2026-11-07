# modules/wizard.R — Decision Wizard (v2 with Design Pattern settings)

wizard_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
      tags$h1("ML System + Design Pattern Decision Engine"),
      tags$h2("Answer 7 questions to get a ranked shortlist of ML systems AND the optimal design patterns"),
      div(
        span(class="hero-badge","52 ML Methods"),
        span(class="hero-badge","30 Design Patterns"),
        span(class="hero-badge","12 Method Groups"),
        span(class="hero-badge","6 Pattern Groups"),
        span(class="hero-badge","Huyen, K&B & Lakshmanan")
      ),
      tags$p(style="color:rgba(255,255,255,0.75);font-size:12px;margin-top:10px;",
        "Based on Designing ML Systems (Huyen 2022), ML System Design (K&B 2025), and ML Design Patterns (Lakshmanan, Robinson & Munn 2020). All three books integrated.")
    ),

    # ── Row 1: Industry + Problem Type ───────────────────────────────────────
    fluidRow(
      box(title="Step 1 — Industry & Sector", status="primary", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>Who is this for?</strong> Filters methods and patterns to those with proven production deployments in your sector.")),
        br(),
        selectInput(ns("industry"), "Industry / Sector:",
          choices=c("Select..."="", setNames(names(INDUSTRIES), names(INDUSTRIES))), width="100%"),
        uiOutput(ns("industry_hint"))
      ),
      box(title="Step 2 — ML Problem Type", status="primary", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>What are you predicting?</strong> Huyen Ch.2: framing the problem correctly is the single most important design decision.")),
        br(),
        selectInput(ns("problem_type"), "ML Problem Type:",
          choices=c("Select..."="", setNames(names(PROBLEM_TYPES), names(PROBLEM_TYPES))), width="100%"),
        uiOutput(ns("problem_hint"))
      )
    ),

    # ── Row 2: Data Profile ──────────────────────────────────────────────────
    fluidRow(
      box(title="Step 3 — Data Profile", status="warning", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>What does your data look like?</strong> Data type and volume are primary drivers of both model selection and design pattern choice. Huyen Ch.3-4 and K&B Ch.3.")),
        br(),
        selectInput(ns("data_type"), "Primary Data Type:",
          choices=c("Select..."="", setNames(names(DATA_TYPES), names(DATA_TYPES))), width="100%"),
        br(),
        selectInput(ns("data_volume"), "Data Volume:",
          choices=c("Select..."="", setNames(names(DATA_VOLUMES), names(DATA_VOLUMES))), width="100%")
      ),
      box(title="Step 4 — Operational Requirements", status="warning", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>Production behaviour constraints.</strong> Latency SLO and serving mode constrain both architecture choices and which design patterns are applicable. Huyen Ch.7 and K&B Ch.7.")),
        br(),
        selectInput(ns("latency"), "Latency Requirement:",
          choices=c("Select..."="", setNames(names(LATENCY_REQS), names(LATENCY_REQS))), width="100%"),
        br(),
        selectInput(ns("serving"), "Serving Mode:",
          choices=c("Select..."="", setNames(names(SERVING_MODES), names(SERVING_MODES))), width="100%"),
        br(),
        selectInput(ns("retraining_trigger"), "Retraining Strategy:",
          choices=c("Select..."="", setNames(names(RETRAINING_TRIGGERS), names(RETRAINING_TRIGGERS))), width="100%")
      )
    ),

    # ── Row 3: Constraints ───────────────────────────────────────────────────
    fluidRow(
      box(title="Step 5 — Non-Functional & Compliance", status="danger", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>Regulatory, fairness, and explainability constraints.</strong> These directly determine which Responsible AI design patterns are mandatory. Huyen Ch.11 and K&B Ch.2.")),
        br(),
        selectInput(ns("interpretability"), "Interpretability Requirement:",
          choices=c("Select..."="", setNames(names(INTERPRETABILITY), names(INTERPRETABILITY))), width="100%"),
        br(),
        checkboxGroupInput(ns("compliance"), "Compliance Requirements:",
          choices=c(
            "GDPR / CCPA (data privacy)"="gdpr",
            "FCA / Basel III (financial regulation)"="fca",
            "HIPAA (healthcare)"="hipaa",
            "AV Act 2024 / ISO 21448 (autonomous vehicles)"="avact",
            "None"="none"),
          selected="none")
      ),
      box(title="Step 6 — Team & Infrastructure", status="danger", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>Team maturity and infrastructure capability.</strong> Pattern complexity (Low to High) must match what your team can realistically implement. Huyen Ch.10.")),
        br(),
        selectInput(ns("team_maturity"), "Team ML Maturity:",
          choices=c("Select..."="", setNames(names(TEAM_MATURITY), names(TEAM_MATURITY))), width="100%"),
        br(),
        selectInput(ns("max_complexity"), "Maximum Pattern Complexity You Can Handle:",
          choices=c(
            "Select..."="",
            "Low only (rule-based, simple transforms)" = "low",
            "Low to Medium (feature stores, versioning)" = "medium",
            "Up to High (pipelines, two-phase, federated)" = "high",
            "Any complexity" = "any"),
          width="100%"),
        br(),
        checkboxGroupInput(ns("pattern_priorities"), "Design Pattern Priorities (select all that apply):",
          choices=c(
            "Data consistency / train-serve skew prevention" = "skew",
            "Scale to billions of candidates" = "scale",
            "Regulatory compliance & explainability" = "compliance",
            "Handle class imbalance / rare events" = "imbalance",
            "Reproducible experiments & splits" = "reproduce",
            "Automated retraining & drift monitoring" = "drift",
            "Efficient large-model training" = "training",
            "Serving latency optimisation" = "latency_opt"
          ))
      )
    ),

    # ── Row 4: Class imbalance optional ─────────────────────────────────────
    fluidRow(
      box(title="Step 7 — Data Challenges (optional)", status="info", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Optional but improves recommendations.</strong> Specific data challenges map directly to design patterns.")),
        fluidRow(
          column(4,
            checkboxGroupInput(ns("data_challenges"), "Data Challenges Present:",
              choices=c(
                "Class imbalance (< 10% positive rate)" = "imbalance",
                "High cardinality categoricals (>1M unique values)" = "high_card",
                "Multiple data modalities" = "multimodal",
                "Schema / feature changes over time" = "schema_evo",
                "Streaming / real-time events" = "streaming",
                "Distributed / privacy-sensitive data" = "federated",
                "Cold-start problem (new users/items)" = "cold_start",
                "Small labelled dataset" = "small_data"
              ))
          ),
          column(4,
            checkboxGroupInput(ns("mlops_maturity"), "MLOps Capabilities Available:",
              choices=c(
                "Feature store (Feast, Vertex AI)" = "feature_store",
                "Model registry (MLflow, Vertex AI)" = "model_registry",
                "ML pipeline orchestration (Airflow, Kubeflow)" = "pipeline",
                "Drift monitoring (Evidently, Arize)" = "monitoring",
                "Distributed training (multi-GPU/TPU)" = "distributed"
              ))
          ),
          column(4,
            div(class="tip-box", HTML("<strong>💡 Pattern selection tip:</strong> Your compliance requirements directly mandate certain patterns:<ul><li>GDPR → Explainable Predictions (RA-02) mandatory</li><li>FCA → Heuristic Benchmark (RA-01) + Model Versioning (RE-07) mandatory</li><li>AV Act → Fairness Lens (RA-03) + Continued Model Evaluation (RS-03) mandatory</li><li>Real-time serving → Stateless Serving Function (RS-01) required</li><li>Drift concerns → Continued Model Evaluation (RS-03) + Workflow Pipeline (RE-05)</li></ul>"))
          )
        )
      )
    ),

    # ── Run button ───────────────────────────────────────────────────────────
    fluidRow(
      box(width=12, style="text-align:center;padding:20px;",
        actionButton(ns("run"), "🔍  Find Optimal ML System + Design Patterns",
          class="btn-meta",
          style="font-size:16px;padding:14px 48px;border-radius:10px;"),
        br(), br(),
        uiOutput(ns("validation_msg"))
      )
    )
  )
}

wizard_server <- function(id, wizard_inputs) {
  moduleServer(id, function(input, output, session) {

    output$industry_hint <- renderUI({
      if(is.null(input$industry) || input$industry == "") return(NULL)
      hints <- list(
        finance="Finance: GBTs dominate for credit/fraud; Explainable Predictions (RA-02) + Heuristic Benchmark (RA-01) are mandatory. GDPR Article 22 + FCA require Model Versioning (RE-07).",
        trading="Trading: IC not R² is the metric. FTRL for HFT; RL for execution. Windowed Inference (RE-04) for rolling features. Heuristic Benchmark (RA-01) mandatory — walk-forward split required.",
        social="Social Media: Two-Tower + FAISS for retrieval; Two Phase Predictions (RS-04) + Feature Store (RE-06) are core patterns. Fairness Lens (RA-03) for EU DSA compliance.",
        retail="Retail: ETS/Prophet for forecasting; Two-Tower for recommendation. Two Phase Predictions (RS-04), Feature Store (RE-06), Batch Serving (RS-02) for pre-compute.",
        av="AV: Safety-critical — Fairness Lens (RA-03) + Explainable Predictions (RA-02) + Continued Model Evaluation (RS-03) are mandatory under AV Act 2024. Cascade (PR-04) for detection pipelines.",
        energy="Energy: ARIMA/ETS/N-BEATS for forecasting; Workflow Pipeline (RE-05) for automated retraining. Physics-Informed NNs use Useful Overfitting (TL-02).",
        general="General: Start with Heuristic Benchmark (RA-01). Apply Transform (RE-01) + Model Versioning (RE-07) for any production deployment. Repeatable Splitting (RE-02) always."
      )
      val <- INDUSTRIES[input$industry]
      msg <- hints[[val]]
      if(is.null(msg)) return(NULL)
      div(class="tip-box", HTML(paste0("<strong>Industry pattern guidance:</strong> ", msg)))
    })

    output$problem_hint <- renderUI({
      if(is.null(input$problem_type) || input$problem_type == "") return(NULL)
      hints <- list(
        classification="Classification: Rebalancing (PR-06) if imbalanced; Reframing (PR-01) if regression-to-classification; Heuristic Benchmark (RA-01) is mandatory before ML deployment.",
        regression="Regression: Transform (RE-01) for skew-prevention; Repeatable Splitting (RE-02) with temporal split for time-series; Explainable Predictions (RA-02) for stakeholder trust.",
        forecasting="Forecasting: Repeatable Splitting (RE-02) mandatory (chronological only); Continued Model Evaluation (RS-03) for drift; Workflow Pipeline (RE-05) for automated retraining.",
        ranking="Ranking/LTR: Two Phase Predictions (RS-04) for retrieval+ranking; Feature Store (RE-06) for pre-computed signals; Heuristic Benchmark (RA-01) vs most-popular baseline.",
        recommendation="Recommendation: Two Phase Predictions (RS-04) + Feature Store (RE-06) + Embeddings (DP-02). Batch Serving (RS-02) for pre-compute; Continued Model Evaluation (RS-03) for drift.",
        anomaly="Anomaly: Rebalancing (PR-06) for extreme class imbalance; Neutral Class (PR-05) for uncertain detections; Continued Model Evaluation (RS-03) for threshold drift.",
        causal="Causal: Fairness Lens (RA-03) for treatment effect equity; Explainable Predictions (RA-02) for coefficient attribution; Heuristic Benchmark (RA-01) vs ATE baseline.",
        generation="Generation: Transfer Learning (TL-01) from foundation models; Checkpoints (TL-03) for fine-tuning; Explainable Predictions (RA-02) for RAG attribution.",
        sequential="Sequential/RL: Windowed Inference (RE-04) for rolling context; Continued Model Evaluation (RS-03) for reward/policy drift; Stateless Serving Function (RS-01) for inference.",
        clustering="Clustering: Heuristic Benchmark (RA-01) vs domain-expert segments; Embeddings (DP-02) as input; Explainable Predictions (RA-02) for cluster label interpretation.",
        retrieval="Retrieval: Two Phase Predictions (RS-04) mandatory at scale; Embeddings (DP-02) + Feature Store (RE-06); Hashed Features (DP-01) for query tokenisation.",
        calibration="Calibration/Uncertainty: Neutral Class (PR-05) for abstain option; Continued Model Evaluation (RS-03) to track ECE drift; Fairness Lens (RA-03) for calibration across groups.",
        simulation="Simulation: Useful Overfitting (TL-02) for physics surrogates; Distribution Strategy (TL-04) for large-scale simulation; Workflow Pipeline (RE-05) for sim-to-real loops.",
        optimisation="Optimisation: Reframing (PR-01) from prediction to decision; Windowed Inference (RE-04) for context; Continued Model Evaluation (RS-03) for policy/reward drift."
      )
      val <- PROBLEM_TYPES[input$problem_type]
      msg <- hints[[val]]
      if(is.null(msg)) return(NULL)
      div(class="tip-box", HTML(paste0("<strong>Problem type patterns:</strong> ", msg)))
    })

    observeEvent(input$run, {
      missing <- c()
      if(is.null(input$industry)     || input$industry=="")     missing <- c(missing,"Industry")
      if(is.null(input$problem_type) || input$problem_type=="") missing <- c(missing,"Problem Type")
      if(is.null(input$data_type)    || input$data_type=="")    missing <- c(missing,"Data Type")
      if(is.null(input$data_volume)  || input$data_volume=="")  missing <- c(missing,"Data Volume")
      if(is.null(input$latency)      || input$latency=="")      missing <- c(missing,"Latency")
      if(is.null(input$team_maturity)|| input$team_maturity=="") missing <- c(missing,"Team Maturity")

      if(length(missing) > 0) {
        output$validation_msg <- renderUI({
          div(class="warn-box", HTML(paste0("<strong>Please complete:</strong> ", paste(missing, collapse=", "))))
        })
        return()
      }

      output$validation_msg <- renderUI({
        div(class="success-box", HTML("<strong>Running recommendation engine...</strong> Switch to Results tab for ML systems, or Design Patterns tab for patterns."))
      })

      wizard_inputs$industry         <- INDUSTRIES[input$industry]
      wizard_inputs$problem_type     <- PROBLEM_TYPES[input$problem_type]
      wizard_inputs$data_type        <- DATA_TYPES[input$data_type]
      wizard_inputs$data_volume      <- DATA_VOLUMES[input$data_volume]
      wizard_inputs$latency          <- LATENCY_REQS[input$latency]
      wizard_inputs$serving          <- SERVING_MODES[input$serving]
      wizard_inputs$interpretability <- INTERPRETABILITY[input$interpretability]
      wizard_inputs$team_maturity    <- TEAM_MATURITY[input$team_maturity]
      wizard_inputs$compliance       <- input$compliance
      wizard_inputs$retraining_trigger <- input$retraining_trigger
      wizard_inputs$max_complexity   <- input$max_complexity
      wizard_inputs$pattern_priorities <- input$pattern_priorities
      wizard_inputs$data_challenges  <- input$data_challenges
      wizard_inputs$mlops_maturity   <- input$mlops_maturity
      wizard_inputs$industry_label   <- input$industry
      wizard_inputs$problem_label    <- input$problem_type
      wizard_inputs$data_label       <- input$data_type
      wizard_inputs$run_count        <- (wizard_inputs$run_count %||% 0) + 1
    })
  })
}
