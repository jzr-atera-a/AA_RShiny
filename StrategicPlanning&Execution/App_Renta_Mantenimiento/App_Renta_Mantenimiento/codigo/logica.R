# ============================================================================
# LÓGICA: fechas, permisos por periodo, alertas, indicadores y gráficas
# ============================================================================

MESES     <- c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto",
               "Septiembre", "Octubre", "Noviembre", "Diciembre")
MESES_COR <- c("ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic")
DIAS      <- c("domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado")

as_fecha <- function(x) suppressWarnings(as.Date(as.character(x), format = "%Y-%m-%d"))
hoy      <- function() Sys.Date()

fecha_mx <- function(x) {
  f <- as_fecha(x)
  ifelse(is.na(f), "", format(f, "%d/%m/%Y"))
}
fecha_larga <- function(f = hoy()) {
  sprintf("%s %d de %s de %s", DIAS[as.POSIXlt(f)$wday + 1], as.POSIXlt(f)$mday,
          tolower(MESES[as.POSIXlt(f)$mon + 1]), format(f, "%Y"))
}
mes_txt <- function(m) {
  m <- as.character(m)
  ok <- !is.na(m) & grepl("^\\d{4}-\\d{2}$", m)
  out <- rep("", length(m))
  out[ok] <- paste(MESES[as.integer(substr(m[ok], 6, 7))], substr(m[ok], 1, 4))
  out
}
mes_de   <- function(f) format(as_fecha(f), "%Y-%m")
mes_ini  <- function(m) as.Date(paste0(m, "-01"))
mes_fin  <- function(m) seq(mes_ini(m), by = "month", length.out = 2)[2] - 1
meses_atras <- function(n, desde = hoy()) {
  base <- as.Date(format(desde, "%Y-%m-01"))
  rev(format(seq(base, by = "-1 month", length.out = n), "%Y-%m"))
}
meses_opciones <- function() {
  m <- c(meses_atras(13), format(seq(as.Date(format(hoy(), "%Y-%m-01")), by = "month", length.out = 2)[2], "%Y-%m"))
  rev(setNames(m, mes_txt(m)))
}

add_months <- function(d, n) {
  d <- as_fecha(d)
  out <- rep(as.Date(NA), length(d))
  for (i in seq_along(d)) {
    if (is.na(d[i]) || is.na(n[i])) next
    lt <- as.POSIXlt(d[i]); tot <- lt$year * 12 + lt$mon + as.integer(n[i])
    y <- tot %/% 12 + 1900; m <- tot %% 12 + 1
    ultimo <- as.POSIXlt(mes_fin(sprintf("%d-%02d", y, m)))$mday
    out[i] <- as.Date(sprintf("%d-%02d-%02d", y, m, min(lt$mday, ultimo)))
  }
  out
}

money <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  ifelse(is.na(x), "", paste0("$", formatC(x, format = "f", digits = 2, big.mark = ",")))
}
money0 <- function(x) paste0("$", formatC(round(sum(x, na.rm = TRUE)), format = "d", big.mark = ","))

PERIODOS <- c("Todo" = "todo", "Este mes" = "mes", "Mes pasado" = "mes_ant", "Últimos 3 meses" = "3m",
              "Este año" = "anio", "Año pasado" = "anio_ant", "Últimos 12 meses" = "12m")

