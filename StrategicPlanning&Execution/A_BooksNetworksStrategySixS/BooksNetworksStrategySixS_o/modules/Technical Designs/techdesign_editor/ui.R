# modules/Technical Designs/techdesign_editor/ui.R

techdesign_editor_ui <- function(id) {
  ns <- NS(id)
  tbl_box <- function(key, title, extra = NULL) {
    box(title = title, status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = !(key %in% c("components", "connections")),
        DT::dataTableOutput(ns(paste0("tbl_", key))),
        br(),
        actionButton(ns(paste0("add_", key)), "Add row", icon = icon("plus"), class = "btn-success btn-sm"),
        actionButton(ns(paste0("del_", key)), "Delete selected row", icon = icon("minus"), class = "btn-danger btn-sm"),
        extra)
  }
  tagList(
    fluidRow(
      box(title = "Design Editor", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "alert alert-info",
              "Load a design, edit it in the tables (double-click a cell), and watch the diagram redraw live. Use 'Modify with The Editing Tool' for bigger changes. ",
              "Save as a NEW VERSION of the same design or as a separate COPY."),
          fluidRow(
            column(5, selectInput(ns("source"), "Load a design:", choices = c("Loading..." = ""))),
            column(2, br(), actionButton(ns("load"), "Load", icon = icon("folder-open"), class = "btn-primary", style = "width:100%;")),
            column(3, selectInput(ns("blank_group"), "Or start blank in:", choices = setNames(TD_GROUPS, unlist(TD_GROUP_LABELS[TD_GROUPS])))),
            column(2, br(), actionButton(ns("blank"), "New blank", icon = icon("file"), class = "btn-default", style = "width:100%;"))
          ),
          htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      box(title = "Metadata", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          fluidRow(
            column(4, textInput(ns("m_title"), "Title:")),
            column(4, textInput(ns("m_variant"), "Variant:")),
            column(2, selectInput(ns("m_complexity"), "Complexity:", choices = c("Low", "Medium", "High"), selected = "Medium")),
            column(2, textInput(ns("m_type"), "Design type id:"))
          ),
          textAreaInput(ns("m_summary"), "Summary:", rows = 3, width = "100%"),
          fluidRow(
            column(6, textAreaInput(ns("m_when"), "When to use:", rows = 2, width = "100%")),
            column(6, textAreaInput(ns("m_when_not"), "When NOT to use:", rows = 2, width = "100%"))
          ),
          textInput(ns("m_tags"), "Tags (comma separated):", width = "100%"))
    ),
    fluidRow(
      box(title = "Diagram (live)", status = "success", solidHeader = TRUE, width = 12,
          export_controls_ui(ns, ns("export_target"), "technical_design"),
          uiOutput(ns("diagram")))
    ),
    fluidRow(
      box(title = "Modify This Design with The Editing Tool", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE,
          textAreaInput(ns("instruction"), NULL, rows = 3, width = "100%",
                        placeholder = "e.g., Add a human review queue before answers are sent, and add a caching layer in front of the retriever."),
          actionButton(ns("modify"), "Apply with The Editing Tool", icon = icon("robot"), class = "btn-warning"),
          actionButton(ns("undo"), "Undo last Editing Tool change", icon = icon("undo"), class = "btn-default"))
    ),
    fluidRow(tbl_box("components", "Components (boxes)")),
    fluidRow(tbl_box("connections", "Connections (arrows)")),
    fluidRow(tbl_box("steps", "Flow steps")),
    fluidRow(tbl_box("tradeoffs", "Trade-offs (kind: pro, con, risk, cost, scaling)")),
    fluidRow(tbl_box("references", "References")),
    fluidRow(
      box(title = "Save", status = "success", solidHeader = TRUE, width = 12,
          fluidRow(
            column(4, actionButton(ns("save_version"), "Save as New Version", icon = icon("save"), class = "btn-success btn-lg", style = "width:100%;")),
            column(4, actionButton(ns("save_copy"), "Save as Copy", icon = icon("copy"), class = "btn-info btn-lg", style = "width:100%;")),
            column(4, downloadButton(ns("download"), "Download Text", class = "btn-warning btn-lg", style = "width:100%;"))
          ),
          br(),
          td_actions_ui(ns))
    )
  )
}
