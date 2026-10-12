# R/utils_techdesign_render.R
# ============================================================
# TECHNICAL DESIGNS - SVG diagram renderer
# ============================================================
# Claude only supplies entities and relationships. ALL geometry is computed
# here (lane columns / class tiers, box sizes from text, edge routing with
# spread ports), so boxes can never overlap by construction.
# Two layouts: "layered" (swimlane architectures) and "class" (UML).

TD_KIND_STYLE <- list(
  actor     = c(fill = "#FDEBD0", stroke = "#E67E22"),
  service   = c(fill = "#D6EAF8", stroke = "#2E86C1"),
  process   = c(fill = "#D1F2EB", stroke = "#17A589"),
  store     = c(fill = "#FCF3CF", stroke = "#B7950B"),
  queue     = c(fill = "#EBDEF0", stroke = "#8E44AD"),
  model     = c(fill = "#E8DAEF", stroke = "#6C3483"),
  gateway   = c(fill = "#D5F5E3", stroke = "#1E8449"),
  cache     = c(fill = "#FAE5D3", stroke = "#CA6F1E"),
  external  = c(fill = "#F2F3F4", stroke = "#7F8C8D"),
  monitor   = c(fill = "#FADBD8", stroke = "#CB4335"),
  class     = c(fill = "#EAF2F8", stroke = "#2874A6"),
  abstract  = c(fill = "#F4ECF7", stroke = "#7D3C98"),
  interface = c(fill = "#FEF9E7", stroke = "#B7950B")
)
TD_EDGE_STYLE <- list(
  data       = list(color = "#2C3E50", dash = "",        label = "Data flow"),
  control    = list(color = "#8E44AD", dash = "7,4",     label = "Control / trigger"),
  event      = list(color = "#E67E22", dash = "2,4",     label = "Event / message"),
  feedback   = list(color = "#C0392B", dash = "7,4",     label = "Feedback loop"),
  inherit    = list(color = "#34495E", dash = "",        label = "Inheritance"),
  implements = list(color = "#34495E", dash = "6,4",     label = "Implements"),
  composition= list(color = "#34495E", dash = "",        label = "Composition"),
  aggregation= list(color = "#34495E", dash = "",        label = "Aggregation"),
  uses       = list(color = "#34495E", dash = "",        label = "Uses"),
  creates    = list(color = "#1E8449", dash = "6,4",     label = "Creates"),
  notifies   = list(color = "#E67E22", dash = "6,4",     label = "Notifies")
)

td_esc <- function(x) htmltools::htmlEscape(as.character(x %||% ""))
td_num <- function(x) formatC(x, format = "f", digits = 1)
td_style <- function(kind) TD_KIND_STYLE[[kind]] %||% TD_KIND_STYLE$service
td_wrap <- function(text, width, max_lines = 4) {
  text <- td_clean(text)
  if (text == "") return(character(0))
  w <- strwrap(text, width = width)
  if (length(w) > max_lines) { w <- w[seq_len(max_lines)]; w[max_lines] <- paste0(sub("\\s+\\S*$", "", w[max_lines]), "...") }
  w
}
td_split_items <- function(x, sep = ";") {
  x <- td_clean(x)
  if (x == "") return(character(0))
  trimws(strsplit(x, sep, fixed = TRUE)[[1]])
}
td_trunc <- function(x, n) if (nchar(x) > n) paste0(substr(x, 1, n - 3), "...") else x

# ---- markers -----------------------------------------------------------
td_markers <- function(wid, kind) {
  mk <- function(id, color, body, w = 12, h = 12, refx = 11, refy = 6, vb = "0 0 12 12") {
    sprintf('<marker id="%s-%s" viewBox="%s" refX="%s" refY="%s" markerWidth="%s" markerHeight="%s" markerUnits="userSpaceOnUse" orient="auto">%s</marker>',
            wid, id, vb, refx, refy, w, h, body)
  }
  out <- character(0)
  if (kind == "layered") {
    for (t in TD_EDGE_TYPES_LAYERED) {
      col <- TD_EDGE_STYLE[[t]]$color
      out <- c(out, mk(paste0("a-", t), col, sprintf('<path d="M1,1 L11,6 L1,11 Z" fill="%s"/>', col)))
    }
  } else {
    out <- c(out,
      mk("tri", "#34495E", '<path d="M1,1 L13,7 L1,13 Z" fill="#ffffff" stroke="#34495E" stroke-width="1.4"/>', 14, 14, 13, 7, "0 0 14 14"),
      mk("open", "#34495E", '<path d="M1,1 L11,6 L1,11" fill="none" stroke="#34495E" stroke-width="1.5"/>'),
      mk("open-green", "#1E8449", '<path d="M1,1 L11,6 L1,11" fill="none" stroke="#1E8449" stroke-width="1.5"/>'),
      mk("open-orange", "#E67E22", '<path d="M1,1 L11,6 L1,11" fill="none" stroke="#E67E22" stroke-width="1.5"/>'),
      mk("dia-fill", "#34495E", '<path d="M1,7 L8,2 L15,7 L8,12 Z" fill="#34495E"/>', 16, 14, 1, 7, "0 0 16 14"),
      mk("dia-hollow", "#34495E", '<path d="M1,7 L8,2 L15,7 L8,12 Z" fill="#ffffff" stroke="#34495E" stroke-width="1.4"/>', 16, 14, 1, 7, "0 0 16 14")
    )
  }
  paste0("<defs>", paste(out, collapse = ""), "</defs>")
}

