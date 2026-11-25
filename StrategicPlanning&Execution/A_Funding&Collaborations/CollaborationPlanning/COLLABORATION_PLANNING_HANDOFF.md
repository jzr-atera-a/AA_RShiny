# Collaboration Planning: handoff (phases 1 to 5 built)

This file describes the whole **Collaboration Planning** R Shiny app. Phases 1 to 5 are now built (version
`0.5.0`). Section 12 lists what changed from the specs below and the rules learnt while building them; read it before
changing code. Sections 1 to 11 are the original phase 1 handoff, kept as the design record.

- **App zip:** `CollaborationPlanning_v0.5.0.zip` (version `0.5.0 (phases 1 to 5)`)
- **Design doc:** "Collaboration Planning: integrated design for funding, collaborators and execution" (claude.ai artifact)
- **Source apps** (separate zips, ask the user for them when a phase needs one): `Funding_programmes.zip`,
  `grant_compass.zip`, `BusinessOperationsSuite.zip`, `BooksNetworksStrategySixS.zip`, `VentureDeals_p.zip`
- **Also follow:** `Modular_RShiny_Improvement_Guide.md` in the "Modular RShiny" project

---

## 1. Purpose

One app that takes a funding programme from first find to a delivered project, in eight stages:

| # | Stage | What happens | Built in |
|---|---|---|---|
| 1 | Discover | Find programmes (live web search), import, browse, charts | Phase 1 (browse), phase 2 (rest) |
| 2 | Qualify | Eligibility check, team fit scoring, ranking, go/no-go tree | Phases 2 and 3 |
| 3 | Team up | Collaborators, partner match, outreach, consortium per bid | Phase 3 |
| 4 | Decide | Written decisions (Driver, Approver), decision log, ideas, meet by exception | Phase 3 |
| 5 | Plan | Project from a "go", work packages and Gantt, RACI, risks, budget by partner | Phase 4 |
| 6 | Write | Question sets (built), section drafts, canvases, submit checklist | Phase 1 (question sets), phase 4 (rest) |
| 7 | Deliver | Trello board, weekly updates, milestones and claims, reminders | Phase 5 |
| 8 | Learn | Outcome per bid, reviewer feedback, lessons, win rate | Phase 5 |

Plus **Home** (pipeline board) and **Admin** (settings, admins only).

## 2. Decisions already made by the user (do not change without asking)

| Topic | Decision |
|---|---|
| Name | Collaboration Planning |
| Storage | **Both** BigQuery and a Google Sheet. Writes go to both; reads from the Sheet, else BigQuery, else local CSV (testing) |
| Sign-in | Like VentureDeals: approved emails in the Sheet tab `allowed_emails`, roles, 5 attempts then a 5-minute lock, every attempt logged |
| Roles | `admin`, `member`, `partner`. Emails in `ADMIN_EMAILS` are always admins |
| Hosting | shinyapps.io |
| Admin | All API and general settings live in the Admin group, visible to admins only. Opening it needs code **7818** (`CP_ADMIN_CODE`) unless the app runs on **Windows** (`.Platform$OS.type == "windows"`), where no code is asked |
| Task boards | Trello |
| Question sets | Innovate UK Smart, CAM Pathfinder, Frontier AI loaded as examples, marked "Example" |
| Older apps | Not retired. Admin > Previous apps explains them |

## 3. Running it

```r
source("install.R")   # shiny, bslib, DT, R6, yaml, httr, jsonlite, openssl, base64enc, htmltools, bigrquery (optional)
shiny::runApp()
```
Testing mode (no Google set-up) keeps tables as CSV in `data/`. Sign in with `joseph.zr@atera-analytics.co.uk`
(seeded from `ADMIN_EMAILS`). Variables are listed in `.Renviron.example`.

## 4. Architecture

```
app.R                     UI shell, sign-in gate, admin lock, builds ctx, starts every module server
global.R                  library() block (deployment list), sources R/ in a fixed order, loader, store_init()
R/_disable_autoload.R     stops Shiny auto-sourcing R/ (sourced once by global.R)
R/config.R                cfg (env vars), IS_WINDOWS, CLAUDE_MODELS, SETTING_DEFAULTS, STAGES, SCHEMAS, CORE_TABLES
R/utils.R                 %||%, now_ts, new_id, is_true, blank, safe_sql_escape, conform, latest_by, log_debug,
                          UI helpers: note(), card(), status_pill(), example_badge()
R/google_sheets.R         Sheets REST API with a service-account JWT (no googlesheets4): gs_read, gs_append,
                          gs_write_all, gs_ensure_tab, gs_list_tabs
R/bigquery.R              bigrquery wrapper, all columns STRING, tables named <CP_BQ_PREFIX><table>:
                          bq_read, bq_append, bq_write_all, bq_ensure_table, bq_read_external
R/store.R                 storage interface (section 5), settings, users
R/seed.R                  first admin + example question sets (only when the table is empty)
R/programmes.R            map_programme_columns() (old app columns -> programme record), add_programmes() (dedup)
R/integrations.R          session keys (server memory), claude_ping(), trello_get(), trello_boards()
R/auth.R                  login_ui/auth_server, admin_lock_ui/admin_lock_server
R/module_loader.R         ModuleLoader R6: scans modules/<Group>/<id>.R, reads headers, sources enabled files
R/nav.R                   sidebar links, group band, horizontal sub-tabs, "Coming next" card
modules/_module_registry.yml  groups (sidebar order, sub-tabs, planned sub-tabs), modules (enabled flags)
modules/<Group>/<id>.R    one file per sub-tab
www/styles.css            Grant Compass look (navy #0b2a3c / #0f4a5c, teal #1a9aa8, cyan #22c3d6), sidebar layout
www/mark.png              logo
auth/                     google_service_account.json goes here (never commit)
data/                     CSV tables in testing mode
```

