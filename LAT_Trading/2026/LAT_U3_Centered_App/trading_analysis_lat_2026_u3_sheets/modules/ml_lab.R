# ************** H. Machine Learning: two models trained on candle history, checked against your own records --------------
ml_lab_ui <- function(id) { ns <- NS(id)
  tagList(
    tags$div(style = "background:#eef2ff; border:1px solid #c7d2fe; border-radius:10px; padding:10px 14px; margin-bottom:10px;",
      tags$div(style = "font-weight:800; font-size:16px; color:#312e81;", "H. Machine learning on the market's history"),
      tags$div(style = "font-size:12.5px; color:#334155; line-height:1.5;",
        "Your own records are still too few to train on, so the models learn from the candle history of the market and of its related markets, and your trades, Morning Sheets and trade sheets are used to check them. ",
        tags$b("Model 1: gradient boosted trees. Model 2: a hidden Markov model of the market state. Model 3: a Kalman filter of the trend. Model 4: a GARCH volatility model. Models 5 to 8 ****************: a neural network, a stacked ensemble that learns how much to trust each forecaster, a latent factor model of the related markets, and structural-break detection. "),
        "Models 1, 2, 3, 5 and 6 forecast; 4, 7 and 8 describe volatility, the common market move and whether the history still applies. Each forecast says how often a BUY or a SELL opened now would reach its target before its stop. All are tested walk-forward (trained on the past, tested on the next block, never on candles they have seen). ",
        tags$b("A model with no proven edge says so: its forecast is then not a reason to trade."))),
    cc_rec_box(1, "Data and settings", tint = "#f8fafc",
      fluidRow(column(3, textInput(ns("epic"), cc_rec_lab("Market (Capital.com epic)"), "OIL_BRENT")),
               column(5, textInput(ns("rel"), cc_rec_lab("Related markets (epics, comma separated)"), "OIL_CRUDE, NATURALGAS, EURUSD")),
               column(2, selectInput(ns("res"), cc_rec_lab("Candle size"), c("15 min" = "MINUTE_15", "30 min" = "MINUTE_30", "1 hour" = "HOUR"))),
               column(2, numericInput(ns("days"), cc_rec_lab("Days of history"), 60, min = 20, max = 200))),
      fluidRow(column(3, numericInput(ns("rrr"), cc_rec_lab("Reward:Risk of the trade"), 1.5, min = 0.5, step = 0.1)),
               column(3, numericInput(ns("stop"), cc_rec_lab("Stop distance (x ATR)"), 1.5, min = 0.5, step = 0.25)),
               column(3, numericInput(ns("hours"), cc_rec_lab("Holding time (hours)"), 10, min = 1)),
               column(3, tags$div(style = "margin-top:25px;", actionButton(ns("train"), "Train and test the models", icon = icon("brain"), class = "btn-primary", style = "color:#fff; font-weight:700; white-space:normal; width:100%;")))),
      fluidRow(column(3, numericInput(ns("slip"), cc_rec_lab("Your slippage per trade (points) *****************"), 0, min = 0, step = 0.001)),
               column(3, tags$div(style = "margin-top:22px;", checkboxInput(ns("tune"), cc_rec_lab("Tune the settings of the boosted trees and the neural network (a little slower)"), TRUE))),
               column(2, numericInput(ns("risk_min"), cc_rec_lab("Plan risk minimum %"), 1, min = 0.1, step = 0.25)), column(2, numericInput(ns("risk_max"), cc_rec_lab("Plan risk maximum %"), 2, min = 0.1, step = 0.25)),
               column(2, numericInput(ns("dd_limit"), cc_rec_lab("Halve the size when this many R below your peak"), 3, min = 0.5, step = 0.5))),
      uiOutput(ns("slip_note")), uiOutput(ns("inventory"))),
    cc_rec_box(2, "Forecast now and verdict", tint = "#f0fdf4", uiOutput(ns("now"))),
    cc_rec_box(3, "Advice per course strategy (tested cases on this market)", tint = "#fffbeb", DT::DTOutput(ns("strat")), uiOutput(ns("meta")),
      cc_rec_note("Cases are candles of the tested period where the strategy's conditions were met, counted at least one holding time apart so they do not overlap; R per trade uses the real exit (target, stop or time-out) after the spread and your slippage. 'Models agree' keeps only the cases where the four forecasting models' average chance was at or above break-even. Proven = the low end of the likely range is above break-even.")),
    cc_rec_box(4, "How good are the models? (out of sample) ****************", tint = "#f8fafc",
      fluidRow(column(3, radioButtons(ns("v_side"), cc_rec_lab("Side shown in the charts"), c("BUY", "SELL"), inline = TRUE)), column(9, uiOutput(ns("best")))),
      tabsetPanel(id = ns("v_tabs"),
        tabPanel("Verdicts", DT::DTOutput(ns("metrics")),
          cc_rec_note("AUC 0.50 = no better than chance, 1.00 = perfect. Skill = how much better than always forecasting the past average (0 or less = no better). Picked = cases where the model's chance was 5 points or more above break-even. Independent = picked cases at least one holding time apart: only these count for the likely range, and under 30 the verdict is TOO FEW CASES. R per trade uses the real exits after the spread and your slippage. The stacked ensemble is tested on fewer cases: it needs one tested block to learn from.")),
        tabPanel("Accuracy", fluidRow(column(6, plotly::plotlyOutput(ns("g_auc"), height = "320px")), column(6, plotly::plotlyOutput(ns("g_hit"), height = "320px"))),
          cc_rec_note("Left: ranking power of each model, BUY and SELL; the dotted line is chance. Right: hit rate of the picked cases with its likely range; a bar is proven only when the whole range is above the break-even line.")),
        tabPanel("ROC curves", plotly::plotlyOutput(ns("g_roc"), height = "360px"), cc_rec_note("The further a curve bows above the diagonal, the better the model separates trades that reach the target from those that are stopped.")),
        tabPanel("Results over time", fluidRow(column(7, plotly::plotlyOutput(ns("g_eq"), height = "340px")), column(5, plotly::plotlyOutput(ns("g_fold"), height = "340px"))),
          cc_rec_note("Left: running total in R if every picked case had been traded at the stated stop and target, after the spread. Cases overlap, so read the shape (steady or one lucky stretch), not the total. Right: AUC in each tested block; a model that is good in one block only is not reliable.")),
        tabPanel("Risk, exits & tuning *****************", DT::DTOutput(ns("risk_models")),
          cc_rec_note("Per model, on its independent picked cases, in R after costs. Sharpe = average result divided by its variation; Sortino counts only the losing side; both are per trade, not per year. Maximum drawdown = the largest fall from a peak of the running total."),
          fluidRow(column(6, tags$div(style = "font-weight:700; margin-top:6px;", "How trades end (triple barrier)"), DT::DTOutput(ns("exits"))), column(6, tags$div(style = "font-weight:700; margin-top:6px;", "Settings tried and chosen"), DT::DTOutput(ns("tuned")))),
          cc_rec_note("Left: of every candle of the history, the share of trades ending at the target, at the stop or by time, and the average result of the time-outs. Right: the settings were chosen on the first training window only, by the lowest log loss on its last quarter; no tested candle took part.")),
        tabPanel("Calibration & drivers", fluidRow(column(4, plotly::plotlyOutput(ns("cal"), height = "320px")), column(4, plotly::plotlyOutput(ns("imp"), height = "320px")), column(4, plotly::plotlyOutput(ns("g_stack"), height = "320px"))),
          cc_rec_note("Left: forecast against what happened. Middle: what the boosted trees used most. Right: how much the stacked ensemble trusts each forecaster (a bar below zero means it bets against that model).")))),
    cc_rec_box(5, "Market structure: common factor and structural breaks ****************", tint = "#eff6ff",
      fluidRow(column(5, uiOutput(ns("fac_txt")), plotly::plotlyOutput(ns("g_fac"), height = "260px")), column(7, uiOutput(ns("brk_txt")), plotly::plotlyOutput(ns("g_brk"), height = "260px")))),
    cc_rec_box(6, "Your own closed trades against the models", tint = "#f8fafc", DT::DTOutput(ns("mine")),
      cc_rec_note("The models' chance at the candle of your entry, from the walk-forward test only. With few trades this is a check, not a proof.")))
}

