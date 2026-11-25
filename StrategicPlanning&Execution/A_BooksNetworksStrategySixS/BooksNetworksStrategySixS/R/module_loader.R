# R/module_loader.R
# ============================================================
# Finds, orders and loads the sub-tabs ("modules") of the app.
#
#   * One file per sub-tab:  modules/<Tab group>/<id>.R
#     It holds a small header (below), then <id>_ui(id) and <id>_server(id, api_manager).
#
#       # ---- module ----------------------------------------------
#       # id:           generate_diagram
#       # name:         Generate Diagram
#       # label:        (optional: sidebar / tab text when it differs from the name)
#       # icon:         magic
#       # description:  one line
#       # packages:     shiny, shinydashboard, DT
#       # api_required: claude
#       # api_optional: bigquery
#       # -----------------------------------------------------------
#
#   * Hubs (sidebar entries that only hold horizontal sub-tabs) have no file: they come from TD_HUBS in R/utils_td_hubs.R.
#   * modules/_module_registry.yml groups the sidebar and gives each id its enabled flag and sort priority.
#
# To add a sub-tab: drop <id>.R into its tab-group folder, then list the id under a hub (R/utils_td_hubs.R) or a group (registry).
# ============================================================

`%||%` <- function(x, y) if (is.null(x)) y else x

MODULES_DIR <- "modules"
MODULE_REGISTRY_FILE <- file.path(MODULES_DIR, "_module_registry.yml")

# Reads the "# key: value" lines of a sub-tab file's header block.
read_module_header <- function(path, max_lines = 40L) {
  lines <- readLines(path, n = max_lines, warn = FALSE)
  start <- grep("^# ---- module", lines)[1]
  if (is.na(start)) return(NULL)
  rest <- lines[-seq_len(start)]
  end <- grep("^# -{20,}\\s*$", rest)[1]
  if (!is.na(end)) rest <- rest[seq_len(end - 1L)]
  kv <- regmatches(rest, regexec("^#\\s*([a-z_]+):\\s*(.*?)\\s*$", rest, perl = TRUE))
  kv <- Filter(function(x) length(x) == 3L, kv)
  out <- stats::setNames(lapply(kv, `[[`, 3L), vapply(kv, `[[`, "", 2L))
  split_list <- function(x) { v <- trimws(strsplit(x %||% "", ",", fixed = TRUE)[[1]]); v[nzchar(v)] }
  for (k in c("packages", "api_required", "api_optional")) out[[k]] <- split_list(out[[k]])
  out
}