# ---- node shapes (layered) --------------------------------------------
td_node_svg <- function(comp, x, y, w, h, label_lines, tech_lines, wid) {
  st <- td_style(comp$kind)
  fill <- st[["fill"]]; stroke <- st[["stroke"]]
  k <- comp$kind
  body <- switch(k,
    store = sprintf('<path d="M0,9 A%s,9 0 0,1 %s,9 L%s,%s A%s,9 0 0,1 0,%s Z" fill="%s" stroke="%s" stroke-width="1.8"/><ellipse cx="%s" cy="9" rx="%s" ry="9" fill="%s" stroke="%s" stroke-width="1.8"/>',
                    w/2, w, w, h - 9, w/2, h - 9, fill, stroke, w/2, w/2, "#ffffff55", stroke),
    queue = sprintf('<rect width="%s" height="%s" rx="%s" fill="%s" stroke="%s" stroke-width="1.8"/><line x1="22" y1="7" x2="22" y2="%s" stroke="%s" stroke-opacity="0.45"/><line x1="%s" y1="7" x2="%s" y2="%s" stroke="%s" stroke-opacity="0.45"/>',
                    w, h, min(h/2, 26), fill, stroke, h - 7, stroke, w - 22, w - 22, h - 7, stroke),
    model = sprintf('<polygon points="18,0 %s,0 %s,%s %s,%s 18,%s 0,%s" fill="%s" stroke="%s" stroke-width="1.8"/>',
                    w - 18, w, h/2, w - 18, h, h, h/2, fill, stroke),
    gateway = sprintf('<polygon points="14,0 %s,0 %s,%s 0,%s" fill="%s" stroke="%s" stroke-width="1.8"/>', w, w - 14, h, h, fill, stroke),
    process = sprintf('<rect width="%s" height="%s" rx="3" fill="%s" stroke="%s" stroke-width="1.8"/><rect width="7" height="%s" rx="3" fill="%s"/>', w, h, fill, stroke, h, stroke),
    external = sprintf('<rect width="%s" height="%s" rx="6" fill="%s" stroke="%s" stroke-width="1.8" stroke-dasharray="6,4"/>', w, h, fill, stroke),
    actor = sprintf('<rect width="%s" height="%s" rx="12" fill="%s" stroke="%s" stroke-width="1.8"/><circle cx="%s" cy="15" r="4" fill="%s"/><path d="M%s,28 q0,-8 8,-8 q8,0 8,8 Z" fill="%s"/>',
                    w, h, fill, stroke, w - 20, stroke, w - 28, stroke),
    monitor = sprintf('<rect width="%s" height="%s" rx="8" fill="%s" stroke="%s" stroke-width="1.8"/><circle cx="%s" cy="14" r="4" fill="%s"/>', w, h, fill, stroke, w - 14, stroke),
    cache = sprintf('<rect width="%s" height="%s" rx="16" fill="%s" stroke="%s" stroke-width="1.8" stroke-dasharray="2,3"/>', w, h, fill, stroke),
    sprintf('<rect width="%s" height="%s" rx="10" fill="%s" stroke="%s" stroke-width="1.8"/>', w, h, fill, stroke)
  )
  top_pad <- if (k == "store") 14 else 0
  texts <- sprintf('<text x="%s" y="%s" text-anchor="middle" class="td-kind" fill="%s">%s</text>',
                   w/2, 14 + top_pad, stroke, toupper(k))
  ty <- 31 + top_pad
  for (ln in label_lines) {
    texts <- c(texts, sprintf('<text x="%s" y="%s" text-anchor="middle" class="td-label">%s</text>', w/2, ty, td_esc(ln)))
    ty <- ty + 15
  }
  ty <- ty + 1
  for (ln in tech_lines) {
    texts <- c(texts, sprintf('<text x="%s" y="%s" text-anchor="middle" class="td-tech">%s</text>', w/2, ty, td_esc(ln)))
    ty <- ty + 12.5
  }
  sprintf('<g class="td-node" data-id="%s" transform="translate(%s,%s)" tabindex="0"><title>%s</title>%s%s</g>',
          td_esc(comp$id), td_num(x), td_num(y), td_esc(td_clean(comp$description)), body, paste(texts, collapse = ""))
}

# cubic bezier midpoint
td_bez_mid <- function(p) {
  c(x = (p[1] + 3*p[3] + 3*p[5] + p[7]) / 8, y = (p[2] + 3*p[4] + 3*p[6] + p[8]) / 8)
}
td_edge_svg <- function(path_d, mid, e, wid, kind, marker_start = NULL, marker_end = NULL, extra_dash = NULL) {
  stl <- TD_EDGE_STYLE[[e$type]] %||% TD_EDGE_STYLE$data
  dash <- extra_dash %||% stl$dash
  lbl <- td_trunc(td_clean(e$label), 30)
  label_svg <- ""
  if (nchar(lbl) > 0) {
    tw <- nchar(lbl) * 5.5 + 10
    label_svg <- sprintf('<rect x="%s" y="%s" width="%s" height="15" rx="4" fill="#ffffff" fill-opacity="0.92" stroke="%s" stroke-opacity="0.25"/><text x="%s" y="%s" text-anchor="middle" class="td-elabel" fill="%s">%s</text>',
                         td_num(mid[["x"]] - tw/2), td_num(mid[["y"]] - 8), td_num(tw), stl$color,
                         td_num(mid[["x"]]), td_num(mid[["y"]] + 3), stl$color, td_esc(lbl))
  }
  sprintf('<g class="td-edge" data-from="%s" data-to="%s" data-type="%s"><path d="%s" fill="none" stroke="%s" stroke-width="1.8"%s%s%s/>%s</g>',
          td_esc(e$from), td_esc(e$to), td_esc(e$type), path_d, stl$color,
          if (nzchar(dash)) sprintf(' stroke-dasharray="%s"', dash) else "",
          if (!is.null(marker_end)) sprintf(' marker-end="url(#%s-%s)"', wid, marker_end) else "",
          if (!is.null(marker_start)) sprintf(' marker-start="url(#%s-%s)"', wid, marker_start) else "",
          label_svg)
}

# spread k of n ports along [lo, hi]
td_spread <- function(lo, hi, k, n) lo + (hi - lo) * (k) / (n + 1)

