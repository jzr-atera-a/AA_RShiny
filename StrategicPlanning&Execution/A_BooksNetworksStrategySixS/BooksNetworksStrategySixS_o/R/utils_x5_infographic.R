# R/utils_infographic.R
# ============================================================
# INFOGRAPHIC STUDIO - data model, prompts, research pipeline, storage
# ============================================================
# Storage: ONE row per version in the existing technical_designs table
# (design_group = "infographic", diagram_kind = "infographic"). The full spec is
# JSON in extras_json; sections and sources are mirrored into components_json /
# references_json. No table change.

IG_GROUP <- "infographic"
IG_DATA_TYPES <- c("stat_row", "donut", "bar_chart", "ranking", "pictogram", "region_map", "quote_cards", "compare_matrix")
IG_TEXT_TYPES <- c("icon_row", "steps", "branch_tree", "callout", "flow", "layers", "radial_zones", "requirements", "readiness", "gauge_row", "timeline")
IG_ALL_TYPES <- c(IG_DATA_TYPES, IG_TEXT_TYPES)
IG_TYPE_LABELS <- c(stat_row = "Big numbers (with progress bars)", donut = "Donut chart", bar_chart = "Bar or pencil chart", ranking = "Ranking bars",
                    pictogram = "People pictogram", region_map = "Region tile map", quote_cards = "Quote cards", icon_row = "Icon row",
                    steps = "Steps / timeline", branch_tree = "Branching tree (pros and cons)", callout = "Big callout",
                    flow = "Pipeline / flow diagram", layers = "Architecture layers", radial_zones = "Zones diagram (sensors, threats, protected site)",
                    requirements = "Requirements table (must-have -> how met)", compare_matrix = "Comparison matrix (rating balls)", readiness = "Readiness scale vs threshold (TRL)",
                    gauge_row = "Gauges with targets", timeline = "Timeline / roadmap")
IG_CAPS <- c(stat_row = 4, donut = 6, bar_chart = 8, ranking = 8, pictogram = 4, region_map = 8, quote_cards = 4, icon_row = 6, steps = 6,
             flow = 7, layers = 5, requirements = 8, compare_matrix = 8, readiness = 8, gauge_row = 4, timeline = 7)
# types whose numbers or claims come from the applicant, not from web research
IG_FACT_TYPES <- c("readiness", "gauge_row")

IG_SCHEMA_DOC <- list(
  stat_row = 'stat_row: {"id","type":"stat_row","heading","intro","items":[{"value":"53%","label":"short label","note":"one short sentence","bar":53 (0-100, optional),"icon":"icon_name (optional)", + evidence fields}]}  (2 to 4 items; value is the text shown, e.g. "53%", "$1.2T", "4.1M")',
  donut = 'donut: {"id","type":"donut","heading","intro","center_value":"100","center_label":"percent of ...","items":[{"label","value":number, + evidence fields}]}  (3 to 6 items that add up to a whole)',
  bar_chart = 'bar_chart: {"id","type":"bar_chart","style":"bars" or "pencils","heading","intro","items":[{"label","value":number,"display":"72%" (text shown above the bar), + evidence fields}]}  (3 to 6 items; "pencils" suits 3-5 items)',
  ranking = 'ranking: {"id","type":"ranking","heading","intro","items":[{"label","value":number,"display":"text shown at the bar end", + evidence fields}]}  (4 to 8 items, sorted high to low)',
  pictogram = 'pictogram: {"id","type":"pictogram","heading","intro","items":[{"label","value":number 0-100 (percent; rounded to tenths of 10 people icons),"icon":"user","display":"53%", + evidence fields}]}  (2 to 4 items)',
  region_map = 'region_map: {"id","type":"region_map","heading","intro","items":[{"region":"north_america|south_america|europe|africa|middle_east|asia|oceania","value":number,"display":"text", + evidence fields}]}  (3 to 7 regions)',
  quote_cards = 'quote_cards: {"id","type":"quote_cards","heading","intro","items":[{"quote":"text","attribution":"who said it or where it was published", + evidence fields}]}  (2 to 4 items)',
  icon_row = 'icon_row: {"id","type":"icon_row","heading","intro","items":[{"icon":"icon_name","label":"2-3 words","text":"one short sentence"}]}  (3 to 6 items)',
  steps = 'steps: {"id","type":"steps","heading","intro","items":[{"label":"1-2 words","text":"one short sentence"}]}  (3 to 6 items, in order)',
  branch_tree = 'branch_tree: {"id","type":"branch_tree","heading","intro","root":"the question being weighed","left":{"label":"Positives","icon":"plus","items":[{"icon":"icon_name","text":"one sentence"}]},"right":{"label":"Negatives","icon":"minus","items":[{"icon":"icon_name","text":"one sentence"}]}}  (2 to 4 items per side)',
  callout = 'callout: {"id","type":"callout","heading":"","intro":"","icon":"icon_name","text":"one memorable sentence, max 22 words"}',
  flow = 'flow: {"id","type":"flow","heading","intro","items":[{"icon":"icon_name","label":"1-3 words","text":"short phrase, max 90 characters","tag":"" or "target" or "insert" or "estimate"}]}  (3 to 7 nodes, in order, drawn as boxes joined by arrows; e.g. a processing pipeline)',
  layers = 'layers: {"id","type":"layers","heading","intro","items":[{"icon":"icon_name","label":"tier name, 1-3 words","text":"one short line (optional)","chips":["short item","short item", ... up to 6, max 28 characters each],"tag":""}]}  (2 to 5 tiers from top to bottom, e.g. sensing / edge compute / communications / user interface)',
  radial_zones = 'radial_zones: {"id","type":"radial_zones","heading","intro","center":"protected asset, max 24 chars","center_icon":"icon_name","zones":[{"label":"zone name","text":"what happens here, max 90 chars (may state a target range, marked with tag target)","tag":""}] (2 to 4 zones listed from the OUTERMOST to the innermost),"nodes":[{"label":"max 20 chars","angle":0-359 (0 = top, clockwise),"zone":1-4 (1 = outermost),"icon":"camera"}] (up to 6 sensor nodes),"threats":[{"label":"Drone 1","angle":0-359,"zone":1,"icon":"drone"}] (up to 3)}',
  requirements = 'requirements: {"id","type":"requirements","heading","intro","items":[{"label":"the requirement, max 6 words","text":"how the design meets it, max 110 characters","status":"met" or "partial" or "planned" or "gap","tag":""}]}  (3 to 8 rows; one per must-have; be honest: use partial, planned or gap where that is the truth)',
  compare_matrix = 'compare_matrix: {"id","type":"compare_matrix","heading","intro","columns":[{"label":"option name, max 24 chars","icon":"icon_name","ours":true for the applicant\'s own option (exactly one)}] (2 to 4 columns),"items":[{"label":"criterion, max 8 words","cells":[{"score":0-4 (0 = weak, 4 = strong),"text":"max 24 chars (optional)"}, ... one cell per column in column order],"note":"", + evidence fields}]}  (3 to 8 criteria. BE HONEST: the applicant must NOT win every row; rate competitors fairly. Evidence fields describe the claims about the OTHER options.)',
  readiness = 'readiness: {"id","type":"readiness","heading","intro","unit":"TRL","scale_max":9,"threshold":6,"threshold_label":"TRL 6 required","items":[{"label":"component, max 5 words","value":number on the scale,"text":"one short line on the evidence, max 70 chars","tag":"estimate" (when you are proposing the level yourself) or "insert" (when the applicant has not provided it; then value must be omitted),"confidence":"applicant" (only if the level was stated in the applicant facts) or "judgment"}]}  (3 to 8 components)',
  gauge_row = 'gauge_row: {"id","type":"gauge_row","heading","intro","items":[{"label":"metric name, max 4 words","value":number,"max":number (scale top, e.g. 1 or 100),"display":"text shown, e.g. 0.87","target":number (optional),"note":"context, max 80 chars","tag":"" or "target" or "insert","confidence":"applicant" (value copied from the applicant facts) or "judgment"}]}  (2 to 4 gauges; for a placeholder use tag "insert" and omit value)',
  timeline = 'timeline: {"id","type":"timeline","heading","intro","items":[{"date":"Feb 2027","label":"1-4 words","text":"one short line","state":"done" or "next" or "planned","icon":"icon_name","tag":""}]}  (3 to 7 milestones in date order; use only dates given in the applicant facts)'
)
IG_EVIDENCE_DOC <- 'Evidence fields on every statistic item: "confidence" ("sourced"|"partial"|"judgment"), "metric" (what was measured), "as_of" (date or period), "quote" (VERBATIM excerpt of at most 25 words copied from the page), "source_ids" (["s1"]). A figure that comes from the APPLICANT FACTS (not the web) uses "confidence":"applicant" with no source.'

