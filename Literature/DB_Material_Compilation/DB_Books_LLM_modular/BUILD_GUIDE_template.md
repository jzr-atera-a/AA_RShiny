# Build Guide: Extending the Shiny Template into a New App

> **Who this is for:** A developer (or an AI assistant in a new chat) picking up the template zip and needing to build a focused, working app as fast as possible — ideally in a single session — without re-discovering the pitfalls that cost time the first time round.
>
> Read this before writing a single line of code. The decisions you make in the first 20 minutes of a new build will either save or cost you hours later.

---

## Part 1 — What This Template Gives You for Free

These things are already built, tested against a production app, and should not be rewritten from scratch in a new project. Accept them as-is and adapt only what they touch.

### The APIManager R6 Pattern

A single shared object (`api_manager`) holds all credentials and provides all data-access methods. Every module receives it as a parameter and calls `api_manager$method()` rather than querying the database or calling APIs directly. This keeps every module independently testable and prevents credential logic from leaking into UI code.

**What works:** modules stay clean and focused. Adding a new data source means adding a method to `APIManager`, not importing a new file into every module that needs it.

**What to preserve:** always pass `api_manager` through the module server signature. Never create a second credentials object inside a module.

### The state_trigger Broadcast

`api_manager$trigger_state_update()` increments a reactive counter. Any module observing `api_manager$state_trigger()` reruns automatically when data changes anywhere in the app. Upload a row in the ingest module, and the browse table and visualisation dropdowns refresh without any direct communication between those modules.

**What works:** adding a new module that displays live data requires only one `observe({ api_manager$state_trigger(); ... })` block — no wiring between modules, no event delegation.

**What to preserve:** always call `trigger_state_update()` after any BigQuery write. Never skip it to save a query — the cost of a stale dropdown catching a user is higher than one extra taxonomy query.

### The pending_text Cross-Module Handoff

A `reactiveVal("")` on `api_manager` lets the ingest module push generated text to another module (bulk paste area, review panel) without either module knowing about the other. The sender calls `api_manager$set_pending_text(txt)`. The receiver observes `api_manager$pending_parsed_text()`.

**What works:** clean decoupling. The ingest module doesn't need to know whether a bulk-paste tab even exists.

**What to extend:** add more `reactiveVal` fields to `api_manager` for other cross-module values your app needs (e.g. a selected item that multiple tabs need to respond to).

### The Parser + Force-Overwrite Pattern

`parse_structured_text()` converts plain LLM output into a data frame. `overwrite_metadata_header()` replaces the LLM's own header with values known to be correct from the form inputs. `blank_optional_fields()` force-sets unwanted fields to "N/A" regardless of what the LLM wrote.

**What works:** treating the LLM as an unreliable typist. You specify the values you care about through the form; the LLM fills in the body content; the post-processing guarantees the stored data matches what the user intended, not what the model decided to rephrase. This pattern eliminates an entire category of parsing bugs.

**What to preserve:** always apply `overwrite_metadata_header()` before storing, displaying, or pushing to any downstream step. Never trust the LLM to reproduce bracket-format metadata exactly.

### The safe_sql_escape Function

BigQuery uses `\'` (backslash) to escape single quotes in string literals, not `''` (the ANSI SQL convention used by PostgreSQL, MySQL, and most other databases). Any user-provided string interpolated into a `WHERE` clause must go through `safe_sql_escape()`. A title containing an apostrophe (e.g. "Don't", "O'Brien") will silently fail to match or crash the query without this.

**What works:** the function is already in `utils_common.R` and used consistently in the visualisations module. Copy this habit to every new query you write.

**What to never do:** interpolate `input$anything` directly into a SQL string without escaping it first.

### The viz-card CSS System

The white-card-with-teal-left-border appearance of each content card is a single CSS class (`.viz-card`) in `www/css/global.css`. The class uses CSS custom properties (`--color-primary`, `--color-accent`) defined at the top of the file, so the entire colour scheme changes by editing two lines.

**What works:** the card system plus the formula-box, reference-box, metrics-row, and section-tag classes provide a complete visual language for any structured record. Most domain adaptations need only to change which fields populate which card elements, not the card structure itself.