# Polyline with rounded corners. pts = matrix (n x 2). Returns SVG path d.
td_round_path <- function(pts, r = 10) {
  keep <- c(TRUE, rowSums(abs(diff(pts))) > 0.01)
  pts <- pts[keep, , drop = FALSE]
  if (nrow(pts) < 2) return(sprintf("M%s,%s", td_num(pts[1, 1]), td_num(pts[1, 2])))
  d <- sprintf("M%s,%s", td_num(pts[1, 1]), td_num(pts[1, 2]))
  if (nrow(pts) > 2) for (i in 2:(nrow(pts) - 1)) {
    prev <- pts[i - 1, ]; cur <- pts[i, ]; nxt <- pts[i + 1, ]
    v1 <- prev - cur; v2 <- nxt - cur
    l1 <- sqrt(sum(v1^2)); l2 <- sqrt(sum(v2^2)); rr <- min(r, l1 / 2, l2 / 2)
    if (rr < 1) { d <- paste0(d, sprintf(" L%s,%s", td_num(cur[1]), td_num(cur[2]))) }
    else {
      a <- cur + v1 / l1 * rr; b <- cur + v2 / l2 * rr
      d <- paste0(d, sprintf(" L%s,%s Q%s,%s %s,%s", td_num(a[1]), td_num(a[2]), td_num(cur[1]), td_num(cur[2]), td_num(b[1]), td_num(b[2])))
    }
  }
  paste0(d, sprintf(" L%s,%s", td_num(pts[nrow(pts), 1]), td_num(pts[nrow(pts), 2])))
}

# Order swimlanes left-to-right so non-feedback edges mostly point right
# (Eades-Lin-Smyth feedback-arc-set heuristic). The model's own order is kept
# unless this yields strictly fewer backward edges.
td_order_lanes <- function(lanes, comps, conns) {
  nl <- length(lanes)
  if (nl < 3) return(lanes)
  li <- function(id) match(comps$lane[match(id, comps$id)], lanes)
  use <- conns[conns$type %in% c("data", "event"), , drop = FALSE]
  w <- matrix(0, nl, nl)
  for (i in seq_len(nrow(use))) {
    a <- li(use$from[i]); b <- li(use$to[i])
    if (!is.na(a) && !is.na(b) && a != b) w[a, b] <- w[a, b] + 1
  }
  backward <- function(ord) { pos <- match(seq_len(nl), ord); sum(w[pos[row(w)] > pos[col(w)]]) }
  remaining <- seq_len(nl); s1 <- integer(0); s2 <- integer(0)
  while (length(remaining) > 0) {
    changed <- TRUE
    while (changed && length(remaining) > 0) {
      changed <- FALSE
      for (v in remaining) {
        if (sum(w[v, setdiff(remaining, v)]) == 0) { s2 <- c(v, s2); remaining <- setdiff(remaining, v); changed <- TRUE; break }
      }
      if (changed) next
      for (v in remaining) {
        if (sum(w[setdiff(remaining, v), v]) == 0) { s1 <- c(s1, v); remaining <- setdiff(remaining, v); changed <- TRUE; break }
      }
    }
    if (length(remaining) > 0) {
      sc <- vapply(remaining, function(v) sum(w[v, setdiff(remaining, v)]) - sum(w[setdiff(remaining, v), v]), numeric(1))
      v <- remaining[which.max(sc)]; s1 <- c(s1, v); remaining <- setdiff(remaining, v)
    }
  }
  new_ord <- c(s1, s2)
  if (backward(new_ord) < backward(seq_len(nl))) lanes[new_ord] else lanes
}

