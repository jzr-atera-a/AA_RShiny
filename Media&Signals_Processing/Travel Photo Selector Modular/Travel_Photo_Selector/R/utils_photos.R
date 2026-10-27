# ============================================================================
# PHOTO MANAGER - R6 CLASS
# Shared state for all modules + persistence to local files in data/
#
#   data/config.json        root folder, limit per country, cost per photo, ...
#   data/inventory.rds      result of the last scan (all photos found)
#   data/selections.json    every ticked photo (kept per root folder, UTF-8)
#   data/thumb_cache/       small/large previews generated on demand
#   data/app.log            simple activity / error log
# ============================================================================

PhotoManager <- R6::R6Class(
  "PhotoManager",
  public = list(
    admin_code = "718",

    data_dir = NULL,
    config_file = NULL,
    inventory_file = NULL,
    selections_file = NULL,
    cache_dir = NULL,
    log_file = NULL,

    config = NULL,
    photos = NULL,         # data.frame: photo_id, rel_path, country, subfolder, file_name, mtime
    scanned_at = NULL,
    selections = NULL,     # data.frame: root_folder, rel_path, country, subfolder, file_name, selected_at
    photo_prefix = NULL,   # URL prefix that serves the original photos

    cfg_trigger = NULL,    # reactiveVal bumped when config / inventory change
    sel_trigger = NULL,    # reactiveVal bumped when selections change
    has_magick = FALSE,
    wm_fonts = list(),     # easy-to-read fonts available for the watermark

    initialize = function(data_dir = "data") {
      dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
      self$data_dir <- normalizePath(data_dir, winslash = "/")
      self$config_file <- file.path(self$data_dir, "config.json")
      self$inventory_file <- file.path(self$data_dir, "inventory.rds")
      self$selections_file <- file.path(self$data_dir, "selections.json")
      self$cache_dir <- file.path(self$data_dir, "thumb_cache")
      self$log_file <- file.path(self$data_dir, "app.log")
      dir.create(self$cache_dir, showWarnings = FALSE)

      self$cfg_trigger <- shiny::reactiveVal(0)
      self$sel_trigger <- shiny::reactiveVal(0)
      self$has_magick <- requireNamespace("magick", quietly = TRUE)
      shiny::addResourcePath("thumbcache", self$cache_dir)

      self$load_config()
      self$register_photo_folder()
      self$load_inventory()
      self$load_selections()
      self$wm_fonts <- init_watermark_fonts(".")
    },

    # ---------------------------------------------------------------- config
    default_config = function() {
      list(
        root_folder = "",
        limit_per_country = 50L,
        cost_per_photo = 5,
        currency = "MXN",
        grid_layout = "2x2",
        last_country = "",
        last_subfolder = "",
        # places panel (applied with the admin's "Aplicar cambios" button)
        country_limits = list(),       # e.g. list("México" = 80); countries not listed use limit_per_country
        inactive_places = character(), # "País || Lugar" keys of de-selected city/region/event folders
        special_cap = 8L,              # recommended max for Museo/Galería/Vuelo folders
        # printing / watermark
        print_parent = "",
        print_mode = "replace",
        wm_enabled = FALSE,
        wm_font = "atkinson",
        wm_size = 5,
        wm_bold = TRUE,
        wm_style = "dark_box"
      )
    },

    load_config = function() {
      cfg <- self$default_config()
      if (file.exists(self$config_file)) {
        saved <- tryCatch(jsonlite::read_json(self$config_file, simplifyVector = TRUE),
                          error = function(e) { self$log("Could not read config: ", conditionMessage(e)); list() })
        cfg <- utils::modifyList(cfg, saved)
      }
      self$config <- cfg
    },

    save_config = function() {
      safe_write(self$config_file, function(p)
        jsonlite::write_json(self$config, p, auto_unbox = TRUE, pretty = TRUE))
    },

    root = function() self$config$root_folder %||% "",
    limit = function() as.integer(self$config$limit_per_country %||% 50L),
    cost = function() as.numeric(self$config$cost_per_photo %||% 5),
    currency = function() self$config$currency %||% "MXN",
    root_ok = function() nzchar(self$root()) && dir.exists(self$root()),

    # ------------------------------------------------ limits / active places
    country_limit = function(country) {
      v <- suppressWarnings(as.integer(self$config$country_limits[[country]] %||% NA))
      if (length(v) == 0 || is.na(v)) self$limit() else v
    },
    special_cap = function() as.integer(self$config$special_cap %||% 8L),
    place_key = function(country, subfolder) {
      if (!length(country) || !length(subfolder)) return(character())
      paste(country, subfolder, sep = " || ")
    },
    inactive_keys = function() {
      k <- as.character(unlist(self$config$inactive_places))
      k[!grepl(" \\|\\| $", k) & nzchar(k)]
    },
    is_active = function(country, subfolder) !(self$place_key(country, subfolder) %in% self$inactive_keys()),

    # Save the admin's confirmed places configuration
    apply_places = function(default_limit, special_cap, country_limits, inactive_keys) {
      cl <- as.list(as.integer(country_limits))
      names(cl) <- names(country_limits)
      cl <- cl[!is.na(unlist(cl)) & unlist(cl) != as.integer(default_limit)]  # keep only real overrides
      self$config$limit_per_country <- as.integer(default_limit)
      self$config$special_cap <- as.integer(special_cap)
      self$config$country_limits <- cl
      self$config$inactive_places <- as.character(inactive_keys)
      self$config$places_applied_at <- format(Sys.time(), "%Y-%m-%d %H:%M")
      self$save_config()
      self$log("Places applied: default=", default_limit, " special=", special_cap,
               " overrides=", length(cl), " inactive=", length(inactive_keys))
      self$bump(c("cfg", "sel"))
    },

    bump = function(which = c("cfg", "sel")) {
      for (w in which) {
        rv <- self[[paste0(w, "_trigger")]]
        rv(shiny::isolate(rv()) + 1)
      }
    },

    log = function(...) log_event(self$log_file, ...),

    register_photo_folder = function() {
      if (self$root_ok()) {
        self$photo_prefix <- paste0("photos_", substr(hash_str(self$root()), 1, 8))
        shiny::addResourcePath(self$photo_prefix, self$root())
      }
    },

    # Returns "same", "set" or an error message
    set_root = function(path) {
      path <- trimws(path)
      if (!nzchar(path) || !dir.exists(path)) return("Esa carpeta no existe.")
      path <- normalizePath(path, winslash = "/")
      if (identical(path, self$root())) return("same")
      self$config$root_folder <- path
      self$save_config()
      self$photos <- NULL
      self$scanned_at <- NULL
      self$register_photo_folder()
      self$load_inventory()           # in case this folder was scanned before
      self$log("Main folder set to: ", path)
      self$bump(c("cfg", "sel"))
      "set"
    },

    update_rules = function(limit = NULL, cost, currency = "MXN") {
      if (!is.null(limit)) self$config$limit_per_country <- as.integer(limit)
      self$config$cost_per_photo <- as.numeric(cost)
      self$config$currency <- currency
      self$save_config()
      self$log("Rules updated: limit=", limit, " cost=", cost, " ", currency)
      self$bump(c("cfg", "sel"))
    },

    set_preference = function(key, value) {
      if (!identical(self$config[[key]], value)) {
        self$config[[key]] <- value
        self$save_config()
      }
    },

    # ------------------------------------------------------------- inventory
    has_inventory = function() !is.null(self$photos) && nrow(self$photos) > 0,

    load_inventory = function() {
      self$photos <- NULL
      self$scanned_at <- NULL
      if (!file.exists(self$inventory_file)) return(invisible(FALSE))
      inv <- tryCatch(readRDS(self$inventory_file), error = function(e) NULL)
      if (!is.null(inv) && identical(inv$root, self$root())) {
        self$photos <- inv$photos
        self$scanned_at <- inv$scanned_at
      }
      invisible(TRUE)
    },

    # Scan root -> country -> place (sub-folder; anything deeper counts for its place)
    scan = function(progress = NULL) {
      root <- self$root()
      if (!self$root_ok()) stop("La carpeta principal no está elegida o ya no existe.")

      dirs <- list.dirs(root, recursive = FALSE, full.names = FALSE)
      dirs <- dirs[!grepl("^[.@#$]", dirs)]
      dirs <- dirs[order(tolower(dirs))]
      pattern <- paste0("\\.(", paste(PHOTO_EXTENSIONS, collapse = "|"), ")$")

      loose_root <- list.files(root, pattern = pattern, ignore.case = TRUE)
      rows <- vector("list", length(dirs))

      for (i in seq_along(dirs)) {
        country <- dirs[i]
        if (!is.null(progress)) progress(i / max(1, length(dirs)), paste("Revisando", country))
        files <- list.files(file.path(root, country), pattern = pattern, recursive = TRUE,
                            ignore.case = TRUE, all.files = FALSE)
        # ignore hidden / system folders such as .thumbnails or @eaDir
        files <- files[!grepl("(^|/)[.@]", files)]
        if (length(files) == 0) next
        subfolder <- ifelse(grepl("/", files, fixed = TRUE), sub("/.*$", "", files), LOOSE_LABEL)
        rel <- paste(country, files, sep = "/")
        rows[[i]] <- data.frame(
          rel_path = rel,
          country = country,
          subfolder = subfolder,
          file_name = basename(files),
          mtime = as.numeric(file.mtime(file.path(root, rel))),
          stringsAsFactors = FALSE
        )
      }

      photos <- do.call(rbind, rows[!vapply(rows, is.null, logical(1))])
      if (is.null(photos)) {
        photos <- data.frame(rel_path = character(), country = character(), subfolder = character(),
                             file_name = character(), mtime = numeric(), stringsAsFactors = FALSE)
      }
      # Loose photos last in each country, everything else alphabetical
      ord <- order(tolower(photos$country), photos$subfolder == LOOSE_LABEL,
                   tolower(photos$subfolder), tolower(photos$rel_path))
      photos <- photos[ord, , drop = FALSE]
      photos$photo_id <- seq_len(nrow(photos))
      rownames(photos) <- NULL

      self$photos <- photos
      self$scanned_at <- Sys.time()
      saveRDS(list(root = root, scanned_at = self$scanned_at, photos = photos), self$inventory_file)

      # Drop selections whose file disappeared from disk
      cur <- self$selections$root_folder == root
      gone <- cur & !(self$selections$rel_path %in% photos$rel_path)
      n_gone <- sum(gone)
      if (n_gone > 0) {
        self$selections <- self$selections[!gone, , drop = FALSE]
        self$save_selections()
      }

      res <- list(
        countries = length(unique(photos$country)),
        places = nrow(unique(photos[, c("country", "subfolder")])),
        photos = nrow(photos),
        loose_root = length(loose_root),
        removed_selections = n_gone
      )
      self$log("Scan done: ", res$countries, " countries, ", res$places, " places, ",
               res$photos, " photos (", n_gone, " missing selections removed)")
      self$bump(c("cfg", "sel"))
      res
    },

    photo_by_id = function(id) {
      if (!self$has_inventory()) return(NULL)
      id <- suppressWarnings(as.integer(id))
      if (is.na(id) || id < 1 || id > nrow(self$photos)) return(NULL)
      as.list(self$photos[id, ])
    },

    # active_only = TRUE hides the city/region/event folders the admin de-selected
    photos_in = function(country, subfolder = ALL_PLACES, active_only = TRUE) {
      if (!self$has_inventory() || is.null(country)) return(self$photos[0, , drop = FALSE])
      p <- self$photos[self$photos$country == country, , drop = FALSE]
      if (active_only && length(self$inactive_keys())) {
        p <- p[!(self$place_key(p$country, p$subfolder) %in% self$inactive_keys()), , drop = FALSE]
      }
      if (!is.null(subfolder) && !identical(subfolder, ALL_PLACES)) {
        p <- p[p$subfolder == subfolder, , drop = FALSE]
      }
      p
    },

    # ------------------------------------------------------------ selections
    empty_selections = function() {
      data.frame(root_folder = character(), rel_path = character(), country = character(),
                 subfolder = character(), file_name = character(), selected_at = character(),
                 stringsAsFactors = FALSE)
    },

    load_selections = function() {
      s <- self$empty_selections()
      if (file.exists(self$selections_file)) {
        s <- tryCatch({
          x <- jsonlite::read_json(self$selections_file, simplifyVector = TRUE)
          if (length(x) == 0 || NROW(x) == 0) self$empty_selections() else {
            x <- as.data.frame(x, stringsAsFactors = FALSE)
            x[setdiff(names(self$empty_selections()), names(x))] <- ""
            x[, names(self$empty_selections())]
          }
        }, error = function(e) { self$log("Could not read selections: ", conditionMessage(e)); s })
      }
      self$selections <- s
    },

    save_selections = function() {
      safe_write(self$selections_file, function(p)
        jsonlite::write_json(self$selections, p, dataframe = "rows", pretty = TRUE))
    },

    current_selections = function() {
      s <- self$selections
      s[s$root_folder == self$root(), , drop = FALSE]
    },

    selected_paths = function() self$current_selections()$rel_path,
    is_selected = function(rel) rel %in% self$selected_paths(),

    toggle = function(rel) {
      ph <- self$photos[self$photos$rel_path == rel, , drop = FALSE]
      if (nrow(ph) == 0) return(list(ok = FALSE, reason = "missing"))
      root <- self$root()
      hit <- self$selections$root_folder == root & self$selections$rel_path == rel

      if (any(hit)) {
        self$selections <- self$selections[!hit, , drop = FALSE]
        self$save_selections()
        self$bump("sel")
        return(list(ok = TRUE, selected = FALSE))
      }

      cur <- self$current_selections()
      n_country <- sum(cur$country == ph$country)
      lim <- self$country_limit(ph$country)
      if (n_country >= lim) {
        return(list(ok = FALSE, reason = "limit", limit = lim, country = ph$country))
      }

      self$selections <- rbind(self$selections, data.frame(
        root_folder = root, rel_path = rel, country = ph$country, subfolder = ph$subfolder,
        file_name = ph$file_name, selected_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        stringsAsFactors = FALSE))
      self$save_selections()
      self$bump("sel")
      list(ok = TRUE, selected = TRUE)
    },

    clear_selections = function(country = NULL) {
      kill <- self$selections$root_folder == self$root()
      if (!is.null(country) && nzchar(country)) kill <- kill & self$selections$country == country
      n <- sum(kill)
      self$selections <- self$selections[!kill, , drop = FALSE]
      self$save_selections()
      self$log("Cleared ", n, " selections", if (!is.null(country)) paste0(" for ", country))
      self$bump(c("cfg", "sel"))
      n
    },

    # ------------------------------------------------------------- summaries
    # photos = photos in ACTIVE places; chosen = every chosen photo of the country
    # (photos chosen earlier in places that are now inactive still count)
    country_summary = function() {
      empty <- data.frame(country = character(), photos = integer(), chosen = integer(),
                          limit = integer(), country_limit = integer(), cost = numeric(),
                          stringsAsFactors = FALSE)
      if (!self$has_inventory()) return(empty)
      countries <- unique(self$photos$country)
      act <- !(self$place_key(self$photos$country, self$photos$subfolder) %in% self$inactive_keys())
      photos <- as.integer(table(factor(self$photos$country[act], levels = countries)))
      cur <- self$current_selections()
      chosen <- as.integer(table(factor(cur$country, levels = countries)))
      cur_inactive <- cur[self$place_key(cur$country, cur$subfolder) %in% self$inactive_keys(), , drop = FALSE]
      chosen_inactive <- as.integer(table(factor(cur_inactive$country, levels = countries)))
      climit <- vapply(countries, self$country_limit, integer(1), USE.NAMES = FALSE)
      data.frame(country = countries, photos = photos, chosen = chosen,
                 limit = pmin(climit, photos + chosen_inactive), country_limit = climit,
                 cost = chosen * self$cost(), stringsAsFactors = FALSE)
    },

    # One row per city/region/event folder of a country.
    # suggested: the country limit shared in proportion to the photos of the ACTIVE places,
    # with Museo/Galería/Vuelo folders capped at special_cap (recommendation only).
    subfolder_summary = function(country, include_inactive = FALSE) {
      empty <- data.frame(subfolder = character(), photos = integer(), share = numeric(),
                          suggested = integer(), chosen = integer(), active = logical(),
                          special = logical(), cap = integer(), stringsAsFactors = FALSE)
      p <- self$photos_in(country, active_only = FALSE)
      if (nrow(p) == 0) return(empty)
      subs <- unique(p$subfolder)
      counts <- as.integer(table(factor(p$subfolder, levels = subs)))
      active <- !(self$place_key(country, subs) %in% self$inactive_keys())
      special <- is_special_place(subs)
      cap <- ifelse(special, self$special_cap(), NA_integer_)
      suggested <- integer(length(subs))
      if (any(active)) {
        suggested[active] <- suggest_allocation_capped(counts[active], self$country_limit(country), cap[active])
      }
      share <- ifelse(active, counts / max(1, sum(counts[active])), NA_real_)
      cur <- self$current_selections()
      cur <- cur[cur$country == country, , drop = FALSE]
      out <- data.frame(
        subfolder = subs, photos = counts, share = share, suggested = suggested,
        chosen = as.integer(table(factor(cur$subfolder, levels = subs))),
        active = active, special = special, cap = as.integer(cap),
        stringsAsFactors = FALSE
      )
      if (include_inactive) out else out[out$active, , drop = FALSE]
    },

    subfolder_suggested = function(country, subfolder) {
      s <- self$subfolder_summary(country)
      s$suggested[match(subfolder, s$subfolder)] %||% 0L
    },

    subfolder_chosen = function(country, subfolder) {
      cur <- self$current_selections()
      sum(cur$country == country & cur$subfolder == subfolder)
    },

    overview = function() {
      if (!self$has_inventory()) return(NULL)
      out <- lapply(unique(self$photos$country), function(cn) {
        s <- self$subfolder_summary(cn, include_inactive = TRUE)
        d <- data.frame(cn, s$subfolder, ifelse(s$active, "Sí", "No"), s$photos,
                        ifelse(is.na(s$share), "—", sprintf("%.1f", 100 * s$share)),
                        ifelse(s$special, paste0("máx. ", s$cap), ""),
                        ifelse(s$active, as.character(s$suggested), "—"), s$chosen,
                        stringsAsFactors = FALSE)
        names(d) <- c("País", "Lugar", "Activo", "Fotos", "% del país", "Museo/Galería/Vuelo", "Sugeridas", "Elegidas")
        d
      })
      do.call(rbind, out)
    },

    # --------------------------------------------------------------- images
    original_url = function(rel) paste0(self$photo_prefix, "/", encode_rel_path(rel)),

    # Small ("thumb") or large preview. Generated once with magick and cached;
    # falls back to the original file if magick is not available or fails.
    image_url = function(rel, size = c("thumb", "large")) {
      size <- match.arg(size)
      if (!self$has_magick) return(self$original_url(rel))
      ph <- self$photos[self$photos$rel_path == rel, , drop = FALSE]
      mt <- if (nrow(ph)) ph$mtime[1] else 0
      fname <- paste0(hash_str(paste(self$root(), rel, mt, size, sep = "|")), ".jpg")
      out <- file.path(self$cache_dir, fname)
      if (!file.exists(out)) {
        geom <- if (size == "thumb") "640x640>" else "1600x1600>"
        ok <- tryCatch({
          img <- magick::image_read(file.path(self$root(), rel))[1]
          img <- magick::image_orient(img)
          img <- magick::image_scale(img, geom)
          img <- magick::image_background(img, "white")
          img <- magick::image_flatten(img)
          magick::image_write(img, out, format = "jpeg", quality = 82)
          rm(img)
          TRUE
        }, error = function(e) { self$log("Preview failed for ", rel, ": ", conditionMessage(e)); FALSE })
        if (!ok) return(self$original_url(rel))
      }
      paste0("thumbcache/", fname)
    },

    pregenerate_previews = function(progress = NULL) {
      if (!self$has_magick || !self$has_inventory()) return(0)
      n <- nrow(self$photos)
      for (i in seq_len(n)) {
        self$image_url(self$photos$rel_path[i], "thumb")
        if (!is.null(progress) && (i %% 10 == 0 || i == n)) progress(i / n, sprintf("%s de %s", i, n))
        if (i %% 200 == 0) gc(verbose = FALSE)
      }
      n
    },

    # --------------------------------------------------------------- export
    selection_table = function() {
      cur <- self$current_selections()
      if (nrow(cur) == 0) return(cur[, c("country", "subfolder", "file_name", "rel_path", "selected_at")])
      cur <- cur[order(cur$country, cur$subfolder, cur$rel_path), , drop = FALSE]
      cur$full_path <- file.path(self$root(), cur$rel_path)
      cur$cost <- self$cost()
      cur[, c("country", "subfolder", "file_name", "rel_path", "full_path", "cost", "selected_at")]
    },

    # Same table with Spanish column names, for the CSV files people open
    selection_table_es = function() {
      tab <- self$selection_table()
      es <- c(country = "País", subfolder = "Ciudad / región / evento", file_name = "Archivo",
              rel_path = "Ruta relativa", full_path = "Ruta completa", cost = "Costo",
              selected_at = "Fecha de elección")
      names(tab) <- es[names(tab)]
      tab
    },

    # Copy every chosen photo to <parent>/Imprimir/<País>/<Lugar - archivo>
    # Optional watermark "País – Lugar" in the bottom-right corner (copies only; originals untouched).
    print_folder = function(parent = self$config$print_parent) {
      if (is.null(parent) || !nzchar(parent)) return("")
      file.path(normalizePath(parent, winslash = "/", mustWork = FALSE), "Imprimir")
    },

    export_for_print = function(parent, mode = c("replace", "update"), watermark = NULL, progress = NULL) {
      mode <- match.arg(mode)
      if (is.null(parent) || !nzchar(parent) || !dir.exists(parent)) stop("La carpeta elegida para Imprimir no existe.")
      parent <- normalizePath(parent, winslash = "/")
      root <- self$root()
      out_dir <- file.path(parent, "Imprimir")
      inside <- function(a, b) startsWith(paste0(a, "/"), paste0(b, "/"))
      if (inside(out_dir, root)) {
        stop("Elija una ubicación FUERA de la carpeta principal de fotos (si no, las copias se volverían a contar al escanear).")
      }
      if (inside(root, out_dir)) stop("La carpeta principal de fotos no puede quedar dentro de la carpeta Imprimir.")

      if (mode == "replace" && dir.exists(out_dir)) {
        unlink(list.files(out_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE), recursive = TRUE)
      }
      dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

      tab <- self$selection_table()
      n <- nrow(tab); copied <- 0; failed <- character()
      used <- character()
      tab$print_file <- NA_character_
      for (i in seq_len(n)) {
        country <- tab$country[i]; place <- tab$subfolder[i]
        cdir <- file.path(out_dir, country)
        dir.create(cdir, showWarnings = FALSE)
        base <- tab$file_name[i]
        if (!identical(place, LOOSE_LABEL)) base <- paste(place, "-", base)
        if (!is.null(watermark)) base <- paste0(tools::file_path_sans_ext(base), ".jpg")
        # avoid name clashes (e.g. IMG_0001.jpg in two sub-folders of the same place)
        cand <- base; k <- 2
        while (tolower(file.path(country, cand)) %in% used) {
          cand <- paste0(tools::file_path_sans_ext(base), " (", k, ").", tools::file_ext(base)); k <- k + 1
        }
        used <- c(used, tolower(file.path(country, cand)))
        target <- file.path(cdir, cand)

        ok <- tryCatch({
          if (is.null(watermark)) {
            file.copy(tab$full_path[i], target, overwrite = TRUE, copy.date = TRUE)
          } else {
            img <- magick::image_read(tab$full_path[i])[1]
            img <- magick::image_orient(img)
            img <- add_watermark(img, watermark_text(country, place), watermark$family,
                                 watermark$size, watermark$bold, watermark$style)
            img <- magick::image_flatten(magick::image_background(img, "white"))
            magick::image_write(img, target, format = "jpeg", quality = 95)
            rm(img)
            TRUE
          }
        }, error = function(e) { self$log("Print copy failed for ", tab$rel_path[i], ": ", conditionMessage(e)); FALSE })
        if (isTRUE(ok)) { copied <- copied + 1; tab$print_file[i] <- file.path(country, cand) }
        else failed <- c(failed, tab$rel_path[i])
        if (!is.null(progress)) progress(i / n, sprintf("%s de %s · %s", i, n, tab$file_name[i]))
        if (i %% 20 == 0) gc(verbose = FALSE)
      }

      lista <- data.frame(
        `País` = tab$country, `Ciudad / región / evento` = tab$subfolder,
        `Archivo en Imprimir` = tab$print_file, `Foto original` = tab$full_path,
        `Costo` = tab$cost, check.names = FALSE, stringsAsFactors = FALSE)
      write_csv_utf8(lista, file.path(out_dir, "lista_para_imprimir.csv"))
      cs <- self$country_summary()
      cs <- cs[cs$chosen > 0, c("country", "chosen", "cost")]
      cs <- rbind(cs, data.frame(country = "TOTAL", chosen = sum(cs$chosen), cost = sum(cs$cost)))
      names(cs) <- c("País", "Fotos elegidas", paste0("Costo (", self$currency(), ")"))
      write_csv_utf8(cs, file.path(out_dir, "resumen_del_pedido.csv"))
      self$log("Exported ", copied, " photos to ", out_dir, if (!is.null(watermark)) " (with watermark)")
      list(copied = copied, total = n, folder = out_dir, failed = failed,
           countries = length(unique(tab$country)))
    },

    print = function() {
      cat("  • Main folder:", if (nzchar(self$root())) self$root() else "(not set yet)", "\n")
      cat("  • Photos in last scan:", if (self$has_inventory()) nrow(self$photos) else 0, "\n")
      cat("  • Photos chosen:", nrow(self$current_selections()), "\n")
      cat("  • Limit per country:", self$limit(), " | Cost per photo:", self$cost(), self$currency(), "\n")
      cat("  • Preview engine:", if (self$has_magick) "magick (cached thumbnails)" else "original files", "\n")
      cat("  • Watermark fonts:", if (length(self$wm_fonts)) paste(names(self$wm_fonts), collapse = ", ") else "(ragg/systemfonts not installed)", "\n")
      invisible(self)
    }
  )
)
