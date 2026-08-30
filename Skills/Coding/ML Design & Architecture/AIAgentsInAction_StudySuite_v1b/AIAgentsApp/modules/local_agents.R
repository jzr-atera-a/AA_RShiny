# modules/local_agents.R — Chapter 3: Local Models & Agent Fundamentals

local_agents_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Local Models & Agent Fundamentals"),
        tags$h2("Chapter 3 — Running LLMs Locally, ReAct Loops, and What Makes an Agent"),
        div(span(class="hero-badge","LM Studio"), span(class="hero-badge","Mistral-7B"),
            span(class="hero-badge","ReAct"), span(class="hero-badge","OpenAI-Compatible API"))
    ),

    fluidRow(
      box(title="🖥️ LM Studio — Local Model Server (Ch.3)", status="primary", solidHeader=TRUE, width=6,
          div(class="success-box", HTML("<strong>Why local models matter:</strong> Running a local model means zero API costs, complete privacy, and offline development. LM Studio wraps any GGUF-format model behind an OpenAI-compatible REST API — so every SDK call you already know works without modification.")),
          br(),
          div(class="section-heading-dark", "LM Studio Setup"),
          timeline_entry("Step 1", "Install & enable Developer Mode", "Download LM Studio, open Settings → Developer Mode → Enable Server. The local server starts on port 1234."),
          timeline_entry("Step 2", "Download a model", "Mistral-7B-Instruct-v0.2-GGUF (TheBloke) is the book's reference. Q4_K_M quantisation balances quality vs memory (~4.1GB VRAM or RAM)."),
          timeline_entry("Step 3", "Point the SDK at localhost", "Change base_url to http://localhost:1234/v1. The model field is ignored — whatever model is loaded in LM Studio responds."),
          br(),
          div(class="code-box", HTML(
            '<span style="color:#C4B5FD">from</span> openai <span style="color:#C4B5FD">import</span> OpenAI<br><br>
             client = OpenAI(<br>
             &nbsp;&nbsp;base_url=<span style="color:#FCD34D">"http://localhost:1234/v1"</span>,<br>
             &nbsp;&nbsp;api_key=<span style="color:#FCD34D">"not-needed-for-local"</span>  <span style="color:#6B7280"># SDK requires something</span><br>
             )<br><br>
             response = client.chat.completions.create(<br>
             &nbsp;&nbsp;model=<span style="color:#FCD34D">"mistral-7b-instruct"</span>,  <span style="color:#6B7280"># Ignored by LM Studio</span><br>
             &nbsp;&nbsp;messages=[{<span style="color:#FCD34D">"role"</span>:<span style="color:#FCD34D">"user"</span>,<span style="color:#FCD34D">"content"</span>:<span style="color:#FCD34D">"Hello!"</span>}]<br>
             )'
          )),
          div(class="warn-box", HTML("<strong>⚠️ Mistral system role:</strong> Mistral-7B-Instruct rejects the <code>system</code> role — it only accepts <code>user</code> and <code>assistant</code>. Merge system + first user message into a single user message when using this model locally."))
      ),
      box(title="🔄 What Makes an Agent? — The ReAct Loop (Ch.3)", status="info", solidHeader=TRUE, width=6,
          div(class="warn-box", HTML("<strong>Chatbot vs Agent:</strong> A chatbot responds. An agent <em>acts</em>. The difference is tool use: an agent can call external functions, observe results, and reason about what to do next — repeatedly, until the task is complete.")),
          br(),
          div(class="section-heading-dark", "ReAct = Reason + Act"),
          tags$p("The ReAct pattern (Yao et al., 2022) interleaves reasoning traces with actions. The model generates a thought, then an action, observes the result, and repeats until it can produce a final answer."),
          div(class="framework-card", tags$h5("Thought"),
              tags$p("The model's internal reasoning: 'I need to find the current temperature in Paris. I should call the weather tool with city=Paris.'"),),
          div(class="framework-card", tags$h5("Action"),
              tags$p("A tool call with structured arguments: {\"name\": \"get_weather\", \"arguments\": {\"city\": \"Paris\"}}.")),
          div(class="framework-card", tags$h5("Observation"),
              tags$p("The tool's return value, injected back into the message history as a tool_result message: {\"temperature\": 18, \"condition\": \"cloudy\"}.")),
          div(class="framework-card", tags$h5("Final answer"),
              tags$p("After enough Thought/Action/Observation cycles, the model produces the user-facing response: 'It is currently 18°C and cloudy in Paris.'")),
          div(class="tip-box", HTML("<strong>💡 Key insight:</strong> The 'loop' is not explicit code — it emerges from the conversation structure. The model keeps generating tool calls as long as it needs more information, then switches to a text response when satisfied."))
      )
    ),

    fluidRow(
      box(title="📐 Agent Taxonomy — Planning Strategies", status="warning", solidHeader=TRUE, width=12,
          tags$table(class="table table-hover",
            tags$thead(tags$tr(
              tags$th("Strategy"), tags$th("How it works"), tags$th("Strength"), tags$th("Weakness"), tags$th("Ch. reference")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$b("ReAct")),          tags$td("Interleaved reasoning + tool calls"),       tags$td("Transparent, debuggable"),       tags$td("Many tokens, slow"),        tags$td("Ch.3")),
              tags$tr(tags$td(tags$b("Plan-and-execute")),tags$td("Create full plan first, then execute"),    tags$td("Efficient tool use"),            tags$td("Plan may be wrong upfront"),tags$td("Ch.3")),
              tags$tr(tags$td(tags$b("Reflection")),      tags$td("Agent critiques its own output and retries"),tags$td("Higher quality output"),        tags$td("2x token cost"),           tags$td("Ch.3, 5")),
              tags$tr(tags$td(tags$b("Multi-agent")),     tags$td("Specialised sub-agents delegate sub-tasks"),tags$td("Parallelism, specialisation"),  tags$td("Orchestration complexity"), tags$td("Ch.4")),
              tags$tr(tags$td(tags$b("Tree-of-thoughts")),tags$td("Explore multiple reasoning branches, prune bad ones"),tags$td("Best for complex reasoning"),tags$td("Very expensive"),     tags$td("Ch.10"))
            )
          ),
          br(),
          fluidRow(
            column(6, textAreaInput(ns("notes"), "Study notes:", value="", rows=3, placeholder="Notes on local models, ReAct loops...")),
            column(3, br(), sliderInput(ns("progress"), "Chapter 3 readiness:", 0, 100, 0, step=5)),
            column(3, br(), br(), actionButton(ns("save_progress"), "Save Progress", class="btn-primary"))
          )
      )
    )
  )
}

local_agents_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_progress, {
      study_mgr$save_note("local_agents", input$notes)
      study_mgr$update_progress("local_agents", input$progress)
      showNotification("Chapter 3 progress saved!", type="message", duration=3)
    })
  })
}
