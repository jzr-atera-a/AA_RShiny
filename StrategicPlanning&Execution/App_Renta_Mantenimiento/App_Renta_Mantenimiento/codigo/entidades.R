# ============================================================================
# SECCIONES: qué campos tiene cada registro, quién puede editarlo y cómo se ve
# ============================================================================

CATEG_MATERIAL <- c("Plomería", "Electricidad", "Pintura", "Carpintería", "Herrería", "Jardinería", "Limpieza",
                    "Ferretería general", "Aires acondicionados", "Electrodomésticos", "Albañilería", "Otro")
SERVICIOS <- c("Agua", "Electricidad (CFE)", "Gas", "Plomería", "Mantenimiento de aires acondicionados",
               "Fumigación", "Jardinería", "Limpieza", "Albañilería", "Cerrajería", "Internet / TV", "Predial", "Otro")
ESPECIALIDADES <- c("Plomería", "Electricidad", "Aires acondicionados", "Pintura", "Carpintería", "Herrería",
                    "Jardinería", "Fumigación", "Limpieza", "Albañilería", "Impermeabilización", "Gas", "Cerrajería",
                    "Tienda / ferretería", "Otro")
PRIORIDADES   <- c("Urgente", "Alta", "Media", "Baja")
ESTADOS_ORDEN <- c("Abierta", "En proceso", "En espera", "Terminada", "Cancelada")
REPORTADO     <- c("Inquilino", "Administrador", "Dueño", "Inspección")
METODOS       <- c("Transferencia", "Depósito", "Efectivo", "Cheque", "Otro")
TIPOS_INSP    <- c("Rutina", "Entrada de inquilino", "Salida de inquilino", "Por reporte", "Otro")
ESTADO_GRAL   <- c("Excelente", "Bueno", "Regular", "Malo")
TIPO_PROP     <- c("Casa", "Departamento", "Local comercial", "Oficina", "Terreno", "Otro")
PREVENTIVO_CAT <- c(
  "Servicio a minisplits / aires acondicionados" = 6, "Cambio de filtros de aire" = 3,
  "Limpieza de tinaco y cisterna" = 6, "Fumigación" = 6, "Impermeabilización" = 12,
  "Revisión de instalación de gas" = 12, "Revisión de bomba de agua / hidroneumático" = 6,
  "Limpieza de canaletas y bajantes" = 6, "Revisión de extintor y detectores de humo" = 12,
  "Mantenimiento de jardín" = 1, "Pintura exterior" = 24, "Revisión eléctrica (centro de carga)" = 12,
  "Mantenimiento de calentador / boiler" = 12)

ch_casas  <- function(ctx) setNames(ctx$casas$id, ctx$casas$nombre)
ch_prov   <- function(ctx) sort(unique(read_tbl("proveedores")$nombre))
ch_ordenes <- function(ctx) {
  o <- visibles(read_tbl("ordenes"), ctx, "fecha"); o <- o[o$casa_id %in% ctx$casas$id, , drop = FALSE]
  if (!nrow(o)) return(c("Ninguna" = ""))
  o <- o[order(o$estado %notin% ORDEN_ABIERTA, o$fecha), , drop = FALSE]
  c("Ninguna" = "", setNames(o$id, paste0(nombre_casa(ctx$casas_all, o$casa_id), " · ", o$titulo,
                                          ifelse(o$estado %in% ORDEN_ABIERTA, "", paste0(" (", o$estado, ")")))))
}
etq_casa <- function(r, ctx) nombre_casa(ctx$casas_all, r$casa_id)