ig_str <- function(x, n) { v <- tdm_chr(x); if (nchar(v) > n) paste0(substr(v, 1, n - 3), "...") else v }

# ---- normalise one section ----------------------------------------------------
IG_CONF_OK <- c("sourced", "partial", "judgment", "applicant")
ig_norm_conf <- function(it, src_ids) {
  conf <- tolower(tdm_chr(it$confidence)); if (!conf %in% IG_CONF_OK) conf <- "judgment"
  ids <- unlist(it$source_ids); ids <- trimws(as.character(ids)); ids <- ids[nzchar(ids) & ids %in% src_ids]
  if (conf %in% c("sourced", "partial") && length(ids) == 0) conf <- "judgment"
  ver <- tolower(tdm_chr(it$verified))
  list(confidence = conf, source_ids = as.list(ids), verified = if (ver %in% c("yes", "no", "unreachable", "unchecked")) ver else "unchecked")
}
ig_norm_item <- function(it, type, src_ids) {
  if (!is.list(it)) return(NULL)
  out <- list()
  for (k in c("label", "text", "note", "quote", "attribution", "display", "metric", "as_of", "center_label")) if (!is.null(it[[k]])) out[[k]] <- ig_str(it[[k]], c(label = 60, text = 220, note = 120, quote = 280, attribution = 80, display = 24, metric = 100, as_of = 40, center_label = 40)[[k]])
  if (!is.null(it$value)) out$value <- if (is.numeric(it$value)) it$value else ig_str(it$value, 24)
  if (!is.null(it$bar)) out$bar <- min(100, max(0, ig_num(it$bar)))
  if (!is.null(it$icon)) out$icon <- ig_icon_name(it$icon)
  tg <- ig_tag_id(it$tag); if (nzchar(tg)) out$tag <- tg
  if (!is.null(it$region)) { r <- ig_region_id(it$region); if (is.na(r)) return(NULL); out$region <- r }
  if (type %in% IG_DATA_TYPES) { cf <- ig_norm_conf(it, src_ids); out$confidence <- cf$confidence; out$source_ids <- cf$source_ids; out$verified <- cf$verified }
  out
}

# items of the text-style diagram blocks (flow, layers, requirements, timeline, readiness, gauge_row)
ig_norm_diag_item <- function(it, type, src_ids) {
  if (!is.list(it)) return(NULL)
  out <- list(); tg <- ig_tag_id(it$tag); if (nzchar(tg)) out$tag <- tg
  if (!is.null(it$icon)) out$icon <- ig_icon_name(it$icon)
  lab <- ig_str(it$label, 60); txt <- ig_str(it$text, 160)
  switch(type,
    flow = { if (!nzchar(lab)) return(NULL); out$label <- lab; out$text <- ig_str(it$text, 110) },
    layers = { if (!nzchar(lab)) return(NULL); out$label <- lab; out$text <- ig_str(it$text, 90); out$chips <- as.list(ig_strs(it$chips, 6, 28)) },
    requirements = { if (!nzchar(lab)) return(NULL); out$label <- ig_str(it$label, 70); out$text <- ig_str(it$text, 140)
      st <- tolower(tdm_chr(it$status)); out$status <- if (st %in% names(IG_REQ_COL)) st else "met" },
    timeline = { if (!nzchar(lab)) return(NULL); out$date <- ig_str(it$date, 18); out$label <- lab; out$text <- ig_str(it$text, 110)
      stt <- tolower(tdm_chr(it$state)); out$state <- if (stt %in% c("done", "next", "planned")) stt else "planned" },
    readiness = { if (!nzchar(lab)) return(NULL); out$label <- ig_str(it$label, 50); out$text <- ig_str(it$text, 80)
      v <- ig_num(it$value, NA); if (!is.na(v)) out$value <- v else if (is.null(out$tag)) out$tag <- "insert" },
    gauge_row = { if (!nzchar(lab)) return(NULL); out$label <- ig_str(it$label, 40); out$note <- ig_str(it$note, 100)
      v <- ig_num(it$value, NA); if (!is.na(v)) out$value <- v else if (is.null(out$tag)) out$tag <- "insert"
      out$max <- ig_num(it$max, 1); if (out$max <= 0) out$max <- 1
      tg2 <- ig_num(it$target, NA); if (!is.na(tg2)) out$target <- tg2
      out$display <- ig_str(it$display %||% it$value, 20) })
  if (type %in% IG_FACT_TYPES && is.null(out$tag)) {   # numbers: applicant-supplied or judgment (never "sourced")
    cf <- tolower(tdm_chr(it$confidence)); out$confidence <- if (cf == "applicant") "applicant" else "judgment"
  }
  out
}

