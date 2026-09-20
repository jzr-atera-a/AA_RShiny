# modules/econ_calendar_live_link.R
#
# "Link to Live Trading" — an explainer tab only. No new code/data wiring
# here; it describes how the economic_calendar_summary table could connect
# to this app's actual live/trading touchpoints. Written against what
# genuinely exists in THIS build (IG session integration, Trade Journal) —
# not assuming any live-signals module that isn't part of this codebase.

econ_calendar_live_link_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ua_intro("Economic Calendars", "Link to Live Trading \u2014 How This Could Work", "\u2014", "\u2014",
             "An explainer, not new functionality: how the calendar data in this group could feed into this app's live/trading touchpoints."),

    ua_callout(paste0(
      "This app currently has two real \u201clive\u201d touchpoints: the IG broker session (R/utils_ig.R, ",
      "used by Market Overview/Composite Analysis for live prices) and the Trade Journal's Individual ",
      "Trade Sheet (manual entry). There is no dedicated automated \u2018live signals\u2019 module in this build ",
      "to plug into \u2014 the description below is a design for how one could be built on top of what's here."
    )),

    tags$h4("1. Pre-flagging high-impact windows"),
    tags$p(paste0(
      "Query `economic_calendar_summary` for rows where event_date falls within the next N hours/days and ",
      "event_importance = 'High'. This gives a simple list of upcoming windows where volatility is likely to ",
      "spike \u2014 exactly the kind of thing a regime/trigger check (ADX read, breakout screen, etc.) should be ",
      "aware of before treating a sudden move as a clean technical signal rather than a news reaction."
    )),

    tags$h4("2. Asset-specific filtering against whatever's on screen"),
    tags$p(paste0(
      "Because every row carries asset_class and specific_asset, a live view could filter to just the asset ",
      "currently selected elsewhere in the app (the same selectors already used by Market Overview, Composite ",
      "Analysis, and the Extended Indicators group) and surface only the events relevant to that instrument \u2014 ",
      "e.g. show only Gold-relevant rows when Gold is the active chart."
    )),

    tags$h4("3. Feeding the Trade Journal"),
    tags$p(paste0(
      "The Individual Trade Sheet (Trade Journal group) has free-text fields for trade rationale and lessons ",
      "learned. A 'relevant calendar events' lookup \u2014 pulling any economic_calendar_summary rows whose ",
      "event_date matches the trade's date and whose specific_asset matches the instrument traded \u2014 could ",
      "pre-fill a reference note on the trade sheet, so a trade taken around a major release is automatically ",
      "annotated with what was happening that day, without the student needing to remember or re-look it up."
    )),

    tags$h4("4. Linking to IG's live session"),
    tags$p(paste0(
      "IGSessionManager already exposes live price/instrument data when a session is active. A combined view ",
      "could overlay economic_calendar_summary event markers (using event_date, and event time if later added ",
      "to the schema) directly on an IG-sourced live price chart \u2014 similar to how the Step-by-Step Practice ",
      "charts already annotate political/macro events on simulated OHLC data, but using real stored events ",
      "against a real live feed instead."
    )),

    tags$h4("5. What would need to be added, if you want to build this"),
    tags$ul(
      tags$li("An event_time (or event_datetime) column, if intraday precision matters \u2014 the current schema is date-level only."),
      tags$li("A shared reactive/selector for \u201ccurrently active asset\u201d that this calendar group and a live module could both read from, the same way the sidebar's global asset selector already feeds several existing tabs."),
      tags$li("A scheduled refresh (outside the Shiny process \u2014 e.g. a cron job or Cloud Scheduler calling the same Claude+BigQuery pipeline used on the Trend Summary/Export tabs) if you want the table kept current without someone opening the app and clicking Generate.")
    )
  )
}

econ_calendar_live_link_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    # Static explainer tab — no server logic needed.
  })
}
