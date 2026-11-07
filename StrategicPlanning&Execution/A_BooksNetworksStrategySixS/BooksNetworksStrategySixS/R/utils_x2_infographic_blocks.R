# R/utils_infographic_blocks.R
# ============================================================
# INFOGRAPHIC STUDIO - diagram blocks (flow, layers, radial_zones, requirements,
# compare_matrix, readiness, timeline, gauge_row) + the extra icons they use.
# Same contract as the other blocks: function(sec, th, y) -> list(svg, h), drawn
# inside [IG_M, IG_W - IG_M] and adaptive to the current width (panels are narrow).
# ============================================================

# ---- extra icons (24 x 24 grid, original geometry) -------------------------------
IG_ICONS$drone <- '<rect x="9.5" y="10" width="5" height="4" rx="1.2"/><path d="M10 10.5L6.5 7M14 10.5L17.5 7M10 13.5L6.5 17M14 13.5l3.5 3.5"/><circle cx="5.2" cy="5.8" r="2.4"/><circle cx="18.8" cy="5.8" r="2.4"/><circle cx="5.2" cy="18.2" r="2.4"/><circle cx="18.8" cy="18.2" r="2.4"/>'
IG_ICONS$camera <- '<rect x="3" y="7.5" width="18" height="12" rx="2"/><path d="M8 7.5l1.4-3h5.2l1.4 3"/><circle cx="12" cy="13.5" r="3.6"/>'
IG_ICONS$radar <- '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><path d="M12 12l6.2-6.2"/><circle cx="12" cy="12" r="1.1" fill="currentColor"/>'
IG_ICONS$robot <- '<rect x="5" y="8.5" width="14" height="11" rx="2.5"/><path d="M12 8.5V5"/><circle cx="12" cy="3.8" r="1.3"/><circle cx="9" cy="13.5" r="1.4" fill="currentColor"/><circle cx="15" cy="13.5" r="1.4" fill="currentColor"/><path d="M9 17h6M2.5 12.5v3M21.5 12.5v3"/>'
IG_ICONS$thermal <- '<path d="M10 14.5V5a2 2 0 0 1 4 0v9.5a4 4 0 1 1-4 0z"/><path d="M12 9v6.5"/><circle cx="12" cy="17" r="1.1" fill="currentColor"/>'
IG_ICONS$bell <- '<path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l2 2H4z"/><path d="M10 21.3h4"/>'
IG_ICONS$antenna <- '<path d="M12 11v10M8 21h8"/><circle cx="12" cy="9" r="1.8"/><path d="M7.4 4.6a6.4 6.4 0 0 0 0 8.8M16.6 4.6a6.4 6.4 0 0 1 0 8.8"/>'
IG_ICONS$tower <- '<path d="M7 21l2-10.5h6L17 21M6 10.5h12M8 10.5V6.5h8v4M12 6.5V3"/>'
IG_ICONS$wall <- '<path d="M3 20V7.5h18V20M3 11.7h18M3 15.9h18M9 7.5v4.2M15 7.5v4.2M6 11.7v4.2M12 11.7v4.2M18 11.7v4.2M9 15.9V20M15 15.9V20"/>'
IG_ICONS$brain <- '<circle cx="6" cy="6" r="2"/><circle cx="6" cy="18" r="2"/><circle cx="12" cy="12" r="2.2"/><circle cx="18" cy="6" r="2"/><circle cx="18" cy="18" r="2"/><path d="M7.8 7l2.6 3.5M7.8 17l2.6-3.5M13.8 10.8L16.4 7.4M13.8 13.2l2.6 3.4"/>'
IG_ICONS$route <- '<circle cx="6" cy="18" r="2.4"/><circle cx="18" cy="6" r="2.4"/><path d="M8.4 18H15a3 3 0 0 0 0-6H9a3 3 0 0 1 0-6h6.6"/>'
IG_ICONS$layers <- '<path d="M12 3l9 5-9 5-9-5z"/><path d="M3 12.5l9 5 9-5M3 16.8l9 5 9-5"/>'
IG_ICONS$handshake <- '<path d="M3 11l4-3 4 2 3-2 7 4M3 11v3l6 5 2-1.5M21 12v3l-5 4-2-1.2"/>'
IG_ICON_NAMES <- names(IG_ICONS)
IG_ICON_SYN <- c(IG_ICON_SYN, uav = "drone", uas = "drone", quadcopter = "drone", aircraft = "drone", camera_eo = "camera", video = "camera", vision = "camera", cctv = "camera", eo = "camera",
                 radar_rf = "radar", sensor = "radar", detect = "radar", detection = "radar", ai_robot = "robot", robotics = "robot", automation = "robot", infrared = "thermal", ir = "thermal",
                 temperature = "thermal", notification = "bell", notify = "bell", siren = "bell", rf = "antenna", signal = "antenna", radio = "antenna", mast = "antenna", guard = "tower",
                 watchtower = "tower", perimeter = "wall", fence = "wall", prison = "wall", boundary = "wall", neural = "brain", ml = "brain", model = "brain", path = "route", track = "route",
                 tracking = "route", stack = "layers", architecture = "layers", partnership = "handshake", partner = "handshake", collaboration = "handshake")

