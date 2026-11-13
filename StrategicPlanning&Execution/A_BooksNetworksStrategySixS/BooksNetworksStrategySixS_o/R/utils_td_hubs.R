# R/utils_td_hubs.R
# ============================================================
# Technical Designs: related tabs are shown as ONE sidebar tab with horizontal sub-tabs ("hubs").
# The existing modules keep their ids, UI and server code: a hub only places their UI inside a tabsetPanel.
#   * create_ui (global.R) skips the children as separate sidebar tabs and the hub draws them;
#   * create_server builds a hub's children together with the hub (see global.R);
#   * td_nav() jumps to a child: it selects the hub in the sidebar and the sub-tab inside it.
# ============================================================

TD_HUBS <- list(
  td_hub_arch = list(title = "Architectures and Design Patterns", icon = "sitemap",
    blurb = "ML / GenAI and data processing architectures and software design patterns: learn them in the guide, get a recommendation for your problem, then generate and draw the one you need.",
    children = list(
      list(id = "techdesign_guide", label = "Design Guide", icon = "book"),
      list(id = "techdesign_recommender", label = "Design Recommender", icon = "lightbulb"),
      list(id = "techdesign_ml", label = "ML / GenAI", icon = "brain"),
      list(id = "techdesign_data", label = "Data Processing", icon = "database"),
      list(id = "techdesign_patterns", label = "Software Patterns", icon = "puzzle-piece"))),
  td_hub_algo = list(title = "Algorithms (LeetCode / Meta interview)", icon = "project-diagram",
    blurb = "Start with the handbook of the 23 LeetCode pattern groups, then paste your question in the selector: the Editing Tool recommends the pattern and draws it as an interactive network you can save and download.",
    children = list(
      list(id = "techdesign_algo_handbook", label = "Intro and Handbook", icon = "book-open"),
      list(id = "techdesign_algorithm", label = "Select, Generate and Visualise", icon = "magic"))),
  td_hub_social = list(title = "Social Dynamics Algorithms", icon = "users",
    blurb = "The top 36 social dynamics algorithms for influencing people, romantic partners, business partners, investors and collaborators: overview, handbook with scenarios and Harvard references, and one diagram tab per audience.",
    children = list(
      list(id = "techdesign_soc_guide", label = "Top 36 Overview", icon = "list-ol"),
      list(id = "techdesign_soc_handbook", label = "Handbook", icon = "book-open"),
      list(id = "techdesign_soc_influence", label = "Influencing", icon = "bullhorn"),
      list(id = "techdesign_soc_romantic", label = "Romantic", icon = "heart"),
      list(id = "techdesign_soc_business", label = "Business", icon = "handshake"),
      list(id = "techdesign_soc_investors", label = "Investors", icon = "chart-line"),
      list(id = "techdesign_soc_collab", label = "Collaborators", icon = "users"))),
  td_hub_manage = list(title = "Library and Editing", icon = "layer-group",
    blurb = "Everything saved in the Technical Designs table: browse the library, edit a design, compare two designs side by side, or paste designs in bulk.",
    children = list(
      list(id = "techdesign_library", label = "Design Library", icon = "layer-group"),
      list(id = "techdesign_editor", label = "Design Editor", icon = "edit"),
      list(id = "techdesign_compare", label = "Compare Designs", icon = "columns"),
      list(id = "techdesign_bulk_import", label = "Bulk Import", icon = "file-import"))),
  td_hub_studio = list(title = "Studios", icon = "palette",
    blurb = "Presentation tools: the Market Matrix and the Infographic Studio turn designs and evidence into visual one-pagers and slides.",
    children = list(
      list(id = "techdesign_matrix", label = "Market Matrix", icon = "table"),
      list(id = "techdesign_infographic", label = "Infographic Studio", icon = "palette")))
)

