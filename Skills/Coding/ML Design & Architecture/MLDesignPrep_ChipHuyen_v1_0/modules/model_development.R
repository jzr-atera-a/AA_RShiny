# modules/model_development.R
# Tab 5: Model Development — Ch. 6 Selection, Ensembling, Training

model_development_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Model Development"),
        tags$h2("Chapter 6 — Selection, Ensembling, Distributed Training & Experiment Tracking"),
        div(
          span(class = "hero-badge", "Model Selection"),
          span(class = "hero-badge", "Ensembling"),
          span(class = "hero-badge", "Distributed Training"),
          span(class = "hero-badge", "Experiment Tracking")
        )
    ),

    fluidRow(
      box(title = "🧠 Model Selection Principles (Ch. 6)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
              HTML("<strong>Huyen's rule:</strong> 'Start with the simplest model that could work. Use a complex model only when you have evidence it's needed.' Complexity is a liability unless justified by data.")),
          br(),

          div(class = "framework-card",
              tags$h5("Model Selection Checklist"),
              tags$ul(
                tags$li("Avoid the SOTA trap — SOTA on a benchmark ≠ best for your production problem"),
                tags$li("Consider the FULL system: training cost, inference latency, memory, explainability"),
                tags$li("Use multiple metrics: accuracy + latency + memory + training time"),
                tags$li("Don't compare models trained on different data — control the variable"),
                tags$li("Always define a baseline BEFORE evaluating complex models")
              )),

          div(class = "section-heading-dark", "Model Selection by Constraint"),
          tags$table(class = "table table-hover",
            tags$thead(tags$tr(tags$th("Constraint"), tags$th("Prefer"), tags$th("Avoid"))),
            tags$tbody(
              tags$tr(tags$td("Low latency (<10ms)"),   tags$td("Linear/logistic regression, small GBDT"), tags$td("Deep transformers, large ensembles")),
              tags$tr(tags$td("High accuracy"),          tags$td("Gradient boosted trees, deep NNs"), tags$td("Naive Bayes, very shallow models")),
              tags$tr(tags$td("Interpretability"),       tags$td("Linear models, decision trees, SHAP"), tags$td("Deep NNs without explainability layer")),
              tags$tr(tags$td("Sparse features (>1M)"), tags$td("Embedding + NN (DLRM style)"), tags$td("One-hot + linear (memory issue)")),
              tags$tr(tags$td("Small data (<10K)"),      tags$td("Transfer learning, traditional ML"), tags$td("Training large NNs from scratch"))
            )
          )
      ),

      box(title = "🔀 Ensembling Methods (Ch. 6)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
              tags$h5("Bagging (Bootstrap Aggregation)"),
              tags$p("Train N models on different bootstrapped subsets. Average predictions (regression) or vote (classification). Reduces variance. Random Forest is the canonical example. Each model sees ~63% of training data.")),
          div(class = "framework-card",
              tags$h5("Boosting"),
              tags$p("Train models sequentially — each corrects errors of the previous. Reduces bias. XGBoost, LightGBM, CatBoost. Dominant on tabular data in production. More sensitive to noisy labels than bagging.")),
          div(class = "framework-card",
              tags$h5("Stacking (Meta-Learning)"),
              tags$p("Level-1 models generate predictions as features. Level-2 meta-model learns to combine them. High performance but high complexity. Rarer in production due to maintenance overhead.")),
          div(class = "framework-card",
              tags$h5("Mixture of Experts (MoE)"),
              tags$p("Different expert models for different input subspaces. Router/gating network selects experts. Used in GPT-4, Switch Transformer. Each token activates only a subset of parameters. Scales model capacity without proportional compute increase.")),
          div(class = "tip-box",
              HTML("<strong>💡 Interview signal:</strong> 'I'd consider ensembling at serving time by averaging predictions from our current model and the challenger — this also gives a natural weighted traffic split for A/B testing.'"))
      )
    ),

    fluidRow(
      box(title = "🔬 Experiment Tracking & Distributed Training (Ch. 6)", status = "warning",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   div(class = "section-heading-dark", "What to Track per Experiment"),
                   div(class = "framework-card",
                       tags$h5("Experiment Artifacts"),
                       tags$ul(
                         tags$li("Model architecture + all hyperparameters"),
                         tags$li("Training data version (snapshot ID or DVC hash)"),
                         tags$li("Code version (git commit SHA)"),
                         tags$li("Offline evaluation metrics per run"),
                         tags$li("Training duration + GPU hours + cost"),
                         tags$li("Environment (Python version, library versions)")
                       )),
                   div(class = "framework-card",
                       tags$h5("Tools"),
                       tags$p(tags$b("Open-source:"), " MLflow, Weights & Biases, Neptune.ai, Comet ML"),
                       tags$p(tags$b("Cloud:"), " Vertex AI Experiments, SageMaker Experiments"),
                       tags$p(tags$b("Internal:"), " FBLearner (Meta), Michelangelo (Uber)"))
            ),
            column(4,
                   div(class = "section-heading-dark", "Distributed Training Patterns"),
                   div(class = "framework-card",
                       tags$h5("Data Parallelism"),
                       tags$p("Replicate model on N GPUs. Each processes a different mini-batch. Average gradients (AllReduce / Ring-AllReduce). Works for models that fit on one GPU. PyTorch DistributedDataParallel (DDP). Standard approach.")),
                   div(class = "framework-card",
                       tags$h5("Model Parallelism"),
                       tags$p("Split model layers across GPUs. Required when model is too large for one GPU (LLMs). Pipeline parallelism: GPUs form an assembly line. Tensor parallelism: split individual layer computations (Megatron-LM)."))
            ),
            column(4,
                   div(class = "section-heading-dark", "Gradient Issues to Know"),
                   div(class = "framework-card",
                       tags$h5("Gradient Vanishing"),
                       tags$p("Gradients shrink to near-zero in deep networks. Symptom: early layers don't learn. Fix: ReLU activations, batch normalisation, residual connections (ResNet), careful initialisation (He, Xavier).")),
                   div(class = "framework-card",
                       tags$h5("Gradient Explosion"),
                       tags$p("Gradients grow unboundedly. Symptom: NaN loss. Fix: gradient clipping (clip_grad_norm_), careful learning rate schedule, gradient scaling (AMP for mixed precision)."))
            )
          )
      )
    ),

    fluidRow(
      box(title = "📊 Self-Assessment: Model Development", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   sliderInput(ns("sc_selection"), "Model selection justification", 0, 10, 5),
                   sliderInput(ns("sc_ensemble"),  "Ensembling understanding",     0, 10, 5),
                   sliderInput(ns("sc_dist"),      "Distributed training",         0, 10, 5),
                   sliderInput(ns("sc_tracking"),  "Experiment tracking",          0, 10, 5),
                   actionButton(ns("calc_model"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8, br(), uiOutput(ns("model_result")))
          )
      )
    )
  )
}

model_development_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_model, {
      avg <- mean(c(input$sc_selection, input$sc_ensemble, input$sc_dist, input$sc_tracking))
      pct <- round(avg * 10)
      prep_manager$update_progress("model_development", pct)

      output$model_result <- renderUI({
        colour <- progress_colour(pct)
        div(class = if (pct >= 70) "success-box" else "tip-box",
            tags$h3(style = paste0("color:", colour), paste0(pct, "% ready")),
            if (pct >= 80) tags$p("✅ Strong model development foundation. Remember: always justify model choice with constraints.") else
              tags$p("💡 Review: model selection criteria, when to use each ensembling approach, and distributed training patterns.")
        )
      })
      showNotification(paste0("Model Development: ", pct, "% saved"), type = "message")
    })
  })
}