IG_REQ_COL <- c(met = "#16A34A", partial = "#F59E0B", planned = "#3B82F6", gap = "#DC2626")
IG_REQ_LABEL <- c(met = "Designed to meet", partial = "Partly meets", planned = "Planned", gap = "Not met")

# ---- small drawing helpers ---------------------------------------------------------------
ig_arrow <- function(x1, y1, x2, y2, col, sw = 3, head = 7) {
  a <- atan2(y2 - y1, x2 - x1); bx <- x2 - head * cos(a); by <- y2 - head * sin(a)
  paste0(ig_line(x1, y1, bx, by, col, sw),
         sprintf('<polygon points="%s,%s %s,%s %s,%s" fill="%s"/>', ig_n(x2), ig_n(y2), ig_n(bx + head * 0.62 * sin(a)), ig_n(by - head * 0.62 * cos(a)), ig_n(bx - head * 0.62 * sin(a)), ig_n(by + head * 0.62 * cos(a)), col))
}
ig_polar <- function(cx, cy, r, deg) { a <- deg * pi / 180; c(cx + r * sin(a), cy - r * cos(a)) }
# partially filled ball (Harvey ball): frac 0..1
ig_ball <- function(cx, cy, r, frac, col, bg) {
  frac <- min(1, max(0, frac)); base <- ig_circle(cx, cy, r, if (frac >= 1) col else bg, col, 2)
  if (frac > 0 && frac < 1) {
    th <- frac * 2 * pi; ex <- cx + r * sin(th); ey <- cy - r * cos(th)
    base <- paste0(base, sprintf('<path d="M%s %s L%s %s A%s %s 0 %d 1 %s %s Z" fill="%s"/>', ig_n(cx), ig_n(cy), ig_n(cx), ig_n(cy - r), ig_n(r), ig_n(r), if (th > pi) 1 else 0, ig_n(ex), ig_n(ey), col))
  }
  base
}
ig_halo_text <- function(x, y, txt, fs, fill, halo, weight = 700, anchor = "middle") {
  sprintf('<text x="%s" y="%s" font-size="%s" font-weight="%s" fill="%s" text-anchor="%s" stroke="%s" stroke-width="3.2" paint-order="stroke" stroke-linejoin="round">%s</text>',
          ig_n(x), ig_n(y + fs), ig_n(fs), weight, fill, anchor, halo, ig_e(txt))
}
ig_conn_col <- function(th) ig_mix(th$muted, th$panel, 0.35)
ig_strs <- function(x, n = 6, maxc = 30) {
  v <- unlist(lapply(x %||% list(), function(z) if (is.list(z)) as.character(z$label %||% z$text %||% "") else as.character(z)))
  v <- trimws(v[nzchar(trimws(v))]); v <- v[seq_len(min(n, length(v)))]; ifelse(nchar(v) > maxc, paste0(substr(v, 1, maxc - 3), "..."), v)
}

# ---- flow: a pipeline of nodes joined by arrows ------------------------------------------------
ig_block_flow <- function(sec, th, y) {
  its <- ig_items(sec, 7); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  gap <- 30; per <- max(1, min(n, floor((IG_CW + gap) / (116 + gap)))); rows <- ceiling(n / per); per <- ceiling(n / rows)
  nw <- (IG_CW - (per - 1) * gap) / per
  cells <- lapply(its, function(it) {
    lt <- ig_wrap(it$label, nw - 20, 13.5, TRUE, 2); tt <- ig_wrap(it$text, nw - 22, 11.5, FALSE, 5); tg <- ig_tag_id(it$tag)
    list(lt = lt, tt = tt, tg = tg, h = 70 + length(lt) * 17.5 + 4 + length(tt) * 15 + (if (nzchar(tg)) 32 else 8) + 4)
  })
  rowh <- vapply(seq_len(rows), function(r) max(vapply(cells[((r - 1) * per + 1):min(n, r * per)], function(z) z$h, 0)), 0)
  rgap <- 34; out <- character(0); ytop <- y
  for (r in seq_len(rows)) {
    idx <- ((r - 1) * per + 1):min(n, r * per)
    for (k in seq_along(idx)) {
      i <- idx[k]; it <- its[[i]]; z <- cells[[i]]; x <- IG_M + (k - 1) * (nw + gap); col <- ig_acc(th, i)
      out <- c(out, "<g>", ig_tip(it, as.character(it$label %||% "")),
               ig_rect(x, ytop, nw, rowh[r], th$panel, 14, if (z$tg == "insert") col else th$panel_line, if (z$tg == "insert") 2 else 1.5, if (z$tg == "insert") ' stroke-dasharray="6 4"' else ""),
               ig_rect(x + 16, ytop, nw - 32, 4, col, 2),
               ig_circle(x + 15, ytop + 17, 9.5, col), ig_text(x + 15, ytop + 10.5, as.character(i), 11, ig_on(col), 800, "middle")$svg,
               ig_badge(x + nw / 2, ytop + 40, 20, col, it$icon, ring = FALSE),
               ig_text(x + nw / 2, ytop + 68, z$lt, 13.5, th$ink, 700, "middle", lh = 17.5)$svg,
               ig_text(x + nw / 2, ytop + 72 + length(z$lt) * 17.5, z$tt, 11.5, th$muted, 400, "middle", lh = 15)$svg,
               if (nzchar(z$tg)) ig_tag_chip(x + nw / 2, ytop + rowh[r] - 25, z$tg, th, "middle")$svg else "", "</g>")
      if (k < length(idx)) out <- c(out, ig_arrow(x + nw + 5, ytop + 40, x + nw + gap - 4, ytop + 40, ig_acc(th, i), 3.2))
    }
    if (r < rows) {
      xl <- IG_M + (length(idx) - 1) * (nw + gap) + nw / 2; ym <- ytop + rowh[r] + rgap / 2; xf <- IG_M + nw / 2
      out <- c(out, sprintf('<path d="M%s %s V%s H%s V%s" fill="none" stroke="%s" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round" stroke-dasharray="1 7"/>', ig_n(xl), ig_n(ytop + rowh[r]), ig_n(ym), ig_n(xf), ig_n(ytop + rowh[r] + rgap - 8), ig_conn_col(th)),
               ig_arrow(xf, ytop + rowh[r] + rgap - 14, xf, ytop + rowh[r] + rgap - 1, ig_conn_col(th), 3))
    }
    ytop <- ytop + rowh[r] + rgap
  }
  list(svg = paste(out, collapse = ""), h = ytop - y - rgap)
}

