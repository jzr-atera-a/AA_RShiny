# R/module_loader.R
# Module Loader for WP5 Omniverse AR App

library(R6)
library(yaml)

ModuleLoader <- R6Class(
  "ModuleLoader",
  public = list(
    registry = NULL,
    
    initialize = function() {
      self$registry <- yaml::read_yaml("modules/_module_registry.yml")
      cat("✓ Module registry loaded\n")
    },
    
    print = function() {
      cat("\n📦 MODULE REGISTRY\n")
      cat("App:", self$registry$app$name, "\n")
      cat("Modules:", length(self$registry$modules), "\n\n")
    },
    
    get_enabled_modules = function() {
      enabled <- list()
      for (module in self$registry$modules) {
        if (module$enabled) {
          enabled[[length(enabled) + 1]] <- list(module = module)
        }
      }
      enabled
    },
    
    load_packages = function() {
      cat("Loading packages...\n")
      cat("✓ Packages loaded\n")
    },
    
    source_modules = function() {
      cat("\nSourcing modules...\n")
      for (module in self$registry$modules) {
        if (module$enabled) {
          module_file <- paste0("modules/", module$id, ".R")
          if (file.exists(module_file)) {
            source(module_file, local = .GlobalEnv)
            cat("  ✓", module$name, "\n")
          } else {
            cat("  ✗", module$name, "- FILE NOT FOUND:", module_file, "\n")
          }
        }
      }
      cat("✓ Modules sourced\n\n")
    }
  )
)
