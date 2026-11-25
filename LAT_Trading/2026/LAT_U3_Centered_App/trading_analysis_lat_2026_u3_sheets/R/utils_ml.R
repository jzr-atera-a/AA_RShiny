# ************** Machine learning on candle history (tab H) -------------------------------------------------------------
# Two models, both forecasting "target reached before stop" for a BUY and for a SELL opened at a candle's close:
#   1. gradient boosted trees (small rpart trees on the logistic loss, Newton leaf values, row sub-sampling);
#   2. a hidden Markov model of the market state (Gaussian, fitted by Baum-Welch); its forecast is the target-first rate
#      of each state weighted by the state probabilities known AT that candle (forward filter only: no look-ahead).
# Tested walk-forward: train on the past, leave a gap of the holding time, forecast the next block, repeat.
# Base R + rpart + TTR only (no new package).

ml_labels <- function(h, l, c, atr, stop_atr = 1.5, rrr = 1.5, horizon = 40L) {
  n <- length(c); buy <- sell <- buy_r <- sell_r <- rep(NA_real_, n); buy_exit <- sell_exit <- rep(NA_character_, n)
  for (i in seq_len(n - 1L)) { a <- atr[i]; if (!is.finite(a) || a <= 0) next
    e <- min(n, i + horizon); j <- (i + 1L):e; sd <- stop_atr * a; td <- rrr * sd; full <- (i + horizon) <= n
    # triple barrier *****************: target, stop or time. Both in one candle: the stop counts first. Time-out: closed at the last close
    one <- function(stop_hit, tgt_hit, dir) { s <- which(stop_hit)[1]; t <- which(tgt_hit)[1]
      if (!is.na(t) && (is.na(s) || t < s)) list(1, rrr, "target") else if (!is.na(s)) list(0, -1, "stop") else if (full) list(0, max(-1, min(rrr, dir * (c[e] - c[i]) / sd)), "time") else list(NA_real_, NA_real_, NA_character_) }
    o <- one(l[j] <= c[i] - sd, h[j] >= c[i] + td, 1); buy[i] <- o[[1]]; buy_r[i] <- o[[2]]; buy_exit[i] <- o[[3]]
    o <- one(h[j] >= c[i] + sd, l[j] <= c[i] - td, -1); sell[i] <- o[[1]]; sell_r[i] <- o[[2]]; sell_exit[i] <- o[[3]] }
  list(buy = buy, sell = sell, buy_r = buy_r, sell_r = sell_r, buy_exit = buy_exit, sell_exit = sell_exit) }

# features known at each candle's close; rel = named list of candle tables of related markets
ml_features <- function(b, rel = list(), tz = "Europe/London") {
  n <- nrow(b); ind <- cc_indicators(b); cl <- b$close; a <- ind$atr; a[!is.finite(a) | a <= 0] <- NA
  lagd <- function(v, k) if (n > k) c(rep(NA_real_, k), v[(k + 1):n] - v[1:(n - k)]) else rep(NA_real_, n)
  x <- data.frame(rsi = ind$rsi, adx = ind$adx, di = ind$di_p - ind$di_n, macd_h = ind$macd_hist / a, bb_pos = (cl - ind$bb_mid) / (ind$bb_up - ind$bb_dn),
    bb_w = ind$bb_width, e20 = (cl - ind$ema20) / a, e50 = (cl - ind$ema50) / a, e200 = (cl - ind$ema200) / a, stoch = ind$stoch_k, vol = 100 * a / cl,
    r1 = lagd(cl, 1) / a, r4 = lagd(cl, 4) / a, r16 = lagd(cl, 16) / a, range = (b$high - b$low) / a, body = (cl - b$open) / a,
    hour = as.numeric(format(b$time, "%H", tz = tz)), wday = as.numeric(format(b$time, "%u", tz = tz)))
  day <- as.Date(format(b$time, "%Y-%m-%d", tz = tz)); ud <- unique(day); dh <- tapply(b$high, day, max); dl <- tapply(b$low, day, min); dc <- tapply(cl, day, function(v) v[length(v)])
  pd <- match(day, ud) - 1L; pd[pd < 1] <- NA; H <- as.numeric(dh)[pd]; L <- as.numeric(dl)[pd]; C <- as.numeric(dc)[pd]; pp <- (H + L + C) / 3   # the day before's pivots
  x$pv_pp <- (cl - pp) / a; x$pv_r1 <- (cl - (2 * pp - L)) / a; x$pv_s1 <- (cl - (2 * pp - H)) / a
  for (nm in names(rel)) { rb <- rel[[nm]]; if (is.null(rb) || nrow(rb) < 30) next; rc <- rb$close[match(as.numeric(b$time), as.numeric(rb$time))]; k <- gsub("[^A-Za-z0-9]", "", nm)
    x[[paste0("rel_", k, "_r4")]] <- 100 * lagd(rc, 4) / rc; x[[paste0("rel_", k, "_r16")]] <- 100 * lagd(rc, 16) / rc }
  x[] <- lapply(x, function(v) { v[!is.finite(v)] <- NA; v }); attr(x, "atr") <- a; x }

# --- model 1: gradient boosted trees --------------------------------------------------------------------------------
ml_gbm_fit <- function(x, y, ntree = 60L, depth = 3L, shrink = 0.1, sub = 0.6, seed = 1L, minbucket = NULL) {
  set.seed(seed); p0 <- min(max(mean(y), 0.02), 0.98); f0 <- stats::qlogis(p0); f <- rep(f0, length(y)); d <- x; trees <- vector("list", ntree); imp <- numeric(0)
  ctl <- rpart::rpart.control(maxdepth = depth, cp = 0, minbucket = minbucket %||% max(15L, floor(sub * nrow(d) / 80)), xval = 0, maxsurrogate = 2, maxcompete = 0)
  for (m in seq_len(ntree)) { p <- stats::plogis(f); d$.g <- y - p; s <- sample.int(nrow(d), floor(sub * nrow(d)))
    t <- rpart::rpart(.g ~ ., data = d[s, , drop = FALSE], method = "anova", control = ctl, y = FALSE)
    v <- tapply(d$.g[s], t$where, sum) / pmax(tapply((p * (1 - p))[s], t$where, sum), 1e-6); t$frame$yval[as.integer(names(v))] <- pmax(-4, pmin(4, v))
    f <- f + shrink * as.numeric(stats::predict(t, d)); vi <- t$variable.importance; if (length(vi)) imp <- tapply(c(imp, vi), c(names(imp), names(vi)), sum)
    t$where <- NULL; trees[[m]] <- t }
  list(f0 = f0, shrink = shrink, trees = trees, importance = sort(100 * imp / sum(imp), decreasing = TRUE)) }
