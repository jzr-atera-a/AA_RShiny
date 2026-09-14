# Unified Suite Architecture & Reuse Guide

This document explains how this app is built, why it's built that way, and how to extend it
with a new "suite" that follows the same pattern: **generate structured content via the Claude
API, store it in BigQuery, visualize/edit it back**. It's written so a future Claude session
can use it as a blueprint without re-deriving the design from scratch.

---

## 1. What this app actually is

It's **one Shiny app containing several independent "suites"** — Book Summary, Flex Table,
Mind Map, Knowledge Graph — each with its own BigQuery table and its own generate/edit/browse
workflow, but all sharing:

- **One Claude API connection** (API key, model, timeout — configured once)
- **One BigQuery authentication** (one project, one dataset — but each suite gets its own
  table inside it)
- **One design system** (CSS, layout conventions, status/card styling)
- **One deployment** (one Posit Connect app, one URL, one running R process)

The mental model: think of it less as "four apps duct-taped together" and more as **one host
app with pluggable content suites**, each of which could, in principle, be extracted back into
its own standalone app with minimal changes — because that's literally how each one started.

---

## 2. Folder structure & modular architecture

```
app.R                     # entry point, wires up ModuleLoader + shinyApp()
global.R                  # UI/server factories, sidebar grouping, package declarations
R/
  module_loader.R         # discovers modules recursively, sources them
  utils_common.R           # parsing/validation/prompt-building, one section per suite
  utils_api.R               # the shared APIManager R6 class (Claude + BigQuery)
www/css/global.css        # shared design system
modules/
  "API Configuration"/
    bigquery_auth/{manifest.yml, ui.R, server.R}
    claude_api_config/{manifest.yml, ui.R, server.R}
  "Book Summary"/
    generate_summary/{...}
    books_bulk_import/{...}
    add_single/{...}
    books_browse/{...}
    visualizations/{...}
    books_about/{...}
  "Flex Table"/
    generate_table/{...}
    ...
  "Mind Map"/
    ...
  "Knowledge Graph"/
    ...
modules/_module_registry.yml   # THE control center - see below
```

### Module discovery is fully recursive

`R/module_loader.R` finds every `manifest.yml` **anywhere** under `modules/`, regardless of
nesting depth:

```r
manifest_paths <- list.files("modules", pattern = "^manifest\\.yml$",
                              recursive = TRUE, full.names = TRUE)
```

This is what makes the "grouped subfolder" layout possible (`modules/"Flex Table"/generate_table/`
instead of a flat `modules/generate_table/`). **If you ever add a module and it doesn't appear
in the app, the first thing to check is that its `manifest.yml` exists and parses** — the
loader silently skips anything it can't find or parse.

### Every module is exactly 3 files

```
manifest.yml   # id, menu label/icon/tabname, package dependencies, enable/priority defaults
ui.R           # {module_id}_ui <- function(id) { ... }
server.R       # {module_id}_server <- function(id, api_manager) { ... }
```

The function names **must** be `{id}_ui` and `{id}_server` where `id` matches the manifest's
`module.id` field exactly — `global.R` looks these up dynamically by string:

```r
ui_function_name <- paste0(module_id, "_ui")
if (exists(ui_function_name, envir = .GlobalEnv)) { ... }
```

### `_module_registry.yml` — the control center

Two top-level sections:

```yaml
groups:
  - id: api_config
    label: "API Configuration"
    icon: "key"
    expanded: true
    modules: [bigquery_auth, claude_api_config]

  - id: book_summary
    label: "Book Summary"
    icon: "book"
    expanded: false
    modules: [generate_summary, books_bulk_import, add_single, books_browse, visualizations, books_about]
  # ... more groups ...

modules:
  bigquery_auth: { enabled: true, priority: 1, description: "..." }
  # ... one entry per module, controlling enable/disable and ordering ...
```

`groups:` controls the **sidebar structure** (collapsible menu sections, in list order).
`modules:` controls **enable/disable and priority ordering within each group**. A module can
exist on disk but be `enabled: false` here to hide it without deleting code.

`global.R` reads `groups:` directly and builds one collapsible `menuItem()` per group, with
`menuSubItem()` children built dynamically via `do.call()`:

