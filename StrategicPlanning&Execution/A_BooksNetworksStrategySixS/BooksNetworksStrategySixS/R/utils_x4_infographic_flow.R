# R/utils_infographic_flow.R
# ============================================================
# INFOGRAPHIC STUDIO - "Illustrated flow" layout
# ============================================================
# A connected, stylised composition instead of cards: a slanted title block, ribbon headings with
# numbered beads, one continuous "snake" rail that links the sections in reading order, soft
# bubbles behind each diagram, ghost numerals, halo-ringed icon orbs on a wavy path, and
# Sankey-style ribbons for rankings. Everything is drawn as SVG, like the other layouts.

# ---- stylised block variants (used only in this layout) --------------------------------------
# orbs: icon orbs with halo rings, on a wavy tube (flow, steps) or loose (icon_row)
ig_flow_orbs <- function(sec, th, y, wave = TRUE, numbered = FALSE) {
  its <- ig_items(sec, 7); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  colw0 <- IG_CW / n; single <- wave && colw0 >= 100
  cols <- if (single) n else max(1, min(n, floor(IG_CW / 112))); colw <- IG_CW / cols; nr <- ceiling(n / cols)
  r <- min(46, max(22, colw * 0.30)); A <- if (single && n > 1) r * 0.6 else 0
  fl <- if (colw < 120) 12 else 14.5; ft <- if (colw < 120) 10.5 else 12; out <- character(0)
  lab_l <- lapply(its, function(it) ig_wrap(it$label, colw - 12, fl, TRUE, 2)); txt_l <- lapply(its, function(it) ig_wrap(it$text, colw - 14, ft, FALSE, 4))
  ht <- vapply(seq_len(n), function(i) length(lab_l[[i]]) * fl * 1.2 + 4 + length(txt_l[[i]]) * ft * 1.28 + 4 + (if (nzchar(ig_tag_id(its[[i]]$tag))) 28 else 0), 0)
  rowh <- vapply(seq_len(nr), function(rr) { ix <- ((rr - 1) * cols + 1):min(n, rr * cols); 2 * A + 2 * r + 32 + max(ht[ix]) + 10 }, 0)
  rtop <- y + c(0, cumsum(rowh))[seq_len(nr)]
  rr_of <- ceiling(seq_len(n) / cols); cc_of <- (seq_len(n) - 1) %% cols + 1
  xs <- IG_M + colw * (cc_of - 0.5); ys <- rtop[rr_of] + A + r + 12 + (if (single) A * ifelse(seq_len(n) %% 2 == 1, -1, 1) else rep(0, n))
  if (single && n > 1) {
    d <- sprintf("M%s,%s", ig_n(xs[1]), ig_n(ys[1]))
    for (i in 2:n) { xm <- (xs[i - 1] + xs[i]) / 2; d <- paste0(d, sprintf(" C%s,%s %s,%s %s,%s", ig_n(xm), ig_n(ys[i - 1]), ig_n(xm), ig_n(ys[i]), ig_n(xs[i]), ig_n(ys[i]))) }
    out <- c(out, sprintf('<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round"/>', d, ig_mix(ig_acc(th, 1), th$panel, 0.7), ig_n(max(10, r * 0.3))),
             sprintf('<path d="%s" fill="none" stroke="%s" stroke-width="2.6" stroke-linecap="round" stroke-dasharray="1 8"/>', d, ig_acc(th, 1)))
  }
  for (i in seq_len(n)) {
    it <- its[[i]]; col <- ig_acc(th, i); tg <- ig_tag_id(it$tag); ins <- identical(tg, "insert")
    out <- c(out, "<g>", ig_tip(it, as.character(it$label %||% "")), ig_circle(xs[i], ys[i], r + 11, "none", col, 3, ' stroke-opacity="0.35"'),
             ig_circle(xs[i], ys[i], r + 3, if (ins) th$panel else col, if (ins) col else th$panel, if (ins) 3 else 4.5, if (ins) ' stroke-dasharray="5 4"' else ""))
    if (!is.null(it$icon) && !numbered) out <- c(out, ig_icon(it$icon, xs[i], ys[i], r * 1.05, if (ins) col else ig_on(col)))
    else out <- c(out, ig_text(xs[i], ys[i] - r * 0.62, as.character(i), r * 0.95, if (ins) col else ig_on(col), 800, "middle")$svg)
    if (!is.null(it$icon) && !numbered && wave) out <- c(out, ig_circle(xs[i] - r * 0.85, ys[i] - r * 0.85, 11, th$panel, col, 2), ig_text(xs[i] - r * 0.85, ys[i] - r * 0.85 - 6.5, as.character(i), 11.5, col, 800, "middle")$svg)
    yy <- ys[i] + r + 20; out <- c(out, ig_text(xs[i], yy, lab_l[[i]], fl, th$ink, 800, "middle", lh = fl * 1.2)$svg); yy <- yy + length(lab_l[[i]]) * fl * 1.2 + 4
    out <- c(out, ig_text(xs[i], yy, txt_l[[i]], ft, th$muted, 400, "middle", lh = ft * 1.28)$svg); yy <- yy + length(txt_l[[i]]) * ft * 1.28 + 4
    ch <- ig_tag_chip(xs[i], yy + 6, tg, th, "middle"); if (ch$h > 0) out <- c(out, ch$svg)
    out <- c(out, "</g>")
  }
  list(svg = paste(out, collapse = ""), h = sum(rowh))
}

