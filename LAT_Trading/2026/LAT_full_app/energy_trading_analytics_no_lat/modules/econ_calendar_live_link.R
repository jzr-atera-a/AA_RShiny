# modules/econ_calendar_live_link.R
#
# "Link to Live Trading" — explainer tab. This app does not include a
# "Live Signals" tab (that lives in the full Trading Analysis F1 app,
# under Unit Assignments, which wasn't part of this app's selected tabs).
# This describes how the economic_calendar_summary data COULD connect to
# a live-trading view if one were added here later.

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
             "This app doesn't include a live-trading tab, but here's how the calendar data could connect to one if added later."),

    ua_callout("Not built in this app \u2014 this is a design note, not a working feature here. The full Trading Analysis F1 app has a working version of this under Unit Assignments \u2192 Unit 3 \u2013 Live Signals, which wasn't part of the tabs selected for this build."),

    ecl_step("1. Pre-flagging high-impact windows",
      tags$p("Query economic_calendar_summary for rows where event_date falls within the next N hours/days and event_importance = 'High'. This gives a simple list of upcoming windows where volatility is likely to spike \u2014 useful context before treating a sudden price move as a clean technical signal rather than a news reaction.")
    ),

    ecl_step("2. Asset-specific relevance",
      tags$p("Every row carries asset_class and specific_asset. A live view could compare these against whatever asset is currently selected in this app's sidebar (data_manager$current_asset) and flag matching events, so a Gold-relevant event stands out when Gold is the active chart."),
      ua_callout("Matching would need to be fuzzy \u2014 the calendar's asset names are free text written by Claude, not a fixed enum.")
    ),

    ecl_step("3. Feeding a trade journal (if one is added)",
      tags$p("A 'relevant calendar events' lookup \u2014 pulling any economic_calendar_summary rows whose event_date matches a trade's date and whose specific_asset matches the instrument traded \u2014 could pre-fill a reference note automatically. This app doesn't include a Trade Journal tab.")
    ),

    ecl_step("4. Overlaying events on a live price chart",
      tags$p("If IG session data or another live feed is added, a combined view could overlay economic_calendar_summary event markers directly on a live price chart, similar to how the Step-by-Step Practice charts (in the full app) annotate political/macro events on simulated OHLC data \u2014 but against a real live feed instead.")
    )
  )
}

econ_calendar_live_link_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    # Static explainer tab — no server logic needed.
  })
}