ig_norm_section <- function(sec, i, src_ids, warn) {
  if (!is.list(sec)) return(list(sec = NULL, warn = warn))
  type <- tolower(tdm_chr(sec$type))
  if (!type %in% IG_ALL_TYPES) return(list(sec = NULL, warn = c(warn, sprintf("Section %d has an unknown type '%s' and was skipped.", i, type))))
  out <- list(id = ig_str(sec$id %||% paste0("s", i), 30), type = type, heading = ig_str(sec$heading, 60), intro = ig_str(sec$intro, 260))
  sl <- suppressWarnings(as.integer(round(as.numeric(sec$slide %||% NA)))); if (!is.na(sl) && sl >= 1 && sl <= 8) out$slide <- sl
  if (type == "callout") { out$text <- ig_str(sec$text %||% sec$statement, 220); out$icon <- ig_icon_name(sec$icon %||% "lightbulb")
    if (!nzchar(out$text)) return(list(sec = NULL, warn = c(warn, sprintf("Callout section %d had no text and was skipped.", i)))) }
  else if (type == "branch_tree") {
    out$root <- ig_str(sec$root %||% sec$heading, 120)
    for (sd in c("left", "right")) {
      s <- sec[[sd]] %||% list(); its <- Filter(Negate(is.null), lapply(s$items %||% list(), function(z) { if (!is.list(z)) return(NULL); list(icon = ig_icon_name(z$icon %||% (if (sd == "left") "plus" else "minus")), text = ig_str(z$text, 220)) }))
      out[[sd]] <- list(label = ig_str(s$label %||% (if (sd == "left") "Positives" else "Negatives"), 30), icon = ig_icon_name(s$icon %||% (if (sd == "left") "plus" else "minus")), items = its[seq_len(min(4, length(its)))])
    }
    if (length(out$left$items) + length(out$right$items) == 0) return(list(sec = NULL, warn = c(warn, sprintf("Tree section %d had no items and was skipped.", i))))
  } else if (type == "radial_zones") {
    zs <- Filter(Negate(is.null), lapply(sec$zones %||% list(), function(z) { if (!is.list(z) || !nzchar(tdm_chr(z$label))) return(NULL); r <- list(label = ig_str(z$label, 26), text = ig_str(z$text, 100)); tg <- ig_tag_id(z$tag); if (nzchar(tg)) r$tag <- tg; r }))
    if (length(zs) < 2) return(list(sec = NULL, warn = c(warn, sprintf("Zones section %d needs at least 2 zones and was skipped.", i))))
    zs <- zs[seq_len(min(4, length(zs)))]; K <- length(zs)
    mk <- function(lst, nmax, default_icon, default_zone) Filter(Negate(is.null), lapply((lst %||% list())[seq_len(min(nmax, length(lst %||% list())))], function(z) {
      if (!is.list(z)) return(NULL); list(label = ig_str(z$label, 22), angle = ig_num(z$angle, NA) %% 360, zone = min(K, max(1, round(ig_num(z$zone, default_zone)))), icon = ig_icon_name(z$icon %||% default_icon)) }))
    nd <- mk(sec$nodes, 6, "camera", K); th <- mk(sec$threats, 3, "drone", 1)
    for (k in seq_along(nd)) if (is.na(nd[[k]]$angle)) nd[[k]]$angle <- (k - 1) * 360 / max(1, length(nd))
    for (k in seq_along(th)) if (is.na(th[[k]]$angle)) th[[k]]$angle <- 40 + 70 * k
    out$center <- ig_str(sec$center, 26); out$center_icon <- ig_icon_name(sec$center_icon %||% "wall"); out$zones <- unname(zs); out$nodes <- unname(nd); out$threats <- unname(th)
  } else if (type == "compare_matrix") {
    cols <- Filter(Negate(is.null), lapply(sec$columns %||% list(), function(c) { if (!is.list(c) || !nzchar(tdm_chr(c$label))) return(NULL); list(label = ig_str(c$label, 28), icon = ig_icon_name(c$icon %||% "radar"), ours = isTRUE(c$ours) || tolower(tdm_chr(c$ours)) == "true") }))
    if (length(cols) < 2) return(list(sec = NULL, warn = c(warn, sprintf("Comparison section %d needs at least 2 columns and was skipped.", i))))
    cols <- cols[seq_len(min(4, length(cols)))]; nc <- length(cols)
    if (!any(vapply(cols, function(c) c$ours, logical(1)))) cols[[1]]$ours <- TRUE
    rows <- Filter(Negate(is.null), lapply(sec$items %||% list(), function(r) {
      if (!is.list(r) || !nzchar(tdm_chr(r$label))) return(NULL)
      o <- ig_norm_item(r, "compare_matrix", src_ids); cl <- r$cells %||% list()
      o$cells <- lapply(seq_len(nc), function(j) { z <- if (j <= length(cl) && is.list(cl[[j]])) cl[[j]] else list(); list(score = min(4, max(0, ig_num(z$score, 0))), text = ig_str(z$text, 28)) }); o }))
    if (length(rows) == 0) return(list(sec = NULL, warn = c(warn, sprintf("Comparison section %d had no rows and was skipped.", i))))
    if (length(rows) > IG_CAPS[["compare_matrix"]]) rows <- rows[seq_len(IG_CAPS[["compare_matrix"]])]
    out$columns <- unname(cols); out$items <- unname(rows)
  } else {
    if (type == "bar_chart") out$style <- if (tolower(tdm_chr(sec$style)) == "pencils") "pencils" else "bars"
    if (type == "donut") { out$center_value <- ig_str(sec$center_value, 12); out$center_label <- ig_str(sec$center_label, 40) }
    if (type == "readiness") { out$unit <- ig_str(sec$unit %||% "TRL", 8); out$scale_max <- min(12, max(3, round(ig_num(sec$scale_max, 9)))); th <- ig_num(sec$threshold, NA)
      if (!is.na(th)) { out$threshold <- th; out$threshold_label <- ig_str(sec$threshold_label %||% sprintf("%s %d required", out$unit, round(th)), 40) } }
    diag <- type %in% c("flow", "layers", "requirements", "timeline", "readiness", "gauge_row")
    items <- Filter(Negate(is.null), lapply(sec$items %||% list(), if (diag) ig_norm_diag_item else ig_norm_item, type = type, src_ids = src_ids))
    cap <- IG_CAPS[[type]]; if (length(items) > cap) { warn <- c(warn, sprintf("Section '%s' had more than %d items; extra items were dropped.", out$heading, cap)); items <- items[seq_len(cap)] }
    if (length(items) == 0) return(list(sec = NULL, warn = c(warn, sprintf("Section %d (%s) had no valid items and was skipped.", i, type))))
    out$items <- unname(items)
  }
  list(sec = out, warn = warn)
}

