# app.R - LAT Unit 3 Trading Records
# The Unit 3 subset of Trading Analysis F1: Morning Sheets, Individual Trade Sheets and the Blotter from IG screenshots
# (Claude API) and online data, saved to BigQuery and Dropbox; the Unit 3 guidance, Live Signals, Execution Plan and
# the Report Builder. Runs on your computer (shiny::runApp()) or on a Posit / Shiny server (see DEPLOY_POSIT.md).

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(lubridate)
library(shinycssloaders)
library(TTR)
library(tidyr)
library(quantmod)
library(zoo)
library(httr)
library(jsonlite)
library(bigrquery)
library(curl)

source("global.R", local = TRUE)
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

u3_instruments <- list(
  Commodities = c("Brent crude (BZ=F)" = "BZ=F", "WTI crude (CL=F)" = "CL=F", "Gold (GC=F)" = "GC=F", "Natural gas (NG=F)" = "NG=F"),
  Forex = c("EUR/USD" = "EURUSD=X", "GBP/USD" = "GBPUSD=X", "USD/JPY" = "JPY=X", "AUD/USD" = "AUDUSD=X"),
  Indices = c("Dow Jones (^DJI)" = "^DJI", "Nikkei 225 (^N225)" = "^N225", "FTSE 100 (^FTSE)" = "^FTSE"))
u3_class_of <- function(sym) if (sym %in% u3_instruments$Forex) "forex" else if (sym %in% u3_instruments$Commodities) "commodity" else "equity"

