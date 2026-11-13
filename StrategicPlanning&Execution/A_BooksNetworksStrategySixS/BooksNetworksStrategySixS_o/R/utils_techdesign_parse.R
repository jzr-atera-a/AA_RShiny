# R/utils_techdesign_parse.R
# Parser / serializer / JSON conversion for Technical Designs.

TD_HEADER_KEYS <- c("design_id", "design_group", "design_type", "title", "variant", "summary",
                    "when_to_use", "when_not_to_use", "complexity", "tags")
TD_BLOCK_KEYS <- list(
  component  = c("id", "label", "lane", "kind", "description", "technologies", "attributes", "methods"),
  connection = c("from", "to", "label", "type"),
  step       = c("order", "text", "components"),
  tradeoff   = c("kind", "text"),
  reference  = c("title", "author", "url")
)
TD_COLS <- list(
  components  = c("id", "label", "lane", "kind", "description", "technologies", "attributes", "methods"),
  connections = c("from", "to", "label", "type"),
  steps       = c("order", "text", "components"),
  tradeoffs   = c("kind", "text"),
  references  = c("title", "author", "url")
)

td_clean <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x)) return("")
  x <- trimws(as.character(x))
  if (toupper(x) %in% c("N/A", "NA", "NONE", "(NONE)")) return("")
  x
}

