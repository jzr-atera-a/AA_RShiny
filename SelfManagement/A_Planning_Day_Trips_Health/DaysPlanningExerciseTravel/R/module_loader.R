# R/module_loader.R
# ModuleLoader (R6): finds, orders and loads the sub-tab files.
# ===============================================================================
# Layout:  modules/<Tab group>/<sub_tab_id>.R   - ONE file per sub-tab (header + <id>_ui + <id>_server)
#          modules/_module_registry.yml          - sidebar groups/sections, enabled flags, priority
# Every sub-tab file starts with a header that replaces the old manifest.yml:
#
#   # ---- module ----------------------------------------------
#   # id:           schedule_browse          (must equal the file name)
#   # name:         Browse Data
#   # label:        (optional: menu text when it differs from name)
#   # icon:         table
#   # description:  one line
#   # packages:     shiny, shinydashboard, DT
#   # api_required: claude                   (optional, informational)
#   # api_optional: bigquery                 (optional, informational)
#   # -----------------------------------------------------------
#
# Files and folders whose name starts with "_" are ignored, so templates and parked tabs can stay in the tree.

library(R6)
library(yaml)

`%||%` <- function(x, y) if (is.null(x)) y else x

module_read_header <- function(path) {
  lines <- readLines(path, n = 40, warn = FALSE, encoding = "UTF-8")
  start <- grep("^# ---- module", lines)
  if (!length(start)) return(NULL)
  rest <- lines[seq_len(length(lines)) > start[1]]
  end <- grep("^# -{20,}\\s*$", rest)
  if (length(end)) rest <- rest[seq_len(end[1] - 1)]
  m <- regmatches(rest, regexec("^#\\s*([a-z_]+):\\s*(.*?)\\s*$", rest, perl = TRUE))
  m <- m[lengths(m) == 3]
  stats::setNames(lapply(m, `[`, 3), vapply(m, `[`, "", 2))
}

module_split_list <- function(x) { x <- trimws(strsplit(x %||% "", ",", fixed = TRUE)[[1]]); x[nzchar(x)] }

