# R/utils_techdesign_actions.R
# Helpers shared by the Technical Designs "management" subtabs: multi-design text
# splitting, seed library, handoffs (Mind Map / Flex Table), recommender, compare,
# AI-modify prompts and the Design Guide content.

# ---- Generic @block parser (used for recommendations) -----------------
td_parse_blocks <- function(text, block) {
  lines <- strsplit(gsub("\r", "", text %||% ""), "\n", fixed = TRUE)[[1]]
  recs <- list(); cur <- NULL
  for (ln in lines) {
    t <- trimws(ln)
    if (grepl(paste0("^@", block, "\\s*$"), t, ignore.case = TRUE)) {
      if (!is.null(cur)) recs[[length(recs) + 1]] <- cur
      cur <- list(); next
    }
    if (is.null(cur) || !nzchar(t)) next
    m <- regmatches(t, regexec("^([A-Za-z_]+)\\s*:\\s*(.*)$", t))[[1]]
    if (length(m) == 3) cur[[tolower(m[2])]] <- trimws(m[3])
  }
  if (!is.null(cur)) recs[[length(recs) + 1]] <- cur
  recs
}

# ---- Split a pasted text into several design texts --------------------
# Separators: a line of 3+ '=' characters, OR a new 'design_group:' / 'design_id:'
# header line that appears after the previous design already had @blocks.
td_split_designs <- function(text) {
  lines <- strsplit(gsub("\r", "", text %||% ""), "\n", fixed = TRUE)[[1]]
  docs <- list(); cur <- character(0); seen_block <- FALSE
  flush <- function() {
    if (any(nzchar(trimws(cur)))) docs[[length(docs) + 1]] <<- paste(cur, collapse = "\n")
    cur <<- character(0); seen_block <<- FALSE
  }
  for (ln in lines) {
    t <- trimws(ln)
    if (grepl("^={3,}$", t)) { flush(); next }
    if (grepl("^@", t)) seen_block <- TRUE
    if (seen_block && grepl("^(design_id|design_group)\\s*:", t)) flush()
    cur <- c(cur, ln)
  }
  flush()
  docs
}

# ---- Seed library ------------------------------------------------------
td_seed_dir <- function() {
  cands <- c(file.path(getwd(), "seed", "techdesign"), file.path("seed", "techdesign"))
  cands <- cands[dir.exists(cands)]
  if (length(cands) == 0) "" else cands[1]
}

# Named list: design_type -> raw text, in catalog order.
td_seed_texts <- function() {
  d <- td_seed_dir()
  if (!nzchar(d)) return(list())
  files <- list.files(d, pattern = "\\.txt$", full.names = TRUE)
  if (length(files) == 0) return(list())
  txt <- lapply(files, function(f) paste(readLines(f, warn = FALSE), collapse = "\n"))
  names(txt) <- sub("\\.txt$", "", basename(files))
  order_ids <- unlist(lapply(TD_CATALOG, names))
  ord <- c(intersect(order_ids, names(txt)), setdiff(names(txt), order_ids))
  txt[ord]
}

td_seed_parsed <- function(design_type) {
  tx <- td_seed_texts()[[design_type]]
  if (is.null(tx)) return(NULL)
  tryCatch(parse_techdesign_text(tx), error = function(e) NULL)
}

# ---- Mind Map handoff --------------------------------------------------
TD_MINDMAP_CATEGORY <- "Technical Designs"

