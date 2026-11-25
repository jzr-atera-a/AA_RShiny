# ============================================================================
# Mantenimiento de casas en renta · app.R · v1.0.0
# Un dueño (clave) · administradores (correo aprobado) · recibos a Google Drive
# ============================================================================

suppressPackageStartupMessages({
  library(shiny)
  library(DT)
  library(jsonlite)
  library(writexl)
})

APP_VERSION <- "1.0.0"
OWNER_PIN   <- "718718"                      # clave del dueño (cámbiela aquí si quiere otra)
APP_DIR     <- normalizePath(".", mustWork = FALSE)
DATA_DIR    <- file.path(APP_DIR, "data")    # todos los datos de la app (textos JSON)
RECIBOS_DIR <- file.path(DATA_DIR, "recibos_locales")  # copia local si Drive no está listo
SECRETS_DIR <- file.path(APP_DIR, "secrets") # cuenta de servicio de Google (no compartir)
SERVICIOS   <- c("Agua", "Plomería", "Electricidad",
                 "Mantenimiento de aires acondicionados", "Gas", "Otro")
options(shiny.maxRequestSize = 25 * 1024^2)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || is.na(x[1]) || !nzchar(as.character(x[1]))) y else x
}
`%notin%` <- function(x, y) !(x %in% y)
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------- Tablas --
COLS <- list(
  casas        = c("id", "nombre", "direccion", "inicio", "fin", "activa"),
  asignaciones = c("email", "casa_id"),
  admins       = c("email", "nombre"),
  recibos      = c("id", "casa_id", "tipo", "servicio", "fecha", "monto", "concepto",
                   "archivo", "archivo_tipo", "archivo_link", "admin_email", "creado"),
  inspecciones = c("id", "casa_id", "fecha", "con_inquilinos", "plan", "comentario_dueno",
                   "admin_email", "creado"),
  cambios      = c("fecha", "usuario", "accion", "entidad", "registro_id", "detalle")
)

empty_tbl <- function(cols) {
  as.data.frame(setNames(rep(list(character(0)), length(cols)), cols), stringsAsFactors = FALSE)
}

read_tbl <- function(name) {
  cols <- COLS[[name]]
  f <- file.path(DATA_DIR, paste0(name, ".json"))
  d <- if (file.exists(f)) tryCatch(fromJSON(f), error = function(e) NULL) else NULL
  if (!is.data.frame(d) || nrow(d) == 0) return(empty_tbl(cols))
  for (cc in setdiff(cols, names(d))) d[[cc]] <- NA_character_
  d <- d[, cols, drop = FALSE]
  d[] <- lapply(d, as.character)
  if ("monto" %in% cols) d$monto <- suppressWarnings(as.numeric(d$monto))
  d
}

write_tbl <- function(name, d) {
  dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
  if ("monto" %in% names(d)) d$monto <- suppressWarnings(as.numeric(d$monto))
  writeLines(toJSON(d, dataframe = "rows", pretty = TRUE, na = "null", auto_unbox = TRUE),
             file.path(DATA_DIR, paste0(name, ".json")), useBytes = TRUE)
}

new_id <- function(p) paste0(p, format(Sys.time(), "%Y%m%d%H%M%S"), sprintf("%03d", sample(999, 1)))
now_txt <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

# Registro de cambios: quién, cuándo, qué hizo y qué cambió
log_change <- function(usuario, accion, entidad, registro_id, detalle = "") {
  d <- read_tbl("cambios")
  d <- rbind(d, data.frame(fecha = now_txt(), usuario = usuario, accion = accion,
                           entidad = entidad, registro_id = registro_id, detalle = detalle,
                           stringsAsFactors = FALSE))
  write_tbl("cambios", d)
}

# Compara campos antes/después y arma el texto del cambio
diff_txt <- function(old, new, labels) {
  parts <- character(0)
  for (k in names(labels)) {
    a <- as.character(old[[k]] %||% ""); b <- as.character(new[[k]] %||% "")
    if (!identical(a, b)) parts <- c(parts, sprintf("%s: '%s' → '%s'", labels[[k]], a, b))
  }
  paste(parts, collapse = "; ")
}

# ---------------------------------------------------------------- Config --
read_cfg <- function() {
  f <- file.path(DATA_DIR, "config.json")
  if (file.exists(f)) fromJSON(f) else list(drive_folder_id = "", drive_sa_file = "")
}
write_cfg <- function(cfg) {
  dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
  writeLines(toJSON(cfg, auto_unbox = TRUE, pretty = TRUE), file.path(DATA_DIR, "config.json"))
}

drive_status <- function(cfg) {
  if (!nzchar(cfg$drive_folder_id %||% "")) return("Falta el ID de la carpeta de Google Drive.")
  sa <- cfg$drive_sa_file %||% ""
  if (!nzchar(sa) || !file.exists(file.path(SECRETS_DIR, sa)))
    return("Falta el archivo de la cuenta de servicio dentro de la carpeta secrets.")
  if (!requireNamespace("googledrive", quietly = TRUE))
    return("Falta instalar el paquete googledrive.")
  "Listo"
}

