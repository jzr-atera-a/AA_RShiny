# R/utils_collab_sync.R
# Two-way exchange of funding programmes with the CollaborationPlanning app (v0.8.0) through its Google Drive folder.
#
# What CollaborationPlanning writes into its folder (R/drive.R of that app):
#   <Country>/<Category>/<Topic>/<programme>__<analysis_id>.json   one Claude analysis (appProperties cp_type=analysis, cp_id)
#   <Country>/<Category>/<Topic>/<programme>__<analysis_id>.html   the same, to read (cp_type=analysis_html)
#   Backups/<YYYY-MM-DD>/programmes.csv                            its whole programmes table, once a day (and on demand)
# What it reads back: only the analysis .json files (Analysis library > "Read from Drive").
#
# So this app:
#   * IMPORTS the latest Backups/<date>/programmes.csv and the programmes found in the analysis tables, maps them to the
#     funding_programmes columns and loads them into BigQuery. Every row is kept; a programme already in the table
#     (same name + funder/sponsor) is loaded with repeated = TRUE so it is easy to tell apart. Rows carry
#     source = "CollaborationPlanning backup" / "CollaborationPlanning analysis" and source_ref = that app's id.
#   * EXPORTS funding programmes as analyses in that app's exact format and place, so its existing
#     "Read from Drive" brings them into its Analysis library without any change to it.
#
# Two ways to reach the folder (API Settings > Google Drive > CollaborationPlanning folder), as in that app:
#   api     the Drive API with a service account that is a member of the Shared Drive holding the folder
#           (the same key CollaborationPlanning uses, or another member key)
#   folder  a folder on this computer synced by Google Drive for desktop (e.g. G:/Shared drives/Team/Collaboration Planning)
# Settings: the "collaboration_planning" section of bos_config.json in the keys folder.

COLLAB_APP <- "CollaborationPlanning"
COLLAB_ANALYSIS_COLS <- c("analysis_id", "suggestion_id", "title", "instructions", "model", "result_raw", "tables_json",
                          "summary", "country", "category", "topic", "programme", "access_emails", "status", "created_by",
                          "created_at", "updated_at", "drive_id", "drive_path", "drive_synced_at", "deleted")
COLLAB_SOURCE_BACKUP <- "CollaborationPlanning backup"
COLLAB_SOURCE_ANALYSIS <- "CollaborationPlanning analysis"
COLLAB_SOURCE_TABLE <- "CollaborationPlanning table"
COLLAB_EXPORT_PREFIX <- "bos_"        # analysis_id of programmes this app shares (bos_<funding id>)

collab_settings_default <- function() list(
  mode = "off",               # off | api | folder
  folder_id = "",             # api: the CollaborationPlanning folder (id or link), inside a Shared Drive
  local_path = "",            # folder: the synced folder on this computer
  key_file = "",              # api: service-account key; "" = the keys-folder key
  share_with = "",            # access list written into exported analyses ("" = that app's owner/admins only; "everyone" = all users)
  exported_by = "",           # created_by written into exported analyses (an email of a person in that app)
  topic = "Funding programme", # Topic level for exported programmes without areas of application
  # its tables (R/suite_cp.R): BigQuery <project>.<bq_dataset>.<bq_prefix><table>, plus its Google Sheet when it uses one
  sheet_id = "",              # GOOGLE_SHEETS_ID there ("" = it keeps its tables in BigQuery only)
  bq_dataset = "business_strategy",   # CP_BQ_DATASET there
  bq_prefix = "cp_"           # CP_BQ_PREFIX there
)

collab_load_settings <- function(path = gd_config_path()) {
  s <- collab_settings_default()
  j <- gd_read_config(path)$collaboration_planning
  if (is.list(j)) for (k in intersect(names(j), names(s))) s[[k]] <- as.character(j[[k]] %|g|% "")
  if (!s$mode %in% c("off", "api", "folder")) s$mode <- "off"
  s
}

collab_save_settings <- function(s, path = gd_config_path()) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  cfg <- gd_read_config(path)
  cfg$collaboration_planning <- s[names(collab_settings_default())]
  writeLines(jsonlite::toJSON(cfg, auto_unbox = TRUE, pretty = TRUE, null = "null"), path, useBytes = TRUE)
  invisible(path)
}

collab_ready <- function(s, sa_path = NA) {
  (s$mode == "folder" && nzchar(s$local_path)) ||
    (s$mode == "api" && nzchar(gd_folder_id(s$folder_id)) && (nzchar(s$key_file) || (!is.na(sa_path) && nzchar(sa_path))))
}

