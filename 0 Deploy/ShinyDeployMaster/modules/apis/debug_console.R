# modules/apis/debug_console.R
# Debug Console — mirrors every log entry written to deploy_mgr$debug_lines.
# Updated automatically via deploy_mgr$debug_trigger(); no polling needed.

debug_console_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "meta-hero",
        tags$h1("\U0001f41b Debug Console"),
        tags$h2("All deployment events, errors, and system messages — updated in real time"),
        div(
          span(class = "hero-badge", "Real-time"),
          span(class = "hero-badge", "All events"),
          span(class = "hero-badge", "Auth \u00b7 Upload \u00b7 Deploy")
        )
    ),

    fluidRow(
      column(12,
        fluidRow(
          column(2, div(class = "metric-card",
                        span(class = "metric-value", textOutput(ns("total_entries"))),
                        span(class = "metric-label", "Log Entries"))),
          column(2, div(class = "metric-card",
                        span(class = "metric-value", textOutput(ns("error_count"))),
                        span(class = "metric-label", "Errors"))),
          column(2, div(class = "metric-card",
                        span(class = "metric-value", textOutput(ns("warn_count"))),
                        span(class = "metric-label", "Warnings"))),
          column(2, div(class = "metric-card",
                        span(class = "metric-value", textOutput(ns("success_count"))),
                        span(class = "metric-label", "Success"))),
          column(2, br(),
                 actionButton(ns("btn_refresh"), tagList(icon("sync"), " Refresh"),
                              class = "btn-info btn-block")),
          column(2, br(),
                 actionButton(ns("btn_clear"), tagList(icon("trash"), " Clear Log"),
                              class = "btn-warning btn-block"))
        )
      )
    ),

    br(),

    fluidRow(
      box(title = "\U0001f4dc Live Debug Log",
          status  = "primary", solidHeader = TRUE, width = 12,

          # Filter bar
          fluidRow(
            column(4,
                   selectInput(ns("filter_type"), "Filter by type:",
                               choices = c("All" = "all", "Errors only" = "error",
                                           "Warnings" = "warn", "Success" = "success",
                                           "Info" = "info"),
                               selected = "all")),
            column(4,
                   selectInput(ns("filter_tag"), "Filter by module:",
                               choices = c("All" = "all", "AUTH", "UPLOAD",
                                           "DEPLOY", "CLEAN", "INFO"),
                               selected = "all")),
            column(4,
                   textInput(ns("filter_text"), "Search text:", placeholder = "Filter by keyword..."))
          ),
          hr(),

          # Console output
          tags$div(
            id = ns("debug_scroll_container"),
            style = paste0(
              "background:#060D18;border-radius:10px;padding:16px 18px;",
              "min-height:420px;max-height:600px;overflow-y:auto;",
              "font-family:'JetBrains Mono',monospace;font-size:12px;"
            ),
            uiOutput(ns("debug_output"))
          ),

          br(),
          div(style = "font-size:11px;color:#94A3B8;",
              textOutput(ns("last_updated")))
      )
    ),

    # Auto-scroll JS
    tags$script(HTML(sprintf("
      Shiny.addCustomMessageHandler('scroll_debug_%s', function(id) {
        var el = document.getElementById(id);
        if (el) el.scrollTop = el.scrollHeight;
      });
    ", id)))
  )
}

debug_console_server <- function(id, deploy_mgr) {
  moduleServer(id, function(input, output, session) {

    ns <- session$ns

    # ── Reactive: filtered debug lines ───────────────────────
    # Shared log (R console + this tab). Re-read every 1.5 s so BigQuery
    # and registry events appear without pressing Refresh.
    debug_lines_now <- reactive({
      invalidateLater(1500, session)
      sdm_log_entries()
    })

    filtered_lines <- reactive({
      deploy_mgr$debug_trigger()
      lines <- debug_lines_now()
      if (length(lines) == 0) return(character(0))

      if (!is.null(input$filter_text) && nchar(trimws(input$filter_text)) > 0)
        lines <- lines[grepl(input$filter_text, lines, ignore.case = TRUE)]

      if (!is.null(input$filter_type) && input$filter_type != "all")
        lines <- lines[grepl(paste0("\\[", input$filter_type, "\\]"),
                              lines, ignore.case = TRUE)]

      if (!is.null(input$filter_tag) && input$filter_tag != "all")
        lines <- lines[grepl(paste0("\\[", input$filter_tag, "\\]"), lines)]

      lines
    })

    # ── Metrics ───────────────────────────────────────────────
    all_lines <- reactive({
      debug_lines_now()
    })

    output$total_entries <- renderText({
      length(all_lines())
    })

    output$error_count <- renderText({
      sum(grepl("\\[error\\]", all_lines(), ignore.case = TRUE))
    })

    output$warn_count <- renderText({
      sum(grepl("\\[warn\\]", all_lines(), ignore.case = TRUE))
    })

    output$success_count <- renderText({
      sum(grepl("\\[success\\]", all_lines(), ignore.case = TRUE))
    })

    output$last_updated <- renderText({
      deploy_mgr$debug_trigger()
      if (length(all_lines()) == 0) "No entries yet."
      else paste("Last updated:", format(Sys.time(), "%H:%M:%S"))
    })

    # ── Console render ────────────────────────────────────────
    output$debug_output <- renderUI({
      lines <- filtered_lines()

      if (length(lines) == 0) {
        return(div(style = "color:#4B5563;padding:10px;",
                   "No debug entries yet. Events from authentication, ",
                   "file upload, and deployment will appear here automatically."))
      }

      line_divs <- lapply(lines, function(l) {
        # Colour by content
        col <- if (grepl("\\[error\\]", l, ignore.case = TRUE)) "#F87171"
               else if (grepl("\\[warn\\]", l, ignore.case = TRUE)) "#FCD34D"
               else if (grepl("\\[success\\]", l, ignore.case = TRUE)) "#4ADE80"
               else if (grepl("\\[AUTH\\]", l)) "#A78BFA"
               else if (grepl("\\[UPLOAD\\]", l)) "#38BDF8"
               else if (grepl("\\[DEPLOY\\]", l)) "#FB923C"
               else "#94A3B8"

        tags$div(style = paste0("color:", col, ";line-height:1.7;white-space:pre-wrap;"), l)
      })

      # Scroll to bottom after render
      session$sendCustomMessage(
        paste0("scroll_debug_", id),
        ns("debug_scroll_container")
      )

      do.call(tagList, line_divs)
    })

    # ── Buttons ───────────────────────────────────────────────
    observeEvent(input$btn_clear, {
      showModal(modalDialog(
        title = "Clear debug log?",
        "This will remove all log entries from this session. The deployment state is not affected.",
        footer = tagList(
          actionButton(ns("confirm_clear"), "Clear", class = "btn-warning"),
          modalButton("Cancel")
        )
      ))
    })

    observeEvent(input$confirm_clear, {
      deploy_mgr$clear_debug()
      removeModal()
      showNotification("Debug log cleared", type = "message")
    })

    observeEvent(input$btn_refresh, {
      deploy_mgr$trigger_debug()
    })
  })
}
