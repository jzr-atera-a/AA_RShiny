# R/utils_infographic_dash.R
# ============================================================
# INFOGRAPHIC STUDIO - dashboard slides
# ============================================================
# Instead of one section per page, a dashboard slide is a grid of 2-6 PANELS (cards),
# each panel drawing one block (chart, diagram, table ...) at its own size. The grid
# (a "bento" layout) is chosen from templates so that wide blocks (pipelines, matrices,
# timelines) get wide cells and compact blocks (gauges, donuts, zones) get small ones.

IG_DASH_CANVAS <- list(`16x9` = c(1440, 1200), `4x3` = c(1280, 1100), a4l = c(1440, 1200), a5l = c(1440, 1200), `1x1` = c(1100, 950), `4x5` = c(1000, 880), `9x16` = c(900, 800), a4 = c(1000, 880))
# canvas width by text size: normal = first value, large = second (smaller canvas, bigger text), small = a wider canvas (more room, finer print)
ig_canvas_w <- function(fmt, size = "normal") { cv <- IG_DASH_CANVAS[[fmt]]; switch(as.character(size), large = cv[2], small = round(cv[1] * 1.2), cv[1]) }

# preferred minimum width and shape (width / height) of each block inside a panel
IG_BLOCK_PREF <- list(
  stat_row = c(380, 2.2), donut = c(420, 1.8), bar_chart = c(420, 1.6), ranking = c(420, 1.7), pictogram = c(440, 2.2), region_map = c(620, 1.5),
  quote_cards = c(440, 1.4), icon_row = c(420, 1.5), steps = c(420, 1.6), branch_tree = c(580, 1.1), callout = c(380, 2.6), flow = c(580, 2.3),
  layers = c(440, 1.8), radial_zones = c(420, 1.15), requirements = c(520, 1.7), compare_matrix = c(580, 1.7), readiness = c(520, 1.9),
  gauge_row = c(420, 2.4), timeline = c(580, 3.2))

# widest a block is drawn inside a panel (it is centred when the cell is wider)
IG_BLOCK_MAXW <- list(radial_zones = 900, gauge_row = 1000, stat_row = 900, donut = 620, callout = 900, pictogram = 760, bar_chart = 760, ranking = 760, steps = 900, icon_row = 900, quote_cards = 900, layers = 760)

# ---- grid templates --------------------------------------------------------------------
tpl_leaf <- function(i) list(k = "leaf", i = i)
tpl_cols <- function(w, ...) list(k = "cols", w = w, kids = list(...))
tpl_rows <- function(...) list(k = "rows", kids = list(...))
ig_templates <- function(n, orient) {
  L <- tpl_leaf; C <- tpl_cols; R <- tpl_rows
  if (orient == "landscape") switch(as.character(n),
    `1` = list(L(1)),
    `2` = list(C(c(.5, .5), L(1), L(2)), C(c(.6, .4), L(1), L(2)), C(c(.4, .6), L(1), L(2))),
    `3` = list(C(c(.52, .48), L(1), R(L(2), L(3))), C(c(.48, .52), R(L(1), L(2)), L(3)), R(L(1), C(c(.5, .5), L(2), L(3)))),
    `4` = list(C(c(.5, .5), R(L(1), L(2)), R(L(3), L(4))), R(C(c(.6, .4), L(1), L(2)), C(c(.4, .6), L(3), L(4))), C(c(.34, .33, .33), R(L(1), L(2)), L(3), L(4)), R(C(c(.5, .5), L(1), L(2)), C(c(.5, .5), L(3), L(4)))),
    `5` = list(R(C(c(.42, .3, .28), L(1), L(2), L(3)), C(c(.5, .5), L(4), L(5))), R(C(c(.5, .5), L(1), L(2)), C(c(.34, .33, .33), L(3), L(4), L(5))), C(c(.4, .3, .3), R(L(1), L(2)), R(L(3), L(4)), L(5))),
    `6` = list(R(C(c(.34, .33, .33), L(1), L(2), L(3)), C(c(.34, .33, .33), L(4), L(5), L(6))), C(c(.4, .3, .3), R(L(1), L(2)), R(L(3), L(4)), R(L(5), L(6)))),
    list(L(1)))
  else if (orient == "square") switch(as.character(n),
    `1` = list(L(1)), `2` = list(R(L(1), L(2))), `3` = list(R(L(1), C(c(.5, .5), L(2), L(3)))), `4` = list(R(C(c(.5, .5), L(1), L(2)), C(c(.5, .5), L(3), L(4)))),
    `5` = list(R(L(1), C(c(.5, .5), L(2), L(3)), C(c(.5, .5), L(4), L(5)))), `6` = list(R(C(c(.5, .5), L(1), L(2)), C(c(.5, .5), L(3), L(4)), C(c(.5, .5), L(5), L(6)))), list(L(1)))
  else switch(as.character(n),
    `1` = list(L(1)), `2` = list(R(L(1), L(2))), `3` = list(R(L(1), L(2), L(3)), R(L(1), C(c(.5, .5), L(2), L(3)))),
    `4` = list(R(L(1), L(2), L(3), L(4)), R(L(1), C(c(.5, .5), L(2), L(3)), L(4))), `5` = list(R(L(1), L(2), C(c(.5, .5), L(3), L(4)), L(5))),
    `6` = list(R(C(c(.5, .5), L(1), L(2)), C(c(.5, .5), L(3), L(4)), C(c(.5, .5), L(5), L(6)))), list(L(1)))
}

