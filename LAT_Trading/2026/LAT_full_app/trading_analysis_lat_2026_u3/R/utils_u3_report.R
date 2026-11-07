# R/utils_u3_report.R
# Unit 3 report support: word counts against the brief, trading-period coverage, references, labelled figures from the
# records, and the LAT Answer Sheet filled with the student's OWN text. Nothing here writes assessed content.

u3_targets <- c(task1 = 1225, task2 = 1575, task3 = 700)
u3_total_range <- c(3150, 3850)
u3_task_titles <- c(task1 = "Task 1: Trading plan (35 marks)", task2 = "Task 2: Evaluation of performance (45 marks)", task3 = "Task 3: Evaluation of the strategy (20 marks)")
u3_task_points <- list(
  task1 = c("Justification of the financial assets chosen", "Objective of the trading plan", "Trading decision process", "Trigger events", "Profit targets (and stops)", "Management of the trading process"),
  task2 = c("Performance of the chosen financial assets", "Where the trading followed the plan / strategy", "Reasons for deviations from the plan, where applicable"),
  task3 = c("Strengths of the trading strategy", "Weaknesses of the trading strategy", "Evidence from your own trades for each point"))
u3_instructions <- c("Name and LAT Student ID at the top of the report", "Answers clearly numbered to match the task numbers",
                     "References section at the end citing every source", "No long quotations", "Every diagram labelled: third-party source or your own work",
                     "Word Count at the start of each Task answer")

# Words as Word counts them: runs of characters separated by white space that contain a letter or digit.
u3_word_count <- function(txt) {
  if (is.null(txt) || !length(txt) || is.na(txt) || !nzchar(trimws(txt))) return(0L)
  w <- unlist(strsplit(trimws(txt), "[[:space:]]+")); sum(grepl("[[:alnum:]]", w))
}
u3_count_status <- function(n, target, tol = 0.1) {
  if (n == 0) return("not started")
  if (n < target * (1 - tol)) sprintf("%d below the lower limit (%d)", round(target * (1 - tol)) - n, round(target * (1 - tol)))
  else if (n > target * (1 + tol)) sprintf("%d above the upper limit (%d)", n - round(target * (1 + tol)), round(target * (1 + tol)))
  else "within +/-10% of the target"
}
# Paragraphs of a pasted draft (blank line = new paragraph; single line breaks kept inside a paragraph)
u3_paragraphs <- function(txt) {
  if (is.null(txt) || is.na(txt) || !nzchar(trimws(txt))) return(character(0))
  p <- trimws(unlist(strsplit(gsub("\r", "", txt), "\n[[:space:]]*\n"))); p[nzchar(p)]
}

