# How-to: auto-load API keys from `C:\111_SecA\_q_api\` and show connection status in the sidebar (R Shiny)

**Audience:** other Claude instances editing R Shiny + shinydashboard apps in this workspace. These apps use an R6 `api_manager` for BigQuery and Claude.
**Reference implementation:** `trading_analysis_lat_2026_u3_sheets` (U3 app), 27 Oct 2026.
**Goal:**
- On Windows, the app finds both keys on its own when it starts.
- If a key isn't found, or the app isn't on Windows, the API Configuration tabs still let the user load the key by hand.
- A sidebar box shows whether each API is ready, so the user knows why data or Claude isn't available yet.

---

## 1. Rules (keep these)

- **Keys never leave the folder.** They are not copied, not written to BigQuery and not printed in full. The console prints only the file path; the UI shows a masked key (`sk-ant-...WXYZ`).
- **Order of sources** (the first one that works wins, and each one is skipped if that API is already connected):
  1. Local folder: `C:/111_SecA/_q_api` on Windows only, or the folder in `LAT_CRED_DIR` on any OS.
  2. Environment variables: `ATERA_BQ_KEY_FILE` / `GOOGLE_APPLICATION_CREDENTIALS` for BigQuery, `ANTHROPIC_API_KEY` (+ `CLAUDE_MODEL`) for Claude.
  3. Manual: the API Configuration tabs (file upload / paste). They are always available, so the user can still switch to another key.
- **Don't change the existing manual auth code.** Only add the auto-load in front of it.
- **Expected files in the folder:**
  - BigQuery: any `*.json` whose content has `"type": "service_account"` and a `private_key`. If there are several, pick the one whose `project_id` matches the app's project (here `atera-2`), otherwise the newest. Other `.json` files are ignored.
  - Claude: `ap_claude_1_line.txt`. Use its first non-empty line, trimmed.

---

## 2. New file `R/utils_local_creds.R`

Source it from `global.R` (`source("R/utils_local_creds.R")`), after the file that defines `tr_or` (or define a `%||%`-style helper yourself).

```r
tr_cred_dir_default <- "C:/111_SecA/_q_api"
tr_cred_dir <- function() {
  d <- Sys.getenv("LAT_CRED_DIR", "")
  if (nzchar(d)) d else if (.Platform$OS.type == "windows") tr_cred_dir_default else ""
}

tr_local_credentials <- function(dir = tr_cred_dir(), project = "atera-2") {
  out <- list(dir = dir, json_path = NA_character_, json_project = NA_character_,
              claude_key = NA_character_, notes = character(0))
  if (!nzchar(dir)) { out$notes <- "Not Windows: no local key folder is searched (set LAT_CRED_DIR to use one)."; return(out) }
  if (!dir.exists(dir)) { out$notes <- sprintf("Folder %s not found.", dir); return(out) }

  # BigQuery: service-account JSON (matching project first, else newest)
  js <- list.files(dir, pattern = "\\.json$", full.names = TRUE, ignore.case = TRUE)
  info <- lapply(js, function(f) {
    j <- tryCatch(jsonlite::fromJSON(f, simplifyVector = TRUE), error = function(e) NULL)
    if (is.list(j) && identical(j$type, "service_account") && !is.null(j$private_key))
      data.frame(path = f, project = tr_or(j$project_id, ""), mtime = file.mtime(f), stringsAsFactors = FALSE) else NULL
  })
  info <- do.call(rbind, Filter(Negate(is.null), info))
  if (!is.null(info) && nrow(info)) {
    info <- info[order(info$project != project, -as.numeric(info$mtime)), , drop = FALSE]
    out$json_path <- info$path[1]; out$json_project <- info$project[1]
    if (nrow(info) > 1) out$notes <- c(out$notes, sprintf("%d service-account keys found; using %s.", nrow(info), basename(info$path[1])))
  } else out$notes <- c(out$notes, sprintf("No service-account .json key in %s.", dir))

  # Claude: single line in ap_claude_1_line.txt
  kf <- file.path(dir, "ap_claude_1_line.txt")
  if (file.exists(kf)) {
    k <- trimws(readLines(kf, warn = FALSE)); k <- k[nzchar(k)]
    if (length(k)) out$claude_key <- k[1] else out$notes <- c(out$notes, "ap_claude_1_line.txt is empty.")
  } else out$notes <- c(out$notes, sprintf("No ap_claude_1_line.txt in %s.", dir))
  out
}

tr_mask_key <- function(k) if (is.na(k) || nchar(k) < 12) "" else
  paste0(substr(k, 1, 7), "...", substr(k, nchar(k) - 3, nchar(k)))

# status texts set at start-up by app.R, read by the API tabs
u3_cred_status <- function() tryCatch(get(".u3_cred_status", envir = .GlobalEnv), error = function(e) list())
```