### 4.1 Sidebar groups and current sub-tabs

| Group id | Label | Folder | Built sub-tabs (module ids) |
|---|---|---|---|
| home | Home | `modules/Home` | `home_board` |
| discover | 1 Discover | `modules/Discover` | `programmes_browse` |
| qualify | 2 Qualify | (create `modules/Qualify`) | none |
| teamup | 3 Team up | (create `modules/Team up`) | none |
| decide | 4 Decide | (create `modules/Decide`) | none |
| plan | 5 Plan | (create `modules/Plan`) | none |
| write | 6 Write | `modules/Write` | `question_sets` |
| deliver | 7 Deliver | (create `modules/Deliver`) | none |
| learn | 8 Learn | (create `modules/Learn`) | none |
| admin | Admin | `modules/Admin` | `admin_access`, `admin_storage`, `admin_claude`, `admin_trello`, `admin_general`, `admin_data`, `admin_previous_apps`, `admin_activity` |

Groups with `planned:` items and no `modules:` show "soon" in the sidebar and a "Coming next" card.
**When you build a planned sub-tab, remove its line from `planned:`.**

### 4.2 Module file format (follow exactly)

```r
# ---- module ----------------------------------------------
# id:           eligibility_check
# name:         Eligibility check
# icon:         clipboard-check
# description:  One line
# packages:     shiny, DT
# -----------------------------------------------------------

eligibility_check_ui <- function(id) {
  ns <- NS(id)
  tagList(...)
}

eligibility_check_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns   # define ns if renderUI builds inputs
    ...
  })
}
```
- File name = `id` = function prefix. The loader warns if the header `id` differs.
- `name` is the sub-tab label, `icon` a Font Awesome name (shiny::icon).
- Register it: add the id to the group's `modules:` list **and** to `modules:` (`{ enabled: true }`) in
  `_module_registry.yml`. The sub-tab's input namespace is its id (inputs are `<id>-<name>` in the browser).
- No new files in `R/` for one tab's logic. Shared logic goes in an `R/` helper only if two or more tabs use it,
  and then add it to the `source()` list in `global.R`.

### 4.3 The `ctx` object every server receives

| Member | Type | Use |
|---|---|---|
| `ctx$user()` | reactive chr | signed-in email (use for `added_by`, change log) |
| `ctx$auth$name()`, `ctx$auth$role()` | reactive chr | display name; `admin` / `member` / `partner` |
| `ctx$is_admin()` | reactive lgl | role is admin |
| `ctx$admin_ok()` | reactive lgl | admin **and** unlocked (code or Windows). Guard every admin action with `req(ctx$admin_ok())` |
| `ctx$data$programmes()`, `$question_sets()`, `$users()`, `$login_log()`, `$changelog()` | reactive df | cached reads, refreshed every 30 s and after `ctx$bump()` |
| `ctx$tick()` | reactive | depend on it to refresh any other `store_read()` |
| `ctx$bump()` | function | call after every write so all tabs refresh |
| `ctx$settings()` | reactive list | `SETTING_DEFAULTS` overlaid with the `settings` table |
| `ctx$nav(group, sub)` | function | jump to a group and sub-tab, e.g. `ctx$nav("decide", "decisions")` |

For a new table, read it with `reactive({ ctx$tick(); store_read("decisions") })`, or add it to `ctx$data` in `app.R`
if three or more tabs use it.

## 5. Storage rules

```r
store_read(tab, fresh = FALSE)        # data frame with exactly SCHEMAS[[tab]] columns, all character
store_append(tab, df, user)           # appends to Sheet AND BigQuery (CSV in testing mode); logs to changelog
store_replace(tab, df, user, detail)  # rewrites the whole table everywhere (edits, deletes)
set_setting(key, value, user); get_settings()
get_users(); user_record(email); is_admin_email(email)
log_change(user, action, entity, detail)
```
- **Every column is text.** Dates are ISO `YYYY-MM-DD`, times `YYYY-MM-DD HH:MM:SS` (`now_ts()`), booleans
  `"TRUE"`/`"FALSE"` (test with `is_true()`), numbers as plain strings (`as.numeric()` when used).