# ------------------------------------------------------------------ small helpers

collab_ts <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")          # same format as that app's now_ts()
collab_safe_name <- function(x, n = 60) {                                   # same rule as that app's safe_name()
  x <- gsub("[\\\\/:*?\"<>|]+", " ", x %|g|% ""); x <- trimws(gsub("\\s+", " ", x))
  substr(if (nzchar(x)) x else "untitled", 1, n)
}
collab_level <- function(x) ifelse(nzchar(trimws(x %|g|% "")), trimws(x), "(not classified)")
collab_norm <- function(x) tolower(gsub("[^a-z0-9]+", "", tolower(x %|g|% "")))
collab_chr <- function(v) { v <- as.character(v %|g|% ""); v[is.na(v)] <- ""; v }
collab_first <- function(...) { for (x in list(...)) if (length(x) && !is.na(x[1]) && nzchar(x[1])) return(as.character(x[1])); "" }
collab_strip_bom <- function(t) sub("^\ufeff", "", t)

collab_read_csv_text <- function(t) {
  t <- collab_strip_bom(t)
  if (!nzchar(trimws(t))) return(data.frame())
  df <- utils::read.csv(text = t, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE, encoding = "UTF-8")
  df[is.na(df)] <- ""
  df
}

# ------------------------------------------------------------------ the folder (api or local)

# A small object with the same four operations for both ways of reaching the folder.
collab_folder <- function(s = collab_load_settings(), sa_path = tryCatch(cred_local()$json_path, error = function(e) NA)) {
  if (s$mode == "folder") {
    root <- s$local_path
    if (!nzchar(root)) stop("Give the CollaborationPlanning folder on this computer (API Settings > Google Drive).", call. = FALSE)
    if (!dir.exists(root)) stop("The folder ", root, " does not exist on this computer.", call. = FALSE)
    return(list(
      mode = "folder", where = normalizePath(root, winslash = "/"),
      analyses = function() {
        f <- list.files(root, pattern = "__.*\\.json$", recursive = TRUE, full.names = TRUE)
        lapply(f, function(x) list(ref = x, text = paste(readLines(x, warn = FALSE, encoding = "UTF-8"), collapse = "\n")))
      },
      latest_backup = function(table = "programmes") {
        d <- file.path(root, "Backups"); if (!dir.exists(d)) return(NULL)
        days <- sort(list.dirs(d, full.names = FALSE, recursive = FALSE), decreasing = TRUE)
        for (day in days) { f <- file.path(d, day, paste0(table, ".csv"))
          if (file.exists(f)) return(list(day = day, text = paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))) }
        NULL
      },
      write_analysis = function(levels, stem, json, html, analysis_id) {
        dir <- do.call(file.path, as.list(c(root, levels))); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
        if (!dir.exists(dir)) stop("Cannot create the folder ", dir, call. = FALSE)
        # the same programme saved before under another classification: remove the old copies (as that app does)
        old <- list.files(root, pattern = paste0("__", analysis_id, "\\.(json|html)$"), recursive = TRUE, full.names = TRUE)
        file.remove(setdiff(old, file.path(dir, paste0(stem, c(".json", ".html")))))
        for (x in list(c(".json", json), c(".html", html))) {
          con <- file(file.path(dir, paste0(stem, x[1])), open = "wb"); writeBin(charToRaw(enc2utf8(x[2])), con); close(con)
        }
        paste(c(levels, stem), collapse = "/")
      },
      write_file = function(levels, name, bytes) {
        dir <- do.call(file.path, as.list(c(root, levels))); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
        con <- file(file.path(dir, name), open = "wb"); writeBin(bytes, con); close(con)
        paste(c(levels, name), collapse = "/")
      }))
  }
  if (s$mode != "api") stop("The CollaborationPlanning folder is not set up (API Settings > Google Drive).", call. = FALSE)
  gs <- gd_settings_default(); gs$auth_mode <- "service_account"; gs$key_file <- s$key_file
  gs$root_folder <- s$folder_id; gs$app_folder <- ""
  g <- GDrive$new(gs, sa_path = sa_path)
  root <- g$resolve_root(s$folder_id)
  if (identical(root, "root")) stop("Give the CollaborationPlanning folder id or link.", call. = FALSE)
  list(
    mode = "api", where = root, client = g,
    analyses = function() {
      f <- g$query("appProperties has { key='cp_type' and value='analysis' } and trashed = false", everywhere = TRUE)
      lapply(f, function(x) { t <- rawToChar(g$download(x$id)); Encoding(t) <- "UTF-8"; list(ref = x$id, text = t) })
    },
    latest_backup = function(table = "programmes") {
      b <- g$find(root, "Backups", folder = TRUE); if (is.null(b)) return(NULL)
      days <- g$children(b$id, folders_only = TRUE)
      days <- days[order(vapply(days, `[[`, "", "name"), decreasing = TRUE)]
      for (d in days) { f <- g$find(d$id, paste0(table, ".csv"))
        if (!is.null(f)) { t <- rawToChar(g$download(f$id)); Encoding(t) <- "UTF-8"; return(list(day = d$name, text = t)) } }
      NULL
    },
    write_analysis = function(levels, stem, json, html, analysis_id) {
      parent <- g$ensure_path(root, levels)
      esc <- function(x) gsub("'", "\\\\'", gsub("\\\\", "\\\\\\\\", x))
      old <- g$query(sprintf("appProperties has { key='cp_id' and value='%s' } and trashed = false", esc(analysis_id)),
                     fields = "files(id,name,parents,appProperties)", everywhere = TRUE)
      pick <- function(kind) Filter(function(f) identical(f$appProperties$cp_type, kind), old)
      for (x in list(list(".json", json, "analysis"), list(".html", html, "analysis_html"))) {
        prev <- pick(x[[3]])
        same_place <- length(prev) && parent %in% unlist(prev[[1]]$parents)
        if (length(prev) && !same_place) for (p in prev) g$delete(p$id)          # moved to another classification
        g$put_file(parent, paste0(stem, x[[1]]), charToRaw(enc2utf8(x[[2]])), if (x[[1]] == ".json") "application/json" else "text/html",
                   file_id = if (same_place) prev[[1]]$id else "", properties = list(cp_type = x[[3]], cp_id = analysis_id))
      }
      paste(c(levels, stem), collapse = "/")
    },
    write_file = function(levels, name, bytes) {
      parent <- g$ensure_path(root, levels)
      prev <- g$find(parent, name)
      g$put_file(parent, name, bytes, gd_mime(tools::file_ext(name)), file_id = if (is.null(prev)) "" else prev$id,
                 properties = list(cp_type = "bos_file"))       # not an analysis: that app's Drive reader leaves it alone
      paste(c(levels, name), collapse = "/")
    })
}

