# ============================================================================
# OUTPUTS MODULE - UI
# Tab 4: Approved cells with code + output, notebook download
# ============================================================================

outputs_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    column(12,
      box(
        title = NULL, solidHeader = FALSE, width = 12,
        style = "padding: 10px 20px;",

        fluidRow(
          column(4,
            uiOutput(ns("summaryBadges"))
          ),
          column(4,
            actionButton(ns("refreshBtn"), "Refresh Outputs",
                         class = "btn-info", icon = icon("sync"), width = "100%")
          ),
          column(4,
            downloadButton(ns("downloadNb"), "Download .ipynb",
                           class = "btn-success", style = "width:100%;")
          )
        )
      )
    ),

    column(12,
      box(
        title = "Approved Cells", status = "primary",
        solidHeader = TRUE, width = 12,

        uiOutput(ns("cellsOutput"))
      )
    )
  )
}
