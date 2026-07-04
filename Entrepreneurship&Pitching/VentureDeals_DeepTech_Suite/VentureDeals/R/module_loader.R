# R/module_loader.R — Module Loader for Venture Deals DeepTech Suite
library(R6)
library(yaml)

ModuleLoader <- R6Class(
  "ModuleLoader",
  public = list(
    registry    = NULL,
    modules_dir = "modules",

    initialize = function() {
      registry_path <- file.path(self$modules_dir, "_module_registry.yml")
      if (!file.exists(registry_path)) stop("Module registry not found at: ", registry_path)
      self$registry <- yaml::read_yaml(registry_path)
      cat("\n📦 Module Loader:\n")
      cat("   Total:", length(self$registry$modules), "\n")
      cat("   Enabled:", sum(sapply(self$registry$modules, function(m) m$enabled)), "\n\n")
    },

    get_enabled_modules = function() {
      modules <- self$registry$modules
      enabled <- modules[sapply(modules, function(m) isTRUE(m$enabled))]
      sorted  <- enabled[order(sapply(enabled, function(m) m$priority %||% 999))]
      lapply(names(sorted), function(id) list(module = c(list(id = id), sorted[[id]])))
    },

    print = function() {
      cat("\n╔═══════════════════════════════════════════╗\n")
      cat("║  Venture Deals: DeepTech Fundraising Suite ║\n")
      cat("╚═══════════════════════════════════════════╝\n\n")
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
