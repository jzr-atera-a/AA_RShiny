# R/sheets_backend.R — Google Sheets Backend via REST API
# Uses httr + jsonlite + openssl + base64enc only.
# No googlesheets4 / googledrive dependency.

library(httr)
library(jsonlite)

# ── Config ──────────────────────────────────────────────────
SHEETS_CONFIG <- list(
  sheet_id      = Sys.getenv("GOOGLE_SHEETS_ID",
                             "1bWxiGjfiE-GARuJxyrXiM_wzCgENifjCe8Eb5wQuq08"),
  sa_key_path   = "auth/google_service_account.json",
  tab_emails    = "allowed_emails",
  tab_login_log = "login_log",
  tab_analytics = "analytics_log",
  cache_secs    = 60,
  admin_emails  = trimws(strsplit(
    Sys.getenv("ADMIN_EMAILS", "joseph.zr@atera-analytics.co.uk"), ","
  )[[1]])
)

# ── Internal state ───────────────────────────────────────────
.sheets_env <- new.env(parent = emptyenv())
.sheets_env$token       <- NULL
.sheets_env$token_exp   <- NULL
.sheets_env$connected   <- FALSE
.sheets_env$email_cache <- NULL
.sheets_env$cache_time  <- NULL

# ── Base64url encode ─────────────────────────────────────────
b64url <- function(x) {
  if (is.character(x)) x <- charToRaw(x)
  b <- base64enc::base64encode(x)
  b <- gsub("\\+", "-", b)
  b <- gsub("/",   "_", b)
  b <- gsub("=+$", "",  b)
  b
}

# ── JWT / OAuth2 token for service account ───────────────────
get_sa_token <- function() {
  if (!is.null(.sheets_env$token) &&
      !is.null(.sheets_env$token_exp) &&
      Sys.time() < .sheets_env$token_exp - 60) {
    return(.sheets_env$token)
  }
  
  key_path <- SHEETS_CONFIG$sa_key_path
  if (!file.exists(key_path)) stop("Key file not found: ", key_path)
  
  sa  <- jsonlite::fromJSON(key_path)
  now <- as.integer(Sys.time())
  
  header_str <- '{"alg":"RS256","typ":"JWT"}'
  claim_str  <- paste0(
    '{"iss":"', sa$client_email, '"',
    ',"scope":"https://www.googleapis.com/auth/spreadsheets',
    ' https://www.googleapis.com/auth/drive"',
    ',"aud":"https://oauth2.googleapis.com/token"',
    ',"iat":', now,
    ',"exp":', now + 3600L, '}'
  )
  
  signing_input <- paste0(b64url(header_str), ".", b64url(claim_str))
  pkey <- openssl::read_key(sa$private_key)
  sig  <- b64url(openssl::signature_create(
    charToRaw(signing_input),
    hash = openssl::sha256,
    key  = pkey
  ))
  jwt <- paste0(signing_input, ".", sig)
  
  resp <- httr::POST(
    "https://oauth2.googleapis.com/token",
    body = list(
      grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion  = jwt
    ),
    encode = "form"
  )
  httr::stop_for_status(resp)
  tok <- httr::content(resp, as = "parsed")
  
  .sheets_env$token     <- tok$access_token
  .sheets_env$token_exp <- Sys.time() + tok$expires_in
  .sheets_env$token
}

# ── Core REST helpers ────────────────────────────────────────

sheets_get <- function(range) {
  tok <- get_sa_token()
  url <- sprintf(
    "https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s",
    SHEETS_CONFIG$sheet_id,
    utils::URLencode(range, reserved = TRUE)
  )
  resp <- httr::GET(url, httr::add_headers(Authorization = paste("Bearer", tok)))
  httr::stop_for_status(resp)
  httr::content(resp, as = "parsed")
}

sheets_append <- function(tab, values_list) {
  tok <- get_sa_token()
  url <- sprintf(
    "https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS",
    SHEETS_CONFIG$sheet_id,
    utils::URLencode(tab, reserved = TRUE)
  )
  body <- jsonlite::toJSON(
    list(values = list(values_list)),
    auto_unbox = TRUE
  )
  resp <- httr::POST(
    url,
    httr::add_headers(
      Authorization  = paste("Bearer", tok),
      `Content-Type` = "application/json"
    ),
    body = body
  )
  httr::stop_for_status(resp)
  invisible(TRUE)
}

parse_sheet <- function(result) {
  rows <- result$values
  if (is.null(rows) || length(rows) == 0) return(NULL)
  headers <- unlist(rows[[1]])
  # Only headers, no data rows
  if (length(rows) < 2) {
    empty <- as.data.frame(matrix(nrow = 0, ncol = length(headers)),
                           stringsAsFactors = FALSE)
    names(empty) <- headers
    return(empty)
  }
  data <- lapply(rows[-1], function(r) {
    r <- unlist(r)
    length(r) <- length(headers)
    r
  })
  df <- as.data.frame(do.call(rbind, data), stringsAsFactors = FALSE)
  names(df) <- headers
  df
}

# ── Connection ───────────────────────────────────────────────

sheets_connect <- function() {
  tok      <- get_sa_token()
  sheet_id <- SHEETS_CONFIG$sheet_id
  
  url <- sprintf(
    "https://sheets.googleapis.com/v4/spreadsheets/%s?fields=properties.title",
    sheet_id
  )
  resp <- httr::GET(url, httr::add_headers(Authorization = paste("Bearer", tok)))
  
  if (resp$status_code == 200) {
    info <- httr::content(resp, as = "parsed")
    cat("✓ Sheets: Connected to:", info$properties$title, "\n")
    .sheets_env$connected <- TRUE
    return(TRUE)
  }
  
  cat("⚠ Sheets: HTTP", resp$status_code, "— using file fallback\n")
  .sheets_env$connected <- FALSE
  FALSE
}