IG_GUT <- 16
# a leaf's natural height drives the row heights; leafnat(i, w) must return it
ig_nat_h <- function(node, w, leafnat) {
  if (node$k == "leaf") return(leafnat(node$i, w))
  if (node$k == "cols") { ws <- (w - (length(node$kids) - 1) * IG_GUT) * node$w / sum(node$w); return(max(vapply(seq_along(node$kids), function(j) ig_nat_h(node$kids[[j]], ws[j], leafnat), 0))) }
  sum(vapply(node$kids, function(k) ig_nat_h(k, w, leafnat), 0)) + (length(node$kids) - 1) * IG_GUT
}
# -> list of leaf rectangles (slot index, x, y, w, h)
ig_place <- function(node, x, y, w, h, leafnat = NULL) {
  if (node$k == "leaf") return(list(list(i = node$i, x = x, y = y, w = w, h = h)))
  out <- list()
  if (node$k == "cols") {
    ws <- (w - (length(node$kids) - 1) * IG_GUT) * node$w / sum(node$w); xx <- x
    for (j in seq_along(node$kids)) { out <- c(out, ig_place(node$kids[[j]], xx, y, ws[j], h, leafnat)); xx <- xx + ws[j] + IG_GUT }
    return(out)
  }
  k <- length(node$kids); avail <- h - (k - 1) * IG_GUT
  wt <- if (is.null(leafnat)) vapply(node$kids, function(z) 1, 0) else vapply(node$kids, function(z) max(60, ig_nat_h(z, w, leafnat)), 0)
  hs <- avail * wt / sum(wt); yy <- y
  for (j in seq_len(k)) { out <- c(out, ig_place(node$kids[[j]], x, yy, w, hs[j], leafnat)); yy <- yy + hs[j] + IG_GUT }
  out
}

ig_perms <- function(n) { if (n <= 1) return(list(seq_len(n))); out <- list(); for (i in seq_len(n)) for (p in ig_perms(n - 1)) out[[length(out) + 1]] <- c(i, (seq_len(n))[-i][p]); out }