techdesign_to_mindmap_df <- function(d) {
  comps <- d$components
  lanes <- unique(comps$lane)
  nodes <- list(); n <- 0L
  add <- function(label, content, parent) {
    n <<- n + 1L
    id <- paste0("N", n)
    nodes[[n]] <<- data.frame(node_id = id, node_label = label, node_content = content,
                              parent_node_id = parent, cross_links = "", sort_order = n,
                              stringsAsFactors = FALSE)
    id
  }
  root <- add(d$meta$title, d$meta$summary, ROOT_MARKER)
  comp_node <- character(0)
  for (ln in lanes) {
    lid <- add(ln, paste0(if (identical(d$meta$diagram_kind, "class")) "Tier: " else "Swimlane: ", ln), root)
    for (i in which(comps$lane == ln)) {
      extra <- c(comps$description[i],
                 if (nzchar(comps$technologies[i])) paste0("Technologies: ", comps$technologies[i]),
                 if (nzchar(comps$attributes[i])) paste0("Attributes: ", comps$attributes[i]),
                 if (nzchar(comps$methods[i])) paste0("Methods: ", comps$methods[i]))
      comp_node[comps$id[i]] <- add(comps$label[i], paste(extra[nzchar(extra)], collapse = " | "), lid)
    }
  }
  df <- do.call(rbind, nodes)
  cn <- d$connections
  for (i in seq_len(nrow(df))) {
    cid <- names(comp_node)[match(df$node_id[i], comp_node)]
    if (is.na(cid)) next
    out <- cn[cn$from == cid & cn$to %in% names(comp_node), , drop = FALSE]
    if (nrow(out) > 0) {
      lab <- ifelse(nzchar(out$label), out$label, out$type)
      df$cross_links[i] <- build_cross_links(unname(comp_node[out$to]), lab)
    }
  }
  df
}

# ---- Flex Table handoff ------------------------------------------------
techdesign_to_flex_text <- function(d, which = c("components", "tradeoffs", "connections")) {
  which <- match.arg(which)
  clean <- function(x) { x <- gsub("\\|\\|\\|", " ", as.character(x)); gsub("[\r\n]+", " ", trimws(x)) }
  title <- d$meta$title
  rows <- list()
  if (which == "components") {
    cl <- identical(d$meta$diagram_kind, "class")
    tb <- "Components"; rowdim <- if (cl) "Class" else "Component"; coldim <- "Attribute"
    for (i in seq_len(nrow(d$components))) {
      cc <- d$components[i, ]
      hs <- c(if (cl) "Tier" else "Lane", "Kind", "Description",
              if (cl) c("Attributes", "Methods") else "Technologies")
      vs <- c(cc$lane, cc$kind, cc$description, if (cl) c(cc$attributes, cc$methods) else cc$technologies)
      vs[!nzchar(vs)] <- "-"
      rows[[i]] <- c(clean(cc$label), build_columns_data(hs, vapply(vs, clean, "")), "")
    }
  } else if (which == "tradeoffs") {
    tb <- "Trade-offs"; rowdim <- "Trade-off type"; coldim <- "Aspect"
    labs <- c(pro = "Pros", con = "Cons", risk = "Risks", cost = "Costs", scaling = "Scaling")
    for (k in names(labs)) {
      pts <- d$tradeoffs$text[d$tradeoffs$kind == k]
      if (length(pts) == 0) next
      rows[[length(rows) + 1]] <- c(labs[[k]], build_columns_data("Points", clean(paste(pts, collapse = " ; "))), "")
    }
  } else {
    tb <- "Connections"; rowdim <- "Connection"; coldim <- "Attribute"
    lab <- setNames(d$components$label, d$components$id)
    for (i in seq_len(nrow(d$connections))) {
      cc <- d$connections[i, ]
      rows[[i]] <- c(clean(paste0(lab[[cc$from]] %||% cc$from, " -> ", lab[[cc$to]] %||% cc$to)),
                     build_columns_data(c("Relationship", "Type"), c(clean(cc$label), clean(cc$type))), "")
    }
  }
  if (length(rows) == 0) stop("This design has nothing to send for that table.")
  head <- c(paste0("[", TD_MINDMAP_CATEGORY, "]"), paste0("[", clean(title), "]"),
            paste0("[", clean(title), " - ", tb, "]"), paste0("[", rowdim, "]"), paste0("[", coldim, "]"), "")
  body <- unlist(lapply(rows, function(r) c(paste0("[row_index]: ", r[1]), paste0("[columns_data]: ", r[2]),
                                            paste0("[notes]: ", r[3]), "")))
  paste(c(head, body), collapse = "\n")
}