# ---- "Start here": the daily routine, and which screen fills which box --------------------------------------------
u3_start_ui <- function() {
  st <- function(n, title, ...) tags$div(style = "display:flex; gap:12px; margin-bottom:12px;",
    tags$div(style = "flex:0 0 34px; height:34px; border-radius:17px; background:#008A82; color:#fff; font-weight:800; display:flex; align-items:center; justify-content:center;", n),
    tags$div(style = "flex:1;", tags$div(style = "font-weight:800; color:#002C3C; font-size:14px;", title), tags$div(style = "font-size:12.5px; color:#334155; line-height:1.6;", ...)))
  tagList(
    tags$div(style = "background: linear-gradient(135deg, #002C3C 0%, #008A82 100%); border-radius: 12px; padding: 16px 20px; margin-bottom: 14px; color:#fff;",
      tags$h3(style = "margin:0 0 4px 0; font-size:19px; font-weight:800; color:#fff;", "Unit 3: every day of the trading period"),
      tags$div(style = "font-size:13px; color:#eafffb; line-height:1.6;", "The LAT asks for a Morning Sheet every trading day, an Individual Trade Sheet for every trade and the Trade Blotter. ",
               "This app fills them from your IG screenshots and online data, keeps everything in BigQuery and Dropbox, and makes the Word + PDF files. The boxes that need your own judgement stay yours to write.")),
    fluidRow(
      column(6, box(width = 12, status = "primary", solidHeader = TRUE, title = "Once",
        st(1, "API Configuration", "BigQuery: sign in with the service-account key (or set ATERA_BQ_KEY_FILE). Claude API: paste the key and Test Connection (or set ANTHROPIC_API_KEY)."),
        st(2, "Trading Records > 1. Connection & Setup", "Create / verify tables. Your name, LAT ID, period, plan numbers and ", tags$b("your expected duration per chart period"), ", then Save settings. Press ",
           tags$b("Test Dropbox"), ". Sheets always go to ", tags$code("Dropbox/London Academy of Trading/Jose-F_Zubizarreta/Morning Sheets"), " and ", tags$code(".../Individual Trade Sheets"), ", Word + PDF, saved automatically after every change."),
        st(3, "Catch up once", tags$b("Complete past Morning Sheets and trades"), " (Setup): every trading day since 12 Oct gets its overnight levels from Yahoo; sheets already in Dropbox are kept."))),
      column(6, box(width = 12, status = "info", solidHeader = TRUE, title = "Rules that keep the work yours",
        tags$ul(style = "font-size:12.5px; line-height:1.6; padding-left:18px;",
          tags$li("Claude only copies values from your screenshots and finds published data with its sources. It never writes your set-up, trigger, execution, reasons, lessons, plan, evaluation or SWOT."),
          tags$li("Crop account names and numbers out of screenshots before uploading."),
          tags$li("Values that cannot be read stay empty, or are marked as estimates. Nothing is invented."),
          tags$li("Say in your submission that records were transcribed with an AI tool from your own platform screenshots (it is in the References list)."))))),
    box(width = 12, status = "success", solidHeader = TRUE, title = "Every trading day",
      fluidRow(
        column(6,
          st("AM", "Morning Sheet (Trading Records > 2)",
             tags$b("IG screenshots: "), "watchlist with Dow (Wall Street), Japan 225, EUR/USD, USD/JPY, GBP/USD, AUD/USD, Oil - US Crude, Spot Gold, Oil - Brent Crude, then ", tags$b("Read levels with Claude"), ". ",
             tags$b("Calendar: "), "IG economic calendar for yesterday and today, then ", tags$b("Read calendar"), " (the pictures are also kept for the sheet). ",
             tags$b("Low / High: "), tags$b("Fill Low / High from Yahoo"), " (overnight range 21:00 to now, scaled to IG points). ",
             "Type your overnight news notes, then ", tags$b("Fill every empty cell and save"), ": Yahoo fills the rest, Claude adds sourced headlines / calendar only if those boxes are empty, and the Word + PDF land in Dropbox."),
          st("PLAN", "Before a trade (Decision Panel)",
             "Read the IG ticket (or type the IG price): levels, noise, regime, calendar and your record are lined up with IG prices. ",
             "Choose Buy / Sell / No trade, fill entry, stop, target and the six boxes in your own words while you look at the facts, then ", tags$b("Save decision snapshot"), ". ",
             "When the trade is saved it links itself and your words fill its empty boxes. An order that expires: Decision journal > ", tags$b("Mark expired"), " saves the 'order not filled' Trade Sheet."),
          st("IN", "Opening a trade (Order Evidence)",
             "Screenshots of the ", tags$b("deal ticket"), " and the ", tags$b("Positions row"), " (entry, stop, limit), then ", tags$b("History > Activity"), " (the time the position opened). ",
             "Read them, Send to Trades, choose Assessed, check the values and Save. If no time was shown, the Activity screenshot fixes it later.")),
        column(6,
          st("MG", "Managing it", "Trades > B: Moved stop / Partial exit with the time. Exports > Pictures: save the updated chart as ", tags$i("In-trade"), " for that action."),
          st("OUT", "Closing it", tags$b("History"), " 'Closed in the last 24 hours' screenshot > Order Evidence > Send to Trades (it finds the matching open trade) > exit code, plan followed? > Save."),
          st("PM", "Completing the Trade Sheet (Exports)",
             tags$b("Pictures: "), "entry chart(s) with captions (4 Hour, 1 Hour, 15 Min...), exit and post-exit charts. ",
             tags$b("Complete this sheet: "), "chart period, expected duration and YOUR set-up, trigger, execution, reasons, reason for exit and lessons, written while you look at the facts panel. ",
             "Every save updates the Word + PDF in Dropbox (the earlier file is kept in '_previous versions'). Empty chart slots get a chart drawn from Yahoo prices, labelled as such: replace it with your IG chart when you can.")))),
    box(width = 12, status = "warning", solidHeader = TRUE, title = "Each week and at the end",
      tags$div(style = "font-size:12.5px; line-height:1.6;", tags$b("Unit 3 > Report Builder: "), "coverage of every trading day, the numbers and labelled figures for Task 2 and Task 3, your References and the Answer Sheet filled with your own text (word count per task, name and LAT ID, figures numbered and labelled). ",
               tags$b("Exports: "), "the Trade Blotter and statistics (Excel).")))
}

