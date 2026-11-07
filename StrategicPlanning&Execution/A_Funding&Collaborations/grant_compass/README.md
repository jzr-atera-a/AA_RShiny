# Grant Compass

A collaborative R Shiny app for inviting a team to review grants, say which fit them best, and vote on project ideas.
Same navy/teal design language as the Innovate UK appendices.

## Run it now (testing mode)
```r
source("install.R")      # once
shiny::runApp()
```
Sign-in is **off** and data is saved to CSV files in `data/`, so nothing else is needed to try it.

## Navigation (two levels)
- **Grants Hub**: Welcome, Grants, Prioritise, Ideas
- **Collaboration Lab**: Workspace, Decisions, Decision log, Weekly updates, Meet by exception, Playbook & invites
- **Admin**

## Grants Hub tabs
| Tab | What it does |
|---|---|
| Welcome | Hero, progress meter, three-step guide, live activity feed, contributor points |
| Grants | Card view with search, theme and status filters; **Prioritise** jumps to scoring |
| Prioritise | Score alignment / interest / capability (1-5) + stance (lead, partner, watch, pass). Weighted 0-100 fit score; "My ranking" and "Team ranking" |
| Ideas | Suggestions from top-scored grants + interests (built-in templates, or AI if a key is set); add your own; upvote |
| Admin | Sign-in switch, scoring weights, users and invites, grant editor, import from a website, Google Sheet status, Anthropic API settings, change log, CSV download |

## Collaboration Lab (decide together without the meetings)
Built from documented practice: GitLab/Basecamp written-first working, DACI roles, nominal-group "think alone first",
Apache lazy consensus, and decision records.

| Tab | What it does |
|---|---|
| Workspace | What needs you now, team pulse, the 4-step rhythm, badges, top contributors |
| Decisions | One page per decision: question, context, 2-4 options, a recommendation, Driver, one Approver, Contributors, deadline. Views stay **hidden until you add yours**. Concerns and objections need a written reason. The Approver records the decision with the reasoning and a "revisit if" trigger. Decisions can be reopened only with new information |
| Decision log | Searchable record of every decision, why, options considered, revisit trigger. CSV download |
| Weekly updates | Done / next / blocked / thanks, streak counter, an auto-built team recap (with .md download) |
| Meet by exception | Live sessions need three "have you tried writing" checks and a reason; every held session must log its outcome |
| Playbook & invites | Six principles with sources, templates, and an invite generator (copy or open in your email app) |

Promote any idea from the Ideas tab with **Decide how to approach**. Rules (days to weigh in, hide-until-you-contribute, silence-agrees)
are in Admin > Access. Extra sheet tabs created automatically: `Decisions, DecisionOptions, DecisionInputs, WeeklyUpdates, SyncRequests`.
In test mode the tester's display name is remembered in the browser.

## Connect the Google Sheet (about 5 minutes)
1. Create a blank Google Sheet. Copy its URL.
2. In Google Cloud: create a service account, enable the **Google Sheets API**, download its JSON key.
3. Share the Sheet with the service-account email as **Editor**.
4. Copy `.Renviron.example` to `.Renviron`, set `GH_SHEET_ID` and `GH_SERVICE_ACCOUNT_JSON`, restart.

On first start the app creates these tabs with headers and seeds Users and Grants:
`Users, Grants, Priorities, Ideas, IdeaVotes, Settings, ChangeLog`.
Every write (scores, votes, ideas, admin edits, sign-ins) is appended to `ChangeLog`.
Priorities and votes are append-only (latest row per person wins), so the sheet keeps full history.

**Users tab columns:** email, name, role (`admin` or `member`), organisation, interests (separated by `;`), active (`TRUE`, `FALSE` or `PENDING`).

## Turn sign-in on
Admin > Access > "Require sign-in", or set `GH_AUTH_REQUIRED=true`. Visitors must enter an email that is active in Users.
Unknown emails can request access (stored as `PENDING`; an admin approves in Admin > Users).
Make sure your own email is an active admin first.
Note: this is an email allow-list, not a password. Fine for a small invited team; for stronger protection put the app behind
your host's login (Posit Connect, shinyapps.io authentication, or an SSO proxy).

## Grants from a website
Admin > Grants > "Pull grants from a website": paste a listing page and a CSS selector, tick the real grants, add them.
The seeded grants other than the Innovate UK battery competition are placeholders: confirm scope, dates and value at source.

## AI ideas (optional)
Admin > Integrations: paste an Anthropic API key and switch on. The key lives in server memory only; use `ANTHROPIC_API_KEY`
to make it permanent. Without a key the app uses its built-in templates.

## Code layout
```
app.R                 UI shell, shared reactive data layer, wiring
R/config.R            env vars, setting defaults, sheet schemas
R/store.R             storage: Google Sheets or local CSV, caching, change log, seed data
R/utils.R             helpers (scoring, formatting, latest-row-wins)
R/ideas_engine.R      idea templates, AI call, website scraper
R/collab_helpers.R    icons, decision status logic, points, badges
R/mod_*.R             one module per tab (auth, welcome, grants, prioritise, ideas, admin, collab_home, decisions, declog, weekly, meet, playbook)
www/styles.css        design system
```
Google Sheets allows about 60 reads a minute per user; reads are cached for `GH_CACHE_TTL` seconds (default 15) across all sessions.