# ------------------------------------------------------------------ IMPORT: that app's records -> funding_programmes rows

# Its programmes table (Backups/<date>/programmes.csv) -> our columns
collab_programmes_to_bos <- function(df) {
  if (!nrow(df)) return(data.frame())
  g <- function(...) { for (k in c(...)) if (k %in% names(df)) return(collab_chr(df[[k]])); rep("", nrow(df)) }
  closes <- g("closes_date"); dl_text <- g("deadline_text")
  deadline <- ifelse(nzchar(closes), closes, ifelse(nzchar(dl_text), dl_text, ifelse(toupper(g("rolling")) == "TRUE", "Rolling", "")))
  amount <- g("amount_text")
  minv <- g("min_gbp"); maxv <- g("max_gbp")
  built <- ifelse(nzchar(maxv), paste0("GBP ", ifelse(nzchar(minv), paste0(minv, " to "), "up to "), maxv), "")
  amount[!nzchar(amount)] <- built[!nzchar(amount)]
  rate <- g("funding_rate_pct"); amount <- ifelse(nzchar(rate) & nzchar(amount), paste0(amount, " (", rate, "% funded)"), amount)
  sponsors <- g("key_sponsors"); funder <- g("funder")
  has <- function(needle, hay) mapply(function(n, h) nzchar(n) && grepl(n, h, fixed = TRUE), needle, hay, USE.NAMES = FALSE)
  sponsors <- ifelse(nzchar(funder) & !has(funder, sponsors), ifelse(nzchar(sponsors), paste0(funder, ", ", sponsors), funder), sponsors)
  cond <- g("conditions"); summ <- g("summary")
  cond <- ifelse(nzchar(summ), ifelse(nzchar(cond), paste0(summ, "\n\nConditions: ", cond), summ), cond)
  urls <- g("verified_urls"); src <- g("source_url")
  urls <- ifelse(nzchar(src) & !has(src, urls), ifelse(nzchar(urls), paste0(urls, ", ", src), src), urls)
  out <- data.frame(
    programme_name = g("programme_name"), category = g("category"), country = g("country"),
    city_region = ifelse(nzchar(g("city_region")), g("city_region"), "All"),
    amount_of_money = amount, conditions = cond, key_sponsors = sponsors,
    key_organiser_profiles = g("key_organiser_profiles"), areas_of_application = g("themes"),
    start_date_for_applying = g("opens_date"), deadline = deadline,
    recommendations_for_applying = g("recommendations"), verified_urls = urls,
    time_zone = "Europe/London",                       # that app works in UK time; its dates carry no zone
    source = COLLAB_SOURCE_BACKUP, source_ref = g("programme_id"), stringsAsFactors = FALSE)
  keep <- nzchar(trimws(out$programme_name)) & toupper(g("is_example")) != "TRUE"
  collab_conform(out[keep, , drop = FALSE])
}