# ---- Recommender -------------------------------------------------------
td_catalog_listing <- function() {
  paste(unlist(lapply(TD_GROUPS, function(g) {
    e <- TD_CATALOG[[g]]
    vapply(names(e), function(id) sprintf("- group=%s | design_type=%s | %s", g, id, e[[id]]$label), "")
  })), collapse = "\n")
}

generate_td_recommend_prompt <- function(problem, n = 3, constraints = "") {
  paste0(
    "You are a principal architect helping a team choose the right technical design for a problem.\n\n",
    "CATALOG (choose ONLY from these; use the exact group and design_type values):\n", td_catalog_listing(), "\n\n",
    "PROBLEM:\n", trimws(problem), "\n",
    if (nzchar(trimws(constraints))) paste0("\nCONSTRAINTS: ", trimws(constraints), "\n") else "",
    "\nRank the ", n, " best-fitting designs. A recommendation may combine layers (for example a data architecture feeding an ML architecture), ",
    "in which case list each separately with its own rank. Be honest: if a design fits only partly, say so.\n\n",
    "OUTPUT FORMAT (plain text, no markdown, every value on ONE line, no square brackets or double quotes):\n",
    "@recommendation\nrank: <1, 2, 3>\ndesign_group: <ml_genai|data_processing|software_patterns>\ndesign_type: <exact design_type from the catalog>\n",
    "fit: <High|Medium|Low>\nreasoning: <2-3 sentences on why it fits THIS problem>\n",
    "drawbacks: <1-2 sentences on what to watch out for>\n",
    "tailored_context: <1-2 sentences that restate the problem as a context for generating this design>\n\n",
    "Begin now with the first @recommendation block.")
}

parse_td_recommendations <- function(text) {
  recs <- td_parse_blocks(text, "recommendation")
  out <- list()
  for (r in recs) {
    g <- r$design_group %||% ""; t <- r$design_type %||% ""
    if (!g %in% TD_GROUPS || is.null(td_catalog_entry(g, t))) next
    out[[length(out) + 1]] <- list(
      rank = suppressWarnings(as.integer(r$rank %||% as.character(length(out) + 1L))), group = g, design_type = t,
      label = td_catalog_entry(g, t)$label, fit = r$fit %||% "", reasoning = r$reasoning %||% "",
      drawbacks = r$drawbacks %||% "", tailored_context = r$tailored_context %||% "")
  }
  if (length(out) > 0) out <- out[order(vapply(out, function(x) if (is.na(x$rank)) 99L else x$rank, 1L))]
  out
}

# ---- Compare -----------------------------------------------------------
td_compare_table <- function(a, b) {
  cnt <- function(d, k) sum(d$tradeoffs$kind == k)
  tech <- function(d) { x <- unique(trimws(unlist(strsplit(paste(d$components$technologies, collapse = ","), ",")))); x[nzchar(x)] }
  tg <- function(d) { x <- unique(trimws(unlist(strsplit(d$meta$tags, ",")))); x[nzchar(x)] }
  shared <- intersect(tolower(tg(a)), tolower(tg(b)))
  rows <- list(
    c("Group", TD_GROUP_LABELS[[a$meta$design_group]], TD_GROUP_LABELS[[b$meta$design_group]]),
    c("Diagram style", if (a$meta$diagram_kind == "class") "UML class diagram" else "Swimlane architecture", if (b$meta$diagram_kind == "class") "UML class diagram" else "Swimlane architecture"),
    c("Variant", a$meta$variant, b$meta$variant),
    c("Complexity", a$meta$complexity, b$meta$complexity),
    c("Components", nrow(a$components), nrow(b$components)),
    c("Lanes / tiers", length(unique(a$components$lane)), length(unique(b$components$lane))),
    c("Connections", nrow(a$connections), nrow(b$connections)),
    c("Flow steps", nrow(a$steps), nrow(b$steps)),
    c("Pros / cons", paste0(cnt(a, "pro"), " / ", cnt(a, "con")), paste0(cnt(b, "pro"), " / ", cnt(b, "con"))),
    c("Risks / costs", paste0(cnt(a, "risk"), " / ", cnt(a, "cost")), paste0(cnt(b, "risk"), " / ", cnt(b, "cost"))),
    c("Distinct technologies named", length(tech(a)), length(tech(b))),
    c("Tags", a$meta$tags, b$meta$tags),
    c("Shared tags", if (length(shared)) paste(shared, collapse = ", ") else "(none)", if (length(shared)) paste(shared, collapse = ", ") else "(none)"),
    c("When to use", a$meta$when_to_use, b$meta$when_to_use),
    c("When NOT to use", a$meta$when_not_to_use, b$meta$when_not_to_use))
  df <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(df) <- c("Dimension", "A", "B"); df
}