# ---- trading-period coverage: one row per weekday ------------------------------------------------
u3_coverage <- function(sheets, levels, trades, evidence, start, end, gaps_fn = NULL) {
  days <- seq(as.Date(start), as.Date(end), by = "day"); days <- days[!format(days, "%u") %in% c("6", "7")]
  if (!length(days)) return(NULL)
  tday <- if (!is.null(trades) && nrow(trades)) as.Date(format(trades$entry_ts, "%Y-%m-%d", tz = "Europe/London")) else as.Date(character(0))
  top <- if (!is.null(trades) && nrow(trades)) trades[trades$status %in% c("OPEN", "CLOSED") & is.na(trades$parent_trade_id), , drop = FALSE] else NULL
  do.call(rbind, lapply(days, function(d) {
    sid <- paste0("MS_", format(d))
    sh <- if (!is.null(sheets) && nrow(sheets)) sheets[sheets$sheet_id == sid, , drop = FALSE] else NULL
    cal <- if (!is.null(evidence) && nrow(evidence)) sum(evidence$trade_id %in% sid & evidence$screen_type %in% c("calendar_o", "calendar_t") & !(evidence$status %in% "DISCARDED")) else 0L
    ms_gaps <- if (!is.null(sh) && nrow(sh)) { lv <- if (!is.null(levels)) levels[levels$sheet_id == sid, , drop = FALSE] else NULL; nrow(tr_morning_gaps(sh[1, ], lv, cal)) } else NA_integer_
    td <- if (!is.null(top)) top[as.Date(format(top$entry_ts, "%Y-%m-%d", tz = "Europe/London")) == d, , drop = FALSE] else NULL
    n_tr <- if (is.null(td)) 0L else nrow(td)
    full <- if (n_tr && !is.null(gaps_fn)) sum(vapply(seq_len(n_tr), function(i) gaps_fn(td[i, ]) == 0L, TRUE)) else NA_integer_
    dec <- if (!is.null(evidence) && nrow(evidence) && "kind" %in% names(evidence)) {
      e <- evidence[!is.na(evidence$kind) & evidence$kind %in% c("decision_snapshot", "no_trade"), , drop = FALSE]
      if (nrow(e)) { sd <- vapply(e$confirmed_json, function(j) { x <- tryCatch(jsonlite::fromJSON(j)$first_saved_uk, error = function(err) NULL); if (is.null(x)) NA_character_ else substr(x, 1, 10) }, "")
        e <- e[!is.na(sd) & sd == format(d), , drop = FALSE]
        if (nrow(e)) paste(vapply(split(e$status, e$status), function(v) sprintf("%d %s", length(v), tolower(v[1])), ""), collapse = ", ") else "-" } else "-" } else "-"
    data.frame(Date = format(d, "%d/%m/%Y"), Day = format(d, "%a"), Week = as.integer(floor(as.numeric(d - as.Date(start)) / 7) + 1), Decisions = dec,
               `Morning Sheet` = if (is.null(sh) || !nrow(sh)) "missing" else if (ms_gaps == 0) "complete" else sprintf("saved, %d gap(s)", ms_gaps),
               Trades = n_tr, `Trade Sheets complete` = if (n_tr) sprintf("%s of %d", if (is.na(full)) "?" else full, n_tr) else "-",
               check.names = FALSE, stringsAsFactors = FALSE)
  }))
}

# ---- references (Harvard style, as LAT asks for a References section) -------------------------------
u3_ref_web <- function(url, title, accessed) {
  host <- sub("^www\\.", "", sub("^https?://([^/]+).*$", "\\1", url))
  t <- if (is.na(title) || !nzchar(title)) host else title
  sprintf("%s (n.d.) %s. Available at: %s (Accessed: %s).", host, t, url, format(as.Date(accessed), "%d %B %Y"))
}
# base: which standard sources to include; web: data.frame(url, title, accessed); extra: lines typed by the student
u3_references <- function(base = c("ig", "lat", "yahoo", "claude"), web = NULL, extra = character(0), period = c("2026-10-12", "2026-11-06"), year = 2026) {
  p <- sprintf("%s to %s", format(as.Date(period[1]), "%d %B %Y"), format(as.Date(period[2]), "%d %B %Y"))
  std <- c(
    ig = sprintf("IG (%d) IG trading platform, demo spread-betting account [Online trading platform]. Available at: https://www.ig.com/uk (Accessed: %s).", year, p),
    lat = sprintf("London Academy of Trading (%d) Level 5 Diploma in Applied Financial Trading. Unit 3: Practical Applications of Financial Market Trading, Assignment Brief. London: London Academy of Trading.", year),
    yahoo = sprintf("Yahoo Finance (%d) Historical and intraday price data: Brent crude (BZ=F), WTI crude (CL=F), gold (GC=F), FX rates, Dow Jones (^DJI) and Nikkei 225 (^N225). Available at: https://finance.yahoo.com (Accessed: %s).", year, p),
    claude = sprintf("Anthropic (%d) Claude [Large language model]. Used only to transcribe values from the author's own IG platform screenshots and to retrieve published market data; no assignment text was generated. Available at: https://www.anthropic.com (Accessed: %s).", year, p))
  out <- unname(std[intersect(base, names(std))])
  if (!is.null(web) && nrow(web)) { web <- web[!is.na(web$url) & nzchar(web$url) & !duplicated(web$url), , drop = FALSE]
    out <- c(out, vapply(seq_len(nrow(web)), function(i) u3_ref_web(web$url[i], web$title[i], web$accessed[i]), "")) }
  extra <- trimws(extra[!is.na(extra)]); out <- c(out, extra[nzchar(extra)])
  out <- out[!duplicated(out)]; out[order(tolower(gsub("^[^A-Za-z]+", "", out)))]
}
# web sources saved by the Morning tab (evidence rows kind "web_sources") -> data.frame(url, title, accessed)
u3_web_sources <- function(evidence) {
  if (is.null(evidence) || !nrow(evidence)) return(NULL)
  e <- evidence[evidence$kind %in% "web_sources" & !is.na(evidence$extracted_json), , drop = FALSE]; if (!nrow(e)) return(NULL)
  d <- do.call(rbind, lapply(seq_len(nrow(e)), function(i) { s <- tryCatch(jsonlite::fromJSON(e$extracted_json[i]), error = function(err) NULL)
    if (is.null(s) || !NROW(s) || is.null(s$url)) return(NULL)
    data.frame(url = s$url, title = if (is.null(s$title)) "" else s$title, accessed = as.Date(format(e$saved_at[i], "%Y-%m-%d", tz = "Europe/London")),
               kind = if (is.null(s$kind)) "" else s$kind, stringsAsFactors = FALSE) }))
  if (is.null(d)) return(NULL); d <- d[order(d$kind != "cited", d$accessed), , drop = FALSE]; d[!duplicated(d$url), , drop = FALSE]
}

