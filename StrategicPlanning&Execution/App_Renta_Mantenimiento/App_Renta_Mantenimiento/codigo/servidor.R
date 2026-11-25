# ============================================================================
# SERVIDOR: acceso, menú, panel, tarjetas de casas, reportes, historial, configuración
# ============================================================================

menu_dueno <- function() {
  sidebarMenu(id = "tabs",
    menuItem("Panel general", tabName = "inicio", icon = icon("gauge-high"), selected = TRUE),
    tags$li(class = "header", "PROPIEDADES"),
    menuItem("Casas y periodos", tabName = "casas", icon = icon("house")),
    menuItem("Contratos e inquilinos", tabName = "contratos", icon = icon("file-signature")),
    menuItem("Administradores", tabName = "admins", icon = icon("user-tie")),
    tags$li(class = "header", "DINERO"),
    menuItem("Materiales", tabName = "materiales", icon = icon("screwdriver-wrench")),
    menuItem("Servicios", tabName = "servicios", icon = icon("bolt")),
    menuItem("Rentas", tabName = "rentas", icon = icon("money-bill-wave")),
    tags$li(class = "header", "MANTENIMIENTO"),
    menuItem("Órdenes de trabajo", tabName = "ordenes", icon = icon("clipboard-list")),
    menuItem("Preventivo", tabName = "preventivo", icon = icon("calendar-check")),
    menuItem("Inspecciones", tabName = "inspecciones", icon = icon("magnifying-glass")),
    menuItem("Proveedores", tabName = "proveedores", icon = icon("address-book")),
    tags$li(class = "header", "CONTROL"),
    menuItem("Reportes y Excel", tabName = "reportes", icon = icon("file-excel")),
    menuItem("Historial de cambios", tabName = "historial", icon = icon("clock-rotate-left")),
    menuItem("Configuración", tabName = "config", icon = icon("gear")))
}

menu_admin <- function() {
  sidebarMenu(id = "tabs",
    menuItem("Mi panel", tabName = "inicio", icon = icon("gauge-high"), selected = TRUE),
    menuItem("Mis casas", tabName = "mis_casas", icon = icon("house-user")),
    tags$li(class = "header", "GASTOS Y RENTAS"),
    menuItem("Materiales", tabName = "materiales", icon = icon("screwdriver-wrench")),
    menuItem("Servicios", tabName = "servicios", icon = icon("bolt")),
    menuItem("Rentas", tabName = "rentas", icon = icon("money-bill-wave")),
    tags$li(class = "header", "MANTENIMIENTO"),
    menuItem("Órdenes de trabajo", tabName = "ordenes", icon = icon("clipboard-list")),
    menuItem("Preventivo", tabName = "preventivo", icon = icon("calendar-check")),
    menuItem("Inspecciones", tabName = "inspecciones", icon = icon("magnifying-glass")),
    menuItem("Proveedores", tabName = "proveedores", icon = icon("address-book")),
    tags$li(class = "header", "REPORTES"),
    menuItem("Reportes y Excel", tabName = "reportes", icon = icon("file-excel")))
}

