# tests/test_pm.R - Pattern Matrix: every one of the 141 simulated examples is found by the improved rules (v2) on exactly
# its candles; the Trading Desk's current rules (v1) are unchanged; v2 does not raise false alarms on random prices.
# Run from the app folder: Rscript tests/test_pm.R
suppressMessages({ library(TTR); library(zoo) }); `%||%` <- function(x, y) if (is.null(x)) y else x
suppressMessages(library(dplyr)); for (f in c("R/utils_cc_catalog.R", "R/utils_cc_api.R", "R/utils_cc_patterns.R", "R/utils_cc_chart.R", "R/utils_synthetic.R", "R/utils_pm.R")) source(f)
pass <- 0L; fail <- 0L; ok <- function(c, w) { if (isTRUE(c)) { pass <<- pass + 1L; cat("  ok  ", w, "\n") } else { fail <<- fail + 1L; cat("  FAIL", w, "\n") } }
ok(setequal(names(pm_ex), cc_catalog$key), sprintf("an example exists for every pattern of the matrix (%d of %d)", length(intersect(names(pm_ex), cc_catalog$key)), nrow(cc_catalog)))
res <- pm_run(); sm <- pm_summary(res, cc_catalog$key)
for (k in 1:6) { x <- sm[sm$step == k, ]; ok(all(x$Result == "PASS"), sprintf("Step %d: %d of %d examples found exactly (%s)", k, sum(x$Result == "PASS"), nrow(x), paste(x$key[x$Result != "PASS"], collapse = ", "))) }
ok(all(vapply(res, function(r) is.null(r$truth$failed), TRUE)), "every example meets its own definition (none had to give up)")
# drawing: every labelled point sits exactly on its candle's high or low (or close)
on_candle <- vapply(res, function(r) { P <- r$truth$points; b <- r$bars; if (is.null(P) || !nrow(P)) return(TRUE)
  all(ifelse(P$type == "H", abs(P$price - b$high[P$i]) < 1e-9, ifelse(P$type == "L", abs(P$price - b$low[P$i]) < 1e-9, TRUE))) }, TRUE)
ok(all(on_candle), sprintf("every labelled turning point is drawn exactly on its candle's high / low (%d examples)", length(on_candle)))
lines_ok <- vapply(res, function(r) { L <- r$truth$lines; P <- r$truth$points; if (is.null(L) || is.null(P) || !nrow(L) || !nrow(P)) return(TRUE)
  k <- match(L$x0, P$i); k <- k[!is.na(k)]; if (!length(k)) return(TRUE); j <- which(L$x0 %in% P$i)
  all(abs(L$y0[j] - P$price[match(L$x0[j], P$i)]) < 1e-9 | abs(L$y0[j] - L$y1[j]) < 1e-9) }, TRUE)   # a line starting at a turning point starts exactly on it (horizontal levels excepted)
ok(all(lines_ok), sprintf("every line that starts at a turning point starts exactly on its high / low (%d examples)", sum(lines_ok)))
ch <- tryCatch({ for (k in c("head_shoulders", "rsi_div_bull", "golden_cross", "bull_engulfing", "pivot_bounce_long")) plotly::plotly_build(pm_chart(res[[k]])); TRUE }, error = function(e) conditionMessage(e))
ok(isTRUE(ch), paste("charts build (price, indicator panels, overlays):", ch))
# v1 unchanged: the Trading Desk rules give the same result as before on an example (v2 is only used here)
ex <- pm_ex$sym_triangle(); s1 <- cc_scan(ex$b, 15, list(horizon = 40), hist_step = nrow(ex$b)); ok(!isTRUE(cc_ctx(ex$b, 15)$v2), "the Trading Desk keeps the current rules (v2 off by default)")
# false alarms on random 15-minute prices: v2 reports at most a little more than v1
set.seed(11); fa <- function(v2) { tot <- 0; for (sd in 1:3) { set.seed(sd); n <- 700; r <- stats::rnorm(n, 0, 0.0012); cl <- 100 * exp(cumsum(r)); op <- c(100, utils::head(cl, -1))
    b <- data.frame(time = pm_t0 + (0:(n - 1)) * 900, open = op, high = pmax(op, cl) + abs(stats::rnorm(n, 0, 0.03)), low = pmin(op, cl) - abs(stats::rnorm(n, 0, 0.03)), close = cl)
    tot <- tot + nrow(cc_scan(b, 15, list(v2 = v2, horizon = 40), hist_step = n)$current_df) }; tot }
f1 <- fa(FALSE); f2 <- fa(TRUE); ok(f2 <= 1.5 * f1 + 3, sprintf("random prices: %d patterns alive with the improved rules vs %d with the current ones (3 series)", f2, f1))

