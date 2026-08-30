# modules/ch09_inference_optimization.R
# Ch. 9 — Inference Optimization

ch09_inference_optimization_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Ch.9 — Inference Optimization"),
        tags$h2("Inference Fundamentals · AI Accelerators · Model & Service Optimization"),
        div(
          span(class = "hero-badge", "Latency vs Throughput"),
          span(class = "hero-badge", "Quantization"),
          span(class = "hero-badge", "Batching & Caching")
        )
    ),

    tabsetPanel(
      id = ns("subtabs"), type = "tabs",

      tabPanel("📖 Theory",
        br(),
        fluidRow(
          box(title = "⏱️ Inference Fundamentals", status = "primary", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("Two-phase generation"), tags$p("Prefill (process the prompt, compute-bound, parallelizable) then decode (generate tokens one at a time, memory-bandwidth-bound) — they have very different bottlenecks and optimization levers.")),
              div(class = "framework-card", tags$h5("Latency vs. throughput trade-off"), tags$p("Batching multiple requests improves throughput/cost-efficiency but can increase per-request latency — the right point depends on whether the workload is interactive or background.")),
              div(class = "framework-card", tags$h5("KV cache"), tags$p("Caching attention key/value tensors avoids recomputation across decode steps — but consumes significant memory, especially with long contexts and many concurrent sessions.")),
              jobfit_box("A1's assistant mixes interactive turns (fast reply needed) with long-running background workflows (throughput matters more than latency) — inference strategy should differ by workflow type, not be one-size-fits-all.",
                         c("Latency Budgets", "Mixed Workload"))
          ),

          box(title = "🛠️ Optimization Techniques", status = "info", solidHeader = TRUE, width = 6,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Technique"), tags$th("Effect"), tags$th("Trade-off"))),
                tags$tbody(
                  tags$tr(tags$td(tags$span(class="stage-pill","Quantization")), tags$td("Lower-precision weights/activations (e.g. int8/int4)"), tags$td("Less memory, faster — some quality loss if too aggressive")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Continuous batching")), tags$td("Dynamically batch requests as they arrive/finish"), tags$td("Much higher throughput than static batching, added scheduling complexity")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Speculative decoding")), tags$td("A small draft model proposes tokens, the big model verifies"), tags$td("Can meaningfully cut latency; adds system complexity")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Prompt/response caching")), tags$td("Skip generation entirely for repeated/near-identical requests"), tags$td("Cache invalidation and staleness risk")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Model distillation/routing")), tags$td("Route simple sub-tasks to a smaller model"), tags$td("Requires a reliable router; quality ceiling per sub-task"))
                )
              )
          )
        ),

        fluidRow(
          box(title = "💰 Cost/Latency Levers Across an Agentic Workflow", status = "warning", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4, div(class="chapter-card", div(class="chapter-num","STEP"), div(class="chapter-title","Intent routing"), div(class="chapter-desc","Small/distilled model — high volume, low complexity, needs to be fast and cheap."))),
                column(4, div(class="chapter-card", div(class="chapter-num","STEP"), div(class="chapter-title","Planning / reasoning"), div(class="chapter-desc","Frontier model — lower volume, needs capability more than speed; cache repeated sub-plans."))),
                column(4, div(class="chapter-card", div(class="chapter-num","STEP"), div(class="chapter-title","Tool execution & confirmation"), div(class="chapter-desc","Often not model-bound at all — latency dominated by external APIs/human confirmation, not inference.")))
              )
          )
        )
      ),

      tabPanel("🎯 A1 Use Case Deep-Dive",
        br(),
        fluidRow(
          box(title = "📌 Use Case: Latency Budgeting Across A1's Mixed Workload", status = "primary", solidHeader = TRUE, width = 12,
              div(class = "success-box", HTML("<strong>Core design problem:</strong> A1's assistant has two fundamentally different workload shapes in the same product — interactive turns where the user is watching and waiting, and background multi-step errands where the user has moved on. Optimizing both the same way wastes money on one and frustrates users on the other.")),

              div(class = "section-heading", "1. Per-workflow-type latency budget"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Workflow Type"), tags$th("User Expectation"), tags$th("Latency Target"), tags$th("Optimization Priority"))),
                tags$tbody(
                  tags$tr(tags$td("Interactive chat turn"), tags$td("Feels like a live conversation"), tags$td("p95 < 2s to first token, streamed"), tags$td("Latency > throughput; token streaming to mask total time")),
                  tags$tr(tags$td("Reply drafting"), tags$td("Ready by the time they open the email"), tags$td("p95 < 8s"), tags$td("Balanced — batching acceptable if it doesn't blow the budget")),
                  tags$tr(tags$td("Multi-step background errand"), tags$td("Notified when done, not watching live"), tags$td("p95 < 5 min end-to-end (dominated by external tool/API latency, not inference)"), tags$td("Throughput/cost > latency; safe to batch heavily")),
                  tags$tr(tags$td("Routing / tool-argument generation"), tags$td("Invisible to user, but gates everything downstream"), tags$td("p95 < 300–500ms"), tags$td("Latency-critical despite being 'invisible' — it's on the critical path of every visible step"))
                )
              ),

              div(class = "section-heading", "2. Concrete optimization stack, mapped to workflow type"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Technique"), tags$th("Applied Where"), tags$th("Expected Impact"))),
                tags$tbody(
                  tags$tr(tags$td("Token streaming"), tags$td("Interactive chat"), tags$td("Perceived latency drops even if total generation time is unchanged — first token in <1s feels responsive")),
                  tags$tr(tags$td("Quantized small model (int8/int4)"), tags$td("Routing, tool-argument generation"), tags$td("Meets the 300–500ms budget at high volume without frontier-API cost")),
                  tags$tr(tags$td("Continuous batching"), tags$td("Background errand steps, bulk note summarisation"), tags$td("Higher GPU utilization, lower $/request — user isn't watching, so added queuing delay is acceptable")),
                  tags$tr(tags$td("Semantic caching"), tags$td("Repeated sub-plans (e.g. 'check calendar availability' called across many tasks)"), tags$td("Skips redundant generation for near-identical tool-argument requests")),
                  tags$tr(tags$td("Speculative decoding"), tags$td("Drafting (frontier model, long-form output)"), tags$td("Cuts perceived latency on the longest-output step without changing model choice"))
                )
              ),

              div(class = "section-heading", "3. Diagnosing a concrete complaint: \"the errand feels stuck\""),
              tags$ol(
                tags$li(tags$b("Instrument the pipeline:"), " log per-step timestamps (routing, planning, each tool call, confirmation wait) — not just total time, or you can't tell inference latency from external API latency from human-confirmation wait time."),
                tags$li(tags$b("Attribute the delay:"), " for a 45-second errand, it's very plausible the model inference is 3-4 seconds total and the rest is a slow external booking API or the user not responding to a confirmation prompt promptly."),
                tags$li(tags$b("Fix the right layer:"), " if it's the external API, the fix is async notification design (Ch.10), not inference optimization — a VP of Research needs to correctly diagnose BEFORE reaching for a model-layer fix.")
              ),

              div(class = "info-box-plain", HTML("<strong>🗣️ Interview talking point:</strong> \"I wouldn't apply one latency strategy across A1's assistant — interactive turns get streaming and a tight budget, background errands get heavy batching for cost efficiency, and the routing/tool-argument layer gets a small quantized model because it's invisible but latency-critical on every downstream step. And before optimizing inference at all, I'd instrument per-step timing, because for multi-step errands the bottleneck is very often an external API or a human confirmation wait, not the model.\""))
          )
        )
      ),

      tabPanel("✍️ Practice",
        br(),
        fluidRow(
          box(title = "Practice: Optimize a Slow Workflow", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4,
                       selectInput(ns("scenario"), "Choose a performance problem:",
                                   choices = c("Multi-step errand takes 45s end-to-end, users report it as 'stuck'", "High infra cost from routing everything through the frontier model",
                                               "Batch summarisation job for weekly notes is too slow overnight", "Repeated identical sub-queries re-computed every time")),
                       sliderInput(ns("confidence"), "Confidence (1–10):", 1, 10, 5),
                       actionButton(ns("save_btn"), "Save Assessment", class = "btn-meta", width = "100%")
                ),
                column(8,
                       div(class = "practice-area",
                           tags$b("Diagnose the bottleneck (prefill/decode/routing/external-call) and propose specific optimizations."),
                           textAreaInput(ns("notes"), label = NULL, rows = 9, width = "100%",
                                         placeholder = "## Likely bottleneck\n\n## Optimization(s) — quantization / batching / caching / routing / speculative decoding\n\n## Expected trade-off and how you'd measure success"),
                           uiOutput(ns("feedback"))
                       )
                )
              )
          )
        )
      )
    )
  )
}

ch09_inference_optimization_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_btn, {
      notes <- input$notes
      conf  <- input$confidence
      score <- 0
      if (grepl("bottleneck|prefill|decode|latency|throughput", notes, ignore.case = TRUE)) score <- score + 30
      if (grepl("quantiz|batch|cache|rout|speculat|distill", notes, ignore.case = TRUE)) score <- score + 40
      if (grepl("measure|trade.?off|metric|monitor", notes, ignore.case = TRUE)) score <- score + 30

      prep_manager$update_progress("ch09_inference_optimization", min(score + conf * 2, 100))
      prep_manager$save_note("ch09_notes", notes)
      prep_manager$add_practice_score("ch09_inference_optimization", score, input$scenario)

      output$feedback <- renderUI({
        div(class = if (score >= 70) "success-box" else "tip-box",
            tags$h5(paste0("Score: ", score, "/100")),
            if (score < 100) tags$p("Strongest answers name the specific bottleneck (not just 'it's slow'), a matching technique, and how you'd measure the fix worked.")
        )
      })
      showNotification("Saved!", type = "message")
    })
  })
}
