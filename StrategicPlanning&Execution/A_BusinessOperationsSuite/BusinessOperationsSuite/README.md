# Business Operations Suite

A unified R Shiny app combining two previously separate module sets into one
grouped, registry-driven modular app:

- **Communications** (contact extraction, storage, AI messaging, email) - from
  the Business Contact Manager app.
- **Funding Programmes** (AI grant/incubator/accelerator/competition discovery)
  - from the reusable Funding Programmes suite package.

Both now share **one Claude API config** and **one BigQuery config**, grouped
under a single **API Settings** main tab.

## Sidebar structure (10 main tabs, 94 tabs)

Order: API Settings; **funding** (Funding Programmes, Project Application, Strategy Canvases); **people and time**
(Communications with Online Collaboration, Events Scheduling with Travel Planning, Day Planner, Gantt to Tickets);
**Health Tracker** (Exercise + Diet); **Media Processing** (Audio Transcription, Visual Media, Receipt Processor).

In Health Tracker and Media Processing each sidebar item has a green shade (left bar, icon, light tint) that shows which
former group it came from: Exercise lime / Diet emerald; Audio mint / Visual Media yellow-green / Receipts deep green.
Set with `tone:` on a section in `modules/_module_registry.yml`, colours in `www/css/global.css` (`.bos-tone-*`).
The Receipt Processor is one sidebar item whose six tabs are horizontal tabs. Diet's "Review" item is labelled
"Diet Review" so it is not confused with "Workout Review".

- **API Settings** - Claude, BigQuery, OpenAI (Whisper + ChatGPT), Google Drive, Titan Calendar, Debug Console
- **Funding Programmes**
  - Find & Add: Find Programmes, Bulk Import, Add Entry
  - Review: Browse Data, Visualizations, Collaboration Sync, About
- **Project Application**
  - Application Sections: 1-3 Project Details, 9-13 Business Case, 14-17 Team & Impact
  - Diagrams: Diagram Generator, Claude Diagrams
- **Strategy Canvases**
  - Business Model Canvas: Generate, View Canvas
  - Disciplined Ent. Canvas: Generate, View Canvas
  - Disciplined Ent. Roadmap: Generate, View Roadmap
- **Communications**
  - Contacts: Process Contact, Explore Contacts, From CollaborationPlanning
  - Outreach: Customise Message, Send Email, SMTP Settings
  - Online Collaboration: Slack Connection, Channels
- **Events Scheduling**
  - Find & Save Events: Scan Events, Bulk Import
  - Calendar & Invites: Events to Calendar, Zoom Schedule, Send Invites (Titan)
  - Review: Browse Events, Visualizations, About
  - Travel Planning: Travel Itinerary Planner
- **Day Planner**
  - Plan the Day: Generate Schedule, Bulk Import, Add Entry
  - Day Preparation: Generate Prep Steps, Checklist
  - Commitments: Add, Browse, Trello Config
  - Review: Browse Data, Visualizations, About
- **Gantt to Tickets**
  - Tasks: Upload Gantt, Review & Edit, Submit to Boards
  - Contacts & Email: Manage Contacts, Email Notifications, Bulk Email
  - Settings: Trello & Jira, Email (SMTP)
- **Health Tracker**
  - Workouts *(exercise tone)*: Generate Workout, Bulk Import, Add Entry
  - Muscle Building *(exercise tone)*: Programme, Log Sets, Muscle Map, Progress
  - Workout Review *(exercise tone)*: Browse Data, Visualizations, About
  - Plan & Log *(diet tone)*: Generate Diet, Bulk Import, Add Entry
  - Diet Review *(diet tone)*: Browse Data, Visualizations, About
- **Media Processing**
  - Prepare Audio *(audio tone)*: Video Audio Extractor, Converter & Splitter
  - Transcribe & Summarise *(audio tone)*: Transcription, Summary
  - Analysis *(audio tone)*: Bulk Text Analysis, Analytics Dashboard
  - PDF Tools *(visual tone)*: Splitter, Merger, Text Extractor, Image to PDF
  - AI Images *(visual tone)*: Image Generation, Further Context
  - Receipt Processor *(receipts tone)*: Settings, PDF to JPG, Convert to PDF, Upload Receipts, View Processed Data, Categorize

