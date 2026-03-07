# R/module_loader.R
# Module Loader for CAV Route Optimizer

library(R6)
library(yaml)

ModuleLoader <- R6Class(
  "ModuleLoader",
  
  public = list(
    registry_path = NULL,
    registry = NULL,
    
    initialize = function(registry_path = "modules/_module_registry.yml") {
      self$registry_path <- registry_path
      
      if (!file.exists(registry_path)) {
        stop("Module registry not found: ", registry_path)
      }
      
      self$registry <- yaml::read_yaml(registry_path)
      cat("✓ Module registry loaded from", registry_path, "\n")
    },
    
    print = function() {
      cat("\n╔════════════════════════════════════════╗\n")
      cat("║  MODULE REGISTRY                       ║\n")
      cat("╚════════════════════════════════════════╝\n\n")
      cat("  App Name:", self$registry$app$name, "\n")
      cat("  Version:", self$registry$app$version, "\n")
      cat("  Total Modules:", length(self$registry$modules), "\n")
      cat("  Enabled:", length(self$get_enabled_modules()), "\n\n")
    },
    
    get_enabled_modules = function() {
      enabled <- list()
      
      for (module_id in names(self$registry$modules)) {
        module_config <- self$registry$modules[[module_id]]
        
        if (is.null(module_config$enabled) || module_config$enabled) {
          # Create full manifest structure
          manifest <- list(
            id = module_id,
            name = if (!is.null(module_config$name)) module_config$name else module_id,
            description = if (!is.null(module_config$description)) module_config$description else "",
            priority = if (!is.null(module_config$priority)) module_config$priority else 999,
            enabled = TRUE,
            menu = list(
              label = if (!is.null(module_config$name)) module_config$name else module_id,
              tabname = module_id,
              icon = if (!is.null(module_config$icon)) module_config$icon else "circle"
            )
          )
          
          enabled[[length(enabled) + 1]] <- list(manifest = manifest)
        }
      }
      
      # Sort by priority
      enabled <- enabled[order(sapply(enabled, function(x) x$manifest$priority))]
      
      return(enabled)
    },
    
    source_modules = function() {
      cat("\n→ Sourcing module files...\n")
      
      enabled <- self$get_enabled_modules()
      
      for (mod in enabled) {
        module_id <- mod$manifest$id
        module_file <- paste0("modules/", module_id, ".R")
        
        if (file.exists(module_file)) {
          source(module_file, local = .GlobalEnv)
          cat(sprintf("  ✓ %s\n", mod$manifest$name))
        } else {
          cat(sprintf("  ✗ %s - FILE NOT FOUND: %s\n", 
                     mod$manifest$name, module_file))
          warning("Module file not found: ", module_file)
        }
      }
      
      cat("\n✓ All modules sourced\n")
    },
    
    load_packages = function() {
      cat("\n→ Checking module dependencies...\n")
      # This could be expanded to check package dependencies
      cat("✓ Dependencies checked\n")
    }
  )
)

cat("✓ ModuleLoader class defined\n")
