# R/utils_common.R
# Shared Utility Functions - Mind Map Suite
# ==========================================
# Core data model: every node has exactly ONE primary parent
# (parent_node_id), which by construction defines a clean, acyclic tree
# - Claude is instructed to only reference already-introduced node_ids
# as a parent, so a cycle in the PRIMARY tree is structurally
# impossible. On top of that tree, nodes may carry auxiliary
# "cross_links" to any other node (including upward, to an ancestor) -
# these are conceptual relationships, not structural ones, rendered as
# a visually distinct second layer of edges.
#
# Storage is APPEND-ONLY, mirroring the Flexible Comparison Table
# Suite: an edit is a new row (same map_id + node_id, change_type =
# 'update'), never an UPDATE/DELETE statement. "Current state" is
# always derived by taking the latest row per (map_id, node_id) and
# dropping anything whose latest change_type is 'delete'. This gives a
# free audit trail and means re-parenting a node never needs to cascade
# a write to its descendants - only a NEW node's own row changes.

safe_sql_escape <- function(input_value) {
  gsub("'", "''", input_value)
}

# ============================================================
# DELIMITER CONTRACT (cross_links field)
# ============================================================
# Same convention as the Flexible Comparison Table Suite's
# columns_data field: literal tokens Claude is instructed never to use
# elsewhere. One cross_links string can hold multiple links.
CROSS_LINK_SEP <- "|||COL|||"   # separates one cross-link entry from the next
CROSS_LINK_KV_SEP <- "|||KV|||" # separates a target node_id from its relationship label

ROOT_MARKER <- "ROOT"  # literal parent_id value for the single root node

# Generates a unique map_id for a NEW mind map (assigned by the app, not
# by Claude, so uniqueness is guaranteed regardless of what Claude returns).
generate_new_map_id <- function(topic) {
  slug <- tolower(gsub("[^a-zA-Z0-9]+", "-", trimws(topic)))
  slug <- gsub("^-+|-+$", "", slug)
  if (nchar(slug) == 0) slug <- "map"
  if (nchar(slug) > 40) slug <- substr(slug, 1, 40)
  paste0(slug, "-", format(Sys.time(), "%Y%m%d%H%M%S"))
}

build_cross_links <- function(target_ids, labels) {
  if (length(target_ids) == 0) return("")
  stopifnot(length(target_ids) == length(labels))
  entries <- mapply(function(t, l) paste0(trimws(t), CROSS_LINK_KV_SEP, trimws(l)),
                     target_ids, labels, SIMPLIFY = TRUE)
  paste(entries, collapse = CROSS_LINK_SEP)
}

parse_cross_links <- function(cross_links_text) {
  if (is.na(cross_links_text) || trimws(cross_links_text) == "" ||
      grepl("^\\(?none\\)?$", trimws(cross_links_text), ignore.case = TRUE)) {
    return(data.frame(target_node_id = character(), relationship_label = character(),
                       stringsAsFactors = FALSE))
  }

  raw <- as.character(cross_links_text)

  # Split into individual link entries using a LOOKAHEAD for the start of
  # the next entry, rather than requiring the exact literal COL_SEP
  # token. Node ids in this app are always "N" + digits, immediately
  # followed by the KV separator - so "N<digits>|||KV|||" is an
  # unambiguous marker for "a new link starts here", regardless of how
  # many pipe characters happen to precede it. This robustly handles
  # BOTH the well-formed case (a full |||COL||| precedes it) AND a
  # Claude slip observed in practice where only a bare "|||" was written
  # between two links instead of the full |||COL||| token - both leave
  # that same "N<digits>|||KV|||" marker right after the split point.
  entries <- strsplit(raw, "\\|+(?=N[0-9]+\\|\\|\\|KV\\|\\|\\|)", perl = TRUE)[[1]]
  entries <- trimws(entries)
  entries <- entries[entries != ""]
  # A well-formed |||COL||| leaves a trailing "COL" fragment stuck to
  # the end of the PRECEDING entry once the split above consumes the
  # pipes around it - strip that leftover fragment.
  entries <- sub("\\|\\|\\|COL$", "", entries)

  targets <- character(length(entries))
  labels <- character(length(entries))

  for (i in seq_along(entries)) {
    parts <- strsplit(entries[i], CROSS_LINK_KV_SEP, fixed = TRUE)[[1]]
    targets[i] <- trimws(parts[1])
    labels[i] <- if (length(parts) >= 2) trimws(paste(parts[-1], collapse = CROSS_LINK_KV_SEP)) else "related to"
  }

  data.frame(target_node_id = targets, relationship_label = labels, stringsAsFactors = FALSE)
}

# Detects the specific malformed pattern above (2+ links present but no
# full |||COL||| token anywhere) purely for a transparency WARNING -
# parse_cross_links() already repairs it via the lookahead split, so
# this never blocks anything, it just tells the user a shorthand was
# auto-corrected so they can eyeball the result rather than trust it blindly.
cross_links_used_shorthand_separator <- function(cross_links_text) {
  if (is.na(cross_links_text) || trimws(cross_links_text) == "") return(FALSE)
  raw <- as.character(cross_links_text)
  kv_matches <- gregexpr(CROSS_LINK_KV_SEP, raw, fixed = TRUE)[[1]]
  kv_count <- if (kv_matches[1] == -1) 0 else length(kv_matches)
  kv_count >= 2 && !grepl(CROSS_LINK_SEP, raw, fixed = TRUE)
}