# ---- figures from the records (PNG, labelled as own work) -----------------------------------------
u3_figure_defs <- c(equity = "Equity curve of the trading account, trade by trade", realr = "Result of each trade in R (multiples of the initial risk)",
                    asset = "Net profit / loss by asset", strategy = "Net profit / loss by strategy", adherence = "Trades that followed the plan vs deviations",
                    exitcode = "How trades ended (exit codes)")
u3_figure_source <- "Source: own work, from the author's IG demo-account trades recorded in the Trading Records app."
# closed: closed trades (one row per leg); returns data.frame(key, file, title) for the figures that could be drawn
u3_make_figures <- function(closed, opening = 10000, dir = tempfile("u3fig_"), keys = names(u3_figure_defs)) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE); out <- list()
  closed <- closed[!is.na(closed$net_pnl_gbp), , drop = FALSE]; if (!nrow(closed)) return(data.frame(key = character(0), file = character(0), title = character(0)))
  closed <- closed[order(closed$exit_ts), , drop = FALSE]
  col <- "#008A82"; neg <- "#b91c1c"
  draw <- function(key, fun) { f <- file.path(dir, paste0("figure_", key, ".png")); grDevices::png(f, width = 1500, height = 820, res = 200)
    op <- graphics::par(mar = c(4.2, 4.6, 1.2, 1), cex = 0.85, las = 1); ok <- tryCatch({ fun(); TRUE }, error = function(e) FALSE); graphics::par(op); grDevices::dev.off()
    if (ok) out[[length(out) + 1]] <<- data.frame(key = key, file = f, title = u3_figure_defs[[key]], stringsAsFactors = FALSE) else unlink(f) }
  bar <- function(v, lab, ylab) { b <- graphics::barplot(v, names.arg = lab, col = ifelse(v >= 0, col, neg), border = NA, ylab = ylab, ylim = range(c(0, v)) * 1.2); graphics::abline(h = 0, col = "grey40"); graphics::text(b, v, formatC(v, format = "f", digits = 2, big.mark = ","), pos = ifelse(v >= 0, 3, 1), cex = 0.8) }
  if ("equity" %in% keys) draw("equity", function() { eq <- opening + cumsum(closed$net_pnl_gbp); x <- 0:length(eq)
    graphics::plot(x, c(opening, eq), type = "b", pch = 19, col = col, lwd = 2, xlab = "Trade number (in order of exit)", ylab = "Account equity (GBP)", xaxt = "n"); graphics::axis(1, at = x); graphics::abline(h = opening, lty = 2, col = "grey50") })
  if ("realr" %in% keys) draw("realr", function() bar(closed$real_r, seq_len(nrow(closed)), "Real R"))
  agg <- function(g) { v <- tapply(closed$net_pnl_gbp, ifelse(is.na(g) | !nzchar(g), "(none)", g), sum); v[order(names(v))] }
  if ("asset" %in% keys) draw("asset", function() { v <- agg(vapply(closed$asset, tr_asset_label, "")); bar(as.numeric(v), names(v), "Net P/L (GBP)") })
  if ("strategy" %in% keys) draw("strategy", function() { lab <- c(PIVOT_BOUNCE = "Pivot Point Bounce", HOLY_GRAIL = "Holy Grail", STRADDLE = "Straddle", OTHER = "Other")
    s <- ifelse(closed$strategy %in% names(lab), lab[closed$strategy], closed$strategy); v <- agg(s); bar(as.numeric(v), names(v), "Net P/L (GBP)") })
  if ("adherence" %in% keys && any(!is.na(closed$plan_followed))) draw("adherence", function() { v <- table(factor(ifelse(closed$plan_followed, "Plan followed", "Deviation"), levels = c("Plan followed", "Deviation")))
    b <- graphics::barplot(v, col = c(col, neg), border = NA, ylab = "Number of trades", ylim = c(0, max(v) * 1.25)); graphics::text(b, v, v, pos = 3) })
  if ("exitcode" %in% keys && any(!is.na(closed$exit_code))) draw("exitcode", function() { v <- table(ifelse(is.na(closed$exit_code), "(none)", closed$exit_code))
    b <- graphics::barplot(v, col = col, border = NA, ylab = "Number of trades", ylim = c(0, max(v) * 1.25)); graphics::text(b, v, v, pos = 3) })
  if (!length(out)) return(data.frame(key = character(0), file = character(0), title = character(0)))
  do.call(rbind, out)
}

