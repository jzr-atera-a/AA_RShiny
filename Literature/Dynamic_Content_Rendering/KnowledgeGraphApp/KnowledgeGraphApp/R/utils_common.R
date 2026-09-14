# R/utils_common.R
# Shared Utility Functions - Knowledge Graph Suite
# =================================================
# Core data model: a knowledge graph has NO root and NO hierarchy -
# just typed ENTITIES connected by typed, directed RELATIONSHIPS
# (subject-predicate-object triples). Unlike the Mind Map Suite, there
# is no delimited multi-value field to worry about: every relationship
# is its own row, which sidesteps that whole class of parsing bug.
#
# Storage is APPEND-ONLY, same philosophy as the sibling apps: an edit
# is a new row (same graph_id + entity_id/relationship_id, change_type
# = 'update'), never an UPDATE/DELETE statement. "Current state" is
# always derived by taking the latest row per id and dropping anything
# whose latest change_type is 'delete'.

safe_sql_escape <- function(input_value) {
  gsub("'", "''", input_value)
}

# Generates a unique graph_id for a NEW knowledge graph (assigned by
# the app, not by Claude, so uniqueness is guaranteed).
generate_new_graph_id <- function(topic) {
  slug <- tolower(gsub("[^a-zA-Z0-9]+", "-", trimws(topic)))
  slug <- gsub("^-+|-+$", "", slug)
  if (nchar(slug) == 0) slug <- "graph"
  if (nchar(slug) > 40) slug <- substr(slug, 1, 40)
  paste0(slug, "-", format(Sys.time(), "%Y%m%d%H%M%S"))
}