- **Adding a table:** add its columns to `SCHEMAS` in `R/config.R`. The Sheet tab and BigQuery table are created on
  first use with that header. Never rename or reorder existing columns: append new columns at the **end** only,
  and add them to the existing Sheet tab header and BigQuery table (`ALTER TABLE ... ADD COLUMN x STRING`).
- **Prefer append-only with "latest row wins"** for things people change often (`priorities`, votes, decision inputs,
  settings): append a new row with a fresh `updated_at`, read with `latest_by(df, keys)`. Use `store_replace()`
  only for small tables or real edits.
- IDs: `new_id("dec")`, `new_id("proj")` and so on.
- Any SQL text built by hand must use `safe_sql_escape()` (BigQuery uses backslash escapes).
- Tables already defined for later phases: `priorities`, `eligibility`, `consortium`, `messages`, `decisions`,
  `projects`, `tasks`, `weekly`, `outcomes`. Extend them as the specs below say. Still to add: `ideas`, `idea_votes`,
  `decision_options`, `decision_inputs`, `raci`, `risks`, `answers`, `budget`.

### Programme record (`programmes`)
`programme_id, programme_name, funder, category, country, city_region, summary, themes, conditions, key_sponsors,
key_organiser_profiles, amount_text, min_gbp, max_gbp, funding_rate_pct, opens_date, closes_date, deadline_text,
rolling, recommendations, verified_urls, source_url, verified_at, verified_by, stage, owner, source, is_example,
added_by, added_at, updated_at`

- `stage` is one of `STAGES`. Moving a programme = `store_replace("programmes", ...)` with that row's `stage` changed.
- `verified_at` blank, or older than the `verify_days` setting = show "check at source".
- Dedup key = funder + name, lower-case alphanumerics (`programme_key()`); use `add_programmes()` to add.

## 6. Conventions

- Look: `card(title, ...)`, `note("ok"|"warn"|"bad"|"info", ...)`, buttons `class = "btn-brand"` (primary) or
  `"btn-ghost"`, `example_badge()`, `status_pill()`. Use `layout_columns(col_widths = ...)` for columns. No new colours.
- Writing style in the UI: plain British English, short sentences, no jargon, no emoji.
- Show errors with `note("bad", safe_error_text(e))` and log them with `log_debug("[Tab] ...")`.
- Secrets (API keys, tokens) are never written to the Sheet, BigQuery, the browser or the change log. They come from
  env vars or `session_key_set()` (server memory). Read them with `claude_key()`, `trello_key()`, `trello_token()`.
- Partners: when a tab shows bid data, a partner (`ctx$auth$role() == "partner"`) sees only programmes where they
  are in `consortium` (any status except `declined`). Members and admins see everything.
- Don't add features the user didn't ask for. Don't rename visible text without reason. Don't split files
  into many small ones.

## 7. Claude calls (phase 2 onwards)

Create one shared helper `R/claude.R` (add to `global.R`) used by every tab:

```r
claude_call <- function(prompt, system = NULL, max_tokens = 4000, web_search = FALSE, model = get_settings()$claude_model)
```
- POST `https://api.anthropic.com/v1/messages`, headers `x-api-key: claude_key()`, `anthropic-version: 2023-06-01`.
- When `web_search = TRUE` (and the setting `claude_web_search` is true) add the server web search tool:
  `tools = list(list(type = "web_search_20250305", name = "web_search", max_uses = 8))`. Check the current tool
  version name in the Anthropic docs (docs.claude.com) before coding; it may have changed.
- Join all `text` blocks of the reply; keep any citation URLs returned with the text.
- Time out after 120 s; return a clear error the tab can show. Log the model and token use with `log_debug()`.
- Models allowed: `claude-sonnet-5-5` (default), `claude-opus-5-5`, `claude-haiku-5-5`.

## 8. Specs for the pending tabs

Each spec gives the tab id, folder, source to port, behaviour and "done when". Build one phase at a time, and test
each one (section 9) before starting the next.

### Phase 2: Discover and Qualify

**`programme_search`**, Discover, "Live search". Port from Funding Programmes `modules/generate_programme`
(and BOS `modules/Funding Programmes/generate_programme.R`).
- Inputs: category (Grant/Incubator/Accelerator/Competition/other), country, city or region (default "All"),
  focus text, number of results (1 to 8).
- Calls `claude_call(..., web_search = TRUE)`. The prompt must ask for the bracket-tag format the old app parses
  (see `parse_programme_text()` in Funding Programmes `R/utils_common.R`, or BOS `R/api_manager.R`) **plus** one source URL per programme and per date
  and amount, and must say: only include programmes found on a live page, never from memory.
