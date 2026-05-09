# ============================================================================
# MONITOR MODULE - UI
# Tab 3: Live progress, log, stats, process controls, human checkpoint
# ============================================================================

monitor_ui <- function(id) {
  ns <- NS(id)

  fluidRow(

    # ── Top controls + stats row ──────────────────────────────────────────
    column(12,
      box(
        title = NULL, status = "primary", solidHeader = FALSE,
        width = 12, style = "padding: 10px 20px;",

        fluidRow(
          # Process control buttons
          column(5,
            tags$div(style = "display:flex; gap:8px; flex-wrap:wrap; align-items:center;",
              actionButton(ns("pauseBtn"),    "Pause",    class = "btn-warning",
                           icon = icon("pause"),   disabled = "disabled"),
              actionButton(ns("continueBtn"), "Continue", class = "btn-success",
                           icon = icon("play"),    disabled = "disabled"),
              actionButton(ns("stopBtn"),     "Stop",     class = "btn-danger",
                           icon = icon("stop"),    disabled = "disabled"),
              uiOutput(ns("agentBadge"))
            )
          ),
          # Progress bar
          column(7,
            tags$div(style = "padding-top:4px;",
              uiOutput(ns("progressLabel")),
              tags$div(class = "progress",
                tags$div(id = ns("progressBar"),
                  class = "progress-bar", role = "progressbar",
                  style = "width: 0%;",
                  `aria-valuenow` = "0", `aria-valuemin` = "0", `aria-valuemax` = "100"
                )
              )
            )
          )
        )
      )
    ),

    # ── Stats cards ───────────────────────────────────────────────────────
    column(12,
      fluidRow(
        column(2, uiOutput(ns("statCellsApproved"))),
        column(2, uiOutput(ns("statCellsTotal"))),
        column(2, uiOutput(ns("statRetries"))),
        column(2, uiOutput(ns("statCost"))),
        column(2, uiOutput(ns("statTokens"))),
        column(2, uiOutput(ns("statSkipped")))
      )
    ),

    # ── Human checkpoint (hidden until needed) ─────────────────────────────
    column(12,
      conditionalPanel(
        condition = paste0("output['", ns("checkpointActive"), "'] == true"),
        div(class = "checkpoint-panel",
          fluidRow(
            column(8,
              tags$h4(icon("exclamation-triangle"), " Human Checkpoint Required"),
              uiOutput(ns("checkpointContent"))
            ),
            column(4,
              br(),
              actionButton(ns("cpAccept"), "Accept",  class = "btn-success",
                           icon = icon("check"),  width = "100%"),
              br(), br(),
              actionButton(ns("cpSkip"),   "Skip",    class = "btn-warning",
                           icon = icon("forward"), width = "100%"),
              br(), br(),
              actionButton(ns("cpAbort"),  "Abort Run", class = "btn-danger",
                           icon = icon("stop"), width = "100%")
            )
          )
        )
      )
    ),

    # ── Terminal log ──────────────────────────────────────────────────────
    column(12,
      box(
        title = "Live Log", status = "primary",
        solidHeader = TRUE, width = 12,

        div(id = ns("termLog"), class = "terminal-pane",
          "Waiting for run to start..."
        ),
        br(),
        tags$small(class = "text-muted",
          "Auto-refreshes every 2 seconds while running. ",
          actionLink(ns("clearLog"), "Clear display")
        )
      )
    )
  )
}