ui <- dashboardPage(
  dashboardHeader(title = "LAT Unit 3 Records", titleWidth = 260),
  dashboardSidebar(width = 260,
    sidebarMenu(id = "sidebar_menu",
      menuItem("Start here", tabName = "u3_start", icon = icon("flag-checkered")),
      menuItem("Trade Journal", icon = icon("file-invoice"), startExpanded = TRUE,
        menuSubItem("Trading Records (BigQuery)", tabName = "trading_records", icon = icon("database"), selected = TRUE),
        menuSubItem("Decision Panel (before a trade)", tabName = "trading_decision", icon = icon("scale-balanced")),
        menuSubItem("Order Evidence (Claude)", tabName = "trading_evidence", icon = icon("camera"))),
      menuItem("Unit 3", icon = icon("graduation-cap"), startExpanded = TRUE,
        menuSubItem("Report Builder (Tasks 1-3)", tabName = "u3_report", icon = icon("file-lines")),
        menuSubItem("Assignment & Plan Guide", tabName = "unit3_workbench", icon = icon("screwdriver-wrench")),
        menuSubItem("Live Signals", tabName = "unit3_live_signals", icon = icon("bolt")),
        menuSubItem("Execution Plan", tabName = "unit3_execution_plan", icon = icon("list-check"))),
      menuItem("API Configuration", icon = icon("key"),
        menuSubItem("BigQuery", tabName = "econ_bigquery_auth", icon = icon("database")),
        menuSubItem("Claude API", tabName = "econ_claude_config", icon = icon("robot")),
        menuSubItem("Trello & Jira", tabName = "trello_jira_config", icon = icon("trello")),
        menuSubItem("Debug Console", tabName = "debug_console", icon = icon("terminal")))
    ),
    tags$div(style = "padding:10px; background-color:#2c3e50; margin-top:10px;",
      tags$div(style = "color:#b2e0db; font-size:11px; font-weight:700; margin-bottom:4px;", "LIVE SIGNALS MARKET (Yahoo Finance)"),
      selectInput("u3_symbol", NULL, choices = u3_instruments, selected = "BZ=F", width = "100%"),
      selectInput("u3_resolution", NULL, width = "100%", selected = "60m",
                  choices = c("15 minutes (~60 days)" = "15m", "30 minutes (~60 days)" = "30m", "1 hour (~2 years)" = "60m", "Daily" = "1d")),
      tags$p("Yahoo prices differ from IG prices (IG quotes oil in points). Use them for the regime and trigger checks; take your levels from IG.",
             style = "font-size:10.5px; color:#b2e0db; font-style:italic; line-height:1.4;")),
    tags$style(HTML("#api_status:empty::before { content: 'BigQuery: connecting...   Claude: connecting...'; color:#fbbf24; font-size:11.5px; }")),
    tags$div(style = "padding:10px; background-color:#2c3e50; margin-top:6px;",
      tags$div(style = "color:#b2e0db; font-size:11px; font-weight:700; margin-bottom:4px;", "API CONNECTIONS"),
      uiOutput("api_status"))
  ),
  dashboardBody(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"), tags$meta(charset = "UTF-8"),
              tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0")),
    tabItems(
      tabItem(tabName = "u3_start", u3_start_ui()),
      tabItem(tabName = "trading_records", trading_records_ui("trading_records")),
      tabItem(tabName = "trading_evidence", trading_evidence_ui("trading_evidence")),
      tabItem(tabName = "trading_decision", trading_decision_ui("trading_decision")),
      tabItem(tabName = "u3_report", u3_report_builder_ui("u3_report")),
      tabItem(tabName = "unit3_workbench", unit3_workbench_ui("unit3_workbench", guidance_only = TRUE)),
      tabItem(tabName = "unit3_live_signals", unit3_live_signals_ui("unit3_live_signals")),
      tabItem(tabName = "unit3_execution_plan", unit3_execution_plan_ui("unit3_execution_plan")),
      tabItem(tabName = "econ_bigquery_auth", econ_bigquery_auth_ui("econ_bigquery_auth")),
      tabItem(tabName = "econ_claude_config", econ_claude_config_ui("econ_claude_config")),
      tabItem(tabName = "trello_jira_config", trello_jira_config_ui("trello_jira_config")),
      tabItem(tabName = "debug_console", debug_console_ui("debug_console"))
    )
  )
)