# ======================= LAYERED LAYOUT ==================================
td_layout_layered <- function(d, wid) {
  comps <- d$components; conns <- d$connections
  lanes <- td_order_lanes(unique(comps$lane), comps, conns)
  nl <- length(lanes)
  BW <- 192; LW <- 236; GAP <- 84; PADX <- 22; HEADER <- 38; VGAP <- 38; TOPPAD <- 22

  comps$lane_i <- match(comps$lane, lanes)
  comps$lines <- lapply(comps$label, function(l) td_wrap(l, 21, 3))
  comps$tech <- lapply(comps$technologies, function(t) td_wrap(gsub("\\s*,\\s*", ", ", t), 30, 2))
  comps$h <- vapply(seq_len(nrow(comps)), function(i) {
    14 + 17 + 15 * max(1, length(comps$lines[[i]])) + (if (length(comps$tech[[i]]) > 0) 4 + 12.5 * length(comps$tech[[i]]) else 0) + 10 +
      (if (comps$kind[i] == "store") 14 else 0)
  }, numeric(1))

  stack_h <- vapply(seq_len(nl), function(li) {
    idx <- which(comps$lane_i == li); sum(comps$h[idx]) + VGAP * (length(idx) - 1)
  }, numeric(1))
  maxh <- max(stack_h)
  comps$order_in_lane <- NA_integer_

  comps$x <- PADX + (comps$lane_i - 1) * (LW + GAP) + (LW - BW) / 2
  comps$y <- NA_real_
  for (li in seq_len(nl)) {
    idx <- which(comps$lane_i == li)
    y <- HEADER + TOPPAD + (maxh - stack_h[li]) / 2
    for (i in idx) { comps$y[i] <- y; y <- y + comps$h[i] + VGAP }
    comps$order_in_lane[idx] <- seq_along(idx)
  }
  comps$cy <- comps$y + comps$h / 2

  idx_of <- function(id) match(id, comps$id)
  conns$si <- idx_of(conns$from); conns$ti <- idx_of(conns$to)
  conns$ls <- comps$lane_i[conns$si]; conns$lt <- comps$lane_i[conns$ti]
  conns$mode <- ifelse(conns$ls < conns$lt, "fwd", ifelse(conns$ls > conns$lt, "back", "same"))

  # port offsets (fraction positions) -------------------------------
  port_pos <- function(key_vec, sort_vec) {
    pos <- numeric(length(key_vec)); n <- numeric(length(key_vec))
    for (k in unique(key_vec)) {
      ii <- which(key_vec == k); ii <- ii[order(sort_vec[ii])]
      for (j in seq_along(ii)) { pos[ii[j]] <- j; n[ii[j]] <- length(ii) }
    }
    list(pos = pos, n = n)
  }
  is_f <- conns$mode == "fwd"
  out_key <- ifelse(is_f, paste0("R", conns$si), paste0("x", seq_len(nrow(conns))))
  in_key  <- ifelse(is_f, paste0("L", conns$ti), paste0("y", seq_len(nrow(conns))))
  po <- port_pos(out_key, comps$cy[conns$ti]); pi <- port_pos(in_key, comps$cy[conns$si])

  n_back <- sum(conns$mode == "back" & abs(conns$ls - conns$lt) > 1)
  content_bottom <- HEADER + TOPPAD + maxh
  bottom_extra <- 40 + 20 * n_back
  H <- content_bottom + bottom_extra + 10
  W <- PADX * 2 + nl * LW + (nl - 1) * GAP

  svg <- character(0)
  # lane bands
  band_cols <- c("#F4F8FB", "#F9F6FB")
  for (li in seq_len(nl)) {
    lx <- PADX + (li - 1) * (LW + GAP)
    svg <- c(svg, sprintf('<rect x="%s" y="0" width="%s" height="%s" rx="14" fill="%s" stroke="#D5DBDB"/>',
                          lx, LW, content_bottom + 16, band_cols[(li %% 2) + 1]))
    svg <- c(svg, sprintf('<rect x="%s" y="0" width="%s" height="%s" rx="14" fill="#002C3C"/><rect x="%s" y="20" width="%s" height="%s" fill="#002C3C"/>',
                          lx, LW, HEADER, lx, LW, HEADER - 20))
    svg <- c(svg, sprintf('<text x="%s" y="%s" text-anchor="middle" class="td-lane">%s</text>',
                          lx + LW/2, HEADER/2 + 5, td_esc(td_trunc(lanes[li], 30))))
  }

  # edges
  back_k <- 0; same_loop_k <- 0; corr_k <- 0
  edge_svg <- character(0)
  for (e in seq_len(nrow(conns))) {
    S <- comps[conns$si[e], ]; T <- comps[conns$ti[e], ]
    ed <- conns[e, ]
    mode <- ed$mode
    pd_custom <- NULL
    if (mode == "fwd") {
      sx <- S$x + BW; sy <- S$y + 8 + td_spread(0, S$h - 16, po$pos[e], po$n[e])
      tx <- T$x;      ty <- T$y + 8 + td_spread(0, T$h - 16, pi$pos[e], pi$n[e])
      dx <- max(40, (tx - sx) * 0.5)
      p <- c(sx, sy, sx + dx, sy, tx - dx, ty, tx, ty)
    } else if (mode == "back") {
      back_k <- back_k + 1
      sx <- S$x; sy <- S$cy + (back_k %% 3 - 1) * 7
      tx <- T$x + BW; ty <- T$cy + (back_k %% 3 - 1) * 7
      if (abs(ed$ls - ed$lt) == 1) {
        dx <- max(30, (sx - tx) * 0.5)
        p <- c(sx, sy, sx - dx, sy, tx + dx, ty, tx, ty)
      } else {
        corr_k <- corr_k + 1
        by <- content_bottom + 22 + 20 * (corr_k - 1)
        gx1 <- sx - 30 - 5 * (corr_k %% 3); gx2 <- tx + 30 + 5 * (corr_k %% 3)
        pts <- rbind(c(sx, sy), c(gx1, sy), c(gx1, by), c(gx2, by), c(gx2, ty), c(tx, ty))
        pd_custom <- td_round_path(pts, 12)
        p <- c(gx1, by, gx1, by, gx2, by, gx2, by)
      }
    } else {
      adjacent <- abs(S$order_in_lane - T$order_in_lane) == 1
      if (adjacent) {
        sx <- S$x + BW / 2; tx <- T$x + BW / 2
        if (S$y < T$y) { sy <- S$y + S$h; ty <- T$y } else { sy <- S$y; ty <- T$y + T$h }
        p <- c(sx, sy, sx, (sy + ty) / 2, tx, (sy + ty) / 2, tx, ty)
      } else {
        same_loop_k <- same_loop_k + 1
        sx <- S$x + BW; tx <- T$x + BW; sy <- S$cy + 6; ty <- T$cy + 6
        off <- 44 + 12 * (same_loop_k %% 3)
        p <- c(sx, sy, sx + off, sy, tx + off, ty, tx, ty)
      }
    }
    pd <- sprintf("M%s,%s C%s,%s %s,%s %s,%s", td_num(p[1]), td_num(p[2]), td_num(p[3]), td_num(p[4]),
                  td_num(p[5]), td_num(p[6]), td_num(p[7]), td_num(p[8]))
    mid <- td_bez_mid(p)
    if (mode == "back" && abs(ed$ls - ed$lt) > 1) {
      pd <- pd_custom
      mid <- c(x = (p[1] + p[7]) / 2, y = p[2])
    }
    edge_svg <- c(edge_svg, td_edge_svg(pd, mid, ed, wid, "layered", marker_end = paste0("a-", ed$type)))
  }
  svg <- c(svg, edge_svg)

  for (i in seq_len(nrow(comps))) {
    svg <- c(svg, td_node_svg(comps[i, ], comps$x[i], comps$y[i], BW, comps$h[i], comps$lines[[i]], comps$tech[[i]], wid))
  }
  list(svg = paste(svg, collapse = "\n"), W = W, H = H)
}