generate_td_compare_prompt <- function(a, b, focus = "") {
  paste0(
    "You are a principal architect comparing two technical designs for a decision-maker.\n\n",
    "DESIGN A:\n", techdesign_to_text(a), "\n\nDESIGN B:\n", techdesign_to_text(b), "\n\n",
    if (nzchar(trimws(focus))) paste0("FOCUS OF THE COMPARISON: ", trimws(focus), "\n\n") else "",
    "Write 6-9 comparison rows on dimensions that genuinely differentiate them (for example data freshness, operational complexity, ",
    "cost profile, failure modes, team skills, scalability, typical use cases). Be specific to these two designs.\n\n",
    "OUTPUT FORMAT (plain text, no markdown): one row per line exactly as\n<dimension> | <what holds for design A> | <what holds for design B>\n",
    "Each cell at most 25 words, no vertical bars inside cells. After the rows add one final line starting with\nverdict: <2-3 sentences on when to prefer A, when B, and when to combine them>\n")
}

parse_td_compare <- function(text) {
  lines <- trimws(strsplit(gsub("\r", "", text %||% ""), "\n", fixed = TRUE)[[1]])
  verdict <- ""
  v <- grep("^verdict\\s*:", lines, ignore.case = TRUE)
  if (length(v) > 0) { verdict <- trimws(sub("^verdict\\s*:\\s*", "", lines[v[1]], ignore.case = TRUE)) }
  rows <- lines[grepl("\\|", lines) & !grepl("^verdict", lines, ignore.case = TRUE)]
  parts <- strsplit(rows, "\\|")
  parts <- Filter(function(p) length(p) >= 3, parts)
  df <- if (length(parts) == 0) data.frame(Dimension = character(), A = character(), B = character(), stringsAsFactors = FALSE)
        else data.frame(Dimension = trimws(vapply(parts, `[`, "", 1)), A = trimws(vapply(parts, `[`, "", 2)),
                        B = trimws(vapply(parts, function(p) paste(p[-(1:2)], collapse = " "), "")), stringsAsFactors = FALSE)
  df <- df[!grepl("^-+$", df$Dimension) & !grepl("^dimension$", df$Dimension, ignore.case = TRUE), , drop = FALSE]
  list(table = df, verdict = verdict)
}

# ---- Ask Claude to modify an existing design ---------------------------
generate_td_modify_prompt <- function(current_text, instruction) {
  paste0(
    "You are editing a technical design stored in a strict plain-text format. Apply the requested change and return the COMPLETE updated design.\n\n",
    "CURRENT DESIGN:\n", current_text, "\n\nREQUESTED CHANGE:\n", trimws(instruction), "\n\n",
    "RULES: keep exactly the same format (header lines, then @component, @connection, @step, @tradeoff and @reference blocks, one value per line). ",
    "Keep all existing ids stable; give new components new unique ids. Every connection must use existing component ids and every component must appear in at least one connection. ",
    "Update flow steps, trade-offs and references when the change makes them wrong. Never use square brackets, double quotes, backslashes or the dollar sign. ",
    "Output only the design text, no commentary and no code fences.")
}

td_strip_fences <- function(x) {
  x <- gsub("^\\s*```[a-zA-Z]*\\s*\n", "", x); gsub("\n\\s*```\\s*$", "", x)
}

