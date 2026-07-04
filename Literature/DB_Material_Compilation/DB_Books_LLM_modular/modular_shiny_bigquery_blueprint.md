# Modular R Shiny + BigQuery + LLM App — Architecture Blueprint

> **Purpose of this document:** Full documentation of a working production app (Book Summary Complete Suite) that uses modular R Shiny architecture, BigQuery as a backend database, and the Anthropic Claude API for AI content generation. The second half translates this into a reusable blueprint for building similar data-collection-and-visualisation apps, with a concrete worked example (City Events Scanner).

---

## Part 1: Reference Implementation — Book Summary Complete Suite

### 1.1 What the App Does

The app allows users to:

1. Authenticate with Google BigQuery and the Anthropic Claude API via dedicated configuration tabs
2. Generate comprehensive AI book summaries (chapter by chapter) using Claude, with optional mathematical formulas and numeric metrics per chapter
3. Import generated summaries into BigQuery via a bulk text parser or one-at-a-time via an Add Single Entry form
4. Browse stored summaries in a paginated data table
5. Visualise stored book data in rich interactive HTML panels — book metadata cards, chapter content cards with LaTeX-rendered formulas, and Plotly numeric trend charts
6. Filter visualisations via a three-level Genre → Topic → Book cascade dropdown, all populated live from BigQuery

---

### 1.2 Technology Stack

| Layer | Technology |
|---|---|
| UI framework | R Shiny + shinydashboard |
| Modular architecture | Custom R6-based ModuleLoader |
| AI generation | Anthropic Claude API (claude-sonnet-4-6 default) |
| Database | Google BigQuery (bigrquery R package) |
| Interactive charts | Plotly |
| Data tables | DT (DataTables) |
| UI utilities | shinyjs (show/hide spinners) |
| HTTP | httr + jsonlite |
| Deployment | shinyapps.io via rsconnect |

---

### 1.3 Folder Structure

```
Modular_db_books_llm/
├── app.R                          # Entry point: sources global.R, wires UI + server
├── global.R                       # Package loading, sourcing, R6 object instantiation
├── R/
│   ├── module_loader.R            # R6 ModuleLoader: discovers, loads, wires modules
│   ├── utils_api.R                # R6 APIManager: BigQuery + Claude API methods
│   └── utils_common.R            # Shared pure functions: parsing, prompts, helpers
├── modules/
│   ├── _module_registry.yml       # Enable/disable modules without touching code
│   ├── bigquery_auth/             # BigQuery JSON key upload + auth
│   ├── claude_api_config/         # Claude API key + model + token config
│   ├── generate_summary/          # AI summary generation UI + server
│   ├── bulk_import/               # Paste-and-parse bulk text → BigQuery
│   ├── add_single/                # Manual single-entry form → BigQuery
│   ├── browse_data/               # Paginated DT table of all rows
│   ├── visualizations/            # Rich HTML + Plotly visualisations
│   └── about/                     # Static info tab
│       ├── ui.R
│       ├── server.R
│       ├── manifest.yml           # Module metadata + dependency declarations
│       └── README.md
└── www/
    └── css/global.css             # Shared status classes, card styles
```

Each module is completely self-contained: its own UI, server, manifest declaring its package dependencies, and README. The `ModuleLoader` reads `_module_registry.yml` at startup, sources the enabled modules in order, and passes the shared `api_manager` R6 object into each module's server function.

---

### 1.4 Core R6 Objects

#### ModuleLoader (`R/module_loader.R`)

Responsibilities:
- Reads `_module_registry.yml` to get the ordered list of enabled modules
- Sources each module's `ui.R` and `server.R`
- Calls `library()` for each package declared in each module's `manifest.yml`
- Provides `load_ui()` and `load_servers()` methods called by `app.R`

Key design: package loading is dynamic at runtime, but `global.R` also declares every package with a literal `library()` call for rsconnect's static dependency scanner. Without those literal calls, shinyapps.io installs only what it can detect from `pkg::function()` references — missing the dynamically loaded ones.

