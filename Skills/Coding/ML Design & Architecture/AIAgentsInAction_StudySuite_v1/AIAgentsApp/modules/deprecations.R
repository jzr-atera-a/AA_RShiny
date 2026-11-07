# modules/deprecations.R — API Sunset Tracker

deprecations_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("API Sunset Tracker"),
        tags$h2("Live view of deprecated models, frameworks, and APIs referenced in the book"),
        div(span(class="hero-badge","OpenAI Models"), span(class="hero-badge","Prompt Flow"),
            span(class="hero-badge","Assistants API"), span(class="hero-badge","LangChain"))
    ),

    fluidRow(
      box(title="🚨 Priority Alerts — Action Required Now (2026)", status="danger", solidHeader=TRUE, width=12,
          fluidRow(
            column(4,
                   div(style="text-align:center;padding:20px;background:linear-gradient(135deg,#991b1b,#ef4444);border-radius:12px;color:white;",
                       tags$h2(style="font-size:3em;margin:0;font-family:'JetBrains Mono',monospace;",
                               textOutput(ns("days_assistants"))),
                       tags$p("days until Assistants API shutdown", style="margin:8px 0 0;opacity:0.85;font-size:13px;"),
                       tags$b("August 26, 2026", style="font-size:12px;opacity:0.70;")
                   )
            ),
            column(4,
                   div(style="text-align:center;padding:20px;background:linear-gradient(135deg,#92400e,#f59e0b);border-radius:12px;color:white;",
                       tags$h2(style="font-size:3em;margin:0;font-family:'JetBrains Mono',monospace;",
                               textOutput(ns("days_gpt4turbo"))),
                       tags$p("days until gpt-4-turbo shutdown", style="margin:8px 0 0;opacity:0.85;font-size:13px;"),
                       tags$b("October 23, 2026", style="font-size:12px;opacity:0.70;")
                   )
            ),
            column(4,
                   div(style="text-align:center;padding:20px;background:linear-gradient(135deg,#4C1D95,#7C3AED);border-radius:12px;color:white;",
                       tags$h2(style="font-size:3em;margin:0;font-family:'JetBrains Mono',monospace;",
                               textOutput(ns("days_promptflow"))),
                       tags$p("days until Prompt Flow retirement", style="margin:8px 0 0;opacity:0.85;font-size:13px;"),
                       tags$b("April 20, 2027", style="font-size:12px;opacity:0.70;")
                   )
            )
          )
      )
    ),

    fluidRow(
      box(title="📋 Complete API Sunset Reference", status="primary", solidHeader=TRUE, width=12,
          tags$table(class="table table-hover",
            tags$thead(tags$tr(
              tags$th("Item"), tags$th("Book chapter(s)"), tags$th("Status"),
              tags$th("Shutdown date"), tags$th("Replacement"), tags$th("Fix in this zip")
            )),
            tags$tbody(
              tags$tr(
                tags$td(tags$b("gpt-4-1106-preview")), tags$td("Ch.2,5,7,8,9,10,11"),
                tags$td(status_badge("DEAD","danger")), tags$td(tags$code("Mar 26, 2026")),
                tags$td(tags$code("gpt-4o-mini")), tags$td(status_badge("Fixed","ok"))
              ),
              tags$tr(
                tags$td(tags$b("gpt-3.5-turbo-1106")), tags$td("Ch.2,5"),
                tags$td(status_badge("DEAD","danger")), tags$td(tags$code("Mar 26, 2026")),
                tags$td(tags$code("gpt-4o-mini")), tags$td(status_badge("Fixed","ok"))
              ),
              tags$tr(
                tags$td(tags$b("Assistants API (beta.assistants)")), tags$td("Ch.11"),
                tags$td(status_badge("RETIRING","warn")), tags$td(tags$code("Aug 26, 2026")),
                tags$td("Responses API + Conversations API"), tags$td(status_badge("Flagged","warn"))
              ),
              tags$tr(
                tags$td(tags$b("gpt-4-turbo")), tags$td("Ch.4,11"),
                tags$td(status_badge("RETIRING","warn")), tags$td(tags$code("Oct 23, 2026")),
                tags$td(tags$code("gpt-4.1")), tags$td(status_badge("Fixed in Ch.11","ok"))
              ),
              tags$tr(
                tags$td(tags$b("Microsoft Prompt Flow")), tags$td("Ch.9,10"),
                tags$td(status_badge("RETIRING","warn")), tags$td(tags$code("Apr 20, 2027")),
                tags$td("Microsoft Agent Framework"), tags$td(status_badge("Flagged","warn"))
              ),
              tags$tr(
                tags$td(tags$b("Gradio tuple chat format")), tags$td("Ch.11"),
                tags$td(status_badge("REMOVED","danger")), tags$td(tags$code("Gradio 4.x")),
                tags$td("messages format {role, content}"), tags$td(status_badge("Fixed","ok"))
              ),
              tags$tr(
                tags$td(tags$b("gr.Chatbot bubble_full_width")), tags$td("Ch.11"),
                tags$td(status_badge("REMOVED","danger")), tags$td(tags$code("Gradio 5.x")),
                tags$td("kwarg removed; use layout="), tags$td(status_badge("Fixed","ok"))
              ),
              tags$tr(
                tags$td(tags$b("SK skill API (import_skill, etc)")), tags$td("Ch.5,8"),
                tags$td(status_badge("REMOVED","danger")), tags$td(tags$code("SK 1.0")),
                tags$td("add_plugin() everywhere"), tags$td(status_badge("Fixed","ok"))
              ),
              tags$tr(
                tags$td(tags$b("SK openai_settings_from_dot_env()")), tags$td("Ch.5,8"),
                tags$td(status_badge("REMOVED","danger")), tags$td(tags$code("SK 1.0")),
                tags$td("os.getenv() + load_dotenv()"), tags$td(status_badge("Fixed","ok"))
              ),
              tags$tr(
                tags$td(tags$b("LangChain monolithic imports")), tags$td("Ch.8"),
                tags$td(status_badge("REMOVED","danger")), tags$td(tags$code("LC 1.0")),
                tags$td("langchain_community / langchain_openai / etc"), tags$td(status_badge("Fixed","ok"))
              ),
              tags$tr(
                tags$td(tags$b("CrewAI verbose=2 (int)")), tags$td("Ch.4"),
                tags$td(status_badge("REMOVED","danger")), tags$td(tags$code("CrewAI 0.4+")),
                tags$td("verbose=True / False only"), tags$td(status_badge("Fixed","ok"))
              ),
              tags$tr(
                tags$td(tags$b("promptflow import tool (top-level)")), tags$td("Ch.9,10"),
                tags$td(status_badge("DEPRECATED","warn")), tags$td(tags$code("PF 1.18+")),
                tags$td("from promptflow.core import tool"), tags$td(status_badge("Fixed","ok"))
              ),
              tags$tr(
                tags$td(tags$b("AutoGen Studio Skills tab")), tags$td("Ch.4"),
                tags$td(status_badge("RENAMED","warn")), tags$td(tags$code("AS 0.4.x")),
                tags$td("Now called 'Tools' under Team Builder"), tags$td(status_badge("Flagged","warn"))
              ),
              tags$tr(
                tags$td(tags$b("gpt-4o (no sunset announced)")), tags$td("Various"),
                tags$td(status_badge("Active","ok")), tags$td(tags$code("—")),
                tags$td("—"), tags$td(status_badge("Safe","ok"))
              ),
              tags$tr(
                tags$td(tags$b("gpt-4o-mini (no sunset announced)")), tags$td("Various"),
                tags$td(status_badge("Active","ok")), tags$td(tags$code("—")),
                tags$td("—"), tags$td(status_badge("Safe","ok"))
              ),
              tags$tr(
                tags$td(tags$b("gpt-4.1 (no sunset announced)")), tags$td("Ch.11 (fixed)"),
                tags$td(status_badge("Active","ok")), tags$td(tags$code("—")),
                tags$td("—"), tags$td(status_badge("Safe","ok"))
              )
            )
          )
      )
    ),

    fluidRow(
      box(title="📌 Study Notes", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(6, textAreaInput(ns("notes"), "Notes:", value="", rows=3, placeholder="Notes on API deprecations, migration plans...")),
            column(3, sliderInput(ns("progress"), "Tracker readiness:", 0, 100, 0, step=5)),
            column(3, br(), actionButton(ns("save_progress"), "Save", class="btn-primary"))
          )
      )
    )
  )
}

deprecations_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {

    compute_days <- function(target_date) {
      days <- as.integer(as.Date(target_date) - Sys.Date())
      if (days < 0) paste0(abs(days), "d ago") else paste0(days, "d")
    }

    output$days_assistants <- renderText({ compute_days("2026-08-26") })
    output$days_gpt4turbo  <- renderText({ compute_days("2026-10-23") })
    output$days_promptflow <- renderText({ compute_days("2027-04-20") })

    observeEvent(input$save_progress, {
      study_mgr$save_note("deprecations", input$notes)
      study_mgr$update_progress("deprecations", input$progress)
      showNotification("Tracker progress saved!", type="message", duration=3)
    })
  })
}