ig_empty <- function() list(meta = list(design_id = "", title = "", subtitle = "", kicker = "", hero_icons = list(), theme = "sky", topic = "", research = "", generated_with = "", format = "poster", slides = 4L,
                                        layout = "stacked", panels = 3L, cover = "auto", text_size = "normal", palette = list(), slide_titles = list(), facts = "", requirements = ""),
                           sections = list(), sources = tdm_empty_df(c("id", "title", "publisher", "url", "in_search_results", "reachable")), warnings = character(0))

ig_hex <- function(x) { x <- trimws(as.character(if (is.null(x) || length(x) == 0) "" else x[[1]])); if (grepl("^#?[0-9A-Fa-f]{6}$", x)) paste0("#", toupper(sub("^#", "", x))) else "" }

parse_infographic_text <- function(text) {
  j <- tdm_extract_json(text); d <- ig_empty(); warn <- character(0)
  m <- j$meta %||% j
  for (k in c("design_id", "title", "subtitle", "kicker", "topic", "research", "generated_with")) { v <- tdm_chr(m[[k]]); if (nzchar(v)) d$meta[[k]] <- v }
  d$meta$title <- ig_str(d$meta$title, 90); d$meta$subtitle <- ig_str(d$meta$subtitle, 260); d$meta$kicker <- ig_str(d$meta$kicker, 40)
  th <- tolower(tdm_chr(m$theme)); d$meta$theme <- if (th %in% c(names(IG_THEMES), "custom")) th else "sky"
  hi <- unlist(m$hero_icons); d$meta$hero_icons <- as.list(unname(vapply(hi[seq_len(min(3, length(hi)))], ig_icon_name, character(1))))
  d$meta$format <- ig_format_id(m$format); d$meta$slides <- ig_slides_n(m$slides)
  ly <- tolower(tdm_chr(m$layout)); d$meta$layout <- if (ly %in% c("stacked", "dashboard", "flow")) ly else "stacked"
  pn <- suppressWarnings(as.integer(round(as.numeric(m$panels %||% NA)))); d$meta$panels <- if (is.na(pn)) 3L else as.integer(min(6L, max(1L, pn)))
  cv <- tolower(tdm_chr(m$cover)); d$meta$cover <- if (cv %in% c("yes", "no", "auto")) cv else "auto"
  ts <- tolower(tdm_chr(m$text_size)); d$meta$text_size <- if (ts %in% c("small", "normal", "large")) ts else "normal"
  pal <- m$palette %||% list(); pal <- list(navy = ig_hex(pal$navy), teal = ig_hex(pal$teal), magenta = ig_hex(pal$magenta), ochre = ig_hex(pal$ochre))
  d$meta$palette <- if (all(nzchar(unlist(pal)))) pal else list()
  if (identical(d$meta$theme, "custom") && length(d$meta$palette) == 0) { d$meta$theme <- "sky"; warn <- c(warn, "Custom theme needs four valid hex colours; the Sky theme is used instead.") }
  st <- Filter(is.list, m$slide_titles %||% list()); d$meta$slide_titles <- unname(lapply(st[seq_len(min(8, length(st)))], function(z) list(title = ig_str(z$title, 70), kicker = ig_str(z$kicker, 40), subtitle = ig_str(z$subtitle, 160))))
  d$meta$facts <- substr(tdm_chr(m$facts), 1, 8000); d$meta$requirements <- substr(tdm_chr(m$requirements), 1, 4000)
  if (!nzchar(d$meta$title)) stop("The spec has no title.")
  src <- tdm_list_to_df(j$sources, c("id", "title", "publisher", "url", "in_search_results", "reachable"))
  src$id <- trimws(src$id); src <- src[nzchar(src$id) & !duplicated(src$id), , drop = FALSE]; src$url[!grepl("^https?://", src$url)] <- ""
  d$sources <- src; rownames(d$sources) <- NULL
  secs <- list()
  for (i in seq_along(j$sections %||% list())) { r <- ig_norm_section(j$sections[[i]], i, d$sources$id, warn); warn <- r$warn; if (!is.null(r$sec)) secs[[length(secs) + 1]] <- r$sec }
  if (length(secs) == 0) stop("The spec has no valid sections.")
  ids <- vapply(secs, function(s) s$id, ""); if (anyDuplicated(ids)) for (k in which(duplicated(ids))) secs[[k]]$id <- paste0(secs[[k]]$id, "_", k)
  d$sections <- secs; d$warnings <- unique(warn)
  d <- ig_check_applicant(d); d
}

# a figure marked "applicant" must really appear in the facts the applicant supplied; otherwise it is only a judgment
ig_check_applicant <- function(d) {
  facts <- as.character(d$meta$facts %||% ""); toks <- unique(unlist(strsplit(gsub("[^0-9.]", " ", facts), "\\s+"))); toks <- sub("\\.$", "", toks[nzchar(toks)])
  tn <- suppressWarnings(as.numeric(toks)); tn <- tn[!is.na(tn)]
  for (si in seq_along(d$sections)) {
    its <- d$sections[[si]]$items; if (is.null(its)) next
    for (k in seq_along(its)) {
      it <- its[[k]]; if (!is.list(it) || !identical(it$confidence, "applicant")) next
      v <- ig_num(it$value, NA); if (is.na(v)) v <- ig_num(it$display, NA); if (is.na(v)) next   # nothing numeric to check
      found <- length(tn) > 0 && any(abs(tn - v) < 1e-9 | abs(tn - v * 100) < 1e-9 | abs(tn * 100 - v) < 1e-9)
      if (!found) { its[[k]]$confidence <- "judgment"; d$warnings <- unique(c(d$warnings, sprintf("'%s': the value %s is not in the facts you supplied, so it is shown as a judgment, not as your data.", it$label %||% "item", format(v)))) }
    }
    d$sections[[si]]$items <- its
  }
  d
}

ig_to_list <- function(d) list(meta = d$meta, sections = d$sections, sources = lapply(seq_len(nrow(d$sources)), function(i) as.list(d$sources[i, , drop = FALSE])))
infographic_to_text <- function(d, pretty = TRUE) as.character(jsonlite::toJSON(ig_to_list(d), auto_unbox = TRUE, pretty = pretty, null = "null", na = "null"))