# ribbons: a Sankey-style fan from a hub to labelled end points (rankings, shares)
ig_flow_ribbons <- function(sec, th, y) {
  its <- ig_items(sec, 8); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  v <- vapply(its, function(it) max(0, ig_num(it$value, 0)), 0); if (sum(v) <= 0) v <- rep(1, n)
  rowh <- 34; H <- n * rowh; hubr <- 40; x0 <- IG_M + hubr * 2 - 6; x1 <- IG_M + IG_CW * 0.52; thick <- pmax(4, (H * 0.78) * v / sum(v)); cy <- y + H / 2
  out <- character(0); ys0 <- cy - sum(thick) / 2
  out <- c(out, ig_circle(IG_M + hubr, cy, hubr, th$hero_from), ig_circle(IG_M + hubr, cy, hubr + 8, "none", ig_acc(th, 1), 3, ' stroke-opacity="0.4"'),
           ig_icon(sec$icon %||% "chart_bar", IG_M + hubr, cy - 8, 26, th$hero_ink), ig_text(IG_M + hubr, cy + 8, "Total", 11.5, th$hero_ink, 700, "middle")$svg)
  for (i in seq_len(n)) {
    it <- its[[i]]; col <- ig_acc(th, i); yt <- y + (i - 0.5) * rowh; ts <- ys0; ys0 <- ys0 + thick[i]; te <- min(rowh * 0.8, thick[i]); xm <- (x0 + x1) / 2
    d <- sprintf("M%s,%s C%s,%s %s,%s %s,%s L%s,%s C%s,%s %s,%s %s,%s Z", ig_n(x0), ig_n(ts), ig_n(xm), ig_n(ts), ig_n(xm), ig_n(yt - te / 2), ig_n(x1), ig_n(yt - te / 2),
                 ig_n(x1), ig_n(yt + te / 2), ig_n(xm), ig_n(yt + te / 2), ig_n(xm), ig_n(ts + thick[i]), ig_n(x0), ig_n(ts + thick[i]))
    disp <- as.character(it$display %||% it$value %||% "")
    out <- c(out, "<g>", ig_tip(it, as.character(it$label %||% "")), sprintf('<path d="%s" fill="%s" fill-opacity="0.82"/>', d, col),
             ig_circle(x1 + 14, yt, 13, th$panel, col, 2.6), ig_text(x1 + 14, yt - 7.5, as.character(i), 12, col, 800, "middle")$svg,
             ig_text(x1 + 36, yt - 11, ig_wrap(disp, 90, 15, TRUE, 1), 15, col, 800)$svg,
             ig_text(x1 + 36 + min(90, nchar(disp) * 9.5 + 8), yt - 8, ig_wrap(it$label, IG_W - IG_M - (x1 + 36 + min(90, nchar(disp) * 9.5 + 8)), 12.5, TRUE, 1), 12.5, th$ink, 700)$svg,
             ig_marker(it, IG_W - IG_M - 4, yt), "</g>")
  }
  list(svg = paste(out, collapse = ""), h = H + 4)
}