periodo_rango <- function(sel, rango = NULL) {
  h <- hoy(); m0 <- as.Date(format(h, "%Y-%m-01")); y <- format(h, "%Y")
  r <- switch(sel %||% "todo",
    mes      = c(m0, mes_fin(format(h, "%Y-%m"))),
    mes_ant  = { a <- seq(m0, by = "-1 month", length.out = 2)[2]; c(a, m0 - 1) },
    `3m`     = c(seq(m0, by = "-2 month", length.out = 2)[2], h),
    anio     = c(as.Date(paste0(y, "-01-01")), as.Date(paste0(y, "-12-31"))),
    anio_ant = c(as.Date(paste0(as.integer(y) - 1, "-01-01")), as.Date(paste0(as.integer(y) - 1, "-12-31"))),
    `12m`    = c(seq(m0, by = "-11 month", length.out = 2)[2], h),
    otro     = if (length(rango) == 2 && !any(is.na(rango))) as.Date(rango) else NULL,
    NULL)
  if (is.null(r)) NULL else as.character(r)
}
filtrar_rango <- function(d, campo, r) {
  if (is.null(r) || !nrow(d)) return(d)
  k <- !is.na(d[[campo]]) & d[[campo]] >= r[1] & d[[campo]] <= r[2]
  d[k, , drop = FALSE]
}

# ---------------------------------------------------------------- Permisos
admin_casas <- function(em) {
  casas <- read_tbl("casas"); asig <- read_tbl("asignaciones")
  ids <- asig$casa_id[tolower(trimws(asig$email)) == tolower(em)]
  casas[casas$id %in% ids & casas$activa == "si", , drop = FALSE]
}

# TRUE si el registro cae dentro del periodo de su casa
en_periodo <- function(d, casas, campo = "fecha") {
  if (!nrow(d)) return(logical(0))
  c_ <- casas[match(d$casa_id, casas$id), , drop = FALSE]
  f <- d[[campo]]
  k <- !is.na(c_$inicio) & !is.na(f) & f >= c_$inicio & f <= c_$fin
  k[is.na(k)] <- FALSE
  k
}

# Lo que cada persona puede ver: el dueño todo; el administrador solo sus casas y su periodo
visibles <- function(d, ctx, fecha = NULL) {
  if (identical(ctx$rol, "dueno") || !"casa_id" %in% names(d)) return(d)
  d <- d[d$casa_id %in% ctx$casas$id, , drop = FALSE]
  if (!is.null(fecha)) d <- d[en_periodo(d, ctx$casas, fecha), , drop = FALSE]
  d
}

nombre_casa <- function(casas, id) {
  n <- casas$nombre[match(id, casas$id)]
  ifelse(is.na(n), "(casa eliminada)", n)
}

# ---------------------------------------------------------------- Contratos y rentas
ORDEN_ABIERTA <- c("Abierta", "En proceso", "En espera")

contrato_de <- function(contratos, casa, fecha) {
  k <- which(contratos$casa_id == casa & (is.na(contratos$estado) | contratos$estado != "Terminado") &
             !is.na(contratos$inicio) & contratos$inicio <= fecha & contratos$fin >= fecha)
  if (length(k)) contratos[k[length(k)], , drop = FALSE] else NULL
}

# Estado de la renta de cada casa en los últimos n meses
estado_rentas <- function(ctx, n = 6) {
  casas <- ctx$casas; con <- read_tbl("contratos"); pag <- visibles(read_tbl("pagos"), ctx, "fecha")
  meses <- meses_atras(n)
  if (!nrow(casas)) return(NULL)
  filas <- list()
  for (i in seq_len(nrow(casas))) for (m in meses) {
    c1 <- contrato_de(con, casas$id[i], as.character(mes_fin(m)))
    if (is.null(c1)) c1 <- contrato_de(con, casas$id[i], as.character(mes_ini(m)))
    pagado <- sum(pag$monto[pag$casa_id == casas$id[i] & pag$mes == m], na.rm = TRUE)
    if (is.null(c1)) { est <- if (pagado > 0) "pagada" else "sin"; renta <- NA; inq <- "" }
    else {
      renta <- c1$renta; inq <- c1$inquilino
      limite <- mes_ini(m) + max(0, min(28, (c1$dia_pago %||% 5) - 1))
      est <- if (pagado >= renta * 0.995) "pagada" else if (pagado > 0) "parcial"
             else if (hoy() <= limite) "pendiente" else "atrasada"
    }
    filas[[length(filas) + 1]] <- data.frame(casa_id = casas$id[i], casa = casas$nombre[i], mes = m,
                                             renta = renta, pagado = pagado, estado = est, inquilino = inq,
                                             stringsAsFactors = FALSE)
  }
  do.call(rbind, filas)
}

