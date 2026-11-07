# ============================================================================
# MIS FOTOS DE VIAJE - REVISAR ESTA COMPUTADORA Y PREPARAR INSTALACIÓN
#
# Córralo desde la misma carpeta donde está app.R:
#   - En RStudio: abra este archivo y presione "Source"
#   - O en la consola:  source("revisar_e_instalar.R", encoding = "UTF-8")
#   - O desde una terminal:  Rscript revisar_e_instalar.R
#
# Hace dos cosas:
#   1. Muestra y guarda en "entorno_actual.txt" la versión de R, de RStudio
#      (si se puede detectar) y de cada paquete que usa la app.
#   2. Crea la carpeta "instalar_en_computadora_nueva/" con todo lo necesario
#      para instalar R, RStudio y los paquetes en una computadora que NO tiene R:
#        1_instalar_todo_Windows.bat    (doble clic en Windows)
#        1_instalar_todo_Mac.command    (doble clic en Mac)
#        2_instalar_paquetes.R          (lo usan los dos anteriores; también se puede correr solo)
#        3_abrir_la_app_Windows.bat / 3_abrir_la_app_Mac.command
#        LEEME.txt                      (instrucciones paso a paso)
# ============================================================================

local({

  # ---------------------------------------------------------- app folder
  app_dir <- getwd()
  if (!file.exists(file.path(app_dir, "app.R"))) {
    # try the folder of this script (Rscript --file=... or source())
    args <- commandArgs(trailingOnly = FALSE)
    f <- sub("^--file=", "", args[grepl("^--file=", args)])
    if (!length(f)) f <- tryCatch(normalizePath(sys.frames()[[1]]$ofile), error = function(e) character())
    if (length(f) && file.exists(file.path(dirname(f[1]), "app.R"))) app_dir <- dirname(normalizePath(f[1]))
  }
  if (!file.exists(file.path(app_dir, "app.R"))) {
    stop("No encontré app.R. Corra este script desde la carpeta de la app (use setwd() o 'Session > Set Working Directory' en RStudio).")
  }
  app_dir <- normalizePath(app_dir, winslash = "/")

  # ---------------------------------------------------- packages needed
  core <- c("shiny", "shinydashboard", "R6", "yaml", "jsonlite")
  from_registry <- tryCatch({
    reg <- yaml::read_yaml(file.path(app_dir, "modules", "_module_registry.yml"))
    unlist(lapply(reg$modules, function(m) if (isTRUE(m$enabled)) m$packages))
  }, error = function(e) c("digest", "shinyFiles", "fs", "magick", "ragg", "systemfonts"))
  paquetes <- unique(c(core, from_registry, "digest", "fs"))

  pkg_version <- function(p) {
    if (requireNamespace(p, quietly = TRUE)) as.character(utils::packageVersion(p)) else NA_character_
  }
  versiones <- vapply(paquetes, pkg_version, character(1))

  # ------------------------------------------------------- R / RStudio
  r_ver <- paste(R.version$major, R.version$minor, sep = ".")

  rstudio_version <- function() {
    # 1) running inside RStudio
    v <- tryCatch({
      if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
        as.character(rstudioapi::versionInfo()$version) else NA_character_
    }, error = function(e) NA_character_)
    if (!is.na(v)) return(paste(v, "(RStudio abierto ahora)"))
    v <- tryCatch({
      f <- get(".rs.api.versionInfo", envir = as.environment("tools:rstudio"))
      paste(as.character(f()$version), "(RStudio abierto ahora)")
    }, error = function(e) NA_character_)
    if (!is.na(v)) return(v)
    # 2) installed but not running: read the version from the installation files
    candidates <- character()
    if (.Platform$OS.type == "windows") {
      pf <- c(Sys.getenv("ProgramFiles"), Sys.getenv("ProgramFiles(x86)"), file.path(Sys.getenv("LOCALAPPDATA"), "Programs"))
      candidates <- file.path(pf[nzchar(pf)], "RStudio", "resources", "app", "package.json")
    } else if (Sys.info()[["sysname"]] == "Darwin") {
      plist <- "/Applications/RStudio.app/Contents/Info.plist"
      if (file.exists(plist)) {
        txt <- readLines(plist, warn = FALSE)
        i <- grep("CFBundleShortVersionString", txt)
        if (length(i)) return(paste(gsub(".*<string>(.*)</string>.*", "\\1", txt[i[1] + 1]), "(instalado)"))
      }
    } else {
      candidates <- c("/usr/lib/rstudio/resources/app/package.json", "/opt/rstudio/resources/app/package.json")
    }
    for (pj in candidates) {
      if (file.exists(pj)) {
        txt <- paste(readLines(pj, warn = FALSE), collapse = "")
        m <- regmatches(txt, regexpr('"version"\\s*:\\s*"[^"]+"', txt))
        if (length(m)) return(paste(gsub('.*"([^"]+)"$', "\\1", m), "(instalado)"))
      }
    }
    "no detectado (no está abierto o no está instalado)"
  }
  rs_ver <- rstudio_version()

  so <- tryCatch(utils::sessionInfo()$running, error = function(e) Sys.info()[["sysname"]])
  imagemagick <- tryCatch(as.character(magick::magick_config()$version), error = function(e) "no disponible")
  fuentes_ok <- tryCatch({
    requireNamespace("systemfonts", quietly = TRUE) && requireNamespace("ragg", quietly = TRUE) &&
      file.exists(file.path(app_dir, "www/fonts/AtkinsonHyperlegible-Regular.ttf"))
  }, error = function(e) FALSE)

  # ------------------------------------------------------------ report
  linea <- strrep("=", 64)
  rep <- c(
    linea,
    " MIS FOTOS DE VIAJE - REVISIÓN DE ESTA COMPUTADORA",
    linea,
    paste(" Fecha:              ", format(Sys.time(), "%Y-%m-%d %H:%M")),
    paste(" Carpeta de la app:  ", app_dir),
    paste(" Sistema operativo:  ", so),
    paste(" Versión de R:       ", R.version.string),
    paste(" Versión de RStudio: ", rs_ver),
    paste(" ImageMagick (magick):", imagemagick),
    paste(" Sello de agua listo:", if (isTRUE(fuentes_ok)) "Sí" else "No (faltan ragg/systemfonts o las fuentes)"),
    "",
    " Paquetes que usa la app:",
    sprintf("   %-16s %s", paquetes, ifelse(is.na(versiones), "NO INSTALADO", versiones)),
    "",
    if (any(is.na(versiones)))
      paste(" ⚠ Faltan paquetes:", paste(paquetes[is.na(versiones)], collapse = ", "),
            "\n   Instálelos con: source('install_packages.R')")
    else " ✔ Todos los paquetes están instalados.",
    linea
  )
  cat(rep, sep = "\n")
  writeLines(enc2utf8(rep), file.path(app_dir, "entorno_actual.txt"), useBytes = TRUE)

  # -------------------------------------------- installer for a new computer
  out <- file.path(app_dir, "instalar_en_computadora_nueva")
  dir.create(out, showWarnings = FALSE)
  write_utf8 <- function(lines, file, eol = "\n") {
    con <- file(file, open = "wb"); on.exit(close(con))
    writeBin(charToRaw(enc2utf8(paste0(paste(lines, collapse = eol), eol))), con)
  }
  fecha <- format(Sys.Date(), "%Y-%m-%d")
  vers_txt <- ifelse(is.na(versiones), "", versiones)

  # ---- 2_instalar_paquetes.R
  pk <- c(
    "# ============================================================================",
    "# MIS FOTOS DE VIAJE - INSTALAR LOS PAQUETES DE R QUE NECESITA LA APP",
    paste0("# Generado el ", fecha, " en una computadora con ", R.version.string),
    "# Se puede correr solo:  Rscript 2_instalar_paquetes.R   (o 'Source' en RStudio)",
    "# ============================================================================",
    "",
    "options(repos = c(CRAN = \"https://cloud.r-project.org\"))",
    "options(install.packages.compile.from.source = \"never\")   # usar versiones ya compiladas (más rápido, sin herramientas extra)",
    "",
    paste0("version_r_original <- \"", r_ver, "\""),
    "paquetes <- c(",
    paste0("  ", sprintf("\"%s\" = \"%s\"", paquetes, vers_txt), c(rep(",", length(paquetes) - 1), ""),
           "   # versión en la computadora original"),
    ")",
    "",
    "cat(\"\\n=== Instalando paquetes para Mis Fotos de Viaje ===\\n\")",
    "cat(\"R en esta computadora:\", R.version.string, \"| R en la original:\", version_r_original, \"\\n\\n\")",
    "if (getRversion() < \"4.1.0\") stop(\"Se necesita R 4.1 o más nuevo. Instale una versión reciente de R.\")",
    "",
    "faltan <- names(paquetes)[!vapply(names(paquetes), requireNamespace, logical(1), quietly = TRUE)]",
    "if (length(faltan)) {",
    "  cat(\"Instalando:\", paste(faltan, collapse = \", \"), \"\\n(esto puede tardar varios minutos)\\n\\n\")",
    "  install.packages(faltan, dependencies = c(\"Depends\", \"Imports\", \"LinkingTo\"))",
    "}",
    "",
    "cat(\"\\n=== Revisión final ===\\n\")",
    "ok <- TRUE",
    "for (p in names(paquetes)) {",
    "  if (requireNamespace(p, quietly = TRUE)) {",
    "    v <- as.character(utils::packageVersion(p))",
    "    cat(sprintf(\"  ✔ %-14s %-10s (original: %s)\\n\", p, v, ifelse(nzchar(paquetes[[p]]), paquetes[[p]], \"-\")))",
    "  } else {",
    "    ok <- FALSE",
    "    cat(sprintf(\"  ✖ %-14s NO SE PUDO INSTALAR\\n\", p))",
    "  }",
    "}",
    "if (ok) {",
    "  cat(\"\\n✅ Listo. Todos los paquetes están instalados.\\n\")",
    "  cat(\"   Para abrir la app use '3_abrir_la_app' o en R: shiny::runApp('<carpeta de la app>', launch.browser = TRUE)\\n\\n\")",
    "} else {",
    "  cat(\"\\n⚠ Algunos paquetes no se instalaron. Revise su conexión a internet y vuelva a correr este script.\\n\")",
    "  if (Sys.info()[[\"sysname\"]] == \"Linux\")",
    "    cat(\"   En Linux, 'magick' y 'ragg' necesitan: sudo apt install libmagick++-dev libfontconfig1-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev\\n\")",
    "}"
  )
  # Preferred: the exact-version installer (same order and method as
  # instalar_paquetes_versiones_exactas.R) filled in with THIS computer's versions.
  plantilla <- file.path(app_dir, "instalar_paquetes_versiones_exactas.R")
  if (file.exists(plantilla) && !any(is.na(versiones))) {
    tpl <- readLines(plantilla, encoding = "UTF-8", warn = FALSE)
    i1 <- grep("^# >>> VERSIONES", tpl); i2 <- grep("^# <<< VERSIONES", tpl)
    if (length(i1) == 1 && length(i2) == 1 && i2 > i1) {
      orden <- c("R6", "digest", "jsonlite", "yaml", "fs", "systemfonts", "ragg", "magick",
                 "shiny", "shinydashboard", "shinyFiles")
      ord <- c(intersect(orden, paquetes), setdiff(paquetes, orden))
      bloque <- c(
        tpl[i1],
        sprintf('FECHA_ORIGINAL <- "%s"', fecha),
        sprintf('R_ORIGINAL     <- "%s"', r_ver),
        "PAQUETES <- c(              # en ORDEN de instalación",
        paste0("  ", sprintf("%-14s = \"%s\"", ord, versiones[ord]), c(rep(",", length(ord) - 1), "")),
        ")",
        tpl[i2]
      )
      pk <- c(tpl[seq_len(i1 - 1)], bloque, tpl[(i2 + 1):length(tpl)])
    }
  }
  write_utf8(pk, file.path(out, "2_instalar_paquetes.R"))

  # ---- Windows: install R + RStudio with winget, then packages
  win <- c(
    "@echo off",
    "chcp 65001 >nul",
    "setlocal EnableExtensions",
    "title Mis Fotos de Viaje - Instalacion",
    "echo ================================================================",
    "echo  MIS FOTOS DE VIAJE - INSTALAR R, RSTUDIO Y LOS PAQUETES",
    "echo ================================================================",
    "echo.",
    "where winget >nul 2>&1",
    "if errorlevel 1 (",
    "  echo No se encontro 'winget' en esta computadora.",
    "  echo Instale R a mano desde la pagina que se va a abrir y luego vuelva a correr este archivo.",
    "  start \"\" \"https://cloud.r-project.org/bin/windows/base/\"",
    "  start \"\" \"https://posit.co/download/rstudio-desktop/\"",
    "  goto PAQUETES",
    ")",
    "",
    paste0("echo [1/3] Instalando R ", r_ver, " (la misma version de la computadora original)..."),
    paste0("winget install -e --id RProject.R --version ", r_ver, " --accept-source-agreements --accept-package-agreements"),
    "if errorlevel 1 (",
    "  echo Esa version exacta no esta disponible; instalando la version mas reciente de R...",
    "  winget install -e --id RProject.R --accept-source-agreements --accept-package-agreements",
    ")",
    "echo.",
    "echo [2/3] Instalando RStudio...",
    "winget install -e --id Posit.RStudio --accept-source-agreements --accept-package-agreements",
    "if errorlevel 1 winget install -e --id RStudio.RStudio --accept-source-agreements --accept-package-agreements",
    "",
    ":PAQUETES",
    "echo.",
    "echo [3/3] Instalando los paquetes de R que usa la app...",
    "set \"RSCRIPT=\"",
    paste0("if exist \"%ProgramFiles%\\R\\R-", r_ver, "\\bin\\Rscript.exe\" set \"RSCRIPT=%ProgramFiles%\\R\\R-", r_ver, "\\bin\\Rscript.exe\""),
    "if not defined RSCRIPT for /d %%D in (\"%ProgramFiles%\\R\\R-*\") do if exist \"%%D\\bin\\Rscript.exe\" set \"RSCRIPT=%%D\\bin\\Rscript.exe\"",
    "if not defined RSCRIPT for /d %%D in (\"%LOCALAPPDATA%\\Programs\\R\\R-*\") do if exist \"%%D\\bin\\Rscript.exe\" set \"RSCRIPT=%%D\\bin\\Rscript.exe\"",
    "if not defined RSCRIPT (",
    "  echo No encontre R instalado. Instale R y vuelva a correr este archivo.",
    "  pause",
    "  exit /b 1",
    ")",
    "echo Usando: %RSCRIPT%",
    "set \"AQUI=%~dp0\"",
    "\"%RSCRIPT%\" \"%AQUI%2_instalar_paquetes.R\"",
    "echo.",
    "echo Termino la instalacion. Para abrir la app use 3_abrir_la_app_Windows.bat",
    "pause"
  )
  write_utf8(win, file.path(out, "1_instalar_todo_Windows.bat"), eol = "\r\n")

  win_open <- c(
    "@echo off",
    "chcp 65001 >nul",
    "title Mis Fotos de Viaje",
    "set \"RSCRIPT=\"",
    "for /d %%D in (\"%ProgramFiles%\\R\\R-*\") do if exist \"%%D\\bin\\Rscript.exe\" set \"RSCRIPT=%%D\\bin\\Rscript.exe\"",
    "if not defined RSCRIPT for /d %%D in (\"%LOCALAPPDATA%\\Programs\\R\\R-*\") do if exist \"%%D\\bin\\Rscript.exe\" set \"RSCRIPT=%%D\\bin\\Rscript.exe\"",
    "if not defined RSCRIPT ( echo No encontre R. Corra primero 1_instalar_todo_Windows.bat & pause & exit /b 1 )",
    "cd /d \"%~dp0..\"",
    "echo Abriendo Mis Fotos de Viaje en el navegador... (no cierre esta ventana mientras usa la app)",
    "\"%RSCRIPT%\" -e \"shiny::runApp('.', launch.browser = TRUE)\"",
    "pause"
  )
  write_utf8(win_open, file.path(out, "3_abrir_la_app_Windows.bat"), eol = "\r\n")

  # ---- Mac
  mac <- c(
    "#!/bin/bash",
    "# MIS FOTOS DE VIAJE - instalar paquetes en Mac (doble clic)",
    "cd \"$(dirname \"$0\")\"",
    "RSCRIPT=\"$(command -v Rscript)\"",
    "[ -z \"$RSCRIPT\" ] && [ -x /Library/Frameworks/R.framework/Resources/bin/Rscript ] && RSCRIPT=/Library/Frameworks/R.framework/Resources/bin/Rscript",
    "if [ -z \"$RSCRIPT\" ]; then",
    paste0("  echo \"R no está instalado. Se abrirán las páginas de descarga de R (la computadora original tenía R ", r_ver, ") y de RStudio.\""),
    "  echo \"Instale los dos (siguiente, siguiente...) y luego vuelva a dar doble clic a este archivo.\"",
    "  open \"https://cloud.r-project.org/bin/macosx/\"",
    "  open \"https://posit.co/download/rstudio-desktop/\"",
    "  read -p \"Presione Enter para cerrar...\"",
    "  exit 1",
    "fi",
    "\"$RSCRIPT\" 2_instalar_paquetes.R",
    "[ -d /Applications/RStudio.app ] || { echo \"(RStudio no está instalado; es opcional para usar la app)\"; open \"https://posit.co/download/rstudio-desktop/\"; }",
    "read -p \"Presione Enter para cerrar...\""
  )
  write_utf8(mac, file.path(out, "1_instalar_todo_Mac.command"))
  mac_open <- c(
    "#!/bin/bash",
    "cd \"$(dirname \"$0\")/..\"",
    "RSCRIPT=\"$(command -v Rscript)\"",
    "[ -z \"$RSCRIPT\" ] && RSCRIPT=/Library/Frameworks/R.framework/Resources/bin/Rscript",
    "echo \"Abriendo Mis Fotos de Viaje en el navegador... (no cierre esta ventana mientras usa la app)\"",
    "\"$RSCRIPT\" -e \"shiny::runApp('.', launch.browser = TRUE)\""
  )
  write_utf8(mac_open, file.path(out, "3_abrir_la_app_Mac.command"))
  Sys.chmod(file.path(out, c("1_instalar_todo_Mac.command", "3_abrir_la_app_Mac.command")), mode = "0755")

  # ---- LEEME
  leeme <- c(
    "MIS FOTOS DE VIAJE - CÓMO INSTALAR EN UNA COMPUTADORA NUEVA",
    strrep("=", 60),
    paste("Preparado el", fecha, "desde una computadora con:"),
    paste("  -", R.version.string),
    paste("  - RStudio:", rs_ver),
    paste("  -", so),
    "",
    "1. Copie TODA la carpeta de la app a la computadora nueva",
    "   (la carpeta donde está app.R, incluyendo esta carpeta).",
    "   Si quiere conservar las fotos elegidas y la configuración, copie también la carpeta 'data'.",
    "",
    "2. Necesita internet. Entre a esta carpeta y dé doble clic a:",
    "     Windows:  1_instalar_todo_Windows.bat",
    "               (instala R, RStudio y los paquetes; acepte si Windows pide permiso)",
    "     Mac:      1_instalar_todo_Mac.command",
    "               (si no hay R, abre la página de descarga; instálelo y vuelva a dar doble clic)",
    "               Si el Mac no deja abrirlo: clic derecho > Abrir.",
    "",
    "3. Para usar la app, doble clic a:",
    "     Windows:  3_abrir_la_app_Windows.bat",
    "     Mac:      3_abrir_la_app_Mac.command",
    "   o en RStudio: abra app.R y presione 'Run App'.",
    "",
    "4. En la app, entre a 'Administrador' (código 718), elija la carpeta principal de fotos",
    "   y presione 'Escanear carpetas y fotos'.",
    "",
    "Paquetes que se instalan:",
    sprintf("   %-14s (en la computadora original: %s)", paquetes, ifelse(is.na(versiones), "no instalado", versiones))
  )
  write_utf8(leeme, file.path(out, "LEEME.txt"), eol = "\r\n")

  cat("\n✔ Se guardó el reporte en:   ", file.path(app_dir, "entorno_actual.txt"), "\n")
  cat("✔ Se preparó la instalación en:", out, "\n")
  cat("  Copie la carpeta completa de la app a la computadora nueva y siga LEEME.txt\n\n")
  invisible(NULL)
})