# ============================================================
# PARSE CLAUDE'S INITIAL FULL-GRAPH GENERATION
# ============================================================
# Expected format:
#
# [Category]
# [Domain]
# [Topic]
# [Graph Title]
#
# [entity_id]: E1
# [label]: Marie Curie
# [type]: Person
# [description]: <~N words>
#
# [entity_id]: E2
# ...
#
# [relationship_id]: R1
# [source]: E1
# [predicate]: won
# [target]: E2
# [description]: <~N words>
#
# Order of entity vs relationship blocks does NOT matter for parsing
# correctness (unlike the Mind Map's tree, references here don't need
# an "already introduced" guarantee) - entities-before-relationships is
# only requested as a style preference in the prompt, for readability.
parse_kg_creation_text <- function(text) {

  lines <- strsplit(text, "\n")[[1]]

  # Tolerant of both bare [Value] and labeled [Category]: Value forms -
  # lesson learned from the Mind Map Suite, where Claude occasionally
  # drifted to the labeled form despite instructions.
  labeled_metadata_re <- "^\\[(Category|Domain|Topic|Graph Title)\\]:\\s*(.*)$"
  bare_metadata_re <- "^\\[.+\\]$"

  category <- NULL; domain <- NULL; topic <- NULL; graph_title <- NULL
  metadata_count <- 0
  for (i in seq_len(min(20, length(lines)))) {
    line <- trimws(lines[i])
    value <- NULL
    if (grepl(labeled_metadata_re, line, ignore.case = TRUE)) {
      value <- trimws(sub(labeled_metadata_re, "\\2", line, ignore.case = TRUE))
    } else if (grepl(bare_metadata_re, line)) {
      value <- gsub("^\\[|\\]$", "", line)
    }
    if (!is.null(value)) {
      metadata_count <- metadata_count + 1
      if (metadata_count == 1) category <- value
      else if (metadata_count == 2) domain <- value
      else if (metadata_count == 3) topic <- value
      else if (metadata_count == 4) graph_title <- value
      else break
    }
  }

  if (is.null(category) || is.null(domain) || is.null(topic)) {
    stop("Could not find Category, Domain, and Topic metadata in generated knowledge graph text")
  }
  if (is.null(graph_title)) graph_title <- topic

  blocks <- list()
  current_block <- list()

  flush_block <- function() {
    if (!is.null(current_block$.kind)) {
      blocks[[length(blocks) + 1]] <<- current_block
    }
    current_block <<- list()
  }

  for (line in lines) {
    trimmed <- trimws(line)

    if (trimmed == "") { flush_block(); next }

    if (grepl("^\\[entity_id\\]:", trimmed, ignore.case = TRUE)) {
      flush_block()
      current_block$.kind <- "entity"
      current_block$entity_id <- trimws(sub("^\\[entity_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[relationship_id\\]:", trimmed, ignore.case = TRUE)) {
      flush_block()
      current_block$.kind <- "relationship"
      current_block$relationship_id <- trimws(sub("^\\[relationship_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[label\\]:", trimmed, ignore.case = TRUE)) {
      current_block$label <- trimws(sub("^\\[label\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[type\\]:", trimmed, ignore.case = TRUE)) {
      current_block$type <- trimws(sub("^\\[type\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[source\\]:", trimmed, ignore.case = TRUE)) {
      current_block$source <- trimws(sub("^\\[source\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[predicate\\]:", trimmed, ignore.case = TRUE)) {
      current_block$predicate <- trimws(sub("^\\[predicate\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[target\\]:", trimmed, ignore.case = TRUE)) {
      current_block$target <- trimws(sub("^\\[target\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[description\\]:", trimmed, ignore.case = TRUE)) {
      current_block$description <- trimws(sub("^\\[description\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (!is.null(current_block$description)) {
      current_block$description <- paste0(current_block$description, " ", trimmed)
    }
  }
  flush_block()

  if (length(blocks) == 0) {
    stop("No valid [entity_id] or [relationship_id] blocks found in generated knowledge graph text")
  }

  entities_list <- list()
  relationships_list <- list()
  truncated_id <- NULL

  # If the response was cut off by the API's token limit, it typically
  # stops mid-way through the LAST block. Only the LAST block missing a
  # required field is treated as truncation (dropped + reported); any
  # OTHER block missing a required field is a genuine formatting
  # problem, left as blank so validate_kg_structure() reports it
  # accurately instead of guessing.
  for (i in seq_along(blocks)) {
    b <- blocks[[i]]
    is_last <- (i == length(blocks))

    if (b$.kind == "entity") {
      missing_required <- is.null(b$label) || is.null(b$type) || is.null(b$description)
      if (missing_required && is_last) { truncated_id <- b$entity_id; next }

      entities_list[[length(entities_list) + 1]] <- data.frame(
        entity_id = b$entity_id,
        entity_label = ifelse(is.null(b$label), "", b$label),
        entity_type = ifelse(is.null(b$type), "", b$type),
        entity_description = ifelse(is.null(b$description), "", b$description),
        sort_order = i,
        stringsAsFactors = FALSE
      )
    } else {
      missing_required <- is.null(b$source) || is.null(b$predicate) || is.null(b$target)
      if (missing_required && is_last) { truncated_id <- b$relationship_id; next }

      relationships_list[[length(relationships_list) + 1]] <- data.frame(
        relationship_id = b$relationship_id,
        source_entity_id = ifelse(is.null(b$source), "", b$source),
        predicate = ifelse(is.null(b$predicate), "", b$predicate),
        target_entity_id = ifelse(is.null(b$target), "", b$target),
        relationship_description = ifelse(is.null(b$description), "", b$description),
        sort_order = i,
        stringsAsFactors = FALSE
      )
    }
  }

  entities_df <- if (length(entities_list) > 0) do.call(rbind, entities_list) else data.frame(
    entity_id = character(), entity_label = character(), entity_type = character(),
    entity_description = character(), sort_order = integer(), stringsAsFactors = FALSE
  )
  relationships_df <- if (length(relationships_list) > 0) do.call(rbind, relationships_list) else data.frame(
    relationship_id = character(), source_entity_id = character(), predicate = character(),
    target_entity_id = character(), relationship_description = character(), sort_order = integer(),
    stringsAsFactors = FALSE
  )

  list(category = category, domain = domain, topic = topic, graph_title = graph_title,
       entities = entities_df, relationships = relationships_df, truncated_id = truncated_id)
}

# ============================================================
# PARSE CLAUDE'S EDIT DELTA
# ============================================================
# ONLY the changed items, one block per change, each starting with
# [change]: CREATE|UPDATE|DELETE and [kind]: ENTITY|RELATIONSHIP.
parse_kg_delta_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]

  blocks <- list()
  current_block <- list()

  flush_block <- function() {
    if (!is.null(current_block$change_type) && !is.null(current_block$kind)) {
      blocks[[length(blocks) + 1]] <<- current_block
    }
    current_block <<- list()
  }

  for (line in lines) {
    trimmed <- trimws(line)
    if (trimmed == "") next

    if (grepl("^\\[change\\]:", trimmed, ignore.case = TRUE)) {
      flush_block()
      current_block$change_type <- toupper(trimws(sub("^\\[change\\]:\\s*", "", trimmed, ignore.case = TRUE)))
    } else if (grepl("^\\[kind\\]:", trimmed, ignore.case = TRUE)) {
      current_block$kind <- toupper(trimws(sub("^\\[kind\\]:\\s*", "", trimmed, ignore.case = TRUE)))
    } else if (grepl("^\\[entity_id\\]:", trimmed, ignore.case = TRUE)) {
      current_block$entity_id <- trimws(sub("^\\[entity_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[relationship_id\\]:", trimmed, ignore.case = TRUE)) {
      current_block$relationship_id <- trimws(sub("^\\[relationship_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[label\\]:", trimmed, ignore.case = TRUE)) {
      current_block$label <- trimws(sub("^\\[label\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[type\\]:", trimmed, ignore.case = TRUE)) {
      current_block$type <- trimws(sub("^\\[type\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[source\\]:", trimmed, ignore.case = TRUE)) {
      current_block$source <- trimws(sub("^\\[source\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[predicate\\]:", trimmed, ignore.case = TRUE)) {
      current_block$predicate <- trimws(sub("^\\[predicate\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[target\\]:", trimmed, ignore.case = TRUE)) {
      current_block$target <- trimws(sub("^\\[target\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[description\\]:", trimmed, ignore.case = TRUE)) {
      current_block$description <- trimws(sub("^\\[description\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (!is.null(current_block$description)) {
      current_block$description <- paste0(current_block$description, " ", trimmed)
    }
  }
  flush_block()

  if (length(blocks) == 0) {
    stop("No valid [change]/[kind] entries found in the edit response")
  }

  entity_changes <- list()
  relationship_changes <- list()

  for (b in blocks) {
    if (is.null(b$change_type) || !b$change_type %in% c("CREATE", "UPDATE", "DELETE")) {
      stop(sprintf("Unknown or missing [change] type '%s'", b$change_type %||% "(none)"))
    }
    if (is.null(b$kind) || !b$kind %in% c("ENTITY", "RELATIONSHIP")) {
      stop(sprintf("Unknown or missing [kind] '%s' - expected ENTITY or RELATIONSHIP", b$kind %||% "(none)"))
    }

    if (b$kind == "ENTITY") {
      entity_changes[[length(entity_changes) + 1]] <- data.frame(
        change_type = tolower(b$change_type),
        entity_id = b$entity_id,
        entity_label = ifelse(is.null(b$label), NA, b$label),
        entity_type = ifelse(is.null(b$type), NA, b$type),
        entity_description = ifelse(is.null(b$description), NA, b$description),
        stringsAsFactors = FALSE
      )
    } else {
      relationship_changes[[length(relationship_changes) + 1]] <- data.frame(
        change_type = tolower(b$change_type),
        relationship_id = b$relationship_id,
        source_entity_id = ifelse(is.null(b$source), NA, b$source),
        predicate = ifelse(is.null(b$predicate), NA, b$predicate),
        target_entity_id = ifelse(is.null(b$target), NA, b$target),
        relationship_description = ifelse(is.null(b$description), NA, b$description),
        stringsAsFactors = FALSE
      )
    }
  }

  entity_delta <- if (length(entity_changes) > 0) do.call(rbind, entity_changes) else data.frame(
    change_type = character(), entity_id = character(), entity_label = character(),
    entity_type = character(), entity_description = character(), stringsAsFactors = FALSE
  )
  relationship_delta <- if (length(relationship_changes) > 0) do.call(rbind, relationship_changes) else data.frame(
    change_type = character(), relationship_id = character(), source_entity_id = character(),
    predicate = character(), target_entity_id = character(), relationship_description = character(),
    stringsAsFactors = FALSE
  )

  list(entity_delta = entity_delta, relationship_delta = relationship_delta)
}

# ============================================================
# VALIDATION
# ============================================================
# Simpler than the Mind Map's tree validation: no root, no depth, no
# cycle concerns (cycles are normal in a knowledge graph). Just:
# uniqueness, completeness, and that every relationship's source/target
# actually exists.
validate_kg_structure <- function(entities_df, relationships_df, max_relationships_per_entity = NULL) {
  issues <- c()
  warnings <- c()

  if (nrow(entities_df) > 0 && any(duplicated(entities_df$entity_id))) {
    dupes <- unique(entities_df$entity_id[duplicated(entities_df$entity_id)])
    issues <- c(issues, sprintf("Duplicate entity_id(s) found: %s", paste(dupes, collapse = ", ")))
  }
  if (nrow(relationships_df) > 0 && any(duplicated(relationships_df$relationship_id))) {
    dupes <- unique(relationships_df$relationship_id[duplicated(relationships_df$relationship_id)])
    issues <- c(issues, sprintf("Duplicate relationship_id(s) found: %s", paste(dupes, collapse = ", ")))
  }

  if (nrow(entities_df) > 0) {
    incomplete <- entities_df[trimws(entities_df$entity_label) == "" |
                              trimws(entities_df$entity_type) == "" |
                              trimws(entities_df$entity_description) == "", ]
    if (nrow(incomplete) > 0) {
      issues <- c(issues, sprintf("%d entit(y/ies) are missing a label, type, or description: %s",
                                  nrow(incomplete), paste(incomplete$entity_id, collapse = ", ")))
    }
  }

  if (nrow(relationships_df) > 0) {
    blank_predicate <- relationships_df[trimws(relationships_df$predicate) == "", ]
    if (nrow(blank_predicate) > 0) {
      issues <- c(issues, sprintf("%d relationship(s) are missing a predicate: %s",
                                  nrow(blank_predicate), paste(blank_predicate$relationship_id, collapse = ", ")))
    }

    missing_sources <- setdiff(relationships_df$source_entity_id[trimws(relationships_df$source_entity_id) != ""],
                               entities_df$entity_id)
    blank_source_rels <- relationships_df$relationship_id[trimws(relationships_df$source_entity_id) == ""]
    if (length(missing_sources) > 0 || length(blank_source_rels) > 0) {
      bad_rel_ids <- relationships_df$relationship_id[
        relationships_df$source_entity_id %in% missing_sources | relationships_df$relationship_id %in% blank_source_rels
      ]
      issues <- c(issues, sprintf("%d relationship(s) reference a source entity_id that doesn't exist or is blank: %s",
                                  length(bad_rel_ids), paste(bad_rel_ids, collapse = ", ")))
    }

    missing_targets <- setdiff(relationships_df$target_entity_id[trimws(relationships_df$target_entity_id) != ""],
                               entities_df$entity_id)
    blank_target_rels <- relationships_df$relationship_id[trimws(relationships_df$target_entity_id) == ""]
    if (length(missing_targets) > 0 || length(blank_target_rels) > 0) {
      bad_rel_ids <- relationships_df$relationship_id[
        relationships_df$target_entity_id %in% missing_targets | relationships_df$relationship_id %in% blank_target_rels
      ]
      issues <- c(issues, sprintf("%d relationship(s) reference a target entity_id that doesn't exist or is blank: %s",
                                  length(bad_rel_ids), paste(bad_rel_ids, collapse = ", ")))
    }

    self_loops <- relationships_df[relationships_df$source_entity_id == relationships_df$target_entity_id &
                                   trimws(relationships_df$source_entity_id) != "", ]
    if (nrow(self_loops) > 0) {
      warnings <- c(warnings, sprintf("%d relationship(s) connect an entity to itself: %s",
                                      nrow(self_loops), paste(self_loops$relationship_id, collapse = ", ")))
    }

    if (!is.null(max_relationships_per_entity)) {
      degree <- table(c(relationships_df$source_entity_id, relationships_df$target_entity_id))
      over_cap <- degree[degree > max_relationships_per_entity]
      if (length(over_cap) > 0) {
        warnings <- c(warnings, sprintf(
          "%d entit(y/ies) exceed the requested cap of %d relationships each: %s",
          length(over_cap), max_relationships_per_entity,
          paste(sprintf("%s (%d)", names(over_cap), as.integer(over_cap)), collapse = ", ")
        ))
      }
    }
  }

  list(valid = length(issues) == 0, issues = issues, warnings = warnings)
}

# ============================================================
# AUTO-PRUNE SPURIOUS EMPTY/DISCONNECTED ENTITIES
# ============================================================
# Same rationale as the Mind Map Suite: occasionally a trailing,
# malformed extra entity block sneaks in - blank label/type/description,
# not referenced by any relationship. Safe to silently drop before
# validation, deliberately conservative (a real entity always has a
# non-blank description).
prune_empty_disconnected_entities <- function(entities_df, relationships_df) {
  pruned_ids <- character(0)
  is_blank <- function(x) is.na(x) || trimws(x) == ""

  max_iterations <- nrow(entities_df) + 2
  for (iter in seq_len(max_iterations)) {
    if (nrow(entities_df) == 0) break

    referenced <- unique(c(relationships_df$source_entity_id, relationships_df$target_entity_id))

    is_candidate <- vapply(seq_len(nrow(entities_df)), function(i) {
      row <- entities_df[i, ]
      label_empty_or_selfref <- is_blank(row$entity_label) || identical(row$entity_label, row$entity_id)
      label_empty_or_selfref && is_blank(row$entity_type) && is_blank(row$entity_description) &&
        !(row$entity_id %in% referenced)
    }, logical(1))

    if (!any(is_candidate)) break
    pruned_ids <- c(pruned_ids, entities_df$entity_id[is_candidate])
    entities_df <- entities_df[!is_candidate, ]
  }

  list(entities = entities_df, pruned_ids = unique(pruned_ids))
}

# ============================================================
# CASCADE DELETE (entity -> its relationships)
# ============================================================
# Deleting an entity must also remove every relationship that touches
# it (as source OR target), or the graph would contain a dangling
# reference. Unlike the Mind Map's subtree cascade, this needs no
# recursive traversal - relationships don't have their own dependents,
# so it's a single filter, not a BFS.
compute_relationship_cascade_delete <- function(relationships_df, entity_ids_to_delete) {
  if (nrow(relationships_df) == 0) return(character(0))
  relationships_df$relationship_id[
    relationships_df$source_entity_id %in% entity_ids_to_delete |
    relationships_df$target_entity_id %in% entity_ids_to_delete
  ]
}

# ============================================================
# COMPACT SERIALIZATION (for edit-prompt context)
# ============================================================
serialize_graph_for_prompt <- function(entities_df, relationships_df, max_words_per_item = 40) {
  if (nrow(entities_df) == 0) return("(empty graph)")

  truncate_words <- function(text, n) {
    words <- strsplit(text, "\\s+")[[1]]
    if (length(words) <= n) return(text)
    paste0(paste(words[seq_len(n)], collapse = " "), " ...")
  }

  entity_lines <- sprintf("%s [%s]: %s - %s", entities_df$entity_id, entities_df$entity_type,
                          entities_df$entity_label,
                          vapply(entities_df$entity_description, truncate_words, character(1), n = max_words_per_item))

  rel_lines <- if (nrow(relationships_df) > 0) {
    sprintf("%s: %s --[%s]--> %s (%s)", relationships_df$relationship_id,
            relationships_df$source_entity_id, relationships_df$predicate, relationships_df$target_entity_id,
            vapply(relationships_df$relationship_description, truncate_words, character(1), n = max_words_per_item))
  } else character(0)

  paste0(
    "ENTITIES:\n", paste(entity_lines, collapse = "\n"),
    "\n\nRELATIONSHIPS:\n", if (length(rel_lines) > 0) paste(rel_lines, collapse = "\n") else "(none)"
  )
}

# Given existing ids like "E1", "E7", "E14", returns the next unused
# integer suffix, so new CREATE items in an edit delta never collide.
next_available_entity_id_num <- function(entities_df) {
  if (nrow(entities_df) == 0) return(1)
  nums <- suppressWarnings(as.integer(gsub("^E", "", entities_df$entity_id, ignore.case = TRUE)))
  nums <- nums[!is.na(nums)]
  if (length(nums) == 0) return(1)
  max(nums) + 1
}
next_available_relationship_id_num <- function(relationships_df) {
  if (nrow(relationships_df) == 0) return(1)
  nums <- suppressWarnings(as.integer(gsub("^R", "", relationships_df$relationship_id, ignore.case = TRUE)))
  nums <- nums[!is.na(nums)]
  if (length(nums) == 0) return(1)
  max(nums) + 1
}

# ============================================================
# CATEGORY / DOMAIN / TOPIC HIERARCHICAL CLASSIFICATION
# ============================================================
CATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_CATEGORY__"
DOMAIN_ADD_NEW_VALUE <- "__ADD_NEW_DOMAIN__"
TOPIC_ADD_NEW_VALUE <- "__ADD_NEW_TOPIC__"

category_domain_topic_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("category_select"), "Category: *",
                choices = c("+ Add New Category" = CATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("category_select"), CATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_category_text"), "New Category Name:", placeholder = "e.g., Science")
    ),
    selectInput(ns("domain_select"), "Domain: *",
                choices = c("+ Add New Domain" = DOMAIN_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("domain_select"), DOMAIN_ADD_NEW_VALUE),
      textInput(ns("new_domain_text"), "New Domain Name:", placeholder = "e.g., Physics")
    ),
    selectInput(ns("topic_select"), "Topic: *",
                choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("topic_select"), TOPIC_ADD_NEW_VALUE),
      textInput(ns("new_topic_text"), "New Topic Name:", placeholder = "e.g., Nobel Laureates in Physics")
    )
  )
}

setup_category_domain_topic_cascade <- function(input, output, session, api_manager) {

  taxonomy <- reactive({
    api_manager$state_trigger()
    if (!api_manager$bq_authenticated) return(api_manager$empty_taxonomy())
    tryCatch(api_manager$bq_get_taxonomy(), error = function(e) api_manager$empty_taxonomy())
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
    choices <- c("+ Add New Category" = CATEGORY_ADD_NEW_VALUE, setNames(categories, categories))

    current <- isolate(input$category_select)
    selected <- if (!is.null(current) && current %in% choices) current else CATEGORY_ADD_NEW_VALUE

    updateSelectInput(session, "category_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  observeEvent(input$category_select, {
    tax <- taxonomy()

    if (is.null(input$category_select) || input$category_select == CATEGORY_ADD_NEW_VALUE) {
      updateSelectInput(session, "domain_select", choices = c("+ Add New Domain" = DOMAIN_ADD_NEW_VALUE))
      return()
    }

    domains <- sort(unique(tax$domain[tax$category == input$category_select & nchar(trimws(tax$domain)) > 0]))

    updateSelectInput(session, "domain_select",
                      choices = c("+ Add New Domain" = DOMAIN_ADD_NEW_VALUE,
                                  if (length(domains) > 0) setNames(domains, domains) else NULL))
  }, ignoreInit = TRUE)

  observeEvent(input$domain_select, {
    tax <- taxonomy()

    if (is.null(input$category_select) || input$category_select == CATEGORY_ADD_NEW_VALUE ||
        is.null(input$domain_select) || input$domain_select == DOMAIN_ADD_NEW_VALUE) {
      updateSelectInput(session, "topic_select", choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE))
      return()
    }

    topics <- sort(unique(tax$topic[tax$category == input$category_select &
                                     tax$domain == input$domain_select &
                                     nchar(trimws(tax$topic)) > 0]))

    updateSelectInput(session, "topic_select",
                      choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE,
                                  if (length(topics) > 0) setNames(topics, topics) else NULL))
  }, ignoreInit = TRUE)

  reactive({
    category <- if (identical(input$category_select, CATEGORY_ADD_NEW_VALUE)) {
      trimws(input$new_category_text %||% "")
    } else {
      input$category_select %||% ""
    }

    domain <- if (identical(input$domain_select, DOMAIN_ADD_NEW_VALUE)) {
      trimws(input$new_domain_text %||% "")
    } else {
      input$domain_select %||% ""
    }

    topic <- if (identical(input$topic_select, TOPIC_ADD_NEW_VALUE)) {
      trimws(input$new_topic_text %||% "")
    } else {
      input$topic_select %||% ""
    }

    list(category = category, domain = domain, topic = topic)
  })
}

# ============================================================
# GENERATE CLAUDE PROMPT - INITIAL FULL GRAPH CREATION
# ============================================================
# Rules-first structure (lesson learned from the Mind Map Suite):
# Claude gets the complete structural "constitution" BEFORE the
# specific topic, which produces more reliable format adherence than
# appending rules after the task description.
build_kg_rules_block <- function(include_latex = FALSE, words_per_entity = 30, words_per_relationship = 25,
                                  max_relationships_per_entity = 8) {

  latex_instruction <- if (isTRUE(include_latex)) {
    '- Where a formula is genuinely relevant inside a description, you may use LaTeX ($inline$ or $$display$$). Do not force it where not relevant.\n'
  } else {
    '- Do NOT use any LaTeX syntax anywhere (no $...$, no $$...$$, no \\frac, \\sum, etc). Express any formulas in plain text instead.\n'
  }

  paste0(
    'You are an assistant that generates KNOWLEDGE GRAPHS for a web app - a set of typed ENTITIES ',
    'connected by typed, directed RELATIONSHIPS (subject-predicate-object triples). Unlike a hierarchy ',
    'or mind map, a knowledge graph has NO root and NO required tree structure: entities can connect to ',
    'any other entities, cycles are fine, and an entity may have zero, one, or many relationships. Before ',
    'you see the specific topic, read and internalize ALL of the following rules.\n\n',

    '========== KNOWLEDGE GRAPH STRUCTURAL RULES ==========\n\n',

    '1. OUTPUT FORMAT - the response must consist of:\n',
    '   - Exactly 4 metadata lines at the very top, each on its own line. Each line must contain ONLY the actual value wrapped in single square brackets - do NOT include a field name, label, or colon inside or around the brackets. For example, if the Category is "Science", the Domain is "Physics", the Topic is "Nobel Laureates", and the Graph Title is "Physics Nobel Laureates Network", the first 4 lines of your entire response must be EXACTLY:\n',
    '     [Science]\n',
    '     [Physics]\n',
    '     [Nobel Laureates]\n',
    '     [Physics Nobel Laureates Network]\n',
    '     Do NOT write "[Category]: Science" or add any other text on these lines - only the bracketed value itself.\n',
    '   - Then output ALL entity blocks FIRST, followed by ALL relationship blocks. Separate every block from the next with exactly ONE blank line.\n\n',

    '2. ENTITY BLOCKS - EXACTLY these 4 tagged lines:\n',
    '   [entity_id]: <a short unique id, e.g. E1, E2, E3, ... incrementing for every entity>\n',
    '   [label]: <the entity\'s name/title - a few words>\n',
    '   [type]: <a short category for this entity, e.g. Person, Organization, Concept, Event, Location, Technology, Publication - choose whatever types genuinely fit this topic, you are not restricted to this list>\n',
    '   [description]: <approx ', words_per_entity, ' words describing this entity specifically>\n\n',

    '3. RELATIONSHIP BLOCKS - EXACTLY these 5 tagged lines:\n',
    '   [relationship_id]: <a short unique id, e.g. R1, R2, R3, ... incrementing for every relationship>\n',
    '   [source]: <the entity_id this relationship starts FROM>\n',
    '   [predicate]: <a short verb phrase describing the relationship, e.g. "won", "influenced", "located in", "founded", "collaborated with">\n',
    '   [target]: <the entity_id this relationship points TO>\n',
    '   [description]: <approx ', words_per_relationship, ' words of specific detail about THIS relationship - not a generic restatement of the predicate>\n\n',

    '4. HARD CAPS (non-negotiable):\n',
    '   - Both [source] and [target] of every relationship MUST reference an entity_id you actually defined in an entity block above - never invent a reference to an entity_id that does not exist.\n',
    '   - No entity may be involved (as source OR target, combined) in more than ', max_relationships_per_entity, ' relationships. If more connections would be relevant, keep only the ', max_relationships_per_entity, ' most important ones for that entity.\n\n',

    '5. CONTENT RULES:\n',
    latex_instruction,
    '   - Each entity description must stay close to the ', words_per_entity, '-word target; each relationship description close to the ', words_per_relationship, '-word target - concise and specific, not padded.\n',
    '   - A relationship\'s description should say something SPECIFIC about that particular connection, not just restate the predicate in different words.\n\n',

    '6. FORMATTING RULES:\n',
    '   - NO extra markdown, NO headers with #, NO numbered list markers.\n',
    '   - Separate every block (entity or relationship) with exactly ONE blank line.\n',
    '   - Use the exact bracket tag format shown above.\n\n',

    '========== END OF RULES ==========\n\n'
  )
}

generate_kg_prompt <- function(category, domain, topic, graph_title, request_description,
                                include_latex = FALSE, words_per_entity = 30, words_per_relationship = 25,
                                max_entities = 15, max_relationships = 20, max_relationships_per_entity = 8) {

  rules_block <- build_kg_rules_block(include_latex = include_latex, words_per_entity = words_per_entity,
                                      words_per_relationship = words_per_relationship,
                                      max_relationships_per_entity = max_relationships_per_entity)

  request_block <- paste0(
    '========== YOUR TASK ==========\n\n',
    'Now build a knowledge graph following ALL the rules above, for:\n\n',
    'Category: ', category, '\n',
    'Domain: ', domain, '\n',
    'Topic: ', topic, '\n',
    'Graph Title: ', graph_title, '\n\n',

    'User request: ', request_description, '\n\n',

    'SIZE TARGET (soft - a guideline, not a hard cap like rule 4 above): aim for around ', max_entities,
    ' entities and around ', max_relationships, ' relationships total - UNLESS the user request above ',
    'clearly implies a different count, in which case follow the user request, while still always ',
    'respecting the HARD per-entity relationship cap from rule 4.\n\n',

    'Begin your response now with the 4 metadata lines, then all entity blocks, then all relationship blocks, exactly as specified in rule 1.'
  )

  paste0(rules_block, request_block)
}

# ============================================================
# GENERATE CLAUDE PROMPT - EDIT DELTA (existing graph)
# ============================================================
generate_kg_edit_prompt <- function(category, domain, topic, graph_title, current_graph_text, edit_request,
                                     next_entity_id_start, next_relationship_id_start,
                                     include_latex = FALSE, words_per_entity = 30, words_per_relationship = 25) {

  latex_instruction <- if (isTRUE(include_latex)) {
    '- Where a formula is genuinely relevant, you may use LaTeX ($inline$ or $$display$$).\n'
  } else {
    '- Do NOT use any LaTeX syntax anywhere - plain text only.\n'
  }

  paste0(
    'You are editing an EXISTING knowledge graph for a web app. You must output ONLY the CHANGES needed - ',
    'never re-output entities or relationships that are not changing.\n\n',

    'Category: ', category, ' | Domain: ', domain, ' | Topic: ', topic, ' | Graph Title: ', graph_title, '\n\n',

    'CURRENT GRAPH (for your reference only - do not re-output unchanged items):\n',
    current_graph_text, '\n\n',

    'EDIT REQUEST: ', edit_request, '\n\n',

    'Format Requirements - follow this EXACTLY:\n\n',

    '1. Output ONE block per CHANGE, separated by ONE blank line, with these tagged lines:\n\n',

    'For a NEW entity:\n',
    '[change]: CREATE\n[kind]: ENTITY\n',
    '[entity_id]: <a NEW id starting at E', next_entity_id_start, ' and incrementing - NEVER reuse an existing entity_id>\n',
    '[label]: <name>\n[type]: <type>\n[description]: <approx ', words_per_entity, ' words>\n\n',

    'For an EXISTING entity whose label/type/description changed:\n',
    '[change]: UPDATE\n[kind]: ENTITY\n',
    '[entity_id]: <the EXISTING entity_id being changed>\n',
    '[label]: <the FULL new label (repeat existing value if unchanged)>\n',
    '[type]: <the FULL new type (repeat existing value if unchanged)>\n',
    '[description]: <the FULL new description (repeat existing value if unchanged)>\n\n',

    'For an entity to remove:\n',
    '[change]: DELETE\n[kind]: ENTITY\n',
    '[entity_id]: <the EXISTING entity_id to delete>\n',
    '(no other tags needed - the app will automatically also remove every relationship touching this entity, so you do NOT need to separately DELETE those relationships)\n\n',

    'For a NEW relationship:\n',
    '[change]: CREATE\n[kind]: RELATIONSHIP\n',
    '[relationship_id]: <a NEW id starting at R', next_relationship_id_start, ' and incrementing - NEVER reuse an existing relationship_id>\n',
    '[source]: <an EXISTING or newly-CREATEd-in-this-response entity_id>\n',
    '[predicate]: <verb phrase>\n',
    '[target]: <an EXISTING or newly-CREATEd-in-this-response entity_id>\n',
    '[description]: <approx ', words_per_relationship, ' words>\n\n',

    'For an EXISTING relationship whose source/predicate/target/description changed:\n',
    '[change]: UPDATE\n[kind]: RELATIONSHIP\n',
    '[relationship_id]: <the EXISTING relationship_id being changed>\n',
    '[source]: <FULL current or new source (repeat if unchanged)>\n',
    '[predicate]: <FULL current or new predicate (repeat if unchanged)>\n',
    '[target]: <FULL current or new target (repeat if unchanged)>\n',
    '[description]: <FULL current or new description (repeat if unchanged)>\n\n',

    'For a relationship to remove:\n',
    '[change]: DELETE\n[kind]: RELATIONSHIP\n',
    '[relationship_id]: <the EXISTING relationship_id to delete>\n\n',

    '2. CRITICAL RULES:\n',
    '   - Do NOT output blocks for entities/relationships that are not changing.\n',
    '   - Do NOT re-output the entire graph.\n',
    '   - For CREATE relationships, [source]/[target] may reference an EXISTING entity_id OR one you just CREATEd earlier in this same response.\n',
    '   - NEVER invent a change to an entity_id or relationship_id that does not exist in the current graph (for UPDATE/DELETE).\n',
    latex_instruction, '\n',

    'Now output ONLY the delta needed to satisfy the edit request above.'
  )
}

# ============================================================
# TOKEN BUDGET ESTIMATION
# ============================================================
estimate_kg_max_tokens <- function(max_entities, max_relationships, words_per_entity, words_per_relationship,
                                    include_latex = FALSE) {
  max_entities <- max(1, as.numeric(max_entities))
  max_relationships <- max(1, as.numeric(max_relationships))
  words_per_entity <- max(1, as.numeric(words_per_entity))
  words_per_relationship <- max(1, as.numeric(words_per_relationship))

  latex_factor <- if (isTRUE(include_latex)) 1.3 else 1.0

  entity_overhead_words <- 20
  relationship_overhead_words <- 20

  total_words <- (max_entities * (words_per_entity + entity_overhead_words) * latex_factor) +
                 (max_relationships * (words_per_relationship + relationship_overhead_words) * latex_factor) +
                 150

  estimated_tokens <- ceiling(total_words * 1.8 * 1.2)

  max(2000, min(estimated_tokens, 64000))
}

# ============================================================
# D3 / CYTOSCAPE DATA PREP
# ============================================================
build_d3_graph_data <- function(entities_df, relationships_df) {
  nodes <- lapply(seq_len(nrow(entities_df)), function(i) {
    list(id = entities_df$entity_id[i], label = entities_df$entity_label[i],
         type = entities_df$entity_type[i], description = entities_df$entity_description[i])
  })
  links <- lapply(seq_len(nrow(relationships_df)), function(i) {
    list(source = relationships_df$source_entity_id[i], target = relationships_df$target_entity_id[i],
         predicate = relationships_df$predicate[i], description = relationships_df$relationship_description[i])
  })
  list(nodes = nodes, links = links)
}

build_cytoscape_elements <- function(entities_df, relationships_df) {
  node_elements <- lapply(seq_len(nrow(entities_df)), function(i) {
    list(data = list(id = entities_df$entity_id[i], label = entities_df$entity_label[i],
                     type = entities_df$entity_type[i], description = entities_df$entity_description[i]))
  })
  edge_elements <- lapply(seq_len(nrow(relationships_df)), function(i) {
    list(data = list(id = paste0("edge_", relationships_df$relationship_id[i]),
                     source = relationships_df$source_entity_id[i],
                     target = relationships_df$target_entity_id[i],
                     predicate = relationships_df$predicate[i],
                     description = relationships_df$relationship_description[i]))
  })
  c(node_elements, edge_elements)
}

`%||%` <- function(x, y) if (is.null(x)) y else x
