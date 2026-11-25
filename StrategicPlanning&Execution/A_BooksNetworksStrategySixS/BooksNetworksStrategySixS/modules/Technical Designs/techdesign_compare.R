# modules/Technical Designs/techdesign_compare.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_compare
# name:         Compare Designs
# icon:         columns
# description:  Two designs side by side with a computed and the Editing Tool-written comparison
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_optional: claude, bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_compare_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Compare Designs", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "alert alert-info",
              "Pick any two designs (starter library or saved). The app draws them side by side and computes a comparison table. ",
              "Optionally ask the Editing Tool for a deeper written comparison."),
          fluidRow(
            column(5, selectInput(ns("a"), "Design A:", choices = c("Loading..." = ""))),
            column(5, selectInput(ns("b"), "Design B:", choices = c("Loading..." = ""))),
            column(2, br(), actionButton(ns("reload"), "Reload lists", icon = icon("sync"), class = "btn-default"))
          ),
          fluidRow(
            column(4, actionButton(ns("compare"), "Compare", icon = icon("columns"), class = "btn-primary btn-lg", style = "width:100%;")),
            column(5, textInput(ns("focus"), NULL, placeholder = "Optional focus for the Editing Tool, e.g., cost and operations")),
            column(3, actionButton(ns("ask"), "Ask the Editing Tool", icon = icon("robot"), class = "btn-info btn-lg", style = "width:100%;"))
          ),
          htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      box(title = "Side by Side", status = "info", solidHeader = TRUE, width = 12,
          export_controls_ui(ns, ns("export_target"), "technical_design_comparison"),
          uiOutput(ns("view")))
    )
  )
}

# ==== Server =======================================================================================

techdesign_compare_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    pair <- reactiveVal(NULL)       # list(a, b)
    claude_cmp <- reactiveVal(NULL) # list(table, verdict)

    refresh_choices <- function() {
      ch <- td_design_choices(api_manager)
      if (length(ch) == 0) ch <- c("(no designs available)" = "")
      a <- isolate(input$a); b <- isolate(input$b)
      updateSelectInput(session, "a", choices = ch, selected = if (!is.null(a) && a %in% ch) a else ch[1])
      updateSelectInput(session, "b", choices = ch, selected = if (!is.null(b) && b %in% ch) b else ch[min(2, length(ch))])
    }
    observe({ api_manager$state_trigger_techdesign(); input$reload; refresh_choices() })

    set_status <- function(cls, msg) output$status <- renderUI(tags$div(class = cls, msg))

    observeEvent(input$compare, {
      a <- td_load_design(api_manager, input$a); b <- td_load_design(api_manager, input$b)
      if (is.null(a) || is.null(b)) { showNotification("Select two designs that can be loaded.", type = "warning"); return() }
      claude_cmp(NULL); pair(list(a = a, b = b))
      set_status("status-success", sprintf("Comparing '%s' with '%s'.", a$meta$title, b$meta$title))
    })

    observeEvent(input$ask, {
      p <- pair()
      if (is.null(p)) { showNotification("Click 'Compare' first.", type = "warning"); return() }
      if (!api_manager$claude_authenticated) { showNotification("Please configure and save Editing Tool API credentials first!", type = "error"); return() }
      set_status("status-info", tags$span(tags$i(class = "fa fa-spinner fa-spin"), " Asking the Editing Tool..."))
      tryCatch({
        resp <- api_manager$call_claude(prompt = generate_td_compare_prompt(p$a, p$b, input$focus %||% ""), max_tokens = 3000, progress_callback = function(m) NULL)
        r <- parse_td_compare(resp)
        if (nrow(r$table) == 0) stop("The Editing Tool's answer contained no comparison rows.")
        claude_cmp(r)
        set_status("status-success", sprintf("The Editing Tool added %d comparison rows.", nrow(r$table)))
      }, error = function(e) set_status("status-error", paste("Failed:", app_err_text(e))))
    })

    html_table <- function(df, hdr) {
      tags$table(class = "table table-striped table-bordered", style = "font-size:12.5px;",
                 tags$thead(tags$tr(lapply(hdr, tags$th))),
                 tags$tbody(lapply(seq_len(nrow(df)), function(i) tags$tr(lapply(seq_len(ncol(df)), function(j) {
                   if (j == 1) tags$td(tags$strong(df[i, j])) else tags$td(df[i, j]) })))))
    }

    output$view <- renderUI({
      p <- pair()
      if (is.null(p)) return(tags$div(class = "status-info", "Pick two designs and click 'Compare'."))
      cm <- claude_cmp()
      export_capture_wrapper(session$ns, tagList(
        div(class = "td-two-col", style = "display:flex;gap:14px;flex-wrap:wrap;",
            div(style = "flex:1 1 480px;min-width:0;", h4(paste("A:", p$a$meta$title)), render_techdesign(p$a)),
            div(style = "flex:1 1 480px;min-width:0;", h4(paste("B:", p$b$meta$title)), render_techdesign(p$b))),
        h4("Computed comparison"),
        html_table(td_compare_table(p$a, p$b), c("Dimension", "A", "B")),
        if (!is.null(cm)) tagList(
          h4("The Editing Tool's comparison"),
          html_table(cm$table, c("Dimension", "A", "B")),
          if (nzchar(cm$verdict)) div(class = "alert alert-success", tags$strong("Verdict: "), cm$verdict))
      ), paste(p$a$meta$title, "vs", p$b$meta$title),
      meta = list(category = "Comparisons", domain = TD_GROUP_LABELS[[p$a$meta$design_group]] %||% p$a$meta$design_group, topic = p$a$meta$design_type))
    })

    output$status <- renderUI(tags$div())
  })
}