ml_gbm_predict <- function(m, x) { x$.g <- 0; f <- rep(m$f0, nrow(x)); for (t in m$trees) f <- f + m$shrink * as.numeric(stats::predict(t, x)); 100 * stats::plogis(f) }

# --- model 2: hidden Markov model of the market state -----------------------------------------------------------------
ml_hmm_obs <- function(x) cbind(x$r4, log(pmax(x$vol, 1e-6)), x$adx / 25)
ml_hmm_emit <- function(m, o) { z <- sweep(sweep(o, 2, m$center), 2, m$scale, "/"); z[!is.finite(z)] <- 0
  B <- sapply(seq_len(m$k), function(k) exp(rowSums(stats::dnorm(z, rep(m$mu[k, ], each = nrow(z)), rep(m$sd[k, ], each = nrow(z)), log = TRUE)))); pmax(B, 1e-300) }
ml_hmm_filter <- function(m, o) { B <- ml_hmm_emit(m, o); n <- nrow(B); g <- matrix(0, n, m$k); a <- m$pi * B[1, ]; g[1, ] <- a / sum(a)
  if (n > 1) for (t in 2:n) { a <- as.numeric(g[t - 1, ] %*% m$A) * B[t, ]; g[t, ] <- a / sum(a) }; g }
ml_hmm_fit <- function(o, k = 3L, iter = 25L) {
  m <- list(k = k, center = colMeans(o, na.rm = TRUE), scale = pmax(apply(o, 2, stats::sd, na.rm = TRUE), 1e-6)); z <- sweep(sweep(o, 2, m$center), 2, m$scale, "/"); z[!is.finite(z)] <- 0
  n <- nrow(z); grp <- cut(rank(z[, 2], ties.method = "first"), k, labels = FALSE)                     # start: low / middle / high volatility
  m$mu <- t(sapply(seq_len(k), function(j) colMeans(z[grp == j, , drop = FALSE]))); m$sd <- matrix(1, k, ncol(z)); m$A <- matrix(0.05 / (k - 1), k, k); diag(m$A) <- 0.95; m$pi <- rep(1 / k, k)
  for (it in seq_len(iter)) { B <- ml_hmm_emit(m, o); al <- matrix(0, n, k); cs <- numeric(n); a <- m$pi * B[1, ]; cs[1] <- sum(a); al[1, ] <- a / cs[1]
    for (t in 2:n) { a <- as.numeric(al[t - 1, ] %*% m$A) * B[t, ]; cs[t] <- sum(a); al[t, ] <- a / cs[t] }
    be <- matrix(1, n, k); for (t in (n - 1):1) be[t, ] <- as.numeric(m$A %*% (B[t + 1, ] * be[t + 1, ])) / cs[t + 1]
    g <- al * be; g <- g / rowSums(g); xi <- matrix(0, k, k)
    for (i in seq_len(k)) for (j in seq_len(k)) xi[i, j] <- sum(al[-n, i] * m$A[i, j] * B[-1, j] * be[-1, j] / cs[-1])
    m$A <- xi / rowSums(xi); m$pi <- g[1, ]; w <- colSums(g)
    m$mu <- t(sapply(seq_len(k), function(j) colSums(g[, j] * z) / w[j])); m$sd <- t(sapply(seq_len(k), function(j) pmax(sqrt(colSums(g[, j] * sweep(z, 2, m$mu[j, ])^2) / w[j]), 0.05))) }
  m$loglik <- sum(log(cs)); m }
ml_hmm_rates <- function(g, y) { ok <- is.finite(y); 100 * colSums(g[ok, , drop = FALSE] * y[ok]) / pmax(colSums(g[ok, , drop = FALSE]), 1e-9) }

# --- model 3: Kalman filter (local linear trend): the hidden slope of price with its uncertainty, noise filtered out ------
# causal: the value at a candle uses candles up to it only; the three variances are fitted on the training candles
ml_kalman <- function(y, par = NULL, upto = length(y), fit_n = 1500L) {
  filt <- function(p, yy, ret = FALSE) { r <- exp(p[1]); q1 <- exp(p[2]); q2 <- exp(p[3]); m <- length(yy); l <- yy[1]; s <- 0; p11 <- r * 10; p12 <- 0; p22 <- r; ll <- 0; sl <- se <- if (ret) numeric(m) else NULL
    for (t in seq_len(m)) { l <- l + s; a11 <- p11 + 2 * p12 + p22 + q1; a12 <- p12 + p22; a22 <- p22 + q2; e <- yy[t] - l; S <- a11 + r; k1 <- a11 / S; k2 <- a12 / S
      l <- l + k1 * e; s <- s + k2 * e; p11 <- a11 - k1 * a11; p12 <- a12 - k1 * a12; p22 <- a22 - k2 * a12; ll <- ll - 0.5 * (log(S) + e * e / S); if (ret) { sl[t] <- s; se[t] <- sqrt(max(p22, 1e-12)) } }
    if (ret) list(slope = sl, se = se) else -ll }
  if (is.null(par)) { tr <- utils::tail(y[seq_len(upto)], fit_n); v <- max(stats::var(diff(tr)), 1e-12)
    par <- tryCatch(stats::optim(log(c(v, v * 0.1, v * 0.001)), filt, yy = tr, method = "Nelder-Mead", control = list(maxit = 150))$par, error = function(e) log(c(v, v * 0.1, v * 0.001))) }
  f <- filt(par, y, TRUE); list(par = par, slope = f$slope, t = f$slope / f$se) }
# forecast from the trend strength: the target-first rate of each fifth of the training candles' trend strength
ml_bin_pred <- function(z, y, tr, te) { br <- unique(stats::quantile(z[tr], 1:4 / 5, na.rm = TRUE)); bt <- findInterval(z[tr], br); rate <- tapply(y[tr], factor(bt, levels = 0:length(br)), mean); rate[is.na(rate)] <- mean(y[tr])
  100 * as.numeric(rate[findInterval(z[te], br) + 1]) }