```r
groups <- registry$groups
for (g in groups) {
  group_mods <- g$modules[g$modules %in% enabled_ids]
  sub_items <- lapply(group_mods, function(mid) menuSubItem(...))
  do.call(menuItem, c(list(text = g$label, icon = icon(g$icon), startExpanded = isTRUE(g$expanded)), sub_items))
}
```

---

## 3. API Configuration: one connection, many tables

There are exactly **two** "API Configuration" tabs, shared by every suite:

- **Claude API Config** — API key, model, max tokens, timeout. Set once, used by every suite's
  Generate/Edit tabs via the same `api_manager$call_claude(...)`.
- **BigQuery Setup** — project ID + dataset ID, set once. On "Connect," the app runs a
  `CREATE TABLE IF NOT EXISTS` for **every suite's table**, all in the same project/dataset,
  in a single click.

This means a user never re-enters credentials per suite, and adding a new suite never adds a
new "connect" step — it just adds one more `CREATE TABLE IF NOT EXISTS` to the existing
connect action.

### The non-negotiable safety rule: never destroy existing data

**Every table-creation statement in this app uses `CREATE TABLE IF NOT EXISTS`, wrapped in a
`tryCatch` that silently no-ops if the table already exists.** There is no `CREATE OR REPLACE
TABLE`, no `DROP TABLE`, no `TRUNCATE`, anywhere in the startup/connect path. Every insert uses
`write_disposition = "WRITE_APPEND"`, never `"WRITE_TRUNCATE"`.

```r
create_table_query <- sprintf("
  CREATE TABLE IF NOT EXISTS `%s` (
    id INTEGER, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(), ...
  )", full_table_id)

tryCatch({ bq_project_query(project_id, create_table_query) }, error = function(e) {})
```

**Any new suite you add must follow this exact pattern.** If the table already exists (with
real user data in it), connecting to BigQuery must be a complete no-op for that table — never
alter its schema, never touch its rows, never fail loudly if it's already there.

---

## 4. Independence between suites (the part that's easy to get wrong)

This is the section most worth reading carefully if you're adding a new suite, because **almost
every real bug found while building this app came from insufficiently isolating one suite from
another** when they share one Shiny process.

### Problem: identical method/module names across suites

Each suite originally had its own `browse_data` module, its own `about` module, its own
`APIManager$bq_insert()`, its own `APIManager$bq_get_taxonomy()`. Merged into one R process,
these collide — R can only have one function/method named `browse_data_server`, one method
named `bq_insert`.

**Fix — namespace everything per suite:**

| Generic name (breaks when merged) | Per-suite name |
|---|---|
| `browse_data` (module id) | `books_browse`, `flex_table_browse`, `mindmap_browse`, `kg_browse` |
| `about` (module id) | `books_about`, `flex_table_about`, `mindmap_about`, `kg_about` |
| `bq_insert()` | `bq_insert_books()`, `bq_insert_flex()`, `bq_insert_mindmap()`, `bq_insert_kg()` |
| `bq_get_taxonomy()` | `bq_get_books_taxonomy()`, `bq_get_flex_taxonomy()`, ... |
| `empty_taxonomy()` | `empty_books_taxonomy()`, `empty_flex_taxonomy()`, ... |

### Problem: shinydashboard doesn't lazy-load hidden tabs

Every module's server-side reactive graph is fully alive **the instant the app starts**,
regardless of which tab is currently visible. This has real consequences:

**4a. A shared reactive trigger causes cross-suite reactive storms.** If all suites listened to
one `state_trigger()`, an upload in Knowledge Graph would needlessly re-fire Book Summary's and
Flex Table's dropdown-populating reactives too — even though the user never touched those tabs.
**Fix:** one scoped `reactiveVal` per suite (`state_trigger_books`, `state_trigger_flex`, ...),
each fired only by `trigger_state_update_books()` etc., and each suite's modules only ever
listen to their own.