# ---------------------------------------------------------------- Tarjetas de casas
casas_cards <- function(ctx) {
  cs <- ctx$casas
  if (!nrow(cs)) return(vacio("house-circle-xmark", "No hay casas para mostrar.",
                              if (identical(ctx$rol, "admin")) "Pida al dueño que le asigne casas y un periodo vigente." else "Agregue la primera con «Nueva casa»."))
  con <- read_tbl("contratos"); rec <- visibles(read_tbl("recibos"), ctx, "fecha")
  ord <- visibles(read_tbl("ordenes"), ctx, "fecha"); pv <- read_tbl("preventivo")
  asig <- read_tbl("asignaciones"); ad <- read_tbl("admins"); er <- estado_rentas(ctx, 1)
  div(class = "house-grid", lapply(seq_len(nrow(cs)), function(i) {
    c1 <- cs[i, ]; h <- hoy()
    ini <- as_fecha(c1$inicio); fin <- as_fecha(c1$fin)
    pct <- if (!is.na(ini) && !is.na(fin) && fin > ini) max(0, min(100, round(100 * as.numeric(h - ini) / as.numeric(fin - ini)))) else 0
    quedan <- as.integer(fin - h)
    per_txt <- if (is.na(quedan)) "" else if (quedan < 0) "Periodo terminado" else if (h < ini) "Aún no empieza" else paste("Quedan", quedan, "días")
    k <- contrato_de(con, c1$id, as.character(h))
    r_mes <- if (!is.null(er)) er[er$casa_id == c1$id, ] else NULL
    est_r <- if (!is.null(r_mes) && nrow(r_mes)) r_mes$estado[1] else "sin"
    est_lbl <- c(pagada = "Renta del mes pagada", parcial = "Pago incompleto", pendiente = "Renta por cobrar", atrasada = "Renta atrasada", sin = "Sin contrato vigente")[est_r]
    est_col <- c(pagada = "green", parcial = "orange", pendiente = "blue", atrasada = "red", sin = "gray")[est_r]
    gasto <- sum(rec$monto[rec$casa_id == c1$id & substr(rec$fecha, 1, 4) == format(h, "%Y")], na.rm = TRUE)
    abiertas <- sum(ord$casa_id == c1$id & ord$estado %in% ORDEN_ABIERTA)
    p1 <- pv[pv$casa_id == c1$id, , drop = FALSE]
    prox <- if (nrow(p1)) { e <- estado_prev(p1); j <- which.min(e$proxima); sprintf("%s · %s", p1$tarea[j], fecha_mx(e$proxima[j])) } else "Sin tareas"
    venc <- if (nrow(p1)) sum(estado_prev(p1)$estado == "Vencida") else 0
    admins <- asig$email[asig$casa_id == c1$id]
    adm_txt <- if (length(admins)) paste(ifelse(is.na(ad$nombre[match(admins, ad$email)]), admins, ad$nombre[match(admins, ad$email)]), collapse = ", ") else "Sin administrador"
    div(class = paste("house", if (c1$activa != "si") "house-off"),
      div(class = "house-top",
          div(class = "house-ic", icon(if (identical(c1$tipo_prop, "Departamento")) "building" else "house")),
          div(class = "house-name", h3(c1$nombre), div(class = "house-addr", icon("location-dot"), c1$direccion %||% "Sin dirección"),
              div(class = "house-badge", HTML(badge(est_lbl, setNames(est_col, est_lbl)))))),
      div(class = "house-period",
          div(class = "hp-row", span(icon("calendar"), " ", fecha_mx(c1$inicio), " – ", fecha_mx(c1$fin)), span(class = "muted", per_txt)),
          div(class = "bar", div(style = sprintf("width:%s%%", pct)))),
      div(class = "house-stats",
          div(div(class = "hs-l", "Inquilino"), div(class = "hs-v", if (is.null(k)) "—" else k$inquilino)),
          div(div(class = "hs-l", "Renta"), div(class = "hs-v", if (is.null(k)) "—" else money(k$renta))),
          div(div(class = "hs-l", "Gastos del año"), div(class = "hs-v", money(gasto))),
          div(div(class = "hs-l", "Órdenes abiertas"), div(class = paste("hs-v", if (abiertas > 0) "warn"), abiertas))),
      div(class = "house-foot",
          div(icon("calendar-check"), " ", span(class = if (venc > 0) "txt-red", if (venc > 0) paste(venc, "mantenimiento(s) vencido(s)") else prox)),
          div(icon("user-tie"), " ", adm_txt)))
  }))
}

