# modules/practice.R
# Capstone: A1 Mock Interview — 45-min timed simulation across the whole book

practice_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("A1 Mock Interview"),
        tags$h2("45-Minute VP of Research (ML) Simulation — spans Ch.1–10"),
        div(
          span(class = "hero-badge", "45 Min Timer"),
          span(class = "hero-badge", "Auto-Score"),
          span(class = "hero-badge", "A1-Specific Prompts")
        )
    ),

    fluidRow(
      box(title = "⚙️ Session Setup & Timer", status = "primary", solidHeader = TRUE, width = 4,
          selectInput(ns("design_topic"), "Choose Interview Question:",
                      choices = c(
                        "Design the evaluation framework for A1's assistant (Ch.3/4)",
                        "Build vs. buy: choose the model stack for A1 (Ch.2/4)",
                        "Design the memory & orchestration system (Ch.6)",
                        "Design the guardrail & safety architecture (Ch.5/10)",
                        "Diagnose and fix a failing 6-step agentic workflow (Ch.6/9)",
                        "Sketch the full production architecture end-to-end (Ch.10)",
                        "Tell me about an irreversible decision you made with incomplete information"
                      )),
          div(class = "timer-card", uiOutput(ns("timer_display"))),
          br(),
          fluidRow(
            column(6, actionButton(ns("start_design"), "▶ Start (45 min)", class = "btn-meta", width = "100%", icon = icon("play"))),
            column(6, actionButton(ns("reset_timer"), "↺ Reset", class = "btn-meta", width = "100%"))
          ),
          br(),
          sliderInput(ns("design_confidence"), "Self-assessed confidence (1–10):", 1, 10, 5),
          actionButton(ns("save_design"), "📊 Score My Answer", class = "btn-meta", width = "100%", icon = icon("chart-bar")),
          br(), br(),
          uiOutput(ns("design_feedback"))
      ),

      box(title = "✍️ Answer Notes", status = "success", solidHeader = TRUE, width = 8,
          div(class = "tip-box", HTML("<strong>💡 Structure reminder:</strong> Clarify constraints → propose approach → name trade-offs → state how you'd evaluate/monitor success → note what would change your mind.")),
          textAreaInput(ns("design_notes"), label = NULL, rows = 14, width = "100%",
                        placeholder = "## Clarifying questions / constraints\n\n## Proposed approach\n\n## Trade-offs considered\n\n## Evaluation / monitoring plan\n\n## What would change your mind / next steps"),
      )
    ),

    fluidRow(
      box(title = "📈 Your Progress Across All Chapters", status = "info", solidHeader = TRUE, width = 12,
          uiOutput(ns("progress_table"))
      )
    )
  )
}

practice_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    time_left  <- reactiveVal(45 * 60)
    timer_on   <- reactiveVal(FALSE)

    observe({
      invalidateLater(1000, session)
      isolate({
        if (timer_on() && time_left() > 0) {
          time_left(time_left() - 1)
          if (time_left() <= 0) {
            timer_on(FALSE)
            showNotification("⏰ Time's up!", type = "warning")
          }
        }
      })
    })

    observeEvent(input$start_design, {
      timer_on(TRUE)
    })

    observeEvent(input$reset_timer, {
      timer_on(FALSE)
      time_left(45 * 60)
    })

    output$timer_display <- renderUI({
      t <- time_left()
      mins <- t %/% 60
      secs <- t %% 60
      div(style = "text-align:center;font-family:'JetBrains Mono',monospace;font-size:2em;font-weight:800;color:#008A82;",
          sprintf("%02d:%02d", mins, secs))
    })

    observeEvent(input$save_design, {
      notes <- input$design_notes
      conf  <- input$design_confidence
      score <- 0
      if (grepl("clarify|constraint|assum", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("approach|propose|design|architect", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("trade.?off|however|but|risk|cost", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("evaluat|monitor|metric|measure", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("change my mind|revisit|next step|iterat", notes, ignore.case = TRUE)) score <- score + 20

      prep_manager$update_progress("practice", min(score + conf * 2, 100))
      prep_manager$save_note("practice_notes", notes)
      prep_manager$add_practice_score("practice", score, input$design_topic)

      output$design_feedback <- renderUI({
        div(class = if (score >= 80) "success-box" else "tip-box",
            tags$h5(paste0("Answer Score: ", score, "/100")),
            if (score < 20) tags$p("⚠️ Missing: clarifying questions / constraints"),
            if (score < 40) tags$p("⚠️ Missing: a concrete proposed approach"),
            if (score < 60) tags$p("⚠️ Missing: explicit trade-offs"),
            if (score < 80) tags$p("⚠️ Missing: evaluation/monitoring plan"),
            if (score >= 80) tags$p("✅ Full VP-level structure covered — strong answer shape for A1.")
        )
      })
      showNotification("Answer scored and saved!", type = "message")
    })

    output$progress_table <- renderUI({
      prep_manager$progress_trigger()
      tabs <- c("overview","job_mapping","ch01_intro","ch02_foundation_models","ch03_evaluation_methodology",
                "ch04_evaluate_systems","ch05_prompt_engineering","ch06_rag_agents","ch07_finetuning",
                "ch08_dataset_engineering","ch09_inference_optimization","ch10_architecture_feedback","practice")
      labels <- c("Overview","A1 Job Mapping","Ch.1 Intro","Ch.2 Foundation Models","Ch.3 Eval Methodology",
                  "Ch.4 Evaluate Systems","Ch.5 Prompt Engineering","Ch.6 RAG & Agents","Ch.7 Finetuning",
                  "Ch.8 Dataset Engineering","Ch.9 Inference Opt.","Ch.10 Architecture & Feedback","Mock Interview")

      rows <- lapply(seq_along(tabs), function(i) {
        pct <- prep_manager$get_progress(tabs[i])
        tags$tr(
          tags$td(labels[i]),
          tags$td(style = "width:60%;",
                   div(style = "background:#e0f4f2;border-radius:8px;height:14px;overflow:hidden;",
                       div(style = paste0("background:", progress_colour(pct), ";width:", pct, "%;height:100%;"))
                   )),
          tags$td(paste0(pct, "%"))
        )
      })

      tags$table(class = "table table-hover", tags$tbody(rows))
    })
  })
}