# big outline numerals with a thick progress bar (stat_row)
ig_flow_stats <- function(sec, th, y) {
  its <- ig_items(sec, 4); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  colw <- IG_CW / n; out <- character(0); hmax <- 0
  for (i in seq_len(n)) {
    it <- its[[i]]; col <- ig_acc(th, i); x <- IG_M + colw * (i - 1) + 6; w <- colw - 22; val <- as.character(it$value %||% "")
    fs <- min(66, max(28, w / max(2.6, nchar(val) * 0.62))); out <- c(out, "<g>", ig_tip(it, as.character(it$label %||% "")),
      sprintf('<text x="%s" y="%s" font-size="%s" font-weight="800" fill="%s" stroke="%s" stroke-width="1.5" letter-spacing="1">%s</text>', ig_n(x), ig_n(y + fs * 0.92), ig_n(fs), col, col, ig_e(val)))
    yy <- y + fs * 1.1 + 8
    if (!is.null(it$bar)) { out <- c(out, ig_rect(x, yy, w, 12, th$track, 6), ig_rect(x, yy, max(12, w * it$bar / 100), 12, col, 6)); yy <- yy + 22 }
    lt <- ig_wrap(it$label, w, 15, TRUE, 2); out <- c(out, ig_text(x, yy, lt, 15, th$ink, 800, lh = 18)$svg); yy <- yy + length(lt) * 18 + 4
    nt <- ig_wrap(it$note, w, 12, FALSE, 4); out <- c(out, ig_text(x, yy, nt, 12, th$muted, 400, lh = 15.5)$svg); yy <- yy + length(nt) * 15.5
    out <- c(out, ig_marker(it, x + w - 4, y + 6), "</g>"); hmax <- max(hmax, yy - y)
  }
  list(svg = paste(out, collapse = ""), h = hmax + 6)
}
# milestones as orbs on the wavy path
ig_flow_timeline <- function(sec, th, y) {
  its <- ig_items(sec, 6)
  its <- lapply(its, function(it) { st <- tolower(as.character(it$state %||% "planned")); if (is.null(it$icon)) it$icon <- c(done = "check", `next` = "flag", planned = "clock")[[if (st %in% c("done", "next", "planned")) st else "planned"]]
    it$text <- paste(Filter(nzchar, c(as.character(it$label %||% ""), as.character(it$text %||% ""))), collapse = ". "); it$label <- as.character(it$date %||% ""); it })
  sec$items <- its; ig_flow_orbs(sec, th, y, TRUE, FALSE)
}

IG_FLOW_BLOCKS <- list(
  stat_row = ig_flow_stats, timeline = ig_flow_timeline,
  flow = function(sec, th, y) ig_flow_orbs(sec, th, y, TRUE, FALSE),
  steps = function(sec, th, y) ig_flow_orbs(sec, th, y, TRUE, TRUE),
  icon_row = function(sec, th, y) ig_flow_orbs(sec, th, y, FALSE, FALSE),
  ranking = function(sec, th, y) ig_flow_ribbons(sec, th, y))

# ---- one cell: ribbon heading, intro, block (in a soft bubble) ----------------------------------------
ig_flow_content <- function(sec, th, w) {
  old <- ig_geom(); on.exit(ig_set_width(old[["w"]], old[["m"]]), add = TRUE)
  wr <- min(w, IG_BLOCK_MAXW[[sec$type %||% ""]] %||% w); ig_set_width(wr, 22)
  fn <- IG_FLOW_BLOCKS[[sec$type %||% ""]] %||% IG_BLOCKS[[sec$type %||% ""]]; if (is.null(fn)) return(NULL)
  it <- ig_text(18, 54, ig_wrap(sec$intro %||% "", w - 36, 12.5, FALSE, 2), 12.5, th$muted, 400, lh = 16)
  hh <- if (it$h > 0) 54 + it$h + 10 else 56
  blk <- fn(sec, th, hh)
  list(wr = wr, intro = it$svg, hh = hh, blk = blk, nat = hh + blk$h + 16)
}

