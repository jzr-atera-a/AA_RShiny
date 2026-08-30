# modules/llm_foundations.R — Chapter 2: LLM Foundations & Direct API

llm_foundations_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("LLM Foundations"),
        tags$h2("Chapter 2 — Direct OpenAI API, Prompt Engineering, Function Calling"),
        div(span(class="hero-badge","openai 2.x"), span(class="hero-badge","Function Calling"),
            span(class="hero-badge","JSON Mode"), span(class="hero-badge","Streaming"))
    ),

    fluidRow(
      box(title="🔌 The OpenAI SDK — Core Patterns (Ch.2)", status="primary", solidHeader=TRUE, width=6,
          div(class="success-box", HTML("<strong>Foundation principle:</strong> Before learning any framework (Semantic Kernel, AutoGen, CrewAI), you must understand the raw API. Every framework is ultimately calling <code>client.chat.completions.create()</code> beneath its abstractions.")),
          br(),
          div(class="section-heading-dark", "Instantiation"),
          div(class="code-box", HTML(
            '<span style="color:#C4B5FD">from</span> <span style="color:#FCD34D">openai</span> <span style="color:#C4B5FD">import</span> OpenAI<br>
             <span style="color:#C4B5FD">from</span> <span style="color:#FCD34D">dotenv</span> <span style="color:#C4B5FD">import</span> load_dotenv<br>
             load_dotenv()  <span style="color:#6B7280"># reads OPENAI_API_KEY from .env</span><br>
             client = OpenAI()'
          )),
          div(class="section-heading-dark", "The Message Array — Central Concept"),
          tags$p("Every call to the API is a list of messages. Three roles: ", tags$code("system"), ", ", tags$code("user"), ", ", tags$code("assistant"), ". The model completes the conversation."),
          div(class="code-box", HTML(
            'response = client.chat.completions.create(<br>
             &nbsp;&nbsp;model=<span style="color:#FCD34D">"gpt-4o-mini"</span>,<br>
             &nbsp;&nbsp;messages=[<br>
             &nbsp;&nbsp;&nbsp;&nbsp;{<span style="color:#FCD34D">"role"</span>: <span style="color:#FCD34D">"system"</span>, <span style="color:#FCD34D">"content"</span>: <span style="color:#FCD34D">"You are a helpful assistant."</span>},<br>
             &nbsp;&nbsp;&nbsp;&nbsp;{<span style="color:#FCD34D">"role"</span>: <span style="color:#FCD34D">"user"</span>, <span style="color:#FCD34D">"content"</span>: <span style="color:#FCD34D">"Explain ReAct in one sentence."</span>}<br>
             &nbsp;&nbsp;]<br>
             )<br>
             text = response.choices[0].message.content'
          )),
          div(class="section-heading-dark", "Streaming"),
          tags$p("Pass ", tags$code("stream=True"), " to get token-by-token delta updates. This is how every chapter's chat UI achieves the \"typewriter\" effect."),
          div(class="code-box", HTML(
            'stream = client.chat.completions.create(<br>
             &nbsp;&nbsp;model=<span style="color:#FCD34D">"gpt-4o-mini"</span>,<br>
             &nbsp;&nbsp;messages=messages, stream=<span style="color:#A5F3FC">True</span><br>
             )<br>
             <span style="color:#C4B5FD">for</span> chunk <span style="color:#C4B5FD">in</span> stream:<br>
             &nbsp;&nbsp;delta = chunk.choices[0].delta.content <span style="color:#C4B5FD">or</span> <span style="color:#FCD34D">""</span><br>
             &nbsp;&nbsp;<span style="color:#FCD34D">print</span>(delta, end=<span style="color:#FCD34D">""</span>, flush=<span style="color:#A5F3FC">True</span>)'
          ))
      ),
      box(title="🔧 Function Calling — The Gateway to Agents (Ch.2)", status="info", solidHeader=TRUE, width=6,
          div(class="warn-box", HTML("<strong>Model substitution required:</strong> The book uses <code>gpt-4-1106-preview</code> and <code>gpt-3.5-turbo-1106</code> — both retired by OpenAI in March 2026. Replace with <code>gpt-4o-mini</code> everywhere.")),
          br(),
          div(class="section-heading-dark", "Why Function Calling Matters"),
          tags$p("This is the primitive that makes agents possible. Instead of generating text, the model can return a ", tags$em("structured tool call"), " — a JSON blob saying which function to call and with what arguments. The application executes the function, returns the result, and continues the conversation."),
          div(class="section-heading-dark", "Function Definition Schema"),
          div(class="code-box", HTML(
            'tools = [<br>
             &nbsp;&nbsp;{<br>
             &nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#FCD34D">"type"</span>: <span style="color:#FCD34D">"function"</span>,<br>
             &nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#FCD34D">"function"</span>: {<br>
             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#FCD34D">"name"</span>: <span style="color:#FCD34D">"get_weather"</span>,<br>
             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#FCD34D">"description"</span>: <span style="color:#FCD34D">"Returns current weather"</span>,<br>
             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#FCD34D">"parameters"</span>: {<br>
             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#FCD34D">"type"</span>: <span style="color:#FCD34D">"object"</span>,<br>
             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#FCD34D">"properties"</span>: {<br>
             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#FCD34D">"city"</span>: {<span style="color:#FCD34D">"type"</span>: <span style="color:#FCD34D">"string"</span>}<br>
             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;},<br>
             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#FCD34D">"required"</span>: [<span style="color:#FCD34D">"city"</span>]<br>
             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}<br>
             &nbsp;&nbsp;&nbsp;&nbsp;}<br>
             &nbsp;&nbsp;}<br>
             ]'
          )),
          div(class="section-heading-dark", "Parallel Function Calling"),
          tags$p("A single message can trigger multiple simultaneous tool calls — e.g. recommend movies AND recipes AND gifts in one turn. The model returns a list of tool_calls; you execute each one and return results."),
          div(class="tip-box", HTML("<strong>💡 Book insight:</strong> Ch.2 deliberately shows the <code>recommend()</code> function as a hardcoded if/elif lookup. This is intentional — the chapter is teaching argument extraction + orchestration, not content intelligence. The model's job is selecting the right tool with the right arguments; what the function does is your responsibility."))
      )
    ),

    fluidRow(
      box(title="📝 JSON Mode & Structured Output", status="success", solidHeader=TRUE, width=6,
          div(class="section-heading-dark", "When to use JSON mode"),
          tags$p("Pass ", tags$code('response_format={"type": "json_object"}'), " when your code needs to parse the model's response programmatically rather than display it as prose. The model guarantees valid JSON."),
          div(class="framework-card", tags$h5("Use case examples"),
              tags$ul(
                tags$li("Parsing movie recommendations into a structured list"),
                tags$li("Extracting named entities from user queries"),
                tags$li("Generating config objects or API payloads"),
                tags$li("Returning scores or ratings as a machine-readable dict")
              )),
          div(class="warn-box", HTML("<strong>⚠️ Trap:</strong> Even with JSON mode, the model can nest extra keys or vary field names. Always validate the output against an expected schema before using it downstream — don't assume the keys will match exactly what you asked for."))
      ),
      box(title="🗺️ Message History — Multi-Turn Conversations", status="warning", solidHeader=TRUE, width=6,
          div(class="section-heading-dark", "Stateless API — State is your responsibility"),
          tags$p("The OpenAI API is completely stateless. Every call starts fresh. To have a multi-turn conversation, you must pass the full message history on each request."),
          div(class="code-box", HTML(
            '<span style="color:#6B7280"># Build history manually</span><br>
             history = [{<span style="color:#FCD34D">"role"</span>:<span style="color:#FCD34D">"system"</span>, <span style="color:#FCD34D">"content"</span>:<span style="color:#FCD34D">"You help plan meals."</span>}]<br><br>
             <span style="color:#C4B5FD">while</span> <span style="color:#A5F3FC">True</span>:<br>
             &nbsp;&nbsp;user_msg = <span style="color:#FCD34D">input</span>(<span style="color:#FCD34D">"You: "</span>)<br>
             &nbsp;&nbsp;history.append({<span style="color:#FCD34D">"role"</span>:<span style="color:#FCD34D">"user"</span>, <span style="color:#FCD34D">"content"</span>:user_msg})<br>
             &nbsp;&nbsp;r = client.chat.completions.create(model=<span style="color:#FCD34D">"gpt-4o-mini"</span>, messages=history)<br>
             &nbsp;&nbsp;reply = r.choices[0].message.content<br>
             &nbsp;&nbsp;history.append({<span style="color:#FCD34D">"role"</span>:<span style="color:#FCD34D">"assistant"</span>, <span style="color:#FCD34D">"content"</span>:reply})<br>
             &nbsp;&nbsp;<span style="color:#FCD34D">print</span>(<span style="color:#FCD34D">f"AI: {reply}"</span>)'
          )),
          div(class="tip-box", HTML("<strong>💡 Token budget:</strong> Every token in the history counts against the context window and costs money. In production, you need a truncation strategy — keep the system message, drop oldest user/assistant pairs, or summarise the middle of the conversation."))
      )
    ),

    fluidRow(
      box(title="✍️ Practice — Fix the API Call", status="primary", solidHeader=TRUE, width=12,
          fluidRow(
            column(4,
                   div(class="section-heading-dark", "Select a scenario"),
                   selectInput(ns("api_scenario"), NULL, choices=c(
                     "Fix the retired model id",
                     "Add streaming to a blocking call",
                     "Convert to JSON mode",
                     "Add function calling",
                     "Build a 3-turn conversation"
                   )),
                   br(),
                   actionButton(ns("show_answer"), "Show Correct Implementation", class="btn-primary btn-block")
            ),
            column(8,
                   div(class="section-heading-dark", "Broken code (as it might appear in the book)"),
                   uiOutput(ns("scenario_code")),
                   br(),
                   uiOutput(ns("scenario_answer"))
            )
          ),
          hr(),
          fluidRow(
            column(12,
                   div(class="section-heading-dark", "My study notes"),
                   textAreaInput(ns("notes"), NULL, value="", rows=3, placeholder="Notes on Ch.2 API patterns, gotchas, things to remember..."),
                   fluidRow(
                     column(4, sliderInput(ns("progress"), "Chapter 2 readiness:", 0, 100, value=0, step=5)),
                     column(3, br(), actionButton(ns("save_progress"), "Save Progress", class="btn-primary"))
                   )
            )
          )
      )
    )
  )
}

