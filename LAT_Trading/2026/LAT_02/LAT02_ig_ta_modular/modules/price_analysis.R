# modules/price_analysis.R

price_analysis_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Price Analysis Controls", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        fluidRow(
          column(3,
                 dateRangeInput(ns("priceRange"), "Analysis Period:",
                                start = Sys.Date() - months(6),
                                end = Sys.Date(),
                                format = "yyyy-mm-dd")
          ),
          column(3,
                 checkboxGroupInput(ns("priceComponents"), "Show Components:",
                                    choices = c("Close" = "close",
                                                "High/Low" = "highlow",
                                                "Open" = "open"),
                                    selected = c("close", "highlow"))
          ),
          column(3,
                 numericInput(ns("priceMAPeriod"), "MA Periods:",
                              value = 20, min = 5, max = 200),
                 checkboxInput(ns("showBollingerBands"), "Bollinger Bands", FALSE)
          ),
          column(3,
                 verbatimTextOutput(ns("priceStats"))
          )
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Detailed Price Chart", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        withSpinner(plotlyOutput(ns("detailedPriceChart"), height = "500px")),
        tags$p(paste0(
          "Price series for the selected asset and date range. Toggle Close, High/Low, and Open in the ",
          "controls above to show or hide each component. The moving average line smooths short-term ",
          "fluctuations to reveal the underlying trend direction. Bollinger Bands, when enabled, form an ",
          "upper and lower envelope two standard deviations either side of the moving average: price touching ",
          "the upper band signals potential overbought conditions, while touching the lower band signals ",
          "potential oversold conditions."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    
    # OHLC chart full-width to prevent overlap
    fluidRow(
      box(
        title = "OHLC Candlestick Chart", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        withSpinner(plotlyOutput(ns("ohlcChart"), height = "450px")),
        tags$p(paste0(
          "Each candlestick represents one trading session. A green candle means the price closed higher ",
          "than it opened (bullish session); a red candle means the price closed lower than it opened ",
          "(bearish session). The body shows the Open-to-Close range; the thin wicks above and below extend ",
          "to the session High and Low. Wide bodies indicate strong directional conviction; long wicks ",
          "suggest price rejection at the extremes."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    
    # ── Candlestick Pattern Detection ──────────────────────────────────
    fluidRow(
      box(
        title = "Candlestick Pattern Detection", status = "primary", solidHeader = TRUE, width = 4,
        tags$p(HTML(paste0(
          "Scans the candlestick data for classic Japanese candlestick patterns within the time window you ",
          "select below. Each detected pattern is boxed directly around the candle(s) it spans, labelled with ",
          "the pattern name, and colour-coded Bullish (green), Bearish (red), or Neutral (orange)."
        )), style = "font-size:12px; color:#444; line-height:1.6;"),
        sliderInput(ns("patternWindow"), "Time Window (bar range):",
                    min = 1, max = 100, value = c(1, 100), step = 1, width = "100%"),
        uiOutput(ns("patternWindowDates")),
        tags$hr(),
        div(style = "display:flex; gap:8px; margin-bottom:10px;",
            actionButton(ns("patternSelectAll"),  "Select All",  class = "btn-default btn-sm"),
            actionButton(ns("patternSelectNone"), "Select None", class = "btn-default btn-sm")
        ),
        checkboxGroupInput(ns("patternsToDetect"), "Patterns to Detect:",
                           choices = c("Doji"                  = "doji",
                                       "Hammer"                = "hammer",
                                       "Inverted Hammer"       = "inverted_hammer",
                                       "Hanging Man"           = "hanging_man",
                                       "Shooting Star"         = "shooting_star",
                                       "Bullish Engulfing"     = "bullish_engulfing",
                                       "Bearish Engulfing"     = "bearish_engulfing",
                                       "Morning Star"          = "morning_star",
                                       "Evening Star"          = "evening_star",
                                       "Piercing Line"         = "piercing_line",
                                       "Dark Cloud Cover"      = "dark_cloud_cover",
                                       "Three White Soldiers"  = "three_white_soldiers",
                                       "Three Black Crows"     = "three_black_crows",
                                       "Bullish Harami"        = "bullish_harami",
                                       "Bearish Harami"        = "bearish_harami",
                                       "Spinning Top"          = "spinning_top",
                                       "Marubozu"              = "marubozu",
                                       "Tweezer Top"           = "tweezer_top",
                                       "Tweezer Bottom"        = "tweezer_bottom",
                                       "Abandoned Baby"        = "abandoned_baby"),
                           selected = c("doji", "hammer", "inverted_hammer", "hanging_man", "shooting_star",
                                        "bullish_engulfing", "bearish_engulfing",
                                        "morning_star", "evening_star")),
        numericInput(ns("patternTrendLookback"), "Trend Context Lookback (bars):",
                     value = 5, min = 2, max = 30, step = 1),
        actionButton(ns("detectPatterns"), "Detect Patterns", icon = icon("magnifying-glass-chart"),
                     class = "btn-primary", width = "100%")
      ),
      box(
        title = "Annotated Candlestick Chart", status = "primary", solidHeader = TRUE, width = 8,
        withSpinner(plotlyOutput(ns("patternChart"), height = "550px")),
        tags$p(paste0(
          "Each box tightly encloses the candle(s) that make up the pattern, with the pattern name labelled ",
          "above it: green = bullish signal, red = bearish signal, orange = neutral/indecision signal."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    
    fluidRow(
      box(
        title = "Detected Patterns", status = "info", solidHeader = TRUE, width = 12,
        withSpinner(DT::dataTableOutput(ns("patternResultsTable"))),
        tags$p(paste0(
          "Every match found in the selected window, most recent first. 'Signal' reflects the pattern's ",
          "classic textbook interpretation, not a guarantee of future price direction — always confirm with ",
          "other analysis before acting on any single pattern."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    # ── End Candlestick Pattern Detection ──────────────────────────────
    
    # Stats table full-width below the chart
    fluidRow(
      box(
        title = "OHLC Statistics", 
        status = "info", 
        solidHeader = TRUE, 
        width = 12,
        withSpinner(DT::dataTableOutput(ns("ohlcStats"))),
        tags$p(paste0(
          "Summary statistics computed across all sessions in the selected period. Avg Range (High minus Low) ",
          "is the typical session price swing, a direct measure of intraday volatility. Max Range identifies ",
          "the most extreme single-session swing. Bullish Days and Bearish Days express the proportion of ",
          "sessions where price closed above or below its open, indicating the directional bias of the period."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    
    fluidRow(
      box(
        title = "Returns Analysis", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("returnsTimeSeries"), height = "320px")),
        tags$p(paste0(
          "Log returns expressed as a percentage. Each bar or spike represents a single session's percentage ",
          "gain or loss relative to the prior close. Spikes far from zero identify extreme event days. The ",
          "distribution of these returns around the zero line reveals whether the asset has a positive or ",
          "negative return bias over the period."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      ),
      box(
        title = "Cumulative Returns", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        withSpinner(plotlyOutput(ns("cumulativeReturns"), height = "320px")),
        tags$p(paste0(
          "The compounded growth of a hypothetical investment in the selected asset over the period, expressed ",
          "as a cumulative percentage. A rising line indicates growth in value; a declining line indicates ",
          "loss of capital. Steep drops reveal drawdown periods. The final value on the right-hand side is the ",
          "total return over the entire date range shown."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    )
  )
}

price_analysis_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    observe({
      data_manager$state_trigger()
    })
    
    # ══════════════════════════════════════════════════════════════════════
    # CANDLESTICK PATTERN DETECTION
    # ══════════════════════════════════════════════════════════════════════
    
    # Detects the 20 classic Japanese candlestick patterns in an OHLC data.frame.
    # Thresholds are standard, commonly-cited rule-of-thumb definitions (body as a
    # % of the session range, shadow-to-body ratios, etc.) rather than a specific
    # vendor's proprietary implementation — treat matches as a starting point for
    # further analysis, not a black-box signal.
    #   df       : data.frame with Date, Open, High, Low, Close (row order = time order)
    #   patterns : character vector of pattern keys to check (see checkboxGroupInput choices)
    #   trend_lookback : bars looked back to classify the prior trend as up/down, used to
    #                    distinguish e.g. Hammer (after a downtrend) from Hanging Man (after an uptrend)
    # Returns a data.frame: BarIndex (trigger/last bar), StartBarIndex, EndBarIndex (the
    # full span of bars the pattern covers — 1/2/3 depending on pattern type, used to size
    # the highlight box), Date, Pattern, Signal, Note
    detect_candlestick_patterns <- function(df, patterns, trend_lookback = 5) {
      n <- nrow(df)
      if (n < 3 || length(patterns) == 0) return(data.frame())
      
      Open  <- df$Open;  High <- df$High;  Low <- df$Low;  Close <- df$Close
      body   <- abs(Close - Open)
      rng    <- High - Low
      rng_safe <- ifelse(rng == 0 | is.na(rng), NA, rng)
      upper_shadow <- High - pmax(Open, Close)
      lower_shadow <- pmin(Open, Close) - Low
      is_bull <- Close > Open
      is_bear <- Close < Open
      body_pct <- ifelse(is.na(rng_safe), 0, body / rng_safe)
      
      prior_trend <- function(ref) {
        look <- ref - trend_lookback
        if (look < 1 || is.na(Close[ref]) || is.na(Close[look])) return("flat")
        d <- Close[ref] - Close[look]
        if (is.na(d)) "flat" else if (d > 0) "up" else if (d < 0) "down" else "flat"
      }
      
      results <- list()
      # span = number of candles the pattern covers (1/2/3), used to size the highlight box
      add_match <- function(i, span, pattern_label, signal, note) {
        results[[length(results) + 1]] <<- data.frame(
          BarIndex = i, StartBarIndex = i - span + 1, EndBarIndex = i,
          Date = df$Date[i], Pattern = pattern_label, Signal = signal, Note = note,
          stringsAsFactors = FALSE
        )
      }
      
      for (i in seq_len(n)) {
        
        # ---- Single-candle patterns (span = 1) ----
        if (!is.na(body_pct[i])) {
          if ("doji" %in% patterns && body_pct[i] < 0.10 && !is.na(rng_safe[i])) {
            add_match(i, 1, "Doji", "Neutral", "Open approx. equals Close; market indecision")
          }
          if ("marubozu" %in% patterns && body_pct[i] >= 0.70 && body[i] > 0 &&
              !is.na(upper_shadow[i]) && !is.na(lower_shadow[i]) &&
              upper_shadow[i] <= 0.10 * body[i] && lower_shadow[i] <= 0.10 * body[i]) {
            add_match(i, 1, "Marubozu", if (is_bull[i]) "Bullish" else "Bearish",
                       "Long body, minimal shadows — strong one-sided conviction")
          }
          if ("spinning_top" %in% patterns && body_pct[i] < 0.30 && !is.na(rng_safe[i]) &&
              !is.na(upper_shadow[i]) && !is.na(lower_shadow[i]) &&
              upper_shadow[i] > 0.20 * rng_safe[i] && lower_shadow[i] > 0.20 * rng_safe[i]) {
            add_match(i, 1, "Spinning Top", "Neutral", "Small body, long wicks both sides — indecision")
          }
          
          hammer_shape <- body_pct[i] < 0.35 && body[i] > 0 && !is.na(rng_safe[i]) &&
                          !is.na(lower_shadow[i]) && !is.na(upper_shadow[i]) &&
                          lower_shadow[i] >= 2 * body[i] && upper_shadow[i] <= 0.15 * rng_safe[i]
          if (hammer_shape && i > trend_lookback) {
            tr <- prior_trend(i - 1)
            if (tr == "down" && "hammer" %in% patterns) {
              add_match(i, 1, "Hammer", "Bullish", "Small body, long lower wick after a downtrend")
            } else if (tr == "up" && "hanging_man" %in% patterns) {
              add_match(i, 1, "Hanging Man", "Bearish", "Small body, long lower wick after an uptrend")
            }
          }
          
          inv_hammer_shape <- body_pct[i] < 0.35 && body[i] > 0 && !is.na(rng_safe[i]) &&
                              !is.na(upper_shadow[i]) && !is.na(lower_shadow[i]) &&
                              upper_shadow[i] >= 2 * body[i] && lower_shadow[i] <= 0.15 * rng_safe[i]
          if (inv_hammer_shape && i > trend_lookback) {
            tr <- prior_trend(i - 1)
            if (tr == "down" && "inverted_hammer" %in% patterns) {
              add_match(i, 1, "Inverted Hammer", "Bullish", "Small body, long upper wick after a downtrend")
            } else if (tr == "up" && "shooting_star" %in% patterns) {
              add_match(i, 1, "Shooting Star", "Bearish", "Small body, long upper wick after an uptrend")
            }
          }
        }
        
        # ---- Two-candle patterns (span = 2) ----
        if (i >= 2) {
          p <- i - 1
          if (!is.na(body_pct[p]) && !is.na(body_pct[i])) {
            
            if ("bullish_engulfing" %in% patterns && is_bear[p] && is_bull[i] &&
                Open[i] <= Close[p] && Close[i] >= Open[p] && body[i] > body[p]) {
              add_match(i, 2, "Bullish Engulfing", "Bullish", "Bullish body fully engulfs the prior bearish body")
            }
            if ("bearish_engulfing" %in% patterns && is_bull[p] && is_bear[i] &&
                Open[i] >= Close[p] && Close[i] <= Open[p] && body[i] > body[p]) {
              add_match(i, 2, "Bearish Engulfing", "Bearish", "Bearish body fully engulfs the prior bullish body")
            }
            
            mid_p <- (Open[p] + Close[p]) / 2
            if ("piercing_line" %in% patterns && is_bear[p] && body_pct[p] > 0.5 &&
                is_bull[i] && Open[i] < Close[p] && Close[i] > mid_p && Close[i] < Open[p]) {
              add_match(i, 2, "Piercing Line", "Bullish", "Opens below prior close, closes above its midpoint")
            }
            if ("dark_cloud_cover" %in% patterns && is_bull[p] && body_pct[p] > 0.5 &&
                is_bear[i] && Open[i] > Close[p] && Close[i] < mid_p && Close[i] > Open[p]) {
              add_match(i, 2, "Dark Cloud Cover", "Bearish", "Opens above prior close, closes below its midpoint")
            }
            
            if ("bullish_harami" %in% patterns && is_bear[p] && body_pct[p] > 0.5 &&
                is_bull[i] && Open[i] >= Close[p] && Close[i] <= Open[p]) {
              add_match(i, 2, "Bullish Harami", "Bullish", "Small bullish body contained within the prior bearish body")
            }
            if ("bearish_harami" %in% patterns && is_bull[p] && body_pct[p] > 0.5 &&
                is_bear[i] && Open[i] <= Close[p] && Close[i] >= Open[p]) {
              add_match(i, 2, "Bearish Harami", "Bearish", "Small bearish body contained within the prior bullish body")
            }
          }
          
          if (i > trend_lookback && !is.na(High[i]) && !is.na(High[p]) && !is.na(Low[i]) && !is.na(Low[p])) {
            window_start <- max(1, i - trend_lookback)
            avg_range <- mean(rng[window_start:i], na.rm = TRUE)
            tol <- if (!is.na(avg_range) && avg_range > 0) 0.10 * avg_range else 0
            tr <- prior_trend(p)
            if ("tweezer_top" %in% patterns && tr == "up" && abs(High[i] - High[p]) <= tol) {
              add_match(i, 2, "Tweezer Top", "Bearish", "Matching highs after an uptrend")
            }
            if ("tweezer_bottom" %in% patterns && tr == "down" && abs(Low[i] - Low[p]) <= tol) {
              add_match(i, 2, "Tweezer Bottom", "Bullish", "Matching lows after a downtrend")
            }
          }
        }
        
        # ---- Three-candle patterns (span = 3) ----
        if (i >= 3) {
          p2 <- i - 2; p1 <- i - 1
          if (!is.na(body_pct[p2]) && !is.na(body_pct[p1]) && !is.na(body_pct[i])) {
            
            if ("morning_star" %in% patterns && is_bear[p2] && body_pct[p2] > 0.5 &&
                body_pct[p1] < 0.30 && max(Open[p1], Close[p1]) < Close[p2] &&
                is_bull[i] && body_pct[i] > 0.5 && Close[i] > (Open[p2] + Close[p2]) / 2) {
              add_match(i, 3, "Morning Star", "Bullish",
                         "Long bearish candle, small-bodied star, long bullish close into prior body")
            }
            if ("evening_star" %in% patterns && is_bull[p2] && body_pct[p2] > 0.5 &&
                body_pct[p1] < 0.30 && min(Open[p1], Close[p1]) > Close[p2] &&
                is_bear[i] && body_pct[i] > 0.5 && Close[i] < (Open[p2] + Close[p2]) / 2) {
              add_match(i, 3, "Evening Star", "Bearish",
                         "Long bullish candle, small-bodied star, long bearish close into prior body")
            }
            
            if ("three_white_soldiers" %in% patterns && is_bull[p2] && is_bull[p1] && is_bull[i] &&
                body_pct[p2] > 0.4 && body_pct[p1] > 0.4 && body_pct[i] > 0.4 &&
                Close[p2] < Close[p1] && Close[p1] < Close[i] &&
                Open[p1] > Open[p2] && Open[p1] < Close[p2] &&
                Open[i] > Open[p1] && Open[i] < Close[p1]) {
              add_match(i, 3, "Three White Soldiers", "Bullish", "Three consecutive long bullish candles, higher closes")
            }
            if ("three_black_crows" %in% patterns && is_bear[p2] && is_bear[p1] && is_bear[i] &&
                body_pct[p2] > 0.4 && body_pct[p1] > 0.4 && body_pct[i] > 0.4 &&
                Close[p2] > Close[p1] && Close[p1] > Close[i] &&
                Open[p1] < Open[p2] && Open[p1] > Close[p2] &&
                Open[i] < Open[p1] && Open[i] > Close[p1]) {
              add_match(i, 3, "Three Black Crows", "Bearish", "Three consecutive long bearish candles, lower closes")
            }
            
            if ("abandoned_baby" %in% patterns) {
              if (is_bear[p2] && body_pct[p2] > 0.5 && body_pct[p1] < 0.10 &&
                  !is.na(High[p1]) && !is.na(Low[p2]) && High[p1] < Low[p2] &&
                  is_bull[i] && body_pct[i] > 0.5 && !is.na(Low[i]) && !is.na(High[p1]) && Low[i] > High[p1]) {
                add_match(i, 3, "Abandoned Baby", "Bullish", "Doji gaps away from both neighbouring long candles")
              }
              if (is_bull[p2] && body_pct[p2] > 0.5 && body_pct[p1] < 0.10 &&
                  !is.na(Low[p1]) && !is.na(High[p2]) && Low[p1] > High[p2] &&
                  is_bear[i] && body_pct[i] > 0.5 && !is.na(High[i]) && !is.na(Low[p1]) && High[i] < Low[p1]) {
                add_match(i, 3, "Abandoned Baby", "Bearish", "Doji gaps away from both neighbouring long candles")
              }
            }
          }
        }
      }
      
      if (length(results) == 0) return(data.frame())
      do.call(rbind, results)
    }
    
    # Keep the time-window slider's bounds in sync with whatever data is currently loaded,
    # defaulting to the most recent 100 bars.
    observeEvent(data_manager$state_trigger(), {
      data <- data_manager$get_data()
      req(data)
      n <- nrow(data)
      updateSliderInput(session, "patternWindow", min = 1, max = n, value = c(max(1, n - 99), n))
    })
    
    output$patternWindowDates <- renderUI({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data, input$patternWindow)
      n <- nrow(data)
      rng <- input$patternWindow
      i1 <- max(1, min(rng[1], n)); i2 <- max(1, min(rng[2], n))
      d1 <- data$Date[i1]; d2 <- data$Date[i2]
      tags$p(paste0("Window: ", format(d1, "%Y-%m-%d %H:%M"), " \u2192 ", format(d2, "%Y-%m-%d %H:%M"),
                    "  (", i2 - i1 + 1, " bars)"),
             style = "font-size:11px; color:#888; margin-top:4px;")
    })
    
    all_pattern_choices <- c("doji", "hammer", "inverted_hammer", "hanging_man", "shooting_star",
                              "bullish_engulfing", "bearish_engulfing", "morning_star", "evening_star",
                              "piercing_line", "dark_cloud_cover", "three_white_soldiers", "three_black_crows",
                              "bullish_harami", "bearish_harami", "spinning_top", "marubozu",
                              "tweezer_top", "tweezer_bottom", "abandoned_baby")
    
    observeEvent(input$patternSelectAll, {
      updateCheckboxGroupInput(session, "patternsToDetect", selected = all_pattern_choices)
    })
    observeEvent(input$patternSelectNone, {
      updateCheckboxGroupInput(session, "patternsToDetect", selected = character(0))
    })
    
    # Runs the detection algorithm over the selected window when "Detect Patterns" is clicked.
    # Pulls in a small lookback buffer before the window start so patterns beginning right at
    # the edge of the window still have correct trend/multi-bar context, then discards matches
    # whose trigger bar falls outside the user's actual selected window.
    pattern_scan_results <- eventReactive(input$detectPatterns, {
      data <- data_manager$get_data()
      req(data, input$patternWindow, input$patternsToDetect)
      n <- nrow(data)
      rng <- input$patternWindow
      start_i <- max(1, min(rng[1], n)); end_i <- max(1, min(rng[2], n))
      if (start_i > end_i) { tmp <- start_i; start_i <- end_i; end_i <- tmp }
      
      lookback_bars <- if (is.null(input$patternTrendLookback)) 5 else input$patternTrendLookback
      buffer_start <- max(1, start_i - (lookback_bars + 3))
      
      window_data <- data[buffer_start:end_i, , drop = FALSE]
      
      matches <- tryCatch(
        detect_candlestick_patterns(window_data, input$patternsToDetect, trend_lookback = lookback_bars),
        error = function(e) {
          showNotification(paste("Pattern detection error:", conditionMessage(e)), type = "error", duration = 8)
          data.frame()
        }
      )
      
      if (is.null(matches) || nrow(matches) == 0) {
        showNotification("No patterns matched in this window/selection.", type = "message", duration = 4)
        return(data.frame())
      }
      
      matches$BarIndex      <- matches$BarIndex      + buffer_start - 1
      matches$StartBarIndex <- matches$StartBarIndex + buffer_start - 1
      matches$EndBarIndex   <- matches$EndBarIndex   + buffer_start - 1
      matches <- matches[matches$BarIndex >= start_i & matches$BarIndex <= end_i, , drop = FALSE]
      matches <- matches[order(matches$BarIndex, decreasing = TRUE), , drop = FALSE]
      
      showNotification(paste0("Found ", nrow(matches), " pattern match(es)."), type = "message", duration = 4)
      matches
    })
    
    # Renders the candlestick chart with each detected pattern boxed exactly around the
    # candle(s) it spans (StartBarIndex..EndBarIndex), labelled with the pattern name above
    # the box, colour-coded by Signal.
    output$patternChart <- renderPlotly({
      data <- data_manager$get_data()
      req(data, input$patternWindow)
      n <- nrow(data)
      rng <- input$patternWindow
      start_i <- max(1, min(rng[1], n)); end_i <- max(1, min(rng[2], n))
      if (start_i > end_i) { tmp <- start_i; start_i <- end_i; end_i <- tmp }
      window_data <- data[start_i:end_i, , drop = FALSE]
      
      p <- plot_ly(window_data, x = ~Date, type = "candlestick",
                   open = ~Open, high = ~High, low = ~Low, close = ~Close,
                   increasing = list(line = list(color = "#27ae60")),
                   decreasing = list(line = list(color = "#e74c3c")),
                   name = data_manager$current_asset)
      
      matches <- tryCatch(pattern_scan_results(), error = function(e) NULL)
      
      shapes_list <- list()
      annotations_list <- list()
      signal_colors <- c(Bullish = "#27ae60", Bearish = "#e74c3c", Neutral = "#e67e22")
      
      if (!is.null(matches) && is.data.frame(matches) && nrow(matches) > 0) {
        
        # Half a typical bar's width, so the box edges sit just outside the candle wicks
        # rather than cutting through them.
        date_nums <- as.numeric(window_data$Date)
        bar_gap <- if (length(date_nums) > 1) median(diff(date_nums), na.rm = TRUE) * 0.4 else 0
        
        for (r in seq_len(nrow(matches))) {
          m <- matches[r, ]
          idx_start <- m$StartBarIndex
          idx_end   <- m$EndBarIndex
          if (idx_start < 1 || idx_end > nrow(data)) next
          
          x0 <- as.numeric(data$Date[idx_start]) - bar_gap
          x1 <- as.numeric(data$Date[idx_end])   + bar_gap
          # Restore Date class/attributes for plotly (numeric round-trip loses tz/class)
          class(x0) <- class(data$Date); class(x1) <- class(data$Date)
          if (inherits(data$Date, "POSIXct")) { attr(x0, "tzone") <- attr(data$Date, "tzone"); attr(x1, "tzone") <- attr(data$Date, "tzone") }
          
          y0 <- min(data$Low[idx_start:idx_end], na.rm = TRUE)
          y1 <- max(data$High[idx_start:idx_end], na.rm = TRUE)
          pad <- (y1 - y0) * 0.18
          if (!is.finite(pad) || pad <= 0) pad <- y1 * 0.005
          y0 <- y0 - pad * 0.4
          y1 <- y1 + pad
          
          col <- signal_colors[[m$Signal]]
          if (is.null(col)) col <- "#7f8c8d"
          
          shapes_list[[length(shapes_list) + 1]] <- list(
            type = "rect", x0 = x0, x1 = x1, y0 = y0, y1 = y1,
            line = list(color = col, width = 2),
            fillcolor = col, opacity = 0.12, layer = "above"
          )
          
          annotations_list[[length(annotations_list) + 1]] <- list(
            x = x0 + (x1 - x0) / 2, y = y1,
            text = paste0("<b>", m$Pattern, "</b>"),
            showarrow = FALSE, yanchor = "bottom",
            font = list(color = col, size = 10),
            bgcolor = "rgba(255,255,255,0.9)", bordercolor = col, borderwidth = 1, borderpad = 3
          )
        }
      }
      
      p %>% layout(
        title = paste("Candlestick Pattern Detection —", data_manager$current_asset),
        xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
        yaxis = list(title = "Price"),
        shapes = shapes_list,
        annotations = annotations_list,
        plot_bgcolor = "white", paper_bgcolor = "white"
      )
    })
    
    output$patternResultsTable <- renderDT({
      matches <- pattern_scan_results()
      if (is.null(matches) || nrow(matches) == 0) {
        return(datatable(data.frame(Message = "No patterns matched in this window/selection — try widening the window or selecting more patterns."),
                          options = list(dom = 't'), rownames = FALSE, colnames = ""))
      }
      display <- data.frame(
        Date    = format(matches$Date, "%Y-%m-%d %H:%M"),
        Pattern = matches$Pattern,
        Signal  = matches$Signal,
        Span    = paste0(matches$EndBarIndex - matches$StartBarIndex + 1, " bar(s)"),
        Note    = matches$Note,
        stringsAsFactors = FALSE
      )
      datatable(display, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE) %>%
        formatStyle("Signal",
                    backgroundColor = styleEqual(
                      c("Bullish", "Bearish", "Neutral"),
                      c("#d5f5e3", "#fadbd8", "#fdebd0")
                    ))
    })
    
    # ══════════════════════════════════════════════════════════════════════
    # PRICE / OHLC / RETURNS OUTPUTS
    # ══════════════════════════════════════════════════════════════════════
    
    output$priceStats <- renderText({
      data <- data_manager$get_data()
      req(data, input$priceRange)
      data <- data %>% filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
      
      if (nrow(data) == 0) return("No data in range")
      
      paste(
        paste("Period:", input$priceRange[1], "to", input$priceRange[2]),
        paste("Records:", nrow(data)),
        paste("Current:", round(tail(data$Close, 1), 2)),
        paste("High:", round(max(data$High), 2)),
        paste("Low:", round(min(data$Low), 2)),
        sep = "\n"
      )
    })
    
    output$detailedPriceChart <- renderPlotly({
      data <- data_manager$get_data()
      req(data, input$priceRange)
      data <- data %>% filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
      
      if (nrow(data) == 0) {
        return(plot_ly() %>% layout(title = "No data in selected range"))
      }
      
      p <- plot_ly(data, x = ~Date)
      
      if ("close" %in% input$priceComponents) {
        p <- p %>% add_lines(y = ~Close, name = "Close", line = list(color = "#2c3e50", width = 2))
      }
      if ("highlow" %in% input$priceComponents) {
        p <- p %>% 
          add_lines(y = ~High, name = "High", line = list(color = "#27ae60", width = 1)) %>%
          add_lines(y = ~Low, name = "Low", line = list(color = "#e74c3c", width = 1))
      }
      if ("open" %in% input$priceComponents) {
        p <- p %>% add_lines(y = ~Open, name = "Open", line = list(color = "#95a5a6", width = 1))
      }
      
      if (nrow(data) >= input$priceMAPeriod) {
        ma <- SMA(data$Close, n = input$priceMAPeriod)
        p <- p %>% add_lines(y = ma, name = paste("MA(", input$priceMAPeriod, ")"),
                             line = list(color = "#9b59b6", width = 2, dash = "dash"))
      }
      
      if (input$showBollingerBands && nrow(data) >= 20) {
        bb <- BBands(data$Close, n = 20)
        p <- p %>%
          add_lines(y = bb[,"up"], name = "BB Upper", line = list(color = "#95a5a6", dash = "dot")) %>%
          add_lines(y = bb[,"dn"], name = "BB Lower", line = list(color = "#95a5a6", dash = "dot"))
      }
      
      p %>% layout(
        title = paste("Detailed Price Analysis -", data_manager$current_asset),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Price"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    })
    
    output$ohlcChart <- renderPlotly({
      data <- data_manager$get_data()
      req(data, input$priceRange)
      data <- data %>%
        filter(Date >= input$priceRange[1] & Date <= input$priceRange[2]) %>%
        tail(200)
      
      if (nrow(data) == 0) {
        return(plot_ly() %>% layout(title = "No data in selected range"))
      }
      
      plot_ly(data, x = ~Date, type = "candlestick",
              open = ~Open, high = ~High, low = ~Low, close = ~Close) %>%
        layout(
          title = paste("Candlestick Chart -", data_manager$current_asset),
          xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
          yaxis = list(title = "Price"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$ohlcStats <- renderDT({
      data <- data_manager$get_data()
      req(data, input$priceRange)
      data <- data %>% filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
      
      if (nrow(data) == 0) {
        return(datatable(data.frame(Message = "No data")))
      }
      
      stats <- data.frame(
        Metric = c("Avg Open", "Avg High", "Avg Low", "Avg Close", 
                   "Avg Range", "Max Range", "Bullish Days", "Bearish Days"),
        Value = c(
          round(mean(data$Open), 2),
          round(mean(data$High), 2),
          round(mean(data$Low), 2),
          round(mean(data$Close), 2),
          round(mean(data$High - data$Low), 2),
          round(max(data$High - data$Low), 2),
          paste0(round(sum(data$Close > data$Open) / nrow(data) * 100, 1), "%"),
          paste0(round(sum(data$Close < data$Open) / nrow(data) * 100, 1), "%")
        )
      )
      
      datatable(stats, options = list(dom = 't'), rownames = FALSE)
    })
    
    output$returnsTimeSeries <- renderPlotly({
      data <- data_manager$get_data()
      req(data, input$priceRange)
      data <- data %>% filter(Date >= input$priceRange[1] & Date <= input$priceRange[2], !is.na(returns))
      
      if (nrow(data) == 0) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      plot_ly(data, x = ~Date, y = ~returns * 100, type = "scatter", mode = "lines",
              line = list(color = "#8e44ad", width = 1)) %>%
        layout(
          title = "Returns Time Series",
          xaxis = list(title = "Date"),
          yaxis = list(title = "Returns (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    output$cumulativeReturns <- renderPlotly({
      data <- data_manager$get_data()
      req(data, input$priceRange)
      data <- data %>% filter(Date >= input$priceRange[1] & Date <= input$priceRange[2], !is.na(returns))
      
      if (nrow(data) == 0) {
        return(plot_ly() %>% layout(title = "No data available"))
      }
      
      data$cumulative_returns <- cumprod(1 + data$returns) - 1
      
      plot_ly(data, x = ~Date, y = ~cumulative_returns * 100, type = "scatter", mode = "lines",
              line = list(color = "#27ae60", width = 2)) %>%
        layout(
          title = "Cumulative Returns",
          xaxis = list(title = "Date"),
          yaxis = list(title = "Cumulative Return (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    })
    
    session$onSessionEnded(function() {})
  })
}
