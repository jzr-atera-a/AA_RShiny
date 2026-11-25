# Collaboration Planning

Choose the right funding programmes, team up with collaborators, and deliver the work.
Built from Funding Programmes, Grant Compass, Business Operations Suite, BooksNetworks StrategySixS and VentureDeals
(see Admin > Previous apps). All five build phases are in this version (0.5.0): every stage from Discover to Learn works.

## Run it now (testing mode)
```r
source("install.R")   # once (on Windows it uses ready-made binary packages)
shiny::runApp()
```
With no Google set-up, data is kept in CSV files in `data/`. Sign in with an email listed in `ADMIN_EMAILS`
(default `joseph.zr@atera-analytics.co.uk`), then add the team in Admin > Users and access.

## Sign-in and admin
- **Sign-in** works like VentureDeals: the email must be in the `allowed_emails` tab of the Google Sheet (or the local
  CSV in testing mode) and active. Five wrong attempts lock the form for five minutes. Every attempt goes to `login_log`.
- **Roles**: `admin`, `member`, `partner`. People in `ADMIN_EMAILS` are always admins.
- **Admin group** (all API and general settings) is visible to admins only. Opening it asks for the admin code
  (`CP_ADMIN_CODE`, default **7818**) unless the app is running on **Windows**, where no code is needed.
  shinyapps.io runs on Linux, so the code is always asked for there.

## Storage: Google Sheet and BigQuery
Every write goes to both services when they are set up; reads come from the Sheet (quick), else BigQuery, else CSV.
If one service fails, the other still saves and the error appears in Admin > Activity.
1. In Google Cloud, create a service account; enable the **Google Sheets API** and **BigQuery API**; download its JSON key.
2. Save the key as `auth/google_service_account.json` (it is bundled when you deploy; never commit it).
3. Create a Google Sheet; share it with the service account's email as **Editor**.
4. Give the service account **BigQuery Data Editor** and **BigQuery Job User** on your project.
5. Copy `.Renviron.example` to `.Renviron` and fill it in (on shinyapps.io: app Settings > Variables).
6. Start the app and open Admin > Storage. Missing tabs and tables (`cp_` prefix in BigQuery) are created with headers.

Tables: `allowed_emails`, `login_log`, `settings`, `changelog`, `programmes`, `question_sets`
(later phases add `priorities`, `eligibility`, `consortium`, `decisions`, `projects`, `tasks`, `weekly`, `outcomes`, ...).
All columns are stored as text so the Sheet and BigQuery hold the same rows.

## Deploy to shinyapps.io
```r
rsconnect::deployApp(appDir = ".", appName = "collaboration_planning")
```
Then set the variables from `.Renviron.example` in the app's Settings > Variables and restart.
Files written to `data/` on shinyapps.io are lost on restart, so connect the Sheet and BigQuery before real use.

## Layout
```
app.R                     UI shell, sign-in gate, admin lock, wires the modules
global.R                  packages (deployment list), sourcing order, start-up
R/config.R                variables, settings defaults, stages, table schemas
R/google_sheets.R         Sheets REST API with a service account (no googlesheets4)
R/bigquery.R              BigQuery through bigrquery (optional package)
R/store.R                 one storage interface: Sheet + BigQuery + CSV, cache, change log, settings, users
R/auth.R                  sign-in and the admin code lock
R/programmes.R            maps old Funding Programmes / Grant Compass columns to one programme record
R/integrations.R          Claude key and Trello (boards, lists, cards, status)
R/claude.R                claude_call() and claude_json(): every Claude request, with optional web search
R/mail.R                  SMTP sending (curl), meeting invitations, reading .eml / PDF / Word into text
R/collab.R                shared rules: fit score, eligibility gate, stage moves, decisions, projects, partners
R/seed.R                  first admin and the three example question sets
R/module_loader.R         finds and loads modules/<Group>/<id>.R from their headers
R/nav.R                   sidebar and group pages from the registry
modules/_module_registry.yml   groups, sub-tabs, planned sub-tabs
modules/<Group>/<id>.R    one file per sub-tab: header + <id>_ui(id) + <id>_server(id, ctx)
www/styles.css            Grant Compass design language
```

### Add a sub-tab
1. Create `modules/<Group>/<new_id>.R` starting with the header block (copy one from any module) and define
   `<new_id>_ui(id)` and `<new_id>_server(id, ctx)`.