# ---- Design Guide content ---------------------------------------------
TD_INFO <- list(
  rag = list(what = "Grounds an LLM in your own documents: chunk and embed offline, retrieve and rerank at question time, answer with citations.",
             best = "Question answering over policies, manuals, tickets and contracts that change often and must be auditable.",
             watch = "Quality is capped by retrieval; chunking, hybrid search and reranking need continuous evaluation.",
             related = "agentic_llm, realtime_ml_pipeline"),
  agentic_llm = list(what = "An LLM that plans, calls tools, observes results and revises its plan, with memory, guardrails and human approval.",
             best = "Multi-step tasks such as research, data analysis, coding and workflow automation.",
             watch = "Latency, cost and unpredictability; add step limits, tracing and approval for risky actions.",
             related = "rag, strategy_pattern"),
  realtime_ml_pipeline = list(what = "Features computed in streaming and batch, shared through a feature store, models served online with monitoring and retraining.",
             best = "Fraud detection, recommendations and pricing where predictions must use the latest events.",
             watch = "Training/serving skew and online store latency; keep one feature definition for both paths.",
             related = "batch_ml_pipeline, kappa_architecture"),
  batch_ml_pipeline = list(what = "Scheduled ingestion, validation, training, evaluation and bulk scoring with a model registry and approval gate.",
             best = "Churn scoring, forecasting and reporting where predictions can be hours old.",
             watch = "Silent upstream schema changes; validation gates and idempotent runs are essential.",
             related = "realtime_ml_pipeline, medallion_lakehouse"),
  lambda_architecture = list(what = "A batch layer recomputes accurate views from full history while a speed layer serves recent data; a serving layer merges both.",
             best = "Needs both accuracy and second-level freshness with existing batch and streaming engines.",
             watch = "Two code paths for the same logic; results can diverge.",
             related = "kappa_architecture, medallion_lakehouse"),
  kappa_architecture = list(what = "One replayable log and one streaming codebase; reprocessing is a replay into a new output table.",
             best = "Event-centric workloads where a single streaming engine can handle live and historical data.",
             watch = "Log retention cost and replay time; exactly-once semantics need care.",
             related = "lambda_architecture, cdc_event_driven"),
  medallion_lakehouse = list(what = "Bronze raw, silver cleaned, gold business-ready layers on a lakehouse with quality checks and a catalog.",
             best = "A governed analytics and ML platform with clear quality stages and lineage.",
             watch = "Layer sprawl and unowned tables; enforce naming, ownership and quality rules.",
             related = "batch_ml_pipeline, lambda_architecture"),
  cdc_event_driven = list(what = "Reads database transaction logs and publishes every change as an event to warehouses, search, caches and services.",
             best = "Keeping many systems in near real-time sync without dual writes or heavy extracts.",
             watch = "A stalled connector can fill the source disk; handle ordering, duplicates and schema evolution.",
             related = "kappa_architecture, observer_pattern"),
  factory_pattern = list(what = "A creator declares a factory method; subclasses decide which concrete product to instantiate.",
             best = "Object creation that varies by configuration or runtime context.",
             watch = "Parallel class hierarchies and indirection when only one product exists.",
             related = "strategy_pattern, adapter_facade_pattern"),
  strategy_pattern = list(what = "Interchangeable algorithms behind one interface, chosen or swapped at runtime by a context.",
             best = "Pricing, routing, validation or sorting rules that vary.",
             watch = "Clients must know which strategy to choose; many tiny classes.",
             related = "factory_pattern, observer_pattern"),
  observer_pattern = list(what = "A subject notifies many observers when its state changes, keeping them loosely coupled.",
             best = "Event systems, UI bindings and notification features.",
             watch = "Unordered notifications, memory leaks from undetached observers, update cascades.",
             related = "cdc_event_driven, strategy_pattern"),
  adapter_facade_pattern = list(what = "Adapter converts one interface into another; Facade offers one simple entry point to a complex subsystem.",
             best = "Integrating legacy or third-party code and hiding subsystem complexity.",
             watch = "Extra indirection; facades growing into god objects.",
             related = "factory_pattern, strategy_pattern")
)