# ============================================================
# PARSE CLAUDE'S INITIAL FULL-TREE GENERATION
# ============================================================
# Expected format:
#
# [Category]
# [Domain]
# [Topic]
# [Map Title]
#
# [node_id]: N1
# [label]: <short title>
# [content]: <summary text>
# [parent_id]: ROOT
# [cross_links]: (none)
#
# [node_id]: N2
# [label]: ...
# [content]: ...
# [parent_id]: N1
# [cross_links]: N5|||KV|||shares energy pathway with
parse_mindmap_creation_text <- function(text) {

  lines <- strsplit(text, "\n")[[1]]

  # Accepts EITHER of two metadata-line formats, since Claude's exact
  # phrasing of "wrap the value in brackets" has been observed to drift:
  #   Format A (intended): [AI]                    - bare value only
  #   Format B (also seen): [Category]: AI          - labeled, colon-separated
  # Format B is detected first (more specific pattern) so it isn't
  # accidentally swallowed by Format A's broader match.
  labeled_metadata_re <- "^\\[(Category|Domain|Topic|Map Title)\\]:\\s*(.*)$"
  bare_metadata_re <- "^\\[.+\\]$"

  category <- NULL; domain <- NULL; topic <- NULL; map_title <- NULL
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
      else if (metadata_count == 4) map_title <- value
      else break
    }
  }

  if (is.null(category) || is.null(domain) || is.null(topic)) {
    stop("Could not find Category, Domain, and Topic metadata in generated mind map text")
  }
  if (is.null(map_title)) map_title <- topic

  entries <- list()
  current_entry <- list()

  flush_entry <- function() {
    if (!is.null(current_entry$node_id)) {
      entries[[length(entries) + 1]] <<- current_entry
    }
    current_entry <<- list()
  }

  for (line in lines) {
    trimmed <- trimws(line)

    if (trimmed == "" || grepl("^\\[.+\\]$", trimmed)) {
      flush_entry()
      next
    }

    if (grepl("^\\[node_id\\]:", trimmed, ignore.case = TRUE)) {
      flush_entry()
      current_entry$node_id <- trimws(sub("^\\[node_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[label\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$node_label <- trimws(sub("^\\[label\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[content\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$node_content <- trimws(sub("^\\[content\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[parent_id\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$parent_node_id <- trimws(sub("^\\[parent_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[cross_links\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$cross_links <- trimws(sub("^\\[cross_links\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (!is.null(current_entry$node_content)) {
      current_entry$node_content <- paste0(current_entry$node_content, " ", trimmed)
    }
  }
  flush_entry()

  if (length(entries) == 0) {
    stop("No valid [node_id] entries found in generated mind map text")
  }

  nodes_df <- data.frame(
    node_id = character(), node_label = character(), node_content = character(),
    parent_node_id = character(), cross_links = character(), sort_order = integer(),
    stringsAsFactors = FALSE
  )

  # If the response was cut off by the API's token limit mid-generation,
  # it typically stops mid-way through the LAST node - most often right
  # before or during its [parent_id] line. Previously this silently
  # defaulted the missing parent_id to ROOT_MARKER, which turned a
  # truncated response into a confusing "2 nodes claim ROOT" validation
  # error instead of a clear "response was cut off" message. Now:
  #   - if it's the LAST entry and [parent_id] never appeared at all,
  #     treat it as truncation: drop the incomplete node and report it.
  #   - if any OTHER (non-last) entry is missing [parent_id], that's a
  #     genuine formatting problem, not truncation - leave its
  #     parent_node_id unresolvable ("") so validate_tree_structure()'s
  #     existing "parent_id references a node that doesn't exist" check
  #     catches it with an accurate message, instead of guessing ROOT.
  truncated_node_id <- NULL

  for (i in seq_along(entries)) {
    e <- entries[[i]]
    is_last_entry <- (i == length(entries))

    if (is.null(e$parent_node_id)) {
      if (is_last_entry) {
        truncated_node_id <- e$node_id
        next
      }
      parent_id <- ""  # genuinely malformed - let validation report it clearly
    } else {
      parent_id <- e$parent_node_id
      if (toupper(trimws(parent_id)) %in% c("", "(ROOT)", "NONE", "NA")) parent_id <- ROOT_MARKER
    }

    nodes_df <- rbind(nodes_df, data.frame(
      node_id = e$node_id,
      node_label = ifelse(is.null(e$node_label), e$node_id, e$node_label),
      node_content = ifelse(is.null(e$node_content), "", e$node_content),
      parent_node_id = parent_id,
      cross_links = ifelse(is.null(e$cross_links), "", e$cross_links),
      sort_order = i,
      stringsAsFactors = FALSE
    ))
  }

  list(category = category, domain = domain, topic = topic, map_title = map_title,
       nodes = nodes_df, truncated_node_id = truncated_node_id)
}

# ============================================================
# PARSE CLAUDE'S EDIT DELTA
# ============================================================
# Expected format - ONLY the changed nodes, one block per change:
#
# [change]: CREATE
# [node_id]: N15
# [label]: ...
# [content]: ...
# [parent_id]: N3
# [cross_links]: ...
#
# [change]: UPDATE
# [node_id]: N2
# [label]: ...
# [content]: ...
# [parent_id]: N1
# [cross_links]: ...
#
# [change]: DELETE
# [node_id]: N7
parse_mindmap_delta_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]

  entries <- list()
  current_entry <- list()

  flush_entry <- function() {
    if (!is.null(current_entry$change_type) && !is.null(current_entry$node_id)) {
      entries[[length(entries) + 1]] <<- current_entry
    }
    current_entry <<- list()
  }

  for (line in lines) {
    trimmed <- trimws(line)

    if (trimmed == "") {
      next
    }

    if (grepl("^\\[change\\]:", trimmed, ignore.case = TRUE)) {
      flush_entry()
      current_entry$change_type <- toupper(trimws(sub("^\\[change\\]:\\s*", "", trimmed, ignore.case = TRUE)))
    } else if (grepl("^\\[node_id\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$node_id <- trimws(sub("^\\[node_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[label\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$node_label <- trimws(sub("^\\[label\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[content\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$node_content <- trimws(sub("^\\[content\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[parent_id\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$parent_node_id <- trimws(sub("^\\[parent_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[cross_links\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$cross_links <- trimws(sub("^\\[cross_links\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (!is.null(current_entry$node_content)) {
      current_entry$node_content <- paste0(current_entry$node_content, " ", trimmed)
    }
  }
  flush_entry()

  if (length(entries) == 0) {
    stop("No valid [change]/[node_id] entries found in the edit response")
  }

  delta_df <- data.frame(
    change_type = character(), node_id = character(), node_label = character(),
    node_content = character(), parent_node_id = character(), cross_links = character(),
    stringsAsFactors = FALSE
  )

  for (e in entries) {
    if (!e$change_type %in% c("CREATE", "UPDATE", "DELETE")) {
      stop(sprintf("Unknown [change] type '%s' for node_id '%s' - expected CREATE, UPDATE, or DELETE",
                   e$change_type, e$node_id))
    }

    delta_df <- rbind(delta_df, data.frame(
      change_type = tolower(e$change_type),
      node_id = e$node_id,
      node_label = ifelse(is.null(e$node_label), NA, e$node_label),
      node_content = ifelse(is.null(e$node_content), NA, e$node_content),
      parent_node_id = ifelse(is.null(e$parent_node_id), NA, e$parent_node_id),
      cross_links = ifelse(is.null(e$cross_links), "", e$cross_links),
      stringsAsFactors = FALSE
    ))
  }

  delta_df
}

# ============================================================
# TREE STRUCTURE HELPERS
# ============================================================

# Computes depth (root = 0) for every node by walking parent_node_id
# chains. Guards against accidental cycles (shouldn't happen given the
# generation contract, but a broken edit could theoretically introduce
# one) with an iteration cap, flagging affected nodes rather than
# infinite-looping.
compute_node_levels <- function(nodes_df) {
  nodes_df$level <- NA_integer_
  root_idx <- which(nodes_df$parent_node_id == ROOT_MARKER | trimws(nodes_df$parent_node_id) == "")
  nodes_df$level[root_idx] <- 0

  max_iterations <- nrow(nodes_df) + 2
  for (iter in seq_len(max_iterations)) {
    unresolved <- which(is.na(nodes_df$level))
    if (length(unresolved) == 0) break

    changed <- FALSE
    for (i in unresolved) {
      parent_idx <- which(nodes_df$node_id == nodes_df$parent_node_id[i])
      if (length(parent_idx) == 1 && !is.na(nodes_df$level[parent_idx])) {
        nodes_df$level[i] <- nodes_df$level[parent_idx] + 1
        changed <- TRUE
      }
    }
    if (!changed) break  # remaining unresolved nodes have a broken/cyclic parent chain
  }

  # Any node whose level never resolved has an invalid parent reference
  # (points to a non-existent node_id, or is part of a cycle) - treat as
  # a second-class root so it still renders instead of vanishing.
  nodes_df$level[is.na(nodes_df$level)] <- 0
  nodes_df
}

# Validates a freshly parsed tree BEFORE upload, catching malformed
# Claude output early with a clear error instead of silently corrupting
# the stored map. Returns TWO separate lists:
#   - issues:   structural problems that BLOCK the upload (bad root,
#               duplicate node_id, a parent_id pointing nowhere - any of
#               these would corrupt the tree itself)
#   - warnings: non-structural problems that do NOT block the upload,
#               currently just a cross_links target that doesn't exist.
#               A dangling cross-link doesn't corrupt the tree - the
#               renderer already silently skips it - but the user should
#               still be told, rather than it fail invisibly.
validate_tree_structure <- function(nodes_df, max_root_children = NULL, max_children_per_node = NULL) {
  issues <- c()
  warnings <- c()

  if (sum(nodes_df$parent_node_id == ROOT_MARKER) == 0) {
    issues <- c(issues, "No node has parent_id = ROOT - a mind map needs exactly one root node.")
  }
  if (sum(nodes_df$parent_node_id == ROOT_MARKER) > 1) {
    issues <- c(issues, sprintf(
      "%d nodes claim parent_id = ROOT - a mind map should have exactly one root.",
      sum(nodes_df$parent_node_id == ROOT_MARKER)
    ))
  }
  if (any(duplicated(nodes_df$node_id))) {
    dupes <- unique(nodes_df$node_id[duplicated(nodes_df$node_id)])
    issues <- c(issues, sprintf("Duplicate node_id(s) found: %s", paste(dupes, collapse = ", ")))
  }

  non_root <- nodes_df[nodes_df$parent_node_id != ROOT_MARKER, ]
  missing_parents <- setdiff(non_root$parent_node_id, nodes_df$node_id)
  if (length(missing_parents) > 0) {
    issues <- c(issues, sprintf(
      "%d node(s) reference a parent_id that doesn't exist among the generated nodes: %s",
      length(missing_parents), paste(missing_parents, collapse = ", ")
    ))
  }

  # ---- Cross-link target existence (non-blocking) ----
  dangling <- c()
  for (i in seq_len(nrow(nodes_df))) {
    cl <- parse_cross_links(nodes_df$cross_links[i])
    if (nrow(cl) == 0) next
    bad_targets <- setdiff(cl$target_node_id, nodes_df$node_id)
    if (length(bad_targets) > 0) {
      dangling <- c(dangling, sprintf("%s -> %s", nodes_df$node_id[i], paste(bad_targets, collapse = ", ")))
    }
  }
  if (length(dangling) > 0) {
    warnings <- c(warnings, sprintf(
      "%d cross-link(s) point to a node_id that doesn't exist and will be silently skipped when rendered: %s",
      length(dangling), paste(dangling, collapse = "; ")
    ))
  }

  shorthand_nodes <- nodes_df$node_id[vapply(nodes_df$cross_links, cross_links_used_shorthand_separator, logical(1))]
  if (length(shorthand_nodes) > 0) {
    warnings <- c(warnings, sprintf(
      "%d node(s) had multiple cross-links joined with a shorthand '|||' instead of the full '|||COL|||' token - auto-corrected, but worth double-checking: %s",
      length(shorthand_nodes), paste(shorthand_nodes, collapse = ", ")
    ))
  }

  # ---- Branching-factor cap verification (defense-in-depth) ----
  # These are enforced as HARD CAPS in the generation prompt (see
  # build_mindmap_rules_block()), but LLM output isn't infallible at
  # obeying numeric constraints, so double-check the actual result here.
  # Non-blocking: exceeding a branching cap doesn't corrupt the tree,
  # it's a "the map is a bit bushier than requested" issue.
  if (!is.null(max_root_children)) {
    root_id <- nodes_df$node_id[nodes_df$parent_node_id == ROOT_MARKER]
    if (length(root_id) == 1) {
      root_children_count <- sum(nodes_df$parent_node_id == root_id)
      if (root_children_count > max_root_children) {
        warnings <- c(warnings, sprintf(
          "The root node has %d direct children, exceeding the requested cap of %d.",
          root_children_count, max_root_children
        ))
      }
    }
  }
  if (!is.null(max_children_per_node)) {
    non_root_ids <- nodes_df$node_id[nodes_df$parent_node_id != ROOT_MARKER]
    child_counts <- table(nodes_df$parent_node_id[nodes_df$parent_node_id %in% non_root_ids])
    over_cap <- child_counts[child_counts > max_children_per_node]
    if (length(over_cap) > 0) {
      warnings <- c(warnings, sprintf(
        "%d node(s) exceed the requested cap of %d children each: %s",
        length(over_cap), max_children_per_node,
        paste(sprintf("%s (%d)", names(over_cap), as.integer(over_cap)), collapse = ", ")
      ))
    }
  }

  list(valid = length(issues) == 0, issues = issues, warnings = warnings)
}

# ============================================================
# AUTO-PRUNE SPURIOUS EMPTY/DISCONNECTED NODES
# ============================================================
# Occasionally Claude's response includes a trailing, malformed extra
# node block - empty label, empty content, no children, not referenced
# by any cross-link - most commonly a second bogus [parent_id]: ROOT
# block tacked on at the very end. It carries no information and isn't
# connected to anything, so it's safe to silently drop BEFORE
# validation runs, rather than blocking the whole upload over an
# artifact the user never asked for and would almost certainly just
# want removed anyway.
#
# Deliberately conservative: a node is only ever pruned if ALL of the
# following hold, so a genuine (if oddly-placed) real node is never
# touched:
#   - its label is blank OR merely echoes its own node_id (the parser's
#     fallback when [label] was omitted - see parse_mindmap_creation_text)
#   - its content is blank
#   - no other node claims it as a parent (it has zero children)
#   - no cross-link, from any node, targets it
# Runs iteratively so a short CHAIN of empty stray nodes (rare, but
# possible) is fully cleared, not just the first one.
prune_empty_disconnected_nodes <- function(nodes_df) {
  pruned_ids <- character(0)
  is_blank <- function(x) is.na(x) || trimws(x) == ""

  max_iterations <- nrow(nodes_df) + 2
  for (iter in seq_len(max_iterations)) {
    if (nrow(nodes_df) == 0) break

    referenced_as_parent <- unique(nodes_df$parent_node_id)
    referenced_as_crosslink_target <- unique(unlist(lapply(seq_len(nrow(nodes_df)), function(i) {
      parse_cross_links(nodes_df$cross_links[i])$target_node_id
    })))

    is_candidate <- vapply(seq_len(nrow(nodes_df)), function(i) {
      row <- nodes_df[i, ]
      label_is_empty_or_selfref <- is_blank(row$node_label) || identical(row$node_label, row$node_id)
      content_is_empty <- is_blank(row$node_content)
      has_no_children <- !(row$node_id %in% referenced_as_parent)
      not_a_crosslink_target <- !(row$node_id %in% referenced_as_crosslink_target)
      label_is_empty_or_selfref && content_is_empty && has_no_children && not_a_crosslink_target
    }, logical(1))

    if (!any(is_candidate)) break

    pruned_ids <- c(pruned_ids, nodes_df$node_id[is_candidate])
    nodes_df <- nodes_df[!is_candidate, ]
  }

  list(nodes = nodes_df, pruned_ids = unique(pruned_ids))
}

# Given the CURRENT tree (data.frame with node_id, parent_node_id) and a
# node_id to delete, returns that node_id plus every descendant - the
# full cascade set. Computed by the APP, not by Claude, so it can never
# miss a node the way an LLM enumerating a large subtree by hand might.
compute_cascade_delete <- function(nodes_df, node_id_to_delete) {
  to_delete <- character(0)
  frontier <- node_id_to_delete

  max_iterations <- nrow(nodes_df) + 2
  for (iter in seq_len(max_iterations)) {
    if (length(frontier) == 0) break
    to_delete <- c(to_delete, frontier)
    children <- nodes_df$node_id[nodes_df$parent_node_id %in% frontier]
    frontier <- setdiff(children, to_delete)
  }

  unique(to_delete)
}

# Compact indented outline of the CURRENT tree, used as context inside
# the edit prompt so Claude can see the existing structure without
# needing to be sent the entire raw delimited storage format.
serialize_tree_for_prompt <- function(nodes_df, max_words_per_node = 60) {
  if (nrow(nodes_df) == 0) return("(empty map)")

  nodes_df <- compute_node_levels(nodes_df)
  nodes_df <- nodes_df[order(nodes_df$level, nodes_df$sort_order %||% 0), ]

  truncate_words <- function(text, n) {
    words <- strsplit(text, "\\s+")[[1]]
    if (length(words) <= n) return(text)
    paste0(paste(words[seq_len(n)], collapse = " "), " ...")
  }

  lines <- c()
  for (i in seq_len(nrow(nodes_df))) {
    indent <- strrep("  ", nodes_df$level[i])
    root_tag <- if (nodes_df$parent_node_id[i] == ROOT_MARKER) " (ROOT)" else ""
    content_preview <- truncate_words(nodes_df$node_content[i], max_words_per_node)
    lines <- c(lines, sprintf("%s%s: %s%s - %s",
                              indent, nodes_df$node_id[i], nodes_df$node_label[i],
                              root_tag, content_preview))
  }

  cross_link_lines <- c()
  for (i in seq_len(nrow(nodes_df))) {
    cl <- parse_cross_links(nodes_df$cross_links[i])
    if (nrow(cl) > 0) {
      for (j in seq_len(nrow(cl))) {
        cross_link_lines <- c(cross_link_lines, sprintf("%s -> %s (%s)",
                                                          nodes_df$node_id[i], cl$target_node_id[j],
                                                          cl$relationship_label[j]))
      }
    }
  }

  paste0(
    "TREE STRUCTURE (indented by depth):\n",
    paste(lines, collapse = "\n"),
    if (length(cross_link_lines) > 0) paste0("\n\nCROSS-LINKS:\n", paste(cross_link_lines, collapse = "\n")) else "\n\nCROSS-LINKS: (none)"
  )
}

# Given existing node_ids like "N1", "N7", "N14", returns the next
# unused integer suffix (15 in this example) so new CREATE nodes in an
# edit delta never collide with existing ids.
next_available_node_id_num <- function(nodes_df) {
  if (nrow(nodes_df) == 0) return(1)
  nums <- suppressWarnings(as.integer(gsub("^N", "", nodes_df$node_id, ignore.case = TRUE)))
  nums <- nums[!is.na(nums)]
  if (length(nums) == 0) return(1)
  max(nums) + 1
}

# ============================================================
# D3 VISUALIZATION DATA PREP
# ============================================================
# The D3-based mind map renderer (modules/visualize_mindmap) needs two
# JSON-serializable structures built from the flat nodes_df:
#   1. A NESTED hierarchy (d3.hierarchy() requires {id, label, content,
#      children: [...]}), built by walking parent_node_id downward from
#      the single ROOT node.
#   2. A FLAT array of cross-links ({source, target, label}), drawn as
#      a second, visually distinct layer of curved edges once the tree
#      layout has assigned every node a position.

# Recursively builds the nested tree from a flat nodes_df. Returns NULL
# if there isn't exactly one root (should already have been caught by
# validate_tree_structure() before this is ever called).
build_d3_tree <- function(nodes_df) {
  root_rows <- nodes_df[nodes_df$parent_node_id == ROOT_MARKER, ]
  if (nrow(root_rows) != 1) return(NULL)

  build_node <- function(node_id) {
    row <- nodes_df[nodes_df$node_id == node_id, ][1, ]
    child_ids <- nodes_df$node_id[nodes_df$parent_node_id == node_id]

    node <- list(
      id = row$node_id,
      label = row$node_label,
      content = row$node_content
    )
    if (length(child_ids) > 0) {
      node$children <- lapply(child_ids, build_node)
    }
    node
  }

  build_node(root_rows$node_id[1])
}

# Flat {source, target, label} list for every cross-link whose target
# actually exists in the current tree (dangling targets are silently
# skipped here too, matching the same rule used elsewhere).
build_d3_cross_links <- function(nodes_df) {
  links <- list()
  for (i in seq_len(nrow(nodes_df))) {
    cl <- parse_cross_links(nodes_df$cross_links[i])
    if (nrow(cl) == 0) next
    for (j in seq_len(nrow(cl))) {
      if (cl$target_node_id[j] %in% nodes_df$node_id) {
        links[[length(links) + 1]] <- list(
          source = nodes_df$node_id[i],
          target = cl$target_node_id[j],
          label = cl$relationship_label[j]
        )
      }
    }
  }
  links
}

# ============================================================
# CATEGORY / DOMAIN / TOPIC HIERARCHICAL CLASSIFICATION
# ============================================================
CATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_CATEGORY__"
DOMAIN_ADD_NEW_VALUE <- "__ADD_NEW_DOMAIN__"
TOPIC_ADD_NEW_VALUE <- "__ADD_NEW_TOPIC__"

# Reusable UI block: Category -> Domain -> Topic, each with "+ Add New"
# and a conditional text box. `ns` must be the calling module's NS(id).
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
      textInput(ns("new_domain_text"), "New Domain Name:", placeholder = "e.g., Biology")
    ),
    selectInput(ns("topic_select"), "Topic: *",
                choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("topic_select"), TOPIC_ADD_NEW_VALUE),
      textInput(ns("new_topic_text"), "New Topic Name:", placeholder = "e.g., Cell Structure")
    )
  )
}

# Wires up the reactive 3-level cascade. Returns reactive() ->
# list(category=, domain=, topic=) with resolved final values.
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
# GENERATE CLAUDE PROMPT - INITIAL FULL TREE CREATION
# ============================================================
# Structured as RULES FIRST, REQUEST SECOND: Claude is given the full
# structural "constitution" of how a mind map must be built (root rule,
# ordering rule, tag format, delimiter contract, branching HARD CAPS,
# LaTeX policy, formatting rules) before it ever sees the specific
# topic being asked for. This is deliberate - for a structured-output
# task like this, giving the model the complete rule set as context
# BEFORE the task description tends to produce more reliable adherence
# than stating the task first and appending rules afterward.
build_mindmap_rules_block <- function(include_latex = FALSE, words_per_node = 40,
                                       max_root_children = 6, max_children_per_node = 5) {

  latex_instruction <- if (isTRUE(include_latex)) {
    paste0(
      '- Where a formula or equation is genuinely relevant inside a node\'s [content], you may use LaTeX ',
      'syntax: $inline$ or $$display$$. Do not force it where not relevant.\n'
    )
  } else {
    paste0(
      '- Do NOT use any LaTeX syntax anywhere (no $...$, no $$...$$, no \\frac, \\sum, etc). ',
      'Express any formulas in plain text instead.\n'
    )
  }

  paste0(
    'You are an assistant that generates MIND MAPS (hierarchical trees with optional cross-links) ',
    'for a web app. Before you see the specific topic to build, read and internalize ALL of the ',
    'following rules - they apply to every mind map you generate, no exceptions.\n\n',

    '========== MIND MAP STRUCTURAL RULES ==========\n\n',

    '1. OUTPUT FORMAT - the response must consist of:\n',
    '   - Exactly 4 metadata lines at the very top, each on its own line. Each line must contain ONLY the actual value wrapped in single square brackets - do NOT include a field name, label, or colon inside or around the brackets. For example, if the Category is "Finance", the Domain is "Investing", the Topic is "Value Investing", and the Map Title is "Principles of Value Investing", the first 4 lines of your entire response must be EXACTLY:\n',
    '     [Finance]\n',
    '     [Investing]\n',
    '     [Value Investing]\n',
    '     [Principles of Value Investing]\n',
    '     Do NOT write "[Category]: Finance" or "[Category] Finance" or add any other text on these lines - only the bracketed value itself, nothing else.\n',
    '   - Then ONE block per node, in the order you introduce them (a node\'s parent must always be introduced before it), with EXACTLY these 5 tagged lines per block, separated from the next block by ONE blank line:\n',
    '      [node_id]: <a short unique id, e.g. N1, N2, N3, ... incrementing for every node>\n',
    '      [label]: <a SHORT title shown directly on the map node itself - a few words max>\n',
    '      [content]: <a longer summary shown when the node is clicked/expanded - approx ', words_per_node, ' words max>\n',
    '      [parent_id]: <the node_id of this node\'s ONE primary parent in the hierarchy>\n',
    '      [cross_links]: <optional additional relationships to OTHER nodes - see rule 3 - or "(none)">\n\n',

    '2. THE ROOT NODE AND HIERARCHY (critical, non-negotiable):\n',
    '   - Exactly ONE node must have [parent_id]: ROOT (this literal word) - this is the single root of the map.\n',
    '   - EVERY other node\'s [parent_id] MUST be the node_id of a node ALREADY introduced earlier in this same response - never reference a node_id that comes later or does not exist. This guarantees the tree has no cycles.\n',
    '   - HARD CAP: the root node may have AT MOST ', max_root_children, ' direct children (nodes whose [parent_id] is the root\'s node_id). Never exceed this, even if more items would seem relevant - if there are more candidates than fit, select only the ', max_root_children, ' most important/representative ones.\n',
    '   - HARD CAP: any OTHER (non-root) node may have AT MOST ', max_children_per_node, ' direct children. Never exceed this either, for the same reason.\n\n',

    '3. CROSS-LINKS (optional, structurally separate from parent_id):\n',
    '   - A cross_link is an ADDITIONAL relationship from this node to any OTHER node anywhere in the map - including nodes introduced LATER, or nodes higher up the hierarchy (e.g. a node linking back to an ancestor or to a node under a completely different branch). This is different from parent_id, which is strictly the primary hierarchy position, and cross-links do NOT count toward the branching HARD CAPS in rule 2 (those only govern parent_id/child relationships).\n',
    '   - Format for ONE cross-link: <target_node_id>', CROSS_LINK_KV_SEP, '<short relationship label, e.g. "builds on", "contrasts with", "depends on">\n',
    '   - Format for MULTIPLE cross-links on the same node: join them with the FULL literal token "', CROSS_LINK_SEP, '" between each complete entry - never just a bare "|||". For example, a node linking to both N5 and N3 must be written EXACTLY like this:\n',
    '     [cross_links]: N5', CROSS_LINK_KV_SEP, 'builds on', CROSS_LINK_SEP, 'N3', CROSS_LINK_KV_SEP, 'extends\n',
    '     NOT like this (missing the "COL" part of the separator - this is a common mistake, avoid it): [cross_links]: N5', CROSS_LINK_KV_SEP, 'builds on|||N3', CROSS_LINK_KV_SEP, 'extends\n',
    '   - Use cross-links sparingly and only where a genuinely meaningful relationship exists beyond the tree structure - most nodes will have [cross_links]: (none).\n',
    '   - NEVER use "', CROSS_LINK_SEP, '" or "', CROSS_LINK_KV_SEP, '" anywhere else in your response (not in labels, content, or metadata).\n\n',

    '4. CONTENT RULES:\n',
    latex_instruction,
    '   - Each [content] value must stay close to the ', words_per_node, '-word target - concise and specific, not padded.\n\n',

    '5. FORMATTING RULES:\n',
    '   - NO extra markdown, NO headers with #, NO numbered list markers, NO markdown tables.\n',
    '   - Separate each node block with exactly ONE blank line.\n',
    '   - Use the exact bracket tag format shown in rule 1 - do not deviate, add extra tags, or omit any of the 5.\n\n',

    '========== END OF RULES ==========\n\n'
  )
}

generate_mindmap_prompt <- function(category, domain, topic, map_title,
                                     request_description,
                                     include_latex = FALSE,
                                     words_per_node = 40,
                                     max_nodes = 12,
                                     max_depth = 3,
                                     max_root_children = 6,
                                     max_children_per_node = 5) {

  rules_block <- build_mindmap_rules_block(
    include_latex = include_latex, words_per_node = words_per_node,
    max_root_children = max_root_children, max_children_per_node = max_children_per_node
  )

  request_block <- paste0(
    '========== YOUR TASK ==========\n\n',
    'Now build a mind map following ALL the rules above, for:\n\n',
    'Category: ', category, '\n',
    'Domain: ', domain, '\n',
    'Topic: ', topic, '\n',
    'Map Title: ', map_title, '\n\n',

    'User request: ', request_description, '\n\n',

    'SIZE TARGET (soft - a guideline, not a hard cap like the branching rules above): aim for around ',
    max_nodes, ' nodes total, with a maximum depth of ', max_depth, ' levels below the root (root = depth 0) ',
    '- UNLESS the user request above clearly implies a different count, in which case follow the user request, ',
    'while still always respecting the HARD branching caps from rule 2.\n\n',

    'Begin your response now with the 4 metadata lines, then the node blocks, exactly as specified in rule 1.'
  )

  paste0(rules_block, request_block)
}

# ============================================================
# GENERATE CLAUDE PROMPT - EDIT DELTA (existing map)
# ============================================================
# Claude receives the CURRENT tree (compact serialization) and an
# edit request, and returns ONLY what changed - never the whole tree.
# Cascade deletion of a node's descendants is computed by the APP
# afterward (see compute_cascade_delete()), not requested from Claude.
generate_mindmap_edit_prompt <- function(category, domain, topic, map_title,
                                          current_tree_text, edit_request,
                                          next_id_start,
                                          include_latex = FALSE,
                                          words_per_node = 40) {

  latex_instruction <- if (isTRUE(include_latex)) {
    '- Where a formula is genuinely relevant, you may use LaTeX ($inline$ or $$display$$).\n'
  } else {
    '- Do NOT use any LaTeX syntax anywhere - plain text only.\n'
  }

  prompt <- paste0(
    'You are editing an EXISTING mind map for a web app. You must output ONLY the CHANGES needed - ',
    'never re-output nodes that are not changing.\n\n',

    'Category: ', category, ' | Domain: ', domain, ' | Topic: ', topic, ' | Map Title: ', map_title, '\n\n',

    'CURRENT TREE (for your reference only - do not re-output unchanged nodes):\n',
    current_tree_text, '\n\n',

    'EDIT REQUEST: ', edit_request, '\n\n',

    'Format Requirements - follow this EXACTLY:\n\n',

    '1. Output ONE block per CHANGE, separated by ONE blank line, with these tagged lines:\n\n',

    'For a NEW node:\n',
    '[change]: CREATE\n',
    '[node_id]: <a NEW id starting at N', next_id_start, ' and incrementing - NEVER reuse an existing node_id>\n',
    '[label]: <short title>\n',
    '[content]: <approx ', words_per_node, ' words max>\n',
    '[parent_id]: <an EXISTING node_id from the current tree above, or ROOT if this somehow becomes a new root (rare)>\n',
    '[cross_links]: <optional, same format as before, or "(none)">\n\n',

    'For an EXISTING node whose content/label/parent/cross_links changed:\n',
    '[change]: UPDATE\n',
    '[node_id]: <the EXISTING node_id being changed>\n',
    '[label]: <the FULL new label (even if only content changed, repeat the label)>\n',
    '[content]: <the FULL new content (even if only the label changed, repeat the content)>\n',
    '[parent_id]: <the FULL current or new parent_id (repeat existing value if not moving this node)>\n',
    '[cross_links]: <the FULL current or new cross_links (repeat existing value if unchanged), or "(none)">\n\n',

    'For a node to remove:\n',
    '[change]: DELETE\n',
    '[node_id]: <the EXISTING node_id to delete>\n',
    '(no other tags needed for DELETE - the app will automatically also remove any descendants of this node, so you do NOT need to individually list its children as separate DELETE blocks unless you specifically want ONLY that one node removed and its children re-attached elsewhere, in which case issue UPDATE blocks for those children with a new parent_id INSTEAD of deleting them)\n\n',

    '2. CRITICAL RULES:\n',
    '   - Do NOT output blocks for nodes that are not changing.\n',
    '   - Do NOT re-output the entire tree.\n',
    '   - For CREATE, only reference an EXISTING node_id (from the current tree above) as [parent_id], unless chaining multiple new CREATE nodes together, in which case you may reference a node_id you just created earlier in this same response.\n',
    '   - NEVER invent a change to a node_id that does not exist in the current tree (for UPDATE/DELETE).\n',
    latex_instruction, '\n',

    'Now output ONLY the delta needed to satisfy the edit request above.'
  )

  return(prompt)
}

# ============================================================
# TOKEN BUDGET ESTIMATION
# ============================================================
# Deliberately generous. Under-budgeting doesn't just waste a little
# headroom - it causes Claude's response to be cut off by the API's own
# max_tokens limit mid-generation, which almost always happens at the
# LAST node, right before or during its [parent_id] line. That's a far
# worse failure mode than a slightly oversized request: a truncated
# response produces an incomplete tree that used to (before this fix)
# masquerade as a confusing "2 nodes claim ROOT" structural error. See
# parse_mindmap_creation_text()'s truncated_node_id handling.
estimate_mindmap_max_tokens <- function(max_nodes, words_per_node, include_latex = FALSE) {
  max_nodes <- max(1, as.numeric(max_nodes))
  words_per_node <- max(1, as.numeric(words_per_node))

  latex_factor <- if (isTRUE(include_latex)) 1.3 else 1.0

  # Structural overhead per node: the 5 tag labels, a short label field,
  # a parent_id, and - critically - headroom for cross_links. The
  # ||| delimiter tokens do NOT compress well under BPE tokenization
  # (punctuation-heavy, unusual sequences typically cost several real
  # API tokens each, not "one word"), and a meaningful fraction of nodes
  # carry 1-2 cross-links in practice. 25 words/node badly undercounted
  # this; 55 is a much safer real-world estimate.
  per_node_overhead_words <- 55

  total_words <- (max_nodes * words_per_node * latex_factor) + (max_nodes * per_node_overhead_words) + 150

  # ~1.8 tokens/word (vs. a plain-prose ~1.3-1.5) to absorb the
  # delimiter-heavy, punctuation-dense format, plus an explicit 20%
  # safety margin on top of that - erring toward "too large" is nearly
  # free, while erring toward "too small" corrupts the upload.
  estimated_tokens <- ceiling(total_words * 1.8 * 1.2)

  max(2500, min(estimated_tokens, 64000))
}