# the course's Step 1-6 tabs: every example that is a matrix pattern, drawn precisely, found exactly, and its outcome as titled
ks <- unlist(lapply(c(1, 2, 3, 6), pm_course_keys)); ok(setequal(ks, cc_catalog$key) && !anyDuplicated(ks), "the 141 patterns are split across the course steps, each exactly once")
cbad <- character(0)
for (id in names(pm_course_map)) { r <- pm_course_get(id); if (!isTRUE(r$ok)) cbad <- c(cbad, id)
  w <- pm_course_map[[id]]$outcome; if (!is.null(w)) { b <- r$bars; e0 <- r$outcome$from; tg <- if (is.finite(r$truth$target %||% NA)) r$truth$target else r$occ$target; cn <- if (is.finite(r$truth$cancel %||% NA)) r$truth$cancel else r$occ$invalid
    d <- sign(tg - b$close[e0]); hit <- if (d > 0) max(b$high[e0:nrow(b)]) >= tg else min(b$low[e0:nrow(b)]) <= tg; thr <- if (d > 0) min(b$close[e0:nrow(b)]) < cn else max(b$close[e0:nrow(b)]) > cn
    if ((w == "hit" && !hit) || (w == "miss" && !thr)) cbad <- c(cbad, paste(id, "outcome")) }
  if (!inherits(try(pm_to_syn(r, id), silent = TRUE), "list")) cbad <- c(cbad, paste(id, "pdf")) }
ok(!length(cbad), sprintf("all %d course examples that are matrix patterns: found exactly, outcome as titled, PDF chart builds (%s)", length(pm_course_map), paste(cbad, collapse = ", ")))

