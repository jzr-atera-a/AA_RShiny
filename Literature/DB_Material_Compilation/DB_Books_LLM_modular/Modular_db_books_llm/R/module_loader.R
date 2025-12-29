# R/module_loader.R
# ModuleLoader R6 Class - Manages module discovery, loading, and initialization
# ===============================================================================

library(R6)
library(yaml)
library(purrr)

ModuleLoader <- R6::R6Class(
  "ModuleLoader",
  
  public = list(
    modules = list(),
    registry = NULL,
    loaded_packages = character(0),
    
    # Initialize: Load registry and discover modules
    initialize = function() {
      self$load_registry()
      self$discover_modules()
    },
    
    # Load the module registry YAML file
    load_registry = function() {
      registry_path <- "modules/_module_registry.yml"
      if (!file.exists(registry_path)) {
        stop("Module registry not found: ", registry_path)
      }
      self$registry <- yaml::read_yaml(registry_path)
      cat("✓ Loaded module registry\n")
    },
    
    # Discover all modules in modules/ directory
    discover_modules = function() {
      module_dirs <- list.dirs("modules", recursive = FALSE)
      module_dirs <- module_dirs[!grepl("^_", basename(module_dirs))]
      
      for (dir in module_dirs) {
        manifest_path <- file.path(dir, "manifest.yml")
        if (!file.exists(manifest_path)) next
        
        manifest <- yaml::read_yaml(manifest_path)
        module_id <- manifest$module$id
        
        # Check enabled status (registry overrides manifest)
        enabled <- if (!is.null(self$registry$modules[[module_id]]$enabled)) {
          self$registry$modules[[module_id]]$enabled
        } else {
          manifest$module$enabled %||% TRUE
        }
        
        manifest$module$enabled <- enabled
        manifest$module$path <- dir
        
        self$modules[[module_id]] <- manifest
      }
      
      # Sort by priority
      self$modules <- self$modules[order(sapply(self$modules, function(m) {
        self$registry$modules[[m$module$id]]$priority %||% 99
      }))]
      
      cat("✓ Discovered", length(self$modules), "modules\n")
    },
    
    # Get only enabled modules
    get_enabled_modules = function() {
      purrr::keep(self$modules, ~ .x$module$enabled)
    },
    
    # Load packages for enabled modules only
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
    
    # Source enabled modules
    source_modules = function() {
      enabled_modules <- self$get_enabled_modules()
      
      for (module in enabled_modules) {
        ui_path <- file.path(module$module$path, "ui.R")
        server_path <- file.path(module$module$path, "server.R")
        
        if (file.exists(ui_path)) source(ui_path, local = .GlobalEnv)
        if (file.exists(server_path)) source(server_path, local = .GlobalEnv)
        
        cat("✓ Loaded module:", module$module$id, "\n")
      }
    },
    
    generate_menu_items = function() {
      enabled_modules <- self$get_enabled_modules()
      
      items <- lapply(seq_along(enabled_modules), function(i) {
        module <- enabled_modules[[i]]
        menu_info <- module$module$menu
        
        badge <- NULL
        if (!is.null(menu_info$badge) && !is.null(menu_info$badge$label)) {
          badge <- tags$span(
            class = paste0("label label-", menu_info$badge$color %||% "primary"),
            menu_info$badge$label
          )
        }
        
        menuItem(
          menu_info$label,
          tabName = menu_info$tabname,
          icon = icon(menu_info$icon),
          badgeLabel = badge,
          selected = (i == 1)  # Select first item by default
        )
      })
      
      return(items)
    },
    
    generate_tab_items = function() {
      enabled_modules <- self$get_enabled_modules()
      
      tab_list <- lapply(enabled_modules, function(module) {
        ui_function_name <- paste0(module$module$id, "_ui")
        
        if (exists(ui_function_name, envir = .GlobalEnv)) {
          ui_function <- get(ui_function_name, envir = .GlobalEnv)
          
          tabItem(
            tabName = module$module$menu$tabname,
            ui_function(module$module$id)
          )
        } else {
          NULL
        }
      })
      
      # Filter out NULLs and return as list for do.call
      Filter(Negate(is.null), tab_list)
    },
    
    # Print module status
    print = function() {
      cat("\n📦 Module Loader Status:\n")
      cat("   Total modules:", length(self$modules), "\n")
      
      enabled <- self$get_enabled_modules()
      cat("   Enabled:", length(enabled), "\n")
      
      if (length(enabled) > 0) {
        cat("\n   Enabled modules:\n")
        for (m in enabled) {
          cat("   ✓", m$module$name, "\n")
        }
      }
      
      disabled <- purrr::keep(self$modules, ~ !.x$module$enabled)
      if (length(disabled) > 0) {
        cat("\n   Disabled modules:\n")
        for (m in disabled) {
          cat("   ✗", m$module$name, "\n")
        }
      }
      cat("\n")
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