# ======================= CLASS (UML) LAYOUT ==============================
td_class_node_svg <- function(comp, x, y, w, h, attrs, meths) {
  st <- td_style(comp$kind)
  stereotype <- switch(comp$kind, interface = "&#171;interface&#187;", abstract = "&#171;abstract&#187;", "")
  italic <- comp$kind %in% c("abstract", "interface")
  head_h <- if (nzchar(stereotype)) 40 else 28
  parts <- c(sprintf('<rect width="%s" height="%s" rx="4" fill="#ffffff" stroke="%s" stroke-width="1.8"/>', w, h, st[["stroke"]]),
             sprintf('<rect width="%s" height="%s" rx="4" fill="%s"/><rect y="%s" width="%s" height="6" fill="%s"/>', w, head_h, st[["fill"]], head_h - 6, w, st[["fill"]]),
             sprintf('<rect width="%s" height="%s" rx="4" fill="none" stroke="%s" stroke-width="1.8"/>', w, h, st[["stroke"]]))
  ty <- 18
  if (nzchar(stereotype)) {
    parts <- c(parts, sprintf('<text x="%s" y="14" text-anchor="middle" class="td-stereo">%s</text>', w/2, stereotype))
    ty <- 31
  }
  parts <- c(parts, sprintf('<text x="%s" y="%s" text-anchor="middle" class="td-cname%s">%s</text>', w/2, ty, if (italic) " td-ital" else "", td_esc(td_trunc(comp$label, 30))))
  y1 <- head_h
  parts <- c(parts, sprintf('<line x1="0" y1="%s" x2="%s" y2="%s" stroke="%s"/>', y1, w, y1, st[["stroke"]]))
  yy <- y1 + 15
  for (a in attrs) { parts <- c(parts, sprintf('<text x="10" y="%s" class="td-member">%s</text>', yy, td_esc(td_trunc(a, 40)))); yy <- yy + 15 }
  attr_h <- max(1, length(attrs)) * 15 + 8
  y2 <- y1 + attr_h
  parts <- c(parts, sprintf('<line x1="0" y1="%s" x2="%s" y2="%s" stroke="%s"/>', y2, w, y2, st[["stroke"]]))
  yy <- y2 + 15
  for (m in meths) { parts <- c(parts, sprintf('<text x="10" y="%s" class="td-member">%s</text>', yy, td_esc(td_trunc(m, 40)))); yy <- yy + 15 }
  sprintf('<g class="td-node" data-id="%s" transform="translate(%s,%s)" tabindex="0"><title>%s</title>%s</g>',
          td_esc(comp$id), td_num(x), td_num(y), td_esc(td_clean(comp$description)), paste(parts, collapse = ""))
}

