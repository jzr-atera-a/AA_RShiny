# =============================================================================
# utilidades.R — Componentes de interfaz reutilizables y tema de gráficas
# =============================================================================

COL <- list(marino = "#0B2545", azul = "#1D4E89", azul2 = "#2A6FB5", cian = "#0E9AA7", ambar = "#E8A317",
            verde = "#2E9D6A", rojo = "#C0392B", violeta = "#6C4F9E", gris = "#5D6D7E", naranja = "#E67E22",
            ideal = "#D7263D", suave = "#2E9D6A", registro = "#F28C28")

parrafo <- function(...) p(class = "description-text", ...)
concepto <- function(..., titulo = NULL, tipo = "") {
  div(class = paste("concept-box", tipo), if (!is.null(titulo)) h4(titulo), ...)
}
ecuacion <- function(tex, desc = NULL, titulo = NULL) {
  div(class = "math-formula", if (!is.null(titulo)) h4(titulo), HTML(tex),
      if (!is.null(desc)) p(class = "desc", HTML(desc)))
}
figura <- function(src, pie, ancho = "100%", alto = NULL) {
  tags$figure(class = "figura",
              tags$img(src = src, style = paste0("width:", ancho, ";", if (!is.null(alto)) paste0("max-height:", alto, ";object-fit:contain;") else ""),
                       alt = gsub("<[^>]+>", "", pie), loading = "lazy"),
              tags$figcaption(HTML(pie)))
}
caja <- function(titulo, ..., ancho = 12, estado = "primary", colapsable = FALSE, colapsada = FALSE) {
  box(width = ancho, title = titulo, status = estado, solidHeader = TRUE, collapsible = colapsable,
      collapsed = colapsada, ...)
}
aviso_sim <- function(texto = "Simulación ilustrativa construida con las ecuaciones de la tesis; no sustituye a las mediciones de la campaña cuantitativa (sección 7.7).") {
  div(class = "aviso-sim", icon("flask"), " ", texto)
}
celda <- function(valor, etiqueta, clase = "") div(class = paste("celda", clase), div(class = "v", HTML(valor)), div(class = "l", HTML(etiqueta)))
resultado <- function(...) div(class = "resultado", ...)
etiqueta <- function(txt, clase = "") span(class = paste("etiqueta", clase), txt)
kpi <- function(valor, etiqueta, icono, clase = "") {
  div(class = paste("kpi", clase), span(class = "i", icon(icono)), div(class = "v", valor), div(class = "l", etiqueta))
}

idioma_dt <- list(
  search = "Buscar:", lengthMenu = "Mostrar _MENU_ filas", info = "Filas _START_ a _END_ de _TOTAL_",
  infoEmpty = "Sin registros", infoFiltered = "(filtrado de _MAX_)", zeroRecords = "No se encontraron coincidencias",
  emptyTable = "Sin datos", paginate = list(previous = "Anterior", `next` = "Siguiente", first = "Primero", last = "Último"),
  buttons = list(copy = "Copiar", csv = "CSV", excel = "Excel", copyTitle = "Copiado",
                 copySuccess = list(`_` = "%d filas copiadas", `1` = "1 fila copiada"))
)

tabla_dt <- function(d, paginas = 10, botones = TRUE, buscar = TRUE, ...) {
  dom <- paste0(if (botones) "B" else "", if (buscar) "f" else "", "rt", if (nrow(d) > paginas) "ip" else "")
  DT::datatable(d, rownames = FALSE, escape = TRUE, class = "cell-border stripe hover compact",
                extensions = if (botones) "Buttons" else character(0),
                options = list(pageLength = paginas, dom = dom, scrollX = TRUE, language = idioma_dt,
                               buttons = list("copy", "csv", "excel"), autoWidth = FALSE, ...))
}
# Tabla estática compacta (sin buscador ni paginación)
tabla_simple <- function(d) tabla_dt(d, paginas = max(nrow(d), 1), botones = FALSE, buscar = FALSE, ordering = FALSE)

tema <- function(p, xt = NULL, yt = NULL, leyenda = TRUE, ...) {
  if (is.null(xt)) xt <- ""
  if (is.null(yt)) yt <- ""
  p %>% layout(
    xaxis = list(title = xt, gridcolor = "#E3E9F1", zerolinecolor = "#C9D3DF"),
    yaxis = list(title = yt, gridcolor = "#E3E9F1", zerolinecolor = "#C9D3DF"),
    font = list(family = "Source Sans 3, Segoe UI, sans-serif", color = "#1F2D3D", size = 13),
    paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "#F7F9FC", showlegend = leyenda,
    legend = list(orientation = "h", y = -0.34, x = 0, yanchor = "top"), margin = list(l = 60, r = 30, t = 30, b = 80),
    hoverlabel = list(font = list(family = "Source Sans 3, sans-serif")), ...) %>%
    config(displaylogo = FALSE, locale = "es",
           modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d", "toggleSpikelines"))
}

# Eje igual para gráficas del plano del piso (x este, −z norte)
plano_piso <- function(p, rx = NULL, ry = NULL) {
  p %>% layout(xaxis = list(title = "x en el piso (m), este positivo", range = rx, scaleanchor = "y",
                            gridcolor = "#E3E9F1", zeroline = FALSE),
               yaxis = list(title = "−z en el piso (m), norte positivo", range = ry,
                            gridcolor = "#E3E9F1", zeroline = FALSE))
}