**What to preserve:** always run the app from the project root directory. Shiny serves `www/css/global.css` relative to the working directory — if that's wrong, the cards render as unstyled plain text with no error message. This is the most common "my styles are gone" bug. Fix: `shiny::runApp("path/to/your/app")` with the full path, not `shiny::runApp()` from an arbitrary directory.

### The rsconnect Dependency Declaration

shinyapps.io's deployment scanner detects packages only through literal `library("pkg")` calls in `.R` files. The template's `global.R` already contains an explicit block declaring every package. Add any new package you introduce to that block, or it will install locally (where it was already present) but silently not install on the server, causing a runtime crash with no obvious cause.

---

## Part 2 — The Fastest Path to a New Functioning App

Based on the actual time cost of each phase in a real build, here is the optimal build sequence. Deviating from this order costs disproportionate time.

### Phase 0: Define the Schema First (30 minutes, do this before opening RStudio)

Write the BigQuery `CREATE TABLE` DDL before touching any R code. This forces every other decision into alignment: what the parser produces, what the LLM is asked to generate, what the cascade dropdowns filter on, and what the visualisation renders. Starting with code and retrofitting the schema later is the single most expensive mistake in terms of rework.

Answer these questions before writing any code:

1. What is the primary entity? (book, event, paper, product, recipe, person)
2. What are the two classification levels (category → subcategory)? These drive the cascade dropdowns everywhere.
3. What is the row-level unit? (chapter, event date, section, ingredient) One row per unit in BigQuery.
4. What is the main body text for each row? (summary, description, abstract)
5. Are formulas and numeric metrics relevant? If not, remove those columns entirely from the start — leaving them in as dead "N/A" columns just adds noise.
6. What domain-specific fields does this app need that the template doesn't have? (date, location, price, URL, duration, coordinates, etc.)

Run `schema.sql` in BigQuery Console before writing the parser. It takes two minutes and gives you a real table to test against immediately.

### Phase 1: Update the Three Constants and the Column List (15 minutes)

In `R/utils_api.R`:

```r
BQ_PROJECT  <- "your-gcp-project-id"
BQ_DATASET  <- "your_dataset"
BQ_TABLE    <- "your_table"
```

And update `REQUIRED_COLS` inside `bq_insert()` to match your schema's column names in the exact order your BigQuery table defines them. Every column must be listed here or uploads will fail with a schema mismatch error.

Update `bq_get_taxonomy()` to select the correct column names (your category/subcategory/title equivalents).

### Phase 2: Write and Test the Parser in Isolation (1–2 hours)

`parse_structured_text()` in `utils_common.R` is the most critical function in the app. Everything else — the LLM prompt, the ingest module, the bulk paste, the BigQuery upload — produces output that flows through this function. If the parser is wrong, everything downstream is wrong.

Write two or three representative example text blocks by hand before asking the LLM to generate anything. Paste them into an R console and call `parse_structured_text()` on them directly. Fix any issues before touching the Shiny UI. Testing the parser in isolation takes minutes; debugging it through the Shiny interface takes hours.

The things most likely to need changing:

- The first field in `FIELDS` is the item-start marker. Change `chapter_or_item` to whatever your row-level unit is called.
- Update the field names in the `data.frame()` call at the end to match your schema column names exactly (they must match `REQUIRED_COLS` in `bq_insert()`).
- If your rows don't have a "section" concept, remove it from `FIELDS` and from the data frame.

### Phase 3: Write the LLM Prompt (1 hour)

`build_llm_prompt()` in `utils_common.R` produces the text sent to the LLM. The most important properties of a good structured prompt:

**Be explicit about the exact bracket format.** Show a complete example entry in the prompt, not just a field list. LLMs follow examples more reliably than they follow abstract rules.

**Specify what to do with optional fields.** If formulas don't apply, instruct the LLM to write "N/A" — not to omit the line, not to write "none", not to skip it. The parser expects every field to be present on every entry. The `blank_optional_fields()` post-processor is a safety net, not a first resort.

**Specify chapter/item numbering explicitly.** Instruct the model to zero-pad single-digit numbers (Item 01, not Item 1). This matters for sort order in BigQuery.

**Ask for a concrete number of entries.** "Generate a summary for all chapters" produces variable output. "Generate one entry per chapter, there are 18 chapters" is more reliable.