td_layout_class <- function(d, wid) {
  comps <- d$components; conns <- d$connections
  tiers <- unique(comps$lane); nt <- length(tiers)
  PAD <- 30; COLGAP <- 90; ROWGAP <- 110

  comps$tier_i <- match(comps$lane, tiers)
  comps$attrs <- lapply(comps$attributes, td_split_items)
  comps$meths <- lapply(comps$methods, td_split_items)
  comps$w <- vapply(seq_len(nrow(comps)), function(i) {
    mx <- max(nchar(c(comps$label[i], comps$attrs[[i]], comps$meths[[i]])), 12)
    max(170, min(310, mx * 6.6 + 24))
  }, numeric(1))
  comps$head_h <- ifelse(comps$kind %in% c("interface", "abstract"), 40, 28)
  comps$h <- comps$head_h + (max(1, 1) * 0) +
    vapply(comps$attrs, function(a) max(1, length(a)) * 15 + 8, numeric(1)) +
    vapply(comps$meths, function(m) max(1, length(m)) * 15 + 8, numeric(1))

  row_w <- vapply(seq_len(nt), function(ti) { ii <- which(comps$tier_i == ti); sum(comps$w[ii]) + COLGAP * (length(ii) - 1) }, numeric(1))
  row_h <- vapply(seq_len(nt), function(ti) max(comps$h[comps$tier_i == ti]), numeric(1))
  W <- max(row_w) + PAD * 2
  comps$x <- NA_real_; comps$y <- NA_real_; comps$col_i <- NA_integer_
  y <- PAD + 24
  tier_y <- numeric(nt)
  for (ti in seq_len(nt)) {
    ii <- which(comps$tier_i == ti)
    x <- (W - row_w[ti]) / 2
    for (k in seq_along(ii)) { i <- ii[k]; comps$x[i] <- x; comps$y[i] <- y; comps$col_i[i] <- k; x <- x + comps$w[i] + COLGAP }
    tier_y[ti] <- y
    y <- y + row_h[ti] + ROWGAP
  }
  H <- y - ROWGAP + PAD + 20
  comps$cx <- comps$x + comps$w / 2; comps$cy <- comps$y + comps$h / 2

  idx_of <- function(id) match(id, comps$id)
  conns$si <- idx_of(conns$from); conns$ti <- idx_of(conns$to)
  conns$ts <- comps$tier_i[conns$si]; conns$tt <- comps$tier_i[conns$ti]
  conns$mode <- ifelse(conns$ts < conns$tt, "down", ifelse(conns$ts > conns$tt, "up", "side"))

  # ports: down edges leave S bottom, enter T top; up edges leave S top, enter T bottom
  keyS <- ifelse(conns$mode == "down", paste0("B", conns$si), ifelse(conns$mode == "up", paste0("T", conns$si), paste0("S", seq_len(nrow(conns)))))
  keyT <- ifelse(conns$mode == "down", paste0("T", conns$ti), ifelse(conns$mode == "up", paste0("B", conns$ti), paste0("E", seq_len(nrow(conns)))))
  port_pos <- function(key_vec, sort_vec) {
    pos <- numeric(length(key_vec)); n <- numeric(length(key_vec))
    for (k in unique(key_vec)) {
      ii <- which(key_vec == k); ii <- ii[order(sort_vec[ii])]
      for (j in seq_along(ii)) { pos[ii[j]] <- j; n[ii[j]] <- length(ii) }
    }
    list(pos = pos, n = n)
  }
  ps <- port_pos(keyS, comps$cx[conns$ti]); pt <- port_pos(keyT, comps$cx[conns$si])

  svg <- character(0); arc_k <- 0
  # tier captions
  for (ti in seq_len(nt)) {
    svg <- c(svg, sprintf('<text x="12" y="%s" class="td-tier">%s</text>', tier_y[ti] - 8, td_esc(toupper(tiers[ti]))))
    svg <- c(svg, sprintf('<line x1="10" y1="%s" x2="%s" y2="%s" stroke="#D5DBDB" stroke-dasharray="3,4"/>', tier_y[ti] - 3, W - 10, tier_y[ti] - 3))
  }
  for (e in seq_len(nrow(conns))) {
    ed <- conns[e, ]; S <- comps[ed$si, ]; T <- comps[ed$ti, ]
    if (ed$mode == "down") {
      sx <- td_spread(S$x, S$x + S$w, ps$pos[e], ps$n[e]); sy <- S$y + S$h
      tx <- td_spread(T$x, T$x + T$w, pt$pos[e], pt$n[e]); ty <- T$y
    } else if (ed$mode == "up") {
      sx <- td_spread(S$x, S$x + S$w, ps$pos[e], ps$n[e]); sy <- S$y
      tx <- td_spread(T$x, T$x + T$w, pt$pos[e], pt$n[e]); ty <- T$y + T$h
    } else {
      adj <- abs(S$col_i - T$col_i) == 1
      if (adj) {
        if (S$cx < T$cx) { sx <- S$x + S$w; tx <- T$x } else { sx <- S$x; tx <- T$x + T$w }
        sy <- S$cy; ty <- T$cy
      } else {
        arc_k <- arc_k + 1
        sx <- S$cx; tx <- T$cx; sy <- S$y; ty <- T$y
      }
    }
    pd_poly <- NULL
    tier_gap <- abs(S$tier_i - T$tier_i)
    if (ed$mode != "side" && tier_gap > 1) {
      lo <- min(S$tier_i, T$tier_i) + 1; hi <- max(S$tier_i, T$tier_i) - 1
      mid_boxes <- comps[comps$tier_i >= lo & comps$tier_i <= hi, , drop = FALSE]
      cand <- c(PAD / 2, W - PAD / 2)
      for (ti in lo:hi) {
        bb <- mid_boxes[mid_boxes$tier_i == ti, , drop = FALSE]
        bb <- bb[order(bb$x), , drop = FALSE]
        if (nrow(bb) > 1) for (k in seq_len(nrow(bb) - 1)) cand <- c(cand, (bb$x[k] + bb$w[k] + bb$x[k + 1]) / 2)
        cand <- c(cand, bb$x[1] - 25, bb$x[nrow(bb)] + bb$w[nrow(bb)] + 25)
      }
      ok <- vapply(cand, function(cx) !any(cx > mid_boxes$x - 12 & cx < mid_boxes$x + mid_boxes$w + 12) && cx > 5 && cx < W - 5, logical(1))
      cand <- cand[ok]
      gx <- if (length(cand) > 0) cand[which.min(abs(cand - (sx + tx) / 2))] else (W - 10)
      arc_k <- arc_k + 1
      off <- 7 * (arc_k %% 3)
      if (ed$mode == "down") {
        y1 <- tier_y[S$tier_i] + row_h[S$tier_i] + 26 + off; y2 <- tier_y[T$tier_i] - 26 - off
      } else {
        y1 <- tier_y[S$tier_i] - 26 - off; y2 <- tier_y[T$tier_i] + row_h[T$tier_i] + 26 + off
      }
      pts <- rbind(c(sx, sy), c(sx, y1), c(gx, y1), c(gx, y2), c(tx, y2), c(tx, ty))
      pd_poly <- td_round_path(pts, 12)
      p <- c(sx, sy, sx, sy, tx, ty, tx, ty)
      mid <- c(x = gx, y = y1 + (y2 - y1) * 0.12)
    } else if (ed$mode == "side" && !(abs(S$col_i - T$col_i) == 1)) {
      lift <- 46 + 14 * arc_k
      p <- c(sx, sy, sx, sy - lift, tx, ty - lift, tx, ty)
      mid <- c(x = (sx + tx) / 2, y = sy - lift * 0.75)
    } else {
      p <- c(sx, sy, sx, sy, tx, ty, tx, ty)
      # straight line expressed as cubic along the segment
      p <- c(sx, sy, sx + (tx - sx) / 3, sy + (ty - sy) / 3, sx + 2 * (tx - sx) / 3, sy + 2 * (ty - sy) / 3, tx, ty)
      mid <- td_bez_mid(p)
    }
    pd <- sprintf("M%s,%s C%s,%s %s,%s %s,%s", td_num(p[1]), td_num(p[2]), td_num(p[3]), td_num(p[4]), td_num(p[5]), td_num(p[6]), td_num(p[7]), td_num(p[8]))
    if (!is.null(pd_poly)) pd <- pd_poly
    t <- ed$type
    ms <- NULL; me <- NULL
    me <- switch(t, inherit = "tri", implements = "tri", creates = "open-green", notifies = "open-orange",
                 composition = NULL, aggregation = NULL, "open")
    ms <- switch(t, composition = "dia-fill", aggregation = "dia-hollow", NULL)
    svg <- c(svg, td_edge_svg(pd, mid, ed, wid, "class", marker_start = ms, marker_end = me))
  }
  for (i in seq_len(nrow(comps))) {
    svg <- c(svg, td_class_node_svg(comps[i, ], comps$x[i], comps$y[i], comps$w[i], comps$h[i], comps$attrs[[i]], comps$meths[[i]]))
  }
  list(svg = paste(svg, collapse = "\n"), W = W, H = H)
}

# ======================= FULL CARD =======================================
td_legend_html <- function(d) {
  kind <- d$meta$diagram_kind
  kinds <- unique(d$components$kind); etypes <- unique(d$connections$type)
  chips <- vapply(kinds, function(k) {
    st <- td_style(k)
    sprintf('<span class="td-chip"><span class="td-swatch" style="background:%s;border-color:%s"></span>%s</span>', st[["fill"]], st[["stroke"]], td_esc(k))
  }, character(1))
  lines <- vapply(etypes, function(t) {
    s <- TD_EDGE_STYLE[[t]] %||% TD_EDGE_STYLE$data
    sprintf('<span class="td-chip"><svg width="34" height="10"><line x1="1" y1="5" x2="33" y2="5" stroke="%s" stroke-width="2"%s/></svg>%s</span>',
            s$color, if (nzchar(s$dash)) sprintf(' stroke-dasharray="%s"', s$dash) else "", td_esc(s$label))
  }, character(1))
  paste0('<div class="td-legend"><strong>Legend</strong> ', paste(chips, collapse = ""), paste(lines, collapse = ""), '</div>')
}

