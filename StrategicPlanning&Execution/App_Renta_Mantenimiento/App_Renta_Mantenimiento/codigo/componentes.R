# ============================================================================
# COMPONENTES DE INTERFAZ: tarjetas, indicadores, etiquetas, tablas
# ============================================================================

esc <- function(x) htmltools::htmlEscape(ifelse(is.na(x), "", as.character(x)))

encabezado <- function(titulo, subtitulo = NULL, icono = "house", derecha = NULL) {
  div(class = "page-head",
      div(class = "page-title",
          div(class = "page-icon", icon(icono)),
          div(h1(titulo), if (!is.null(subtitulo)) p(subtitulo))),
      div(class = "page-actions", derecha))
}

tarjeta <- function(titulo, ..., icono = NULL, derecha = NULL, class = "") {
  div(class = paste("card", class),
      if (!is.null(titulo)) div(class = "card-head", h3(if (!is.null(icono)) icon(icono), titulo), derecha),
      div(class = "card-body", ...))
}

kpi <- function(titulo, valor, sub = NULL, icono = "chart-line", color = "purple") {
  div(class = paste("kpi", paste0("kpi-", color)),
      div(class = "kpi-icon", icon(icono)),
      div(class = "kpi-body",
          div(class = "kpi-title", titulo),
          div(class = "kpi-value", valor),
          if (!is.null(sub)) div(class = "kpi-sub", sub)))
}

# Colores de las etiquetas por valor
COLORES <- list(
  estado     = c("Abierta" = "red", "En proceso" = "blue", "En espera" = "orange", "Terminada" = "green", "Cancelada" = "gray"),
  prioridad  = c("Urgente" = "red", "Alta" = "orange", "Media" = "blue", "Baja" = "gray"),
  prev       = c("Vencida" = "red", "Próxima" = "orange", "Al día" = "green", "Sin fecha" = "gray"),
  contrato   = c("Vigente" = "green", "Terminado" = "gray"),
  general    = c("Excelente" = "green", "Bueno" = "blue", "Regular" = "orange", "Malo" = "red"),
  tipo       = c("Material" = "purple", "Servicio" = "blue"),
  activa     = c("si" = "green", "no" = "gray"),
  accion     = c("Crear" = "green", "Editar" = "blue", "Eliminar" = "red", "Realizado" = "purple", "Entrar" = "gray")
)

badge <- function(v, mapa = NULL, texto = v) {
  col <- if (is.null(mapa)) rep("gray", length(v)) else unname(mapa[as.character(v)])
  col[is.na(col)] <- "gray"
  ifelse(is.na(v) | v == "", "", sprintf('<span class="pill p-%s">%s</span>', col, esc(texto)))
}

estrellas <- function(n) {
  n <- suppressWarnings(as.integer(n))
  ifelse(is.na(n), "", sprintf('<span class="stars">%s<span class="off">%s</span></span>',
                               strrep("★", pmax(0, pmin(5, n))), strrep("★", 5 - pmax(0, pmin(5, n)))))
}

link_ver <- function(url, texto = "Ver") {
  ifelse(is.na(url) | url == "", '<span class="muted">—</span>',
         sprintf('<a class="file-link" href="%s" target="_blank" rel="noopener"><i class="fa fa-paperclip"></i> %s</a>', esc(url), texto))
}

largo <- function(x, n = 90) {
  x <- ifelse(is.na(x), "", as.character(x))
  corto <- ifelse(nchar(x) > n, paste0(substr(x, 1, n), "…"), x)
  sprintf('<span title="%s">%s</span>', esc(x), esc(corto))
}

DT_LANG <- list(search = "", searchPlaceholder = "Buscar…", info = "_START_–_END_ de _TOTAL_",
                infoEmpty = "Sin registros", infoFiltered = "(de _MAX_)", lengthMenu = "Mostrar _MENU_",
                paginate = list(previous = "‹", `next` = "›"),
                emptyTable = "Sin registros", zeroRecords = "No hay coincidencias")

# Tabla simple (sin columna id)
tabla_simple <- function(d, pageLength = 10, dom = "ftip") {
  DT::datatable(d, escape = FALSE, rownames = FALSE, selection = "none", class = "display compact hover",
                options = list(language = DT_LANG, pageLength = pageLength, dom = dom, ordering = TRUE))
}

vacio <- function(icono, texto, sub = NULL) {
  div(class = "empty", icon(icono), div(class = "empty-t", texto), if (!is.null(sub)) div(class = "empty-s", sub))
}
