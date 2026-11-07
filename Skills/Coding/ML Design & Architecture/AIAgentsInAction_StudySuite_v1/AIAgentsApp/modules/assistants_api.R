# modules/assistants_api.R — Chapter 11: Assistants API & Gradio

assistants_api_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Assistants API & Gradio"),
        tags$h2("Chapter 11 — OpenAI Assistants API, Streaming Event Handlers, Gradio UIs"),
        div(span(class="hero-badge","openai 2.43.0"), span(class="hero-badge","Gradio 6.x"),
            span(class="hero-badge","AssistantEventHandler"), span(class="hero-badge","Threads & Runs"))
    ),

    fluidRow(
      box(title="🚨 CRITICAL: Assistants API Shuts Down August 26, 2026", status="danger", solidHeader=TRUE, width=12,
          div(class="warn-box", HTML(
            "<strong>This is not a deprecation — it's a shutdown.</strong> Per OpenAI's deprecations page, on August 26, 2025 OpenAI notified developers that <code>client.beta.assistants.*</code> and <code>client.beta.threads.*</code> will be fully removed from the API on <strong>August 26, 2026</strong> — approximately <strong>2 months from this session</strong>.<br><br>
             <strong>10 of 14 files in Chapter 11 will stop working on that date.</strong> The other 4 are unaffected:<br>
             ✓ <code>gradio_chat.py</code> — plain Chat Completions, not Assistants<br>
             ✓ <code>webcam.py</code>, <code>zzz_working.py</code> — no OpenAI dependency<br>
             ✓ <code>streamlit_assistants_playground.py</code> — ships empty<br><br>
             OpenAI's recommended replacement: <strong>Responses API + Conversations API</strong>. Migration guide: <code>developers.openai.com/api/docs/assistants/migration</code>"
          ))
      )
    ),

    fluidRow(
      box(title="🧵 Core Concepts: Assistants, Threads & Runs", status="primary", solidHeader=TRUE, width=6,
          framework_card("Assistant", "A configured AI persona — model, instructions, tools (code_interpreter, file_search) — created once and referenced by ID. Persists across sessions."),
          framework_card("Thread", "A persistent conversation. The API stores and auto-truncates message history for you. You don't manage the message array manually."),
          framework_card("Run", "One execution of an Assistant against a Thread. May involve multiple tool calls internally. Returns status: queued → in_progress → completed."),
          framework_card("AssistantEventHandler", "Subclassable callback for streaming — on_text_delta, on_tool_call_delta, on_image_file_done fire as the run progresses."),
          br(),
          div(class="code-box", HTML(
            '<span style="color:#C4B5FD">from</span> openai <span style="color:#C4B5FD">import</span> OpenAI, AssistantEventHandler<br>
             <span style="color:#C4B5FD">from</span> typing_extensions <span style="color:#C4B5FD">import</span> override<br><br>
             client = OpenAI()<br>
             assistant = client.beta.assistants.create(<br>
             &nbsp;&nbsp;name=<span style="color:#FCD34D">"Code Helper"</span>,<br>
             &nbsp;&nbsp;instructions=<span style="color:#FCD34D">"You are a coding expert."</span>,<br>
             &nbsp;&nbsp;tools=[{<span style="color:#FCD34D">"type"</span>:<span style="color:#FCD34D">"code_interpreter"</span>}],<br>
             &nbsp;&nbsp;model=<span style="color:#FCD34D">"gpt-4.1"</span>  <span style="color:#6B7280"># was gpt-4-turbo</span><br>
             )<br>
             thread = client.beta.threads.create()'
          ))
      ),
      box(title="🛠️ All 15 Fixes Applied to Chapter 11", status="warning", solidHeader=TRUE, width=6,
          div(class="section-heading-dark", "Logic bugs (genuine, not version drift)"),
          timeline_entry("Bug 1", "streamlit_manage_assistants.py — create", "api.create_assistant() called with 4 args; method requires 8. TypeError on every button click."),
          timeline_entry("Bug 2", "streamlit_manage_assistants.py — update", "api.update_assistant() wrong arity AND first two args swapped (id where name expected). TypeError + silent data corruption."),
          timeline_entry("Bug 3", "'model' in assistant always False", "assistant is a pydantic object; 'in' checks key names against string 'model', which never matches. Displayed model never reflected reality."),
          timeline_entry("Bug 4", "response_format='type'", "gradio_assistants_panel.py set response_format to the literal string 'type' — not a valid API value. Broken in create, update, AND display paths."),
          br(),
          div(class="section-heading-dark", "Version/API changes"),
          timeline_entry("Fix 5", "gpt-4-turbo → gpt-4.1", "gpt-4-turbo is retiring Oct 2026. gpt-4.1 is OpenAI's listed replacement."),
          timeline_entry("Fix 6", "gpt-4-1106-preview already dead", "Retired March 2026. Replaced with gpt-4.1 in chatgpt_clone_streaming.py."),
          timeline_entry("Fix 7", "Gradio bubble_full_width removed", "This gr.Chatbot kwarg no longer exists in Gradio 6.x. Raises TypeError."),
          timeline_entry("Fix 8", "Gradio tuple → messages format", "Gradio 6.x removed the old (user, bot) tuple chat format entirely. All history code rewritten for {role, content} dicts."),
          timeline_entry("Fix 9", "Missing load_dotenv()", "3 of 7 OpenAI-calling files were missing this call. Only worked if OPENAI_API_KEY was already in shell env.")
      )
    ),

    fluidRow(
      box(title="✍️ Study Notes", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(6, textAreaInput(ns("notes"), "Study notes:", value="", rows=3, placeholder="Notes on Assistants API, threads, streaming, Gradio migration...")),
            column(3, sliderInput(ns("progress"), "Chapter 11 readiness:", 0, 100, 0, step=5)),
            column(3, br(), actionButton(ns("save_progress"), "Save Progress", class="btn-primary"))
          )
      )
    )
  )
}

assistants_api_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_progress, {
      study_mgr$save_note("assistants_api", input$notes)
      study_mgr$update_progress("assistants_api", input$progress)
      showNotification("Chapter 11 progress saved!", type="message", duration=3)
    })
  })
}