# ---- the Answer Sheet --------------------------------------------------------------------------
# texts: list(task1 =, task2 =, task3 =) (the student's own text); figs: data.frame(task, path, caption) placed after the text
# of that task with "Figure n: caption" above each; refs: character vector; swot: list(S =, W =, O =, T =) or NULL
u3_answer_sheet_docx <- function(file, name, student_id, abe = "", date = Sys.Date(), texts = list(), figs = NULL, refs = character(0), swot = NULL) {
  path <- tr_tpl_find("Answer_Sheet_Template.docx"); if (is.na(path)) stop("Answer_Sheet_Template.docx is missing from www/templates.")
  tp <- tr_tpl_open(path); tb <- tr_tpl_tables(tp)
  st <- Filter(function(t) grepl("Student Name", xml2::xml_text(t), fixed = TRUE), tb)[[1]]
  vals <- c(name, student_id, abe, format(as.Date(date), "%d/%m/%Y"))
  for (i in 1:4) tr_tpl_set(tr_tpl_cell(st, i, 2), vals[i])
  fig_n <- 0L
  for (k in c("task1", "task2", "task3")) {
    txt <- texts[[k]]; n <- u3_word_count(txt)
    tr_tpl_fill_items(tp, tr_tpl_find_par(tp, "Word Count: [please", 1), list(list(type = "caption", value = sprintf("Word Count: %s", formatC(n, big.mark = ",")))))
    items <- lapply(u3_paragraphs(txt), function(p) list(type = "text", value = p))
    if (k == "task3" && !is.null(swot) && any(nzchar(unlist(swot)))) {
      lab <- c(S = "Strengths", W = "Weaknesses", O = "Opportunities", T = "Threats")
      for (z in names(lab)) if (!is.null(swot[[z]]) && nzchar(trimws(swot[[z]]))) items <- c(items, list(list(type = "caption", value = lab[[z]])), lapply(u3_paragraphs(swot[[z]]), function(p) list(type = "text", value = p)))
    }
    if (!is.null(figs) && nrow(figs)) { f <- figs[figs$task == k & file.exists(figs$path), , drop = FALSE]
      for (i in seq_len(nrow(f))) { fig_n <- fig_n + 1L; items <- c(items, list(list(type = "caption", value = sprintf("Figure %d: %s", fig_n, f$caption[i])), list(type = "pic", value = f$path[i]))) } }
    if (k == "task3" && length(refs)) items <- c(items, list(list(type = "text", value = " "), list(type = "caption", value = "References")), lapply(refs, function(r) list(type = "text", value = r)))
    if (!length(items)) items <- list(list(type = "text", value = " "))
    tr_tpl_fill_items(tp, tr_tpl_find_par(tp, "Write your answers here", 1), items)
  }
  tr_tpl_save(tp, file)
}
u3_answer_filename <- function(name, ext = "docx") paste0("Unit_3_Assignment_", gsub("[^A-Za-z0-9]+", "_", trimws(name)), ".", ext)