ModuleLoader <- R6::R6Class(
  "ModuleLoader",

  public = list(
    modules = list(),          # id -> list(id, name, label, icon, description, group, packages, file, hub, enabled, priority)
    registry = NULL,
    loaded_packages = character(0),

    initialize = function() {
      if (!file.exists(MODULE_REGISTRY_FILE)) stop("Module registry not found: ", MODULE_REGISTRY_FILE)
      self$registry <- yaml::read_yaml(MODULE_REGISTRY_FILE)
      cat("✓ Loaded module registry\n")
      self$discover_modules()
    },

    discover_modules = function() {
      found <- list()
      add <- function(m) {
        if (!is.null(found[[m$id]])) stop("Two sub-tabs share the id '", m$id, "': ", found[[m$id]]$file %||% "(hub)", " and ", m$file %||% "(hub)")
        reg <- self$registry$modules[[m$id]]
        m$enabled <- isTRUE(reg$enabled %||% TRUE)
        m$priority <- as.numeric(reg$priority %||% 99)
        m$label <- m$label %||% m$name
        found[[m$id]] <<- m
      }

      # sub-tab files: modules/<Tab group>/<id>.R (files or folders starting with "_" are ignored)
      files <- list.files(MODULES_DIR, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
      rel <- substring(files, nchar(MODULES_DIR) + 2L)
      ok <- lengths(strsplit(rel, "/", fixed = TRUE)) == 2L & !grepl("(^|/)_", rel)
      for (f in sort(files[ok])) {
        h <- read_module_header(f)
        id <- sub("\\.R$", "", basename(f))
        if (is.null(h) || is.null(h$id)) { warning("No module header in ", f, " - file skipped"); next }
        if (!identical(h$id, id)) stop("The id in the header of ", f, " is '", h$id, "': it must equal the file name")
        add(list(id = id, name = h$name %||% id, label = h$label, icon = h$icon %||% "circle", description = h$description %||% "",
                 group = basename(dirname(f)), packages = h$packages, api_required = h$api_required, api_optional = h$api_optional,
                 file = f, hub = FALSE))
      }

      # hubs: defined in R/utils_td_hubs.R, no file of their own
      hubs <- if (exists("TD_HUBS", inherits = TRUE)) get("TD_HUBS", inherits = TRUE) else list()
      for (id in names(hubs)) {
        h <- hubs[[id]]
        add(list(id = id, name = h$label %||% h$title, label = h$label %||% h$title, icon = h$icon %||% "folder", description = h$blurb %||% "",
                 group = NA_character_, packages = c("shiny", "shinydashboard"), file = NULL, hub = TRUE))
      }

      self$modules <- found[order(vapply(found, function(m) m$priority, 0))]
      cat("✓ Discovered", length(self$modules), "modules (", sum(!vapply(self$modules, function(m) m$hub, TRUE)), "sub-tab files,",
          sum(vapply(self$modules, function(m) m$hub, TRUE)), "hubs )\n")
      self$check_placement(hubs)
      invisible(self)
    },

    # Says so when the files, the hubs and the registry disagree (a typo in an id would otherwise just make a tab vanish).
    check_placement = function(hubs) {
      ids <- names(self$modules)
      in_hub <- unlist(lapply(hubs, function(h) vapply(h$children %||% list(), function(x) x$id, "")), use.names = FALSE)
      in_group <- unlist(lapply(self$registry$groups %||% list(), function(g) unlist(g$modules)), use.names = FALSE)
      note <- function(what, x) if (length(x)) cat("⚠️  [Modules]", what, paste(x, collapse = ", "), "\n")
      note("sub-tab file(s) not placed in any hub or sidebar group (not shown):", setdiff(ids, c(in_hub, in_group)))
      note("listed in a hub or sidebar group but no such sub-tab file:", setdiff(c(in_hub, in_group), ids))
      note("in the registry's modules: list but no such sub-tab:", setdiff(names(self$registry$modules), ids))
      invisible(self)
    },

    get_enabled_modules = function() Filter(function(m) isTRUE(m$enabled), self$modules),
    enabled_ids = function() names(self$get_enabled_modules()),

    load_packages = function() {
      pkgs <- unique(unlist(lapply(self$get_enabled_modules(), function(m) m$packages)))
      for (pkg in setdiff(pkgs, self$loaded_packages)) {
        if (!requireNamespace(pkg, quietly = TRUE)) { warning("Package not installed: ", pkg); next }
        suppressPackageStartupMessages(library(pkg, character.only = TRUE))
        self$loaded_packages <- c(self$loaded_packages, pkg)
      }
      cat("✓ Loaded packages:", paste(self$loaded_packages, collapse = ", "), "\n")
      invisible(self)
    },

    # Each sub-tab file defines <id>_ui and <id>_server in the global environment (hubs and shared helpers look them up by name).
    source_modules = function() {
      mods <- Filter(function(m) !m$hub, self$get_enabled_modules())
      for (m in mods) {
        source(m$file, local = .GlobalEnv)
        for (fn in paste0(m$id, c("_ui", "_server")))
          if (!exists(fn, envir = .GlobalEnv, mode = "function")) warning(m$file, " does not define ", fn, "()")
      }
      cat("✓ Loaded", length(mods), "sub-tab files\n")
      invisible(self)
    },

    # UI / server of one module (NULL when the file does not define it). A hub draws its children and has no server logic.
    ui_function = function(id) {
      m <- self$modules[[id]]
      if (isTRUE(m$hub)) return(function(id) td_hub_ui(id))
      get0(paste0(id, "_ui"), envir = .GlobalEnv, mode = "function")
    },
    server_function = function(id) {
      if (isTRUE(self$modules[[id]]$hub)) return(NULL)
      get0(paste0(id, "_server"), envir = .GlobalEnv, mode = "function")
    },

    print = function() {
      enabled <- self$get_enabled_modules()
      disabled <- Filter(function(m) !isTRUE(m$enabled), self$modules)
      cat("\n\U0001F4E6 Module Loader Status:\n")
      cat("   Total modules:", length(self$modules), "| enabled:", length(enabled), "\n")
      by_group <- split(vapply(enabled, function(m) m$name, ""), vapply(enabled, function(m) if (m$hub) "(hubs)" else m$group, ""))
      for (g in names(by_group)) cat(sprintf("   ✓ %-20s %s\n", g, paste(by_group[[g]], collapse = ", ")))
      if (length(disabled)) cat("   ✗ disabled:", paste(vapply(disabled, function(m) m$name, ""), collapse = ", "), "\n")
      cat("\n")
      invisible(self)
    }
  )
)