llm_foundations_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {

    SCENARIOS <- list(
      "Fix the retired model id" = list(
        broken = 'response = client.chat.completions.create(\n  model="gpt-4-1106-preview",  # RETIRED March 2026\n  messages=[{"role":"user","content":"Hello"}]\n)',
        fixed  = 'response = client.chat.completions.create(\n  model="gpt-4o-mini",  # Current, no sunset date\n  messages=[{"role":"user","content":"Hello"}]\n)\n# Also accept: "gpt-4.1", "gpt-4o"'
      ),
      "Add streaming to a blocking call" = list(
        broken = 'response = client.chat.completions.create(\n  model="gpt-4o-mini",\n  messages=messages\n)\nprint(response.choices[0].message.content)',
        fixed  = 'stream = client.chat.completions.create(\n  model="gpt-4o-mini",\n  messages=messages,\n  stream=True  # Key addition\n)\nfor chunk in stream:\n  delta = chunk.choices[0].delta.content or ""\n  print(delta, end="", flush=True)'
      ),
      "Convert to JSON mode" = list(
        broken = 'response = client.chat.completions.create(\n  model="gpt-4o-mini",\n  messages=[{"role":"user","content":"Return a dict with name and score"}]\n)',
        fixed  = 'response = client.chat.completions.create(\n  model="gpt-4o-mini",\n  messages=[{"role":"user","content":"Return JSON: {name, score}"}],\n  response_format={"type": "json_object"}  # Guarantees valid JSON\n)\nimport json\ndata = json.loads(response.choices[0].message.content)'
      ),
      "Add function calling" = list(
        broken = 'response = client.chat.completions.create(\n  model="gpt-4o-mini",\n  messages=[{"role":"user","content":"What is 2+2?"}]\n)',
        fixed  = 'tools = [{"type":"function","function":{\n  "name":"calculate","description":"Evaluates a math expression",\n  "parameters":{"type":"object","properties":{"expr":{"type":"string"}},\n                "required":["expr"]}}}]\nresponse = client.chat.completions.create(\n  model="gpt-4o-mini",\n  messages=[{"role":"user","content":"What is 2+2?"}],\n  tools=tools, tool_choice="auto"\n)'
      ),
      "Build a 3-turn conversation" = list(
        broken = '# Three separate unlinked calls — the model has no memory\nr1 = client.chat.completions.create(model="gpt-4o-mini", messages=[{"role":"user","content":"My name is Alice"}])\nr2 = client.chat.completions.create(model="gpt-4o-mini", messages=[{"role":"user","content":"What is my name?"}])',
        fixed  = 'history = [{"role":"system","content":"You are a helpful assistant."}]\n\ndef chat(user_msg):\n  history.append({"role":"user","content":user_msg})\n  r = client.chat.completions.create(model="gpt-4o-mini", messages=history)\n  reply = r.choices[0].message.content\n  history.append({"role":"assistant","content":reply})\n  return reply\n\nchat("My name is Alice")\nchat("What is the capital of France?")\nprint(chat("What is my name?"))  # Correctly returns Alice'
      )
    )

    show_ans <- reactiveVal(FALSE)
    observeEvent(input$show_answer, { show_ans(!show_ans()) })
    observeEvent(input$api_scenario, { show_ans(FALSE) })

    output$scenario_code <- renderUI({
      s <- SCENARIOS[[input$api_scenario]]
      div(class="code-box", tags$pre(style="background:transparent;border:none;color:#E9D5FF;margin:0;padding:0;", s$broken))
    })

    output$scenario_answer <- renderUI({
      req(show_ans())
      s <- SCENARIOS[[input$api_scenario]]
      div(
        div(class="section-heading-dark", "✅ Correct implementation"),
        div(class="code-box", tags$pre(style="background:transparent;border:none;color:#BBF7D0;margin:0;padding:0;", s$fixed))
      )
    })

    observeEvent(input$save_progress, {
      study_mgr$save_note("llm_foundations", input$notes)
      study_mgr$update_progress("llm_foundations", input$progress)
      showNotification("Chapter 2 progress saved!", type="message", duration=3)
    })
  })
}