# --- model 4: GARCH(1,1) volatility: how far price is likely to travel in the holding time -----------------------------
ml_garch_filter <- function(r, w, a, b) { n <- length(r); s2 <- numeric(n); s2[1] <- w / (1 - a - b); for (t in 2:n) s2[t] <- w + a * r[t - 1]^2 + b * s2[t - 1]; s2 }
ml_garch_fit <- function(r) { r[!is.finite(r)] <- 0; v <- max(stats::var(r), 1e-14); tr <- function(p) { a <- stats::plogis(p[1]) * 0.3; b <- stats::plogis(p[2]) * (0.999 - a); c(v * (1 - a - b), a, b) }
  nll <- function(p) { q <- tr(p); s2 <- ml_garch_filter(r, q[1], q[2], q[3]); 0.5 * sum(log(s2) + r^2 / s2) }
  q <- tr(tryCatch(stats::optim(c(stats::qlogis(1 / 3), stats::qlogis(0.9)), nll, method = "Nelder-Mead", control = list(maxit = 120))$par, error = function(e) c(stats::qlogis(1 / 3), stats::qlogis(0.9))))
  list(w = q[1], a = q[2], b = q[3], uncond = q[1] / (1 - q[2] - q[3]), persistence = q[2] + q[3]) }
# standard deviation of the log move over the next h candles, for every candle (uses returns up to that candle only)
ml_garch_sd <- function(g, r, h) { r[!is.finite(r)] <- 0; s2 <- ml_garch_filter(r, g$w, g$a, g$b); nx <- g$w + g$a * r^2 + g$b * s2; p <- g$persistence
  sqrt(pmax(h * g$uncond + (nx - g$uncond) * (1 - p^h) / (1 - p), 1e-16)) }
ml_garch_view <- function(b, atr, stop_atr, rrr, horizon) { n <- nrow(b); cl <- b$close; r <- c(0, diff(log(cl))); cut <- floor(0.6 * n); g0 <- ml_garch_fit(r[2:cut])
  te <- (cut + 1):(n - horizon); real <- abs(log(cl[te + horizon] / cl[te])); f0 <- ml_garch_sd(g0, r, horizon)[te]; cor_s <- function(x) suppressWarnings(stats::cor(x, real, method = "spearman", use = "complete.obs"))
  g <- ml_garch_fit(r[-1]); sdl <- ml_garch_sd(g, r, horizon)[n]; move <- cl[n] * sdl; sd <- stop_atr * atr[n]; td <- rrr * sd; reach <- function(d) 100 * 2 * (1 - stats::pnorm(d / move))
  list(move = move, stop = sd, target = td, move_vs_stop = move / sd, p_stop = reach(sd), p_target = reach(td), vol_ratio = sqrt((g$w + g$a * r[n]^2 + g$b * ml_garch_filter(r, g$w, g$a, g$b)[n]) / g$uncond),
       persistence = g$persistence, half_life = if (g$persistence < 1) log(0.5) / log(g$persistence) else NA_real_, cor_garch = cor_s(f0), cor_atr = cor_s(atr[te]), tested = length(te)) }

# --- model 5: neural network (one hidden layer, weight decay; package nnet, which ships with R) -------------------------
ml_nn_fit <- function(x, y, size = 4L, decay = 1, seed = 1L) { med <- vapply(x, stats::median, 0, na.rm = TRUE); sc <- pmax(vapply(x, stats::sd, 0, na.rm = TRUE), 1e-9); med[!is.finite(med)] <- 0; sc[!is.finite(sc)] <- 1
  set.seed(seed); z <- ml_nn_scale(x, med, sc); list(med = med, sc = sc, net = nnet::nnet(z, y, size = size, decay = decay, maxit = 200, entropy = TRUE, trace = FALSE, MaxNWts = 5000)) }
ml_nn_scale <- function(x, med, sc) { z <- sweep(sweep(as.matrix(x[names(med)]), 2, med), 2, sc, "/"); z[!is.finite(z)] <- 0; z[z > 5] <- 5; z[z < -5] <- -5; z }
ml_nn_predict <- function(m, x) 100 * as.numeric(stats::predict(m$net, ml_nn_scale(x, m$med, m$sc)))

# --- model 6: stacked ensemble: a logistic model learns, from earlier tested blocks, how much to trust each forecaster ---
ml_stack_fit <- function(P, y, rows, keys) { d <- as.data.frame(lapply(P[keys], function(v) v[rows] / 100)); d$y <- y[rows]; d <- d[stats::complete.cases(d), , drop = FALSE]
  if (nrow(d) < 150 || length(unique(d$y)) < 2) return(NULL); tryCatch(suppressWarnings(stats::glm(y ~ ., data = d, family = stats::binomial())), error = function(e) NULL) }
ml_stack_predict <- function(m, P, rows, keys) { d <- as.data.frame(lapply(P[keys], function(v) v[rows] / 100)); if (is.null(m)) return(rep(NA_real_, length(rows))); 100 * as.numeric(stats::predict(m, d, type = "response")) }
ml_stack_weights <- function(m, P, rows, keys) { if (is.null(m)) return(NULL); b <- stats::coef(m)[keys]; b[is.na(b)] <- 0; w <- b * vapply(keys, function(k) stats::sd(P[[k]][rows] / 100, na.rm = TRUE), 0); w[!is.finite(w)] <- 0; w }