.drive <- new.env(); .drive$auth <- FALSE

# Sube el comprobante a Google Drive; si no está listo, guarda una copia local
guardar_comprobante <- function(path, nombre, cfg) {
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
    }, error = function(e) NULL)
    if (!is.null(res)) return(res)
  }
  dir.create(RECIBOS_DIR, showWarnings = FALSE, recursive = TRUE)
  file.copy(path, file.path(RECIBOS_DIR, nombre), overwrite = FALSE)
  list(archivo = nombre, archivo_tipo = "local", archivo_link = "")
}

# ---------------------------------------------------------------- Lógica --
admin_casas <- function(em) {
  casas <- read_tbl("casas"); asig <- read_tbl("asignaciones")
  ids <- asig$casa_id[tolower(trimws(asig$email)) == em]
  casas[casas$id %in% ids & casas$activa == "si", , drop = FALSE]
}

# TRUE si cada registro cae dentro del periodo de su casa
en_periodo <- function(d, casas) {
  c_ <- casas[match(d$casa_id, casas$id), , drop = FALSE]
  k <- !is.na(c_$inicio) & !is.na(d$fecha) & d$fecha >= c_$inicio & d$fecha <= c_$fin
  k[is.na(k)] <- FALSE
  k
}

nombre_casa <- function(casas, id) casas$nombre[match(id, casas$id)]

totales_df <- function(casas, rec) {
  if (nrow(casas) == 0) return(data.frame(Mensaje = "Aún no hay casas", stringsAsFactors = FALSE))
  do.call(rbind, lapply(seq_len(nrow(casas)), function(i) {
    cs <- casas[i, ]
    r <- rec[rec$casa_id == cs$id, , drop = FALSE]
    r <- r[en_periodo(r, cs), , drop = FALSE]
    mat <- sum(r$monto[r$tipo == "Material"], na.rm = TRUE)
    srv <- sum(r$monto[r$tipo == "Servicio"], na.rm = TRUE)
    data.frame(Casa = cs$nombre, Periodo = paste(cs$inicio, "a", cs$fin),
               Materiales = mat, Servicios = srv, Total = mat + srv,
               Recibos = nrow(r), stringsAsFactors = FALSE)
  }))
}

money <- function(x) ifelse(is.na(x), "", paste0("$", formatC(x, format = "f", digits = 2, big.mark = ",")))

tabla_recibos <- function(d, casas) {
  if (nrow(d) == 0) return(data.frame(id = character(0), Mensaje = character(0)))
  link <- ifelse(is.na(d$archivo_link) | d$archivo_link == "", "",
                 paste0("<a href='", d$archivo_link, "' target='_blank'>Ver</a>"))
  data.frame(id = d$id, Casa = nombre_casa(casas, d$casa_id), Tipo = d$tipo,
             Servicio = ifelse(is.na(d$servicio), "", d$servicio), Fecha = d$fecha,
             Monto = money(d$monto), Concepto = d$concepto, Comprobante = link,
             stringsAsFactors = FALSE)
}

tabla_insp <- function(d, casas) {
  if (nrow(d) == 0) return(data.frame(id = character(0), Mensaje = character(0)))
  data.frame(id = d$id, Casa = nombre_casa(casas, d$casa_id), Fecha = d$fecha,
             `Lo que se habló con inquilinos` = d$con_inquilinos,
             `Qué se planea hacer` = d$plan,
             `Comentario para el dueño` = d$comentario_dueno,
             check.names = FALSE, stringsAsFactors = FALSE)
}

DT_LANG <- list(search = "Buscar:", info = "Mostrando _START_ a _END_ de _TOTAL_",
                paginate = list(previous = "Anterior", `next` = "Siguiente"),
                emptyTable = "Sin registros", zeroRecords = "Sin resultados")

tabla_dt <- function(d, selection = "single") {
  datatable(d, selection = selection, escape = FALSE, rownames = FALSE,
            options = list(language = DT_LANG, pageLength = 10, dom = "ftp",
                           columnDefs = list(list(visible = FALSE, targets = 0))))
}

