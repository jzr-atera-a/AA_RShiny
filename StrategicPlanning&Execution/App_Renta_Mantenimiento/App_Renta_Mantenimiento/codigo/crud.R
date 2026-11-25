# ============================================================================
# MOTOR DE REGISTROS: una sola forma de crear, ver, editar y borrar
# Cada sección (recibos, órdenes, contratos…) se describe en R/entidades.R
# ============================================================================

campo <- function(id, label, tipo = "text", req = FALSE, choices = NULL, ancho = 6, min = NULL, max = NULL,
                  default = NULL, ayuda = NULL, solo_crear = FALSE, virtual = FALSE, hoy = TRUE) {
  list(id = id, label = label, tipo = tipo, req = req, choices = choices, ancho = ancho, min = min, max = max,
       default = default, ayuda = ayuda, solo_crear = solo_crear, virtual = virtual, hoy = hoy)
}
col <- function(lbl, f, fmt = "text", ...) list(lbl = lbl, f = f, fmt = fmt, ...)

# ---------------------------------------------------------------- Formulario
campo_ui <- function(iid, f, val, ctx, nuevo) {
  ch <- if (is.function(f$choices)) f$choices(ctx) else f$choices
  vac <- is.null(val) || length(val) == 0 || is.na(val[1]) || !nzchar(as.character(val[1]))
  lbl <- tagList(f$label, if (isTRUE(f$req)) span(class = "req", "*"))
  if (!nuevo && isTRUE(f$solo_crear)) {
    w <- div(class = "form-group", tags$label(f$label), div(class = "form-fixed", val))
  } else w <- switch(f$tipo,
    textarea  = textAreaInput(iid, lbl, value = if (vac) "" else val, rows = 3, width = "100%"),
    number    = numericInput(iid, lbl, value = if (vac) (f$default %||% NA) else as.numeric(val), min = if (is.null(f$min)) NA else f$min, max = if (is.null(f$max)) NA else f$max, width = "100%"),
    date      = suppressWarnings(dateInput(iid, lbl, value = if (!vac) as.Date(val) else if (isTRUE(f$hoy)) hoy() else NA,
                          language = "es", format = "dd/mm/yyyy", width = "100%")),
    select    = selectInput(iid, lbl, choices = ch, selected = if (vac) f$default else val, width = "100%"),
    selectize = selectizeInput(iid, lbl, choices = c("", ch), selected = if (vac) "" else val, width = "100%",
                               options = list(create = TRUE, placeholder = "Elija o escriba…")),
    multi     = selectizeInput(iid, lbl, choices = ch, selected = if (vac) NULL else val, multiple = TRUE, width = "100%",
                               options = list(placeholder = "Elija una o varias…")),
    file      = fileInput(iid, if (nuevo) lbl else paste(f$label, "(opcional: reemplazar)"), accept = c("image/*", ".pdf"),
                          buttonLabel = tagList(icon("camera"), "Elegir"), placeholder = "Foto del celular o PDF", width = "100%"),
    textInput(iid, lbl, value = if (vac) (f$default %||% "") else val, width = "100%"))
  column(f$ancho, w, if (!is.null(f$ayuda)) div(class = "help-text", f$ayuda))
}

leer_campo <- function(iid, f, input) {
  v <- input[[iid]]
  switch(f$tipo,
    date   = if (length(v) == 0 || is.na(v)) "" else as.character(v),
    number = if (is.null(v) || length(v) == 0 || is.na(v)) "" else as.character(v),
    multi  = if (is.null(v)) character(0) else v,
    file   = v,
    trimws(as.character(v %||% "")))
}

