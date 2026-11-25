# modules/Strategic Analysis/diagram_bulk_import.R
# ---- module --------------------------------------------------------------------------------------
# id:           diagram_bulk_import
# name:         Diagram Bulk Import
# label:        Bulk Import
# icon:         file-import
# description:  Paste or receive-from-Generate diagram component text, parse, preview, upload
# packages:     shiny, shinydashboard, DT
# api_optional: bigquery
# --------------------------------------------------------------------------------------------------

# The tab itself is shared with other suites: see component_import_ui / component_import_server in R/utils_suite_tabs.R.

DIAGRAM_BULK_IMPORT_CFG <- list(
  title = "Bulk Import Diagram Components to BigQuery",
  intro = p("Paste text produced by the Generate Diagram tab (or written by hand in the same format). ",
            "Parse it first to preview the components, then upload. The framework, diagram group, category, ",
            "domain, topic, and title are read directly from the pasted text's metadata lines - no need to ",
            "re-select them here."),
  format_help = list(
    tags$li("First 6 lines (metadata, no field names): [framework id, e.g. swot]", tags$br(),
            "[diagram group, e.g. situational_analysis]", tags$br(), "[category]", tags$br(),
            "[domain]", tags$br(), "[topic]", tags$br(), "[title]"),
    tags$li("Then one blank line, then one block per component:"),
    tags$li("[component_type]: shape_rectangle"),
    tags$li("[layout_role]: grid_cell"),
    tags$li("[grid_row]: 1 [grid_col]: 1 [sequence_order]: 1"),
    tags$li("[label_text]: ...  [sub_text]: ...  [items_packed]: item1", HTML("&nbsp;|||DIAGITEM|||&nbsp;"), "item2"),
    tags$li("See the Tool Guide tab for the ~27 valid framework ids and their diagram groups.")
  ),
  placeholder = "[swot]\n[situational_analysis]\n[Business]\n[Trading Hedge Fund Startup]\n[Market Entry]\n[SWOT: Trading Hedge Fund Analysis]\n\n[component_type]: shape_rectangle\n[layout_role]: grid_cell\n[grid_row]: 1\n[grid_col]: 1\n...",
  pending = "pending_bulk_text_diagram",
  parse = function(text) parse_diagram_text(text, diagram_id = "", is_template = FALSE, created_by = "manual_bulk_import"),
  new_id = generate_new_diagram_id,
  insert = "bq_insert_diagram",
  parsed_info = " Successfully parsed %d component row(s) for '%s' (Framework: %s [%s] | Category: %s | Domain: %s | Topic: %s)"
)

diagram_bulk_import_ui <- function(id) component_import_ui(id, DIAGRAM_BULK_IMPORT_CFG)
diagram_bulk_import_server <- function(id, api_manager) component_import_server(id, api_manager, DIAGRAM_BULK_IMPORT_CFG)
