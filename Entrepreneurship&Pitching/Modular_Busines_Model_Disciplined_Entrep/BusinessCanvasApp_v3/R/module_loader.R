# Module Loader R6 Class
library(R6)
library(yaml)
library(purrr)

ModuleLoader <- R6::R6Class(
  "ModuleLoader",
  
  public = list(
    modules = list(),
    registry = NULL,
    loaded_packages = character(0),
    
    initialize = function() {
      cat("📋 Loading module registry...\n")
      self$load_registry()
      cat("🔍 Discovering modules...\n")
      self$discover_modules()
    },
    
    load_registry = function() {
      registry_path <- "modules/_module_registry.yml"
      if (!file.exists(registry_path)) {
        stop("Module registry not found at: ", registry_path)
      }
      self$registry <- yaml::read_yaml(registry_path)
    },
    
    discover_modules = function() {
      module_dirs <- list.dirs("modules", full.names = FALSE, recursive = FALSE)
      module_dirs <- module_dirs[!startsWith(module_dirs, "_")]
      
      for (module_dir in module_dirs) {
        manifest_path <- file.path("modules", module_dir, "manifest.yml")
        
        if (file.exists(manifest_path)) {
          manifest <- yaml::read_yaml(manifest_path)
          
          # Check if enabled in registry (registry overrides manifest)
          registry_enabled <- self$registry$modules[[module_dir]]$enabled
          if (!is.null(registry_enabled)) {
            manifest$module$enabled <- registry_enabled
          }
          
          # Ensure tabname exists
          if (is.null(manifest$menu$tabname) || manifest$menu$tabname == "") {
            manifest$menu$tabname <- manifest$module$id
          }
          
          manifest$module$path <- file.path("modules", module_dir)
          self$modules[[module_dir]] <- manifest
        }
      }
    },
    
    get_enabled_modules = function() {
      purrr::keep(self$modules, ~ .x$module$enabled == TRUE)
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
        module_path <- module$module$path
        
        ui_file <- file.path(module_path, "ui.R")
        server_file <- file.path(module_path, "server.R")
        
        if (file.exists(ui_file)) {
          source(ui_file, local = FALSE)
          cat(sprintf("   ✓ %s (UI)\n", module$module$name))
        }
        
        if (file.exists(server_file)) {
          source(server_file, local = FALSE)
          cat(sprintf("   ✓ %s (Server)\n", module$module$name))
        }
      }
    },
    
    generate_menu_items = function() {
      enabled <- self$get_enabled_modules()
      menu_items <- list()
      
      for (module in enabled) {
        menu_items[[length(menu_items) + 1]] <- menuItem(
          text = module$menu$label,
          tabName = module$menu$tabname,
          icon = icon(module$menu$icon)
        )
      }
      
      return(menu_items)
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
        } else {
          tab_items[[length(tab_items) + 1]] <- tabItem(
            tabName = tabname,
            fluidRow(
              box(
                title = paste("Module:", module$module$name),
                status = "warning",
                solidHeader = TRUE,
                width = 12,
                h4("Module UI function not found"),
                p("Expected function:", ui_function_name)
              )
            )
          )
        }
      }
      
      return(tab_items)
    },
    
    print = function() {
      cat("\n╔════════════════════════════════════╗\n")
      cat("║      MODULE LOADER STATUS          ║\n")
      cat("╚════════════════════════════════════╝\n\n")
      
      enabled <- self$get_enabled_modules()
      disabled <- purrr::discard(self$modules, ~ .x$module$enabled == TRUE)
      
      cat(sprintf("✅ Enabled modules: %d\n", length(enabled)))
      for (module in enabled) {
        cat(sprintf("   • %s\n", module$module$name))
      }
      
      if (length(disabled) > 0) {
        cat(sprintf("\n⏸️  Disabled modules: %d\n", length(disabled)))
        for (module in disabled) {
          cat(sprintf("   • %s\n", module$module$name))
        }
      }
      cat("\n")
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
