# DSA Interactive Academy

An R Shiny app for Meta / Google interview preparation: step-through visualisers for every core
data-structure and algorithm topic, a local Python judge with 63 LeetCode-style problems, mock
interviews, an AI-assisted coding round, code-reading drills, behavioural (STAR) and system-design
practice, saved progress, and diagram export (PNG / SVG / PDF / HTML / GIF / JSON) to a local
folder or Google Drive.

## Run it

```r
install.packages(c("shiny", "shinydashboard", "plotly", "DT", "jsonlite", "later", "bigrquery"))
install.packages("googledrive")   # optional — only for saving diagrams straight to Google Drive
shiny::runApp("path/to/this/folder")
```

Python 3.8+ must be on the PATH (or set `Sys.setenv(DSA_PYTHON = "C:/Python312/python.exe")`
before launching) for the judge, the AI-assisted round and "Run it" in Code Reading.
Code runs **on your own computer** — run the app locally, not on a shared server.

### Where progress is saved: Google BigQuery

Every record (submissions, drafts, time on task, reviews, quizzes, mock interviews, AI-round, code-reading,
behavioural and design attempts, STAR stories, settings, export history) is stored in BigQuery, in 14 tables
named `dsa_*` in one dataset (default project `atera-2`, dataset `business_strategy`).

* **Connect automatically:** put the service-account `.json` key in `C:/111_SecA/_q_api` (Windows) or in the folder
  named by `LAT_CRED_DIR`, or point `DSA_BQ_KEY_FILE` / `ATERA_BQ_KEY_FILE` / `GOOGLE_APPLICATION_CREDENTIALS` at it.
* **Or connect by hand** in **APIs › BigQuery** (upload or paste the key, change project / dataset / prefix).
* Override defaults with `DSA_BQ_PROJECT`, `DSA_BQ_DATASET`, `DSA_BQ_PREFIX`, `DSA_BQ_LOCATION`.
* The service account needs *BigQuery Job User* on the project and *BigQuery Data Editor* on the dataset.
* Connecting creates the dataset if needed, runs `CREATE TABLE IF NOT EXISTS` for missing tables and
  `ALTER TABLE … ADD COLUMN IF NOT EXISTS` for missing columns. Nothing existing is dropped or rewritten.
* All tables are read in one query at connect; pages read from memory. Changes are written as one
  `BEGIN TRANSACTION … COMMIT` script a few seconds after you act (a minute for autosaved drafts and
  time on task), when a browser tab closes and when the app stops. The sidebar light shows the state.

`data/` next to the app (or `DSA_DATA_DIR`) only holds diagram exports and an optional Google Drive key — no database.

## Layout

| Path | What it is |
|---|---|
| `app.R` | Catalogue of pages, sidebar, server wiring |
| `global.R` | Palette, shared UI helpers, step player, quiz engine, topic problem lists |
| `modules/mod_*.R` | One module per page |
| `practice/runner.py`, `problems.json`, `build_bank.py`, `bank/` | Judge and problem bank (rebuild with `python build_bank.py`) |
| `practice/project_runner.py`, `projects/`, `build_projects.py` | AI-assisted round projects (rebuild / validate with `python build_projects.py`) |
| `practice/reading/` | Code-reading exercises (`python build_reading.py` re-validates answers by running them) |
| `practice/exporter.R`, `modules/mod_drive.R`, `www/js/export.js` | Diagram export and the Google Drive settings page (APIs › Google Drive) |
| `www/` | CSS, Ace editor, export libraries (all bundled for offline use) |

## Google Drive exports

Open **APIs › Google Drive**. Choose *Service account* (upload the JSON key; share the target folder or
shared drive with the service-account e-mail — service accounts have no storage of their own, so use a
shared drive or a folder owned by a user) or *OAuth* (your Google account, opens a browser sign-in).
Files are saved as `{app}/{group}/{topic}/{diagram}/{yyyy}-{mm}/{stamp}_{diagram}.{ext}` (editable
template); missing folders are created and cached. Every export is listed in
`{app}/_index/manifest.csv` and `manifest.json`, which other Shiny apps can read — the settings page shows
ready-to-copy R snippets.