ModuleLoader <- R6::R6Class(
  "ModuleLoader",

  public = list(
    modules = list(),
    registry = NULL,
    loaded_packages = character(0),
    modules_dir = "modules",

    initialize = function(modules_dir = "modules") {
      self$modules_dir <- modules_dir
      self$load_registry()
      self$discover_modules()
      self$check_placement()
    },

    load_registry = function() {
      registry_path <- file.path(self$modules_dir, "_module_registry.yml")
      if (!file.exists(registry_path)) stop("Module registry not found: ", registry_path)
      self$registry <- yaml::read_yaml(registry_path)
      cat("✓ Loaded module registry\n")
    },

    # modules/<Tab group>/<id>.R only: exactly two path parts below modules/, nothing starting with "_"
    discover_modules = function() {
      groups <- list.dirs(self$modules_dir, recursive = FALSE, full.names = TRUE)
      groups <- sort(groups[!grepl("^_", basename(groups))])
      found <- list()
      for (g in groups) {
        files <- sort(list.files(g, pattern = "\\.R$", full.names = TRUE))
        for (f in files[!grepl("^_", basename(files))]) {
          h <- module_read_header(f)
          file_id <- sub("\\.R$", "", basename(f))
          if (is.null(h) || is.null(h$id)) { warning("Skipped (no module header): ", f, call. = FALSE); next }
          if (!identical(h$id, file_id)) stop("Module id '", h$id, "' does not match its file name: ", f, call. = FALSE)
          if (!is.null(found[[h$id]])) stop("Duplicate module id '", h$id, "': ", found[[h$id]]$module$file, " and ", f, call. = FALSE)
          reg <- self$registry$modules[[h$id]]
          found[[h$id]] <- list(module = list(
            id = h$id, name = h$name %||% h$id, description = h$description %||% "",
            enabled = isTRUE(reg$enabled %||% TRUE), file = f, path = dirname(f),
            menu = list(label = h$label %||% h$name %||% h$id, icon = h$icon %||% "circle", tabname = h$id),
            dependencies = list(packages = module_split_list(h$packages)),
            api = list(required = module_split_list(h$api_required), optional = module_split_list(h$api_optional))))
        }
      }
      prio <- vapply(found, function(m) as.numeric(self$registry$modules[[m$module$id]]$priority %||% 99), 0)
      self$modules <- found[order(prio)]          # stable: ties keep folder/file order
      cat("✓ Discovered", length(self$modules), "modules\n")
    },

    # Warn (never fail) about anything that would silently drop a tab from the app.
    check_placement = function() {
      ids <- names(self$modules); enabled <- self$enabled_ids()
      grouped <- unique(unlist(lapply(self$registry$groups, function(g) g$modules)))
      sectioned <- unlist(lapply(self$registry$groups, function(g) lapply(g$sections, function(s) unlist(s$modules))))
      note <- function(what, x) if (length(x)) warning(what, ": ", paste(x, collapse = ", "), call. = FALSE)
      note("Sub-tab file(s) not placed in any sidebar group (they will not be shown)", setdiff(enabled, grouped))
      note("Sidebar group lists id(s) with no file", setdiff(grouped, ids))
      note("Sidebar section lists id(s) with no file", setdiff(unique(sectioned), ids))
      note("Sidebar section lists id(s) missing from its group's modules list", setdiff(unique(sectioned), grouped))
      note("Registry 'modules:' lists id(s) with no file", setdiff(names(self$registry$modules), ids))
      invisible(TRUE)
    },

    get_enabled_modules = function() Filter(function(m) isTRUE(m$module$enabled), self$modules),
    enabled_ids = function() names(self$get_enabled_modules()),

    load_packages = function() {
      all_packages <- unique(unlist(lapply(self$get_enabled_modules(), function(m) m$module$dependencies$packages)))
      for (pkg in setdiff(all_packages, self$loaded_packages)) {
        if (!requireNamespace(pkg, quietly = TRUE)) {
          warning("Package not installed: ", pkg)
        } else {
          suppressPackageStartupMessages(library(pkg, character.only = TRUE))
          self$loaded_packages <- c(self$loaded_packages, pkg)
        }
      }
      cat("✓ Loaded packages:", paste(self$loaded_packages, collapse = ", "), "\n")
    },

    # Each enabled sub-tab file is sourced once into the global environment.
    source_modules = function() {
      for (m in self$get_enabled_modules()) {
        id <- m$module$id
        source(m$module$file, local = .GlobalEnv)
        missing <- Filter(function(fn) !exists(fn, envir = .GlobalEnv, mode = "function"), paste0(id, c("_ui", "_server")))
        if (length(missing)) warning("Module file ", m$module$file, " does not define: ", paste(missing, collapse = ", "), call. = FALSE)
      }
      cat("✓ Loaded", length(self$get_enabled_modules()), "sub-tab files\n")
    },

    ui_function = function(id) get0(paste0(id, "_ui"), envir = .GlobalEnv, mode = "function"),
    server_function = function(id) get0(paste0(id, "_server"), envir = .GlobalEnv, mode = "function"),

    print = function() {
      enabled <- self$get_enabled_modules()
      cat("\n\U0001F4E6 Module Loader Status:\n")
      cat("   Total modules:", length(self$modules), "\n")
      cat("   Enabled:", length(enabled), "\n")
      by_group <- split(vapply(enabled, function(m) m$module$name, ""), vapply(enabled, function(m) basename(m$module$path), ""))
      for (g in names(by_group)) cat("   ✓ ", g, ": ", paste(by_group[[g]], collapse = ", "), "\n", sep = "")
      disabled <- Filter(function(m) !isTRUE(m$module$enabled), self$modules)
      if (length(disabled)) cat("   ✗ Disabled:", paste(vapply(disabled, function(m) m$module$name, ""), collapse = ", "), "\n")
      cat("\n")
      invisible(self)
    }
  )
)
