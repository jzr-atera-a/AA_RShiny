# ============================================================================
# PYTHON BRIDGE - R6 CLASS
# Manages Python process lifecycle via processx
# Windows-aware: handles conda envs, anaconda paths, forward slashes
# ============================================================================

PythonBridge <- R6::R6Class(
  "PythonBridge",

  public = list(
    process     = NULL,
    run_dir     = NULL,
    log_path    = NULL,
    python_path = NULL,
    script_path = NULL,

    initialize = function(python_path = NULL) {
      raw <- if (is.null(python_path) || nchar(trimws(python_path)) == 0) {
        self$detect_python()
      } else {
        python_path
      }
      # Normalise slashes for Windows
      self$python_path <- gsub("\\\\", "/", raw)
      self$script_path <- file.path(getwd(), "python", "notebook_builder.py")
      cat("✓ PythonBridge ready:", self$python_path, "\n")
    },

    detect_python = function() {
      is_win <- .Platform$OS.type == "windows"

      # 1. PATH
      for (name in c("python3", "python")) {
        p <- unname(Sys.which(name))
        if (nchar(p) > 0) return(gsub("\\\\", "/", p))
      }

      # 2. Windows Anaconda / Miniconda common locations
      if (is_win) {
        user_home <- gsub("\\\\", "/", Sys.getenv("USERPROFILE",
                          normalizePath("~", winslash = "/")))
        candidates <- c(
          paste0(user_home, "/anaconda3/python.exe"),
          paste0(user_home, "/miniconda3/python.exe"),
          paste0(user_home, "/AppData/Local/anaconda3/python.exe"),
          paste0(user_home, "/AppData/Local/miniconda3/python.exe"),
          "C:/ProgramData/anaconda3/python.exe",
          "C:/ProgramData/miniconda3/python.exe",
          "C:/anaconda3/python.exe",
          "C:/miniconda3/python.exe"
        )
        for (p in candidates) {
          if (file.exists(p)) {
            cat("  Auto-detected Python:", p, "\n")
            return(p)
          }
        }
      }

      # 3. Last resort
      if (is_win) "python.exe" else "python3"
    },

    # ── Validate python path ───────────────────────────────────────────────

    validate = function(py_path = NULL) {
      path <- gsub("\\\\", "/", if (!is.null(py_path)) py_path else self$python_path)
      result <- tryCatch({
        out <- processx::run(path, args = c("-c", "import sys; print(sys.version)"),
                             timeout = 10, error_on_status = FALSE)
        if (out$status == 0) {
          list(ok = TRUE,  msg = paste("Python:", trimws(out$stdout)))
        } else {
          list(ok = FALSE, msg = paste("stderr:", trimws(out$stderr)))
        }
      }, error = function(e) list(ok = FALSE, msg = e$message))
      result
    },

    # ── Launch notebook builder as subprocess ──────────────────────────────

    launch = function(spec, run_dir, api_key, model, context_dir,
                      max_cost, max_tokens, max_retries, max_consec_fails,
                      review_every, kernel_name = "python3") {

      self$run_dir  <- run_dir
      self$log_path <- file.path(run_dir, "run.log")
      dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

      cfg <- list(
        spec             = spec,
        run_dir          = gsub("\\\\", "/", run_dir),
        api_key          = api_key,
        model            = model,
        context_dir      = gsub("\\\\", "/", context_dir),
        max_cost_usd     = max_cost,
        max_tokens       = max_tokens,
        max_retries      = max_retries,
        max_consec_fails = max_consec_fails,
        review_every     = review_every,
        kernel_name      = kernel_name
      )
      launch_cfg_path <- file.path(run_dir, "launch_config.json")
      jsonlite::write_json(cfg, launch_cfg_path, pretty = TRUE, auto_unbox = TRUE)

      self$process <- processx::process$new(
        command = self$python_path,
        args    = c(self$script_path, "--launch-config",
                    gsub("\\\\", "/", launch_cfg_path)),
        stdout  = self$log_path,
        stderr  = self$log_path,
        cleanup = FALSE
      )
      cat("✓ Python process launched PID:", self$process$get_pid(), "\n")
      invisible(self)
    },

    # ── Resume existing run ────────────────────────────────────────────────

    resume = function(run_dir, api_key) {
      self$run_dir  <- run_dir
      self$log_path <- file.path(run_dir, "run.log")

      cfg_path <- file.path(run_dir, "launch_config.json")
      if (file.exists(cfg_path)) {
        cfg <- jsonlite::fromJSON(cfg_path)
        cfg$api_key <- api_key
        jsonlite::write_json(cfg, cfg_path, pretty = TRUE, auto_unbox = TRUE)
      }

      jsonlite::write_json(list(command = "run"),
                           file.path(run_dir, "control.json"), auto_unbox = TRUE)

      self$process <- processx::process$new(
        command = self$python_path,
        args    = c(self$script_path, "--launch-config",
                    gsub("\\\\", "/", cfg_path), "--resume"),
        stdout  = self$log_path,
        stderr  = self$log_path,
        cleanup = FALSE
      )
      cat("✓ Python process resumed PID:", self$process$get_pid(), "\n")
      invisible(self)
    },

    is_running = function() {
      !is.null(self$process) && self$process$is_alive()
    },

    stop_process = function() {
      if (self$is_running()) { self$process$kill(); cat("✓ Python process killed\n") }
    },

    get_pid = function() {
      if (!is.null(self$process)) self$process$get_pid() else NA
    }
  )
)