# ---- layers: stacked tiers (architecture) -------------------------------------------------------
ig_block_layers <- function(sec, th, y) {
  its <- ig_items(sec, 5); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  lw <- min(190, IG_CW * 0.3); cx0 <- IG_M + lw + 10; cwid <- IG_CW - lw - 10; out <- character(0); yy <- y; gap <- 16
  for (i in seq_len(n)) {
    it <- its[[i]]; col <- ig_acc(th, i); chips <- ig_strs(it$chips, 6, 30)
    # chip layout
    cx <- cx0 + 12; cy <- 0; place <- list(); rowsn <- 1
    for (c in chips) { w <- nchar(c) * 6.4 + 22; if (cx + w > cx0 + cwid - 10 && cx > cx0 + 12) { cx <- cx0 + 12; cy <- cy + 30; rowsn <- rowsn + 1 }; place[[length(place) + 1]] <- list(c = c, x = cx, y = cy, w = w); cx <- cx + w + 8 }
    lt <- ig_wrap(it$label, lw - 62, 14, TRUE, 2); tt <- ig_wrap(it$text, lw - 24, 10.5, FALSE, 3)
    rowh <- max(64, rowsn * 30 + 22, 22 + length(lt) * 17.5 + length(tt) * 13.5 + 14); tg <- ig_tag_chip(cx0 + cwid - 10, yy + 6, it$tag, th, "end")
    out <- c(out, "<g>", ig_tip(it, as.character(it$label %||% "")), ig_rect(cx0, yy, cwid, rowh, th$panel, 12, th$panel_line, 1.5),
             ig_rect(IG_M, yy, lw, rowh, col, 12), ig_icon(it$icon %||% "gear", IG_M + 26, yy + 28, 24, ig_on(col)),
             ig_text(IG_M + 50, yy + 14, lt, 14, ig_on(col), 800, lh = 17.5)$svg, ig_text(IG_M + 12, yy + 22 + length(lt) * 17.5, tt, 10.5, ig_on(col), 400, lh = 13.5, opacity = 0.9)$svg)
    for (p in place) out <- c(out, ig_rect(p$x, yy + 12 + p$y + (if (nzchar(tg$svg)) 8 else 0), p$w, 24, ig_mix(col, th$panel, 0.86), 12, col, 1.3), ig_text(p$x + p$w / 2, yy + 12 + p$y + (if (nzchar(tg$svg)) 8 else 0) + 5.5, p$c, 11.5, th$ink, 700, "middle")$svg)
    out <- c(out, tg$svg, "</g>")
    if (i < n) out <- c(out, sprintf('<polygon points="%s,%s %s,%s %s,%s" fill="%s"/>', ig_n(IG_M + lw / 2 - 9), ig_n(yy + rowh + 2), ig_n(IG_M + lw / 2 + 9), ig_n(yy + rowh + 2), ig_n(IG_M + lw / 2), ig_n(yy + rowh + gap - 2), ig_conn_col(th)))
    yy <- yy + rowh + gap
  }
  list(svg = paste(out, collapse = ""), h = yy - y - gap)
}

