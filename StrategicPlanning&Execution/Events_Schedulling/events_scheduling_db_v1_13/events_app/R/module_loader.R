# R/module_loader.R
# ModuleLoader R6 Class
# =====================

library(R6)
library(yaml)
library(purrr)

ModuleLoader <- R6::R6Class(
  "ModuleLoader",

  public = list(
    modules         = list(),
    registry        = NULL,
    loaded_packages = character(0),

    initialize = function() {
      self$load_registry()
      self$discover_modules()
    },

    load_registry = function() {
      registry_path <- "modules/_module_registry.yml"
      if (!file.exists(registry_path)) stop("Module registry not found: ", registry_path)
      self$registry <- yaml::read_yaml(registry_path)
      cat("✓ Loaded module registry\n")
    },

    discover_modules = function() {
      module_dirs <- list.dirs("modules", recursive = FALSE)
      module_dirs <- module_dirs[!grepl("^_", basename(module_dirs))]

      for (dir in module_dirs) {
        manifest_path <- file.path(dir, "manifest.yml")
        if (!file.exists(manifest_path)) next

        manifest  <- yaml::read_yaml(manifest_path)
        module_id <- manifest$module$id

        enabled <- if (!is.null(self$registry$modules[[module_id]]$enabled)) {
          self$registry$modules[[module_id]]$enabled
        } else {
          manifest$module$enabled %||% TRUE
        }

        manifest$module$enabled <- enabled
        manifest$module$path    <- dir
        self$modules[[module_id]] <- manifest
      }

      self$modules <- self$modules[order(sapply(self$modules, function(m) {
        self$registry$modules[[m$module$id]]$priority %||% 99
      }))]

      cat("✓ Discovered", length(self$modules), "modules\n")
    },

    get_enabled_modules = function() {
      purrr::keep(self$modules, ~ .x$module$enabled)
    },

    load_packages = function() {
      enabled_modules <- self$get_enabled_modules()
      all_packages <- unique(unlist(lapply(enabled_modules, function(m) {
        m$module$dependencies$packages
      })))

      for (pkg in all_packages) {
        if (!pkg %in% self$loaded_packages) {
          if (!requireNamespace(pkg, quietly = TRUE)) {
            warning("Package not installed: ", pkg)
          } else {
            suppressPackageStartupMessages(library(pkg, character.only = TRUE))
            self$loaded_packages <- c(self$loaded_packages, pkg)
          }
        }
      }
      cat("✓ Loaded packages:", paste(self$loaded_packages, collapse = ", "), "\n")
    },

    source_modules = function() {
      enabled_modules <- self$get_enabled_modules()
      for (module in enabled_modules) {
        ui_path     <- file.path(module$module$path, "ui.R")
        server_path <- file.path(module$module$path, "server.R")
        if (file.exists(ui_path))     source(ui_path,     local = .GlobalEnv)
        if (file.exists(server_path)) source(server_path, local = .GlobalEnv)
        cat("✓ Loaded module:", module$module$id, "\n")
      }
    },

    print = function() {
      cat("\n📦 Module Loader Status:\n")
      cat("   Total modules:", length(self$modules), "\n")
      enabled  <- self$get_enabled_modules()
      cat("   Enabled:", length(enabled), "\n\n")
      if (length(enabled) > 0) {
        cat("   Enabled modules:\n")
        for (m in enabled) cat("   ✓", m$module$name, "\n")
      }
      disabled <- purrr::keep(self$modules, ~ !.x$module$enabled)
      if (length(disabled) > 0) {
        cat("\n   Disabled modules:\n")
        for (m in disabled) cat("   ✗", m$module$name, "\n")
      }
      cat("\n")
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