**Test the prompt before building any UI.** Call `api_manager$call_llm(prompt)` directly from the R console with a short `max_tokens` (e.g. 2000). Check whether the output format matches what `parse_structured_text()` expects. Iterate on the prompt until parsing succeeds cleanly before building the ingest tab.

### Phase 4: Update the Cascade Labels (15 minutes)

In `utils_common.R`, `category_subcategory_ui()` accepts `category_label` and `subcategory_label` parameters. Pass your domain's terms wherever you call it:

```r
# In your ingest module UI:
category_subcategory_ui(ns, category_label = "City", subcategory_label = "Event Type")
```

Also update the placeholder text in `textInput(ns("new_category_text"), ...)` to give users a useful example for your domain.

### Phase 5: Adapt the Visualisation Cards (2–3 hours)

The visualisations module is the most domain-specific part of the app and takes the most adaptation time. The card HTML generation loop in `modules/visualizations/server.R` references field names directly — update these to your schema's column names.

For most apps, the card structure itself (title, section tag, body text, optional formula box, optional reference link, optional metric row) works well as-is with field name changes. Spend the time here on what the cards display, not on reinventing the card structure.

If your app needs a non-card visualisation (map, calendar, timeline), add it as a separate `output` block and `uiOutput` slot in the UI rather than replacing the card system — keep cards for the detail view and use the alternative visualisation for the overview.

### Phase 6: Test the End-to-End Flow Before Deploying (1 hour)

Before touching rsconnect, run the complete flow locally:
1. Authenticate BigQuery
2. Authenticate LLM
3. Generate one entry via the LLM
4. Parse and upload it
5. Browse it in the table
6. Load it in the visualisation tab
7. Check that the cascade dropdowns populate correctly after upload

Fix any issues locally. Debugging on shinyapps.io is significantly slower because you lose the R console and must infer everything from the app's visible error state.

---

## Part 3 — What Has Worked Well

### Structured plain text as the LLM output format

Having the LLM return a rigid bracket-delimited format (`[field]: value`) rather than JSON or markdown works better in practice for two reasons: the LLM is less likely to introduce syntax errors (a missing closing brace breaks JSON; a missing bracket line just creates an empty field), and the format is human-readable in the bulk paste textarea, making manual correction straightforward.

The lenient parser (`is_metadata_line()` + `extract_metadata_value()`) that accepts both the correct `[Value]` format and the malformed `[Label]: Value` format the LLM sometimes produces has eliminated the most common failure mode without requiring prompt re-engineering.

### Force-overwriting metadata rather than trusting the LLM

The decision to replace the LLM's metadata header entirely with values from the form — rather than parsing what the LLM wrote — removed a recurring bug category. LLMs consistently deviate from exact bracket formatting on header lines despite explicit instructions, often adding their own labels, elaborations, or colons. The `overwrite_metadata_header()` approach sidesteps this entirely: the LLM generates body content, the app provides metadata.

### Comprehensive console logging with emoji markers

The `cat()` statements with emoji prefixes (🖱️ 🔧 ✅ ❌ 📡) introduced to diagnose the silent generation failure turned out to be genuinely useful to keep. When something goes wrong in a long async flow (a 3-minute LLM call followed by a BigQuery upload), being able to see exactly which step the execution reached in the console is worth the verbosity. Keep this convention in new apps.

### The optional math toggle defaulting to OFF

Making formulas and numeric data opt-in rather than opt-out, with the toggle defaulting to off, solved both a prompt efficiency problem (shorter prompt = less truncation risk, fewer tokens) and a data quality problem (no more fabricated "mathematical formulas" on books where none make sense). The force-blank post-processor as a second enforcement layer ensures the database stays clean regardless of what the LLM writes.

### stop_reason detection for truncation

Checking `result$stop_reason == "max_tokens"` and surfacing an explicit warning in the UI when triggered saved repeated confusion about why generated content was missing its final entries. The LLM returns HTTP 200 with valid content regardless of whether it finished — there is no error to catch. Surface the truncation as a warning, not an error, with a clear instruction to increase max_tokens.

### The cascade dropdown pattern as shared infrastructure