# ---- radial_zones: concentric detection zones around an asset, with sensors and threats --------------
ig_block_radial_zones <- function(sec, th, y) {
  zs <- Filter(is.list, (sec$zones %||% list())[seq_len(min(4, length(sec$zones %||% list())))]); K <- length(zs); if (K == 0) return(list(svg = "", h = 0))
  wide <- IG_CW >= 560
  R <- if (wide) min(IG_CW * 0.46, 165) else min(IG_CW * 0.46, 170); cx <- if (wide) IG_M + R + 4 else IG_M + IG_CW / 2; cy <- y + R + 6
  rin <- max(36, R * 0.27); b <- c(R, R - (seq_len(K)) * (R - rin) / K)   # b[1] = outer edge, b[k+1] = inner edge of zone k
  out <- character(0)
  for (k in seq_len(K)) out <- c(out, ig_circle(cx, cy, b[k], ig_mix(ig_acc(th, k), th$panel, 0.8 + 0.03 * (k - 1)), ig_acc(th, k), 1.8, ' stroke-dasharray="7 5"'))
  out <- c(out, ig_circle(cx, cy, rin, th$hero_from))
  ctr <- ig_wrap(sec$center %||% "Protected site", rin * 2 - 12, 10.5, TRUE, 2)
  out <- c(out, ig_icon(sec$center_icon %||% "wall", cx, cy - (if (length(ctr) > 0) 9 else 0), min(28, rin * 0.7), th$hero_ink), ig_text(cx, cy + rin * 0.28, ctr, 10.5, th$hero_ink, 700, "middle", lh = 12.5)$svg)
  zmid <- function(k) (b[k] + b[k + 1]) / 2
  nodes <- Filter(is.list, (sec$nodes %||% list())[seq_len(min(6, length(sec$nodes %||% list())))]); nn <- length(nodes)
  thr <- Filter(is.list, (sec$threats %||% list())[seq_len(min(3, length(sec$threats %||% list())))])
  # sensing wedges first (under the markers)
  for (i in seq_len(nn)) {
    nd <- nodes[[i]]; ang <- ig_num(nd$angle, (i - 1) * 360 / max(1, nn)); zk <- min(K, max(1, round(ig_num(nd$zone, K))))
    p <- ig_polar(cx, cy, zmid(zk), ang); q1 <- ig_polar(cx, cy, R - 2, ang - 17); q2 <- ig_polar(cx, cy, R - 2, ang + 17)
    out <- c(out, sprintf('<path d="M%s %s L%s %s A%s %s 0 0 1 %s %s Z" fill="%s" fill-opacity="0.18" stroke="%s" stroke-opacity="0.5" stroke-width="1"/>', ig_n(p[1]), ig_n(p[2]), ig_n(q1[1]), ig_n(q1[2]), ig_n(R - 2), ig_n(R - 2), ig_n(q2[1]), ig_n(q2[2]), ig_acc(th, 1), ig_acc(th, 1)))
  }
  for (i in seq_len(nn)) {
    nd <- nodes[[i]]; ang <- ig_num(nd$angle, (i - 1) * 360 / max(1, nn)); zk <- min(K, max(1, round(ig_num(nd$zone, K)))); p <- ig_polar(cx, cy, zmid(zk), ang)
    lp <- ig_polar(cx, cy, zmid(zk) + 24, ang)
    out <- c(out, "<g>", ig_circle(p[1], p[2], 14, ig_acc(th, 1), th$panel, 2.4), ig_icon(nd$icon %||% "camera", p[1], p[2], 17, ig_on(ig_acc(th, 1))),
             ig_halo_text(lp[1], lp[2] - 6, as.character(nd$label %||% ""), 10.5, th$ink, th$panel, 700, if (lp[1] < cx - 8) "end" else if (lp[1] > cx + 8) "start" else "middle"), "</g>")
  }
  for (i in seq_along(thr)) {
    t <- thr[[i]]; ang <- ig_num(t$angle, 40 + 70 * i); zk <- min(K, max(1, round(ig_num(t$zone, 1)))); p <- ig_polar(cx, cy, zmid(zk) + (if (zk == 1) 8 else 0), ang)
    e <- ig_polar(cx, cy, rin + 2, ang)
    out <- c(out, "<g>", sprintf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2" stroke-dasharray="5 4"/>', ig_n(p[1]), ig_n(p[2]), ig_n(e[1]), ig_n(e[2]), ig_acc(th, 2)),
             ig_circle(p[1], p[2], 14, ig_acc(th, 2), th$panel, 2.4), ig_icon(t$icon %||% "drone", p[1], p[2], 18, ig_on(ig_acc(th, 2))),
             ig_halo_text(p[1] + (if (p[1] < cx) -20 else 20), p[2] - 6, as.character(t$label %||% "Drone"), 10.5, ig_acc(th, 2), th$panel, 800, if (p[1] < cx) "end" else "start"), "</g>")
  }
  for (k in seq_len(K)) { p <- ig_polar(cx, cy, zmid(k), 315); out <- c(out, ig_circle(p[1], p[2], 10, ig_acc(th, k), th$panel, 2), ig_text(p[1], p[2] - 7, as.character(k), 11, ig_on(ig_acc(th, k)), 800, "middle")$svg) }
  # legend
  lx <- if (wide) cx + R + 34 else IG_M; ly <- if (wide) y + 10 else cy + R + 24; lw <- IG_W - IG_M - lx; yy <- ly
  for (k in seq_len(K)) {
    z <- zs[[k]]; lt <- ig_wrap(z$label, lw - 40, 14.5, TRUE, 1); tt <- ig_wrap(z$text, lw - 40, 12, FALSE, 3); tg <- ig_tag_chip(lx + 34, yy + 4, z$tag, th)
    out <- c(out, ig_circle(lx + 12, yy + 12, 11, ig_acc(th, k)), ig_text(lx + 12, yy + 5, as.character(k), 12, ig_on(ig_acc(th, k)), 800, "middle")$svg,
             ig_text(lx + 34, yy + 2, lt, 14.5, th$ink, 800)$svg, ig_text(lx + 34, yy + 22, tt, 12, th$muted, 400, lh = 15)$svg)
    h1 <- 26 + length(tt) * 15; if (tg$h > 0) { out <- c(out, ig_tag_chip(lx + 34, yy + 35 + length(tt) * 15, z$tag, th)$svg); h1 <- h1 + 22 }
    yy <- yy + h1 + 12
  }
  keyy <- yy + 2; k1 <- ig_wrap("Sensor node and its field of view", lw - 30, 11.5, FALSE, 2); k2y <- keyy + 8 + length(k1) * 14
  out <- c(out, ig_circle(lx + 12, keyy + 10, 8, ig_acc(th, 1)), ig_text(lx + 28, keyy + 2, k1, 11.5, th$muted, 600, lh = 14)$svg,
           ig_circle(lx + 12, k2y + 10, 8, ig_acc(th, 2)), ig_text(lx + 28, k2y + 2, "Incoming threat", 11.5, th$muted, 600)$svg)
  keyy <- k2y - 22
  list(svg = paste(out, collapse = ""), h = max(2 * R + 16, keyy + 46 - y))
}