# Which column of a Claude table holds what (headers are free text)
COLLAB_HEADER_RULES <- list(
  programme_name = "^(programme|program|scheme|competition|fund|funding programme|opportunity|call|grant|name|title)( name| title)?$|programme|scheme name|competition name|call name",
  key_sponsors = "funder|funding body|sponsor|provider|agency|organi[sz]ation|organiser|run by|body",
  amount_of_money = "amount|award|grant size|value|budget|how much|size|£|gbp|funding available|money",
  deadline = "deadline|clos|due|submission date|end date",
  start_date_for_applying = "open|launch|start",
  country = "^country$|nation",
  city_region = "region|city|location|area covered",
  category = "^type$|category|kind",
  verified_urls = "url|link|website|source|web",
  conditions = "eligib|condition|who can apply|requirement|criteria|restriction",
  areas_of_application = "theme|focus|sector|topic|priority|area|scope",
  recommendations_for_applying = "recommend|tip|advice|next step|why|fit|relevance|notes|action")

collab_map_headers <- function(cols) {
  h <- tolower(trimws(cols)); used <- character(0); map <- list()
  for (field in names(COLLAB_HEADER_RULES)) {
    i <- which(grepl(COLLAB_HEADER_RULES[[field]], h, perl = TRUE) & !seq_along(h) %in% used)
    if (length(i)) { map[[field]] <- i[1]; used <- c(used, i[1]) }
  }
  map
}

# One analysis record (parsed JSON) -> programme rows (one per row of each programme table; else one from its classification)
collab_analysis_to_bos <- function(a) {
  cl <- function(k) collab_chr(a[[k]])[1]
  tabs <- tryCatch(jsonlite::fromJSON(cl("tables_json"), simplifyVector = FALSE), error = function(e) list())
  rows <- list()
  for (t in tabs) {
    cols <- as.character(unlist(t$columns)); if (!length(cols)) next
    m <- collab_map_headers(cols)
    if (is.null(m$programme_name) || length(intersect(names(m), c("key_sponsors", "amount_of_money", "deadline", "verified_urls"))) == 0) next
    for (r in t$rows %|g|% list()) {
      v <- as.character(unlist(lapply(r, function(x) x %|g|% ""))); length(v) <- length(cols); v[is.na(v)] <- ""
      cell <- function(f) if (is.null(m[[f]])) "" else trimws(v[m[[f]]])
      if (!nzchar(cell("programme_name"))) next
      extra <- setdiff(seq_along(cols), unlist(m))
      more <- paste(vapply(extra[nzchar(v[extra])], function(i) paste0(cols[i], ": ", v[i]), ""), collapse = "\n")
      rows[[length(rows) + 1]] <- list(
        programme_name = cell("programme_name"), key_sponsors = cell("key_sponsors"), amount_of_money = cell("amount_of_money"),
        deadline = cell("deadline"), start_date_for_applying = cell("start_date_for_applying"),
        country = if (nzchar(cell("country"))) cell("country") else cl("country"),
        city_region = if (nzchar(cell("city_region"))) cell("city_region") else "All",
        category = if (nzchar(cell("category"))) cell("category") else cl("category"),
        verified_urls = cell("verified_urls"), conditions = cell("conditions"),
        areas_of_application = if (nzchar(cell("areas_of_application"))) cell("areas_of_application") else cl("topic"),
        recommendations_for_applying = paste(c(cell("recommendations_for_applying")[nzchar(cell("recommendations_for_applying"))],
                                               if (nzchar(more)) more, if (nzchar(t$title %|g|% "")) paste0("From the table \"", t$title, "\" of the analysis \"", cl("title"), "\"")),
                                             collapse = "\n"))
    }
  }
  if (!length(rows) && nzchar(cl("programme")))     # no programme table: the analysis itself is about one programme
    rows[[1]] <- list(programme_name = cl("programme"), key_sponsors = "", amount_of_money = "", deadline = "", start_date_for_applying = "",
                      country = cl("country"), city_region = "All", category = cl("category"), verified_urls = "",
                      conditions = cl("summary"), areas_of_application = cl("topic"),
                      recommendations_for_applying = paste0("From the analysis \"", cl("title"), "\""))
  if (!length(rows)) return(data.frame())
  out <- do.call(rbind, lapply(rows, as.data.frame, stringsAsFactors = FALSE))
  out$time_zone <- "Europe/London"; out$source <- COLLAB_SOURCE_ANALYSIS
  out$source_ref <- if (nrow(out) == 1) cl("analysis_id") else paste0(cl("analysis_id"), "#", seq_len(nrow(out)))
  out
}