# ---------------------------------------------------------------- Formato de columnas
fmt_col <- function(d, c, ctx) {
  v <- d[[c$f]]
  switch(c$fmt,
    casa  = esc(nombre_casa(ctx$casas_all, v)),
    money = money(v),
    date  = fecha_mx(v),
    mes   = mes_txt(v),
    badge = badge(v, COLORES[[c$mapa]]),
    link  = link_ver(link_comprobante(d$archivo_tipo, d$archivo, d$archivo_link)),
    long  = largo(v, c$n %||% 90),
    stars = estrellas(v),
    fun   = c$fun(d, ctx),
    esc(v))
}
sort_key <- function(d, c) {
  if (c$fmt %in% c("date", "mes", "money")) { v <- d[[c$f]]; if (c$fmt == "money") v <- sprintf("%015.2f", as.numeric(v)); ifelse(is.na(v), "", v) }
  else if (!is.null(c$sort)) c$sort(d) else NULL
}

boton <- function(k, a, id, icono, titulo, cls = "") {
  sprintf('<button type="button" class="btn-acc %s" title="%s" onclick="Shiny.setInputValue(\'crud_evt\',{k:\'%s\',a:\'%s\',id:\'%s\',n:Math.random()},{priority:\'event\'})"><i class="fa fa-%s"></i></button>',
          cls, titulo, k, a, id, icono)
}

tabla_crud <- function(sp, d, ctx, puede) {
  if (!nrow(d)) {
    return(DT::datatable(data.frame(x = if (puede) sprintf("Aún no hay registros. Use «%s» para agregar el primero.", sp$boton %||% "Nuevo") else "Aún no hay registros."),
                         colnames = "", rownames = FALSE, selection = "none", options = list(dom = "t", ordering = FALSE, language = DT_LANG)))
  }
  out <- data.frame(id = d$id, stringsAsFactors = FALSE)
  orden <- list()
  for (c in sp$columnas) {
    out[[c$lbl]] <- fmt_col(d, c, ctx)
    sk <- sort_key(d, c)
    if (!is.null(sk)) orden[[c$lbl]] <- sk
  }
  out$Acciones <- vapply(seq_len(nrow(d)), function(i) {
    id <- d$id[i]
    b <- boton(sp$key, "ver", id, "eye", "Ver detalle")
    for (a in names(sp$acciones %||% list())) {
      ac <- sp$acciones[[a]]
      if (ctx$rol %in% ac$roles) b <- paste0(b, boton(sp$key, a, id, ac$icono, ac$titulo, "acc-ok"))
    }
    if (puede) b <- paste0(b, boton(sp$key, "editar", id, "pen", "Editar"), boton(sp$key, "borrar", id, "trash-can", "Eliminar", "acc-del"))
    paste0('<div class="acc">', b, '</div>')
  }, "")
  n_vis <- ncol(out)
  defs <- list(list(visible = FALSE, targets = 0), list(orderable = FALSE, className = "dt-acc", targets = n_vis - 1))
  for (lbl in names(orden)) {
    out[[paste0(".o_", lbl)]] <- orden[[lbl]]
    defs[[length(defs) + 1]] <- list(targets = which(names(out) == lbl) - 1, orderData = ncol(out) - 1)
    defs[[length(defs) + 1]] <- list(targets = ncol(out) - 1, visible = FALSE, searchable = FALSE)
  }
  DT::datatable(out, escape = FALSE, rownames = FALSE, selection = "none", class = "display hover",
                options = list(language = DT_LANG, pageLength = 15, dom = "ftip", order = list(),
                               autoWidth = FALSE, columnDefs = defs))
}

# ---------------------------------------------------------------- Página
crud_page <- function(sp) {
  k <- sp$key
  tabItem(tabName = sp$tab,
    encabezado(sp$titulo, sp$subtitulo, sp$icono, uiOutput(paste0(k, "_nuevo_ui"), inline = TRUE)),
    if (!is.null(sp$arriba)) uiOutput(sp$arriba),
    div(class = "card",
      div(class = "toolbar",
        if (isTRUE(sp$casa)) div(class = "tb-item", uiOutput(paste0(k, "_fcasa_ui"))),
        if (!is.null(sp$fecha)) div(class = "tb-item", selectInput(paste0(k, "_fper"), "Periodo", choices = PERIODOS, width = "190px")),
        if (!is.null(sp$filtro)) div(class = "tb-item", selectInput(paste0(k, "_fextra"), sp$filtro$label,
                                                                     choices = sp$filtro$choices, selected = sp$filtro$default, width = "200px")),
        div(class = "tb-res", uiOutput(paste0(k, "_resumen")))),
      DT::DTOutput(paste0(k, "_tabla")))
  )
}