# choose template and panel -> slot assignment with the lowest mismatch penalty
ig_choose_layout <- function(types, W, H, content = NULL) {
  n <- length(types); orient <- if (W / H >= 1.25) "landscape" else if (W / H >= 0.85) "square" else "portrait"
  best <- NULL; perms <- ig_perms(n)
  for (tp in ig_templates(n, orient)) {
    for (pm in perms) {   # pm[slot] = panel index
      lf <- if (is.null(content)) NULL else function(slot, w) { pc <- content(pm[slot], w); if (is.null(pc)) 100 else pc$nat }
      rects <- ig_place(tp, 0, 0, W, H, lf); ord <- order(vapply(rects, function(r) round(r$y / 40), 0), vapply(rects, function(r) r$x, 0)); rank <- integer(n); rank[ord] <- seq_len(n)
      pen <- 0
      for (sl in seq_len(n)) {
        r <- rects[[sl]]; pr <- IG_BLOCK_PREF[[types[pm[sl]]]] %||% c(420, 1.6)
        pen <- pen + max(0, pr[1] - r$w) / pr[1] * 10 + abs(log((r$w / r$h) / pr[2])) * 1.5 + 0.18 * abs(rank[sl] - pm[sl])
        if (!is.null(content)) { pc <- content(pm[sl], r$w); if (!is.null(pc) && pc$blk$h > 0) { sc <- min(1, (r$h - pc$hh - 14) / pc$blk$h); pen <- pen + 40 * max(0, 0.9 - sc) } }
      }
      if (is.null(best) || pen < best$pen) best <- list(pen = pen, tpl = tp, perm = pm)
    }
  }
  best
}

# ---- one panel ------------------------------------------------------------------------------
ig_panel_content <- function(sec, th, w) {
  old <- ig_geom(); on.exit(ig_set_width(old[["w"]], old[["m"]]), add = TRUE)
  wr <- min(w, IG_BLOCK_MAXW[[sec$type %||% ""]] %||% w); ig_set_width(wr, 20)
  fn <- IG_BLOCKS[[sec$type %||% ""]]; if (is.null(fn)) return(NULL)
  ht <- ig_text(34, 15, ig_wrap(toupper(as.character(sec$heading %||% "")), w - 60, 15, TRUE, 1), 15, th$ink, 800, ls = 0.6)
  it <- ig_text(20, 42, ig_wrap(sec$intro %||% "", w - 40, 12, FALSE, 2), 12, th$muted, 400, lh = 15)
  hh <- if (it$h > 0) 42 + it$h + 12 else 46
  blk <- fn(sec, th, hh)
  list(wr = wr, head = paste0(if (nzchar(as.character(sec$heading %||% ""))) ig_rect(20, 17, 5, 17, ig_acc(th, 1), 2.5) else "", ht$svg, it$svg), hh = hh, blk = blk, nat = hh + blk$h + 18)
}

ig_panel_svg <- function(pc, th, w, h, idx) {
  avail <- h - pc$hh - 14; s <- if (pc$blk$h > 0) min(1, avail / pc$blk$h) else 1
  vc <- max(0, (avail - pc$blk$h * s) / 2); tx <- (w - pc$wr * s) / 2; ty <- pc$hh + vc - s * pc$hh
  list(svg = paste0(ig_rect(0, 0, w, h, th$panel, 16, th$panel_line, 1.5), ig_rect(16, 0, w - 32, 4, ig_acc(th, idx), 2), pc$head,
                    sprintf('<g transform="translate(%s,%s) scale(%s)">%s</g>', ig_n(tx), ig_n(ty), formatC(s, format = "f", digits = 4), pc$blk$svg)), scale = s)
}

