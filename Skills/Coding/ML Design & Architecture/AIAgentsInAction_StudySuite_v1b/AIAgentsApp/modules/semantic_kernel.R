# modules/semantic_kernel.R — Chapter 5: Semantic Kernel

semantic_kernel_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Semantic Kernel"),
        tags$h2("Chapter 5 — Microsoft's SDK for LLM Applications: Kernel, Plugins & Planner"),
        div(span(class="hero-badge","semantic-kernel 1.43.1"), span(class="hero-badge","Plugins"),
            span(class="hero-badge","KernelArguments"), span(class="hero-badge","FunctionChoiceBehavior"))
    ),

    fluidRow(
      box(title="⚠️ The API Churn Problem — 100% of Scripts Needed Fixes", status="danger", solidHeader=TRUE, width=12,
          div(class="warn-box", HTML("<strong>Session finding:</strong> All 7 Semantic Kernel scripts tested in this book required at least one fix. The book was written against an early 0.x/early-1.x version. The installed version (1.43.1) has a completely different API surface. Apply every fix in the table below <em>proactively before running any script</em>.")),
          br(),
          tags$table(class="table table-hover",
            tags$thead(tags$tr(tags$th("Deprecated (book's code)"), tags$th("Current (1.43.1)"), tags$th("Error if not fixed"))),
            tags$tbody(
              compare_row("sk.openai_settings_from_dot_env()",    "os.getenv('OPENAI_API_KEY') + load_dotenv()",      "AttributeError: function removed entirely"),
              compare_row("sk.PromptTemplateConfig",               "from semantic_kernel.prompt_template import PromptTemplateConfig", "ImportError"),
              compare_row("sk.KernelArguments",                    "from semantic_kernel.functions import KernelArguments",           "ImportError"),
              compare_row("kernel.create_function_from_prompt(...)",  "kernel.add_function(...)",                      "AttributeError: renamed"),
              compare_row("kernel.import_plugin_from_object(obj, name)", "kernel.add_plugin(obj, name)",               "AttributeError: renamed"),
              compare_row("@kernel_function(..., input_description='...')", "Remove input_description kwarg",          "TypeError: unexpected keyword argument"),
              compare_row("tool_choice='auto', tools=get_tool_call_object(...)", "function_choice_behavior=FunctionChoiceBehavior.Auto()", "TypeError"),
              compare_row("chat_completion_with_tool_call(...)",    "FunctionChoiceBehavior.Auto() + get_chat_message_content()", "AttributeError: function doesn't exist")
            )
          )
      )
    ),

    fluidRow(
      box(title="🏗️ SK Architecture — The Kernel + Plugin Model", status="primary", solidHeader=TRUE, width=6,
          div(class="success-box", HTML("<strong>Core concept:</strong> The <em>Kernel</em> is the central dependency injection container. It holds AI services (OpenAI, Azure), plugins (collections of functions), and memory. Everything flows through the Kernel.")),
          br(),
          div(class="section-heading-dark", "Modern Kernel Setup (v1.43.1)"),
          div(class="code-box", HTML(
            '<span style="color:#C4B5FD">import</span> os<br>
             <span style="color:#C4B5FD">from</span> dotenv <span style="color:#C4B5FD">import</span> load_dotenv<br>
             <span style="color:#C4B5FD">import</span> semantic_kernel <span style="color:#C4B5FD">as</span> sk<br>
             <span style="color:#C4B5FD">from</span> semantic_kernel.connectors.ai.open_ai <span style="color:#C4B5FD">import</span> (<br>
             &nbsp;&nbsp;OpenAIChatCompletion, OpenAIChatPromptExecutionSettings<br>
             )<br>
             <span style="color:#C4B5FD">from</span> semantic_kernel.connectors.ai.function_choice_behavior <span style="color:#C4B5FD">import</span> FunctionChoiceBehavior<br>
             <span style="color:#C4B5FD">from</span> semantic_kernel.functions <span style="color:#C4B5FD">import</span> KernelArguments<br><br>
             load_dotenv()<br>
             kernel = sk.Kernel()<br>
             kernel.add_service(OpenAIChatCompletion(<br>
             &nbsp;&nbsp;service_id=<span style="color:#FCD34D">"chat"</span>,<br>
             &nbsp;&nbsp;ai_model_id=<span style="color:#FCD34D">"gpt-4o-mini"</span>,<br>
             &nbsp;&nbsp;api_key=os.getenv(<span style="color:#FCD34D">"OPENAI_API_KEY"</span>)<br>
             ))'
          )),
          div(class="section-heading-dark", "Native Plugin (Python class)"),
          div(class="code-box", HTML(
            '<span style="color:#C4B5FD">from</span> semantic_kernel.functions <span style="color:#C4B5FD">import</span> kernel_function<br><br>
             <span style="color:#C4B5FD">class</span> <span style="color:#FCD34D">TimePlugin</span>:<br>
             &nbsp;&nbsp;<span style="color:#A5F3FC">@kernel_function</span>(<br>
             &nbsp;&nbsp;&nbsp;&nbsp;description=<span style="color:#FCD34D">"Returns the current time"</span>,<br>
             &nbsp;&nbsp;&nbsp;&nbsp;name=<span style="color:#FCD34D">"get_time"</span><br>
             &nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#6B7280"># No input_description= anymore!</span><br>
             &nbsp;&nbsp;)<br>
             &nbsp;&nbsp;<span style="color:#C4B5FD">def</span> <span style="color:#FCD34D">get_time</span>(self) -> str:<br>
             &nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#C4B5FD">from</span> datetime <span style="color:#C4B5FD">import</span> datetime<br>
             &nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#C4B5FD">return</span> datetime.now().strftime(<span style="color:#FCD34D">"%H:%M:%S"</span>)<br><br>
             kernel.add_plugin(TimePlugin(), <span style="color:#FCD34D">"time"</span>)'
          ))
      ),
      box(title="🔄 Tool Calling Pattern — The Modern Way", status="info", solidHeader=TRUE, width=6,
          div(class="section-heading-dark", "FunctionChoiceBehavior.Auto()"),
          tags$p("This single setting replaces the old two-kwarg pattern (tool_choice + tools=get_tool_call_object(...)). The kernel automatically exposes all registered plugins as callable tools."),
          div(class="code-box", HTML(
            'settings = OpenAIChatPromptExecutionSettings(<br>
             &nbsp;&nbsp;service_id=<span style="color:#FCD34D">"chat"</span>,<br>
             &nbsp;&nbsp;ai_model_id=<span style="color:#FCD34D">"gpt-4o-mini"</span>,<br>
             &nbsp;&nbsp;function_choice_behavior=FunctionChoiceBehavior.Auto()<br>
             )<br><br>
             chat_svc = kernel.get_service(<span style="color:#FCD34D">"chat"</span>)<br>
             history = ChatHistory()<br>
             history.add_user_message(<span style="color:#FCD34D">"What time is it?"</span>)<br><br>
             result = <span style="color:#C4B5FD">await</span> chat_svc.get_chat_message_content(<br>
             &nbsp;&nbsp;chat_history=history,<br>
             &nbsp;&nbsp;settings=settings,<br>
             &nbsp;&nbsp;kernel=kernel<br>
             )'
          )),
          div(class="section-heading-dark", "The Skill → Plugin rename"),
          div(class="framework-card", tags$h5("What changed"),
              tags$p("In Semantic Kernel 1.x, 'Skills' were renamed 'Plugins' throughout the API. import_skill() → add_plugin(). skill_name= → plugin_name=. Every reference to 'skill' in the book needs to become 'plugin'.")),
          div(class="section-heading-dark", "Prompt template functions"),
          div(class="code-box", HTML(
            '<span style="color:#6B7280"># Old: kernel.create_semantic_function(prompt, skill_name=...)</span><br>
             <span style="color:#6B7280"># New:</span><br>
             func = kernel.add_function(<br>
             &nbsp;&nbsp;plugin_name=<span style="color:#FCD34D">"MyPlugin"</span>,<br>
             &nbsp;&nbsp;function_name=<span style="color:#FCD34D">"Summarize"</span>,<br>
             &nbsp;&nbsp;prompt=<span style="color:#FCD34D">"Summarize this: {{$input}}"</span>,<br>
             &nbsp;&nbsp;prompt_execution_settings=settings<br>
             )<br>
             result = <span style="color:#C4B5FD">await</span> kernel.invoke(func, KernelArguments(input=<span style="color:#FCD34D">"..."</span>))'
          ))
      )
    ),

    fluidRow(
      box(title="✍️ Study Notes & Self-Assessment", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(6,
                   div(class="section-heading-dark", "Key questions for Ch.5"),
                   tags$ul(
                     tags$li("What is the difference between a native plugin and a prompt template function in SK?"),
                     tags$li("How does FunctionChoiceBehavior.Auto() differ from the old tool_choice='auto' pattern?"),
                     tags$li("Why does", tags$code("input_description="), "cause a TypeError even though it looks valid?"),
                     tags$li("What does", tags$code("kernel.invoke(func, KernelArguments(...))"), "replace?"),
                     tags$li("How would you add an Azure OpenAI backend instead of direct OpenAI to the same kernel?")
                   )
            ),
            column(6,
                   textAreaInput(ns("notes"), "Study notes:", value="", rows=4, placeholder="Notes on SK kernel, plugins, API migration..."),
                   fluidRow(
                     column(5, sliderInput(ns("progress"), "Chapter 5 readiness:", 0, 100, 0, step=5)),
                     column(3, br(), actionButton(ns("save_progress"), "Save", class="btn-primary"))
                   )
            )
          )
      )
    )
  )
}

semantic_kernel_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_progress, {
      study_mgr$save_note("semantic_kernel", input$notes)
      study_mgr$update_progress("semantic_kernel", input$progress)
      showNotification("Chapter 5 progress saved!", type="message", duration=3)
    })
  })
}
