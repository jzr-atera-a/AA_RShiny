# ============================================================================
# MODULE LOADER - R6 CLASS
# ============================================================================
# 
# Handles discovery, loading, and management of modular components
# Controls which modules are active based on registry settings
#
# ============================================================================

library(R6)
library(yaml)
library(purrr)

ModuleLoader <- R6Class(
  "ModuleLoader",
  
  public = list(
    modules = list(),
    registry = NULL,
    loaded_packages = character(0),
    
    # Initialize and discover modules
    initialize = function() {
      self$load_registry()
      self$discover_modules()
    },
    
    # Load the central module registry
    load_registry = function() {
      registry_path <- "modules/_module_registry.yml"
      if (file.exists(registry_path)) {
        self$registry <- yaml::read_yaml(registry_path)
      } else {
        stop("Module registry not found: ", registry_path)
      }
    },
    
    # Discover all modules in modules/ directory
    discover_modules = function() {
      module_dirs <- list.dirs("modules", recursive = FALSE, full.names = TRUE)
      # Exclude registry file directory
      module_dirs <- module_dirs[!grepl("/_", basename(module_dirs))]
      
      for (dir in module_dirs) {
        manifest_path <- file.path(dir, "manifest.yml")
        
        if (file.exists(manifest_path)) {
          manifest <- yaml::read_yaml(manifest_path)
          module_id <- manifest$module$id
          
          # Check if module is enabled (registry overrides manifest)
          enabled <- manifest$module$enabled %||% FALSE
          
          if (!is.null(self$registry$modules[[module_id]])) {
            registry_enabled <- self$registry$modules[[module_id]]$enabled
            if (!is.null(registry_enabled)) {
              enabled <- registry_enabled
            }
          }
          
          manifest$module$enabled <- enabled
          manifest$module$dir <- dir
          
          self$modules[[module_id]] <- manifest
        }
      }
    },
    
    # Get only enabled modules
    get_enabled_modules = function() {
      purrr::keep(self$modules, ~ .x$module$enabled)
    },
    
    # Load packages for enabled modules only
    load_packages = function() {
      enabled <- self$get_enabled_modules()
      
      # Collect all unique packages
      all_packages <- unique(unlist(lapply(enabled, function(m) {
        m$module$dependencies$packages
      })))
      
      # Remove already loaded core packages
      core_packages <- c("shiny", "shinydashboard", "R6", "yaml", "purrr")
      all_packages <- setdiff(all_packages, core_packages)
      
      # Load each package
      for (pkg in all_packages) {
        if (!requireNamespace(pkg, quietly = TRUE)) {
          message("⚠ Package not installed: ", pkg)
          message("  Install with: install.packages('", pkg, "')")
        } else {
          suppressPackageStartupMessages({
            library(pkg, character.only = TRUE)
          })
          self$loaded_packages <- c(self$loaded_packages, pkg)
        }
      }
      
      if (length(self$loaded_packages) > 0) {
        cat("  Loaded packages:", paste(self$loaded_packages, collapse = ", "), "\n")
      }
    },
    
    # Source UI and server files for enabled modules
    source_modules = function() {
      enabled <- self$get_enabled_modules()
      
      for (module in enabled) {
        module_id <- module$module$id
        module_dir <- module$module$dir
        
        ui_path <- file.path(module_dir, "ui.R")
        server_path <- file.path(module_dir, "server.R")
        
        if (file.exists(ui_path)) {
          source(ui_path, local = .GlobalEnv)
          cat("  ✓ Loaded UI:", module_id, "\n")
        } else {
          warning("UI file not found: ", ui_path)
        }
        
        if (file.exists(server_path)) {
          source(server_path, local = .GlobalEnv)
          cat("  ✓ Loaded server:", module_id, "\n")
        } else {
          warning("Server file not found: ", server_path)
        }
      }
    },
    
    # Generate sidebar menu items
    generate_menu_items = function() {
      enabled <- self$get_enabled_modules()
      
      # Sort by priority
      enabled <- enabled[order(sapply(enabled, function(m) {
        priority <- self$registry$modules[[m$module$id]]$priority
        if (is.null(priority)) 99 else priority
      }))]
      
      lapply(enabled, function(m) {
        menuItem(
          m$module$menu$label,
          tabName = m$module$menu$tabname,
          icon = icon(m$module$menu$icon)
        )
      })
    },
    
    # Generate tab items for dashboard body
    generate_tab_items = function() {
      enabled <- self$get_enabled_modules()
      
      tab_items <- lapply(enabled, function(m) {
        module_id <- m$module$id
        ui_function_name <- paste0(module_id, "_ui")
        
        tryCatch({
          if (exists(ui_function_name, envir = .GlobalEnv)) {
            ui_function <- get(ui_function_name, envir = .GlobalEnv)
            
            tabItem(
              tabName = m$module$menu$tabname,
              ui_function(module_id)
            )
          } else {
            warning("UI function not found: ", ui_function_name)
            tabItem(
              tabName = m$module$menu$tabname,
              box(
                title = paste("Error:", m$module$name),
                status = "danger",
                width = 12,
                paste("UI function not found:", ui_function_name)
              )
            )
          }
        }, error = function(e) {
          warning("Error generating tab for ", module_id, ": ", e$message)
          tabItem(
            tabName = m$module$menu$tabname,
            box(
              title = paste("Error:", m$module$name),
              status = "danger",
              width = 12,
              paste("Error:", e$message)
            )
          )
        })
      })
      
      # Filter out NULL values
      tab_items[!sapply(tab_items, is.null)]
    },
    
    # Print module status
    print = function() {
      cat("\n╔═══ MODULE LOADER STATUS ═══╗\n")
      cat("  Total modules:  ", length(self$modules), "\n")
      cat("  Enabled:        ", length(self$get_enabled_modules()), "\n")
      cat("  Disabled:       ", length(self$modules) - length(self$get_enabled_modules()), "\n")
      cat("╚════════════════════════════╝\n\n")
      
      cat("Module Status:\n")
      for (m in self$modules) {
        status <- if (m$module$enabled) "✓ ENABLED " else "  DISABLED"
        priority <- self$registry$modules[[m$module$id]]$priority %||% 99
        cat(sprintf("  %s [%2d] %s\n", status, priority, m$module$name))
      }
      cat("\n")
    }
  )
)
