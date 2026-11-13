# R/utils_techdesign_social_module.R
# Tabs for the Social Dynamics Algorithms: one tab per audience + a guide/index tab.

social_rank <- function(id) which(vapply(SOC_SPECS, function(s) s$id == id, TRUE))

social_tab_ui <- function(id, aud) {
  ns <- NS(id)
  specs <- social_specs_for(aud)
  ch <- setNames(vapply(specs, function(s) s$id, ""), vapply(specs, function(s) sprintf("#%d  %s  (%s)", social_rank(s$id), s$label, s$src), ""))
  tagList(
    fluidRow(box(
      title = paste("Social Dynamics:", SOC_AUDIENCES[[aud]]), status = "danger", solidHeader = TRUE, width = 12,
      div(class = "alert alert-info", style = "color:#0c4a5a;", sprintf("%d of the top 36 algorithms apply to this audience. Pick one: the procedure is drawn at once (no API needed) as a network of boxes with a step-by-step player. Honest intent, mutual benefit and consent apply to all of them; each design has an ethical guardrail box.", length(specs))),
      selectInput(ns("algo"), "Algorithm:", choices = ch, width = "100%"),
      uiOutput(ns("blurb")),
      hr(),
      textAreaInput(ns("context"), "Optional: your specific situation (the Editing Tool tailors the boxes to it):", rows = 3, width = "100%",
                    placeholder = "e.g., Seed round pitch to a climate fund that has backed two battery start-ups; my BATNA is a smaller angel round."),
      fluidRow(
        column(4, actionButton(ns("tailor"), "Tailor with the Editing Tool", icon = icon("magic"), class = "btn-primary", style = "width:100%;")),
        column(4, actionButton(ns("reset"), "Back to the built-in design", icon = icon("undo"), class = "btn-default", style = "width:100%;")),
        column(4, actionButton(ns("save"), "Save to BigQuery", icon = icon("cloud-upload-alt"), class = "btn-success", style = "width:100%;"))
      ),
      br(), htmlOutput(ns("status"))
    )),
    fluidRow(box(title = "Diagram", status = "info", solidHeader = TRUE, width = 12,
                 export_controls_ui(ns, ns("export_target"), paste0("social_", aud)),
                 uiOutput(ns("diagram"))))
  )
}

social_tab_server <- function(id, api_manager, aud) {
  moduleServer(id, function(input, output, session) {
    tailored <- reactiveVal(NULL)   # parsed design returned by the Editing Tool, or NULL
    saved_once <- reactiveVal(character(0))
    set_status <- function(cls, ico, msg) output$status <- renderUI(tags$div(class = cls, tags$i(class = ico), " ", msg))

    spec <- reactive({ req(input$algo); social_spec(input$algo) })
    base_text <- reactive(social_build_text(spec(), aud))
    design <- reactive({ t <- tailored(); if (!is.null(t) && identical(t$meta$design_type, spec()$id)) t else parse_techdesign_text(base_text()) })

    observeEvent(input$algo, tailored(NULL), ignoreInit = TRUE)
    output$blurb <- renderUI({
      s <- spec()
      div(style = "background:#fdf2f8;border-left:4px solid #C2185B;padding:8px 12px;border-radius:4px;",
          p(tags$b(sprintf("#%d %s", social_rank(s$id), s$label)), " - ", tags$i(s$src)),
          p(s$summary),
          p(tags$b("For ", tolower(SOC_AUDIENCES[[aud]]), ": "), unname(s$app[aud])))
    })
    output$diagram <- renderUI({
      d <- design()
      export_capture_wrapper(session$ns, render_techdesign(d), d$meta$title)
    })

    observeEvent(input$reset, { tailored(NULL); set_status("status-info", "fa fa-info-circle", "Showing the built-in design.") })

    observeEvent(input$tailor, {
      if (!isTRUE(api_manager$claude_authenticated)) { showNotification("Please configure Editing Tool API credentials first!", type = "error"); return() }
      s <- spec(); ctx <- trimws(input$context %||% "")
      if (nchar(ctx) < 10) { showNotification("Describe your situation first (at least a sentence).", type = "warning"); return() }
      set_status("status-info", "fa fa-spinner fa-spin", "Tailoring the design to your situation ...")
      tryCatch({
        prompt <- generate_techdesign_prompt("social_dynamics", s$id, paste0(s$label, " for ", tolower(SOC_AUDIENCES[[aud]])),
                    guidance = paste0("\nBASE DESIGN to adapt (keep its logic, the lanes Input, Signals and State, Procedure, Check and Act, Outcome, and the ethical guardrail box; rename and add boxes to fit the situation):\n", base_text(), "\n"),
                    context = ctx, detail = 2)
        resp <- api_manager$call_claude(prompt = prompt, max_tokens = 8000)
        d <- parse_techdesign_text(td_force_header(resp, "social_dynamics", s$id))
        d$meta$variant <- SOC_AUDIENCES[[aud]]
        tailored(d)
        set_status("status-success", "fa fa-check-circle", sprintf("Tailored: %d boxes, %d connections. Save it to keep this version.", nrow(d$components), nrow(d$connections)))
      }, error = function(e) { set_status("status-error", "fa fa-times-circle", paste("Failed:", app_err_text(e))); showNotification(paste("Error:", app_err_text(e)), type = "error", duration = 12) })
    })

    observeEvent(input$save, {
      if (!isTRUE(api_manager$bq_authenticated)) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      tryCatch({
        d <- design(); s <- spec()
        did <- paste0("social-", s$id, "-", tolower(aud))
        first <- !(did %in% saved_once())
        row <- techdesign_to_row(d, did, s$label, change_type = if (first) "create" else "update")
        api_manager$bq_insert_techdesign(row)
        saved_once(c(saved_once(), did))
        set_status("status-success", "fa fa-check-circle", sprintf("Saved '%s' (design_id: %s). Find it in Technical Designs > Library.", d$meta$title, did))
        showNotification("Design saved", type = "message")
      }, error = function(e) { set_status("status-error", "fa fa-times-circle", paste("Save failed:", app_err_text(e))); showNotification(paste("Error:", app_err_text(e)), type = "error", duration = 12) })
    })

    output$status <- renderUI(tags$div())
    session$onSessionEnded(function() {})
  })
}

