# Aplicación R Shiny — Tesis CPM

**Integración progresiva de elementos de microelectrónica y robótica en un sistema de navegación autónoma con Realidad Aumentada**
José Francisco Zubizarreta Rodríguez · Colegio y Proyectos en Microelectrónica, S.C. · Ciudad de México, 2026

## Ejecutar
```r
install.packages(c("shiny", "shinydashboard", "plotly", "DT", "jsonlite"))
shiny::runApp("CPM_Tesis_Shiny")
```
(O abrir `app.R` en RStudio y pulsar *Run App*.)

## Contenido
- `app.R` — tablero (shinydashboard) con 15 pestañas: Inicio, capítulos 1–8, Laboratorio de seguimiento, Análisis de pruebas en R (sección 6.6.1), Plan de estudios CPM, Bibliografía, Apéndices técnicos (A: modelos 3D; C–F: los 36 listados de programas con búsqueda y descarga; algoritmos 1–6) y Anexos (B, G, abreviaturas y nomenclatura).
- `modulos/datos.R` — tablas de la tesis; `modulos/calculos.R` — ecuaciones y algoritmos (velocidad serie, ADC, Timer0/PWM, MD22, Menger, Ackermann, Kalman, ARC/SPLINE, generador a 5 Hz, simulador de seguimiento); `modulos/tab_*.R` — interfaz y servidor de cada pestaña.
- `data/m25_londres.geojson` — mapa del M25 del proyecto; `data/ejemplo_seguimiento_simulado.csv` — CSV de ejemplo **simulado**; `data/listados.json` — los 36 listados de los apéndices C a F, extraídos de la tesis.
- `www/` — estilo e imágenes extraídas de la tesis.

Las simulaciones están marcadas como ilustrativas; los resultados medidos que se citan provienen de la tesis.
