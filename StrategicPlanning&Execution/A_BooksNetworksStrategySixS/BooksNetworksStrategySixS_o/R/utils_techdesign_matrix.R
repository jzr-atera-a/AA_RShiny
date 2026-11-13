# R/utils_techdesign_matrix.R
# ============================================================
# MARKET MATRIX - dual hierarchy + evidence matrix
# ============================================================
# Data model, parsing, hierarchy building, prompts, source verification and
# BigQuery row conversion. Drawing lives in utils_techdesign_matrix_render.R.
#
# Storage: ONE row per version in the existing technical_designs table
# (design_group = "market_matrix", diagram_kind = "matrix"). The full payload
# (items, cells with evidence, sources, authored trees, branch names) is kept
# as JSON in extras_json; items / cells / sources are ALSO mirrored into
# components_json / connections_json / references_json so plain SQL works.

TDM_GROUP <- "market_matrix"
TDM_CONF <- c("sourced", "partial", "judgment")
TDM_PALETTE <- c("#2563EB", "#7C3AED", "#EA580C", "#CA8A04", "#0D9488",
                 "#DB2777", "#64748B", "#16A34A", "#0891B2", "#B91C1C")
TDM_CELL_COLS <- c("row", "col", "score", "confidence", "metric", "value", "as_of",
                   "quote", "source_ids", "rationale", "verified")

tdm_chr <- function(x) {
  if (is.null(x) || length(x) == 0) return("")
  x <- x[[1]]
  if (is.null(x) || is.na(x)) return("")
  trimws(as.character(x))
}
tdm_id <- function(x) {
  x <- tolower(gsub("[^A-Za-z0-9]+", "_", trimws(as.character(x))))
  gsub("^_+|_+$", "", x)
}
tdm_sort <- function(x) sort(x, method = "radix")
tdm_sig <- function(ids) paste(tdm_sort(ids), collapse = "+")

tdm_empty_df <- function(cols) {
  as.data.frame(setNames(replicate(length(cols), character(0), simplify = FALSE), cols), stringsAsFactors = FALSE)
}

tdm_empty <- function() {
  list(
    meta = list(design_id = "", title = "", subtitle = "", row_axis = "Rows", col_axis = "Columns",
                score_definition = "Relevance of the column to the row, 0 (none) to 100 (very high).",
                tree_mode = "computed", topic = "", generated_with = "", research = ""),
    rows = tdm_empty_df(c("id", "label", "class")),
    cols = tdm_empty_df(c("id", "label", "category", "metric_hint", "scoring_rule")),
    cells = {
      df <- tdm_empty_df(TDM_CELL_COLS); df$score <- numeric(0); df
    },
    sources = tdm_empty_df(c("id", "title", "publisher", "url", "in_search_results", "reachable")),
    row_tree = NULL, col_tree = NULL,
    row_names = list(), col_names = list(),
    warnings = character(0)
  )
}

# ---- JSON extraction ------------------------------------------------------
tdm_extract_json <- function(text) {
  text <- gsub("\r", "", text %||% "")
  text <- gsub("```[a-zA-Z]*", "", text)
  a <- regexpr("{", text, fixed = TRUE)
  if (a < 0) stop("No JSON object was found in the response.")
  chars <- strsplit(text, "", fixed = TRUE)[[1]]
  depth <- 0L; in_str <- FALSE; esc <- FALSE; end <- NA_integer_
  for (i in seq.int(a, length(chars))) {
    ch <- chars[i]
    if (in_str) {
      if (esc) esc <- FALSE else if (ch == "\\") esc <- TRUE else if (ch == "\"") in_str <- FALSE
    } else if (ch == "\"") in_str <- TRUE
    else if (ch == "{") depth <- depth + 1L
    else if (ch == "}") { depth <- depth - 1L; if (depth == 0L) { end <- i; break } }
  }
  if (is.na(end)) stop("The JSON in the response is incomplete (it was probably cut off by the token limit).")
  js <- paste(chars[a:end], collapse = "")
  out <- tryCatch(jsonlite::fromJSON(js, simplifyVector = FALSE), error = function(e) stop("Invalid JSON: ", e$message))
  if (!is.list(out)) stop("The JSON is not an object.")
  out
}

