# Shiny App Template — Full Developer Guide
**Atera Analytics | Portable Shiny Skeleton**

---

## Purpose

This template is a production-ready R Shiny skeleton that provides:
- **Email-based login gate** validated against a Google Sheet
- **Full user analytics tracking** (tabs, clicks, sliders, plots, session duration)
- **Admin reporting tab** with live charts, user management, and email filter
- **3 dummy content tabs** ready to be replaced with real content
- **Dark DeepTech CSS theme** (navy/cyan) reusable across apps

Upload this zip to any Claude chat and say:
> *"Use this template to build [your app description]. The Google Sheets connection, login gate, analytics tracking, and admin tab are already working — do not modify those files. Replace the 3 dummy tabs with [your content]."*

---

## Architecture Overview

```
app.R                          ← Entry point. Wire tabs here. Set APP_NAME.
global.R                       ← UI helper functions + Plotly dark theme
R/
  sheets_backend.R             ← Google Sheets REST API (read/write/auth)
  analytics_tracker.R          ← Event tracking module server
  auth.R                       ← Login overlay UI + session bar UI
modules/
  tab_one.R                    ← Dummy tab 1  ← REPLACE WITH YOUR CONTENT
  tab_two.R                    ← Dummy tab 2  ← REPLACE WITH YOUR CONTENT
  tab_three.R                  ← Dummy tab 3  ← REPLACE WITH YOUR CONTENT
  admin_reporting.R            ← Admin analytics tab ← DO NOT MODIFY
auth/
  allowed_emails.txt           ← Fallback email list (when Sheets unavailable)
  google_service_account.json  ← YOU add this (gitignored, never commit)
www/css/
  global.css                   ← Full app theme
  auth.css                     ← Login screen styles
.Renviron                      ← Local env vars (never commit)
.gitignore                     ← Protects credentials from git
README.md                      ← Quick start guide
```

---

## Google Sheets Setup (One-Time)

### 1. Create the spreadsheet
Create a Google Sheet with exactly **3 tabs** named:

**Tab: `allowed_emails`**
```
Row 1: email | role | added_by | added_date | notes
Row 2+: your users
```

**Tab: `login_log`**
```
Row 1: timestamp | email | role | success | ip | session_id
(app writes here automatically)
```

**Tab: `analytics_log`**
```
Row 1: timestamp | email | session_id | event_type | tab | element | detail | duration_secs
(app writes here automatically)
```

> **If using the provided Excel template:** rows 1-2 are decorative, row 3 = column headers, data starts row 4. This is already handled by `EMAIL_DATA_ROW = 4` and `LOG_HEADER_ROW = 3` in `sheets_backend.R`.

### 2. Service account
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Enable **Google Sheets API** and **Google Drive API**
3. Create a Service Account → download JSON key
4. Save as `auth/google_service_account.json`
5. Share the Google Sheet with the service account's `client_email` as **Editor**

### 3. Environment variables
Edit `.Renviron` for local development:
```
GOOGLE_SHEETS_ID=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms
ADMIN_EMAILS=admin@yourcompany.com
```

For shinyapps.io: set `GOOGLE_SHEETS_ID` and `ADMIN_EMAILS` in the app dashboard under **Settings → Environment Variables** (paid plans) or hardcode defaults in `R/sheets_backend.R`:
```r
SHEETS_CONFIG <- list(
  sheet_id     = Sys.getenv("GOOGLE_SHEETS_ID", "YOUR_HARDCODED_ID"),
  admin_emails = trimws(strsplit(
    Sys.getenv("ADMIN_EMAILS", "admin@yourcompany.com"), ","
  )[[1]])
  ...
)
```

---

## Login Gate — How It Works

### Flow
```
User visits app
  → Login overlay shown immediately (CSS position:fixed, z-index:99999)
  → User types email → clicks "Request Access"
  → Server checks email against Google Sheets allowed_emails tab
  → If allowed:  overlay hidden via JS, app content revealed, login logged to Sheet
  → If denied:   error shown, attempt counted, lockout after 5 failures (5 min)
```

### Key design decision
The login overlay is **always in the DOM** (not inside `conditionalPanel`). This ensures Shiny button bindings work immediately on page load. A `conditionalPanel` would delay rendering and break the button.

The overlay is hidden/shown by:
```javascript
// In auth.R — registered via session$sendCustomMessage()
Shiny.addCustomMessageHandler('authenticate_user', function(msg) {
  document.getElementById('login_overlay').style.display = 'none';
  document.body.classList.add('authenticated');
});
```