# ---- storage -------------------------------------------------------------------
ig_to_row <- function(d, design_id, name = NULL, change_type = "create", created_by = "claude_agent") {
  secs <- d$sections
  comps <- data.frame(id = vapply(secs, function(s) s$id, ""), label = vapply(secs, function(s) s$heading, ""), lane = vapply(secs, function(s) s$type, ""), kind = "section",
                      description = vapply(secs, function(s) s$intro %||% "", ""), technologies = "", attributes = "", methods = "", stringsAsFactors = FALSE)
  refs <- data.frame(title = d$sources$title, author = d$sources$publisher, url = d$sources$url, stringsAsFactors = FALSE)
  cnt <- ig_evidence_counts(d); d$meta$design_id <- design_id
  data.frame(design_id = design_id, design_group = IG_GROUP, design_type = IG_GROUP, name = name %||% d$meta$title, variant = d$meta$topic, title = d$meta$title, summary = d$meta$subtitle,
             when_to_use = paste("theme:", d$meta$theme), when_not_to_use = sprintf("evidence: %d verified, %d unverified, %d contradicted, %d applicant, %d judgment", cnt[["verified"]], cnt[["unverified"]], cnt[["contradicted"]], cnt[["applicant"]], cnt[["judgment"]]),
             complexity_level = sprintf("%d sections", length(secs)), tags = paste(c("infographic", unique(comps$lane)), collapse = ","), diagram_kind = "infographic",
             components_json = td_df_to_json(comps), connections_json = "[]", flow_steps_json = "[]", tradeoffs_json = "[]", references_json = td_df_to_json(refs),
             extras_json = infographic_to_text(d, pretty = FALSE), schema_version = 1L, change_type = change_type, created_by = created_by, stringsAsFactors = FALSE)
}
infographic_from_row <- function(row) {
  ex <- row[["extras_json"]][1]
  if (is.null(ex) || is.na(ex) || nchar(ex) < 10) stop("This saved row has no infographic data.")
  d <- parse_infographic_text(ex); d$meta$design_id <- as.character(row[["design_id"]][1]); d
}

ig_seed_dir <- function() { for (p in c("seed/infographic", file.path(getwd(), "seed", "infographic"))) if (dir.exists(p)) return(p); "seed/infographic" }
ig_seed_files <- function() { f <- sort(list.files(ig_seed_dir(), pattern = "\\.json$", full.names = TRUE)); setNames(f, tools::toTitleCase(gsub("_", " ", sub("^[0-9]+_", "", tools::file_path_sans_ext(basename(f)))))) }

ig_facts_table <- function(d) {
  rows <- list()
  for (s in d$sections) for (it in (s$items %||% list())) if (is.list(it) && nzchar(it$confidence %||% "")) {
    rows[[length(rows) + 1]] <- data.frame(Section = s$heading, Type = s$type, Item = as.character(it$label %||% it$region %||% it$quote %||% ""), Value = as.character(it$display %||% it$value %||% ""),
                                           Evidence = ig_item_status(it), Metric = as.character(it$metric %||% ""), As_of = as.character(it$as_of %||% ""), Quote = as.character(it$quote %||% ""),
                                           Sources = paste(unlist(it$source_ids), collapse = ","), stringsAsFactors = FALSE)
  }
  if (length(rows) == 0) data.frame(Section = character(), Type = character(), Item = character(), Value = character(), Evidence = character(), Metric = character(), As_of = character(), Quote = character(), Sources = character())
  else do.call(rbind, rows)
}

# ---- prompts -----------------------------------------------------------------------
IG_JSON_NOTE <- "Respond with ONE JSON object and nothing else (no markdown fences, no commentary). Plain ASCII text in strings. Keep every text short: the layout is fixed and long text is cut off."

# the facts the applicant supplied, and the rules for using them
ig_facts_block <- function(meta) {
  f <- trimws(as.character(meta$facts %||% "")); rq <- trimws(as.character(meta$requirements %||% ""))
  if (!nzchar(f) && !nzchar(rq)) return("")
  paste0(
    if (nzchar(f)) paste0("APPLICANT FACTS (authoritative; supplied by the user):\n", f, "\n\n") else "",
    if (nzchar(rq)) paste0("REQUIREMENTS THE INFOGRAPHIC MUST ADDRESS (one per line):\n", rq, "\n\n") else "",
    "HONESTY RULES:\n",
    "  - Numbers that describe the applicant's own results may only be copied from the APPLICANT FACTS (confidence=\"applicant\"). Never invent, round up or extend a result.\n",
    "  - Anything the facts say is not done yet must appear as a visible placeholder: tag \"insert\", no value (the page shows [INSERT]).\n",
    "  - A design goal that is not a measured result must carry tag \"target\". A level or score you propose yourself (e.g. a TRL) must carry tag \"estimate\".\n",
    "  - Comparisons with competing options must be fair: the applicant must NOT win every row.\n\n")
}