# ---------------------------------------------------------------- UI --
CSS <- "
:root{--p1:#667eea;--p2:#764ba2}
body{background:linear-gradient(135deg,#f5f7fa 0%,#c3cfe2 100%);min-height:100vh;font-size:17px}
.app-header{background:linear-gradient(135deg,var(--p1),var(--p2));color:#fff;padding:14px 18px;
  border-radius:12px;margin:10px 0 14px;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px}
.app-header h2{margin:0;font-size:24px}
.box-card{background:#fff;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,.08);padding:16px;margin-bottom:16px}
.btn-primary,.btn-success,.btn-danger{border:none;font-size:16px;padding:8px 14px}
.btn-primary{background:linear-gradient(135deg,var(--p1),var(--p2))!important}
.btn-success{background:linear-gradient(135deg,#11998e,#38ef7d)!important;color:#fff!important}
.nav-tabs>li>a{font-size:16px}
.note{color:#555;font-size:15px}
"

header_app <- function(titulo, sesion = NULL) {
  div(class = "app-header",
      h2(titulo),
      if (!is.null(sesion)) div(sesion, " · ", actionLink("salir", "Salir", style = "color:#fff;text-decoration:underline")))
}

ui_login <- function() {
  tagList(
    header_app("🏠 Mantenimiento de mis casas"),
    fluidRow(
      column(6, div(class = "box-card", h3("Soy el dueño"),
                    passwordInput("pin", "Clave del dueño:"),
                    actionButton("btn_dueno", "Entrar", class = "btn-primary"))),
      column(6, div(class = "box-card", h3("Soy administrador"),
                    textInput("email", "Mi correo (el que aprobó el dueño):"),
                    actionButton("btn_admin", "Entrar", class = "btn-primary")))
    )
  )
}

ui_dueno <- function() {
  tagList(
    header_app("🏠 Mantenimiento · Dueño", "Sesión del dueño"),
    tabsetPanel(id = "tab_dueno",
      tabPanel("Casas y periodos", br(),
        div(class = "box-card",
            h4("Crear o editar una casa"),
            uiOutput("c_sel_ui"),
            textInput("c_nombre", "Nombre de la casa:"),
            textInput("c_dir", "Dirección:"),
            dateInput("c_ini", "Inicio del periodo:", language = "es", format = "dd/mm/yyyy"),
            dateInput("c_fin", "Fin del periodo:", language = "es", format = "dd/mm/yyyy"),
            checkboxInput("c_act", "Casa activa (los administradores la ven)", TRUE),
            actionButton("c_guardar", "Guardar casa", class = "btn-success")),
        DTOutput("tb_casas")),
      tabPanel("Administradores", br(),
        div(class = "box-card",
            h4("Aprobar un administrador"),
            textInput("a_email", "Correo del administrador:"),
            textInput("a_nombre", "Nombre:"),
            actionButton("a_guardar", "Aprobar administrador", class = "btn-success")),
        div(class = "box-card",
            h4("Casas que administra"),
            uiOutput("a_sel_ui"),
            checkboxGroupInput("a_casas", "Casas asignadas:", choices = NULL),
            actionButton("a_asig", "Guardar asignación", class = "btn-success"),
            actionButton("a_quitar", "Quitar este administrador", class = "btn-danger")),
        DTOutput("tb_admins")),
      tabPanel("Totales y Excel", br(),
        div(class = "box-card",
            p(class = "note", "Solo cuentan los recibos dentro del periodo de cada casa."),
            downloadButton("dl_excel", "Descargar Excel", class = "btn-success")),
        DTOutput("tb_totales")),
      tabPanel("Inspecciones", br(), DTOutput("tb_ins_dueno")),
      tabPanel("Cambios", br(), p(class = "note", "Quién creó, editó o borró cada registro."),
               DTOutput("tb_cambios")),
      tabPanel("Configuración", br(),
        div(class = "box-card",
            h4("Google Drive para los recibos"),
            textInput("cfg_folder", "ID de la carpeta de Drive:"),
            textInput("cfg_sa", "Nombre del archivo de la cuenta de servicio (dentro de secrets):"),
            actionButton("cfg_guardar", "Guardar configuración", class = "btn-success"),
            br(), br(), uiOutput("cfg_estado")))
    )
  )
}

ui_admin <- function(em) {
  p_form <- function(prefijo, tipo_extra) {
    tagList(
      uiOutput(paste0(prefijo, "casa_ui")),
      dateInput(paste0(prefijo, "fecha"), "Fecha del gasto:", language = "es", format = "dd/mm/yyyy"),
      tipo_extra,
      numericInput(paste0(prefijo, "monto"), "Monto ($):", value = NULL, min = 0),
      textInput(paste0(prefijo, "concepto"), "Concepto (qué se compró o se pagó):"),
      fileInput(paste0(prefijo, "archivo"), "Foto o PDF del recibo:",
                accept = c("image/*", ".pdf"), buttonLabel = "Elegir archivo",
                placeholder = "Ninguno"),
      actionButton(paste0(prefijo, "guardar"), "Guardar recibo", class = "btn-success"),
      br(), br(),
      actionButton(paste0(prefijo, "editar"), "Editar seleccionado", class = "btn-primary"),
      actionButton(paste0(prefijo, "eliminar"), "Eliminar seleccionado", class = "btn-danger")
    )
  }
  tagList(
    header_app("🏠 Mantenimiento · Administrador", em),
    tabsetPanel(id = "tab_admin",
      tabPanel("Mis casas", br(), DTOutput("tb_mis_casas")),
      tabPanel("Materiales", br(),
        div(class = "box-card", h4("Recibo de material comprado"), p_form("m_", NULL)),
        DTOutput("tb_mat")),
      tabPanel("Servicios", br(),
        div(class = "box-card", h4("Pago de servicio"),
            p_form("s_", selectInput("s_servicio", "Tipo de servicio:", choices = SERVICIOS))),
        DTOutput("tb_serv")),
      tabPanel("Inspecciones", br(),
        div(class = "box-card",
            h4("Inspección de la casa"),
            uiOutput("i_casa_ui"),
            dateInput("i_fecha", "Fecha de la inspección:", language = "es", format = "dd/mm/yyyy"),
            textAreaInput("i_inq", "Lo que se habló con los inquilinos:", rows = 3),
            textAreaInput("i_plan", "Lo que se planea hacer:", rows = 3),
            textAreaInput("i_dueno", "Comentarios para el dueño:", rows = 3),
            actionButton("i_guardar", "Guardar inspección", class = "btn-success"),
            br(), br(),
            actionButton("i_editar", "Editar seleccionada", class = "btn-primary"),
            actionButton("i_eliminar", "Eliminar seleccionada", class = "btn-danger")),
        DTOutput("tb_insp_admin"))
    )
  )
}

# ---------------------------------------------------------------- Server --
server <- function(input, output, session) {
  rol <- reactiveVal(NULL)     # "dueno" | "admin" | NULL
  em  <- reactiveVal("")       # correo del administrador
  db  <- reactiveVal(0)        # se sube cada vez que cambian datos
  bump <- function() db(db() + 1)
  edit_target <- reactiveVal(NULL)
  del_target  <- reactiveVal(NULL)

  output$main <- renderUI({
    switch(rol() %||% "", dueno = ui_dueno(), admin = ui_admin(em()), ui_login())
  })

  # ------------------------------------------------ Acceso
  observeEvent(input$btn_dueno, {
    if (identical(trimws(input$pin %||% ""), OWNER_PIN)) rol("dueno")
    else showNotification("La clave no es correcta.", type = "error")
  })
  observeEvent(input$btn_admin, {
    e <- tolower(trimws(input$email %||% ""))
    ok <- nzchar(e) && e %in% tolower(trimws(read_tbl("admins")$email))
    if (ok) { em(e); rol("admin") }
    else showNotification("Su correo no está aprobado por el dueño.", type = "error")
  })
  observeEvent(input$salir, { rol(NULL); em("") })

  # ------------------------------------------------ Selectores que dependen de los datos
  output$c_sel_ui <- renderUI({
    db(); casas <- read_tbl("casas")
    selectInput("c_sel", "Casa:", choices = c("Nueva casa" = "", setNames(casas$id, casas$nombre)))
  })
  output$a_sel_ui <- renderUI({
    db(); ad <- read_tbl("admins")
    selectInput("a_sel", "Administrador:", choices = c("Elija uno" = "", setNames(ad$email, ad$email)))
  })
  observe({
    db(); casas <- read_tbl("casas")
    updateCheckboxGroupInput(session, "a_casas",
      choices = setNames(casas$id, casas$nombre),
      selected = read_tbl("asignaciones")$casa_id[read_tbl("asignaciones")$email == (input$a_sel %||% "")])
  })
  output$m_casa_ui <- renderUI({ db(); selector_casa_admin("m_") })
  output$s_casa_ui <- renderUI({ db(); selector_casa_admin("s_") })
  output$i_casa_ui <- renderUI({ db(); selector_casa_admin("i_") })
  selector_casa_admin <- function(p) {
    cs <- admin_casas(em())
    selectInput(paste0(p, "casa"), "Casa:", choices = c("Elija la casa" = "", setNames(cs$id, cs$nombre)))
  }

  # ------------------------------------------------ Dueño: casas
  observeEvent(input$c_sel, {
    if (!nzchar(input$c_sel %||% "")) {
      updateTextInput(session, "c_nombre", value = ""); updateTextInput(session, "c_dir", value = "")
      return()
    }
    cs <- read_tbl("casas"); r <- cs[cs$id == input$c_sel, ]
    updateTextInput(session, "c_nombre", value = r$nombre)
    updateTextInput(session, "c_dir", value = r$direccion)
    updateDateInput(session, "c_ini", value = as.Date(r$inicio))
    updateDateInput(session, "c_fin", value = as.Date(r$fin))
    updateCheckboxInput(session, "c_act", value = r$activa == "si")
  })

  observeEvent(input$c_guardar, {
    nom <- trimws(input$c_nombre %||% "")
    if (!nzchar(nom)) return(showNotification("Escriba el nombre de la casa.", type = "warning"))
    ini <- as.character(input$c_ini); fin <- as.character(input$c_fin)
    if (is.na(ini) || is.na(fin) || ini > fin) return(showNotification("El periodo no es válido: la fecha de inicio debe ser anterior al fin.", type = "warning"))
    cs <- read_tbl("casas")
    new <- data.frame(nombre = nom, direccion = trimws(input$c_dir %||% ""), inicio = ini, fin = fin,
                      activa = if (isTRUE(input$c_act)) "si" else "no", stringsAsFactors = FALSE)
    if (nzchar(input$c_sel %||% "")) {
      i <- which(cs$id == input$c_sel)
      old <- cs[i, ]
      cs[i, c("nombre", "direccion", "inicio", "fin", "activa")] <- new
      write_tbl("casas", cs)
      log_change("Dueño", "Editar", "casa", old$id,
        diff_txt(old, cs[i, ], c(nombre = "Nombre", direccion = "Dirección", inicio = "Inicio", fin = "Fin", activa = "Activa")))
      showNotification("Casa actualizada.", type = "message")
    } else {
      id <- new_id("c")
      cs <- rbind(cs, cbind(id = id, new))
      write_tbl("casas", cs)
      log_change("Dueño", "Crear", "casa", id, paste("Casa:", nom, "Periodo:", ini, "a", fin))
      showNotification("Casa creada.", type = "message")
    }
    bump()
  })

  output$tb_casas <- renderDT({
    db(); cs <- read_tbl("casas")
    tabla_dt(data.frame(id = cs$id, Casa = cs$nombre, "Dirección" = cs$direccion,
                        Inicio = cs$inicio, Fin = cs$fin,
                        Activa = ifelse(cs$activa == "si", "Sí", "No"), stringsAsFactors = FALSE))
  })

  # ------------------------------------------------ Dueño: administradores
  observeEvent(input$a_guardar, {
    e <- tolower(trimws(input$a_email %||% ""))
    if (!grepl("^[^@ ]+@[^@ ]+\\.[^@ ]+$", e)) return(showNotification("Escriba un correo válido.", type = "warning"))
    ad <- read_tbl("admins")
    if (e %in% tolower(ad$email)) return(showNotification("Ese correo ya está aprobado.", type = "warning"))
    ad <- rbind(ad, data.frame(email = e, nombre = trimws(input$a_nombre %||% ""), stringsAsFactors = FALSE))
    write_tbl("admins", ad)
    log_change("Dueño", "Aprobar administrador", "administrador", e, "")
    updateTextInput(session, "a_email", value = ""); updateTextInput(session, "a_nombre", value = "")
    bump()
  })

  observeEvent(input$a_asig, {
    if (!nzchar(input$a_sel %||% "")) return(showNotification("Elija un administrador.", type = "warning"))
    asig <- read_tbl("asignaciones")
    antes <- paste(sort(asig$casa_id[asig$email == input$a_sel]), collapse = ",")
    asig <- asig[asig$email != input$a_sel, , drop = FALSE]
    if (length(input$a_casas)) asig <- rbind(asig, data.frame(email = input$a_sel, casa_id = input$a_casas, stringsAsFactors = FALSE))
    write_tbl("asignaciones", asig)
    despues <- paste(sort(input$a_casas), collapse = ",")
    log_change("Dueño", "Asignar casas", "administrador", input$a_sel, paste("Casas:", antes, "→", despues))
    showNotification("Asignación guardada.", type = "message")
    bump()
  })

  observeEvent(input$a_quitar, {
    if (!nzchar(input$a_sel %||% "")) return(showNotification("Elija un administrador.", type = "warning"))
    ad <- read_tbl("admins"); ad <- ad[ad$email != input$a_sel, , drop = FALSE]
    asig <- read_tbl("asignaciones"); asig <- asig[asig$email != input$a_sel, , drop = FALSE]
    write_tbl("admins", ad); write_tbl("asignaciones", asig)
    log_change("Dueño", "Quitar administrador", "administrador", input$a_sel, "Se quitó su aprobación y sus casas")
    bump()
  })

  output$tb_admins <- renderDT({
    db(); ad <- read_tbl("admins"); asig <- read_tbl("asignaciones"); cs <- read_tbl("casas")
    casas_txt <- sapply(ad$email, function(e) {
      ids <- asig$casa_id[asig$email == e]
      if (!length(ids)) "(sin casas)" else paste(cs$nombre[match(ids, cs$id)], collapse = ", ")
    })
    tabla_dt(data.frame(Correo = ad$email, Nombre = ad$nombre, Casas = unname(casas_txt),
                        stringsAsFactors = FALSE), selection = "none")
  })

  # ------------------------------------------------ Dueño: totales, Excel, cambios, inspecciones
  output$tb_totales <- renderDT({
    db(); tabla_dt(totales_df(read_tbl("casas"), read_tbl("recibos")), selection = "none")
  })

  output$dl_excel <- downloadHandler(
    filename = function() paste0("Mantenimiento_", format(Sys.Date(), "%Y%m%d"), ".xlsx"),
    content = function(file) {
      cs <- read_tbl("casas"); rec <- read_tbl("recibos"); ins <- read_tbl("inspecciones"); cam <- read_tbl("cambios")
      det <- data.frame(Casa = nombre_casa(cs, rec$casa_id), Tipo = rec$tipo,
                        Servicio = rec$servicio, Fecha = rec$fecha, Monto = rec$monto,
                        Concepto = rec$concepto, Administrador = rec$admin_email,
                        Comprobante = rec$archivo_link, stringsAsFactors = FALSE)
      ins_x <- data.frame(Casa = nombre_casa(cs, ins$casa_id), Fecha = ins$fecha,
                          `Con inquilinos` = ins$con_inquilinos, Plan = ins$plan,
                          `Comentario dueño` = ins$comentario_dueno, Administrador = ins$admin_email,
                          check.names = FALSE, stringsAsFactors = FALSE)
      write_xlsx(list(Totales = totales_df(cs, rec), Recibos = det,
                      Inspecciones = ins_x, Cambios = cam), file)
    })

  output$tb_ins_dueno <- renderDT({
    db(); cs <- read_tbl("casas"); ins <- read_tbl("inspecciones")
    tabla_dt(tabla_insp(ins, cs), selection = "none")
  })

  output$tb_cambios <- renderDT({
    db(); cam <- read_tbl("cambios")
    cam <- cam[order(cam$fecha, decreasing = TRUE), , drop = FALSE]
    tabla_dt(cam[, c("fecha", "usuario", "accion", "entidad", "detalle")], selection = "none")
  })

  # ------------------------------------------------ Dueño: configuración
  observe({
    if (identical(rol(), "dueno")) {
      cfg <- read_cfg()
      updateTextInput(session, "cfg_folder", value = cfg$drive_folder_id %||% "")
      updateTextInput(session, "cfg_sa", value = cfg$drive_sa_file %||% "")
    }
  })
  observeEvent(input$cfg_guardar, {
    cfg <- list(drive_folder_id = trimws(input$cfg_folder %||% ""), drive_sa_file = trimws(input$cfg_sa %||% ""))
    write_cfg(cfg)
    log_change("Dueño", "Configurar Drive", "configuración", "config", "Carpeta de recibos actualizada")
    showNotification("Configuración guardada.", type = "message")
    bump()
  })
  output$cfg_estado <- renderUI({
    db(); est <- drive_status(read_cfg())
    if (est == "Listo") p(style = "color:#11998e;font-weight:bold", "✔ Google Drive listo: los recibos se suben a la carpeta.")
    else p(style = "color:#b00", "⚠ ", est, " Mientras tanto, los recibos se guardan en la app.")
  })

  # ------------------------------------------------ Administrador: mis casas
  output$tb_mis_casas <- renderDT({
    db(); cs <- admin_casas(em()); asig <- read_tbl("asignaciones"); ad <- read_tbl("admins")
    otros <- sapply(cs$id, function(id) {
      emails <- asig$email[asig$casa_id == id]
      nm <- ad$nombre[match(emails, ad$email)]
      paste(ifelse(is.na(nm) | !nzchar(nm), emails, nm), collapse = ", ")
    })
    tabla_dt(data.frame(Casa = cs$nombre, "Dirección" = cs$direccion,
                        `Periodo que puedo registrar` = paste(cs$inicio, "a", cs$fin),
                        `Administradores` = unname(otros), check.names = FALSE, stringsAsFactors = FALSE),
             selection = "none")
  })

  # ------------------------------------------------ Administrador: recibos (materiales y servicios)
  mis_recibos <- function(tipo) reactive({
    db(); cs <- admin_casas(em()); rec <- read_tbl("recibos")
    rec <- rec[rec$casa_id %in% cs$id & rec$tipo == tipo, , drop = FALSE]
    rec <- rec[en_periodo(rec, cs), , drop = FALSE]
    rec[order(rec$fecha, decreasing = TRUE), , drop = FALSE]
  })
  rec_mat <- mis_recibos("Material")
  rec_srv <- mis_recibos("Servicio")
  output$tb_mat  <- renderDT({ tabla_dt(tabla_recibos(rec_mat(), admin_casas(em()))) })
  output$tb_serv <- renderDT({ tabla_dt(tabla_recibos(rec_srv(), admin_casas(em()))) })

  guardar_recibo <- function(tipo, p) {
    cs <- admin_casas(em())
    casa <- input[[paste0(p, "casa")]] %||% ""
    fecha <- as.character(input[[paste0(p, "fecha")]])
    monto <- input[[paste0(p, "monto")]]
    concepto <- trimws(input[[paste0(p, "concepto")]] %||% "")
    f <- input[[paste0(p, "archivo")]]
    if (!nzchar(casa) || casa %notin% cs$id) return(showNotification("Elija una casa que usted administra.", type = "warning"))
    c1 <- cs[cs$id == casa, ]
    if (is.na(fecha) || fecha < c1$inicio || fecha > c1$fin)
      return(showNotification(sprintf("La fecha debe estar dentro del periodo de la casa (%s a %s).", c1$inicio, c1$fin), type = "warning"))
    if (is.null(monto) || is.na(monto) || monto <= 0) return(showNotification("Escriba un monto mayor a cero.", type = "warning"))
    if (!nzchar(concepto)) return(showNotification("Escriba el concepto del gasto.", type = "warning"))
    if (is.null(f)) return(showNotification("Suba la foto o el PDF del recibo.", type = "warning"))
    servicio <- if (tipo == "Servicio") input$s_servicio %||% "Otro" else ""
    id <- new_id(if (tipo == "Material") "m" else "s")
    ext <- tools::file_ext(f$name)
    nombre <- paste0(gsub("[^A-Za-z0-9]+", "_", c1$nombre), "_", fecha, "_", id, if (nzchar(ext)) paste0(".", ext))
    arch <- guardar_comprobante(f$datapath, nombre, read_cfg())
    d <- read_tbl("recibos")
    d <- rbind(d, data.frame(id = id, casa_id = casa, tipo = tipo, servicio = servicio, fecha = fecha,
                             monto = monto, concepto = concepto, archivo = arch$archivo,
                             archivo_tipo = arch$archivo_tipo, archivo_link = arch$archivo_link,
                             admin_email = em(), creado = now_txt(), stringsAsFactors = FALSE))
    write_tbl("recibos", d)
    log_change(em(), "Crear", tipo, id, sprintf("%s · %s · %s · %s", c1$nombre, fecha, money(monto), concepto))
    updateNumericInput(session, paste0(p, "monto"), value = NA)
    updateTextInput(session, paste0(p, "concepto"), value = "")
    showNotification("Recibo guardado.", type = "message")
    bump()
  }
  observeEvent(input$m_guardar, guardar_recibo("Material", "m_"))
  observeEvent(input$s_guardar, guardar_recibo("Servicio", "s_"))

  # Editar y eliminar recibos (materiales y servicios)
  seleccion <- function(tbl_input, rec_fun) {
    i <- input[[tbl_input]]
    if (is.null(i) || length(i) == 0) return(NULL)
    rec_fun()$id[i]
  }
  edit_recibo_modal <- function(id) {
    r <- read_tbl("recibos"); r <- r[r$id == id, ]
    showModal(modalDialog(title = "Editar recibo", easyClose = TRUE,
      dateInput("ed_fecha", "Fecha del gasto:", value = as.Date(r$fecha), language = "es", format = "dd/mm/yyyy"),
      numericInput("ed_monto", "Monto ($):", value = r$monto, min = 0),
      textInput("ed_concepto", "Concepto:", value = r$concepto),
      if (r$tipo == "Servicio") selectInput("ed_servicio", "Tipo de servicio:", choices = SERVICIOS, selected = r$servicio),
      footer = tagList(modalButton("Cancelar"), actionButton("ed_guardar", "Guardar cambios", class = "btn-success"))))
  }
  observeEvent(input$m_editar, {
    id <- seleccion("tb_mat_rows_selected", rec_mat)
    if (is.null(id)) return(showNotification("Seleccione un recibo de la tabla.", type = "warning"))
    edit_target(list(tabla = "recibos", id = id)); edit_recibo_modal(id)
  })
  observeEvent(input$s_editar, {
    id <- seleccion("tb_serv_rows_selected", rec_srv)
    if (is.null(id)) return(showNotification("Seleccione un pago de la tabla.", type = "warning"))
    edit_target(list(tabla = "recibos", id = id)); edit_recibo_modal(id)
  })
  observeEvent(input$ed_guardar, {
    t <- edit_target(); req(t)
    if (t$tabla == "recibos") {
      d <- read_tbl("recibos"); i <- which(d$id == t$id); old <- d[i, ]
      cs <- admin_casas(em()); c1 <- cs[cs$id == old$casa_id, ]
      fecha <- as.character(input$ed_fecha)
      if (!nrow(c1) || is.na(fecha) || fecha < c1$inicio || fecha > c1$fin)
        return(showNotification("La fecha debe estar dentro del periodo de la casa.", type = "warning"))
      if (is.na(input$ed_monto) || input$ed_monto <= 0) return(showNotification("Escriba un monto mayor a cero.", type = "warning"))
      new <- old
      new$fecha <- fecha; new$monto <- input$ed_monto; new$concepto <- trimws(input$ed_concepto)
      if (old$tipo == "Servicio") new$servicio <- input$ed_servicio
      d[i, ] <- new
      write_tbl("recibos", d)
      log_change(em(), "Editar", old$tipo, t$id,
        diff_txt(list(fecha = old$fecha, monto = money(old$monto), concepto = old$concepto, servicio = old$servicio),
                 list(fecha = new$fecha, monto = money(new$monto), concepto = new$concepto, servicio = new$servicio),
                 c(fecha = "Fecha", monto = "Monto", concepto = "Concepto", servicio = "Servicio")))
    } else {
      d <- read_tbl("inspecciones"); i <- which(d$id == t$id); old <- d[i, ]
      new <- old
      new$fecha <- as.character(input$ed_i_fecha)
      new$con_inquilinos <- input$ed_i_inq; new$plan <- input$ed_i_plan; new$comentario_dueno <- input$ed_i_dueno
      d[i, ] <- new
      write_tbl("inspecciones", d)
      log_change(em(), "Editar", "inspección", t$id,
        diff_txt(as.list(old), as.list(new),
                 c(fecha = "Fecha", con_inquilinos = "Con inquilinos", plan = "Plan", comentario_dueno = "Comentario dueño")))
    }
    removeModal(); edit_target(NULL)
    showNotification("Cambios guardados y registrados.", type = "message")
    bump()
  })

  eliminar <- function(tabla, id, rec_label) {
    del_target(list(tabla = tabla, id = id))
    showModal(modalDialog(title = "¿Eliminar?", paste("Se eliminará:", rec_label, ". Esta acción queda registrada."),
      footer = tagList(modalButton("Cancelar"), actionButton("del_ok", "Sí, eliminar", class = "btn-danger"))))
  }
  observeEvent(input$m_eliminar, {
    id <- seleccion("tb_mat_rows_selected", rec_mat)
    if (is.null(id)) return(showNotification("Seleccione un recibo de la tabla.", type = "warning"))
    r <- read_tbl("recibos"); r <- r[r$id == id, ]
    eliminar("recibos", id, paste(r$concepto, money(r$monto)))
  })
  observeEvent(input$s_eliminar, {
    id <- seleccion("tb_serv_rows_selected", rec_srv)
    if (is.null(id)) return(showNotification("Seleccione un pago de la tabla.", type = "warning"))
    r <- read_tbl("recibos"); r <- r[r$id == id, ]
    eliminar("recibos", id, paste(r$concepto, money(r$monto)))
  })
  observeEvent(input$del_ok, {
    t <- del_target(); req(t)
    d <- read_tbl(t$tabla); old <- d[d$id == t$id, ]
    write_tbl(t$tabla, d[d$id != t$id, , drop = FALSE])
    log_change(em(), "Eliminar", if (t$tabla == "recibos") old$tipo else "inspección", t$id,
               paste(old$concepto %||% old$fecha, if (t$tabla == "recibos") money(old$monto) else ""))
    removeModal(); del_target(NULL)
    showNotification("Eliminado y registrado.", type = "message")
    bump()
  })

  # ------------------------------------------------ Administrador: inspecciones
  observeEvent(input$i_guardar, {
    cs <- admin_casas(em()); casa <- input$i_casa %||% ""
    fecha <- as.character(input$i_fecha)
    if (!nzchar(casa) || casa %notin% cs$id) return(showNotification("Elija una casa que usted administra.", type = "warning"))
    c1 <- cs[cs$id == casa, ]
    if (is.na(fecha) || fecha < c1$inicio || fecha > c1$fin)
      return(showNotification(sprintf("La fecha debe estar dentro del periodo de la casa (%s a %s).", c1$inicio, c1$fin), type = "warning"))
    id <- new_id("i")
    d <- read_tbl("inspecciones")
    d <- rbind(d, data.frame(id = id, casa_id = casa, fecha = fecha,
                             con_inquilinos = input$i_inq %||% "", plan = input$i_plan %||% "",
                             comentario_dueno = input$i_dueno %||% "", admin_email = em(),
                             creado = now_txt(), stringsAsFactors = FALSE))
    write_tbl("inspecciones", d)
    log_change(em(), "Crear", "inspección", id, paste(c1$nombre, fecha))
    updateTextAreaInput(session, "i_inq", value = ""); updateTextAreaInput(session, "i_plan", value = "")
    updateTextAreaInput(session, "i_dueno", value = "")
    showNotification("Inspección guardada.", type = "message")
    bump()
  })

  mis_insp <- reactive({
    db(); cs <- admin_casas(em()); d <- read_tbl("inspecciones")
    d <- d[d$casa_id %in% cs$id, , drop = FALSE]
    d <- d[en_periodo(d, cs), , drop = FALSE]
    d[order(d$fecha, decreasing = TRUE), , drop = FALSE]
  })
  output$tb_insp_admin <- renderDT({ tabla_dt(tabla_insp(mis_insp(), admin_casas(em()))) })

  observeEvent(input$i_editar, {
    i <- input$tb_insp_admin_rows_selected
    if (is.null(i)) return(showNotification("Seleccione una inspección de la tabla.", type = "warning"))
    id <- mis_insp()$id[i]
    r <- read_tbl("inspecciones"); r <- r[r$id == id, ]
    edit_target(list(tabla = "inspecciones", id = id))
    showModal(modalDialog(title = "Editar inspección", easyClose = TRUE,
      dateInput("ed_i_fecha", "Fecha:", value = as.Date(r$fecha), language = "es", format = "dd/mm/yyyy"),
      textAreaInput("ed_i_inq", "Con inquilinos:", value = r$con_inquilinos, rows = 3),
      textAreaInput("ed_i_plan", "Plan:", value = r$plan, rows = 3),
      textAreaInput("ed_i_dueno", "Comentario para el dueño:", value = r$comentario_dueno, rows = 3),
      footer = tagList(modalButton("Cancelar"), actionButton("ed_guardar", "Guardar cambios", class = "btn-success"))))
  })
  observeEvent(input$i_eliminar, {
    i <- input$tb_insp_admin_rows_selected
    if (is.null(i)) return(showNotification("Seleccione una inspección de la tabla.", type = "warning"))
    id <- mis_insp()$id[i]
    eliminar("inspecciones", id, "esta inspección")
  })
}

ui <- fluidPage(
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$script(HTML("document.documentElement.lang = 'es-MX';")),
    tags$style(HTML(CSS))
  ),
  uiOutput("main")
)

shinyApp(ui, server)
