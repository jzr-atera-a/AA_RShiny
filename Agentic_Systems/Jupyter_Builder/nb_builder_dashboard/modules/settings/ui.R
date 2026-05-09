# ============================================================================
# SETTINGS MODULE - UI
# Tab 1: API config, paths, budget, persistence settings
# ============================================================================

settings_ui <- function(id) {
  ns <- NS(id)

  fluidRow(

    # ── Left column: API + Python ─────────────────────────────────────────
    column(6,

      box(
        title = "Claude API Configuration", status = "primary",
        solidHeader = TRUE, width = 12,

        passwordInput(ns("apiKey"), "Anthropic API Key:",
                      placeholder = "sk-ant-..."),
        selectInput(ns("model"), "Claude Model:",
                    choices = c(
                      "claude-opus-4-5"   = "claude-opus-4-5",
                      "claude-sonnet-4-6" = "claude-sonnet-4-6",
                      "claude-haiku-4-5"  = "claude-haiku-4-5-20251001"
                    ), selected = "claude-opus-4-5"),
        br(),
        actionButton(ns("testApiBtn"), "Test Connection",
                     class = "btn-info", icon = icon("plug"), width = "100%"),
        br(), br(),
        verbatimTextOutput(ns("apiStatus"))
      ),

      box(
        title = "Python Environment", status = "primary",
        solidHeader = TRUE, width = 12,

        div(class = "info-box",
          tags$p(tags$b("Specify the Python executable to use.")),
          tags$ul(
            tags$li("Conda env: ", tags$code("/opt/conda/envs/myenv/bin/python")),
            tags$li("venv: ", tags$code("./venv/bin/python")),
            tags$li("System Python: leave blank for auto-detect")
          )
        ),
        textInput(ns("pythonPath"), "Python executable path:",
                  placeholder = "/path/to/env/bin/python"),
        actionButton(ns("testPythonBtn"), "Validate Python",
                     class = "btn-info", icon = icon("check-circle"), width = "100%"),
        br(), br(),
        verbatimTextOutput(ns("pythonStatus"))
      )
    ),

    # ── Right column: Paths + Budget + Persistence ────────────────────────
    column(6,

      box(
        title = "File Locations", status = "primary",
        solidHeader = TRUE, width = 12,

        textInput(ns("contextDir"), "Context / reference files folder:",
                  placeholder = "/path/to/context"),
        div(class = "info-box",
            icon("info-circle"), " Place API docs, schemas, sample files here.",
            "They are loaded once and stored in session.json — not re-read on restart."),
        br(),

        textInput(ns("runsDir"), "Runs output folder:",
                  placeholder = "/path/to/runs"),
        div(class = "info-box",
            icon("folder-open"), " Each run creates a timestamped subfolder with",
            " session.json, notebook.ipynb, and per-cell outputs."),
        br(),

        uiOutput(ns("contextFileList"))
      ),

      box(
        title = "Budget & Circuit Breaker", status = "warning",
        solidHeader = TRUE, width = 12,

        numericInput(ns("maxCost"), "Max spend (USD):",
                     value = 2.00, min = 0.1, max = 50, step = 0.5),
        numericInput(ns("maxTokens"), "Max total tokens:",
                     value = 200000, min = 10000, max = 2000000, step = 10000),
        numericInput(ns("maxRetries"), "Max retries per cell:",
                     value = 3, min = 1, max = 10, step = 1),
        numericInput(ns("maxConsecFails"), "Max consecutive cell failures:",
                     value = 3, min = 1, max = 10, step = 1),
        checkboxInput(ns("reviewEveryCell"), "Pause for human review on every cell",
                      value = FALSE)
      ),

      box(
        title = "Save Settings", status = "success",
        solidHeader = TRUE, width = 12,

        div(class = "info-box",
            icon("save"), " Settings are saved to ",
            tags$code("nb_session_config.json"), " in the app folder.",
            " API key, paths, and budget persist across restarts."),
        br(),
        actionButton(ns("saveBtn"), "Save All Settings",
                     class = "btn-success", icon = icon("save"), width = "100%"),
        br(), br(),
        verbatimTextOutput(ns("saveStatus"))
      )
    )
  )
}
