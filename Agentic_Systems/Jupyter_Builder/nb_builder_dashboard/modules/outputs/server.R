# ============================================================================
# OUTPUTS MODULE - SERVER
# ============================================================================

outputs_server <- function(id, session_mgr, app_state, session) {
  moduleServer(id, function(input, output, session) {

    cells_data <- reactiveVal(list())

    # ── Load cells from session.json ───────────────────────────────────────
    load_cells <- function() {
      rd <- app_state$run_dir %||% ""
      if (nchar(rd) == 0) return(list())

      state <- session_mgr$load_run_state(rd)
      if (is.null(state)) return(list())

      approved <- state$approved_cells %||% list()

      # Also try to load per-cell output.txt from disk
      lapply(seq_along(approved), function(i) {
        cell <- approved[[i]]
        # Look for matching cell folder
        cell_dirs <- list.dirs(rd, recursive = FALSE, full.names = TRUE)
        pat       <- paste0("^cell_", sprintf("%02d", i), "_")
        matched   <- cell_dirs[grepl(pat, basename(cell_dirs))]
        output_txt <- ""
        if (length(matched) > 0) {
          out_path <- file.path(matched[1], "output.txt")
          if (file.exists(out_path)) {
            output_txt <- paste(readLines(out_path, warn = FALSE), collapse = "\n")
          }
        }
        list(
          num         = i,
          explanation = cell$explanation %||% paste("Cell", i),
          code        = cell$code %||% "",
          output      = output_txt
        )
      })
    }

    # ── Refresh ────────────────────────────────────────────────────────────
    observeEvent(input$refreshBtn, {
      cells_data(load_cells())
    })

    # Auto-refresh when run_dir changes
    observe({
      app_state$run_dir
      cells_data(load_cells())
    })

    # Poll every 5s during active run
    poll <- reactiveTimer(5000)
    observe({
      poll()
      if (isTRUE(app_state$running)) cells_data(load_cells())
    })

    # ── Summary badges ─────────────────────────────────────────────────────
    output$summaryBadges <- renderUI({
      cells <- cells_data()
      n     <- length(cells)
      rd    <- app_state$run_dir %||% ""
      tagList(
        tags$span(class = "badge badge-success", style = "font-size:14px; margin-right:8px;",
                  n, " cells approved"),
        if (nchar(rd) > 0)
          tags$small(class = "text-muted", basename(rd))
      )
    })

    # ── Cell cards ─────────────────────────────────────────────────────────
    output$cellsOutput <- renderUI({
      cells <- cells_data()
      if (length(cells) == 0) {
        return(div(class = "info-box", icon("info-circle"),
                   " No approved cells yet. Start a run in the Task tab."))
      }

      div(class = "scrollable-outputs",
        lapply(cells, function(cell) {
          out_section <- if (nchar(cell$output) > 0) {
            tagList(
              tags$p(tags$b("Output:")),
              tags$div(class = "cell-output", cell$output)
            )
          } else {
            tags$p(class = "text-muted", tags$em("(no output)"))
          }

          div(class = "cell-card",
            tags$div(class = "cell-num",   paste("Cell", cell$num)),
            tags$div(class = "cell-title", cell$explanation),
            tags$details(
              tags$summary(style = "cursor:pointer; color:#4f46e5; font-size:13px;",
                           "Show code"),
              tags$pre(cell$code)
            ),
            out_section
          )
        })
      )
    })

    # ── Download notebook ──────────────────────────────────────────────────
    output$downloadNb <- downloadHandler(
      filename = function() {
        rd  <- app_state$run_dir %||% ""
        nm  <- if (nchar(rd) > 0) basename(rd) else "notebook"
        paste0(nm, ".ipynb")
      },
      content = function(file) {
        rd <- app_state$run_dir %||% ""
        nb_path <- file.path(rd, "notebook.ipynb")
        if (file.exists(nb_path)) {
          file.copy(nb_path, file)
        } else {
          writeLines('{"nbformat":4,"nbformat_minor":5,"metadata":{},"cells":[]}', file)
        }
      }
    )
  })
}
