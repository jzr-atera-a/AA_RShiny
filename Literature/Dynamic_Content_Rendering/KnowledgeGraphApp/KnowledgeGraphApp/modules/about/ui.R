# modules/about/ui.R

about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Knowledge Graph Suite",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        h4("What this app does"),
        p("Generates, edits, and visualizes AI-generated KNOWLEDGE GRAPHS - typed ENTITIES (e.g. Person, ",
          "Organization, Concept, Event, Location) connected by typed, directed RELATIONSHIPS (subject-",
          "predicate-object triples). Unlike the sibling Mind Map Suite, there is NO root and NO required ",
          "hierarchy: entities can connect to any other entities, cycles are normal, and an entity may ",
          "have zero, one, or many relationships."),

        h4("BigQuery Schema (append-only, versioned, two row kinds)"),
        tags$pre(
"id                        INTEGER    auto-generated, sequential (also the version ordinal)
created_at                TIMESTAMP  auto-generated
source                    STRING     'claude' or 'manual'
change_type               STRING     'create' | 'update' | 'delete'
row_kind                  STRING     'entity' | 'relationship'
category                  STRING     top-level domain, e.g. 'Science'
domain                    STRING     e.g. 'Physics'
topic                     STRING     e.g. 'Nobel Laureates'
graph_id                  STRING     groups all versions of all entities/relationships in one graph
graph_title               STRING     display title
entity_id                 STRING     populated when row_kind='entity', e.g. 'E1'
entity_label              STRING     the entity's name/title
entity_type               STRING     e.g. 'Person', 'Award', 'Concept' - Claude's choice, not a fixed list
entity_description        STRING
relationship_id           STRING     populated when row_kind='relationship', e.g. 'R1'
source_entity_id          STRING     the entity_id this relationship starts FROM
predicate                 STRING     the relationship type, e.g. 'won', 'influenced', 'located in'
target_entity_id          STRING     the entity_id this relationship points TO
relationship_description  STRING     detail specific to this one relationship
sort_order                INTEGER    ordering / audit-trail sequencing"
        ),

        h4("Why two row kinds in one table"),
        p("A relationship in a knowledge graph carries real content of its own (a description specific to ",
          "that connection, not just a label) and deserves a stable id for future editing - so unlike the ",
          "Mind Map Suite's ", tags$code("cross_links"), " (a sparse, secondary delimited field on each ",
          "node), relationships here are full first-class rows. Entity metadata (type/description) is ",
          "stored once per entity rather than repeated on every relationship that touches it."),

        h4("Why append-only, and no root/depth concept at all"),
        p("Every edit inserts a NEW row - never an UPDATE or DELETE statement - matching the same insert-",
          "only philosophy as the sibling apps. 'Current state' is the latest row per (graph_id, entity_id) ",
          "and separately per (graph_id, relationship_id), with anything whose latest change_type is ",
          "'delete' excluded. There is no root, no depth, and no cycle-prevention logic needed at all - a ",
          "knowledge graph simply doesn't have those constraints."),

        h4("Cascade delete: entity -> its relationships"),
        p("Deleting an entity also deletes every relationship that touches it (as source OR target) - ",
          "otherwise the graph would contain a dangling reference. Claude only needs to name the ONE ",
          "entity_id to delete; the app itself finds every relationship that references it and tombstones ",
          "them automatically. Unlike the Mind Map Suite's subtree cascade, this needs no recursive ",
          "traversal - relationships don't have their own dependents, so it's a single filter, not a walk."),

        h4("Editing model: delta, not full regeneration"),
        p("When editing an existing graph, Claude is shown a compact list of the CURRENT entities and ",
          "relationships plus your edit request, and returns ONLY what changed - CREATE/UPDATE/DELETE ",
          "blocks tagged with an ENTITY or RELATIONSHIP kind, never the whole graph re-transcribed."),

        h4("Generation prompt: rules first, request second"),
        p("Every generation call sends Claude a fixed structural rule block FIRST - covering output ",
          "format, entity/relationship block tags, the hard per-entity relationship cap, and formatting ",
          "rules - and only THEN the specific Category/Domain/Topic/description for this particular ",
          "graph. 'Max Relationships per Entity' is enforced as a hard cap; total entity/relationship ",
          "counts remain soft targets, since the right size depends on the topic."),

        h4("Truncation handling"),
        p("If a response is cut off by hitting the token limit mid-generation, the last incomplete block ",
          "is detected via the API's own ", tags$code("stop_reason"), " signal, dropped automatically, and ",
          "clearly reported - rather than silently corrupting the graph the way a naive parser might."),

        h4("Two visualization tabs"),
        p(tags$strong("D3 Visualization"), " uses a force-directed layout (nodes repel, edges pull ",
          "connected ones together) hand-built with D3.js - full control over styling, drag-to-reposition, ",
          "zoom/pan, a color-by-type legend, and node size scaled by connection count.", tags$br(),
          tags$strong("Cytoscape Visualization"), " uses Cytoscape.js, a library purpose-built for network ",
          "graphs, with its built-in 'cose' force-directed layout and more polished tap/select interaction ",
          "handling. Both read the exact same current graph state - try both and see which you prefer for ",
          "a given graph."),

        h4("Tabs"),
        tags$ul(
          tags$li(tags$strong("BigQuery Setup"), " - connect to your dataset (auto-creates the table)"),
          tags$li(tags$strong("Claude API Config"), " - credentials, model, timeout, network diagnostics"),
          tags$li(tags$strong("Generate Graph"), " - create a brand-new knowledge graph"),
          tags$li(tags$strong("Edit Graph"), " - load an existing graph, request a delta edit, review the cascade-computed preview, apply"),
          tags$li(tags$strong("D3 Visualization"), " - interactive force-directed graph"),
          tags$li(tags$strong("Cytoscape Visualization"), " - interactive graph via Cytoscape.js"),
          tags$li(tags$strong("Browse Data"), " - raw versioned backup view + CSV export")
        )
      )
    )
  )
}