Notes:
- Use forward slashes (`C:/...`). R on Windows accepts them, and there's no backslash escaping to get wrong.
- `.Platform$OS.type == "windows"` is the OS check. On Linux or Posit Connect, nothing is searched unless `LAT_CRED_DIR` is set.

---

## 3. `app.R` server: auto-connect at start-up

Put this at the top of `server`, **before** the API config modules and any module that reads BigQuery. It is wrapped in `local()` and is safe to run once per session; the `isTRUE(...authenticated)` checks skip work that is already done.

```r
local({
  st <- list(bq = NULL, claude = NULL, dir = tr_cred_dir())
  lc <- tryCatch(tr_local_credentials(), error = function(e) list(notes = conditionMessage(e)))
  if (length(lc$notes)) cat("[Keys]", paste(lc$notes, collapse = " "), "\n")

  # 1a. BigQuery from the folder
  if (!is.na(tr_or(lc$json_path, NA)) && !isTRUE(api_manager$bq_authenticated)) {
    ok <- tryCatch({ api_manager$authenticate_bigquery(json_path = lc$json_path); TRUE },
                   error = function(e) { cat("[BigQuery] key from", lc$json_path, "failed:", conditionMessage(e), "\n"); FALSE })
    st$bq <- if (ok) sprintf("Connected automatically with %s (found in %s).", basename(lc$json_path), lc$dir)
             else sprintf("A key was found (%s) but the connection failed: see the Debug Console.", basename(lc$json_path))
  }
  # 1b. Claude from the folder
  if (!is.na(tr_or(lc$claude_key, NA)) && !isTRUE(api_manager$claude_authenticated)) {
    m <- Sys.getenv("CLAUDE_MODEL", "")
    api_manager$set_claude_credentials(lc$claude_key, model = if (nzchar(m)) m else NULL)
    cat("[Claude] API key taken from", file.path(lc$dir, "ap_claude_1_line.txt"), "\n")   # path only, never the key
    st$claude <- sprintf("Key loaded automatically from %s (%s). Press Test Connection to check it.",
                         file.path(lc$dir, "ap_claude_1_line.txt"), tr_mask_key(lc$claude_key))
  }
  assign(".u3_cred_status", st, envir = .GlobalEnv)

  # 2. environment variables (unchanged fallback)
  key <- Sys.getenv("ATERA_BQ_KEY_FILE", Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS", ""))
  if (nzchar(key) && file.exists(key) && !isTRUE(api_manager$bq_authenticated))
    tryCatch(api_manager$authenticate_bigquery(json_path = key), error = function(e) cat("[BigQuery] automatic sign-in failed:", conditionMessage(e), "\n"))
  k <- Sys.getenv("ANTHROPIC_API_KEY", "")
  if (nzchar(k) && !isTRUE(api_manager$claude_authenticated)) {
    m <- Sys.getenv("CLAUDE_MODEL", ""); api_manager$set_claude_credentials(k, model = if (nzchar(m)) m else NULL)
  }
})
```

**Adapt:** the method and field names (`authenticate_bigquery(json_path=)`, `set_claude_credentials()`, `bq_authenticated`, `claude_authenticated`) are this app's `api_manager` API. Check yours with `grep -n "authenticate\|authenticated" R/utils_api_manager.R`.

---

## 4. API Configuration tabs: green or amber banner

In each config module UI (BigQuery box and Claude box), add `uiOutput(ns("auto_key"))` as the first element. In the module server:

```r
output$auto_key <- renderUI({
  st <- if (exists("u3_cred_status", mode = "function")) u3_cred_status() else list()
  txt <- st$bq            # use st$claude in the Claude module
  d <- if (is.null(st$dir)) "" else st$dir
  if (!is.null(txt))
    tags$div(style = "background:#ecfdf5; border:1px solid #a7f3d0; color:#065f46; border-radius:8px; padding:8px 10px; margin-bottom:10px; font-size:12.5px;",
             icon("key"), " ", txt, " You can still load another key below.")
  else
    tags$div(style = "background:#fffbeb; border:1px solid #fde68a; color:#92400e; border-radius:8px; padding:8px 10px; margin-bottom:10px; font-size:12.5px;",
             if (nzchar(d)) paste0("No service-account .json key found in ", d, ": load the key file or paste it below.")
             else "This is not Windows, so no local key folder is searched: load the key file or paste it below.")
})
```

