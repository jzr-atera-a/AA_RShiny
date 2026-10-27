# R/utils_local_creds.R
# ============================================================
# Auto-load the BigQuery service-account key and the Claude API key from a local folder.
#   * Windows: C:/111_SecA/_q_api (or the folder in the LAT_CRED_DIR environment variable)
#   * Any other system, or folder missing: nothing is searched; the user types the folder
#     in the API Configuration tabs (or loads the keys by hand as before).
# Keys never leave the folder: only the file path and a masked key are shown or printed.
#   BigQuery: any *.json with "type": "service_account" and a private_key (project match first, else newest)
#   Claude:   ap_claude_1_line.txt (first non-empty line)
# ============================================================

APP_CRED_DIR_WINDOWS <- "C:/111_SecA/_q_api"
.app_cred_env <- new.env()   # status texts, read by the sidebar box and the API tabs
.app_cred_env$status <- list(bq = NULL, claude = NULL, dir = "", notes = character(0), bq_failed = FALSE, claude_failed = FALSE)

app_cred_dir <- function() {
  d <- Sys.getenv("LAT_CRED_DIR", "")
  if (nzchar(d)) d else if (.Platform$OS.type == "windows") APP_CRED_DIR_WINDOWS else ""
}

app_mask_key <- function(k) if (is.null(k) || is.na(k) || nchar(k) < 12) "" else paste0(substr(k, 1, 7), "...", substr(k, nchar(k) - 3, nchar(k)))