# ---------------------------------------------------------------- Mantenimiento preventivo
estado_prev <- function(p) {
  prox <- add_months(p$ultima, p$frecuencia)
  dias <- as.integer(prox - hoy())
  list(proxima = prox, dias = dias,
       estado = ifelse(is.na(dias), "Sin fecha", ifelse(dias < 0, "Vencida", ifelse(dias <= 30, "Próxima", "Al día"))))
}

# ---------------------------------------------------------------- Alertas
alertas <- function(ctx) {
  a <- list()
  add <- function(nivel, icono, casa, texto, peso) a[[length(a) + 1]] <<- data.frame(nivel = nivel, icono = icono, casa = casa, texto = texto, peso = peso, stringsAsFactors = FALSE)
  casas <- ctx$casas; h <- hoy()
  if (!nrow(casas)) return(NULL)

  con <- read_tbl("contratos"); con <- con[con$casa_id %in% casas$id & (is.na(con$estado) | con$estado != "Terminado"), , drop = FALSE]
  for (i in seq_len(nrow(con))) {
    d <- as.integer(as_fecha(con$fin[i]) - h); cn <- nombre_casa(casas, con$casa_id[i])
    if (is.na(d)) next
    if (d < 0) add("danger", "file-circle-exclamation", cn, sprintf("Contrato de %s vencido el %s.", con$inquilino[i], fecha_mx(con$fin[i])), 1)
    else if (d <= 60) add("warning", "file-signature", cn, sprintf("Contrato de %s vence en %d días (%s).", con$inquilino[i], d, fecha_mx(con$fin[i])), 3)
  }
  er <- estado_rentas(ctx, 2)
  if (!is.null(er)) for (i in which(er$estado %in% c("atrasada", "parcial"))) {
    add(if (er$estado[i] == "atrasada") "danger" else "warning", "money-bill-wave", er$casa[i],
        sprintf("Renta de %s %s: pagado %s de %s.", tolower(mes_txt(er$mes[i])),
                if (er$estado[i] == "atrasada") "atrasada" else "incompleta", money(er$pagado[i]), money(er$renta[i])), 1)
  }
  pv <- read_tbl("preventivo"); pv <- pv[pv$casa_id %in% casas$id, , drop = FALSE]
  if (nrow(pv)) {
    ep <- estado_prev(pv)
    for (i in seq_len(nrow(pv))) {
      if (ep$estado[i] == "Vencida") add("danger", "calendar-xmark", nombre_casa(casas, pv$casa_id[i]), sprintf("Mantenimiento vencido: %s (desde %s).", pv$tarea[i], fecha_mx(ep$proxima[i])), 2)
      else if (!is.na(ep$dias[i]) && ep$dias[i] <= 15) add("warning", "calendar-day", nombre_casa(casas, pv$casa_id[i]), sprintf("Próximo mantenimiento: %s el %s.", pv$tarea[i], fecha_mx(ep$proxima[i])), 4)
    }
  }
  or <- visibles(read_tbl("ordenes"), ctx, "fecha"); or <- or[or$casa_id %in% casas$id & or$estado %in% ORDEN_ABIERTA, , drop = FALSE]
  for (i in seq_len(nrow(or))) {
    dias <- as.integer(h - as_fecha(or$fecha[i]))
    if (identical(or$prioridad[i], "Urgente")) add("danger", "triangle-exclamation", nombre_casa(casas, or$casa_id[i]), sprintf("Orden urgente abierta: %s.", or$titulo[i]), 1)
    else if (!is.na(dias) && dias > 14) add("warning", "clipboard-list", nombre_casa(casas, or$casa_id[i]), sprintf("Orden abierta hace %d días: %s.", dias, or$titulo[i]), 3)
  }
  for (i in seq_len(nrow(casas))) {
    d <- as.integer(as_fecha(casas$fin[i]) - h)
    if (is.na(d)) next
    if (identical(ctx$rol, "admin") && d >= 0 && d <= 30)
      add("info", "hourglass-half", casas$nombre[i], sprintf("Su periodo para registrar en esta casa termina el %s.", fecha_mx(casas$fin[i])), 5)
    if (identical(ctx$rol, "dueno") && d < 0 && casas$activa[i] == "si")
      add("info", "hourglass-end", casas$nombre[i], sprintf("El periodo de administración terminó el %s. Amplíelo si sigue activo.", fecha_mx(casas$fin[i])), 5)
  }
  if (identical(ctx$rol, "dueno")) {
    asig <- read_tbl("asignaciones")
    for (i in which(casas$activa == "si" & casas$id %notin% asig$casa_id))
      add("warning", "user-slash", casas$nombre[i], "No tiene administrador asignado.", 3)
  }
  if (!length(a)) return(NULL)
  a <- do.call(rbind, a)
  a[order(a$peso), , drop = FALSE]
}