Leave the existing `fileInput` / `textAreaInput` / `passwordInput` and their buttons as they are.

---

## 5. Sidebar "API CONNECTIONS" box

**UI** (`dashboardSidebar`, after `sidebarMenu(...)` and any existing sidebar boxes):

```r
tags$style(HTML("#api_status:empty::before { content: 'BigQuery: connecting...   Claude: connecting...'; color:#fbbf24; font-size:11.5px; }")),
tags$div(style = "padding:10px; background-color:#2c3e50; margin-top:6px;",
  tags$div(style = "color:#b2e0db; font-size:11px; font-weight:700; margin-bottom:4px;", "API CONNECTIONS"),
  uiOutput("api_status"))
```

Why the CSS `:empty::before`:
- The start-up auth runs synchronously inside `server`, so `renderUI` sends nothing until it finishes.
- While the output is still empty, the browser shows the amber "connecting..." text.
- The first render replaces it.

**Server** (in `app.R`, next to the other top-level outputs):

```r
output$api_status <- renderUI({
  invalidateLater(3000)                       # re-check, so a key loaded later in API Configuration turns green
  st <- u3_cred_status()
  light <- function(name, ok, wait, txt) {
    col <- if (ok) "#22c55e" else if (wait) "#fbbf24" else "#ef4444"
    tags$div(style = "display:flex; align-items:flex-start; gap:6px; margin:3px 0; font-size:11.5px; color:#ecf0f1;",
      tags$span(style = sprintf("display:inline-block; width:10px; height:10px; border-radius:50%%; background:%s; margin-top:3px; flex:none;", col)),
      tags$span(tags$b(name, ": "), txt))
  }
  bq <- isTRUE(api_manager$bq_authenticated); cl <- isTRUE(api_manager$claude_authenticated)
  bq_fail <- !bq && !is.null(st$bq)
  tagList(
    light("BigQuery", bq, FALSE, if (bq) "ready" else if (bq_fail) "key found, connection failed (see Debug Console)"
                                  else "not connected: API Configuration > BigQuery"),
    light("Claude", cl, FALSE, if (cl) "ready (key loaded)" else "no key: API Configuration > Claude API"))
})
```

How it works:
- The `api_manager` fields are plain R6 fields, not reactive, so `invalidateLater(3000)` is what picks up changes.
- In `sprintf`, the CSS percent must be written as `%%`.
- Claude "ready" means the key is loaded. It doesn't prove the key is valid. To show that too, store the result of the last call or test in `api_manager` and add a third state.

---

## 6. Debug Console output to expect (Windows, both keys present)

```
=== [BigQuery] authenticate_bigquery() START ===
...
=== [BigQuery] authenticate_bigquery() END (success) ===
[Claude] API key taken from C:/111_SecA/_q_api/ap_claude_1_line.txt
```

If there is more than one key: `[Keys] 2 service-account keys found; using atera-2-xxxx.json.`

---

## 7. Testing without Windows

1. Make a temp folder with a fake service-account JSON (`{"type":"service_account","project_id":"atera-2","private_key":"x"}`), a non-key `.json`, and `ap_claude_1_line.txt` containing one line.
2. Run with `LAT_CRED_DIR=/path/to/folder`.
3. `tr_local_credentials()` must pick the `atera-2` key, ignore the other `.json`, and return the trimmed Claude key.
4. In the browser, the Claude banner should be green with the masked key.
5. BigQuery will show "key found, connection failed", because the fake key can't sign in. A real sign-in can only be confirmed on the user's PC.

---

## 8. Checklist for replicating in another app

- [ ] Add `R/utils_local_creds.R` and source it in `global.R`.
- [ ] Add the `local({...})` start-up block at the top of `server`, before any module that reads BigQuery.
- [ ] Add `uiOutput(ns("auto_key"))` and its `renderUI` to both API config modules.
- [ ] Add the sidebar box (UI + CSS + `output$api_status`).
- [ ] Check the `api_manager` method and field names in this app.
- [ ] Confirm keys are never printed or stored; only the path and masked key appear.
- [ ] Document `LAT_CRED_DIR` and the folder in the app's deploy notes (here `DEPLOY_POSIT.md`).
