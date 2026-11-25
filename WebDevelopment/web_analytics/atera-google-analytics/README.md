# Atera Analytics Dashboard - version 5.0.0

A Shiny dashboard for the GA4 property behind www.atera-analytics.co.uk.

## Run it

1. Unzip `atera-google-analytics.zip` (app.R is at the top level of the zip).
2. In RStudio open `app.R` and press **Run App** (or run `shiny::runApp()` from this folder).
   Tip: start from a fresh R session (Session > Restart R) so packages from older scripts are not loaded.

Packages needed: `shiny`, `shinydashboard`, `plotly`, `DT`, `httr`, `jsonlite`, `yaml`
(`gargle` is used if present). `googleAnalyticsR` is no longer required.

## Connect to Google Analytics

The app opens on demo data (clearly labelled). To see real visitors:

1. Sidebar > **API Configuration** > **Google Analytics** tab.
2. Upload the service account JSON key. Property ID is pre-filled with `515710306`.
3. The **Connection check** panel runs each step (key, Google sign-in, visible
   properties, test report) and prints Google's own error plus the fix if one fails.

Leave "Remember this key" ticked and the app reconnects by itself next time.
The key is copied to `credentials/` - treat that folder like a password.

## Saving charts (Google Drive or your computer)

Every chart has a **Save** button, and the header has **Save charts** for every chart on the page.
Formats: interactive HTML, PNG, SVG, PDF, GIF (time charts animate), JPEG, WebP, Plotly JSON, CSV of the chart data.
Destination: Google Drive, a download (one file, or a .zip laid out like the Drive folders), or both.

### Set up Google Drive once (API Configuration > Google Drive)

1. Google Cloud Console (project Atera 2) > APIs & Services > Library: enable **Google Drive API**.
2. In Google Drive create a **Shared drive** and add the service account
   (`atera-analytics-service@atera-2.iam.gserviceaccount.com`) as **Content manager**.
   Service accounts have no storage of their own, so an ordinary My Drive folder will fail the write test.
   Without shared drives, use Workspace domain-wide delegation and fill in "Act as this Workspace user".
3. Paste the shared drive / folder link, press **Connect & test**. The check panel says exactly what to fix.

### Folder scheme (editable on the same page)

```
<your folder>/
  Atera Analytics/
    _catalog/manifest.csv   <- every saved file, one row each (other apps read this)
    _catalog/README.txt
    GA4-515710306/                     (or "Demo data")
      Overview & Monitoring/          <- main group (sidebar)
        Overview/                     <- page (tab)
          Traffic over time/
            2026-11/traffic-over-time__2026-10-24_to_2026-11-20__20261121-234005.png
            latest/traffic-over-time.png   <- same file ID every save
```

Missing folders are created as files arrive; "Create folder tree now" builds the tab folders up front.

### Reading the files from another Shiny app

Copy `drive_reader.R` into the other app, give its service account Viewer access to the shared drive, then
`atera_catalog()`, `atera_latest()`, `atera_download()`, `atera_read_csv()`, `atera_plotly()`.

## Navigation: main groups and pages

The sidebar shows **main groups**; each group's pages are **tabs across the top** of the page.
The Period / Compare bar at the top applies to every page except Real-time and API Configuration.

| Main group (sidebar) | Pages (tabs) | Theme |
|---|---|---|
| Overview & Monitoring | Overview · Real-time · Trends & Forecast | The big picture: headline numbers and insights, right now, and where it is heading |
| Audience | Visitors · Acquisition | Who visits and where they come from |
| Content & Engagement | Page Performance · User Behaviour | What people read and do |
| Conversions & Actions | Contact Funnel · Website Events | What visitors act on: enquiries, calls to action, live platforms, the diagram, FAQs |
| Data Explorer | Data Explorer | Any report you like, charted and exported |
| API Configuration | Google Analytics · Google Drive · Debug Console | Connections and troubleshooting |

## Structure

```
app.R                          entry point: packages, period bar, shared data function, starts every page
core/                          shared code, sourced once
  nav.R                        builds sidebar + page tabs from the registry, starts page servers
  ga4_api.R  gdrive.R          Google Analytics and Google Drive clients
  analytics.R  demo_data.R     comparisons, forecast, anomalies, insights; demo data
  chart_export.R  helpers.R    chart saving pipeline; cards, KPI tiles, chart/table helpers, theme colours
  debug_capture.R              console capture for the Debug Console
modules/
  _module_registry.yml         main groups, their pages and order, tab labels, icons
  <Main group folder>/         one folder per main group
    <page id>.R                one file per page: header + <id>_ui(id) + <id>_server(id, ...)
www/styles.css                 teal suite theme (same design system as the Business Operations Suite)
www/export.js  www/vendor/     chart saving in the browser (jsPDF, JSZip, gifenc bundled)
drive_reader.R                 copy into other apps to read saved charts
credentials/                   saved keys (created when you tick "Remember"); never share
```

Rules (same as the reference suite):

- One folder per main group; file name = page id = function prefix (`<id>_ui`, `<id>_server`).
- A page's server asks for what it needs by naming it: `ctx` (data + period), `app` (GA4 connection), `drive` (Drive connection).
- To regroup pages, move ids between groups in `modules/_module_registry.yml` (and the file into that group's folder).
  To hide a page, set `enabled: false` for it under `pages:`. The app stops with a clear message if a listed file is missing.

## Website events (WordPress theme v5.3.0+)

The theme sends these GA4 events through the Site Kit Google tag:

| Event | Detail (custom dimension) |
|---|---|
| generate_lead (key event) | form_id |
| contact_form_start, form_error | form_id |
| cta_click | cta_location (+ built-in link text / URL) |
| navigation_click | nav_location (+ link text) |
| app_open | app_name (shinyapps.io platforms) |
| architecture_view, architecture_select, architecture_open_full | architecture_component |
| faq_open | faq_question |
| scroll_depth | percent_scrolled (25/50/75/100) |

Once, after installing the theme: Website Events > **Set up in GA4**. It registers the custom
dimensions and marks generate_lead as a key event (needs the service account to be Editor or
Administrator on the property, and the "Google Analytics Admin API" enabled). Custom dimensions
only collect from the moment they are registered.

## Changes

- 5.0.0 - Redesigned navigation and look, modelled on the Business Operations Suite: six themed main groups in the
  sidebar, related pages as tabs across the top, page headings with a one-line purpose, teal theme with white cards.
  Navigation is driven by modules/_module_registry.yml; one folder per main group. Saved charts now go into
  Drive folders named after the main group (e.g. Audience/Visitors) and default to the light look.
- 4.1.0 - Fixed "is.character(txt) is not TRUE" / "unused argument (need(...))" errors on every chart when
  jsonlite (or httr) was already loaded in the R session: the app now pins shiny::validate/need/req and
  plotly::layout/config. Zip renamed to atera-google-analytics.zip with app.R at the top level.
- 4.0.0 - Website Events tab and one-click GA4 set-up for the WordPress theme's events.
- 3.0.0 - Save charts to Google Drive / download; Google Drive settings tab.
- 2.0.0 - Rebuilt on live GA4 data: comparisons, forecast, anomalies, Data Explorer.
