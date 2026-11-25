# ============================================================================
# DATOS: dónde y cómo se guarda todo (archivos JSON de texto en data/)
# ============================================================================

APP_VERSION <- "2.0.0"
DATA_FORMAT <- 2
OWNER_PIN   <- Sys.getenv("OWNER_PIN", "718718")      # clave del dueño (o variable de entorno OWNER_PIN)
APP_DIR     <- normalizePath(".", mustWork = FALSE)
DATA_DIR    <- Sys.getenv("RENTA_DATA_DIR", file.path(APP_DIR, "data"))
RECIBOS_DIR <- file.path(DATA_DIR, "recibos_locales")   # comprobantes si Drive no está listo
RESPALDO_DIR <- file.path(DATA_DIR, "respaldos")
SECRETS_DIR <- file.path(APP_DIR, "secrets")            # cuenta de servicio de Google (no compartir)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || is.na(x[1]) || !nzchar(as.character(x[1]))) y else x
}
`%notin%` <- function(x, y) !(x %in% y)

for (d in c(DATA_DIR, RECIBOS_DIR, RESPALDO_DIR)) dir.create(d, showWarnings = FALSE, recursive = TRUE)

AUD <- c("creado", "creado_por", "editado", "editado_por")
ARCH <- c("archivo", "archivo_tipo", "archivo_link")

# Columnas de cada tabla. REGLA: solo agregar columnas, nunca renombrar ni quitar.
COLS <- list(
  casas        = c("id", "nombre", "direccion", "tipo_prop", "inicio", "fin", "activa", "notas", AUD),
  admins       = c("id", "email", "nombre", "telefono", AUD),
  asignaciones = c("email", "casa_id"),
  contratos    = c("id", "casa_id", "inquilino", "telefono", "email", "renta", "dia_pago", "inicio", "fin",
                   "deposito", "estado", "notas", AUD),
  proveedores  = c("id", "nombre", "especialidad", "telefono", "email", "calificacion", "notas", AUD),
  ordenes      = c("id", "casa_id", "fecha", "titulo", "descripcion", "reportado_por", "prioridad", "estado",
                   "proveedor", "costo_estimado", "fecha_cierre", ARCH, "notas", AUD),
  preventivo   = c("id", "casa_id", "tarea", "frecuencia", "ultima", "responsable", "notas", AUD),
  pagos        = c("id", "casa_id", "mes", "fecha", "monto", "metodo", ARCH, "notas", AUD),
  recibos      = c("id", "casa_id", "tipo", "categoria", "servicio", "fecha", "monto", "concepto", "proveedor",
                   "orden_id", ARCH, "notas", "admin_email", AUD),
  inspecciones = c("id", "casa_id", "fecha", "tipo_insp", "estado_general", "con_inquilinos", "plan",
                   "comentario_dueno", ARCH, "admin_email", AUD),
  cambios      = c("fecha", "usuario", "accion", "entidad", "registro_id", "detalle")
)
NUM_COLS <- c("monto", "renta", "deposito", "costo_estimado", "frecuencia", "dia_pago", "calificacion")

empty_tbl <- function(cols) {
  as.data.frame(setNames(rep(list(character(0)), length(cols)), cols), stringsAsFactors = FALSE)
}

read_tbl <- function(name) {
  cols <- COLS[[name]]
  f <- file.path(DATA_DIR, paste0(name, ".json"))
  d <- if (file.exists(f)) tryCatch(jsonlite::fromJSON(f), error = function(e) NULL) else NULL
  if (is.list(d) && !is.data.frame(d) && is.data.frame(d$filas)) d <- d$filas   # formato con encabezado
  if (!is.data.frame(d) || nrow(d) == 0) {
    d <- empty_tbl(cols)
  } else {
    for (cc in setdiff(cols, names(d))) d[[cc]] <- NA_character_
    d <- d[, cols, drop = FALSE]
    d[] <- lapply(d, function(x) if (is.list(x)) vapply(x, function(v) paste(v, collapse = ", "), "") else as.character(x))
  }
  for (cc in intersect(NUM_COLS, cols)) d[[cc]] <- suppressWarnings(as.numeric(d[[cc]]))
  # Datos de la versión 1: completar lo que falta
  if (name == "admins" && nrow(d)) { na <- is.na(d$id) | d$id == ""; d$id[na] <- d$email[na] }
  if (name == "recibos" && nrow(d)) {
    na <- is.na(d$categoria) | d$categoria == ""
    d$categoria[na] <- ifelse(d$tipo[na] == "Servicio", d$servicio[na] %||% "Otro", "Otro")
    d$categoria[is.na(d$categoria)] <- "Otro"
  }
  if (name == "casas" && nrow(d)) d$activa[is.na(d$activa)] <- "si"
  d
}