## Merge with DaysPlanningExerciseTravel (Nov 2026)

Events Scheduling, Day Planner, Travel Planning, Exercise Tracker, Diet Planner (36 tabs) and the Titan Calendar
sign-in come from DaysPlanningExerciseTravel (DPET). **Their code is unchanged**: the tab files are in
`modules/<group>/` as shipped, and DPET's helper files are in `R/dpet/` as shipped. The only edits are help texts
that named DPET's menus ("API Configuration >" is now "API Settings >", and "Contact Manager > Send Email" is now
"Events Scheduling > Send Invites (Titan)").

How it fits (`R/suite_dpet.R`):
- **Own helpers, no clashes.** Both apps have helpers with the same names but different code (`nav_layout`,
  `generic_export_box_ui`, `parse_programme_text`, the APIManager class ...). DPET's files are loaded into their
  own environment, so DPET tabs use DPET's versions and this app's tabs use this app's. Registry entries with
  `suite: dpet` mark the DPET tabs.
- **One set of API settings.** Each session has one DPET manager. It is connected through this app's API
  Settings with the same BigQuery service-account key, project and dataset (`atera-2.business_strategy`) and the
  same Claude key and model. If either changes there, DPET follows within about 1.5 seconds. DPET's own BigQuery,
  Claude, Google Drive and Debug tabs were not added (they would be duplicates). Titan Calendar is a new tab
  in API Settings.
- **BigQuery tables per tab group** (each tab checks its own tables the first time it is opened; results show
  in the sidebar TABLES box):

  | Group | Tables |
  |---|---|
  | Funding Programmes | funding_programmes |
  | Communications | business_contacts, contact_communications |
  | Gantt to Tickets | gantt_tasks |
  | Strategy Canvases | business_model_canvas, disciplined_entrepreneurship_canvas, disciplined_entrepreneurship_roadmap |
  | Events Scheduling | city_events |
  | Day Planner | day_scheduler, day_prep_steps, monthly_commitments |
  | Exercise Tracker | exercise_log, muscle_programmes, muscle_diagrams, muscle_set_log, muscle_targets |
  | Diet Planner | diet_log |
  | Online Collaboration, Travel, Audio, Visual Media, Receipts | none (Slack, Claude, OpenAI or local files) |

- **Other APIs per group.** Claude: Funding, Communications, Strategy Canvases, Project Application, Events,
  Day Planner, Travel, Exercise, Diet. OpenAI: Audio Transcription, Receipts, Visual Media, Diagram Generator.
  Titan (CalDAV + SMTP): Events to Calendar, Send Invites (Titan), and the Titan buttons. Slack: Online
  Collaboration. Trello / Jira: Gantt to Tickets, Day Planner > Commitments. Google Drive: every diagram tab.
- **Google Drive.** This app's tabs use the "Save diagram" bars (API Settings > Google Drive). The DPET tabs keep
  their own "Save Diagrams to Google Drive" box, which needs a service account and a shared folder. It connects
  with DPET's saved folder if there is one, or with the API Settings folder when Google Drive there is set to
  "service account". With a personal Google account sign-in, only the "Save diagram" bars save to Drive.
- **Scheduling, joined up.** With the Titan sign-in loaded, the visualisation tabs of Day Planner, Diet,
  Exercise and Events, and now also **Funding Programmes > Visualizations** (deadlines and application-open
  dates) and **Gantt to Tickets > Review & Edit** (one "Due" entry per task, on its end date), have two buttons:
  ".ics load to calendar" and "Load events into calendar". Both hand the events to Events Scheduling >
  Events to Calendar, which saves them to the Titan calendar. A Zoom screenshot in Zoom Schedule becomes an
  invitation in Send Invites (Titan).
- **Two Send Email tabs on purpose.** Communications > Send Email sends through SMTP Settings (contacts and
  outreach, with CC and calendar invitations). Events Scheduling > Send Invites (Titan) is DPET's own tab, which
  sends from the Titan mailbox and receives the Zoom and Events to Calendar invitations. Both stay as tested.