generate_ig_plan_prompt <- function(topic, n_sections, allowed, theme, extra = "", format = "poster", slides = 4L, layout = "stacked", panels = 3L, cover = "auto", facts = "", requirements = "") {
  fmt <- ig_format_id(format); f <- IG_FORMATS[[fmt]]; slides <- ig_slides_n(slides); flowl <- identical(layout, "flow"); dash <- layout %in% c("dashboard", "flow") && !identical(fmt, "poster")
  cv <- ig_cover_on(fmt, slides, cover); content_slides <- slides - as.integer(cv)
  flow_note <- if (!flowl) "" else paste0("STYLE: this is an ILLUSTRATED FLOW infographic. The sections are linked by one continuous path and are read in order (left to right, then back right to left on the next row), so the ORDER of the sections is the story: each section should lead to the next. ",
    "Prefer block types that draw well as connected, stylised shapes: flow, steps, icon_row (icon orbs), ranking (ribbons from a hub), stat_row (big numerals), timeline, radial_zones, branch_tree, donut, pictogram, bar_chart (pencils), compare_matrix, readiness, gauge_row. Give each section a short, punchy heading (max 4 words).\n\n")
  layout_txt <- if (identical(fmt, "poster")) flow_note else if (dash) paste0(flow_note,
    "LAYOUT: this will be shown as ", slides, " separate fixed-size slide(s) in the ", f$label, " format", if (cv) " (slide 1 is a title cover generated by the app; do not plan it)" else "", ". ",
    "Each content slide is a DASHBOARD of about ", panels, " panels (cards), each panel holding one section. Plan EXACTLY ", n_sections, " sections, ", panels, " per content slide, and give every section a \"slide\" number (",
    if (cv) "2" else "1", " to ", slides, "). Make each slide tell one part of the story and pick a mix of block types that look different (pipelines, zone diagrams, gauges, matrices, timelines, charts), with a wide block (flow, compare_matrix, timeline) and compact ones (gauge_row, readiness, stat_row, donut) on each slide. ",
    "Every panel stands alone: a clear heading, at most 5 items, very short labels. Also return \"slides\": [{\"title\": \"the message of this slide, max 9 words\", \"kicker\": \"2-3 word label\", \"subtitle\": \"one short line\"} ...] with one entry per content slide.\n\n") else paste0(
    "LAYOUT: this is NOT a tall poster. It will be shown as ", slides, " separate fixed-size page(s) in the ", f$label, " format",
    if (isTRUE(f$cover) && slides >= 2) " (page 1 is a title cover, then the sections follow)" else "", ", about ", f$per, " section(s) per page. ",
    "Every section must therefore stand alone on its page: a clear heading, at most 4 items, very short labels and sentences. Plan EXACTLY ", n_sections, " sections.\n\n")
  paste0(
    "TASK: INFOGRAPHIC_PLAN\n\nPlan a rich, visual infographic ", if (identical(fmt, "poster")) "poster" else "deck", " about:\n\"", topic, "\"\n\n",
    if (nzchar(trimws(extra))) paste0("Extra instructions: ", extra, "\n\n") else "",
    ig_facts_block(list(facts = facts, requirements = requirements)),
    layout_txt,
    "The infographic is a sequence of SECTIONS. Each section uses exactly one block type from this list (use only these):\n",
    paste(sprintf("  - %s: %s", allowed, IG_TYPE_LABELS[allowed]), collapse = "\n"), "\n\n",
    "Plan ", if (identical(fmt, "poster")) "about " else "exactly ", n_sections, " sections with a clear story",
    if (nzchar(trimws(requirements))) ", making sure EVERY requirement listed above is addressed by at least one section (name the requirement in that section's brief)" else ": hook, what it is, the numbers, the voices or views, the trade-offs, what to do", ". ",
    "Mix block types (avoid repeating one type more than twice). Put the types that carry statistics where the numbers matter. ",
    "For each section's \"brief\", list the exact facts, figures, labels and placeholders it must show, COPYING the relevant applicant facts word for word, because the writer of that section sees only the brief.\n\n",
    "Return JSON: {\"title\": \"max 8 words\", \"subtitle\": \"one sentence\", \"kicker\": \"2-4 word label above the title\", ",
    "\"hero_icons\": [up to 3 icon names], ",
    if (identical(theme, "auto")) paste0("\"theme\": one of ", paste(names(IG_THEMES), collapse = "|"), " (choose what suits the topic), ") else paste0("\"theme\": \"", theme, "\", "),
    if (dash) "\"slides\": [...], " else "",
    "\"sections\": [{\"id\": \"s1\", \"type\": \"block type\", \"heading\": \"max 5 words\", \"intro\": \"one sentence\", ",
    if (dash) "\"slide\": 1, " else "", "\"brief\": \"what this section must show, including which facts or figures are needed\"}, ...]}\n\n",
    "Icon names you may use: ", paste(IG_ICON_NAMES, collapse = ", "), ".\n", IG_JSON_NOTE, "\n")
}

generate_ig_data_prompt <- function(meta, sec, research, max_uses = 4L) {
  paste0(
    "TASK: INFOGRAPHIC_DATA\n\nPoster: \"", meta$title, "\" - ", meta$subtitle, "\n",
    ig_facts_block(meta),
    "Fill this section: id=", sec$id, ", type=", sec$type, ", heading=\"", sec$heading, "\"\nIts brief: ", sec$brief, "\n\n",
    "Block format:\n", IG_SCHEMA_DOC[[sec$type]], "\n", IG_EVIDENCE_DOC, "\n\n",
    if (research) paste0(
      "RESEARCH: use the web search tool (at most ", max_uses, " searches) to find REAL figures from credible sources (statistics offices, central banks, agencies, company filings, reputable research). ",
      "Rules:\n  1. confidence=\"sourced\" only when a retrieved page states the figure; \"partial\" when it supports it indirectly; otherwise \"judgment\" with no sources. Never present a guess as sourced.\n",
      "  2. For sourced/partial items fill metric, as_of, quote (verbatim, max 25 words, copied from the page) and source_ids.\n",
      "  3. Only list sources whose URL you actually retrieved with the tool. NEVER write a URL from memory.\n",
      if (nzchar(trimws(as.character(meta$facts %||% "")))) "  3b. Figures about the applicant come from the APPLICANT FACTS above (confidence=\"applicant\", no search needed). Use the web only for outside facts such as competing technologies.\n" else "",
      if (sec$type == "quote_cards") "  4. quote_cards: each quote must be a verbatim excerpt from a retrieved page and attribution must be the person or organisation named there. If you cannot find real quotes, return fewer items. Never invent a quotation.\n" else "",
      "\nReturn JSON: {\"section\": {the block}, \"sources\": [{\"id\": \"s1\", \"title\": \"page title\", \"publisher\": \"organisation\", \"url\": \"https://...\"}]}\n") else paste0(
      "NO WEB RESEARCH in this run: use your own knowledge, set confidence=\"judgment\" for every item, leave quote/metric/as_of empty and sources empty.",
      if (sec$type == "quote_cards") " quote_cards: write 'key points' (paraphrased advice), NOT quotations, and never attribute words to a real named person; set attribution to \"Key point\"." else "", "\n\nReturn JSON: {\"section\": {the block}, \"sources\": []}\n"),
    "Icon names you may use: ", paste(IG_ICON_NAMES, collapse = ", "), ".\n", IG_JSON_NOTE, "\n")
}

generate_ig_content_prompt <- function(meta, secs, knowledge = FALSE) {
  specs <- vapply(secs, function(s) sprintf("- id=%s, type=%s, heading=\"%s\"\n  brief: %s\n  format: %s", s$id, s$type, s$heading, s$brief, IG_SCHEMA_DOC[[s$type]]), character(1))
  paste0(
    "TASK: INFOGRAPHIC_CONTENT\n\nPoster: \"", meta$title, "\" - ", meta$subtitle, "\n", ig_facts_block(meta), "Write the content of these sections (keep the ids, types and headings given):\n", paste(specs, collapse = "\n"), "\n\n",
    if (knowledge) paste0(IG_EVIDENCE_DOC, "\nNO WEB RESEARCH in this run: set confidence=\"judgment\" on every statistic item, leave quote/metric/as_of empty and source_ids empty. Figures are illustrative estimates from your own knowledge. For quote_cards write 'key points' (paraphrased advice), NOT quotations, never attributed to a real named person; attribution=\"Key point\".\n\n") else "",
    "Return JSON: {\"sections\": [ one block per section above, in the same order ]}\n",
    "Icon names you may use: ", paste(IG_ICON_NAMES, collapse = ", "), ".\n", IG_JSON_NOTE, "\n")
}