# ---- requirements: must-have -> how it is met -> status --------------------------------------------
ig_block_requirements <- function(sec, th, y) {
  its <- ig_items(sec, 8); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  stacked <- IG_CW < 600; lw <- if (stacked) IG_CW - 50 else min(230, IG_CW * 0.34); tw <- if (stacked) IG_CW - 50 else IG_CW - lw - 70
  out <- character(0); yy <- y
  for (i in seq_len(n)) {
    it <- its[[i]]; st <- tolower(as.character(it$status %||% "met")); if (!st %in% names(IG_REQ_COL)) st <- "met"; col <- IG_REQ_COL[[st]]
    lt <- ig_wrap(it$label, lw - 6, 13.5, TRUE, 2); tt <- ig_wrap(it$text, tw - 4, 12, FALSE, 4); tg <- ig_tag_id(it$tag)
    hh <- if (stacked) 12 + length(lt) * 17.5 + 3 + length(tt) * 15.5 + 12 + (if (nzchar(tg)) 20 else 0) else max(46, 14 + max(length(lt) * 17.5, length(tt) * 15.5) + 8)
    cxs <- IG_M + 22; cys <- yy + (if (stacked) 20 else hh / 2)
    out <- c(out, "<g>", ig_rect(IG_M - 6, yy, IG_CW + 12, hh - 4, if (i %% 2 == 1) th$panel else "none", 10, if (i %% 2 == 1) th$panel_line else NULL, 1),
             if (st == "met") paste0(ig_circle(cxs, cys, 12, col), ig_icon("check", cxs, cys, 14, "#FFFFFF", sw = 2.6))
             else if (st == "partial") paste0(ig_ball(cxs, cys, 11.5, 0.5, col, th$panel))
             else if (st == "planned") paste0(ig_circle(cxs, cys, 12, th$panel, col, 2.2, ' stroke-dasharray="3 2.5"'), ig_icon("clock", cxs, cys, 13, col, sw = 2.2))
             else paste0(ig_circle(cxs, cys, 12, col), ig_icon("cross", cxs, cys, 12, "#FFFFFF", sw = 2.6)),
             ig_text(IG_M + 44, yy + (if (stacked) 8 else (hh - 4 - length(lt) * 17.5) / 2 + 1), lt, 13.5, th$ink, 800, lh = 17.5)$svg,
             if (stacked) ig_text(IG_M + 44, yy + 10 + length(lt) * 17.5, tt, 12, th$muted, 400, lh = 15.5)$svg else ig_text(IG_M + 44 + lw + 8, yy + (hh - 4 - length(tt) * 15.5) / 2 + 1, tt, 12, th$muted, 400, lh = 15.5)$svg,
             if (nzchar(tg)) (if (stacked) ig_tag_chip(IG_M + 44, yy + hh - 26, tg, th)$svg else ig_tag_chip(IG_W - IG_M - 2, yy + 4, tg, th, "end")$svg) else "", "</g>")
    yy <- yy + hh
  }
  lg <- character(0); xx <- IG_M
  for (s in names(IG_REQ_COL)) { lg <- c(lg, ig_circle(xx + 5, yy + 12, 5, IG_REQ_COL[[s]]), ig_text(xx + 15, yy + 5, IG_REQ_LABEL[[s]], 10.5, th$muted, 600)$svg); xx <- xx + 30 + nchar(IG_REQ_LABEL[[s]]) * 6 }
  list(svg = paste(c(out, lg), collapse = ""), h = yy - y + 22)
}

