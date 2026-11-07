# ============================================================================
# MODULE LOADER - R6 CLASS
# ============================================================================

ModuleLoader <- R6::R6Class(
  "ModuleLoader",
  public = list(
    modules = NULL,
    
    initialize = function() {
      registry_path <- "modules/_module_registry.yml"
      if (!file.exists(registry_path)) {
        stop("Module registry not found: ", registry_path)
      }
      
      registry <- yaml::read_yaml(registry_path)
      self$modules <- registry$modules
      
      cat("✓ Module registry loaded\n")
    },
    
    get_enabled_modules = function() {
      enabled <- Filter(function(m) isTRUE(m$enabled), self$modules)
      return(lapply(enabled, function(m) list(module = m)))
    },
    
    load_packages = function() {
      enabled <- self$get_enabled_modules()
      all_packages <- unique(unlist(lapply(enabled, function(m) m$module$packages)))
      
      for (pkg in all_packages) {
        if (!requireNamespace(pkg, quietly = TRUE)) {
          cat("⚠ Package not installed:", pkg, "\n")
        } else {
          suppressPackageStartupMessages(library(pkg, character.only = TRUE))
        }
      }
      cat("✓ Packages loaded\n")
    },
    
    source_modules = function() {
      enabled <- self$get_enabled_modules()
      
      for (module in enabled) {
        module_id <- module$module$id
        module_dir <- file.path("modules", module_id)
        
        ui_file <- file.path(module_dir, "ui.R")
        server_file <- file.path(module_dir, "server.R")
        
        if (file.exists(ui_file)) source(ui_file, local = .GlobalEnv)
        if (file.exists(server_file)) source(server_file, local = .GlobalEnv)
      }
      cat("✓ Module code sourced\n")
    },
    
    print = function() {
      enabled <- self$get_enabled_modules()
      cat("Enabled modules:", length(enabled), "\n")
      for (m in enabled) {
        cat("  •", m$module$name, "\n")
      }
    }
  )
)
