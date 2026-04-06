# modules/wizard.R — Decision Wizard

wizard_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
      tags$h1("ML System Design Decision Engine"),
      tags$h2("Answer 6 questions to get a ranked shortlist of ML approaches for your scenario"),
      div(
        span(class="hero-badge","52 ML Methods"),
        span(class="hero-badge","12 Method Groups"),
        span(class="hero-badge","6 Industry Sectors"),
        span(class="hero-badge","150+ Use Cases"),
        span(class="hero-badge","Huyen & K&B Referenced")
      ),
      tags$p(style="color:rgba(255,255,255,0.75);font-size:12px;margin-top:10px;",
        "Based on Designing ML Systems (Huyen, O'Reilly 2022) and ML System Design (Kravchenko & Babushkin, Manning 2025). Every recommendation is grounded in both books.")
    ),

    fluidRow(
      box(title="Step 1 — Industry & Sector", status="primary", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>Who is this for?</strong> Select the industry closest to your use case. This filters the method library to those with proven production deployments in your sector.")),
        br(),
        selectInput(ns("industry"), "Industry / Sector:",
          choices=c("Select..."="", setNames(names(INDUSTRIES), names(INDUSTRIES))),
          width="100%"),
        uiOutput(ns("industry_hint"))
      ),
      box(title="Step 2 — ML Problem Type", status="primary", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>What are you predicting?</strong> This is Huyen Ch.2 — framing the problem correctly is the single most important design decision.")),
        br(),
        selectInput(ns("problem_type"), "ML Problem Type:",
          choices=c("Select..."="", setNames(names(PROBLEM_TYPES), names(PROBLEM_TYPES))),
          width="100%"),
        uiOutput(ns("problem_hint"))
      )
    ),

    fluidRow(
      box(title="Step 3 — Data Profile", status="warning", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>What does your data look like?</strong> Data type and volume are primary drivers of model selection. From Huyen Ch.3-4 and K&B Ch.3.")),
        br(),
        selectInput(ns("data_type"), "Primary Data Type:",
          choices=c("Select..."="", setNames(names(DATA_TYPES), names(DATA_TYPES))),
          width="100%"),
        br(),
        selectInput(ns("data_volume"), "Data Volume:",
          choices=c("Select..."="", setNames(names(DATA_VOLUMES), names(DATA_VOLUMES))),
          width="100%")
      ),
      box(title="Step 4 — Operational Requirements", status="warning", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>How must the system behave in production?</strong> Latency SLO and serving mode constrain architecture choices. From Huyen Ch.7 and K&B Ch.7.")),
        br(),
        selectInput(ns("latency"), "Latency Requirement:",
          choices=c("Select..."="", setNames(names(LATENCY_REQS), names(LATENCY_REQS))),
          width="100%"),
        br(),
        selectInput(ns("serving"), "Serving Mode:",
          choices=c("Select..."="", setNames(names(SERVING_MODES), names(SERVING_MODES))),
          width="100%")
      )
    ),

    fluidRow(
      box(title="Step 5 — Non-Functional Requirements", status="danger", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>Regulatory, fairness and explainability constraints.</strong> From Huyen Ch.11 — responsible AI and K&B Ch.2 non-functional SLOs.")),
        br(),
        selectInput(ns("interpretability"), "Interpretability Requirement:",
          choices=c("Select..."="", setNames(names(INTERPRETABILITY), names(INTERPRETABILITY))),
          width="100%"),
        br(),
        checkboxGroupInput(ns("compliance"), "Compliance Requirements:",
          choices=c("GDPR / CCPA (data privacy)"="gdpr",
                    "FCA / Basel III (financial regulation)"="fca",
                    "HIPAA (healthcare)"="hipaa",
                    "AV Act 2024 / ISO 21448 (autonomous vehicles)"="avact",
                    "None"="none"),
          selected="none")
      ),
      box(title="Step 6 — Team & Infrastructure", status="danger", solidHeader=TRUE, width=6,
        div(class="info-box-plain", HTML("<strong>Team maturity and build vs buy.</strong> From Huyen Ch.10 and K&B Ch.2 — your team capability determines which solutions are practical.")),
        br(),
        selectInput(ns("team_maturity"), "Team ML Maturity:",
          choices=c("Select..."="", setNames(names(TEAM_MATURITY), names(TEAM_MATURITY))),
          width="100%"),
        br(),
        sliderInput(ns("retraining_freq"), "Expected Retraining Frequency:",
          min=1, max=365, value=7, step=1,
          post=" days"),
        tags$p(style="font-size:11px;color:#546e7a;",
          "1 = continuous/daily, 7 = weekly, 30 = monthly, 365 = annually")
      )
    ),

    fluidRow(
      box(width=12, style="text-align:center;padding:20px;",
        actionButton(ns("run"), "🔍  Find My ML System Design",
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
        finance="Finance: GBTs dominate for credit/fraud; regulatory models must be interpretable (Logistic Regression as baseline). GDPR Article 22 applies to automated decisions.",
        trading="Trading/Quant: low SNR environment — IC not R² is the metric. Walk-forward validation mandatory. FTRL for HFT signals; RL for execution optimisation.",
        social="Social Media: recommendation at scale. Two-Tower + FAISS for retrieval; LambdaMART for ranking; RLHF for LLM alignment. Degenerate feedback loops are the key risk.",
        retail="Retail: demand forecasting (ETS/Prophet/N-BEATS), recommendation (Two-Tower), dynamic pricing (Bandits/Survival), causal uplift for promotions.",
        av="Autonomous Vehicles: safety-critical — calibration mandatory. YOLOv8 for perception; Kalman Filter for sensor fusion; PPO for motion planning. AV Act 2024 requires ODD declaration.",
        energy="Energy: time-series forecasting (ARIMA/ETS/N-BEATS), probabilistic forecasting (GP/BNN), physics-informed models (PINN/FNO), RL for grid optimisation.",
        general="General: start with Logistic Regression or GBT baseline. Only move to deep learning if tabular methods are insufficient. Huyen Ch.6 baseline hierarchy."
      )
      val <- INDUSTRIES[input$industry]
      msg <- hints[[val]]
      if(is.null(msg)) return(NULL)
      div(class="tip-box", HTML(paste0("<strong>Industry context:</strong> ", msg)))
    })

    output$problem_hint <- renderUI({
      if(is.null(input$problem_type) || input$problem_type == "") return(NULL)
      hints <- list(
        classification="Binary/multiclass: GBTs first. Use PR-AUC not ROC-AUC for imbalanced classes. Focal loss for severe imbalance. Huyen Ch.4.",
        regression="Regression: GBTs for tabular; ARIMA/ETS/N-BEATS for time series. Use temporal split — never random split across time. Huyen Ch.6.",
        forecasting="Forecasting: start with ETS/ARIMA as baseline. Only move to DL (N-BEATS, Transformers) if baseline is insufficient. Walk-forward validation mandatory.",
        ranking="Ranking/LTR: LambdaMART optimises NDCG directly. Two-Tower for candidate retrieval first. Evaluate with NDCG@K not accuracy. K&B Ch.6.",
        recommendation="Recommendation: Two-Tower for retrieval at scale; LambdaMART for ranking; Bandits for exploration/exploitation. Cold start requires LightFM or content-based fallback.",
        anomaly="Anomaly detection: Isolation Forest or Autoencoder for unsupervised; GBT with class weights for supervised. Use PR-AUC — extreme class imbalance expected.",
        causal="Causal inference: DiD/CausalImpact for policy evaluation; Meta-Learners for uplift; DML for high-dimensional confounders. Huyen Ch.11 — correlation is not causation.",
        generation="Generation: LLM + RAG for text; Diffusion for images. RAG reduces hallucination. LoRA/QLoRA for fine-tuning on limited GPU. RLHF for alignment.",
        sequential="Sequential/RL: DQN (off-policy) or PPO (on-policy). Reward function design is the hardest part. Start with bandit if simpler formulation is possible.",
        clustering="Clustering: K-Means as baseline; HDBSCAN for arbitrary shapes; BERTopic for text. Always compare against domain-expert segments.",
        retrieval="Retrieval/Search: Two-Tower + FAISS for dense retrieval; BM25 for sparse; hybrid for best of both. ColBERT for fine-grained matching. K&B Ch.7.",
        calibration="Uncertainty quantification: Conformal Prediction for distribution-free guarantees; Temperature Scaling for LLMs/NNs; Deep Ensembles for best calibration.",
        simulation="Simulation: Digital Twins (CARLA/Isaac Sim) for synthetic data generation; PINNs when governing equations are known; Monte Carlo for financial scenario analysis.",
        optimisation="Optimisation: RL for sequential decisions; Bandits for simpler explore/exploit; CVXPY for convex optimisation; OR-Tools for combinatorial problems."
      )
      val <- PROBLEM_TYPES[input$problem_type]
      msg <- hints[[val]]
      if(is.null(msg)) return(NULL)
      div(class="tip-box", HTML(paste0("<strong>Problem type guidance:</strong> ", msg)))
    })

    observeEvent(input$run, {
      missing <- c()
      if(is.null(input$industry)     || input$industry==""     ) missing <- c(missing, "Industry")
      if(is.null(input$problem_type) || input$problem_type=="") missing <- c(missing, "Problem Type")
      if(is.null(input$data_type)    || input$data_type==""    ) missing <- c(missing, "Data Type")
      if(is.null(input$data_volume)  || input$data_volume==""  ) missing <- c(missing, "Data Volume")
      if(is.null(input$latency)      || input$latency==""      ) missing <- c(missing, "Latency")
      if(is.null(input$team_maturity)|| input$team_maturity=="" ) missing <- c(missing, "Team Maturity")

      if(length(missing) > 0) {
        output$validation_msg <- renderUI({
          div(class="warn-box",
            HTML(paste0("<strong>Please complete:</strong> ", paste(missing, collapse=", ")))
          )
        })
        return()
      }

      output$validation_msg <- renderUI({
        div(class="success-box", HTML("<strong>Running recommendation engine...</strong> Switch to the Results tab."))
      })

      wizard_inputs$industry       <- INDUSTRIES[input$industry]
      wizard_inputs$problem_type   <- PROBLEM_TYPES[input$problem_type]
      wizard_inputs$data_type      <- DATA_TYPES[input$data_type]
      wizard_inputs$data_volume    <- DATA_VOLUMES[input$data_volume]
      wizard_inputs$latency        <- LATENCY_REQS[input$latency]
      wizard_inputs$serving        <- SERVING_MODES[input$serving]
      wizard_inputs$interpretability <- INTERPRETABILITY[input$interpretability]
      wizard_inputs$team_maturity  <- TEAM_MATURITY[input$team_maturity]
      wizard_inputs$compliance     <- input$compliance
      wizard_inputs$retraining_freq<- input$retraining_freq
      wizard_inputs$industry_label <- input$industry
      wizard_inputs$problem_label  <- input$problem_type
      wizard_inputs$data_label     <- input$data_type
      wizard_inputs$run_count      <- (wizard_inputs$run_count %||% 0) + 1
    })
  })
}
