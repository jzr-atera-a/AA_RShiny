# modules/Six Sigma Analysis/sixsigma_bulk_import.R
# ---- module --------------------------------------------------------------------------------------
# id:           sixsigma_bulk_import
# name:         Six Sigma Bulk Import
# label:        Bulk Import
# icon:         file-import
# description:  Paste or receive-from-Generate Six Sigma diagram component text, parse, preview, upload
# packages:     shiny, shinydashboard, DT
# api_optional: bigquery
# --------------------------------------------------------------------------------------------------

# The tab itself is shared with other suites: see component_import_ui / component_import_server in R/utils_suite_tabs.R.

SIXSIGMA_BULK_IMPORT_CFG <- list(
  title = "Bulk Import Six Sigma Diagram Components to BigQuery",
  intro = p("Paste text produced by the Generate Diagram tab (or written by hand in the same format). ",
            "Parse it first to preview the components, then upload. Diagram type, diagram group, category, ",
            "domain, topic, and title are read directly from the pasted text's metadata lines - no need to ",
            "re-select them here."),
  format_help = list(
    tags$li("First 6 lines (metadata, no field names): [diagram_type]", tags$br(),
            "[diagram_group]", tags$br(), "[category]", tags$br(), "[domain]", tags$br(),
            "[topic]", tags$br(), "[title]"),
    tags$li("Then one blank line, then one block per component:"),
    tags$li("[component_type]: shape_rectangle"),
    tags$li("[layout_role]: grid_cell"),
    tags$li("[grid_row]: 1 [grid_col]: 1 [sequence_order]: 1"),
    tags$li("[label_text]: ...  [sub_text]: ...  [items_packed]: item1", HTML("&nbsp;|||SSITEM|||&nbsp;"), "item2")
  ),
  placeholder = "[fishbone]\n[analyse]\n[Business]\n[Manufacturing Quality]\n[Inconsistent Fill Weight]\n[Cereal Box Weight Fishbone]\n\n[component_type]: effect_box\n[layout_role]: title\n[label_text]: Inconsistent fill weight\n...",
  pending = "pending_bulk_text_sixsigma",
  parse = function(text) parse_sixsigma_text(text, diagram_id = "", is_template = FALSE, created_by = "manual_bulk_import"),
  new_id = generate_new_sixsigma_id,
  insert = "bq_insert_sixsigma",
  parsed_info = " Successfully parsed %d component row(s) for '%s' (Type: %s | Group: %s | Category: %s | Domain: %s | Topic: %s)"
)

sixsigma_bulk_import_ui <- function(id) component_import_ui(id, SIXSIGMA_BULK_IMPORT_CFG)
sixsigma_bulk_import_server <- function(id, api_manager) component_import_server(id, api_manager, SIXSIGMA_BULK_IMPORT_CFG)
