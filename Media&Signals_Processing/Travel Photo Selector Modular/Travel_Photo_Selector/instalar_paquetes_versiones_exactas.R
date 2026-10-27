# ============================================================================
# MIS FOTOS DE VIAJE - INSTALAR LOS PAQUETES CON LAS VERSIONES EXACTAS
# DE LA COMPUTADORA ORIGINAL, EN EL ORDEN CORRECTO
#
# Cómo usarlo:
#   1. Abra RStudio y REINICIE R antes (menú Session > Restart R, o Ctrl+Shift+F10).
#      Así ningún paquete está "en uso" y Windows deja reemplazarlo.
#   2. Abra este archivo y presione "Source"
#      (o en la consola: source("instalar_paquetes_versiones_exactas.R", encoding = "UTF-8")).
#   Necesita internet. Tarda unos minutos.
#
# Cómo consigue las versiones exactas SIN tener que compilar (sin Rtools):
#   Usa Posit Package Manager, que guarda una "foto" de CRAN de cada día con
#   paquetes ya compilados para Windows y Mac. Se usa la foto del día en que se
#   revisó la computadora original, así todas las versiones son compatibles entre sí.
#   Si algún paquete tiene otra versión en esa foto, busca la foto del día en que
#   salió la versión exacta.
#
# Por qué importa el orden:
#   - install.packages() NO actualiza dependencias que ya están instaladas aunque
#     sean muy viejas; después la app falla con "namespace X ... is required".
#     Por eso primero se instalan/actualizan TODAS las dependencias de fondo
#     (Rcpp, rlang, htmltools, httpuv, later, promises, etc.) desde la misma foto.
#   - Luego los paquetes de la app, de los más básicos a los que dependen de ellos:
#       R6, digest, jsonlite, yaml, fs      (los usan shiny y shinyFiles)
#       systemfonts -> ragg                 (ragg usa el código de systemfonts)
#       magick                              (independiente, el más pesado)
#       shiny -> shinydashboard, shinyFiles (estos dos necesitan shiny ya instalado)
# ============================================================================

# >>> VERSIONES DE LA COMPUTADORA ORIGINAL (no mueva esta línea)
FECHA_ORIGINAL <- "2026-10-24"
R_ORIGINAL     <- "4.4.0"
PAQUETES <- c(              # en ORDEN de instalación
  R6             = "2.6.1",
  digest         = "0.6.39",
  jsonlite       = "2.0.0",
  yaml           = "2.3.12",
  fs             = "2.1.0",
  systemfonts    = "1.3.2",
  ragg           = "1.5.2",
  magick         = "2.9.1",
  shiny          = "1.14.0",
  shinydashboard = "0.7.3",
  shinyFiles     = "0.9.3"
)
# <<< VERSIONES DE LA COMPUTADORA ORIGINAL (no mueva esta línea)