# ── User Management ──────────────────────────────────────────

sheets_get_allowed_emails <- function(force = FALSE) {
  if (!force &&
      !is.null(.sheets_env$email_cache) &&
      !is.null(.sheets_env$cache_time) &&
      as.numeric(Sys.time() - .sheets_env$cache_time, units = "secs") < SHEETS_CONFIG$cache_secs) {
    return(.sheets_env$email_cache)
  }
  
  if (sheets_connect()) {
    tryCatch({
      result <- sheets_get(paste0(SHEETS_CONFIG$tab_emails, "!A4:A200"))
      rows   <- result$values
      if (!is.null(rows) && length(rows) > 0) {
        emails <- tolower(trimws(sapply(rows, function(r) r[[1]])))
        emails <- emails[nchar(emails) > 0 & !startsWith(emails, "removed_")]
        .sheets_env$email_cache <- emails
        .sheets_env$cache_time  <- Sys.time()
        return(emails)
      }
    }, error = function(e) {
      cat("⚠ Sheets: Could not read emails:", e$message, "\n")
    })
  }
  
  sheets_emails_from_file()
}

sheets_get_users_df <- function() {
  if (sheets_connect()) {
    tryCatch({
      result <- sheets_get(paste0(SHEETS_CONFIG$tab_emails, "!A3:E200"))
      return(parse_sheet(result))
    }, error = function(e) NULL)
  }
  emails <- sheets_emails_from_file()
  data.frame(email = emails, role = "user", added_by = "file",
             added_date = NA, notes = NA, stringsAsFactors = FALSE)
}

sheets_add_user <- function(email, role = "user", added_by = "admin", notes = "") {
  email <- tolower(trimws(email))
  if (!sheets_connect()) return(list(ok = FALSE, msg = "Not connected"))
  tryCatch({
    sheets_append(SHEETS_CONFIG$tab_emails, list(
      email, role, added_by,
      format(Sys.time(), "%Y-%m-%d %H:%M:%S"), notes
    ))
    .sheets_env$email_cache <- NULL
    list(ok = TRUE, msg = paste0("User ", email, " added"))
  }, error = function(e) list(ok = FALSE, msg = e$message))
}

sheets_remove_user <- function(email) {
  list(ok = FALSE,
       msg = paste0("To remove '", email,
                    "', prefix their email with REMOVED_ directly in the Google Sheet."))
}

# ── Login Logging ────────────────────────────────────────────

sheets_log_login <- function(email, success, session_id, ip = "unknown") {
  tryCatch({
    if (sheets_connect()) {
      sheets_append(SHEETS_CONFIG$tab_login_log, list(
        format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        email,
        if (tolower(email) %in% tolower(SHEETS_CONFIG$admin_emails)) "admin" else "user",
        if (success) "TRUE" else "FALSE",
        ip,
        session_id
      ))
    }
  }, error = function(e) invisible())
}

# ── Analytics Logging ────────────────────────────────────────

sheets_log_event <- function(email, session_id, event_type,
                             tab = "", element = "", detail = "",
                             duration_secs = NA) {
  cat(sprintf("📝 sheets_log_event called: %s for %s\n", event_type, email))
  tryCatch({
    connected <- sheets_connect()
    cat(sprintf("📝 sheets_connect result: %s\n", connected))
    if (connected) {
      row_data <- list(
        format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        email, session_id, event_type, tab, element,
        substr(as.character(detail), 1, 200),
        if (is.na(duration_secs)) "" else as.character(round(duration_secs, 1))
      )
      cat(sprintf("📝 Appending to tab: %s\n", SHEETS_CONFIG$tab_analytics))
      sheets_append(SHEETS_CONFIG$tab_analytics, row_data)
      cat(sprintf("✓ sheets_log_event success: %s\n", event_type))
    } else {
      cat("❌ sheets_log_event: not connected\n")
    }
  }, error = function(e) {
    cat(sprintf("❌ sheets_log_event error: %s\n", e$message))
  })
}

# ── Analytics Reading ────────────────────────────────────────

sheets_get_login_log <- function() {
  if (!sheets_connect()) return(NULL)
  tryCatch({
    # Row 3 = column headers, data from row 4 onwards
    result <- sheets_get(paste0(SHEETS_CONFIG$tab_login_log, "!A3:F2000"))
    parse_sheet(result)
  }, error = function(e) NULL)
}

sheets_get_analytics <- function() {
  if (!sheets_connect()) return(NULL)
  tryCatch({
    # Row 3 = column headers, data from row 4 onwards
    result <- sheets_get(paste0(SHEETS_CONFIG$tab_analytics, "!A3:H2000"))
    parse_sheet(result)
  }, error = function(e) NULL)
}

# ── File fallback ────────────────────────────────────────────

sheets_emails_from_file <- function() {
  path <- "auth/allowed_emails.txt"
  if (!file.exists(path)) return(character(0))
  lines <- readLines(path, warn = FALSE)
  lines <- trimws(lines)
  tolower(lines[nchar(lines) > 0 & !startsWith(lines, "#")])
}

# ── Is admin ────────────────────────────────────────────────

is_admin <- function(email) {
  tolower(trimws(email)) %in% tolower(trimws(SHEETS_CONFIG$admin_emails))
}