ig_flow_cell_svg <- function(sec, pc, th, w, h, k) {
  col <- ig_acc(th, k); avail <- h - pc$hh - 8; s <- if (pc$blk$h > 0) min(1, avail / pc$blk$h) else 1
  vc <- max(0, (avail - pc$blk$h * s) / 2); tx <- (w - pc$wr * s) / 2; ty <- pc$hh + vc - s * pc$hh
  head <- toupper(if (nzchar(as.character(sec$heading %||% ""))) as.character(sec$heading) else if (identical(sec$type, "callout")) "Remember" else as.character(IG_TYPE_LABELS[[sec$type]] %||% "")); fs <- 15.5; rw <- min(w - 30, max(150, nchar(head) * fs * 0.68 + 58))
  lines <- ig_wrap(head, rw - 62, fs, TRUE, 1)
  ribbon <- sprintf('<polygon points="21,0 %s,0 %s,21 %s,42 21,42" fill="%s"/>', ig_n(rw), ig_n(rw + 18), ig_n(rw), col)
  list(svg = paste0(
    ig_rect(0, 26, w, h - 26, th$panel, 26, NULL, 1, ' fill-opacity="0.58"'),
    sprintf('<text x="%s" y="102" font-size="%s" font-weight="800" fill="none" stroke="%s" stroke-width="2" stroke-opacity="0.15" text-anchor="end">%02d</text>', ig_n(w - 14), ig_n(min(96, h * 0.42)), col, k),
    ribbon, ig_text(46, 12, lines, fs, ig_on(col), 800, ls = 0.6)$svg,
    ig_circle(21, 21, 23, th$panel, col, 5), ig_text(21, 21 - 10.5, as.character(k), 20, col, 800, "middle")$svg,
    pc$intro, sprintf('<g transform="translate(%s,%s) scale(%s)">%s</g>', ig_n(tx), ig_n(ty), formatC(s, format = "f", digits = 4), pc$blk$svg)), scale = s)
}

# ---- rows (reading order is a snake: left to right, then right to left, ...) -------------------------------------
ig_flow_rows <- function(n, orient, types = NULL) {
  wide_pref <- function(i) if (is.null(types) || i > length(types)) 0 else (IG_BLOCK_PREF[[types[i]]] %||% c(420, 1.6))[1]
  if (orient == "landscape") switch(as.character(n), `1` = 1, `2` = 2,
    `3` = { if (!is.null(types) && max(vapply(1:3, wide_pref, 0)) >= 520) { if (wide_pref(3) >= wide_pref(1)) c(2, 1) else c(1, 2) } else 3 },
    `4` = c(2, 2), `5` = c(3, 2), `6` = c(3, 3), 1)
  else if (orient == "square") switch(as.character(n), `1` = 1, `2` = c(1, 1), `3` = c(1, 2), `4` = c(2, 2), `5` = c(1, 2, 2), `6` = c(2, 2, 2), 1)
  else rep(1, n)
}

