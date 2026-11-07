# R/utils_local_creds.R
# Keys kept in a local folder on this PC: on Windows the app looks in C:\111_SecA\_q_api\ at start-up for
#   - the BigQuery service-account key: a *.json file with "type": "service_account" (the one for project atera-2 first,
#     otherwise the newest), and
#   - the Claude API key: the single line in ap_claude_1_line.txt.
# Nothing is copied anywhere; if a key is not found (or this is not Windows) the API Configuration tabs ask for it as before.
# LAT_CRED_DIR (environment) points at another folder, on any OS.
tr_cred_dir_default <- "C:/111_SecA/_q_api"
tr_cred_dir <- function() { d <- Sys.getenv("LAT_CRED_DIR", ""); if (nzchar(d)) d else if (.Platform$OS.type == "windows") tr_cred_dir_default else "" }
tr_local_credentials <- function(dir = tr_cred_dir(), project = "atera-2") {
  out <- list(dir = dir, json_path = NA_character_, json_project = NA_character_, claude_key = NA_character_, notes = character(0))
  if (!nzchar(dir)) { out$notes <- "Not Windows: no local key folder is searched (set LAT_CRED_DIR to use one)."; return(out) }
  if (!dir.exists(dir)) { out$notes <- sprintf("Folder %s not found.", dir); return(out) }
  js <- list.files(dir, pattern = "\\.json$", full.names = TRUE, ignore.case = TRUE)
  info <- lapply(js, function(f) { j <- tryCatch(jsonlite::fromJSON(f, simplifyVector = TRUE), error = function(e) NULL)
    if (is.list(j) && identical(j$type, "service_account") && !is.null(j$private_key)) data.frame(path = f, project = tr_or(j$project_id, ""), mtime = file.mtime(f), stringsAsFactors = FALSE) else NULL })
  info <- do.call(rbind, Filter(Negate(is.null), info))
  if (!is.null(info) && nrow(info)) { info <- info[order(info$project != project, -as.numeric(info$mtime)), , drop = FALSE]
    out$json_path <- info$path[1]; out$json_project <- info$project[1]
    if (nrow(info) > 1) out$notes <- c(out$notes, sprintf("%d service-account keys found; using %s.", nrow(info), basename(info$path[1])))
  } else out$notes <- c(out$notes, sprintf("No service-account .json key in %s.", dir))
  kf <- file.path(dir, "ap_claude_1_line.txt")
  if (file.exists(kf)) { k <- trimws(readLines(kf, warn = FALSE)); k <- k[nzchar(k)]
    if (length(k)) out$claude_key <- k[1] else out$notes <- c(out$notes, "ap_claude_1_line.txt is empty.")
  } else out$notes <- c(out$notes, sprintf("No ap_claude_1_line.txt in %s.", dir))
  out
}
tr_mask_key <- function(k) if (is.na(k) || nchar(k) < 12) "" else paste0(substr(k, 1, 7), "...", substr(k, nchar(k) - 3, nchar(k)))
# What the API tabs show: list(bq = text or NULL, claude = text or NULL), set at start-up by app.R
u3_cred_status <- function() tryCatch(get(".u3_cred_status", envir = .GlobalEnv), error = function(e) list())
