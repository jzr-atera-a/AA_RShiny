# Titan Events – handover notes for the next developer / LLM

This file explains what the app does, how it is built, what has been learned about the
Titan calendar server, and what is still open. Read it fully before changing code.

## 1. Purpose

An R Shiny app that creates calendar events and saves them **directly into a Titan
calendar over CalDAV**, so the user doesn't have to open the Titan mobile app or the
Titan calendar website. It can also import events from an `.ics` file, list events in a
date range, show an event's raw stored data, and delete events.

## 2. The user's setup (confirmed)

- Mailbox: **Professional Email powered by Titan, bought through a GoDaddy-family
  reseller** (the webmail is branded *123 Reg*, "powered by Titan"; account sign-in page
  `sso.secureserver.net`). Domain: `atera-analytics.co.uk`.
- The website's contact form (WordPress + WPForms + WP Mail SMTP) sends via
  `smtpout.secureserver.net`, port 465, SSL. That is GoDaddy's SMTP for Titan mailboxes.
  It is only proof that SMTP works; it isn't used by this app.
- **Working CalDAV server: `https://dav.myprofessionalmail.com`.**
  `dav.titan.email` / `dav-eu.titan.email` are for direct Titan customers.
- Sign-in: full email address + **mailbox** password (Basic auth over HTTPS).
- Confirmed working layout (from the app's Log):
  - principal / calendar home: `https://dav.myprofessionalmail.com/principals/<email>`
  - calendars are listed at: `https://dav.myprofessionalmail.com/principals/<email>/calendar/`
  - one calendar is found, display name like `atera-analytics.co.uk, <user>`; its URL is
    `.../principals/<email>/calendar/<numeric id>/`

## 3. Files

The zip handed to the user must contain these files **at the top level, with no
enclosing folder** (the user asked for this explicitly):

| File | Role |
|---|---|
| `app.R` | Shiny UI and server logic. `source("caldav.R")` at the top. |
| `caldav.R` | All iCalendar building/parsing and CalDAV HTTP requests. No Shiny code. |
| `README.md` | End-user instructions. |
| `HANDOVER.md` | This file. |

Run with: `shiny::runApp("<folder>")`.
Packages: `shiny`, `bslib`, `DT`, `httr2`, `xml2`, `uuid` (developed on R 4.3,
shiny 1.8, httr2 1.0, bslib 0.6, DT 0.31). `caldav.R` defines `%||%` itself for R < 4.4.
Optional env vars `TITAN_EMAIL` / `TITAN_PASSWORD` prefill the sign-in fields.

## 4. App walkthrough (app.R)

Sidebar:
- **Calendar server** select. Default **Auto-detect**, which tries in order
  `dav.myprofessionalmail.com`, `dav.titan.email`, `dav-eu.titan.email` (`SERVER_URLS`)
  and stops at the first that yields calendars. "Other CalDAV server..." accepts any URL
  (used for local testing).
- Email, password, **Connect** → `discover_calendars()`. Each attempt writes a
  "Connection test for …" block to the Log (step, HTTP status, URL, note).
- **Save events to**: the calendar picked from the discovered list.
- "Calendar URL manually": bypasses discovery with a pasted calendar URL.

Tabs:
1. **New events**: title, date, start (HH:MM text), duration (minutes), all-day, time zone
   (default `Europe/London`), location, notes, reminder checkboxes + an optional custom
   reminder. "Add to list" queues; "Save to Titan now" saves one; "Save all to Titan"
   saves the queue (failed items stay queued); "Download .ics" exports the queue.
2. **Import .ics file**: uploads a file, `split_ics()` turns it into one calendar object
   per UID, then the events are saved. There's an optional "replace if same UID" checkbox.
3. **Upcoming events**: date range + **Refresh** (loads **only on Refresh**, never
   automatically) → `list_events()`. The table shows Start/End/Title/Reminders (count of
   `VALARM`s). "Show raw event data" GETs each selected event and shows it in a modal.
   "Delete selected from Titan" (with confirmation) DELETEs.
4. **Log**: newest-first log of connection tests, saves, loads and failures.

State lives in `reactiveValues rv` (calendars, connected, status, queue, imported,
events, log). Credentials are only kept in memory.

## 5. caldav.R function reference

iCalendar:
- `ics_escape()`: escapes `\ ; ,` and newlines.
- `ics_fold()`: folds lines at 75 octets without splitting UTF-8 characters.
- `build_event_ics(title, start, end, all_day, location, description, alarms, uid)`:
  produces a one-event VCALENDAR with CRLF line endings. Times are written in **UTC**
  (`...Z`), so DST is handled by R's time zone conversion; all-day events use
  `VALUE=DATE`. One `VALARM` (ACTION:DISPLAY, `TRIGGER:-PT<n>M`) is written per reminder.
  **Titan strips these** (see §6).
- `combine_ics()`: merges several events into one file for download.
- `ics_unfold()`, `split_ics()`: split an uploaded file per UID. `split_ics()` drops
  `METHOD` (not allowed in stored CalDAV objects), copies VTIMEZONEs to each piece and
  adds a UID if one is missing.
- `parse_vevent()`: tolerant summary of the first VEVENT, or NULL. `parse_ics_time()`
  reads UTC, TZID (quoted or not) and date-only values, returning NA instead of an error.

CalDAV:
- `dav_request(url, user, pass, method, body, depth, headers, timeout = 30)`: an httr2
  request with Basic auth that never throws on HTTP status.
- `discover_calendars(server, user, pass)` returns `list(calendars, trace)`:
  1. PROPFIND `current-user-principal` on the candidates `/principals/<email>`, the same
     with `/`, the same URL-encoded, `/.well-known/caldav`, and `/`;
  2. PROPFIND `calendar-home-set`;
  3. PROPFIND Depth 1 on the home(s), keeping collections whose resourcetype includes
     `calendar` (and VEVENT, if components are listed), descending one level if needed.
  On failure it throws an error whose message distinguishes unreachable, 401 everywhere,
  and "signed in but no calendars"; the error carries `$trace`.
- `put_event(calendar_url, ..., ics, uid, overwrite)`: PUT to `<calendar>/<uid>.ics` with
  `If-None-Match: *` unless overwriting. Returns `list(ok, status, message, url)`
  (201 Created, 204 Updated, 412 Already exists).
- `list_events(calendar_url, ..., from, to, budget = 25)`: a calendar-query REPORT with a
  time-range. Items returned without readable `calendar-data` are fetched with
  **calendar-multiget in batches of 50**, within a total time budget. The result has the
  attributes `skipped` and `sample` (the start of the server's answer, which the app logs
  when something couldn't be read).
- `get_event_raw(href, ...)`: GET one event. `delete_event(href, ...)`: DELETE.

## 6. What the Titan server does (observed on the user's account)

- Saving with PUT works (201 Created). Titan **rewrites the stored event**. The raw data
  of an app-created event ("Test 6") came back as:
  - `PRODID://Flock //Flock Calendar 0.01p//EN` (Titan's backend is "Flock"; the alternate
    host `dav.flockmail.com` appears in Titan documentation)
  - calendar-level `NAME`, `COLOR`, `METHOD:PUBLISH`, and `URL:/principals/<email>/calendar/<id>/TITAN1-1-<n>-<rand>.ics`
  - event-level `X-TITAN-MEET:`, `X-TITAN-EVENT-FLAG:19`, `X-NEW-ICS-TEMP:t`, `SEQUENCE`,
    `TRANSP`, `ORGANIZER`, `STATUS:CONFIRMED`, `CREATED`, `LAST-MODIFIED`
  - **no `VALARM`**: Titan discarded the reminder the app sent.
- Titan's per-event "Push notification" / "Email reminder" (website) and "Notify me"
  (mobile) are therefore **not set by `VALARM`**. They aren't known to be stored in the
  CalDAV data at all; this is unconfirmed (see §8).
- **Workaround in use, confirmed working by the user:** in the Titan calendar website,
  hover the calendar name in the left panel → ⋮ → **Settings and sharing** →
  "Calender notifications" → set **Push notification** (set to *15 minutes before*). New
  events saved by the app then get that push reminder. It's the same reminder for every
  event, and existing events are not changed.

## 7. Lessons from debugging (don't repeat these)

- **Shiny is single-threaded per process.** A long-running observer freezes the whole app:
  saves queue silently, the Log doesn't update, and the page looks dead. An earlier version
  fetched every unreadable event with its own GET and auto-loaded on tab switch. That froze
  the app for minutes. Keep every network call bounded (timeouts, batching, time budget)
  and avoid automatic heavy loads.
- An earlier parser crashed with `NA/NaN argument` when an item had no
  `BEGIN:VEVENT` (`l[i:j]` with NA). Parsing must tolerate empty items, tasks,
  lowercase keywords, trailing spaces and missing DTEND.
- **An empty Log and an empty table with only headers** means the browser page is
  disconnected from R (R restarted or crashed, or an old tab is open), not a server delay.
  Fix: stop R fully, run `runApp` again, use the new window, and check the R console for
  errors.
- In discovery, don't abort on the first 401 or 404. Try all candidate URLs and log each.

## 8. Open items / next steps

1. **Per-event reminders.** Find out whether Titan stores the website's per-event
   push/email reminder anywhere in CalDAV. Method: create an event in the Titan website
   with a non-default push notification (e.g. 5 min), then compare its "Show raw event
   data" with an app-created event. Check whether a `VALARM` appears or
   `X-TITAN-EVENT-FLAG` differs from 19. If it does, write that form in `build_event_ics()`.
   If it doesn't, reminders are server-side only and the account default (§6) is the only
   automatic option.
2. **UI honesty.** Until (1) is solved, the reminder checkboxes in "New events" have no
   effect in Titan. Consider relabelling them ("written to the .ics only; Titan uses the
   calendar's default notification") or hiding them for Titan servers.
3. Possible extras: recurring events (needs TZID + VTIMEZONE rather than UTC, so local
   times stay fixed across DST), editing existing events (GET → modify → PUT with
   `If-Match` ETag), and an app-password note if the user enables 2-step verification.

## 9. Testing without the real account

The real Titan servers weren't reachable from the build sandbox, so tests used:
- **Radicale** (`pip install radicale`) as a standard local CalDAV server, with htpasswd
  `plain` auth, `MKCALENDAR` to create a calendar, and the server set to "Other CalDAV
  server..." `http://127.0.0.1:5232`.
- A small **Python mock server** that imitates suspected Titan behaviour: calendar-query
  returns hrefs without calendar-data, and calendar-multiget returns the data. It was used
  to check that 300 events load in about 6 seconds without freezing.
- `shiny::testServer()` for server logic, plus driving the running app over Shiny's
  websocket protocol for browser-like checks. When doing that, send an empty numeric
  input as `"custom_rem:shiny.number": null`, as a browser does; otherwise R gets `NULL`
  and you get a false error.

Always repackage with `zip app.R caldav.R README.md HANDOVER.md` from inside the app
folder (flat zip).
