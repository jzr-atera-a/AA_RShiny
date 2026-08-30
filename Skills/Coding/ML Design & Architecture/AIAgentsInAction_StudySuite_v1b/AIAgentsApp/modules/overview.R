# modules/overview.R — Overview & Roadmap

overview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "meta-hero",
        tags$h1("AI Agents in Action — Study Suite"),
        tags$h2("Michael Lanham · Manning Publications · 11 Chapters · Full Stack AI Agent Development"),
        div(
          span(class = "hero-badge", "11 Chapters"),
          span(class = "hero-badge", "6 Frameworks"),
          span(class = "hero-badge", "Python 3.10"),
          span(class = "hero-badge", "OpenAI + SK + AutoGen"),
          span(class = "hero-badge", "Prompt Flow")
        )
    ),

    fluidRow(
      column(2, div(class = "metric-card", span(class = "metric-value", textOutput(ns("pct_overall"))), span(class = "metric-label", "Study Progress"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "11"),  span(class = "metric-label", "Book Chapters"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "6"),   span(class = "metric-label", "AI Frameworks"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "45+"), span(class = "metric-label", "Code Scripts"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "3"),   span(class = "metric-label", "UI Toolkits"))),
      column(2, div(class = "metric-card", span(class = "metric-value", "2026"), span(class = "metric-label", "API Watch Year")))
    ),

    fluidRow(
      box(title = "📚 Book Architecture — The 11 Chapters", status = "primary",
          solidHeader = TRUE, width = 8,
          div(class = "success-box",
              HTML("<strong>Lanham's progression:</strong> The book builds deliberately — from a single API call through local models, multi-agent orchestration, memory systems, DAG-based prompt pipelines, and finally production UIs. Each chapter adds one architectural layer.")),
          br(),
          fluidRow(
            column(6,
              chapter_card("Ch.2", "LLM Foundations", "Direct OpenAI API, prompt engineering, function calling, JSON output, message history.", c("OpenAI SDK","Prompt Design","Functions")),
              chapter_card("Ch.4", "Multi-Agent Frameworks", "AutoGen Studio 0.4.x, CrewAI crews, agent-to-agent communication, tool use.", c("AutoGen","CrewAI","Tools")),
              chapter_card("Ch.6", "Behavior Trees", "py_trees library, Blackboard data sharing, agent decisions as composable tree structures.", c("py_trees","BTs","Decisions")),
              chapter_card("Ch.8", "Memory & RAG", "Semantic Kernel memory store, vector search, LangChain retrieval, ChromaDB embeddings.", c("SK Memory","LangChain","ChromaDB")),
              chapter_card("Ch.10", "Prompting Techniques", "11 techniques via Prompt Flow: zero-shot through tree-of-thoughts, self-consistency evaluation.", c("Zero-shot","CoT","ToT"))
            ),
            column(6,
              chapter_card("Ch.3", "Agent Fundamentals", "What makes an agent vs a chatbot. ReAct loops, tool calling patterns, planning strategies.", c("ReAct","Planning","Tools")),
              chapter_card("Ch.5", "Semantic Kernel", "Kernel, plugins, native functions, prompt templates, planner, OpenAI connector.", c("SK","Plugins","Kernel")),
              chapter_card("Ch.7", "Chat UIs (Streamlit)", "Streamlit chat interfaces, session state, streaming responses, multi-turn conversations.", c("Streamlit","Streaming","Chat")),
              chapter_card("Ch.9", "Prompt Flow", "Microsoft Prompt Flow DAGs, YAML-defined pipelines, LLM + Python nodes, evaluation flows.", c("Prompt Flow","DAGs","Evaluation")),
              chapter_card("Ch.11", "Assistants API + Gradio", "OpenAI Assistants API, threads, streaming event handlers, Gradio UIs, file uploads.", c("Assistants","Gradio","Threads"))
            )
          )
      ),
      box(title = "⚡ Framework Comparison at a Glance", status = "info",
          solidHeader = TRUE, width = 4,
          div(class = "section-heading-dark", "Orchestration Layer"),
          framework_card("OpenAI SDK (Direct)", "Maximum control. No abstraction. Chapter 2's foundation — understand this before any framework."),
          framework_card("AutoGen 0.4.x", "Microsoft's multi-agent chat framework. ConversableAgent pattern, tool execution, code-writing agents."),
          framework_card("CrewAI", "Role-based crews. Researcher + Writer patterns. Sequential/hierarchical processes. YAML task definitions."),
          framework_card("Semantic Kernel", "Microsoft's SDK for LLM application development. Kernel + Plugin + Planner architecture. C#/Python."),
          br(),
          div(class = "section-heading-dark", "Orchestration Layer"),
          framework_card("Prompt Flow", "Microsoft's DAG-based LLM pipeline tool. YAML DAGs, variants, evaluation flows. Now deprecated (Apr 2027)."),
          framework_card("py_trees", "Behavior tree library. Not LLM-specific — provides agent decision structure independent of the model.")
      )
    ),

    fluidRow(
      box(title = "📊 Your Chapter Progress", status = "primary", solidHeader = TRUE, width = 12,
          uiOutput(ns("tab_progress_bars"))
      )
    ),

    fluidRow(
      box(title = "🔄 The Agent Development Stack — Layered View", status = "warning",
          solidHeader = TRUE, width = 12,
          tags$table(class = "table table-hover",
            tags$thead(tags$tr(
              tags$th("Layer"), tags$th("What it handles"), tags$th("Book coverage"),
              tags$th("Key tools"), tags$th("Deprecated risk")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$b("Model API")),        tags$td("LLM calls, tokens, streaming"),         tags$td("Ch.2"),       tags$td("openai 2.x, streaming"), tags$td(status_badge("gpt-4-turbo Oct-26","warn"))),
              tags$tr(tags$td(tags$b("Prompt Design")),    tags$td("Templates, few-shot, CoT, ToT"),         tags$td("Ch.2, 10"),   tags$td("jinja2, Prompt Flow"),   tags$td(status_badge("Stable","ok"))),
              tags$tr(tags$td(tags$b("Tool Use")),         tags$td("Function calling, structured output"),   tags$td("Ch.2, 4, 5"), tags$td("function_definitions"),  tags$td(status_badge("Stable","ok"))),
              tags$tr(tags$td(tags$b("Agent Loop")),       tags$td("ReAct, planning, reflection, memory"),   tags$td("Ch.3–5"),     tags$td("AutoGen, CrewAI, SK"),   tags$td(status_badge("SK evolving","warn"))),
              tags$tr(tags$td(tags$b("Behavior Control")), tags$td("Decisions, sequences, priorities"),      tags$td("Ch.6"),       tags$td("py_trees BT library"),   tags$td(status_badge("Stable","ok"))),
              tags$tr(tags$td(tags$b("Memory & RAG")),     tags$td("Vector search, semantic recall"),        tags$td("Ch.8"),       tags$td("SK memory, ChromaDB"),   tags$td(status_badge("LangChain v3","warn"))),
              tags$tr(tags$td(tags$b("Pipeline")),         tags$td("DAG orchestration, eval flows"),         tags$td("Ch.9–10"),    tags$td("Prompt Flow 1.18.5"),    tags$td(status_badge("Retiring Apr-27","warn"))),
              tags$tr(tags$td(tags$b("UI Layer")),         tags$td("Chat interfaces, streaming, panels"),    tags$td("Ch.7, 11"),   tags$td("Streamlit, Gradio 6.x"), tags$td(status_badge("Gradio 6 changed","warn"))),
              tags$tr(tags$td(tags$b("Assistants API")),   tags$td("Threads, runs, file search, CI"),        tags$td("Ch.11"),      tags$td("beta.assistants"),       tags$td(status_badge("SHUTDOWN Aug-26","danger")))
            )
          ),
          div(class = "tip-box", HTML("<strong>💡 Reading order:</strong> Chapters 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11. Each chapter assumes the previous. If you skip Ch.2's API fundamentals, Ch.5's Semantic Kernel fixes will make less sense. Don't skip."))
      )
    )
  )
}

