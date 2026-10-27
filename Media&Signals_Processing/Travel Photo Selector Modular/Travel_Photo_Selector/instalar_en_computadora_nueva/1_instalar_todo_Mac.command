#!/bin/bash
# MIS FOTOS DE VIAJE - instalar paquetes en Mac (doble clic)
cd "$(dirname "$0")"
RSCRIPT="$(command -v Rscript)"
[ -z "$RSCRIPT" ] && [ -x /Library/Frameworks/R.framework/Resources/bin/Rscript ] && RSCRIPT=/Library/Frameworks/R.framework/Resources/bin/Rscript
if [ -z "$RSCRIPT" ]; then
  echo "R no está instalado. Se abrirán las páginas de descarga de R (la computadora original tenía R 4.4.0) y de RStudio."
  echo "Instale los dos (siguiente, siguiente...) y luego vuelva a dar doble clic a este archivo."
  open "https://cloud.r-project.org/bin/macosx/"
  open "https://posit.co/download/rstudio-desktop/"
  read -p "Presione Enter para cerrar..."
  exit 1
fi
"$RSCRIPT" 2_instalar_paquetes.R
[ -d /Applications/RStudio.app ] || { echo "(RStudio no está instalado; es opcional para usar la app)"; open "https://posit.co/download/rstudio-desktop/"; }
read -p "Presione Enter para cerrar..."