Putting `category_subcategory_ui()` and `setup_category_cascade()` in `utils_common.R` as shared functions (called by ingest, add-single, and visualisations) rather than implementing the cascade independently per module was worth the extra abstraction. Every module that shows a category/subcategory picker gets automatic refresh on new data and consistent behaviour without duplicating observer logic.

---

## Part 4 — What to Avoid

### Do not start with the UI

The temptation to build the visual interface first because it gives immediate feedback is a reliable time trap. A beautiful UI connected to a broken parser or a prompt that produces unparseable output means rebuilding large parts of the UI after the logic is fixed. Build in this order: schema → parser → prompt → API wiring → UI → CSS. The UI is the last thing to polish.

### Do not mix domain logic into module servers

Module servers should be short: validate inputs, call `api_manager` methods, update outputs. Any logic that runs without needing Shiny state (text transformation, parsing, prompt construction, SQL query building) belongs in `utils_common.R` or `utils_api.R`. The cost of violating this rule is that the logic becomes untestable without running the full Shiny app, and it silently duplicates when a second module needs the same function.

### Do not trust the LLM with field names or bracket format

Every real deployment has hit cases where the LLM echoes the placeholder name inside the bracket instead of the real value (`[Book Title]: 48 Laws of Power` instead of `[48 Laws of Power]`), adds its own elaboration after a colon, or uses slightly different casing than instructed. The lenient parser and force-overwrite functions handle this — but only for the header. For body fields, design the parser to be lenient about leading/trailing whitespace and to treat missing fields as empty rather than errors.

### Do not skip the connection test before building

Before writing the ingest module, verify the BigQuery connection and LLM connection independently using the auth tabs. A 400 from the LLM API is more likely a retired model ID or a billing/quota issue than a code bug, but without testing the connection first, it looks like a code bug and gets diagnosed as one. The most common LLM connection failure since mid-2026 is using a model string that has been retired — check Anthropic's model deprecations page if you get a 404, not your code.

### Do not use a blocking HTTP call for long LLM requests

The single `httr::POST()` that waits for the complete response works fine for short generations (under ~20 seconds). For longer requests, corporate firewalls, VPN concentrators, and proxy servers reset idle TCP connections typically between 60 and 300 seconds. The connection reset produces an uninformative "Recv failure: Connection was reset" error that looks like a network problem but is actually an architectural one. The proper fix is streaming (Server-Sent Events), where the response arrives in small chunks and the connection is never idle. This template does not implement streaming — for any generation likely to exceed 60–90 seconds, either implement streaming or design the prompt to generate in smaller chunks.

### Do not leave rsconnect dependency detection to chance

The pattern of writing new code that uses a package, testing locally (where the package was already installed months ago), and deploying — only to get a runtime crash because the server never installed the package — is easily avoided by always checking `global.R`'s explicit library block when you add a new `library()` or `::` usage anywhere in the app. Add it there at the same time you write the code. Do not add it at deployment time when you're under pressure.

### Do not share api_manager across users in production

The template creates `api_manager` once in `global.R`, shared across all concurrent Shiny sessions. This is a deliberate simplification for single-user and prototyping use. In a multi-user deployment, one user's credentials and `pending_parsed_text` are visible to every other concurrent session. Moving `api_manager <- APIManager$new()` inside `server()` in `app.R` is a one-line fix. Do it before going to production with more than one user.

### Do not hardcode model IDs for long-lived deployments

LLM providers (including Anthropic) retire specific model snapshot IDs on a rolling basis, typically 6–12 months after release. A hardcoded ID that works today will return HTTP 404 when the model is retired, with no warning until someone hits the error. For long-lived deployments, consider fetching available models dynamically from the provider's models API to populate the dropdown, or establish a process to check the deprecation notices before each deployment.

### Do not store BigQuery credentials in source code

The template requires users to upload a JSON key file at runtime, which works for personal or internal tools. For any public-facing or multi-user deployment, the JSON content should be stored as an environment variable on the hosting platform (shinyapps.io: App → Settings → Environment Variables) and read at startup, with BigQuery authentication happening silently. A service account JSON key in source code is a significant security risk even in a private repository.

---

## Part 5 — Time Budget for a New Build