local({
  PPM  <- getOption("fotos.ppm", "https://packagemanager.posit.co/cran")   # (la opción solo se usa para pruebas)
  CRAN <- getOption("fotos.cran", "https://cloud.r-project.org")
  es_win <- .Platform$OS.type == "windows"
  es_mac <- Sys.info()[["sysname"]] == "Darwin"
  tipo   <- if (es_win || es_mac) "binary" else getOption("pkgType")
  options(install.packages.compile.from.source = "never", timeout = max(600, getOption("timeout")))

  msg  <- function(...) cat(..., "\n", sep = "")
  paso <- function(n, txt) msg("\n", strrep("-", 64), "\n PASO ", n, ": ", txt, "\n", strrep("-", 64))
  ver_instalada <- function(p) {
    v <- tryCatch(as.character(utils::packageVersion(p)), error = function(e) NA_character_)
    if (length(v) == 0) NA_character_ else v
  }
  snapshot <- function(fecha) paste0(PPM, "/", fecha)
  disponibles <- function(repo) {
    tryCatch(utils::available.packages(repos = repo, type = tipo), error = function(e) NULL)
  }

  msg(strrep("=", 64))
  msg(" MIS FOTOS DE VIAJE - INSTALAR PAQUETES CON VERSIONES EXACTAS")
  msg(strrep("=", 64))
  msg(" R en esta computadora: ", R.version.string)
  msg(" R en la original:      ", R_ORIGINAL, "   | Fecha de referencia: ", FECHA_ORIGINAL)

  # ------------------------------------------------------------ PASO 0
  paso(0, "Revisiones previas")
  r_aqui <- paste(R.version$major, sub("\\..*", "", R.version$minor), sep = ".")
  r_orig <- sub("^(\\d+\\.\\d+).*", "\\1", R_ORIGINAL)
  if (getRversion() < "4.1.0") stop("Se necesita R 4.1 o más nuevo.")
  if (r_aqui != r_orig) {
    msg(" ⚠ Esta computadora tiene R ", r_aqui, ".x y la original R ", r_orig, ".x.")
    msg("   Se intentará igual; si alguna versión exacta no existe compilada para este R, se avisará.")
  } else msg(" ✔ Misma versión principal de R (", r_aqui, ".x)")

  cargados <- intersect(loadedNamespaces(), c(names(PAQUETES), "Rcpp", "rlang", "htmltools", "httpuv", "later", "promises"))
  if (length(cargados)) {
    msg(" ✖ Estos paquetes están en uso en esta sesión: ", paste(cargados, collapse = ", "))
    stop("Reinicie R (Session > Restart R o Ctrl+Shift+F10) y vuelva a correr este script sin abrir la app antes.", call. = FALSE)
  }
  lib <- .libPaths()[1]
  if (file.access(lib, 2) != 0) {
    lib <- Sys.getenv("R_LIBS_USER")
    dir.create(lib, recursive = TRUE, showWarnings = FALSE)
    .libPaths(c(lib, .libPaths()))
  }
  msg(" ✔ Se instalará en: ", lib)

  # ------------------------------------------------------------ PASO 1
  paso(1, paste("Conectando con la foto de CRAN del", FECHA_ORIGINAL))
  repo_base <- snapshot(FECHA_ORIGINAL)
  db <- disponibles(repo_base)
  if (is.null(db) || nrow(db) == 0) {
    msg(" ⚠ No se pudo usar Posit Package Manager; se usará CRAN normal (versiones más recientes).")
    repo_base <- CRAN
    db <- disponibles(repo_base)
    if (is.null(db)) stop("No hay conexión a internet o CRAN no responde. Revise su conexión e intente de nuevo.", call. = FALSE)
  }
  msg(" ✔ Repositorio: ", repo_base, "  (", nrow(db), " paquetes disponibles)")

  # ------------------------------------------------------------ PASO 2
  paso(2, "Instalando/actualizando primero las dependencias de fondo")
  deps <- tools::package_dependencies(names(PAQUETES), db = db, recursive = TRUE,
                                      which = c("Depends", "Imports", "LinkingTo"))
  base_pkgs <- rownames(utils::installed.packages(priority = "base"))
  deps <- setdiff(unique(unlist(deps)), c(names(PAQUETES), base_pkgs))
  deps <- deps[deps %in% rownames(db)]
  hace_falta <- deps[vapply(deps, function(p) {
    v <- ver_instalada(p)
    is.na(v) || utils::compareVersion(v, db[p, "Version"]) < 0
  }, logical(1))]
  # Dependencias que a su vez necesitan un paquete de la app (p. ej. textshaping necesita
  # systemfonts): se instalan justo después de ese paquete, en el PASO 3.
  necesita_app <- tools::package_dependencies(hace_falta, db = db, recursive = TRUE,
                                              which = c("Depends", "Imports", "LinkingTo"))
  despues_de <- vapply(necesita_app, function(d) {
    pos <- match(d, names(PAQUETES)); if (all(is.na(pos))) 0L else max(pos, na.rm = TRUE)
  }, integer(1))
  tardias <- hace_falta[despues_de > 0]
  despues_de <- despues_de[despues_de > 0]
  hace_falta <- setdiff(hace_falta, tardias)
  if (length(tardias)) msg(" (Se instalarán más adelante, en su lugar: ", paste(tardias, collapse = ", "), ")")
  if (length(hace_falta)) {
    msg(" Instalando ", length(hace_falta), " dependencia(s): ", paste(hace_falta, collapse = ", "))
    # install.packages ordena estas dependencias entre sí automáticamente
    utils::install.packages(hace_falta, repos = repo_base, type = tipo, lib = lib, dependencies = FALSE)
  } else msg(" ✔ Las ", length(deps), " dependencias de fondo ya están al día.")

  # ------------------------------------------------------------ PASO 3
  paso(3, "Instalando los paquetes de la app en orden, con su versión exacta")

  # Busca la fecha en que salió una versión (para usar la foto de ese día)
  fecha_de_version <- function(p, v) {
    url <- sprintf("https://crandb.r-pkg.org/%s/%s", p, v)
    txt <- tryCatch(suppressWarnings(paste(readLines(url, warn = FALSE), collapse = "")), error = function(e) "")
    m <- regmatches(txt, regexpr('"Date/Publication"\\s*:\\s*"[0-9]{4}-[0-9]{2}-[0-9]{2}', txt))
    if (!length(m)) return(NA_character_)
    sub('.*"', "", m)
  }

  resultado <- data.frame(paquete = names(PAQUETES), deseada = unname(PAQUETES),
                          instalada = NA_character_, como = "", stringsAsFactors = FALSE)

  for (i in seq_along(PAQUETES)) {
    p <- names(PAQUETES)[i]; v <- PAQUETES[[i]]
    actual <- ver_instalada(p)
    if (!is.na(actual) && actual == v) {
      msg(sprintf(" [%2d/%d] %-14s %-8s ✔ ya estaba instalada", i, length(PAQUETES), p, v))
      resultado$instalada[i] <- actual; resultado$como[i] <- "ya estaba"; next
    }
    msg(sprintf(" [%2d/%d] %-14s %-8s instalando...", i, length(PAQUETES), p, v))
    repo <- NULL
    if (p %in% rownames(db) && db[p, "Version"] == v) {
      repo <- repo_base
    } else {
      # la foto del día de referencia tiene otra versión: buscar la foto del día en que salió v
      f <- fecha_de_version(p, v)
      if (!is.na(f)) {
        for (k in 1:5) {                       # unos días después de su publicación
          cand <- snapshot(format(as.Date(f) + k, "%Y-%m-%d"))
          dbk <- disponibles(cand)
          if (!is.null(dbk) && p %in% rownames(dbk) && dbk[p, "Version"] == v) { repo <- cand; break }
        }
      }
    }
    if (!is.null(repo)) {
      tryCatch(utils::install.packages(p, repos = repo, type = tipo, lib = lib, dependencies = FALSE),
               error = function(e) msg("        ✖ ", conditionMessage(e)))
      resultado$como[i] <- if (identical(repo, repo_base)) "foto de referencia" else sub(".*/", "foto del ", repo)
    } else {
      # último recurso: la versión disponible más cercana (ya compilada)
      msg("        ⚠ No encontré ", p, " ", v, " ya compilada; se instala la versión ",
          if (p %in% rownames(db)) db[p, "Version"] else "más reciente", " (compatible).")
      tryCatch(utils::install.packages(p, repos = repo_base, type = tipo, lib = lib, dependencies = FALSE),
               error = function(e) msg("        ✖ ", conditionMessage(e)))
      resultado$como[i] <- "versión más cercana"
    }
    resultado$instalada[i] <- ver_instalada(p)

    # dependencias que esperaban a este paquete
    ahora <- tardias[despues_de == i]
    if (length(ahora)) {
      msg("        + dependencia(s) que necesitaban ", p, ": ", paste(ahora, collapse = ", "))
      tryCatch(utils::install.packages(ahora, repos = repo_base, type = tipo, lib = lib, dependencies = FALSE),
               error = function(e) msg("        ✖ ", conditionMessage(e)))
    }
  }

  # ------------------------------------------------------------ PASO 4
  paso(4, "Revisión final (cada paquete se carga en una sesión limpia de R)")
  rscript <- file.path(R.home("bin"), if (es_win) "Rscript.exe" else "Rscript")
  carga_ok <- vapply(names(PAQUETES), function(p) {
    out <- suppressWarnings(system2(rscript, c("-e", shQuote(sprintf("suppressMessages(library(%s))", p))),
                                    stdout = TRUE, stderr = TRUE))
    is.null(attr(out, "status")) || attr(out, "status") == 0
  }, logical(1))

  resultado$instalada <- vapply(resultado$paquete, ver_instalada, character(1))
  resultado$exacta <- !is.na(resultado$instalada) & resultado$instalada == resultado$deseada
  resultado$carga  <- carga_ok
  for (i in seq_len(nrow(resultado))) {
    r <- resultado[i, ]
    icono <- if (!r$carga) "✖" else if (r$exacta) "✔" else "≈"
    msg(sprintf("  %s %-14s deseada %-8s instalada %-10s %s", icono, r$paquete, r$deseada,
                ifelse(is.na(r$instalada), "—", r$instalada), if (!r$carga) "NO CARGA" else ""))
  }
  reporte <- file.path(getwd(), "resultado_instalacion.txt")
  tryCatch(utils::write.table(resultado, reporte, sep = "\t", row.names = FALSE, quote = FALSE,
                              fileEncoding = "UTF-8"), error = function(e) NULL)

  msg("")
  if (all(resultado$carga) && all(resultado$exacta)) {
    msg(" ✅ Listo: todos los paquetes tienen la versión exacta de la computadora original.")
  } else if (all(resultado$carga)) {
    msg(" ✅ Listo: todo funciona. Los marcados con ≈ tienen una versión distinta pero compatible.")
  } else {
    msg(" ⚠ Algunos paquetes no cargan. Reinicie R y vuelva a correr este script.")
    msg("   Si sigue fallando, mándeme el archivo resultado_instalacion.txt")
  }
  msg(" Reporte guardado en: ", reporte, "\n")
  invisible(resultado)
})