# ---------------------------------------------------------------- Indicadores
kpis <- function(ctx) {
  rec <- visibles(read_tbl("recibos"), ctx, "fecha"); rec <- rec[rec$casa_id %in% ctx$casas$id, , drop = FALSE]
  m <- format(hoy(), "%Y-%m"); m_ant <- meses_atras(2)[1]; y <- format(hoy(), "%Y")
  g_mes <- sum(rec$monto[substr(rec$fecha, 1, 7) == m], na.rm = TRUE)
  g_ant <- sum(rec$monto[substr(rec$fecha, 1, 7) == m_ant], na.rm = TRUE)
  g_anio <- sum(rec$monto[substr(rec$fecha, 1, 4) == y], na.rm = TRUE)
  er <- estado_rentas(ctx, 1)
  esperado <- if (is.null(er)) 0 else sum(er$renta, na.rm = TRUE)
  cobrado <- if (is.null(er)) 0 else sum(er$pagado, na.rm = TRUE)
  or <- visibles(read_tbl("ordenes"), ctx, "fecha"); or <- or[or$casa_id %in% ctx$casas$id & or$estado %in% ORDEN_ABIERTA, , drop = FALSE]
  pv <- read_tbl("preventivo"); pv <- pv[pv$casa_id %in% ctx$casas$id, , drop = FALSE]
  venc <- if (nrow(pv)) sum(estado_prev(pv)$estado == "Vencida") else 0
  list(casas = nrow(ctx$casas), g_mes = g_mes, g_ant = g_ant, g_anio = g_anio,
       esperado = esperado, cobrado = cobrado,
       ordenes = nrow(or), urgentes = sum(or$prioridad == "Urgente", na.rm = TRUE), vencidos = venc)
}

# ---------------------------------------------------------------- Gráficas (ggplot2)
COL_MAT <- "#667eea"; COL_SRV <- "#c084fc"; COL_REN <- "#10b981"; COL_ESP <- "#d1d5f0"

theme_app <- function() {
  ggplot2::theme_minimal(base_size = 13, base_family = "") +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank(), panel.grid.minor = ggplot2::element_blank(),
                   panel.grid.major.y = ggplot2::element_line(colour = "#eceef6"),
                   legend.position = "top", legend.justification = "left", legend.title = ggplot2::element_blank(),
                   axis.title = ggplot2::element_blank(), axis.text = ggplot2::element_text(colour = "#6b7280"),
                   plot.background = ggplot2::element_rect(fill = "white", colour = NA),
                   plot.margin = ggplot2::margin(4, 8, 4, 4))
}
eje_dinero <- function(x) paste0("$", formatC(x, format = "d", big.mark = ","))
etiqueta_mes <- function(m) paste0(MESES_COR[as.integer(substr(m, 6, 7))], "\n", substr(m, 3, 4))