tdm_list_to_df <- function(lst, cols) {
  if (length(lst) == 0) return(tdm_empty_df(cols))
  rows <- lapply(lst, function(b) {
    vals <- vapply(cols, function(cn) tdm_chr(b[[cn]]), character(1))
    as.data.frame(as.list(vals), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows); rownames(out) <- NULL; out
}

tdm_src_ids <- function(x) {
  if (is.null(x)) return("")
  if (is.list(x)) x <- unlist(x)
  paste(trimws(as.character(x)), collapse = ",")
}

# ---- authored tree (nested list: name + children; leaves are ids) ----------
tdm_authored_to_node <- function(x, valid) {
  if (is.character(x) || (is.list(x) && is.null(x$children) && is.null(x$name))) {
    id <- tdm_id(if (is.list(x)) unlist(x)[1] else x)
    if (id %in% valid) return(list(leaf = TRUE, id = id, h = 0, n = 1L, sig = id, leaves = id))
    return(NULL)
  }
  kids <- Filter(Negate(is.null), lapply(x$children %||% list(), tdm_authored_to_node, valid = valid))
  if (length(kids) == 0) return(NULL)
  if (length(kids) == 1) return(kids[[1]])
  leaves <- unlist(lapply(kids, function(k) k$leaves))
  list(leaf = FALSE, name = tdm_chr(x$name), children = kids, h = max(vapply(kids, function(k) k$h, numeric(1))) + 1,
       n = length(leaves), sig = tdm_sig(leaves), leaves = leaves)
}

# Authored tree + any rows the tree forgot (kept visible under "Other")
tdm_build_authored_tree <- function(tree_list, ids) {
  root <- tdm_authored_to_node(tree_list, ids)
  warn <- character(0)
  if (is.null(root)) return(list(tree = NULL, warnings = "The authored hierarchy contained no valid items; a computed one is used instead."))
  missing <- setdiff(ids, root$leaves)
  if (length(missing) > 0) {
    warn <- c(warn, sprintf("%d item(s) missing from the authored hierarchy were grouped under 'Other'.", length(missing)))
    kids <- lapply(missing, function(i) list(leaf = TRUE, id = i, h = 0, n = 1L, sig = i, leaves = i))
    other <- if (length(kids) == 1) kids[[1]] else list(leaf = FALSE, name = "Other", children = kids, h = 1, n = length(kids), sig = tdm_sig(missing), leaves = missing)
    all_l <- c(root$leaves, missing)
    root <- list(leaf = FALSE, name = "", children = list(root, other), h = max(root$h, other$h) + 1, n = length(all_l), sig = tdm_sig(all_l), leaves = all_l)
  }
  list(tree = root, warnings = warn)
}

# ---- computed tree (Ward linkage on score profiles) -------------------------
tdm_hclust_tree <- function(M, ids) {
  n <- length(ids)
  if (n == 1) return(list(leaf = TRUE, id = ids, h = 0, n = 1L, sig = ids, leaves = ids))
  if (n == 2) {
    kids <- lapply(ids, function(i) list(leaf = TRUE, id = i, h = 0, n = 1L, sig = i, leaves = i))
    return(list(leaf = FALSE, name = "", children = kids, h = sqrt(sum((M[1, ] - M[2, ])^2)), n = 2L, sig = tdm_sig(ids), leaves = ids))
  }
  hc <- stats::hclust(stats::dist(M), method = "ward.D2")
  nodes <- vector("list", n - 1)
  get <- function(k) if (k < 0) list(leaf = TRUE, id = ids[-k], h = 0, n = 1L, sig = ids[-k], leaves = ids[-k]) else nodes[[k]]
  for (k in seq_len(n - 1)) {
    a <- get(hc$merge[k, 1]); b <- get(hc$merge[k, 2])
    lv <- c(a$leaves, b$leaves)
    nodes[[k]] <- list(leaf = FALSE, name = "", children = list(a, b), h = hc$height[k], n = length(lv),
                       sig = tdm_sig(lv), leaves = lv)
  }
  nodes[[n - 1]]
}

tdm_score_matrix <- function(d) {
  M <- matrix(0, nrow = nrow(d$rows), ncol = nrow(d$cols), dimnames = list(d$rows$id, d$cols$id))
  if (nrow(d$cells) > 0) {
    ri <- match(d$cells$row, d$rows$id); ci <- match(d$cells$col, d$cols$id)
    ok <- !is.na(ri) & !is.na(ci)
    M[cbind(ri[ok], ci[ok])] <- d$cells$score[ok]
  }
  M
}

# Returns list(row = tree, col = tree). Authored trees win when present.
tdm_trees <- function(d) {
  M <- tdm_score_matrix(d)
  rt <- NULL; ct <- NULL
  if (!is.null(d$row_tree)) rt <- tdm_build_authored_tree(d$row_tree, d$rows$id)$tree
  if (!is.null(d$col_tree)) ct <- tdm_build_authored_tree(d$col_tree, d$cols$id)$tree
  if (is.null(rt)) rt <- tdm_hclust_tree(M, d$rows$id)
  if (is.null(ct)) ct <- tdm_hclust_tree(t(M), d$cols$id)
  list(row = rt, col = ct)
}

# Internal nodes, biggest first - used by the naming prompt and the renderer
tdm_internal_nodes <- function(tree) {
  out <- list()
  walk <- function(nd) {
    if (isTRUE(nd$leaf)) return(invisible())
    out[[length(out) + 1]] <<- nd
    for (k in nd$children) walk(k)
  }
  walk(tree)
  if (length(out) == 0) return(out)
  ord <- order(-vapply(out, function(z) z$h, numeric(1)), -vapply(out, function(z) z$n, numeric(1)))
  out[ord]
}

# ---- Parse the editable JSON text -------------------------------------------
parse_matrix_text <- function(text) {
  j <- tdm_extract_json(text)
  d <- tdm_empty()
  warn <- character(0)

  m <- j$meta %||% j
  for (k in c("design_id", "title", "subtitle", "row_axis", "col_axis", "score_definition", "tree_mode", "topic", "generated_with", "research")) {
    v <- tdm_chr(m[[k]]); if (nzchar(v)) d$meta[[k]] <- v
  }
  if (!d$meta$tree_mode %in% c("computed", "authored")) d$meta$tree_mode <- "computed"

  d$rows <- tdm_list_to_df(j$rows, c("id", "label", "class"))
  d$cols <- tdm_list_to_df(j$cols, c("id", "label", "category", "metric_hint", "scoring_rule"))
  d$rows$id <- tdm_id(d$rows$id); d$cols$id <- tdm_id(d$cols$id)
  d$rows$label[d$rows$label == ""] <- d$rows$id[d$rows$label == ""]
  d$cols$label[d$cols$label == ""] <- d$cols$id[d$cols$label == ""]
  d$rows$class[d$rows$class == ""] <- "Other"
  d$cols$category[d$cols$category == ""] <- "Other"
  d$rows <- d$rows[nzchar(d$rows$id) & !duplicated(d$rows$id), , drop = FALSE]
  d$cols <- d$cols[nzchar(d$cols$id) & !duplicated(d$cols$id), , drop = FALSE]
  if (nrow(d$rows) < 3) stop("Fewer than 3 valid rows were found - the data looks incomplete.")
  if (nrow(d$cols) < 3) stop("Fewer than 3 valid columns were found - the data looks incomplete.")
  rownames(d$rows) <- NULL; rownames(d$cols) <- NULL

  src <- tdm_list_to_df(j$sources, c("id", "title", "publisher", "url", "in_search_results", "reachable"))
  src$id <- trimws(src$id)
  src <- src[nzchar(src$id) & !duplicated(src$id), , drop = FALSE]
  src$url[!grepl("^https?://", src$url)] <- ""
  d$sources <- src; rownames(d$sources) <- NULL

  cells <- tdm_list_to_df(j$cells, TDM_CELL_COLS)
  if (nrow(cells) > 0) {
    cells$row <- tdm_id(cells$row); cells$col <- tdm_id(cells$col)
    sc <- suppressWarnings(as.numeric(vapply(j$cells, function(b) tdm_chr(b$score), character(1))))
    cells$score <- sc
    # source_ids may be a JSON array
    cells$source_ids <- vapply(j$cells, function(b) tdm_src_ids(b$source_ids), character(1))
    bad <- !(cells$row %in% d$rows$id & cells$col %in% d$cols$id) | is.na(cells$score)
    if (any(bad)) warn <- c(warn, sprintf("%d cell(s) with unknown row/column ids or a non-numeric score were dropped.", sum(bad)))
    cells <- cells[!bad, , drop = FALSE]
    dup <- duplicated(paste(cells$row, cells$col))
    if (any(dup)) { warn <- c(warn, sprintf("%d duplicate cell(s) dropped (first kept).", sum(dup))); cells <- cells[!dup, , drop = FALSE] }
    cells$score <- pmin(100, pmax(0, round(cells$score)))
    cells$confidence <- tolower(cells$confidence)
    cells$confidence[!cells$confidence %in% TDM_CONF] <- "judgment"
    cells$verified <- tolower(cells$verified)
    cells$verified[!cells$verified %in% c("yes", "no", "unreachable", "unchecked")] <- "unchecked"
    # evidence claims need real source ids, otherwise they are judgments
    for (i in seq_len(nrow(cells))) {
      ids <- trimws(strsplit(cells$source_ids[i], ",", fixed = TRUE)[[1]]); ids <- ids[nzchar(ids)]
      known <- ids[ids %in% d$sources$id]
      cells$source_ids[i] <- paste(known, collapse = ",")
      if (cells$confidence[i] != "judgment" && length(known) == 0) {
        cells$confidence[i] <- "judgment"
        warn <- c(warn, sprintf("Cell %s x %s claimed evidence without a valid source and was downgraded to 'judgment'.", cells$row[i], cells$col[i]))
      }
    }
    rownames(cells) <- NULL
  }
  d$cells <- cells
  nmiss <- nrow(d$rows) * nrow(d$cols) - nrow(d$cells)
  if (nmiss > 0) warn <- c(warn, sprintf("%d of %d cells have no value (shown as 0, flagged as 'judgment').", nmiss, nrow(d$rows) * nrow(d$cols)))
  if (nmiss > 0) {
    have <- paste(d$cells$row, d$cells$col)
    grid <- expand.grid(row = d$rows$id, col = d$cols$id, stringsAsFactors = FALSE)
    grid <- grid[!(paste(grid$row, grid$col) %in% have), , drop = FALSE]
    fill <- tdm_empty_df(TDM_CELL_COLS); fill <- fill[seq_len(nrow(grid)), , drop = FALSE]
    fill$row <- grid$row; fill$col <- grid$col; fill$score <- 0
    fill[is.na(fill)] <- ""; fill$confidence <- "judgment"; fill$verified <- "unchecked"
    fill$rationale <- "No value was returned for this cell."
    d$cells <- rbind(d$cells, fill[, names(d$cells)])
  }

  d$row_tree <- j$row_tree; d$col_tree <- j$col_tree
  if (!is.null(d$row_tree)) { r <- tdm_build_authored_tree(d$row_tree, d$rows$id); warn <- c(warn, r$warnings); if (is.null(r$tree)) d$row_tree <- NULL }
  if (!is.null(d$col_tree)) { r <- tdm_build_authored_tree(d$col_tree, d$cols$id); warn <- c(warn, r$warnings); if (is.null(r$tree)) d$col_tree <- NULL }

  nm <- function(x) { x <- x %||% list(); out <- as.list(vapply(x, tdm_chr, character(1))); out[nzchar(unlist(out))] }
  d$row_names <- nm(j$row_node_names); d$col_names <- nm(j$col_node_names)
  # names that came with an authored tree
  tr <- tdm_trees(d)
  for (nd in tdm_internal_nodes(tr$row)) if (nzchar(nd$name %||% "") && is.null(d$row_names[[nd$sig]])) d$row_names[[nd$sig]] <- nd$name
  for (nd in tdm_internal_nodes(tr$col)) if (nzchar(nd$name %||% "") && is.null(d$col_names[[nd$sig]])) d$col_names[[nd$sig]] <- nd$name

  d$warnings <- unique(warn)
  d
}

# ---- Serialize to the editable JSON text ------------------------------------
tdm_to_list <- function(d) {
  df_rows <- function(df) lapply(seq_len(nrow(df)), function(i) as.list(df[i, , drop = FALSE]))
  cells <- lapply(seq_len(nrow(d$cells)), function(i) {
    b <- as.list(d$cells[i, , drop = FALSE])
    b$source_ids <- as.list(trimws(strsplit(b$source_ids, ",", fixed = TRUE)[[1]]))
    b$source_ids <- Filter(nzchar, b$source_ids)
    b
  })
  out <- list(
    meta = d$meta,
    rows = df_rows(d$rows), cols = df_rows(d$cols),
    cells = cells, sources = df_rows(d$sources),
    row_node_names = d$row_names, col_node_names = d$col_names
  )
  if (!is.null(d$row_tree)) out$row_tree <- d$row_tree
  if (!is.null(d$col_tree)) out$col_tree <- d$col_tree
  out
}
matrix_to_text <- function(d, pretty = TRUE) {
  as.character(jsonlite::toJSON(tdm_to_list(d), auto_unbox = TRUE, pretty = pretty, na = "null", null = "null"))
}

# ---- Evidence status (used for the cell markers + counts) -------------------
tdm_status <- function(confidence, verified) {
  ifelse(confidence == "judgment", "judgment",
         ifelse(verified == "yes", "verified",
                ifelse(verified == "no", "contradicted", "unverified")))
}
tdm_status_counts <- function(d) {
  st <- tdm_status(d$cells$confidence, d$cells$verified)
  vapply(c("verified", "unverified", "contradicted", "judgment"), function(s) sum(st == s), integer(1))
}

# ---- BigQuery row <-> design -------------------------------------------------
tdm_to_row <- function(d, design_id, name = NULL, change_type = "create", created_by = "claude_agent") {
  items <- rbind(
    data.frame(id = d$rows$id, label = d$rows$label, lane = "row", kind = d$rows$class, description = "", technologies = "", attributes = "", methods = "", stringsAsFactors = FALSE),
    data.frame(id = d$cols$id, label = d$cols$label, lane = "col", kind = d$cols$category, description = d$cols$metric_hint, technologies = d$cols$scoring_rule, attributes = "", methods = "", stringsAsFactors = FALSE))
  conns <- data.frame(from = d$cells$row, to = d$cells$col, label = as.character(d$cells$score), type = d$cells$confidence, stringsAsFactors = FALSE)
  refs <- data.frame(title = d$sources$title, author = d$sources$publisher, url = d$sources$url, stringsAsFactors = FALSE)
  d$meta$design_id <- design_id
  st <- tdm_status_counts(d)
  data.frame(
    design_id = design_id, design_group = TDM_GROUP, design_type = TDM_GROUP,
    name = name %||% d$meta$title, variant = d$meta$topic, title = d$meta$title, summary = d$meta$subtitle,
    when_to_use = d$meta$score_definition,
    when_not_to_use = sprintf("evidence: %d verified, %d unverified, %d contradicted, %d judgment", st[["verified"]], st[["unverified"]], st[["contradicted"]], st[["judgment"]]),
    complexity_level = sprintf("%dx%d", nrow(d$rows), nrow(d$cols)), tags = "matrix,dual-hierarchy,evidence", diagram_kind = "matrix",
    components_json = td_df_to_json(items), connections_json = td_df_to_json(conns),
    flow_steps_json = "[]", tradeoffs_json = "[]", references_json = td_df_to_json(refs),
    extras_json = matrix_to_text(d, pretty = FALSE),
    schema_version = 1L, change_type = change_type, created_by = created_by, stringsAsFactors = FALSE
  )
}

matrix_from_row <- function(row) {
  ex <- row[["extras_json"]][1]
  if (!is.null(ex) && !is.na(ex) && nchar(ex) > 2) {
    d <- tryCatch(parse_matrix_text(ex), error = function(e) NULL)
    if (!is.null(d)) { d$meta$design_id <- as.character(row[["design_id"]][1]); return(d) }
  }
  # fallback: rebuild from the mirrored columns (no evidence detail)
  comps <- td_json_to_df(row[["components_json"]][1], TD_COLS$components)
  conns <- td_json_to_df(row[["connections_json"]][1], TD_COLS$connections)
  refs <- td_json_to_df(row[["references_json"]][1], TD_COLS$references)
  txt <- jsonlite::toJSON(list(
    meta = list(title = as.character(row[["title"]][1]), subtitle = as.character(row[["summary"]][1])),
    rows = lapply(which(comps$lane == "row"), function(i) list(id = comps$id[i], label = comps$label[i], class = comps$kind[i])),
    cols = lapply(which(comps$lane == "col"), function(i) list(id = comps$id[i], label = comps$label[i], category = comps$kind[i])),
    cells = lapply(seq_len(nrow(conns)), function(i) list(row = conns$from[i], col = conns$to[i], score = suppressWarnings(as.numeric(conns$label[i])), confidence = conns$type[i])),
    sources = lapply(seq_len(nrow(refs)), function(i) list(id = paste0("s", i), title = refs$title[i], publisher = refs$author[i], url = refs$url[i]))
  ), auto_unbox = TRUE)
  d <- parse_matrix_text(as.character(txt)); d$meta$design_id <- as.character(row[["design_id"]][1]); d
}

# ---- Seed ---------------------------------------------------------------------
tdm_seed_dir <- function() {
  for (p in c("seed/techdesign_matrix", file.path(getwd(), "seed", "techdesign_matrix"))) if (dir.exists(p)) return(p)
  "seed/techdesign_matrix"
}
tdm_seed_files <- function() {
  f <- list.files(tdm_seed_dir(), pattern = "\\.json$", full.names = TRUE)
  setNames(f, tools::toTitleCase(gsub("_", " ", tools::file_path_sans_ext(basename(f)))))
}

# ---- Node naming (computed hierarchies) ----------------------------------------
TDM_NAME_MAX_NODES <- 24L

tdm_name_catalog <- function(d, lab_rows, lab_cols) {
  tr <- tdm_trees(d)
  mk <- function(tree, prefix, labels) {
    nodes <- tdm_internal_nodes(tree)
    nodes <- nodes[seq_len(min(length(nodes), TDM_NAME_MAX_NODES))]
    keys <- sprintf("%s%d", prefix, seq_along(nodes))
    list(keys = keys, sigs = vapply(nodes, function(z) z$sig, character(1)),
         text = vapply(seq_along(nodes), function(i) sprintf("  %s: %s", keys[i], paste(labels[nodes[[i]]$leaves], collapse = "; ")), character(1)))
  }
  list(rows = mk(tr$row, "R", setNames(d$rows$label, d$rows$id)),
       cols = mk(tr$col, "C", setNames(d$cols$label, d$cols$id)))
}

generate_matrix_name_prompt <- function(d, cat) {
  paste0(
    "TASK: MATRIX_NAME_BRANCHES\n\n",
    "Two hierarchies were computed (Ward clustering of score profiles) over a matrix titled \"", d$meta$title, "\".\n",
    "Rows are: ", d$meta$row_axis, ". Columns are: ", d$meta$col_axis, ".\n\n",
    "Give every cluster below a SHORT, specific name (2-4 words, max 28 characters) that says what the members have in common ",
    "(for example 'Oil & energy', 'Rates & credit', 'AI & software'). The name must be true of ALL members listed. ",
    "Higher clusters should have broader names; the biggest cluster can be 'All ", tolower(d$meta$row_axis), "' / 'All ", tolower(d$meta$col_axis), "'.\n\n",
    "ROW CLUSTERS (key: members):\n", paste(cat$rows$text, collapse = "\n"), "\n\n",
    "COLUMN CLUSTERS (key: members):\n", paste(cat$cols$text, collapse = "\n"), "\n\n",
    "Return ONLY one JSON object, no prose, no markdown fences:\n",
    "{\"row_clusters\": {\"R1\": \"name\", ...}, \"col_clusters\": {\"C1\": \"name\", ...}}\n"
  )
}

parse_matrix_names <- function(text, cat) {
  j <- tdm_extract_json(text)
  pick <- function(map, keys, sigs) {
    out <- list()
    for (i in seq_along(keys)) {
      v <- tdm_chr(map[[keys[i]]])
      if (nzchar(v)) out[[sigs[i]]] <- substr(v, 1, 32)
    }
    out
  }
  list(rows = pick(j$row_clusters %||% list(), cat$rows$keys, cat$rows$sigs),
       cols = pick(j$col_clusters %||% list(), cat$cols$keys, cat$cols$sigs))
}

# ---- Prompts: plan, per-column research, knowledge-only ---------------------------
TDM_SCHEMA_NOTE <- paste0(
  "Output rules: respond with ONE JSON object and nothing else (no markdown fences, no commentary before or after). ",
  "Use only ASCII characters inside strings (write 'and' instead of '&' is NOT required; plain quotes are escaped properly). ",
  "Ids are lowercase letters, digits and underscores only."
)

generate_matrix_plan_prompt <- function(topic, n_rows, n_cols, tree_mode, extra = "") {
  paste0(
    "TASK: MATRIX_PLAN\n\n",
    "Design a two-hierarchy evidence matrix for this request:\n\"", topic, "\"\n\n",
    if (nzchar(trimws(extra))) paste0("Extra instructions: ", extra, "\n\n") else "",
    "ROWS = the main subjects (about ", n_rows, " items) with a CLASS each (4-7 classes). ",
    "COLUMNS = the drivers / criteria they are compared against (about ", n_cols, " items) with a CATEGORY each (3-5 categories). ",
    "Each cell will later hold a relevance score 0-100 backed by evidence from the web.\n\n",
    "For EVERY column you must plan the evidence so that scores are computed by a fixed rule, not guessed:\n",
    "  - metric_hint: a concrete, measurable and publicly documented quantity that shows how relevant this column is to a row ",
    "(e.g. 'share of revenue from the segment', '5-year correlation of monthly returns', 'sensitivity of earnings to 1 USD move in oil price', 'percent of capex tied to AI infrastructure').\n",
    "  - scoring_rule: an explicit rule turning that metric (or, when no number exists, qualitative evidence) into 0-100 ",
    "(e.g. 'abs(correlation) x 100, rounded', 'revenue share in percent, capped at 100; qualitative: direct=70, indirect=40, weak=15').\n",
    "Prefer metrics that a web search can actually find (company filings, central banks, statistics offices, index providers, exchanges, reputable research).\n\n",
    if (identical(tree_mode, "authored")) paste0(
      "ALSO give an authored hierarchy for the rows (row_tree) and for the columns (col_tree): nested objects ",
      "{\"name\": \"cluster name\", \"children\": [ ... ]} where leaves are the item ids as plain strings. ",
      "Group items by meaning (3-4 levels deep), every item exactly once, names 2-4 words.\n\n") else
      "Do NOT output a hierarchy; it will be computed from the scores.\n\n",
    "Return this JSON shape:\n",
    "{\"title\": \"...\", \"subtitle\": \"one sentence about what the matrix shows\", \"row_axis\": \"short name of the rows (e.g. Financial markets)\", ",
    "\"col_axis\": \"short name of the columns (e.g. Economic and technology drivers)\", ",
    "\"score_definition\": \"what 0 and 100 mean\",\n",
    " \"rows\": [{\"id\": \"nasdaq_100\", \"label\": \"Nasdaq 100\", \"class\": \"Equities\"}, ...],\n",
    " \"cols\": [{\"id\": \"oil_price\", \"label\": \"Oil price\", \"category\": \"Commodities\", \"metric_hint\": \"...\", \"scoring_rule\": \"...\"}, ...]",
    if (identical(tree_mode, "authored")) ",\n \"row_tree\": {...}, \"col_tree\": {...}" else "",
    "}\n\n", TDM_SCHEMA_NOTE, "\n"
  )
}

generate_matrix_cells_prompt <- function(d, col_idx, research, max_uses = 4L) {
  cols <- d$cols[col_idx, , drop = FALSE]
  rows_txt <- paste(sprintf("  - %s: %s (%s)", d$rows$id, d$rows$label, d$rows$class), collapse = "\n")
  cols_txt <- paste(sprintf("  - %s: %s (%s)\n      metric_hint: %s\n      scoring_rule: %s", cols$id, cols$label, cols$category,
                            ifelse(nzchar(cols$metric_hint), cols$metric_hint, "(choose a sensible measurable metric)"),
                            ifelse(nzchar(cols$scoring_rule), cols$scoring_rule, "(state the rule you apply)")), collapse = "\n")
  paste0(
    "TASK: MATRIX_CELLS\n\n",
    "Matrix: \"", d$meta$title, "\". ", d$meta$subtitle, "\nScore meaning: ", d$meta$score_definition, "\n\n",
    "ROWS:\n", rows_txt, "\n\nCOLUMN(S) TO FILL NOW:\n", cols_txt, "\n\n",
    "Produce one cell for EVERY (row, column) pair above (", nrow(d$rows) * nrow(cols), " cells).\n\n",
    if (research) paste0(
      "RESEARCH: use the web search tool (at most ", max_uses, " searches in total) to find real, citable evidence for the metric of each column, ",
      "preferring primary sources (filings, central banks, statistics offices, exchanges, index providers, peer-reviewed or reputable research). ",
      "One good source frequently covers many rows.\n",
      "EVIDENCE RULES (strict):\n",
      "  1. confidence = \"sourced\" only if a retrieved page states the number or fact you used; \"partial\" if the page supports it only indirectly; ",
      "otherwise \"judgment\" with NO sources. Never present a guess as sourced.\n",
      "  2. For sourced/partial cells give: metric (what was measured), value (the figure with units), as_of (date or period), ",
      "quote (a VERBATIM excerpt of at most 25 words copied from the page, not paraphrased), source_ids, and score computed with the column's scoring_rule.\n",
      "  3. Only list sources whose URL you actually retrieved through the search tool. NEVER write a URL from memory.\n",
      "  4. rationale: one short sentence saying how the value became the score (apply the scoring_rule consistently across the column).\n\n") else paste0(
      "NO WEB RESEARCH in this run: use your own knowledge, set confidence = \"judgment\" for EVERY cell, leave quote/metric/value/as_of empty and sources empty. ",
      "rationale: one short sentence explaining the score.\n\n"),
    "Return ONE JSON object:\n",
    "{\"cells\": [{\"row\": \"row_id\", \"col\": \"col_id\", \"score\": 0-100, \"confidence\": \"sourced|partial|judgment\", \"metric\": \"\", \"value\": \"\", \"as_of\": \"\", \"quote\": \"\", \"source_ids\": [\"s1\"], \"rationale\": \"\"}, ...],\n",
    " \"sources\": [{\"id\": \"s1\", \"title\": \"page title\", \"publisher\": \"organisation\", \"url\": \"https://...\"}]}\n\n",
    TDM_SCHEMA_NOTE, "\n"
  )
}

# Merge one cells-response into the working design (global source ids S1, S2 ...; URL de-duplication)
tdm_merge_cells <- function(d, resp_json, search_urls = character(0)) {
  new_src <- tdm_list_to_df(resp_json$sources, c("id", "title", "publisher", "url"))
  new_src$url[!grepl("^https?://", new_src$url)] <- ""
  map <- character(0)
  for (i in seq_len(nrow(new_src))) {
    u <- sub("[#]$", "", new_src$url[i])
    hit <- if (nzchar(u)) match(u, d$sources$url) else NA_integer_
    if (is.na(hit)) {
      gid <- paste0("S", nrow(d$sources) + 1L)
      norm <- function(x) sub("/+$", "", sub("^https?://(www\\.)?", "", tolower(x)))
      inres <- if (length(search_urls) > 0 && nzchar(u)) as.character(any(norm(search_urls) == norm(u))) else ""
      d$sources <- rbind(d$sources, data.frame(id = gid, title = new_src$title[i], publisher = new_src$publisher[i], url = u,
                                              in_search_results = if (inres == "TRUE") "yes" else if (inres == "FALSE") "no" else "", reachable = "", stringsAsFactors = FALSE))
      map[[new_src$id[i]]] <- gid
    } else map[[new_src$id[i]]] <- d$sources$id[hit]
  }
  cells <- tdm_list_to_df(resp_json$cells, TDM_CELL_COLS)
  if (nrow(cells) == 0) return(d)
  cells$score <- suppressWarnings(as.numeric(vapply(resp_json$cells, function(b) tdm_chr(b$score), character(1))))
  cells$row <- tdm_id(cells$row); cells$col <- tdm_id(cells$col)
  cells$source_ids <- vapply(resp_json$cells, function(b) {
    ids <- trimws(strsplit(tdm_src_ids(b$source_ids), ",", fixed = TRUE)[[1]])
    paste(unname(ifelse(ids %in% names(map), map[ids], "")), collapse = ",")
  }, character(1))
  cells$source_ids <- gsub("^,+|,+$", "", gsub(",+", ",", cells$source_ids))
  cells$verified <- "unchecked"
  ok <- cells$row %in% d$rows$id & cells$col %in% d$cols$id & !is.na(cells$score)
  cells <- cells[ok, TDM_CELL_COLS, drop = FALSE]
  d$cells <- rbind(d$cells[!(paste(d$cells$row, d$cells$col) %in% paste(cells$row, cells$col)), , drop = FALSE], cells)
  d
}

# ---- Source verification (fetch the page, look for the quote) ---------------------
tdm_url_is_public <- function(url) {
  if (!grepl("^https?://", url)) return(FALSE)
  host <- tolower(sub("^https?://([^/:?#]+).*$", "\\1", url))
  if (!grepl(".", host, fixed = TRUE)) return(FALSE)
  if (grepl("^(localhost|127\\.|10\\.|0\\.|192\\.168\\.|169\\.254\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.)", host)) return(FALSE)
  if (grepl("\\.(local|internal|lan)$", host)) return(FALSE)
  TRUE
}

tdm_fetch_page_text <- function(url, timeout = 15, max_bytes = 3e6) {
  if (!tdm_url_is_public(url)) return(NA_character_)
  h <- curl::new_handle(timeout = timeout, followlocation = TRUE, maxredirs = 5, useragent = "Mozilla/5.0 (compatible; MatrixSourceCheck/1.0)")
  res <- tryCatch(curl::curl_fetch_memory(url, handle = h), error = function(e) NULL)
  if (is.null(res) || res$status_code != 200 || length(res$content) == 0) return(NA_character_)
  raw <- res$content[seq_len(min(length(res$content), max_bytes))]
  ctype <- tolower(curl::parse_headers_list(res$headers)[["content-type"]] %||% "")
  txt <- if (grepl("pdf", ctype) || grepl("\\.pdf($|\\?)", tolower(url))) {
    if (requireNamespace("pdftools", quietly = TRUE)) tryCatch(paste(pdftools::pdf_text(raw), collapse = " "), error = function(e) NA_character_) else NA_character_
  } else {
    s <- tryCatch(rawToChar(raw), error = function(e) NA_character_)
    if (is.na(s)) return(NA_character_)
    s <- iconv(s, from = "UTF-8", to = "UTF-8", sub = " ")
    s <- gsub("(?is)<(script|style|noscript)[^>]*>.*?</\\1>", " ", s, perl = TRUE)
    s <- gsub("<[^>]+>", " ", s)
    gsub("&nbsp;|&#160;", " ", gsub("&amp;", "&", s))
  }
  txt
}

tdm_norm_text <- function(x) {
  x <- tolower(iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT", sub = " "))
  x <- gsub("[^a-z0-9%.]+", " ", x)
  trimws(gsub("\\s+", " ", x))
}

# "yes" / "no" for one quote against one normalised page text
tdm_quote_in_page <- function(quote, page_norm) {
  q <- tdm_norm_text(quote)
  w <- strsplit(q, " ", fixed = TRUE)[[1]]; w <- w[nzchar(w)]
  if (length(w) < 4) return("unchecked")
  if (grepl(q, page_norm, fixed = TRUE)) return("yes")
  k <- 4L
  sh <- vapply(seq_len(length(w) - k + 1L), function(i) paste(w[i:(i + k - 1L)], collapse = " "), character(1))
  frac <- mean(vapply(sh, function(s) grepl(s, page_norm, fixed = TRUE), logical(1)))
  if (frac >= 0.6) "yes" else "no"
}

# fetcher(url) -> page text or NA. Returns the design with sources$reachable and cells$verified set.
tdm_verify_sources <- function(d, fetcher = tdm_fetch_page_text, progress = NULL) {
  d$sources$reachable <- rep("", nrow(d$sources))
  cache <- list()
  urls <- unique(d$sources$url[nzchar(d$sources$url)])
  for (i in seq_along(urls)) {
    if (!is.null(progress)) progress(sprintf("Checking source %d of %d ...", i, length(urls)))
    p <- tryCatch(fetcher(urls[i]), error = function(e) NA_character_)
    cache[[urls[i]]] <- if (is.na(p)) NA_character_ else tdm_norm_text(p)
  }
  for (i in seq_len(nrow(d$sources))) {
    u <- d$sources$url[i]
    d$sources$reachable[i] <- if (!nzchar(u)) "no" else if (is.na(cache[[u]])) "no" else "yes"
  }
  for (i in seq_len(nrow(d$cells))) {
    if (d$cells$confidence[i] == "judgment") { d$cells$verified[i] <- "unchecked"; next }
    ids <- trimws(strsplit(d$cells$source_ids[i], ",", fixed = TRUE)[[1]]); ids <- ids[nzchar(ids)]
    q <- d$cells$quote[i]
    if (!nzchar(q)) { d$cells$verified[i] <- "unchecked"; next }
    res <- vapply(ids, function(sid) {
      u <- d$sources$url[match(sid, d$sources$id)]
      if (is.na(u) || !nzchar(u) || is.null(cache[[u]]) || is.na(cache[[u]])) return("unreachable")
      tdm_quote_in_page(q, cache[[u]])
    }, character(1))
    d$cells$verified[i] <- if (length(res) == 0) "unreachable" else if (any(res == "yes")) "yes" else if (any(res == "no")) "no" else if (any(res == "unchecked")) "unchecked" else "unreachable"
  }
  d
}

# ---- Orchestration (kept free of Shiny so it can be tested) --------------------------
tdm_run_pipeline <- function(api, topic, n_rows = 14, n_cols = 8, tree_mode = "computed", research = TRUE,
                             max_uses = 4L, verify = TRUE, extra = "", progress = function(msg) NULL, fetcher = tdm_fetch_page_text) {
  progress("Step 1: planning rows, columns and the evidence metric for each column ...")
  plan_txt <- api$call_claude(generate_matrix_plan_prompt(topic, n_rows, n_cols, tree_mode, extra), max_tokens = 6000)
  pj <- tdm_extract_json(plan_txt)
  skeleton <- jsonlite::toJSON(c(pj[c("title", "subtitle", "row_axis", "col_axis", "score_definition", "rows", "cols")],
                                 if (!is.null(pj$row_tree)) list(row_tree = pj$row_tree), if (!is.null(pj$col_tree)) list(col_tree = pj$col_tree)),
                               auto_unbox = TRUE)
  d <- tryCatch(parse_matrix_text(as.character(skeleton)), error = function(e) stop("The plan could not be parsed: ", e$message))
  d$cells <- d$cells[0, , drop = FALSE]   # the skeleton has no real cells yet (parse fills a blank grid)
  d$meta$topic <- topic
  d$meta$tree_mode <- tree_mode
  d$meta$research <- if (research) "web" else "knowledge"
  d$meta$generated_with <- format(Sys.time(), "%Y-%m-%d")
  d$warnings <- character(0)

  groups <- if (research) split(seq_len(nrow(d$cols)), seq_len(nrow(d$cols))) else list(seq_len(nrow(d$cols)))
  for (g in seq_along(groups)) {
    idx <- groups[[g]]
    progress(sprintf("Step 2: %s (%d of %d) ...", if (research) paste("researching", d$cols$label[idx[1]]) else "scoring all columns from knowledge", g, length(groups)))
    prompt <- generate_matrix_cells_prompt(d, idx, research, max_uses)
    tools <- if (research) list(claude_web_search_tool(max_uses)) else NULL
    resp <- tryCatch(api$call_claude(prompt, max_tokens = 8000, tools = tools), error = function(e) e)
    parsed <- if (inherits(resp, "error")) NULL else tryCatch(tdm_extract_json(resp), error = function(e) NULL)
    if (is.null(parsed) && research) {
      progress(sprintf("   retrying %s without the search tool (cells will be marked as judgment) ...", d$cols$label[idx[1]]))
      resp <- tryCatch(api$call_claude(generate_matrix_cells_prompt(d, idx, FALSE), max_tokens = 8000), error = function(e) e)
      parsed <- if (inherits(resp, "error")) NULL else tryCatch(tdm_extract_json(resp), error = function(e) NULL)
      if (!is.null(parsed)) { for (i in seq_along(parsed$cells)) { parsed$cells[[i]]$confidence <- "judgment"; parsed$cells[[i]]$source_ids <- list() }; parsed$sources <- list() }
    }
    if (!is.null(parsed) && !research) {   # knowledge-only runs can never claim evidence
      for (i in seq_along(parsed$cells)) { parsed$cells[[i]]$confidence <- "judgment"; parsed$cells[[i]]$source_ids <- list() }
      parsed$sources <- list()
    }
    if (is.null(parsed)) { d$warnings <- c(d$warnings, sprintf("Column '%s' could not be filled (%s).", d$cols$label[idx[1]], if (inherits(resp, "error")) conditionMessage(resp) else "unparseable response")); next }
    su <- if (!inherits(resp, "error")) attr(resp, "claude_search_urls") else NULL
    d <- tdm_merge_cells(d, parsed, search_urls = if (is.null(su)) character(0) else su$url)
  }

  # complete the grid (anything missing becomes an explicit judgment 0)
  d <- parse_matrix_text(matrix_to_text(d))
  if (research && verify && nrow(d$sources) > 0) {
    d <- tdm_verify_sources(d, fetcher = fetcher, progress = function(m) progress(paste("Step 3:", m)))
    d <- parse_matrix_text(matrix_to_text(d))
  }

  if (identical(tree_mode, "computed")) {
    progress("Step 4: naming the branches of both hierarchies ...")
    cat <- tdm_name_catalog(d, setNames(d$rows$label, d$rows$id), setNames(d$cols$label, d$cols$id))
    nm <- tryCatch(parse_matrix_names(api$call_claude(generate_matrix_name_prompt(d, cat), max_tokens = 2500), cat), error = function(e) NULL)
    if (is.null(nm)) d$warnings <- c(d$warnings, "Branch names could not be generated; use 'Name branches' to retry.")
    else { d$row_names <- nm$rows; d$col_names <- nm$cols }
  }
  d
}

# Re-run only the naming step on an existing design
tdm_rename_branches <- function(api, d) {
  cat <- tdm_name_catalog(d, setNames(d$rows$label, d$rows$id), setNames(d$cols$label, d$cols$id))
  nm <- parse_matrix_names(api$call_claude(generate_matrix_name_prompt(d, cat), max_tokens = 2500), cat)
  d$row_names <- nm$rows; d$col_names <- nm$cols
  d
}

# ---- Export helpers ----------------------------------------------------------------
tdm_cells_table <- function(d) {
  rl <- setNames(d$rows$label, d$rows$id); cl <- setNames(d$cols$label, d$cols$id)
  srcurl <- setNames(d$sources$url, d$sources$id)
  data.frame(
    Row = unname(rl[d$cells$row]), Row_class = d$rows$class[match(d$cells$row, d$rows$id)],
    Column = unname(cl[d$cells$col]), Column_category = d$cols$category[match(d$cells$col, d$cols$id)],
    Score = d$cells$score, Evidence = tdm_status(d$cells$confidence, d$cells$verified),
    Metric = d$cells$metric, Value = d$cells$value, As_of = d$cells$as_of, Quote = d$cells$quote,
    Sources = vapply(d$cells$source_ids, function(s) { ids <- trimws(strsplit(s, ",", fixed = TRUE)[[1]]); paste(unname(srcurl[ids[ids %in% names(srcurl)]]), collapse = " ") }, character(1)),
    Rationale = d$cells$rationale, stringsAsFactors = FALSE)
}

tdm_to_flex_text <- function(d) {
  clean <- function(x) { x <- gsub("\\|\\|\\|", " ", as.character(x)); gsub("[\r\n]+", " ", trimws(x)) }
  st <- tdm_status(d$cells$confidence, d$cells$verified)
  head <- c(paste0("[", TD_MINDMAP_CATEGORY, "]"), paste0("[", clean(d$meta$title), "]"),
            paste0("[", clean(d$meta$title), " - relevance matrix]"), paste0("[", clean(d$meta$row_axis), "]"), paste0("[", clean(d$meta$col_axis), "]"), "")
  body <- unlist(lapply(seq_len(nrow(d$rows)), function(i) {
    vals <- vapply(seq_len(nrow(d$cols)), function(j) {
      k <- which(d$cells$row == d$rows$id[i] & d$cells$col == d$cols$id[j])
      if (length(k) == 0) "-" else sprintf("%d (%s)", as.integer(d$cells$score[k[1]]), st[k[1]])
    }, character(1))
    c(paste0("[row_index]: ", clean(d$rows$label[i])), paste0("[columns_data]: ", build_columns_data(clean(d$cols$label), vals)),
      paste0("[notes]: ", clean(d$rows$class[i])), "")
  }))
  paste(c(head, body), collapse = "\n")
}
