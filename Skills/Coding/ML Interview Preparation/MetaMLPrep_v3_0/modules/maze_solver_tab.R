# modules/maze_solver_tab.R
# Maze Solver — 4-pane code viewer + Python runner
# Python files live in www/python/ relative to app root
#
# KEY FIX vs earlier version:
#   system2() does not have a cwd parameter. We temporarily setwd() to
#   python_dir before invoking Python so that inter-file imports
#   (from maze import Maze, from solver import solve) resolve correctly.
#   After the call we restore the original working directory.
#
#   Python path is read from prep_manager$python_path (set by python_runner
#   tab) so users only need to configure it once. A local override field
#   is still provided as a fallback.

maze_solver_tab_ui <- function(id) {
  ns <- NS(id)

  tagList(

    tags$style(HTML("
      /* ── Maze tab: code pane styling ────────────────────────────────── */
      .mz-shell {
        background: #0d1117;
        border: 1px solid #30363d;
        border-radius: 10px;
        overflow: hidden;
        display: flex;
        flex-direction: column;
        height: 340px;
      }
      .mz-chrome {
        background: #161b22;
        padding: 6px 12px;
        display: flex;
        align-items: center;
        gap: 8px;
        border-bottom: 1px solid #30363d;
        flex-shrink: 0;
      }
      .mz-dot  { width:10px; height:10px; border-radius:50%; display:inline-block; }
      .mz-dot-r { background:#f87171; }
      .mz-dot-a { background:#fbbf24; }
      .mz-dot-g { background:#4ade80; }
      .mz-filename {
        font-family: 'Fira Code', monospace;
        font-size: 12px; color: #8b949e; margin-left: 4px;
      }
      .mz-badge {
        font-size: 10px; font-weight:700;
        color: #4ade80; font-family: 'Fira Code', monospace;
        margin-left: auto;
      }
      .mz-code {
        flex: 1;
        overflow-y: auto; overflow-x: auto;
        padding: 10px 14px; margin: 0;
        background: #0d1117; color: #e6edf3;
        font-family: 'Fira Code', 'Courier New', monospace;
        font-size: 11.5px; line-height: 1.6;
        white-space: pre; border: none; border-radius: 0;
      }
      .mz-code::-webkit-scrollbar { width:5px; height:5px; }
      .mz-code::-webkit-scrollbar-track { background:#0d1117; }
      .mz-code::-webkit-scrollbar-thumb { background:#30363d; border-radius:3px; }
      .mz-run-bar {
        display: flex; align-items: center; gap: 8px;
        padding: 8px 2px 4px; flex-wrap: wrap;
      }
      .mz-run-btn {
        background: linear-gradient(135deg,#16a34a,#15803d) !important;
        color: white !important; font-weight:700 !important;
        font-size:13px !important; border:none !important;
        border-radius:7px !important; padding:8px 22px !important;
        box-shadow:0 3px 10px rgba(22,163,74,.35) !important;
      }
      .mz-test-btn {
        background: linear-gradient(135deg,#1877F2,#0A66C2) !important;
        color: white !important; font-weight:700 !important;
        font-size:13px !important; border:none !important;
        border-radius:7px !important; padding:8px 22px !important;
        box-shadow:0 3px 10px rgba(24,119,242,.35) !important;
      }
      .mz-output {
        background: #0d1117; color: #58a6ff;
        border-radius: 8px; padding: 12px 14px;
        font-family: 'Fira Code', monospace; font-size: 11.5px;
        min-height: 180px; max-height: 360px;
        overflow-y: auto; border: 1px solid #30363d;
        white-space: pre-wrap; word-break: break-word; margin-top: 4px;
      }
    ")),

    # ── Hero ────────────────────────────────────────────────────────────────
    div(class="meta-hero",
        tags$h1("Maze Solver — AI-Enabled Coding Practice"),
        tags$h2("BFS with Keys, Doors and One-Way Chutes — Meta Interview Format"),
        div(
          span(class="hero-badge", "BFS State-Space"),
          span(class="hero-badge", "Keys + Doors"),
          span(class="hero-badge", "One-Way Chutes"),
          span(class="hero-badge", "17 Test Cases — 25 Assertions"),
          span(class="hero-badge", "Multi-File Codebase")
        )
    ),

    # ── Python path row ─────────────────────────────────────────────────────
    fluidRow(
      box(title = "Python Interpreter", status = "primary",
          solidHeader = TRUE, width = 5,
        div(class = "tip-box",
          icon("info-circle"),
          tags$b(" Auto-reads from Python Runner tab."),
          tags$span(" Configure and Test there once — it applies here automatically.")
        ),
        div(style = "display:flex; align-items:center; gap:8px; margin-top:10px;",
          div(style = "flex:1;",
            textInput(ns("python_path_override"), label = NULL,
                      value = "",
                      placeholder = "Leave blank to use Python Runner setting  |  or override here")
          ),
          actionButton(ns("test_python"), "Test", class = "btn-meta", icon = icon("plug"))
        ),
        uiOutput(ns("python_status"))
      ),
      box(title = "Interview Context", status = "info",
          solidHeader = TRUE, width = 7,
        div(class = "framework-card",
          tags$p(tags$b("Four-part structure mirrors the real CoderPad interview:")),
          tags$ol(
            tags$li(tags$b("maze.py"), " — read and understand the starter data structures"),
            tags$li(tags$b("solver.py"), " — implement BFS over state (position, frozenset_of_keys)"),
            tags$li(tags$b("main.py"), " — run 6 demo scenarios, verify console output"),
            tags$li(tags$b("test_maze.py"), " — hit 25/25 assertions including edge cases")
          ),
          tags$p(style = "margin-top:8px; color:#555; font-size:12px;",
            "Key insight to narrate: 'Same cell + different keys = different BFS state. ",
            "frozenset in the state tuple prevents false loops and missed paths.'")
        )
      )
    ),

    # ── Row A: maze.py  |  solver.py ────────────────────────────────────────
    fluidRow(
      column(6,
        div(class = "mz-shell",
          div(class = "mz-chrome",
            span(class = "mz-dot mz-dot-r"),
            span(class = "mz-dot mz-dot-a"),
            span(class = "mz-dot mz-dot-g"),
            span(class = "mz-filename", "maze.py"),
            span(class = "mz-badge", "STARTER CODE — DATA STRUCTURES")
          ),
          tags$pre(class = "mz-code", uiOutput(ns("code_maze_ui")))
        )
      ),
      column(6,
        div(class = "mz-shell",
          div(class = "mz-chrome",
            span(class = "mz-dot mz-dot-r"),
            span(class = "mz-dot mz-dot-a"),
            span(class = "mz-dot mz-dot-g"),
            span(class = "mz-filename", "solver.py"),
            span(class = "mz-badge", "BFS ENGINE — IMPLEMENT THIS")
          ),
          tags$pre(class = "mz-code", uiOutput(ns("code_solver_ui")))
        )
      )
    ),

    # ── Row B: main.py + output  |  test_maze.py + output ───────────────────
    fluidRow(
      column(6,
        div(class = "mz-shell",
          div(class = "mz-chrome",
            span(class = "mz-dot mz-dot-r"),
            span(class = "mz-dot mz-dot-a"),
            span(class = "mz-dot mz-dot-g"),
            span(class = "mz-filename", "main.py"),
            span(class = "mz-badge", "6 DEMO SCENARIOS")
          ),
          tags$pre(class = "mz-code", uiOutput(ns("code_main_ui")))
        ),
        div(class = "mz-run-bar",
          actionButton(ns("run_main"), "\u25b6  Run Demos",
                       class = "mz-run-btn", icon = icon("play")),
          uiOutput(ns("main_py_info"))
        ),
        div(class = "mz-output", uiOutput(ns("main_output")))
      ),
      column(6,
        div(class = "mz-shell",
          div(class = "mz-chrome",
            span(class = "mz-dot mz-dot-r"),
            span(class = "mz-dot mz-dot-a"),
            span(class = "mz-dot mz-dot-g"),
            span(class = "mz-filename", "test_maze.py"),
            span(class = "mz-badge", "17 TESTS / 25 ASSERTIONS")
          ),
          tags$pre(class = "mz-code", uiOutput(ns("code_test_ui")))
        ),
        div(class = "mz-run-bar",
          actionButton(ns("run_tests"), "\u25b6  Run Tests",
                       class = "mz-test-btn", icon = icon("vial")),
          uiOutput(ns("test_py_info"))
        ),
        div(class = "mz-output", uiOutput(ns("test_output")))
      )
    )

  ) # end tagList
}


maze_solver_tab_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    # ── Locate python files directory ─────────────────────────────────────
    python_dir <- file.path(getwd(), "www", "python")

    # ── Resolve which Python to use ───────────────────────────────────────
    # Priority: local override field > prep_manager$python_path > "python"
    get_python <- function() {
      override <- trimws(input$python_path_override %||% "")
      if (nchar(override) > 0) return(override)
      pm_path <- prep_manager$python_path %||% "python"
      trimws(pm_path)
    }

    # ── Helper: read a Python file for display ────────────────────────────
    read_py <- function(filename) {
      path <- file.path(python_dir, filename)
      if (!file.exists(path))
        return(paste("# File not found:", path))
      paste(readLines(path, warn = FALSE), collapse = "\n")
    }

    # ── Render the four code panes ────────────────────────────────────────
    output$code_maze_ui   <- renderUI({ tags$span(read_py("maze.py"))     })
    output$code_solver_ui <- renderUI({ tags$span(read_py("solver.py"))   })
    output$code_main_ui   <- renderUI({ tags$span(read_py("main.py"))     })
    output$code_test_ui   <- renderUI({ tags$span(read_py("test_maze.py")) })

    # ── Python test ───────────────────────────────────────────────────────
    observeEvent(input$test_python, {
      py  <- get_python()
      res <- tryCatch(
        system2(py, "--version", stdout = TRUE, stderr = TRUE),
        error = function(e) NULL
      )
      ok <- !is.null(res) && length(res) > 0 && grepl("Python", res[1])
      if (ok) prep_manager$python_path <- py
      output$python_status <- renderUI({
        if (ok)
          div(class = "connection-success", style = "margin-top:8px;",
              tags$b("\u2705 Connected:"), tags$code(res[1]))
        else
          div(class = "connection-error", style = "margin-top:8px;",
              tags$b("\u274c Not found —"),
              tags$small("Try: python | python3 | python3.11 | C:/Python311/python.exe"))
      })
    })

    # ── Show which interpreter will be used ───────────────────────────────
    output$main_py_info <- renderUI({
      py <- get_python()
      tags$span(style = "font-size:11px; color:#8b949e;",
                paste0("interpreter: ", py,
                       "   cwd: www/python/"))
    })
    output$test_py_info <- renderUI({
      py <- get_python()
      tags$span(style = "font-size:11px; color:#8b949e;",
                paste0("interpreter: ", py,
                       "   cwd: www/python/"))
    })

    # ── Core runner ───────────────────────────────────────────────────────
    # FIX: setwd(python_dir) before system2 so that inter-file imports
    # (from maze import Maze) work. Python adds the script's directory to
    # sys.path[0] only when run as a script with a relative filename;
    # using setwd ensures the cwd matches the script location.
    run_python_file <- function(filename, py_path) {
      if (!dir.exists(python_dir)) {
        return(tags$span(style = "color:#f87171;",
                         paste("Directory not found:", python_dir)))
      }
      script <- file.path(python_dir, filename)
      if (!file.exists(script)) {
        return(tags$span(style = "color:#f87171;",
                         paste("File not found:", script)))
      }

      # ── KEY FIX: change cwd to python_dir so imports resolve ─────────
      orig_wd <- setwd(python_dir)
      result <- tryCatch(
        system2(py_path, args = filename, stdout = TRUE, stderr = TRUE),
        error = function(e) paste("ERROR:", e$message)
      )
      setwd(orig_wd)   # always restore
      # ─────────────────────────────────────────────────────────────────

      # Colourise output lines
      lines_ui <- lapply(result, function(ln) {
        style <-
          if      (grepl("\\[\\+\\]|PASS|Goal reached|Collected|RESULT.*found", ln))
            "color:#4ade80;"
          else if (grepl("\\[X\\]|FAIL|No path|ERROR|Traceback|ModuleNotFoundError", ln))
            "color:#f87171;"
          else if (grepl("\\[BFS\\]|\\[KEY\\]|\\[CHUTE\\]", ln))
            "color:#fbbf24;"
          else if (grepl("^={3,}|SUMMARY|MAZE SOLVER|Scenario [0-9]", ln))
            "color:#60a5fa; font-weight:700;"
          else if (grepl("Path:|Solved in|steps", ln))
            "color:#c084fc;"
          else
            "color:#e6edf3;"
        tags$div(style = style, ln)
      })

      do.call(tagList, lines_ui)
    }

    # ── Run main.py ────────────────────────────────────────────────────────
    observeEvent(input$run_main, {
      py <- get_python()
      output$main_output <- renderUI({
        withProgress(message = "Running main.py...", value = 0.5,
                     run_python_file("main.py", py))
      })
      prep_manager$update_progress("maze_solver_tab", 60)
    })

    # ── Run test_maze.py ───────────────────────────────────────────────────
    observeEvent(input$run_tests, {
      py <- get_python()
      output$test_output <- renderUI({
        withProgress(message = "Running test suite...", value = 0.5,
                     run_python_file("test_maze.py", py))
      })
      prep_manager$update_progress("maze_solver_tab", 80)
    })

    prep_manager$update_progress("maze_solver_tab", 10)
  })
}