### Managing users
- **Add:** Edit the `allowed_emails` tab in Google Sheets directly. No restart needed — email list is cached for 60 seconds and re-read on next login attempt.
- **Remove:** Prefix the email with `REMOVED_` in the Sheet (preserves audit trail) or use the Admin tab inside the app.
- **Fallback:** If Sheets is unavailable, app falls back to `auth/allowed_emails.txt`

### Admin vs regular user
Set `ADMIN_EMAILS` env var. Admin users see an extra **★ Admin** tab in the sidebar with full analytics reporting and user management. Regular users never see this tab — it is hidden via CSS and only revealed via JS for admins:
```javascript
Shiny.addCustomMessageHandler('show_admin_tab', function(msg) {
  document.getElementById('admin_menu_item')
    .style.setProperty('display', 'block', 'important');
});
```

---

## Analytics Tracking — How It Works

### Architecture: why JS inputs are passed from the parent server

`moduleServer` in Shiny namespaces all `input$` values. So inside the tracker module:
- `input$__tracker_tab_change` becomes `tracker-__tracker_tab_change`
- But JS sets `Shiny.setInputValue('__tracker_tab_change', ...)` — no namespace

**Solution:** All JS-driven inputs are passed as `reactive()` arguments from the **parent server** (where they exist as plain `input$__tracker_X`) into the tracker module. The module observes these parent reactives instead of its own namespaced inputs.

```r
# In app.R server() — correct pattern
tracker_server(
  id                     = "tracker",
  email_reactive         = reactive({ state$email %||% "" }),
  session_id             = isolate(state$session_id),
  tab_reactive           = reactive(input$tabs),           # parent input$tabs
  box_click_reactive     = reactive(input$`__tracker_box_click`),
  btn_click_reactive     = reactive(input$`__tracker_btn_click`),
  tab_change_reactive    = reactive(input$`__tracker_tab_change`),
  plot_interact_reactive = reactive(input$`__tracker_plot_interact`),
  session_end_reactive   = reactive(input$`__tracker_session_end`),
  flush_secs             = 10
)
```

### Why tracker_server() must be called at the top level of server()
`moduleServer` only binds correctly when called at the **top level** of `server()`, not inside `observeEvent`. If placed inside `observeEvent(state$authenticated, ...)`, the session binding fails silently and no events are tracked.

```r
# ✅ CORRECT — top level
server <- function(input, output, session) {
  tracker_server("tracker", ...)  # called immediately
  ...
}

# ❌ WRONG — inside observeEvent
server <- function(input, output, session) {
  observeEvent(state$authenticated, {
    tracker_server("tracker", ...)  # moduleServer fails here
  })
}
```

The tracker uses `push_event()` which gates on `email_reactive()` being non-empty, so events are only queued after login — the module can safely start before authentication.

### Events tracked automatically

| Event type | Trigger | Data captured |
|---|---|---|
| `session_start` | Email becomes available after login | hostname |
| `tab_view` | User navigates to a tab | tab name |
| `tab_exit` | User leaves a tab | tab name, seconds spent |
| `box_click` | Click on any `.box` element | box title, tab |
| `button_click` | Click any `actionButton` (except login) | button ID, label, tab |
| `plot_interact` | Plotly zoom/pan/select | plot element ID |
| `input_change` | Slider/select change (debounced 1.5s) | element ID, new value, tab |
| `session_end` | Browser tab closed | total session seconds |

### Adding tracked inputs (sliders, selects)
In `R/analytics_tracker.R`, add input IDs to `tracked_inputs`:
```r
tracked_inputs <- c(
  "my_module-my_slider",      # format: "module_id-input_id"
  "my_module-my_select",
  "another_module-my_slider"
)
```

### Flush behaviour
Events are **queued in memory** and written to Google Sheets in batches:
- Every `flush_secs` seconds (default: 10)
- Immediately on session end
- This minimises API calls while ensuring data is not lost

---

## Module Pattern — How Each Tab Works

Every content tab follows this exact pattern:

```r
# modules/my_tab.R

my_tab_ui <- function(id) {
  ns <- NS(id)           # ← always create ns from id
  tagList(
    # UI elements — use ns() for all input/output IDs
    sliderInput(ns("my_slider"), "Value", 1, 100, 50),
    plotlyOutput(ns("my_plot"))
  )
}

my_tab_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
    # Server logic — input$ is already namespaced, no ns() needed here
    output$my_plot <- renderPlotly({
      plot_ly(x = 1:input$my_slider, y = rnorm(input$my_slider)) %>% dt_theme()
    })
  })
}
```

Wire in `app.R`:
```r
# In dashboardSidebar sidebarMenu:
menuItem("My Tab", tabName = "my_tab", icon = icon("chart-line"))

# In dashboardBody tabItems():
tabItem(tabName = "my_tab", my_tab_ui("my_tab"))

# In server() at top level:
my_tab_server("my_tab")
```

