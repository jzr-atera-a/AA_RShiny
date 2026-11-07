# *** Course checks Claude adds to its chart reading (beside the pattern identification). Each names its LAT week and topic.
cc_course_checks <- data.frame(stringsAsFactors = FALSE, matrix(ncol = 5, byrow = TRUE, c(
  "htf",    "Higher time-frame trend, Dow phase and bull / bear cycle", "Week 2, Week 4", "Time-frame Analysis, Dow Theory, market cycle", "Daily and 4-hour trend, phase, with or against",
  "r5",     "Rule of Five time-frames ****", "Week 7", "The Rule of Five", "Minor, base and major trend agree or not",
  "sr",     "Support / resistance, pivots and Fibonacci ****", "Week 1, Week 2, Week 6", "Support and Resistance, Fibonacci, Pivot Points", "Nearest levels above and below the price",
  "cand",   "Patterns by course topic: candlesticks, trend lines, chart patterns ****", "Week 1, Week 2", "Japanese Candlesticks, Trend Lines, Price Patterns", "What each pattern alive means, by topic",
  "ind",    "Indicators: MAs, MACD, RSI, stochastics, divergence, Bollinger, OBV", "Week 3", "Technical indicators and oscillators", "Momentum, volatility and volume read",
  "adx",    "ADX/DMI trend strength and Parabolic SAR stop", "Week 6", "ADX and DMI, Parabolic SAR", "Is the trend strong; where to trail",
  "prof",   "POC, value area and initial balance", "Week 5", "Volume Profile, Market Profile", "Levels as stop and target anchors",
  "filt",   "Price/time breakout filter", "Week 2", "Price/Time Filters", "Is the break real or a false break",
  "strat",  "Course strategies: Pivot, Holy Grail, Straddle", "Week 6, Weeks 7-8", "Course strategies", "Does any course set-up fire now",
  "news",   "News in the holding time", "Introduction", "Economic Calendar, US Macro Crib Sheet", "Releases and what they mean for this market",
  "rel",    "Related markets, correlation and relative value", "Week 2", "Relative Value Trading", "Brent vs WTI, dollar index, ratio z-score",
  "risk",   "Types of investment risk for this deal ****", "Week 2", "Types of Investment Risk", "Market, liquidity, gap, overnight, leverage, event, correlation",
  "plan",   "Fit with my trading plan", "Week 4, Weeks 7-8", "Structured Trading Plan, Trade Plan Template", "Set-up allowed, minimum R:R, session, plan points",
  "record", "Measured record of this set-up", "Weeks 9-12", "Backtesting workbook", "Win % and expectancy from the backtest",
  "trader", "Trader state: psychology, biases, attitude survey ****", "Week 4, Introduction", "Trading Psychology, Attitude Survey", "Mood, losses in a row, biases, survey score")))
names(cc_course_checks) <- c("id", "label", "week", "topic", "desc")
cc_course_checks$default <- cc_course_checks$id %in% c("htf", "r5", "sr", "ind", "prof", "news", "risk")

cc_course_check_ui <- function(id_checkbox, selected = cc_course_checks$id[cc_course_checks$default]) {
  lab <- lapply(seq_len(nrow(cc_course_checks)), function(i) { r <- cc_course_checks[i, ]
    htmltools::tags$span(htmltools::tags$b(r$label), htmltools::tags$br(),
      htmltools::tags$span(style = "display:inline-block; font-size:11px; background:#dbeafe; color:#1e3a8a; padding:1px 7px; border-radius:6px; margin:2px 0;", paste(r$week, "·", r$topic)),
      htmltools::tags$br(), htmltools::tags$span(style = "font-size:12px; color:#555;", r$desc)) })
  shiny::checkboxGroupInput(id_checkbox, NULL, choiceNames = lab, choiceValues = cc_course_checks$id, selected = selected, width = "100%") }

# facts: named list id -> text computed in R. Builds the prompt part Claude must answer in "course".
cc_course_prompt <- function(facts) { facts <- facts[nzchar(unlist(facts))]; if (!length(facts)) return("")
  r <- cc_course_checks[match(names(facts), cc_course_checks$id), ]
  paste0("\n\nCOURSE CHECKS (LAT course; values computed in R, use them, do not invent numbers):\n",
         paste(sprintf("- [%s] %s (%s, %s): %s", r$id, r$label, r$week, r$topic, unlist(facts)), collapse = "\n"),
         "\nFor EACH course check above, add to your JSON a \"course\" array item {\"id\":\"...\",\"verdict\":\"supports|against|neutral\",\"note\":\"one or two plain sentences on what it means for the patterns found\"}.") }

cc_course_parse <- function(txt) { j <- tryCatch({ s <- sub("^[^{]*", "", txt); s <- sub("[^}]*$", "", s); jsonlite::fromJSON(s, simplifyVector = FALSE) }, error = function(e) NULL)
  if (is.null(j) || !length(j$course)) return(data.frame(id = character(), verdict = character(), note = character()))
  x <- do.call(rbind, lapply(j$course, function(z) data.frame(id = as.character(z$id %||% ""), verdict = as.character(z$verdict %||% ""), note = as.character(z$note %||% ""), stringsAsFactors = FALSE)))
  x[x$id %in% cc_course_checks$id, , drop = FALSE] }