**4b. Multiple modules within one suite independently querying the same data.** Within Flex
Table alone, both "Generate Table" and "Table Viewer" independently ask for the same
Category/Topic list on load. With 4 suites × 2-4 modules each all doing this simultaneously on
connect, that's a burst of 10+ near-simultaneous BigQuery queries — and since Shiny is
single-threaded, they queue and process one at a time, making the *next* real user click feel
stuck behind a backlog it has nothing to do with.
**Fix:** a taxonomy result **cache** per suite on `APIManager` (`books_taxonomy_cache`, etc.),
invalidated only when that suite's own trigger fires. The first reactive to ask actually queries
BigQuery; every other one in the same batch reuses the cached result instantly.

```r
bq_get_books_taxonomy = function() {
  if (!is.null(self$books_taxonomy_cache)) return(self$books_taxonomy_cache)
  result <- self$bq_query(...)
  self$books_taxonomy_cache <- result
  result
}
```

**4c. A generate→bulk-import handoff buffer shared across suites.** Book Summary and Flex Table
both have a "Copy generated text to Bulk Import" button, implemented via one `reactiveVal`
holding the pending text. Shared, this means generating in one suite and clicking "copy" could
silently overwrite the *other* suite's pending buffer. **Fix:** scoped per suite
(`pending_bulk_text_books`, `pending_bulk_text_flex`), same pattern as the triggers.

### Problem: navigating to the wrong tab after a rename

When a module is renamed for uniqueness (`bulk_import` → `books_bulk_import`), **every string
reference to its old tab name must be found and updated too** — not just the manifest. A
`updateTabItems(session, "sidebar_menu", selected = "bulk_import")` left over from before a
rename will silently navigate to a *different suite's* tab of the same old name. Always grep
the whole codebase for the old name after any rename, not just the module's own files.

### Rule of thumb for any new suite

Before wiring a new suite in, ask: **"if I search this app for `[method name]` or `[module id]`,
does it appear in more than one suite?"** If yes, it needs a suite-specific suffix. This applies
to BigQuery methods, module ids, tabnames used in navigation calls, and any `reactiveVal`
intended to carry cross-module state within one suite.

---

## 5. The generate → store → visualize pattern

Every suite's "Generate" tab follows the same shape, refined over several iterations of real
bugs found in production use:

### 5a. Rules-first prompt construction

The prompt sent to Claude is built in two parts: a **fixed rules block** (output format,
delimiter contract, hard caps, formatting rules) presented **before** the specific request, then
the **specific task** (category/topic/description) after. Giving the model the complete rule
set before the task produces more reliable format adherence than appending rules afterward.

### 5b. A strict, parseable text format

Claude's response uses `[tag]: value` bracket-tagged lines, one block per record, separated by
blank lines — never JSON (avoids escaping/truncation-mid-object issues), never free prose
(unparseable). Multi-value fields within one record use two dedicated literal delimiter tokens
(e.g. `|||COL|||` between entries, `|||KV|||` between a key and its value) that the prompt
explicitly instructs Claude never to use elsewhere.

### 5c. Truncation detection, not truncation guessing

`call_claude()` captures the Claude API's own `stop_reason` field from the streaming response.
If it's `"max_tokens"`, the app tells the user immediately and explicitly — rather than letting
a silently-incomplete response corrupt the parsed data. The parser additionally treats **only
the very last block** being incomplete as likely truncation (dropped + reported by name); any
*other* incomplete block is a real formatting problem, surfaced as a validation error instead of
guessed at.

### 5d. Streaming, not blocking, API calls

`call_claude()` uses Server-Sent Events streaming (`curl::curl_fetch_stream()`), not a single
blocking POST. A non-streaming call sends zero bytes back while Claude generates — for a
longer response that can be 60+ seconds of total silence on the wire, which many corporate
proxies/firewalls interpret as a dead connection and kill outright, even though nothing is
actually wrong. Streaming keeps bytes flowing continuously, so the connection never looks idle.

### 5e. Validate before upload, with two severities

`validate_*_structure()` returns **issues** (blocking — duplicate IDs, dangling references,
missing required fields; upload is refused with a clear message) separately from **warnings**
(non-blocking — a soft cap exceeded, a dangling cross-reference silently skipped at render time;
upload proceeds, user is informed).

### 5f. Editable generation text before upload

