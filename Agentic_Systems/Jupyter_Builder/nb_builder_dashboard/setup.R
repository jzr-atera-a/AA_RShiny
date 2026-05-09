# ============================================================================
# SETUP — run once before launching the app
#
# Usage (in RStudio console):
#   source("setup.R")
#   setup("C:/101_Code/PythonVEnvs/arcgis-ml")   # explicit env
#
# From terminal:
#   Rscript setup.R "C:/101_Code/PythonVEnvs/arcgis-ml"
# ============================================================================

setup <- function(python_env_path = NULL) {

  cat("\n╔══════════════════════════════════════════════════════╗\n")
  cat("║         NOTEBOOK BUILDER — SETUP                    ║\n")
  cat("╚══════════════════════════════════════════════════════╝\n\n")

  # ── 1. R packages ──────────────────────────────────────────────────────
  cat("── Step 1: R packages ────────────────────────────────\n")
  pkgs <- c("shiny","shinydashboard","shinyjs","R6","yaml","purrr",
            "httr","jsonlite","processx","fs","DT")
  for (pkg in pkgs) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      cat("  Installing:", pkg, "... ")
      tryCatch({
        install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
        cat("✓\n")
      }, error = function(e) cat("✗ FAILED:", e$message, "\n"))
    } else {
      cat("  ✓", pkg, "\n")
    }
  }

  # ── 2. Resolve Python executable ───────────────────────────────────────
  cat("\n── Step 2: Python environment ────────────────────────\n")
  python_exe <- resolve_python(python_env_path)
  if (is.null(python_exe)) {
    cat("✗ Could not find Python. Pass the env path explicitly:\n")
    cat('  setup("C:/101_Code/PythonVEnvs/arcgis-ml")\n\n')
    return(invisible(FALSE))
  }
  cat("  Using Python:", python_exe, "\n")

  # FIX 1: write a temp script instead of using -c (avoids semicolon/quoting
  #         issues in Windows cmd.exe)
  tmp_py <- tempfile(fileext = ".py")
  writeLines("import sys; print(sys.version)", tmp_py)
  test <- tryCatch(
    system2(python_exe, args = tmp_py, stdout = TRUE, stderr = TRUE),
    error = function(e) NULL
  )
  file.remove(tmp_py)
  if (!is.null(test) && length(test) > 0 && !grepl("Error|error", test[1]))
    cat("  Python version:", trimws(test[1]), "\n")
  else
    cat("  ⚠ Could not read version — but path looks valid.\n")

  # ── 3. Python packages ─────────────────────────────────────────────────
  cat("\n── Step 3: Python packages ───────────────────────────\n")
  py_pkgs <- c("anthropic", "jupyter_client", "ipykernel")
  for (pkg in py_pkgs) {
    cat("  Installing:", pkg, "... ")
    result <- system2(
      python_exe,
      args   = c("-m", "pip", "install", pkg, "--quiet",
                 "--no-warn-script-location"),
      stdout = TRUE, stderr = TRUE
    )
    status <- attr(result, "status")
    if (is.null(status) || status == 0 ||
        any(grepl("already satisfied|Successfully", result, ignore.case = TRUE))) {
      cat("✓\n")
    } else {
      cat("⚠\n")
      cat(paste(result, collapse = "\n"), "\n")
    }
  }

  # ── 4. Register ipykernel ──────────────────────────────────────────────
  cat("\n── Step 4: Register ipykernel ────────────────────────\n")
  env_label   <- if (!is.null(python_env_path)) basename(python_env_path) else "default"
  # FIX 2: kernel name AND display-name both use only safe chars (no spaces,
  #         no parens) so cmd.exe doesn't split the argument.
  kernel_name  <- paste0("nb_builder_", gsub("[^a-z0-9]", "_", tolower(env_label)))
  display_name <- kernel_name   # same simple string — no spaces/parens

  result <- system2(
    python_exe,
    args   = c("-m", "ipykernel", "install", "--user",
               "--name",         kernel_name,
               "--display-name", display_name),
    stdout = TRUE, stderr = TRUE
  )
  cat("  Kernel name:", kernel_name, "\n")
  if (any(grepl("Installed|kernelspec", result, ignore.case = TRUE))) {
    cat("  ✓ Kernel registered\n")
  } else {
    cat(paste(result, collapse = "\n"), "\n")
  }

  # ── 5. Save config so Tab 1 is pre-filled ──────────────────────────────
  cat("\n── Step 5: Pre-populate Settings config ──────────────\n")
  if (!requireNamespace("jsonlite", quietly = TRUE))
    install.packages("jsonlite", repos = "https://cloud.r-project.org", quiet = TRUE)

  config_path  <- "nb_session_config.json"
  existing_cfg <- if (file.exists(config_path)) {
    tryCatch(jsonlite::fromJSON(config_path), error = function(e) list())
  } else list()

  existing_cfg$python_env_path <- python_exe
  existing_cfg$kernel_name     <- kernel_name
  jsonlite::write_json(existing_cfg, config_path, pretty = TRUE, auto_unbox = TRUE)
  cat("  ✓ Saved to", config_path, "\n")
  cat("  Python :", python_exe, "\n")
  cat("  Kernel :", kernel_name, "\n")

  cat("\n╔══════════════════════════════════════════════════════╗\n")
  cat("║  ✅  Setup complete!                                 ║\n")
  cat("║                                                      ║\n")
  cat("║  Launch: shiny::runApp()                             ║\n")
  cat("║  Tab 1 > Validate Python to confirm before running.  ║\n")
  cat("╚══════════════════════════════════════════════════════╝\n\n")
  invisible(TRUE)
}