# ---- slide chrome ----------------------------------------------------------------------------
ig_dash_header <- function(th, W, hb, kicker, title, subtitle, deck_title, k, total) {
  col1 <- ig_acc(th, 1); col2 <- ig_acc(th, 2)
  side <- W >= 1100; tl <- ig_wrap(title, if (side) W - 330 else W - 150, 30, TRUE, if (side) 1 else 2); st <- ig_wrap(subtitle, if (side) W - 330 else W - 150, 13, FALSE, 1)
  paste0(sprintf('<rect x="0" y="0" width="%s" height="%s" fill="url(#igHero)"/>', ig_n(W), ig_n(hb)),
         ig_circle(W - 60, hb * 0.2, hb * 0.9, "none", col1, 14, ' stroke-opacity="0.16"'), ig_circle(W - 60, hb * 0.2, hb * 0.55, "none", col2, 7, ' stroke-opacity="0.22"'),
         ig_rect(0, hb - 4, W, 4, col1),
         if (nzchar(kicker)) ig_text(24, 10, toupper(kicker), 11.5, col1, 800, ls = 2)$svg else "",
         ig_text(24, if (nzchar(kicker)) 24 else 16, tl, 30, th$hero_ink, 800)$svg,
         if (length(st) > 0) ig_text(24, hb - 28, st, 13, th$hero_ink, 400, opacity = 0.85)$svg else "",
         if (side) ig_text(W - 24, 18, if (nchar(deck_title) > 46) paste0(substr(deck_title, 1, 43), "...") else deck_title, 12, th$hero_ink, 600, "end", opacity = 0.75)$svg else "",
         ig_text(W - 24, 38, sprintf("%d / %d", k, total), 17, col1, 800, "end")$svg)
}
ig_chrome_legend <- function(th, W, H, cnt, dark) {
  if (sum(cnt) == 0) return("")
  items <- names(cnt)[cnt > 0]; xx <- W / 2 - sum(26 + nchar(items) * 5.6) / 2; out <- character(0); col <- if (dark) th$hero_ink else th$muted
  for (s in items) { out <- c(out, ig_status_dot(s, xx + 5, H - 19, 4.2), ig_text(xx + 14, H - 26, s, 10.5, col, 600, opacity = 0.8)$svg); xx <- xx + 26 + nchar(s) * 5.6 }
  paste(out, collapse = "")
}

# group sections into slides (explicit `slide` numbers when valid, otherwise in order)
ig_group_slides <- function(secs, n_slides, per) {
  sl <- vapply(secs, function(s) as.integer(s$slide %||% NA), 1L)
  if (all(!is.na(sl)) && all(sl >= 1 & sl <= n_slides) && length(unique(sl)) >= 1) {
    g <- lapply(seq_len(n_slides), function(k) which(sl == k)); g <- Filter(function(z) length(z) > 0, g)
  } else {
    k <- min(n_slides, length(secs)); sz <- rep(floor(length(secs) / k), k); if (length(secs) %% k > 0) sz[seq_len(length(secs) %% k)] <- sz[seq_len(length(secs) %% k)] + 1L; g <- unname(split(seq_along(secs), rep(seq_len(k), sz)))
  }
  lapply(g, function(z) z[seq_len(min(6, length(z)))])
}

ig_cover_page <- function(d, th, W, H, total, LW) {
  m <- d$meta; cs <- 1.3; old <- ig_geom(); ig_set_width(W / cs, 48); hero <- ig_hero(m, th, fill_h = H / cs, slant = 0); ig_set_width(old[["w"]], old[["m"]])
  sprintf('<svg xmlns="http://www.w3.org/2000/svg" class="ig-svg ig-page" data-ig-page="1" viewBox="0 0 %d %d" width="%d" height="%d" style="max-width:100%%;height:auto;display:block"><title>%s</title>%s%s<g transform="scale(%s)">%s</g>%s</svg>',
          W, H, W, H, ig_e(m$title), ig_defs_css(th), ig_rect(0, 0, W, H, th$bandB), cs, hero$svg, ig_page_chrome(th, W, H, 1, total, m$title, TRUE))
}