td_list_html <- function(items, cls = "") {
  if (length(items) == 0) return("")
  paste0('<ul class="', cls, '">', paste0("<li>", td_esc(items), "</li>", collapse = ""), "</ul>")
}

# Self-contained SVG styling: html2canvas (used for the PDF/PPTX/JPEG export) serializes the
# <svg> on its own, so page stylesheets would be lost. These rules travel inside the SVG.
TD_SVG_CSS <- paste0(
  ".td-svg{font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif}",
  ".td-svg .td-lane{fill:#fff;font-size:13px;font-weight:700;letter-spacing:.3px}",
  ".td-svg .td-kind{font-size:8.5px;font-weight:700;letter-spacing:1.2px;opacity:.85}",
  ".td-svg .td-label{font-size:12.5px;font-weight:700;fill:#1B2631}",
  ".td-svg .td-tech{font-size:10.2px;fill:#566573;font-style:italic}",
  ".td-svg .td-elabel{font-size:10px;font-weight:600}",
  ".td-svg .td-tier{font-size:10px;font-weight:700;fill:#7B8794;letter-spacing:1.4px}",
  ".td-svg .td-cname{font-size:13px;font-weight:700;fill:#1B2631}",
  ".td-svg .td-ital{font-style:italic}",
  ".td-svg .td-stereo{font-size:10px;fill:#566573}",
  ".td-svg .td-member{font-size:11px;fill:#2C3E50;font-family:Consolas,'Courier New',monospace}"
)