#### APIManager (`R/utils_api.R`)

A single R6 instance created in `global.R` and passed into every module server. It holds all state and provides all data methods:

**State fields:**
- `bq_authenticated` (logical)
- `claude_authenticated` (logical)
- `claude_api_key`, `claude_model`, `claude_max_tokens`, `claude_timeout`
- `bq_project_id`, `bq_dataset_id`, `bq_table_id`, `bq_full_table_id`
- `state_trigger` — a `reactiveVal(0)` that any module can increment to cause all other modules' `observe(api_manager$state_trigger())` blocks to re-run (e.g. after a BigQuery upload, all dropdowns refresh automatically)
- `pending_bulk_text` — a `reactiveVal("")` used to pass generated summary text from the Generate Summary tab to the Bulk Import tab without either module needing to know about the other

**Methods:**
- `set_bq_credentials()` / `test_bq_connection()`
- `set_claude_credentials()` / `test_claude_connection()`
- `call_claude(prompt, max_tokens, progress_callback)` → returns `list(text, stop_reason, truncated)`
- `bq_query(query)` → runs arbitrary SELECT, returns data frame
- `bq_get_taxonomy()` → `SELECT DISTINCT genre, topic, book_name, author` for cascade dropdowns
- `bq_insert(df)` → normalises column order, fills missing columns with `""`, appends to table
- `trigger_state_update()` → increments `state_trigger` to refresh all dependent observers
- `set_pending_bulk_text(text)` → cross-module text handoff

**Critical architectural note:** `api_manager` is instantiated once in `global.R` and shared across all Shiny sessions. This is fine for single-user or low-traffic deployments but means session isolation does not exist — credentials and pending text are global. For multi-user production deployments, `api_manager` must be moved inside `server()` so each session gets its own instance.

---

### 1.5 BigQuery Schema

Table: `project.dataset.book_summaries_test3`

| Column | Type | Notes |
|---|---|---|
| id | INTEGER | Client-computed: `MAX(id) + 1` before each insert |
| created_at | TIMESTAMP | Set to `Sys.time()` at insert |
| book_name | STRING | |
| author | STRING | |
| genre | STRING | Top-level classification (e.g. "Business") |
| topic | STRING | Sub-category under genre (e.g. "Entrepreneurship") |
| chapter | STRING | e.g. "Chapter 01: Introduction" — zero-padded for sort |
| section | STRING | e.g. "All Sections" |
| main_details | STRING | 100–200 word chapter summary |
| formula | STRING | LaTeX string or "N/A" |
| formula_explanation | STRING | Plain-text explanation of formula or "N/A" |
| reference_url | STRING | URL or "N/A" |
| reference_description | STRING | Description of URL or "N/A" |
| numeric_data | STRING | Comma-separated 6 numbers e.g. "75,95,20,85,90,70" |
| numeric_data_description | STRING | Labels for each number or "N/A" |