ig_build_dashboard <- function(d, fmt, n) {
  f <- IG_FORMATS[[fmt]]; n <- ig_slides_n(n); ts <- tolower(as.character(d$meta$text_size %||% "normal"))
  W <- ig_canvas_w(fmt, ts); H <- round(W / f$ar); th <- ig_theme(d); m <- d$meta
  old <- ig_geom(); on.exit(ig_set_width(old[["w"]], old[["m"]]), add = TRUE)
  secs <- Filter(function(s) !is.null(IG_BLOCKS[[s$type %||% ""]]), d$sections); if (length(secs) == 0) stop("Nothing to draw.")
  cover <- identical(d$meta$cover %||% "auto", "yes") && n >= 2; Pc <- n - as.integer(cover); notes <- character(0)
  groups <- ig_group_slides(secs, Pc, d$meta$panels %||% 3L); total <- length(groups) + as.integer(cover)
  if (length(groups) < Pc) notes <- c(notes, sprintf("There are only %d section(s), so the deck has %d page(s) instead of %d.", length(secs), total, n))
  cnt <- ig_evidence_counts(d); pages <- character(0); hb <- if (W >= 1100) min(round(H * 0.105), 125) else 140; chrome_h <- 34; max_src <- if (W > H) 8 else 12
  if (cover) pages <- c(pages, ig_cover_page(d, th, W, H, total, W))
  for (g in seq_along(groups)) {
    k <- g + as.integer(cover); idx <- groups[[g]]; last <- (g == length(groups)); ps <- secs[idx]
    foot <- if (last && nrow(d$sources) > 0) ig_footer_compact(d, th, W, H, max_src) else list(svg = "", h = chrome_h)
    bx <- 20; by <- hb + 14; bw <- W - 40; bh <- H - by - (if (last && nrow(d$sources) > 0) foot$h else chrome_h) - 10
    types <- vapply(ps, function(s) s$type, ""); cache <- new.env()
    panel_by <- function(pi, w) { key <- paste0(pi, "_", round(w)); if (is.null(cache[[key]])) cache[[key]] <- ig_panel_content(ps[[pi]], th, w); cache[[key]] }
    lay <- ig_choose_layout(types, bw, bh, panel_by)
    panel_at <- function(slot, w) panel_by(lay$perm[slot], w)
    rects <- ig_place(lay$tpl, bx, by, bw, bh, leafnat = function(slot, w) { pc <- panel_at(slot, w); if (is.null(pc)) 100 else pc$nat })
    body <- character(0)
    for (r in rects) {
      pc <- panel_at(r$i, r$w); if (is.null(pc)) next
      pn <- ig_panel_svg(pc, th, r$w, r$h, lay$perm[r$i])
      if (pn$scale < 0.62) notes <- c(notes, sprintf("Slide %d: panel '%s' had to be shrunk to %d%%; it may be hard to read. Use fewer items or more slides.", k, ps[[lay$perm[r$i]]]$heading, round(pn$scale * 100)))
      body <- c(body, sprintf('<g transform="translate(%s,%s)">%s</g>', ig_n(r$x), ig_n(r$y), pn$svg))
    }
    stl <- m$slide_titles %||% list(); stt <- if (g <= length(stl) && is.list(stl[[g]])) stl[[g]] else list()
    title <- if (nzchar(as.character(stt$title %||% ""))) stt$title else if (length(ps) > 0 && nzchar(as.character(ps[[1]]$heading %||% ""))) ps[[1]]$heading else m$title
    hdr <- ig_dash_header(th, W, hb, as.character(stt$kicker %||% m$kicker %||% ""), as.character(title), as.character(stt$subtitle %||% ""), m$title, k, total)
    pages <- c(pages, sprintf('<svg xmlns="http://www.w3.org/2000/svg" class="ig-svg ig-page" data-ig-page="%d" viewBox="0 0 %d %d" width="%d" height="%d" style="max-width:100%%;height:auto;display:block"><title>%s</title>%s%s%s%s%s%s%s</svg>',
                              k, W, H, W, H, ig_e(m$title), ig_defs_css(th), ig_rect(0, 0, W, H, th$bandA), hdr, paste(body, collapse = ""), if (last) foot$svg else "",
                              ig_chrome_legend(th, W, H, cnt, last && nrow(d$sources) > 0), ig_page_chrome(th, W, H, k, total, m$title, last && nrow(d$sources) > 0)))
  }
  list(svg = paste(pages, collapse = ""), w = W, h = H, pages = as.list(pages), n = length(pages), notes = unique(notes), fmt = fmt)
}
