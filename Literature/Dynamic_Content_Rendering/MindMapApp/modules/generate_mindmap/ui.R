# modules/generate_mindmap/ui.R

generate_mindmap_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Mind Map Definition",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Define a new mind map. Claude decides the exact tree shape - the root node represents ",
          "your Topic, every other node has exactly one primary parent (forming a clean hierarchy), ",
          "and nodes may optionally carry extra 'cross-links' to any other node in the map, including ",
          "nodes higher up the hierarchy."),

        fluidRow(
          column(6,
                 category_domain_topic_dropdown_ui(ns)
          ),
          column(6,
                 textInput(ns("map_title"), "Map Title:",
                           placeholder = "e.g., Cell Structure Overview")
          )
        ),

        textAreaInput(ns("request_description"), "Describe what the mind map should cover: *",
                      rows = 5, width = "100%",
                      placeholder = paste0(
                        "e.g., Create a mind map explaining the structure of a eukaryotic cell. ",
                        "The root is the cell itself. Major organelles (nucleus, mitochondria, ",
                        "endoplasmic reticulum, Golgi apparatus, ribosomes) branch from the root, ",
                        "each with 1-2 sub-points on their specific function. Add a cross-link between ",
                        "mitochondria and the ER noting their shared role in calcium signaling.")),

        hr(),
        h4("Generation Settings"),

        fluidRow(
          column(4,
                 numericInput(ns("max_nodes"), "Target Total Nodes (approx., soft):",
                              value = 12, min = 3, max = 60, step = 1)
          ),
          column(4,
                 numericInput(ns("max_depth"), "Max Depth (levels below root):",
                              value = 3, min = 1, max = 8, step = 1)
          ),
          column(4,
                 numericInput(ns("max_root_children"), "Max Subnodes of Main Topic (hard cap):",
                              value = 6, min = 2, max = 15, step = 1)
          )
        ),
        fluidRow(
          column(4,
                 numericInput(ns("max_children_per_node"), "Max Children per Lower Node (hard cap):",
                              value = 5, min = 1, max = 10, step = 1)
          ),
          column(4,
                 radioButtons(ns("include_latex"), "Include LaTeX in node content?",
                              choices = c("No (plain text only)" = "no", "Yes" = "yes"),
                              selected = "no")
          ),
          column(4,
                 sliderInput(ns("words_per_node"), "Max Words per Node:",
                            min = 20, max = 200, value = 40, step = 20)
          )
        ),
        p(style = "color: #7f8c8d; font-size: 12px;",
          "The two 'hard cap' fields are enforced as strict limits in the prompt sent to Claude - ",
          "'Target Total Nodes' remains a soft guideline since the exact count still depends on what ",
          "the topic naturally calls for."),

        hr(),

        fluidRow(
          column(4,
                 actionButton(ns("generate"), "Generate Mind Map", icon = icon("magic"),
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
        title = "Generated Mind Map (raw delimited text - editable)",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Generating mind map...")),

        p(style = "color: #7f8c8d; font-size: 12px;",
          "This box is editable - fix a typo, delete a stray line, or tweak content by hand before ",
          "uploading. 'Parse & Upload Direct' and 'Download Text' always use whatever is CURRENTLY in ",
          "this box, not the original generation. Click 'Re-Parse & Update Preview' after editing to ",
          "refresh the Structure Preview below."),

        textAreaInput(ns("generated_text_edit"), NULL, rows = 18, width = "100%",
                      placeholder = "Generated mind map text will appear here after clicking 'Generate Mind Map' above."),

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
        p("A quick outline preview before uploading. Check the Visualize Mind Map tab after uploading ",
          "for the full interactive tree."),
        htmlOutput(ns("preview_html"))
      )
    )
  )
}