# ---------------------------------------------------------------- Gastos (materiales y servicios)
gasto_spec <- function(tipo) {
  mat <- tipo == "Material"
  list(
    key = if (mat) "mat" else "srv", tabla = "recibos", tab = if (mat) "materiales" else "servicios",
    titulo = if (mat) "Materiales" else "Servicios", singular = if (mat) "Recibo de material" else "Pago de servicio",
    subtitulo = if (mat) "Recibos de material comprado para el mantenimiento de cada casa."
                else "Pagos de agua, luz, gas, plomería, aires acondicionados y otros servicios.",
    icono = if (mat) "screwdriver-wrench" else "bolt", prefijo = if (mat) "m" else "s",
    boton = if (mat) "Nuevo recibo" else "Nuevo pago",
    editores = "admin", casa = TRUE, fecha = "fecha", fijo = list(tipo = tipo), orden = "fecha",
    campos = list(
      campo("casa_id", "Casa", "select", req = TRUE, choices = ch_casas),
      campo("fecha", if (mat) "Fecha de la compra" else "Fecha del pago", "date", req = TRUE),
      campo("categoria", if (mat) "Categoría" else "Servicio", "select", req = TRUE, choices = if (mat) CATEG_MATERIAL else SERVICIOS),
      campo("monto", "Monto ($ MXN)", "number", req = TRUE, min = 0.01),
      campo("concepto", if (mat) "Qué se compró" else "Concepto", req = TRUE, ancho = 12),
      campo("proveedor", if (mat) "Tienda o proveedor" else "Proveedor o empresa", "selectize", choices = ch_prov),
      campo("orden_id", "Orden de trabajo (opcional)", "select", choices = ch_ordenes),
      campo("archivo", "Foto o PDF del recibo", "file", req = TRUE, ancho = 12),
      campo("notas", "Notas", "textarea", ancho = 12)),
    columnas = list(
      col("Casa", "casa_id", "casa"), col("Fecha", "fecha", "date"),
      col(if (mat) "Categoría" else "Servicio", "categoria"), col("Concepto", "concepto", "long", n = 60),
      col("Proveedor", "proveedor"), col("Monto", "monto", "money"),
      col("Orden", "orden_id", "fun", fun = function(d, ctx) {
        o <- read_tbl("ordenes"); t <- o$titulo[match(d$orden_id, o$id)]; ifelse(is.na(t), "", largo(t, 30)) }),
      col("Recibo", "archivo", "link")),
    preparar = function(vals, ctx, old) { if (!mat) vals$servicio <- vals$categoria; vals },
    etiqueta = function(r, ctx) sprintf("%s · %s · %s · %s", etq_casa(r, ctx), fecha_mx(r$fecha), money(r$monto), r$concepto),
    resumen = function(d) if (nrow(d)) {
      top <- sort(tapply(d$monto, d$categoria, sum, na.rm = TRUE), decreasing = TRUE)[1]
      list(span(class = "chip", icon("tag"), sprintf("Mayor gasto: %s (%s)", names(top), money(top))))
    }
  )
}

