admin_settings_server <- function(id, photo_manager, session) {
  moduleServer(id, function(input, output, session) {
    pm <- photo_manager
    ns <- session$ns
    unlocked <- reactiveVal(FALSE)
    print_parent <- reactiveVal(pm$config$print_parent %||% "")
    places_ver <- reactiveVal(0)              # re-draws the places editor (scan, folder change, apply, undo)
    places_countries <- reactiveVal(character())
    pending_root <- reactiveVal(NULL)

    volumes <- get_volume_roots()
    shinyFiles::shinyDirChoose(input, "rootDir", roots = volumes, session = session)
    shinyFiles::shinyDirChoose(input, "printDir", roots = volumes, session = session)

    # ------------------------------------------------------------ lock UI
    locked_ui <- function() {
      fluidRow(column(
        width = 12,
        box(
          title = "Acceso del administrador", status = "primary", solidHeader = TRUE, width = NULL,
          div(class = "lock-box",
              h3("🔒 Esta sección es solo para el administrador"),
              passwordInput(ns("code"), "Escriba el código de administrador:", width = "100%"),
              actionButton(ns("unlock"), "Entrar", class = "btn-primary btn-big", style = "width: 100%;"))
        )
      ))
    }

    # ------------------------------------------- places / limits box
    places_box <- function(cfg) {
      box(
        title = "2. Países, lugares y límites", status = "primary", solidHeader = TRUE, width = NULL,
        p(HTML("Aquí decide cuántas fotos puede elegir el usuario en cada país y qué ciudades, regiones o eventos se usan.
               <b>Nada cambia hasta presionar “Aplicar cambios”.</b> Las fotos que el usuario ya eligió no se modifican.")),
        fluidRow(
          column(6, numericInput(ns("defLimit"), "Límite por defecto para cada país:",
                                 value = as.integer(cfg$limit_per_country %||% 50), min = 1, step = 1, width = "100%")),
          column(6, numericInput(ns("specialCap"), "Máximo recomendado para Museos, Galerías y Vuelos:",
                                 value = as.integer(cfg$special_cap %||% 8), min = 0, step = 1, width = "100%"))
        ),
        div(class = "wm-hint", style = "margin-top: -4px;",
            "Museos, Galerías y Vuelos = lugares cuyo nombre empieza con Museo(s), Galería(s) o Vuelo(s). Es solo una recomendación."),
        uiOutput(ns("placesEditor")),
        uiOutput(ns("placesStatus")),
        fluidRow(
          column(8, actionButton(ns("applyPlaces"), "✔ Aplicar cambios", class = "btn-success btn-big", style = "width: 100%;")),
          column(4, actionButton(ns("resetPlaces"), "Deshacer cambios sin aplicar", class = "btn-default admin-btn",
                                 style = "width: 100%; white-space: normal;"))
        )
      )
    }

    # ----------------------------------------------- print / watermark box
    print_box <- function(cfg) {
      fonts <- pm$wm_fonts
      wm_controls <- if (length(fonts) == 0) {
        p(class = "status-bad", "Para usar el sello de agua instale los paquetes ragg y systemfonts (vea install_packages.R).")
      } else {
        css_map <- jsonlite::toJSON(lapply(fonts, function(f) f$css), auto_unbox = TRUE)
        render_js <- I(sprintf(paste0(
          "{option: function(item, escape) { var m = %s; return '<div style=\"font-family: \\'' + m[item.value] + '\\', sans-serif; font-size: 19px; padding: 9px 12px;\">' + escape(item.label) + '</div>'; },",
          " item: function(item, escape) { var m = %s; return '<div style=\"font-family: \\'' + m[item.value] + '\\', sans-serif;\">' + escape(item.label) + '</div>'; }}"),
          css_map, css_map))
        font_choices <- setNames(names(fonts), vapply(fonts, function(f) f$label, character(1)))
        sel_font <- if (cfg$wm_font %in% names(fonts)) cfg$wm_font else names(fonts)[1]
        tagList(
          checkboxInput(ns("wmEnabled"),
                        HTML("<b>Guardar con sello de agua</b> – escribe <i>País – Ciudad/Región/Evento</i> en la esquina inferior derecha de cada foto"),
                        value = isTRUE(cfg$wm_enabled)),
          conditionalPanel(
            "input.wmEnabled", ns = ns,
            div(class = "wm-panel",
                fluidRow(
                  column(6,
                         selectizeInput(ns("wmFont"), "Tipo de letra:", choices = font_choices, selected = sel_font,
                                        width = "100%", options = list(render = render_js)),
                         sliderInput(ns("wmSize"), "Tamaño de la letra:", min = 2, max = 10, step = 0.5,
                                     value = as.numeric(cfg$wm_size %||% 5), post = " %", width = "100%"),
                         uiOutput(ns("wmSizeHint"))),
                  column(6,
                         checkboxInput(ns("wmBold"), "Letra en negritas (más fácil de leer)", isTRUE(cfg$wm_bold)),
                         radioButtons(ns("wmStyle"), "Estilo del sello:", choices = WM_STYLES,
                                      selected = cfg$wm_style %||% "dark_box"))
                ),
                tags$b("Vista previa (con una de las fotos elegidas):"),
                div(class = "wm-preview", imageOutput(ns("wmPreview"), height = "auto"))
            )
          )
        )
      }

      box(
        title = "3. Opciones de impresión y sello de agua", status = "primary", solidHeader = TRUE, width = NULL,
        p(HTML("La ubicación y el botón para copiar están arriba, en <b>🖨 Imprimir las fotos elegidas</b>.
               Las fotos originales <b>no se modifican</b>.")),
        radioButtons(ns("printMode"), "Si la carpeta Imprimir ya tiene fotos:",
                     choices = c("Reemplazar todo (queda solo lo elegido ahora)" = "replace",
                                 "Solo agregar o actualizar (no borra nada)" = "update"),
                     selected = cfg$print_mode %||% "replace"),
        hr(),
        wm_controls
      )
    }

    # ------------------------------------- quick print box (top of the tab)
    quick_print_box <- function(cfg) {
      box(
        title = "🖨 Imprimir las fotos elegidas", status = "success", solidHeader = TRUE, width = NULL,
        uiOutput(ns("quickStatus")),
        fluidRow(
          column(
            4,
            div(class = "step-label", "Paso 1 · ¿Dónde guardar las fotos?"),
            shinyFiles::shinyDirButton(ns("printDir"), "Elegir carpeta…",
                                       "Seleccione dónde crear la carpeta Imprimir", class = "btn-info btn-big",
                                       style = "width: 100%;", icon = icon("folder-open")),
            tags$details(
              style = "margin-top: 8px;",
              tags$summary(style = "cursor: pointer; font-size: 16px; color: #667eea;", "…o escriba / pegue la ruta"),
              textInput(ns("printPathTyped"), NULL, value = cfg$print_parent %||% "", width = "100%",
                        placeholder = "p. ej. C:/Users/Ana/Desktop"),
              actionButton(ns("usePrintTyped"), "Usar esta ruta", class = "btn-primary admin-btn")
            )
          ),
          column(5, div(class = "step-label", "Se guardarán en:"), uiOutput(ns("printPath"))),
          column(
            3,
            div(class = "step-label", "Paso 2 · Copiar"),
            actionButton(ns("export"), HTML("Copiar fotos<br>ahora"), class = "btn-success btn-big quick-copy-btn",
                         style = "width: 100%;", icon = icon("print"))
          )
        )
      )
    }

    admin_ui <- function() {
      cfg <- pm$config
      tagList(
      div(class = "admin-topbar",
          span(class = "admin-topbar-text", "🔓 La sección de administrador está abierta"),
          actionButton(ns("lock"), "Bloquear Administrador", class = "btn-danger btn-big", icon = icon("lock"))),
      fluidRow(column(12, quick_print_box(cfg))),
      fluidRow(
        column(
          width = 7,
          box(
            title = "1. Carpeta principal y escaneo", status = "primary", solidHeader = TRUE, width = NULL,
            p("Elija la carpeta principal. Adentro debe haber una carpeta por país, y dentro de cada país una carpeta por ciudad, región o evento."),
            uiOutput(ns("rootStatus")),
            br(),
            fluidRow(
              column(6, shinyFiles::shinyDirButton(
                ns("rootDir"), "Buscar carpeta principal…", "Seleccione la carpeta PRINCIPAL de fotos",
                class = "btn-info btn-big", style = "width: 100%;", icon = icon("folder-open"))),
              column(6, actionButton(ns("scan"), "Escanear carpetas y fotos", class = "btn-success btn-big",
                                     style = "width: 100%;", icon = icon("sync")))
            ),
            br(),
            checkboxInput(ns("makePreviews"),
                          "Preparar también todas las vistas previas ahora (escaneo más lento, pero las fotos cargan más rápido después)", FALSE),
            tags$details(
              tags$summary(style = "cursor: pointer; font-size: 16px; color: #667eea;", "…o escriba / pegue la ruta de la carpeta"),
              br(),
              textInput(ns("rootPath"), NULL, value = cfg$root_folder, width = "100%",
                        placeholder = "p. ej. C:/Users/Ana/Pictures/Viajes"),
              actionButton(ns("useTyped"), "Usar esta ruta", class = "btn-primary admin-btn")
            ),
            uiOutput(ns("scanResult"))
          ),
          places_box(cfg),
          print_box(cfg),
          box(
            title = "Resumen de carpetas (fotos, sugeridas, elegidas)", status = "info", solidHeader = TRUE,
            width = NULL, collapsible = TRUE,
            div(class = "table-scroll", tableOutput(ns("overview")))
          )
        ),
        column(
          width = 5,
          box(
            title = "Costo de impresión", status = "primary", solidHeader = TRUE, width = NULL,
            fluidRow(
              column(8, numericInput(ns("cost"), "Costo por foto impresa:", value = cfg$cost_per_photo,
                                     min = 0, step = 0.5, width = "100%")),
              column(4, textInput(ns("currency"), "Moneda:", value = cfg$currency, width = "100%"))
            ),
            actionButton(ns("saveRules"), "Guardar costo", class = "btn-primary btn-big", style = "width: 100%;")
          ),
          box(
            title = "4. Lista de fotos elegidas", status = "primary", solidHeader = TRUE, width = NULL,
            uiOutput(ns("selStatus")),
            downloadButton(ns("downloadSel"), "Descargar lista de fotos elegidas (CSV)", class = "btn-success admin-btn",
                           style = "width: 100%; margin-bottom: 10px;"),
            hr(),
            selectInput(ns("clearWhich"), "Borrar fotos elegidas de:", choices = NULL, width = "100%"),
            actionButton(ns("clear"), "Borrar fotos elegidas…", class = "btn-danger admin-btn", style = "width: 100%;")
          ),
          box(
            title = "Información", status = "info", solidHeader = TRUE, width = NULL, collapsible = TRUE,
            collapsed = TRUE,
            div(class = "reference-box", style = "margin-top: 0;",
                h4(style = "margin-top: 0; color: #4f46e5;", "🗂 Dónde se guarda todo"),
                tags$ul(
                  tags$li(tags$code("data/config.json"), " – carpeta, límite, costo"),
                  tags$li(tags$code("data/selections.json"), " – cada foto elegida"),
                  tags$li(tags$code("data/inventory.rds"), " – resultado del último escaneo"),
                  tags$li(tags$code("data/thumb_cache/"), " – vistas previas (se pueden borrar sin problema)")
                ),
                p("Las fotos elegidas se guardan por carpeta principal. Si cambia la carpeta se ocultan; si vuelve a la misma, regresan.")),
            NULL
          )
        )
      )
      )
    }

    output$panel <- renderUI(if (unlocked()) admin_ui() else locked_ui())

    observeEvent(input$unlock, {
      if (identical(trimws(input$code %||% ""), pm$admin_code)) {
        unlocked(TRUE)
        showNotification("Sección de administrador abierta", type = "message")
      } else {
        updateTextInput(session, "code", value = "")
        showNotification("Código incorrecto", type = "error")
      }
    })
    observeEvent(input$lock, {
      unlocked(FALSE)
      removeModal()
      showNotification("🔒 Administrador bloqueado. Para entrar otra vez se necesita el código.", type = "message", duration = 6)
    })

    # ------------------------------------------------------- main folder
    output$rootStatus <- renderUI({
      pm$cfg_trigger()
      root <- pm$root()
      scanned <- if (!is.null(pm$scanned_at)) fmt_fecha(pm$scanned_at) else "nunca"
      tagList(
        tags$b("Carpeta principal actual:"),
        div(class = "folder-path", if (nzchar(root)) root else "(todavía no se elige)"),
        div(style = "margin-top: 8px;",
            if (pm$root_ok()) span(class = "status-ok", "✔ Carpeta encontrada") else span(class = "status-bad", "✖ Carpeta no disponible"),
            sprintf("   ·   Último escaneo: %s   ·   Fotos: %s", scanned,
                    fmt_int(if (pm$has_inventory()) nrow(pm$photos) else 0)))
      )
    })

    apply_root <- function(path) {
      path <- trimws(path)
      if (!nzchar(path) || !dir.exists(path)) {
        showNotification("Esa carpeta no existe.", type = "error"); return()
      }
      if (identical(normalizePath(path, winslash = "/"), pm$root())) {
        showNotification("Esa ya es la carpeta principal.", type = "message"); return()
      }
      n_sel <- nrow(pm$current_selections())
      if (n_sel > 0) {
        pending_root(path)
        showModal(modalDialog(
          title = "¿Cambiar la carpeta principal?",
          p(sprintf("El usuario tiene %s fotos elegidas en la carpeta actual.", n_sel)),
          p("Se quedan guardadas en el archivo, pero no se verán mientras use otra carpeta. Regresan si vuelve a elegir la carpeta actual."),
          footer = tagList(modalButton("Cancelar"),
                           actionButton(ns("confirmRoot"), "Sí, cambiar carpeta", class = "btn-primary"))
        ))
      } else {
        do_set_root(path)
      }
    }

    do_set_root <- function(path) {
      res <- pm$set_root(path)
      if (identical(res, "set")) {
        places_ver(places_ver() + 1)
        updateTextInput(session, "rootPath", value = pm$root())
        msg <- if (pm$has_inventory()) "Carpeta principal guardada (se recuperó el escaneo anterior de esta carpeta)."
               else "Carpeta principal guardada. Ahora presione “Escanear carpetas y fotos”."
        showNotification(msg, type = "message", duration = 8)
      } else if (!identical(res, "same")) {
        showNotification(res, type = "error")
      }
    }

    observeEvent(input$confirmRoot, { removeModal(); do_set_root(pending_root()) })

    observeEvent(input$rootDir, {
      if (is.integer(input$rootDir)) return()
      path <- shinyFiles::parseDirPath(volumes, input$rootDir)
      if (length(path) == 0) return()
      apply_root(as.character(path))
    })
    observeEvent(input$useTyped, apply_root(input$rootPath))

    # ---------------------------------------------------------------- scan
    observeEvent(input$scan, {
      if (!pm$root_ok()) {
        showNotification("Primero elija la carpeta principal.", type = "error"); return()
      }
      res <- tryCatch(
        withProgress(message = "Escaneando fotos…", value = 0, {
          pm$scan(progress = function(f, d) setProgress(f * 0.98, detail = d))
        }),
        error = function(e) { showNotification(conditionMessage(e), type = "error"); NULL })
      if (is.null(res)) return()

      if (isTRUE(input$makePreviews) && res$photos > 0) {
        withProgress(message = "Preparando vistas previas…", value = 0, {
          pm$pregenerate_previews(progress = function(f, d) setProgress(f, detail = d))
        })
      }

      places_ver(places_ver() + 1)
      output$scanResult <- renderUI(div(
        class = "dimension-display", style = "margin-top: 14px;",
        HTML(sprintf(
          "<b>Escaneo terminado.</b> %s países · %s lugares · %s fotos.%s%s",
          res$countries, res$places, fmt_int(res$photos),
          if (res$loose_root > 0) sprintf("<br>⚠ %s foto(s) están sueltas en la carpeta principal (no dentro de un país) y no se tomaron en cuenta.", res$loose_root) else "",
          if (res$removed_selections > 0) sprintf("<br>⚠ %s foto(s) elegidas ya no existen en la computadora y se quitaron de la lista.", res$removed_selections) else ""
        ))))
      showNotification(sprintf("Escaneo terminado: se encontraron %s fotos", fmt_int(res$photos)), type = "message")
    })

    output$overview <- renderTable({
      pm$cfg_trigger(); pm$sel_trigger()
      pm$overview()
    }, striped = TRUE, hover = TRUE, spacing = "s", width = "100%", digits = 1)

    # --------------------------------------------------------------- rules
    observeEvent(input$saveRules, {
      cost <- suppressWarnings(as.numeric(input$cost))
      if (is.na(cost) || cost < 0) { showNotification("El costo debe ser 0 o más.", type = "error"); return() }
      cur <- trimws(input$currency %||% "MXN"); if (!nzchar(cur)) cur <- "MXN"
      pm$update_rules(NULL, cost, cur)
      showNotification("Costo guardado.", type = "message")
    })

    # ---------------------------------------------------------- selections
    output$selStatus <- renderUI({
      pm$cfg_trigger(); pm$sel_trigger()
      cs <- pm$country_summary()
      p(HTML(sprintf("<b>%s</b> fotos elegidas en total · costo aproximado <b>%s</b>",
                     sum(cs$chosen), fmt_money(sum(cs$cost), pm$currency()))))
    })

    observe({
      pm$cfg_trigger()
      cs <- pm$country_summary()
      updateSelectInput(session, "clearWhich",
                        choices = c("Todos los países" = "", setNames(cs$country, cs$country)))
    })

    observeEvent(input$clear, {
      what <- if (nzchar(input$clearWhich %||% "")) input$clearWhich else "TODOS los países"
      showModal(modalDialog(
        title = "¿Borrar fotos elegidas?",
        p(sprintf("Esto quita las marcas de %s. No se puede deshacer.", what)),
        footer = tagList(modalButton("Cancelar"),
                         actionButton(ns("confirmClear"), "Sí, borrar", class = "btn-danger"))
      ))
    })
    observeEvent(input$confirmClear, {
      removeModal()
      n <- pm$clear_selections(if (nzchar(input$clearWhich %||% "")) input$clearWhich else NULL)
      showNotification(sprintf("Se borraron %s foto(s) elegidas.", n), type = "message")
    })

    output$downloadSel <- downloadHandler(
      filename = function() paste0("fotos_elegidas_", format(Sys.time(), "%Y%m%d_%H%M"), ".csv"),
      content = function(file) write_csv_utf8(pm$selection_table_es(), file)
    )

    # ------------------------------------------------- places editor
    output$placesEditor <- renderUI({
      places_ver(); unlocked()
      if (!isolate(pm$has_inventory())) {
        return(div(class = "empty-state", style = "padding: 20px; font-size: 17px;",
                   "Primero elija la carpeta principal y presione “Escanear carpetas y fotos”."))
      }
      countries <- isolate(unique(pm$photos$country))
      places_countries(countries)
      cap <- isolate(pm$special_cap())
      tagList(lapply(seq_along(countries), function(i) {
        cn <- countries[i]
        ss <- isolate(pm$subfolder_summary(cn, include_inactive = TRUE))
        override <- isolate(pm$config$country_limits[[cn]])
        labels <- lapply(seq_len(nrow(ss)), function(j) {
          tagList(
            tags$b(ss$subfolder[j]), sprintf("  (%s fotos", fmt_int(ss$photos[j])),
            if (ss$chosen[j] > 0) sprintf(" · %s ya elegidas", ss$chosen[j]),
            ")",
            if (ss$special[j]) span(class = "special-tag", sprintf("🏛 máx. recomendado %s", cap))
          )
        })
        n_act <- sum(ss$active)
        tags$details(
          class = "place-country",
          tags$summary(HTML(sprintf("<b>%s</b> — %s fotos · %s de %s lugares activos · límite %s",
                                    htmltools::htmlEscape(cn), fmt_int(sum(ss$photos)), n_act, nrow(ss),
                                    isolate(pm$country_limit(cn))))),
          div(class = "place-country-body",
              numericInput(ns(paste0("cl_", i)),
                           sprintf("Límite de fotos para %s (vacío = usar el límite por defecto):", cn),
                           value = if (is.null(override)) NA else as.integer(override), min = 1, step = 1, width = "260px"),
              checkboxGroupInput(ns(paste0("act_", i)), "Lugares que se usan (quite la marca para no incluirlo):",
                                 choiceNames = labels, choiceValues = ss$subfolder,
                                 selected = ss$subfolder[ss$active], width = "100%"))
        )
      }))
    })

    # what the admin has typed/ticked right now (not applied yet)
    places_inputs <- reactive({
      countries <- places_countries()
      req(length(countries) > 0)
      cl <- vapply(seq_along(countries), function(i) {
        v <- suppressWarnings(as.integer(input[[paste0("cl_", i)]])); if (length(v) == 0) NA_integer_ else v
      }, integer(1))
      names(cl) <- countries
      inactive <- unlist(lapply(seq_along(countries), function(i) {
        subs <- unique(pm$photos$subfolder[pm$photos$country == countries[i]])
        sel <- input[[paste0("act_", i)]] %||% character()
        if (is.null(input[[paste0("cl_", i)]]) && is.null(input[[paste0("act_", i)]])) {
          # editor not drawn yet: keep what is saved
          return(intersect(pm$place_key(countries[i], subs), pm$inactive_keys()))
        }
        pm$place_key(countries[i], setdiff(subs, sel))
      }))
      list(default = suppressWarnings(as.integer(input$defLimit)),
           special = suppressWarnings(as.integer(input$specialCap)),
           limits = cl, inactive = sort(as.character(inactive)))
    })

    places_pending <- reactive({
      pm$cfg_trigger()
      x <- places_inputs()
      saved_over <- unlist(pm$config$country_limits)
      typed_over <- x$limits[!is.na(x$limits) & x$limits != x$default]
      !identical(x$default, pm$limit()) || !identical(x$special, pm$special_cap()) ||
        !setequal(paste(names(typed_over), typed_over), paste(names(saved_over), saved_over)) ||
        !setequal(x$inactive, pm$inactive_keys())
    })

    output$placesStatus <- renderUI({
      pm$cfg_trigger()
      pend <- tryCatch(places_pending(), error = function(e) FALSE)
      when <- pm$config$places_applied_at
      if (isTRUE(pend)) {
        div(class = "places-pending", "⚠ Hay cambios SIN aplicar. Presione “Aplicar cambios” para que cuenten.")
      } else {
        div(class = "places-ok", if (!is.null(when)) sprintf("✔ Cambios aplicados (último: %s). La configuración actual ya está en uso.", when)
                                 else "✔ La configuración actual ya está en uso.")
      }
    })

    observeEvent(input$applyPlaces, {
      x <- places_inputs()
      if (is.na(x$default) || x$default < 1) { showNotification("El límite por defecto debe ser 1 o más.", type = "error"); return() }
      if (is.na(x$special) || x$special < 0) { showNotification("El máximo para museos, galerías y vuelos debe ser 0 o más.", type = "error"); return() }
      bad <- names(x$limits)[!is.na(x$limits) & x$limits < 1]
      if (length(bad)) { showNotification(paste("Revise el límite de:", paste(bad, collapse = ", ")), type = "error"); return() }
      pm$apply_places(x$default, x$special, x$limits, x$inactive)
      places_ver(places_ver() + 1)
      cs <- pm$country_summary()
      over <- cs$country[cs$chosen > cs$country_limit]
      showModal(modalDialog(
        title = "✔ Cambios aplicados",
        div(class = "big-message",
            p(sprintf("Límite por defecto: %s fotos por país · Museos, Galerías y Vuelos: máx. recomendado %s.",
                      x$default, x$special)),
            p(sprintf("Lugares desactivados: %s.", length(x$inactive))),
            p("Las fotos sugeridas ya se recalcularon. Las fotos que el usuario ya había elegido no se modificaron."),
            if (length(over)) p(class = "status-bad", sprintf("Ojo: %s ya tiene(n) más fotos elegidas que su nuevo límite. Se respetan, pero el usuario no podrá elegir más ahí.",
                                                              paste(over, collapse = ", ")))),
        footer = modalButton("Aceptar"), easyClose = TRUE))
    })

    observeEvent(input$resetPlaces, {
      updateNumericInput(session, "defLimit", value = pm$limit())
      updateNumericInput(session, "specialCap", value = pm$special_cap())
      places_ver(places_ver() + 1)
      showNotification("Se regresó a la configuración guardada.", type = "message")
    })

    # ------------------------------------------------- print folder
    set_print_parent <- function(path) {
      path <- trimws(path)
      if (!nzchar(path) || !dir.exists(path)) { showNotification("Esa carpeta no existe.", type = "error"); return(FALSE) }
      path <- normalizePath(path, winslash = "/")
      if (pm$root_ok() && startsWith(paste0(path, "/"), paste0(pm$root(), "/"))) {
        showNotification("Elija una ubicación FUERA de la carpeta principal de fotos.", type = "error", duration = 8)
        return(FALSE)
      }
      pm$set_preference("print_parent", path)
      print_parent(path)
      updateTextInput(session, "printPathTyped", value = path)
      showNotification("Ubicación guardada. Ahora presione “Copiar fotos ahora”.", type = "message")
      TRUE
    }
    observeEvent(input$printDir, {
      if (is.integer(input$printDir)) return()
      path <- shinyFiles::parseDirPath(volumes, input$printDir)
      if (length(path) == 0) return()
      set_print_parent(as.character(path))
    })
    observeEvent(input$usePrintTyped, set_print_parent(input$printPathTyped %||% ""))

    output$quickStatus <- renderUI({
      pm$cfg_trigger(); pm$sel_trigger()
      cs <- pm$country_summary(); cs <- cs[cs$chosen > 0, , drop = FALSE]
      wm <- if (isTRUE(input$wmEnabled) && length(pm$wm_fonts)) {
        f <- pm$wm_fonts[[input$wmFont %||% ""]]
        sprintf("Sí (%s, %s %%)", if (is.null(f)) "" else sub(" –.*", "", f$label), input$wmSize %||% "")
      } else "No"
      div(class = "quick-status",
          HTML(sprintf("<b>%s fotos elegidas</b> de %s país(es) · costo aproximado <b>%s</b> · Sello de agua: <b>%s</b> <span class='wm-hint'>(se cambia en la sección 3)</span>",
                       sum(cs$chosen), nrow(cs), fmt_money(sum(cs$cost), pm$currency()), wm)))
    })

    # open the Imprimir folder in Windows Explorer / Finder
    observeEvent(input$openPrintFolder, {
      f <- pm$print_folder(print_parent())
      if (!dir.exists(f)) return()
      tryCatch({
        if (.Platform$OS.type == "windows") shell.exec(f)
        else if (Sys.info()[["sysname"]] == "Darwin") system2("open", shQuote(f), wait = FALSE)
        else system2("xdg-open", shQuote(f), wait = FALSE)
      }, error = function(e) showNotification("No se pudo abrir la carpeta.", type = "error"))
    })

    output$printPath <- renderUI({
      pm$cfg_trigger(); pm$sel_trigger()
      par <- print_parent()
      if (!nzchar(par)) {
        return(div(class = "folder-path", style = "margin: 8px 0;", "(todavía no se elige la ubicación)"))
      }
      cs <- pm$country_summary(); cs <- cs$country[cs$chosen > 0]
      sub <- if (length(cs)) paste0(" → ", paste(cs, collapse = ", ")) else ""
      tagList(
        div(style = "margin-top: 8px;", tags$b("Las fotos se guardarán en:")),
        div(class = "folder-path", style = "margin-bottom: 8px;", paste0(pm$print_folder(par), sub)),
        if (!dir.exists(par)) div(class = "status-bad", "✖ Esa ubicación ya no existe, elija otra.")
      )
    })

    # Save print / watermark preferences whenever they change
    observeEvent(input$printMode, pm$set_preference("print_mode", input$printMode), ignoreInit = TRUE)
    observeEvent(input$wmEnabled, pm$set_preference("wm_enabled", isTRUE(input$wmEnabled)), ignoreInit = TRUE)
    observeEvent(input$wmFont, pm$set_preference("wm_font", input$wmFont), ignoreInit = TRUE)
    observeEvent(input$wmSize, pm$set_preference("wm_size", input$wmSize), ignoreInit = TRUE)
    observeEvent(input$wmBold, pm$set_preference("wm_bold", isTRUE(input$wmBold)), ignoreInit = TRUE)
    observeEvent(input$wmStyle, pm$set_preference("wm_style", input$wmStyle), ignoreInit = TRUE)

    output$wmSizeHint <- renderUI({
      req(input$wmSize)
      div(class = "wm-hint",
          sprintf("En una foto de 10 × 15 cm, las letras medirán aprox. %s mm de alto.", wm_letter_mm(input$wmSize)))
    })

    wm_settings <- debounce(reactive({
      req(length(pm$wm_fonts) > 0, input$wmFont, input$wmSize, input$wmStyle)
      f <- pm$wm_fonts[[input$wmFont]]
      req(f)
      list(family = f$family, size = input$wmSize, bold = isTRUE(input$wmBold), style = input$wmStyle,
           label = f$label)
    }), 400)

    output$wmPreview <- renderImage({
      wm <- wm_settings()
      pm$cfg_trigger()
      sample <- NULL
      cur <- pm$current_selections()
      if (nrow(cur) > 0 && pm$root_ok()) sample <- cur[1, ]
      else if (pm$has_inventory()) sample <- pm$photos[1, ]
      img <- NULL; text <- "México \u2013 Cancún"
      if (!is.null(sample)) {
        img <- tryCatch(magick::image_read(file.path(pm$root(), sample$rel_path))[1], error = function(e) NULL)
        text <- watermark_text(sample$country, sample$subfolder)
      }
      if (is.null(img)) img <- magick::image_blank(1500, 1000, "#7f8fa6")
      img <- magick::image_scale(magick::image_orient(img), "1000x1000")
      img <- add_watermark(img, text, wm$family, wm$size, wm$bold, wm$style)
      tmp <- tempfile(fileext = ".jpg")
      magick::image_write(img, tmp, format = "jpeg", quality = 85)
      list(src = tmp, contentType = "image/jpeg", width = "100%", alt = "Vista previa del sello de agua")
    }, deleteFile = TRUE)

    # ------------------------------------------------------- export
    observeEvent(input$export, {
      par <- print_parent()
      if (!nzchar(par) || !dir.exists(par)) {
        showNotification("Primero elija dónde crear la carpeta Imprimir.", type = "error"); return()
      }
      n <- nrow(pm$current_selections())
      if (n == 0) { showNotification("Todavía no hay fotos elegidas.", type = "warning"); return() }
      out <- pm$print_folder(par)
      has_content <- dir.exists(out) && length(list.files(out)) > 0
      use_wm <- isTRUE(input$wmEnabled) && length(pm$wm_fonts) > 0
      cs <- pm$country_summary(); cs <- cs[cs$chosen > 0, ]
      showModal(modalDialog(
        title = "¿Copiar las fotos para imprimir?",
        div(class = "big-message",
            p(HTML(sprintf("Se copiarán <b>%s fotos</b> de %s país(es) a:", n, nrow(cs)))),
            div(class = "folder-path", out),
            tags$ul(style = "margin-top: 10px;",
                    tags$li(HTML(paste0("Carpetas: <b>", paste(htmltools::htmlEscape(cs$country), collapse = "</b>, <b>"), "</b>"))),
                    tags$li(if (use_wm) sprintf("Con sello de agua: %s, %s %%%s", sub(" –.*", "", isolate(wm_settings())$label),
                                                input$wmSize, if (isTRUE(input$wmBold)) ", negritas" else "")
                            else "Sin sello de agua (copia exacta de las fotos)")),
            if (has_content && identical(input$printMode, "replace"))
              p(class = "status-bad", "⚠ La carpeta Imprimir ya tiene archivos: se borrarán y quedarán solo las fotos elegidas ahora.")),
        footer = tagList(modalButton("Cancelar"),
                         actionButton(ns("confirmExport"), "Sí, copiar fotos", class = "btn-success"))
      ))
    })

    observeEvent(input$confirmExport, {
      removeModal()
      use_wm <- isTRUE(input$wmEnabled) && length(pm$wm_fonts) > 0
      wm <- if (use_wm) isolate(wm_settings()) else NULL
      res <- tryCatch(
        withProgress(message = if (use_wm) "Copiando fotos con sello de agua…" else "Copiando fotos…", value = 0,
                     pm$export_for_print(print_parent(), mode = input$printMode %||% "replace", watermark = wm,
                                         progress = function(f, d) setProgress(f, detail = d))),
        error = function(e) { showNotification(conditionMessage(e), type = "error", duration = 10); NULL })
      if (!is.null(res)) {
        showModal(modalDialog(
          title = "✅ Fotos listas para imprimir",
          div(class = "big-message",
              p(sprintf("Se copiaron %s de %s fotos a:", res$copied, res$total)),
              div(class = "folder-path", res$folder),
              p(style = "margin-top: 10px;", "Adentro hay una carpeta por país, y también los archivos lista_para_imprimir.csv y resumen_del_pedido.csv."),
              if (length(res$failed))
                p(class = "status-bad", sprintf("⚠ %s foto(s) no se pudieron copiar: %s", length(res$failed),
                                                paste(head(res$failed, 5), collapse = ", ")))),
          footer = tagList(actionButton(ns("openPrintFolder"), "📂 Abrir la carpeta Imprimir", class = "btn-info"),
                           modalButton("Aceptar")), easyClose = TRUE))
      }
    })
  })
}