ig_flow_header <- function(th, W, hb, kicker, title, subtitle, k, total) {
  c1 <- ig_acc(th, 1); c2 <- ig_acc(th, 2); wide <- W >= 1100; bw <- if (wide) W * 0.6 else W - 30; cut <- hb * 0.34
  poly <- sprintf('<polygon points="0,0 %s,0 %s,%s 0,%s" fill="url(#igHero)"/>', ig_n(bw), ig_n(bw - cut), ig_n(hb), ig_n(hb))
  fs <- if (wide) min(36, max(24, hb * 0.235)) else 30; tl <- ig_wrap(title, bw - cut - 56, fs, TRUE, 2)
  th_h <- length(tl) * fs * 1.2; sl <- if (!wide && nzchar(subtitle)) ig_wrap(subtitle, bw - 120, 13, FALSE, 2) else character(0); sub_h <- if (length(sl) > 0) length(sl) * 17 + 16 else 0
  kh <- if (nzchar(kicker)) 18 else 0; ky <- (hb - (kh + th_h + sub_h)) / 2
  right <- if (wide) paste0(ig_text(bw + 24, hb / 2 - 30, ig_wrap(subtitle, W - bw - 150, 14.5, FALSE, 4), 14.5, th$ink, 500, lh = 19)$svg) else ""
  sub_in <- if (length(sl) > 0) ig_text(28, ky + kh + th_h + 14, sl, 13, th$hero_ink, 400, lh = 17, opacity = 0.85)$svg else ""
  rr <- hb * 0.3; rx <- W - rr - 26; ry <- hb / 2
  ring <- paste0(ig_circle(rx, ry, rr + 12, "none", c1, 5, ' stroke-opacity="0.3"'), ig_circle(rx, ry, rr, th$hero_from, th$panel, 4),
                 ig_text(rx, ry - 13, sprintf("%d/%d", k, total), 20, th$hero_ink, 800, "middle")$svg)
  paste0(poly,
         if (nzchar(kicker)) ig_text(28, ky, toupper(kicker), 12, c1, 800, ls = 2.2)$svg else "",
         ig_text(28, ky + kh, tl, fs, th$hero_ink, 800, lh = fs * 1.2)$svg, sub_in, right, ring)
}

ig_flow_decor <- function(th, W, H) {
  c1 <- ig_acc(th, 1); c2 <- ig_acc(th, 2); c3 <- ig_acc(th, 3)
  paste0(sprintf('<defs><pattern id="igDots" width="22" height="22" patternUnits="userSpaceOnUse"><circle cx="3" cy="3" r="1.5" fill="%s" fill-opacity="0.22"/></pattern></defs>', c1),
         sprintf('<rect x="0" y="0" width="%s" height="%s" fill="url(#igDots)"/>', ig_n(W), ig_n(H)),
         sprintf('<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="%s" fill-opacity="0.07"/>', ig_n(W * 0.62), ig_n(H), ig_n(W * 0.78), ig_n(H * 0.25), ig_n(W * 0.9), ig_n(H * 0.25), ig_n(W * 0.74), ig_n(H), c2),
         ig_circle(W * 0.06, H * 0.9, H * 0.22, "none", c1, 16, ' stroke-opacity="0.10"'), ig_circle(W * 0.94, H * 0.38, H * 0.16, "none", c3, 12, ' stroke-opacity="0.10"'))
}

# the snake rail through the beads
ig_flow_rail <- function(th, rows, W, mL, mR) {
  if (length(rows) == 0) return("")
  col <- ig_acc(th, 1); rad <- 16; pts <- list(); d <- ""
  for (r in seq_along(rows)) {
    y <- rows[[r]]$y + 21; ltr <- (r %% 2 == 1); xs <- vapply(rows[[r]]$cells, function(c) c$x + 21, 0)
    xa <- if (ltr) min(xs) else max(xs) + 0; xb <- if (ltr) W - mR + 10 else mL - 10
    if (r == 1) d <- sprintf("M%s,%s", ig_n(xa), ig_n(y))
    else { prev <- rows[[r - 1]]; yp <- prev$y + 21; side <- if ((r - 1) %% 2 == 1) 1 else -1   # previous row ended on the right (1) or left (-1)
      xe <- if (side == 1) W - mR + 10 else mL - 10; d <- paste0(d, sprintf(" L%s,%s", ig_n(xe - side * rad), ig_n(yp)), sprintf(" Q%s,%s %s,%s", ig_n(xe), ig_n(yp), ig_n(xe), ig_n(yp + rad)),
                                                           sprintf(" L%s,%s", ig_n(xe), ig_n(y - rad)), sprintf(" Q%s,%s %s,%s", ig_n(xe), ig_n(y), ig_n(xe - side * rad), ig_n(y)),
                                                           sprintf(" L%s,%s", ig_n(xa), ig_n(y))) }
  }
  last <- rows[[length(rows)]]; yl <- last$y + 21; xl <- vapply(last$cells, function(c) c$x + 21, 0); xend <- if (length(rows) %% 2 == 1) max(xl) else min(xl)
  d <- paste0(d, sprintf(" L%s,%s", ig_n(xend), ig_n(yl)))
  # a final extension on the last row is not needed; arrows sit in the gaps between cells
  paste0(sprintf('<path d="%s" fill="none" stroke="%s" stroke-width="13" stroke-linecap="round" stroke-linejoin="round"/>', d, ig_mix(col, th$bandA, 0.7)),
         sprintf('<path d="%s" fill="none" stroke="%s" stroke-width="3" stroke-linecap="round" stroke-dasharray="1 9"/>', d, col))
}

