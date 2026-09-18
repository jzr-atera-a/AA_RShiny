# modules/Strategic Analysis/diagram_recommender/ui.R

diagram_recommender_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Strategy Tool Recommender",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        div(class = "alert alert-info",
            tags$strong("How this works:"), " Claude sees the full catalog of all ", length(DIAGRAM_TYPES),
            " available frameworks (with a short description of each) and picks the ones that genuinely fit ",
            "YOUR problem best - not just the most famous ones. Click any recommended tool's name below to jump ",
            "straight to the Generate Diagram tab with it pre-selected."),

        textAreaInput(ns("problem_description"), "Describe the strategic problem you need to solve or frame: *",
                      height = "140px",
                      placeholder = "e.g. We're a mid-size UK retailer deciding whether to expand into continental Europe over the next 18 months, but we're uncertain whether our brand and operations model will translate, and we have limited capital to fund a misstep."),

        sliderInput(ns("num_recommendations"), "Number of frameworks to recommend:",
                   min = 1, max = 8, value = 3, step = 1, width = "100%"),

        actionButton(ns("recommend"), "Get Recommendations", icon = icon("magic"),
                    class = "btn-primary btn-lg", style = "width: 100%;"),

        br(), br(),
        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Analysing your problem against the full framework catalog...")),

        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Recommended Frameworks",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,

        DT::dataTableOutput(ns("recommendations_table"))
      )
    )
  )
}