# ---------------------------------------------------------------- Servidor principal de páginas fijas
servidor_paginas <- function(input, output, session, st) {
  ctx <- st$ctx

  # ---------------- Panel
  output$inicio_head <- renderUI({
    x <- ctx(); req(x$rol)
    encabezado(if (x$rol == "dueno") "Panel general" else "Mi panel",
               paste0(sub("^(.)", "\\U\\1", fecha_larga(), perl = TRUE), " · ",
                      if (x$rol == "dueno") sprintf("%d casas registradas", nrow(x$casas_all)) else sprintf("%d casa(s) a su cargo", nrow(x$casas))),
               "gauge-high")
  })
  output$inicio_kpis <- renderUI({
    x <- ctx(); req(x$rol); k <- kpis(x)
    dif <- if (k$g_ant > 0) round(100 * (k$g_mes - k$g_ant) / k$g_ant) else NA
    pct_r <- if (k$esperado > 0) round(100 * k$cobrado / k$esperado) else NA
    div(class = "kpi-grid",
      kpi("Gastos de este mes", money0(k$g_mes),
          if (is.na(dif)) paste("Mes pasado:", money0(k$g_ant)) else sprintf("%s%d %% vs. mes pasado", if (dif > 0) "+" else "", dif), "wallet", "purple"),
      kpi("Gastos del año", money0(k$g_anio), paste("Enero a", tolower(MESES[as.POSIXlt(hoy())$mon + 1]), format(hoy(), "%Y")), "chart-line", "blue"),
      kpi("Rentas del mes", money0(k$cobrado), if (k$esperado > 0) sprintf("de %s esperados (%d %%)", money0(k$esperado), pct_r) else "Sin contratos vigentes", "money-bill-wave", "green"),
      kpi("Órdenes abiertas", k$ordenes, if (k$urgentes > 0) sprintf("%d urgente(s)", k$urgentes) else "Ninguna urgente", "clipboard-list", if (k$urgentes > 0) "red" else "orange"),
      kpi("Preventivo vencido", k$vencidos, if (k$vencidos > 0) "Requiere atención" else "Todo al día", "calendar-check", if (k$vencidos > 0) "red" else "teal"))
  })
  output$inicio_alertas <- renderUI({
    x <- ctx(); req(x$rol); a <- alertas(x)
    if (is.null(a)) return(vacio("circle-check", "Todo en orden", "No hay pendientes por ahora."))
    tags$ul(class = "alert-list", lapply(seq_len(min(nrow(a), 12)), function(i)
      tags$li(class = paste0("al al-", a$nivel[i]), div(class = "al-ic", icon(a$icono[i])),
              div(div(class = "al-casa", a$casa[i]), div(class = "al-txt", a$texto[i])))),
      if (nrow(a) > 12) tags$li(class = "al-more", sprintf("y %d más…", nrow(a) - 12)))
  })
  rec_vis <- reactive({ x <- ctx(); req(x$rol); r <- visibles(read_tbl("recibos"), x, "fecha"); r[r$casa_id %in% x$casas$id, , drop = FALSE] })
  output$pl_gastos_mes <- renderPlot(plot_gastos_mes(rec_vis()), res = 96, bg = "white")
  output$pl_categorias <- renderPlot(plot_categorias(rec_vis()), res = 96, bg = "white")
  output$pl_rentas     <- renderPlot({ x <- ctx(); req(x$rol); plot_rentas(estado_rentas(x, 6)) }, res = 96, bg = "white")

  output$inicio_casas <- renderUI({
    x <- ctx(); req(x$rol)
    if (x$rol == "admin") return(tarjeta("Mis casas", icono = "house-user", casas_cards(x)))
    cs <- x$casas_all; if (!nrow(cs)) return(NULL)
    rec <- read_tbl("recibos"); pag <- read_tbl("pagos"); ord <- read_tbl("ordenes"); con <- read_tbl("contratos")
    asig <- read_tbl("asignaciones"); ad <- read_tbl("admins"); y <- format(hoy(), "%Y")
    filas <- lapply(seq_len(nrow(cs)), function(i) {
      id <- cs$id[i]; k <- contrato_de(con, id, as.character(hoy()))
      g <- sum(rec$monto[rec$casa_id == id & substr(rec$fecha, 1, 4) == y], na.rm = TRUE)
      r <- sum(pag$monto[pag$casa_id == id & substr(pag$fecha, 1, 4) == y], na.rm = TRUE)
      e <- asig$email[asig$casa_id == id]
      tags$tr(tags$td(tags$b(cs$nombre[i])),
              tags$td(if (length(e)) paste(ifelse(is.na(ad$nombre[match(e, ad$email)]), e, ad$nombre[match(e, ad$email)]), collapse = ", ") else span(class = "muted", "Sin asignar")),
              tags$td(if (is.null(k)) span(class = "muted", "—") else k$inquilino),
              tags$td(class = "num", if (is.null(k)) "—" else money(k$renta)),
              tags$td(class = "num", money(r)), tags$td(class = "num", money(g)),
              tags$td(class = paste("num", if (r - g < 0) "txt-red" else "txt-green"), money(r - g)),
              tags$td(class = "num", sum(ord$casa_id == id & ord$estado %in% ORDEN_ABIERTA)))
    })
    tarjeta(paste("Resumen por casa ·", y), icono = "table",
      div(class = "tbl-wrap", tags$table(class = "tbl",
        tags$thead(tags$tr(tags$th("Casa"), tags$th("Administrador"), tags$th("Inquilino"), tags$th(class = "num", "Renta"),
                           tags$th(class = "num", "Rentas cobradas"), tags$th(class = "num", "Gastos"), tags$th(class = "num", "Balance"),
                           tags$th(class = "num", "Órdenes"))),
        tags$tbody(filas))))
  })
  output$inicio_actividad <- renderUI({
    x <- ctx(); req(identical(x$rol, "dueno"))
    cam <- read_tbl("cambios"); cam <- cam[cam$accion != "Entrar", , drop = FALSE]
    if (!nrow(cam)) return(NULL)
    cam <- head(cam[order(cam$fecha, decreasing = TRUE), ], 8)
    tarjeta("Actividad reciente", icono = "clock-rotate-left",
      tags$ul(class = "act-list", lapply(seq_len(nrow(cam)), function(i)
        tags$li(HTML(badge(cam$accion[i], COLORES$accion)), span(class = "act-ent", cam$entidad[i]),
                span(class = "act-det", sub(" · datos: .*$", "", substr(cam$detalle[i], 1, 140))),
                span(class = "act-meta", paste(cam$usuario[i], "·", format(as.POSIXct(cam$fecha[i]), "%d/%m %H:%M")))))))
  })

  # ---------------- Tarjetas de casas
  output$casas_cards_admin <- renderUI({ x <- ctx(); req(identical(x$rol, "admin")); casas_cards(x) })
  output$casas_cards_dueno <- renderUI({ x <- ctx(); req(identical(x$rol, "dueno")); casas_cards(x) })

  # ---------------- Tablero de rentas (últimos 6 meses)
  output$rentas_tablero <- renderUI({
    x <- ctx(); req(x$rol); er <- estado_rentas(x, 6)
    if (is.null(er) || all(er$estado == "sin")) return(div(class = "card", vacio("file-signature", "Aún no hay contratos vigentes.",
      if (x$rol == "dueno") "Regístrelos en «Contratos e inquilinos» para ver aquí qué meses están pagados." else "El dueño registra los contratos; después aquí verá qué meses están pagados.")))
    meses <- sort(unique(er$mes))
    simb <- c(pagada = "✔", parcial = "◐", pendiente = "•", atrasada = "✖", sin = "—")
    tarjeta("Estado de las rentas · últimos 6 meses", icono = "table-cells",
      derecha = div(class = "legend", span(class = "lg r-pagada", "✔ Pagada"), span(class = "lg r-parcial", "◐ Incompleta"),
                    span(class = "lg r-pendiente", "• Por cobrar"), span(class = "lg r-atrasada", "✖ Atrasada")),
      div(class = "tbl-wrap", tags$table(class = "tbl rent-grid",
        tags$thead(tags$tr(tags$th("Casa"), tags$th("Inquilino"), lapply(meses, function(m) tags$th(class = "c", HTML(sub("\n", "<br>", etiqueta_mes(m))))))),
        tags$tbody(lapply(unique(er$casa_id), function(cid) {
          e <- er[er$casa_id == cid, ]; inq <- tail(e$inquilino[nzchar(e$inquilino)], 1)
          tags$tr(tags$td(tags$b(e$casa[1])), tags$td(if (length(inq)) inq else span(class = "muted", "—")),
                  lapply(meses, function(m) { j <- which(e$mes == m)
                    tags$td(class = paste("c", paste0("r-", e$estado[j])),
                            title = if (e$estado[j] == "sin") "Sin contrato" else sprintf("Pagado %s de %s", money(e$pagado[j]), money(e$renta[j])),
                            simb[e$estado[j]]) }))
        })))))
  })

  # ---------------- Preventivo: marcar como hecho
  observeEvent(input$prev_hecho_ok, {
    id <- st$prev_id(); req(id); x <- ctx()
    p <- read_tbl("preventivo"); i <- which(p$id == id); req(length(i) == 1, p$casa_id[i] %in% x$casas$id)
    f <- as.character(input$prev_hecho_fecha)
    if (!length(f) || is.na(f) || f > as.character(hoy())) return(showNotification("Elija una fecha válida (no futura).", type = "warning"))
    antes <- p$ultima[i]; p$ultima[i] <- f; p$editado[i] <- now_txt(); p$editado_por[i] <- x$usuario
    write_tbl("preventivo", p)
    nota <- trimws(input$prev_hecho_nota %||% "")
    log_change(x$usuario, "Realizado", "Tarea preventiva", id,
               sprintf("%s · %s · hecho el %s (antes: %s)%s", nombre_casa(x$casas_all, p$casa_id[i]), p$tarea[i], fecha_mx(f), fecha_mx(antes),
                       if (nzchar(nota)) paste0(" · ", nota) else ""))
    removeModal(); st$prev_id(NULL)
    showNotification(sprintf("✔ Listo. Próxima vez: %s", fecha_mx(add_months(f, p$frecuencia[i]))), type = "message", duration = 6)
    st$bump()
  })

  # ---------------- Reportes
  output$rep_casa_ui <- renderUI({ x <- ctx(); req(x$rol)
    selectInput("rep_casa", "Casa", choices = c("Todas" = "", setNames(x$casas$id, x$casas$nombre)), selected = isolate(input$rep_casa), width = "220px") })
  rep <- reactive({
    st$db(); x <- ctx(); req(x$rol)
    r <- periodo_rango(input$rep_per, input$rep_rango)
    cas <- x$casas; if (nzchar(input$rep_casa %||% "")) cas <- cas[cas$id == input$rep_casa, , drop = FALSE]
    get <- function(t, f) { d <- visibles(read_tbl(t), x, f); d <- d[d$casa_id %in% cas$id, , drop = FALSE]; if (is.null(f)) d else filtrar_rango(d, f, r) }
    list(casas = cas, rango = r, recibos = get("recibos", "fecha"), pagos = get("pagos", "fecha"), ordenes = get("ordenes", "fecha"),
         inspecciones = get("inspecciones", "fecha"), preventivo = get("preventivo", NULL), contratos = get("contratos", NULL))
  })
  output$rep_kpis <- renderUI({
    d <- rep(); g <- sum(d$recibos$monto, na.rm = TRUE); p <- sum(d$pagos$monto, na.rm = TRUE)
    div(class = "kpi-grid",
      kpi("Materiales", money0(d$recibos$monto[d$recibos$tipo == "Material"]), sprintf("%d recibos", sum(d$recibos$tipo == "Material")), "screwdriver-wrench", "purple"),
      kpi("Servicios", money0(d$recibos$monto[d$recibos$tipo == "Servicio"]), sprintf("%d pagos", sum(d$recibos$tipo == "Servicio")), "bolt", "blue"),
      kpi("Rentas cobradas", money0(p), sprintf("%d pagos", nrow(d$pagos)), "money-bill-wave", "green"),
      kpi("Balance", money0(p - g), "Rentas menos gastos", "scale-balanced", if (p - g < 0) "red" else "teal"),
      kpi("Órdenes", nrow(d$ordenes), sprintf("%d abiertas", sum(d$ordenes$estado %in% ORDEN_ABIERTA)), "clipboard-list", "orange"))
  })
  resumen_casas <- function(d) {
    if (!nrow(d$casas)) return(data.frame(Mensaje = "Sin casas"))
    do.call(rbind, lapply(seq_len(nrow(d$casas)), function(i) {
      id <- d$casas$id[i]; r <- d$recibos[d$recibos$casa_id == id, ]; p <- d$pagos[d$pagos$casa_id == id, ]
      mat <- sum(r$monto[r$tipo == "Material"], na.rm = TRUE); srv <- sum(r$monto[r$tipo == "Servicio"], na.rm = TRUE); ren <- sum(p$monto, na.rm = TRUE)
      data.frame(Casa = d$casas$nombre[i], Materiales = mat, Servicios = srv, `Total gastos` = mat + srv, `Rentas cobradas` = ren,
                 Balance = ren - mat - srv, `Órdenes` = sum(d$ordenes$casa_id == id), Inspecciones = sum(d$inspecciones$casa_id == id),
                 check.names = FALSE, stringsAsFactors = FALSE)
    }))
  }
  output$rep_tabla <- DT::renderDT({
    tb <- resumen_casas(rep())
    if (!"Materiales" %in% names(tb)) return(tabla_simple(tb))
    tot <- as.data.frame(as.list(colSums(tb[, -1])), check.names = FALSE)
    tot <- cbind(Casa = "<b>TOTAL</b>", tot); names(tot) <- names(tb)
    tb$Casa <- esc(tb$Casa)
    tb <- rbind(tb, tot)
    for (cc in c("Materiales", "Servicios", "Total gastos", "Rentas cobradas", "Balance")) tb[[cc]] <- money(tb[[cc]])
    tb$Balance <- ifelse(grepl("^\\$-", tb$Balance), sprintf('<span class="txt-red">%s</span>', tb$Balance), tb$Balance)
    tabla_simple(tb, pageLength = 50, dom = "t")
  })
  output$rep_categorias <- DT::renderDT({
    r <- rep()$recibos
    if (!nrow(r)) return(tabla_simple(data.frame(Mensaje = "Sin gastos en este periodo"), dom = "t"))
    ag <- aggregate(monto ~ tipo + categoria, data = r, FUN = sum); ag <- ag[order(-ag$monto), ]
    n <- aggregate(monto ~ tipo + categoria, data = r, FUN = length)
    tabla_simple(data.frame(Tipo = ifelse(ag$tipo == "Material", "Materiales", "Servicios"), Categoría = esc(ag$categoria),
                            Registros = n$monto[match(paste(ag$tipo, ag$categoria), paste(n$tipo, n$categoria))],
                            Total = money(ag$monto), `% del gasto` = paste0(round(100 * ag$monto / sum(ag$monto)), " %"), check.names = FALSE),
                 pageLength = 20, dom = "t")
  })
  output$rep_excel <- downloadHandler(
    filename = function() paste0("Casas_en_renta_", format(Sys.Date(), "%Y%m%d"), ".xlsx"),
    content = function(file) {
      d <- rep(); x <- isolate(ctx()); cn <- function(id) nombre_casa(x$casas_all, id)
      fx <- function(v) as_fecha(v)
      lnk <- function(t) link_comprobante(t$archivo_tipo, t$archivo, t$archivo_link)
      gastos <- function(tp) { r <- d$recibos[d$recibos$tipo == tp, ]; o <- read_tbl("ordenes")
        data.frame(Casa = cn(r$casa_id), Fecha = fx(r$fecha), Categoría = r$categoria, Concepto = r$concepto, Proveedor = r$proveedor,
                   Monto = r$monto, `Orden de trabajo` = o$titulo[match(r$orden_id, o$id)], Notas = r$notas, `Registró` = r$admin_email,
                   Comprobante = lnk(r), check.names = FALSE) }
      p <- d$pagos; o <- d$ordenes; i <- d$inspecciones; pv <- d$preventivo; k <- d$contratos
      ep <- if (nrow(pv)) estado_prev(pv) else list(proxima = as.Date(character(0)), estado = character(0))
      hojas <- list(
        Resumen = resumen_casas(d),
        Materiales = gastos("Material"), Servicios = gastos("Servicio"),
        Rentas = data.frame(Casa = cn(p$casa_id), Mes = mes_txt(p$mes), `Fecha de pago` = fx(p$fecha), Monto = p$monto, Forma = p$metodo,
                            Notas = p$notas, Comprobante = lnk(p), check.names = FALSE),
        `Órdenes de trabajo` = data.frame(Casa = cn(o$casa_id), Fecha = fx(o$fecha), Trabajo = o$titulo, Detalles = o$descripcion,
                                          Prioridad = o$prioridad, Estado = o$estado, Proveedor = o$proveedor, `Costo estimado` = o$costo_estimado,
                                          `Terminada el` = fx(o$fecha_cierre), Notas = o$notas, check.names = FALSE),
        Preventivo = data.frame(Casa = cn(pv$casa_id), Tarea = pv$tarea, `Cada (meses)` = pv$frecuencia, `Última vez` = fx(pv$ultima),
                                `Próxima` = ep$proxima, Estado = ep$estado, Responsable = pv$responsable, check.names = FALSE),
        Inspecciones = data.frame(Casa = cn(i$casa_id), Fecha = fx(i$fecha), Tipo = i$tipo_insp, `Estado general` = i$estado_general,
                                  `Con inquilinos` = i$con_inquilinos, Plan = i$plan, `Para el dueño` = i$comentario_dueno,
                                  `Registró` = i$admin_email, check.names = FALSE),
        Contratos = data.frame(Casa = cn(k$casa_id), Inquilino = k$inquilino, Teléfono = k$telefono, Renta = k$renta, `Día de pago` = k$dia_pago,
                               Inicio = fx(k$inicio), Fin = fx(k$fin), Depósito = k$deposito, Estado = k$estado, check.names = FALSE))
      if (identical(x$rol, "dueno")) {
        cam <- filtrar_rango(transform(read_tbl("cambios"), dia = substr(fecha, 1, 10)), "dia", d$rango)
        hojas$Historial <- data.frame(Fecha = cam$fecha, Usuario = cam$usuario, Acción = cam$accion, Sección = cam$entidad, Detalle = cam$detalle)
      }
      writexl::write_xlsx(hojas, file)
    })

  # ---------------- Historial (dueño)
  output$his_usuario_ui <- renderUI({ st$db(); req(identical(ctx()$rol, "dueno"))
    u <- sort(unique(read_tbl("cambios")$usuario))
    selectInput("his_usuario", "Usuario", choices = c("Todos" = "", u), selected = isolate(input$his_usuario), width = "220px") })
  output$his_tabla <- DT::renderDT({
    st$db(); req(identical(ctx()$rol, "dueno"))
    cam <- read_tbl("cambios"); cam$dia <- substr(cam$fecha, 1, 10)
    cam <- filtrar_rango(cam, "dia", periodo_rango(input$his_per))
    if (nzchar(input$his_usuario %||% "")) cam <- cam[cam$usuario == input$his_usuario, ]
    if (nzchar(input$his_accion %||% "")) cam <- cam[cam$accion == input$his_accion, ]
    cam <- cam[order(cam$fecha, decreasing = TRUE), ]
    tabla_simple(data.frame(Fecha = sprintf('<span data-o="%s">%s</span>', cam$fecha, format(as.POSIXct(cam$fecha), "%d/%m/%Y %H:%M")),
                            Usuario = esc(cam$usuario), Acción = badge(cam$accion, COLORES$accion), Sección = esc(cam$entidad),
                            Detalle = largo(sub(" · datos: .*$", " · (datos completos guardados)", cam$detalle), 160), check.names = FALSE),
                 pageLength = 25)
  })

  # ---------------- Configuración (dueño)
  observe({ if (identical(ctx()$rol, "dueno")) { cfg <- read_cfg()
    updateTextInput(session, "cfg_folder", value = cfg$drive_folder_id); updateTextInput(session, "cfg_sa", value = cfg$drive_sa_file) } })
  observeEvent(input$cfg_guardar, { req(identical(ctx()$rol, "dueno"))
    write_cfg(modifyList(read_cfg(), list(drive_folder_id = trimws(input$cfg_folder %||% ""), drive_sa_file = trimws(input$cfg_sa %||% ""))))
    log_change("Dueño", "Editar", "Configuración", "config", "Google Drive para comprobantes")
    showNotification("Configuración guardada.", type = "message"); st$bump() })
  output$cfg_estado <- renderUI({ st$db(); est <- drive_status()
    if (est == "Listo") div(class = "status ok", icon("circle-check"), "Google Drive listo: los comprobantes se suben a la carpeta.")
    else div(class = "status warn", icon("triangle-exclamation"), est, " Mientras tanto, los comprobantes se guardan dentro de la app.") })
  output$cfg_respaldo <- downloadHandler(
    filename = function() paste0("respaldo_casas_en_renta_", format(Sys.time(), "%Y%m%d_%H%M"), ".json"),
    content = function(file) { req(identical(isolate(ctx())$rol, "dueno")); writeLines(respaldo_json(), file) })
  observeEvent(input$cfg_restaurar, {
    req(identical(ctx()$rol, "dueno"))
    f <- input$cfg_restaurar_f
    if (is.null(f)) return(showNotification("Elija primero el archivo de respaldo.", type = "warning"))
    n <- tryCatch(restaurar_respaldo(f$datapath), error = function(e) conditionMessage(e))
    if (is.character(n)) return(showNotification(paste("No se pudo restaurar:", n), type = "error", duration = 10))
    log_change("Dueño", "Editar", "Respaldo", "respaldo", sprintf("Se restauró un respaldo (%d tablas). La información anterior quedó en data/respaldos.", n))
    showNotification(sprintf("✔ Respaldo restaurado (%d tablas).", n), type = "message", duration = 8); st$bump()
  })
  output$cfg_info <- renderUI({ st$db()
    n <- vapply(c("casas", "recibos", "pagos", "ordenes", "inspecciones", "cambios"), function(t) nrow(read_tbl(t)), 0)
    tags$table(class = "detail",
      tags$tr(tags$th("Versión"), tags$td(APP_VERSION)),
      tags$tr(tags$th("Datos guardados"), tags$td(sprintf("%d casas · %d gastos · %d pagos de renta · %d órdenes · %d inspecciones · %d cambios en el historial", n[1], n[2], n[3], n[4], n[5], n[6]))),
      tags$tr(tags$th("Carpeta de datos"), tags$td(tags$code(DATA_DIR))),
      tags$tr(tags$th("Clave del dueño"), tags$td("Se cambia con la variable OWNER_PIN del servidor o en codigo/datos.R."))) })
}