**Important:** `numeric_data` is stored as a delimited STRING, not a BigQuery ARRAY. It is split with `strsplit()` at read time in the visualisation module. `formula` uses LaTeX syntax rendered client-side via MathJax (loaded in `global.R`'s dashboard body).

**SQL escaping:** BigQuery's GoogleSQL uses backslash to escape single quotes inside string literals (`\'`), not the ANSI SQL doubled-quote (`''`). Any string interpolated into a `WHERE` clause must be escaped with `gsub("'", "\\\\'", value)`.

---

### 1.6 Text Format Contract

Claude is prompted to return a strictly structured plain-text document. `parse_summary_text()` in `utils_common.R` is the single parser for this format. Both the Generate Summary tab (via "Parse and Upload Direct") and the Bulk Import tab use this same function.

**Format:**
```
[Book Title]
[Author Name]
[Genre]
[Topic]

[chapter]: Chapter 01: Chapter Title
[section]: All Sections
[main_details]: ...
[formula]: $$LaTeX$$ or N/A
[formula_explanation]: ...
[reference_url]: https://...
[reference_description]: ...
[numeric_data]: 75,95,20,85,90,70
[numeric_data_description]: Label1 (75), Label2 (95), ...
```

**Parsing rules:**
- First 4 lines: metadata, extracted with the lenient `is_metadata_line()` / `extract_metadata_value()` helpers that accept both pure `[Value]` and malformed `[Label]: Value` patterns
- Subsequent entries: each `[chapter]:` line starts a new row; all fields are extracted with regex `^\[field_name\]:\s*(.+)$`
- Each parsed chapter becomes one row in the data frame, all inheriting the same book_name/author/genre/topic from the header

**Post-processing guarantees applied in `generate_summary/server.R` before the text reaches any downstream step:**
1. `overwrite_metadata_header()` — replaces everything before the first `[chapter]:` line with a clean 4-line header built from the user's actual input values, regardless of what Claude wrote
2. `blank_math_fields()` — if the "Include formulas" checkbox was unchecked, force-sets formula/numeric fields to "N/A" on every line

---

### 1.7 Genre/Topic Taxonomy System

A hierarchical two-level classification system: Genre (e.g. "Business") contains Topics (e.g. "Entrepreneurship"). Both levels are enforced as required fields on Generate Summary and Add Single Entry.

**How it works:**
- `bq_get_taxonomy()` queries `SELECT DISTINCT genre, topic, book_name, author` from BigQuery
- `genre_topic_dropdown_ui(ns)` in `utils_common.R` renders two linked `selectInput` dropdowns with "+ Add New" options
- `setup_genre_topic_cascade(input, output, session, api_manager)` in `utils_common.R` wires the reactive cascade: genre selection filters available topic choices; selecting "+ Add New" enables a text input for a custom value
- The cascade function returns a `reactive()` yielding `list(genre, topic)` with sentinel values resolved to the typed text
- Sentinel constants: `GENRE_ADD_NEW_VALUE <- "__ADD_NEW_GENRE__"` and `TOPIC_ADD_NEW_VALUE <- "__ADD_NEW_TOPIC__"`
- Both dropdowns refresh automatically via `api_manager$state_trigger()` after any upload
- In the Visualisations tab, a third level is added: Genre → Topic → Book, where book choices are filtered by the selected genre/topic pair and labelled as "Title — Author"

This pattern (shared UI builder + shared cascade wiring + sentinel-based new-value detection) is fully reusable for any hierarchical classification scheme in any domain.

---

### 1.8 Cross-Module Communication Patterns

Modules never import or call each other directly. All cross-module communication goes through the shared `api_manager` object:

**Pattern 1: Broadcast refresh via state_trigger**
Any module that writes data calls `api_manager$trigger_state_update()`. Every other module that needs to react (dropdowns refreshing, tables reloading) has an `observe(api_manager$state_trigger())` block that re-queries BigQuery and updates its UI.

**Pattern 2: Directed handoff via reactiveVal**
Generate Summary pushes its completed text to `api_manager$pending_bulk_text(text)`. Bulk Import observes this value with `observeEvent(api_manager$pending_bulk_text(), ...)` and updates its textarea. Tab navigation is triggered with `updateTabItems(session$rootScope(), "sidebar_menu", selected = "bulk_import")` — `session$rootScope()` is required because the dashboard's sidebarMenu lives outside any module's namespace.

---

### 1.9 Claude API Integration Details

**Endpoint:** `POST https://api.anthropic.com/v1/messages`

**Required headers:**
```
x-api-key: <key>
anthropic-version: 2023-06-01
content-type: application/json
```

**Request body:**
```json
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 16000,
  "messages": [{ "role": "user", "content": "<prompt>" }]
}
```

**Response handling:**
- `result$content[[1]]$text` — the generated text
- `result$stop_reason` — `"end_turn"` means complete; `"max_tokens"` means truncated (content is incomplete)
- The app surfaces a visible warning in the UI when `stop_reason == "max_tokens"` so the user knows to increase Max Tokens and regenerate
- The connection reset error observed on long generations (90k+ char responses) is caused by the blocking single-request pattern: the HTTP connection sits idle while Claude generates, and firewalls/proxies reset it. The fix is streaming (receiving the response in chunks via SSE), which keeps the connection continuously active

**Current model IDs (as of June 2026):**
| Display Name | API Model String |
|---|---|
| Claude Sonnet 4.6 (recommended) | `claude-sonnet-4-6` |
| Claude Opus 4.8 (most capable) | `claude-opus-4-8` |
| Claude Haiku 4.5 (fastest) | `claude-haiku-4-5-20251001` |

Anthropic retires model snapshots regularly. If you get a 404 on Test Connection, the model ID is retired — check `https://docs.anthropic.com/en/about-claude/model-deprecations` and update the model ID in `modules/claude_api_config/ui.R` and `R/utils_api.R`.

---

### 1.10 Deployment on shinyapps.io

**The rsconnect dependency scanner problem:** rsconnect's static scanner only detects packages referenced as literal `library("pkg")` or `pkg::function()` in R source files. It cannot see inside YAML files or resolve `library(pkg, character.only = TRUE)` when `pkg` is a variable. This means every package loaded dynamically by `ModuleLoader` must also appear as a literal `library()` call in `global.R`. Without this, the app deploys silently but crashes at runtime when modules try to use packages that were never installed on the server.

**Deploy command:**
```r
library(rsconnect)
rsconnect::deployApp("path/to/app/")
```

**Environment variables for embedded credentials:** shinyapps.io supports per-app environment variables set in the dashboard (App → Settings → Environment Variables). Store the BigQuery service account JSON as a variable and read it in `global.R` at startup:
```r
bq_json <- Sys.getenv("BQ_SERVICE_ACCOUNT_JSON")
if (nchar(bq_json) > 0) {
  tmp <- tempfile(fileext = ".json")
  writeLines(bq_json, tmp)
  bigrquery::bq_auth(path = tmp)
}
```
This eliminates the need for users to upload a JSON file and keeps credentials server-side only.

---

## Part 2: Reusable Blueprint

This section describes how to apply the same architecture to any domain that follows the same pattern: **an AI or automated source generates structured data → it gets stored in BigQuery → users browse and visualise it in rich interactive views.**

---

### 2.1 The Universal Pattern

```
[Source]     →    [Parser]     →    [BigQuery]    →    [Visualiser]
AI / scraper      Structured         Append-only        Shiny UI
/ manual form     text → rows        table(s)           + Plotly/DT
```

Every app following this pattern needs the same five components:

1. **Authentication tab** — credentials for BigQuery (and optionally the AI/data API)
2. **Data ingestion tab** — AI generation, scraping, API call, or manual form
3. **Parser** — converts source format to data frame with fixed schema
4. **Browse tab** — paginated table with search/filter
5. **Visualisation tab** — domain-appropriate charts, maps, calendars, or cards

The `APIManager`, `ModuleLoader`, `state_trigger` pattern, taxonomy cascade, and text-format contract are all domain-agnostic and can be reused verbatim or with minor renaming.

---

### 2.2 What to Reuse Verbatim

| Component | Reuse as-is |
|---|---|
| `R/module_loader.R` | Yes — copy exactly |
| `modules/_module_registry.yml` pattern | Yes — just rename module entries |
| `modules/bigquery_auth/` | Yes — works for any BQ table |
| `modules/browse_data/` | Yes — generic DT table, just change the query |
| `modules/about/` | Yes — update text only |
| `global.R` structure | Yes — update package list and module sources |
| `api_manager$state_trigger` pattern | Yes — universal cross-module broadcast |
| `api_manager$pending_*` handoff pattern | Yes — for any directed cross-module value |
| `safe_sql_escape()` | Yes — required for any string in a WHERE clause |
| `has_real_value()` | Yes — for any nullable/optional field |
| `genre_topic_dropdown_ui()` + `setup_genre_topic_cascade()` | Yes — or adapt for any 2-level hierarchy |
| `bq_insert()` column normalisation pattern | Yes — adapt column list to new schema |

---

### 2.3 What to Replace Per App

| Component | Replace with |
|---|---|
| `modules/claude_api_config/` | Config tab for your data source API (OpenAI, Ticketmaster, Eventbrite, etc.) |
| `modules/generate_summary/` | Your ingestion tab (scrape, API call, AI generation, or form) |
| `modules/bulk_import/` | Paste-and-parse for your text format, or remove if not needed |
| `modules/add_single/` | Manual entry form matching your schema |
| `modules/visualizations/` | Domain-appropriate visualisations (calendar, map, timeline, etc.) |
| `R/utils_common.R` parse functions | Parser for your data's text format |
| `R/utils_api.R` call_claude() | Call to your AI or data API |
| BigQuery schema | Your domain's table structure |
| Text format contract | Your data's serialised format |

---

### 2.4 Worked Example — City Events Scanner

**Concept:** Users scan and store events happening in a city (concerts, conferences, exhibitions, markets, etc.), organised by topic and date, then browse them in a calendar and on an interactive map.

#### Schema

Table: `project.dataset.city_events`

| Column | Type | Notes |
|---|---|---|
| id | INTEGER | Auto-incremented client-side |
| created_at | TIMESTAMP | Insert time |
| event_name | STRING | |
| organiser | STRING | |
| city | STRING | |
| country | STRING | |
| category | STRING | Top-level: "Music", "Tech", "Food", "Art", etc. |
| subcategory | STRING | Sub-level: "Jazz", "AI Conference", "Street Food", etc. |
| event_date | STRING | ISO date "2026-07-15" stored as STRING for flexibility |
| event_time | STRING | "19:30" or "All Day" |
| venue_name | STRING | |
| address | STRING | |
| latitude | STRING | Decimal degrees as string |
| longitude | STRING | Decimal degrees as string |
| description | STRING | 100–300 word event description |
| ticket_url | STRING | |
| price_range | STRING | e.g. "Free", "£10–£25", "N/A" |
| source_url | STRING | Where the data came from |

#### Text Format Contract

The AI (or scraper) returns events in a structured text block:

```
[city]: London
[country]: United Kingdom
[scan_date]: 2026-07-01

[event_name]: London Jazz Festival Opening Night
[category]: Music
[subcategory]: Jazz
[event_date]: 2026-07-15
[event_time]: 19:30
[venue_name]: Ronnie Scott's
[address]: 47 Frith Street, Soho, London W1D 4HT
[latitude]: 51.5132
[longitude]: -0.1314
[description]: The opening night of the annual London Jazz Festival...
[ticket_url]: https://ronniescotts.co.uk/
[price_range]: £25–£45
[source_url]: https://londonjazzfestival.org.uk/

[event_name]: AI Summit London 2026
...
```

The shared header (city, country, scan_date) maps to every row; each `[event_name]:` block starts a new row — exactly the same pattern as book chapter entries.

#### Modules to Build

**`modules/events_api_config/`**
Config tab for whichever data source you use: Ticketmaster API, Eventbrite API, Meetup API, a generic web scraping key, or an AI API (Claude/GPT for generating fictional or curated event lists from a prompt). Stores the key in `api_manager$events_api_key`. Mirrors `claude_api_config` exactly.

**`modules/scan_events/`**
Replaces `generate_summary`. User selects city, country, date range, category. App calls the events API (or Claude with a structured prompt) and receives the text block. Post-processing: `overwrite_header_fields()` replaces the header with known-correct city/country from the form, and `geocode_events()` optionally fills in lat/lon for any event missing coordinates (using a geocoding API like OpenCage or Google Maps). Includes the same "copy to bulk import" button for manual review before upload.

**`modules/bulk_import_events/`**
Paste-and-parse for the event text format. `parse_events_text()` in `utils_common.R` mirrors `parse_summary_text()` exactly — same loop, different field names. Output is a data frame with one row per event. Preview table shows before upload.

**`modules/visualizations_events/`**
This is where the domain diverges most from the book app. Three views:

*Calendar view* — use the `fullcalendar` R package (wraps FullCalendar.js) or a custom HTML widget. Events populate by date, colour-coded by category. Click an event to show a detail card with venue, price, ticket link.

*Map view* — use `leaflet` R package. Markers clustered by proximity, colour-coded by category. Popup shows event name, date, venue, description, ticket link. Filter controls: date range slider, category dropdown, city search.

*List view* — DT table with column filters, sortable by date, searchable. Same browse-data module but pre-filtered to events rather than book rows.

The cascade dropdowns become: Country → City → Category → Subcategory, all populated from `bq_get_taxonomy_events()` (same pattern as the book genre/topic query, extended to 4 levels).

#### Key Implementation Differences from the Book App

**Geocoding requirement:** Addresses need lat/lon for the map. Strategy: if the data source provides coordinates, store them directly. If not, call a geocoding API at import time and store the result — never geocode at render time since it's slow and costs API calls on every visualisation load.

**Date handling:** Store event dates as STRING in BigQuery for simplicity, but parse to R Date objects at read time for sorting and calendar rendering. The BigQuery `DATE` type is another option but requires more careful handling with bigrquery.

**Multiple visualisation types:** The book app has one main visualisation type (the HTML card + chart layout). The events app needs at least a calendar and a map as distinct views, ideally as tabs within the visualisations module.

**No AI formula/numeric fields:** The `formula`, `numeric_data`, and related optional fields from the book schema don't apply here. The equivalent optional fields might be `price_range`, `ticket_url`, and `source_url` — all optional, stored as "N/A" when unknown, checked with `has_real_value()` before rendering links or prices in the UI.

---

### 2.5 Other Use Cases and Schema Suggestions

**Research Paper Tracker**
Scan academic papers on a topic, extract key claims, methods, and findings per paper. Schema: `paper_title`, `authors`, `year`, `journal`, `field`, `subfield`, `abstract`, `key_claim`, `methodology`, `sample_size`, `main_finding`, `limitations`, `doi_url`. Visualisations: timeline of publication dates, network graph of shared citations (requires additional relationship table), Plotly scatter of year vs. citation count.

**Product / Competitor Intelligence**
Track competitor product launches, pricing changes, and feature announcements by category. Schema: `company`, `product_name`, `category`, `subcategory`, `announcement_date`, `price`, `key_features` (pipe-delimited), `source_url`, `sentiment_score`. Visualisations: timeline by company, price comparison chart, feature matrix heatmap.

**Job Market Scanner**
Scan job postings per role, location, and skill set. Schema: `job_title`, `company`, `city`, `country`, `category` (e.g. "Engineering"), `subcategory` (e.g. "Machine Learning"), `posted_date`, `salary_min`, `salary_max`, `required_skills` (comma-separated), `apply_url`, `source`. Visualisations: salary range chart by role/city, skill frequency bar chart, posting volume over time.

**Recipe / Nutrition Database**
Generate or import structured recipes with nutritional data. Schema: `recipe_name`, `cuisine`, `meal_type`, `prep_time`, `cook_time`, `servings`, `calories`, `protein`, `carbs`, `fat`, `ingredients` (pipe-delimited), `instructions`, `source_url`. Visualisations: macro comparison chart across recipes, filter by cuisine/meal type, nutritional heatmap.

---

### 2.6 Checklist for Building a New App from This Blueprint

When starting a new app, work through these steps in order:

**1. Define your schema first.** Write the BigQuery `CREATE TABLE` DDL before touching any R code. Every other decision flows from this.

**2. Define your text format contract.** Write two or three example entries of what your AI or scraper will return. This becomes the spec for your parser and your prompt.

**3. Copy the skeleton.** Take the existing app and rename/delete modules rather than starting from scratch. Keep `bigquery_auth`, `browse_data`, `about`, and all of `R/module_loader.R` and the `APIManager` skeleton unchanged.

**4. Write the parser first.** `parse_your_format()` in `utils_common.R` is the most important function in the app — everything else depends on it being correct. Test it against your example entries before building any UI.

**5. Write the prompt / scraper query second.** Make sure it reliably produces the format your parser expects. Add a `overwrite_header_fields()` post-processing function to guarantee the metadata header is always clean regardless of what the source returns.

**6. Build the ingestion module.** Copy `generate_summary` as the starting point. Replace the Claude call with your API call. Keep the progress callback pattern, the truncation/error detection, and the copy-to-bulk-import handoff.

**7. Build the visualisation module last.** It depends on having real data in BigQuery to test against. Build the cascade dropdowns first (they're domain-agnostic), then the domain-specific charts/maps/calendar views one at a time.

**8. Handle the rsconnect scanner problem.** Before deploying, audit `global.R` and ensure every package used anywhere in the app appears as a literal `library()` call there.

**9. Move credentials to environment variables.** For any deployed version where users should not see a credentials tab, store API keys and BigQuery credentials as shinyapps.io environment variables and authenticate silently at startup.

**10. Add user gating if needed.** A minimal `users` table in BigQuery with allowed email addresses, checked at app startup before rendering any content, is the lightest-weight approach and requires no external auth service. More robust options: Google Identity Platform / Firebase Auth for token-based auth with password or magic-link flows.

---

### 2.7 Common Pitfalls to Avoid

**BigQuery SQL escaping.** GoogleSQL uses backslash to escape single quotes inside string literals (`\'`), not the ANSI SQL doubled-quote convention (`''`). Book titles, event names, and any other user-provided strings interpolated into `WHERE` clauses must be escaped with `gsub("'", "\\\\'", value)`. Any string with an apostrophe (e.g. "Don't", "O'Brien") will silently fail to match or crash the query if this is not applied.

**rsconnect dependency detection.** Covered in section 1.10. Every package must appear as a literal `library("pkg")` call in `global.R` regardless of whether it's also loaded dynamically by `ModuleLoader`.

**stop_reason / truncation detection.** When the AI response hits `max_tokens`, the response body is a valid HTTP 200 with complete JSON — there is no error. The content is simply incomplete. Always check `result$stop_reason == "max_tokens"` and surface a visible warning. Do not assume a successful HTTP response means a complete response.

**API connection resets on long requests.** A blocking `httr::POST()` that waits several minutes for a large response will be reset by firewalls, proxies, or infrastructure between the client and the API. The proper fix is streaming (Server-Sent Events), where the response arrives in chunks and the connection stays continuously active. For Anthropic's API, set `"stream": true` in the request body and process the response with a streaming HTTP client.

**Shared api_manager for multi-user deployments.** The current architecture creates one `api_manager` instance in `global.R`, shared across all concurrent Shiny sessions. For single-user or admin-only deployments this is fine. For any app with multiple simultaneous users, move `api_manager <- APIManager$new()` inside `server()` so each session is isolated.

**Module ID consistency.** Every module must have a consistent ID across three places: the key in `_module_registry.yml`, the `id` field in `manifest.yml`, and the function name pattern (`module_name_ui` / `module_name_server`). A mismatch causes silent load failure with no useful error message.

**BigQuery `WRITE_APPEND` and schema drift.** `bq_table_upload(..., write_disposition = "WRITE_APPEND")` will fail if the data frame column names or types don't match the table schema. Always normalise column order and fill missing columns with empty strings in `bq_insert()` before uploading. Never add a new column to the BigQuery table without also updating the column list in `bq_insert()`.