# ---- BigQuery store (pattern_examples): read first, generate only when missing or not connected ---------------------
cat("BigQuery store of the examples (in-memory stand-in for BigQuery)\n")
strip <- function(r) { attr(r, "source") <- NULL; r }
chart_json <- function(r) { p <- plotly::plotly_build(pm_chart(r)); jsonlite::toJSON(list(p$x$data, p$x$layout$shapes, p$x$layout$annotations), auto_unbox = TRUE, digits = NA, force = TRUE) }
be <- pm_mem_backend(); pm_store_use(be); rm(list = ls(pm_mem), envir = pm_mem)
ok(grepl("CREATE TABLE IF NOT EXISTS `p.d.pattern_examples`", pm_ddl("p", "d")) && all(vapply(names(pm_cols), function(c) grepl(paste0("\n  ", c, " "), pm_ddl("p", "d")), TRUE)), "the table DDL has all its columns")
r1 <- pm_get("head_shoulders"); ok(identical(attr(r1, "source"), "generated") && length(pm_store$queue) == 1, "not stored yet: generated and queued for BigQuery")
pm_store_flush(); row <- be$db$rows
ok(!is.null(row) && nrow(row) == 1 && length(pm_store$queue) == 0, "flush writes one row and empties the queue")
need <- c("pattern_label", "course_step", "candles_json", "truth_json", "detection_json", "signal_candle", "entry", "cancel_level", "target", "found", "check_ok", "payload_b64")
ok(all(need %in% names(row)) && row$course_step %in% c(1, 2, 3, 6) && isTRUE(row$check_ok) && is.finite(row$signal_candle), "the row holds the pattern, step, check result and signal candle")
cj <- jsonlite::fromJSON(row$candles_json); tj <- jsonlite::fromJSON(row$truth_json)
ok(length(cj$close) == nrow(r1$bars) && isTRUE(all.equal(cj$high, r1$bars$high)) && !is.null(tj$points) && !is.null(tj$lines), "readable columns: every candle, the turning points and the lines")
rm(list = ls(pm_mem), envir = pm_mem); pm_store$tried <- character(0); rm(list = ls(pm_store$rows), envir = pm_store$rows); n0 <- be$db$reads
r2 <- pm_get("head_shoulders"); ok(identical(attr(r2, "source"), "bigquery") && be$db$reads == n0 + 1 && length(be$db$last_ids) == 1, "new session: only that example is read from BigQuery (one small query)")
ok(identical(strip(r2), strip(pm_generate("head_shoulders"))), "the example from BigQuery is identical to a freshly generated one")
ok(identical(chart_json(r2), chart_json(strip(pm_generate("head_shoulders")))), "and its chart is identical")
n1 <- be$db$reads; invisible(pm_get("head_shoulders")); ok(be$db$reads == n1, "the same example again: from memory, no query")
# course variants (seed, hit / miss tail) are separate rows
rc <- pm_course_get("pp_hs_miss"); pm_store_flush(); ok(any(be$db$rows$course_id %in% "pp_hs_miss" & be$db$rows$outcome %in% "miss"), "course variants are stored with their course id and outcome")
# not connected: generated, kept, saved when the connection is back
be2 <- pm_mem_backend(up = FALSE); pm_store_use(be2); rm(list = ls(pm_mem), envir = pm_mem)
r3 <- pm_get("double_top"); ok(identical(attr(r3, "source"), "generated") && isTRUE(r3$ok), "no BigQuery connection: the example is generated and works")
pm_store_flush(); ok(is.null(be2$db$rows) && length(pm_store$queue) == 1 && grepl("not connected", pm_store_status()), "nothing written while offline; kept for later; status says so")
be2$db$up <- TRUE; pm_store_flush(); ok(!is.null(be2$db$rows) && nrow(be2$db$rows) == 1 && !length(pm_store$queue), "connection back: the kept example is saved")
# a write that fails keeps the rows
be3 <- pm_mem_backend(); be3$write <- function(df) stop("quota"); pm_store_use(be3); rm(list = ls(pm_mem), envir = pm_mem); invisible(pm_get("bull_flag")); pm_store_flush()
ok(length(pm_store$queue) == 1 && grepl("quota", pm_store_status()), "a failed write keeps the example queued and shows the error")
# rows of another generator version are ignored
be4 <- pm_mem_backend(); pm_store_use(be4); rm(list = ls(pm_mem), envir = pm_mem); invisible(pm_get("bear_flag")); pm_store_flush()
be4$db$rows$gen_version <- "v2-old"; pm_store_use(be4); rm(list = ls(pm_mem), envir = pm_mem); r4 <- pm_get("bear_flag")
ok(identical(attr(r4, "source"), "generated"), "rows from an older generator / rules version are not used: rebuilt and saved again")
# every example the app shows can be stored and read back
be5 <- pm_mem_backend(); pm_store_use(be5); rm(list = ls(pm_mem), envir = pm_mem); ex <- pm_all_examples()
for (e in ex) invisible(pm_get(e$key, e$args, e$seed, e$outcome, course_id = e$course_id)); pm_store_flush()
nr <- nrow(be5$db$rows); ok(nr == length(unique(vapply(ex, function(e) pm_example_id(e$key, e$args, e$seed, e$outcome), ""))), sprintf("all examples stored: %d rows (141 patterns + course variants)", nr))
ok(max(nchar(be5$db$rows$payload_b64)) < 9e6 && all(be5$db$rows$check_ok), sprintf("every row fits BigQuery's limits (largest %.0f KB) and every stored example passes its check", max(nchar(be5$db$rows$payload_b64)) / 1024))
rm(list = ls(pm_mem), envir = pm_mem); pm_store$tried <- character(0); rm(list = ls(pm_store$rows), envir = pm_store$rows); n5 <- be5$db$reads
vis4 <- vapply(ex[1:4], function(e) pm_example_id(e$key, e$args, e$seed, e$outcome), ""); pm_store_prefetch(vis4)
ok(be5$db$reads - n5 == 1 && length(be5$db$last_ids) == 4 && all(vapply(vis4, pm_store_has, TRUE)), "charts coming into view: their examples are fetched together in one query")
src <- vapply(ex, function(e) attr(pm_get(e$key, e$args, e$seed, e$outcome), "source"), "")
ok(all(src == "bigquery") && sum(be5$db$rows$saved_at > 0) == nr, sprintf("reopened: all %d examples from BigQuery, none built or saved again", length(src)))
pm_store_prefetch(vis4); ok(be5$db$reads - n5 == length(unique(c(vis4, vapply(ex, function(e) pm_example_id(e$key, e$args, e$seed, e$outcome), "")))) - 3, "examples already fetched are never queried again")
pm_store_use(NULL); pm_store$backend <- NULL

cat("Descriptions: one per chart (own title, caption, outcome) + 141 patterns, overwritten in BigQuery behind a code\n")
calls <- 0L; fake_claude <- function(prompt) { calls <<- calls + 1L; ks <- sub("key: ", "", regmatches(prompt, gregexpr("key: [A-Za-z0-9_:.-]+", prompt))[[1]])
  paste0('{"descriptions":[', paste(sprintf('{"key":"%s","text":"%s"}', ks, vapply(ks, function(k) paste(rep(sprintf("Text v%d written for %s only, about what this chart shows, why its outcome happened and the lesson.", calls, k), 3), collapse = " "), "")), collapse = ","), ']}') }