- **Slack**: `R/utils_slack.R` is now the original file again (httr2), because httr2 is loaded anyway.

Checks: `tools/merge_dpet_check.R` (21 checks: isolation, entry points, credentials passed over, tables
checked on first opening, Titan hand-off from Gantt, sidebar order).

## Merge with FundingGanttContactsCollaboration (Nov 2026)

That app holds four groups: Funding Programmes, Gantt to Tickets, Contact Manager, Online Collaboration.

- **Funding Programmes**: this app's version was kept. It already had everything that one has (time zones,
  .ics with reminders and application-open dates, Drive saving), plus the progress line and 300 s timeout in
  Find Programmes, Collaboration Sync and the configured-table About tab. Its Titan calendar buttons were not
  taken: they only work with an Events Scheduling > Events to Calendar tab, which neither app has.
- **Contact Manager** is the same group as **Communications** here (same five tabs), so it was not added
  twice. What it had in addition was merged into Communications > Send Email: a CC field and **calendar
  invitations** (an inline `text/calendar; method=REQUEST` part, so email apps show Yes / No / Maybe, plus the
  .ics attached). Sending still goes through `send_email_with_curl` to your SMTP server (Titan presets); no
  new mail package.
- **Gantt to Tickets** is the same group as here (different file names). Added from it: the task timeline
  .ics download and **Save Tasks to BigQuery** in Review & Edit, and the **Submission History** in Submit to
  Boards. Each save and each Trello/Jira submission appends rows to BigQuery `gantt_tasks` (same columns as
  that app, plus `time_zone`; an existing table from that app gets the column added). Tables unit: `gantt`.
- **Online Collaboration** (Slack Connection, Channels) was added as a new group. The bot token stays in server
  memory only. (`R/utils_slack.R` is the original file, using httr2.)
- Not taken: Titan CalDAV sign-in (`titan_auth`), Zoom invites and `mail_drafts` (they feed tabs this app does
  not have), and that app's own Drive export box (the "Save diagram" bars here already cover it).

Checks: `tools/merge_fgc_check.R` (19 checks: Gantt .ics, invitation email against a local SMTP server, Slack
layer against a mock, sidebar order).

## Architecture