- Show results as cards with a checkbox each; "Save selected" maps them with `map_programme_columns()` and calls
  `add_programmes()`, setting `source = "Live search"`, `verified_at = now_ts()`, `verified_by = "Claude web search"`.
- Programmes with no source URL are saved with `verified_at` blank (shown as unverified).
- Done when: a search returns programmes with links, saving twice adds no duplicates.

**`programme_bulk_import`**, Discover. Port `modules/bulk_import` (bracket-tag text pasted, parsed, previewed, saved).
Keep the CSV upload in `programmes_browse` as it is.

**`programme_add`**, Discover, "Add entry". Port `modules/add_single`, with date inputs for `opens_date` and
`closes_date`, a "rolling" checkbox and numeric `min_gbp`/`max_gbp`.

**`programme_charts`**, Discover, "Charts and calendar". Port `modules/visualizations` (filters for category,
country, region, date ranges; counters; chart by category). Add a **deadline calendar**: programmes at Qualify or
later by `closes_date`, plus a `.ics` download of the deadlines (one VEVENT per programme, with a VALARM 7 days before).
Rolling programmes must still appear when no date filter is set.

**Re-check in `programmes_browse`**: add a "Re-check at source" button in the detail card. It calls Claude with web
search on `source_url`, shows what changed (amount, dates, status) side by side, and on "Accept" updates the row
and sets `verified_at`/`verified_by`. Remove "Live web search", "Bulk import", "Add entry" and "Charts..." from
`planned:` in the registry.

**`eligibility_check`**, Qualify, new.
- Pick a programme (Discover or Qualify stage). Split its `conditions` into separate conditions (Claude, or split on
  `;` and new lines). For each, Claude compares it with the `company_profile` setting and returns
  met / unclear / not met + one line of evidence. People can override each result.
- Save to `eligibility` (append; latest per programme + condition wins).
- Any "not met" marks the programme **ineligible**: it shows a red badge everywhere and cannot be moved to Decide
  (enforce in every stage-move control). Done when: the gate stops a move and says why.

**`team_scoring`**, Qualify. Port Grant Compass `R/mod_prioritise.R`.
- Each person scores alignment, interest, capability (1 to 5), picks a stance (lead / partner / watch / pass) and a note.
- Save to `priorities` (append, latest per email + programme_id). Fit score = Grant Compass `calc_score()`:
  `round((w1*a + w2*i + w3*c) / (w1+w2+w3) * 20)`, weights from settings `w_alignment`, `w_interest`, `w_capability`.
- Partners do not score in phase 2.

**`team_ranking`**, Qualify. Port the ranking view from `mod_prioritise.R`: average fit score, number of scorers,
stance counts, eligibility badge, closing date. A "Move to Team up" button for Lead/Partner programmes.

**Home board**: show the fit score and an ineligible badge on each card.

### Phase 3: Team up and Decide

**Tables:** extend `allowed_emails`? **No.** Keep `allowed_emails` for sign-in only; people who are contacts but
don't sign in go in a new `people` table:
`person_id, email, name, organisation, role_title, type (team|partner|contact), interests, past_projects, phone,
linkedin, notes, source, added_by, added_at, updated_at`. Use `email` to join with `allowed_emails`.

**`collaborators`**, Team up. Port BOS `modules/Communications/process_contact.R` (Claude reads a CV, signature or
pasted text into contact fields) and `explore_contacts.R` (browse and filter). Save to `people`. A button "Invite to
sign in" adds them to `allowed_emails` with role `partner` (admins only).

**`partner_match`**, Team up, new. For a chosen programme, rank `people` by overlap between their `interests` and
`past_projects` and the programme's `themes` and `conditions` (simple word overlap first; Claude explanation as an
option). "Add to consortium" adds a row with status `asked`.

**`outreach`**, Team up. Port BOS `customise_communication.R` (message by channel and purpose) and `send_email.R`
(SMTP; SMTP settings go into a new Admin sub-tab `admin_email`, port `smtp_config.R`). Save messages to `messages`
with `programme_id`.

**`consortium`**, Team up, new. Per programme: partners, role (lead / partner / subcontractor), status
(asked / interested / committed / declined), budget share %, documents owed (letter of support, finance form...).
Warn when shares don't add to 100%. Save to `consortium` (append, latest per programme + email).

**`decisions`**, Decide. Port Grant Compass `R/mod_decisions.R` with `collab_helpers.R`.
- Decision fields as in Grant Compass, with `linked_grant` renamed `programme_id`; add tables `decision_options`
  (`decision_id, option_id, label, detail, created_at`) and `decision_inputs`
  (`decision_id, email, option_id, stance (support|concern|object), comment, updated_at`, latest per decision + email).
