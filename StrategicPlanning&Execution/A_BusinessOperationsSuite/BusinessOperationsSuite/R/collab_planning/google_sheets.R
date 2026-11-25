# R/google_sheets.R - Google Sheets through the REST API with a service account
# Same approach as the VentureDeals app: a signed JWT (openssl) swapped for an access token,
# then plain httr calls. No googlesheets4 / googledrive needed.

.gs <- new.env(parent = emptyenv())
.gs$token <- NULL
.gs$token_exp <- NULL

b64url <- function(x) {
  if (is.character(x)) x <- charToRaw(x)
  b <- base64enc::base64encode(x)
  b <- gsub("+", "-", b, fixed = TRUE)
  b <- gsub("/", "_", b, fixed = TRUE)
  sub("=+$", "", b)
}

sa_key_available <- function() file.exists(cfg$sa_key_path)

sa_client_email <- function() {
  if (!sa_key_available()) return("")
  tryCatch(jsonlite::fromJSON(cfg$sa_key_path)$client_email, error = function(e) "")
}

# One token for both services: Sheets (storage) and Drive (copies of the analysis tables)
google_token <- function(scopes = c("https://www.googleapis.com/auth/spreadsheets", "https://www.googleapis.com/auth/drive")) {
  if (!is.null(.gs$token) && !is.null(.gs$token_exp) && Sys.time() < .gs$token_exp - 60) return(.gs$token)
  if (!sa_key_available()) stop("Service account key not found at ", cfg$sa_key_path)
  sa  <- jsonlite::fromJSON(cfg$sa_key_path)
  now <- as.integer(Sys.time())
  header <- '{"alg":"RS256","typ":"JWT"}'
  claim  <- jsonlite::toJSON(list(iss = sa$client_email, scope = paste(scopes, collapse = " "),
                                  aud = "https://oauth2.googleapis.com/token", iat = now, exp = now + 3600L),
                             auto_unbox = TRUE)
  signing_input <- paste0(b64url(header), ".", b64url(as.character(claim)))
  sig <- b64url(openssl::signature_create(charToRaw(signing_input), hash = openssl::sha256,
                                          key = openssl::read_key(sa$private_key)))
  resp <- httr::POST("https://oauth2.googleapis.com/token",
                     body = list(grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer",
                                 assertion = paste0(signing_input, ".", sig)),
                     encode = "form", httr::timeout(20))
  httr::stop_for_status(resp, "get a Google access token")
  tok <- httr::content(resp, as = "parsed")
  .gs$token <- tok$access_token
  .gs$token_exp <- Sys.time() + as.numeric(tok$expires_in %||% 3600)
  .gs$token
}

gs_url <- function(path) sprintf("https://sheets.googleapis.com/v4/spreadsheets/%s%s", cfg$sheet_id, path)
gs_auth <- function() httr::add_headers(Authorization = paste("Bearer", google_token()))
gs_range <- function(x) utils::URLencode(x, reserved = TRUE)

gs_list_tabs <- function() {
  resp <- httr::GET(gs_url("?fields=sheets.properties.title"), gs_auth(), httr::timeout(20))
  httr::stop_for_status(resp, "list the Sheet's tabs")
  .gs$tabs <- vapply(httr::content(resp, as = "parsed")$sheets, function(s) s$properties$title, "")
  .gs$tabs
}
.gs$tabs <- NULL
gs_tabs_cached <- function() .gs$tabs %||% gs_list_tabs()

gs_add_tab <- function(tab) {
  body <- list(requests = list(list(addSheet = list(properties = list(title = tab)))))
  resp <- httr::POST(gs_url(":batchUpdate"), gs_auth(), body = body, encode = "json", httr::timeout(20))
  httr::stop_for_status(resp, paste("add tab", tab))
  invisible(TRUE)
}

# Read a whole tab into a data frame (first row = header). Ragged rows are padded.
gs_read <- function(tab) {
  resp <- httr::GET(gs_url(paste0("/values/", gs_range(paste0(tab, "!A:AZ")))), gs_auth(), httr::timeout(20))
  httr::stop_for_status(resp, paste("read tab", tab))
  gs_values_to_df(httr::content(resp, as = "parsed")$values, tab)
}