```
app.R                     entry point (source global.R, shinyApp())
global.R                  libraries, module discovery, grouped-sidebar UI/server factories
R/
  api_manager.R            shared APIManager R6 class (Claude, BigQuery, SMTP,
                            funding taxonomy/parser helpers) + %||%/safe_sql_escape
  module_loader.R           ModuleLoader R6 class - reads the registry, sources files
  utils_gdrive.R            Google Drive v3 client (httr + openssl, no extra packages) + folder scheme
  utils_diagram_export.R    "Save diagram" bar: formats, Google Drive upload, zip download
www/css/global.css          one theme for the whole app
www/js/bos_diagram.js       takes the picture of a diagram in the browser (Plotly.toImage / html2canvas)
tools/                      checks: gdrive_check.R, diagram_formats_check.R, diagram_harness.R, r_e2e.js, fake_drive.py
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
- **OpenAI was originally kept as its own subtab** (`OpenAI API Config`,
  renamed from the source's `api_config`) inside Project Application, since it
  was needed only by this group's ChatGPT-based generation buttons and
  Diagram Generator. **This later moved to API Settings** (renamed "ChatGPT
  API Config") once Visual Media was added and needed to reuse the same key -
  see "API Settings consolidation" below. The underlying
  `api_manager$openai_api_key`/`call_openai()` never changed, only which tab
  configures them.
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
Trello's REST API, Jira's REST API, and its own SMTP settings (sent with curl through
`send_email_with_curl()`, the same sender as Communications; Titan / GoDaddy presets). There was nothing to fold into API Settings this time.

- **Its SMTP and contacts are deliberately kept separate from Communications',
  not merged.** Communications already has an "SMTP Configuration" tab and a
  BigQuery-backed contacts table; this suite has its own "Email Configuration"
  tab (curl-based like Communications, different config shape - provider dropdown, SSL
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
- New package dependencies for this group: `readxl`, `writexl`,
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

## Visual Media suite - integration notes

This group combines two separate source uploads:

1. A DALL-E image-generation app (`GenAI_Image_Generator_Text_Modular.zip`) -
   Image Generation (DALL-E 3/2, with dimension/aspect-ratio calculator and
   multi-format download) + Further Context (ChatGPT text rewriting).
2. A monolithic, non-modular "PDF Manager" `app.R` (uploaded directly, not a
   zip) - PDF Splitter, PDF Merger, Text Extractor, and Image to PDF. This one
   has **zero API/AI involvement** - pure local file processing via `qpdf`,
   `pdftools`, and `magick`. Confirmed by grep before porting: no `httr`,
   `api_key`, or provider-name matches anywhere in the source file.

### API Settings consolidation

Per explicit request, this addition also **relocated** the OpenAI config tab:
`Project Application > OpenAI API Config` moved into `API Settings`, renamed
"ChatGPT API Config" - API Settings is now Claude + ChatGPT + BigQuery
together. The underlying `api_manager$openai_api_key`/`openai_model`/
`call_openai()` fields are unchanged, so every suite that already depended on
them (Project Application's generation buttons + Diagram Generator) keeps
working exactly as before; only the tab's location and label changed. All
"configure your key" error messages pointing at the old location were updated
to the new one. Visual Media's Image Generation and Further Context reuse
this same shared key - **no separate DALL-E API key or settings tab** was
added, unlike every prior suite (Gantt to Tickets, Audio Transcription,
Receipt Processor), which each got their own explicitly-separate key. This is
intentional: those suites' source apps used genuinely different-shaped
credentials or the user asked for isolation; here the user asked for the
opposite - one shared "Claude + ChatGPT" hub in API Settings.

### Other notes

- **Converted from a non-modular monolith.** The PDF Manager's `app.R` used
  bare (non-namespaced) input IDs like `input$input_pdf` directly in
  `server()`/`ui()` - the same style as the very first app in this project's
  history. All four tabs were rebuilt as proper `NS()`-wrapped modules.
- **The Image to PDF tab's file-timestamp capture required care with
  namespacing.** The source used a bare JS selector (`#img_files`) and a bare
  `Shiny.setInputValue()` call to read each file's original last-modified
  time (not exposed by `fileInput()` by default, but useful for
  auto-ordering screenshots oldest-first). Inside a Shiny module the actual
  DOM id is namespace-prefixed, so this script is now built with `ns(...)`
  at UI-render time so it targets the correct namespaced element and posts to
  the correct namespaced input.
- **Upload size limit removed app-wide.** The PDF Manager's source explicitly
  disabled Shiny's upload cap (`shiny.maxRequestSize = -1`) to handle large
  PDFs/image sets. This supersedes Audio Transcription's earlier 500MB
  setting - the app now has no upload size limit at all.
- **New package dependency:** `qpdf` (PDF split/merge). `magick`, `pdftools`,
  `fs`, and `shinyFiles` were already present from earlier suites.
- **The Image Generation -> Further Context handoff** uses
  `api_manager$pending_prompt_visual_media` (a `reactiveVal`, cleared after
  being read), replacing the source app's `session$userData$transferred_text`
  mechanism - consistent with the handoff pattern already used elsewhere in
  this app (e.g. Find Programmes -> Bulk Import).

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

## Funding Programmes: exchange with CollaborationPlanning (Google Drive)

**Funding Programmes > Review > Collaboration Sync** (`modules/Funding Programmes/funding_collab_sync.R`,
`R/utils_collab_sync.R`) exchanges programmes with the CollaborationPlanning app (v0.8.0) through **its** Drive folder,
in its own formats, so neither app needs the other to change:

