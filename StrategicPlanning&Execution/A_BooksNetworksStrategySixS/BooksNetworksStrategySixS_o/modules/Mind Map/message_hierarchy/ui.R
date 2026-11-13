# modules/message_hierarchy/ui.R
# Variation of the Mind Map tab: same table, category locked to "MessageHierarchy".

message_hierarchy_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Message Hierarchy Definition",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Design how to deliver a critical message in a talk or presentation. The Editing Tool builds a pyramid: ",
          "your core message at the top, the supporting points that prove it below, and evidence under each point. ",
          "Saved in the Mind Map table with the reserved category 'MessageHierarchy' (it does not appear in the regular Mind Map tabs)."),

        fluidRow(
          column(6, category_domain_topic_dropdown_ui(ns)),
          column(6, textInput(ns("map_title"), "Title of this talk / structure:",
                              placeholder = "e.g., Q3 Strategy Keynote"))
        ),

        textAreaInput(ns("core_message"), "Core message (the one thing the audience must remember): *",
                      rows = 2, width = "100%",
                      placeholder = "e.g., We must move to a subscription model this year."),
        textAreaInput(ns("outcome"), "Critical outcome wanted from the audience: *",
                      rows = 2, width = "100%",
                      placeholder = "e.g., The board approves the budget before the end of the meeting."),

        fluidRow(
          column(4, sliderInput(ns("n_points"), "Number of supporting points:",
                                min = 2, max = 8, value = 3, step = 1)),
          column(4, sliderInput(ns("evidence_per_point"), "Evidence items per point:",
                                min = 1, max = 4, value = 2, step = 1)),
          column(4, sliderInput(ns("words_per_node"), "Max words per node:",
                                min = 20, max = 120, value = 40, step = 20))
        ),

        fluidRow(
          column(6, textInput(ns("audience"), "Audience (optional):",
                              placeholder = "e.g., Board of directors, sceptical CFO")),
          column(6, textInput(ns("reference"), "Book or online resource to follow (optional):",
                              placeholder = "e.g., The Pyramid Principle by Barbara Minto, or a URL"))
        ),
        textAreaInput(ns("extra"), "Extra guidance (optional):", rows = 2, width = "100%"),

        hr(),
        fluidRow(
          column(4, actionButton(ns("generate"), "Generate Message Hierarchy", icon = icon("magic"),
                                 class = "btn-primary btn-lg", style = "width: 100%;")),
          column(4, actionButton(ns("parse_and_upload"), "Parse & Upload Direct", icon = icon("cloud-upload-alt"),
                                 class = "btn-success btn-lg", style = "width: 100%;")),
          column(4, downloadButton(ns("download"), "Download Text", class = "btn-warning", style = "width: 100%;"))
        )
      )
    ),

    fluidRow(
      box(
        title = "Generated Structure (raw delimited text - editable)",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,

        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Generating message hierarchy...")),

        textAreaInput(ns("generated_text_edit"), NULL, rows = 14, width = "100%",
                      placeholder = "Generated text will appear here. You can edit it before uploading."),
        actionButton(ns("reparse_preview"), "Re-Parse & Update Preview", icon = icon("sync"),
                     class = "btn-info", style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("gen_status")),
        htmlOutput(ns("preview_html"))
      )
    ),

    fluidRow(
      box(
        title = "View a Saved Message Hierarchy",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        fluidRow(
          column(3, selectInput(ns("viz_category"), "Category: *", choices = NULL)),
          column(3, selectInput(ns("viz_domain"), "Domain: *", choices = NULL)),
          column(3, selectInput(ns("viz_topic"), "Topic: *", choices = NULL)),
          column(3, selectInput(ns("viz_map_id"), "Version: *", choices = NULL))
        ),
        fluidRow(
          column(6, checkboxInput(ns("show_cross_links"), "Show call-back links (dashed orange)", value = TRUE)),
          column(6, actionButton(ns("load_map"), "Load Hierarchy", class = "btn-success btn-lg",
                                 icon = icon("project-diagram"), style = "width: 100%;"))
        ),
        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Message Hierarchy",
        status = "success",
        solidHeader = TRUE,
        width = 8,
        collapsible = TRUE,
        p(style = "color: #7f8c8d; font-size: 12px;",
          "The core message is the root on the left; each branch is a supporting point, then its evidence. ",
          "Click a circle to collapse/expand, click a label to read it on the right."),
        export_controls_ui(ns, ns("export_target"), "message_hierarchy"),
        uiOutput(ns("network"))
      ),
      box(
        title = "Selected Node",
        status = "info",
        solidHeader = TRUE,
        width = 4,
        collapsible = TRUE,
        htmlOutput(ns("node_detail"))
      )
    )
  )
}
