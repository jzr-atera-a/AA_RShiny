# modules/generate_kg/ui.R

generate_kg_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Knowledge Graph Definition",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Define a new knowledge graph. Unlike a mind map, there is no root and no hierarchy - Claude ",
          "generates a set of typed ENTITIES (e.g. Person, Organization, Concept) connected by typed, ",
          "directed RELATIONSHIPS (subject-predicate-object triples). Cycles and many-to-many connections ",
          "are normal and expected."),

        fluidRow(
          column(6,
                 category_domain_topic_dropdown_ui(ns)
          ),
          column(6,
                 textInput(ns("graph_title"), "Graph Title:",
                           placeholder = "e.g., Physics Nobel Laureates Network")
          )
        ),

        textAreaInput(ns("request_description"), "Describe what the knowledge graph should cover: *",
                      rows = 5, width = "100%",
                      placeholder = paste0(
                        "e.g., Build a knowledge graph of the key figures, institutions, and discoveries ",
                        "in the early history of radioactivity research. Include entities for the major ",
                        "scientists, the awards they won, the institutions they worked at, and the key ",
                        "discoveries/concepts, with relationships showing who influenced whom, who won ",
                        "what, and who worked where.")),

        hr(),
        h4("Generation Settings"),

        fluidRow(
          column(4,
                 numericInput(ns("max_entities"), "Target Total Entities (approx., soft):",
                              value = 15, min = 2, max = 60, step = 1)
          ),
          column(4,
                 numericInput(ns("max_relationships"), "Target Total Relationships (approx., soft):",
                              value = 20, min = 1, max = 100, step = 1)
          ),
          column(4,
                 numericInput(ns("max_relationships_per_entity"), "Max Relationships per Entity (hard cap):",
                              value = 8, min = 1, max = 20, step = 1)
          )
        ),
        fluidRow(
          column(4,
                 sliderInput(ns("words_per_entity"), "Max Words per Entity Description:",
                            min = 20, max = 200, value = 30, step = 10)
          ),
          column(4,
                 sliderInput(ns("words_per_relationship"), "Max Words per Relationship Description:",
                            min = 20, max = 200, value = 25, step = 10)
          ),
          column(4,
                 radioButtons(ns("include_latex"), "Include LaTeX in descriptions?",
                              choices = c("No (plain text only)" = "no", "Yes" = "yes"),
                              selected = "no")
          )
        ),
        p(style = "color: #7f8c8d; font-size: 12px;",
          "'Max Relationships per Entity' is enforced as a strict limit in the prompt sent to Claude - ",
          "the two 'Target Total' fields remain soft guidelines since the exact counts still depend on ",
          "what the topic naturally calls for."),

        hr(),

        fluidRow(
          column(4,
                 actionButton(ns("generate"), "Generate Knowledge Graph", icon = icon("magic"),
                              class = "btn-primary btn-lg", style = "width: 100%;")
          ),
          column(4,
                 actionButton(ns("parse_and_upload"), "Parse & Upload Direct", icon = icon("cloud-upload-alt"),
                              class = "btn-success btn-lg", style = "width: 100%;")
          ),
          column(4,
                 downloadButton(ns("download"), "Download Text", class = "btn-warning", style = "width: 100%;")
          )
        )
      )
    ),

    fluidRow(
      box(
        title = "Generated Knowledge Graph (raw text - editable)",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Generating knowledge graph...")),

        p(style = "color: #7f8c8d; font-size: 12px;",
          "This box is editable - fix a typo, delete a stray block, or tweak content by hand before ",
          "uploading. 'Parse & Upload Direct' and 'Download Text' always use whatever is CURRENTLY in ",
          "this box. Click 'Re-Parse & Update Preview' after editing to refresh the preview below."),

        textAreaInput(ns("generated_text_edit"), NULL, rows = 18, width = "100%",
                      placeholder = "Generated knowledge graph text will appear here after clicking 'Generate Knowledge Graph' above."),

        actionButton(ns("reparse_preview"), "Re-Parse & Update Preview", icon = icon("sync"),
                    class = "btn-info", style = "width: 100%;"),

        br(), br(),
        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Structure Preview",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        p("A quick summary before uploading. Check the Visualize tabs after uploading for the full ",
          "interactive graph."),
        htmlOutput(ns("preview_html"))
      )
    )
  )
}
