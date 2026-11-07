# modules/quiz.R — Chapter Quiz

QUIZ_QUESTIONS <- list(
  list(q="In Semantic Kernel 1.43.1, what replaces the old tool_choice='auto' + get_tool_call_object() pattern?",
       choices=c("ToolCallBehavior.EnableKernelFunctions()","FunctionChoiceBehavior.Auto()","kernel.enable_tool_calling()","AutoToolInvoke()"),
       answer=2, chapter="Ch.5", explanation="FunctionChoiceBehavior.Auto() is a single kwarg in OpenAIChatPromptExecutionSettings that replaces the old two-kwarg pattern. It automatically exposes all registered plugins as callable tools."),

  list(q="The book uses verbose=2 for CrewAI. What happens in current CrewAI?",
       choices=c("Sets log level to DEBUG","Works as before","Raises a pydantic ValidationError","Sets log level to WARNING"),
       answer=3, chapter="Ch.4", explanation="Current CrewAI requires verbose=True or verbose=False only. Integer values are no longer accepted and raise a pydantic ValidationError at Crew construction time."),

  list(q="When does OpenAI shut down the Assistants API (client.beta.assistants.*)?",
       choices=c("January 1, 2027","April 20, 2027","August 26, 2026","October 23, 2026"),
       answer=3, chapter="Ch.11", explanation="Per OpenAI's deprecations page, the Assistants API is being removed on August 26, 2026 — one year after the deprecation notice was issued on August 26, 2025."),

  list(q="In Gradio 6.x, what format does gr.Chatbot's history arrive in (for ChatInterface)?",
       choices=c("List of (user, bot) tuples","List of {role, content} dicts","List of Message objects","A pandas DataFrame"),
       answer=2, chapter="Ch.11", explanation="Gradio 6.x removed the old tuple-pair format entirely. History is now a flat list of {role: 'user'/'assistant', content: ...} dicts — the same shape as the OpenAI API's messages array."),

  list(q="What is the correct way to pass a jinja2 prompt template to an SK function in v1.43.1?",
       choices=c("kernel.create_semantic_function(prompt, skill_name='MySkill')","kernel.add_function(plugin_name='X', function_name='Y', prompt='...', prompt_execution_settings=settings)","kernel.import_semantic_function('prompt.yaml')","SKFunction.from_native_method(prompt)"),
       answer=2, chapter="Ch.5", explanation="create_semantic_function() was renamed to add_function() with different kwargs. skill_name became plugin_name. The prompt is passed directly and execution settings replace the old creation_config argument."),

  list(q="In the ReAct pattern, what are the three repeating elements?",
       choices=c("Read, Analyse, Complete","Retrieve, Answer, Check","Thought, Action, Observation","Plan, Execute, Verify"),
       answer=3, chapter="Ch.3", explanation="ReAct = Reason + Act. The cycle is: Thought (internal reasoning about what to do next), Action (tool call with structured arguments), Observation (tool result injected back into context). Repeat until a final answer is ready."),

  list(q="What does memory=False on a py_trees Sequence node mean?",
       choices=c("The tree has no Blackboard","Results are not stored after execution","The Sequence always restarts from its first child if a child returns RUNNING","The Sequence runs children in random order"),
       answer=3, chapter="Ch.6", explanation="With memory=False, a Sequence always restarts evaluation from its first child, even if a previous child returned RUNNING. With memory=True, the Sequence remembers where it stopped and continues from there."),

  list(q="How many of the book's 18 Prompt Flow flows had a correctly customised samples.json before the fixes?",
       choices=c("All 18","About half","Only the evaluate_groundings flow","None — all had the generic {'topic': 'atom'} placeholder"),
       answer=4, chapter="Ch.9/10", explanation="Every single samples.json across all 18 flows still had promptflow's unedited scaffold placeholder {\"topic\": \"atom\"}, which doesn't match any flow's actual declared inputs. All were rebuilt from each flow's own default: values."),

  list(q="In LangChain 1.0, where does langchain.document_loaders now live?",
       choices=c("langchain_core.loaders","langchain_community.document_loaders","langchain.community.loaders","langchain_loaders"),
       answer=2, chapter="Ch.8", explanation="LangChain 1.0 split into multiple packages. Most community integrations moved to langchain_community. The full chain: langchain.document_loaders → langchain_community.document_loaders."),

  list(q="What does the Blackboard in py_trees provide?",
       choices=c("A GUI for visualising the behavior tree","A shared key-value store for all nodes to read and write without tight coupling","A log of all node execution results","A database-backed memory store that persists between runs"),
       answer=2, chapter="Ch.6", explanation="The Blackboard is py_trees' shared in-memory key-value store. Any node can register read or write access to specific keys. This lets nodes communicate (e.g. an action node writing a result that a downstream condition node reads) without creating direct dependencies."),

  list(q="In the self-consistency prompting technique (Ch.10), how is the 'best' answer selected from N samples?",
       choices=c("By taking the most frequent exact string match","By embedding all answers and finding the one closest to the mean embedding","By asking the model to rank all N answers","By choosing the longest answer"),
       answer=2, chapter="Ch.10", explanation="The Prompt Flow self-consistency-evaluation flow embeds all sampled answers, computes the centroid embedding (mean), and selects the answer whose embedding is closest to that centroid using cosine similarity. This is more robust than exact-match majority voting."),

  list(q="What is the @kernel_function decorator's input_description kwarg in SK 1.43.1?",
       choices=c("Renamed to parameter_description","Moved to the function parameter as type annotation","It was removed — passing it raises TypeError","Now optional with a different default"),
       answer=3, chapter="Ch.5", explanation="input_description was removed from @kernel_function in SK 1.x. The only supported kwargs are description= (the function-level docstring) and name=. Passing input_description= raises TypeError: unexpected keyword argument at class-definition time when the module is imported.")
)

