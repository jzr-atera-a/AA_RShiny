# ============================================================================
# SESSION MANAGER - R6 CLASS
# Fixes: simplifyVector=FALSE, arcgis-ml fallback path, config location search
# ============================================================================

SessionManager <- R6::R6Class(
  "SessionManager",

  public = list(
    config_path = NULL,
    config      = NULL,

    initialize = function(config_path = NULL) {
      # Search for config in app dir AND working dir
      self$config_path <- private$resolve_config_path(config_path)
      self$config      <- self$load_config()
      cat("✓ SessionManager initialised\n")
    },

    load_config = function() {
      defaults <- list(
        anthropic_api_key    = "",
        claude_model         = "claude-opus-4-5",
        python_env_path      = "",
        kernel_name          = "python3",
        context_dir          = file.path(getwd(), "context"),
        runs_dir             = file.path(getwd(), "runs"),
        max_cost_usd         = 2.00,
        max_tokens           = 200000,
        max_retries_per_cell = 3,
        max_consec_fails     = 3,
        review_every_cell    = FALSE,
        last_run_dir         = ""
      )

      if (file.exists(self$config_path)) {
        saved <- tryCatch(
          # simplifyVector=FALSE keeps everything as plain R lists/scalars,
          # avoiding data.frame coercion that causes "environments cannot be
          # coerced to other types" errors
          jsonlite::fromJSON(self$config_path, simplifyVector = FALSE),
          error = function(e) { cat("  ⚠ Config parse error:", e$message, "\n"); list() }
        )
        # Merge saved values over defaults, coercing types explicitly
        if (is.list(saved) && length(saved) > 0) {
          for (k in names(saved)) {
            v <- saved[[k]]
            if (!is.null(v)) defaults[[k]] <- v
          }
          cat("  ✓ Config loaded from", self$config_path, "\n")
        }
      } else {
        cat("  ℹ No saved config found — using defaults\n")
      }

      # ── Auto-detect Python if not saved ───────────────────────────────────
      py <- defaults$python_env_path
      if (!nzchar(trimws(py %||% "")) || !file.exists(py %||% "")) {
        detected <- private$detect_python_fallback()
        if (!is.null(detected)) {
          defaults$python_env_path <- detected
          cat("  Auto-detected Python:", detected, "\n")
        }
      }

      # ── Ensure numeric types are numeric (JSON can return them as list) ───
      defaults$max_cost_usd         <- as.numeric(defaults$max_cost_usd         %||% 2.00)
      defaults$max_tokens           <- as.numeric(defaults$max_tokens           %||% 200000)
      defaults$max_retries_per_cell <- as.integer(defaults$max_retries_per_cell %||% 3)
      defaults$max_consec_fails     <- as.integer(defaults$max_consec_fails     %||% 3)
      defaults$review_every_cell    <- as.logical(defaults$review_every_cell    %||% FALSE)

      defaults
    },

    save_config = function(cfg) {
      # Ensure plain scalar types before writing
      cfg$max_cost_usd         <- as.numeric(cfg$max_cost_usd)
      cfg$max_tokens           <- as.numeric(cfg$max_tokens)
      cfg$max_retries_per_cell <- as.integer(cfg$max_retries_per_cell)
      cfg$max_consec_fails     <- as.integer(cfg$max_consec_fails)
      cfg$review_every_cell    <- as.logical(cfg$review_every_cell)

      self$config <- cfg
      jsonlite::write_json(cfg, self$config_path, pretty = TRUE, auto_unbox = TRUE)
      cat("✓ Config saved to", self$config_path, "\n")
    },

    get = function(key, default = NULL) {
      val <- self$config[[key]]
      if (is.null(val) || (length(val) == 1 && is.na(val))) default else val
    },

    # ── Per-run state ─────────────────────────────────────────────────────

    load_run_state = function(run_dir) {
      path <- file.path(run_dir, "session.json")
      if (!file.exists(path)) return(NULL)
      tryCatch(
        jsonlite::fromJSON(path, simplifyVector = FALSE),
        error = function(e) { cat("⚠ session.json parse error:", e$message, "\n"); NULL }
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
      lines <- tryCatch(
        readLines(path, warn = FALSE, encoding = "UTF-8"),
        error = function(e) {
          # Retry with native encoding on Windows
          tryCatch(readLines(path, warn = FALSE), error = function(e2) character(0))
        }
      )
      if (length(lines) > tail_n) lines <- tail(lines, tail_n)
      paste(lines, collapse = "\n")
    },

    send_command = function(run_dir, command) {
      path <- file.path(run_dir, "control.json")
      jsonlite::write_json(list(command = command), path, auto_unbox = TRUE)
      cat("  → Command:", command, "\n")
    },

    list_runs = function(runs_dir) {
      if (!dir.exists(runs_dir)) return(character(0))
      dirs <- list.dirs(runs_dir, recursive = FALSE, full.names = TRUE)
      dirs <- dirs[file.exists(file.path(dirs, "session.json"))]
      sort(dirs, decreasing = TRUE)
    },

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
  ),

  private = list(

    resolve_config_path = function(path) {
      if (!is.null(path) && nzchar(path)) return(path)
      # Check app directory first, then working directory
      candidates <- c(
        file.path(getwd(), "nb_session_config.json"),
        "nb_session_config.json"
      )
      for (p in candidates) {
        if (file.exists(p)) return(p)
      }
      # Default to app dir
      file.path(getwd(), "nb_session_config.json")
    },

    detect_python_fallback = function() {
      is_win <- .Platform$OS.type == "windows"

      python_in_env <- function(dir) {
        cands <- if (is_win)
          c(file.path(dir, "python.exe"), file.path(dir, "Scripts", "python.exe"))
        else
          c(file.path(dir, "bin", "python3"), file.path(dir, "bin", "python"))
        found <- cands[file.exists(cands)]
        if (length(found) > 0) normalizePath(found[1], winslash = "/") else NULL
      }

      # 1. Known project env (highest priority)
      known <- "C:/101_Code/PythonVEnvs/arcgis-ml"
      if (dir.exists(known)) {
        py <- python_in_env(known)
        if (!is.null(py)) return(py)
      }

      # 2. conda env list
      if (is_win) {
        conda <- unname(Sys.which(c("conda.exe", "conda")))
      } else {
        conda <- unname(Sys.which("conda"))
      }
      conda <- conda[nzchar(conda)]
      if (length(conda) > 0) {
        raw <- tryCatch(
          system2(conda[1], c("env", "list", "--json"), stdout = TRUE, stderr = FALSE),
          error = function(e) character(0)
        )
        if (length(raw) > 0) {
          info <- tryCatch(jsonlite::fromJSON(paste(raw, collapse = "\n"), simplifyVector = FALSE),
                           error = function(e) NULL)
          for (d in (info$envs %||% list())) {
            py <- python_in_env(d)
            if (!is.null(py)) return(py)
          }
        }
      }

      # 3. Common Anaconda locations on Windows
      if (is_win) {
        home <- gsub("\\\\", "/", Sys.getenv("USERPROFILE", normalizePath("~", winslash = "/")))
        roots <- c(
          paste0(home, "/anaconda3"), paste0(home, "/miniconda3"),
          paste0(home, "/AppData/Local/anaconda3"),
          "C:/ProgramData/anaconda3", "C:/anaconda3"
        )
        for (r in roots) {
          py <- python_in_env(r)
          if (!is.null(py)) return(py)
        }
      }

      # 4. PATH
      for (nm in c("python3", "python")) {
        p <- unname(Sys.which(nm))
        if (nzchar(p)) return(p)
      }
      NULL
    }
  )
)

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x