# ---- compare_matrix: options x criteria with rating balls (honest comparison) -----------------------------
ig_block_compare_matrix <- function(sec, th, y) {
  cols <- Filter(is.list, (sec$columns %||% list())[seq_len(min(4, length(sec$columns %||% list())))]); nc <- length(cols)
  rows <- ig_items(sec, 8); if (nc < 2 || length(rows) == 0) return(list(svg = "", h = 0))
  lw <- min(230, IG_CW * 0.3); cw <- (IG_CW - lw) / nc; out <- character(0)
  hdr <- 64; oursi <- which(vapply(cols, function(c) isTRUE(c$ours), logical(1)))
  has_txt <- any(vapply(rows, function(r) any(vapply(r$cells %||% list(), function(c) is.list(c) && nzchar(as.character(c$text %||% "")), logical(1))), logical(1)))
  rh <- if (has_txt) 58 else 42; body_h <- length(rows) * rh; out <- character(0)
  for (j in oursi) out <- c(out, ig_rect(IG_M + lw + (j - 1) * cw + 4, y, cw - 8, hdr + body_h + 6, ig_mix(ig_acc(th, 1), th$panel, 0.9), 14, ig_acc(th, 1), 2))
  for (j in seq_len(nc)) {
    c <- cols[[j]]; ours <- isTRUE(c$ours); x <- IG_M + lw + (j - 1) * cw; col <- if (ours) ig_acc(th, 1) else ig_mix(th$ink, th$panel, 0.35)
    lt <- ig_wrap(c$label, cw - 16, 12.5, TRUE, 2)
    out <- c(out, ig_icon(c$icon %||% (if (ours) "eye" else "radar"), x + cw / 2, y + 17, 20, col), ig_text(x + cw / 2, y + 32, lt, 12.5, if (ours) ig_acc(th, 1) else th$ink, 800, "middle", lh = 15)$svg)
  }
  yy <- y + hdr
  for (i in seq_along(rows)) {
    r <- rows[[i]]; cells <- r$cells %||% list()
    out <- c(out, "<g>", ig_tip(r, as.character(r$label %||% "")), if (i %% 2 == 0) ig_rect(IG_M - 4, yy, lw - 2, rh, th$panel, 8, NULL, 1, ' fill-opacity="0.65"') else "",
             ig_text(IG_M + 4, yy + (rh - length(ig_wrap(r$label, lw - 14, 12.5, TRUE, 3)) * 15.5) / 2, ig_wrap(r$label, lw - 14, 12.5, TRUE, 3), 12.5, th$ink, 700, lh = 15.5)$svg)
    for (j in seq_len(nc)) {
      cl <- if (j <= length(cells) && is.list(cells[[j]])) cells[[j]] else list(); ours <- isTRUE(cols[[j]]$ours); col <- if (ours) ig_acc(th, 1) else ig_mix(th$ink, th$panel, 0.25)
      sc <- min(4, max(0, ig_num(cl$score, 0))); x <- IG_M + lw + (j - 1) * cw + cw / 2; ty <- as.character(cl$text %||% "")
      cyb <- yy + (if (nzchar(ty)) 17 else rh / 2)
      out <- c(out, ig_ball(x, cyb, 11, sc / 4, col, th$panel), if (nzchar(ty)) ig_text(x, yy + 31, ig_wrap(ty, cw - 12, 10.5, FALSE, 2), 10.5, th$muted, 500, "middle", lh = 12.5)$svg else "")
    }
    out <- c(out, ig_marker(r, IG_W - IG_M + 4, yy + 8), "</g>"); yy <- yy + rh
  }
  lgx <- IG_M + lw; lgy <- yy + 12
  out <- c(out, ig_text(IG_M, lgy, "Rating:", 10.5, th$muted, 700)$svg)
  for (k in 0:4) out <- c(out, ig_ball(IG_M + 62 + k * 22, lgy + 7, 7, k / 4, th$muted, th$panel))
  out <- c(out, ig_text(IG_M + 62 + 5 * 22 + 2, lgy, "weak to strong. Ratings are the applicant's assessment unless a source is shown.", 10.5, th$muted, 400)$svg)
  list(svg = paste(out, collapse = ""), h = lgy + 24 - y)
}

