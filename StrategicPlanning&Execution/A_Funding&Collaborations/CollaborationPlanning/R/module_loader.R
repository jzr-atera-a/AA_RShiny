# R/module_loader.R - finds, checks and loads the sub-tab files
# Scans modules/<Group>/<id>.R (two levels, no "_" prefix), reads the header block at the top of
# each file, and sources every enabled file once. Warns (does not fail) about mismatches.

read_module_header <- function(path) {
  lines <- readLines(path, n = 40, warn = FALSE, encoding = "UTF-8")
  m <- regmatches(lines, regexec("^#\\s*([a-z_]+):\\s*(.*)$", lines, perl = TRUE))
  h <- list()
  for (x in m) if (length(x) == 3) h[[x[2]]] <- trimws(x[3])
  h
}

ModuleLoader <- R6::R6Class("ModuleLoader",
  public = list(
    registry = NULL, modules = list(), warnings = character(0),

    initialize = function(dir = "modules") {
      self$registry <- yaml::read_yaml(file.path(dir, "_module_registry.yml"))
      files <- list.files(dir, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
      rel <- sub(paste0("^", dir, "/"), "", files)
      keep <- vapply(strsplit(rel, "/"), function(p) length(p) == 2 && !any(startsWith(p, "_")), TRUE)
      for (f in files[keep]) {
        h <- read_module_header(f)
        id <- tools::file_path_sans_ext(basename(f))
        if (!identical(h$id, id)) self$warn("header id '", h$id %||% "", "' does not match file name ", f)
        if (!is.null(self$modules[[id]])) stop("Duplicate module id: ", id)
        h$path <- f; h$id <- id
        self$modules[[id]] <- h
      }
      placed <- unlist(lapply(self$registry$groups, `[[`, "modules"))
      for (id in setdiff(names(self$modules), placed)) self$warn("module ", id, " is not placed in any group")
      for (id in setdiff(placed, names(self$modules))) self$warn("group lists ", id, " but there is no file for it")
      for (id in self$enabled_ids()) {
        source(self$modules[[id]]$path, local = .GlobalEnv)
        for (fn in paste0(id, c("_ui", "_server")))
          if (!exists(fn, envir = .GlobalEnv, mode = "function")) self$warn(id, ": ", fn, "() is missing")
      }
      invisible(self)
    },

    warn = function(...) { msg <- paste0(...); self$warnings <- c(self$warnings, msg); log_debug("[Loader] warning: ", msg) },

    enabled_ids = function() {
      reg <- self$registry$modules
      ids <- names(self$modules)
      ids[vapply(ids, function(i) !identical(reg[[i]]$enabled, FALSE), TRUE)]
    },

    group_modules = function(g) intersect(g$modules %||% character(0), self$enabled_ids()),

    print = function(...) {
      cat(sprintf("[Loader] %d module files, %d enabled, %d groups\n", length(self$modules),
                  length(self$enabled_ids()), length(self$registry$groups)))
      invisible(self)
    }
  )
)