# Jump targets: which tabname shows which group
TD_GROUP_TAB <- c(ml_genai = "techdesign_ml", data_processing = "techdesign_data", software_patterns = "techdesign_patterns")

# ---- Jump to a generate subtab with a design preselected --------------
td_goto_generate <- function(api_manager, session, group, design_type, context = "") {
  api_manager$set_pending_techdesign_selection(list(group = group, design_type = design_type, context = context))
  updateTabItems(session$rootScope(), "sidebar_menu", selected = TD_GROUP_TAB[[group]])
}

# ---- Design pickers (starter library + saved designs) ------------------
# Values: "seed:<design_type>" or "db:<design_id>"
td_design_choices <- function(api_manager, include_seeds = TRUE, include_saved = TRUE) {
  ch <- character(0)
  if (include_seeds) {
    seeds <- names(td_seed_texts())
    for (t in seeds) {
      g <- NULL
      for (gg in TD_GROUPS) if (!is.null(td_catalog_entry(gg, t))) g <- gg
      lab <- if (!is.null(g)) paste0("Starter: ", td_catalog_entry(g, t)$label, " (", TD_GROUP_LABELS[[g]], ")") else paste0("Starter: ", t)
      ch[lab] <- paste0("seed:", t)
    }
  }
  if (include_saved && isTRUE(api_manager$bq_authenticated)) {
    lst <- api_manager$bq_get_techdesign_list()
    if (nrow(lst) > 0) {
      lab <- sprintf("Saved: %s%s (%s)", lst$title, ifelse(is.na(lst$variant) | lst$variant == "", "", paste0(" - ", lst$variant)),
                     TD_GROUP_LABELS[lst$design_group])
      ch <- c(ch, setNames(paste0("db:", lst$design_id), lab))
    }
  }
  ch
}

td_load_design <- function(api_manager, key) {
  if (is.null(key) || !nzchar(key)) return(NULL)
  if (startsWith(key, "seed:")) return(td_seed_parsed(sub("^seed:", "", key)))
  if (startsWith(key, "db:")) {
    row <- api_manager$bq_get_techdesign(sub("^db:", "", key))
    if (nrow(row) == 0) return(NULL)
    return(techdesign_from_row(row))
  }
  NULL
}

td_group_badge <- function(group) {
  col <- c(ml_genai = "#8E44AD", data_processing = "#2980B9", software_patterns = "#27AE60")[[group]]
  tags$span(style = sprintf("background:%s;color:#fff;border-radius:10px;padding:2px 9px;font-size:11px;", col), TD_GROUP_LABELS[[group]])
}

