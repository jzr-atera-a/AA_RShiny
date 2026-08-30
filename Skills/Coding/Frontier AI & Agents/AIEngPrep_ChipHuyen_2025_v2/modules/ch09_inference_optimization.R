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
        ),

        fluidRow(
          box(title = "🎓 Bridging From Traditional ML: Why Generation Latency Behaves Differently", status = "success", solidHeader = TRUE, width = 12,
              div(class = "framework-card",
                  tags$h5("1. The core structural difference from a classifier's forward pass"),
                  tags$p("Serving a traditional classifier is one forward pass: input in, prediction out, done — latency is roughly constant regardless of the answer's 'complexity.' Autoregressive generation requires a SEPARATE forward pass for every output token, each conditioned on all previous tokens — so latency scales directly with output length, and there's an inherent sequential dependency you can't fully parallelize away (each token needs the previous one to exist first). This single fact explains most of Ch.9's optimization techniques: they all attack this sequential bottleneck from different angles.")),
              div(class = "framework-card",
                  tags$h5("2. Compute-bound vs. memory-bandwidth-bound — the prefill/decode split, explained"),
                  tags$p("Prefill (processing the input prompt) computes attention over many tokens at once — this parallelizes well and saturates the accelerator's compute (FLOPs), so it's compute-bound. Decode (generating one token at a time) does much less arithmetic per step but must repeatedly read the model's weights and the growing KV cache from memory — the bottleneck becomes how fast data can move (memory bandwidth), not how fast the accelerator can multiply numbers. This distinction directly explains why bigger models slow down decode disproportionately (more weights to read per step) while prefill scales more gracefully with model size.")),
              div(class = "framework-card",
                  tags$h5("3. Quantization — the same compression concept you may already use, applied earlier"),
                  tags$p("If you've deployed a traditional model to a resource-constrained environment, you've likely used quantization or pruning to shrink it. The exact same idea applies here — represent weights/activations with fewer bits (e.g. 8-bit or 4-bit integers instead of 16/32-bit floats) — but at foundation-model scale, the memory savings directly translate into decode-phase speedups too, since decode is memory-bandwidth-bound: less data to move per step means faster generation, not just a smaller model on disk.")),
              div(class = "framework-card",
                  tags$h5("4. Batching — throughput/latency trade-off, formalized"),
                  tags$p("You know that batch prediction (processing many examples at once) improves hardware utilization versus single-example inference. The same logic applies to LLM serving, with a wrinkle: because different requests finish generating at different lengths, NAIVE static batching wastes compute waiting for the longest request in a batch to finish. Continuous/dynamic batching solves this by adding new requests into a batch as soon as any slot frees up — a scheduling optimization with no direct traditional-ML-training equivalent, but conceptually similar to job-scheduling optimizations in any shared-resource system.")),
              div(class = "framework-card",
                  tags$h5("5. Speculative decoding — an elegant trick worth understanding precisely"),
                  tags$p("A small, fast 'draft' model proposes several tokens ahead; the large, accurate 'target' model then verifies all of them in a SINGLE parallel forward pass (since verifying is compute-bound and parallelizable, unlike generating). If the draft model's guesses match what the large model would have generated, you get multiple tokens for the cost of one large-model forward pass; if they mismatch, you fall back to the large model's own token and continue. It's a 'cheap guesser + expensive verifier' pattern that exploits the fact that verification is cheaper than generation for the same sequence.")),
              div(class = "warn-box", HTML("<strong>⚠️ Likely interview probe:</strong> \"Why does adding more GPUs not linearly reduce the latency of generating a single long response?\" Strong answer: because decode is inherently sequential (each token depends on the last) and memory-bandwidth-bound rather than compute-bound — more accelerators help you serve MORE concurrent requests (throughput), not make ONE request's token-by-token generation loop faster, unless you specifically apply techniques like speculative decoding that restructure the sequential dependency."))
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

      # ══════════════════════════════════════════════════════════ GLOSSARY
      tabPanel("📔 Glossary",
        br(),
        fluidRow(
          box(title = "Key Terms — Chapter 9", status = "info", solidHeader = TRUE, width = 12,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Term"), tags$th("Definition"), tags$th("How It Relates to What You Already Know"))),
                tags$tbody(
                  tags$tr(tags$td(tags$b("Prefill")), tags$td("The phase of inference that processes the full input prompt in parallel before generation begins."), tags$td("Similar to a standard batched forward pass — compute-bound and parallelizable, like scoring a batch in a traditional model.")),
                  tags$tr(tags$td(tags$b("Decode")), tags$td("The phase of inference that generates output tokens one at a time, each conditioned on all previous tokens."), tags$td("Has no direct equivalent in single-shot classifiers — introduces a sequential dependency that fundamentally shapes LLM serving latency.")),
                  tags$tr(tags$td(tags$b("KV Cache")), tags$td("Stored attention key/value tensors from previous tokens, reused during decode to avoid recomputing them at every step."), tags$td("A memoization technique — trading memory for avoided recomputation, a pattern used broadly in computer science, applied here to attention.")),
                  tags$tr(tags$td(tags$b("Latency")), tags$td("The time taken to complete a single request/response."), tags$td("Same definition as in any production ML serving system — but for generation, it scales with output length, not just model size.")),
                  tags$tr(tags$td(tags$b("Throughput")), tags$td("The number of requests (or tokens) a system can process per unit time, typically maximized via batching."), tags$td("The same latency-vs-throughput trade-off you manage in any batch-vs-online-serving decision, now applied to token generation.")),
                  tags$tr(tags$td(tags$b("Batching (Static / Continuous / Dynamic)")), tags$td("Grouping multiple requests to process together for efficiency; continuous/dynamic batching adds new requests as slots free up rather than waiting for a fixed batch to fully complete."), tags$td("An evolution of standard batch inference to handle variable-length sequential generation efficiently.")),
                  tags$tr(tags$td(tags$b("Quantization")), tags$td("Representing weights/activations with lower numeric precision to reduce memory and increase speed."), tags$td("The same model-compression technique used for deploying traditional models to constrained environments — here it also speeds up the memory-bandwidth-bound decode phase.")),
                  tags$tr(tags$td(tags$b("AI Accelerator (GPU/TPU)")), tags$td("Specialized hardware designed for the parallel matrix operations foundation models require."), tags$td("The evolution of the same hardware you'd use to train/serve traditional deep learning models, now central to both training and serving.")),
                  tags$tr(tags$td(tags$b("Speculative Decoding")), tags$td("Using a small 'draft' model to propose multiple tokens, verified in one parallel pass by the large 'target' model."), tags$td("A 'cheap guesser + expensive verifier' pattern with no direct traditional-ML-training analog, but similar in spirit to using a cheap heuristic to prune search space before an expensive exact check.")),
                  tags$tr(tags$td(tags$b("Arithmetic Intensity")), tags$td("The ratio of compute operations to memory accesses for a given workload — determines whether a workload is compute-bound or memory-bound."), tags$td("A hardware-performance concept explaining precisely why prefill (high intensity) and decode (low intensity) behave so differently on the same accelerator.")),
                  tags$tr(tags$td(tags$b("p50 / p95 / p99 Latency")), tags$td("The 50th/95th/99th percentile of a latency distribution — standard tail-latency reporting metrics."), tags$td("Standard production-systems metrics, unchanged in definition, just now applied to model inference calls."))
                )
              )
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