# --- model 7: latent factor model (principal components of the market and its related markets) -------------------------
ml_factor <- function(b, rel, k = 4L, recent = 16L) { if (!length(rel)) return(NULL); cl <- data.frame(own = b$close); for (nm in names(rel)) cl[[nm]] <- rel[[nm]]$close[match(as.numeric(b$time), as.numeric(rel[[nm]]$time))]
  n <- nrow(cl); r <- as.data.frame(lapply(cl, function(v) c(rep(NA_real_, k), 100 * (v[(k + 1):n] / v[1:(n - k)] - 1)))); ok <- stats::complete.cases(r); if (sum(ok) < 300) return(NULL)
  pc <- stats::prcomp(r[ok, ], center = TRUE, scale. = TRUE); ve <- 100 * pc$sdev^2 / sum(pc$sdev^2); ld <- pc$rotation[, 1]; if (ld[["own"]] < 0) { ld <- -ld; pc$x[, 1] <- -pc$x[, 1] }
  f1 <- pc$x[, 1]; own <- r$own[ok]; fit <- stats::lm(own ~ f1); res <- stats::residuals(fit); last <- utils::tail(which(ok), 1)
  rr <- function(v) { m <- 100 * (v[n] / v[max(1, n - recent)] - 1); if (is.finite(m)) m else NA_real_ }; mv <- vapply(cl, rr, 0)
  list(explained = ve, loadings = ld, r2 = 100 * summary(fit)$r.squared, resid_z = utils::tail(res, 1) / stats::sd(res), common_now = stats::coef(fit)[[2]] * utils::tail(f1, 1), own_now = utils::tail(res, 1),
       moves = mv, cor = stats::cor(r[ok, ])[1, ], n = sum(ok), recent = recent, k = k, fresh = last == n) }

# --- model 8: structural breaks in volatility (Inclan-Tiao cumulative sum of squares, split again inside each part) -----
ml_breaks <- function(r, min_seg = 150L, depth = 3L, crit = 1.358) { r[!is.finite(r)] <- 0
  one <- function(lo, hi, d) { m <- hi - lo + 1; if (d < 1 || m < 2 * min_seg) return(integer(0)); x <- r[lo:hi]^2; cs <- cumsum(x); if (cs[m] <= 0) return(integer(0)); D <- cs / cs[m] - seq_len(m) / m
    idx <- min_seg:(m - min_seg); k <- idx[which.max(abs(D[idx]))]; if (sqrt(m / 2) * abs(D[k]) < crit) return(integer(0)); c(one(lo, lo + k - 1, d - 1), lo + k - 1, one(lo + k, hi, d - 1)) }
  sort(one(1L, length(r), depth)) }
ml_breaks_view <- function(b) { r <- c(0, diff(log(b$close))); br <- ml_breaks(r); n <- nrow(b); e <- c(0, br, n); seg <- data.frame(from = e[-length(e)] + 1, to = e[-1])
  seg$vol <- vapply(seq_len(nrow(seg)), function(i) 100 * stats::sd(r[seg$from[i]:seg$to[i]]), 0); list(breaks = br, segments = seg, since = n - (if (length(br)) max(br) else 0), n = n,
    vol_now_vs_before = if (nrow(seg) > 1) seg$vol[nrow(seg)] / seg$vol[nrow(seg) - 1] else NA_real_) }

ml_roc <- function(p, y) { ok <- is.finite(p) & is.finite(y); p <- p[ok]; y <- y[ok]; if (!sum(y == 1) || !sum(y == 0)) return(NULL); th <- sort(unique(c(-Inf, stats::quantile(p, 0:40 / 40), Inf)), decreasing = TRUE)
  data.frame(fpr = vapply(th, function(t) mean(p[y == 0] >= t), 0), tpr = vapply(th, function(t) mean(p[y == 1] >= t), 0)) }