# ---- References that explain / defend each example design -------------
# Each URL was located through a web search (title and address matched) on
# 2026-10-12. Re-check them from time to time: web pages move.
TD_EXAMPLE_REFS <- list(
  rag = list(
    list(title = "Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks", source = "Lewis et al., arXiv 2005.11401 (2020)",
         url = "https://arxiv.org/abs/2005.11401",
         why = "The original RAG paper: combines a retriever over an external document index with a generator, which is the core loop drawn in this diagram.")),
  agentic_llm = list(
    list(title = "ReAct: Synergizing Reasoning and Acting in Language Models", source = "Yao et al., arXiv 2210.03629 (2022)",
         url = "https://arxiv.org/abs/2210.03629",
         why = "Introduces the reason-act-observe loop that the Planner, Executor and tools implement."),
    list(title = "Building effective agents", source = "Anthropic",
         url = "https://www.anthropic.com/news/building-effective-agents",
         why = "Practical guidance on when to use workflows versus agents, tool design, and keeping guardrails and human checkpoints.")),
  realtime_ml_pipeline = list(
    list(title = "MLOps: Continuous delivery and automation pipelines in machine learning", source = "Google Cloud Architecture Center",
         url = "https://docs.cloud.google.com/architecture/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning",
         why = "Describes feature stores, training pipelines, model registry, serving and monitoring-triggered retraining, the building blocks of this design.")),
  batch_ml_pipeline = list(
    list(title = "MLOps: Continuous delivery and automation pipelines in machine learning", source = "Google Cloud Architecture Center",
         url = "https://docs.cloud.google.com/architecture/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning",
         why = "Covers automated data validation, training, evaluation, registry and scheduled or triggered pipeline runs."),
    list(title = "Hidden Technical Debt in Machine Learning Systems", source = "Sculley et al., Google Research, NeurIPS 2015",
         url = "https://research.google/pubs/hidden-technical-debt-in-machine-learning-systems/",
         why = "Explains why data validation, monitoring and clean pipeline boundaries matter, as reflected in the validation gates and drift monitor.")),
  lambda_architecture = list(
    list(title = "Lambda architecture", source = "Databricks Glossary",
         url = "https://databricks.com/glossary/lambda-architecture",
         why = "Explains the batch, speed and serving layers and how results are merged."),
    list(title = "Questioning the Lambda Architecture", source = "Jay Kreps, O'Reilly Radar",
         url = "https://www.oreilly.com/ideas/questioning-the-lambda-architecture",
         why = "The well-known critique of maintaining two code paths, useful for understanding the trade-offs listed here.")),
  kappa_architecture = list(
    list(title = "Questioning the Lambda Architecture", source = "Jay Kreps, O'Reilly Radar",
         url = "https://www.oreilly.com/ideas/questioning-the-lambda-architecture",
         why = "The original argument for a single streaming path where reprocessing is a replay of the log.")),
  medallion_lakehouse = list(
    list(title = "What is the medallion lakehouse architecture?", source = "Databricks documentation",
         url = "https://docs.databricks.com/lakehouse/medallion.html",
         why = "Defines the bronze, silver and gold layers and the data quality progression between them.")),
  cdc_event_driven = list(
    list(title = "Debezium features and documentation", source = "Debezium project",
         url = "https://debezium.io/documentation/reference/features.html",
         why = "Documents log-based change data capture that streams row changes as events."),
    list(title = "Pattern: Transactional outbox", source = "Chris Richardson, microservices.io",
         url = "https://microservices.io/patterns/data/transactional-outbox",
         why = "Explains publishing domain events atomically with database writes, the Outbox part of this design.")),
  factory_pattern = list(
    list(title = "Factory Method", source = "Refactoring Guru",
         url = "https://refactoring.guru/design-patterns/factory-method",
         why = "Clear explanation of the creator and product structure, applicability and pros and cons.")),
  strategy_pattern = list(
    list(title = "Strategy", source = "Refactoring Guru",
         url = "https://refactoring.guru/design-patterns/strategy",
         why = "Explains the context and interchangeable strategy structure and when it replaces conditionals.")),
  observer_pattern = list(
    list(title = "Observer", source = "Refactoring Guru",
         url = "https://refactoring.guru/design-patterns/observer",
         why = "Explains the subscription mechanism between a publisher and its subscribers, including notification pitfalls.")),
  adapter_facade_pattern = list(
    list(title = "Adapter", source = "Refactoring Guru",
         url = "https://refactoring.guru/design-patterns/adapter",
         why = "Explains wrapping an incompatible interface so clients can use it."),
    list(title = "Facade", source = "Refactoring Guru",
         url = "https://refactoring.guru/design-patterns/facade",
         why = "Explains providing one simple interface to a complex subsystem."))
)

td_example_refs_ui <- function(design_type) {
  refs <- TD_EXAMPLE_REFS[[design_type]]
  if (is.null(refs)) return(NULL)
  div(class = "td-example-refs", style = "margin-top:18px;padding:14px;border:1px solid #dfe6e9;border-radius:8px;background:#fff;",
      h4(icon("book"), " Reference and rationale"),
      p(style = "color:#7f8c8d;font-size:12px;", "Sources that explain or defend this design. Links open in a new tab."),
      tags$ul(lapply(refs, function(r) tags$li(style = "margin-bottom:8px;",
        tags$a(href = r$url, target = "_blank", rel = "noopener noreferrer", tags$strong(r$title)),
        tags$span(style = "color:#7f8c8d;", paste0(" - ", r$source)), tags$br(), r$why))))
}

