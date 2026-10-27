#!/bin/bash
cd "$(dirname "$0")/.."
RSCRIPT="$(command -v Rscript)"
[ -z "$RSCRIPT" ] && RSCRIPT=/Library/Frameworks/R.framework/Resources/bin/Rscript
echo "Abriendo Mis Fotos de Viaje en el navegador... (no cierre esta ventana mientras usa la app)"
"$RSCRIPT" -e "shiny::runApp('.', launch.browser = TRUE)"
