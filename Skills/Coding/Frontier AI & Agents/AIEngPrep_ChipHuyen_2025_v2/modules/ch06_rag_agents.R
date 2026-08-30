# modules/ch06_rag_agents.R
# Ch. 6 — RAG and Agents

ch06_rag_agents_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Ch.6 — RAG and Agents"),
        tags$h2("RAG Architecture & Retrieval · Agents (Tools, Planning, Failure Modes) · Memory"),
        div(
          span(class = "hero-badge", "Retrieval"),
          span(class = "hero-badge", "Tool Use & Planning"),
          span(class = "hero-badge", "Memory Systems"),
          span(class = "hero-badge", "Core JD Chapter")
        )
    ),

    tabsetPanel(
      id = ns("subtabs"), type = "tabs",

      tabPanel("📖 Theory",
        br(),
        fluidRow(
          box(title = "📥 RAG Architecture", status = "primary", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("Indexing"), tags$p("Chunk source content (emails, notes, docs), embed, and store in a vector/hybrid index — chunking strategy materially affects retrieval quality.")),
              div(class = "framework-card", tags$h5("Retrieval"), tags$p("Query embedding + similarity search, often combined with keyword/BM25 (hybrid search) and a reranking step for precision.")),
              div(class = "framework-card", tags$h5("Augmentation"), tags$p("Retrieved chunks are inserted into the prompt context — context window budget, ordering, and citation/attribution all matter.")),
              div(class = "framework-card", tags$h5("Generation"), tags$p("Model generates grounded in retrieved context — reduces (but does not eliminate) hallucination versus parametric-only generation.")),
              div(class = "tip-box", HTML("<strong>💡 A1 angle:</strong> the assistant's 'persistent context' need is effectively a RAG problem over the user's own data — emails, notes, tasks — updated continuously, not a static corpus."))
          ),

          box(title = "🤖 Agents: Tools, Planning, Failure Modes", status = "info", solidHeader = TRUE, width = 6,
              div(class = "section-heading-dark", "Core agent loop"),
              tags$p(style="font-size:12.5px;color:#2c3e50;", "Perceive (context/state) → Plan (decompose task, choose next action) → Act (call a tool) → Observe (tool result) → Repeat until done or escalate."),
              div(class = "section-heading-dark", "Common failure modes"),
              tags$ul(
                tags$li(tags$b("Planning drift:"), " agent loses track of the original goal over long horizons."),
                tags$li(tags$b("Tool misuse:"), " wrong tool chosen, or correct tool called with malformed/hallucinated arguments."),
                tags$li(tags$b("Infinite/looping behaviour:"), " agent repeats a failing action without escalating."),
                tags$li(tags$b("Compounding errors:"), " an early wrong step corrupts every subsequent step in a multi-step workflow.")
              ),
              jobfit_box("This chapter is the direct source of the JD's 'context representation, memory, reasoning, planning, and orchestration' bullet — expect deep technical probing here specifically.",
                         c("Agent Loop", "Failure Modes"))
          )
        ),

        fluidRow(
          box(title = "🧠 Memory Systems — Design Options", status = "warning", solidHeader = TRUE, width = 12,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Memory Type"), tags$th("What It Stores"), tags$th("A1 Use Case"), tags$th("Key Risk"))),
                tags$tbody(
                  tags$tr(tags$td(tags$span(class="stage-pill","Working memory")), tags$td("Current conversation/task context window"), tags$td("Active errand or reply drafting"), tags$td("Context window overflow on long tasks")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Episodic memory")), tags$td("Past interactions/sessions, timestamped"), tags$td("Recalling 'what did I ask you last week'"), tags$td("Staleness, contradiction with current state")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Semantic memory")), tags$td("Durable facts about the user (preferences, relationships)"), tags$td("Personalisation without re-asking"), tags$td("Privacy, incorrect fact persistence")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Procedural memory")), tags$td("Learned workflows / how the user likes tasks done"), tags$td("Consistent errand execution style"), tags$td("Overfitting to stale procedures"))
                )
              ),
              div(class = "success-box", HTML("<strong>✅ Design principle:</strong> separate memory write (what gets persisted, and when) from memory read (what gets retrieved into context for a given task) — conflating them is a common source of context bloat and irrelevant retrieval."))
          )
        ),

        fluidRow(
          box(title = "🎓 Bridging From Traditional ML: Retrieval as k-NN, Agents as Sequential Decisions", status = "success", solidHeader = TRUE, width = 12,
              div(class = "framework-card",
                  tags$h5("1. Vector retrieval IS nearest-neighbour search — no new algorithm here"),
                  tags$p("Embed a query and a corpus of chunks into the same vector space, then find the closest vectors by cosine similarity or dot product — this is literally k-NN, a technique you already know well, just applied to dense embeddings instead of raw feature vectors. What's new is the embedding model itself (learned via self-supervision, Ch.2) and the engineering around it — chunking strategy, hybrid keyword+vector search, and reranking — not the underlying retrieval algorithm.")),
              div(class = "framework-card",
                  tags$h5("2. Why RAG reduces (but doesn't eliminate) hallucination"),
                  tags$p("A model generating from parametric knowledge alone is recalling patterns compressed into its weights during pretraining — lossy, and with no way to distinguish 'confidently recalled fact' from 'plausible-sounding confabulation' at generation time. RAG grounds generation in retrieved text placed directly in context, so the model can copy/paraphrase from a verifiable source rather than reconstruct from memory. It doesn't eliminate hallucination because the model can still misread, over-generalize from, or ignore the retrieved context — grounding reduces the RATE of fabrication, it doesn't guarantee correctness.")),
              div(class = "framework-card",
                  tags$h5("3. Agents, reframed via the RL agent-environment loop you may already know"),
                  tags$p("If you've studied reinforcement learning: an agent (policy) observes state, selects an action, receives an updated state/reward, repeats — an MDP. LLM agents follow the same abstract loop (perceive → plan → act → observe), but critically, the 'policy' here is usually NOT trained via RL to select actions — it's a pretrained language model PROMPTED to reason about which action to take next, using its general reasoning ability rather than a policy learned through trial-and-error reward maximization on this specific task. Some frontier agent systems DO use RL fine-tuning on top (a genuine convergence with your RL background) — worth naming as a possible future direction if asked.")),
              div(class = "framework-card",
                  tags$h5("4. Memory breaks the i.i.d. assumption you're used to"),
                  tags$p("Standard supervised learning assumes each training/test example is independent and identically distributed — sample order doesn't matter. A long-running agentic assistant is fundamentally sequential: step 5's correctness depends on what happened in steps 1–4, and today's interaction depends on memory written last week. This is much closer to a time-series or sequential-decision-making problem than to i.i.d. supervised learning — which is exactly why 'compounding errors' (Ch.6's failure mode) is a real, structural risk that doesn't have a direct analog in single-shot classification.")),
              div(class = "warn-box", HTML("<strong>⚠️ Likely interview probe:</strong> \"Why not just train the planning/orchestration behaviour end-to-end with reinforcement learning, since you clearly understand RL?\" Strong answer: RL over long-horizon, real-world, partially-irreversible actions is extremely sample-inefficient and risky to explore in production (you can't cheaply 'reset the environment' after a bad email gets sent) — prompted reasoning over a pretrained model gets usable behaviour with zero task-specific reward engineering, and RL fine-tuning can be layered in later on narrow, well-instrumented sub-tasks once enough safe, offline data/simulation exists."))
          )
        )
      ),

      tabPanel("🎯 A1 Use Case Deep-Dive",
        br(),
        fluidRow(
          box(title = "📌 Use Case: The Multi-Step Errand Agent — \"Reschedule My Dentist Appointment\"", status = "primary", solidHeader = TRUE, width = 12,
              div(class = "success-box", HTML("<strong>Scenario:</strong> user says \"reschedule my dentist appointment to next week sometime after 3pm.\" This requires: finding the existing appointment (retrieval), checking calendar availability (tool call), contacting the dentist's office or using a booking tool (tool call, possibly external/irreversible), confirming with the user, and updating the calendar — a genuinely multi-step, multi-tool, partially irreversible workflow. This is the concrete version of the JD's 'context representation, memory, reasoning, planning, and orchestration.'")),

              div(class = "section-heading", "1. Full agent loop trace for this task"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Step"), tags$th("Phase"), tags$th("Action"), tags$th("Notes"))),
                tags$tbody(
                  tags$tr(tags$td("1"), tags$td("Perceive"), tags$td("Parse user request, retrieve current appointment from calendar (RAG over the user's calendar index)"), tags$td("Working memory now holds: original appt time/place, constraint ('next week, after 3pm')")),
                  tags$tr(tags$td("2"), tags$td("Plan"), tags$td("Decompose: (a) check calendar for 3pm+ slots next week, (b) check for conflicts, (c) contact dentist's office to confirm new slot, (d) update calendar, (e) notify user"), tags$td("Plan stored as a structured object, not just implicit in a chat transcript — needed for step 6 below")),
                  tags$tr(tags$td("3"), tags$td("Act"), tags$td("Call calendar-read tool for free/busy next week after 3pm"), tags$td("Read-only — no confirmation needed")),
                  tags$tr(tags$td("4"), tags$td("Observe"), tags$td("3 candidate slots returned"), tags$td("")),
                  tags$tr(tags$td("5"), tags$td("Act"), tags$td("Call booking/contact tool to request the dentist reschedule to the top candidate slot"), tags$td(tags$b("Irreversible/external — requires user confirmation before this call executes"))),
                  tags$tr(tags$td("6"), tags$td("Observe / recover"), tags$td("If the dentist's system rejects the slot, re-plan from step 3 with the remaining candidates — NOT restart the whole task"), tags$td("This is the planning-drift and compounding-error mitigation in practice")),
                  tags$tr(tags$td("7"), tags$td("Act"), tags$td("Update calendar with confirmed new time; write episodic memory entry"), tags$td("")),
                  tags$tr(tags$td("8"), tags$td("Respond"), tags$td("Notify user with a summary of what changed"), tags$td("Closes the loop; this summary is also the implicit-feedback capture point (Ch.8/10)"))
                )
              ),

              div(class = "section-heading", "2. Memory schema used across this task"),
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Memory Type"), tags$th("What's Written"), tags$th("When It's Read"))),
                tags$tbody(
                  tags$tr(tags$td(tags$span(class="stage-pill","Working")), tags$td("The plan object (step 2) + tool results as they arrive"), tags$td("Every step of this task, discarded after completion")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Episodic")), tags$td("\"Rescheduled dentist appt from X to Y on [date]\""), tags$td("If the user asks about it later (\"did you move my dentist thing?\")")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Semantic")), tags$td("\"User prefers afternoon appointments\" (inferred from the 'after 3pm' constraint, if it recurs)"), tags$td("Future scheduling tasks — but only written after a pattern repeats, not from a single instance, to avoid overfitting to a one-off constraint")),
                  tags$tr(tags$td(tags$span(class="stage-pill","Procedural")), tags$td("\"For appointment changes, always confirm before contacting the provider\""), tags$td("Every future task in this workflow category"))
                )
              ),

              div(class = "section-heading", "3. Failure-mode handling specific to this task"),
              fluidRow(
                column(6, div(class="warn-box", HTML("<strong>⚠️ Planning drift example:</strong> if step 5 takes long enough that a NEW user message arrives (\"actually, cancel that, I'll call myself\"), the agent must interrupt the in-flight plan, not queue the old plan behind the new message."))),
                column(6, div(class="warn-box", HTML("<strong>⚠️ Compounding error example:</strong> if step 1's retrieval picks the wrong appointment (user has two dentists), everything downstream is wrong. Mitigation: surface the retrieved appointment for confirmation BEFORE planning, when ambiguity is detected (e.g. multiple matching calendar entries).")))
              ),

              div(class = "section-heading", "4. Orchestration pattern used"),
              div(class = "tip-box", HTML("<strong>💡 Pattern: plan-and-execute with re-planning on failure</strong> (Ch.10) — a full plan is generated upfront (not step-by-step improvisation), each step executes with its own observe/validate, and failures trigger targeted re-planning from the failure point rather than a full restart. This bounds both cost (no redundant re-work) and risk (no silent divergence from the original goal).")),

              div(class = "info-box-plain", HTML("<strong>🗣️ Interview talking point:</strong> \"I'd trace this exact 8-step loop on a whiteboard — the key design decisions are: irreversible tool calls always pause for confirmation, failures trigger re-planning from the failure point not a restart, and memory writes are tiered — working memory for the task, episodic for recall, semantic only after a preference repeats, procedural for workflow-level policy. That tiering is what keeps context relevant instead of bloated over a long-running assistant relationship.\""))
          )
        )
      ),

      # ══════════════════════════════════════════════════════════ GLOSSARY
      tabPanel("📔 Glossary",
        br(),
        fluidRow(
          box(title = "Key Terms — Chapter 6", status = "info", solidHeader = TRUE, width = 12,
              tags$table(class = "table table-hover",
                tags$thead(tags$tr(tags$th("Term"), tags$th("Definition"), tags$th("How It Relates to What You Already Know"))),
                tags$tbody(
                  tags$tr(tags$td(tags$b("RAG (Retrieval-Augmented Generation)")), tags$td("Retrieving relevant external content and inserting it into the model's context before generation."), tags$td("An information-retrieval system feeding a downstream model — the retrieval step itself is literally nearest-neighbour search over embeddings.")),
                  tags$tr(tags$td(tags$b("Vector Database / Embedding Index")), tags$td("A storage system optimized for fast similarity search over dense vector embeddings."), tags$td("A specialized data structure for k-NN search at scale — conceptually similar to an indexed lookup structure, but over continuous vector space.")),
                  tags$tr(tags$td(tags$b("Chunking")), tags$td("Splitting source documents into smaller segments before embedding and indexing them."), tags$td("A data-preprocessing decision, analogous to choosing window sizes/feature granularity in a traditional pipeline — directly affects retrieval quality.")),
                  tags$tr(tags$td(tags$b("Reranking")), tags$td("A second-pass model that reorders initially retrieved candidates for higher precision."), tags$td("Similar to a two-stage retrieval-then-ranking system in traditional search/recommendation pipelines.")),
                  tags$tr(tags$td(tags$b("Hybrid Search")), tags$td("Combining vector similarity search with traditional keyword search (e.g. BM25) for better retrieval."), tags$td("An ensemble of two retrieval methods with different strengths — dense embeddings capture semantics, keyword search captures exact terms.")),
                  tags$tr(tags$td(tags$b("Agent")), tags$td("A system that perceives context, plans, and takes actions (often via tools) toward a goal, typically in a loop."), tags$td("Follows the same abstract agent-environment loop as reinforcement learning, but the decision-making 'policy' is usually a prompted pretrained model, not an RL-trained policy.")),
                  tags$tr(tags$td(tags$b("Tool / Function Calling")), tags$td("A mechanism allowing a model to invoke external functions/APIs with structured arguments."), tags$td("The model choosing among a fixed action space is analogous to an RL agent's discrete action set — but arguments are generated as free-form structured output.")),
                  tags$tr(tags$td(tags$b("Planning")), tags$td("Decomposing a complex goal into an ordered sequence of steps/actions before or during execution."), tags$td("Analogous to classical AI planning or a manually engineered decision pipeline — here it's typically generated by the model reasoning in natural language.")),
                  tags$tr(tags$td(tags$b("ReAct")), tags$td("A prompting pattern interleaving reasoning steps with actions and observations in the agent loop."), tags$td("A specific implementation of the perceive-plan-act-observe loop, formatted as alternating 'thought' and 'action' text.")),
                  tags$tr(tags$td(tags$b("Orchestrator-Worker Pattern")), tags$td("An architecture where one model/component plans and delegates sub-tasks to other specialized models/components."), tags$td("Similar to a manager-worker or MapReduce-style decomposition pattern from distributed systems, applied to model calls.")),
                  tags$tr(tags$td(tags$b("Working / Episodic / Semantic / Procedural Memory")), tags$td("Four tiers of agent memory: current-task context, timestamped past events, durable facts, and learned workflows, respectively."), tags$td("No single traditional-ML equivalent — closest parallel is separating a model's 'state' (RL) from a persistent knowledge base (recommender systems' user-profile store).")),
                  tags$tr(tags$td(tags$b("Context Window")), tags$td("The maximum amount of text (tokens) a model can process in a single call."), tags$td("Analogous to a fixed input-size constraint in traditional models, but here it directly limits how much retrieved/memory content can be used per request.")),
                  tags$tr(tags$td(tags$b("Hallucination")), tags$td("A model generating plausible-sounding but factually incorrect or unsupported content."), tags$td("Has no direct traditional-ML equivalent since classifiers can't 'invent' novel wrong answers the way open-ended generation can.")),
                  tags$tr(tags$td(tags$b("Grounding")), tags$td("Anchoring a model's output in verifiable external content (e.g. via RAG) rather than relying solely on parametric memory."), tags$td("Conceptually like constraining a model's predictions to be consistent with a retrieved evidence set, rather than an unconstrained free generation."))
                )
              )
          )
        )
      ),

      tabPanel("✍️ Practice",
        br(),
        fluidRow(
          box(title = "Practice: Diagnose an Agent Failure", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4,
                       selectInput(ns("scenario"), "Choose a failure to diagnose:",
                                   choices = c("Assistant books the wrong time after a 6-step rescheduling chain", "Agent loops calling the same failing tool repeatedly",
                                               "Assistant forgets a preference stated 3 days ago", "Agent's plan drifts from the original user goal mid-task")),
                       sliderInput(ns("confidence"), "Confidence (1–10):", 1, 10, 5),
                       actionButton(ns("save_btn"), "Save Assessment", class = "btn-meta", width = "100%")
                ),
                column(8,
                       div(class = "practice-area",
                           tags$b("Diagnose the likely root cause (planning, memory, tool-use) and propose a fix."),
                           textAreaInput(ns("notes"), label = NULL, rows = 9, width = "100%",
                                         placeholder = "## Likely root cause (planning / memory / tool-use / retrieval)\n\n## How you'd confirm it (logs, traces, eval)\n\n## Proposed fix\n\n## How you'd prevent recurrence (monitoring / guardrail)"),
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

ch06_rag_agents_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_btn, {
      notes <- input$notes
      conf  <- input$confidence
      score <- 0
      if (grepl("root cause|planning|memory|tool|retriev", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("log|trace|debug|confirm|eval", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("fix|solution|redesign|add", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("monitor|prevent|guardrail|alert|recur", notes, ignore.case = TRUE)) score <- score + 25

      prep_manager$update_progress("ch06_rag_agents", min(score + conf * 2, 100))
      prep_manager$save_note("ch06_notes", notes)
      prep_manager$add_practice_score("ch06_rag_agents", score, input$scenario)

      output$feedback <- renderUI({
        div(class = if (score >= 75) "success-box" else "tip-box",
            tags$h5(paste0("Score: ", score, "/100")),
            if (score < 100) tags$p("Strong agent-debugging answers name a specific root cause category (planning/memory/tool-use), how you'd confirm it with traces, and a monitoring change to prevent recurrence — this is a very likely live-debugging interview question.")
        )
      })
      showNotification("Saved!", type = "message")
    })
  })
}
