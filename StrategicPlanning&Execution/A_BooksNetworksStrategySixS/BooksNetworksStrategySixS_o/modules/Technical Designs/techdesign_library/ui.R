# modules/Technical Designs/techdesign_library/ui.R

techdesign_library_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Design Library", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, selectInput(ns("group"), "Group:", choices = c("All groups" = "", setNames(TD_GROUPS, unlist(TD_GROUP_LABELS[TD_GROUPS]))))),
            column(5, textInput(ns("search"), "Search title / tags / type:", placeholder = "e.g., streaming")),
            column(4, br(), actionButton(ns("refresh"), "Refresh", icon = icon("sync"), class = "btn-default"))
          ),
          DT::dataTableOutput(ns("list")),
          br(),
          fluidRow(
            column(3, actionButton(ns("show"), "Show Diagram", icon = icon("eye"), class = "btn-primary", style = "width:100%;")),
            column(3, actionButton(ns("open_editor"), "Open in Editor", icon = icon("edit"), class = "btn-info", style = "width:100%;")),
            column(3, actionButton(ns("delete"), "Delete", icon = icon("trash"), class = "btn-danger", style = "width:100%;")),
            column(3, actionButton(ns("generate_similar"), "Generate Another", icon = icon("magic"), class = "btn-default", style = "width:100%;"))
          ),
          htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      box(title = "Diagram", status = "info", solidHeader = TRUE, width = 12,
          export_controls_ui(ns, ns("export_target"), "technical_design"),
          uiOutput(ns("diagram")))
    ),
    fluidRow(
      box(title = "Use This Design Elsewhere", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          td_actions_ui(ns))
    ),
    fluidRow(
      box(title = "Version History", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE,
          p(style = "color:#7f8c8d;font-size:12px;", "Every save appends a version; nothing is overwritten. Select a version to view it, or restore it as the newest version."),
          DT::dataTableOutput(ns("versions")),
          br(),
          fluidRow(
            column(3, actionButton(ns("view_version"), "View This Version", icon = icon("eye"), class = "btn-primary", style = "width:100%;")),
            column(3, actionButton(ns("restore_version"), "Restore as Newest", icon = icon("undo"), class = "btn-warning", style = "width:100%;"))
          ))
    )
  )
}