# Every analysis on the folder -> programme rows (latest copy of each analysis; deleted ones and this app's own exports skipped)
collab_read_analyses <- function(files) {
  recs <- lapply(files, function(f) tryCatch({ j <- jsonlite::fromJSON(collab_strip_bom(f$text), simplifyVector = FALSE)
    if (!identical(j$cp_type, "analysis")) NULL else j }, error = function(e) NULL))
  recs <- Filter(Negate(is.null), recs)
  if (!length(recs)) return(list(rows = data.frame(), analyses = 0L, skipped_own = 0L))
  ids <- vapply(recs, function(j) collab_chr(j$analysis_id)[1], ""); upd <- vapply(recs, function(j) collab_chr(j$updated_at)[1], "")
  ord <- order(ids, upd, decreasing = TRUE); recs <- recs[ord][!duplicated(ids[ord])]
  own <- vapply(recs, function(j) startsWith(collab_chr(j$analysis_id)[1], COLLAB_EXPORT_PREFIX) || identical(j$bos_origin, TRUE), TRUE)
  del <- vapply(recs, function(j) toupper(collab_chr(j$deleted)[1]) == "TRUE", TRUE)
  use <- recs[!own & !del]
  rows <- lapply(use, collab_analysis_to_bos); rows <- Filter(function(d) nrow(d) > 0, rows)
  list(rows = collab_conform(if (length(rows)) do.call(rbind, lapply(rows, collab_conform)) else NULL), analyses = length(use), skipped_own = sum(own))
}

# Every incoming row gets the same columns (backup rows and analysis rows have different ones)
COLLAB_ROW_COLS <- c("programme_name", "category", "country", "city_region", "amount_of_money", "conditions", "key_sponsors",
                     "key_organiser_profiles", "areas_of_application", "start_date_for_applying", "deadline",
                     "recommendations_for_applying", "verified_urls", "time_zone", "source", "source_ref")
collab_conform <- function(d) {
  if (!is.data.frame(d) || !nrow(d)) return(as.data.frame(setNames(replicate(length(COLLAB_ROW_COLS), character(0), simplify = FALSE), COLLAB_ROW_COLS), stringsAsFactors = FALSE))
  for (k in setdiff(COLLAB_ROW_COLS, names(d))) d[[k]] <- ""
  d[, COLLAB_ROW_COLS, drop = FALSE]
}

# Marks each incoming row: "New", "Repeated" (the same programme is already in the table or earlier in this batch:
# same name and same funder/sponsor, or one of them has no funder) or "Already imported" (the same record of that app
# was loaded before - its source_ref is in the table).
collab_mark_repeats <- function(incoming, existing) {
  if (!nrow(incoming)) return(incoming)
  ex_name <- collab_norm_vec(existing$programme_name); ex_sp <- collab_norm_vec(existing$key_sponsors)
  ex_ref <- collab_chr(existing$source_ref %|g|% character(0))
  st <- character(nrow(incoming)); match_id <- character(nrow(incoming))
  seen_n <- character(0); seen_s <- character(0)
  for (i in seq_len(nrow(incoming))) {
    n <- collab_norm(incoming$programme_name[i]); sp <- collab_norm(incoming$key_sponsors[i])
    hit <- which(ex_name == n & (ex_sp == sp | !nzchar(ex_sp) | !nzchar(sp)))
    in_batch <- any(seen_n == n & (seen_s == sp | !nzchar(seen_s) | !nzchar(sp)))
    st[i] <- if (nzchar(incoming$source_ref[i]) && incoming$source_ref[i] %in% ex_ref) "Already imported"
             else if (length(hit) || in_batch) "Repeated" else "New"
    if (length(hit) && !is.null(existing$id)) match_id[i] <- as.character(existing$id[hit[1]])
    seen_n <- c(seen_n, n); seen_s <- c(seen_s, sp)
  }
  incoming$status <- st; incoming$same_as_id <- match_id
  incoming
}
collab_norm_vec <- function(x) vapply(collab_chr(x), collab_norm, "", USE.NAMES = FALSE)