# ---------------------------------------------------------------- Servidor
crud_server <- function(sp, input, output, session, st) {
  force(sp); k <- sp$key
  editando <- reactiveVal(NULL)
  borrando <- reactiveVal(NULL)
  form_n   <- reactiveVal(0)       # cada formulario tiene ids nuevos: nunca se cuela un archivo anterior
  iid <- function(campo_id, n = isolate(form_n())) paste0("f_", k, "_", campo_id, "_", n)

  puede <- reactive({ r <- st$ctx()$rol; !is.null(r) && r %in% sp$editores })

  base <- reactive({
    st$db(); ctx <- st$ctx(); req(ctx$rol)
    d <- read_tbl(sp$tabla)
    for (f in names(sp$fijo)) d <- d[d[[f]] %in% sp$fijo[[f]], , drop = FALSE]
    d <- visibles(d, ctx, sp$fecha)
    if (isTRUE(sp$casa)) d <- d[d$casa_id %in% ctx$casas$id, , drop = FALSE]
    d
  })

  datos <- reactive({
    d <- base()
    fc <- input[[paste0(k, "_fcasa")]]
    if (isTRUE(sp$casa) && nzchar(fc %||% "")) d <- d[d$casa_id == fc, , drop = FALSE]
    if (!is.null(sp$fecha)) d <- filtrar_rango(d, sp$fecha, periodo_rango(input[[paste0(k, "_fper")]]))
    if (!is.null(sp$filtro)) {
      fe <- input[[paste0(k, "_fextra")]] %||% ""
      if (nzchar(fe)) d <- if (!is.null(sp$filtro$fun)) sp$filtro$fun(d, fe) else d[d[[sp$filtro$campo]] == fe, , drop = FALSE]
    }
    if (!is.null(sp$orden) && nrow(d)) d <- d[order(d[[sp$orden]], decreasing = sp$orden %notin% c("nombre"), na.last = TRUE), , drop = FALSE]
    d
  })

  output[[paste0(k, "_nuevo_ui")]] <- renderUI({
    if (puede()) actionButton(paste0(k, "_nuevo"), sp$boton %||% "Nuevo", icon = icon("plus"), class = "btn-primary btn-lg-app")
  })
  output[[paste0(k, "_fcasa_ui")]] <- renderUI({
    ctx <- st$ctx(); req(ctx$rol)
    selectInput(paste0(k, "_fcasa"), "Casa", choices = c("Todas" = "", setNames(ctx$casas$id, ctx$casas$nombre)),
                selected = isolate(input[[paste0(k, "_fcasa")]]), width = "220px")
  })
  output[[paste0(k, "_resumen")]] <- renderUI({
    d <- datos()
    chips <- list(span(class = "chip", icon("list"), sprintf("%d %s", nrow(d), if (nrow(d) == 1) "registro" else "registros")))
    if ("monto" %in% names(d)) chips <- c(chips, list(span(class = "chip chip-strong", icon("sack-dollar"), money(sum(d$monto, na.rm = TRUE)))))
    if (!is.null(sp$resumen)) chips <- c(chips, sp$resumen(d))
    tagList(chips)
  })
  output[[paste0(k, "_tabla")]] <- DT::renderDT({ tabla_crud(sp, datos(), st$ctx(), puede()) })

  # ---- abrir formulario
  abrir_form <- function(row) {
    ctx <- st$ctx(); nuevo <- is.null(row)
    form_n(form_n() + 1); n <- form_n()
    vals <- if (nuevo) list() else c(as.list(row), if (!is.null(sp$valores_extra)) sp$valores_extra(row))
    ui <- lapply(sp$campos, function(f) campo_ui(iid(f$id, n), f, vals[[f$id]], ctx, nuevo))
    showModal(modalDialog(
      title = div(class = "modal-t", icon(sp$icono), if (nuevo) sp$nuevo_titulo %||% paste("Nuevo:", sp$singular) else paste("Editar:", sp$singular)),
      size = "l", easyClose = FALSE,
      div(class = "form-grid", do.call(fluidRow, ui)),
      if (!is.null(sp$nota_form)) div(class = "form-note", icon("circle-info"), sp$nota_form),
      footer = tagList(modalButton("Cancelar"),
                       actionButton(paste0(k, "_guardar"), "Guardar", icon = icon("check"), class = "btn-primary"))))
  }
  observeEvent(input[[paste0(k, "_nuevo")]], { req(puede()); editando(NULL); abrir_form(NULL) })

  # Reacciones dentro del formulario (ej. elegir tarea → frecuencia sugerida)
  if (!is.null(sp$reactivo)) observe({
    n <- form_n(); req(n > 0)
    sp$reactivo(input, session, function(campo_id) iid(campo_id, n), is.null(isolate(editando())), st)
  })

  fila <- function(id) { d <- isolate(base()); d[d$id == id, , drop = FALSE] }

  observeEvent(input$crud_evt, {
    e <- input$crud_evt
    req(identical(e$k, k))
    row <- fila(e$id)
    if (!nrow(row)) return(showNotification("Ese registro ya no está disponible.", type = "warning"))
    ctx <- st$ctx()
    if (e$a == "ver") return(modal_ver(sp, row, ctx))
    if (e$a == "editar") { req(puede()); editando(e$id); return(abrir_form(row)) }
    if (e$a == "borrar") {
      req(puede())
      if (!is.null(sp$puede_eliminar)) { m <- sp$puede_eliminar(row); if (!is.null(m)) return(showNotification(m, type = "warning", duration = 8)) }
      borrando(e$id)
      return(showModal(modalDialog(title = div(class = "modal-t", icon("trash-can"), "¿Eliminar este registro?"),
        p(HTML(sprintf("Se eliminará <b>%s</b>.", esc(sp$etiqueta(row, ctx))))),
        p(class = "muted", "Queda anotado en el historial con todos sus datos."),
        footer = tagList(modalButton("Cancelar"), actionButton(paste0(k, "_borrar_ok"), "Sí, eliminar", class = "btn-danger")))))
    }
    ac <- sp$acciones[[e$a]]
    if (!is.null(ac) && ctx$rol %in% ac$roles) ac$handler(row, input, session, st)
  })

  observeEvent(input[[paste0(k, "_guardar")]], {
    res <- guardar_registro(sp, input, st, editando(), function(campo_id) iid(campo_id))
    if (is.character(res)) return(showNotification(res, type = "warning", duration = 7))
    removeModal(); editando(NULL)
    showNotification(paste("✔", sp$singular, "guardado."), type = "message")
    st$bump()
  })

  observeEvent(input[[paste0(k, "_borrar_ok")]], {
    id <- borrando(); req(id, puede())
    d <- read_tbl(sp$tabla); old <- d[d$id == id, , drop = FALSE]
    req(nrow(old))
    write_tbl(sp$tabla, d[d$id != id, , drop = FALSE])
    ctx <- st$ctx()
    log_change(ctx$usuario, "Eliminar", sp$singular, id,
               paste0(sp$etiqueta(old, ctx), " · datos: ", jsonlite::toJSON(as.list(old), auto_unbox = TRUE, na = "null")))
    if (!is.null(sp$al_eliminar)) sp$al_eliminar(old, ctx)
    removeModal(); borrando(NULL)
    showNotification("Eliminado. Quedó en el historial.", type = "message")
    st$bump()
  })
}

