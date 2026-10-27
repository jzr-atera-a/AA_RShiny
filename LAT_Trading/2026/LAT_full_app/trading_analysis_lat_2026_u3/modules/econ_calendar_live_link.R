# modules/econ_calendar_live_link.R
#
# "Link to Live Trading" — explainer tab. Points 1 and 2 below (pre-flagging
# high-impact windows, asset-specific relevance) are now REAL, working
# functionality: see the "Upcoming High-Impact Calendar Events" panel on
# Unit 3 - Live Signals (modules/unit3_live_signals.R), which queries this
# same economic_calendar_summary table live and highlights rows relevant to
# whatever asset is currently selected. Points 3 and 4 remain a design for
# later, not yet built, and are labelled as such below.

ecl_step <- function(title, ...) {
  tags$div(class = "ua-task",
    style = "background: #ffffff; border: 1px solid #e2e8f0; border-left: 5px solid #008A82; border-radius: 10px; padding: 16px 20px; margin-bottom: 18px; box-shadow: 0 1px 4px rgba(0,44,60,0.06);",
    tags$div(class = "ua-task-head",
      style = "display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; padding-bottom: 8px; border-bottom: 1px solid #e2e8f0;",
      tags$div(class = "ua-task-title", style = "font-size: 16px; font-weight: 800; color: #002C3C;", title)
    ),
    tags$div(class = "ua-task-body", style = "font-size: 13.5px; line-height: 1.75; color: #2c3e50;", ...)
  )
}

econ_calendar_live_link_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ua_intro("Economic Calendars", "Link to Live Trading", "\u2014", "\u2014",
             "How the calendar data in this group connects to Unit 3's live trading tools \u2014 built, not just proposed."),

    ecl_step("1. Pre-flagging high-impact windows \u2014 BUILT",
      tags$p("Unit 3 \u2192 Live Signals now has an \u201cUpcoming High-Impact Calendar Events\u201d panel that queries this same economic_calendar_summary table for rows where event_date falls within the next N days (adjustable, 1\u201314) and event_importance = 'High'. This gives a live list of upcoming windows where volatility is likely to spike \u2014 exactly the kind of thing to check before treating a sudden move as a clean technical signal rather than a news reaction."),
      tags$span(style = "display:inline-block; background:#eafaf1; color:#1e8449; font-size:11px; font-weight:700; padding:3px 10px; border-radius:12px;", "See it on Unit 3 \u2192 Live Signals")
    ),

    ecl_step("2. Asset-specific relevance \u2014 BUILT",
      tags$p("Every row carries asset_class and specific_asset. The Live Signals panel compares these against whatever asset is currently selected in this app's sidebar (data_manager$current_asset) using a small alias table (e.g. \u201cGC=F\u201d \u2194 \u201cGold\u201d, \u201cEURUSD=X\u201d \u2194 \u201cEUR/USD\u201d) and visually flags any matching event with a red \u201cRELEVANT TO YOUR ASSET\u201d badge \u2014 so a Gold-relevant event stands out immediately when Gold is the active chart, without hiding other high-importance events that might still matter."),
      ua_callout("Matching is fuzzy by design \u2014 the calendar's asset names are free text written by Claude, not a fixed enum, so this favours showing a plausibly-relevant event over silently hiding one that just didn't match a naming pattern exactly.")
    ),

    ecl_step("3. Feeding the Trade Journal \u2014 not yet built",
      tags$p("The Individual Trade Sheet (Trade Journal group) has free-text fields for trade rationale and lessons learned. A \u201crelevant calendar events\u201d lookup \u2014 pulling any economic_calendar_summary rows whose event_date matches the trade's date and whose specific_asset matches the instrument traded \u2014 could pre-fill a reference note on the trade sheet, so a trade taken around a major release is automatically annotated with what was happening that day. This would mean touching modules/trade_sheet.R, which hasn't been done here.")
    ),

    ecl_step("4. Overlaying events on IG's live price chart \u2014 not yet built",
      tags$p("IGSessionManager already exposes live price/instrument data when a session is active. A combined view could overlay economic_calendar_summary event markers directly on an IG-sourced live price chart, similar to how the Step-by-Step Practice charts already annotate political/macro events on simulated OHLC data \u2014 but using real stored events against a real live feed instead. Not built yet.")
    ),

    ecl_step("What's still needed for the rest",
      tags$ul(
        tags$li("An event_time (or event_datetime) column, if intraday precision matters for points 3\u20134 \u2014 the current schema is date-level only."),
        tags$li("A scheduled refresh (outside the Shiny process \u2014 e.g. a cron job or Cloud Scheduler calling the same Claude+BigQuery pipeline used on the Trend Summary/Export tabs) if the table should stay current without someone opening the app and clicking Generate.")
      )
    )
  )
}

econ_calendar_live_link_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    # Static explainer tab — no server logic needed.
  })
}