# Read many tabs in ONE request (values:batchGet), so polling all tables stays far inside Google's quota
gs_batch_read <- function(tabs) {
  tabs <- intersect(tabs, gs_tabs_cached())
  if (!length(tabs)) return(list())
  q <- paste0("ranges=", vapply(paste0(tabs, "!A:AZ"), gs_range, ""), collapse = "&")
  resp <- httr::GET(gs_url(paste0("/values:batchGet?majorDimension=ROWS&", q)), gs_auth(), httr::timeout(30))
  httr::stop_for_status(resp, "read the Sheet")
  vr <- httr::content(resp, as = "parsed")$valueRanges
  setNames(lapply(seq_along(tabs), function(i) gs_values_to_df(vr[[i]]$values, tabs[i])), tabs)
}

gs_values_to_df <- function(vals, tab) {
  if (length(vals) < 1) return(empty_table(tab))
  header <- tolower(trimws(unlist(vals[[1]])))
  rows <- vals[-1]
  if (!length(rows)) return(conform(NULL, tab))
  m <- t(vapply(rows, function(r) { r <- as.character(unlist(r)); length(r) <- length(header); r[is.na(r)] <- ""; r },
                character(length(header))))
  if (length(header) == 1) m <- matrix(m, ncol = 1)
  df <- as.data.frame(m, stringsAsFactors = FALSE)
  names(df) <- header
  conform(df, tab)
}

gs_append <- function(tab, df) {
  if (!nrow(df)) return(invisible(0))
  gs_ensure_header(tab)
  values <- unname(lapply(seq_len(nrow(df)), function(i) unname(as.list(df[i, , drop = TRUE]))))
  url <- gs_url(paste0("/values/", gs_range(paste0(tab, "!A1")), ":append?valueInputOption=RAW&insertDataOption=INSERT_ROWS"))
  resp <- httr::POST(url, gs_auth(), body = list(values = values), encode = "json", httr::timeout(30))
  httr::stop_for_status(resp, paste("append to tab", tab))
  invisible(nrow(df))
}

gs_write_all <- function(tab, df) {
  resp <- httr::POST(gs_url(paste0("/values/", gs_range(paste0(tab, "!A:AZ")), ":clear")), gs_auth(),
                     body = list(), encode = "json", httr::timeout(30))
  httr::stop_for_status(resp, paste("clear tab", tab))
  values <- c(list(as.list(names(df))),
              unname(lapply(seq_len(nrow(df)), function(i) unname(as.list(df[i, , drop = TRUE])))))
  url <- gs_url(paste0("/values/", gs_range(paste0(tab, "!A1")), "?valueInputOption=RAW"))
  resp <- httr::PUT(url, gs_auth(), body = list(values = values), encode = "json", httr::timeout(30))
  httr::stop_for_status(resp, paste("write tab", tab))
  invisible(nrow(df))
}

# Create the tab with its header row if it is missing
gs_ensure_tab <- function(tab, existing = NULL) {
  existing <- existing %||% gs_tabs_cached()
  if (tab %in% existing) return(invisible(FALSE))
  gs_add_tab(tab)
  .gs$tabs <- unique(c(.gs$tabs, tab))
  gs_write_all(tab, empty_table(tab))
  log_debug("[Sheets] created tab ", tab)
  invisible(TRUE)
}

# Add any schema columns missing from an existing tab's header row. New columns are only ever
# appended at the end of SCHEMAS, so the header is rewritten in schema order. Checked once per tab.
.gs$headers_ok <- character(0)
gs_ensure_header <- function(tab) {
  if (tab %in% .gs$headers_ok) return(invisible(FALSE))
  resp <- httr::GET(gs_url(paste0("/values/", gs_range(paste0(tab, "!1:1")))), gs_auth(), httr::timeout(20))
  httr::stop_for_status(resp, paste("read header of", tab))
  have <- tolower(trimws(unlist(httr::content(resp, as = "parsed")$values[[1]] %||% list())))
  want <- SCHEMAS[[tab]]
  if (length(have) < length(want) && identical(have, want[seq_along(have)])) {
    url <- gs_url(paste0("/values/", gs_range(paste0(tab, "!A1")), "?valueInputOption=RAW"))
    r2 <- httr::PUT(url, gs_auth(), body = list(values = list(as.list(want))), encode = "json", httr::timeout(20))
    httr::stop_for_status(r2, paste("update header of", tab))
    log_debug("[Sheets] added columns to ", tab, ": ", paste(setdiff(want, have), collapse = ", "))
  } else if (length(have) && !identical(have, want[seq_along(have)]))
    log_debug("[Sheets] header of ", tab, " differs from the schema; check the tab by hand")
  .gs$headers_ok <- unique(c(.gs$headers_ok, tab))
  invisible(TRUE)
}
