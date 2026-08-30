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