quiz_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Chapter Quiz"),
        tags$h2("Test your knowledge across all 11 chapters"),
        div(span(class="hero-badge", paste(length(QUIZ_QUESTIONS),"Questions")),
            span(class="hero-badge","All Chapters"), span(class="hero-badge","Instant Feedback"))
    ),

    fluidRow(
      column(2, div(class="metric-card", span(class="metric-value", textOutput(ns("q_num"))), span(class="metric-label", "Question"))),
      column(2, div(class="metric-card", span(class="metric-value", textOutput(ns("score_display"))), span(class="metric-label", "Score"))),
      column(2, div(class="metric-card", span(class="metric-value", textOutput(ns("pct_display"))), span(class="metric-label", "Accuracy"))),
      column(2, div(class="metric-card", span(class="metric-value", textOutput(ns("chapter_display"))), span(class="metric-label", "Chapter"))),
      column(4, br(), fluidRow(
        column(6, actionButton(ns("new_q"), "New Question", class="btn-primary btn-block")),
        column(6, actionButton(ns("reset_quiz"), "Reset All", class="btn-warning btn-block"))
      ))
    ),

    br(),

    fluidRow(
      box(title="❓ Question", status="primary", solidHeader=TRUE, width=12,
          uiOutput(ns("question_text")),
          br(),
          uiOutput(ns("answer_choices")),
          br(),
          uiOutput(ns("feedback_panel"))
      )
    ),

    fluidRow(
      box(title="📊 Session Score History", status="info", solidHeader=TRUE, width=12,
          plotly::plotlyOutput(ns("score_chart"), height="200px"),
          br(),
          fluidRow(
            column(6, textAreaInput(ns("notes"), "Study notes:", value="", rows=2, placeholder="Notes from the quiz...")),
            column(3, sliderInput(ns("progress"), "Quiz readiness:", 0, 100, 0, step=5)),
            column(3, br(), actionButton(ns("save_progress"), "Save Progress", class="btn-primary"))
          )
      )
    )
  )
}

