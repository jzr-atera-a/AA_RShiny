# Setup Guide — Google Sheets Auth & Analytics

## What this system does

| Feature | How it works |
|---|---|
| **User allowlist** | Read from a Google Sheet tab — edit the Sheet to add/remove users instantly |
| **Login log** | Every login attempt (success or denied) written to Sheet |
| **Tab tracking** | Every tab the user visits, with time spent |
| **Box/button clicks** | Every interaction tracked with element name |
| **Slider changes** | Key inputs tracked with debounce (1.5s) |
| **Admin dashboard** | Tab 11 (admin emails only) — user management + all charts |

---

## Step 1 — Create the Google Sheet

1. Go to [sheets.google.com](https://sheets.google.com) and create a new sheet.
2. Name it: **VentureDeals Analytics**
3. Create **3 tabs** with these exact names:

### Tab: `allowed_emails`
| email | role | added_by | added_date | notes |
|---|---|---|---|---|
| alice@company.com | admin | setup | 2024-01-01 | |
| bob@company.com | user | alice@company.com | 2024-01-01 | |

### Tab: `login_log`
| timestamp | email | role | success | ip | session_id |
|---|---|---|---|---|---|
*(leave empty — app writes here)*

### Tab: `analytics_log`
| timestamp | email | session_id | event_type | tab | element | detail | duration_secs |
|---|---|---|---|---|---|---|---|
*(leave empty — app writes here)*

4. Copy the **Sheet ID** from the URL:
   ```
   https://docs.google.com/spreadsheets/d/COPY_THIS_PART/edit
   ```

---

## Step 2 — Create a Google Service Account

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a project (or select existing)
3. Enable **Google Sheets API** and **Google Drive API**
4. Go to **IAM & Admin → Service Accounts → Create Service Account**
5. Name it: `venturedeals-app`
6. Click **Create and Continue → Done**
7. Click the service account → **Keys → Add Key → JSON**
8. Download the JSON file
9. **Save it as:** `auth/google_service_account.json` in the app folder

---

## Step 3 — Share the Sheet with the service account

1. Open the JSON file — copy the `client_email` value (looks like `venturedeals-app@project.iam.gserviceaccount.com`)
2. In Google Sheets, click **Share**
3. Paste that email → set role to **Editor** → Share

---

## Step 4 — Configure environment variables

### On shinyapps.io:
1. Go to your app → **Settings → Environment Variables**
2. Add:

| Variable | Value |
|---|---|
| `GOOGLE_SHEETS_ID` | Your Sheet ID from Step 1 |
| `ADMIN_EMAILS` | `admin@company.com,another@company.com` (comma-separated) |

### For local development:
Create a `.Renviron` file in the project root:
```
GOOGLE_SHEETS_ID=your_sheet_id_here
ADMIN_EMAILS=admin@company.com
```

---

## Step 5 — Deploy

```r
# Install required packages first
install.packages(c("googlesheets4", "googledrive", "dplyr"))

# Deploy (bundles auth/google_service_account.json automatically)
rsconnect::deployApp(
  appDir  = "path/to/VentureDeals",
  appName = "venture-deals-deeptech"
)
```

---

## Managing users (after deployment)

**Add a user:** Open the Google Sheet → `allowed_emails` tab → add a row.
Takes effect within 60 seconds (cache refresh). No app restart needed.

**Remove a user:** Use the Admin Analytics tab inside the app (admin emails only),
or delete/prefix with `REMOVED_` directly in the Sheet.

**View activity:** Open the Admin Analytics tab — shows live data from the Sheet.

---

## How tracking works

### Events captured

| Event type | What triggers it | Data captured |
|---|---|---|
| `session_start` | User logs in | hostname |
| `tab_view` | User clicks a sidebar tab | tab name |
| `tab_exit` | User leaves a tab | tab name, seconds spent |
| `box_click` | User clicks any `.box` | box title, tab |
| `button_click` | Any action button | button ID, label, tab |
| `input_change` | Slider/input changes (debounced 1.5s) | element ID, new value |
| `plot_interact` | Plotly zoom/select | plot ID |
| `session_end` | Browser tab closed | total session seconds |

### Flush interval
Events are batched and written to Google Sheets every **30 seconds**,
plus immediately on session end. This keeps API calls low.

---

## Fallback behaviour

If Google Sheets is unavailable (no credentials, API down):
- Auth falls back to `auth/allowed_emails.txt` (one email per line)
- Analytics events are silently dropped (no crash)
- App continues to function normally

---

## File structure added

```
VentureDeals/
├── auth/
│   ├── google_service_account.json   ← you add this (never commit to git)
│   └── allowed_emails.txt            ← fallback list
├── R/
│   ├── sheets_backend.R              ← Sheets read/write layer
│   ├── analytics_tracker.R           ← event capture & flush
│   └── auth.R                        ← login gate
├── modules/
│   └── admin_reporting.R             ← Tab 11 (admin only)
└── www/css/
    └── auth.css                      ← login screen styles
```

---

## Security notes

- The service account JSON key should **never be committed to a public git repo**.
  Add `auth/google_service_account.json` to `.gitignore`.
- This is an allowlist gate — it prevents unauthorised access effectively for
  internal tools. For GDPR-sensitive or highly confidential data, use
  **Posit Connect** with its built-in identity provider integration instead.
- All login attempts (including denied ones) are logged with timestamp.