server <- function(input, output, session) {
  shared_econ_state <- reactiveValues(transfer_df = NULL, transfer_asset_class = NULL, transfer_ts = 0)   # used by Live Signals
  observe({ sym <- input$u3_symbol; req(sym); data_manager$set_current_asset(sym, u3_class_of(sym), input$u3_resolution %||% "60m") })

  # credentials from the environment (desktop .Renviron, or the server's variables)
  local({
    # 1. keys in the local folder (Windows: C:\111_SecA\_q_api\), then 2. the environment, then 3. the API Configuration tabs
    st <- list(bq = NULL, claude = NULL, dir = tr_cred_dir())
    lc <- tryCatch(tr_local_credentials(), error = function(e) list(notes = conditionMessage(e)))
    if (length(lc$notes)) cat("[Keys]", paste(lc$notes, collapse = " "), "\n")
    if (!is.na(tr_or(lc$json_path, NA)) && !isTRUE(api_manager$bq_authenticated)) {
      ok <- tryCatch({ api_manager$authenticate_bigquery(json_path = lc$json_path); TRUE }, error = function(e) { cat("[BigQuery] key from", lc$json_path, "failed:", conditionMessage(e), "\n"); FALSE })
      st$bq <- if (ok) sprintf("Connected automatically with %s (found in %s).", basename(lc$json_path), lc$dir) else sprintf("A key was found (%s) but the connection failed: see the Debug Console.", basename(lc$json_path))
    }
    if (!is.na(tr_or(lc$claude_key, NA)) && !isTRUE(api_manager$claude_authenticated)) {
      m <- Sys.getenv("CLAUDE_MODEL", ""); api_manager$set_claude_credentials(lc$claude_key, model = if (nzchar(m)) m else NULL)
      cat("[Claude] API key taken from", file.path(lc$dir, "ap_claude_1_line.txt"), "\n")
      st$claude <- sprintf("Key loaded automatically from %s (%s). Press Test Connection to check it.", file.path(lc$dir, "ap_claude_1_line.txt"), tr_mask_key(lc$claude_key))
    }
    assign(".u3_cred_status", st, envir = .GlobalEnv)
    key <- Sys.getenv("ATERA_BQ_KEY_FILE", Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS", ""))
    if (nzchar(key) && file.exists(key) && !isTRUE(api_manager$bq_authenticated))
      tryCatch(api_manager$authenticate_bigquery(json_path = key), error = function(e) cat("[BigQuery] automatic sign-in failed:", conditionMessage(e), "\n"))
    k <- Sys.getenv("ANTHROPIC_API_KEY", "")
    if (nzchar(k) && !isTRUE(api_manager$claude_authenticated)) {
      m <- Sys.getenv("CLAUDE_MODEL", ""); api_manager$set_claude_credentials(k, model = if (nzchar(m)) m else NULL)
      cat("[Claude] API key taken from ANTHROPIC_API_KEY\n")
    }
  })

  # sidebar lights: BigQuery / Claude readiness (re-checked every 3 s, so a key loaded later in API Configuration shows too)
  output$api_status <- renderUI({
    invalidateLater(3000)
    st <- u3_cred_status()
    light <- function(name, ok, wait, txt) {
      col <- if (ok) "#22c55e" else if (wait) "#fbbf24" else "#ef4444"
      tags$div(style = "display:flex; align-items:flex-start; gap:6px; margin:3px 0; font-size:11.5px; color:#ecf0f1;",
        tags$span(style = sprintf("display:inline-block; width:10px; height:10px; border-radius:50%%; background:%s; margin-top:3px; flex:none;", col)),
        tags$span(tags$b(name, ": "), txt)) }
    bq <- isTRUE(api_manager$bq_authenticated); cl <- isTRUE(api_manager$claude_authenticated)
    bq_fail <- !bq && !is.null(st$bq)
    tagList(
      light("BigQuery", bq, FALSE, if (bq) "ready" else if (bq_fail) "key found, connection failed (see Debug Console)" else "not connected: API Configuration > BigQuery"),
      light("Claude", cl, FALSE, if (cl) "ready (key loaded)" else "no key: API Configuration > Claude API"))
  })

  econ_bigquery_auth_server("econ_bigquery_auth", api_manager)
  econ_claude_config_server("econ_claude_config", api_manager)
  trello_jira_config_server("trello_jira_config", api_manager)
  debug_console_server("debug_console")

  records_store <- tr_make_store(tr_bq_backend(api_manager))
  records_bus <- reactiveValues(ts = 0, kind = NULL, values = NULL, evidence_id = NULL)
  records_pictures <- new.env(parent = emptyenv())
  trading_records_server("trading_records", api_manager, records_store, bus = records_bus, pictures = records_pictures)
  trading_evidence_server("trading_evidence", api_manager, records_store, records_bus, pictures = records_pictures)
  trading_decision_server("trading_decision", api_manager, records_store, bus = records_bus, pictures = records_pictures)
  u3_report_builder_server("u3_report", records_store, active = reactive(identical(input$sidebar_menu, "u3_report")))

  unit3_workbench_server("unit3_workbench", data_manager)
  unit3_live_signals_server("unit3_live_signals", data_manager, api_manager, shared_econ_state)
  unit3_execution_plan_server("unit3_execution_plan", records_store)
}

shinyApp(ui, server)
