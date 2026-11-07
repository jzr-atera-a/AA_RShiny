# ---- Storage layer ------------------------------------------------------------
# One interface, two back-ends:
#   * "sheets": a Google Sheet (one tab per table in SCHEMAS)  -> production
#   * "local" : CSV files in ./data                             -> testing / fallback
# Every write is also recorded in the ChangeLog tab.

.store <- new.env(parent = emptyenv())
.store$cache   <- list()
.store$backend <- "local"
.store$status  <- "saving to CSV files in ./data (testing mode)"
.store$ss      <- NULL
.store$api_key <- cfg$anthropic_key

empty_df <- function(tab) {
  cols <- SCHEMAS[[tab]]
  as.data.frame(stats::setNames(rep(list(character()), length(cols)), cols), stringsAsFactors = FALSE)
}

norm_df <- function(df, tab) {
  cols <- SCHEMAS[[tab]]
  df <- as.data.frame(df, stringsAsFactors = FALSE)
  for (c in setdiff(cols, names(df))) df[[c]] <- rep(NA_character_, nrow(df))
  df <- df[cols]
  df[] <- lapply(df, function(x) { x <- as.character(x); x[is.na(x)] <- ""; x })
  rownames(df) <- NULL
  df
}

local_path <- function(tab) file.path(cfg$data_dir, paste0(tab, ".csv"))

store_init <- function() {
  dir.create(cfg$data_dir, showWarnings = FALSE, recursive = TRUE)
  if (nzchar(cfg$sheet_id)) {
    res <- tryCatch({
      if (nzchar(cfg$sa_json) && file.exists(cfg$sa_json)) {
        googlesheets4::gs4_auth(path = cfg$sa_json)
      } else if (nzchar(cfg$google_email)) {
        googlesheets4::gs4_auth(email = cfg$google_email)
      } else {
        googlesheets4::gs4_deauth()   # read-only access to link-shared sheets
      }
      ss <- googlesheets4::as_sheets_id(cfg$sheet_id)
      existing <- googlesheets4::sheet_names(ss)
      for (tab in setdiff(names(SCHEMAS), existing)) {
        googlesheets4::sheet_write(empty_df(tab), ss = ss, sheet = tab)
      }
      .store$ss <- ss
      TRUE
    }, error = function(e) {
      .store$status <- paste("Google Sheets unavailable - using local store. Reason:", conditionMessage(e))
      FALSE
    })
    if (isTRUE(res)) {
      .store$backend <- "sheets"
      .store$status  <- "Connected to Google Sheet"
    }
  }
  seed_defaults()
  invisible(.store$backend)
}

store_read <- function(tab, force = FALSE) {
  hit <- .store$cache[[tab]]
  if (!force && !is.null(hit) && difftime(Sys.time(), hit$t, units = "secs") < cfg$cache_ttl) return(hit$df)
  df <- tryCatch({
    if (.store$backend == "sheets") {
      googlesheets4::read_sheet(.store$ss, sheet = tab, col_types = "c")
    } else if (file.exists(local_path(tab))) {
      utils::read.csv(local_path(tab), colClasses = "character", stringsAsFactors = FALSE, na.strings = character())
    } else empty_df(tab)
  }, error = function(e) {
    if (!is.null(hit)) hit$df else empty_df(tab)
  })
  df <- norm_df(df, tab)
  .store$cache[[tab]] <- list(t = Sys.time(), df = df)
  df
}

store_replace <- function(tab, df) {
  df <- norm_df(df, tab)
  if (.store$backend == "sheets") {
    googlesheets4::sheet_write(df, ss = .store$ss, sheet = tab)
  } else {
    utils::write.csv(df, local_path(tab), row.names = FALSE)
  }
  .store$cache[[tab]] <- list(t = Sys.time(), df = df)
  invisible(df)
}