# ---------------------------------------------------------------- Guardar
guardar_registro <- function(sp, input, st, id_edit, iidf) {
  ctx <- isolate(st$ctx()); nuevo <- is.null(id_edit)
  d <- read_tbl(sp$tabla)
  old <- NULL
  if (!nuevo) { old <- d[d$id == id_edit, , drop = FALSE]; if (!nrow(old)) return("Ese registro ya no existe.") }

  vals <- list()
  for (f in sp$campos) {
    if (f$tipo == "file") next
    if (!nuevo && isTRUE(f$solo_crear)) { vals[[f$id]] <- old[[f$id]]; next }
    vals[[f$id]] <- leer_campo(iidf(f$id), f, input)
  }
  for (f in sp$campos) {
    if (f$tipo == "file") next
    v <- vals[[f$id]]
    if (isTRUE(f$req) && (!length(v) || is.na(v[1]) || !nzchar(v[1]))) return(paste0("Falta llenar: ", f$label, "."))
    if (f$tipo == "number" && length(v) && nzchar(v[1])) {
      x <- suppressWarnings(as.numeric(v))
      if (is.na(x)) return(paste0(f$label, ": escriba un número."))
      if (!is.null(f$min) && x < f$min) return(sprintf("%s debe ser al menos %s.", f$label, f$min))
      if (!is.null(f$max) && x > f$max) return(sprintf("%s debe ser como máximo %s.", f$label, f$max))
    }
  }
  if (isTRUE(sp$casa) && vals$casa_id %notin% ctx$casas$id) return("Elija una casa que usted puede administrar.")
  if (isTRUE(sp$casa) && !is.null(sp$fecha) && identical(ctx$rol, "admin")) {
    c1 <- ctx$casas[ctx$casas$id == vals$casa_id, ]
    fv <- vals[[sp$fecha]]
    if (!nzchar(fv) || fv < c1$inicio || fv > c1$fin)
      return(sprintf("La fecha debe estar dentro de su periodo en %s (%s a %s).", c1$nombre, fecha_mx(c1$inicio), fecha_mx(c1$fin)))
  }
  fspec <- Filter(function(f) f$tipo == "file", sp$campos)
  up <- NULL
  if (length(fspec)) {
    up <- input[[iidf(fspec[[1]]$id)]]
    if (nuevo && isTRUE(fspec[[1]]$req) && is.null(up)) return(paste0("Falta: ", fspec[[1]]$label, "."))
  }
  if (!is.null(sp$validar)) { m <- sp$validar(vals, ctx, old); if (!is.null(m)) return(m) }
  if (!is.null(sp$preparar)) vals <- sp$preparar(vals, ctx, old)

  cols <- COLS[[sp$tabla]]
  reales <- vals[names(vals) %in% cols & !vapply(names(vals), function(n) any(vapply(sp$campos, function(f) f$id == n && isTRUE(f$virtual), TRUE)), TRUE)]
  id <- if (nuevo) new_id(sp$prefijo) else id_edit

  arch <- NULL
  if (!is.null(up)) {
    casa_n <- if (!is.null(vals$casa_id)) nombre_casa(ctx$casas_all, vals$casa_id) else sp$prefijo
    ext <- tools::file_ext(up$name)
    nombre <- paste0(gsub("[^A-Za-z0-9]+", "_", iconv(casa_n, to = "ASCII//TRANSLIT")), "_",
                     vals[[sp$fecha %||% "fecha"]] %||% format(hoy()), "_", id, if (nzchar(ext)) paste0(".", tolower(ext)))
    arch <- guardar_comprobante(up$datapath, nombre)
  }

  if (nuevo) {
    row <- setNames(as.list(rep(NA_character_, length(cols))), cols)
    row$id <- id
    for (n in names(reales)) row[[n]] <- as.character(reales[[n]])
    for (n in names(sp$fijo)) row[[n]] <- sp$fijo[[n]]
    row$creado <- now_txt(); row$creado_por <- ctx$usuario
    if ("admin_email" %in% cols && identical(ctx$rol, "admin")) row$admin_email <- ctx$email
    if (!is.null(arch)) row[names(arch)] <- arch
    d <- rbind(d, as.data.frame(row, stringsAsFactors = FALSE))
    write_tbl(sp$tabla, d)
    log_change(ctx$usuario, "Crear", sp$singular, id, sp$etiqueta(as.data.frame(row, stringsAsFactors = FALSE), ctx))
  } else {
    i <- which(d$id == id)
    for (n in names(reales)) d[i, n] <- as.character(reales[[n]])
    if (!is.null(arch)) for (n in names(arch)) d[i, n] <- arch[[n]]
    d[i, "editado"] <- now_txt(); d[i, "editado_por"] <- ctx$usuario
    write_tbl(sp$tabla, d)
    labs <- list(); tipos <- list()
    for (f in sp$campos) if (f$tipo != "file" && !isTRUE(f$virtual)) { labs[[f$id]] <- f$label; tipos[[f$id]] <- f$tipo }
    partes <- character(0)
    for (n in names(labs)) {
      a <- as.character(old[[n]]); a <- if (is.na(a)) "" else a
      b <- as.character(reales[[n]] %||% ""); b <- if (is.na(b)) "" else b
      if (n %in% NUM_COLS) { a <- if (nzchar(a)) format(as.numeric(a)) else ""; b <- if (nzchar(b)) format(as.numeric(b)) else "" }
      if (identical(tipos[[n]], "date")) { a <- fecha_mx(a); b <- fecha_mx(b) }
      if (!identical(a, b)) partes <- c(partes, sprintf("%s: «%s» → «%s»", labs[[n]], a, b))
    }
    if (!is.null(arch)) partes <- c(partes, "Comprobante reemplazado")
    log_change(ctx$usuario, "Editar", sp$singular, id,
               paste0(sp$etiqueta(d[i, , drop = FALSE], ctx), if (length(partes)) paste0(" · ", paste(partes, collapse = "; ")) else " · sin cambios"))
  }
  if (!is.null(sp$despues_guardar)) sp$despues_guardar(id, vals, ctx, old)
  invisible(TRUE)
}