# ---- readiness: TRL (or any 1-9 scale) per component against a required threshold ----------------------------
ig_block_readiness <- function(sec, th, y) {
  its <- ig_items(sec, 8); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  mx <- max(3, min(12, round(ig_num(sec$scale_max, 9)))); thr <- ig_num(sec$threshold, NA); unit <- as.character(sec$unit %||% "TRL")
  lw <- min(215, IG_CW * 0.36); bx <- IG_M + lw + 6; bw <- max(120, IG_CW - lw - 6 - 62); gap <- 3; sw <- (bw - (mx - 1) * gap) / mx; rowh <- 52; out <- character(0)
  top <- if (!is.na(thr)) 26 else 0; yy <- y + top
  if (!is.na(thr)) {
    xt <- bx + (thr - 1) * (sw + gap) - gap / 2; lab <- as.character(sec$threshold_label %||% sprintf("%s %d required", unit, round(thr)))
    out <- c(out, ig_line(xt, y + 18, xt, yy + n * rowh - 4, ig_acc(th, 2), 2, ' stroke-dasharray="5 4"'), ig_text(xt, y, lab, 11.5, ig_acc(th, 2), 800, "middle")$svg)
  }
  for (i in seq_len(n)) {
    it <- its[[i]]; tg <- ig_tag_id(it$tag); v <- ig_num(it$value, NA); ins <- tg == "insert" || is.na(v); ok <- !ins && (is.na(thr) || v >= thr)
    col <- if (ok) ig_acc(th, 1) else ig_acc(th, 3); ry <- yy + (i - 1) * rowh
    lt <- ig_wrap(it$label, lw - 8, 13.5, TRUE, 2); tt <- ig_wrap(it$text, lw - 8, 10.5, FALSE, 2)
    out <- c(out, "<g>", ig_tip(it, as.character(it$label %||% "")), ig_text(IG_M, ry + 2, lt, 13.5, th$ink, 700, lh = 16.5)$svg, ig_text(IG_M, ry + 4 + length(lt) * 16.5, tt, 10.5, th$muted, 400, lh = 13)$svg)
    for (k in seq_len(mx)) {
      x <- bx + (k - 1) * (sw + gap); on <- !ins && k <= round(v)
      out <- c(out, ig_rect(x, ry + 6, sw, 22, if (on) col else th$track, 4, if (ins) th$muted else NULL, 1.2, if (ins) ' fill-opacity="0.35" stroke-dasharray="3 2"' else ""))
    }
    out <- c(out, ig_text(IG_W - IG_M, ry + 5, if (ins) "?" else sprintf("%s %s", unit, if (v == round(v)) round(v) else v), 14, if (ins) th$muted else col, 800, "end")$svg)
    if (nzchar(tg)) out <- c(out, ig_tag_chip(IG_W - IG_M, ry + 28, tg, th, "end")$svg)
    out <- c(out, ig_marker(it, bx - 8, ry + 17), "</g>")
  }
  list(svg = paste(out, collapse = ""), h = top + n * rowh)
}

# ---- gauge_row: semicircle gauges with an optional target tick ------------------------------------------------
ig_block_gauge_row <- function(sec, th, y) {
  its <- ig_items(sec, 4); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  colw <- IG_CW / n; r <- min(78, (colw - 26) / 2); out <- character(0); hmax <- 0
  for (i in seq_len(n)) {
    it <- its[[i]]; cx <- IG_M + colw * (i - 0.5); col <- ig_acc(th, i); cy <- y + r + 8; tg <- ig_tag_id(it$tag)
    mx <- ig_num(it$max, 1); v <- ig_num(it$value, NA); ins <- tg == "insert" || is.na(v); frac <- if (ins) 0 else min(1, max(0, v / mx))
    r1 <- r; r0 <- r * 0.74; a0 <- pi; a1 <- pi + pi * frac
    out <- c(out, "<g>", ig_tip(it, as.character(it$label %||% "")), sprintf('<path d="%s" fill="%s"%s/>', ig_arc(cx, cy, r0, r1, pi, 2 * pi), th$track, if (ins) ' fill-opacity="0.5"' else ""))
    if (frac > 0.002) out <- c(out, sprintf('<path d="%s" fill="%s"/>', ig_arc(cx, cy, r0, r1, a0, min(a1, 2 * pi - 0.0001)), col))
    tgt <- ig_num(it$target, NA)
    if (!is.na(tgt)) { ta <- pi + pi * min(1, max(0, tgt / mx)); p0 <- c(cx + (r0 - 5) * cos(ta), cy + (r0 - 5) * sin(ta)); p1 <- c(cx + (r1 + 6) * cos(ta), cy + (r1 + 6) * sin(ta))
      out <- c(out, ig_line(p0[1], p0[2], p1[1], p1[2], th$ink, 3)) }
    vt <- if (ins) "[INSERT]" else as.character(it$display %||% it$value); fs <- min(28, max(12, (2 * r0 - 12) / (0.68 * max(3, nchar(vt)))))
    out <- c(out, ig_text(cx, cy - fs * 1.1, vt, fs, if (ins) th$muted else th$ink, 800, "middle")$svg)
    yy <- cy + 14; lt <- ig_wrap(it$label, colw - 20, 13.5, TRUE, 2); out <- c(out, ig_text(cx, yy, lt, 13.5, th$ink, 700, "middle", lh = 16.5)$svg); yy <- yy + length(lt) * 16.5 + 7
    nt <- ig_wrap(it$note, colw - 22, 11, FALSE, 4); out <- c(out, ig_text(cx, yy, nt, 11, th$muted, 400, "middle", lh = 14)$svg); yy <- yy + length(nt) * 14 + 4
    if (!is.na(tgt)) { out <- c(out, ig_text(cx, yy, sprintf("Target: %s (black tick)", as.character(it$target)), 10.5, th$ink, 700, "middle")$svg); yy <- yy + 17 }
    if (nzchar(tg)) { out <- c(out, ig_tag_chip(cx, yy, tg, th, "middle")$svg); yy <- yy + 22 }
    out <- c(out, ig_marker(it, cx + r + 6, y + 8), "</g>"); hmax <- max(hmax, yy - y)
  }
  list(svg = paste(out, collapse = ""), h = hmax + 4)
}