write_tbl <- function(name, d) {
  for (cc in intersect(NUM_COLS, names(d))) d[[cc]] <- suppressWarnings(as.numeric(d[[cc]]))
  f <- file.path(DATA_DIR, paste0(name, ".json"))
  tmp <- paste0(f, ".tmp")
  writeLines(jsonlite::toJSON(d, dataframe = "rows", pretty = TRUE, na = "null", auto_unbox = TRUE),
             tmp, useBytes = TRUE)
  file.rename(tmp, f)   # escritura atómica: nunca queda un archivo a medias
}

new_id  <- function(p) paste0(p, format(Sys.time(), "%Y%m%d%H%M%S"), sprintf("%04d", sample(9999, 1)))
now_txt <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

# Historial: quién, cuándo, qué hizo y qué cambió
log_change <- function(usuario, accion, entidad, registro_id, detalle = "") {
  d <- read_tbl("cambios")
  d <- rbind(d, data.frame(fecha = now_txt(), usuario = usuario, accion = accion, entidad = entidad,
                           registro_id = registro_id, detalle = detalle, stringsAsFactors = FALSE))
  write_tbl("cambios", d)
}

# ---------------------------------------------------------------- Configuración
read_cfg <- function() {
  f <- file.path(DATA_DIR, "config.json")
  cfg <- if (file.exists(f)) tryCatch(jsonlite::fromJSON(f), error = function(e) list()) else list()
  modifyList(list(drive_folder_id = "", drive_sa_file = ""), cfg)
}
write_cfg <- function(cfg) {
  writeLines(jsonlite::toJSON(cfg, auto_unbox = TRUE, pretty = TRUE), file.path(DATA_DIR, "config.json"))
}

# ---------------------------------------------------------------- Google Drive
drive_status <- function(cfg = read_cfg()) {
  if (!nzchar(cfg$drive_folder_id %||% "")) return("Falta el ID de la carpeta de Google Drive.")
  sa <- cfg$drive_sa_file %||% ""
  if (!nzchar(sa) || !file.exists(file.path(SECRETS_DIR, sa)))
    return("Falta el archivo de la cuenta de servicio dentro de la carpeta secrets.")
  if (!requireNamespace("googledrive", quietly = TRUE)) return("Falta instalar el paquete googledrive.")
  "Listo"
}

.drive <- new.env(); .drive$auth <- FALSE

# Sube el comprobante a Drive; si no se puede, guarda una copia en la app
guardar_comprobante <- function(path, nombre, cfg = read_cfg()) {
  if (drive_status(cfg) == "Listo") {
    res <- tryCatch({
      if (!.drive$auth) {
        googledrive::drive_auth(path = file.path(SECRETS_DIR, cfg$drive_sa_file))
        .drive$auth <- TRUE
      }
      f <- googledrive::drive_upload(path, path = googledrive::as_id(cfg$drive_folder_id),
                                     name = nombre, overwrite = FALSE)
      list(archivo = f$id, archivo_tipo = "drive",
           archivo_link = paste0("https://drive.google.com/file/d/", f$id, "/view"))
    }, error = function(e) { message("Drive: ", conditionMessage(e)); NULL })
    if (!is.null(res)) return(res)
  }
  file.copy(path, file.path(RECIBOS_DIR, nombre), overwrite = FALSE)
  list(archivo = nombre, archivo_tipo = "local", archivo_link = "")
}

# Enlace para ver un comprobante (Drive o copia local)
link_comprobante <- function(tipo, archivo, link) {
  ifelse(!is.na(link) & nzchar(link %||% ""), link,
         ifelse(!is.na(tipo) & tipo == "local" & !is.na(archivo), paste0("comprobantes/", utils::URLencode(archivo)), ""))
}

# ---------------------------------------------------------------- Respaldo y restauración
respaldo_json <- function() {
  jsonlite::toJSON(list(formato = DATA_FORMAT, app_version = APP_VERSION, fecha = now_txt(),
                        config = read_cfg(),
                        tablas = setNames(lapply(names(COLS), read_tbl), names(COLS))),
                   dataframe = "rows", pretty = TRUE, na = "null", auto_unbox = TRUE)
}

restaurar_respaldo <- function(path) {
  x <- jsonlite::fromJSON(path)
  if (is.null(x$tablas)) stop("El archivo no es un respaldo de esta app.")
  writeLines(respaldo_json(), file.path(RESPALDO_DIR, paste0("antes_de_restaurar_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json")))
  n <- 0
  for (t in intersect(names(x$tablas), names(COLS))) {
    d <- x$tablas[[t]]
    if (!is.data.frame(d)) d <- empty_tbl(COLS[[t]])
    write_tbl(t, d); n <- n + 1
  }
  if (is.list(x$config)) write_cfg(modifyList(read_cfg(), x$config))
  n
}