td_build_notes_ui <- function() {
  sec <- function(title, ...) tags$details(style = "margin-bottom:8px;", tags$summary(style = "cursor:pointer;font-weight:600;", title), div(style = "padding:6px 4px 2px 18px;", ...))
  div(class = "td-build-notes", style = "margin-top:18px;padding:14px;border:1px solid #dfe6e9;border-radius:8px;background:#fff;",
    h4(icon("tools"), " How these diagrams are built, and how to keep the quality"),
    sec("1. The principle: the AI supplies data, the app does the drawing",
      p("The Editing Tool (or a seed file) only returns facts: components with an id, label, lane, kind and technologies; connections (from, to, label, type); numbered flow steps; trade-offs; references. It is never asked for coordinates, because language models are unreliable at spatial arithmetic. All geometry is computed in R by code, which is why every diagram follows the same rules and a bad answer cannot produce overlapping boxes."),
      p("The same design is one row in the technical_designs table, so any design can be re-drawn, edited and versioned.")),
    sec("2. What the layout code does",
      tags$ul(
        tags$li(tags$strong("Lane order: "), "swimlanes are ordered left to right to minimise arrows that run backwards, but only when that is a strict improvement, so a deliberately authored order is kept."),
        tags$li(tags$strong("Box size: "), "each box is sized from its wrapped label and technology text, so nothing is cut off."),
        tags$li(tags$strong("Arrows: "), "forward arrows are smooth curves with their attachment points spread along the box side; feedback and long backward arrows are routed through a corridor below the lanes with rounded corners, so they do not cross boxes."),
        tags$li(tags$strong("UML class diagrams: "), "classes sit in tier rows, with name, attributes and methods compartments; inheritance, implementation, composition, aggregation, uses, creates and notifies each get their own line style and arrowhead; long links use elbow routing."),
        tags$li(tags$strong("Visual language: "), "the shape shows the kind of component (cylinder = store, hexagon = model, slanted box = gateway, dashed = external, dotted = cache) and the line style shows the type of arrow; the legend is generated from what is on the diagram."))),
    sec("3. Interactivity and export",
      p("Hovering a box highlights its connections and dims the rest, clicking opens its details, and the step player walks through the flow. The SVG carries its own stylesheet, so PDF, PowerPoint, HTML and JPEG exports look the same as on screen.")),
    sec("4. What to be aware of when you add or change designs",
      tags$ul(
        tags$li("Aim for 10 to 18 components and at most 6 or 7 lanes (6 to 8 classes for patterns). Beyond that, lines cross and labels collide."),
        tags$li("One idea per box, labels of 5 words or fewer, 2 to 4 example technologies."),
        tags$li("List lanes in the order of the main flow, left to right (or tiers top to bottom). Put cross-cutting concerns such as governance and monitoring in the last or first lane."),
        tags$li("Use 'feedback' only for a loop that returns to an earlier stage (retraining, replay, reflection). Use 'control' sparingly, because many control arrows make a diagram noisy."),
        tags$li("Label every arrow with 2 to 4 words saying what flows. Every component must be connected; every step must name real component ids."),
        tags$li("Keep trade-offs honest (pros, cons, risks, costs, scaling) and cite real references only. Never invent a URL; use N/A."),
        tags$li("Avoid square brackets, double quotes, backslashes and the dollar sign in values: the text format cannot carry them."),
        tags$li("After any edit, re-parse and look at the diagram: zero parse warnings, no box hidden behind a line, no unreadable label."))),
    sec("5. Known limits (be realistic)",
      tags$ul(
        tags$li("Dense designs (the agentic system, Kappa) still have some crossing lines and occasionally overlapping arrow labels. The fix is fewer arrows or a different lane order, not manual dragging."),
        tags$li("The Editing Tool's output varies: it may choose odd lanes or too many connections. Use the Compact level of detail for dense topics, then refine in the Design Editor."),
        tags$li("The 12 starter designs were written and checked by hand. Designs generated by the Editing Tool should be reviewed before you rely on them, and their references checked."))))
}