plot_vacio <- function(txt) {
  ggplot2::ggplot() + ggplot2::annotate("text", x = 0, y = 0, label = txt, colour = "#9ca3af", size = 5) +
    ggplot2::theme_void() + ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))
}

plot_gastos_mes <- function(rec) {
  meses <- meses_atras(12)
  rec <- rec[substr(rec$fecha, 1, 7) %in% meses, , drop = FALSE]
  if (!nrow(rec)) return(plot_vacio("Aún no hay gastos en los últimos 12 meses"))
  rec$mes <- substr(rec$fecha, 1, 7)
  ag <- aggregate(monto ~ mes + tipo, data = rec, FUN = sum)
  ag$tipo <- factor(ifelse(ag$tipo == "Material", "Materiales", "Servicios"), levels = c("Materiales", "Servicios"))
  ggplot2::ggplot(ag, ggplot2::aes(x = factor(mes, levels = meses), y = monto, fill = tipo)) +
    ggplot2::geom_col(width = 0.62) +
    ggplot2::scale_fill_manual(values = c(Materiales = COL_MAT, Servicios = COL_SRV), drop = FALSE) +
    ggplot2::scale_x_discrete(labels = etiqueta_mes, drop = FALSE) +
    ggplot2::scale_y_continuous(labels = eje_dinero, expand = ggplot2::expansion(mult = c(0, 0.08))) +
    theme_app()
}

plot_categorias <- function(rec) {
  rec <- rec[substr(rec$fecha, 1, 4) == format(hoy(), "%Y"), , drop = FALSE]
  if (!nrow(rec)) return(plot_vacio("Aún no hay gastos este año"))
  ag <- aggregate(monto ~ categoria, data = rec, FUN = sum)
  ag <- head(ag[order(-ag$monto), ], 8)
  ggplot2::ggplot(ag, ggplot2::aes(x = reorder(categoria, monto), y = monto)) +
    ggplot2::geom_col(fill = COL_MAT, width = 0.6) +
    ggplot2::geom_text(ggplot2::aes(label = eje_dinero(round(monto))), hjust = -0.1, size = 3.6, colour = "#374151") +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(labels = eje_dinero, n.breaks = 3, expand = ggplot2::expansion(mult = c(0, 0.32))) +
    ggplot2::scale_x_discrete(labels = function(x) ifelse(nchar(x) > 26, paste0(substr(x, 1, 24), "…"), x)) +
    theme_app() + ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                                 panel.grid.major.x = ggplot2::element_line(colour = "#eceef6"))
}

plot_rentas <- function(er) {
  if (is.null(er) || all(is.na(er$renta)) && sum(er$pagado) == 0) return(plot_vacio("Registre contratos para ver las rentas"))
  ag <- aggregate(cbind(Esperada = ifelse(is.na(renta), 0, renta), Cobrada = pagado) ~ mes, data = er, FUN = sum)
  df <- rbind(data.frame(mes = ag$mes, tipo = "Esperada", monto = ag$Esperada),
              data.frame(mes = ag$mes, tipo = "Cobrada", monto = ag$Cobrada))
  df$tipo <- factor(df$tipo, levels = c("Esperada", "Cobrada"))
  lv <- sort(unique(df$mes))
  ggplot2::ggplot(df, ggplot2::aes(x = factor(mes, levels = lv), y = monto, fill = tipo)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.7), width = 0.62) +
    ggplot2::scale_fill_manual(values = c(Esperada = COL_ESP, Cobrada = COL_REN)) +
    ggplot2::scale_x_discrete(labels = etiqueta_mes) +
    ggplot2::scale_y_continuous(labels = eje_dinero, expand = ggplot2::expansion(mult = c(0, 0.08))) +
    theme_app()
}
