# =============================================================================
# R/utils_local_creds.R - load the Claude and BigQuery credentials automatically
# (adapted from the API-keys reference app; names are cred_* / keys_* so they
# cannot collide with the rest of the suite).
#
# Folder searched (the first source that works wins; each API is skipped if it
# is already connected):
#   1. C:/111_SecA/_q_api on Windows, or the folder named in LAT_CRED_DIR on any OS
#        BigQuery : any *.json with "type": "service_account" and a private_key
#                   (several: the one whose project_id is the app's project wins, else the newest)
#        Claude   : ap_claude_1_line.txt - first non-empty line = the Anthropic API key
#   2. environment: ATERA_BQ_KEY_FILE / GOOGLE_APPLICATION_CREDENTIALS (BigQuery),
#                   ANTHROPIC_API_KEY (+ CLAUDE_MODEL) (Claude)
#   3. by hand in API Configuration (always available, also to switch keys)
#
# Keys are only read. They are never copied, written to BigQuery or files, or
# printed: logs show the file path, the UI shows a masked key at most.
# =============================================================================

cred_dir_default <- "C:/111_SecA/_q_api"

cred_dir <- function() {
  d <- Sys.getenv("LAT_CRED_DIR", "")
  if (nzchar(d)) d else if (.Platform$OS.type == "windows") cred_dir_default else ""
}

cred_mask <- function(k) if (is.null(k) || is.na(k) || nchar(k) < 12) "" else paste0(substr(k, 1, 7), "...", substr(k, nchar(k) - 3, nchar(k)))

cred_local <- function(dir = cred_dir(), project = "") {
  out <- list(dir = dir, json_path = NA_character_, json_project = NA_character_, claude_key = NA_character_, notes = character(0))
  if (!nzchar(dir)) { out$notes <- "Not Windows: no local key folder is searched (set LAT_CRED_DIR to use one)."; return(out) }
  if (!dir.exists(dir)) { out$notes <- sprintf("Folder %s not found.", dir); return(out) }

  js <- list.files(dir, pattern = "\\.json$", full.names = TRUE, ignore.case = TRUE)
  info <- lapply(js, function(f) {
    j <- tryCatch(jsonlite::fromJSON(f, simplifyVector = TRUE), error = function(e) NULL)
    if (is.list(j) && identical(j$type, "service_account") && !is.null(j$private_key))
      data.frame(path = f, project = j$project_id %||% "", mtime = as.numeric(file.mtime(f)), stringsAsFactors = FALSE) else NULL
  })
  info <- do.call(rbind, Filter(Negate(is.null), info))
  if (!is.null(info) && nrow(info)) {
    info <- info[order(info$project != project, -info$mtime), , drop = FALSE]
    out$json_path <- info$path[1]; out$json_project <- info$project[1]
    if (nrow(info) > 1) out$notes <- c(out$notes, sprintf("%d service-account keys found; using %s.", nrow(info), basename(info$path[1])))
  } else out$notes <- c(out$notes, sprintf("No service-account .json key in %s.", dir))

  kf <- file.path(dir, "ap_claude_1_line.txt")
  if (file.exists(kf)) {
    k <- trimws(readLines(kf, warn = FALSE)); k <- k[nzchar(k)]
    if (length(k)) out$claude_key <- k[1] else out$notes <- c(out$notes, "ap_claude_1_line.txt is empty.")
  } else out$notes <- c(out$notes, sprintf("No ap_claude_1_line.txt in %s.", dir))
  out
}

cred_status <- function() tryCatch(get(".cred_status", envir = .GlobalEnv), error = function(e) list())
cred_set_status <- function(...) {   # e.g. cred_set_status(bq = "Connected by hand.", bq_failed = FALSE)
  st <- cred_status(); a <- list(...); for (n in names(a)) st[n] <- list(a[[n]])
  assign(".cred_status", st, envir = .GlobalEnv); invisible(st)
}

# Called once at the top of create_server(), BEFORE any module reads BigQuery or calls Claude.
# Runs the same live check as the Test Connection button right after a key is
# auto-loaded, so the sidebar turns green without the user pressing anything.
cred_test_claude <- function(api, st, where, mask) {
  r <- tryCatch({ api$test_claude_connection(); NULL }, error = function(e) conditionMessage(e))
  if (is.null(r)) {
    cat("[Keys] Claude API key tested OK (live call to api.anthropic.com)\n")
    st$claude <- sprintf("Key loaded automatically from %s (%s) and tested: connection OK.", where, mask)
    st$claude_failed <- FALSE
  } else {
    cat("[Keys] Claude API key from", where, "failed the live test:", r, "\n")
    st$claude <- sprintf("Key loaded from %s (%s) but the live test failed: %s. Check the key or network and press Test Connection.", where, mask, r)
    st$claude_failed <- TRUE
  }
  st
}


