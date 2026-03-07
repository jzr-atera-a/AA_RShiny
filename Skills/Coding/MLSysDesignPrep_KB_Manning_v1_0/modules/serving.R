# modules/serving.R
# Tab 7: Model Serving & Deployment — Ch. 7

serving_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Model Serving & Deployment"),
        tags$h2("Chapter 7 — Online vs Batch, Model Servers, Compression, Rollback Strategies"),
        div(span(class="hero-badge","TorchServe"), span(class="hero-badge","Triton"),
            span(class="hero-badge","Quantisation"), span(class="hero-badge","Canary Deploy"),
            span(class="hero-badge","Blue-Green"))
    ),

    fluidRow(
      box(title="⚡ Online vs Batch Serving — K&B's Decision Framework (Ch. 7)", status="primary", solidHeader=TRUE, width=7,
          tags$table(class="table table-hover",
            tags$thead(tags$tr(tags$th(""), tags$th("Online (Real-time)"), tags$th("Batch (Pre-computed)"))),
            tags$tbody(
              tags$tr(tags$td(tags$b("When")),         tags$td("Request-time prediction needed"),      tags$td("Predictions can be pre-computed")),
              tags$tr(tags$td(tags$b("Latency")),      tags$td("< 200ms typically"),                  tags$td("Minutes–hours (acceptable for cold start, email)")),
              tags$tr(tags$td(tags$b("Freshness")),    tags$td("Reflects current context"),            tags$td("Stale by definition — schedule wisely")),
              tags$tr(tags$td(tags$b("Cold start")),   tags$td("Can handle new items/users dynamically"),tags$td("Cannot — new entities have no predictions")),
              tags$tr(tags$td(tags$b("Cost")),         tags$td("High (always-on GPUs/CPUs)"),          tags$td("Lower (spot instances, off-peak)")),
              tags$tr(tags$td(tags$b("Complexity")),   tags$td("High (SLOs, autoscaling, fallback)"),  tags$td("Lower (retry-friendly, simpler infra)")),
              tags$tr(tags$td(tags$b("Examples")),     tags$td("Feed ranking, fraud detection, search"),tags$td("Email recs, batch scoring, weekly reports"))
            )
          ),
          br(),
          div(class="success-box",
              HTML("<strong>✅ K&B's hybrid pattern (production standard):</strong> Pre-compute slow-changing features (user embeddings, item popularity) in batch. Combine with real-time context (current session, query, time-of-day) at serving time. This achieves low latency + freshness where it matters.")),
          div(class="tip-box",
              HTML("<strong>💡 Interview answer:</strong> 'I'd use a two-layer approach — batch pre-computation for candidate generation (stored in Redis for <5ms retrieval), with real-time ranking using a lightweight model scored against current request context.'"))
      ),

      box(title="🚀 Model Servers & Serving Infrastructure (Ch. 7)", status="info", solidHeader=TRUE, width=5,
          div(class="framework-card",
              tags$h5("NVIDIA Triton Inference Server"),
              tags$p("Multi-framework (PyTorch, TF, ONNX, TensorRT). Dynamic batching: waits for N requests before running inference (configurable timeout). Concurrent model execution. GPU memory management. KServe wraps it in Kubernetes.")),
          div(class="framework-card",
              tags$h5("TorchServe"),
              tags$p("PyTorch-native. Simple to adopt for PyTorch teams. Handles model versioning, logging, metrics. Less flexible than Triton for mixed-framework orgs.")),
          div(class="framework-card",
              tags$h5("vLLM (LLMs Only)"),
              tags$p(tags$b("PagedAttention:"), " Manages KV-cache like OS virtual memory. Eliminates memory fragmentation. 30× throughput over naive HuggingFace serving."),
              tags$p(tags$b("Continuous batching:"), " Process requests of different lengths together without padding waste."),
              tags$p(tags$b("Speculative decoding:"), " Small draft model generates candidates; large model verifies. 2–4× latency reduction.")),
          div(class="framework-card",
              tags$h5("BentoML / Ray Serve"),
              tags$p("Python-native serving. BentoML for packaging ML artifacts. Ray Serve for distributed multi-model serving. Good for Python-first teams without dedicated infra.")),
          div(class="tip-box",
              HTML("<strong>💡 Name-drop appropriately:</strong> 'For LLM serving, I'd use vLLM for its PagedAttention scheduler which gives 15–30× throughput improvement. For a multi-model system, Triton with dynamic batching.'"))
      )
    ),

    fluidRow(
      box(title="🗜️ Model Compression for Production (Ch. 7)", status="warning", solidHeader=TRUE, width=7,
          div(class="success-box",
              HTML("<strong>K&B principle:</strong> Every model deployed at scale should go through a compression evaluation step. The goal: find the point where accuracy loss is acceptable but inference cost drops significantly.")),
          fluidRow(
            column(6,
                   div(class="framework-card",
                       tags$h5("Quantisation"),
                       tags$p(tags$b("FP32 → FP16:"), " 2× memory, ~same accuracy. Free win — always do this."),
                       tags$p(tags$b("FP16 → INT8 (PTQ):"), " 4× memory reduction vs FP32. Slight accuracy drop. Apply calibration dataset."),
                       tags$p(tags$b("QAT (Quantisation-Aware Training):"), " Simulate quantisation during training. Minimal accuracy loss. Required for mobile (INT8 on-device)."),
                       tags$p(tags$b("INT4/NF4:"), " For LLMs (GPTQ, GGUF). 8× memory reduction. Used for LLaMA on consumer GPUs.")),
                   div(class="framework-card",
                       tags$h5("Knowledge Distillation"),
                       tags$p("Train small student model to mimic large teacher model's output distribution (soft labels, not hard labels)."),
                       tags$p(tags$b("DistilBERT:"), " 60% of BERT params, 97% of GLUE performance, 60% faster."),
                       tags$p(tags$b("Temperature:"), " T > 1 in teacher softmax reveals inter-class relationships hidden by argmax.")),
                   div(class="framework-card",
                       tags$h5("Pruning"),
                       tags$p(tags$b("Unstructured:"), " Remove individual weights below threshold. 90% sparsity achievable but hardware acceleration limited."),
                       tags$p(tags$b("Structured:"), " Remove entire filters/heads/layers. Hardware-efficient. Easier to combine with quantisation."))
            ),
            column(6,
                   div(class="framework-card",
                       tags$h5("LoRA / Low-Rank Adaptation"),
                       tags$p("Decompose weight update ΔW = B·A where rank(B·A) << rank(ΔW). Only train B and A (0.1–1% of params)."),
                       tags$p(tags$b("Memory:"), " 3× less GPU memory for fine-tuning. QLoRA adds INT4 quantisation."),
                       tags$p(tags$b("Multi-LoRA serving:"), " Share base model, hot-swap adapter per tenant. Cost-effective multi-tenant fine-tuning.")),
                   div(class="framework-card",
                       tags$h5("ONNX Runtime"),
                       tags$p("Export to ONNX for framework-agnostic optimisation. ONNX Runtime applies:"),
                       tags$ul(
                         tags$li("Operator fusion (combine sequential ops)"),
                         tags$li("Constant folding (pre-compute static subgraphs)"),
                         tags$li("Graph simplification"),
                         tags$li("Target-specific kernel selection")
                       )),
                   div(class="framework-card",
                       tags$h5("TensorRT (NVIDIA)"),
                       tags$p("NVIDIA-specific compilation. Fuses layers, selects precision per-layer. Often 2–5× speedup over vanilla PyTorch for GPU inference. Industry standard for production GPU serving."))
            )
          )
      ),

      box(title="🚦 Deployment Strategies & Rollback (Ch. 7)", status="danger", solidHeader=TRUE, width=5,
          div(class="framework-card",
              tags$h5("1. Shadow Deployment (Zero Risk)"),
              tags$p("New model runs alongside prod. Predictions logged but NOT served. Compare offline. K&B: always shadow-test for at least 24h before any live traffic.")),
          div(class="framework-card",
              tags$h5("2. Canary (1% → 10% → 50% → 100%)"),
              tags$p("Gradual traffic ramp. Monitor guardrail metrics at each stage. Auto-promote if metrics hold; auto-rollback if they don't. Gate on: error rate, latency SLO, primary metric.")),
          div(class="framework-card",
              tags$h5("3. Blue-Green Deployment"),
              tags$p("Two identical environments: blue (live), green (new). Switch all traffic instantly. Easy rollback: switch back to blue. Zero downtime. Higher infra cost (2× capacity needed).")),
          div(class="framework-card",
              tags$h5("4. Feature Flags"),
              tags$p("Decouple deployment from activation. Deploy model to all instances, but activate only for flagged user segment. Allows instant rollback without re-deploy.")),
          div(class="warn-box",
              HTML("<strong>⚠️ K&B rollback principle:</strong> Every model deployment MUST have an automated rollback trigger based on guardrail metrics. Manual rollback decisions are too slow at scale — if p99 latency > SLO for 5 minutes, auto-rollback to previous version.")),
          div(class="tip-box",
              HTML("<strong>💡 Canary is K&B's default recommendation</strong> for most ML model deployments. Shadow mode first, then 1% canary, then gradual ramp."))
      )
    ),

    fluidRow(
      box(title="📊 Self-Assessment: Serving & Deployment", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(3, sliderInput(ns("sc_online_batch"), "Online vs batch decision", 0,10,5),
                      sliderInput(ns("sc_server"),       "Model server knowledge",   0,10,5)),
            column(3, sliderInput(ns("sc_compression"),  "Compression techniques",  0,10,5),
                      sliderInput(ns("sc_deploy"),       "Deployment strategies",   0,10,5)),
            column(3, sliderInput(ns("sc_rollback"),     "Rollback design",         0,10,5),
                      br(), actionButton(ns("calc_serv"), "Save Assessment", class="btn-meta", width="100%")),
            column(3, br(), uiOutput(ns("serv_result")))
          )
      )
    )
  )
}

serving_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$calc_serv, {
      avg <- mean(c(input$sc_online_batch, input$sc_server, input$sc_compression, input$sc_deploy, input$sc_rollback))
      pct <- round(avg * 10)
      prep_manager$update_progress("serving", pct)
      output$serv_result <- renderUI({
        div(class=if(pct>=70)"success-box" else "tip-box",
            tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
            if(pct>=80) tags$p("✅ Strong serving knowledge. Always propose shadow + canary deployment.") else
              tags$p("💡 Review: hybrid serving pattern, vLLM for LLMs, and automated rollback triggers."))
      })
      showNotification(paste0("Serving: ",pct,"% saved"), type="message")
    })
  })
}
