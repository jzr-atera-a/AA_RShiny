# modules/about/ui.R

about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Mind Map Suite",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        h4("What this app does"),
        p("Generates, edits, and visualizes AI-generated MIND MAPS - hierarchical trees where every ",
          "node has exactly ONE primary parent (guaranteeing a clean, acyclic backbone), plus optional ",
          "auxiliary cross-links to any other node in the map, including nodes higher up the hierarchy."),

        h4("BigQuery Schema (append-only, versioned)"),
        tags$pre(
"id                INTEGER    auto-generated, sequential (also the version ordinal)
created_at        TIMESTAMP  auto-generated
source            STRING     'claude' or 'manual'
change_type       STRING     'create' | 'update' | 'delete'
category          STRING     top-level domain, e.g. 'Science'
domain            STRING     e.g. 'Biology'
topic             STRING     e.g. 'Cell Structure' - the root node's subject
map_id            STRING     groups all versions of all nodes in one map generation
map_title         STRING     display title
node_id           STRING     stable identity, unique within a map_id, e.g. 'N1'
node_label        STRING     short title shown ON the node itself
node_content      STRING     longer summary shown when the node is clicked
parent_node_id    STRING     the ONE primary hierarchical parent; 'ROOT' for the root node
cross_links       STRING     delimited: target_node_id|||KV|||relationship label, repeated with |||COL|||
sort_order        INTEGER    ordering / audit-trail sequencing"
        ),

        h4("The generation prompt: rules first, request second"),
        p("Every 'Generate Mind Map' call sends Claude a fixed structural rule block FIRST - covering ",
          "output format, the root/hierarchy rule, the two branching HARD CAPS below, the cross-link ",
          "delimiter contract, and formatting rules - and only THEN the specific Category/Domain/Topic/ ",
          "description for this particular map. Presenting the full rule set before the task tends to ",
          "produce more reliable adherence than appending rules after the request."),

        h4("Branching hard caps"),
        p("Two controls on the Generate Mind Map tab are enforced as HARD CAPS in that rule block, not ",
          "soft suggestions: ", tags$strong("Max Subnodes of Main Topic"), " limits how many direct ",
          "children the root may have, and ", tags$strong("Max Children per Lower Node"), " limits ",
          "branching for every other node. 'Target Total Nodes' remains a soft guideline, since the ",
          "right total still depends on what the topic naturally calls for. As defense-in-depth, the ",
          "validator also re-checks the actual generated tree against both caps after the fact and ",
          "surfaces a non-blocking warning (not an upload-blocking error) if Claude exceeded either one."),

        h4("Why append-only, and why no stored depth/level column"),
        p("Every edit inserts a NEW row - never an UPDATE or DELETE statement - matching the same ",
          "insert-only philosophy as the rest of this app's sibling tools. 'Current state' is always ",
          "the latest row per (map_id, node_id), with anything whose latest change_type is 'delete' ",
          "excluded. This gives a free audit trail and means RE-PARENTING a node is a single new row - ",
          "no cascading update to descendants, because depth (level) is computed on read by walking ",
          "parent_node_id chains, never stored."),

        h4("Cascade delete"),
        p("Deleting a node deletes its entire subtree. When you ask Claude to delete a node, Claude ",
          "only needs to name that ONE node_id - the app itself walks the CURRENT tree (already loaded ",
          "in memory) to find every descendant and tombstones them automatically. This is deliberate: ",
          "asking an LLM to correctly enumerate an entire subtree by hand is exactly the kind of ",
          "multi-hop reasoning task it can get wrong on a large tree."),

        h4("The delimiter contract (cross_links field)"),
        tags$ul(
          tags$li(tags$code("|||COL|||"), " separates one cross-link entry from the next"),
          tags$li(tags$code("|||KV|||"), " separates a target node_id from its relationship label")
        ),
        p("Validation before upload checks for two categories of problem: BLOCKING issues (no root, ",
          "multiple roots, duplicate node_id, a parent_id pointing nowhere - any of these would corrupt ",
          "the tree and prevent upload) and non-blocking WARNINGS (a cross-link target that doesn't ",
          "exist, or a branching hard cap that was exceeded) - shown to you, but the upload still proceeds."),

        h4("Editing model: delta, not full regeneration"),
        p("When editing an existing map, Claude is shown a compact outline of the CURRENT tree plus ",
          "your edit request, and returns ONLY what changed - CREATE/UPDATE/DELETE blocks for the ",
          "affected nodes, never the whole tree re-transcribed. This avoids token waste, avoids Claude ",
          "subtly rewording untouched nodes, and avoids asking it to manually enumerate a deleted ",
          "subtree (see above)."),

        h4("Tabs"),
        tags$ul(
          tags$li(tags$strong("BigQuery Setup"), " - connect to your dataset (auto-creates the table)"),
          tags$li(tags$strong("Claude API Config"), " - credentials, model, timeout, network diagnostics"),
          tags$li(tags$strong("Generate Mind Map"), " - create a brand-new map (full tree)"),
          tags$li(tags$strong("Edit Mind Map"), " - load an existing map, request a delta edit, review the cascade-computed preview, apply"),
          tags$li(tags$strong("Visualize Mind Map"), " - interactive D3.js collapsible tree: solid colored lines = hierarchy, dashed orange = cross-links, click a circle to collapse/expand, click a label for full content"),
          tags$li(tags$strong("Browse Data"), " - raw versioned backup view + CSV export")
        )
      )
    )
  )
}
