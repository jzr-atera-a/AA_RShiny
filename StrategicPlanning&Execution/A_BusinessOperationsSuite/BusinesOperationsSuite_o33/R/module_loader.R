# R/module_loader.R
#
# Reads modules/_module_registry.yml, sources each enabled module's single
# <file>.R (which must define <id>_ui(id) and <id>_server(id, api_manager)),
# and exposes the group/module structure needed to build a grouped sidebar.

ModuleLoader <- R6::R6Class("ModuleLoader",
  public = list(
    registry = NULL,
    modules_dir = NULL,

    initialize = function(modules_dir = "modules", registry_file = "modules/_module_registry.yml") {
      self$modules_dir <- modules_dir
      self$registry <- yaml::read_yaml(registry_file)
      invisible(self)
    },

    # Source every enabled module's single R file. Called once at app start.
    load_all = function() {
      n_loaded <- 0
      for (mod_id in names(self$registry$modules)) {
        meta <- self$registry$modules[[mod_id]]
        if (!isTRUE(meta$enabled)) next

        path <- file.path(self$modules_dir, meta$folder, paste0(meta$file, ".R"))
        if (!file.exists(path)) {
          warning(sprintf("[ModuleLoader] Missing file for module '%s': %s", mod_id, path))
          next
        }
        source(path, local = FALSE)

        ui_fn <- paste0(mod_id, "_ui")
        server_fn <- paste0(mod_id, "_server")
        if (!exists(ui_fn) || !exists(server_fn)) {
          warning(sprintf("[ModuleLoader] '%s' loaded but missing %s()/%s()", mod_id, ui_fn, server_fn))
          next
        }
        n_loaded <- n_loaded + 1
      }
      cat(sprintf("✓ [ModuleLoader] Loaded %d module(s)\n", n_loaded))
      invisible(n_loaded)
    },

    # Ordered list of groups (each a list with id/label/icon/expanded/modules)
    get_groups = function() {
      self$registry$groups
    },

    # All enabled module ids, in registry (group) order
    get_all_module_ids = function() {
      ids <- unlist(lapply(self$get_groups(), function(g) g$modules))
      ids[vapply(ids, function(i) isTRUE(self$registry$modules[[i]]$enabled), logical(1))]
    },

    get_module_meta = function(mod_id) {
      self$registry$modules[[mod_id]]
    },

    get_ui_function = function(mod_id) {
      get(paste0(mod_id, "_ui"), envir = .GlobalEnv)
    },

    get_server_function = function(mod_id) {
      get(paste0(mod_id, "_server"), envir = .GlobalEnv)
    }
  )
)