ig_flow_arrows <- function(th, rows) {
  out <- character(0)
  for (r in seq_along(rows)) {
    cs <- rows[[r]]$cells; ltr <- (r %% 2 == 1); y <- rows[[r]]$y + 21
    for (j in seq_len(max(0, length(cs) - 1))) {
      a <- cs[[j]]; b <- cs[[j + 1]]; gx <- (a$x + a$w + b$x) / 2; dir <- if (ltr) 1 else -1
      out <- c(out, sprintf('<polygon points="%s,%s %s,%s %s,%s" fill="%s" stroke="%s" stroke-width="2.5" stroke-linejoin="round"/>', ig_n(gx - 8 * dir), ig_n(y - 9), ig_n(gx + 9 * dir), ig_n(y), ig_n(gx - 8 * dir), ig_n(y + 9), ig_acc(th, 2), th$bandA))
    }
  }
  paste(out, collapse = "")
}

# ---- composer ----------------------------------------------------------------------------------------------------
ig_build_flow <- function(d, fmt, n) {
  f <- IG_FORMATS[[fmt]]; poster <- identical(fmt, "poster"); n <- if (poster) 1L else ig_slides_n(n); m <- d$meta
  ts <- tolower(as.character(m$text_size %||% "normal"))
  W <- if (poster) 1100 else ig_canvas_w(fmt, ts); H <- if (poster) NA_real_ else round(W / f$ar); th <- ig_theme(d)
  old <- ig_geom(); on.exit(ig_set_width(old[["w"]], old[["m"]]), add = TRUE); ig_set_width(W, 24)
  secs <- Filter(function(s) !is.null(IG_BLOCKS[[s$type %||% ""]]), d$sections); if (length(secs) == 0) stop("Nothing to draw.")
  cover <- !poster && identical(m$cover %||% "auto", "yes") && n >= 2; Pc <- n - as.integer(cover); notes <- character(0)
  groups <- if (poster) list(seq_along(secs)) else ig_group_slides(secs, Pc, m$panels %||% 3L)
  total <- length(groups) + as.integer(cover)
  if (!poster && length(groups) < Pc) notes <- c(notes, sprintf("There are only %d section(s), so the deck has %d page(s) instead of %d.", length(secs), total, n))
  cnt <- ig_evidence_counts(d); pages <- character(0); chrome_h <- 34; max_src <- if (!poster && W > H) 8 else 12; mL <- 34; mR <- 34; gap <- 28; rgap <- 22
  if (cover) pages <- c(pages, ig_cover_page(d, th, W, H, total, W))
  for (g in seq_along(groups)) {
    k <- g + as.integer(cover); ps <- secs[groups[[g]]]; last <- (g == length(groups)); np <- length(ps)
    orient <- if (poster) "poster" else if (W / H >= 1.25) "landscape" else if (W / H >= 0.85) "square" else "portrait"
    rowsN <- if (poster) rep(2, ceiling(np / 2)) else ig_flow_rows(np, orient, vapply(ps, function(z) z$type, "")); if (poster && np %% 2 == 1) rowsN[length(rowsN)] <- 1
    hb <- if (poster) 210 else if (W >= 1100) min(round(H * 0.17), 150) else 170
    stl <- m$slide_titles %||% list(); stt <- if (g <= length(stl) && is.list(stl[[g]])) stl[[g]] else list()
    title <- if (nzchar(as.character(stt$title %||% ""))) stt$title else if (poster || identical(g, 1L)) m$title else (ps[[1]]$heading %||% m$title)
    sub <- as.character(stt$subtitle %||% (if (poster || g == 1) m$subtitle else "")); kick <- as.character(stt$kicker %||% m$kicker %||% "")
    has_src <- last && nrow(d$sources) > 0
    foot_h <- if (has_src) ig_footer_compact(d, th, W, 1000, max_src)$h else chrome_h
    cache <- new.env(); cell <- function(i, w) { key <- paste0(i, "_", round(w)); if (is.null(cache[[key]])) cache[[key]] <- ig_flow_content(ps[[i]], th, w); cache[[key]] }
    # order: snake (odd rows left to right, even rows right to left)
    idx <- 1L; rowspec <- list(); iw <- W - mL - mR
    for (r in seq_along(rowsN)) {
      cn <- rowsN[r]; cw <- (iw - (cn - 1) * gap) / cn; ids <- idx:(idx + cn - 1); idx <- idx + cn
      slots <- lapply(seq_len(cn), function(j) list(x = mL + (j - 1) * (cw + gap), w = cw))
      assign_ids <- if (r %% 2 == 1) ids else rev(ids)
      for (j in seq_len(cn)) slots[[j]]$i <- assign_ids[j]
      rowspec[[r]] <- list(cells = slots, nat = max(vapply(slots, function(s) { pc <- cell(s$i, s$w); if (is.null(pc)) 100 else pc$nat }, 0)))
    }
    nat <- vapply(rowspec, function(z) z$nat, 0)
    if (poster) { bh <- sum(nat) + (length(nat) - 1) * rgap; H <- hb + 24 + bh + 24 + foot_h + 6; hts <- nat }
    else { bh <- H - hb - 22 - foot_h - 10; hts <- (bh - (length(nat) - 1) * rgap) * nat / sum(nat) }
    yy <- hb + 22; body <- character(0)
    for (r in seq_along(rowspec)) {
      rowspec[[r]]$y <- yy
      for (j in seq_along(rowspec[[r]]$cells)) {
        s <- rowspec[[r]]$cells[[j]]; pc <- cell(s$i, s$w); if (is.null(pc)) next
        cs <- ig_flow_cell_svg(ps[[s$i]], pc, th, s$w, hts[r], s$i)
        if (cs$scale < 0.62) notes <- c(notes, sprintf("Slide %d: '%s' had to be shrunk to %d%%; it may be hard to read. Use fewer items or more slides.", k, ps[[s$i]]$heading, round(cs$scale * 100)))
        body <- c(body, sprintf('<g transform="translate(%s,%s)">%s</g>', ig_n(s$x), ig_n(yy), cs$svg))
      }
      yy <- yy + hts[r] + rgap
    }
    foot <- if (has_src) ig_footer_compact(d, th, W, H, max_src) else list(svg = "", h = chrome_h)
    hdr <- ig_flow_header(th, W, hb, kick, as.character(title), sub, k, total)
    pages <- c(pages, sprintf('<svg xmlns="http://www.w3.org/2000/svg" class="ig-svg ig-page" data-ig-page="%d" viewBox="0 0 %d %d" width="%d" height="%d" style="max-width:100%%;height:auto;display:block"><title>%s</title>%s%s%s%s%s%s%s%s%s%s</svg>',
                              k, as.integer(W), as.integer(round(H)), as.integer(W), as.integer(round(H)), ig_e(m$title), ig_defs_css(th), ig_rect(0, 0, W, H, th$bandA), ig_flow_decor(th, W, H), hdr,
                              ig_flow_rail(th, rowspec, W, mL, mR), ig_flow_arrows(th, rowspec), paste(body, collapse = ""), if (has_src) foot$svg else "",
                              ig_chrome_legend(th, W, H, cnt, has_src), ig_page_chrome(th, W, H, k, total, m$title, has_src)))
  }
  Hf <- if (poster) as.integer(round(H)) else H
  list(svg = paste(pages, collapse = ""), w = W, h = Hf, pages = as.list(pages), n = length(pages), notes = unique(notes), fmt = fmt)
}
