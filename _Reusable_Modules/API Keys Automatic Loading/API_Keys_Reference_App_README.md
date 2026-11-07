# Reference app: load API keys from a local folder (Windows), with manual fallback and a sidebar status box

A minimal R Shiny app (shinydashboard). It shows one pattern to reuse in other R Shiny apps:

1. At start-up, the app looks for the API keys in a local folder and connects by itself.
2. If a key isn't there, or the app isn't on Windows, the API Configuration tab lets the user load it by hand.
3. A sidebar box shows each API as green, amber or red.

Covers **BigQuery** (service-account JSON) and **Claude** (Anthropic API key). Adding another API is described at the end.

## Run it
```r
install.packages(c("shiny", "shinydashboard", "R6", "jsonlite", "httr", "bigrquery"))
shiny::runApp("api_keys_reference_app")
```
Tests (no Windows, no real keys, no network needed): `Rscript tests/test_keys.R` from the app folder. 16 checks.

## The key folder
| | |
|---|---|
| Folder | `C:/111_SecA/_q_api` on Windows. On any OS, the folder named in `LAT_CRED_DIR` is used instead. Not Windows and no `LAT_CRED_DIR`: nothing is searched. |
| BigQuery | Any `*.json` with `"type": "service_account"` and a `private_key`. If there are several, the one whose `project_id` is the app's project wins, else the newest. Other `.json` files are ignored. |
| Claude | `ap_claude_1_line.txt`: its first non-empty line, trimmed. |

Order of sources (the first that works wins; each is skipped if that API is already connected):
1. The local folder.
2. Environment variables: `ATERA_BQ_KEY_FILE` / `GOOGLE_APPLICATION_CREDENTIALS` for BigQuery, and `ANTHROPIC_API_KEY` (+ `CLAUDE_MODEL`) for Claude.
3. The API Configuration tab (always available, also to switch to another key).

## Files (copy all four into another app's `R/` folder)
| File | What it holds |
|---|---|
| `R/local_creds.R` | `cred_dir()`, `local_credentials(dir, project)`, `mask_key()`. Pure functions with no Shiny. |
| `R/api_manager.R` | `ApiManager` (R6): `authenticate_bigquery(json_path=, json_text=)`, `bq_query()`, `set_claude_credentials()`, `call_claude()`, `test_claude()`. Fields: `bq_authenticated`, `claude_authenticated`, `claude_tested`. |
| `R/startup_keys.R` | `startup_keys(api)`: runs the order above, returns and stores status texts; `cred_status()` reads them. |
| `R/mod_api_config.R` | `bq_config_ui/server`, `claude_config_ui/server` (banner + file/paste/typed inputs), `api_status_ui/server` (sidebar lights). |

## Adding it to another app
1. Copy the four files into `R/` and source them in the app (`for (f in list.files("R", full.names = TRUE)) source(f)`).
2. If the app already has its own api manager, keep it. Check its names with `grep -n "authenticate\|authenticated" R/*.R` and either:
   - rename the calls in `startup_keys.R`; or
   - add the four fields and methods it uses: `bq_project_id`, `bq_authenticated`, `authenticate_bigquery(json_path=)`, `claude_authenticated`, `set_claude_credentials()`.
3. Create the shared object once: `api <- ApiManager$new()`.
4. In `server`, call `startup_keys(api)` **first**, before any module that reads BigQuery or calls Claude.
5. Put `bq_config_ui("bq")` and `claude_config_ui("claude")` in the configuration tab, and `api_status_ui("status")` in `dashboardSidebar()` after `sidebarMenu()`. Then call the three servers.
6. Change the defaults to your app: project `atera-2`, dataset `business_strategy`, and the model list.

## Rules to keep
- **Keys are never copied, written to BigQuery or files, or printed.** Logs show the file path; the UI shows a masked key (`sk-ant-...WXYZ`). The paste boxes are cleared after use.
- **The manual inputs stay** even when a key was found, so the user can switch keys.
- **Loading a Claude key does not prove it works.** The light stays amber ("not tested") until Test connection makes one tiny call. BigQuery is green only after `bq_project_datasets()` succeeds.
- **The api fields are plain R6 fields, not reactive.** The sidebar re-checks every 3 s with `invalidateLater(3000)`, so a key loaded later turns the light green.
- **Show a placeholder while start-up runs.** `startup_keys()` runs synchronously inside `server`, so the sidebar output is empty until it finishes. CSS `:empty::before` shows "connecting..." in the meantime.
- **`%%` in `sprintf`.** A CSS percent inside `sprintf()` must be written `%%`.
- **Forward slashes.** Use `C:/...` paths in R on Windows.

## Adding another API (example: a broker key)
1. Add a finder in `local_creds.R`, for example the first `*.json` whose name contains `capital` and that has `api_key`.
2. Add a block in `startup_keys()` that calls your client's login and sets `st$<name>`.
3. Copy the Claude config module as a template for its tab.
4. Add one `light()` line in `api_status_server`.
