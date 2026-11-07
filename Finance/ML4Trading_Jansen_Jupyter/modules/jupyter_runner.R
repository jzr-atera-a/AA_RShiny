# modules/jupyter_runner.R — Jupyter Notebook Runner
# Using EXACT approach from MetaMLPrep python_runner.R
# Each code cell has its own CodeMirror instance and runs separately

library(jsonlite)
library(dplyr)
library(markdown)

jupyter_runner_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # ── CodeMirror 5 from CDN (EXACT same as MetaMLPrep) ──
    tags$link(rel = "stylesheet",
              href = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/python/python.min.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/addon/edit/matchbrackets.min.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/addon/edit/closebrackets.min.js"),
    
    # ── CSS (EXACT styling from MetaMLPrep, scoped to .jnb-cm-host) ──
    tags$style(HTML("
      /* Container */
      .jnb-container {
        max-width: 1600px;
        margin: 0 auto;
        padding: 20px;
      }
      
      /* Header */
      .jnb-header {
        background: linear-gradient(135deg, #008A82, #00A39A);
        color: white;
        padding: 30px;
        border-radius: 12px;
        margin-bottom: 30px;
        box-shadow: 0 4px 20px rgba(0, 138, 130, 0.3);
      }
      
      .jnb-header h1 {
        margin: 0 0 10px 0;
        font-size: 28px;
        font-weight: 700;
      }
      
      /* Python Configuration */
      .jnb-python-config {
        background: white;
        border: 2px solid #008A82;
        border-radius: 8px;
        padding: 20px;
        margin-bottom: 20px;
      }
      
      .jnb-python-location {
        background: #e8f5f4;
        border-left: 4px solid #008A82;
        padding: 12px 15px;
        margin-top: 15px;
        border-radius: 4px;
        font-family: 'Fira Code', monospace;
        font-size: 13px;
        color: #155724;
      }
      
      .jnb-python-location strong {
        color: #008A82;
      }
      
      .jnb-venv-selector {
        background: #fff9e6;
        border: 2px solid #ffc107;
        border-radius: 8px;
        padding: 15px;
        margin-top: 15px;
      }
      
      .jnb-venv-btn {
        background: #ffc107 !important;
        color: #000 !important;
        border: none !important;
        padding: 8px 20px !important;
        font-size: 13px !important;
        font-weight: 700 !important;
        border-radius: 4px !important;
        cursor: pointer !important;
        margin-top: 10px !important;
      }
      
      .jnb-active-env {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border-radius: 12px;
        padding: 25px;
        margin-bottom: 20px;
        box-shadow: 0 8px 24px rgba(102, 126, 234, 0.4);
      }
      
      .jnb-active-env h3 {
        margin: 0 0 15px 0;
        font-size: 18px;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 10px;
      }
      
      .jnb-env-info {
        background: rgba(255, 255, 255, 0.15);
        border-radius: 8px;
        padding: 15px;
        font-family: 'Fira Code', monospace;
        font-size: 13px;
        line-height: 1.8;
      }
      
      .jnb-env-info-row {
        display: flex;
        margin-bottom: 8px;
      }
      
      .jnb-env-label {
        font-weight: 700;
        min-width: 180px;
        color: #ffd700;
      }
      
      .jnb-env-value {
        color: #fff;
        word-break: break-all;
      }
      
      .jnb-env-badge {
        display: inline-block;
        background: rgba(255, 255, 255, 0.3);
        padding: 4px 12px;
        border-radius: 12px;
        font-size: 11px;
        font-weight: 700;
        margin-left: 10px;
      }
      
      .jnb-env-venv-badge {
        background: #28a745;
        color: white;
        padding: 6px 14px;
        border-radius: 16px;
        font-size: 12px;
        font-weight: 700;
        display: inline-block;
        margin-left: 10px;
      }
      
      .jnb-env-system-badge {
        background: #6c757d;
        color: white;
        padding: 6px 14px;
        border-radius: 16px;
        font-size: 12px;
        font-weight: 700;
        display: inline-block;
        margin-left: 10px;
      }
      
      .connection-success {
        color: #28a745;
        font-weight: 600;
        padding: 10px;
        background: #d4edda;
        border-radius: 4px;
        margin-top: 10px;
      }
      
      .connection-error {
        color: #dc3545;
        font-weight: 600;
        padding: 10px;
        background: #f8d7da;
        border-radius: 4px;
        margin-top: 10px;
      }
      
      /* Terminal */
      .jnb-terminal-panel {
        background: white;
        border: 2px solid #6c757d;
        border-radius: 8px;
        padding: 20px;
        margin-bottom: 20px;
      }
      
      .jnb-terminal-panel h4 {
        margin-top: 0;
        color: #6c757d;
        display: flex;
        align-items: center;
        gap: 10px;
      }
      
      .jnb-terminal-output {
        background: #1e1e1e;
        color: #00ff00;
        font-family: 'Fira Code', 'Consolas', monospace;
        font-size: 13px;
        padding: 15px;
        border-radius: 4px;
        min-height: 200px;
        max-height: 400px;
        overflow-y: auto;
        margin-bottom: 15px;
        white-space: pre-wrap;
        word-wrap: break-word;
      }
      
      .jnb-terminal-prompt {
        color: #00ff00;
        font-weight: 700;
      }
      
      .jnb-terminal-command {
        color: #ffffff;
      }
      
      .jnb-terminal-output-text {
        color: #d4d4d4;
      }
      
      .jnb-terminal-error {
        color: #ff6b6b;
      }
      
      .jnb-terminal-input-group {
        display: flex;
        gap: 10px;
        align-items: center;
      }
      
      .jnb-terminal-input {
        flex: 1;
        font-family: 'Fira Code', monospace;
        background: #f8f9fa;
        border: 1px solid #6c757d;
        padding: 8px 12px;
        border-radius: 4px;
        font-size: 13px;
      }
      
      .jnb-terminal-btn {
        background: #6c757d !important;
        color: white !important;
        border: none !important;
        padding: 8px 20px !important;
        font-size: 13px !important;
        font-weight: 600 !important;
        border-radius: 4px !important;
        cursor: pointer !important;
      }
      
      .jnb-terminal-clear-btn {
        background: #dc3545 !important;
        color: white !important;
        border: none !important;
        padding: 6px 15px !important;
        font-size: 12px !important;
        font-weight: 600 !important;
        border-radius: 4px !important;
        cursor: pointer !important;
      }
      
      .jnb-terminal-hints {
        background: #fff3cd;
        border-left: 4px solid #ffc107;
        padding: 10px 15px;
        margin-top: 10px;
        border-radius: 4px;
        font-size: 12px;
        color: #856404;
      }
      
      /* Upload Section */
      .jnb-upload-section {
        background: white;
        border: 2px dashed #008A82;
        border-radius: 12px;
        padding: 40px;
        text-align: center;
        margin-bottom: 30px;
      }
      
      /* Cell Container */
      .jnb-cell {
        background: white;
        border: 1px solid #e0e0e0;
        border-radius: 8px;
        margin-bottom: 20px;
        overflow: hidden;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
      }
      
      .jnb-cell-header {
        background: #f8f9fa;
        padding: 8px 20px;
        border-bottom: 1px solid #dee2e6;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .jnb-cell-label {
        font-size: 11px;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        color: #008A82;
      }
      
      .jnb-run-btn {
        background: #008A82 !important;
        color: white !important;
        border: none !important;
        padding: 6px 16px !important;
        font-size: 12px !important;
        font-weight: 600 !important;
        border-radius: 4px !important;
        cursor: pointer !important;
      }
      
      /* ═══════════════════════════════════════════════════════════
         CODEMIRROR THEME — EXACT copy from MetaMLPrep
         Scoped to .jnb-cm-host so it doesn't affect other tabs
      ═══════════════════════════════════════════════════════════ */
      
      /* Host wrapper */
      .jnb-cm-host { width: 100% !important; display: block; }
      
      /* Editor base */
      .jnb-cm-host .CodeMirror {
        background: #1e1e1e !important;
        color: #d4d4d4 !important;
        font-family: 'Fira Code', 'Cascadia Code', 'Consolas', 'Courier New', monospace !important;
        font-size: 14px !important;
        line-height: 1.5 !important;
        height: auto !important;
        min-height: 60px !important;
        border: none !important;
        box-shadow: none !important;
        width: 100% !important;
      }
      
      .jnb-cm-host .CodeMirror-scroll { 
        min-height: 60px !important; 
      }
      
      /* Fix: stop global.css from bleeding into lines */
      .jnb-cm-host pre.CodeMirror-line,
      .jnb-cm-host pre.CodeMirror-line-like {
        background: transparent !important;
        border: none !important;
        box-shadow: none !important;
        margin: 0 !important;
      }
      
      .jnb-cm-host .CodeMirror-lines pre {
        margin: 0 !important;
        padding-top: 0 !important;
        padding-bottom: 0 !important;
      }
      
      /* Gutter */
      .jnb-cm-host .CodeMirror-gutters {
        background: #252526 !important;
        border-right: 1px solid #3c3c3c !important;
        box-shadow: none !important;
      }
      
      .jnb-cm-host .CodeMirror-linenumber { 
        color: #858585 !important; 
      }
      
      /* Cursor & selection */
      .jnb-cm-host .CodeMirror-cursor { 
        border-left: 2px solid #aeafad !important; 
      }
      
      .jnb-cm-host .CodeMirror-selected,
      .jnb-cm-host .CodeMirror-focused .CodeMirror-selected { 
        background: #264f78 !important; 
      }
      
      .jnb-cm-host .CodeMirror-activeline-background { 
        background: #2a2d2e !important; 
      }
      
      .jnb-cm-host .CodeMirror-matchingbracket {
        background: #3b514d !important; 
        color: #d4d4d4 !important;
      }
      
      /* ── Python syntax tokens (EXACT from MetaMLPrep) ── */
      
      /* Comments → green */
      .jnb-cm-host .CodeMirror .cm-comment { 
        color: #6a9955 !important; 
        font-style: italic; 
      }
      
      /* Keywords → blue */
      .jnb-cm-host .CodeMirror .cm-keyword { 
        color: #569cd6 !important; 
        font-weight: 600; 
      }
      
      /* Built-ins → yellow-green */
      .jnb-cm-host .CodeMirror .cm-builtin { 
        color: #dcdcaa !important; 
      }
      
      /* Strings → orange-brown */
      .jnb-cm-host .CodeMirror .cm-string  { 
        color: #ce9178 !important; 
      }
      .jnb-cm-host .CodeMirror .cm-string-2 { 
        color: #ce9178 !important; 
      }
      
      /* Numbers → light green */
      .jnb-cm-host .CodeMirror .cm-number  { 
        color: #b5cea8 !important; 
      }
      
      /* Atoms: True False None → blue-purple */
      .jnb-cm-host .CodeMirror .cm-atom    { 
        color: #569cd6 !important; 
      }
      
      /* Operators → white-grey */
      .jnb-cm-host .CodeMirror .cm-operator { 
        color: #d4d4d4 !important; 
      }
      
      /* Punctuation → white */
      .jnb-cm-host .CodeMirror .cm-punctuation { 
        color: #d4d4d4 !important; 
      }
      
      /* Variables → light blue */
      .jnb-cm-host .CodeMirror .cm-variable  { 
        color: #9cdcfe !important; 
      }
      .jnb-cm-host .CodeMirror .cm-variable-2 { 
        color: #9cdcfe !important; 
      }
      
      /* Function/class definition names → yellow */
      .jnb-cm-host .CodeMirror .cm-def      { 
        color: #dcdcaa !important; 
      }
      
      /* Property access → light blue */
      .jnb-cm-host .CodeMirror .cm-property { 
        color: #9cdcfe !important; 
      }
      
      /* Type hints → teal */
      .jnb-cm-host .CodeMirror .cm-type     { 
        color: #4ec9b0 !important; 
      }
      
      /* Error tokens → red */
      .jnb-cm-host .CodeMirror .cm-error    { 
        color: #f44747 !important; 
      }
      
      /* Default text → always visible */
      .jnb-cm-host .CodeMirror span { 
        color: #d4d4d4; 
      }
      
      /* Markdown cells */
      .jnb-markdown-content {
        padding: 15px 20px;
        font-size: 14px;
        line-height: 1.4;
        background: white;
        color: #2c3e50;
      }
      
      .jnb-markdown-content h1 { 
        font-size: 22px; 
        margin: 10px 0 8px 0; 
        color: #1a252f;
        font-weight: 700;
      }
      .jnb-markdown-content h2 { 
        font-size: 19px; 
        margin: 10px 0 6px 0; 
        color: #1a252f;
        font-weight: 700;
      }
      .jnb-markdown-content h3 { 
        font-size: 16px; 
        margin: 8px 0 6px 0; 
        color: #1a252f;
        font-weight: 600;
      }
      .jnb-markdown-content p {
        margin: 6px 0;
        color: #2c3e50;
      }
      .jnb-markdown-content ul, .jnb-markdown-content ol {
        margin: 6px 0;
        padding-left: 25px;
      }
      .jnb-markdown-content li {
        margin: 3px 0;
        color: #2c3e50;
      }
      .jnb-markdown-content code {
        background: #f4f4f4;
        padding: 2px 6px;
        border-radius: 3px;
        font-family: monospace;
        color: #e74c3c;
        font-size: 13px;
      }
      .jnb-markdown-content a {
        color: #3498db;
        text-decoration: none;
      }
      .jnb-markdown-content a:hover {
        text-decoration: underline;
      }
      
      /* Output styling */
      .jnb-output {
        background: #f8f9fa;
        border-top: 1px solid #dee2e6;
        padding: 15px 20px;
        font-family: 'Fira Code', monospace;
        font-size: 13px;
        max-height: 400px;
        overflow-y: auto;
      }
      
      .jnb-output pre {
        margin: 0;
        white-space: pre-wrap;
        word-wrap: break-word;
      }
      
      .jnb-error {
        color: #dc3545;
        background: #f8d7da;
        padding: 10px;
        border-radius: 4px;
        border-left: 4px solid #dc3545;
      }
      
      .jnb-success {
        color: #155724;
        background: #d4edda;
        padding: 10px;
        border-radius: 4px;
        border-left: 4px solid #28a745;
      }
      
      /* Controls */
      .jnb-controls {
        background: white;
        padding: 15px 20px;
        border-radius: 8px;
        margin-bottom: 20px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        display: flex;
        gap: 15px;
        align-items: center;
      }
    ")),
    
    div(class = "jnb-container",
      # Clear Session Button (Top Right)
      div(style = "text-align: right; margin-bottom: 15px;",
        actionButton(ns("clear_session"), "🔄 Clear Python Session", 
                     style = "background: #dc3545; color: white; padding: 10px 20px; border: none; border-radius: 4px; font-size: 13px; font-weight: 600; cursor: pointer;")
      ),
      
      # Header
      div(class = "jnb-header",
        h1("📓 Jupyter Notebook Runner"),
        p("Upload and run Jupyter notebooks (.ipynb) interactively. Execute code cells separately.")
      ),
      
      # Python Configuration - Using Shiny box with native collapse
      box(
        title = "🐍 Python Configuration", 
        status = "primary",
        solidHeader = TRUE,
        collapsible = TRUE,
        collapsed = FALSE,
        width = 12,
        
        p("Specify the path to your Python executable:"),
        textInput(ns("python_path"), 
                  label = NULL,
                  value = "python",
                  placeholder = "python  |  python3.11  |  C:/Python311/python.exe"),
        actionButton(ns("test_python"), "Test Connection",
                     icon = icon("plug"), style = "background: #008A82; color: white;"),
        uiOutput(ns("python_status")),
        uiOutput(ns("python_location")),
        
        # Virtual Environment Selector
        div(class = "jnb-venv-selector",
          tags$strong("🔧 Use Virtual Environment"),
          p(style = "font-size: 13px; margin: 8px 0;",
            "Select your virtual environment folder to use it for running notebooks."),
          textInput(ns("venv_path"),
                    label = "Virtual Environment Path:",
                    value = "C:\\201_Data\\PyVenv\\ml4t",
                    placeholder = "e.g., C:/myenv or ./myenv or /path/to/myenv"),
          div(style = "display: flex; gap: 10px; align-items: center;",
            actionButton(ns("use_venv"), "Use This Virtual Environment",
                         class = "jnb-venv-btn", icon = icon("check-circle")),
            actionButton(ns("detect_venv"), "Auto-Detect from System",
                         class = "jnb-venv-btn", icon = icon("search"), 
                         style = "background: #17a2b8 !important; color: white !important;")
          ),
          tags$small(style = "color: #856404; margin-top: 10px; display: block;",
            "💡 Tip: After activating venv in your system terminal, click 'Auto-Detect' to find it automatically.")
        ),
        
        tags$br(),
        tags$small(style = "color: #666;",
          "Try: python | python3 | python3.11",
          tags$br(),
          "Windows: C:/Python311/python.exe"
        )
      ),
      
      # Active Environment Display
      uiOutput(ns("active_environment_display")),
      
      # Interactive Terminal - Using Shiny box with native collapse
      box(
        title = "💻 Interactive Terminal",
        status = "success",
        solidHeader = TRUE,
        collapsible = TRUE,
        collapsed = TRUE,
        width = 12,
        
        p("Run commands using your configured Python environment. Install packages, create virtual environments, and more."),
        
        # Terminal output/history
        div(id = ns("terminal_output"), class = "jnb-terminal-output",
          span(class = "jnb-terminal-prompt", "$ "),
          span(class = "jnb-terminal-output-text", "Terminal ready. Type commands below."),
          tags$br(),
          span(class = "jnb-terminal-output-text", 
               "Examples: pip list | pip install pandas | python --version"),
          tags$br()
        ),
        
        # Command input
        div(class = "jnb-terminal-input-group",
          span(class = "jnb-terminal-prompt", style = "font-size: 14px;", "$ "),
          textInput(ns("terminal_command"), 
                    label = NULL,
                    value = "",
                    placeholder = "Type command and press Enter or click Execute (e.g., pip list, python --version)"),
          actionButton(ns("execute_command"), "Execute", 
                       class = "jnb-terminal-btn",
                       icon = icon("play")),
          actionButton(ns("clear_terminal"), "Clear", 
                       class = "jnb-terminal-clear-btn",
                       icon = icon("trash"))
        ),
        
        # Helpful hints
        div(class = "jnb-terminal-hints",
          tags$strong("💡 Quick Tips:"), tags$br(),
          tags$b("Install packages:"), " pip install numpy pandas matplotlib", tags$br(),
          tags$b("Create venv:"), " python -m venv myenv", tags$br(),
          tags$b("Activate (Windows):"), " myenv\\Scripts\\activate", tags$br(),
          tags$b("Activate (Unix):"), " source myenv/bin/activate", tags$br(),
          tags$b("List packages:"), " pip list | pip freeze"
        ),
        
        # JavaScript for Enter key in terminal
        tags$script(HTML(paste0("
          $(document).ready(function() {
            $('#", ns("terminal_command"), "').on('keypress', function(e) {
              if (e.which === 13 || e.keyCode === 13) {
                e.preventDefault();
                $('#", ns("execute_command"), "').click();
              }
            });
          });
        ")))
      ),
      
      # Upload section
      div(class = "jnb-upload-section",
        h3("Select Jupyter Notebook"),
        fileInput(ns("notebook_file"),
                  label = NULL,
                  accept = c(".ipynb"),
                  buttonLabel = "📂 Browse Files",
                  placeholder = "No file selected"),
        uiOutput(ns("file_info"))
      ),
      
      # Notebook info
      uiOutput(ns("notebook_info")),
      
      # Control buttons
      uiOutput(ns("control_buttons")),
      
      # Cells container
      uiOutput(ns("cells_container"))
    )
  )
}

jupyter_runner_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive values
    notebook_data <- reactiveVal(NULL)
    python_ok <- reactiveVal(FALSE)
    python_path_full <- reactiveVal(NULL)
    terminal_history <- reactiveVal(character(0))
    active_env_info <- reactiveVal(NULL)
    executed_code_history <- reactiveVal(list())  # Store all executed code for session persistence
    
    # Helper: Strip Jupyter magic commands
    strip_magic_commands <- function(code) {
      lines <- strsplit(code, "\n")[[1]]
      # Remove lines starting with % or %%
      lines <- lines[!grepl("^\\s*%%?", lines)]
      paste(lines, collapse = "\n")
    }
    
    # Helper: Get Python executable from venv path
    get_venv_python <- function(venv_path) {
      if (.Platform$OS.type == "windows") {
        file.path(venv_path, "Scripts", "python.exe")
      } else {
        file.path(venv_path, "bin", "python")
      }
    }
    
    # Helper: Check if path is a venv
    is_venv <- function(py_path) {
      # Check if path contains 'venv', 'env', or 'virtualenv'
      grepl("venv|virtualenv|env", py_path, ignore.case = TRUE) ||
      grepl("Scripts|bin", py_path) ||
      # Check if pyvenv.cfg exists nearby
      file.exists(file.path(dirname(dirname(py_path)), "pyvenv.cfg"))
    }
    
    # Helper: Get venv name from path
    get_venv_name <- function(py_path) {
      if (is_venv(py_path)) {
        # Extract venv folder name
        parts <- strsplit(py_path, "[/\\\\]")[[1]]
        # Find the venv folder (usually 2-3 levels up from python executable)
        for (i in length(parts):1) {
          if (parts[i] %in% c("Scripts", "bin")) {
            if (i > 1) return(parts[i-1])
          }
        }
        return("venv")
      }
      return(NULL)
    }
    
    # Helper: Get installed packages count
    get_package_count <- function(py_path) {
      tryCatch({
        result <- system2(py_path, c("-m", "pip", "list", "--format=freeze"), 
                         stdout = TRUE, stderr = TRUE)
        length(result)
      }, error = function(e) NA)
    }
    
    # Update active environment display
    update_env_display <- function() {
      req(python_ok())
      
      py_path <- python_path_full()
      py_version <- input$python_status
      is_virtual <- is_venv(py_path)
      venv_name <- get_venv_name(py_path)
      pkg_count <- get_package_count(trimws(input$python_path %||% "python"))
      
      active_env_info(list(
        path = py_path,
        is_venv = is_virtual,
        venv_name = venv_name,
        package_count = pkg_count
      ))
      
      output$active_environment_display <- renderUI({
        div(class = "jnb-active-env",
          h3(
            icon("rocket"), 
            "Active Environment for Jupyter Notebooks",
            if (is_virtual) {
              span(class = "jnb-env-venv-badge", paste0("VENV: ", venv_name))
            } else {
              span(class = "jnb-env-system-badge", "SYSTEM PYTHON")
            }
          ),
          div(class = "jnb-env-info",
            div(class = "jnb-env-info-row",
              span(class = "jnb-env-label", "🐍 Python Executable:"),
              span(class = "jnb-env-value", py_path)
            ),
            if (is_virtual) {
              div(class = "jnb-env-info-row",
                span(class = "jnb-env-label", "📦 Virtual Environment:"),
                span(class = "jnb-env-value", venv_name)
              )
            },
            div(class = "jnb-env-info-row",
              span(class = "jnb-env-label", "📊 Installed Packages:"),
              span(class = "jnb-env-value", 
                   if (!is.na(pkg_count)) paste(pkg_count, "packages") else "Unknown")
            ),
            div(class = "jnb-env-info-row",
              span(class = "jnb-env-label", "✓ Status:"),
              span(class = "jnb-env-value", 
                   "All notebook cells will run in this environment")
            )
          )
        )
      })
    }
    
    # ── Use Virtual Environment Button ──
    observeEvent(input$use_venv, {
      venv_path <- trimws(input$venv_path)
      
      if (is.null(venv_path) || nchar(venv_path) == 0) {
        showNotification("Please enter a virtual environment path", 
                        type = "error", duration = 3)
        return()
      }
      
      # Construct Python executable path
      py_exe <- get_venv_python(venv_path)
      
      # Check if it exists
      if (!file.exists(py_exe)) {
        showNotification(paste("Python executable not found at:", py_exe,
                              "\nMake sure the path points to a valid venv folder"),
                        type = "error", duration = 5)
        return()
      }
      
      # Update Python path
      updateTextInput(session, "python_path", value = py_exe)
      
      # Trigger test connection
      showNotification("Testing connection to virtual environment...", 
                      type = "message", duration = 2)
      
      # Manually trigger the test
      py  <- trimws(py_exe)
      res <- tryCatch(
        system2(py, "--version", stdout=TRUE, stderr=TRUE),
        error = function(e) NULL
      )
      
      if (!is.null(res) && length(res)>0 && grepl("Python", res[1])) {
        python_ok(TRUE)
        py_location <- py_exe
        python_path_full(py_location)
        update_env_display()
        
        showNotification(paste("✓ Successfully switched to virtual environment:", 
                              basename(venv_path)),
                        type = "message", duration = 4)
      } else {
        showNotification("Failed to connect to virtual environment Python",
                        type = "error", duration = 4)
      }
    })
    
    # ── Auto-Detect Virtual Environment ──
    observeEvent(input$detect_venv, {
      # Try to detect VIRTUAL_ENV environment variable
      venv_env <- Sys.getenv("VIRTUAL_ENV")
      
      if (nchar(venv_env) > 0) {
        # Found active venv from environment
        updateTextInput(session, "venv_path", value = venv_env)
        
        py_exe <- get_venv_python(venv_env)
        updateTextInput(session, "python_path", value = py_exe)
        
        # Test the connection
        res <- tryCatch(
          system2(py_exe, "--version", stdout=TRUE, stderr=TRUE),
          error = function(e) NULL
        )
        
        if (!is.null(res) && length(res)>0 && grepl("Python", res[1])) {
          python_ok(TRUE)
          python_path_full(py_exe)
          update_env_display()
          
          showNotification(paste("✓ Auto-detected and activated virtual environment:", 
                                basename(venv_env)),
                          type = "message", duration = 4)
        }
      } else {
        showNotification(paste("No active virtual environment detected.",
                              "Activate a venv in your system terminal first, or enter the path manually."),
                        type = "warning", duration = 5)
      }
    })
    
    # ── Python connection test (EXACT from MetaMLPrep) ──
    observeEvent(input$test_python, {
      py  <- trimws(input$python_path %||% "python")
      res <- tryCatch(
        system2(py, "--version", stdout=TRUE, stderr=TRUE),
        error = function(e) NULL
      )
      
      # Get full Python path
      py_location <- tryCatch({
        if (.Platform$OS.type == "windows") {
          system2("where", py, stdout=TRUE, stderr=TRUE)[1]
        } else {
          system2("which", py, stdout=TRUE, stderr=TRUE)[1]
        }
      }, error = function(e) py)
      
      output$python_status <- renderUI({
        if (!is.null(res) && length(res)>0 && grepl("Python", res[1])) {
          python_ok(TRUE)
          python_path_full(py_location)
          
          # Update environment display
          update_env_display()
          
          div(class="connection-success", 
              tags$b("✅ Connected:"), br(), 
              tags$code(res[1]))
        } else {
          python_ok(FALSE)
          python_path_full(NULL)
          div(class="connection-error",  
              tags$b("❌ Not found"), br(),
              tags$small("Try: python | python3 | python3.11", br(),
                         "Windows: C:/Python311/python.exe"))
        }
      })
      
      # Display Python location
      output$python_location <- renderUI({
        req(python_ok())
        location <- python_path_full()
        if (!is.null(location) && nchar(location) > 0) {
          div(class = "jnb-python-location",
            tags$strong("📍 Python Location: "), 
            tags$code(location)
          )
        }
      })
    })
    
    # ── Terminal: Execute Command ──
    observeEvent(input$execute_command, {
      command <- trimws(input$terminal_command)
      if (is.null(command) || nchar(command) == 0) {
        showNotification("Please enter a command", type = "warning", duration = 2)
        return()
      }
      
      # Parse command - check if it needs Python path
      cmd_parts <- strsplit(command, "\\s+")[[1]]
      base_cmd <- cmd_parts[1]
      cmd_args <- if (length(cmd_parts) > 1) cmd_parts[-1] else character(0)
      
      # If command starts with 'python' or 'pip', use configured Python path
      if (base_cmd %in% c("python", "python3", "pip", "pip3")) {
        py <- trimws(input$python_path %||% "python")
        
        # For pip, use python -m pip
        if (base_cmd %in% c("pip", "pip3")) {
          actual_cmd <- py
          actual_args <- c("-m", "pip", cmd_args)
        } else {
          actual_cmd <- py
          actual_args <- cmd_args
        }
      } else {
        actual_cmd <- base_cmd
        actual_args <- cmd_args
      }
      
      # Execute command
      result <- tryCatch({
        system2(actual_cmd, actual_args, stdout=TRUE, stderr=TRUE)
      }, error = function(e) {
        paste("ERROR:", e$message)
      })
      
      # Format output
      is_error <- any(grepl("Error|error|ERROR|not found|command not found", result, ignore.case=TRUE))
      output_text <- paste(result, collapse="\n")
      
      # Update terminal history
      history <- terminal_history()
      new_entry <- list(
        command = command,
        output = output_text,
        is_error = is_error
      )
      history[[length(history) + 1]] <- new_entry
      terminal_history(history)
      
      # Render terminal output
      shiny::insertUI(
        selector = paste0("#", ns("terminal_output")),
        where = "beforeEnd",
        ui = tagList(
          tags$br(),
          span(class = "jnb-terminal-prompt", "$ "),
          span(class = "jnb-terminal-command", command),
          tags$br(),
          span(class = if (is_error) "jnb-terminal-error" else "jnb-terminal-output-text",
               output_text),
          tags$br()
        )
      )
      
      # Clear input
      updateTextInput(session, "terminal_command", value = "")
    })
    
    # ── Terminal: Clear Output ──
    observeEvent(input$clear_terminal, {
      terminal_history(character(0))
      
      shiny::removeUI(
        selector = paste0("#", ns("terminal_output"), " > *:not(:first-child):not(:nth-child(2)):not(:nth-child(3))")
      )
      
      # Reset terminal to initial state
      output$terminal_output_reset <- renderUI({
        div(id = ns("terminal_output"), class = "jnb-terminal-output",
          span(class = "jnb-terminal-prompt", "$ "),
          span(class = "jnb-terminal-output-text", "Terminal cleared. Type commands below."),
          tags$br()
        )
      })
    })
    
    # Handle file upload
    observeEvent(input$notebook_file, {
      req(input$notebook_file)
      
      tryCatch({
        nb <- fromJSON(input$notebook_file$datapath, simplifyVector = FALSE)
        notebook_data(nb)
        
        # Clear code execution history
        executed_code_history(list())
        
        showNotification("Notebook loaded successfully! Python session cleared.", 
                        type = "message", duration = 3)
      }, error = function(e) {
        showNotification(paste("Error loading notebook:", e$message),
                        type = "error", duration = 5)
      })
    })
    
    # Clear Python Session
    observeEvent(input$clear_session, {
      executed_code_history(list())
      showNotification("✓ Python session cleared. All variables and imports reset.", 
                      type = "message", duration = 3)
    })
    
    # Display file info
    output$file_info <- renderUI({
      req(input$notebook_file)
      div(style = "margin-top: 15px; color: #28a745; font-weight: 600;",
        icon("check-circle"), " File loaded: ", input$notebook_file$name
      )
    })
    
    # Display notebook info
    output$notebook_info <- renderUI({
      req(notebook_data())
      nb <- notebook_data()
      
      n_code <- sum(sapply(nb$cells, function(c) c$cell_type == "code"))
      n_markdown <- sum(sapply(nb$cells, function(c) c$cell_type == "markdown"))
      
      div(style = "background: #f8f9fa; border-left: 4px solid #008A82; padding: 15px; margin-bottom: 20px; border-radius: 4px;",
        tags$strong("Notebook Information:"),
        tags$ul(
          tags$li(paste("Total cells:", length(nb$cells))),
          tags$li(paste("Code cells:", n_code)),
          tags$li(paste("Markdown cells:", n_markdown))
        )
      )
    })
    
    # Control buttons
    output$control_buttons <- renderUI({
      req(notebook_data())
      
      div(class = "jnb-controls",
        actionButton(ns("run_all"), "▶ Run All Cells", 
                     style = "background: #16a34a; color: white; padding: 10px 25px; font-weight: 700;"),
        actionButton(ns("clear_all"), "🗑 Clear All Outputs",
                     style = "background: #6c757d; color: white; padding: 10px 25px; font-weight: 700;")
      )
    })
    
    # Render cells
    output$cells_container <- renderUI({
      req(notebook_data())
      nb <- notebook_data()
      
      cells_ui <- lapply(seq_along(nb$cells), function(i) {
        cell <- nb$cells[[i]]
        
        if (cell$cell_type == "markdown") {
          # Markdown cell
          markdown_content <- paste(unlist(cell$source), collapse = "\n")
          
          div(class = "jnb-cell",
            div(class = "jnb-cell-header",
              span(class = "jnb-cell-label", "📝 MARKDOWN CELL")
            ),
            div(class = "jnb-markdown-content",
                HTML(markdown::markdownToHTML(text = markdown_content, fragment.only = TRUE))
            )
          )
          
        } else if (cell$cell_type == "code") {
          # Code cell - EACH gets its own CodeMirror instance
          code_content <- paste(unlist(cell$source), collapse = "\n")
          cm_host_id <- ns(paste0("cm_host_", i))
          code_input_id <- ns(paste0("code_input_", i))
          
          # Properly escape code for JavaScript string
          js_code <- code_content
          js_code <- gsub("\\\\", "\\\\\\\\", js_code)  # Escape backslashes first
          js_code <- gsub("'", "\\\\'", js_code)        # Escape single quotes
          js_code <- gsub("\n", "\\\\n", js_code)       # Convert newlines to \n
          js_code <- gsub("\r", "", js_code)            # Remove carriage returns
          js_code <- gsub("\t", "\\\\t", js_code)       # Convert tabs to \t
          
          tagList(
            div(class = "jnb-cell",
              div(class = "jnb-cell-header",
                span(class = "jnb-cell-label", paste("💻 CODE CELL", i)),
                actionButton(ns(paste0("run_", i)), "▶ Run", class = "jnb-run-btn")
              ),
              
              # CodeMirror host (EXACT structure from MetaMLPrep)
              div(class = "jnb-cm-host",
                  div(id = cm_host_id),
                  tags$input(type = "hidden", id = code_input_id, style = "display:none;")
              ),
              
              uiOutput(ns(paste0("output_", i)))
            ),
            
            # Initialize CodeMirror for THIS cell (EXACT from MetaMLPrep)
            tags$script(HTML(paste0("
(function waitForCM_", i, "() {
  if (typeof CodeMirror === 'undefined') { 
    return setTimeout(waitForCM_", i, ", 80); 
  }

  var host   = document.getElementById('", cm_host_id, "');
  var hidden = document.getElementById('", code_input_id, "');

  if (!host || !hidden) { 
    return setTimeout(waitForCM_", i, ", 80); 
  }

  var cm = CodeMirror(host, {
    value:             '", js_code, "',
    mode:              'python',
    theme:             'default',
    lineNumbers:       true,
    indentUnit:        4,
    tabSize:           4,
    indentWithTabs:    false,
    matchBrackets:     true,
    autoCloseBrackets: true,
    readOnly:          false,
    lineWrapping:      false,
    viewportMargin:    Infinity
  });

  /* Store in global object */
  window._jnbEditors = window._jnbEditors || {};
  window._jnbEditors['", code_input_id, "'] = cm;

  /* Refresh after DOM settles (CRITICAL for proper rendering) */
  setTimeout(function() { cm.refresh(); }, 300);
  setTimeout(function() { cm.refresh(); }, 800);

  /* Sync to Shiny */
  cm.on('change', function() {
    var val = cm.getValue();
    hidden.value = val;
    try {
      Shiny.setInputValue('", code_input_id, "', val, { priority: 'event' });
    } catch(e) {}
  });

})();
            ")))
          )
        }
      })
      
      do.call(tagList, cells_ui)
    })
    
    # Run individual cell (EXACT execution from MetaMLPrep)
    observe({
      nb <- notebook_data()
      req(nb)
      
      lapply(seq_along(nb$cells), function(i) {
        cell <- nb$cells[[i]]
        if (cell$cell_type == "code") {
          
          observeEvent(input[[paste0("run_", i)]], {
            
            if (!python_ok()) {
              output[[paste0("output_", i)]] <- renderUI({
                div(class = "jnb-output",
                  div(class = "jnb-error",
                    tags$strong("⚠ Python Not Configured"), br(),
                    "Please configure Python path above and test the connection first."
                  )
                )
              })
              return()
            }
            
            # Get current code from CodeMirror
            code <- input[[paste0("code_input_", i)]]
            if (is.null(code)) {
              code <- paste(unlist(cell$source), collapse = "\n")
            }
            
            # Strip Jupyter magic commands (lines starting with % or %%)
            code_clean <- strip_magic_commands(code)
            
            # Store this cell's code in history
            history <- executed_code_history()
            history[[as.character(i)]] <- code_clean
            executed_code_history(history)
            
            # Build complete script: ALL previous cells + current cell
            # This ensures ALL imports and variables are available
            all_cells <- history[order(as.numeric(names(history)))]
            complete_code <- paste(all_cells, collapse = "\n\n# ────────────────────────\n\n")
            
            py <- trimws(input$python_path %||% "python")
            
            # Execute complete code (all previous cells + current)
            tmp <- tempfile(fileext=".py")
            writeLines(complete_code, tmp)
            
            result <- tryCatch(
              system2(py, tmp, stdout=TRUE, stderr=TRUE),
              error = function(e) paste("ERROR:", e$message)
            )
            
            file.remove(tmp)
            
            is_error <- any(grepl("Error|Traceback", result, ignore.case=TRUE))
            out_text <- paste(result, collapse="\n")
            
            # Handle empty output
            if (is.null(out_text) || nchar(trimws(out_text)) == 0) {
              out_text <- "(No output)"
            }
            
            output[[paste0("output_", i)]] <- renderUI({
              div(class = "jnb-output",
                if (!is_error) {
                  div(class = "jnb-success", 
                      icon("check-circle"), " Executed successfully")
                },
                tags$pre(style = paste0("color:", 
                                       if (is_error) "#f87171" else "#4ade80",
                                       ";margin:0;"),
                        out_text)
              )
            })
            
          })
        }
      })
    })
    
    # Run all cells
    observeEvent(input$run_all, {
      nb <- notebook_data()
      req(nb)
      
      if (!python_ok()) {
        showNotification("Please configure and test Python connection first!",
                        type = "error", duration = 4)
        return()
      }
      
      showNotification("Running all code cells...", type = "message", duration = 2)
      
      # Trigger all run buttons sequentially
      lapply(seq_along(nb$cells), function(i) {
        if (nb$cells[[i]]$cell_type == "code") {
          Sys.sleep(0.2)
          updateActionButton(session, paste0("run_", i))
        }
      })
    })
    
    # Clear all outputs
    observeEvent(input$clear_all, {
      nb <- notebook_data()
      req(nb)
      
      lapply(seq_along(nb$cells), function(i) {
        if (nb$cells[[i]]$cell_type == "code") {
          output[[paste0("output_", i)]] <- renderUI({
            div(class = "jnb-output", style = "color: #999; font-style: italic;",
              "No output yet. Click 'Run' to execute this cell.")
          })
        }
      })
      
      showNotification("All outputs cleared", type = "message", duration = 2)
    })
    
  })
}
