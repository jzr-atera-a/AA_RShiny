# global.R
# Machine Learning for Algorithmic Trading — Stefan Jansen
# Shared helpers, Python execution, UI component builders

library(shiny)
library(shinydashboard)
library(shinyAce)

# ── Python execution via reticulate ──────────────────────────────────────────
python_available <- tryCatch({
  library(reticulate)
  py_available(initialize = FALSE)
}, error = function(e) FALSE)

run_python_safe <- function(code_str, module_files = list()) {
  if (!python_available) {
    return("⚠ Python / reticulate not available on this machine.\nPlease install Python 3 and run: install.packages('reticulate')")
  }
  tryCatch({
    tmp_dir <- normalizePath(tempdir(), winslash = "/")

    # Write all sibling module files for imports
    for (nm in names(module_files)) {
      writeLines(module_files[[nm]], file.path(tmp_dir, nm))
    }

    # Triple-quote safe: escape any ''' in user code
    safe_code <- gsub("'''", "\"\"\"", code_str, fixed = TRUE)

    wrapper <- paste0(
      "import sys, os\n",
      "sys.path.insert(0, r'", tmp_dir, "')\n",
      "os.chdir(r'", tmp_dir, "')\n",
      "from io import StringIO\n",
      "_cap = StringIO(); _ecap = StringIO()\n",
      "_oo = sys.stdout; _oe = sys.stderr\n",
      "sys.stdout = _cap; sys.stderr = _ecap\n",
      "try:\n",
      "    exec('''", safe_code, "''')\n",
      "except Exception as _e:\n",
      "    print(f'\\u274c {type(_e).__name__}: {_e}')\n",
      "finally:\n",
      "    sys.stdout = _oo; sys.stderr = _oe\n",
      "_output   = _cap.getvalue()\n",
      "_eoutput  = _ecap.getvalue()\n"
    )

    py_run_string(wrapper, convert = FALSE)
    out  <- py$`_output`
    eout <- py$`_eoutput`
    result <- if (nzchar(trimws(out))) out else ""
    if (nzchar(trimws(eout))) result <- paste0(result, "\n[stderr]\n", eout)
    if (!nzchar(trimws(result))) result <- "(no output)"
    result
  }, error = function(e) {
    paste("Reticulate error:", conditionMessage(e))
  })
}

# ── UI helper: hero banner ────────────────────────────────────────────────────
chapter_hero <- function(num, icon_emoji, title, subtitle, badges = character()) {
  badge_tags <- lapply(badges, function(b) span(class = "hero-badge", b))
  div(class = "chapter-hero",
      div(class = "hero-chapter-num", paste("Chapter", num)),
      tags$h1(class = "hero-title", paste(icon_emoji, title)),
      tags$p(class = "hero-subtitle", subtitle),
      div(class = "badge-row", tagList(badge_tags))
  )
}

# ── UI helper: stats row ──────────────────────────────────────────────────────
stats_row <- function(...) {
  stats <- list(...)
  cols  <- lapply(stats, function(s) {
    column(3,
           div(class = "stat-card",
               span(class = "stat-value",  s[[1]]),
               span(class = "stat-label",  s[[2]])
           )
    )
  })
  fluidRow(tagList(cols))
}

# ── UI helper: code lab header ────────────────────────────────────────────────
code_lab_header <- function(title, subtitle) {
  div(class = "codelab-header",
      div(class = "codelab-badge-row",
          span(class = "codelab-badge",      "Code Lab"),
          span(class = "codelab-lang-badge", "Python 3")
      ),
      tags$p(class = "codelab-title",    title),
      tags$p(class = "codelab-subtitle", subtitle)
  )
}

# ── UI helper: file selector pills ───────────────────────────────────────────
file_pills_ui <- function(ns, files) {
  choices <- setNames(seq_along(files), sapply(files, `[[`, "name"))
  div(class = "file-pill-row",
      radioButtons(ns("file_sel"), label = NULL,
                   choices = choices, selected = 1, inline = TRUE)
  )
}

# ── UI helper: Python code display block ─────────────────────────────────────
py_code_display <- function(ns) {
  tagList(
    div(class = "code-display-wrap",
        div(class = "code-disp-header",
            uiOutput(ns("code_filename")),
            actionButton(ns("copy_btn"), "⎘ Copy", class = "btn-copy")
        ),
        div(class = "code-scroll",
            verbatimTextOutput(ns("code_display"))
        )
    )
  )
}

# ── UI helper: terminal output ────────────────────────────────────────────────
terminal_ui <- function(ns) {
  tagList(
    div(class = "run-desc-row",
        uiOutput(ns("file_desc")),
        actionButton(ns("run_btn"), "▶  Run", class = "btn-run")
    ),
    div(class = "terminal-wrap",
        div(class = "terminal-header",
            div(class = "term-dots",
                span(class = "td-red"), span(class = "td-yellow"), span(class = "td-green")
            ),
            span(class = "term-label", textOutput(ns("term_label"), inline = TRUE))
        ),
        div(class = "terminal-body",
            verbatimTextOutput(ns("py_output"))
        )
    )
  )
}

# ── Server helper: code lab logic ─────────────────────────────────────────────
code_lab_server <- function(input, output, session, files_list) {
  ns <- session$ns

  sel_file <- reactive({
    idx <- as.integer(input$file_sel)
    if (is.na(idx) || idx < 1 || idx > length(files_list)) files_list[[1]]
    else files_list[[idx]]
  })

  output$code_filename <- renderUI({
    span(class = "code-fname", sel_file()$name)
  })

  output$file_desc <- renderUI({
    HTML(paste0("<div class='file-desc-text'>", sel_file()$description, "</div>"))
  })

  output$code_display <- renderText({
    sel_file()$code
  })

  output$term_label <- renderText({
    paste("output —", sel_file()$name)
  })

  py_result <- eventReactive(input$run_btn, {
    f <- sel_file()
    code_to_run <- if (!is.null(f$demo) && nzchar(trimws(f$demo))) {
      paste(f$code, "\n# ── Demo ──\n", f$demo, sep = "\n")
    } else {
      f$code
    }
    # Build sibling modules from the chapter file list
    mods <- setNames(
      lapply(files_list, `[[`, "code"),
      sapply(files_list, `[[`, "name")
    )
    run_python_safe(code_to_run, mods)
  })

  output$py_output <- renderText({
    if (input$run_btn == 0) return("$ Ready — select a file and click ▶ Run")
    py_result()
  })

  observeEvent(input$copy_btn, {
    session$sendCustomMessage("copy_to_clipboard", sel_file()$code)
  })
}
