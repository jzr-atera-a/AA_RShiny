# Changes since the previous DaysPlanningFundingTravel.zip

Nothing was removed. The code is 48 KB larger than in the previous zip: 1,135,617 bytes now, against 1,087,458 bytes before. The zip file is smaller only because it holds 88 files instead of 205. Every file in a zip carries its own headers, and small files compress less well, so fewer files means a smaller zip.

## Why there are fewer files

1. **One file per tab (requested restructure).** Each tab used to be a folder with three files: `manifest.yml`, `ui.R` and `server.R`. Each tab is now one file, `modules/<Tab group>/<tab_id>.R`, with the manifest as a header comment at the top. 61 tab folders with 183 files became 61 files. `R/module_loader.R` was rewritten to read this layout. `STRUCTURE.md` explains it.
2. **Shared Bulk Import and Browse.** The Bulk Import and Browse tabs of Day Planner, Diet Planner, Exercise Tracker and Funding Programmes were eight near-copies of the same code. They now share one implementation in `R/utils_suite_tabs.R`, and each suite's own texts, table, sort order and parser are set there. Each of these tab files is now a short stub that calls the shared code.

## Checks against the previous zip

- In 47 of the 62 old tab folders, every code line of `ui.R` and `server.R` is present unchanged in the new tab file.
- In 7 tabs, one closing line gained a comma so the new Google Drive box could follow it.
- In 2 tabs, `source("R/utils_calendar_export.R")` moved into `global.R`, so the file loads once at start-up instead of once per session.
- In the 8 shared Bulk Import and Browse tabs, every text, label, table name, sort order, parser and upload function of each suite is still present. The text is now set per suite in `R/utils_suite_tabs.R`.
- `app.R` dropped lines that repeated the first line's clean-up, and an empty `onSessionEnded` handler that did nothing.
- `safe_sql_escape` now escapes backslashes before quotes. This is a bug fix.
- `www/css/global.css` and `R/utils_local_creds.R` contain every line of the previous version.

## What was added

- **Google Drive saving for diagrams.** These files are new: `R/utils_gdrive.R`, `R/utils_diagram.R` (writes PNG, PDF, SVG, HTML and GIF), `R/utils_drive_export.R`, and the API Configuration > Google Drive tab (`modules/API Configuration/gdrive_api_config.R`).
- **A "Save Diagrams to Google Drive" box** on the diagram tabs: Day Planner, Diet Planner, Exercise Tracker (including Muscle Map, Progress, Log and Programme), Events Scheduling, Funding Programmes and Travel Planning. Files are saved to `<root>/<Tab group>/<Tab>/<Subject>/<diagram>.<format>`.
- `R/utils_suite_tabs.R`, `R/_disable_autoload.R` and `STRUCTURE.md`.