**Critical rule:** All module servers must be called at the **top level** of `server()`, not inside reactive contexts.

---

## UI Helper Functions (global.R)

These are available in all modules — no need to redefine them.

```r
# Page hero banner (blue gradient, left border, badges)
page_hero(title, subtitle, badges = character())

# Section heading (cyan underline)
sh("Section Title")

# Metric card (dark box with cyan value)
mc_stat("£1.2M", "Revenue")

# Horizontal rule (blue)
hr_blue()

# Coloured info boxes
tip_box(...)       # blue — tips, notes
success_box(...)   # green — positive outcomes
warn_box(...)      # red — warnings, errors

# Apply dark theme to any plotly chart
my_plot %>% dt_theme()
```

---

## Adding a New Tab — Step by Step

### 1. Create the module file
```r
# modules/my_new_tab.R
my_new_tab_ui <- function(id) {
  ns <- NS(id)
  tagList(
    page_hero("My New Tab", "Description here.", c("BADGE1", "BADGE2")),
    fluidRow(
      box(title = "My Chart", status = "primary", solidHeader = TRUE, width = 8,
        sliderInput(ns("n"), "Points", 10, 200, 50),
        plotlyOutput(ns("chart"))
      ),
      box(title = "Stats", status = "info", solidHeader = TRUE, width = 4,
        sh("Key Metrics"),
        uiOutput(ns("stats"))
      )
    )
  )
}

my_new_tab_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
    output$chart <- renderPlotly({
      df <- data.frame(x = 1:input$n, y = cumsum(rnorm(input$n)))
      plot_ly(df, x = ~x, y = ~y, type = "scatter", mode = "lines") %>% dt_theme()
    })
    output$stats <- renderUI({
      tagList(mc_stat(input$n, "Points"), mc_stat("Active", "Status"))
    })
  })
}
```

### 2. Wire in app.R
```r
# Source automatically if you use the for loop:
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

# Add to sidebar:
menuItem("My New Tab", tabName = "my_new_tab", icon = icon("chart-line"))

# Add to tabItems():
tabItem(tabName = "my_new_tab", my_new_tab_ui("my_new_tab"))

# Add to server() at top level:
my_new_tab_server("my_new_tab")
```

### 3. Track slider inputs (optional)
```r
# In R/analytics_tracker.R, add to tracked_inputs:
tracked_inputs <- c(
  # existing entries...
  "my_new_tab-n"
)
```

---

## Admin Tab — What It Shows

The admin tab is only visible to emails in `ADMIN_EMAILS`. It provides:

### User Management
- Add users by email + role (user / admin / viewer) — writes to Google Sheet
- Remove users — prefixes with `REMOVED_` in Sheet (preserves audit trail)
- View current user list with roles and dates

### Login Activity
- Total logins, unique users, logins today, denied attempts
- Full login log table (last 50 entries)
- Bar chart: daily logins by user over time

### Analytics Filter
- Dropdown populated from emails found in `analytics_log`
- Selecting an email filters all analytics charts below to that user
- Selecting "All Users" shows aggregate across everyone
- Uses a plain native HTML `<select>` (not selectize) to avoid React-like re-render flickering

### Analytics Charts (all filtered by dropdown)
- **Tab Engagement**: bar chart of tab views + line of avg time-on-tab
- **Interaction Heatmap**: user × tab matrix (darker = more events)
- **Top Interacted Elements**: horizontal bar of most-clicked buttons/sliders
- **Raw Analytics Log**: full event table (last 100 rows)

---

## CSS Theme — Customisation

The dark DeepTech theme uses CSS variables defined in `www/css/global.css`.

### Key colour palette
```css
--navy:       #040D21   /* page background */
--blue-med:   #071A3E   /* sidebar, boxes */
--cyan:       #00E5FF   /* primary accent, values */
--cyan-dim:   #00BFFF   /* borders, highlights */
--text-main:  #CDD9F5   /* primary text */
--text-dim:   #8FB0D8   /* secondary text */
--text-muted: #7AA8E0   /* labels, captions */
```

### Box status colours
```r
box(status = "primary")  # dark blue header
box(status = "info")     # medium blue header
box(status = "warning")  # cyan header
box(status = "success")  # green header
box(status = "danger")   # red header
```

### Changing the theme
To use a different colour scheme, edit the CSS variables at the top of `global.css`. All components inherit from these values.

---

## Google Sheets Backend — Key Functions

