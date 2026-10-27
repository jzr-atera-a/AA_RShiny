# ============================================================================
# MIS FOTOS DE VIAJE - INSTALAR LOS PAQUETES DE R QUE NECESITA LA APP
# Generado el 2026-10-24 en una computadora con R version 4.4.0 (2024-04-24 ucrt)
# Se puede correr solo:  Rscript 2_instalar_paquetes.R   (o 'Source' en RStudio)
# ============================================================================

options(repos = c(CRAN = "https://cloud.r-project.org"))
options(install.packages.compile.from.source = "never")   # usar versiones ya compiladas (más rápido, sin herramientas extra)

version_r_original <- "4.4.0"
paquetes <- c(
  "shiny" = "1.14.0",   # versión en la computadora original
  "shinydashboard" = "0.7.3",   # versión en la computadora original
  "R6" = "2.6.1",   # versión en la computadora original
  "yaml" = "2.3.12",   # versión en la computadora original
  "jsonlite" = "2.0.0",   # versión en la computadora original
  "digest" = "0.6.39",   # versión en la computadora original
  "shinyFiles" = "0.9.3",   # versión en la computadora original
  "fs" = "2.1.0",   # versión en la computadora original
  "magick" = "2.9.1",   # versión en la computadora original
  "ragg" = "1.5.2",   # versión en la computadora original
  "systemfonts" = "1.3.2"   # versión en la computadora original
)

cat("\n=== Instalando paquetes para Mis Fotos de Viaje ===\n")
cat("R en esta computadora:", R.version.string, "| R en la original:", version_r_original, "\n\n")
if (getRversion() < "4.1.0") stop("Se necesita R 4.1 o más nuevo. Instale una versión reciente de R.")

faltan <- names(paquetes)[!vapply(names(paquetes), requireNamespace, logical(1), quietly = TRUE)]
if (length(faltan)) {
  cat("Instalando:", paste(faltan, collapse = ", "), "\n(esto puede tardar varios minutos)\n\n")
  install.packages(faltan, dependencies = c("Depends", "Imports", "LinkingTo"))
}

cat("\n=== Revisión final ===\n")
ok <- TRUE
for (p in names(paquetes)) {
  if (requireNamespace(p, quietly = TRUE)) {
    v <- as.character(utils::packageVersion(p))
    cat(sprintf("  ✔ %-14s %-10s (original: %s)\n", p, v, ifelse(nzchar(paquetes[[p]]), paquetes[[p]], "-")))
  } else {
    ok <- FALSE
    cat(sprintf("  ✖ %-14s NO SE PUDO INSTALAR\n", p))
  }
}
if (ok) {
  cat("\n✅ Listo. Todos los paquetes están instalados.\n")
  cat("   Para abrir la app use '3_abrir_la_app' o en R: shiny::runApp('<carpeta de la app>', launch.browser = TRUE)\n\n")
} else {
  cat("\n⚠ Algunos paquetes no se instalaron. Revise su conexión a internet y vuelva a correr este script.\n")
  if (Sys.info()[["sysname"]] == "Linux")
    cat("   En Linux, 'magick' y 'ragg' necesitan: sudo apt install libmagick++-dev libfontconfig1-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev\n")
}