The raw generated text is shown in an **editable** textarea, not read-only output. A "Re-Parse &
Update Preview" button lets the user fix a small issue by hand (delete a stray line, correct a
typo) without regenerating the whole thing. Upload always reads whatever is *currently* in the
box.

### 5g. Append-only storage where edit history matters

Suites with an Edit tab (Mind Map, Knowledge Graph) never run `UPDATE`/`DELETE` SQL. An edit is
a new row (`change_type = 'create'|'update'|'delete'`, same stable id, higher `id`/version
number). "Current state" is always derived by taking the latest row per id and dropping
anything whose latest `change_type` is `'delete'`. This gives a free audit trail and makes
cascade-deletes trivial (compute what needs tombstoning in R, insert new rows — never touch
existing ones).

---

## 6. How to add a new suite

1. **Design the schema.** One BigQuery table, one row shape. Decide if it needs the append-only
   versioned pattern (if there's an Edit tab) or can be simpler create-only (if not).
2. **Add the table's `CREATE TABLE IF NOT EXISTS` statement** to `authenticate_bigquery()` in
   `utils_api.R`, in the same `tryCatch`-wrapped list as the others.
3. **Add suite-scoped `APIManager` fields and methods**: `bq_table_<suite>`,
   `bq_full_table_<suite>`, `state_trigger_<suite>`, `trigger_state_update_<suite>()` (must also
   null out that suite's taxonomy cache), `<suite>_taxonomy_cache`, `empty_<suite>_taxonomy()`,
   `bq_get_<suite>_taxonomy()` (cache-checking), `bq_insert_<suite>()`. Copy an existing suite's
   block as a template — the shape is identical every time.
4. **Write the parsing/validation/prompt-building functions** in `utils_common.R`, in their own
   clearly-commented section. Reuse the shared cascade-dropdown helpers if your suite needs a
   Category/Topic (or Category/Domain/Topic) picker — check whether the existing 2-level or
   3-level helper fits before writing a new one.
5. **Build the modules** under `modules/"<Suite Name>"/`, each exactly 3 files. Name every
   module id uniquely across the *whole app*, not just within your suite (`grep -r` for the id
   first).
6. **Register in `_module_registry.yml`**: add a `groups:` entry with your suite's module id
   list, and a `modules:` entry per module with `enabled`/`priority`.
7. **Declare every package your suite's modules use as a literal `library(...)` call in
   `global.R`** — not just in each module's `manifest.yml`. This is the single most common way
   a new suite breaks *only on deployment*: rsconnect's dependency scanner can't see inside YAML
   files, so a package declared only there simply won't be installed on the server, and the app
   will crash within seconds of loading (see the incident writeup below).
8. **Cross-check before deploying**: no duplicate module ids, no duplicate `APIManager` method
   names, every `updateTabItems(...)` navigation call points at a real, current tabname, every
   package used anywhere has a literal `library()` call in `global.R`.

---

## 7. Real deployment incidents worth knowing about

**The silent missing-package crash.** A new suite's chart module used `plotly`, declared only
in its `manifest.yml`. Locally it worked fine (the package happened to already be installed in
that R environment from earlier work). On a fresh Posit Connect deployment, the app crashed
within ~2 seconds of loading — not a timeout, a hard crash, because `create_ui()` calls every
enabled module's UI function immediately at startup to build the full sidebar/body, and
`plotlyOutput()` doesn't exist if `plotly` was never installed. **Lesson: every package used
anywhere in the app needs a literal `library()` call somewhere rsconnect's static scanner can
see — a YAML manifest entry alone is not enough.**

**The R raw-string delimiter trap.** Embedding a large JS block in R via
`js <- r"(...)"` breaks the moment the JS contains a literal `)"` sequence — which ordinary JS
does constantly (e.g. string concatenation `+ ")"`). Use a longer delimiter,
`r"---(...)---"`, and verify the exact delimiter sequence doesn't appear inside the embedded
content before relying on it.

**Stale CSS during a merge.** When consolidating multiple apps' stylesheets into one, always
verify the *complete, current* version of each stylesheet is the one that ends up in the merged
file — an earlier, feature-incomplete ancestor CSS can silently drop working functionality
(e.g. frozen-column/row grid styling) even though the underlying HTML/JS generating that markup
is completely correct and unchanged.