ENTIDADES <- list(
  # ------------------------------------------------------------ Casas (dueño)
  casas = list(
    key = "cas", tabla = "casas", tab = "casas", titulo = "Casas y periodos", singular = "Casa",
    subtitulo = "Cada casa tiene un periodo: los administradores solo registran y ven lo de ese periodo.",
    icono = "house", prefijo = "c", boton = "Nueva casa", editores = "dueno", casa = FALSE, orden = "nombre",
    arriba = "casas_cards_dueno",
    campos = list(
      campo("nombre", "Nombre de la casa", req = TRUE, ayuda = "Ejemplo: Casa Reforma 100"),
      campo("tipo_prop", "Tipo de propiedad", "select", choices = TIPO_PROP, default = "Casa"),
      campo("direccion", "Dirección", ancho = 12),
      campo("inicio", "Inicio del periodo de administración", "date", req = TRUE),
      campo("fin", "Fin del periodo de administración", "date", req = TRUE, hoy = FALSE),
      campo("activa", "¿Activa?", "select", choices = c("Sí" = "si", "No" = "no"), default = "si",
            ayuda = "Si no está activa, los administradores no la ven."),
      campo("notas", "Notas", "textarea", ancho = 12)),
    columnas = list(col("Casa", "nombre"), col("Tipo", "tipo_prop"), col("Dirección", "direccion", "long", n = 50),
                    col("Inicio", "inicio", "date"), col("Fin", "fin", "date"),
                    col("Activa", "activa", "fun", fun = function(d, ctx) badge(d$activa, COLORES$activa, ifelse(d$activa == "si", "Activa", "Inactiva"))),
                    col("Administradores", "id", "fun", fun = function(d, ctx) {
                      a <- read_tbl("asignaciones"); ad <- read_tbl("admins")
                      vapply(d$id, function(i) { e <- a$email[a$casa_id == i]; if (!length(e)) '<span class="muted">Sin asignar</span>'
                        else esc(paste(ifelse(is.na(ad$nombre[match(e, ad$email)]), e, ad$nombre[match(e, ad$email)]), collapse = ", ")) }, "") })),
    validar = function(v, ctx, old) if (v$inicio > v$fin) "La fecha de inicio debe ser anterior a la de fin.",
    etiqueta = function(r, ctx) sprintf("%s (%s a %s)", r$nombre, fecha_mx(r$inicio), fecha_mx(r$fin)),
    puede_eliminar = function(r) {
      usados <- sum(vapply(c("recibos", "pagos", "ordenes", "inspecciones", "contratos", "preventivo"),
                           function(t) sum(read_tbl(t)$casa_id == r$id, na.rm = TRUE), 0))
      if (usados > 0) sprintf("No se puede eliminar: la casa tiene %d registros. Márquela como inactiva.", usados)
    },
    al_eliminar = function(r, ctx) { a <- read_tbl("asignaciones"); write_tbl("asignaciones", a[a$casa_id != r$id, , drop = FALSE]) }
  ),

  # ------------------------------------------------------------ Administradores (dueño)
  admins = list(
    key = "adm", tabla = "admins", tab = "admins", titulo = "Administradores", singular = "Administrador",
    subtitulo = "Solo los correos aprobados aquí pueden entrar. Cada uno ve únicamente sus casas asignadas.",
    icono = "user-tie", prefijo = "a", boton = "Aprobar administrador", editores = "dueno", casa = FALSE, orden = "nombre",
    campos = list(
      campo("email", "Correo electrónico", req = TRUE, solo_crear = TRUE, ayuda = "Con este correo entra a la app."),
      campo("nombre", "Nombre", req = TRUE),
      campo("telefono", "Teléfono"),
      campo("casas", "Casas que administra", "multi", virtual = TRUE, choices = function(ctx) setNames(ctx$casas_all$id, ctx$casas_all$nombre))),
    columnas = list(col("Nombre", "nombre"), col("Correo", "email"), col("Teléfono", "telefono"),
                    col("Casas", "email", "fun", fun = function(d, ctx) {
                      a <- read_tbl("asignaciones")
                      vapply(d$email, function(e) { ids <- a$casa_id[a$email == e]
                        if (!length(ids)) '<span class="muted">Sin casas</span>' else paste(badge(nombre_casa(ctx$casas_all, ids), NULL), collapse = " ") }, "") })),
    valores_extra = function(r) { a <- read_tbl("asignaciones"); list(casas = a$casa_id[a$email == r$email]) },
    validar = function(v, ctx, old) {
      v$email <- tolower(v$email)
      if (!grepl("^[^@ ]+@[^@ ]+\\.[^@ ]+$", v$email)) return("Escriba un correo válido.")
      if (is.null(old) && v$email %in% tolower(read_tbl("admins")$email)) return("Ese correo ya está aprobado.")
    },
    preparar = function(v, ctx, old) { v$email <- tolower(trimws(v$email)); v },
    despues_guardar = function(id, v, ctx, old) {
      a <- read_tbl("asignaciones"); antes <- sort(a$casa_id[a$email == v$email]); despues <- sort(v$casas)
      a <- a[a$email != v$email, , drop = FALSE]
      if (length(despues)) a <- rbind(a, data.frame(email = v$email, casa_id = despues, stringsAsFactors = FALSE))
      write_tbl("asignaciones", a)
      if (!identical(antes, despues))
        log_change(ctx$usuario, "Editar", "Asignación de casas", id, sprintf("%s · casas: «%s» → «%s»", v$email,
                   paste(nombre_casa(ctx$casas_all, antes), collapse = ", "), paste(nombre_casa(ctx$casas_all, despues), collapse = ", ")))
    },
    etiqueta = function(r, ctx) sprintf("%s (%s)", r$nombre, r$email),
    al_eliminar = function(r, ctx) { a <- read_tbl("asignaciones"); write_tbl("asignaciones", a[a$email != r$email, , drop = FALSE]) }
  ),

  # ------------------------------------------------------------ Contratos (dueño)
  contratos = list(
    key = "con", tabla = "contratos", tab = "contratos", titulo = "Contratos e inquilinos", singular = "Contrato",
    subtitulo = "Inquilino, renta, día de pago y vigencia. Con esto la app sabe qué rentas esperar y avisa antes del vencimiento.",
    icono = "file-signature", prefijo = "k", boton = "Nuevo contrato", editores = "dueno", casa = TRUE, orden = "inicio",
    filtro = list(label = "Estado", campo = "estado", choices = c("Todos" = "", "Vigente", "Terminado"), default = ""),
    campos = list(
      campo("casa_id", "Casa", "select", req = TRUE, choices = ch_casas),
      campo("inquilino", "Nombre del inquilino", req = TRUE),
      campo("telefono", "Teléfono del inquilino"), campo("email", "Correo del inquilino"),
      campo("renta", "Renta mensual ($ MXN)", "number", req = TRUE, min = 0),
      campo("dia_pago", "Día de pago (1–31)", "number", req = TRUE, min = 1, max = 31, default = 5),
      campo("inicio", "Inicio del contrato", "date", req = TRUE), campo("fin", "Fin del contrato", "date", req = TRUE, hoy = FALSE),
      campo("deposito", "Depósito en garantía ($)", "number", min = 0),
      campo("estado", "Estado", "select", choices = c("Vigente", "Terminado"), default = "Vigente"),
      campo("notas", "Notas", "textarea", ancho = 12)),
    columnas = list(col("Casa", "casa_id", "casa"), col("Inquilino", "inquilino"), col("Teléfono", "telefono"),
                    col("Renta", "renta", "money"), col("Día de pago", "dia_pago"),
                    col("Inicio", "inicio", "date"), col("Fin", "fin", "date"),
                    col("Estado", "estado", "fun", fun = function(d, ctx) {
                      dias <- as.integer(as_fecha(d$fin) - hoy())
                      ifelse(d$estado == "Terminado", badge(d$estado, COLORES$contrato),
                        ifelse(!is.na(dias) & dias < 0, badge("Vencido", c(Vencido = "red")),
                          ifelse(!is.na(dias) & dias <= 60, badge(paste0("Vence en ", dias, " días"), NULL) |> sub(pattern = "p-gray", replacement = "p-orange"),
                                 badge("Vigente", COLORES$contrato)))) })),
    validar = function(v, ctx, old) if (v$inicio > v$fin) "El inicio del contrato debe ser anterior al fin.",
    etiqueta = function(r, ctx) sprintf("%s · %s · %s/mes", etq_casa(r, ctx), r$inquilino, money(r$renta))
  ),

  # ------------------------------------------------------------ Rentas (administrador)
  pagos = list(
    key = "pag", tabla = "pagos", tab = "rentas", titulo = "Rentas", singular = "Pago de renta",
    subtitulo = "Pagos de renta recibidos. El tablero muestra qué meses están pagados, pendientes o atrasados.",
    icono = "money-bill-wave", prefijo = "r", boton = "Registrar pago", editores = "admin", casa = TRUE, fecha = "fecha",
    orden = "fecha", arriba = "rentas_tablero",
    campos = list(
      campo("casa_id", "Casa", "select", req = TRUE, choices = ch_casas),
      campo("mes", "Mes que se paga", "select", req = TRUE, choices = function(ctx) meses_opciones(), default = format(hoy(), "%Y-%m")),
      campo("fecha", "Fecha en que se recibió", "date", req = TRUE),
      campo("monto", "Monto recibido ($ MXN)", "number", req = TRUE, min = 0.01),
      campo("metodo", "Forma de pago", "select", choices = METODOS),
      campo("archivo", "Comprobante (opcional)", "file"),
      campo("notas", "Notas", "textarea", ancho = 12)),
    columnas = list(col("Casa", "casa_id", "casa"), col("Mes", "mes", "mes"),
                    col("Inquilino", "casa_id", "fun", fun = function(d, ctx) {
                      con <- read_tbl("contratos")
                      vapply(seq_len(nrow(d)), function(i) { c1 <- contrato_de(con, d$casa_id[i], as.character(mes_fin(d$mes[i]))); if (is.null(c1)) "—" else esc(c1$inquilino) }, "") }),
                    col("Monto", "monto", "money"), col("Recibido", "fecha", "date"), col("Forma", "metodo"),
                    col("Comprobante", "archivo", "link")),
    reactivo = function(input, session, idf, nuevo, st) {
      casa <- input[[idf("casa_id")]]; mes <- input[[idf("mes")]]
      if (!nuevo || is.null(casa) || !nzchar(casa) || is.null(mes)) return()
      c1 <- contrato_de(read_tbl("contratos"), casa, as.character(mes_fin(mes)))
      if (!is.null(c1)) updateNumericInput(session, idf("monto"), value = c1$renta)
    },
    etiqueta = function(r, ctx) sprintf("%s · renta de %s · %s", etq_casa(r, ctx), tolower(mes_txt(r$mes)), money(r$monto))
  ),

  # ------------------------------------------------------------ Órdenes de trabajo
  ordenes = list(
    key = "ord", tabla = "ordenes", tab = "ordenes", titulo = "Órdenes de trabajo", singular = "Orden de trabajo",
    subtitulo = "Cada reparación, desde que se reporta hasta que se termina: prioridad, estado, proveedor y costo.",
    icono = "clipboard-list", prefijo = "o", boton = "Nueva orden", editores = c("admin", "dueno"), casa = TRUE,
    fecha = "fecha", orden = "fecha",
    filtro = list(label = "Estado", campo = "estado", choices = c("Abiertas" = "__abiertas", "Todas" = "", ESTADOS_ORDEN),
                  default = "__abiertas", fun = function(d, v) if (v == "__abiertas") d[d$estado %in% ORDEN_ABIERTA, , drop = FALSE] else d[d$estado == v, , drop = FALSE]),
    campos = list(
      campo("casa_id", "Casa", "select", req = TRUE, choices = ch_casas),
      campo("fecha", "Fecha del reporte", "date", req = TRUE),
      campo("titulo", "¿Qué hay que arreglar?", req = TRUE, ancho = 12, ayuda = "Ejemplo: Fuga en el baño principal"),
      campo("descripcion", "Detalles", "textarea", ancho = 12),
      campo("reportado_por", "Lo reportó", "select", choices = REPORTADO),
      campo("prioridad", "Prioridad", "select", choices = PRIORIDADES, default = "Media"),
      campo("estado", "Estado", "select", choices = ESTADOS_ORDEN, default = "Abierta"),
      campo("proveedor", "Proveedor asignado", "selectize", choices = ch_prov),
      campo("costo_estimado", "Costo estimado ($)", "number", min = 0),
      campo("fecha_cierre", "Fecha en que se terminó", "date", hoy = FALSE),
      campo("archivo", "Foto del problema (opcional)", "file", ancho = 12),
      campo("notas", "Notas y seguimiento", "textarea", ancho = 12)),
    columnas = list(col("Casa", "casa_id", "casa"), col("Reporte", "fecha", "date"), col("Trabajo", "titulo", "long", n = 50),
                    col("Prioridad", "prioridad", "badge", mapa = "prioridad"), col("Estado", "estado", "badge", mapa = "estado"),
                    col("Proveedor", "proveedor"),
                    col("Gastado", "id", "fun", fun = function(d, ctx) {
                      r <- read_tbl("recibos"); money(vapply(d$id, function(i) sum(r$monto[r$orden_id %in% i], na.rm = TRUE), 0)) }),
                    col("Días", "fecha", "fun", fun = function(d, ctx) {
                      fin <- ifelse(d$estado %in% ORDEN_ABIERTA | is.na(d$fecha_cierre), as.character(hoy()), d$fecha_cierre)
                      as.character(as.integer(as_fecha(fin) - as_fecha(d$fecha))) })),
    preparar = function(v, ctx, old) {
      if (v$estado %in% c("Terminada", "Cancelada") && !nzchar(v$fecha_cierre)) v$fecha_cierre <- as.character(hoy())
      if (v$estado %in% ORDEN_ABIERTA) v$fecha_cierre <- ""
      v
    },
    detalle_extra = function(row, ctx) {
      r <- read_tbl("recibos"); r <- r[r$orden_id %in% row$id, , drop = FALSE]
      if (!nrow(r)) return(div(class = "form-note", icon("receipt"), "Aún no hay recibos ligados a esta orden. Al capturar un recibo, elija esta orden."))
      tagList(h4(class = "sub-h", "Recibos de esta orden"),
              tags$table(class = "detail", tags$tbody(lapply(seq_len(nrow(r)), function(i)
                tags$tr(tags$th(fecha_mx(r$fecha[i])), tags$td(paste(r$concepto[i], "·", money(r$monto[i]))))),
                tags$tr(class = "tot", tags$th("Total"), tags$td(money(sum(r$monto, na.rm = TRUE)))))))
    },
    resumen = function(d) list(span(class = "chip chip-red", icon("triangle-exclamation"), sprintf("%d urgentes", sum(d$prioridad == "Urgente" & d$estado %in% ORDEN_ABIERTA, na.rm = TRUE)))),
    etiqueta = function(r, ctx) sprintf("%s · %s · %s · %s", etq_casa(r, ctx), r$titulo, r$prioridad, r$estado)
  ),

  # ------------------------------------------------------------ Mantenimiento preventivo
  preventivo = list(
    key = "pre", tabla = "preventivo", tab = "preventivo", titulo = "Mantenimiento preventivo", singular = "Tarea preventiva",
    subtitulo = "Tareas que se repiten (aires, tinaco, fumigación…). La app calcula la próxima fecha y avisa cuando se vence.",
    icono = "calendar-check", prefijo = "p", boton = "Nueva tarea", editores = c("admin", "dueno"), casa = TRUE, orden = NULL,
    filtro = list(label = "Estado", choices = c("Todas" = "", "Vencidas" = "Vencida", "Próximas (30 días)" = "Próxima", "Al día" = "Al día"),
                  default = "", fun = function(d, v) d[estado_prev(d)$estado == v, , drop = FALSE]),
    campos = list(
      campo("casa_id", "Casa", "select", req = TRUE, choices = ch_casas),
      campo("tarea", "Tarea", "selectize", req = TRUE, choices = names(PREVENTIVO_CAT), ayuda = "Elija una sugerida o escriba otra."),
      campo("frecuencia", "Cada cuántos meses", "number", req = TRUE, min = 1, max = 120, default = 6),
      campo("ultima", "Última vez que se hizo", "date", req = TRUE),
      campo("responsable", "Proveedor o responsable", "selectize", choices = ch_prov),
      campo("notas", "Notas", "textarea", ancho = 12)),
    columnas = list(col("Casa", "casa_id", "casa"), col("Tarea", "tarea"),
                    col("Cada", "frecuencia", "fun", fun = function(d, ctx) paste(d$frecuencia, ifelse(d$frecuencia == 1, "mes", "meses"))),
                    col("Última vez", "ultima", "date"),
                    col("Próxima", "ultima", "fun", fun = function(d, ctx) fecha_mx(estado_prev(d)$proxima),
                        sort = function(d) as.character(estado_prev(d)$proxima)),
                    col("Estado", "ultima", "fun", fun = function(d, ctx) { e <- estado_prev(d)
                      txt <- ifelse(e$estado == "Vencida", paste0("Vencida hace ", -e$dias, " d"), ifelse(e$estado == "Próxima", paste0("En ", e$dias, " días"), e$estado))
                      badge(e$estado, COLORES$prev, txt) }, sort = function(d) sprintf("%06d", estado_prev(d)$dias + 50000)),
                    col("Responsable", "responsable")),
    acciones = list(hecho = list(icono = "check", titulo = "Marcar como hecho", roles = c("admin", "dueno"),
      handler = function(row, input, session, st) {
        st$prev_id(row$id)
        showModal(modalDialog(title = div(class = "modal-t", icon("check"), "Marcar como hecho"),
          p(HTML(sprintf("<b>%s</b> · %s", esc(row$tarea), esc(nombre_casa(st$ctx()$casas_all, row$casa_id))))),
          dateInput("prev_hecho_fecha", "¿Cuándo se hizo?", value = hoy(), language = "es", format = "dd/mm/yyyy"),
          textInput("prev_hecho_nota", "Nota (opcional)", width = "100%", placeholder = "Quién lo hizo, costo, observaciones…"),
          div(class = "form-note", icon("circle-info"), "Si hubo gasto, regístrelo también en Materiales o Servicios."),
          footer = tagList(modalButton("Cancelar"), actionButton("prev_hecho_ok", "Guardar", icon = icon("check"), class = "btn-primary"))))
      })),
    reactivo = function(input, session, idf, nuevo, st) {
      t <- input[[idf("tarea")]]
      if (nuevo && !is.null(t) && t %in% names(PREVENTIVO_CAT)) updateNumericInput(session, idf("frecuencia"), value = PREVENTIVO_CAT[[t]])
    },
    resumen = function(d) if (nrow(d)) { e <- estado_prev(d)$estado
      list(span(class = "chip chip-red", icon("calendar-xmark"), sprintf("%d vencidas", sum(e == "Vencida"))),
           span(class = "chip chip-orange", icon("calendar-day"), sprintf("%d próximas", sum(e == "Próxima")))) },
    etiqueta = function(r, ctx) sprintf("%s · %s (cada %s meses)", etq_casa(r, ctx), r$tarea, r$frecuencia)
  ),

  # ------------------------------------------------------------ Inspecciones (administrador)
  inspecciones = list(
    key = "ins", tabla = "inspecciones", tab = "inspecciones", titulo = "Inspecciones", singular = "Inspección",
    subtitulo = "Visitas a la casa: estado general, lo que se habló con los inquilinos, lo que se planea y comentarios para el dueño.",
    icono = "magnifying-glass", prefijo = "i", boton = "Nueva inspección", editores = "admin", casa = TRUE, fecha = "fecha", orden = "fecha",
    campos = list(
      campo("casa_id", "Casa", "select", req = TRUE, choices = ch_casas),
      campo("fecha", "Fecha de la inspección", "date", req = TRUE),
      campo("tipo_insp", "Tipo de visita", "select", choices = TIPOS_INSP),
      campo("estado_general", "Estado general de la casa", "select", choices = ESTADO_GRAL, default = "Bueno"),
      campo("con_inquilinos", "Lo que se habló con los inquilinos", "textarea", req = TRUE, ancho = 12),
      campo("plan", "Lo que se planea hacer", "textarea", ancho = 12),
      campo("comentario_dueno", "Comentarios para el dueño", "textarea", ancho = 12),
      campo("archivo", "Foto (opcional)", "file", ancho = 12)),
    columnas = list(col("Casa", "casa_id", "casa"), col("Fecha", "fecha", "date"), col("Tipo", "tipo_insp"),
                    col("Estado", "estado_general", "badge", mapa = "general"),
                    col("Con inquilinos", "con_inquilinos", "long", n = 70), col("Plan", "plan", "long", n = 60),
                    col("Para el dueño", "comentario_dueno", "long", n = 60), col("Foto", "archivo", "link")),
    etiqueta = function(r, ctx) sprintf("%s · %s · %s", etq_casa(r, ctx), fecha_mx(r$fecha), r$tipo_insp %||% "Inspección")
  ),

  # ------------------------------------------------------------ Proveedores (todos)
  proveedores = list(
    key = "prv", tabla = "proveedores", tab = "proveedores", titulo = "Proveedores", singular = "Proveedor",
    subtitulo = "Plomeros, electricistas, técnicos de aires y tiendas de confianza, con su teléfono y calificación.",
    icono = "address-book", prefijo = "v", boton = "Nuevo proveedor", editores = c("admin", "dueno"), casa = FALSE, orden = NULL,
    filtro = list(label = "Especialidad", campo = "especialidad", choices = c("Todas" = "", ESPECIALIDADES), default = ""),
    campos = list(
      campo("nombre", "Nombre o empresa", req = TRUE),
      campo("especialidad", "Especialidad", "select", choices = ESPECIALIDADES),
      campo("telefono", "Teléfono"), campo("email", "Correo"),
      campo("calificacion", "Calificación", "select", choices = c("★★★★★ Excelente" = 5, "★★★★ Bueno" = 4, "★★★ Regular" = 3, "★★ Malo" = 2, "★ Muy malo" = 1), default = 4),
      campo("notas", "Notas", "textarea", ancho = 12)),
    columnas = list(col("Nombre", "nombre"), col("Especialidad", "especialidad"),
                    col("Teléfono", "telefono", "fun", fun = function(d, ctx) ifelse(is.na(d$telefono) | d$telefono == "", "",
                        sprintf('<a href="tel:%s">%s</a>', esc(gsub("[^0-9+]", "", d$telefono)), esc(d$telefono)))),
                    col("Correo", "email"), col("Calificación", "calificacion", "stars"),
                    col("Trabajos", "nombre", "fun", fun = function(d, ctx) {
                      o <- read_tbl("ordenes"); r <- read_tbl("recibos")
                      vapply(d$nombre, function(n) as.character(sum(o$proveedor == n, na.rm = TRUE) + sum(r$proveedor == n, na.rm = TRUE)), "") })),
    etiqueta = function(r, ctx) sprintf("%s (%s)", r$nombre, r$especialidad %||% "")
  ),

  materiales = gasto_spec("Material"),
  servicios  = gasto_spec("Servicio")
)
