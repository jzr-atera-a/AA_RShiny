# 📷 Travel Photo Selector (R Shiny, modular)

The whole interface is in **Mexican Spanish** (usted form), including the Admin tab, pop-ups, the folder dialog and the CSV/print files. This README stays in English for whoever maintains it.

An app for an elderly user to tick the travel photos they want printed. It is built on
the same modular architecture and purple look as the *DALL-E Image Generator* template
(module registry + `ModuleLoader`, shared R6 manager, `www/css/global.css`).

## Quick start
```r
setwd("path/to/Travel_Photo_Selector")
source("install_packages.R")          # once
shiny::runApp(launch.browser = TRUE)
```
1. Open **Administrador**, enter code **718**.
2. **Buscar carpeta principal…** (or paste the path) → **Escanear carpetas y fotos**.
3. The user works in **Elegir mis fotos** and checks progress in **Mis fotos elegidas**.

### Moving the app to a new computer (no R installed)
On the computer where the app already works, run `source("revisar_e_instalar.R", encoding = "UTF-8")` from the app folder (or press *Source* in RStudio). It:
* prints and saves `entorno_actual.txt` with the R version, the RStudio version (when it can be detected) and each package version;
* creates `instalar_en_computadora_nueva/` with `1_instalar_todo_Windows.bat` (installs the same R version with winget, falling back to the latest, plus RStudio and the packages), `1_instalar_todo_Mac.command`, `2_instalar_paquetes.R`, `3_abrir_la_app_*` launchers and `LEEME.txt` (step-by-step guide in Spanish).

Copy the whole app folder to the new computer and double-click `1_instalar_todo_…`.

`instalar_paquetes_versiones_exactas.R` installs the **exact package versions of the original computer** (recorded at the top of the file) without Rtools: it uses the Posit Package Manager CRAN snapshot of the reference date (pre-built Windows/Mac binaries). Order: background dependencies first (install.packages never upgrades already-installed dependencies), then `R6, digest, jsonlite, yaml, fs → systemfonts (→ textshaping) → ragg → magick → shiny → shinydashboard, shinyFiles`; finally every package is loaded in a clean R session and a report `resultado_instalacion.txt` is written. Restart R before running it. `revisar_e_instalar.R` generates `2_instalar_paquetes.R` from this same file with the current computer's versions.

Want to try it first? Run `Rscript tools/make_demo_photos.R` and point the app to `~/Demo_Travel_Photos`.

## Expected folder structure
```
Main folder/
├── México/                 ← country (level 1)
│   ├── Cancún/             ← city / region / event (level 2)
│   │   ├── IMG_0001.jpg
│   │   └── Day 2/…         ← deeper folders count for "Cancún"
│   └── Ciudad de México/
└── España/
    ├── Barcelona/
    └── Boda de Lucía/
```
* Photos placed directly in a country folder appear as "(Fotos sueltas en la carpeta del país)".
* Photos placed directly in the main folder are ignored, and the scan reports how many.
* Supported: jpg, jpeg, png, gif, bmp, webp, tif/tiff, heic/heif (the last three need `magick`).