# ── Python resolver ───────────────────────────────────────────────────────────

resolve_python <- function(env_path = NULL) {
  is_win <- .Platform$OS.type == "windows"

  python_in_env <- function(dir) {
    candidates <- if (is_win)
      c(file.path(dir, "python.exe"), file.path(dir, "Scripts", "python.exe"))
    else
      c(file.path(dir, "bin", "python3"), file.path(dir, "bin", "python"))
    found <- candidates[file.exists(candidates)]
    if (length(found) > 0) normalizePath(found[1], winslash = "/") else NULL
  }

  # 1. Explicit path (directory or direct exe)
  if (!is.null(env_path) && nchar(trimws(env_path)) > 0) {
    env_path <- normalizePath(env_path, winslash = "/", mustWork = FALSE)
    if (dir.exists(env_path)) {
      py <- python_in_env(env_path)
      if (!is.null(py)) { cat("  Found Python in env dir:", py, "\n"); return(py) }
    }
    if (file.exists(env_path)) {
      cat("  Using explicit exe:", env_path, "\n"); return(env_path)
    }
    cat("  ⚠ Path not found:", env_path, "\n")
  }

  # 2. conda env list
  conda_exe <- unname(Sys.which(if (is_win) c("conda.exe","conda") else "conda"))
  conda_exe <- conda_exe[nchar(conda_exe) > 0]
  if (length(conda_exe) > 0) {
    cat("  conda found — scanning envs...\n")
    raw <- tryCatch(
      system2(conda_exe[1], c("env","list","--json"), stdout = TRUE, stderr = FALSE),
      error = function(e) character(0)
    )
    if (length(raw) > 0) {
      info <- tryCatch(jsonlite::fromJSON(paste(raw, collapse="\n")), error=function(e) NULL)
      for (d in (info$envs %||% character(0))) {
        py <- python_in_env(d)
        if (!is.null(py)) { cat("  Found conda Python:", py, "\n"); return(py) }
      }
    }
  }

  # 3. Common Windows Anaconda locations
  if (is_win) {
    home <- gsub("\\\\","/", Sys.getenv("USERPROFILE", normalizePath("~",winslash="/")))
    roots <- c(
      paste0(home,"/anaconda3"), paste0(home,"/miniconda3"),
      paste0(home,"/AppData/Local/anaconda3"),
      paste0(home,"/AppData/Local/miniconda3"),
      "C:/ProgramData/anaconda3","C:/ProgramData/miniconda3",
      "C:/anaconda3","C:/miniconda3"
    )
    for (r in roots) {
      py <- python_in_env(r)
      if (!is.null(py)) { cat("  Found Anaconda Python:", py, "\n"); return(py) }
    }
  }

  # 4. PATH fallback
  for (name in c("python3","python")) {
    p <- unname(Sys.which(name))
    if (nchar(p) > 0) { cat("  Found on PATH:", p, "\n"); return(p) }
  }

  NULL
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x


# ── Auto-run ──────────────────────────────────────────────────────────────────

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  setup(args[1])
} else {
  known <- "C:/101_Code/PythonVEnvs/arcgis-ml"
  if (dir.exists(known)) {
    cat("  Detected env at:", known, "\n\n")
    setup(known)
  } else {
    setup()
  }
}
