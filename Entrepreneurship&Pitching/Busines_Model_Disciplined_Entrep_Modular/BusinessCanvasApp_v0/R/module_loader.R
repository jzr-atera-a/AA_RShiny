# R/module_loader.R
# R6 Class for conditional module loading

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
      self$load_registry()
      self$discover_modules()
    },
    
    load_registry = function() {
      registry_path <- "modules/_module_registry.yml"
      if (!file.exists(registry_path)) {
        stop("Module registry not found at: ", registry_path)
      }
      self$registry <- yaml::read_yaml(registry_path)
      cat(sprintf("📋 Loaded module registry: %d modules defined\n", 
                  length(self$registry$modules)))
    },
    
    discover_modules = function() {
      modules_dir <- "modules"
      module_dirs <- list.dirs(modules_dir, recursive = FALSE, full.names = FALSE)
      module_dirs <- module_dirs[!grepl("^_", module_dirs)]
      
      for (module_dir in module_dirs) {
        manifest_path <- file.path(modules_dir, module_dir, "manifest.yml")
        
        if (file.exists(manifest_path)) {
          manifest <- yaml::read_yaml(manifest_path)
          
          registry_enabled <- self$registry$modules[[module_dir]]$enabled %||% 
            manifest$module$enabled %||% FALSE
          priority <- self$registry$modules[[module_dir]]$priority %||% 50
          
          manifest$module$enabled <- registry_enabled
          manifest$module$priority <- priority
          manifest$module$path <- file.path(modules_dir, module_dir)
          
          # Ensure tabname exists
          if (is.null(manifest$menu$tabname)) {
            manifest$menu$tabname <- manifest$module$id
          }
          
          self$modules[[module_dir]] <- manifest
        }
      }
      
      self$modules <- self$modules[order(sapply(self$modules, function(m) m$module$priority))]
      
      enabled_count <- sum(sapply(self$modules, function(m) m$module$enabled))
      cat(sprintf("🔍 Discovered %d modules (%d enabled, %d disabled)\n", 
                  length(self$modules), enabled_count, 
                  length(self$modules) - enabled_count))
    },
    
    get_enabled_modules = function() {
      purrr::keep(self$modules, ~ .x$module$enabled)
    },
    
    load_packages = function() {
      enabled_modules <- self$get_enabled_modules()
      all_packages <- character(0)
      
      for (module in enabled_modules) {
        if (!is.null(module$dependencies$packages)) {
          all_packages <- c(all_packages, module$dependencies$packages)
        }
      }
      
      unique_packages <- unique(all_packages)
      core_packages <- c("shiny", "shinydashboard", "R6", "yaml", "purrr")
      packages_to_load <- setdiff(unique_packages, core_packages)
      
      if (length(packages_to_load) > 0) {
        cat(sprintf("\n📦 Loading %d packages for enabled modules...\n", length(packages_to_load)))
        
        for (pkg in packages_to_load) {
          if (requireNamespace(pkg, quietly = TRUE)) {
            suppressPackageStartupMessages(library(pkg, character.only = TRUE))
            self$loaded_packages <- c(self$loaded_packages, pkg)
            cat(sprintf("   ✓ %s\n", pkg))
          } else {
            warning(sprintf("Package '%s' not installed", pkg))
          }
        }
      }
      
      cat(sprintf("\n✅ Loaded %d packages successfully\n", length(self$loaded_packages)))
    },
    
    source_modules = function() {
      enabled_modules <- self$get_enabled_modules()
      
      if (length(enabled_modules) == 0) {
        warning("No enabled modules found!")
        return()
      }
      
      cat(sprintf("\n📂 Sourcing %d enabled modules...\n", length(enabled_modules)))
      
      for (module in enabled_modules) {
        module_path <- module$module$path
        
        for (file_name in c("utils.R", "ui.R", "server.R")) {
          file_path <- file.path(module_path, file_name)
          if (file.exists(file_path) && file.info(file_path)$size > 0) {
            tryCatch({
              source(file_path, local = .GlobalEnv)
            }, error = function(e) {
              warning(sprintf("Error sourcing %s for %s: %s", 
                              file_name, module$module$id, e$message))
            })
          }
        }
        
        cat(sprintf("   ✓ %s\n", module$module$name))
      }
      cat("\n")
    },
    
    generate_menu_items = function() {
      enabled_modules <- self$get_enabled_modules()
      
      lapply(enabled_modules, function(module) {
        tabname <- module$menu$tabname %||% module$module$id
        menuItem(
          module$menu$label,
          tabName = tabname,
          icon = icon(module$menu$icon %||% "circle")
        )
      })
    },
    
    generate_tab_items = function() {
      enabled_modules <- self$get_enabled_modules()
      
      lapply(enabled_modules, function(module) {
        ui_function_name <- paste0(module$module$id, "_ui")
        tabname <- module$menu$tabname %||% module$module$id
        
        if (is.null(tabname) || tabname == "") {
          tabname <- module$module$id
        }
        
        if (exists(ui_function_name, envir = .GlobalEnv)) {
          ui_function <- get(ui_function_name, envir = .GlobalEnv)
          tabItem(tabName = tabname, ui_function(module$module$id))
        } else {
          tabItem(
            tabName = tabname,
            fluidRow(
              box(
                title = paste("Module:", module$module$name),
                status = "warning",
                solidHeader = TRUE,
                width = 12,
                h3(module$module$name),
                div(class = "alert alert-info",
                    tags$strong("Status: "), "Implementation needed",
                    br(),
                    tags$small(paste("Expected:", ui_function_name))
                ),
                hr(),
                h5("Implementation Steps:"),
                tags$ol(
                  tags$li("Edit: ", tags$code(paste0("modules/", module$module$id, "/ui.R"))),
                  tags$li("See: ", tags$code("modules/claude_auth/ui.R"), " for example"),
                  tags$li("Consult: ", tags$code("TODO.md"), " for detailed instructions")
                ),
                tags$pre(style = "background:#f5f5f5;padding:10px;border-radius:5px;",
                         paste0(ui_function_name, " <- function(id) {\n  ns <- NS(id)\n  tagList(\n    # UI here\n  )\n}"))
              )
            )
          )
        }
      })
    },
    
    print = function() {
      cat("\n┌─────────────────────────────────────┐\n")
      cat("│  MODULE LOADER STATUS               │\n")
      cat("└─────────────────────────────────────┘\n\n")
      
      cat(sprintf("Total modules: %d\n", length(self$modules)))
      cat(sprintf("Enabled: %d\n", length(self$get_enabled_modules())))
      cat(sprintf("Disabled: %d\n\n", length(self$modules) - length(self$get_enabled_modules())))
      
      cat("Enabled modules:\n")
      for (module in self$get_enabled_modules()) {
        cat(sprintf("  ✓ %s (priority: %d)\n", module$module$name, module$module$priority))
      }
      
      disabled <- purrr::keep(self$modules, ~ !.x$module$enabled)
      if (length(disabled) > 0) {
        cat("\nDisabled modules:\n")
        for (module in disabled) {
          cat(sprintf("  ✗ %s\n", module$module$name))
        }
      }
      cat("\n")
    }
  )
)