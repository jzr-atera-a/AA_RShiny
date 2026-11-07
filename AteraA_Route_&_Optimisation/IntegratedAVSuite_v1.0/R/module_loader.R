# R/module_loader.R
# Module Loader R6 Class - Flat Structure (no subdirectories, no manifest.yml)
# Loads modules directly from modules/ folder based on _module_registry.yml

library(R6)
library(yaml)
library(purrr)

ModuleLoader <- R6Class(
  "ModuleLoader",
  
  public = list(
    registry = NULL,
    modules_dir = "modules",
    
    initialize = function() {
      registry_path <- file.path(self$modules_dir, "_module_registry.yml")
      
      if (!file.exists(registry_path)) {
        stop("Module registry not found at: ", registry_path)
      }
      
      self$registry <- yaml::read_yaml(registry_path)
      
      cat("\n📦 Module Loader Status:\n")
      cat("   Total modules:", length(self$registry$modules), "\n")
      cat("   Enabled:", sum(sapply(self$registry$modules, function(m) m$enabled)), "\n\n")
    },
    
    get_enabled_modules = function() {
      modules <- self$registry$modules
      
      enabled <- modules[sapply(modules, function(m) isTRUE(m$enabled))]
      
      sorted <- enabled[order(sapply(enabled, function(m) m$priority %||% 999))]
      
      lapply(names(sorted), function(id) {
        list(
          module = c(list(id = id), sorted[[id]])
        )
      })
    },
    
    load_packages = function() {
      cat("📚 Loading packages...\n")
      
      required_pkgs <- c(
        "shiny", "shinydashboard", "R6", "yaml", "purrr", "magrittr", "dplyr",
        "sf", "osmdata", "dodgr", "bigrquery", "leaflet", "htmltools",
        "DT", "plotly", "jsonlite", "httr"
      )
      
      for (pkg in required_pkgs) {
        if (!requireNamespace(pkg, quietly = TRUE)) {
          cat("   ⚠ Missing package:", pkg, "\n")
        }
      }
      
      cat("✓ Package check complete\n\n")
    },
    
    source_modules = function() {
      cat("📂 Loading modules...\n")
      
      enabled_modules <- self$get_enabled_modules()
      
      if (length(enabled_modules) == 0) {
        cat("   ⚠ No enabled modules found\n\n")
        return()
      }
      
      cat("   Enabled modules:\n")
      
      for (mod_info in enabled_modules) {
        module_id <- mod_info$module$id
        module_file <- file.path(self$modules_dir, paste0(module_id, ".R"))
        
        if (file.exists(module_file)) {
          tryCatch({
            source(module_file, local = .GlobalEnv)
            cat("   ✓", mod_info$module$name, "\n")
          }, error = function(e) {
            cat("   ✗", mod_info$module$name, "- ERROR:", e$message, "\n")
          })
        } else {
          cat("   ⚠", mod_info$module$name, "- FILE NOT FOUND:", module_file, "\n")
        }
      }
      
      cat("\n✓ Module loading complete\n\n")
    },
    
    print = function() {
      cat("\n╔═══════════════════════════════════════╗\n")
      cat("║  Module Loader - Flat Structure      ║\n")
      cat("╚═══════════════════════════════════════╝\n\n")
      
      enabled <- self$get_enabled_modules()
      
      cat("Modules directory:", self$modules_dir, "\n")
      cat("Total modules:", length(self$registry$modules), "\n")
      cat("Enabled modules:", length(enabled), "\n\n")
      
      if (length(enabled) > 0) {
        cat("Enabled modules:\n")
        for (mod in enabled) {
          cat(sprintf("  %d. %s (%s)\n", 
                     mod$module$priority, 
                     mod$module$name, 
                     mod$module$id))
        }
      }
      
      cat("\n")
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
