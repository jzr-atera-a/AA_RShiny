# R/utils_deploy_manager.R
# DeployManager — shared state across all deploy modules.
# Holds auth credentials, temp file paths, and a dual-channel log
# (every entry goes to both the deploy console and the debug tab).

library(R6)

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
      self$debug_lines   <- c(self$debug_lines,
                               paste0("[", ts, "][", tag, "] ", prefix, " ", msg))
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
      self$debug_lines <- character(0)
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
