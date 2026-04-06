# R/module_loader.R
library(R6)
library(yaml)
library(purrr)

ModuleLoader <- R6Class(
  "ModuleLoader",
  public = list(
    registry    = NULL,
    modules_dir = "modules",

    initialize = function() {
      registry_path <- file.path(self$modules_dir, "_module_registry.yml")
      if (!file.exists(registry_path))
        stop("Module registry not found at: ", registry_path)
      self$registry <- yaml::read_yaml(registry_path)
      cat("📦 ModuleLoader: ", length(self$registry$modules), "modules\n")
    },

    get_enabled_modules = function() {
      modules <- self$registry$modules
      enabled <- modules[sapply(modules, function(m) isTRUE(m$enabled))]
      sorted  <- enabled[order(sapply(enabled, function(m) m$priority %||% 999))]
      lapply(names(sorted), function(id) {
        list(module = c(list(id = id), sorted[[id]]))
      })
    },

    load_packages = function() {
      pkgs <- c("shiny","shinydashboard","R6","yaml","purrr","magrittr","dplyr","DT","plotly","jsonlite")
      for (pkg in pkgs)
        if (!requireNamespace(pkg, quietly=TRUE))
          cat("⚠ Missing:", pkg, "\n")
    },

    source_modules = function() {
      cat("📂 Loading modules...\n")
      for (mod_info in self$get_enabled_modules()) {
        f <- file.path(self$modules_dir, paste0(mod_info$module$id, ".R"))
        if (file.exists(f)) {
          tryCatch(source(f, local=.GlobalEnv), error=function(e)
            cat("✗", mod_info$module$name, "-", e$message, "\n"))
        }
      }
    }
  )
)
`%||%` <- function(x, y) if (is.null(x)) y else x