cred_startup <- function(api) {
  st <- cred_status(); st$dir <- cred_dir()
  lc <- tryCatch(cred_local(project = api$bq_project_id), error = function(e) list(notes = conditionMessage(e)))
  if (length(lc$notes)) cat("[Keys]", paste(lc$notes, collapse = " "), "\n")

  if (!is.na(lc$json_path %||% NA) && !isTRUE(api$bq_authenticated)) {
    cat("[Keys] BigQuery key found:", lc$json_path, "- connecting...\n")
    ok <- tryCatch({
      api$set_bigquery_credentials(api$bq_project_id, api$bq_dataset_id)
      api$authenticate_bigquery(json_path = lc$json_path); TRUE
    }, error = function(e) { cat("[Keys] BigQuery key from", lc$json_path, "failed:", conditionMessage(e), "\n"); FALSE })
    st$bq <- if (ok) sprintf("Connected automatically with %s (found in %s).", basename(lc$json_path), lc$dir)
             else sprintf("A key was found (%s) but the connection failed: see the R console. Load another key below.", basename(lc$json_path))
    st$bq_failed <- !ok
  }
  if (!is.na(lc$claude_key %||% NA) && !isTRUE(api$claude_authenticated)) {
    m <- Sys.getenv("CLAUDE_MODEL", ""); api$set_claude_credentials(lc$claude_key, model = if (nzchar(m)) m else NULL)
    api$claude_authenticated <- TRUE; api$claude_tested <- NA
    cat("[Keys] Claude API key taken from", file.path(lc$dir, "ap_claude_1_line.txt"), "(key not printed)\n")
    st <- cred_test_claude(api, st, file.path(lc$dir, "ap_claude_1_line.txt"), cred_mask(lc$claude_key))
  }

  key <- Sys.getenv("ATERA_BQ_KEY_FILE", Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS", ""))
  if (nzchar(key) && file.exists(key) && !isTRUE(api$bq_authenticated)) {
    ok <- tryCatch({ api$set_bigquery_credentials(api$bq_project_id, api$bq_dataset_id); api$authenticate_bigquery(json_path = key); TRUE },
                   error = function(e) { cat("[Keys] BigQuery environment key failed:", conditionMessage(e), "\n"); FALSE })
    if (ok) { st$bq <- sprintf("Connected automatically with the key named in the environment (%s).", basename(key)); st$bq_failed <- FALSE }
  }
  k <- Sys.getenv("ANTHROPIC_API_KEY", "")
  if (nzchar(k) && !isTRUE(api$claude_authenticated)) {
    m <- Sys.getenv("CLAUDE_MODEL", ""); api$set_claude_credentials(k, model = if (nzchar(m)) m else NULL)
    api$claude_authenticated <- TRUE; api$claude_tested <- NA
    st <- cred_test_claude(api, st, "ANTHROPIC_API_KEY", cred_mask(k))
  }
  assign(".cred_status", st, envir = .GlobalEnv)
  st
}

# banner shown at the top of the two configuration tabs
cred_banner <- function(ok, ...) tags$div(
  style = sprintf("background:%s; border:1px solid %s; color:%s; border-radius:8px; padding:8px 10px; margin-bottom:10px; font-size:12.5px;",
                  if (ok) "#ecfdf5" else "#fffbeb", if (ok) "#a7f3d0" else "#fde68a", if (ok) "#065f46" else "#92400e"),
  icon(if (ok) "key" else "circle-info"), " ", ...)
cred_not_found_text <- function(what) {
  d <- cred_status()$dir %||% cred_dir()
  if (nzchar(d)) sprintf("No %s found in %s: load it below.", what, d)
  else sprintf("This is not Windows, so no local key folder is searched: load the %s below.", what)
}

# ---- sidebar box: green = ready, amber = key loaded but not proved, red = missing or failed ----
keys_status_box <- function(id) {
  ns <- NS(id)
  tagList(
    tags$style(HTML(sprintf("#%s:empty::before { content: 'BigQuery: connecting...   Claude: connecting...'; color:#fbbf24; font-size:11.5px; }", ns("lights")))),
    tags$div(style = "padding:10px; margin:6px 10px; background:rgba(0,0,0,.18); border-radius:8px;",
             tags$div(style = "color:#b2e0db; font-size:11px; font-weight:700; margin-bottom:4px;", "API CONNECTIONS"), uiOutput(ns("lights"))))
}
keys_status_wire <- function(id, api) moduleServer(id, function(input, output, session) {
  output$lights <- renderUI({
    st <- cred_status()
    connecting <- length(st) == 0     # start-up connect has not finished yet
    invalidateLater(if (connecting || !isTRUE(api$bq_authenticated) || is.na(api$claude_tested %||% NA)) 700 else 3000)   # the api fields are plain R6 fields, not reactive: re-check every 3 s
    if (connecting) return(tagList(
      tags$div(style = "font-size:11.5px; color:#fbbf24;", icon("spinner", class = "fa-spin"), " BigQuery: connecting..."),
      tags$div(style = "font-size:11.5px; color:#fbbf24;", icon("spinner", class = "fa-spin"), " Claude: connecting...")))
    light <- function(name, col, txt) tags$div(style = "display:flex; gap:6px; margin:3px 0; font-size:11.5px; color:#ecf0f1;",
      tags$span(style = sprintf("display:inline-block; width:10px; height:10px; border-radius:50%%; background:%s; margin-top:3px; flex:none;", col)), tags$span(tags$b(name, ": "), txt))
    bq <- isTRUE(api$bq_authenticated); cl <- isTRUE(api$claude_authenticated); t <- api$claude_tested
    tagList(
      light("BigQuery", if (bq) "#22c55e" else "#ef4444", if (bq) "ready" else if (isTRUE(st$bq_failed)) "key found, connection failed" else "not connected: API Configuration"),
      light("Claude", if (cl && isTRUE(t)) "#22c55e" else if (cl && (is.null(t) || is.na(t))) "#fbbf24" else "#ef4444",
            if (!cl) "no key: API Configuration" else if (isTRUE(t)) "ready (tested)" else if (is.null(t) || is.na(t)) "key loaded, not tested yet" else "test failed"))
  })
})