Based on real build experience, here is a realistic time allocation for building a new domain-specific app from this template in a single focused session:

| Phase | Task | Time |
|---|---|---|
| 0 | Define schema, write DDL, run in BigQuery | 30 min |
| 1 | Update BQ constants, REQUIRED_COLS, taxonomy query | 15 min |
| 2 | Write and test parser in R console | 60–90 min |
| 3 | Write and test LLM prompt in R console | 45–60 min |
| 4 | Update cascade labels, form field labels, placeholder text | 15 min |
| 5 | Adapt visualisation card field names | 45–60 min |
| 5a | Add domain-specific visualisation (map/calendar/chart) if needed | 2–4 hours |
| 6 | End-to-end local test and bug fixing | 60 min |
| 7 | Deploy to shinyapps.io and verify | 20–30 min |
| — | **Total (no custom visualisation)** | **~5 hours** |
| — | **Total (with map or calendar)** | **~8–10 hours** |

The largest variable is Phase 5a. A leaflet map or a fullcalendar widget is a significant addition. If building one of these, allocate it as its own session rather than trying to fit it into the same session as the rest of the app.

---

## Part 6 — Domain Adaptation Quick Reference

### Fields to rename in every file

When adapting the template, these names appear in multiple files and must be updated consistently. The right approach is to search the entire project for each term and replace it everywhere:

| Template name | What it represents | Your replacement |
|---|---|---|
| `title` | Primary identifier of the entity | `event_name`, `paper_title`, `product_name` |
| `author` | Creator/owner of the entity | `organiser`, `authors`, `brand` |
| `category` | Top-level classification | `city`, `field`, `genre`, `product_type` |
| `subcategory` | Second-level classification | `event_type`, `subfield`, `topic` |
| `chapter_or_item` | Row-level unit | `event`, `section`, `ingredient`, `finding` |
| `main_content` | Body text of the row | `description`, `abstract`, `summary` |

### Files to update when renaming

- `R/utils_api.R` — `REQUIRED_COLS`, `bq_get_taxonomy()` SELECT and empty data frame
- `R/utils_common.R` — `FIELDS` vector, `data.frame()` call in parser, `build_llm_prompt()` field list and example, `overwrite_metadata_header()` marker pattern
- `modules/visualizations/server.R` — every `row$field_name` reference in the card loop, `bq_get_taxonomy()` column references in the cascade
- `modules/data_ingest/ui.R` — form input labels and placeholder text
- `modules/data_ingest/server.R` — field references when building the data frame for direct upload
- `schema.sql` — column names in the DDL

### What you do not need to update

- `global.R` — structure is domain-agnostic; only update the page title string
- `app.R` — no domain-specific content
- `modules/bigquery_auth/` — entirely domain-agnostic
- `modules/llm_config/` — domain-agnostic; update model dropdown choices only if provider changes
- `modules/browse_data/` — almost entirely domain-agnostic; only the filter column names change
- `modules/about/` — update descriptive text only
- `www/css/global.css` — update `--color-primary` and `--color-accent` for brand colours; the card structure works for any domain

---

## Part 7 — Handing This to an AI Assistant

When starting a new build in a separate Claude chat, provide:

1. This file (`BUILD_GUIDE.md`)
2. The `TEMPLATE_GUIDE.md` from the template zip (the technical file map and step-by-step instructions)
3. The `modular_shiny_bigquery_blueprint.md` (the detailed architecture reference with pitfalls)
4. Your schema definition (even a rough column list is enough to start)
5. Two or three example records in the text format the parser expects

With these four artefacts, the AI has everything needed to adapt the template without re-explaining the architecture, without re-discovering the BigQuery escaping issue, and without repeating the rsconnect scanner problem. The goal is to spend AI session time on domain-specific implementation, not on re-deriving known patterns.

The most efficient prompt to start a new build session is:

> "I have a working Shiny + BigQuery + LLM template app. I want to build a [domain] app that stores [primary entity] with [classification levels] as the hierarchy and [row unit] as the row-level unit. The main fields per row are [list]. [Optional: formulas and numeric metrics are / are not applicable]. Here is the schema I want: [DDL or column list]. Please adapt the template for this domain, starting with the parser and prompt, then the BigQuery methods, then the visualisation cards."
