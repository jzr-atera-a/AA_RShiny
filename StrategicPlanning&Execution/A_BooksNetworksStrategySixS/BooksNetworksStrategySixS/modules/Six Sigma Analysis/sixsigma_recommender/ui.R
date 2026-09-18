# modules/Six Sigma Analysis/sixsigma_recommender/ui.R

sixsigma_recommender_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Six Sigma Tool Recommender",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        div(class = "alert alert-info",
            tags$strong("How this works:"), " Claude sees the full catalog of all ", length(SIXSIGMA_ALL_TYPES),
            " available Six Sigma tools (with a short description of each) and picks the ones that genuinely ",
            "fit YOUR problem best - not just whichever tool is most famous. Click any recommended tool's name ",
            "below to jump straight to the Generate Diagram tab with it pre-selected."),

        textAreaInput(ns("problem_description"), "Describe the Six Sigma problem you need to solve or frame: *",
                      height = "140px",
                      placeholder = "e.g. Our injection moulding line has a 12% scrap rate and changeovers between product runs take over 90 minutes, cutting into available production time."),

        sliderInput(ns("num_recommendations"), "Number of tools to recommend:",
                   min = 1, max = 8, value = 3, step = 1, width = "100%"),

        actionButton(ns("recommend"), "Get Recommendations", icon = icon("magic"),
                    class = "btn-primary btn-lg", style = "width: 100%;"),

        br(), br(),
        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Analysing your problem against the full tool catalog...")),

        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Recommended Tools",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,

        DT::dataTableOutput(ns("recommendations_table"))
      )
    )
  )
}
