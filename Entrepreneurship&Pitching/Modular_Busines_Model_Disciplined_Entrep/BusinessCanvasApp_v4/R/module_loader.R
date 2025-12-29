# Module Loader R6 Class - WORKING VERSION

library(R6)
library(yaml)
library(purrr)

ModuleLoader <- R6Class(
  "ModuleLoader",
  
  public = list(
    modules = list(),
    registry = NULL,
    loaded_packages = character(0),
    
    initialize = function() {
      self$load_registry()
      self$discover_modules()
    },
    
    load_registry = function() {
      registry_path <- "modules/_module_registry.yml"
      if (!file.exists(registry_path)) {
        stop("Module registry not found: ", registry_path)
      }
      self$registry <- yaml::read_yaml(registry_path)
    },
    
    discover_modules = function() {
      module_dirs <- list.dirs("modules", recursive = FALSE, full.names = TRUE)
      module_dirs <- module_dirs[!grepl("^_", basename(module_dirs))]
      
      for (dir in module_dirs) {
        manifest_path <- file.path(dir, "manifest.yml")
        if (!file.exists(manifest_path)) next
        
        manifest <- yaml::read_yaml(manifest_path)
        module_id <- manifest$module$id
        
        registry_entry <- self$registry$modules[[module_id]]
        enabled <- if (!is.null(registry_entry$enabled)) {
          registry_entry$enabled
        } else {
          manifest$module$enabled %||% TRUE
        }
        
        priority <- if (!is.null(registry_entry$priority)) {
          registry_entry$priority
        } else {
          manifest$module$priority %||% 99
        }
        
        manifest$module$enabled <- enabled
        manifest$module$priority <- priority
        manifest$module$path <- dir
        
        manifest$menu <- manifest$module$menu
        
        self$modules[[module_id]] <- manifest
      }
      
      self$modules <- self$modules[order(sapply(self$modules, function(m) m$module$priority))]
    },
    
    get_enabled_modules = function() {
      purrr::keep(self$modules, ~ .x$module$enabled)
    },
    
    load_packages = function() {
      cat("\n📦 Loading packages for enabled modules...\n")
      enabled <- self$get_enabled_modules()
      
      all_packages <- character(0)
      for (module in enabled) {
        if (!is.null(module$dependencies$packages)) {
          all_packages <- c(all_packages, module$dependencies$packages)
        }
      }
      
      all_packages <- unique(all_packages)
      core_packages <- c("shiny", "shinydashboard", "R6", "yaml", "purrr")
      all_packages <- setdiff(all_packages, core_packages)
      
      for (pkg in all_packages) {
        if (!pkg %in% self$loaded_packages) {
          tryCatch({
            suppressPackageStartupMessages(library(pkg, character.only = TRUE))
            self$loaded_packages <- c(self$loaded_packages, pkg)
            cat(sprintf("   ✓ %s\n", pkg))
          }, error = function(e) {
            cat(sprintf("   ⚠ %s (not installed)\n", pkg))
          })
        }
      }
    },
    
    source_modules = function() {
      cat("\n📂 Sourcing enabled modules...\n")
      enabled <- self$get_enabled_modules()
      
      for (module in enabled) {
        module_id <- module$module$id
        ui_path <- file.path(module$module$path, "ui.R")
        server_path <- file.path(module$module$path, "server.R")
        
        if (file.exists(ui_path)) {
          source(ui_path, local = .GlobalEnv)
        }
        if (file.exists(server_path)) {
          source(server_path, local = .GlobalEnv)
        }
        
        cat(sprintf("   ✓ %s\n", module$module$name))
      }
    },
    
    generate_menu_items = function() {
      enabled <- self$get_enabled_modules()
      
      lapply(enabled, function(module) {
        menu <- module$menu
        
        badge <- if (!is.null(menu$badge$label)) {
          tags$small(
            class = paste0("label label-", menu$badge$color %||% "primary", " pull-right"),
            menu$badge$label
          )
        } else {
          NULL
        }
        
        menuItem(
          menu$label,
          tabName = menu$tabname,
          icon = icon(menu$icon),
          badgeLabel = badge
        )
      })
    },
    
    generate_tab_items = function() {
      enabled <- self$get_enabled_modules()
      tab_items <- list()
      
      for (module in enabled) {
        module_id <- module$module$id
        ui_function_name <- paste0(module_id, "_ui")
        tabname <- module$menu$tabname %||% module_id
        
        if (exists(ui_function_name, envir = .GlobalEnv)) {
          ui_function <- get(ui_function_name, envir = .GlobalEnv)
          tab_items[[length(tab_items) + 1]] <- tabItem(
            tabName = tabname,
            ui_function(module_id)
          )
        }
      }
      
      return(tab_items)
    },
    
    print = function() {
      cat("\n╔════════════════════════════════════════════╗\n")
      cat("║      MODULE LOADER STATUS REPORT           ║\n")
      cat("╚════════════════════════════════════════════╝\n\n")
      
      cat(sprintf("📊 Total modules discovered: %d\n", length(self$modules)))
      
      enabled <- self$get_enabled_modules()
      cat(sprintf("✅ Enabled modules: %d\n", length(enabled)))
      
      disabled <- purrr::keep(self$modules, ~ !.x$module$enabled)
      cat(sprintf("❌ Disabled modules: %d\n\n", length(disabled)))
      
      if (length(enabled) > 0) {
        cat("ENABLED MODULES:\n")
        for (m in enabled) {
          cat(sprintf("  ✓ %s (priority: %d)\n", m$module$name, m$module$priority))
        }
        cat("\n")
      }
      
      if (length(disabled) > 0) {
        cat("DISABLED MODULES:\n")
        for (m in disabled) {
          cat(sprintf("  ✗ %s\n", m$module$name))
        }
        cat("\n")
      }
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x