# --- measures ---------------------------------------------------------------------------------------------------------
ml_auc <- function(p, y) { ok <- is.finite(p) & is.finite(y); p <- p[ok]; y <- y[ok]; n1 <- sum(y == 1); n0 <- sum(y == 0); if (!n1 || !n0) return(NA_real_); (sum(rank(p)[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
# independent cases *****************: picked cases at least one holding time apart, so their outcomes do not overlap
ml_thin <- function(idx, gap) { if (!length(idx)) return(idx); keep <- logical(length(idx)); last <- -Inf; for (k in seq_along(idx)) if (idx[k] - last >= gap) { keep[k] <- TRUE; last <- idx[k] }; idx[keep] }
ml_risk_stats <- function(r) { r <- r[is.finite(r)]; n <- length(r); if (!n) return(NULL); eq <- cumsum(r); dd <- cummax(pmax(eq, 0)) - eq; w <- r[r > 0]; l <- r[r <= 0]; dn <- sqrt(mean(pmin(r, 0)^2))
  runs <- rle(r <= 0); list(trades = n, win_pct = 100 * mean(r > 0), avg_win = if (length(w)) mean(w) else NA_real_, avg_loss = if (length(l)) mean(l) else NA_real_, expectancy = mean(r), total = sum(r),
    profit_factor = if (length(l) && sum(l) < 0) sum(w) / -sum(l) else NA_real_, sharpe = if (n > 1 && stats::sd(r) > 0) mean(r) / stats::sd(r) else NA_real_, sortino = if (dn > 0) mean(r) / dn else NA_real_,
    max_dd = max(dd), dd_now = dd[n], worst_streak = if (any(runs$values)) max(runs$lengths[runs$values]) else 0L, equity = eq, drawdown = dd) }
ml_measure <- function(p, y, base, rrr, cost_r = 0, margin = 5, r = NULL, horizon = 1L) { ok <- is.finite(p) & is.finite(y); pos <- which(ok); p <- p[ok]; y <- y[ok]; base <- base[ok]; be <- 100 / (1 + rrr)
  rr <- if (is.null(r)) y * (1 + rrr) - 1 else r[ok]; sel <- p >= be + margin; ns <- sum(sel); ind <- match(ml_thin(pos[sel], horizon), pos); ni <- length(ind)
  hit <- if (ns) 100 * mean(y[sel]) else NA_real_; w <- if (ni) cc_wilson(hit, ni) else list(lo = NA_real_, hi = NA_real_)
  pr <- if (ns) mean(rr[sel]) - cost_r else NA_real_; skill <- 100 * (1 - mean((p / 100 - y)^2) / mean((base / 100 - y)^2)); rs <- if (ni) ml_risk_stats(rr[ind] - cost_r) else NULL
  data.frame(cases = length(y), base_rate = round(100 * mean(y), 1), auc = round(ml_auc(p, y), 3), skill_pct = round(skill, 1), break_even = round(be, 1), picked = ns, independent = ni,
    picked_hit = round(hit, 1), picked_lo = round(w$lo, 1), picked_hi = round(w$hi, 1), picked_r = round(pr, 2), sharpe = round(rs$sharpe %||% NA_real_, 2), sortino = round(rs$sortino %||% NA_real_, 2), max_dd = round(rs$max_dd %||% NA_real_, 1),
    verdict = if (ni < 30) "TOO FEW CASES" else if (is.finite(w$lo) && w$lo > be && pr > 0) "EDGE" else if (hit > be && pr > 0 && is.finite(skill) && skill > 0) "WEAK EDGE (not proven)" else "NO EDGE", stringsAsFactors = FALSE) }

# tuning *****************: settings are chosen on the FIRST training window only (its last quarter as validation, a gap of the
# holding time between), so no tested candle takes part
ml_tune <- function(x, y, rows, horizon) { rows <- rows[is.finite(y[rows])]; cut <- rows[floor(0.75 * length(rows))]; a <- rows[rows <= cut - horizon]; v <- rows[rows > cut]
  if (length(a) < 300 || length(v) < 80 || length(unique(y[v])) < 2) return(NULL); ll <- function(p) { q <- pmin(pmax(p / 100, 0.01), 0.99); -mean(y[v] * log(q) + (1 - y[v]) * log(1 - q)) }
  G <- list(list(depth = 2L, shrink = 0.1, ntree = 40L), list(depth = 3L, shrink = 0.1, ntree = 60L), list(depth = 3L, shrink = 0.05, ntree = 100L), list(depth = 4L, shrink = 0.1, ntree = 40L))
  N <- list(list(size = 3L, decay = 2), list(size = 4L, decay = 1), list(size = 6L, decay = 0.5))
  gl <- vapply(G, function(g) ll(ml_gbm_predict(ml_gbm_fit(x[a, , drop = FALSE], y[a], ntree = g$ntree, depth = g$depth, shrink = g$shrink), x[v, , drop = FALSE])), 0)
  nl <- vapply(N, function(g) tryCatch(ll(ml_nn_predict(ml_nn_fit(x[a, , drop = FALSE], y[a], size = g$size, decay = g$decay), x[v, , drop = FALSE])), error = function(e) Inf), 0)
  list(gbm = G[[which.min(gl)]], nn = N[[which.min(nl)]], table = rbind(
    data.frame(model = "Gradient boosted trees", setting = vapply(G, function(g) sprintf("depth %d, step %.2f, %d trees", g$depth, g$shrink, g$ntree), ""), log_loss = round(gl, 4), chosen = seq_along(G) == which.min(gl)),
    data.frame(model = "Neural network", setting = vapply(N, function(g) sprintf("%d hidden units, decay %.1f", g$size, g$decay), ""), log_loss = round(nl, 4), chosen = seq_along(N) == which.min(nl)))) }

# Shapley values by sampling *****************: how many points each feature adds to or takes from THIS forecast of the boosted
# trees, against the average candle (features are switched one at a time from a random past candle to the present one)
ml_shap <- function(m, bg, row, nperm = 40L, seed = 1L) { set.seed(seed); f <- names(row); k <- length(f); z <- bg[sample.int(nrow(bg), nperm, replace = TRUE), f, drop = FALSE]
  big <- z[rep(seq_len(nperm), each = k + 1L), , drop = FALSE]; ord <- lapply(seq_len(nperm), function(i) sample.int(k))
  for (i in seq_len(nperm)) for (s in seq_len(k)) { rr <- ((i - 1L) * (k + 1L) + s + 1L):(i * (k + 1L)); big[rr, ord[[i]][s]] <- row[[ord[[i]][s]]] }
  p <- ml_gbm_predict(m, big); phi <- numeric(k); for (i in seq_len(nperm)) { q <- p[((i - 1L) * (k + 1L) + 1L):(i * (k + 1L))]; phi[ord[[i]]] <- phi[ord[[i]]] + diff(q) }
  phi <- stats::setNames(phi / nperm, f); list(values = phi[order(-abs(phi))], base = mean(p[seq(1L, by = k + 1L, length.out = nperm)]), pred = ml_gbm_predict(m, row), row = unlist(row)) }

# meta-labelling *****************: a second model trained ONLY on the candles where one of your course set-ups fired; it learns
# which of those signals to take. Tested walk-forward on the same blocks.
ml_meta <- function(x, lab, flags, cuts, warm, horizon, rrr, cost_r) { n <- nrow(x); be <- 100 / (1 + rrr)
  sg <- do.call(rbind, lapply(names(flags), function(nm) { f <- flags[[nm]]; i <- which(f$on %in% TRUE); if (!length(i)) return(NULL); data.frame(i = i, buy = as.numeric(f$side == "buy"), hg = as.numeric(grepl("Holy Grail", nm)), y = lab[[f$side]][i], r = lab[[paste0(f$side, "_r")]][i], strategy = nm, stringsAsFactors = FALSE) }))
  empty <- list(signals = 0L, verdict = "TOO FEW SIGNALS", table = NULL, now = NULL); if (is.null(sg)) return(empty); sg <- sg[order(sg$i), , drop = FALSE]
  X <- cbind(x[sg$i, , drop = FALSE], side_buy = sg$buy, holy_grail = sg$hg); rownames(X) <- NULL; p <- rep(NA_real_, nrow(sg)); fit <- function(tr) ml_gbm_fit(X[tr, , drop = FALSE], sg$y[tr], ntree = 40L, depth = 2L, minbucket = 8L)
  for (k in seq_len(length(cuts) - 1)) { te <- which(sg$i >= cuts[k] & sg$i < cuts[k + 1]); tr <- which(sg$i >= warm & sg$i < cuts[k] - horizon & is.finite(sg$y)); if (!length(te) || length(tr) < 40 || length(unique(sg$y[tr])) < 2) next
    p[te] <- ml_gbm_predict(fit(tr), X[te, , drop = FALSE]) }
  ok <- is.finite(p) & is.finite(sg$y); row <- function(lbl, w) { ind <- match(ml_thin(sg$i[w], horizon), sg$i); data.frame(group = lbl, signals = sum(w), independent = length(ind), hit = if (sum(w)) round(100 * mean(sg$y[w]), 1) else NA_real_,
    r_per_trade = if (sum(w)) round(mean(sg$r[w]) - cost_r, 2) else NA_real_, total_r = if (sum(w)) round(sum(sg$r[ind]) - cost_r * length(ind), 1) else NA_real_, stringsAsFactors = FALSE) }
  tb <- rbind(row("Every signal of your set-ups", ok), row("Signals the meta-model would TAKE (chance at or above break-even)", ok & p >= be), row("Signals the meta-model would SKIP", ok & p < be))
  verdict <- if (tb$independent[1] < 30 || tb$independent[2] < 15) "TOO FEW SIGNALS" else if (tb$r_per_trade[2] > max(0, tb$r_per_trade[1]) && tb$r_per_trade[2] > tb$r_per_trade[3]) "THE FILTER HELPS" else "NO HELP SHOWN"
  now <- NULL; on <- which(sg$i == n); tr <- which(is.finite(sg$y) & sg$i >= warm)
  if (length(on) && length(tr) >= 40 && length(unique(sg$y[tr])) > 1) now <- data.frame(strategy = sg$strategy[on], chance = round(ml_gbm_predict(fit(tr), X[on, , drop = FALSE])), stringsAsFactors = FALSE)
  list(signals = sum(ok), verdict = verdict, table = tb, now = now, all_signals = nrow(sg)) }

# size from the forecast *****************: a quarter of the Kelly fraction, cut when volatility is above usual and halved in a
# drawdown, never above the plan's maximum. Without a proven edge the models give no size.
ml_size <- function(chance, rrr, verdict, vol_ratio = 1, dd_now = 0, dd_limit = 3, risk_min = 1, risk_max = 2) { be <- 100 / (1 + rrr); why <- character(0)
  if (!(verdict %in% "EDGE")) return(list(risk = 0, why = sprintf("No proven edge on this side (%s): the models give no size. If your own set-up triggers under your plan, use the plan minimum of %.1f%%.", verdict, risk_min)))
  if (!is.finite(chance) || chance <= be) return(list(risk = 0, why = sprintf("The chance now (%.0f%%) is not above break-even (%.0f%%): no trade from the models.", chance, be)))
  k <- (chance / 100 * (1 + rrr) - 1) / rrr; f <- 25 * k; why <- c(why, sprintf("Kelly fraction %.1f%% of equity, a quarter of it = %.2f%%", 100 * k, f))
  if (is.finite(vol_ratio) && vol_ratio > 1) { f <- f / vol_ratio; why <- c(why, sprintf("volatility is %.0f%% of usual: cut to %.2f%%", 100 * vol_ratio, f)) }
  if (is.finite(dd_now) && dd_now >= dd_limit) { f <- f / 2; why <- c(why, sprintf("you are %.1f R below your peak (limit %.1f R): halved to %.2f%%", dd_now, dd_limit, f)) }
  if (f > risk_max) { f <- risk_max; why <- c(why, sprintf("capped at your plan maximum %.1f%%", risk_max)) }
  if (f < risk_min) why <- c(why, sprintf("below your plan minimum %.1f%%: the edge is thin, so the smallest size or no trade", risk_min))
  list(risk = round(f, 2), why = paste(why, collapse = "; ")) }
# your own closed trades as R, oldest first; planned R:R; week
ml_own_r <- function(trades, tz = "Europe/London") { if (is.null(trades) || !NROW(trades)) return(NULL); t <- trades[trades$status %in% "CLOSED", , drop = FALSE]; if (!nrow(t)) return(NULL)
  num <- function(k) if (k %in% names(t)) suppressWarnings(as.numeric(t[[k]])) else rep(NA_real_, nrow(t)); sg <- ifelse(toupper(t$direction) %in% "BUY", 1, -1); st <- num("stop_initial"); st <- ifelse(is.finite(st), st, num("stop_level"))
  risk <- abs(num("entry_level") - st); when <- if ("exit_ts" %in% names(t)) as.POSIXct(t$exit_ts, tz = "UTC") else as.POSIXct(t$entry_ts, tz = "UTC"); when[is.na(when)] <- as.POSIXct(t$entry_ts, tz = "UTC")[is.na(when)]
  d <- data.frame(when = when, epic = as.character(t$epic), side = toupper(t$direction), r = sg * (num("exit_level") - num("entry_level")) / risk, planned_rr = abs(num("target_level") - num("entry_level")) / risk, stringsAsFactors = FALSE)
  d <- d[is.finite(d$r), , drop = FALSE]; if (!nrow(d)) return(NULL); d <- d[order(d$when), , drop = FALSE]; d$week <- format(d$when, "%G-W%V", tz = tz); d }
ml_own_slippage <- function(trades) { lg <- tryCatch(cc_trade_log(trades), error = function(e) NULL); if (is.null(lg)) return(list(points = 0, n = 0L)); v <- c(lg$slip_entry, lg$slip_exit); v <- v[is.finite(v)]
  list(points = if (length(v)) max(0, mean(lg$slip_entry, na.rm = TRUE), na.rm = TRUE) + max(0, mean(lg$slip_exit, na.rm = TRUE), na.rm = TRUE) else 0, n = length(v)) }

# course strategies as conditions on the features (cases for the per-strategy record)
ml_strategy_flags <- function(x) list(
  "Holy Grail BUY (ADX above 30, pullback to the 20 average)" = list(side = "buy", on = x$adx > 30 & x$di > 0 & abs(x$e20) <= 0.5),
  "Holy Grail SELL (ADX above 30, pullback to the 20 average)" = list(side = "sell", on = x$adx > 30 & x$di < 0 & abs(x$e20) <= 0.5),
  "Pivot Point Bounce BUY (ADX below 20, up candle at PP or S1)" = list(side = "buy", on = x$adx < 20 & x$body > 0 & (abs(x$pv_pp) <= 0.4 | abs(x$pv_s1) <= 0.4)),
  "Pivot Point Bounce SELL (ADX below 20, down candle at PP or R1)" = list(side = "sell", on = x$adx < 20 & x$body < 0 & (abs(x$pv_pp) <= 0.4 | abs(x$pv_r1) <= 0.4)))

# --- the whole run ------------------------------------------------------------------------------------------------------
ml_run <- function(b, rel = list(), rrr = 1.5, stop_atr = 1.5, horizon = 40L, folds = 4L, spread = 0, ntree = 60L, progress = function(v, m) NULL, slip = 0, tune = FALSE) {
  n <- nrow(b); if (n < 800) stop("Only ", n, " candles: at least 800 are needed to train and test.")
  progress(0.05, "Working out the features and the outcomes..."); x <- ml_features(b, rel); atr <- attr(x, "atr"); lab <- ml_labels(b$high, b$low, b$close, atr, stop_atr, rrr, horizon)
  warm <- 210L; first <- warm + floor(0.4 * (n - warm)); cuts <- unique(round(seq(first, n + 1, length.out = folds + 1)))
  cr <- function(v) if (is.finite(v) && v > 0) mean(v / (stop_atr * atr), na.rm = TRUE) else 0; cost_spread <- cr(spread); cost_slip <- cr(slip); cost_r <- cost_spread + cost_slip   # ***************** your own slippage is charged too
  tuned <- list(); gset <- function(side) tuned[[side]]$gbm %||% list(depth = 3L, shrink = 0.1, ntree = ntree); nset <- function(side) tuned[[side]]$nn %||% list(size = 4L, decay = 1)
  gfit <- function(side, tr) { g <- gset(side); ml_gbm_fit(x[tr, , drop = FALSE], lab[[side]][tr], ntree = g$ntree, depth = g$depth, shrink = g$shrink) }
  nfit <- function(side, tr) { g <- nset(side); ml_nn_fit(x[tr, , drop = FALSE], lab[[side]][tr], size = g$size, decay = g$decay) }
  if (isTRUE(tune)) for (side in c("buy", "sell")) { progress(0.07, sprintf("Tuning the settings on the first training window (%s)...", toupper(side))); tuned[[side]] <- tryCatch(ml_tune(x, lab[[side]], warm:(first - 1 - horizon), horizon), error = function(e) NULL) }
  P <- list(); base <- list(); KZ <- list(); fc <- c("gbm", "hmm", "kal", "nn"); fold <- rep(NA_integer_, n)
  mods <- c(gbm = "Gradient boosted trees", hmm = "Hidden Markov model", kal = "Kalman trend filter", nn = "Neural network", both = "Average of the four", stk = "Stacked ensemble")
  for (side in c("buy", "sell")) { y <- lab[[side]]; pg <- ph <- pk <- pn <- pb <- rep(NA_real_, n)
    for (k in seq_len(length(cuts) - 1)) { progress(0.1 + 0.7 * ((match(side, c("buy", "sell")) - 1) * folds + k) / (2 * folds), sprintf("Walk-forward %s, block %d of %d: training on the past, forecasting the next block...", toupper(side), k, length(cuts) - 1))
      te <- cuts[k]:(cuts[k + 1] - 1); tr <- warm:(cuts[k] - 1 - horizon); tr <- tr[is.finite(y[tr])]; if (length(tr) < 300) next
      fold[te] <- k; pb[te] <- 100 * mean(y[tr]); pn[te] <- tryCatch(ml_nn_predict(nfit(side, tr), x[te, , drop = FALSE]), error = function(e) NA_real_); m <- gfit(side, tr); pg[te] <- ml_gbm_predict(m, x[te, , drop = FALSE])
      o <- ml_hmm_obs(x); h <- ml_hmm_fit(o[warm:max(tr), , drop = FALSE]); g <- ml_hmm_filter(h, o[warm:max(te), , drop = FALSE]); idx <- warm:max(te)
      ph[te] <- as.numeric(g[match(te, idx), , drop = FALSE] %*% ml_hmm_rates(g[match(tr, idx), , drop = FALSE], y[tr]))
      if (is.null(KZ[[as.character(k)]])) KZ[[as.character(k)]] <- ml_kalman(b$close, upto = max(tr))$t; pk[te] <- ml_bin_pred(KZ[[as.character(k)]], y, tr, te) }
    Q <- list(gbm = pg, hmm = ph, kal = pk, nn = pn); Q$both <- rowMeans(cbind(pg, ph, pk, pn), na.rm = TRUE); Q$both[!is.finite(Q$both)] <- NA; ps <- rep(NA_real_, n)
    if (length(cuts) > 2) for (k in 2:(length(cuts) - 1)) { te <- cuts[k]:(cuts[k + 1] - 1); past <- cuts[1]:(cuts[k] - 1 - horizon); ps[te] <- ml_stack_predict(ml_stack_fit(Q, y, past, fc), Q, te, fc) }
    Q$stk <- ps; Q$y <- y; Q$r <- lab[[paste0(side, "_r")]]; P[[side]] <- Q; base[[side]] <- pb }
  met <- do.call(rbind, lapply(c("buy", "sell"), function(side) do.call(rbind, lapply(names(mods), function(key)
    cbind(data.frame(model = mods[[key]], side = toupper(side), stringsAsFactors = FALSE), ml_measure(P[[side]][[key]], P[[side]]$y, base[[side]], rrr, cost_r, r = P[[side]]$r, horizon = horizon)))))); rownames(met) <- NULL
  progress(0.85, "Training on all the history for the forecast now..."); now <- list(); imp <- list(); stackw <- list(); shap <- list(); o <- ml_hmm_obs(x); h <- ml_hmm_fit(o[warm:n, , drop = FALSE]); g <- ml_hmm_filter(h, o[warm:n, , drop = FALSE]); kf <- ml_kalman(b$close)
  for (side in c("buy", "sell")) { y <- lab[[side]]; tr <- warm:n; tr <- tr[is.finite(y[tr])]; m <- gfit(side, tr); imp[[side]] <- m$importance; shap[[side]] <- tryCatch(ml_shap(m, x[tr, , drop = FALSE], x[n, , drop = FALSE]), error = function(e) NULL)
    now[[side]] <- c(gbm = ml_gbm_predict(m, x[n, , drop = FALSE]), hmm = sum(g[nrow(g), ] * ml_hmm_rates(g[match(tr, warm:n), , drop = FALSE], y[tr])), kal = ml_bin_pred(kf$t, y, tr, n),
                       nn = tryCatch(ml_nn_predict(nfit(side, tr), x[n, , drop = FALSE]), error = function(e) NA_real_))
    all_te <- which(is.finite(fold)); sm <- ml_stack_fit(P[[side]], y, all_te, fc); stackw[[side]] <- ml_stack_weights(sm, P[[side]], all_te, fc)
    now[[side]] <- c(now[[side]], both = mean(now[[side]], na.rm = TRUE)); now[[side]][["stk"]] <- if (is.null(sm)) NA_real_ else 100 * as.numeric(stats::predict(sm, as.data.frame(as.list(now[[side]][fc] / 100)), type = "response")) }
  progress(0.92, "Fitting the GARCH volatility model..."); garch <- tryCatch(ml_garch_view(b, atr, stop_atr, rrr, horizon), error = function(e) NULL)
  st <- ml_strategy_flags(x); be <- 100 / (1 + rrr)
  strat <- do.call(rbind, lapply(names(st), function(nm) { s <- st[[nm]]; y <- P[[s$side]]$y; p <- P[[s$side]]$both; on <- s$on %in% TRUE & is.finite(y) & is.finite(p)
    rr <- P[[s$side]]$r; one <- function(i) { k <- sum(i); ni <- length(ml_thin(which(i), horizon)); hit <- if (k) 100 * mean(y[i]) else NA_real_; lo <- if (ni) cc_wilson(hit, ni)$lo else NA_real_; c(ni, hit, lo, if (k) mean(rr[i]) - cost_r else NA_real_) }
    a <- one(on); f <- one(on & p >= be)
    rec <- if (a[1] < 30) "NOT ENOUGH CASES: no advice" else if (a[3] > be) "TRADE IT: proven above break-even" else if (f[1] >= 30 && f[3] > be) "TRADE IT ONLY WHEN THE MODELS AGREE"
           else if (is.finite(a[4]) && a[4] > 0) "HALF SIZE: above break-even but not proven" else "LEAVE IT: below break-even on this market"
    data.frame(strategy = nm, cases = a[1], hit = round(a[2], 1), likely_low = round(a[3], 1), break_even = round(be, 1), r_per_trade = round(a[4], 2), cases_models_agree = f[1], hit_models_agree = round(f[2], 1),
               r_models_agree = round(f[4], 2), met_now = isTRUE(s$on[n]), advice = rec, stringsAsFactors = FALSE) }))
  progress(0.95, "Meta-labelling your set-ups and summing up the exits..."); meta <- tryCatch(ml_meta(x, lab, st, cuts, warm, horizon, rrr, cost_r), error = function(e) NULL)
  exits <- do.call(rbind, lapply(c("buy", "sell"), function(side) { e <- lab[[paste0(side, "_exit")]]; r <- lab[[paste0(side, "_r")]]; ok <- !is.na(e); data.frame(side = toupper(side), cases = sum(ok), target = round(100 * mean(e[ok] == "target"), 1),
    stop = round(100 * mean(e[ok] == "stop"), 1), time = round(100 * mean(e[ok] == "time"), 1), time_r = round(mean(r[ok & e %in% "time"]), 2), all_r = round(mean(r[ok]) - cost_r, 2), stringsAsFactors = FALSE) }))
  cal <- do.call(rbind, lapply(c("buy", "sell"), function(side) { p <- P[[side]]$both; y <- P[[side]]$y; ok <- is.finite(p) & is.finite(y); if (sum(ok) < 50) return(NULL)
    q <- cut(p[ok], unique(stats::quantile(p[ok], 0:5 / 5)), include.lowest = TRUE); data.frame(side = toupper(side), forecast = as.numeric(tapply(p[ok], q, mean)), actual = 100 * as.numeric(tapply(y[ok], q, mean)), n = as.numeric(table(q))) }))
  list(metrics = met, now = now, importance = imp, strategies = strat, calibration = cal, pred = P, times = b$time, n = n, tested = sum(is.finite(P$buy$both)), features = names(x), states = round(100 * g[nrow(g), ]), models = mods, forecasters = fc, fold = fold, stack_weights = stackw, factor = tryCatch(ml_factor(b, rel), error = function(e) NULL), breaks = tryCatch(ml_breaks_view(b), error = function(e) NULL), close = b$close, garch = garch, trend = list(t = kf$t[n], slope = kf$slope[n], atr = atr[n]),
       rrr = rrr, stop_atr = stop_atr, horizon = horizon, cost_r = cost_r, cost_spread_r = cost_spread, cost_slip_r = cost_slip, slip = slip, spread = spread, tuned = tuned, shap = shap, meta = meta, exits = exits, from = min(b$time), to = max(b$time)) }

# the models' out-of-sample forecast at the entry of each of your own closed trades
ml_trades_check <- function(trades, run, epic) {
  if (is.null(trades) || !nrow(trades)) return(NULL); t <- trades[trades$epic %in% epic & trades$status %in% "CLOSED" & !is.na(trades$entry_ts), , drop = FALSE]; if (!nrow(t)) return(NULL)
  i <- findInterval(as.numeric(t$entry_ts), as.numeric(run$times)); side <- ifelse(t$direction %in% "BUY", "buy", "sell")
  p <- vapply(seq_len(nrow(t)), function(k) if (i[k] < 1 || i[k] > run$n) NA_real_ else run$pred[[side[k]]]$both[i[k]], 0)
  r <- (t$exit_level - t$entry_level) * ifelse(side == "buy", 1, -1) / abs(t$entry_level - t$stop_initial)
  data.frame(entry_uk = format(t$entry_ts, "%d/%m %H:%M", tz = "Europe/London"), side = t$direction, models_chance = ifelse(is.finite(p), sprintf("%.0f%%", p), "outside the tested period"),
             result_r = round(r, 2), outcome = ifelse(is.finite(r), ifelse(r > 0, "won", "lost"), "-"), stringsAsFactors = FALSE) }

cc_tables$ml_runs <- list(table = "cc_ml_runs", key = "run_id",
  cols = c(run_id = "STRING", saved_at = "TIMESTAMP", epic = "STRING", resolution = "STRING", related = "STRING", candles = "INT64", tested = "INT64", rrr = "FLOAT64", stop_atr = "FLOAT64",
           horizon = "INT64", model = "STRING", side = "STRING", cases = "INT64", base_rate = "FLOAT64", auc = "FLOAT64", skill_pct = "FLOAT64", picked = "INT64", picked_hit = "FLOAT64",
           picked_r = "FLOAT64", verdict = "STRING", chance_now = "FLOAT64", strategies_json = "STRING"))