2. Add `<new_id>` to the group's `modules:` list and to `modules:` in `_module_registry.yml`.
3. `ctx` gives you `ctx$user()`, `ctx$is_admin()`, `ctx$admin_ok()`, `ctx$data$<table>()`, `ctx$bump()`,
   `ctx$settings()` and `ctx$nav(group, sub)`. Save with `store_append()` / `store_replace()`.

## What each group does
| Group | Sub-tabs |
|---|---|
| Home | Pipeline board with fit score, ineligible and blocked flags, "Decide whether to bid" on each card |
| 1 Discover | Programmes (re-check at source with Claude), Live search (Claude web search, a source link per programme), Bulk import, Add entry, Charts and calendar (.ics with 7-day reminders) |
| 2 Qualify | Eligibility check (Claude against the company profile; any "not met" blocks moves to Decide or later), Team scoring, Team ranking, Go/no-go tree |
| 3 Team up | Collaborators (Claude reads CVs, signatures, emails), Partner match, Outreach (Claude drafts; sends by SMTP with an optional meeting invitation), Process emails (drop in a partner's reply: person, consortium status, documents and tasks are updated after you confirm), Consortium |
| 4 Decide | Decisions (options, Driver and Approver, blind input, silence agrees; Go creates a project, No go moves to Learn), Decision log, Ideas (votes), Meet by exception (agenda and invitation) |
| 5 Plan | Work packages and Gantt (template or Excel upload), RACI, Risk register (Claude suggestions), Budget by partner |
| 6 Write | Section drafts (live word counts, Claude drafts from the whole bid, every save a version, .docx and .md download), Question sets, Canvases and diagrams, Submit checklist |
| 7 Deliver | Trello board (one list per work package, card ids kept so re-sending updates; pull status back), Weekly updates, Milestones and claims (a missed one opens a decision), Reminders (email by button) |
| 8 Learn | Outcomes and lessons (won moves to Deliver, others to Learn), Win rate (by funder, category, theme; fit score won against lost) |
| Suggestions | My suggestions (private to whoever adds them), Analysis workbench (owner: instructions window, run Claude, parse into tables, classify, share, upload to Drive), Analysis library (flextable tables in a Country > Category > Topic > Programme tree; each person sees what is shared with them) |
| Admin (owner only) | Tabs and groups, Usage analytics (each person's contributions, sign-ins, activity by week; saved to Drive), Users, Storage, Claude API, Trello, Email, Google Drive, General settings, Data import, Previous apps, Activity |

Partners (role `partner`) see only bids where they are in the consortium, and only the tabs that make sense for them;
they can weigh in on decisions and update their own consortium entry.

## Email
Set the mailbox in Admin > Email (Titan: `smtp.titan.email`, port 465). The password comes from `SMTP_PASSWORD`
(shinyapps.io > Settings > Variables) or is pasted in Admin for the running app only. It is never written to the Sheet or BigQuery.

## Version history
- 0.8.0: How to use this app (top of Discover); General collaboration ideas (commercial ideas with notes to build on them); preloaded examples: two open Innovate UK BridgeAI AI competitions, three ideas, one shared analysis.
- 0.7.0: Usage analytics (owner); analytics and a copy of every table saved to Google Drive (daily when the owner signs in, or by button); ali.jboloori@gmail.com registered as a member (CP_SEED_MEMBERS).
- 0.6.1: app.R always loads its own global.R, so running it after another version in the same R session no longer uses old code.
- 0.6.0: sidebar tab groups and burger button; Admin and tab setup for the owner (ADMIN_EMAILS) only; Suggestions group with Claude analysis tables (British English, no long dashes), hierarchy, access lists, Google Drive upload and pull back.
- 0.5.2: mermaid.js loaded from the CDN instead of bundled (zip down from 1.4 MB); zip has no top folder.
- 0.5.1: officer, pdftools, readxl and writexl are optional (the app starts without them); install.R uses Windows binaries and installs each package separately.
- 0.5.0: phases 2 to 5 (all tabs), email sending and email processing, Trello sync, batched Sheet reads, automatic
  header and column upgrades for Sheet tabs and BigQuery tables.
- 0.1.0: phase 1, the frame, sign-in, storage, Admin, data import, example question sets.
