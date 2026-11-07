# R/utils_deploy_manager.R
# DeployManager — shared state across all deploy modules.
# Holds auth credentials, temp file paths, and a dual-channel log
# (every entry goes to both the deploy console and the debug tab).

library(R6)

# Reads a text file whatever its encoding: UTF-16 (Windows "Unicode" / PowerShell
# Out-File), UTF-8 with or without a byte-order mark, and CRLF or LF line endings.
read_text_robust <- function(path) {
  bytes <- readBin(path, what = "raw", n = file.info(path)$size)
  n <- length(bytes)
  if (n >= 2 && identical(bytes[1:2], as.raw(c(0xff, 0xfe))))
    txt <- iconv(list(bytes[-(1:2)]), from = "UTF-16LE", to = "UTF-8")
  else if (n >= 2 && identical(bytes[1:2], as.raw(c(0xfe, 0xff))))
    txt <- iconv(list(bytes[-(1:2)]), from = "UTF-16BE", to = "UTF-8")
  else {
    if (n >= 3 && identical(bytes[1:3], as.raw(c(0xef, 0xbb, 0xbf)))) bytes <- bytes[-(1:3)]
    txt <- rawToChar(bytes[bytes != as.raw(0)])
  }
  paste(strsplit(gsub("\r\n?", "\n", txt), "\n")[[1]], collapse = "\n")
}

# Reads name / token / secret from an rsconnect setAccountInfo() file.
# The file is parsed, never executed. Missing values are NA.
read_account_info <- function(path) {
  txt <- read_text_robust(path)
  pick <- function(param) {
    pat <- paste0("(?<![A-Za-z0-9_.])", param, "\\s*=\\s*['\"]([^'\"]+)['\"]")
    m   <- regmatches(txt, regexec(pat, txt, perl = TRUE))[[1]]
    if (length(m) < 2) NA_character_ else m[2]
  }
  list(name = pick("name"), token = pick("token"), secret = pick("secret"))
}

DeployManager <- R6Class(
  "DeployManager",

  public = list(

    # ── Auth state ───────────────────────────────────────────────
    authenticated   = FALSE,
    account_name    = NULL,
    account_token   = NULL,
    account_secret  = NULL,

    # ── Upload / unzip state ────────────────────────────────────
    zip_temp_path    = NULL,   # path to the copied zip
    unzip_temp_dir   = NULL,   # top-level temp dir created for this upload
    detected_app_dir = NULL,   # sub-dir containing app.R / server.R

    # ── Deploy state ────────────────────────────────────────────
    app_name      = NULL,
    deploy_status = "idle",   # idle | running | success | error

    # ── Log stores ──────────────────────────────────────────────
    # Each entry: named list(ts, msg, type, prefix) serialised as JSON
    console_lines = character(0),
    debug_lines   = character(0),

    # ── Reactive triggers ────────────────────────────────────────
    console_trigger = NULL,
    debug_trigger   = NULL,
    status_trigger  = NULL,

    # ────────────────────────────────────────────────────────────
    initialize = function() {
      self$console_trigger <- reactiveVal(0)
      self$debug_trigger   <- reactiveVal(0)
      self$status_trigger  <- reactiveVal(0)
      cat("[DeployManager] initialized\n")
    },

    # ── Auth ─────────────────────────────────────────────────────
    set_auth = function(name, token, secret) {
      self$account_name   <- name
      self$account_token  <- token
      self$account_secret <- secret
      self$authenticated  <- TRUE
      self$log("AUTH", paste("Authenticated as:", name), "success")
    },

    clear_auth = function() {
      self$authenticated  <- FALSE
      self$account_name   <- NULL
      self$account_token  <- NULL
      self$account_secret <- NULL
      self$log("AUTH", "Credentials cleared", "warn")
    },

    # ── Unified logger ────────────────────────────────────────────
    # type: "info" | "success" | "error" | "warn" | "cmd"
    log = function(tag = "INFO", msg, type = "info") {
      ts     <- format(Sys.time(), "%H:%M:%S")
      prefix <- switch(type,
        success = "\u2713",
        error   = "\u2717",
        warn    = "\u26a0",
        cmd     = "$",
        ">"
      )
      entry <- jsonlite::toJSON(
        list(ts = ts, tag = tag, msg = msg, type = type, prefix = prefix),
        auto_unbox = TRUE
      )
      self$console_lines <- c(self$console_lines, entry)
      sdm_log(tag, msg, type)              # shared log: R console + Debug Console tab
      self$trigger_console()
      self$trigger_debug()
    },

    # ── Status ───────────────────────────────────────────────────
    set_status = function(status) {
      self$deploy_status <- status
      self$trigger_status()
    },

    # ── Temp file cleanup (success path only) ────────────────────
    cleanup_temp = function() {
      if (!is.null(self$zip_temp_path) && file.exists(self$zip_temp_path)) {
        file.remove(self$zip_temp_path)
        self$log("CLEAN", paste("Deleted zip:", self$zip_temp_path), "info")
      }
      if (!is.null(self$unzip_temp_dir) && dir.exists(self$unzip_temp_dir)) {
        unlink(self$unzip_temp_dir, recursive = TRUE)
        self$log("CLEAN", paste("Deleted unzip dir:", self$unzip_temp_dir), "info")
      }
      self$zip_temp_path    <- NULL
      self$unzip_temp_dir   <- NULL
      self$detected_app_dir <- NULL
    },

    # ── Clear logs ────────────────────────────────────────────────
    clear_console = function() {
      self$console_lines <- character(0)
      self$trigger_console()
    },

    clear_debug = function() {
      sdm_log_clear()
      self$trigger_debug()
    },

    # ── Internal triggers ─────────────────────────────────────────
    trigger_console = function() {
      if (!is.null(self$console_trigger))
        self$console_trigger(isolate(self$console_trigger()) + 1L)
    },
    trigger_debug = function() {
      if (!is.null(self$debug_trigger))
        self$debug_trigger(isolate(self$debug_trigger()) + 1L)
    },
    trigger_status = function() {
      if (!is.null(self$status_trigger))
        self$status_trigger(isolate(self$status_trigger()) + 1L)
    }
  )
)
