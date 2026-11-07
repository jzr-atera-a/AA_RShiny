# R/module_loader.R
library(R6); library(yaml); library(purrr)

ModuleLoader <- R6Class("ModuleLoader",
  public = list(
    registry    = NULL,
    modules_dir = "modules",

    initialize = function() {
      path <- file.path(self$modules_dir, "_module_registry.yml")
      if (!file.exists(path)) stop("Registry not found: ", path)
      self$registry <- yaml::read_yaml(path)
      cat("\n📦 ModuleLoader: ", length(self$registry$modules), "modules found\n")
    },

    get_enabled_modules = function() {
      mods    <- self$registry$modules
      enabled <- mods[sapply(mods, function(m) isTRUE(m$enabled))]
      sorted  <- enabled[order(sapply(enabled, function(m) m$priority %||% 999))]
      lapply(names(sorted), function(id) list(module = c(list(id = id), sorted[[id]])))
    },

    load_packages = function() {
      pkgs <- c("shiny","shinydashboard","R6","yaml","purrr","magrittr","dplyr","DT","plotly","jsonlite")
      for (p in pkgs) if (!requireNamespace(p, quietly=TRUE)) cat("   ⚠ Missing:", p, "\n")
      cat("✓ Packages checked\n")
    },

    source_modules = function() {
      cat("📂 Loading modules...\n")
      for (m in self$get_enabled_modules()) {
        f <- file.path(self$modules_dir, paste0(m$module$id, ".R"))
        if (file.exists(f)) {
          tryCatch({ source(f, local=.GlobalEnv); cat("   ✓", m$module$name, "\n") },
                   error = function(e) cat("   ✗", m$module$name, "-", e$message, "\n"))
        } else cat("   ⚠ File not found:", f, "\n")
      }
      cat("✓ Modules loaded\n")
    },

    print = function() {
      cat("\n╔══════════════════════════════════════╗\n")
      cat("║  ML System Design Prep (Manning 2025)║\n")
      cat("╚══════════════════════════════════════╝\n\n")
      for (m in self$get_enabled_modules())
        cat(sprintf("  %d. %s\n", m$module$priority, m$module$name))
      cat("\n")
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
