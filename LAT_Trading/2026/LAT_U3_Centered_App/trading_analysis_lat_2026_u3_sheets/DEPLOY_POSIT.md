# Running the app: desktop (default) or a Posit / Shiny server

The same code runs in both places. It detects a server by itself (Shiny Server sets `SHINY_SERVER_VERSION`; Posit Connect sets `RSTUDIO_PRODUCT=CONNECT`). Set `TRADING_RUNTIME=server` or `TRADING_RUNTIME=desktop` to force either mode.

| | Desktop (your PC) | Posit / Shiny server |
|---|---|---|
| Start | `shiny::runApp("trading_analysis_lat_2026_u3_sheets")` | Copy the folder into `/srv/shiny-server/` (Shiny Server), or `rsconnect::deployApp()` (Posit Connect) |
| Dropbox | **Folder** in Setup = your synced Dropbox folder (for example `C:/Users/you/Dropbox/LAT/Unit3`). Add the **API path** too if you also run the server | **API path** only (for example `/LAT/Unit3`). A folder on the server is ignored |
| Screenshots | Copied into `<folder>/Screenshots/<date>/` | Uploaded to `<API path>/Screenshots/<date>/` and downloaded again when a sheet is exported |
| PDF | Needs LibreOffice installed (Windows: `C:/Program Files/LibreOffice`) | Needs LibreOffice on the server: `sudo apt-get install -y libreoffice-writer` (Shiny Server). On Posit Connect / shinyapps.io it is usually missing: you still get the Word file |
| BigQuery | Sign in under API Configuration, or set `ATERA_BQ_KEY_FILE` | Set `ATERA_BQ_KEY_FILE` to the service-account JSON on the server |
| Claude | Paste the key under API Configuration, or set `ANTHROPIC_API_KEY` | Set `ANTHROPIC_API_KEY` (and `CLAUDE_MODEL` if you want a different model) |

## Environment variables

Desktop: put them in `~/.Renviron` (Windows: `Documents/.Renviron`). Shiny Server: put them in the app folder's `.Renviron`. Posit Connect: use the app's **Vars** panel. `Renviron.example` lists them all. **Never put keys in BigQuery or in the code.**

| Variable | What for |
|---|---|
| `ANTHROPIC_API_KEY` | Claude (screenshots, calendar, web search) |
| `CLAUDE_MODEL` | optional, for example `claude-sonnet-4-6` |
| `ATERA_BQ_KEY_FILE` | path to the BigQuery service-account JSON |
| `DROPBOX_APP_KEY`, `DROPBOX_APP_SECRET`, `DROPBOX_REFRESH_TOKEN` | Dropbox API **(recommended: the refresh token does not expire)** |
| `DROPBOX_ACCESS_TOKEN` | alternative to the three above; expires after about 4 hours |
| `TRADING_RUNTIME` | optional: `server` or `desktop` |

### Getting a Dropbox refresh token (once)
1. Go to https://www.dropbox.com/developers/apps, then **Create app**. Choose *Scoped access* and *App folder* (or *Full Dropbox*).
2. Under **Permissions**, tick `files.content.write` and `files.content.read`, then click Submit.
3. Open this link in a browser, replacing APP_KEY with your app key, and allow access:
   `https://www.dropbox.com/oauth2/authorize?client_id=APP_KEY&response_type=code&token_access_type=offline`
4. Exchange the code it shows for a refresh token, from any terminal:
   `curl https://api.dropbox.com/oauth2/token -d code=THE_CODE -d grant_type=authorization_code -u APP_KEY:APP_SECRET`
5. Copy `refresh_token` from the reply into `DROPBOX_REFRESH_TOKEN`, and put the app key and secret in the other two variables.

With an *App folder* app, the API path in Setup is relative to `Apps/<your app name>/`.

## Packages
`shiny shinydashboard shinycssloaders DT plotly R6 TTR quantmod dplyr tidyr zoo lubridate httr curl jsonlite bigrquery xml2 zip officer openxlsx png` (no igfetchr: this app does not use the IG API), plus `magick` (optional: shrinks big screenshots before they go to Claude).
For Posit Connect, run `rsconnect::writeManifest()` in the app folder before deploying.

## Fixed sheet folders (21 Oct)
Morning Sheets and Individual Trade Sheets are always saved, as Word + PDF, to:
- desktop: `C:/Users/jfz00/Dropbox/London Academy of Trading/Jose-F_Zubizarreta/Morning Sheets` and `.../Individual Trade Sheets`
- server (Dropbox API): `/London Academy of Trading/Jose-F_Zubizarreta/Morning Sheets` and `.../Individual Trade Sheets`. For these paths the Dropbox app needs **Full Dropbox** access, not "App folder".

The Trade Blotter and the Answer Sheet go to `.../Jose-F_Zubizarreta`. A file that is replaced is first copied to `_previous versions` (desktop); on the server, Dropbox's own version history keeps the earlier copy. Set `LAT_DROPBOX_ROOT` only to use another Dropbox root, for example on another computer.

## Decision Panel (24 Oct)
Trade Journal > **Decision Panel (before a trade)**. No setup needed beyond the above: it uses the same BigQuery tables (decisions are rows of `trading_evidence`, kind `decision_snapshot` / `no_trade`), the same Yahoo prices and the same Dropbox folders.
- Type the IG price (or read an IG ticket screenshot with Claude) so the Yahoo bars line up with IG points. Without it every level is marked "not aligned".
- Settings used: `risk_pct`, `combined_cap_pct`, `min_rrr`, `adx_trend_min`, `adx_range_max`, `plan_durations`, `opening_balance` (Trading Records > Setup).
- An expired order: Decision journal > Mark expired saves `Individual_Trade_Sheet_<Market>_<dd-mm-yyyy>_order_not_filled.docx` (+ PDF) to Individual Trade Sheets.

## Keys from a local folder (27 Oct)
On Windows the app looks in `C:\111_SecA\_q_api\` when it starts:
- **BigQuery:** the service-account key, a `.json` file with `"type": "service_account"`. The key for project `atera-2` is used first; otherwise the newest.
- **Claude:** the key on the single line of `ap_claude_1_line.txt`.

The API Configuration tabs say what was found. If nothing was found, or the app is not on Windows, load or paste the keys there as before; `ATERA_BQ_KEY_FILE` and `ANTHROPIC_API_KEY` still work. Set `LAT_CRED_DIR` to use another folder.