# ---- Hubs of the other suites (same pattern; titles show the suite) ----
TD_HUBS_MORE <- list(
  bk_hub_create = list(title = "Book Summary: Create and Add", icon = "magic",
    blurb = "Make book summaries with the Editing Tool, paste many at once, or type one in by hand.",
    children = list(
      list(id = "generate_summary", label = "Generate Summary", icon = "magic"),
      list(id = "books_bulk_import", label = "Bulk Import", icon = "file-import"),
      list(id = "add_single", label = "Add Single", icon = "plus"))),
  bk_hub_explore = list(title = "Book Summary: Browse and Visualise", icon = "chart-bar",
    blurb = "Browse and download the stored summaries, or see them as charts.",
    children = list(
      list(id = "books_browse", label = "Browse and Download", icon = "table"),
      list(id = "visualizations", label = "Visualisations", icon = "chart-bar"))),
  fx_hub_create = list(title = "Flex Table: Create and Add", icon = "magic",
    blurb = "Generate comparison tables with the Editing Tool, import them in bulk, or add a single row.",
    children = list(
      list(id = "generate_table", label = "Generate Table", icon = "magic"),
      list(id = "bulk_import", label = "Bulk Import", icon = "file-import"),
      list(id = "add_entry", label = "Add Entry", icon = "plus"))),
  fx_hub_explore = list(title = "Flex Table: View and Browse", icon = "table",
    blurb = "Render stored tables as comparison grids, or browse and download the raw rows.",
    children = list(
      list(id = "table_viewer", label = "Table Viewer", icon = "table"),
      list(id = "flex_table_browse", label = "Browse and Download", icon = "list"))),
  mm_hub_create = list(title = "Mind Map: Create and Edit", icon = "magic",
    blurb = "Generate mind maps and message hierarchies with the Editing Tool, then edit a saved map.",
    children = list(
      list(id = "generate_mindmap", label = "Generate Mind Map", icon = "magic"),
      list(id = "message_hierarchy", label = "Message Hierarchy", icon = "sitemap"),
      list(id = "edit_mindmap", label = "Edit Mind Map", icon = "edit"))),
  mm_hub_explore = list(title = "Mind Map: Visualise and Browse", icon = "share-nodes",
    blurb = "Draw a stored mind map, or browse and download the raw rows.",
    children = list(
      list(id = "visualize_mindmap", label = "Visualise", icon = "share-nodes"),
      list(id = "mindmap_browse", label = "Browse and Download", icon = "table"))),
  kg_hub_create = list(title = "Knowledge Graph: Create and Edit", icon = "magic",
    blurb = "Generate a knowledge graph with the Editing Tool, then edit a saved graph.",
    children = list(
      list(id = "generate_kg", label = "Generate Graph", icon = "magic"),
      list(id = "edit_kg", label = "Edit Graph", icon = "edit"))),
  kg_hub_explore = list(title = "Knowledge Graph: Visualise and Browse", icon = "diagram-project",
    blurb = "Explore a graph as a D3 force layout or a Cytoscape network, or browse the stored rows.",
    children = list(
      list(id = "visualize_kg_d3", label = "D3 Force Graph", icon = "diagram-project"),
      list(id = "visualize_kg_cytoscape", label = "Cytoscape Graph", icon = "project-diagram"),
      list(id = "kg_browse", label = "Browse and Download", icon = "table"))),
  sk_hub_create = list(title = "Sankey Graph: Create and Import", icon = "magic",
    blurb = "Generate a Sankey flow with the Editing Tool, or paste many in bulk.",
    children = list(
      list(id = "generate_sankey", label = "Generate Sankey", icon = "magic"),
      list(id = "sankey_bulk_import", label = "Bulk Import", icon = "file-import"))),
  sk_hub_explore = list(title = "Sankey Graph: Visualise and Browse", icon = "water",
    blurb = "Draw stored flows as Sankey diagrams, or browse and download the raw rows.",
    children = list(
      list(id = "sankey_visualizations", label = "Visualisations", icon = "water"),
      list(id = "sankey_browse", label = "Browse and Download", icon = "table"))),
  sa_hub_learn = list(title = "Strategic Analysis: Learn and Choose", icon = "lightbulb",
    blurb = "Read the tool guide, then let the recommender pick the strategic diagram that fits your question.",
    children = list(
      list(id = "diagram_tool_guide", label = "Tool Guide", icon = "book"),
      list(id = "diagram_recommender", label = "Diagram Recommender", icon = "lightbulb"))),
  sa_hub_create = list(title = "Strategic Analysis: Create and Add", icon = "magic",
    blurb = "Generate a strategic diagram with the Editing Tool, import many at once, or add one by hand.",
    children = list(
      list(id = "generate_diagram", label = "Generate Diagram", icon = "magic"),
      list(id = "diagram_bulk_import", label = "Bulk Import", icon = "file-import"),
      list(id = "diagram_add_single", label = "Add Single", icon = "plus"))),
  sa_hub_explore = list(title = "Strategic Analysis: Browse and Visualise", icon = "chess",
    blurb = "Browse and download the stored diagrams, or see them rendered.",
    children = list(
      list(id = "diagram_browse", label = "Browse and Download", icon = "table"),
      list(id = "diagram_visualizations", label = "Visualisations", icon = "chess"))),
  ss_hub_learn = list(title = "Six Sigma Analysis: Learn and Choose", icon = "lightbulb",
    blurb = "Read the tool guide, then let the recommender pick the Six Sigma tool that fits your problem.",
    children = list(
      list(id = "sixsigma_tool_guide", label = "Tool Guide", icon = "book"),
      list(id = "sixsigma_recommender", label = "Tool Recommender", icon = "lightbulb"))),
  ss_hub_create = list(title = "Six Sigma Analysis: Create and Add", icon = "magic",
    blurb = "Generate a Six Sigma tool with the Editing Tool, import many at once, or add one by hand.",
    children = list(
      list(id = "generate_sixsigma", label = "Generate Tool", icon = "magic"),
      list(id = "sixsigma_bulk_import", label = "Bulk Import", icon = "file-import"),
      list(id = "sixsigma_add_single", label = "Add Single", icon = "plus"))),
  ss_hub_explore = list(title = "Six Sigma Analysis: Browse and Visualise", icon = "microscope",
    blurb = "Browse and download the stored tools, or see them rendered.",
    children = list(
      list(id = "sixsigma_browse", label = "Browse and Download", icon = "table"),
      list(id = "sixsigma_visualizations", label = "Visualisations", icon = "microscope")))
)
TD_HUBS_MORE$api_hub_conn <- list(title = "API Configuration", icon = "key", blurb = "Connections: BigQuery, the Claude API and the Debug Console.",
  children = list(
    list(id = "bigquery_auth", label = "BigQuery", icon = "database"),
    list(id = "claude_api_config", label = "Claude", icon = "robot"),
    list(id = "debug_console", label = "Debug Console", icon = "terminal")))