| Direction | What | Where in its folder |
|---|---|---|
| CollaborationPlanning -> BigQuery | its programmes list (the latest daily backup) | `Backups/<YYYY-MM-DD>/programmes.csv` |
| CollaborationPlanning -> BigQuery | programmes in its Claude analyses (rows of tables with a programme column, or the analysis's own programme) | `<Country>/<Category>/<Topic>/<programme>__<id>.json` |
| this app -> CollaborationPlanning | our programmes, one analysis each (`bos_<id>`, a Field/Value table, classification Country > Category > Topic > Programme) | same place and format; there: Analysis library > **Read from Drive** |

- **Reach the folder** (API Settings > Google Drive > *CollaborationPlanning folder*): *Google Drive API* with a
  service account that is a member of its Shared Drive (the same key as CollaborationPlanning, or the keys-folder key),
  or *a folder on this computer* synced by Google Drive for desktop. Saved in `bos_config.json` under `"collaboration_planning"`.
- **Import:** *Read from Drive* shows a preview: **New**, **Repeated** (same programme name and funder/sponsor already in
  `funding_programmes`, or earlier in the list) and **Already imported** (that very record was loaded before).
  *Load into BigQuery* loads New and Repeated rows; repeated ones carry `repeated = TRUE` and are highlighted in amber in
  Browse Data (which also gets a *Show* filter). Columns added to `funding_programmes` (once, like `time_zone`):
  `source` (`CollaborationPlanning backup` / `CollaborationPlanning analysis`), `source_ref` (its programme or analysis id)
  and `repeated`. Its columns are mapped: `closes_date`/`deadline_text` -> `deadline`, `opens_date` -> `start_date_for_applying`,
  `funder` + `key_sponsors` -> `key_sponsors`, `amount_text` or `min_gbp`-`max_gbp` (+ funding rate) -> `amount_of_money`,
  `summary` + `conditions` -> `conditions`, `themes` -> `areas_of_application`, `recommendations`, `verified_urls` + `source_url`.
  Its dates have no zone; they are loaded as Europe/London (that app works in UK time). Example rows are skipped.
- **Share:** programmes added in this app (or all), optionally by country/category. Re-sharing updates the same file
  (and moves it when the classification changed). Our own shared analyses are never imported back.
- Checks: `tools/collab_sync_check.R` (48 checks, local folder and Drive API, against CollaborationPlanning's **own**
  `R/drive.R`, `R/analysis.R`, `R/programmes.R`: its code writes what we read, and reads what we write) and
  `tools/collab_sync_server_check.R` (8 checks of the tab: Read, Load, Share).

## CollaborationPlanning: full compatibility (tables, Drive, contacts, Trello) - Nov 2026

CollaborationPlanning (v0.8.0) is the app other people use to explore funding and collaboration. On top of the Drive
exchange above, this app now reads **and writes** its tables and shares its Drive areas:

| Area | CollaborationPlanning | This app |
|---|---|---|
| Programmes list (`cp_programmes`, + its Google Sheet) | Discover | **Collaboration Sync**: read (import into `funding_programmes`, repeats marked) and write (add our programmes; funder + name already there are skipped by its own `add_programmes`) |
| Analyses (`cp_analyses`, + Sheet) | Suggestions > Analysis library | read programmes from them; write ours as `bos_<id>` analyses (shown there at once; newest version wins; visible to the *share with* emails by its own access rule) |
| Drive `<Country>/<Category>/<Topic>/` | its analysis files | analysis files as before **plus** funding outputs: "Save to Google Drive" on Funding > Visualizations also copies the files there, and Browse Data > *To CollaborationPlanning folder* writes one CSV per country + category. Names never contain `__` and are never `.json`, so its reader does not take them for analyses |
| Drive `Backups/<date>/` | daily copy of every table | read (programmes) |
| People (`cp_people`) and messages (`cp_messages`) | Team up > Collaborators, Outreach, Inbox | **Communications > Contacts > From CollaborationPlanning**: import into `business_contacts` (`cp_<person_id>`) and `contact_communications` (`cp_<message_id>`); same email or same name + organisation = **Repeated** (`repeated = TRUE`, amber in Explore Contacts); messages are linked to our own contact when the email matches. Nothing is written back (our contacts stay private) |
| Trello board | Deliver > Trello board: one card per task, updated by card id | **Gantt > Submit to Boards** now updates its cards on resubmit (found by id, or by name on the board) instead of adding duplicates, sets the due date, and *Read status back* takes Done / In Progress / Blocked from the list. Cards CollaborationPlanning made (its "From Collaboration Planning task" mark) are never touched, so both apps can use the same board |
| Email | its own SMTP settings (Titan) | unchanged: both send through Titan with their own settings; no conflict |

How the tables are reached (`R/suite_cp.R`): CollaborationPlanning's own storage files are in `R/collab_planning/`
**unchanged** (config, utils, google_sheets, bigquery, store, programmes, analysis, collab) and run in their own
environment, so every read and write follows its rules (columns, ids, latest-version-wins, change log). BigQuery uses this
app's connection (same project; dataset and prefix as there, default `business_strategy` / `cp_`); its Google Sheet, when
it has one, is opened with the CollaborationPlanning service-account key. **If it uses a Sheet, give its id** in
API Settings > Google Drive > CollaborationPlanning: it reads from the Sheet, so rows written only to BigQuery would not
show there. *Test its tables* checks the connection.

Checks: `tools/cp_tables_check.R` (28: its own storage code on an in-memory BigQuery and Sheet - reads, writes, duplicate
rules, visibility, change log, people/messages, folder outputs ignored by its own Drive reader), `tools/trello_check.R`
(6, against `tools/fake_trello.py`), `tools/collab_sync_server_check.R` (8).

## Funding Programmes: time zones and calendars

Brought over from DaysPlanningFundingTravel (it writes the same `funding_programmes` table) and taken further:

- **Time zones** (`R/utils_timezone.R`): Find Programmes, Add Single Entry and Bulk Import have a 30-zone dropdown that
  starts on this computer's zone. Claude is told to write every date and time in it; generated text starts with a
  `[time_zone]: <zone>` line (kept through editing and Copy to Bulk Import); each programme is saved with a
  `time_zone` column, added to older tables automatically (`APIManager$bq_ensure_time_zone_column`, once per
  connection, together with `source`, `source_ref` and `repeated`; if the account may not alter the table but the column exists, saving still works). Rows saved
  before this have no zone and are read as `America/Mexico_City` - the same rule as DaysPlanningFundingTravel.
- **Calendar (.ics)** (`R/utils_ics.R`): Visualizations ("Save These Programmes" > Add to Calendar) and Browse Data
  (Calendar button) export deadlines - timed when the deadline has a time, all-day otherwise - and, optionally,
  application-open dates, in each programme's saved zone, with reminders 7 days and 1 day before (1 hour before
  timed deadlines). Re-importing updates entries instead of duplicating them. Browse Data uses this engine too
  (DaysPlanningFundingTravel's Browse still uses the older exporter in `R/utils_calendar_export.R`).
- Kept from this app: the Save diagram bars (Google Drive), Find Programmes' live progress text and longer Claude
  timeout, and the About tab showing the configured table.
- Not brought over: the Titan calendar buttons. They hand events to DaysPlanningFundingTravel's Events to Calendar
  tab and Titan sign-in (a CalDAV calendar suite of about 1,700 lines), which this app does not have.

Check: `Rscript tools/funding_tz_ics_check.R` (18 checks: parser + header, prompt, calendar events, reminders, UTC
conversion, default zone).

## Saving diagrams to Google Drive

Every tab that shows a diagram has a **Save diagram** bar under it: tick the formats, then **Save to Google
Drive** or **Download (zip)** (the zip holds the same folder layout).

| Group | Tab | Diagram(s) |
|---|---|---|
| Funding Programmes | Visualizations | Overview tiles, Programmes by Category (plotly) |
| Project Application | Diagram Generator, Claude Diagrams | the generated SVG / HTML / Mermaid diagram |
| Strategy Canvases | View Canvas (BM and DE), View Roadmap | the whole canvas (the template when nothing is loaded) |
| Audio Transcription | Analytics Dashboard | Word Count Distribution, Processing Time (plotly) |

Formats: **HTML** (the interactive plotly chart, the generated diagram's own page, or for canvases a page with
the picture and the box texts), **PDF** (one A4 page), **PNG**, **JPG**, **GIF**, **TIFF**, **SVG** (the real
vector SVG for SVG diagrams, else the picture inside an SVG), **CSV** (the numbers or box texts) and **Source**
(Mermaid `.mmd`). The picture is taken in the browser (`www/js/bos_diagram.js`: `Plotly.toImage` for charts,
html2canvas from the jsdelivr CDN for everything else) and converted with magick.

Folder scheme on Drive; every missing folder is created on the first save and reused afterwards; files are never
overwritten (the time is in the name):

```
<root folder>/BusinessOpsSuite/<Group>/<Section>/<Tab>/<YYYY>/<YYYY-MM>/[<format>/]<tab_id>_<diagram>_<YYYYMMDD_HHMMSS>.<ext>
<root folder>/BusinessOpsSuite/_manifest.csv   one row per file (time, group, section, tab, tab_id, diagram, format, name, folder, file id, link, size, type, note)
<root folder>/BusinessOpsSuite/_README.txt     this scheme, for whoever opens the folder
```

Group / Section / Tab are the sidebar names from `_module_registry.yml`, e.g.
`Strategy Canvases/Business Model Canvas/View Canvas/2026/2026-11/bm_canvas_view_business_model_canvas_..._20261122_130555.pdf`.
The Android app uses the same names and scheme, so both can share one Drive folder and one manifest.
Each file also carries `appProperties` (`bos_group`, `bos_section`, `bos_tab`, `bos_tab_id`, `bos_diagram`,
`bos_format`, `bos_created_utc`). Reading them from another Shiny app:

```r
library(googledrive)
m <- read.csv(text = drive_read_string(drive_get("BusinessOpsSuite/_manifest.csv")))
canvases <- drive_find(q = "appProperties has { key='bos_tab_id' and value='bm_canvas_view' }")
drive_download(as_id(tail(m$file_id, 1)), path = "latest.html", overwrite = TRUE)
```

**API Settings > Google Drive** (`modules/API Settings/gdrive_config.R`). Settings are stored in the keys folder
as the `"google_drive"` section of `bos_config.json` (the other sections are kept; the Android app reads the same file).

- *Google account*: create an OAuth client of type **TVs and Limited Input devices** (Drive API enabled), enter
  its ID and secret, press *Sign in with Google* and enter the code shown at google.com/device. This sign-in uses
  the `drive.file` scope, so leave *Root folder* empty (the app folder is made in My Drive) or use a folder the app
  made; to write into an existing folder, paste a refresh token with the full `drive` scope.
- *Service account*: the BigQuery key from the keys folder, or another JSON key. Service accounts have no Drive
  storage: the root folder must be in a Shared Drive with the service account as Content manager (or use *Act as
  user* with Workspace domain-wide delegation).
- *Test connection* signs in, checks the folder and creates the app folder + `_README.txt`; *Test upload* writes
  and deletes a small file. The tab also lists the files uploaded in this session.

Checks (run from the app folder; `fake_drive.py` is a stand-in for Google's servers):

```
python3 tools/fake_drive.py 8899 &
Rscript tools/gdrive_check.R 8899 path/to/service_account.json   # 39 checks: sign-in, folders, uploads, manifest, retries, errors
Rscript tools/diagram_formats_check.R                              # 18 checks: every format, read back with magick / pdftools
```

`tools/diagram_harness.R` + `tools/r_e2e.js` (Playwright) drive the real app and the harness in Chromium against the
fake server: plotly, SVG, Mermaid, HTML-in-iframe and canvas captures, zip download, the Google Drive tab and the
device sign-in (15 checks).

## Running

```r
shiny::runApp("BusinessOperationsSuite")
```

Required packages: shiny, shinydashboard, shinyjs, shinyWidgets, httr, curl,
jsonlite, DT, plotly, pdftools, readtext, uuid, bigrquery, DBI, glue,
base64enc, R6, yaml, openxlsx, stringr, readxl, writexl, openssl,
dplyr, av, fs, shinyFiles, magick, qpdf, and for the DaysPlanningExerciseTravel tabs purrr, tidyr, httr2, gargle,
xml2, png (the same packages that app uses); email is sent with the `curl` command-line tool (built into
Windows 10/11, macOS and most Linux) - blastula is no longer needed (Google Drive saving adds none: it uses httr, openssl, jsonlite, magick
and zip, which openxlsx already installs). Optional (recommended): future,
promises (async video extraction - falls back to synchronous processing
without them).