quiz_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {

    state <- reactiveValues(
      current_q   = NULL,
      answered    = FALSE,
      correct     = FALSE,
      score       = 0,
      total       = 0,
      history     = c()
    )

    pick_question <- function() {
      idx <- sample(seq_along(QUIZ_QUESTIONS), 1)
      state$current_q <- QUIZ_QUESTIONS[[idx]]
      state$answered  <- FALSE
      state$correct   <- FALSE
    }

    observeEvent(TRUE, { pick_question() }, once = TRUE)
    observeEvent(input$new_q, { pick_question() })

    observeEvent(input$reset_quiz, {
      state$score   <- 0
      state$total   <- 0
      state$history <- c()
      pick_question()
      showNotification("Quiz reset!", type="message", duration=2)
    })

    output$q_num       <- renderText({ paste0(state$total + 1) })
    output$score_display <- renderText({ paste0(state$score, "/", state$total) })
    output$pct_display <- renderText({
      if (state$total == 0) "—" else paste0(round(100 * state$score / state$total), "%")
    })
    output$chapter_display <- renderText({
      if (is.null(state$current_q)) "—" else state$current_q$chapter
    })

    output$question_text <- renderUI({
      req(state$current_q)
      div(
        div(class="section-heading-dark", state$current_q$chapter),
        tags$h4(state$current_q$q, style="color:#1e293b;font-size:15px;font-weight:600;")
      )
    })

    output$answer_choices <- renderUI({
      req(state$current_q)
      q <- state$current_q
      btn_list <- lapply(seq_along(q$choices), function(i) {
        btn_id <- paste0("ans_", i)
        disabled <- if (state$answered) "disabled" else ""
        extra_class <- ""
        if (state$answered) {
          if (i == q$answer) extra_class <- "correct"
          else if (isTRUE(input[[paste0("ans_last")]] == i) && i != q$answer) extra_class <- "incorrect"
        }
        div(class=paste("answer-card", extra_class),
            onclick=if (!state$answered) sprintf("Shiny.setInputValue('%s', %d, {priority:'event'})", session$ns("answer_click"), i) else "",
            tags$b(LETTERS[i], ".", style="color:#7C3AED;margin-right:8px;"),
            q$choices[[i]]
        )
      })
      do.call(tagList, btn_list)
    })

    observeEvent(input$answer_click, {
      req(!state$answered, state$current_q)
      chosen <- input$answer_click
      correct <- chosen == state$current_q$answer
      state$answered <- TRUE
      state$correct  <- correct
      state$total    <- state$total + 1
      if (correct) state$score <- state$score + 1
      state$history  <- c(state$history, if (correct) 1 else 0)
      study_mgr$add_quiz_score("quiz", state$score, state$total, state$current_q$chapter)
    })

    output$feedback_panel <- renderUI({
      req(state$answered)
      q <- state$current_q
      if (state$correct) {
        div(class="success-box",
            HTML(paste0("<strong>✅ Correct!</strong> ", q$explanation)))
      } else {
        div(class="warn-box",
            HTML(paste0("<strong>❌ Not quite.</strong> The answer is <strong>", LETTERS[q$answer], ". ", q$choices[[q$answer]], "</strong>.<br><br>", q$explanation)))
      }
    })

    output$score_chart <- plotly::renderPlotly({
      h <- state$history
      if (length(h) == 0) {
        plotly::plot_ly() %>%
          plotly::add_annotations(text="Answer questions to see your progress here",
                                  showarrow=FALSE, font=list(color="#94a3b8",size=13)) %>%
          plotly::layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)",
                         xaxis=list(visible=FALSE), yaxis=list(visible=FALSE))
      } else {
        cum_pct <- cumsum(h) / seq_along(h) * 100
        plotly::plot_ly(x=seq_along(cum_pct), y=cum_pct, type="scatter", mode="lines+markers",
                        line=list(color="#7C3AED",width=2.5),
                        marker=list(color=ifelse(h==1,"#22c55e","#ef4444"),size=8)) %>%
          plotly::add_hline(y=80, line=list(color="#22c55e",dash="dot",width=1)) %>%
          plotly::layout(
            paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(245,243,255,0.5)",
            xaxis=list(title="Question #",tickfont=list(size=10),gridcolor="rgba(196,181,253,0.3)"),
            yaxis=list(title="Cumulative %",range=c(0,105),tickfont=list(size=10),gridcolor="rgba(196,181,253,0.3)"),
            margin=list(t=10,b=40,l=40,r=10)
          )
      }
    })

    observeEvent(input$save_progress, {
      study_mgr$save_note("quiz", input$notes)
      study_mgr$update_progress("quiz", input$progress)
      showNotification("Quiz progress saved!", type="message", duration=3)
    })
  })
}
