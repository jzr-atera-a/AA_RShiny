# ============================================================================
# SESSION MANAGER - R6 CLASS
# Handles persistence of: API keys, paths, context files, run state
# Stored in: {runs_dir}/session_config.json  (config layer)
#            {run_dir}/session.json           (per-run state, written by Python)
# ============================================================================

SessionManager <- R6::R6Class(
  "SessionManager",

  public = list(
    config_path  = NULL,   # app-level config (API key, paths, budget)
    config       = NULL,   # loaded config list

    initialize = function(config_path = "nb_session_config.json") {
      self$config_path <- config_path
      self$config      <- self$load_config()
      cat("✓ SessionManager initialised\n")
    },

    # ── App-level config (Tab 1 settings) ─────────────────────────────────

    load_config = function() {
      defaults <- list(
        anthropic_api_key   = "",
        claude_model        = "claude-opus-4-5",
        python_env_path     = "",
        context_dir         = file.path(getwd(), "context"),
        runs_dir            = file.path(getwd(), "runs"),
        max_cost_usd        = 2.00,
        max_tokens          = 200000,
        max_retries_per_cell= 3,
        max_consec_fails    = 3,
        review_every_cell   = FALSE,
        last_run_dir        = ""
      )
      if (file.exists(self$config_path)) {
        saved <- tryCatch(
          jsonlite::fromJSON(self$config_path, simplifyVector = TRUE),
          error = function(e) list()
        )
        for (k in names(saved)) defaults[[k]] <- saved[[k]]
        cat("  ✓ Config loaded from", self$config_path, "\n")
      } else {
        cat("  ℹ No saved config found — using defaults\n")
      }
      defaults
    },

    save_config = function(cfg) {
      self$config <- cfg
      jsonlite::write_json(cfg, self$config_path, pretty = TRUE, auto_unbox = TRUE)
      cat("✓ Config saved to", self$config_path, "\n")
    },

    get = function(key, default = NULL) {
      val <- self$config[[key]]
      if (is.null(val)) default else val
    },

    # ── Per-run state (written by Python, read by R) ───────────────────────

    load_run_state = function(run_dir) {
      path <- file.path(run_dir, "session.json")
      if (!file.exists(path)) return(NULL)
      tryCatch(
        jsonlite::fromJSON(path, simplifyVector = FALSE),
        error = function(e) { cat("⚠ Could not parse session.json:", e$message, "\n"); NULL }
      )
    },

    load_progress = function(run_dir) {
      path <- file.path(run_dir, "progress.json")
      if (!file.exists(path)) return(NULL)
      tryCatch(
        jsonlite::fromJSON(path, simplifyVector = FALSE),
        error = function(e) NULL
      )
    },

    load_log = function(run_dir, tail_n = 200) {
      path <- file.path(run_dir, "run.log")
      if (!file.exists(path)) return("")
      lines <- tryCatch(readLines(path, warn = FALSE), error = function(e) character(0))
      if (length(lines) > tail_n) lines <- tail(lines, tail_n)
      paste(lines, collapse = "\n")
    },

    # ── Control file — R → Python communication ────────────────────────────

    send_command = function(run_dir, command) {
      # command: "run" | "pause" | "stop"
      path <- file.path(run_dir, "control.json")
      jsonlite::write_json(list(command = command), path, auto_unbox = TRUE)
      cat("  → Control command sent:", command, "\n")
    },

    # ── List existing runs ─────────────────────────────────────────────────

    list_runs = function(runs_dir) {
      if (!dir.exists(runs_dir)) return(character(0))
      dirs <- list.dirs(runs_dir, recursive = FALSE, full.names = TRUE)
      dirs <- dirs[file.exists(file.path(dirs, "session.json"))]
      sort(dirs, decreasing = TRUE)
    },

    # ── Context files ──────────────────────────────────────────────────────

    list_context_files = function(context_dir) {
      if (!dir.exists(context_dir)) return(character(0))
      f <- list.files(context_dir, full.names = FALSE)
      f[!startsWith(f, ".")]
    },

    load_context_files = function(context_dir) {
      files <- list.files(context_dir, full.names = TRUE)
      files <- files[!startsWith(basename(files), ".")]
      result <- list()
      for (f in files) {
        content <- tryCatch(
          paste(readLines(f, warn = FALSE), collapse = "\n"),
          error = function(e) NA_character_
        )
        result[[basename(f)]] <- content
      }
      result
    }
  )
)
