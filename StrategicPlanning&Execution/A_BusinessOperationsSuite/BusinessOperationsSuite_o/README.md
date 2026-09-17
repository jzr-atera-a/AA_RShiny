# Business Operations Suite

A unified R Shiny app combining two previously separate module sets into one
grouped, registry-driven modular app:

- **Communications** (contact extraction, storage, AI messaging, email) - from
  the Business Contact Manager app.
- **Funding Programmes** (AI grant/incubator/accelerator/competition discovery)
  - from the reusable Funding Programmes suite package.

Both now share **one Claude API config** and **one BigQuery config**, grouped
under a single **API Settings** main tab.

## Sidebar structure (3 main tabs, 13 subtabs)

- **API Settings**
  - Claude API Config
  - BigQuery Config
- **Communications**
  - SMTP Configuration
  - Process Contact
  - Explore Contacts
  - Customise Communication
  - Send Email
- **Funding Programmes**
  - Find Programmes
  - Bulk Import
  - Add Single Entry
  - Browse Data
  - Visualizations
  - About
- **Project Application** (grant/proposal builder - Project Details, Business Case,
  Team & Impact sections, plus two diagram generators)
  - OpenAI API Config (used only within this group)
  - Project Details
  - Business Case
  - Team & Impact
  - Diagram Generator (ChatGPT)
  - Claude Diagrams (uses the shared Claude config from API Settings)
- **Strategy Canvases** (Business Model Canvas, Disciplined Entrepreneurship
  Canvas, and its 24-step Roadmap - all Claude-generated, BigQuery-backed)
  - Generate BM Canvas
  - Generate DE Canvas
  - Generate DE Roadmap
  - Business Model Canvas (view)
  - Disciplined Ent. Canvas (view)
  - Disciplined Ent. Roadmap (view)