store_append <- function(tab, rows) {
  rows <- norm_df(rows, tab)
  if (nrow(rows) == 0) return(invisible(NULL))
  if (.store$backend == "sheets") {
    googlesheets4::sheet_append(.store$ss, data = rows, sheet = tab)
    cur <- store_read(tab)
    .store$cache[[tab]] <- list(t = Sys.time(), df = rbind(cur, rows))
  } else {
    store_replace(tab, rbind(store_read(tab, force = TRUE), rows))
  }
  invisible(rows)
}

log_change <- function(user, action, entity, detail = "") {
  try(store_append("ChangeLog", data.frame(timestamp = now_ts(), user = user, action = action,
                                           entity = entity, detail = substr(detail, 1, 400))), silent = TRUE)
}

# ---- settings (key/value tab, latest value wins) ---------------------------------
get_settings <- function() {
  s <- store_read("Settings")
  out <- SETTING_DEFAULTS
  if (nrow(s) > 0) {
    s <- s[order(s$updated_at), ]
    for (i in seq_len(nrow(s))) out[[s$key[i]]] <- s$value[i]
  }
  out
}

set_setting <- function(key, value, user = "admin") {
  s <- store_read("Settings", force = TRUE)
  row <- data.frame(key = key, value = as.character(value), updated_by = user, updated_at = now_ts())
  s <- rbind(s[s$key != key, , drop = FALSE], norm_df(row, "Settings"))
  store_replace("Settings", s)
  log_change(user, "setting", key, as.character(value))
}

# ---- first-run seed data -------------------------------------------------------------
seed_defaults <- function() {
  if (nrow(store_read("Users", force = TRUE)) == 0) {
    store_replace("Users", data.frame(
      email = cfg$admin_email, name = "Admin", role = "admin", organisation = "Atera Analytics",
      interests = "AI; digital twins; batteries; drones; energy", active = "TRUE", invited_at = now_ts()))
  }
  if (nrow(store_read("Grants", force = TRUE)) == 0) {
    seed <- data.frame(
      grant_id = sprintf("g%03d", 1:6),
      title = c(
        "CfI: Battery innovation for dual use & defence - Phase 1",
        "Innovate UK - Smart / open funding rounds (check latest)",
        "CCAV - connected & automated mobility calls (check latest)",
        "Faraday Battery Challenge - current competitions (check latest)",
        "DASA - open call for innovation (check latest)",
        "Net Zero Living / digital energy - follow-on funding (check latest)"),
      funder = c("Innovate UK", "Innovate UK", "CCAV / Innovate UK", "Faraday Institution / UKRI", "Dstl / DASA", "Innovate UK / DESNZ"),
      summary = c(
        "Phase 1 contract for innovation (comp 2587). Challenge 2 covers standardisation of dual-use battery packs.",
        "Placeholder - confirm scope, dates and value at source before prioritising.",
        "Placeholder - confirm scope, dates and value at source before prioritising.",
        "Placeholder - confirm scope, dates and value at source before prioritising.",
        "Placeholder - confirm scope, dates and value at source before prioritising.",
        "Placeholder - confirm scope, dates and value at source before prioritising."),
      themes = c("batteries; defence; standards; dual-use", "ai; data; innovation", "mobility; ev; digital-twin; geospatial",
                 "batteries; manufacturing; energy", "defence; drones; ai", "net-zero; energy; ev; digital-twin"),
      min_gbp = c("20000", "", "", "", "", ""), max_gbp = c("50000", "", "", "", "", ""),
      closes = c("2026-11-04", "", "", "", "", ""),
      url = c("https://apply-for-innovation-funding.service.gov.uk/competition/2587/overview",
              "https://www.ukri.org/opportunity/", "https://www.ukri.org/opportunity/",
              "https://www.ukri.org/opportunity/", "https://www.gov.uk/government/organisations/defence-and-security-accelerator",
              "https://www.ukri.org/opportunity/"),
      status = c("open", rep("upcoming", 5)),
      source = c("seed", rep("seed-placeholder", 5)), added_by = cfg$admin_email, added_at = now_ts())
    store_replace("Grants", seed)
  }
  invisible(TRUE)
}
