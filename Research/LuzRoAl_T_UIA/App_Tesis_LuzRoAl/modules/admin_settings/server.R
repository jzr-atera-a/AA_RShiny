admin_settings_server <- function(id, tm, parent_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    setup_common(input, parent_session)
    unlocked <- reactiveVal(FALSE)
    pending_path <- reactiveVal(NULL)
    pending_backup <- reactiveVal(NULL)
    exported <- reactiveVal(NULL)

    volumes <- get_volume_roots()
    shinyFiles::shinyDirChoose(input, "workDir", roots = volumes, session = session)

    # ------------------------------------------------------------ lock screen
    locked_ui <- function() {
      fluidRow(column(12, box(
        title = "Acceso del administrador", status = "primary", solidHeader = TRUE, width = NULL,
        div(class = "lock-box",
            h3("🔒 Esta sección es solo para el administrador"),
            passwordInput(ns("code"), "Escriba el código de administrador:", width = "100%"),
            actionButton(ns("unlock"), "Entrar", class = "btn-primary btn-big", style = "width: 100%;"))
      )))
    }

    admin_ui <- function() {
      cfg <- tm$config
      tagList(
        div(class = "admin-topbar",
            span(icon("unlock"), " Sección de administrador abierta"),
            actionButton(ns("lock"), "Bloquear Administrador", class = "btn-danger", icon = icon("lock"))),
        fluidRow(
          column(7,
            box(title = "1. Carpeta de trabajo: dónde se guarda todo", status = "primary", solidHeader = TRUE, width = NULL,
                p("Elija la carpeta donde la app irá guardando la tesis mientras la persona escribe: ideas, bosquejo, textos, comentarios de Claude, versiones y respaldos."),
                uiOutput(ns("workStatus")),
                br(),
                fluidRow(
                  column(6, shinyFiles::shinyDirButton(ns("workDir"), "Elegir carpeta…", "Seleccione la carpeta de trabajo de la tesis",
                                                       class = "btn-info btn-big", style = "width: 100%;", icon = icon("folder-open"))),
                  column(6, actionButton(ns("openFolder"), "Abrir la carpeta", class = "btn-default btn-big", style = "width: 100%;", icon = icon("external-link-alt")))),
                tags$details(style = "margin-top: 10px;",
                  tags$summary(style = "cursor: pointer; font-size: 16px; color: #667eea;", "…o escriba / pegue la ruta de la carpeta"),
                  br(),
                  textInput(ns("workPath"), NULL, value = cfg$work_folder %||% "", width = "100%",
                            placeholder = "p. ej. C:/Users/Luz/Documents/Mi tesis"),
                  actionButton(ns("useTyped"), "Usar esta ruta", class = "btn-primary admin-btn")),
                div(class = "reference-box",
                    h4(style = "margin-top:0; color:#4f46e5;", "🗂 Qué hay dentro de la carpeta"),
                    tags$ul(
                      tags$li(tags$code("proyecto.json"), " – todo el trabajo (se actualiza cada vez que se guarda)"),
                      tags$li(tags$code("textos/"), " – copia legible de cada parte (.md, se abre con cualquier editor)"),
                      tags$li(tags$code("retroalimentacion/"), " – cada respuesta de Claude"),
                      tags$li(tags$code("versiones/"), " – versiones guardadas de cada parte"),
                      tags$li(tags$code("respaldos/"), " – una copia automática al día"),
                      tags$li(tags$code("exportar/"), " – la tesis completa en Word, HTML y Markdown")))),
            box(title = "2. Datos de la tesis", status = "primary", solidHeader = TRUE, width = NULL,
                fluidRow(
                  column(6, textInput(ns("author"), "Nombre de quien escribe la tesis:", value = cfg$author_name, width = "100%")),
                  column(6, textInput(ns("generacion"), "Generación (años en la IBERO):", value = cfg$generacion, width = "100%",
                                      placeholder = "p. ej. 1977–1981"))),
                textInput(ns("grado"), "Título que se obtiene:", value = cfg$titulo_grado, width = "100%"),
                textInput(ns("universidad"), "Universidad:", value = cfg$universidad, width = "100%"),
                selectInput(ns("citation"), "Estilo de citas:", width = "100%",
                            choices = c("APA 7.ª edición", "Chicago (autor-fecha)", "Harvard", "MLA"), selected = cfg$citation_style)),
            box(title = "3. Cómo da Claude sus comentarios", status = "primary", solidHeader = TRUE, width = NULL,
                radioButtons(ns("fbStyle"), "Estilo de retroalimentación:", choices = FEEDBACK_STYLES, selected = cfg$feedback_style),
                checkboxInput(ns("context"), "Mandar a Claude el tema y el bosquejo con cada pregunta (recomendado)", isTRUE(cfg$include_context)),
                textAreaInput(ns("extra"), "Indicaciones adicionales para Claude (opcional):", value = cfg$extra_instructions %||% "",
                              rows = 3, width = "100%",
                              placeholder = "p. ej. Mi asesora pide capítulos de no más de 25 páginas. Recuérdame citar el DOF.")),
            box(title = "4. Metas, guardado y tamaño de letra", status = "primary", solidHeader = TRUE, width = NULL,
                fluidRow(
                  column(6, numericInput(ns("chTarget"), "Meta de palabras por capítulo:", value = cfg$chapter_target, min = 500, step = 500, width = "100%")),
                  column(6, numericInput(ns("autosave"), "Guardar solito después de (segundos sin escribir):", value = cfg$autosave_secs, min = 1, max = 30, width = "100%"))),
                sliderInput(ns("fontScale"), "Tamaño de toda la pantalla:", min = 80, max = 150, step = 5, value = cfg$font_scale, post = " %", width = "100%"),
                div(class = "wm-hint", "Se aplica al momento; se recuerda para la próxima vez.")),
            actionButton(ns("saveCfg"), "Guardar ajustes", class = "btn-success btn-big", icon = icon("save"), style = "width: 100%; margin-bottom: 20px;")
          ),
          column(5,
            box(title = tagList(icon("file-word"), " La tesis completa"), status = "success", solidHeader = TRUE, width = NULL,
                p("Arma un solo documento con portada, introducción, capítulos, conclusiones y bibliografía. Se guarda en la carpeta ", tags$code("exportar/"), "."),
                actionButton(ns("export"), "Armar la tesis completa", class = "btn-success btn-big", icon = icon("cogs"), style = "width: 100%;"),
                uiOutput(ns("exportLinks"))),
            box(title = tagList(icon("life-ring"), " Respaldos"), status = "primary", solidHeader = TRUE, width = NULL,
                p("La app hace una copia automática al día. También puede hacer una ahora:"),
                actionButton(ns("backup"), "Hacer respaldo ahora", class = "btn-primary btn-big", icon = icon("copy"), style = "width: 100%;"),
                br(), br(),
                uiOutput(ns("backups"))),
            box(title = tagList(icon("key"), " Código de administrador"), status = "primary", solidHeader = TRUE, width = NULL, collapsible = TRUE, collapsed = TRUE,
                passwordInput(ns("newCode1"), "Código nuevo:", width = "100%"),
                passwordInput(ns("newCode2"), "Repita el código nuevo:", width = "100%"),
                actionButton(ns("saveCode"), "Cambiar código", class = "btn-primary admin-btn", style = "width: 100%;")),
            box(title = "Resumen del proyecto", status = "info", solidHeader = TRUE, width = NULL, collapsible = TRUE,
                tableOutput(ns("summary")))
          )
        )
      )
    }

    output$panel <- renderUI(if (unlocked()) admin_ui() else locked_ui())

    observeEvent(input$unlock, {
      if (identical(trimws(input$code %||% ""), tm$admin_code())) {
        unlocked(TRUE); showNotification("Sección de administrador abierta", type = "message")
      } else {
        updateTextInput(session, "code", value = ""); showNotification("Código incorrecto", type = "error")
      }
    })
    observeEvent(input$lock, { unlocked(FALSE); showNotification("🔒 Administrador bloqueado", type = "message") })

    # ------------------------------------------------------------ work folder
    output$workStatus <- renderUI({
      tm$cfg_trigger(); tm$proj_trigger()
      wf <- tm$config$work_folder %||% ""
      tagList(
        tags$b("Carpeta de trabajo actual:"),
        div(class = "folder-path", tm$work_dir()),
        div(style = "margin-top: 8px;",
            if (!nzchar(wf)) span(class = "status-bad", "⚠ Se está usando la carpeta interna de la app. Conviene elegir una carpeta propia (por ejemplo en Documentos).")
            else if (tm$work_dir_ok()) span(class = "status-ok", "✔ Carpeta encontrada")
            else span(class = "status-bad", "✖ La carpeta elegida no está disponible; se usa la carpeta interna."),
            br(), sprintf("Último guardado: %s", fmt_fecha(tm$project$updated))))
    })

    propose_folder <- function(path) {
      path <- trimws(path)
      if (!nzchar(path) || !dir.exists(path)) { showNotification("Esa carpeta no existe.", type = "error"); return() }
      path <- normalizePath(path, winslash = "/")
      if (identical(path, normalizePath(tm$work_dir(), winslash = "/"))) { showNotification("Esa ya es la carpeta de trabajo.", type = "message"); return() }
      pending_path(path)
      has_project <- file.exists(file.path(path, "proyecto.json"))
      showModal(modalDialog(
        title = "¿Usar esta carpeta de trabajo?",
        div(class = "folder-path", path), br(),
        if (has_project) div(class = "big-message",
          p("En esta carpeta ", tags$b("ya hay una tesis guardada"), "."),
          p("Si la abre, la app mostrará ese trabajo. El trabajo actual se queda donde está.")) else
          div(class = "big-message", p("La app copiará ahí todo el trabajo actual y desde ahora guardará en esa carpeta.")),
        footer = tagList(modalButton("Cancelar"),
                         if (has_project) actionButton(ns("folderOpen"), "Abrir la tesis de esa carpeta", class = "btn-primary")
                         else actionButton(ns("folderCopy"), "Sí, guardar ahí mi trabajo", class = "btn-success")),
        easyClose = TRUE))
    }
    observeEvent(input$workDir, {
      if (is.integer(input$workDir)) return()
      path <- shinyFiles::parseDirPath(volumes, input$workDir)
      if (length(path)) propose_folder(as.character(path))
    })
    observeEvent(input$useTyped, propose_folder(input$workPath))
    observeEvent(input$folderCopy, {
      removeModal()
      tryCatch({ tm$set_work_folder(pending_path(), "copy"); showNotification("✔ Desde ahora todo se guarda en la nueva carpeta.", type = "message", duration = 6) },
               error = function(e) showNotification(paste("No se pudo usar la carpeta:", conditionMessage(e)), type = "error", duration = 10))
      updateTextInput(session, "workPath", value = tm$config$work_folder)
    })
    observeEvent(input$folderOpen, {
      removeModal()
      tryCatch({ tm$set_work_folder(pending_path(), "open"); showNotification("✔ Se abrió la tesis de esa carpeta.", type = "message", duration = 6) },
               error = function(e) showNotification(paste("No se pudo abrir:", conditionMessage(e)), type = "error", duration = 10))
      updateTextInput(session, "workPath", value = tm$config$work_folder)
    })
    observeEvent(input$openFolder, {
      ok <- open_in_file_manager(tm$work_dir())
      if (!ok) showNotification(paste("Ábrala desde el explorador de archivos:", tm$work_dir()), type = "warning", duration = 10)
    })

    # ------------------------------------------------------------ settings
    observeEvent(input$fontScale, ignoreInit = TRUE, {
      session$sendCustomMessage("set-zoom", list(zoom = input$fontScale / 100))
    })
    observeEvent(input$saveCfg, {
      tm$set_config(author_name = trimws(input$author), generacion = trimws(input$generacion),
                    titulo_grado = trimws(input$grado), universidad = trimws(input$universidad),
                    citation_style = input$citation, feedback_style = input$fbStyle,
                    include_context = isTRUE(input$context), extra_instructions = trimws(input$extra),
                    chapter_target = max(500, as.numeric(input$chTarget %||% 4000)),
                    autosave_secs = max(1, min(30, as.numeric(input$autosave %||% 2))),
                    font_scale = as.numeric(input$fontScale))
      tm$touch()
      showNotification("✔ Ajustes guardados", type = "message")
    })
    observeEvent(input$saveCode, {
      a <- trimws(input$newCode1 %||% ""); b <- trimws(input$newCode2 %||% "")
      if (nchar(a) < 3) { showNotification("El código debe tener al menos 3 caracteres.", type = "warning"); return() }
      if (!identical(a, b)) { showNotification("Los dos códigos no coinciden.", type = "error"); return() }
      tm$set_config(admin_code = a)
      updateTextInput(session, "newCode1", value = ""); updateTextInput(session, "newCode2", value = "")
      showNotification("✔ Código cambiado. Anótelo en un lugar seguro.", type = "message", duration = 6)
    })

    # ------------------------------------------------------------ export
    observeEvent(input$export, {
      files <- withProgress(message = "Armando la tesis completa…", value = 0.5, tm$export_files())
      exported(files)
      showNotification(sprintf("✔ Tesis armada en %d formatos (carpeta exportar).", length(files)), type = "message", duration = 6)
    })
    output$exportLinks <- renderUI({
      f <- exported(); if (is.null(f)) return(NULL)
      tagList(br(),
        div(class = "places-ok", "✔ Listo. Se guardó en: ", div(class = "folder-path", dirname(f[[1]]))),
        if (!is.null(f$docx)) downloadButton(ns("dlDocx"), "Descargar en Word (.docx)", class = "btn-success admin-btn", style = "width: 100%; margin-bottom: 8px;"),
        downloadButton(ns("dlHtml"), "Descargar para ver o imprimir (.html)", class = "btn-primary admin-btn", style = "width: 100%; margin-bottom: 8px;"),
        downloadButton(ns("dlMd"), "Descargar en texto (.md)", class = "btn-default admin-btn", style = "width: 100%;"))
    })
    dl <- function(ext) downloadHandler(filename = function() basename(exported()[[ext]]),
                                        content = function(file) file.copy(exported()[[ext]], file))
    output$dlDocx <- dl("docx"); output$dlHtml <- dl("html"); output$dlMd <- dl("md")

    # ------------------------------------------------------------ backups
    backup_files <- reactive({
      tm$proj_trigger(); input$backup
      rev(sort(list.files(file.path(tm$work_dir(), "respaldos"), pattern = "^proyecto_.*\\.json$", full.names = TRUE)))
    })
    observeEvent(input$backup, {
      f <- tm$backup_now()
      showNotification(paste("✔ Respaldo guardado:", basename(f)), type = "message", duration = 6)
    })
    output$backups <- renderUI({
      fs <- head(backup_files(), 8)
      if (!length(fs)) return(p(class = "wm-hint", "Todavía no hay respaldos."))
      tagList(tags$b("Respaldos más recientes:"),
        lapply(fs, function(f) {
          stamp <- sub("^proyecto_(\\d{8}_\\d{6}).*$", "\\1", basename(f))
          div(class = "version-row compact",
              span(fmt_fecha(as.POSIXct(stamp, format = "%Y%m%d_%H%M%S")), if (grepl("_auto", f)) span(class = "wm-hint", " (automático)")),
              js_btn(" Recuperar", ns("bkEvt"), basename(f), "restore", "btn-default btn-sm", icon_name = "undo"))
        }))
    })
    observeEvent(input$bkEvt, {
      pending_backup(input$bkEvt$id)
      showModal(modalDialog(title = "¿Recuperar este respaldo?",
        div(class = "big-message", p("Todo el trabajo volverá a como estaba en ese respaldo."),
            p("Antes se hace un respaldo del estado actual, por si quiere regresar.")),
        footer = tagList(modalButton("Cancelar"), actionButton(ns("bkOk"), "Sí, recuperar", class = "btn-danger")), easyClose = TRUE))
    })
    observeEvent(input$bkOk, {
      removeModal()
      src <- file.path(tm$work_dir(), "respaldos", pending_backup())
      if (!file.exists(src)) return()
      tm$backup_now()
      file.copy(src, tm$project_file(), overwrite = TRUE)
      tm$load_project(); tm$save_project()
      showNotification("✔ Respaldo recuperado", type = "message", duration = 6)
    })

    output$summary <- renderTable({
      tm$proj_trigger(); tm$cfg_trigger()
      p <- tm$progress()$steps
      data.frame(
        Concepto = c("Ideas", "Tema elegido", "Bosquejo", "Capítulos", "Palabras: introducción", "Palabras: capítulos",
                     "Palabras: conclusiones", "Comentarios de Claude", "Consultas a Claude"),
        Valor = c(length(tm$ideas()), if (is.null(tm$chosen())) "—" else tm$chosen()$titulo, paste0(p$bosquejo, " %"),
                  length(tm$chapters()), fmt_int(tm$parts_words(INTRO_PARTS)), fmt_int(tm$chapters_words()),
                  fmt_int(tm$parts_words(CONCL_PARTS)), length(tm$project$feedback), fmt_int(tm$claude$calls)),
        check.names = FALSE)
    }, striped = TRUE, width = "100%")
  })
}

# Open a folder in Windows Explorer / Finder / the Linux file manager
open_in_file_manager <- function(path) {
  tryCatch({
    if (.Platform$OS.type == "windows") shell.exec(normalizePath(path))
    else if (Sys.info()[["sysname"]] == "Darwin") system2("open", shQuote(path), wait = FALSE)
    else system2("xdg-open", shQuote(path), wait = FALSE, stdout = FALSE, stderr = FALSE)
    TRUE
  }, error = function(e) FALSE)
}
