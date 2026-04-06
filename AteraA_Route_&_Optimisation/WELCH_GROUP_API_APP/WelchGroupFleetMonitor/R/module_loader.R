# R/module_loader.R - Welch Group Fleet Monitor
# R6 Class for loading and managing modules

ModuleLoader <- R6::R6Class("ModuleLoader",
  public = list(
    config      = NULL,
    loaded_pkgs = character(0),

    initialize = function() {
      registry <- file.path("modules", "_module_registry.yml")
      if (!file.exists(registry)) stop("Module registry not found: ", registry)
      self$config <- yaml::read_yaml(registry)
      cat("  ✓ ModuleLoader: registry read,", length(self$config$modules), "modules found\n")
    },

    print = function(...) {
      cat("\n── ModuleLoader ────────────────────────────────\n")
      for (m in self$config$modules) {
        status <- if (isTRUE(m$module$enabled)) "✓" else "✗"
        cat(sprintf("  %s  %-25s  [%s]\n", status, m$module$name, m$module$id))
      }
      cat("────────────────────────────────────────────────\n\n")
      invisible(self)
    },

    load_packages = function() {
      cat("  ✓ Packages already loaded in global.R\n")
      invisible(self)
    },

    source_modules = function() {
      for (m in self$config$modules) {
        if (isTRUE(m$module$enabled)) {
          path <- m$module$file
          if (file.exists(path)) {
            source(path, local = FALSE)
            cat("  ✓ Sourced:", path, "\n")
          } else {
            warning("Module file not found: ", path)
          }
        }
      }
      invisible(self)
    },

    get_enabled_modules = function() {
      Filter(function(m) isTRUE(m$module$enabled), self$config$modules)
    }
  )
)