social_guide_ui <- function(id) {
  ns <- NS(id)
  tagList(fluidRow(box(title = "Top 36 Social Dynamics Algorithms", status = "danger", solidHeader = TRUE, width = 12,
    p("Distilled from Games People Play, How to Win Friends and Influence People, Influence, Getting to Yes, Thinking in Bets, Algorithms to Live By, How Life Imitates Chess, Captivate, The Rational Male, The Game, the film Limitless and the series Elementary. Concept-level summaries in plain words; four start-up funding algorithms (narrative, traction ladder, fundraising sprint, investor fit) were added. Each expressed as an inputs - state - procedure - check - outcome algorithm."),
    div(class = "alert alert-warning", style = "color:#7a4b00;", tags$b("Ethics: "), "every algorithm assumes honest intent, mutual benefit and consent. Where a source is manipulative or contested (pickup tactics, the sexual-marketplace model), the design keeps the useful skill and states the limit."),
    fluidRow(column(4, selectInput(ns("aud"), "Audience:", choices = c("All" = "", setNames(names(SOC_AUDIENCES), unlist(SOC_AUDIENCES))))),
             column(4, br(), downloadButton(ns("dl"), "Download the full research (Markdown)", class = "btn-warning"))),
    DT::dataTableOutput(ns("tbl")),
    h4("Sources"), tags$ul(lapply(gsub(" \\| ", " - ", SOC_BOOK_REFS), tags$li)))))
}

social_guide_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    df <- reactive({
      d <- data.frame(Rank = seq_along(SOC_SPECS), Algorithm = vapply(SOC_SPECS, function(s) s$label, ""), Source = vapply(SOC_SPECS, function(s) s$src, ""),
                      Audiences = vapply(SOC_SPECS, function(s) paste(SOC_AUDIENCES[s$aud], collapse = ", "), ""), Summary = vapply(SOC_SPECS, function(s) s$summary, ""), stringsAsFactors = FALSE)
      a <- input$aud %||% ""; if (nzchar(a)) d <- d[vapply(SOC_SPECS, function(s) a %in% s$aud, TRUE), , drop = FALSE]
      d
    })
    output$tbl <- DT::renderDataTable(DT::datatable(df(), rownames = FALSE, options = list(pageLength = 40, scrollX = TRUE)))
    output$dl <- downloadHandler(filename = function() paste0("social_dynamics_top36_", format(Sys.Date(), "%Y%m%d"), ".md"),
                                 content = function(file) writeLines(social_report_md(), file, useBytes = TRUE))
    session$onSessionEnded(function() {})
  })
}