app_local_credentials <- function(dir = app_cred_dir(), project = "atera-2") {
  out <- list(dir = dir, json_path = NA_character_, json_project = NA_character_, claude_key = NA_character_, notes = character(0))
  if (!nzchar(dir)) { out$notes <- "Not Windows: no local key folder is searched (enter a folder in the API Configuration tab, or set LAT_CRED_DIR)."; return(out) }
  if (!dir.exists(dir)) { out$notes <- sprintf("Folder %s not found.", dir); return(out) }
  js <- list.files(dir, pattern = "\\.json$", full.names = TRUE, ignore.case = TRUE)
  info <- lapply(js, function(f) {
    j <- tryCatch(jsonlite::fromJSON(f, simplifyVector = TRUE), error = function(e) NULL)
    if (is.list(j) && identical(j$type, "service_account") && !is.null(j$private_key))
      data.frame(path = f, project = if (is.null(j$project_id)) "" else as.character(j$project_id)[1], mtime = as.numeric(file.mtime(f)), stringsAsFactors = FALSE) else NULL
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

app_cred_status <- function() .app_cred_env$status

# Load whatever is found in `dir` into api_manager (skipping an API that is already connected).
# which = "both", "bq" or "claude". Returns the status list (also stored for the UI).
app_cred_autoload <- function(api_manager, dir = app_cred_dir(), which = "both", force = FALSE) {
  st <- .app_cred_env$status; st$dir <- dir
  lc <- tryCatch(app_local_credentials(dir, project = api_manager$bq_project_id %||% "atera-2"), error = function(e) list(notes = conditionMessage(e), json_path = NA, claude_key = NA))
  st$notes <- lc$notes; if (length(lc$notes)) cat("[Keys]", paste(lc$notes, collapse = " "), "\n")
  if (which %in% c("both", "bq") && !is.na(lc$json_path) && (force || !(isTRUE(api_manager$bq_connected) || isTRUE(api_manager$bq_authenticated)))) {
    ok <- tryCatch({
      # same project / dataset / fixed table names as the manual "Connect" button (atera-2 / Wonderfulp_March by default)
      api_manager$set_bigquery_credentials(api_manager$bq_project_id, api_manager$bq_dataset_id)
      shiny::isolate(api_manager$authenticate_bigquery(json_path = lc$json_path)); TRUE }, error = function(e) { cat("[BigQuery] key from", lc$json_path, "failed:", conditionMessage(e), "\n"); FALSE })
    st$bq_failed <- !ok
    st$bq <- if (ok) sprintf("Connected automatically with %s (found in %s). Each suite's table is checked and loaded when you open its tab.", basename(lc$json_path), dir) else sprintf("A key was found (%s) but the connection failed: see the Debug Console.", basename(lc$json_path))
  }
  if (which %in% c("both", "claude") && !is.na(lc$claude_key) && (force || !isTRUE(api_manager$claude_authenticated))) {
    m <- Sys.getenv("CLAUDE_MODEL", "")
    api_manager$set_claude_credentials(lc$claude_key, model = if (nzchar(m)) m else NULL)
    cat("[Claude] API key taken from", file.path(dir, "ap_claude_1_line.txt"), "\n")   # path only, never the key
    # no test call at start-up (it would spend a request on every launch): the key is marked as loaded and is checked by the first real
    # request, or at once with the Test Connection button in the Claude API tab
    api_manager$claude_authenticated <- TRUE
    st$claude_failed <- FALSE
    st$claude <- sprintf("Key loaded from %s (%s). It is checked by the first request; press Test Connection to check it now.", file.path(dir, "ap_claude_1_line.txt"), app_mask_key(lc$claude_key))
  }
  .app_cred_env$status <- st
  invisible(st)
}

# environment-variable fallback (unchanged behaviour)
app_cred_env_fallback <- function(api_manager) {
  key <- Sys.getenv("ATERA_BQ_KEY_FILE", Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS", ""))
  if (nzchar(key) && file.exists(key) && !(isTRUE(api_manager$bq_connected) || isTRUE(api_manager$bq_authenticated)))
    tryCatch(shiny::isolate(api_manager$authenticate_bigquery(json_path = key)), error = function(e) cat("[BigQuery] automatic sign-in failed:", conditionMessage(e), "\n"))
  k <- Sys.getenv("ANTHROPIC_API_KEY", "")
  if (nzchar(k) && !isTRUE(api_manager$claude_authenticated)) {
    m <- Sys.getenv("CLAUDE_MODEL", ""); api_manager$set_claude_credentials(k, model = if (nzchar(m)) m else NULL)
    api_manager$claude_authenticated <- TRUE
  }
}

# ---- UI helpers ---------------------------------------------------------------------------------
# folder box placed at the top of each API tab: green/amber banner + a folder box for other systems
app_cred_box_ui <- function(ns, what = "key file") {
  tagList(
    uiOutput(ns("auto_key")),
    tags$details(style = "margin-bottom:10px;",
      tags$summary(style = "cursor:pointer;font-weight:600;", "Load the key from a folder on this computer"),
      p(style = "color:#7f8c8d;font-size:12px;margin:6px 0;", "Type the folder that holds the ", what, ". On Windows the folder C:/111_SecA/_q_api is read automatically at start-up. ",
        "The browser cannot browse the disk of the machine that runs the app, so paste the folder path (it must be on the computer where R is running)."),
      fluidRow(column(8, textInput(ns("cred_dir"), NULL, value = "", placeholder = "e.g. C:/111_SecA/_q_api or /home/me/keys", width = "100%")),
               column(4, actionButton(ns("cred_load"), "Load from this folder", icon = icon("folder-open"), style = "width:100%;"))))
  )
}
app_cred_banner <- function(which, trigger = NULL) {
  if (!is.null(trigger)) trigger()
  st <- app_cred_status(); txt <- st[[which]]; d <- if (is.null(st$dir)) "" else st$dir
  bad <- isTRUE(st[[paste0(which, "_failed")]])
  if (!is.null(txt)) tags$div(style = sprintf("background:%s; border:1px solid %s; color:%s; border-radius:8px; padding:8px 10px; margin-bottom:10px; font-size:12.5px;", if (bad) "#fffbeb" else "#ecfdf5", if (bad) "#fde68a" else "#a7f3d0", if (bad) "#92400e" else "#065f46"),
                              icon("key"), " ", txt, " You can still load another key below.")
  else tags$div(style = "background:#fffbeb; border:1px solid #fde68a; color:#92400e; border-radius:8px; padding:8px 10px; margin-bottom:10px; font-size:12.5px;",
                if (nzchar(d)) paste0("No key was loaded from ", d, ": ", paste(st$notes, collapse = " "), " Load the key below.")
                else "This is not Windows, so no local key folder is searched: type a folder below, or load the key file / paste it.")
}

# sidebar box
app_api_status_css <- function() tags$style(HTML("#api_status:empty::before { content: 'BigQuery: connecting...   Claude: connecting...'; color:#fbbf24; font-size:11.5px; }"))
app_api_status_ui <- function() tagList(app_api_status_css(),
  tags$div(style = "padding:10px; background-color:#2c3e50; margin-top:6px;",
    tags$div(style = "color:#b2e0db; font-size:11px; font-weight:700; margin-bottom:4px;", "API CONNECTIONS"), uiOutput("api_status")))
app_api_status_render <- function(api_manager) {
  invalidateLater(3000)
  st <- app_cred_status()
  light <- function(name, ok, txt) {
    col <- if (ok) "#22c55e" else "#ef4444"
    tags$div(style = "display:flex; align-items:flex-start; gap:6px; margin:3px 0; font-size:11.5px; color:#ecf0f1;",
      tags$span(style = sprintf("display:inline-block; width:10px; height:10px; border-radius:50%%; background:%s; margin-top:3px; flex:none;", col)), tags$span(tags$b(name, ": "), txt))
  }
  bq <- isTRUE(api_manager$bq_connected) || isTRUE(api_manager$bq_authenticated); cl <- isTRUE(api_manager$claude_authenticated)
  tagList(light("BigQuery", bq, if (bq) "connected (suites load when opened)" else if (isTRUE(st$bq_failed)) "key found, connection failed (see Debug Console)" else "not connected: API Configuration > BigQuery"),
          light("Claude", cl, if (cl) "key loaded" else if (isTRUE(st$claude_failed)) "key loaded, test call failed" else "no key: API Configuration > Claude API"))
}