- Rules from settings: `blind_input` (hide others' inputs until you add yours), `decision_days`, `silence_agrees`.
- "Decide whether to bid" button (in `team_ranking` and the Home card) creates a decision with options Go / No go,
  pre-filled with the fit score, eligibility results and the go/no-go tree value.
- Recording outcome **Go** moves the programme to Plan and creates a `projects` row (phase 4 uses it).
  **No go** moves it to Learn with result "not pursued".

**`decision_log`**, Decide. Port `R/mod_declog.R`. **`ideas`**, Decide. Port `R/mod_ideas.R` (+ tables `ideas`,
`idea_votes`, add `programme_id`). **`meet_by_exception`**, Decide. Port `R/mod_meet.R`.

**`go_no_go`**, Qualify. Port the decision tree from BooksNetworks `R/utils_decision_tree.R` (expected value
rolled back in R). Fixed template: Bid (cost of writing, negative) -> chance node Win (probability, grant value) /
Lose (0); Don't bid (0). Inputs pre-filled from the programme (`max_gbp`, `funding_rate_pct`) and the team's
estimate. Show expected value of bidding vs not; save the inputs with the decision.

**Partner view**: in every tab, partners only see their consortium programmes (section 6). Done when a partner can sign
in, see one bid, weigh in on its decision, and nothing else.

### Phase 4: Plan and Write

**Tables:** `projects` exists. Add `raci` (`project_id, task_id, email, letter (R|A|C|I), updated_at`),
`risks` (`risk_id, project_id, risk, cause, effect, likelihood 1-5, impact 1-5, owner_email, mitigation, status,
updated_at`), `budget` (`project_id, partner, category, amount_gbp, funded_pct, note, updated_at`),
`answers` (`project_id, set_id, question_no, version, text, words, updated_by, updated_at`).

**`work_packages`**, Plan. Port BOS `modules/Gantt to Tickets/upload_gantt.R` and `review_edit.R`.
- New projects get work packages from a template by programme category (Project management; Technical work;
  Testing and validation; Dissemination and exploitation), editable. Excel Gantt upload still works.
- Save to `tasks`; show a Gantt chart (plotly timeline or a DT with bars).

**`raci`**, Plan. Grid of tasks by consortium people, one letter per cell. Exactly one **A** per task (warn otherwise).
**`risk_register`**, Plan. Port the FMEA/risk idea from BooksNetworks Six Sigma (`modules/Six Sigma Analysis`):
score = likelihood x impact, colour by score, sort by score.
**`budget`**, Plan. Per partner and cost category; totals, grant at `funding_rate_pct`, check against the
programme's `max_gbp` and the consortium shares.

**`section_drafts`**, Write. Port BOS `modules/Project Application/project_details.R`, `business_case.R`,
`team_impact.R`, but driven by `question_sets` instead of fixed CAM questions:
- Pick project -> pick question set -> one text box per question with a live word count against `word_limit`
  (red when over).
- "Draft with Claude" per question uses: the programme record, company profile, consortium, work packages, risks
  and budget. Save every save as a new `version` in `answers`. Download all answers as .docx or .md.
**`canvases_diagrams`**, Write. Port BOS `Strategy Canvases/bm_canvas_*.R`, `de_canvas_generate.R`, and
`Project Application/diagram_generator.R`, `claude_diagrams.R`, keyed to `project_id`.
**`submit_checklist`**, Write, new. Per project: every question under its limit, budget adds up, all consortium
documents received, eligibility all met, deadline. "Mark submitted" sets the project status `submitted`.

### Phase 5: Deliver and Learn

**`trello_board`**, Deliver. Port BOS `submit_boards.R` (Trello part only). Sends `tasks` of a project to the board
in the `trello_board_id` setting: one list per work package, one card per task with due date and description;
stores `trello_card_id` so re-sending updates instead of duplicating. A "Pull status" button reads card
list/completion back into `tasks$status`.
**`weekly_updates`**, Deliver. Port Grant Compass `R/mod_weekly.R`, with `project_id`. "Blocked" items raise a flag on Home.
**`milestones`**, Deliver. Milestones and grant claim dates per project, with status; a missed milestone creates a
decision ("Milestone X missed: what now?").
**`reminders`**, Deliver. Port BOS `email_send.R` / `email_configuration.R`: email owners about tasks due in 7 days and
decisions closing. Triggered by a button (shinyapps.io has no scheduler); show what was sent.
**`outcomes`**, Learn. Per finished bid: result (won / lost / withdrawn / not pursued), score, reviewer feedback,
lessons. Save to `outcomes`; move the programme to Learn.
**`win_rate`**, Learn. Win rate by funder, category and theme; average fit score of won vs lost bids (to tune the
weights in Admin > General settings).

## 9. How to test each phase (required before delivering)

1. Start from an empty folder in testing mode (delete `data/*.csv`): `Rscript -e 'shiny::runApp(port=4321)'`.
   The start-up log must have no warnings and `loader warnings: 0`.
2. Drive the app headless with Playwright (Chrome): sign in as the seeded admin, open every group and sub-tab,
   screenshot each, use each new feature once, including awkward text (apostrophes, new lines, accents).
   Selectize dropdowns: set them with `Shiny.setInputValue('<id>-<input>', value)`.
3. Sign in as a `partner` in a second browser and check what they can and cannot see.
4. Admin lock: wrong code refused, 7818 accepted, "Lock again" works.
5. Google paths: test `gs_*`/`bq_*` functions with stand-ins (mock `httr::GET/POST` in the httr namespace) unless the
   user provides credentials. Say clearly what was only tested against stand-ins.
6. Static scan: every function in `.GlobalEnv` checked with `codetools::findGlobals()`; zero undefined functions.
7. Zip the app folder (exclude `data/*.csv`, `.Renviron`, `auth/*.json`), unzip into a new folder, start it, confirm
   HTTP 200 and a clean log.
8. Bump `APP_VERSION` in `R/config.R` (`0.2.0 (phase 2)` and so on) and update README.md's phase list.

## 10. Known limits and gotchas

- shinyapps.io deletes files in `data/` on restart: connect the Sheet and BigQuery before real use.
- Google Sheets reads are capped (about 60 per minute per user); reads are cached for `CP_CACHE_SECS` (30 s).
  Don't call `store_read(fresh = TRUE)` inside reactives; only just before a write.
- `store_replace()` rewrites the whole table on both services; keep it for small tables. For large or busy tables
  use append + `latest_by()`.
- Sign-in is an approved-email check, not a password. For stronger protection, turn on shinyapps.io authentication too.
- Keys pasted in Admin last until the app restarts; permanent keys go in shinyapps.io > Settings > Variables.
- `bigrquery` is optional; without it the app runs on the Sheet only. Keep `library(bigrquery)` guarded in global.R.
- Font Awesome icons: use names that exist in the shiny version installed (check with `shiny::icon("name")`).
- bslib on the build machine was 0.6.1: `navset_hidden`, `nav_panel_hidden`, `layout_columns` are available.
- The previous-apps text in `modules/Admin/admin_previous_apps.R` (`PREVIOUS_APPS`) should be updated if apps move
  or get URLs (only Funding Programmes and VentureDeals have URLs so far).

## 11. Where the source code for each feature is

| Feature | App | Path in its zip |
|---|---|---|
| Programme search, bulk import, add, browse, charts | Funding Programmes | `modules/generate_programme`, `bulk_import`, `add_single`, `browse_data`, `visualizations`; parser in `R/utils_common.R` |
| Same, newer layout | Business Operations Suite | `modules/Funding Programmes/*.R` |
| Fit scoring, ranking | Grant Compass | `R/mod_prioritise.R`, `calc_score()` in `R/utils.R` |
| Decisions, decision log, meet, ideas, weekly | Grant Compass | `R/mod_decisions.R`, `mod_declog.R`, `mod_meet.R`, `mod_ideas.R`, `mod_weekly.R`, `R/collab_helpers.R`, `R/ideas_engine.R` |
| Contacts, outreach, email | Business Operations Suite | `modules/Communications/process_contact.R`, `explore_contacts.R`, `customise_communication.R`, `send_email.R`, `smtp_config.R` |
| Application sections | Business Operations Suite | `modules/Project Application/project_details.R`, `business_case.R`, `team_impact.R`, `diagram_generator.R`, `claude_diagrams.R` |
| Canvases | Business Operations Suite | `modules/Strategy Canvases/bm_canvas_generate.R`, `bm_canvas_view.R`, `de_canvas_generate.R` |
| Gantt, Trello, email notices | Business Operations Suite | `modules/Gantt to Tickets/upload_gantt.R`, `review_edit.R`, `submit_boards.R`, `email_*.R` |
| Decision tree with expected value | BooksNetworks StrategySixS | `R/utils_decision_tree.R` |
| RACI, FMEA, risk | BooksNetworks StrategySixS | `modules/Six Sigma Analysis/*`, `modules/Strategic Analysis/*` |
| Sign-in, Sheets via service account | VentureDeals | `R/auth.R`, `R/sheets_backend.R` (already ported) |

When porting: keep the old logic and prompts, but swap their storage calls for `store_*`, their API code for
`claude_call()`, their layout for the module format in 4.2, and their styling for the classes in section 6.

## 12. Status after phases 2 to 5 (version 0.5.0)

All sub-tabs in section 8 exist, plus `inbox` (3 Team up > Process emails) and `admin_email` (Admin > Email).
Nothing is left in any group's `planned:` list. 42 module files, loader warnings 0.

### 12.1 New shared files
| File | Holds |
|---|---|
| `R/claude.R` | `claude_call()` (section 7), `claude_json()`, `parse_json_loose()`. Handles `pause_turn` (up to 3 continuations). Web search tool version = `CP_WEB_SEARCH_TOOL` (default `web_search_20250305`; for `web_search_20260209` or later it sends `allowed_callers: ["direct"]`) |
| `R/mail.R` | SMTP over curl, ported from DaysPlanning `utils_titan.R`: `send_mail()`, `smtp_test()`, `meeting_ics()`, `mail_build_message()`; `eml_parse()` and `mail_read_file()` (.eml, .txt, .pdf, .docx to text) |
| `R/collab.R` | `calc_score()`, `fit_summary()`, `eligibility_summary()`, `stage_gate()`, `move_programme_stage()` (**every stage move must call it**), `create_decision()`, `create_bid_decision()`, `record_decision_outcome()`, `create_project_for()`, `upsert_person()`, `extract_contact()`, project helpers, `.ics` builder, `num()`, `%|%`, `named()`, `pick_sel()` |
| `R/integrations.R` | added `trello_req()`, `trello_lists()`, `trello_list_create()`, `trello_card_upsert()`, `trello_board_cards()` |

### 12.2 New tables and columns (see `SCHEMAS`)
New: `people, decision_options, decision_inputs, ideas, idea_votes, gonogo, raci, risks, budget, answers, canvases,
milestones, reminders_log`. Columns appended at the end of: `consortium` (documents_received, name, organisation,
updated_by), `messages` (subject, direction, status, detail), `decisions` (kind, tree_inputs), `projects` (lead_email),
`tasks` (description, trello_url, deleted, updated_by). Existing Sheet tabs get the new header columns automatically on
the next write (`gs_ensure_header`), and BigQuery tables get `ADD COLUMN` through `bq_table_patch` in `bq_ensure_table`.

### 12.3 Changes to the plan, and why
- **Won bids go to Deliver**, not Learn (Outcomes tab): a won bid is a running project. Lost, withdrawn and not pursued go to Learn.
- **Sheet reads are batched**: on a cache miss `store_read()` reads every table in one `values:batchGet` call. With about 30
  tables, separate reads would pass Google's 60 reads a minute per user.
- **Process emails** (`inbox`) is new: a pasted or uploaded partner email is read by Claude into sender, bid, intent
  (interested / committed / declined...), documents received and action items; the user ticks what to apply.
- `programme_add` uses text date fields (YYYY-MM-DD): shiny 1.8.0 cannot show an empty `dateInput`.
- The gate blocks moves of an ineligible programme to Decide, Plan, Write and Deliver (Learn is still allowed).
- Grant Compass and BooksNetworks zips were not supplied, so decisions, decision log, ideas, meet by exception, weekly
  updates, team scoring, go/no-go, RACI and risks were built from the specs here, not ported line by line.

### 12.4 Rules learnt while building (follow them)
1. **`ctx` data only signals real changes.** `ctx$data$*`, `ctx$settings()` and `ctx$table("name")()` are reactiveVals
   refreshed every 30 s that only invalidate when the content changes, so the poll never rebuilds a form someone is
   typing in. Use `ctx$table("risks")()` for any table; do **not** write `reactive({ ctx$tick(); store_read(...) })`.
2. **Tab code starts before sign-in.** Every read also depends on `shell_v`, which goes up after the app (and the Admin
   area) has been drawn, so dropdowns refill into freshly drawn inputs. Keep `session$onFlushed(...)` in `app.R`.
3. **`req(nrow(x))` does not stop on 0** (0 is "truthy" in Shiny). Always `req(nrow(x) > 0)`.
4. **`paste0()` on empty columns returns one string**, so `setNames(ids, paste0(...))` or `data.frame(a = paste0(...))`
   break on empty tables. Use `named()` or check `nrow()` first.
5. **Refreshing a dropdown**: `selected = pick_sel(isolate(input$x), choices, preferred)`; a fresh input is `""`, not NULL.
6. **Numbers**: `as.character(900000)` is `"9e+05"`. `conform()` now writes numbers plainly, and `num()` reads both forms.
7. `%|%` (in `R/collab.R`) is "a, or b where a is empty" and works on whole columns; `%||%` only handles NULL / NA.
8. Do not use `updateSelectizeInput(server = TRUE)`: with no choices it throws a JavaScript error in shiny 1.8.0.

### 12.5 How it was tested (section 9)
- Start-up from empty `data/`: clean log, `loader warnings: 0`. Static scan: zero undefined functions in 257.
- Playwright (Chrome), 71 checks, all passing: sign-in refusal, admin code (wrong refused, 7818 accepted, lock again),
  every group and sub-tab opened and screenshotted with no output errors, and each feature used once with awkward text
  (apostrophes, accents, new lines, quotes, RFC 2047 encoded subject). Includes: live search saved twice with no
  duplicates; re-check accepted; eligibility gate stopping a move with the reason; Go creating a project; Trello send
  (12 new), re-send (0 new, 12 updated), status pull; missed milestone opening a decision; reminders; partner in a
  second browser seeing one bid, weighing in, unable to record the outcome or see Admin, search or contacts.
- **Stand-ins only** (no real credentials were available): Claude (HTTP responses with `pause_turn`, web search
  results and citations), Trello (in-memory board), SMTP (real MIME message built, delivery recorded), Google Sheets
  (httr mocked: header upgrade, one batchGet for all tables, new tab, rewrite; accents and apostrophes round-trip).
  BigQuery column patching is untested. **Test each with real keys before relying on it.**
- The test scripts are not in the zip (they patch functions); ask for them if needed.

### 12.6 Optional packages (0.5.1)
`officer`, `pdftools`, `readxl`, `writexl` are optional: `global.R` attaches them only when installed, `has_pkg()` /
`need_pkg()` in `R/utils.R` switch the features off with a clear message. Reason: officer 0.7.9 from source fails to
build on Windows R 4.4, and one missing package must not stop the whole app. `install.R` uses binaries on Windows.

### 12.7 Size and zip layout
Keep the zip small (target under 700 KB): no bundled JavaScript libraries; mermaid is loaded from jsDelivr in
`canvases_diagrams.R`. Zip the app's contents with no folder above them (`app.R` at the top of the zip).

### 12.8 Version 0.6.0: owner, sidebar, suggestions, analyses, Drive
- **Owner** = emails in `ADMIN_EMAILS` (`ctx$is_owner()`, `auth$is_owner()`). Only the owner sees the Admin group, `admin_tabs`,
  `analysis_workbench` (`owner: true` in the registry) and Drive actions. Role `admin` keeps its powers inside tabs.
- **Sidebar** (`R/nav.R`, `www/app.js`): each group lists its tabs (`cpGo()` sends `input$nav_to`); carets fold groups; the burger
  hides the sidebar; both remembered in the browser. `ctx$nav()` marks the active link.
- **Tab setup**: settings key `tab_config` (JSON: `modules.<id>.{label, enabled, members, partners}`, `groups.<id>.{label, enabled}`),
  applied by `module_visible()`. Saving redraws the app in place (`ctx$rebuild_shell()`), no reload, so no new sign-in.
- **Tables** `suggestions` and `analyses` (schemas in `R/config.R`). `R/analysis.R`: prompt (JSON tables), `clean_dashes()`,
  `parse_analysis()` (JSON, else Markdown tables), flextable rendering (optional package, HTML fallback), `can_see_analysis()`,
  `analysis_tree()`. Access list = `access_emails`; the suggester is always on it; the owner sees all.
- **Drive** (`R/drive.R`): `api` (Shared Drive folder; service accounts cannot store files in a personal My Drive) or `folder`
  (synced folder, as in the Mi Tesis app). Files: `<Country>/<Category>/<Topic>/<programme>__<id>.json` + `.html`, tagged
  `cp_type`/`cp_id`; re-saving replaces, reclassifying moves. Pull back takes copies that are new or newer.
- Tested: browser 96/96; analysis helpers and a real synced folder 14/14; Drive API against a stand-in 6/6.

### 12.9 Loading rule (0.6.1)
`app.R` always sources `global.R` (only the test harness skips it with `options(cp.keep_global = TRUE)`). The old
`if (!exists("loader"))` guard kept a previous version's functions when two versions ran in one R session. Test that case:
source the old `global.R`, then `shiny::runApp()` the new folder in the same session.

### 12.10 Version 0.7.0: usage analytics, Drive copies, registered member
- `admin_analytics` (Admin, owner only): contributions counted from the author column of 22 tables (`CONTRIB_SOURCES`),
  sign-ins and refusals from `login_log`; charts by person and by week; people table; CSV download.
- Drive: `drive_save_file()` (any file, replaced not copied) and `drive_backup_tables()` (every table to `Backups/<date>/`,
  UTF-8 CSV with BOM). Runs once a day when the owner signs in (`drive_auto_backup`, `drive_last_backup`), or by button in
  Usage analytics and Admin > Google Drive. Analytics snapshots go to `Analytics/<date>/`.
- `CP_SEED_MEMBERS` (default `ali.jboloori@gmail.com`): added to `allowed_emails` as `member` when the email is not on the
  list at all; never re-added after removal. Not an admin, so no Admin group.
- Lesson: never name a list element `errors` when code checks `r$error`: `$` on a list matches partial names.
- Tested: browser 107/107 (Ali signs in as a member, analytics, Drive files checked on disk); Drive API stand-in 8/8.

### 12.11 Next steps worth doing
- Fetch partner emails straight from the mailbox (IMAP over curl, same login as SMTP) into Process emails.
- Trello webhooks are not possible on shinyapps.io; status is pulled by button.
- Optional: per-project Trello board (today one board from settings, choosable per send).