overview_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {

    output$pct_overall <- renderText({
      study_mgr$progress_trigger()
      paste0(study_mgr$get_overall_progress(), "%")
    })

    output$tab_progress_bars <- renderUI({
      study_mgr$progress_trigger()
      tabs <- list(
        list(id="llm_foundations",      label="LLM Foundations (Ch.2)"),
        list(id="local_agents",         label="Local Models (Ch.3)"),
        list(id="autogen_crewai",       label="AutoGen & CrewAI (Ch.4)"),
        list(id="semantic_kernel",      label="Semantic Kernel (Ch.5)"),
        list(id="behavior_trees",       label="Behavior Trees (Ch.6)"),
        list(id="chat_uis",             label="Chat UIs — Streamlit (Ch.7)"),
        list(id="memory_rag",           label="Memory & RAG (Ch.8)"),
        list(id="prompt_flow",          label="Prompt Flow (Ch.9)"),
        list(id="prompting_techniques", label="Prompting Techniques (Ch.10)"),
        list(id="assistants_api",       label="Assistants API & Gradio (Ch.11)"),
        list(id="deprecations",         label="API Sunset Tracker"),
        list(id="quiz",                 label="Chapter Quiz")
      )
      bars <- lapply(tabs, function(t) {
        pct <- study_mgr$get_progress(t$id)
        col <- progress_colour(pct)
        fluidRow(
          column(3, tags$small(tags$b(t$label))),
          column(7, div(style="background:rgba(196,181,253,0.2);border-radius:6px;height:12px;",
                        div(style=paste0("width:",pct,"%;background:",col,";border-radius:6px;height:12px;transition:width 0.6s;")))),
          column(2, tags$small(style=paste0("color:",col,";font-weight:700;"), paste0(pct,"%")))
        )
      })
      do.call(tagList, bars)
    })
  })
}
