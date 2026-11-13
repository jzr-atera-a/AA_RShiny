# modules/Technical Designs/techdesign_matrix/ui.R

techdesign_matrix_ui <- function(id) {
  ns <- NS(id)
  seeds <- tdm_seed_files()
  tagList(
    fluidRow(
      box(
        title = "Market Matrix: two hierarchies, one evidence matrix", status = "primary", solidHeader = TRUE, width = 12,
        div(class = "alert alert-info",
            tags$strong("How this works:"),
            " describe two things to contrast (for example financial markets vs economic and technology drivers). The Editing Tool plans the rows, columns and the measurable metric for each column, ",
            "then researches each column on the web and returns every score with its metric, value, date, a verbatim quote and the source URL. ",
            "The app then fetches each cited page and checks that the quote is really there, computes both hierarchies from the scores (Ward clustering), asks for names for the branches, and draws the diagram. ",
            "Cells without a source are marked as judgment. Everything is stored as one row per version in the Technical Designs table."),
        textAreaInput(ns("topic"), "What should be contrasted? *", rows = 3, width = "100%",
                      placeholder = "e.g., Major financial markets (equity indices, mega-cap tech, bonds, FX, oil, gold) versus the economic and technology drivers that move them."),
        textInput(ns("extra"), "Extra instructions (optional):", width = "100%",
                  placeholder = "e.g., focus on US and Europe; prefer central bank and exchange sources; use 5-year data"),
        fluidRow(
          column(3, numericInput(ns("n_rows"), "About how many rows:", value = 14, min = 5, max = 30, step = 1)),
          column(3, numericInput(ns("n_cols"), "About how many columns:", value = 8, min = 4, max = 14, step = 1)),
          column(3, radioButtons(ns("research"), "Evidence:", choices = c("Research the web (sourced)" = "web", "Knowledge only (all judgment)" = "knowledge"), selected = "web")),
          column(3, radioButtons(ns("tree_mode"), "Hierarchies:", choices = c("Computed from scores + named" = "computed", "Authored by the Editing Tool" = "authored"), selected = "computed"))
        ),
        fluidRow(
          column(3, numericInput(ns("max_uses"), "Max web searches per column:", value = 4, min = 1, max = 8, step = 1)),
          column(3, checkboxInput(ns("verify"), "Fetch cited pages and check the quotes", value = TRUE)),
          column(6, p(style = "color:#7f8c8d;font-size:12px;margin-top:6px;",
                      "Web research makes one call per column (about 20-60 seconds each), so 8 columns can take several minutes. Web search must be enabled for your organisation in the Anthropic Console."))
        ),
        hr(),
        fluidRow(
          column(3, actionButton(ns("generate"), "Generate Matrix", icon = icon("magic"), class = "btn-primary btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("preview"), "Re-Parse & Draw", icon = icon("sync"), class = "btn-info btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("save"), "Save to BigQuery", icon = icon("cloud-upload-alt"), class = "btn-success btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("rename"), "Name Branches Again", icon = icon("tags"), class = "btn-default btn-lg", style = "width: 100%;"))
        ),
        br(),
        fluidRow(
          column(4, selectInput(ns("seed"), "Example:", choices = if (length(seeds) > 0) seeds else c("(none)" = ""))),
          column(2, br(), actionButton(ns("load_seed"), "Load Example", icon = icon("folder-open"), style = "width:100%;")),
          column(3, br(), downloadButton(ns("dl_json"), "Download JSON", style = "width:100%;")),
          column(3, br(), downloadButton(ns("dl_csv"), "Download Evidence CSV", style = "width:100%;"))
        ),
        htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      box(title = "Diagram", status = "info", solidHeader = TRUE, width = 12,
          export_controls_ui(ns, ns("export_target"), "market_matrix"),
          uiOutput(ns("diagram")))
    ),
    fluidRow(
      box(title = "Use This Matrix Elsewhere", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          fluidRow(column(4, actionButton(ns("to_flex"), "Matrix to Flex Table", icon = icon("table"), class = "btn-info", style = "width:100%;")),
                   column(8, p(style = "color:#7f8c8d;font-size:12px;", "Sends every row with its scores (and evidence status) to the Flex Table Bulk Import tab.")))
      )
    ),
    fluidRow(
      box(title = "Evidence Table", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          p(style = "color:#7f8c8d;font-size:12px;", "Every cell with its metric, value, date, quote, source and verification result."),
          DT::dataTableOutput(ns("evidence")))
    ),
    fluidRow(
      box(title = "Data (editable JSON)", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          p(style = "color:#7f8c8d;font-size:12px;", "Edit any score, label, class, quote or branch name, then click 'Re-Parse & Draw'. 'Save' stores exactly what is in this box; ",
            "if you loaded a saved matrix, saving adds a NEW VERSION of it. Edited scores change the computed hierarchies; branch names follow the members, so new groupings may need 'Name Branches Again'."),
          textAreaInput(ns("gen_text"), NULL, rows = 18, width = "100%", placeholder = "The matrix JSON will appear here."))
    ),
    fluidRow(
      box(title = "Saved Matrices", status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE,
          fluidRow(column(12, selectInput(ns("saved_id"), "Saved matrix:", choices = c("(none saved yet)" = ""), width = "100%"))),
          fluidRow(
            column(3, actionButton(ns("load_view"), "Show Diagram", icon = icon("eye"), class = "btn-primary", style = "width: 100%;")),
            column(3, actionButton(ns("load_edit"), "Load into Editor", icon = icon("edit"), class = "btn-info", style = "width: 100%;")),
            column(3, actionButton(ns("delete"), "Delete", icon = icon("trash"), class = "btn-danger", style = "width: 100%;")),
            column(3, actionButton(ns("refresh"), "Refresh List", icon = icon("sync"), class = "btn-default", style = "width: 100%;"))
          ))
    )
  )
}