# ---- sources registry + verification -------------------------------------------------
ig_register_sources <- function(d, resp_sources, search_urls = character(0)) {
  new_src <- tdm_list_to_df(resp_sources, c("id", "title", "publisher", "url")); new_src$url[!grepl("^https?://", new_src$url)] <- ""
  norm <- function(x) sub("/+$", "", sub("^https?://(www\\.)?", "", tolower(x))); map <- list()
  for (i in seq_len(nrow(new_src))) {
    u <- new_src$url[i]; hit <- if (nzchar(u)) match(u, d$sources$url) else NA_integer_
    if (is.na(hit)) {
      gid <- paste0("S", nrow(d$sources) + 1L)
      inres <- if (length(search_urls) > 0 && nzchar(u)) (if (any(norm(search_urls) == norm(u))) "yes" else "no") else ""
      d$sources <- rbind(d$sources, data.frame(id = gid, title = new_src$title[i], publisher = new_src$publisher[i], url = u, in_search_results = inres, reachable = "", stringsAsFactors = FALSE))
      map[[new_src$id[i]]] <- gid
    } else map[[new_src$id[i]]] <- d$sources$id[hit]
  }
  list(d = d, map = map)
}
ig_remap_items <- function(sec, map) {
  fix <- function(it) { if (is.list(it) && !is.null(it$source_ids)) { ids <- trimws(as.character(unlist(it$source_ids))); it$source_ids <- as.list(unname(vapply(ids, function(x) if (!is.null(map[[x]])) map[[x]] else "", ""))); it$source_ids <- Filter(nzchar, it$source_ids) }; it }
  sec$items <- lapply(sec$items %||% list(), fix); sec
}

ig_verify <- function(d, fetcher = tdm_fetch_page_text, progress = NULL) {
  d$sources$reachable <- rep("", nrow(d$sources)); cache <- list(); urls <- unique(d$sources$url[nzchar(d$sources$url)])
  for (i in seq_along(urls)) { if (!is.null(progress)) progress(sprintf("Checking source %d of %d ...", i, length(urls))); p <- tryCatch(fetcher(urls[i]), error = function(e) NA_character_); cache[[urls[i]]] <- if (is.na(p)) NA_character_ else tdm_norm_text(p) }
  for (i in seq_len(nrow(d$sources))) { u <- d$sources$url[i]; d$sources$reachable[i] <- if (!nzchar(u) || is.null(cache[[u]]) || is.na(cache[[u]])) "no" else "yes" }
  for (si in seq_along(d$sections)) {
    its <- d$sections[[si]]$items; if (is.null(its)) next
    for (k in seq_along(its)) {
      it <- its[[k]]; if (!is.list(it) || !nzchar(it$confidence %||% "") || it$confidence == "judgment") next
      ids <- as.character(unlist(it$source_ids)); q <- as.character(it$quote %||% "")
      if (!nzchar(q)) { its[[k]]$verified <- "unchecked"; next }
      res <- vapply(ids, function(sid) { u <- d$sources$url[match(sid, d$sources$id)]; if (is.na(u) || !nzchar(u) || is.null(cache[[u]]) || is.na(cache[[u]])) "unreachable" else tdm_quote_in_page(q, cache[[u]]) }, character(1))
      its[[k]]$verified <- if (length(res) == 0) "unreachable" else if (any(res == "yes")) "yes" else if (any(res == "no")) "no" else if (any(res == "unchecked")) "unchecked" else "unreachable"
    }
    d$sections[[si]]$items <- its
  }
  d
}