# ------------------------------------------------------------------ EXPORT: funding_programmes rows -> that app's analyses

collab_programme_table <- function(r) {
  f <- c("Programme" = "programme_name", "Category" = "category", "Country" = "country", "City / region" = "city_region",
         "Amount" = "amount_of_money", "Applications open" = "start_date_for_applying", "Deadline" = "deadline",
         "Time zone" = "time_zone", "Funder / sponsors" = "key_sponsors", "Organiser profiles" = "key_organiser_profiles",
         "Areas of application" = "areas_of_application", "Conditions" = "conditions",
         "Recommendations for applying" = "recommendations_for_applying", "Verified URLs" = "verified_urls")
  val <- function(k) if (k %in% names(r)) collab_chr(r[[k]])[1] else ""
  keep <- vapply(f, function(k) nzchar(val(k)), TRUE)
  list(list(title = "Programme details", columns = c("Field", "Value"),
            rows = unname(lapply(names(f)[keep], function(n) c(n, val(f[[n]]))))))
}

# One funding_programmes row -> list(levels, stem, json, html, analysis_id) in that app's format
collab_export_record <- function(r, s = collab_load_settings(), user = "") {
  val <- function(k) if (k %in% names(r)) collab_chr(r[[k]])[1] else ""
  id <- if (nzchar(val("id"))) paste0(COLLAB_EXPORT_PREFIX, collab_norm(val("id"))) else paste0(COLLAB_EXPORT_PREFIX, "n", substr(collab_norm(val("programme_name")), 1, 40))
  topic <- trimws(strsplit(val("areas_of_application"), "[,;\n]")[[1]][1] %|g|% "")
  if (is.na(topic) || !nzchar(topic)) topic <- collab_first(s$topic, "Funding programme")
  summary <- paste(c(
    if (nzchar(val("amount_of_money"))) paste0("Amount: ", val("amount_of_money")),
    if (nzchar(val("deadline"))) paste0("Deadline: ", val("deadline"), if (nzchar(val("time_zone"))) paste0(" (", val("time_zone"), ")")),
    if (nzchar(val("conditions"))) val("conditions")), collapse = ". ")
  tabs <- collab_programme_table(r)
  now <- collab_ts()
  rec <- list(
    analysis_id = id, suggestion_id = "", title = val("programme_name"),
    instructions = "Shared from the Business Operations Suite (Funding Programmes).", model = "", result_raw = "",
    tables_json = as.character(jsonlite::toJSON(tabs, auto_unbox = TRUE)), summary = summary,
    country = val("country"), category = val("category"), topic = topic, programme = val("programme_name"),
    access_emails = s$share_with %|g|% "", status = "saved",
    created_by = tolower(collab_first(s$exported_by, user)), created_at = if (nzchar(val("created_at"))) substr(val("created_at"), 1, 19) else now,
    updated_at = now, drive_id = "", drive_path = "", drive_synced_at = "", deleted = "FALSE",
    cp_type = "analysis", app_version = "BusinessOperationsSuite", saved_at = now, bos_origin = TRUE)
  levels <- vapply(c(rec$country, rec$category, rec$topic), function(x) collab_safe_name(collab_level(x), 50), "", USE.NAMES = FALSE)
  stem <- paste0(collab_safe_name(rec$programme %|g|% rec$title, 60), "__", id)
  rec$drive_path <- paste(c(levels, stem), collapse = "/")
  list(levels = levels, stem = stem, analysis_id = id,
       json = as.character(jsonlite::toJSON(rec, auto_unbox = TRUE, pretty = TRUE)),
       html = collab_export_html(rec, tabs))
}

