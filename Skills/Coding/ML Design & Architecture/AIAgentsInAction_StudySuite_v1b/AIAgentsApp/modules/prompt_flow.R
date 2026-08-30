# modules/prompt_flow.R — Chapter 9: Microsoft Prompt Flow

prompt_flow_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Microsoft Prompt Flow"),
        tags$h2("Chapter 9 — DAG-Based LLM Pipelines: Flows, Connections, Variants & Evaluation"),
        div(span(class="hero-badge","promptflow 1.18.5"), span(class="hero-badge","YAML DAGs"),
            span(class="hero-badge","Connections"), span(class="hero-badge","pf CLI"))
    ),
    fluidRow(
      box(title="⚠️ Prompt Flow is Being Retired", status="danger", solidHeader=TRUE, width=12,
          div(class="warn-box", HTML("<strong>Important:</strong> Microsoft announced Prompt Flow's retirement. Feature development ended <strong>April 20, 2026</strong>. Full retirement (SDK, CLI, VS Code extension, Azure authoring) is scheduled for <strong>April 20, 2027</strong>. Microsoft's recommended successor is <strong>Microsoft Agent Framework</strong>. Migration guide: <code>github.com/microsoft/promptflow → migration-guide/PromptFlow-to-MAF</code>.<br><br>The code in this chapter works today (promptflow 1.18.5 confirmed working). The underlying concepts (DAG-based orchestration, prompt variants, evaluation flows) transfer directly to Agent Framework and are worth learning regardless of the tooling.")),
      )
    ),
    fluidRow(
      box(title="🔀 What is a Prompt Flow?", status="primary", solidHeader=TRUE, width=6,
          div(class="success-box", HTML("<strong>Core concept:</strong> A flow is a directed acyclic graph (DAG) of nodes, described entirely in <code>flow.dag.yaml</code>. Each node is either an LLM call (renders a jinja2 template) or a Python tool (@tool-decorated function). Node outputs are wired explicitly as inputs to downstream nodes.")),
          br(),
          div(class="section-heading-dark", "flow.dag.yaml anatomy"),
          div(class="code-box", HTML(
            'inputs:<br>
             &nbsp;&nbsp;user_input:<br>
             &nbsp;&nbsp;&nbsp;&nbsp;type: string<br>
             &nbsp;&nbsp;&nbsp;&nbsp;default: <span style="color:#FCD34D">"What movies do you recommend?"</span><br><br>
             nodes:<br>
             - name: recommender<br>
             &nbsp;&nbsp;type: llm<br>
             &nbsp;&nbsp;source:<br>
             &nbsp;&nbsp;&nbsp;&nbsp;type: code<br>
             &nbsp;&nbsp;&nbsp;&nbsp;path: recommend.jinja2<br>
             &nbsp;&nbsp;inputs:<br>
             &nbsp;&nbsp;&nbsp;&nbsp;connection: OpenAI<br>
             &nbsp;&nbsp;&nbsp;&nbsp;model: gpt-4o-mini  <span style="color:#6B7280"># was gpt-4-1106-preview</span><br>
             &nbsp;&nbsp;&nbsp;&nbsp;query: ${inputs.user_input}<br><br>
             - name: echo<br>
             &nbsp;&nbsp;type: python<br>
             &nbsp;&nbsp;source:<br>
             &nbsp;&nbsp;&nbsp;&nbsp;type: code<br>
             &nbsp;&nbsp;&nbsp;&nbsp;path: echo.py<br>
             &nbsp;&nbsp;inputs:<br>
             &nbsp;&nbsp;&nbsp;&nbsp;text: ${recommender.output}'
          )),
          div(class="section-heading-dark", "Import fix required everywhere"),
          div(class="code-box", HTML(
            '<span style="color:#6B7280"># Old (book) — still works but deprecated:</span><br>
             <span style="color:#C4B5FD">from</span> promptflow <span style="color:#C4B5FD">import</span> tool<br><br>
             <span style="color:#6B7280"># Correct (promptflow 1.18.5):</span><br>
             <span style="color:#C4B5FD">from</span> promptflow.core <span style="color:#C4B5FD">import</span> tool'
          ))
      ),
      box(title="🔧 Systematic Fixes Across All 7 Flows", status="warning", solidHeader=TRUE, width=6,
          div(class="section-heading-dark", "What was wrong in every single flow"),
          timeline_entry("Fix 1", "Deprecated imports", "from promptflow import tool → from promptflow.core import tool. Applied to all 14 Python tool files."),
          timeline_entry("Fix 2", "Retired model", "gpt-4-1106-preview → gpt-4o-mini in all flow.dag.yaml LLM nodes."),
          timeline_entry("Fix 3", "Empty requirements.txt", "evaluate_groundings/requirements.txt shipped completely empty. All 7 per-flow files needed pinning."),
          timeline_entry("Fix 4", "samples.json never customised", "ALL 7 samples.json still had the promptflow scaffold placeholder {\"topic\": \"atom\"} — none matched the flow's actual input schema. Rebuilt from each flow's own defaults."),
          timeline_entry("Fix 5", "No connection tooling", "No connection.yaml or setup_connection.ps1 shipped. Every flow references connection: OpenAI but there was no way to create it. Added."),
          br(),
          div(class="section-heading-dark", "Running flows"),
          div(class="code-box", HTML(
            '<span style="color:#6B7280"># Single-input test</span><br>
             pf flow test --flow .<br><br>
             <span style="color:#6B7280"># Batch run against samples.json</span><br>
             pf run create --flow . --data samples.json \\<br>
             &nbsp;&nbsp;--column-mapping user_input=<span style="color:#FCD34D">\'${data.user_input}\'</span><br><br>
             <span style="color:#6B7280"># Disable noisy telemetry warning</span><br>
             pf config set telemetry.enabled=false'
          ))
      )
    ),
    fluidRow(
      box(title="✍️ Study Notes", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(6, textAreaInput(ns("notes"), "Study notes:", value="", rows=3, placeholder="Notes on Prompt Flow, DAGs, the pf CLI...")),
            column(3, sliderInput(ns("progress"), "Chapter 9 readiness:", 0, 100, 0, step=5)),
            column(3, br(), actionButton(ns("save_progress"), "Save Progress", class="btn-primary"))
          )
      )
    )
  )
}

prompt_flow_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_progress, {
      study_mgr$save_note("prompt_flow", input$notes)
      study_mgr$update_progress("prompt_flow", input$progress)
      showNotification("Chapter 9 progress saved!", type="message", duration=3)
    })
  })
}
