# modules/Technical Designs/techdesign_guide/ui.R

techdesign_guide_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(id = ns("example_box"),
        fluidRow(
          box(title = "Example Diagram (click 'Show example' on any design below)", status = "info", solidHeader = TRUE, width = 12,
              export_controls_ui(ns, ns("export_target"), "technical_design_example"),
              uiOutput(ns("example"))))),
    fluidRow(
      box(title = "Design Guide", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "alert alert-info",
              "A quick reference for the starter designs: what each one is, when it fits, what to watch out for. ",
              "'Show example' draws a complete example diagram from the bundled starter library (works offline, no the Editing Tool call). ",
              "'Generate this' jumps to the right subtab with the design preselected."),
          selectInput(ns("group_filter"), "Show:", choices = c("All groups" = "", setNames(TD_GROUPS, unlist(TD_GROUP_LABELS[TD_GROUPS]))), width = "300px"),
          uiOutput(ns("cards"))
      )
    )
  )
}