render_techdesign <- function(d) {
  wid <- paste0("td", sample(10000:99999, 1), sample(10000:99999, 1))
  kind <- d$meta$diagram_kind
  lay <- if (identical(kind, "class")) td_layout_class(d, wid) else td_layout_layered(d, wid)

  svg_full <- sprintf('<svg xmlns="http://www.w3.org/2000/svg" class="td-svg" viewBox="0 0 %s %s" width="%s" height="%s" style="max-width:100%%;height:auto;"><style>%s</style>%s%s</svg>',
                      td_num(lay$W), td_num(lay$H), td_num(lay$W), td_num(lay$H), TD_SVG_CSS, td_markers(wid, if (identical(kind, "class")) "class" else "layered"), lay$svg)

  m <- d$meta
  comps <- d$components
  # ---- details data for JS
  data_list <- list(
    components = setNames(lapply(seq_len(nrow(comps)), function(i) as.list(comps[i, c("id", "label", "lane", "kind", "description", "technologies", "attributes", "methods")])), comps$id),
    edges = lapply(seq_len(nrow(d$connections)), function(i) as.list(d$connections[i, c("from", "to", "label", "type")]))
  )
  data_json <- as.character(jsonlite::toJSON(data_list, auto_unbox = TRUE))
  data_json <- gsub("</", "<\\/", data_json, fixed = TRUE)

  steps_html <- ""
  if (nrow(d$steps) > 0) {
    steps_html <- paste0(
      '<div class="td-section"><h4><i class="fa fa-play-circle"></i> Flow (click a step, or press Play)</h4>',
      '<div class="td-steps-controls"><button type="button" class="btn btn-xs btn-primary td-play">&#9654; Play</button> ',
      '<button type="button" class="btn btn-xs btn-default td-reset">Reset</button></div><ol class="td-steps">',
      paste0(sprintf('<li data-comps="%s"><span>%s</span></li>', td_esc(gsub("\\s+", "", d$steps$components)), td_esc(d$steps$text)), collapse = ""),
      '</ol></div>')
  }

  tr <- d$tradeoffs
  kind_label <- c(pro = "Advantages", con = "Drawbacks", risk = "Risks", cost = "Cost", scaling = "Scaling")
  trade_html <- ""
  if (nrow(tr) > 0) {
    cols <- vapply(unique(tr$kind), function(k) {
      its <- tr$text[tr$kind == k]
      sprintf('<div class="td-trade td-trade-%s"><h5>%s</h5>%s</div>', td_esc(k), td_esc(kind_label[[k]] %||% tools::toTitleCase(k)), td_list_html(its))
    }, character(1))
    trade_html <- paste0('<div class="td-section"><h4><i class="fa fa-balance-scale"></i> Trade-offs</h4><div class="td-trade-grid">', paste(cols, collapse = ""), '</div></div>')
  }

  refs <- d$references
  refs_html <- ""
  if (nrow(refs) > 0) {
    items <- vapply(seq_len(nrow(refs)), function(i) {
      t <- td_esc(refs$title[i]); a <- if (nzchar(refs$author[i])) paste0(" - ", td_esc(refs$author[i])) else ""
      if (nzchar(refs$url[i]) && grepl("^https?://", refs$url[i])) sprintf('<li><a href="%s" target="_blank" rel="noopener">%s</a>%s</li>', td_esc(refs$url[i]), t, a)
      else sprintf("<li>%s%s</li>", t, a)
    }, character(1))
    refs_html <- paste0('<div class="td-section"><h4><i class="fa fa-book"></i> References</h4><ul>', paste(items, collapse = ""), '</ul></div>')
  }

  tags_html <- ""
  if (nzchar(m$tags)) {
    tg <- trimws(strsplit(m$tags, ",", fixed = TRUE)[[1]])
    tags_html <- paste0('<div class="td-tags">', paste0('<span class="td-tag">', td_esc(tg), "</span>", collapse = ""), "</div>")
  }

  html <- paste0(
    '<div class="td-card" id="', wid, '">',
    '<div class="td-title">', td_esc(m$title),
    if (nzchar(m$variant)) paste0(' <span class="td-variant">', td_esc(m$variant), '</span>') else "",
    if (nzchar(m$complexity)) paste0(' <span class="td-complexity">Complexity: ', td_esc(m$complexity), '</span>') else "",
    '</div>', tags_html,
    if (nzchar(m$summary)) paste0('<p class="td-summary">', td_esc(m$summary), '</p>') else "",
    '<div class="td-svg-wrap">', svg_full, '</div>',
    td_legend_html(d),
    '<div class="td-detail"><em>Hover a box to highlight its connections. Click it to see details here.</em></div>',
    '<div class="td-two-col">',
    if (nzchar(m$when_to_use)) paste0('<div class="td-use"><h5><i class="fa fa-check-circle"></i> When to use</h5><p>', td_esc(m$when_to_use), '</p></div>') else "",
    if (nzchar(m$when_not_to_use)) paste0('<div class="td-avoid"><h5><i class="fa fa-times-circle"></i> When not to use</h5><p>', td_esc(m$when_not_to_use), '</p></div>') else "",
    '</div>',
    steps_html, trade_html, refs_html,
    '</div>')

  js <- r"---(
(function() {
  var root = document.getElementById("__WID__");
  if (!root) return;
  var DATA = __DATA__;
  var nodes = root.querySelectorAll(".td-node");
  var edges = root.querySelectorAll(".td-edge");
  var detail = root.querySelector(".td-detail");
  var timer = null, selected = null;

  function esc(s) { var d = document.createElement("div"); d.textContent = (s == null ? "" : s); return d.innerHTML; }
  function clearHL() {
    root.classList.remove("td-focus");
    nodes.forEach(function(n) { n.classList.remove("td-on"); });
    edges.forEach(function(e) { e.classList.remove("td-on"); });
  }
  function focusIds(ids, edgePred) {
    root.classList.add("td-focus");
    nodes.forEach(function(n) { n.classList.toggle("td-on", ids.indexOf(n.getAttribute("data-id")) >= 0); });
    edges.forEach(function(e) { e.classList.toggle("td-on", edgePred(e.getAttribute("data-from"), e.getAttribute("data-to"))); });
  }
  function focusNode(id) {
    var ids = [id];
    DATA.edges.forEach(function(e) { if (e.from === id && ids.indexOf(e.to) < 0) ids.push(e.to); if (e.to === id && ids.indexOf(e.from) < 0) ids.push(e.from); });
    focusIds(ids, function(f, t) { return f === id || t === id; });
  }
  function restore() { if (selected) focusNode(selected); else clearHL(); }
  function label(id) { var c = DATA.components[id]; return c ? c.label : id; }
  function showDetail(id) {
    var c = DATA.components[id]; if (!c) return;
    var h = "<strong>" + esc(c.label) + "</strong> <span class='td-kindtag'>" + esc(c.kind) + "</span> <span class='td-lanetag'>" + esc(c.lane) + "</span>";
    if (c.description) h += "<p>" + esc(c.description) + "</p>";
    if (c.technologies) h += "<p><b>Technologies:</b> " + esc(c.technologies) + "</p>";
    if (c.attributes) h += "<p><b>Attributes:</b> " + esc(c.attributes) + "</p>";
    if (c.methods) h += "<p><b>Methods:</b> " + esc(c.methods) + "</p>";
    var inc = DATA.edges.filter(function(e) { return e.to === id; }), out = DATA.edges.filter(function(e) { return e.from === id; });
    if (inc.length) h += "<p><b>Receives from:</b> " + inc.map(function(e) { return esc(label(e.from)) + (e.label ? " (" + esc(e.label) + ")" : ""); }).join("; ") + "</p>";
    if (out.length) h += "<p><b>Sends to:</b> " + out.map(function(e) { return esc(label(e.to)) + (e.label ? " (" + esc(e.label) + ")" : ""); }).join("; ") + "</p>";
    detail.innerHTML = h;
  }
  nodes.forEach(function(n) {
    var id = n.getAttribute("data-id");
    n.addEventListener("mouseenter", function() { if (!timer) focusNode(id); });
    n.addEventListener("mouseleave", function() { if (!timer) restore(); });
    n.addEventListener("click", function() { stop(); selected = (selected === id ? null : id); if (selected) { showDetail(id); } restore(); });
    n.addEventListener("keydown", function(ev) { if (ev.key === "Enter") n.dispatchEvent(new Event("click")); });
  });

  var lis = root.querySelectorAll(".td-steps li");
  function showStep(i) {
    lis.forEach(function(l, k) { l.classList.toggle("td-active", k === i); });
    var ids = (lis[i].getAttribute("data-comps") || "").split(",").filter(function(x) { return x; });
    focusIds(ids, function(f, t) { return ids.indexOf(f) >= 0 && ids.indexOf(t) >= 0; });
  }
  function stop() { if (timer) { clearInterval(timer); timer = null; } lis.forEach(function(l) { l.classList.remove("td-active"); }); }
  lis.forEach(function(l, i) { l.addEventListener("click", function() { stop(); selected = null; showStep(i); }); });
  var play = root.querySelector(".td-play"), reset = root.querySelector(".td-reset");
  if (play) play.addEventListener("click", function() {
    stop(); selected = null; var i = 0; showStep(0);
    timer = setInterval(function() { i++; if (i >= lis.length) { stop(); clearHL(); return; } showStep(i); }, 1900);
  });
  if (reset) reset.addEventListener("click", function() { stop(); selected = null; clearHL(); detail.innerHTML = "<em>Hover a box to highlight its connections. Click it to see details here.</em>"; });
})();
)---"
  js <- gsub("__WID__", wid, js, fixed = TRUE)
  js <- gsub("__DATA__", data_json, js, fixed = TRUE)

  htmltools::tagList(htmltools::HTML(html), htmltools::tags$script(htmltools::HTML(js)))
}
