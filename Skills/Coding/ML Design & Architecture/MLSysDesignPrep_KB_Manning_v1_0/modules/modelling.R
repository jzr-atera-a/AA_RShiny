# modules/modelling.R
# Tab 5: Model Development & Training — Ch. 5

modelling_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Model Development & Training"),
        tags$h2("Chapter 5 — Architecture Selection, Loss Functions, Distributed Training, HPO"),
        div(span(class="hero-badge","Architecture Selection"), span(class="hero-badge","Loss Functions"),
            span(class="hero-badge","Distributed Training"), span(class="hero-badge","Hyperparameter Optimisation"),
            span(class="hero-badge","Experiment Tracking"))
    ),

    fluidRow(
      box(title="🧠 Model Architecture Selection — K&B's Decision Framework (Ch. 5)", status="primary", solidHeader=TRUE, width=6,
          div(class="success-box",
              HTML("<strong>K&B principle:</strong> Never choose a model architecture based on benchmark leaderboards. Choose based on YOUR constraints: latency, data size, interpretability requirements, training cost, and operational complexity.")),
          br(),
          tags$table(class="table table-hover",
            tags$thead(tags$tr(tags$th("Model Family"), tags$th("Best When"), tags$th("Caution"))),
            tags$tbody(
              tags$tr(tags$td(tags$span(class="stage-pill","Logistic Regression")),
                      tags$td("Baseline, interpretability required, low latency (<1ms)"),
                      tags$td("Assumes linear decision boundary, limited capacity")),
              tags$tr(tags$td(tags$span(class="stage-pill","Gradient Boosted Trees")),
                      tags$td("Tabular data, mixed types, production-proven at scale"),
                      tags$td("Doesn't learn representations; feature engineering still needed")),
              tags$tr(tags$td(tags$span(class="stage-pill","Deep Neural Network")),
                      tags$td("Large data (>100K), unstructured data, feature learning"),
                      tags$td("Needs GPU, slower training, harder to debug")),
              tags$tr(tags$td(tags$span(class="stage-pill","Two-Tower (Embedding)")),
                      tags$td("Retrieval systems, semantic search, recommendations"),
                      tags$td("Requires item/user vocab. Cold start is harder.")),
              tags$tr(tags$td(tags$span(class="stage-pill","Transformer / LLM")),
                      tags$td("NLP tasks, generation, code, long-context understanding"),
                      tags$td("Very expensive. Latency. Requires careful eval + guardrails.")),
              tags$tr(tags$td(tags$span(class="stage-pill","Graph Neural Network")),
                      tags$td("Fraud rings, social network ranking, molecule prediction"),
                      tags$td("Complex infra, memory-intensive, not standard in most stacks"))
            )
          ),
          div(class="tip-box",
              HTML("<strong>💡 Interview gold:</strong> When asked to choose a model, say: 'Given the latency SLO of 50ms and the feature set being primarily tabular, I'd start with a gradient-boosted tree (LightGBM) as a strong baseline before considering a neural network.' Show constraint-driven thinking."))
      ),

      box(title="📉 Loss Functions & Training Objectives (Ch. 5)", status="info", solidHeader=TRUE, width=6,
          div(class="section-heading-dark","Classification"),
          div(class="framework-card",
              tags$h5("Cross-Entropy Loss"),
              tags$p("Standard binary/multi-class classification. Penalises confident wrong predictions heavily. Common for: CTR prediction, intent classification, content moderation."),
              tags$p(tags$b("Calibration:"), " cross-entropy encourages calibrated probabilities. Important for downstream use of scores (auction bidding, threshold decisions).")),
          div(class="framework-card",
              tags$h5("Focal Loss"),
              tags$p("Cross-entropy with a modulating factor (1 - p_t)^γ. Down-weights easy examples. Focuses training on hard cases. Used in: object detection (RetinaNet), content moderation with extreme class imbalance."),
              tags$p(tags$b("γ = 2"), " is standard. Higher γ = more focus on hard examples.")),
          div(class="section-heading-dark","Ranking & Recommendation"),
          div(class="framework-card",
              tags$h5("BPR Loss (Bayesian Personalised Ranking)"),
              tags$p("Optimises: P(interacted item > non-interacted item) for each user. Pairwise loss for implicit feedback. Foundation of matrix factorisation for recommendations.")),
          div(class="framework-card",
              tags$h5("LambdaRank / LambdaLoss"),
              tags$p("Listwise loss that directly optimises NDCG. Non-differentiable NDCG → surrogate gradient (lambda weights). Industry standard for search ranking. Used by Google, Microsoft, Baidu.")),
          div(class="section-heading-dark","Multi-Task Learning"),
          div(class="framework-card",
              tags$h5("Weighted Multi-Task Loss"),
              tags$p("L = w₁·L_click + w₂·L_share + w₃·L_watch. Weights are tunable hyperparameters — K&B warn: set these via business priority, not just model convergence. Gradient surgery can prevent negative transfer."))
      )
    ),

    fluidRow(
      box(title="⚡ Distributed Training Patterns (Ch. 5)", status="warning", solidHeader=TRUE, width=6,
          div(class="framework-card",
              tags$h5("Data Parallelism (Most Common)"),
              tags$p("Replicate model weights across N GPUs. Each GPU processes a different mini-batch. Gradients are averaged via AllReduce (Ring-AllReduce is bandwidth-optimal)."),
              tags$p(tags$b("PyTorch DDP:"), " Standard. Works when model fits on one GPU. Scale to 1000+ GPUs."),
              tags$p(tags$b("When to use:"), " Model < GPU memory. Most NN architectures. The default.")),
          div(class="framework-card",
              tags$h5("Model Parallelism (Large Models)"),
              tags$p("Split model across GPUs. Required when model > single GPU memory (e.g., GPT-4, Llama-70B)."),
              tags$p(tags$b("Tensor parallelism:"), " Split individual matrix multiplications. Megatron-LM."),
              tags$p(tags$b("Pipeline parallelism:"), " Split layers into stages. GPUs form an assembly line. GPipe."),
              tags$p(tags$b("ZeRO (DeepSpeed):"), " Partition optimizer states + gradients + parameters across GPUs. Up to 8× memory reduction.")),
          div(class="framework-card",
              tags$h5("Gradient Accumulation"),
              tags$p("Simulate large batch training on limited GPU memory. Accumulate gradients over N micro-batches before optimizer step. Effectively batch_size = micro_batch × N_accum × N_GPU.")),
          div(class="tip-box",
              HTML("<strong>💡 Interview signal:</strong> Show you know WHICH strategy to use and WHY. Don't just name them. 'Given the 70B parameter model, I'd use ZeRO-3 with DeepSpeed for optimizer state partitioning across 64 A100s.'"))
      ),

      box(title="🔬 Experiment Tracking & HPO (Ch. 5)", status="success", solidHeader=TRUE, width=6,
          div(class="section-heading-dark","What Must Be Tracked per Experiment"),
          div(class="framework-card",
              tags$h5("Reproducibility Requirements"),
              tags$ul(
                tags$li("All hyperparameters (learning rate, batch size, model architecture config)"),
                tags$li("Training data version (snapshot hash / DVC tag / S3 path + prefix)"),
                tags$li("Code version (git commit SHA — non-negotiable)"),
                tags$li("All evaluation metrics (train, validation, test)"),
                tags$li("Training duration, GPU hours, cost estimate"),
                tags$li("Environment hash (Python version, library versions, CUDA version)")
              )),
          div(class="framework-card",
              tags$h5("Hyperparameter Optimisation"),
              tags$p(tags$b("Grid search:"), " Exhaustive. Use only for small search spaces (< 4 params)."),
              tags$p(tags$b("Random search:"), " 10× more efficient than grid for high-dimensional spaces (Bergstra & Bengio 2012)."),
              tags$p(tags$b("Bayesian optimisation (Optuna/Hyperopt):"), " Model the objective surface. Sample smarter. Best for expensive function evaluations."),
              tags$p(tags$b("Population-Based Training (PBT):"), " Evolve hyperparams during training. Used by DeepMind for game-playing agents.")),
          div(class="section-heading-dark","Tooling"),
          div(class="framework-card",
              tags$h5("Experiment Tracking Stack"),
              tags$p(tags$b("MLflow:"), " Open-source. Tracking + model registry + serving. Most widely adopted."),
              tags$p(tags$b("Weights & Biases:"), " Rich UI. Automatic system metrics. Collaborative. Popular in research."),
              tags$p(tags$b("Vertex AI Experiments / SageMaker:"), " Managed cloud options. No infra overhead."))
      )
    ),

    fluidRow(
      box(title="📊 Self-Assessment: Modelling & Training", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(3, sliderInput(ns("sc_arch"),    "Architecture selection",   0,10,5),
                      sliderInput(ns("sc_loss"),    "Loss function selection",  0,10,5)),
            column(3, sliderInput(ns("sc_dist"),    "Distributed training",     0,10,5),
                      sliderInput(ns("sc_hpo"),     "HPO strategy",             0,10,5)),
            column(3, sliderInput(ns("sc_tracking"),"Experiment tracking",     0,10,5),
                      br(), actionButton(ns("calc_mod"),"Save Assessment", class="btn-meta", width="100%")),
            column(3, br(), uiOutput(ns("mod_result")))
          )
      )
    )
  )
}

modelling_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_mod, {
      avg <- mean(c(input$sc_arch, input$sc_loss, input$sc_dist, input$sc_hpo, input$sc_tracking))
      pct <- round(avg * 10)
      prep_manager$update_progress("modelling", pct)
      output$mod_result <- renderUI({
        div(class=if(pct>=70)"success-box" else "tip-box",
            tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
            if(pct>=80) tags$p("✅ Strong modelling foundation. Always justify architecture via constraints!") else
              tags$p("💡 Focus: constraint-driven model selection and distributed training patterns."))
      })
      showNotification(paste0("Modelling: ",pct,"% saved"), type="message")
    })
  })
}