## Features
| Tab | What it does |
|---|---|
| **Choose My Photos** | Two horizontal sub-tabs. **1. Elegir viaje** (opens by default): counters (photos of the country, chosen X of the country limit, cost), country → place drop-downs (active places only), matrix size **2×2, 3×2 (3 columns × 2 rows) or 3×3**, filter, a **photo size slider (60–100 %)** that applies instantly and is remembered (without a saved value it starts at 80 % inside the RStudio window and 100 % in a browser), suggested-per-place table, and the **Ver fotos** button, which applies the choice, hides the sidebar menu (☰ brings it back) and switches to **2. Fotos**: one summary row (chosen vs recommended for that place) + the photo matrix with large tick buttons and a "Ver grande" view. |
| **Suggested per place** | The country limit is shared in proportion to the photos of the **active** places (largest-remainder method). Places whose name starts with *Museo(s), Galería(s)/Galeria(s), Vuelo(s)* are capped at a recommended maximum (default **8**); the surplus goes to the other places. Example: 800 + 200 photos, limit 50 → **40 + 10**; 600 + "Museo" 400 → **42 + 8**. |
| **My Chosen Photos** | Chosen and cost per country plus the total, a gallery of the chosen photos with an un-tick button, and a CSV download. |
| **Admin (code 718)** | Top bar with **Bloquear Administrador** (locks the tab again; the code is needed to re-enter, and it is always locked when the app starts). **🖨 Imprimir las fotos elegidas** box at the top: summary, step 1 choose where to save (browse or type the path), step 2 **Copiar fotos ahora**, then an *Abrir la carpeta Imprimir* button. Main folder (browse or type) and scan; **2. Países, lugares y límites**: default limit per country (50), optional limit per country, recommended maximum for museums/galleries/flights (8), a tick box per city/region/event to include/exclude it, and **Aplicar cambios** (nothing changes until pressed; a banner shows pending vs applied); cost per photo (5 MXN); overview table; selection CSV; clearing selections. |
| **Copiar fotos para imprimir** (Admin) | From the top box the admin picks a location (options such as replace/update and the watermark live in section 3); the app creates `Imprimir/<País>/` there, with files named `<Lugar> - <archivo>.jpg` (name clashes get " (2)"), plus `lista_para_imprimir.csv` and `resumen_del_pedido.csv`. Modes: *replace everything* (asks for confirmation) or *only add/update*. The location may not be inside the main photo folder. Originals are never modified. |
| **Sello de agua** (optional) | Writes `País – Ciudad/Región/Evento` in the bottom-right corner of the **copies**. Controls: typeface (bundled **Atkinson Hyperlegible**, **Andika**, **Lexend**; plus Verdana/Tahoma/Arial/DejaVu Sans if installed), size (2–10 % of the photo's short side, with the approximate mm on a 10×15 cm print), bold, and three high-contrast styles. Live preview on a chosen photo. All settings are remembered. |

The **country** limit is a hard stop; the museum/gallery/flight maximum is only a recommendation. Photos chosen earlier in a place that is later de-activated stay saved and keep counting (totals, cost, printing).

The limit is a hard stop. When a country reaches it, a friendly message asks the user to un-tick a photo first. Going over the *suggested* number for a place only shows a gentle notice.

## Persistence (`data/`)
| File | Content |
|---|---|
| `config.json` | main folder, default limit, per-country limits, inactive places, museum/gallery/flight maximum, cost, currency, grid layout, photo size, last country/place viewed, Imprimir location and sello de agua settings |
| `selections.json` | every ticked photo. It is saved on each click and keyed by main folder. |
| `inventory.rds` | result of the last scan, so no rescan is needed on restart |
| `thumb_cache/` | cached previews (EXIF-rotated). It is safe to delete. |
| `app.log` | activity / error log |

If the app restarts with the same main folder, everything comes back as it was. Rescanning
keeps the selections (it only drops photos that no longer exist on disk). Changing the main
folder hides the old selections; switching back to that folder restores them.

## Structure
```
Travel_Photo_Selector/
├── app.R  global.R  install_packages.R  revisar_e_instalar.R  instalar_paquetes_versiones_exactas.R  README.md
├── R/ module_loader.R  utils_common.R  utils_photos.R (PhotoManager R6)  utils_watermark.R
├── modules/_module_registry.yml
│   ├── photo_explorer/  ui.R server.R
│   ├── my_selection/    ui.R server.R
│   └── admin_settings/  ui.R server.R
├── www/css/global.css  www/js/app.js  www/fonts/ (TTF + OFL licences)
└── tools/make_demo_photos.R
```
To change the admin code, edit `admin_code` in `R/utils_photos.R`.

## Fonts
The watermark fonts in `www/fonts/` are under the SIL Open Font License (licence files included), so they can be redistributed with the app.
They are loaded with `systemfonts` + `ragg`, so they work the same on Windows, Mac and Linux without installing anything.
