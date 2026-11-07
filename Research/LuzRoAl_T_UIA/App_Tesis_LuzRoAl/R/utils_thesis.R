# ============================================================================
# THESIS MANAGER - R6 CLASS
# Shared state for all modules + persistence (like PhotoManager in the photo app)
#
# App folder  data/
#   config.json        admin settings (work folder, names, Claude defaults, …)
#   .claude_key        the Claude key, only if "Recordar la clave" is ticked
#   usage.json         number of Claude calls and tokens
#   app.log            activity / error log
#
# Work folder (chosen by the admin; default data/mi_tesis/)
#   proyecto.json      EVERYTHING the user writes (ideas, outline, texts, feedback)
#   textos/            readable copies (.md) of each part, rewritten on every save
#   retroalimentacion/ every Claude answer as a .md file
#   versiones/         snapshots saved with "Guardar versión"
#   respaldos/         automatic daily copy of proyecto.json (+ "Hacer respaldo ahora")
#   exportar/          the full thesis (.md / .html / .docx)
# ============================================================================

ThesisManager <- R6::R6Class(
  "ThesisManager",
  public = list(
    data_dir = NULL,
    config_file = NULL,
    key_file = NULL,
    usage_file = NULL,
    log_file = NULL,

    config = NULL,
    project = NULL,
    claude = NULL,

    cfg_trigger = NULL,     # admin settings changed
    proj_trigger = NULL,    # project content changed
    claude_trigger = NULL,  # connection state / usage changed
    fb_trigger = NULL,      # a new Claude answer was stored
    load_trigger = NULL,    # a (different) project file was loaded
    nav_request = NULL,     # reactiveVal: tab name another module wants to open

    initialize = function(data_dir = "data") {
      dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
      self$data_dir <- normalizePath(data_dir, winslash = "/")
      self$config_file <- file.path(self$data_dir, "config.json")
      self$key_file <- file.path(self$data_dir, ".claude_key")
      self$usage_file <- file.path(self$data_dir, "usage.json")
      self$log_file <- file.path(self$data_dir, "app.log")

      self$cfg_trigger <- shiny::reactiveVal(0)
      self$proj_trigger <- shiny::reactiveVal(0)
      self$claude_trigger <- shiny::reactiveVal(0)
      self$fb_trigger <- shiny::reactiveVal(0)
      self$load_trigger <- shiny::reactiveVal(0)
      self$nav_request <- shiny::reactiveVal(NULL)

      self$load_config()
      self$claude <- ClaudeClient$new()
      self$init_claude()
      self$load_project()
      self$auto_backup()
    },

    log = function(...) log_event(self$log_file, ...),

    # ---------------------------------------------------------------- config
    default_config = function() {
      list(
        admin_code = "718",
        work_folder = "",
        author_name = "",
        generacion = "",
        titulo_grado = paste("Licenciatura en", CARRERA),
        universidad = UNIVERSIDAD,
        citation_style = "APA 7.ª edición",
        feedback_style = "detallado",
        extra_instructions = "",
        include_context = TRUE,
        font_scale = 110,
        autosave_secs = 2,
        chapter_target = 4000,
        claude_model = "claude-sonnet-5-5",
        claude_max_tokens = 4000,
        claude_timeout = 300,
        remember_key = FALSE
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
      safe_write(self$config_file, function(p) jsonlite::write_json(self$config, p, auto_unbox = TRUE, pretty = TRUE))
      bump(self$cfg_trigger)
    },

    set_config = function(...) {
      vals <- list(...)
      for (n in names(vals)) self$config[[n]] <- vals[[n]]
      self$save_config()
    },

    font_scale = function() as.numeric(self$config$font_scale %||% 110),
    admin_code = function() as.character(self$config$admin_code %||% "718"),

    # ---------------------------------------------------------------- Claude
    init_claude = function() {
      key <- ""
      if (file.exists(self$key_file)) key <- trimws(read_utf8(self$key_file))
      if (!nzchar(key)) key <- Sys.getenv("ANTHROPIC_API_KEY")
      self$claude$set_credentials(api_key = if (nzchar(key)) key else NULL,
                                  model = self$config$claude_model,
                                  max_tokens = self$config$claude_max_tokens,
                                  timeout = self$config$claude_timeout)
      if (file.exists(self$usage_file)) {
        u <- tryCatch(jsonlite::read_json(self$usage_file), error = function(e) list())
        self$claude$calls <- as.integer(u$calls %||% 0)
        self$claude$tokens_in <- as.numeric(u$tokens_in %||% 0)
        self$claude$tokens_out <- as.numeric(u$tokens_out %||% 0)
      }
    },

    remember_key = function(remember) {
      if (isTRUE(remember) && self$claude$has_key()) {
        write_utf8(self$claude$api_key, self$key_file)
      } else if (file.exists(self$key_file)) {
        unlink(self$key_file)
      }
      self$set_config(remember_key = isTRUE(remember))
    },

    save_usage = function() {
      safe_write(self$usage_file, function(p) jsonlite::write_json(
        list(calls = self$claude$calls, tokens_in = self$claude$tokens_in, tokens_out = self$claude$tokens_out),
        p, auto_unbox = TRUE))
    },

    # One call to Claude with the shared system prompt; stores the exchange as feedback
    ask = function(prompt, tab, key, action, title, max_tokens = NULL, store = TRUE) {
      ctx <- if (isTRUE(self$config$include_context)) self$project_context() else ""
      sys <- build_system_prompt(self$config, ctx)
      msgs <- list(list(role = "user", content = prompt))
      res <- self$claude$chat(system = sys, messages = msgs, max_tokens = max_tokens)
      self$save_usage()
      bump(self$claude_trigger)
      fb <- list(id = new_id("fb"), time = now_str(), tab = tab, key = key, action = action, title = title,
                 model = res$model, messages = list(list(role = "user", content = prompt),
                                                    list(role = "assistant", content = res$text)))
      if (store) self$add_feedback(fb)
      fb
    },

    # Continue the conversation of a stored answer
    follow_up = function(fb_id, question) {
      i <- self$feedback_index(fb_id)
      if (is.na(i)) stop("No se encontró esa conversación.")
      fb <- self$project$feedback[[i]]
      msgs <- c(fb$messages, list(list(role = "user", content = question)))
      ctx <- if (isTRUE(self$config$include_context)) self$project_context() else ""
      res <- self$claude$chat(system = build_system_prompt(self$config, ctx), messages = msgs)
      self$save_usage()
      bump(self$claude_trigger)
      fb$messages <- c(msgs, list(list(role = "assistant", content = res$text)))
      fb$time <- now_str()
      self$project$feedback[[i]] <- fb
      self$write_feedback_md(fb)
      self$save_project()
      bump(self$fb_trigger)
      fb
    },

    # --------------------------------------------------------- work folder
    default_work_dir = function() file.path(self$data_dir, "mi_tesis"),
    work_dir = function() {
      wf <- self$config$work_folder %||% ""
      if (nzchar(wf) && dir.exists(wf)) wf else self$default_work_dir()
    },
    work_dir_ok = function() {
      wf <- self$config$work_folder %||% ""
      !nzchar(wf) || dir.exists(wf)
    },
    project_file = function(dir = self$work_dir()) file.path(dir, "proyecto.json"),

    ensure_dirs = function(dir = self$work_dir()) {
      for (d in c("", "textos", "retroalimentacion", "versiones", "respaldos", "exportar"))
        dir.create(file.path(dir, d), showWarnings = FALSE, recursive = TRUE)
    },

    # Change where everything is saved. mode = "copy" (take my work there) or "open" (use what is there)
    set_work_folder = function(path, mode = c("copy", "open")) {
      mode <- match.arg(mode)
      path <- normalizePath(path, winslash = "/", mustWork = TRUE)
      if (mode == "copy") {
        old <- self$work_dir()
        self$ensure_dirs(path)
        for (sub in c("textos", "retroalimentacion", "versiones", "respaldos", "exportar")) {
          files <- list.files(file.path(old, sub), full.names = TRUE)
          if (length(files)) file.copy(files, file.path(path, sub), overwrite = FALSE)
        }
        self$config$work_folder <- path
        self$save_config()
        self$save_project()
        self$log("Work folder set (copy): ", path)
      } else {
        self$config$work_folder <- path
        self$save_config()
        self$load_project()
        self$log("Work folder set (open): ", path)
      }
      bump(self$proj_trigger)
      bump(self$fb_trigger)
      invisible(TRUE)
    },

    # ---------------------------------------------------------------- project
    empty_project = function() {
      list(
        version = 1, created = now_str(), updated = now_str(),
        guide_read = FALSE,
        ideas = list(),
        chosen_idea = "",
        outline = list(titulo = "", pregunta = "", hipotesis = "", objetivo_general = "",
                       objetivos_especificos = "", justificacion = "", marco_teorico = "",
                       metodologia = "", alcances = "", chapters = list()),
        sections = list(),
        feedback = list()
      )
    },

    load_project = function() {
      dir <- self$work_dir()
      self$ensure_dirs(dir)
      pf <- self$project_file(dir)
      prj <- self$empty_project()
      if (file.exists(pf)) {
        saved <- tryCatch(jsonlite::read_json(pf, simplifyVector = FALSE),
                          error = function(e) { self$log("Could not read project: ", conditionMessage(e)); NULL })
        # shallow merge (modifyList would drop unnamed lists such as ideas, chapters and feedback)
        if (!is.null(saved)) for (n in names(saved)) {
          if (n == "outline" && is.list(saved$outline)) {
            for (m in names(saved$outline)) prj$outline[[m]] <- saved$outline[[m]]
          } else prj[[n]] <- saved[[n]]
        }
      }
      # empty JSON arrays come back as list(); make sure the containers have the right type
      if (!is.list(prj$sections)) prj$sections <- list()
      if (!is.list(prj$outline$chapters)) prj$outline$chapters <- list()
      self$project <- prj
      bump(self$proj_trigger)
      bump(self$load_trigger)
    },

    save_project = function(write_texts = TRUE) {
      dir <- self$work_dir()
      self$ensure_dirs(dir)
      self$project$updated <- now_str()
      prj <- self$project
      if (length(prj$sections) == 0) prj$sections <- structure(list(), names = character())
      safe_write(self$project_file(dir), function(p) jsonlite::write_json(prj, p, auto_unbox = TRUE, pretty = TRUE, null = "null"))
      if (write_texts) tryCatch(self$write_text_files(), error = function(e) self$log("write_text_files: ", conditionMessage(e)))
      invisible(TRUE)
    },

    touch = function() bump(self$proj_trigger),

    auto_backup = function() {
      dir <- file.path(self$work_dir(), "respaldos")
      pf <- self$project_file()
      if (!file.exists(pf)) return(invisible(NULL))
      today <- format(Sys.Date(), "%Y%m%d")
      if (!any(grepl(paste0("^proyecto_", today), list.files(dir)))) {
        file.copy(pf, file.path(dir, sprintf("proyecto_%s_auto.json", format(Sys.time(), "%Y%m%d_%H%M%S"))))
        self$log("Daily backup created")
      }
    },

    backup_now = function() {
      self$save_project()
      dest <- file.path(self$work_dir(), "respaldos", sprintf("proyecto_%s.json", format(Sys.time(), "%Y%m%d_%H%M%S")))
      file.copy(self$project_file(), dest)
      dest
    },

    # ---------------------------------------------------------------- sections (texts)
    get_text = function(key) self$project$sections[[key]]$text %||% "",
    get_updated = function(key) self$project$sections[[key]]$updated %||% "",
    set_text = function(key, text) {
      if (identical(self$get_text(key), text)) return(invisible(FALSE))
      self$project$sections[[key]] <- list(text = text, updated = now_str(), words = word_count(text))
      self$save_project()
      self$touch()
      invisible(TRUE)
    },
    words = function(key) word_count(self$get_text(key)),

    snapshot = function(key, label = "") {
      txt <- self$get_text(key)
      if (!nzchar(trimws(txt))) return(NULL)
      f <- file.path(self$work_dir(), "versiones", sprintf("%s_%s.md", key, format(Sys.time(), "%Y%m%d_%H%M%S")))
      write_utf8(c(if (nzchar(label)) paste0("<!-- ", label, " -->"), txt), f)
      f
    },
    versions = function(key) {
      f <- list.files(file.path(self$work_dir(), "versiones"), pattern = paste0("^", key, "_\\d{8}_\\d{6}\\.md$"), full.names = TRUE)
      rev(sort(f))
    },

    # ---------------------------------------------------------------- ideas
    ideas = function() self$project$ideas %||% list(),
    idea_index = function(id) {
      ids <- vapply(self$ideas(), function(x) x$id %||% "", character(1))
      match(id, ids)
    },
    get_idea = function(id) { i <- self$idea_index(id); if (is.na(i)) NULL else self$project$ideas[[i]] },
    add_idea = function(titulo, descripcion = "", experiencia = "", materias = character(), origen = "usuario") {
      idea <- list(id = new_id("idea"), titulo = titulo, descripcion = descripcion, experiencia = experiencia,
                   materias = as.list(materias), estado = "nueva", origen = origen, created = now_str())
      self$project$ideas <- c(self$ideas(), list(idea))
      self$save_project(); self$touch()
      idea$id
    },
    update_idea = function(id, ...) {
      i <- self$idea_index(id); if (is.na(i)) return(invisible(FALSE))
      vals <- list(...)
      for (n in names(vals)) self$project$ideas[[i]][[n]] <- vals[[n]]
      self$save_project(); self$touch()
      invisible(TRUE)
    },
    delete_idea = function(id) {
      i <- self$idea_index(id); if (is.na(i)) return(invisible(FALSE))
      self$project$ideas[[i]] <- NULL
      if (identical(self$project$chosen_idea, id)) self$project$chosen_idea <- ""
      self$save_project(); self$touch()
      invisible(TRUE)
    },
    choose_idea = function(id) {
      self$project$chosen_idea <- id
      for (i in seq_along(self$project$ideas)) {
        if (identical(self$project$ideas[[i]]$id, id)) self$project$ideas[[i]]$estado <- "elegida"
        else if (identical(self$project$ideas[[i]]$estado, "elegida")) self$project$ideas[[i]]$estado <- "explorando"
      }
      self$save_project(); self$touch()
    },
    chosen = function() { id <- self$project$chosen_idea %||% ""; if (nzchar(id)) self$get_idea(id) else NULL },

    # ---------------------------------------------------------------- outline
    outline = function() self$project$outline,
    chapters = function() self$project$outline$chapters %||% list(),
    set_outline = function(fields, chapters = NULL) {
      for (n in names(fields)) self$project$outline[[n]] <- fields[[n]]
      if (!is.null(chapters)) self$project$outline$chapters <- chapters
      self$save_project(); self$touch()
    },
    outline_text = function() {
      o <- self$outline()
      caps <- self$chapters()
      lab <- c(titulo = "Título tentativo", pregunta = "Pregunta de investigación", hipotesis = "Hipótesis / tesis central",
               objetivo_general = "Objetivo general", objetivos_especificos = "Objetivos específicos",
               justificacion = "Justificación", marco_teorico = "Marco teórico", metodologia = "Metodología y fuentes",
               alcances = "Alcances (lugar, periodo, actores)")
      parts <- vapply(names(lab), function(n) paste0("**", lab[[n]], ":** ", o[[n]] %||% ""), character(1))
      capt <- if (length(caps)) paste0(seq_along(caps), ". ", vapply(caps, function(c) paste0(c$titulo, " — ", c$descripcion %||% ""), character(1)), collapse = "\n") else "(sin capítulos)"
      paste0(paste(parts, collapse = "\n"), "\n**Capítulos:**\n", capt)
    },
    outline_pct = function() {
      o <- self$outline()
      f <- c("titulo", "pregunta", "hipotesis", "objetivo_general", "objetivos_especificos",
             "justificacion", "marco_teorico", "metodologia", "alcances")
      filled <- sum(vapply(f, function(n) nzchar(trimws(o[[n]] %||% "")), logical(1)))
      round(100 * (filled + min(3, length(self$chapters()))) / (length(f) + 3))
    },

    # Short summary sent to Claude with every request
    project_context = function() {
      out <- character()
      t <- self$chosen()
      if (!is.null(t)) out <- c(out, paste0("Tema elegido: ", t$titulo, ". ", t$descripcion %||% ""),
                                if (nzchar(t$experiencia %||% "")) paste0("Experiencia personal relacionada: ", t$experiencia))
      if (self$outline_pct() > 0) out <- c(out, "Bosquejo:", self$outline_text())
      clip_text(paste(out, collapse = "\n"), 6000)
    },

    # ---------------------------------------------------------------- feedback
    feedback_index = function(id) {
      ids <- vapply(self$project$feedback %||% list(), function(x) x$id %||% "", character(1))
      match(id, ids)
    },
    add_feedback = function(fb) {
      self$project$feedback <- c(self$project$feedback %||% list(), list(fb))
      self$write_feedback_md(fb)
      self$save_project(write_texts = FALSE)
      bump(self$fb_trigger)
    },
    delete_feedback = function(id) {
      i <- self$feedback_index(id); if (is.na(i)) return(invisible(FALSE))
      self$project$feedback[[i]] <- NULL
      self$save_project(write_texts = FALSE)
      bump(self$fb_trigger)
    },
    feedback_for = function(keys = NULL, tab = NULL) {
      fb <- self$project$feedback %||% list()
      keep <- vapply(fb, function(x) (is.null(keys) || (x$key %||% "") %in% keys) && (is.null(tab) || identical(x$tab, tab)), logical(1))
      rev(fb[keep])
    },
    write_feedback_md = function(fb) {
      f <- file.path(self$work_dir(), "retroalimentacion", paste0(fb$id, "_", fb$action, ".md"))
      body <- vapply(fb$messages, function(m) paste0("### ", if (m$role == "user") "Pregunta" else "Claude", "\n\n", m$content), character(1))
      tryCatch(write_utf8(c(paste0("# ", fb$title), paste0("*", fmt_fecha(fb$time), " · ", fb$tab, "*"), "", body), f),
               error = function(e) self$log("feedback md: ", conditionMessage(e)))
    },

    # ---------------------------------------------------------------- progress
    part_target = function(parts) sum(vapply(parts, function(p) as.numeric(p$meta %||% 0), numeric(1))),
    parts_words = function(parts) sum(vapply(parts, function(p) self$words(p$key), numeric(1))),
    chapter_key = function(ch_id) paste0("cap_", ch_id),
    chapters_words = function() sum(vapply(self$chapters(), function(c) self$words(self$chapter_key(c$id)), numeric(1))),
    chapters_target = function() max(1, length(self$chapters())) * as.numeric(self$config$chapter_target %||% 4000),

    progress = function() {
      pct <- function(a, b) if (b <= 0) 0 else min(100, round(100 * a / b))
      st <- list(
        claude   = if (self$claude$connected) 100 else 0,
        guia     = if (isTRUE(self$project$guide_read)) 100 else 0,
        ideas    = pct(length(self$ideas()), 3),
        tema     = if (!is.null(self$chosen())) 100 else 0,
        bosquejo = self$outline_pct(),
        intro    = pct(self$parts_words(INTRO_PARTS), self$part_target(INTRO_PARTS)),
        caps     = if (length(self$chapters())) pct(self$chapters_words(), self$chapters_target()) else 0,
        concl    = pct(self$parts_words(CONCL_PARTS), self$part_target(CONCL_PARTS))
      )
      w <- c(claude = 3, guia = 4, ideas = 8, tema = 8, bosquejo = 15, intro = 15, caps = 35, concl = 12)
      overall <- round(sum(unlist(st)[names(w)] * w) / sum(w))
      nxt <- "¡Felicidades! Revise y exporte su tesis."
      for (r in RUTA) if (st[[r$key]] < 100) { nxt <- paste0("Siguiente: ", r$titulo); break }
      list(steps = st, overall = overall, next_step = nxt)
    },

    # ---------------------------------------------------------------- export
    write_text_files = function() {
      dir <- file.path(self$work_dir(), "textos")
      parts_md <- function(parts) paste(vapply(parts, function(p)
        paste0("## ", p$titulo, "\n\n", self$get_text(p$key)), character(1)), collapse = "\n\n")
      write_utf8(c("# Bosquejo", "", self$outline_text()), file.path(dir, "00_bosquejo.md"))
      write_utf8(c("# Introducción", "", parts_md(INTRO_PARTS)), file.path(dir, "01_introduccion.md"))
      caps <- self$chapters()
      old <- list.files(dir, pattern = "^02_capitulo_.*\\.md$", full.names = TRUE)
      keep <- character()
      for (i in seq_along(caps)) {
        f <- file.path(dir, sprintf("02_capitulo_%02d.md", i)); keep <- c(keep, f)
        write_utf8(c(sprintf("# Capítulo %d. %s", i, caps[[i]]$titulo), "", self$get_text(self$chapter_key(caps[[i]]$id))), f)
      }
      unlink(setdiff(old, keep))
      write_utf8(c("# Conclusiones", "", parts_md(CONCL_PARTS)), file.path(dir, "03_conclusiones.md"))
      ideas <- self$ideas()
      write_utf8(c("# Mis ideas", "", vapply(ideas, function(x)
        paste0("## ", x$titulo, if (identical(x$id, self$project$chosen_idea)) " ⭐ (mi tema)" else "", "\n\n",
               x$descripcion %||% "", "\n\n*Experiencia:* ", x$experiencia %||% ""), character(1))),
        file.path(dir, "ideas.md"))
    },

    # Full thesis as Markdown (used for .md, .html and .docx)
    thesis_markdown = function() {
      cfg <- self$config; o <- self$outline(); caps <- self$chapters()
      title <- if (nzchar(o$titulo %||% "")) o$titulo else "(Título de la tesis)"
      parts_md <- function(parts) paste(vapply(parts, function(p) {
        t <- self$get_text(p$key); if (!nzchar(trimws(t))) return("")
        paste0("### ", sub("^\\d+\\.\\s*", "", p$titulo), "\n\n", t)
      }, character(1)), collapse = "\n\n")
      cap_md <- if (length(caps)) paste(vapply(seq_along(caps), function(i)
        paste0("## Capítulo ", i, ". ", caps[[i]]$titulo, "\n\n", self$get_text(self$chapter_key(caps[[i]]$id))),
        character(1)), collapse = "\n\n") else ""
      concl_parts <- Filter(function(p) p$key != "concl_biblio", CONCL_PARTS)
      paste0(
        "# ", title, "\n\n",
        "**Tesis para obtener el título de ", cfg$titulo_grado, "**\n\n",
        cfg$universidad, "\n\n",
        if (nzchar(cfg$author_name %||% "")) paste0("Presenta: **", cfg$author_name, "**\n\n") else "",
        format(Sys.Date(), "%Y"), "\n\n---\n\n",
        "## Introducción\n\n", parts_md(INTRO_PARTS), "\n\n",
        cap_md, "\n\n",
        "## Conclusiones\n\n", parts_md(concl_parts), "\n\n",
        "## Bibliografía\n\n", self$get_text("concl_biblio"), "\n"
      )
    },

    export_files = function() {
      dir <- file.path(self$work_dir(), "exportar")
      stamp <- format(Sys.time(), "%Y%m%d_%H%M")
      md <- self$thesis_markdown()
      f_md <- file.path(dir, paste0("Mi_tesis_", stamp, ".md"))
      write_utf8(md, f_md)
      f_html <- file.path(dir, paste0("Mi_tesis_", stamp, ".html"))
      write_utf8(thesis_html(md, self$outline()$titulo %||% "Mi tesis"), f_html)
      f_docx <- tryCatch(export_docx(md, file.path(dir, paste0("Mi_tesis_", stamp, ".docx"))), error = function(e) {
        self$log("docx export: ", conditionMessage(e)); NULL })
      Filter(Negate(is.null), list(md = f_md, html = f_html, docx = f_docx))
    },

    print = function() {
      cat("Work folder:", self$work_dir(), "\n")
      cat("Ideas:", length(self$ideas()), " · Chapters:", length(self$chapters()),
          " · Claude key:", self$claude$masked_key(), if (self$claude$mock) "(MOCK)" else "", "\n")
    }
  )
)

# Printable HTML page for the full thesis
thesis_html <- function(md, title) {
  body <- as.character(shiny::markdown(md))
  paste0('<!doctype html><html lang="es"><head><meta charset="utf-8"><title>', htmltools::htmlEscape(title), '</title>',
         '<style>body{font-family:"Times New Roman",Georgia,serif;max-width:800px;margin:40px auto;padding:0 24px;',
         'font-size:13pt;line-height:1.6;color:#222} h1{text-align:center;font-size:24pt;margin-top:120px}',
         'h2{page-break-before:always;font-size:18pt;border-bottom:1px solid #999;padding-bottom:4px}',
         'h3{font-size:14pt} p{text-align:justify} hr{display:none}</style></head><body>', body, '</body></html>')
}

# Word file with the officer package (optional). Simple Markdown: #, ##, ###, paragraphs, lists, **bold**
export_docx <- function(md, path) {
  if (!requireNamespace("officer", quietly = TRUE)) return(NULL)
  doc <- officer::read_docx()
  lines <- strsplit(md, "\n", fixed = TRUE)[[1]]
  para <- character()
  flush <- function() {
    if (length(para)) {
      txt <- gsub("\\*\\*(.*?)\\*\\*", "\\1", paste(para, collapse = " "))
      doc <<- officer::body_add_par(doc, txt, style = "Normal")
      para <<- character()
    }
  }
  first_h2 <- TRUE
  for (ln in lines) {
    if (grepl("^# ", ln)) { flush(); doc <- officer::body_add_par(doc, sub("^# ", "", ln), style = "heading 1") }
    else if (grepl("^## ", ln)) {
      flush()
      if (!first_h2) doc <- officer::body_add_break(doc)
      first_h2 <- FALSE
      doc <- officer::body_add_par(doc, sub("^## ", "", ln), style = "heading 2")
    }
    else if (grepl("^### ", ln)) { flush(); doc <- officer::body_add_par(doc, sub("^### ", "", ln), style = "heading 3") }
    else if (grepl("^\\s*([-*]|\\d+\\.)\\s+", ln)) { flush(); doc <- officer::body_add_par(doc, gsub("\\*\\*(.*?)\\*\\*", "\\1", sub("^\\s*[-*]\\s+", "• ", ln)), style = "Normal") }
    else if (grepl("^---\\s*$", ln)) { flush(); doc <- officer::body_add_break(doc) }
    else if (!nzchar(trimws(ln))) flush()
    else para <- c(para, ln)
  }
  flush()
  print(doc, target = path)
  path
}