- **Gantt to Tickets** (convert an uploaded Gantt-chart Excel file into
  Trello cards / Jira issues, with email notifications and a small local
  contact list - no BigQuery/Claude involved)
  - API Configuration (Trello + Jira credentials)
  - Email Configuration (SMTP, separate from Communications' SMTP)
  - Upload Gantt Chart
  - Review & Edit Tasks
  - Submit to Boards
  - Send Email Notifications
  - Manage Contacts
  - Email Contacts
- **Audio Transcription** (video/audio -> Whisper transcription -> ChatGPT
  summarization/analysis pipeline - no BigQuery/Claude involved)
  - Video Audio Extractor (MP4 -> MP3 chunks, native file browsing, async)
  - Audio Converter & Splitter
  - Whisper API Settings
  - ChatGPT API Settings
  - Audio Transcription (batch, up to 10 files)
  - Transcription Summary
  - Bulk Text Analysis
  - Analytics Dashboard
- **Receipt Processor** (OpenAI Vision receipt extraction -> Excel storage ->
  categorization/file-organization pipeline - no BigQuery/Claude involved)
  - Settings (OpenAI key, storage folder, Excel filename)
  - PDF to JPG Converter
  - Convert to PDF
  - Upload Receipts (Vision extraction, smart filenames)
  - View Processed Data
  - Categorize Receipts (radio-button categories, folder organization)

## Architecture

```
app.R                     entry point (source global.R, shinyApp())
global.R                  libraries, module discovery, grouped-sidebar UI/server factories
R/
  api_manager.R            shared APIManager R6 class (Claude, BigQuery, SMTP,
                            funding taxonomy/parser helpers) + %||%/safe_sql_escape
  module_loader.R           ModuleLoader R6 class - reads the registry, sources files
www/css/global.css          one theme for the whole app
modules/
  _module_registry.yml      groups (main tabs) + modules (subtabs), single source of truth
  API Settings/
    claude_config.R         <id>_ui() + <id>_server() in ONE file
    bq_config.R
  Communications/
    smtp_config.R
    process_contact.R
    explore_contacts.R
    customise_communication.R
    send_email.R
  Funding Programmes/
    generate_programme.R
    funding_bulk_import.R
    funding_add_single.R
    funding_browse.R
    funding_visualizations.R
    funding_about.R
```

Each module file defines exactly two functions named after its registry id:
`<id>_ui(id)` and `<id>_server(id, api_manager)`. No separate `ui.R`/`server.R`/
`manifest.yml` per module - `_module_registry.yml` holds the label/icon/order
metadata instead, and `ModuleLoader` sources the single file per module.

## Shared APIManager (R/api_manager.R)

One `APIManager$new()` instance is created per session in `global.R` and
passed into every module's server function, so all three suites see the same
live state:

- **Claude**: `claude_api_key`, `claude_model`, `call_claude(prompt, ...)`
- **BigQuery**: `bq_project_id`, `bq_dataset_id`, three table names
  (contacts / communications / funding), `bq_query()`, `bq_execute()`,
  `create_all_tables()`
- **SMTP**: connection state + `send_email()`
- **Cross-tab state**: `selected_contact`, `generated_message`, etc. as
  `reactiveVal`s, plus `state_trigger_contacts` / `state_trigger_funding` for
  cache invalidation - this is what lets Explore Contacts -> Customise
  Communication -> Send Email, and Find Programmes -> Bulk Import, hand off
  data across tabs.

## Project Application suite - integration notes

This group came from a separate "Complete_Modular_App_FINAL.zip" (a grant/proposal
builder with sections named after a UK CAM/AV-style application form: Project
Details, Business Case with 5 sections including "CAM Service", Team & Impact
with 4 sections). It shipped with its own `claude_config` module identical in
purpose to the one already in API Settings, so:

- **`claude_config` was NOT duplicated.** "Claude Diagrams" calls the exact
  same `api_manager$claude_authenticated` / `api_manager$call_claude()` that
  API Settings > Claude API Config already sets up - configure Claude once,
  it works everywhere in the app.
- **OpenAI was kept as its own subtab** (`OpenAI API Config`, renamed from the
  source's `api_config`) inside Project Application, since it's needed only
  by this group's ChatGPT-based generation buttons and Diagram Generator, and
  the request was to route only the Claude setup into the shared API tab.
- The source app's `call_openai()`/`call_claude()` had a different signature
  and return shape (plain string or `NULL`) than this app's `call_claude()`
  (throws on error, returns `list(text=, stop_reason=, truncated=)`). A
  matching `call_openai()` was added to `APIManager` with the *same* contract
  as `call_claude()`, and every generate-button handler in this group was
  rewritten (not just copy-pasted) to use `tryCatch(...)$text` accordingly.
- **Excel export stays local-file-based**, exactly as shipped: "Save to
  Excel" writes an `.xlsx` to a path on the server's filesystem via
  `openxlsx`, it does not trigger a browser download. That's fine for local/
  desktop use; on a hosted Shiny deployment the file lands on the server, not
  the visitor's computer - swap in a `downloadHandler` if you need the latter.
- Both diagram modules' "Upload Reference File" boxes had an unwired info
  output in the source app (the file was accepted but never read). A small
  `preview_uploaded_file()` helper now fills that in with basic file info;
  neither diagram generator actually sends the file's contents to the LLM
  (true vision analysis for Claude Diagrams would be a further feature, not
  present in the source code).

## Strategy Canvases suite - integration notes

This group came from a single monolithic `app.R` (`db_biz_mod_disc_ent_llm_canvas.zip`,
~3300 lines) covering a Business Model Canvas, a Disciplined Entrepreneurship
(DE) Canvas, and a 24-step DE Roadmap, each with its own "Generate with
Claude" + "view" pair of tabs, plus a Claude API Connection tab and a
BigQuery Authentication tab that were folded into API Settings per the usual
pattern (nothing new needed there - Claude auth is shared, and BigQuery Config
now also holds three more table names: BM Canvas, DE Canvas, DE Roadmap).

- **Shared taxonomy, ported as-is.** In the source app, the selection
  dropdowns for all three "view" tabs (Business Area / Project / Business
  Focus) are deliberately sourced from the **BM Canvas table only** - a
  single project identity ties its BM Canvas, DE Canvas and DE Roadmap
  together. This is preserved via `api_manager$bq_get_canvas_taxonomy()` and
  a shared `setup_canvas_selection_cascade()` helper used by all three view
  modules.
- **Inserts normalized to `bq_table_upload()`.** The source app used raw
  `INSERT INTO ... VALUES (...)` SQL with manual `gsub()` quote-escaping for
  DE Canvas and DE Roadmap (BM Canvas already used `bq_table_upload()`). All
  three now use `bq_table_upload()` with a data frame, for consistency with
  the rest of this app and to avoid manual SQL-escaping fragility.
- **DE Roadmap view was a non-functional stub in the source app** - "Load
  Data" only ever showed a placeholder notification; the 24 boxes always
  displayed the same static framework description regardless of selection
  (unlike BM Canvas view and DE Canvas view, which were fully wired to
  BigQuery). This version completes it: `de_roadmap_view.R` now genuinely
  queries and renders the 24 saved steps, using the same pattern as the
  other two view tabs.
- **Parsing made more robust for the 24-step Roadmap.** The source app
  matched each step by its exact title text via regex, which needed special-
  cased escaping for steps 22/23 (parentheses and quotes in their titles).
  This version matches by step *number* only (`[Step 7: ...]` → captures
  whatever follows "Step 7"), which is simpler and tolerates minor title
  wording drift from the LLM.

## Gantt to Tickets suite - integration notes

This group came from a self-contained modular app (`Modular_Gantt_to_PM_API_Dashboards.zip`)
that converts an uploaded Gantt-chart Excel file into Trello cards and/or
Jira issues, with email notifications and a small contact list. Unlike every
other group so far, it has **no BigQuery and no Claude API** - it uses
Trello's REST API, Jira's REST API, and its own SMTP setup (via the
`blastula` package). There was nothing to fold into API Settings this time.

- **Its SMTP and contacts are deliberately kept separate from Communications',
  not merged.** Communications already has an "SMTP Configuration" tab and a
  BigQuery-backed contacts table; this suite has its own "Email Configuration"
  tab (blastula-based, different config shape - provider dropdown, SSL
  checkbox) and its own contact list (Country/City/Organization/Full_Name/
  LinkedIn/Email/Phone/Date_Added, local-Excel-file-backed, not BigQuery).
  These are genuinely different tools with overlapping *names* but different
  schemas and storage - merging them would have silently changed behavior
  neither app asked for, so `APIManager` carries both side by side
  (`smtp_*`/`contacts_cache` for Communications vs. `gantt_smtp_config`/
  `gantt_contacts_data` for this suite) rather than sharing fields.
- **Local Excel-file contact storage preserved as-is**, same caveat as the
  Project Application suite's Excel export: the contacts file
  (`contacts_database.xlsx`) is written to the server's working directory,
  which is fine for local/desktop use but won't hand the file to a remote
  visitor's browser on a hosted deployment.
- New package dependencies for this group: `readxl`, `writexl`, `blastula`,
  `openssl`, `dplyr` (all added to `global.R`).

### A bug this integration surfaced (now fixed everywhere)

While validating this addition, a real defect was found in `R/api_manager.R`:
a trailing comma at the end of the `public = list(...)` block (left over from
an earlier edit) that would have made `APIManager$new()` fail immediately -
i.e. **the app would not have started at all**. `parse()` alone cannot catch
this class of bug (trailing commas in a `list()` call are only a runtime
error, not a syntax error), so this had slipped through every previous
"parse-check all files" pass. It's fixed now, and validation going forward
includes two extra checks specifically for this: (1) a static regex sweep of
every `.R` file for `,` immediately before a `)`, and (2) forcing full runtime
evaluation of `R/api_manager.R`'s class body by stubbing out `R6::R6Class`
with a function that actually evaluates its `public = list(...)` argument.
Both are clean across the whole app as of this delivery.

## Audio Transcription suite - integration notes

This group came from a self-contained modular app (`Modular_Audio_Text_LLM_V4.zip`):
video/audio in, Whisper transcription, ChatGPT summarization/analysis, an
analytics dashboard. Like Gantt to Tickets, it has no BigQuery/Claude, so it's
fully self-contained - its Whisper and ChatGPT keys are kept separate from
each other and from `api_manager$openai_api_key` (Project Application),
matching the source app's own design (it already kept Whisper and ChatGPT as
two distinct keys within itself).

- **Runs best locally/on-desktop, not as a typical hosted multi-user app.**
  The Video Audio Extractor and several save/output-directory pickers use
  `shinyFiles` (`shinyFilesButton`/`shinyDirButton`) for *native OS* file and
  folder browsing - this bypasses the browser upload entirely (why it can
  handle 500MB videos), but it means the Shiny process needs direct
  filesystem access on the machine it's running on. This is a different I/O
  model from every other suite in this app (which use browser-based
  `fileInput()`), carried over unchanged because rewriting it as browser
  uploads would cut the 500MB video-handling this suite was explicitly built
  around. `options(shiny.maxRequestSize = 500*1024^2)` was added app-wide in
  `global.R` to support this (was previously Shiny's 5MB default everywhere).
- **Video extraction runs in a background process** (`future`/`promises`,
  `multisession`) so it doesn't block the rest of the app while a large MP4
  is being chunked; falls back to synchronous (blocking) extraction if those
  packages aren't installed, exactly as the source app did.
- Three real bugs were found and fixed while porting (not just carried over):
  1. **Bulk Text Analysis called `api_manager$chatgpt_complete()`**, a method
     that doesn't exist anywhere in the source app's own `APIManager` (only
     `analyze_text()` does) - this button would have thrown "could not find
     function" at runtime. Now calls `analyze_text()` with the same
     system/user prompt split the source intended.
  2. **The Whisper retry loop had an infinite-loop bug**: its error handler
     updated `retry_count`/`last_error` with `<-` instead of `<<-`, which in R
     creates a local variable inside the handler's own closure rather than
     modifying the outer `while` loop's counter - so on a persistent network
     error it would retry forever at a fixed 1-second delay instead of
     stopping after 3 attempts. Fixed by moving the increment into the loop's
     own scope in `transcribe_audio()`.
  3. **The Analytics Dashboard wasn't reactive.** `api_manager$transcriptions`
     was a plain (non-reactive) data.frame; mutating an R6 field doesn't
     invalidate any Shiny reactive context, so new transcriptions wouldn't
     appear without restarting the session. Added `state_trigger_audio`
     (incremented by `add_transcription_record()`), the same pattern already
     used for contacts/funding/canvas caches elsewhere in this app.

## Receipt Processor suite - integration notes

This group came from `receipt-processor-modular.zip`: OpenAI Vision (`gpt-4o`)
extracts provider/amount/date/description from receipt photos, saves them
with descriptive filenames, logs everything to a local Excel file, and lets
you categorize and file-organize them afterward. Like the two suites above,
it's fully self-contained - `receipt_api_key` is kept separate from every
other OpenAI-flavored key in this app, matching the same reasoning throughout
(a user may want a distinct/restricted key per suite).

- **Local Excel storage, same caveat as elsewhere.** `receipt_data.xlsx` and
  the `receipts/` folder are written to the server's working directory - fine
  for local/desktop use, but on a hosted deployment the file lands on the
  server rather than the visitor's machine (the "View Processed Data" tab's
  Excel *download* button is a real browser download, though - only the
  underlying storage file itself is server-side).
- **Uses `get_folder_volumes()`**, a second, distinct folder-browsing helper
  from Audio Transcription's `get_volume_roots()` - this one additionally
  merges `shinyFiles::getVolumes()`'s auto-detected system volumes, matching
  the source app's own (slightly more thorough) implementation. Kept separate
  rather than forcing both suites onto one function.
- **Two more instances of the same `<-` vs `<<-` bug class** found and fixed:
  both `receipt_pdf_converter.R` and `receipt_to_pdf_converter.R` had error
  handlers doing `results_list[[i]] <- data.frame(...)` inside a `tryCatch`
  callback - in R this creates a local binding inside the handler's own
  closure rather than updating the enclosing loop's `results_list`, so a
  failed page/image conversion's error row was silently dropped instead of
  being recorded. Both fixed with `<<-`. (This is the same bug class as the
  Whisper retry-loop fix in Audio Transcription - worth knowing about if any
  future source app you bring in uses this same error-handler pattern.)

## Notable design decisions / assumptions made

1. **LLM provider unified on Claude.** The original Business Contact Manager
   used OpenAI; Process Contact and Customise Communication were rewritten to
   call `api_manager$call_claude()` instead, since Funding Programmes requires
   Claude and you asked for one shared LLM config.
2. **Process Contact was placed under Communications** alongside the four
   tabs you named (SMTP, Explore Contacts, Customise Communication, Send
   Email), since it's the entry point that produces the contacts those other
   tabs work with. Move or drop it by editing `_module_registry.yml` if you'd
   rather it live elsewhere.
3. **BigQuery project/dataset defaults** (`atera-2` / `business_strategy`)
   match both source apps, so all three tables live side by side with no
   config changes needed out of the box.
4. **Contact update/delete** write to the in-memory cache immediately (so the
   UI reflects the change instantly) and best-effort attempt a BigQuery DML
   `UPDATE`/`DELETE`, which is swallowed if the row is still in BigQuery's
   streaming buffer (rows are un-editable via DML for up to ~90 min after a
   streaming insert - a BigQuery platform limitation, not a bug here).

## Running

```r
shiny::runApp("BusinessOperationsSuite")
```

Required packages: shiny, shinydashboard, shinyjs, shinyWidgets, httr, curl,
jsonlite, DT, plotly, pdftools, readtext, uuid, bigrquery, DBI, glue,
base64enc, R6, yaml, openxlsx, stringr, readxl, writexl, blastula, openssl,
dplyr, av, fs, shinyFiles, magick. Optional (recommended): future, promises
(async video extraction - falls back to synchronous processing without them).