collab_export_html <- function(rec, tabs) {
  esc <- htmltools::htmlEscape
  tbl <- paste0(vapply(tabs, function(t) paste0('<div class="ft-title">', esc(t$title), '</div><table><tr>',
    paste0("<th>", esc(t$columns), "</th>", collapse = ""), "</tr>",
    paste0(vapply(t$rows, function(r) paste0("<tr>", paste0("<td>", gsub("\n", "<br>", esc(r)), "</td>", collapse = ""), "</tr>"), ""), collapse = ""),
    "</table>"), ""), collapse = "")
  paste0('<!DOCTYPE html><html lang="en-GB"><head><meta charset="utf-8"><title>', esc(rec$title), '</title>',
         '<style>body{font-family:Arial,sans-serif;max-width:1100px;margin:24px auto;color:#1d2b36}',
         'table{border-collapse:collapse;width:100%;font-size:13px;margin:6px 0 16px}th{background:#0f4a5c;color:#fff;text-align:left}',
         'th,td{border:1px solid #cfdde3;padding:6px 8px;vertical-align:top}tr:nth-child(even) td{background:#f2f8fa}',
         '.ft-title{font-weight:bold;color:#0f4a5c;margin-top:14px}</style></head><body>',
         '<h1>', esc(rec$title), '</h1><p><b>Classification: </b>', esc(paste(collab_level(c(rec$country, rec$category, rec$topic, rec$programme)), collapse = " > ")),
         '</p><p>', esc(rec$summary), '</p>', tbl,
         '<p style="color:#6b7c88;font-size:12px">Shared from the Business Operations Suite on ', esc(rec$saved_at), ' - analysis ', esc(rec$analysis_id), '</p></body></html>')
}

# The marked preview -> the rows to load: every New and Repeated row (repeated = TRUE / FALSE);
# "Already imported" rows only when asked (they are then loaded as repeated too).
collab_rows_for_bq <- function(marked, include_already = FALSE) {
  if (!nrow(marked)) return(marked)
  keep <- marked$status != "Already imported" | isTRUE(include_already)
  d <- marked[keep, , drop = FALSE]
  d$repeated <- ifelse(d$status == "New", "FALSE", "TRUE")
  d[, setdiff(names(d), c("status", "same_as_id")), drop = FALSE]
}

# ------------------------------------------------------------------ CONTACTS: its people + messages -> Communications

COLLAB_CONTACT_PREFIX <- "cp_"     # contact_id / message_id of records imported from that app (cp_<its id>)

# its people (latest, not deleted) -> rows of business_contacts (+ source, source_ref)
collab_people_to_contacts <- function(p) {
  if (is.null(p) || !nrow(p)) return(data.frame())
  g <- function(k) if (k %in% names(p)) collab_chr(p[[k]]) else rep("", nrow(p))
  day <- function(x) { d <- substr(x, 1, 10); ifelse(grepl("^\\d{4}-\\d{2}-\\d{2}$", d), d, NA_character_) }
  when <- ifelse(nzchar(g("updated_at")), g("updated_at"), g("added_at"))
  notes <- trimws(paste0(g("notes"), ifelse(nzchar(g("notes")), "\n", ""), "From CollaborationPlanning",
                         ifelse(nzchar(g("type")), paste0(" (", g("type"), ")"), ""), ifelse(nzchar(g("added_by")), paste0(", added by ", g("added_by")), "")))
  data.frame(
    contact_id = paste0(COLLAB_CONTACT_PREFIX, g("person_id")), full_name = g("name"), industry = g("type"),
    company = g("organisation"), job_title = g("role_title"), location = "", country = g("country"),
    email = tolower(trimws(g("email"))), phone = g("phone"), linkedin = g("linkedin"), areas_of_interest = g("interests"),
    university = "", academic_background = g("past_projects"), user_notes = notes,
    last_interaction_date = day(when), created_at = ifelse(nzchar(g("added_at")), g("added_at"), collab_ts()), updated_at = collab_ts(),
    source = "CollaborationPlanning people", source_ref = g("person_id"), stringsAsFactors = FALSE)[nzchar(trimws(g("name"))) | nzchar(trimws(g("email"))), , drop = FALSE]
}