td_blocks_to_df <- function(blocks, cols) {
  if (length(blocks) == 0) {
    df <- as.data.frame(setNames(replicate(length(cols), character(0), simplify = FALSE), cols), stringsAsFactors = FALSE)
    return(df)
  }
  rows <- lapply(blocks, function(b) {
    vals <- vapply(cols, function(cn) td_clean(b[[cn]]), character(1))
    as.data.frame(as.list(vals), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# Returns list(meta, components, connections, steps, tradeoffs, references, warnings)
parse_techdesign_text <- function(text) {
  text <- gsub("\r", "", text %||% "")
  text <- gsub("```[a-zA-Z]*", "", text)
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]

  header <- list()
  blocks <- list(component = list(), connection = list(), step = list(), tradeoff = list(), reference = list())
  cur_type <- NULL
  cur <- NULL
  last_key <- NULL
  warnings <- character(0)

  flush <- function() {
    if (!is.null(cur_type) && length(cur) > 0) {
      blocks[[cur_type]][[length(blocks[[cur_type]]) + 1]] <<- cur
    }
  }

  for (raw in lines) {
    line <- trimws(raw)
    if (line == "") next

    m <- regmatches(line, regexec("^@(component|connection|step|tradeoff|reference)\\s*$", line, ignore.case = TRUE))[[1]]
    if (length(m) == 2) {
      flush()
      cur_type <- tolower(m[2]); cur <- list(); last_key <- NULL
      next
    }

    km <- regmatches(line, regexec("^([a-z_]+)\\s*:\\s*(.*)$", line))[[1]]
    allowed <- if (is.null(cur_type)) TD_HEADER_KEYS else TD_BLOCK_KEYS[[cur_type]]
    if (length(km) == 3 && km[2] %in% allowed) {
      key <- km[2]; val <- trimws(km[3])
      if (is.null(cur_type)) header[[key]] <- val else cur[[key]] <- val
      last_key <- key
      next
    }

    # continuation of the previous value
    if (!is.null(last_key)) {
      if (is.null(cur_type)) header[[last_key]] <- paste(header[[last_key]], line)
      else cur[[last_key]] <- paste(cur[[last_key]], line)
    }
  }
  flush()

  group <- td_clean(header$design_group)
  if (!group %in% TD_GROUPS) stop("Missing or invalid design_group in the first header lines (expected one of: ",
                                  paste(TD_GROUPS, collapse = ", "), ").")
  design_type <- td_slug(td_clean(header$design_type))

  comps <- td_blocks_to_df(blocks$component, TD_COLS$components)
  conns <- td_blocks_to_df(blocks$connection, TD_COLS$connections)
  steps <- td_blocks_to_df(blocks$step, TD_COLS$steps)
  trade <- td_blocks_to_df(blocks$tradeoff, TD_COLS$tradeoffs)
  refs  <- td_blocks_to_df(blocks$reference, TD_COLS$references)

  if (nrow(comps) < 2) stop("Fewer than 2 components were found - the text looks incomplete (was the response cut off?).")
  comps <- comps[nchar(comps$id) > 0 & nchar(comps$label) > 0, , drop = FALSE]
  if (anyDuplicated(comps$id) > 0) {
    warnings <- c(warnings, paste("Duplicate component ids dropped:", paste(unique(comps$id[duplicated(comps$id)]), collapse = ", ")))
    comps <- comps[!duplicated(comps$id), , drop = FALSE]
  }
  if (nrow(comps) < 2) stop("Fewer than 2 valid components (each needs an id and a label).")

  bad <- !(conns$from %in% comps$id & conns$to %in% comps$id)
  if (any(bad)) {
    warnings <- c(warnings, sprintf("%d connection(s) referencing unknown component ids were dropped.", sum(bad)))
    conns <- conns[!bad, , drop = FALSE]
  }
  lonely <- setdiff(comps$id, c(conns$from, conns$to))
  if (length(lonely) > 0) warnings <- c(warnings, paste("Components without any connection:", paste(lonely, collapse = ", ")))

  steps$order_num <- suppressWarnings(as.integer(steps$order))
  if (nrow(steps) > 0) {
    steps <- steps[order(ifelse(is.na(steps$order_num), 999L, steps$order_num)), , drop = FALSE]
    steps$order <- as.character(seq_len(nrow(steps)))
  }
  steps$order_num <- NULL

  group_kind <- TD_GROUP_DIAGRAM_KIND[[group]]
  if (!"kind" %in% names(comps)) comps$kind <- ""
  comps$kind <- tolower(comps$kind)
  valid_kinds <- if (group_kind == "class") TD_NODE_KINDS_CLASS else TD_NODE_KINDS_LAYERED
  default_kind <- if (group_kind == "class") "class" else "service"
  comps$kind[!comps$kind %in% valid_kinds] <- default_kind
  conns$type <- tolower(conns$type)
  valid_edges <- if (group_kind == "class") TD_EDGE_TYPES_CLASS else TD_EDGE_TYPES_LAYERED
  conns$type[!conns$type %in% valid_edges] <- if (group_kind == "class") "uses" else "data"
  comps$lane[comps$lane == ""] <- if (group_kind == "class") "Classes" else "Components"

  meta <- list(
    design_id = td_clean(header$design_id),
    design_group = group, design_type = design_type,
    title = td_clean(header$title), variant = td_clean(header$variant),
    summary = td_clean(header$summary), when_to_use = td_clean(header$when_to_use),
    when_not_to_use = td_clean(header$when_not_to_use),
    complexity = td_clean(header$complexity), tags = td_clean(header$tags),
    diagram_kind = group_kind
  )
  if (meta$title == "") meta$title <- td_clean(header$design_type)

  list(meta = meta, components = comps, connections = conns, steps = steps,
       tradeoffs = trade, references = refs, warnings = warnings)
}

# ---- Serialize back to the editable text format -----------------------
techdesign_to_text <- function(d) {
  m <- d$meta
  one <- function(x) if (nchar(x %||% "") == 0) "N/A" else x
  out <- c(
    if (nchar(m$design_id %||% "") > 0) paste0("design_id: ", m$design_id),
    paste0("design_group: ", m$design_group), paste0("design_type: ", m$design_type),
    paste0("title: ", one(m$title)), paste0("variant: ", one(m$variant)),
    paste0("summary: ", one(m$summary)), paste0("when_to_use: ", one(m$when_to_use)),
    paste0("when_not_to_use: ", one(m$when_not_to_use)), paste0("complexity: ", one(m$complexity)),
    paste0("tags: ", one(m$tags)), ""
  )
  blk <- function(type, df, cols) {
    res <- character(0)
    for (i in seq_len(nrow(df))) {
      res <- c(res, paste0("@", type))
      for (cn in cols) res <- c(res, paste0(cn, ": ", one(df[[cn]][i])))
      res <- c(res, "")
    }
    res
  }
  all_lines <- c(out,
    blk("component", d$components, TD_COLS$components),
    blk("connection", d$connections, TD_COLS$connections),
    blk("step", d$steps, TD_COLS$steps),
    blk("tradeoff", d$tradeoffs, TD_COLS$tradeoffs),
    blk("reference", d$references, TD_COLS$references))
  paste(all_lines, collapse = "\n")
}

# ---- JSON <-> data.frame ---------------------------------------------
td_df_to_json <- function(df) {
  if (is.null(df) || nrow(df) == 0) return("[]")
  as.character(jsonlite::toJSON(df, dataframe = "rows", auto_unbox = TRUE, na = "null"))
}
td_json_to_df <- function(json, cols) {
  empty <- as.data.frame(setNames(replicate(length(cols), character(0), simplify = FALSE), cols), stringsAsFactors = FALSE)
  if (is.null(json) || is.na(json) || nchar(trimws(json)) == 0) return(empty)
  df <- tryCatch(jsonlite::fromJSON(json, simplifyDataFrame = TRUE), error = function(e) NULL)
  if (is.null(df) || !is.data.frame(df) || nrow(df) == 0) return(empty)
  for (cn in cols) if (!cn %in% names(df)) df[[cn]] <- ""
  df <- df[, cols, drop = FALSE]
  for (cn in cols) { df[[cn]] <- as.character(df[[cn]]); df[[cn]][is.na(df[[cn]])] <- "" }
  df
}

# One-row data.frame ready for bq_insert_techdesign()
techdesign_to_row <- function(d, design_id, design_name, change_type = "create", created_by = "claude_agent") {
  m <- d$meta
  data.frame(
    design_id = design_id, design_group = m$design_group, design_type = m$design_type,
    name = design_name, variant = m$variant, title = m$title, summary = m$summary,
    when_to_use = m$when_to_use, when_not_to_use = m$when_not_to_use,
    complexity_level = m$complexity, tags = m$tags, diagram_kind = m$diagram_kind,
    components_json = td_df_to_json(d$components), connections_json = td_df_to_json(d$connections),
    flow_steps_json = td_df_to_json(d$steps), tradeoffs_json = td_df_to_json(d$tradeoffs),
    references_json = td_df_to_json(d$references), extras_json = "{}",
    schema_version = 1L, change_type = change_type, created_by = created_by,
    stringsAsFactors = FALSE
  )
}

# Row from BigQuery -> design list (same shape parse_techdesign_text returns)
techdesign_from_row <- function(row) {
  g <- function(cn) { v <- row[[cn]][1]; if (is.null(v) || is.na(v)) "" else as.character(v) }
  list(
    meta = list(design_id = g("design_id"), design_group = g("design_group"), design_type = g("design_type"), title = g("title"),
                variant = g("variant"), summary = g("summary"), when_to_use = g("when_to_use"),
                when_not_to_use = g("when_not_to_use"), complexity = g("complexity_level"),
                tags = g("tags"),
                diagram_kind = if (nchar(g("diagram_kind")) > 0) g("diagram_kind") else TD_GROUP_DIAGRAM_KIND[[g("design_group")]] %||% "layered"),
    components = td_json_to_df(g("components_json"), TD_COLS$components),
    connections = td_json_to_df(g("connections_json"), TD_COLS$connections),
    steps = td_json_to_df(g("flow_steps_json"), TD_COLS$steps),
    tradeoffs = td_json_to_df(g("tradeoffs_json"), TD_COLS$tradeoffs),
    references = td_json_to_df(g("references_json"), TD_COLS$references),
    warnings = character(0)
  )
}
