# modules/autogen_crewai.R — Chapter 4: AutoGen Studio & CrewAI

autogen_crewai_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("AutoGen & CrewAI"),
        tags$h2("Chapter 4 — Multi-Agent Frameworks: Conversation-Based & Role-Based Orchestration"),
        div(span(class="hero-badge","AutoGen 0.4.2"), span(class="hero-badge","CrewAI"),
            span(class="hero-badge","Multi-Agent"), span(class="hero-badge","Tool Use"))
    ),

    fluidRow(
      box(title="🤖 AutoGen — Conversational Multi-Agent (Ch.4)", status="primary", solidHeader=TRUE, width=6,
          div(class="success-box", HTML("<strong>Core idea:</strong> AutoGen treats multi-agent collaboration as a <em>conversation</em>. Each agent has a role, a name, and a system prompt. Agents take turns sending messages in a group chat, with tool execution and code running as part of the conversation.")),
          br(),
          div(class="section-heading-dark", "The ConversableAgent Pattern"),
          framework_card("AssistantAgent", "The LLM-backed reasoning agent. Generates replies, writes code, calls tools. Has a system prompt defining its role and capabilities."),
          framework_card("UserProxyAgent", "Represents the human (or automated input). Decides when to terminate, executes code in a local sandbox, passes tool results back. Sets human_input_mode."),
          br(),
          div(class="section-heading-dark", "AutoGen Studio 0.4.x vs book screenshots"),
          div(class="warn-box", HTML("<strong>⚠️ UI drift:</strong> The book shows AutoGen Studio with a 'Skills' tab under Build. Version 0.4.2.2 (the installed version) uses 'Tools' under 'Team Builder'. Every tab name and button location in the book's screenshots is stale — expect to re-discover the UI yourself.")),
          br(),
          div(class="section-heading-dark", "Finding built-in tool source code"),
          tags$p("Rather than guessing at UI-exposed tool code, query the AutoGen Studio SQLite database directly:"),
          div(class="code-box", HTML(
            'import sqlite3<br>
             conn = sqlite3.connect(<span style="color:#FCD34D">r"%USERPROFILE%\\.autogenstudio\\autogen04202.db"</span>)<br>
             cursor = conn.cursor()<br>
             cursor.execute(<span style="color:#FCD34D">"SELECT name, content FROM gallery WHERE type=\'skill\'"</span>)<br>
             <span style="color:#C4B5FD">for</span> name, code <span style="color:#C4B5FD">in</span> cursor.fetchall():<br>
             &nbsp;&nbsp;<span style="color:#FCD34D">print</span>(<span style="color:#FCD34D">f"=== {name} ==="</span>)<br>
             &nbsp;&nbsp;<span style="color:#FCD34D">print</span>(code)'
          ))
      ),
      box(title="👥 CrewAI — Role-Based Agent Crews (Ch.4)", status="info", solidHeader=TRUE, width=6,
          div(class="success-box", HTML("<strong>Core idea:</strong> CrewAI organises agents into a <em>crew</em> with explicit roles, goals, and backstories — like a team with defined job titles. Tasks flow sequentially or hierarchically, with each agent's output piped to the next.")),
          br(),
          div(class="section-heading-dark", "Anatomy of a CrewAI Crew"),
          div(class="code-box", HTML(
            '<span style="color:#C4B5FD">from</span> crewai <span style="color:#C4B5FD">import</span> Agent, Task, Crew, Process<br><br>
             researcher = Agent(<br>
             &nbsp;&nbsp;role=<span style="color:#FCD34D">"Joke Researcher"</span>,<br>
             &nbsp;&nbsp;goal=<span style="color:#FCD34D">"Find the best programming jokes"</span>,<br>
             &nbsp;&nbsp;backstory=<span style="color:#FCD34D">"Expert in tech humour..."</span>,<br>
             &nbsp;&nbsp;verbose=<span style="color:#A5F3FC">True</span><br>
             )<br>
             writer = Agent(<br>
             &nbsp;&nbsp;role=<span style="color:#FCD34D">"Joke Writer"</span>,<br>
             &nbsp;&nbsp;goal=<span style="color:#FCD34D">"Craft polished jokes from raw material"</span>,<br>
             &nbsp;&nbsp;backstory=<span style="color:#FCD34D">"Comedy writer for tech publications"</span><br>
             )<br>
             crew = Crew(<br>
             &nbsp;&nbsp;agents=[researcher, writer],<br>
             &nbsp;&nbsp;tasks=[research_task, write_task],<br>
             &nbsp;&nbsp;process=Process.sequential,<br>
             &nbsp;&nbsp;verbose=<span style="color:#A5F3FC">True</span>  <span style="color:#6B7280"># NOT verbose=2 — pydantic error</span><br>
             )'
          )),
          div(class="warn-box", HTML("<strong>⚠️ Breaking change:</strong> The book uses <code>verbose=2</code> (old integer log-level convention). Current CrewAI requires <code>verbose=True</code> or <code>verbose=False</code>. Passing an int now raises a pydantic <code>ValidationError</code>."))
      )
    ),

    fluidRow(
      box(title="⚖️ AutoGen vs CrewAI — Choosing the Right Framework", status="warning", solidHeader=TRUE, width=12,
          tags$table(class="table table-hover",
            tags$thead(tags$tr(
              tags$th("Dimension"), tags$th("AutoGen"), tags$th("CrewAI"), tags$th("When to choose")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$b("Metaphor")),       tags$td("Group chat / conversation"),   tags$td("Org chart / team"),            tags$td("AutoGen: emergent conversation; CrewAI: structured workflows")),
              tags$tr(tags$td(tags$b("Agent definition")),tags$td("System prompt + capabilities"),tags$td("Role + Goal + Backstory"),       tags$td("CrewAI roles are more descriptive for non-tech teams")),
              tags$tr(tags$td(tags$b("Task flow")),       tags$td("Dynamic, conversation-driven"),tags$td("Explicit task list, sequential"), tags$td("AutoGen: open-ended; CrewAI: pipeline-style")),
              tags$tr(tags$td(tags$b("Code execution")),  tags$td("Built-in sandbox executor"),   tags$td("Tool use via decorators"),      tags$td("AutoGen better for agentic coding tasks")),
              tags$tr(tags$td(tags$b("Termination")),     tags$td("TERMINATE keyword or max turns"),tags$td("Task completion"),            tags$td("CrewAI has clearer stopping conditions")),
              tags$tr(tags$td(tags$b("Studio UI")),       tags$td("AutoGen Studio (browser app)"),tags$td("Code-first primarily"),         tags$td("AutoGen Studio great for experimenting without Python")),
              tags$tr(tags$td(tags$b("Best for")),        tags$td("Research, coding assistants, dynamic Q&A"),tags$td("Business workflows, content pipelines"),tags$td("Match to your use case"))
            )
          )
      )
    ),

    fluidRow(
      box(title="🛠️ Common Fixes Applied This Session", status="danger", solidHeader=TRUE, width=6,
          div(class="section-heading-dark", "Chapter 4 compatibility issues"),
          timeline_entry("Fix 1", "Model retirement", "gpt-4-1106-preview and gpt-3.5-turbo-1106 both retired. Substitute: gpt-4o-mini everywhere in OAI_CONFIG_LIST and inline calls."),
          timeline_entry("Fix 2", "CrewAI verbose=2", "Pydantic ValidationError. Change to verbose=True or verbose=False. Integer verbosity levels no longer supported."),
          timeline_entry("Fix 3", "AutoGen Studio tabs", "Book references 'Skills' tab — does not exist in 0.4.2.x. Equivalent is 'Tools' under Team Builder. All UI screenshots are stale."),
          timeline_entry("Fix 4", "generate_image tool", "DALL-E 3 replaced by gpt-image-1 for image generation. Check client.models.list() before assuming which image model is available on your account.")
      ),
      box(title="✍️ Practice & Study Notes", status="success", solidHeader=TRUE, width=6,
          div(class="section-heading-dark", "Chapter 4 — Self-assessment"),
          tags$p("Can you answer these without looking?"),
          tags$ul(
            tags$li("What is the difference between", tags$code("AssistantAgent"), "and", tags$code("UserProxyAgent"), "?"),
            tags$li("How does AutoGen's", tags$code("human_input_mode"), "parameter control agent flow?"),
            tags$li("What does", tags$code("Process.sequential"), "mean in CrewAI? How does it differ from", tags$code("Process.hierarchical"), "?"),
            tags$li("Why is", tags$code("code_execution_config={\"use_docker\": False}"), "important for local testing?"),
            tags$li("What is the TERMINATE pattern and why is it needed in AutoGen group chats?")
          ),
          br(),
          textAreaInput(ns("notes"), "Study notes:", value="", rows=3, placeholder="Notes on AutoGen, CrewAI patterns, gotchas..."),
          fluidRow(
            column(4, sliderInput(ns("progress"), "Chapter 4 readiness:", 0, 100, 0, step=5)),
            column(3, br(), actionButton(ns("save_progress"), "Save", class="btn-primary"))
          )
      )
    )
  )
}

autogen_crewai_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_progress, {
      study_mgr$save_note("autogen_crewai", input$notes)
      study_mgr$update_progress("autogen_crewai", input$progress)
      showNotification("Chapter 4 progress saved!", type="message", duration=3)
    })
  })
}