```r
# Connection (call at app startup)
sheets_connect()                    # returns TRUE/FALSE

# User management
sheets_get_allowed_emails()         # returns character vector of emails
sheets_get_users_df()               # returns data.frame of all users
sheets_add_user(email, role, ...)   # appends row to allowed_emails tab
sheets_remove_user(email)           # returns message (edit Sheet directly)

# Logging (called automatically — don't call manually)
sheets_log_login(email, success, session_id)
sheets_log_event(email, session_id, event_type, tab, element, detail, duration_secs)

# Reading (for admin tab)
sheets_get_login_log()              # returns login_log as data.frame
sheets_get_analytics()              # returns analytics_log as data.frame

# Helper
is_admin(email)                     # returns TRUE/FALSE
```

### Fallback behaviour
If Google Sheets is unavailable (no credentials, API down, wrong sheet ID):
- Login falls back to `auth/allowed_emails.txt`
- Analytics events are silently dropped (no crash)
- App continues to function normally
- Console shows `⚠ Sheets: ... — file fallback`

---

## Deployment to shinyapps.io

```r
# Install rsconnect if needed
install.packages("rsconnect")

# Configure your account (one-time)
rsconnect::setAccountInfo(name = "your-account", token = "...", secret = "...")

# Deploy
rsconnect::deployApp(
  appDir  = "path/to/ShinyTemplate",
  appName = "my-app-name"
)
```

**Before deploying:**
1. Hardcode your Sheet ID as the default in `R/sheets_backend.R` (since `.Renviron` is ignored on shinyapps.io):
   ```r
   sheet_id = Sys.getenv("GOOGLE_SHEETS_ID", "YOUR_ACTUAL_SHEET_ID")
   ```
2. Ensure `auth/google_service_account.json` is in the project folder (it deploys with the app, encrypted)
3. The `.gitignore` already protects it from git commits

---

## Required R Packages

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "plotly",
  "DT",
  "dplyr",
  "httr",
  "jsonlite",
  "openssl",
  "base64enc"
))
```

No `googlesheets4` or `googledrive` required — the template uses direct REST API calls to avoid version compatibility issues.

---

## Common Issues & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| Login button does nothing | Button inside `conditionalPanel` loses Shiny binding | Use `div(id="login_overlay")` always in DOM, hide via JS |
| `⚠ Sheets: GOOGLE_SHEETS_ID not set` | Env var not loaded | Run `readRenviron(".Renviron")` then restart app |
| `HTTP 400 Bad Request` on token | JWT signing issue | Check `openssl` and `base64enc` are installed |
| `HTTP 403 Forbidden` | Sheet not shared with service account | Share Sheet with `client_email` from JSON as Editor |
| `HTTP 404 Not Found` | Wrong Sheet ID or Sheet is Excel format | Re-check ID; if uploaded as .xlsx, do File → Save as Google Sheet |
| Analytics not writing | Tracker not firing | Ensure `tracker_server()` is called at top level of `server()`, not inside `observeEvent` |
| Admin tab shown to all users | CSS rule missing | Ensure `#admin_menu_item { display: none !important; }` is in `tags$style` in `app.R` |
| Dropdown flickering | `updateSelectInput` called on every flush | Use native `<select>` via `uiOutput` + JS `setInputValue`, compare email list before updating |
| `could not find function "ns"` | `ns` not defined inside `moduleServer` | Add `ns <- session$ns` at top of `moduleServer` body |
| App content visible before login | CSS cover not applied fast enough | Use `position:fixed; z-index:99999; display:flex` inline on login overlay div |

---

## Prompt for New Claude Chat

When starting a new app from this template, use this prompt:

```
I'm attaching a Shiny app template zip called ShinyTemplate.zip.
This template already has working:
  - Google Sheets login gate (email allowlist)
  - Full user analytics tracking (tabs, clicks, sliders, session duration)
  - Admin reporting tab with user management and analytics charts
  - Dark DeepTech CSS theme

DO NOT modify these files:
  - R/sheets_backend.R
  - R/analytics_tracker.R
  - R/auth.R
  - modules/admin_reporting.R
  - www/css/global.css
  - www/css/auth.css
  - app.R (only modify APP_NAME and add new tabs)

REPLACE these dummy modules with real content:
  - modules/tab_one.R
  - modules/tab_two.R
  - modules/tab_three.R

BUILD: [describe your app here]

Each new tab should follow the pattern in the existing dummy tabs:
  - my_tab_ui(id) with ns <- NS(id) at top
  - my_tab_server(id, ...) with moduleServer
  - Wire in app.R sidebar + tabItems + server() at top level

The Google Sheets ID and admin email are already set in .Renviron.
The service account JSON is already in auth/.
```