# New / Repeated (same email, or same name + organisation, already ours or earlier in the list) / Already imported
collab_mark_contact_repeats <- function(incoming, existing) {
  if (!nrow(incoming)) return(incoming)
  ex_id <- collab_chr(existing$contact_id %|g|% character(0)); ex_ref <- collab_chr(existing$source_ref %|g|% character(0))
  ex_mail <- tolower(trimws(collab_chr(existing$email %|g|% character(0))))
  ex_nc <- paste(collab_norm_vec(existing$full_name %|g|% character(0)), collab_norm_vec(existing$company %|g|% character(0)))
  st <- character(nrow(incoming)); same <- character(nrow(incoming)); seen_m <- character(0); seen_nc <- character(0)
  for (i in seq_len(nrow(incoming))) {
    m <- incoming$email[i]; nc <- paste(collab_norm(incoming$full_name[i]), collab_norm(incoming$company[i]))
    hit <- which((nzchar(m) & ex_mail == m) | (nzchar(collab_norm(incoming$full_name[i])) & ex_nc == nc))
    hit <- setdiff(hit, which(ex_id == incoming$contact_id[i]))
    st[i] <- if (incoming$contact_id[i] %in% ex_id || (nzchar(incoming$source_ref[i]) && incoming$source_ref[i] %in% ex_ref)) "Already imported"
             else if (length(hit) || (nzchar(m) && m %in% seen_m) || nc %in% seen_nc) "Repeated" else "New"
    if (length(hit)) same[i] <- ex_id[hit[1]]
    seen_m <- c(seen_m, m); seen_nc <- c(seen_nc, nc)
  }
  incoming$status <- st; incoming$same_as_id <- same
  incoming
}

# its messages -> rows of contact_communications, linked to our contact (ours when the email matches, else the imported one)
collab_messages_to_comms <- function(msgs, contacts, existing_ids = character(0)) {
  if (is.null(msgs) || !nrow(msgs) || !nrow(contacts)) return(data.frame())
  g <- function(k) if (k %in% names(msgs)) collab_chr(msgs[[k]]) else rep("", nrow(msgs))
  mail <- tolower(trimws(g("email")))
  cm <- tolower(trimws(collab_chr(contacts$email)))
  pref <- ifelse(startsWith(collab_chr(contacts$contact_id), COLLAB_CONTACT_PREFIX), 1, 0)       # our own contact wins
  ord <- order(pref); cm <- cm[ord]; cid <- collab_chr(contacts$contact_id)[ord]
  to <- cid[match(mail, cm)]
  purpose <- trimws(paste(g("purpose"), ifelse(nzchar(g("direction")) | nzchar(g("status")),
                          paste0("(", trimws(paste(g("direction"), g("status"))), ")"), "")))
  out <- data.frame(
    message_id = paste0(COLLAB_CONTACT_PREFIX, g("message_id")), contact_id = to, channel_type = g("channel"),
    communication_purpose = purpose, language = "", message_length = "",
    message_content = ifelse(nzchar(g("subject")), paste0("Subject: ", g("subject"), "\n\n", g("content")), g("content")),
    created_at = ifelse(nzchar(g("created_at")), g("created_at"), collab_ts()),
    source = "CollaborationPlanning messages", source_ref = g("message_id"), stringsAsFactors = FALSE)
  out[!is.na(out$contact_id) & nzchar(g("message_id")) & !out$message_id %in% existing_ids, , drop = FALSE]
}

# ------------------------------------------------------------------ FUNDING OUTPUTS into its Country/Category/Topic folders

# the folder levels that app uses for a country / category (blank or "all" = every country / category)
collab_output_levels <- function(country, category, s = collab_load_settings()) {
  lv <- function(x, all) { x <- collab_chr(x)[1]; if (!nzchar(x) || identical(tolower(x), "all")) all else x }
  vapply(c(lv(country, "All countries"), lv(category, "All categories"), collab_level(collab_first(s$topic, "Funding programme"))),
         function(x) collab_safe_name(x, 50), "", USE.NAMES = FALSE)
}
# file name: no "__" and never .json, so that app never mistakes it for one of its analyses
collab_output_name <- function(base, ext, at = Sys.time()) {
  b <- gsub("_+", "_", gsub("[^A-Za-z0-9._-]+", "_", base))
  paste0(sub("_$", "", b), "_", format(at, "%Y%m%d_%H%M%S"), ".", ext)
}
# writes files (list of list(ext, bytes)) into the CollaborationPlanning folder; NULL when that folder is not set up
collab_write_outputs <- function(levels, base, files, s = collab_load_settings(), sa_path = tryCatch(cred_local()$json_path, error = function(e) NA)) {
  if (!collab_ready(s, sa_path)) return(NULL)
  f <- collab_folder(s, sa_path); at <- Sys.time()
  vapply(files, function(x) f$write_file(levels, collab_output_name(base, x$ext, at), x$bytes), "")
}