ml_lab_server <- function(id, client, store = NULL, records_store = NULL, fetch_bars = NULL, now_fn = Sys.time) {
  moduleServer(id, function(input, output, session) {
    # the related markets follow "my markets" (B. Analyse & Place) unless you typed your own list
    if (exists("cc_watch")) { wv <- reactivePoll(3000, session, function() cc_watch$v, function() cc_watch$v); auto_rel <- reactiveVal("OIL_CRUDE, NATURALGAS, EURUSD")
      observeEvent(wv(), { cur <- trimws(input$rel %||% ""); if (!identical(cur, auto_rel()) && nzchar(cur)) return()
        r <- paste(setdiff(cc_watch_get(), toupper(trimws(input$epic %||% ""))), collapse = ", "); auto_rel(r); updateTextInput(session, "rel", value = r) }, ignoreInit = TRUE) }
    if (is.null(fetch_bars)) fetch_bars <- function(epic, res, from, to) cc_fetch_bars(client, epic, res, from, to)
    run <- reactiveVal(NULL); meta <- reactiveVal(NULL)
    note <- function(m, type = "message") showNotification(m, type = type, duration = 8)
    cnt <- function(st, name) { x <- tryCatch(st$current(name), error = function(e) NULL); if (is.null(x)) 0L else nrow(x) }
    output$inventory <- renderUI({ run(); tr <- if (is.null(store)) NULL else tryCatch(store$current("trades"), error = function(e) NULL)
      closed <- if (is.null(tr)) 0L else sum(tr$status %in% "CLOSED"); m <- meta()
      tags$div(style = "font-size:12.5px; background:#fff; border:1px solid #e2e8f0; border-radius:8px; padding:6px 10px;",
        tags$b("Your records in BigQuery: "), sprintf("%d Capital.com trade(s), %d closed; %d Morning Sheet(s); %d IG / screenshot trade(s); %d saved chart scan(s); %d scenario row(s). ",
          if (is.null(tr)) 0L else nrow(tr), closed, if (is.null(records_store)) 0L else cnt(records_store, "morning_sheets"), if (is.null(records_store)) 0L else cnt(records_store, "trades"),
          if (is.null(store)) 0L else cnt(store, "scans"), if (is.null(store)) 0L else cnt(store, "scenarios")),
        tags$span(style = sprintf("font-weight:700; color:%s;", if (closed >= 100) "#166534" else "#b45309"),
          if (closed >= 100) "Enough closed trades to start training on them: ask for that build." else sprintf("%d closed trade(s) is too few to train on (about 100 are needed), so the models learn from candle history.", closed)),
        if (!is.null(m)) tags$div(sprintf("Last run: %s, %d candles from %s to %s UK, %d tested out of sample; related markets read: %s.", m$epic, m$n, m$from, m$to, m$tested, m$rel))) })
    observeEvent(input$train, withProgress(message = "Reading the candle history from Capital.com...", value = 0.02, tryCatch({
      if (!client$connected()) { note("Connect Capital.com first (API Configuration > Capital.com).", "warning"); return() }
      epic <- toupper(trimws(input$epic)); res <- input$res; mins <- cc_res_minutes[[res]]; to <- now_fn(); from <- to - max(20, min(200, input$days %||% 60)) * 86400
      b <- fetch_bars(epic, res, from, to); if (is.null(b) || nrow(b) < 800) stop(sprintf("Capital.com returned %d candles for %s: at least 800 are needed. Use more days or check the epic.", NROW(b), epic))
      eps <- setdiff(toupper(trimws(unlist(strsplit(input$rel %||% "", "[,;]")))), c("", epic)); rel <- list()
      for (e in eps) { setProgress(0.04, message = sprintf("Reading the related market %s...", e)); rb <- tryCatch(fetch_bars(e, res, from, to), error = function(x) NULL); if (!is.null(rb) && nrow(rb) >= 200) rel[[e]] <- rb }
      px <- tryCatch(cc_market_facts(client$market(epic)), error = function(e) NULL); spread <- suppressWarnings(as.numeric(px$offer - px$bid)); if (!length(spread) || !is.finite(spread)) spread <- 0
      r <- ml_run(b, rel, rrr = input$rrr %||% 1.5, stop_atr = input$stop %||% 1.5, horizon = max(4L, as.integer(round((input$hours %||% 10) * 60 / mins))), spread = spread,
                  slip = max(0, input$slip %||% 0), tune = isTRUE(input$tune), progress = function(v, m) setProgress(v, message = m))
      fm <- function(t) format(t, "%d/%m/%Y %H:%M", tz = "Europe/London")
      meta(list(epic = epic, res = res, n = r$n, tested = r$tested, from = fm(r$from), to = fm(r$to), rel = if (length(rel)) paste(names(rel), collapse = ", ") else "none", missed = setdiff(eps, names(rel)))); run(r)
      if (length(setdiff(eps, names(rel)))) note(sprintf("No candles for: %s (check the epic). The models ran without it.", paste(setdiff(eps, names(rel)), collapse = ", ")), "warning")
      if (!is.null(store)) { setProgress(0.95, message = "Saving the run to BigQuery (cc_ml_runs)..."); rid <- format(to, "ML%Y%m%d%H%M%S", tz = "UTC"); m <- r$metrics
        key <- stats::setNames(names(r$models), r$models)
        store$write("ml_runs", data.frame(run_id = paste(rid, key[m$model], m$side, sep = "-"), epic = epic, resolution = res, related = paste(names(rel), collapse = ","), candles = r$n, tested = r$tested, rrr = r$rrr,
          stop_atr = r$stop_atr, horizon = r$horizon, model = m$model, side = m$side, cases = m$cases, base_rate = m$base_rate, auc = m$auc, skill_pct = m$skill_pct, picked = m$picked, picked_hit = m$picked_hit,
          picked_r = m$picked_r, verdict = m$verdict, chance_now = vapply(seq_len(nrow(m)), function(i) r$now[[tolower(m$side[i])]][[key[[m$model[i]]]]], 0),
          strategies_json = as.character(jsonlite::toJSON(r$strategies, auto_unbox = TRUE)), stringsAsFactors = FALSE)) }
      note(sprintf("Models trained and tested on %d candles of %s.", r$n, epic))
    }, error = function(e) note(paste("Machine learning run failed:", conditionMessage(e)), "error"))))
    output$now <- renderUI({ r <- run(); if (is.null(r)) return(cc_rec_note("Press 'Train and test the models'. It reads the history, tests the models walk-forward and takes about a minute."))
      be <- 100 / (1 + r$rrr); m <- r$metrics
      card <- function(side) { v <- r$now[[tolower(side)]]; avg <- v[["both"]]; vd <- m$verdict[m$model == r$models[["both"]] & m$side == side]; edge <- vd %in% "EDGE"; weak <- grepl("WEAK", vd)
        col <- if (edge && avg >= be) "#16a34a" else if ((edge || weak) && avg >= be) "#d97706" else "#64748b"
        column(6, tags$div(style = sprintf("border:2px solid %s; border-radius:10px; background:#fff; padding:8px 12px;", col),
          tags$div(style = "font-weight:800; font-size:15px;", sprintf("%s now: %.0f%% chance of target first", side, avg)),
          tags$div(style = "font-size:12.5px;", sprintf("Boosted trees %.0f%% | hidden Markov model %.0f%% | Kalman trend %.0f%% | neural network %.0f%% | stacked ensemble %s | break-even %.0f%%%s", v[["gbm"]], v[["hmm"]], v[["kal"]], v[["nn"]], if (is.finite(v[["stk"]])) sprintf("%.0f%%", v[["stk"]]) else "-", be, if (diff(range(v[r$forecasters], na.rm = TRUE)) > 20) " | THE MODELS DISAGREE by more than 20 points" else "")),
          tags$div(style = sprintf("font-weight:700; color:%s;", col), sprintf("Tested verdict: %s. %s", vd,
            if (edge && avg >= be) "The models have a proven edge on this side and the chance now is above break-even."
            else if (edge || weak) (if (avg >= be) "Above break-even now, but the edge is not proven: treat it as a weak reason only." else "The chance now is below break-even: no reason to trade this side from the models.")
            else "The models have shown no edge on this side, so this forecast is not a reason to trade.")))) }
      g <- r$garch; tr <- r$trend; box <- function(title, ...) column(6, tags$div(style = "border:1px solid #cbd5e1; border-radius:10px; background:#fff; padding:8px 12px; margin-top:8px; font-size:12.5px;", tags$div(style = "font-weight:800; font-size:14px;", title), ...))
      own <- own_r(); dd <- if (is.null(own)) 0 else ml_risk_stats(own$r)$dd_now
      size <- function(side) { v <- r$now[[tolower(side)]]; z <- ml_size(v[["both"]], r$rrr, m$verdict[m$model == r$models[["both"]] & m$side == side], if (is.null(r$garch)) 1 else r$garch$vol_ratio, dd, input$dd_limit %||% 3, input$risk_min %||% 1, input$risk_max %||% 2)
        column(6, tags$div(style = sprintf("border:1px solid %s; border-radius:10px; background:#fff; padding:8px 12px; margin-top:8px; font-size:12.5px;", if (z$risk > 0) "#16a34a" else "#cbd5e1"),
          tags$div(style = "font-weight:800; font-size:14px;", sprintf("Size for a %s *****************: risk %s of equity", side, if (z$risk > 0) sprintf("%.2f%%", z$risk) else "0%")), z$why)) }
      tagList(fluidRow(card("BUY"), card("SELL")), fluidRow(size("BUY"), size("SELL")),
        fluidRow(
          box(sprintf("Trend (Kalman filter): %s", if (!is.finite(tr$t)) "-" else if (tr$t >= 2) "UP, clear" else if (tr$t <= -2) "DOWN, clear" else if (abs(tr$t) >= 1) paste(if (tr$t > 0) "up" else "down", "but weak") else "none"),
            sprintf("Hidden slope %+.3f per candle (%+.2f ATR), %.1f times its own uncertainty. Under 1 is noise; 2 or more is a clear trend. ", tr$slope, tr$slope / tr$atr, abs(tr$t)),
            tags$b(if (!is.finite(tr$t)) "" else if (abs(tr$t) < 1) "No trend the filter can tell from noise: a Holy Grail trade has little behind it now." else sprintf("A %s is with this trend; a %s is against it.", if (tr$t > 0) "BUY" else "SELL", if (tr$t > 0) "SELL" else "BUY"))),
          if (is.null(g)) box("Volatility (GARCH)", "Could not be fitted on this history.") else box(sprintf("Volatility (GARCH): %.0f%% of its usual level", 100 * g$vol_ratio),
            sprintf("Likely move in your holding time: about %.3f (1 standard deviation) = %.1f times your stop distance. Chance that price travels as far as the stop %.0f%%, as far as the target %.0f%%. ", g$move, g$move_vs_stop, g$p_stop, g$p_target),
            tags$b(if (g$p_target < 35) "The target is far for this holding time: expect many trades to end at neither level. Consider a longer holding time or a nearer target. " else if (g$move_vs_stop > 2.5) "Price is likely to travel well beyond the stop distance: the stop is tight for this volatility. " else "Stop and target are in proportion to the likely move. "),
            if (!is.finite(g$cor_garch)) sprintf("No volatility clustering was found in this history, so GARCH adds nothing over ATR here (tested on %d candles).", g$tested)
            else sprintf("A volatility shock halves in about %.0f candles. Tested out of sample on %d candles: GARCH ranks the size of the coming move with correlation %.2f (ATR alone %.2f)%s.", g$half_life, g$tested, g$cor_garch, g$cor_atr, if (g$cor_garch <= g$cor_atr) ": no better than ATR on this history" else ""))),
        fluidRow(column(6, plotly::plotlyOutput(session$ns("g_shap_buy"), height = "300px")), column(6, plotly::plotlyOutput(session$ns("g_shap_sell"), height = "300px"))),
        cc_rec_note("Why this forecast *****************: Shapley values of the boosted trees. Each bar is how many points that reading adds to (green) or takes from (red) the chance now, against the average candle; the bars add up exactly to the difference. The value of each reading now is in brackets. To set the size in the ticket, type the risk % above into Setup or use 'size for my plan risk'."),
        cc_rec_note(sprintf("For a trade opened at the last candle's close with a stop %.2g ATR away, a target at R:R %.2g and %d candles of holding time. Market state now (hidden Markov model): %s. Costs charged in every result: spread %.3f R + your slippage %.3f R = %.2f R per trade.",
          r$stop_atr, r$rrr, r$horizon, paste(sprintf("state %d %d%%", seq_along(r$states), r$states), collapse = ", "), r$cost_spread_r, r$cost_slip_r, r$cost_r))) })
    tbl <- function(x, ...) DT::datatable(x, rownames = FALSE, options = list(dom = "t", scrollX = TRUE, pageLength = 20), ...)
    output$strat <- DT::renderDT({ r <- run(); if (is.null(r)) return(NULL); s <- r$strategies; s$met_now <- ifelse(s$met_now, "YES", "no")
      names(s) <- c("Strategy", "Independent cases", "Target first %", "Likely at least %", "Break-even %", "R per trade", "Independent cases (models agree)", "Target first % (models agree)", "R per trade (models agree)", "Conditions met now?", "Advice")
      DT::formatStyle(tbl(s[, c(11, 1:10)]), "Advice", fontWeight = "800", color = DT::styleEqual(unique(s$Advice), ifelse(grepl("^TRADE", unique(s$Advice)), "#166534", ifelse(grepl("^HALF", unique(s$Advice)), "#b45309", ifelse(grepl("^LEAVE", unique(s$Advice)), "#b91c1c", "#475569"))))) })
    output$metrics <- DT::renderDT({ r <- run(); if (is.null(r)) return(NULL); m <- r$metrics[, c("verdict", "model", "side", "cases", "base_rate", "auc", "skill_pct", "break_even", "picked", "independent", "picked_hit", "picked_lo", "picked_r")]
      names(m) <- c("Verdict", "Model", "Side", "Cases tested", "Target first % (all)", "AUC", "Skill %", "Break-even %", "Picked", "Independent *****************", "Picked: target first %", "Picked: likely at least %", "Picked: R per trade")
      DT::formatStyle(tbl(m), "Verdict", fontWeight = "800", color = DT::styleEqual(c("EDGE", "WEAK EDGE (not proven)", "NO EDGE", "TOO FEW CASES"), c("#166534", "#b45309", "#b91c1c", "#475569"))) })
    output$cal <- plotly::renderPlotly({ r <- run(); if (is.null(r) || is.null(r$calibration)) return(NULL); c0 <- r$calibration; p <- plotly::plot_ly()
      for (s in unique(c0$side)) { d <- c0[c0$side == s, ]; p <- plotly::add_trace(p, x = d$forecast, y = d$actual, type = "scatter", mode = "lines+markers", name = s, text = sprintf("%d cases", d$n)) }
      rg <- range(c(c0$forecast, c0$actual)); p <- plotly::add_trace(p, x = rg, y = rg, type = "scatter", mode = "lines", name = "perfect", line = list(dash = "dot", color = "#94a3b8"))
      plotly::layout(p, title = list(text = "Forecast against what happened (tested period)", font = list(size = 13)), xaxis = list(title = "Models' chance %"), yaxis = list(title = "Target first %"), margin = list(t = 40)) })
    output$imp <- plotly::renderPlotly({ r <- run(); if (is.null(r)) return(NULL); v <- utils::head(r$importance$buy, 12); v2 <- r$importance$sell[names(v)]; v2[is.na(v2)] <- 0; o <- rev(seq_along(v))
      p <- plotly::plot_ly(y = factor(names(v)[o], levels = names(v)[o]), x = as.numeric(v)[o], type = "bar", orientation = "h", name = "BUY model"); p <- plotly::add_trace(p, x = as.numeric(v2)[o], name = "SELL model")
      plotly::layout(p, barmode = "group", title = list(text = "What the boosted trees used most (% of importance)", font = list(size = 13)), margin = list(t = 40, l = 110)) })
    pal <- c(gbm = "#2563eb", hmm = "#7c3aed", kal = "#0d9488", nn = "#db2777", both = "#475569", stk = "#d97706")
    lay <- function(p, title, ...) plotly::layout(p, title = list(text = title, font = list(size = 13)), margin = list(t = 40), legend = list(orientation = "h", y = -0.25), ...)
    side_k <- reactive(tolower(input$v_side %||% "BUY"))
    output$best <- renderUI({ r <- run(); if (is.null(r)) return(NULL); m <- r$metrics[r$metrics$side == toupper(side_k()), ]; rk <- match(m$verdict, c("EDGE", "WEAK EDGE (not proven)", "NO EDGE", "TOO FEW CASES")); o <- order(rk, -m$picked_r, -m$auc)[1]
      tags$div(style = "font-size:12.5px; background:#fff; border:1px solid #e2e8f0; border-radius:8px; padding:6px 10px; margin-top:4px;", tags$b(sprintf("Best on %s: %s (%s). ", toupper(side_k()), m$model[o], m$verdict[o])),
        sprintf("AUC %.2f; %d picked cases, %s%% reached the target against a break-even of %.0f%%, %s R per trade. %d of %d models show a proven edge on this side.", m$auc[o], m$picked[o], m$picked_hit[o], m$break_even[o], m$picked_r[o], sum(m$verdict == "EDGE"), nrow(m))) })
    output$g_auc <- plotly::renderPlotly({ r <- run(); if (is.null(r)) return(NULL); m <- r$metrics; p <- plotly::plot_ly()
      for (sd in c("BUY", "SELL")) { d <- m[m$side == sd, ]; p <- plotly::add_trace(p, x = d$model, y = d$auc, type = "bar", name = sd, text = sprintf("%.2f", d$auc), textposition = "outside") }
      lay(p, "Ranking power (AUC) by model", barmode = "group", yaxis = list(title = "AUC", range = c(0.3, 0.9)), xaxis = list(title = "", categoryorder = "array", categoryarray = unname(r$models)),
          shapes = list(list(type = "line", x0 = -0.5, x1 = length(r$models) - 0.5, y0 = 0.5, y1 = 0.5, line = list(dash = "dot", color = "#94a3b8")))) })
    output$g_hit <- plotly::renderPlotly({ r <- run(); if (is.null(r)) return(NULL); d <- r$metrics[r$metrics$side == toupper(side_k()) & is.finite(r$metrics$picked_hit), ]; if (!nrow(d)) return(NULL)
      hi <- d$picked_hi
      p <- plotly::plot_ly(x = d$model, y = d$picked_hit, type = "bar", marker = list(color = ifelse(d$verdict == "EDGE", "#16a34a", ifelse(grepl("WEAK", d$verdict), "#d97706", "#94a3b8"))), hovertext = sprintf("%d independent cases, %s", d$independent, d$verdict),
        error_y = list(type = "data", symmetric = FALSE, array = hi - d$picked_hit, arrayminus = d$picked_hit - d$picked_lo, color = "#334155"))
      lay(p, sprintf("%s: hit rate of the picked cases against break-even", toupper(side_k())), yaxis = list(title = "Target first %"), xaxis = list(title = "", categoryorder = "array", categoryarray = unname(r$models)), showlegend = FALSE,
          shapes = list(list(type = "line", x0 = -0.5, x1 = nrow(d) - 0.5, y0 = d$break_even[1], y1 = d$break_even[1], line = list(dash = "dash", color = "#dc2626")))) })
    output$g_roc <- plotly::renderPlotly({ r <- run(); if (is.null(r)) return(NULL); P <- r$pred[[side_k()]]; p <- plotly::plot_ly()
      for (k in names(r$models)) { z <- ml_roc(P[[k]], P$y); if (!is.null(z)) p <- plotly::add_trace(p, x = z$fpr, y = z$tpr, type = "scatter", mode = "lines", name = sprintf("%s (%.2f)", r$models[[k]], ml_auc(P[[k]], P$y)), line = list(color = pal[[k]])) }
      p <- plotly::add_trace(p, x = c(0, 1), y = c(0, 1), type = "scatter", mode = "lines", name = "chance", line = list(dash = "dot", color = "#94a3b8"))
      lay(p, sprintf("%s: ROC curve of each model (AUC in brackets)", toupper(side_k())), xaxis = list(title = "Stopped trades wrongly picked"), yaxis = list(title = "Target trades picked")) })
    output$g_eq <- plotly::renderPlotly({ r <- run(); if (is.null(r)) return(NULL); P <- r$pred[[side_k()]]; be <- 100 / (1 + r$rrr); p <- plotly::plot_ly()
      for (k in names(r$models)) { i <- which(is.finite(P[[k]]) & is.finite(P$y) & P[[k]] >= be + 5); if (length(i) < 5) next
        p <- plotly::add_trace(p, x = r$times[i], y = cumsum(P$r[i] - r$cost_r), type = "scatter", mode = "lines", name = r$models[[k]], line = list(color = pal[[k]])) }
      lay(p, sprintf("%s: running result of the picked cases (R)", toupper(side_k())), xaxis = list(title = ""), yaxis = list(title = "Cumulative R")) })
    output$g_fold <- plotly::renderPlotly({ r <- run(); if (is.null(r)) return(NULL); P <- r$pred[[side_k()]]; f <- sort(unique(stats::na.omit(r$fold))); p <- plotly::plot_ly()
      for (k in names(r$models)) p <- plotly::add_trace(p, x = paste("Block", f), y = vapply(f, function(j) { v <- ml_auc(P[[k]][r$fold %in% j], P$y[r$fold %in% j]); if (is.null(v)) NA_real_ else v }, 0), type = "scatter", mode = "lines+markers", name = r$models[[k]], line = list(color = pal[[k]]), marker = list(color = pal[[k]]), showlegend = FALSE)
      lay(p, sprintf("%s: AUC in each tested block", toupper(side_k())), yaxis = list(title = "AUC"), xaxis = list(title = ""), shapes = list(list(type = "line", x0 = -0.5, x1 = length(f) - 0.5, y0 = 0.5, y1 = 0.5, line = list(dash = "dot", color = "#94a3b8")))) })
    output$g_stack <- plotly::renderPlotly({ r <- run(); if (is.null(r)) return(NULL); w <- r$stack_weights[[side_k()]]; if (is.null(w)) return(NULL)
      lay(plotly::plot_ly(x = unname(r$models[names(w)]), y = as.numeric(w), type = "bar", marker = list(color = unname(pal[names(w)]))), sprintf("%s: trust of the stacked ensemble in each model", toupper(side_k())), xaxis = list(title = ""), yaxis = list(title = "Weight"), showlegend = FALSE) })
    info <- function(...) tags$div(style = "font-size:12.5px; background:#fff; border:1px solid #cbd5e1; border-radius:8px; padding:6px 10px; margin-bottom:6px;", ...)
    output$fac_txt <- renderUI({ r <- run(); if (is.null(r)) return(cc_rec_note("Run the models first.")); f <- r$factor; if (is.null(f)) return(info(tags$b("Latent factor model: "), "no related market with enough candles was read, so there is no common factor."))
      info(tags$b(sprintf("Latent factor model: %.0f%% of this market's moves are shared with its related markets. ", f$r2)),
        sprintf("Over the last move measured, the common factor accounts for %+.2f%% and the market's own part for %+.2f%% (%.1f standard deviations). ", f$common_now, f$own_now, f$resid_z),
        tags$b(if (abs(f$resid_z) >= 2) "The market has moved on its own, away from its related markets: such moves often fade back, so be careful chasing it." else if (f$r2 >= 50) "The market is moving with its group: check the related markets before trading against them." else "The market mostly moves on its own: the related markets say little about it.")) })
    output$g_fac <- plotly::renderPlotly({ r <- run(); if (is.null(r) || is.null(r$factor)) return(NULL); f <- r$factor; nm <- names(f$loadings); nm[nm == "own"] <- "this market"
      p <- plotly::plot_ly(x = nm, y = as.numeric(f$loadings), type = "bar", name = "Weight in the common factor", marker = list(color = "#2563eb")); p <- plotly::add_trace(p, x = nm, y = as.numeric(f$cor), name = "Correlation with this market", marker = list(color = "#94a3b8"))
      lay(p, sprintf("Common factor: %.0f%% of all the moves", f$explained[1]), barmode = "group", xaxis = list(title = "")) })
    output$brk_txt <- renderUI({ r <- run(); if (is.null(r)) return(NULL); k <- r$breaks; if (is.null(k)) return(NULL); nb <- length(k$breaks)
      info(tags$b(sprintf("Structural breaks: %d change(s) of volatility found in %d candles. ", nb, k$n)),
        if (!nb) "The history behaves as one period, so the models' training data is consistent." else sprintf("The last one was %d candles ago, at %s UK; volatility since is %.0f%% of the period before. ", k$since, format(r$times[max(k$breaks)], "%d/%m %H:%M", tz = "Europe/London"), 100 * k$vol_now_vs_before),
        tags$b(if (nb && k$since < 300) "The market changed recently: the models learned mostly from the earlier behaviour, so trust their forecasts less until more candles build up." else if (nb) "Enough candles have built up since the last change for the models to have learned the present behaviour." else "")) })
    output$g_brk <- plotly::renderPlotly({ r <- run(); if (is.null(r) || is.null(r$breaks)) return(NULL); k <- r$breaks; sg <- k$segments; p <- plotly::plot_ly()
      for (i in seq_len(nrow(sg))) { j <- sg$from[i]:sg$to[i]; p <- plotly::add_trace(p, x = r$times[j], y = r$close[j], type = "scatter", mode = "lines", name = sprintf("Period %d: volatility %.3f%% per candle", i, sg$vol[i])) }
      lay(p, "Price, one colour per volatility period", xaxis = list(title = ""), yaxis = list(title = "")) })
    own_r <- reactive({ if (is.null(store)) NULL else ml_own_r(tryCatch(store$current("trades"), error = function(e) NULL)) })
    slip_done <- reactiveVal(FALSE)
    observe({ if (slip_done() || is.null(store)) return(); tr <- tryCatch(store$current("trades"), error = function(e) NULL); if (is.null(tr) || !nrow(tr)) return(); z <- ml_own_slippage(tr); slip_done(TRUE); if (z$n > 0) updateNumericInput(session, "slip", value = round(z$points, 4)) })
    output$slip_note <- renderUI({ z <- if (is.null(store)) list(points = 0, n = 0L) else ml_own_slippage(tryCatch(store$current("trades"), error = function(e) NULL))
      cc_rec_note(if (z$n > 0) sprintf("Your own average slippage in the Trade Log is %.4f points per trade (entry plus exit, from %d recorded fills). It is filled in above and charged in every result with the spread; change it if you wish.", z$points, z$n)
                  else "No slippage is recorded in your Trade Log yet, so only the spread is charged. Type a figure to test how sensitive the results are.") })
    shap_plot <- function(side) plotly::renderPlotly({ r <- run(); if (is.null(r)) return(NULL); h <- r$shap[[side]]; if (is.null(h)) return(NULL); v <- utils::head(h$values, 10); o <- rev(seq_along(v)); lab <- sprintf("%s (%s)", names(v), formatC(h$row[names(v)], digits = 3, format = "g"))
      plotly::layout(plotly::plot_ly(y = factor(lab[o], levels = lab[o]), x = as.numeric(v)[o], type = "bar", orientation = "h", marker = list(color = ifelse(v[o] >= 0, "#16a34a", "#dc2626"))),
          title = list(text = sprintf("%s: why the boosted trees say %.0f%% (average candle %.0f%%)", toupper(side), h$pred, h$base), font = list(size = 13)), xaxis = list(title = "Points added to or taken from the chance"), margin = list(t = 40, l = 150), showlegend = FALSE) })
    output$g_shap_buy <- shap_plot("buy"); output$g_shap_sell <- shap_plot("sell")
    output$meta <- renderUI({ r <- run(); if (is.null(r)) return(NULL); me <- r$meta; if (is.null(me) || is.null(me$table)) return(info(tags$b("Meta-labelling *****************: "), "none of your set-ups fired in this history, so there is nothing to filter."))
      t <- me$table; col <- if (me$verdict == "THE FILTER HELPS") "#166534" else if (me$verdict == "NO HELP SHOWN") "#b91c1c" else "#475569"
      tags$div(style = "background:#fff; border:1px solid #cbd5e1; border-radius:8px; padding:8px 12px; margin-top:8px; font-size:12.5px;",
        tags$div(style = "font-weight:800; font-size:14px;", "Meta-labelling *****************: which signals of your own set-ups to take"),
        "A second model is trained only on the candles where a Holy Grail or Pivot Point Bounce signal fired, and learns which of them reached the target. Tested on later signals only. ",
        tags$span(style = sprintf("font-weight:800; color:%s;", col), sprintf("Verdict: %s. ", me$verdict)),
        if (me$verdict == "THE FILTER HELPS") "Taking only the signals it approves gave a better result per trade than taking them all." else if (me$verdict == "NO HELP SHOWN") "Filtering your signals with it did not beat taking them all: do not use it to skip signals." else "Too few signals in this history to judge: use more days of history.",
        tags$table(class = "table table-condensed", style = "margin:6px 0 2px; font-size:12.5px;", tags$tr(lapply(c("", "Signals", "Independent", "Target first %", "R per trade", "Total R (independent)"), tags$th)),
          lapply(seq_len(nrow(t)), function(i) tags$tr(tags$td(t$group[i]), tags$td(t$signals[i]), tags$td(t$independent[i]), tags$td(t$hit[i]), tags$td(t$r_per_trade[i]), tags$td(t$total_r[i])))),
        if (!is.null(me$now)) tags$div(style = "font-weight:700;", paste(sprintf("A signal is on NOW (%s): the meta-model gives it %.0f%% against a break-even of %.0f%%.", me$now$strategy, me$now$chance, 100 / (1 + r$rrr)), collapse = " ")) else "No signal of your set-ups is on at the last candle.") })
    output$risk_models <- DT::renderDT({ r <- run(); if (is.null(r)) return(NULL); m <- r$metrics[r$metrics$side == toupper(side_k()), c("model", "independent", "picked_hit", "picked_r", "sharpe", "sortino", "max_dd", "verdict")]
      names(m) <- c("Model", "Independent trades", "Target first %", "R per trade", "Sharpe (per trade)", "Sortino (per trade)", "Maximum drawdown (R)", "Verdict"); tbl(m) })
    output$exits <- DT::renderDT({ r <- run(); if (is.null(r)) return(NULL); e <- r$exits; names(e) <- c("Side", "Cases", "Target %", "Stop %", "Time-out %", "Average R of time-outs", "Average R of all, after costs"); tbl(e) })
    output$tuned <- DT::renderDT({ r <- run(); if (is.null(r)) return(NULL); t <- r$tuned[[side_k()]]; if (is.null(t)) return(tbl(data.frame(Note = "Tuning was off or the first training window was too short: standard settings were used.")))
      x <- t$table; x$chosen <- ifelse(x$chosen, "CHOSEN", ""); names(x) <- c("Model", "Setting", "Log loss (lower is better)", "Chosen"); tbl(x) })
    # ---- risk review of your own trades (shown in tab E) *****************
    output$own_tiles <- renderUI({ d <- own_r(); if (is.null(d)) return(cc_rec_note("No closed Capital.com trade in your records yet."))
      k <- ml_risk_stats(d$r); f <- function(v, dg = 2) if (is.null(v) || !is.finite(v)) "-" else formatC(v, digits = dg, format = "f")
      tile <- function(lbl, val, sub = NULL, col = "#0f172a") column(2, tags$div(style = "background:#fff; border:1px solid #e2e8f0; border-radius:10px; padding:8px 10px; margin-bottom:8px; min-height:86px;", tags$div(style = "font-size:11.5px; color:#64748b;", lbl), tags$div(style = sprintf("font-size:20px; font-weight:800; color:%s;", col), val), tags$div(style = "font-size:11px; color:#64748b;", sub)))
      be <- 100 / (1 + mean(d$planned_rr, na.rm = TRUE)); sgn <- function(v) if (is.finite(v) && v > 0) "#166534" else "#b91c1c"
      tagList(fluidRow(
        tile("Closed trades", k$trades, sprintf("%d week(s)", length(unique(d$week)))),
        tile("Win rate", sprintf("%.0f%%", k$win_pct), sprintf("break-even %.0f%% at your average planned R:R", be), if (k$win_pct > be) "#166534" else "#b91c1c"),
        tile("Average planned R:R", f(mean(d$planned_rr, na.rm = TRUE)), sprintf("achieved: win %s R, loss %s R", f(k$avg_win), f(k$avg_loss))),
        tile("Result", sprintf("%+.2f R", k$total), sprintf("%+.2f R per trade; profit factor %s", k$expectancy, f(k$profit_factor)), sgn(k$total)),
        tile("Sharpe / Sortino", sprintf("%s / %s", f(k$sharpe), f(k$sortino)), "per trade, not per year", sgn(k$sharpe %||% NA_real_)),
        tile("Maximum drawdown", sprintf("%.2f R", k$max_dd), sprintf("now %.2f R below the peak; worst losing run %d", k$dd_now, k$worst_streak), if (k$max_dd > 3) "#b91c1c" else "#0f172a")),
        cc_rec_note(if (k$trades < 30) sprintf("With %d trades these figures describe what happened; they are not yet evidence of skill (about 30 trades are needed before Sharpe and Sortino mean much). The share of trades that followed your rules is in the Statistics section above.", k$trades)
                    else "Sharpe = average R per trade divided by its variation; Sortino counts only losing variation. The share of trades that followed your rules is in the Statistics section above.")) })
    output$own_eq <- plotly::renderPlotly({ d <- own_r(); if (is.null(d)) return(NULL); k <- ml_risk_stats(d$r)
      p <- plotly::plot_ly(x = seq_along(k$equity), y = k$equity, type = "scatter", mode = "lines+markers", name = "Running total (R)", line = list(color = "#0d9488"), text = sprintf("%s %s %s: %+.2f R", format(d$when, "%d/%m", tz = "Europe/London"), d$epic, d$side, d$r))
      p <- plotly::add_trace(p, y = -k$drawdown, type = "scatter", mode = "lines", name = "Drawdown (R)", fill = "tozeroy", line = list(color = "#dc2626"), fillcolor = "rgba(220,38,38,0.15)", text = NULL)
      lay(p, "Your closed trades: running total and drawdown", xaxis = list(title = "Trade number", dtick = 1), yaxis = list(title = "R")) })
    output$own_weeks <- DT::renderDT({ d <- own_r(); if (is.null(d)) return(NULL)
      w <- do.call(rbind, lapply(split(d, d$week), function(x) { k <- ml_risk_stats(x$r); data.frame(Week = x$week[1], Trades = k$trades, `Win %` = round(k$win_pct), `Average planned R:R` = round(mean(x$planned_rr, na.rm = TRUE), 2), `Total R` = round(k$total, 2),
        `R per trade` = round(k$expectancy, 2), Sharpe = round(k$sharpe %||% NA_real_, 2), Sortino = round(k$sortino %||% NA_real_, 2), `Max drawdown (R)` = round(k$max_dd, 2), check.names = FALSE, stringsAsFactors = FALSE) })); tbl(w) })
    output$mine <- DT::renderDT({ r <- run(); m <- meta(); if (is.null(r) || is.null(store)) return(NULL); x <- ml_trades_check(tryCatch(store$current("trades"), error = function(e) NULL), r, m$epic)
      if (is.null(x)) return(tbl(data.frame(Note = sprintf("No closed Capital.com trade on %s in your records.", m$epic))))
      names(x) <- c("Entry (UK)", "Side", "Models' chance at entry", "Result (R)", "Outcome"); tbl(x) })
    invisible(list(run = run))
  })
}

# ***************** weekly risk review of your own trades, shown in E. Statistics & Backtest (same module id as tab H)
ml_risk_ui <- function(id) { ns <- NS(id)
  tagList(cc_rec_note("Your plan's weekly review: win rate with the average risk to reward, Sharpe and Sortino, and maximum drawdown, all in R (multiples of the planned risk) from your closed Capital.com trades."),
    uiOutput(ns("own_tiles")), fluidRow(column(6, plotly::plotlyOutput(ns("own_eq"), height = "300px")), column(6, tags$div(style = "font-weight:700;", "Week by week"), DT::DTOutput(ns("own_weeks"))))) }