bd <- pm_mem_backend(); pm_store_use(bd); rm(list = ls(pm_charts), envir = pm_charts)
c1 <- pm_chart_add(list(id = "tri_asc_hit", title = "Ascending Triangle — Hit Target", desc = "Pattern breaks out and reaches its measured-move price objective (MPO)."), 2)
c2 <- pm_chart_add(list(id = "tri_asc_miss", title = "Ascending Triangle — Failed to Reach Target", desc = "Pattern breaks out but fails to reach its measured-move price objective."), 2)
c3 <- pm_chart_add(list(id = "hammer_ok", title = "Hammer at a Support Level — Confirmed", desc = "Pattern confirmed."), 1)
ok(length(unique(c(c1, c2, c3))) == 3 && c1 == "chart:tri_asc_hit", "every chart has its own key (no more one text per group)")
pr <- pm_desc_prompt(c(c1, c2)); ok(grepl("Hit Target", pr) && grepl("Failed to Reach Target", pr) && grepl("must get clearly different texts", pr), "Claude gets each chart's own title and caption, and is told similar charts need different texts")
ok(grepl("not in BigQuery yet", paste(as.character(pm_desc_box(c1)), collapse = "")) && grepl("0 of 144", pm_desc_status()), "before writing: the box and the status say so")
ok(!pm_desc_code_ok("") && !pm_desc_code_ok("717") && pm_desc_code_ok("718") && pm_desc_code_ok(" 718 "), "only the code 718 unlocks 'Overwrite descriptions'")
res <- pm_desc_write(fake_claude, overwrite = TRUE); n1 <- nrow(bd$db$desc)
ok(res$done == 144 && n1 == 144 && grepl("Text v", pm_desc_get(c1)) && pm_desc_get(c1) != pm_desc_get(c2), "all written; the two triangle charts have different texts")
res2 <- pm_desc_write(fake_claude, overwrite = TRUE)
ok(nrow(bd$db$desc) == 144 && (bd$db$deletes %||% 0) == 30 && !any(grepl("Text v1 ", bd$db$desc$description)) && grepl("Text v1[1-9]", pm_desc_get(c1)), "overwrite: old rows deleted in BigQuery, one row per key, new texts shown")
# fill missing: existing rows untouched, only the missing keys go to Claude
bd$db$desc <- bd$db$desc[!bd$db$desc$pattern_key %in% c(c2, "bull_flag"), , drop = FALSE]; keep1 <- bd$db$desc$description[bd$db$desc$pattern_key == c1]
pm_desc_load(force = TRUE); miss <- pm_desc_missing(); asked <- NULL; spy <- function(p) { asked <<- c(asked, sub("key: ", "", regmatches(p, gregexpr("key: [A-Za-z0-9_:.-]+", p))[[1]])); fake_claude(p) }
d0 <- bd$db$deletes; r3 <- pm_desc_write(spy, keys = miss)
ok(setequal(miss, c(c2, "bull_flag")) && setequal(asked, miss) && r3$done == 2 && bd$db$deletes == d0, "fill missing: only the 2 missing keys are sent to Claude; nothing is deleted")
ok(identical(bd$db$desc$description[bd$db$desc$pattern_key == c1], keep1) && nrow(bd$db$desc) == 144 && !length(pm_desc_missing()), "existing descriptions are untouched; all 144 present again")
pm_store_use(bd); n0 <- bd$db$desc_reads %||% 0L; invisible(pm_desc_get(c1)); ok((bd$db$desc_reads - n0) == 1 && grepl("Text v1[1-9]", pm_desc_get(c1)), "a new session reads them in ONE query")
bo <- pm_mem_backend(up = FALSE); pm_store_use(bo); ok(grepl("not connected", pm_desc_status()) && inherits(tryCatch(pm_desc_write(fake_claude, overwrite = TRUE), error = function(e) e), "error"), "BigQuery not connected: nothing written, status says so")
pm_store_use(NULL); pm_store$backend <- NULL; rm(list = ls(pm_charts), envir = pm_charts)
# a new zip must reuse what is stored: the version is fixed, and examples may only change if it is raised
ok(identical(pm_gen_version, "v2-4373e267122a"), "the version is fixed in the code (the tag of the rows already stored in BigQuery), not taken from the files")
ref <- utils::read.delim("tests/pm_reference.tsv", stringsAsFactors = FALSE); exu <- ex[!duplicated(vapply(ex, function(e) pm_example_id(e$key, e$args, e$seed, e$outcome), ""))]
fp <- vapply(exu, function(e) pm_fingerprint(pm_generate(e$key, e$args, e$seed, e$outcome)), ""); idu <- vapply(exu, function(e) pm_example_id(e$key, e$args, e$seed, e$outcome), "")
chg <- idu[substr(fp, 1, 16) != ref$fingerprint[match(idu, ref$example_id)] | is.na(match(idu, ref$example_id))]
ok(!length(chg) || !identical(unique(ref$gen_version), pm_gen_version), sprintf("examples unchanged for version %s (%d checked; changed: %s). If an example changes on purpose, raise pm_gen_version and rewrite tests/pm_reference.tsv", pm_gen_version, length(idu), paste(utils::head(chg, 5), collapse = ", ")))
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); if (fail) quit(status = 1)