# ---------------------------------------------------------------- Ver detalle
modal_ver <- function(sp, row, ctx) {
  filas <- lapply(sp$campos, function(f) {
    v <- row[[f$id]]
    txt <- if (f$tipo == "file") HTML(link_ver(link_comprobante(row$archivo_tipo, row$archivo, row$archivo_link), "Abrir comprobante"))
      else if (isTRUE(f$virtual) && !is.null(sp$valores_extra)) {
        x <- sp$valores_extra(row)[[f$id]]
        if (f$id == "casas") paste(nombre_casa(ctx$casas_all, x), collapse = ", ") else paste(x, collapse = ", ")
      }
      else if (f$id == "casa_id") nombre_casa(ctx$casas_all, v)
      else if (f$id == "orden_id") { o <- read_tbl("ordenes"); t <- o$titulo[match(v, o$id)]; if (is.na(t)) "—" else t }
      else if (f$tipo == "date") { x <- fecha_mx(v); if (nzchar(x)) x else "—" }
      else if (f$id == "mes") mes_txt(v)
      else if (f$id %in% c("monto", "renta", "deposito", "costo_estimado")) money(v)
      else if (f$id == "activa") if (identical(v, "si")) "Sí" else "No"
      else if (is.null(v) || is.na(v) || !nzchar(as.character(v))) "—" else as.character(v)
    tags$tr(tags$th(f$label), tags$td(class = if (f$tipo == "textarea") "pre", txt))
  })
  extra <- if (!is.null(sp$detalle_extra)) sp$detalle_extra(row, ctx)
  aud <- c(if (!is.na(row$creado %||% NA)) sprintf("Creado %s por %s", row$creado, row$creado_por %||% row$admin_email %||% "—"),
           if (!is.na(row$editado %||% NA)) sprintf("Última edición %s por %s", row$editado, row$editado_por %||% "—"))
  showModal(modalDialog(title = div(class = "modal-t", icon(sp$icono), sp$singular), size = "l", easyClose = TRUE,
    tags$table(class = "detail", do.call(tags$tbody, filas)), extra,
    if (length(aud)) div(class = "audit", icon("clock-rotate-left"), paste(aud, collapse = " · ")),
    footer = modalButton("Cerrar")))
}