# ---- timeline: milestones along a track ----------------------------------------------------------------------------
ig_block_timeline <- function(sec, th, y) {
  its <- ig_items(sec, 7); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  st_of <- function(it) { s <- tolower(as.character(it$state %||% "planned")); if (s %in% c("done", "next", "planned")) s else "planned" }
  mark <- function(x, yv, it, i) {
    s <- st_of(it); col <- ig_acc(th, if (s == "next") 2 else 1)
    switch(s, done = paste0(ig_circle(x, yv, 12, col), ig_icon("check", x, yv, 14, ig_on(col), sw = 2.6)),
           `next` = paste0(ig_circle(x, yv, 17, "none", col, 2.4, ' stroke-opacity="0.45"'), ig_circle(x, yv, 12, col), ig_icon("flag", x, yv, 13, ig_on(col), sw = 2.2)),
           ig_circle(x, yv, 11, th$panel, th$muted, 2.2, ' stroke-dasharray="3 2.5"'))
  }
  out <- character(0)
  if (IG_CW >= 560) {
    colw <- IG_CW / n; ly <- y + 40; out <- c(out, ig_line(IG_M + colw / 2, ly, IG_M + colw * (n - 0.5), ly, th$track, 6))
    dn <- which(vapply(its, function(it) st_of(it) == "done", logical(1))); if (length(dn) > 0) out <- c(out, ig_line(IG_M + colw / 2, ly, IG_M + colw * (max(dn) - 0.5), ly, ig_acc(th, 1), 6))
    hmax <- 0
    for (i in seq_len(n)) {
      it <- its[[i]]; cx <- IG_M + colw * (i - 0.5); col <- ig_acc(th, if (st_of(it) == "next") 2 else 1)
      lt <- ig_wrap(it$label, colw - 14, 13.5, TRUE, 2); tt <- ig_wrap(it$text, colw - 16, 11.5, FALSE, 5); tg <- ig_tag_chip(cx, 0, it$tag, th, "middle")
      yy <- ly + 28
      out <- c(out, "<g>", ig_tip(it, as.character(it$label %||% "")), ig_text(cx, y + 4, as.character(it$date %||% ""), 13, col, 800, "middle")$svg, mark(cx, ly, it, i),
               ig_text(cx, yy, lt, 13.5, th$ink, 700, "middle", lh = 16.5)$svg, ig_text(cx, yy + 3 + length(lt) * 16.5, tt, 11.5, th$muted, 400, "middle", lh = 14.5)$svg)
      yy <- yy + 3 + length(lt) * 16.5 + length(tt) * 14.5
      if (tg$h > 0) { out <- c(out, ig_tag_chip(cx, yy + 4, it$tag, th, "middle")$svg); yy <- yy + 24 }
      out <- c(out, "</g>"); hmax <- max(hmax, yy - y)
    }
    return(list(svg = paste(out, collapse = ""), h = hmax + 6))
  }
  yy <- y
  for (i in seq_len(n)) {
    it <- its[[i]]; col <- ig_acc(th, if (st_of(it) == "next") 2 else 1)
    lt <- ig_wrap(paste0(it$date %||% "", if (nzchar(as.character(it$date %||% ""))) "  -  " else "", it$label %||% ""), IG_CW - 52, 13.5, TRUE, 2); tt <- ig_wrap(it$text, IG_CW - 52, 11.5, FALSE, 4); tg <- ig_tag_id(it$tag)
    hh <- 10 + length(lt) * 17 + length(tt) * 14.5 + (if (nzchar(tg)) 24 else 6) + 6
    if (i < n) out <- c(out, ig_line(IG_M + 14, yy + 14, IG_M + 14, yy + hh + 14, th$track, 4))
    out <- c(out, "<g>", mark(IG_M + 14, yy + 14, it, i), ig_text(IG_M + 40, yy + 3, lt, 13.5, col, 800, lh = 17)$svg, ig_text(IG_M + 40, yy + 5 + length(lt) * 17, tt, 11.5, th$muted, 400, lh = 14.5)$svg,
             if (nzchar(tg)) ig_tag_chip(IG_M + 40, yy + hh - 26, tg, th)$svg else "", "</g>")
    yy <- yy + hh
  }
  list(svg = paste(out, collapse = ""), h = yy - y)
}

IG_BLOCKS$flow <- ig_block_flow; IG_BLOCKS$layers <- ig_block_layers; IG_BLOCKS$radial_zones <- ig_block_radial_zones; IG_BLOCKS$requirements <- ig_block_requirements
IG_BLOCKS$compare_matrix <- ig_block_compare_matrix; IG_BLOCKS$readiness <- ig_block_readiness; IG_BLOCKS$gauge_row <- ig_block_gauge_row; IG_BLOCKS$timeline <- ig_block_timeline
