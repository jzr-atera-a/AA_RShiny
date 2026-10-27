# modules/Technical Designs/techdesign_about/ui.R

techdesign_about_ui <- function(id) {
  ns <- NS(id)
  col_tbl <- function(rows) tags$table(class = "table table-striped",
    tags$thead(tags$tr(tags$th("Column"), tags$th("Purpose"))),
    tags$tbody(lapply(rows, function(r) tags$tr(tags$td(tags$code(r[1])), tags$td(r[2])))))
  tagList(
    fluidRow(
      box(title = "About Technical Designs", status = "primary", solidHeader = TRUE, width = 12,
          h4("What this group does"),
          p("Documents architectures and design patterns as data. The Editing Tool fills in entities, relationships, flow steps, trade-offs and references; ",
            "the app computes the layout and draws a swimlane architecture diagram (ML / GenAI and Data Processing) or a UML class diagram (Software Patterns). ",
            "Nothing about positions is ever asked from the Editing Tool."),
          h4("Subtabs"),
          tags$ul(
            tags$li(tags$strong("Design Guide"), " - reference cards and offline example diagrams for the 12 starter designs."),
            tags$li(tags$strong("Design Recommender"), " - describe a problem, the Editing Tool ranks designs across all groups."),
            tags$li(tags$strong("ML / GenAI, Data Processing, Software Patterns"), " - generate, edit text, redraw, save, export."),
            tags$li(tags$strong("Bulk Import Designs"), " - paste many designs or load the starter library."),
            tags$li(tags$strong("Design Library"), " - browse everything, version history, restore, delete."),
            tags$li(tags$strong("Design Editor"), " - table-based editing with live redraw and the Editing Tool."),
            tags$li(tags$strong("Compare Designs"), " - two designs side by side."),
            tags$li(tags$strong("Market Matrix"), " - a dual-hierarchy relevance matrix (for example markets vs drivers). Every score is researched on the web with a quote and a source URL, the cited pages are fetched to check the quotes, both hierarchies are computed and named, and each version is stored in the same Technical Designs table.")),
            tags$li(tags$strong("Infographic Studio"), " - rich infographics from a topic: a long poster or a deck of 1-8 slides (16:9, 4:3, 1:1, 4:5, 9:16, A4). Figures are researched with quotes and source URLs, the app draws everything itself, and you download PowerPoint, PDF, HTML, JPEG, PNG or GIF. Each version is stored in the same Technical Designs table."),
          h4("Table: technical_designs"),
          p("ONE row per design VERSION. Saves only append rows; the newest row per ", tags$code("design_id"), " is the current design, and ",
            tags$code("change_type = delete"), " hides it. Adding new architectures later needs no schema change: components, connections, steps, trade-offs and references are stored as JSON columns."),
          col_tbl(list(
            c("id / created_at", "Row id and timestamp (assigned on insert)"),
            c("design_id", "Stable id shared by all versions of one design"),
            c("design_group / design_type", "ml_genai, data_processing, software_patterns / e.g. rag, lambda_architecture, observer_pattern"),
            c("name / variant / title / summary", "Display fields"),
            c("when_to_use / when_not_to_use", "Guidance text"),
            c("complexity_level / tags", "Low, Medium, High / comma-separated tags"),
            c("diagram_kind", "layered (swimlane) or class (UML)"),
            c("components_json", "Boxes: id, label, lane, kind, description, technologies, attributes, methods"),
            c("connections_json", "Arrows: from, to, label, type"),
            c("flow_steps_json", "Numbered walkthrough used by the step player"),
            c("tradeoffs_json / references_json", "Pros, cons, risks, costs, scaling / books, papers, links"),
            c("extras_json / schema_version", "Reserved for future fields / format version"),
            c("change_type / created_by", "create, update, delete / who or what wrote the row"))),
          h4("Text format"),
          p("Header lines, then blocks. One value per line. Do not use square brackets, double quotes, backslashes or the dollar sign. ", tags$code("N/A"), " means empty."),
          tags$pre(paste(c(
            "design_id: my_rag_v1            (optional, stable id)",
            "design_group: ml_genai",
            "design_type: rag",
            "title: Retrieval-Augmented Generation",
            "variant: Hybrid search",
            "summary: ...", "when_to_use: ...", "when_not_to_use: ...",
            "complexity: Medium", "tags: rag, llm", "",
            "@component", "id: C1", "label: User", "lane: Client", "kind: actor", "description: ...", "technologies: N/A", "",
            "@connection", "from: C1", "to: C2", "label: question", "type: data", "",
            "@step", "order: 1", "text: ...", "components: C1,C2", "",
            "@tradeoff", "kind: pro", "text: ...", "",
            "@reference", "title: ...", "author: ...", "url: N/A"), collapse = "\n")),
          p("Class diagrams use ", tags$code("attributes"), " and ", tags$code("methods"), " (semicolon separated) instead of technologies, and lanes are tiers (rows)."),
          tags$ul(
            tags$li(tags$strong("Node kinds (swimlane): "), paste(TD_NODE_KINDS_LAYERED, collapse = ", ")),
            tags$li(tags$strong("Node kinds (class): "), paste(TD_NODE_KINDS_CLASS, collapse = ", ")),
            tags$li(tags$strong("Edge types (swimlane): "), paste(TD_EDGE_TYPES_LAYERED, collapse = ", ")),
            tags$li(tags$strong("Edge types (class): "), paste(TD_EDGE_TYPES_CLASS, collapse = ", "))),
          h4("Multiple designs in one paste"),
          p("Separate designs with a line containing only ", tags$code("====="), ". Designs with a ", tags$code("design_id"), " that already exists are skipped on import."),
          h4("How to add a new architecture or pattern to the dropdowns"),
          p("Open ", tags$code("R/utils_techdesign_catalog.R"), " and add an entry under the right group in ", tags$code("TD_CATALOG"),
            ": an id, a label and a short structure guidance paragraph (suggested lanes and components). Optionally add a guide entry in ",
            tags$code("TD_INFO"), " (", tags$code("R/utils_techdesign_actions.R"), ") and a starter text file in ", tags$code("seed/techdesign/<design_type>.txt"),
            ". No database change is needed. Without editing code you can also choose '+ Custom design...' in any generate subtab."),
          h4("Handoffs"),
          tags$ul(
            tags$li("Create Mind Map: inserts a mind map (category 'Technical Designs'; root = design, level 1 = lanes, level 2 = components, cross-links from connections)."),
            tags$li("Flex Table: sends components, trade-offs or connections as a comparison table into the Flex Table Bulk Import tab."),
            tags$li("Bulk Import: sends generated text to this group's Bulk Import for batch upload.")),
          h4("Shared connections"),
          p("Uses the single Editing Tool API and BigQuery connection from API Configuration; the table is created automatically on BigQuery login.")
      )
    )
  )
}