TD_HUBS <- c(TD_HUBS, TD_HUBS_MORE)
TD_HUB_OF <- unlist(lapply(names(TD_HUBS), function(h) setNames(rep(h, length(TD_HUBS[[h]]$children)), vapply(TD_HUBS[[h]]$children, function(x) x$id, ""))))
TD_HUB_CHILD_IDS <- names(TD_HUB_OF)

td_hub_ui <- function(hub) {
  h <- TD_HUBS[[hub]]
  tagList(
    div(class = "td-hub",
        do.call(tabsetPanel, c(list(id = paste0(hub, "_tabs"), type = "tabs"),
          lapply(h$children, function(ch) {
            f <- get(paste0(ch$id, "_ui"), envir = .GlobalEnv)
            tabPanel(title = tagList(icon(ch$icon), " ", ch$label), value = ch$id, f(ch$id))
          }))))
  )
}

# Jump to a Technical Designs tab by its old tab id: selects the hub in the sidebar and the sub-tab inside it.
td_nav <- function(session, tab) {
  root <- session$rootScope()
  hub <- unname(TD_HUB_OF[tab])
  if (length(hub) == 0 || is.na(hub)) { updateTabItems(root, "sidebar_menu", selected = tab); return(invisible()) }
  updateTabItems(root, "sidebar_menu", selected = hub)
  updateTabsetPanel(root, paste0(hub, "_tabs"), selected = tab)
  invisible()
}

# generic name used by the other suites
app_nav <- td_nav