# ---- orchestration -------------------------------------------------------------------
ig_run_pipeline <- function(api, topic, n_sections = 8, allowed = IG_ALL_TYPES, theme = "auto", research = TRUE, max_uses = 4L, verify = TRUE,
                            extra = "", progress = function(msg) NULL, fetcher = tdm_fetch_page_text, format = "poster", slides = 4L,
                            layout = "stacked", panels = 3L, cover = "auto", text_size = "normal", palette = list(), facts = "", requirements = "") {
  format <- ig_format_id(format); slides <- ig_slides_n(slides); layout <- if (identical(layout, "flow")) "flow" else if (identical(layout, "dashboard") && !identical(format, "poster")) "dashboard" else "stacked"
  panels <- as.integer(min(6L, max(1L, ig_num(panels, 3)))); cover <- if (tolower(as.character(cover)) %in% c("yes", "no", "auto")) tolower(as.character(cover)) else "auto"
  if (!identical(format, "poster")) n_sections <- ig_sections_for(format, slides, layout, panels, cover)
  allowed <- intersect(allowed, IG_ALL_TYPES); if (length(allowed) == 0) allowed <- IG_ALL_TYPES
  progress("Step 1: planning the story and the sections ...")
  pj <- tdm_extract_json(api$call_claude(generate_ig_plan_prompt(topic, n_sections, allowed, theme, extra, format, slides, layout, panels, cover, facts, requirements), max_tokens = 6000))
  plan <- Filter(function(s) is.list(s) && tolower(tdm_chr(s$type)) %in% allowed, pj$sections %||% list())
  if (length(plan) == 0) stop("The plan contained no usable sections.")
  plan <- lapply(seq_along(plan), function(i) list(id = paste0("s", i), type = tolower(tdm_chr(plan[[i]]$type)), heading = ig_str(plan[[i]]$heading, 60), intro = ig_str(plan[[i]]$intro, 260), brief = tdm_chr(plan[[i]]$brief), slide = suppressWarnings(as.integer(round(as.numeric(plan[[i]]$slide %||% NA))))))
  d <- ig_empty()
  d$meta$title <- ig_str(pj$title, 90); d$meta$subtitle <- ig_str(pj$subtitle, 260); d$meta$kicker <- ig_str(pj$kicker, 40)
  d$meta$hero_icons <- as.list(unlist(pj$hero_icons)); d$meta$topic <- topic; d$meta$format <- format; d$meta$slides <- slides
  d$meta$layout <- layout; d$meta$panels <- panels; d$meta$cover <- cover; d$meta$text_size <- if (text_size %in% c("small", "large")) text_size else "normal"
  d$meta$facts <- substr(as.character(facts %||% ""), 1, 8000); d$meta$requirements <- substr(as.character(requirements %||% ""), 1, 4000)
  st <- Filter(is.list, pj$slides %||% list()); d$meta$slide_titles <- unname(lapply(st[seq_len(min(8, length(st)))], function(z) list(title = ig_str(z$title, 70), kicker = ig_str(z$kicker, 40), subtitle = ig_str(z$subtitle, 160))))
  pal <- palette %||% list()
  if (length(pal) == 4 && all(nzchar(vapply(pal, ig_hex, ""))) ) { d$meta$palette <- lapply(pal, ig_hex); theme <- "custom" }
  d$meta$research <- if (research) "web" else "knowledge"; d$meta$generated_with <- format(Sys.time(), "%Y-%m-%d")
  d$meta$theme <- if (identical(theme, "custom")) "custom" else if (identical(theme, "auto")) (if (tolower(tdm_chr(pj$theme)) %in% names(IG_THEMES)) tolower(tdm_chr(pj$theme)) else "sky") else theme
  filled <- list(); warn <- character(0)
  take_blocks <- function(blocks) for (b in blocks) if (is.list(b) && nzchar(tdm_chr(b$id))) filled[[tdm_chr(b$id)]] <<- b

  if (research) {
    dat <- Filter(function(s) s$type %in% IG_DATA_TYPES, plan)
    for (k in seq_along(dat)) {
      s <- dat[[k]]; progress(sprintf("Step 2: researching '%s' (%d of %d) ...", s$heading, k, length(dat)))
      resp <- tryCatch(api$call_claude(generate_ig_data_prompt(d$meta, s, TRUE, max_uses), max_tokens = 6000, tools = list(claude_web_search_tool(max_uses))), error = function(e) e)
      pj2 <- if (inherits(resp, "error")) NULL else tryCatch(tdm_extract_json(resp), error = function(e) NULL)
      forced <- FALSE
      if (is.null(pj2)) {
        progress(sprintf("   retrying '%s' without the search tool (items will be marked as judgment) ...", s$heading))
        resp <- tryCatch(api$call_claude(generate_ig_data_prompt(d$meta, s, FALSE), max_tokens = 6000), error = function(e) e)
        pj2 <- if (inherits(resp, "error")) NULL else tryCatch(tdm_extract_json(resp), error = function(e) NULL); forced <- TRUE
      }
      if (is.null(pj2) || !is.list(pj2$section)) { warn <- c(warn, sprintf("Section '%s' could not be filled.", s$heading)); next }
      b <- pj2$section; b$id <- s$id; b$type <- s$type
      if (forced) { b$items <- lapply(b$items %||% list(), function(it) { if (!identical(it$confidence, "applicant")) it$confidence <- "judgment"; it$source_ids <- list(); it }); pj2$sources <- list() }
      su <- if (!inherits(resp, "error")) attr(resp, "claude_search_urls") else NULL
      rg <- ig_register_sources(d, pj2$sources %||% list(), if (is.null(su)) character(0) else su$url); d <- rg$d
      filled[[s$id]] <- ig_remap_items(b, rg$map)
    }
    txt <- Filter(function(s) s$type %in% IG_TEXT_TYPES, plan)
    if (length(txt) > 0) {
      progress("Step 3: writing the remaining sections ...")
      r <- tryCatch(tdm_extract_json(api$call_claude(generate_ig_content_prompt(d$meta, txt, FALSE), max_tokens = 6000)), error = function(e) NULL)
      if (is.null(r)) warn <- c(warn, "The text sections could not be written.") else take_blocks(r$sections %||% list())
    }
  } else {
    progress("Step 2: writing all sections from knowledge (no web research) ...")
    r <- tryCatch(tdm_extract_json(api$call_claude(generate_ig_content_prompt(d$meta, plan, TRUE), max_tokens = 9000)), error = function(e) e)
    if (inherits(r, "error")) stop("Could not write the sections: ", conditionMessage(r))
    take_blocks(r$sections %||% list())
    for (id in names(filled)) { filled[[id]]$items <- lapply(filled[[id]]$items %||% list(), function(it) { if (is.list(it) && !is.null(it$confidence) && !identical(it$confidence, "applicant")) { it$confidence <- "judgment"; it$source_ids <- list() }; it }) }
  }
  secs <- list()
  for (s in plan) { b <- filled[[s$id]]; if (is.null(b)) { warn <- c(warn, sprintf("Section '%s' is missing.", s$heading)); next }; b$id <- s$id; b$type <- s$type; if (!is.na(s$slide)) b$slide <- s$slide; if (!nzchar(tdm_chr(b$heading))) b$heading <- s$heading; if (!nzchar(tdm_chr(b$intro))) b$intro <- s$intro; secs[[length(secs) + 1]] <- b }
  d$sections <- secs
  d <- parse_infographic_text(infographic_to_text(d))   # normalise + validate
  if (research && verify && nrow(d$sources) > 0) { d <- ig_verify(d, fetcher, function(m) progress(paste("Step 4:", m))); d <- parse_infographic_text(infographic_to_text(d)) }
  d$warnings <- unique(c(warn, d$warnings)); d
}

# ---- download bar ---------------------------------------------------------------------
ig_export_ui <- function(ns, target_id, default_filename = "infographic") {
  sel <- ns("ig_format")
  tags$div(class = "export-controls-bar",
    tags$label("Download as:", `for` = sel, class = "export-controls-label"),
    tags$select(id = sel, class = "form-control export-format-select",
      tags$option(value = "pptx", "PowerPoint (PPTX, one picture per slide)"),
      tags$option(value = "pdf", "PDF (one page per slide; A4 / A5 formats use the real paper size)"),
      tags$option(value = "pdf_2up", "PDF: 2 x A5 slides on one A4 portrait sheet (print-ready, no cropping)"),
      tags$option(value = "pdf_a4", "PDF in A4 pages (long poster only)"),
      tags$option(value = "html", "HTML (standalone file)"),
      tags$option(value = "jpeg", "JPEG (ZIP of images when there are several slides)"), tags$option(value = "png", "PNG (ZIP of images when there are several slides)"),
      tags$option(value = "gif", "GIF (animated when there are several slides)")),
    tags$button(type = "button", class = "btn btn-success export-download-btn",
                onclick = sprintf("window.exportInfographic('%s', '%s', '%s')", target_id, sel, default_filename),
                tags$i(class = "fa fa-download"), " Download"))
}
