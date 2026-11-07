# R/utils_techdesign_matrix_render.R
# ============================================================
# MARKET MATRIX - SVG renderer (all geometry computed here)
# ============================================================
# Layout: column dendrogram on top, row dendrogram on the left, heatmap in the
# middle, category strips, labels, legends. Named branches are drawn as pills.
# Cells carry an evidence marker (verified / unverified / contradicted / judgment)
# and open an evidence panel on click.

TDM_RAMP <- grDevices::colorRamp(c("#F4F8FD", "#8DB8F4", "#2F6FE0", "#12285E"))
tdm_cell_fill <- function(score) {
  m <- TDM_RAMP(pmin(100, pmax(0, score)) / 100)
  grDevices::rgb(m[, 1], m[, 2], m[, 3], maxColorValue = 255)
}
TDM_STATUS_STYLE <- list(
  verified     = list(fill = "#16A34A", stroke = "#FFFFFF", label = "Sourced, quote found on the page"),
  unverified   = list(fill = "#F59E0B", stroke = "#FFFFFF", label = "Sourced, page not checked / not reachable / partial"),
  contradicted = list(fill = "#DC2626", stroke = "#FFFFFF", label = "Quote NOT found on the cited page"),
  judgment     = list(fill = "#FFFFFF", stroke = "#94A3B8", label = "Judgment (no source)")
)

TDM_SVG_CSS <- paste0(
  ".tdm-svg{font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif}",
  ".tdm-svg .tdm-title{font-size:22px;font-weight:700;fill:#0F172A}",
  ".tdm-svg .tdm-sub{font-size:12.5px;fill:#475569}",
  ".tdm-svg .tdm-val{font-size:11.5px}",
  ".tdm-svg .tdm-rl,.tdm-svg .tdm-cl{font-size:12px;cursor:pointer}",
  ".tdm-svg .tdm-pill text{font-size:9.6px;font-weight:700;fill:#0F172A}",
  ".tdm-svg .tdm-leg{font-size:11px;fill:#334155}",
  ".tdm-svg .tdm-legt{font-size:10.5px;font-weight:700;fill:#475569}",
  ".tdm-svg .tdm-foot{font-size:10.5px;fill:#B45309;font-style:italic}",
  ".tdm-svg .tdm-cell{cursor:pointer}"
)

tdm_text_w <- function(x, px = 6.2) nchar(x) * px

tdm_palette_for <- function(vals) {
  u <- unique(vals)
  setNames(TDM_PALETTE[((seq_along(u) - 1) %% length(TDM_PALETTE)) + 1], u)
}

# Draw one dendrogram. orient = "top" (columns) or "left" (rows).
# Returns list(svg, nodes) ; nodes = data.frame-like list for pill placement.
tdm_draw_tree <- function(tree, orient, pos, group_of, group_col, geom, names_map) {
  hmax <- if (tree$h > 0) tree$h else 1
  svg <- character(0); nodes <- list()
  to_xy <- function(cross, f) {
    if (orient == "top") c(cross, geom$base - f * geom$span) else c(geom$base - f * geom$span, cross)
  }
  seg <- function(a, b, col) {
    sprintf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.7" stroke-linecap="round"/>', td_num(a[1]), td_num(a[2]), td_num(b[1]), td_num(b[2]), col)
  }
  walk <- function(nd) {
    if (isTRUE(nd$leaf)) return(list(cross = pos[[nd$id]], f = 0))
    kids <- lapply(nd$children, walk)
    cp <- vapply(kids, function(k) k$cross, numeric(1))
    f <- nd$h / hmax
    grp <- unique(group_of[nd$leaves])
    col <- if (length(grp) == 1) group_col[[grp]] else "#8A99B0"
    for (k in kids) svg <<- c(svg, seg(to_xy(k$cross, k$f), to_xy(k$cross, f), col))
    svg <<- c(svg, seg(to_xy(min(cp), f), to_xy(max(cp), f), col))
    cross <- (min(cp) + max(cp)) / 2
    nodes[[length(nodes) + 1]] <<- list(sig = nd$sig, n = nd$n, h = nd$h, cross = cross, f = f,
                                        name = names_map[[nd$sig]] %||% "", xy = to_xy(cross, f))
    list(cross = cross, f = f)
  }
  walk(tree)
  list(svg = paste(svg, collapse = ""), nodes = nodes)
}

# Greedy, collision-free placement of the branch-name pills (largest branches first)
tdm_place_pills <- function(nodes, orient, bounds, placed = list()) {
  nodes <- Filter(function(z) nzchar(z$name), nodes)
  if (length(nodes) == 0) return(list(svg = "", placed = placed))
  ord <- order(-vapply(nodes, function(z) z$h, numeric(1)), -vapply(nodes, function(z) z$n, numeric(1)))
  svg <- character(0)
  for (k in ord) {
    z <- nodes[[k]]
    w <- tdm_text_w(z$name, 5.9) + 14; h <- 16
    if (orient == "top") { x1 <- z$xy[1] - w / 2; y1 <- z$xy[2] - h / 2 } else { x1 <- z$xy[1] + 3 - w; y1 <- z$xy[2] - h / 2 }
    x1 <- max(bounds$x0 + 2, min(x1, bounds$x1 - w - 2)); y1 <- max(bounds$y0 + 1, min(y1, bounds$y1 - h - 1))
    clash <- any(vapply(placed, function(p) !(x1 + w + 3 < p[1] || p[1] + p[3] + 3 < x1 || y1 + h + 2 < p[2] || p[2] + p[4] + 2 < y1), logical(1)))
    if (clash) next
    placed[[length(placed) + 1]] <- c(x1, y1, w, h)
    svg <- c(svg, sprintf('<g class="tdm-pill"><rect x="%s" y="%s" width="%s" height="%s" rx="8" fill="#FFFFFF" stroke="#64748B" stroke-width="1.1"/><text x="%s" y="%s" text-anchor="middle">%s</text></g>',
                          td_num(x1), td_num(y1), td_num(w), td_num(h), td_num(x1 + w / 2), td_num(y1 + h / 2 + 3.4), td_esc(z$name)))
  }
  list(svg = paste(svg, collapse = ""), placed = placed)
}

tdm_flow_chips <- function(items, cols, x, y, maxw, shape = "rect", lh = 20) {
  svg <- character(0); cx <- x; cy <- y
  for (i in seq_along(items)) {
    w <- tdm_text_w(items[i], 6.0) + 28
    if (cx + w > x + maxw && cx > x) { cx <- x; cy <- cy + lh }
    svg <- c(svg, sprintf('<rect x="%s" y="%s" width="12" height="12" rx="3" fill="%s"/><text class="tdm-leg" x="%s" y="%s">%s</text>',
                          td_num(cx), td_num(cy - 10), cols[[items[i]]], td_num(cx + 17), td_num(cy), td_esc(items[i])))
    cx <- cx + w
  }
  list(svg = paste(svg, collapse = ""), y = cy)
}

render_matrix <- function(d) {
  wid <- paste0("tdm", sample(10000:99999, 1), sample(10000:99999, 1))
  tr <- tdm_trees(d)
  rows_order <- tr$row$leaves; cols_order <- tr$col$leaves
  nr <- length(rows_order); nc <- length(cols_order)
  ri <- setNames(seq_len(nr), rows_order); ci <- setNames(seq_len(nc), cols_order)
  rlab <- setNames(d$rows$label, d$rows$id); clab <- setNames(d$cols$label, d$cols$id)
  rcls <- setNames(d$rows$class, d$rows$id); ccat <- setNames(d$cols$category, d$cols$id)
  rpal <- tdm_palette_for(d$rows$class); cpal <- tdm_palette_for(d$cols$category)

  CW <- if (nc <= 8) 78 else if (nc <= 12) 68 else 58
  CH <- if (nr <= 16) 34 else if (nr <= 26) 30 else 26
  left <- 16; TW <- 360; ROOT_OFF <- 135; TH <- 190
  xstrip <- left + TW + 4; x0 <- xstrip + 14
  ytree <- 92; ystrip <- ytree + TH + 4; y0 <- ystrip + 14
  y1 <- y0 + nr * CH
  xlab <- x0 + nc * CW + 10
  labw <- max(tdm_text_w(d$rows$label, 6.9)) + 8
  W <- max(xlab + labw + 16, 760)
  col_lab_h <- min(120, max(tdm_text_w(d$cols$label, 6.0)) * sin(40 * pi / 180) + 26)
  ylegend <- y1 + col_lab_h + 24

  # ---- trees
  rpos <- setNames(y0 + (seq_len(nr) - 0.5) * CH, rows_order)
  cpos <- setNames(x0 + (seq_len(nc) - 0.5) * CW, cols_order)
  rt <- tdm_draw_tree(tr$row, "left", as.list(rpos), rcls, rpal, list(base = left + TW - 4, span = TW - 4 - ROOT_OFF), d$row_names)
  ct <- tdm_draw_tree(tr$col, "top", as.list(cpos), ccat, cpal, list(base = ytree + TH, span = TH - 26), d$col_names)
  pc <- tdm_place_pills(ct$nodes, "top", list(x0 = left, x1 = W - 8, y0 = ytree - 2, y1 = ytree + TH), list())
  pr <- tdm_place_pills(rt$nodes, "left", list(x0 = 4, x1 = left + TW, y0 = y0 - 4, y1 = y1 + 2), pc$placed)

  # ---- strips and cells
  strips <- c(
    vapply(rows_order, function(id) sprintf('<rect x="%s" y="%s" width="10" height="%s" fill="%s"/>', td_num(xstrip), td_num(rpos[[id]] - CH / 2 + 1), td_num(CH - 2), rpal[[rcls[[id]]]]), character(1)),
    vapply(cols_order, function(id) sprintf('<rect x="%s" y="%s" width="%s" height="10" fill="%s"/>', td_num(cpos[[id]] - CW / 2 + 1), td_num(ystrip), td_num(CW - 2), cpal[[ccat[[id]]]]), character(1)))

  stat <- tdm_status(d$cells$confidence, d$cells$verified)
  key <- paste(d$cells$row, d$cells$col)
  cell_svg <- character(0)
  for (id_r in rows_order) for (id_c in cols_order) {
    k <- match(paste(id_r, id_c), key)
    sc <- if (is.na(k)) 0 else d$cells$score[k]
    st <- if (is.na(k)) "judgment" else stat[k]
    cx <- x0 + (ci[[id_c]] - 1) * CW; cy <- y0 + (ri[[id_r]] - 1) * CH
    sty <- TDM_STATUS_STYLE[[st]]
    tip <- sprintf("%s x %s: %d (%s)", rlab[[id_r]], clab[[id_c]], as.integer(sc), sty$label)
    mk <- if (st == "judgment") sprintf('<circle cx="%s" cy="%s" r="3.4" fill="#FFFFFF" fill-opacity="0.75" stroke="%s" stroke-width="1.3"/>', td_num(cx + CW - 9), td_num(cy + 9), sty$stroke)
          else sprintf('<circle cx="%s" cy="%s" r="3.8" fill="%s" stroke="#FFFFFF" stroke-width="1.2"/>', td_num(cx + CW - 9), td_num(cy + 9), sty$fill)
    cell_svg <- c(cell_svg, sprintf(
      '<g class="tdm-cell" data-r="%s" data-c="%s" tabindex="0"><title>%s</title><rect x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="#FFFFFF" stroke-width="1.5"/><text class="tdm-val" x="%s" y="%s" text-anchor="middle" fill="%s" font-weight="%s">%d</text>%s</g>',
      id_r, id_c, td_esc(tip), td_num(cx), td_num(cy), td_num(CW), td_num(CH), tdm_cell_fill(sc),
      td_num(cx + CW / 2), td_num(cy + CH / 2 + 4), if (sc >= 55) "#FFFFFF" else "#334155", if (sc >= 70) "700" else "400", as.integer(sc), mk))
  }

  # ---- labels
  rl <- vapply(rows_order, function(id) sprintf('<text class="tdm-rl" data-id="%s" x="%s" y="%s" fill="%s">%s</text>', id, td_num(xlab), td_num(rpos[[id]] + 4), rpal[[rcls[[id]]]], td_esc(rlab[[id]])), character(1))
  cl <- vapply(cols_order, function(id) sprintf('<text class="tdm-cl" data-id="%s" x="%s" y="%s" fill="%s" transform="rotate(40 %s %s)">%s</text>',
                                                id, td_num(cpos[[id]] - CW / 2 + 8), td_num(y1 + 16), cpal[[ccat[[id]]]], td_num(cpos[[id]] - CW / 2 + 8), td_num(y1 + 16), td_esc(clab[[id]])), character(1))

  # ---- legends
  gid <- paste0("g", wid)
  stops <- paste0(sprintf('<stop offset="%d%%" stop-color="%s"/>', c(0, 25, 50, 75, 100), tdm_cell_fill(c(0, 25, 50, 75, 100))), collapse = "")
  bar <- sprintf('<defs><linearGradient id="%s" x1="0" x2="1" y1="0" y2="0">%s</linearGradient></defs><text class="tdm-legt" x="%d" y="%s">Score (0-100)</text><rect x="%d" y="%s" width="190" height="12" fill="url(#%s)" stroke="#CBD5E1"/><text class="tdm-leg" x="%d" y="%s">0</text><text class="tdm-leg" x="%d" y="%s" text-anchor="end">100</text>',
                 gid, stops, left, td_num(ylegend), left, td_num(ylegend + 8), gid, left, td_num(ylegend + 34), left + 190, td_num(ylegend + 34))
  ev_x <- left + 230; ev <- character(0)
  ev <- c(ev, sprintf('<text class="tdm-legt" x="%d" y="%s">Evidence marker (top-right of each cell)</text>', ev_x, td_num(ylegend)))
  for (i in seq_along(TDM_STATUS_STYLE)) {
    s <- TDM_STATUS_STYLE[[i]]; yy <- ylegend + 16 + (i - 1) * 16
    ev <- c(ev, sprintf('<circle cx="%d" cy="%s" r="4" fill="%s" stroke="%s" stroke-width="1.3"/><text class="tdm-leg" x="%d" y="%s">%s</text>', ev_x + 5, td_num(yy - 3.5), s$fill, s$stroke, ev_x + 16, td_num(yy), td_esc(s$label)))
  }
  yl2 <- ylegend + 16 + length(TDM_STATUS_STYLE) * 16 + 14
  l1 <- tdm_flow_chips(unique(d$cols$category), cpal, left + 150, yl2, W - 2 * left - 150)
  l2 <- tdm_flow_chips(unique(d$rows$class), rpal, left + 150, l1$y + 22, W - 2 * left - 150)
  leg2 <- paste0(sprintf('<text class="tdm-legt" x="%d" y="%s">%s</text>', left, td_num(yl2), td_esc(td_trunc(d$meta$col_axis, 24))), l1$svg,
                 sprintf('<text class="tdm-legt" x="%d" y="%s">%s</text>', left, td_num(l1$y + 22), td_esc(td_trunc(d$meta$row_axis, 24))), l2$svg)

  cnt <- tdm_status_counts(d)
  foot <- sprintf("Evidence: %d verified, %d unverified, %d contradicted, %d judgment (no source) of %d cells.", cnt[["verified"]], cnt[["unverified"]], cnt[["contradicted"]], cnt[["judgment"]], sum(cnt))
  if (cnt[["judgment"]] > 0) foot <- paste0(foot, " Judgment cells are illustrative, not measured.")
  yfoot <- l2$y + 30
  H <- yfoot + 14

  sub <- td_wrap(d$meta$subtitle, floor((W - 2 * left) / 6.4), 2)
  head <- paste0(sprintf('<text class="tdm-title" x="%d" y="34">%s</text>', left, td_esc(d$meta$title)),
                 paste0(sprintf('<text class="tdm-sub" x="%d" y="%d">%s</text>', left, 56 + 16 * (seq_along(sub) - 1), td_esc(sub)), collapse = ""))

  svg_full <- paste0('<svg xmlns="http://www.w3.org/2000/svg" class="tdm-svg" viewBox="0 0 ', td_num(W), ' ', td_num(H), '" width="', td_num(W), '" height="', td_num(H),
                     '" style="max-width:100%;height:auto;"><style>', TDM_SVG_CSS, '</style><rect width="100%" height="100%" fill="#FFFFFF"/>',
                     head, ct$svg, rt$svg, paste(strips, collapse = ""), pc$svg, pr$svg, paste(cell_svg, collapse = ""),
                     paste(rl, collapse = ""), paste(cl, collapse = ""), bar, paste(ev, collapse = ""), leg2,
                     sprintf('<text class="tdm-foot" x="%d" y="%s">%s</text>', left, td_num(yfoot), td_esc(foot)), '</svg>')

  # ---- data for the evidence panel
  cells_js <- setNames(lapply(seq_len(nrow(d$cells)), function(i) list(
    s = d$cells$score[i], st = stat[i], metric = d$cells$metric[i], value = d$cells$value[i], as_of = d$cells$as_of[i],
    quote = d$cells$quote[i], why = d$cells$rationale[i], src = as.list(Filter(nzchar, trimws(strsplit(d$cells$source_ids[i], ",", fixed = TRUE)[[1]]))))), key)
  names(cells_js) <- paste0(d$cells$row, "|", d$cells$col)
  srcs_js <- setNames(lapply(seq_len(nrow(d$sources)), function(i) list(title = d$sources$title[i], publisher = d$sources$publisher[i], url = d$sources$url[i],
                                                                        found = d$sources$in_search_results[i], reach = d$sources$reachable[i])), d$sources$id)
  data_json <- as.character(jsonlite::toJSON(list(
    rows = setNames(lapply(d$rows$label, function(x) x), d$rows$id), cols = setNames(lapply(d$cols$label, function(x) x), d$cols$id),
    cells = cells_js, sources = srcs_js, rowOrder = as.list(rows_order), colOrder = as.list(cols_order)), auto_unbox = TRUE, null = "null"))
  data_json <- gsub("</", "<\\/", data_json, fixed = TRUE)

  # ---- sources list
  src_html <- ""
  if (nrow(d$sources) > 0) {
    used <- vapply(d$sources$id, function(s) sum(vapply(strsplit(d$cells$source_ids, ",", fixed = TRUE), function(x) s %in% trimws(x), logical(1))), integer(1))
    items <- vapply(seq_len(nrow(d$sources)), function(i) {
      s <- d$sources[i, ]
      link <- if (grepl("^https?://", s$url)) sprintf('<a href="%s" target="_blank" rel="noopener">%s</a>', td_esc(s$url), td_esc(if (nzchar(s$title)) s$title else s$url)) else td_esc(s$title)
      badges <- c(if (s$in_search_results == "yes") '<span class="tdm-b tdm-ok">returned by web search</span>' else if (s$in_search_results == "no") '<span class="tdm-b tdm-bad">NOT in the search results - treat with caution</span>',
                  if (s$reachable == "yes") '<span class="tdm-b tdm-ok">page fetched</span>' else if (s$reachable == "no") '<span class="tdm-b tdm-warn">page could not be fetched</span>')
      sprintf('<li><b>%s</b> %s%s %s <span class="tdm-n">cited by %d cell(s)</span></li>', td_esc(s$id), link, if (nzchar(s$publisher)) paste0(" - ", td_esc(s$publisher)) else "", paste(badges, collapse = " "), used[i])
    }, character(1))
    src_html <- paste0('<div class="td-section"><h4><i class="fa fa-book"></i> Sources (', nrow(d$sources), ')</h4><ul class="tdm-src">', paste(items, collapse = ""), '</ul></div>')
  }

  css <- paste0("<style>",
    "#", wid, " .tdm-wrap{overflow-x:auto}",
    "#", wid, ".tdm-focus .tdm-cell:not(.tdm-on){opacity:.22}",
    "#", wid, ".tdm-focus .tdm-rl:not(.tdm-on),#", wid, ".tdm-focus .tdm-cl:not(.tdm-on){opacity:.3}",
    "#", wid, " .tdm-b{display:inline-block;font-size:11px;border-radius:9px;padding:0 8px;margin-left:4px}",
    "#", wid, " .tdm-ok{background:#DCFCE7;color:#166534}#", wid, " .tdm-warn{background:#FEF3C7;color:#92400E}#", wid, " .tdm-bad{background:#FEE2E2;color:#991B1B}",
    "#", wid, " .tdm-n{color:#64748B;font-size:11px}#", wid, " .tdm-src li{margin:4px 0}",
    "#", wid, " .tdm-q{border-left:3px solid #CBD5E1;padding-left:8px;color:#475569;font-style:italic;margin:6px 0}",
    "</style>")

  html <- paste0(css, '<div class="td-card tdm-card" id="', wid, '">',
    '<div class="tdm-wrap">', svg_full, '</div>',
    '<div class="td-detail"><em>Hover a cell to highlight its row and column. Click a cell to see its evidence; click a label to rank that row or column.</em></div>',
    src_html, '</div>')

  js <- r"---(
(function() {
  var root = document.getElementById("__WID__"); if (!root) return;
  var D = __DATA__;
  var cells = root.querySelectorAll(".tdm-cell"), rls = root.querySelectorAll(".tdm-rl"), cls = root.querySelectorAll(".tdm-cl");
  var detail = root.querySelector(".td-detail");
  var STX = {verified: "verified (the quote was found on the cited page)", unverified: "sourced, but not verified (page not checked, not reachable, or partial support)", contradicted: "the quote was NOT found on the cited page", judgment: "judgment - no source"};
  function esc(s) { var d = document.createElement("div"); d.textContent = (s == null ? "" : s); return d.innerHTML; }
  function clear() { root.classList.remove("tdm-focus"); root.querySelectorAll(".tdm-on").forEach(function(n) { n.classList.remove("tdm-on"); }); }
  function focus(r, c) {
    root.classList.add("tdm-focus");
    cells.forEach(function(n) { n.classList.toggle("tdm-on", (r && n.getAttribute("data-r") === r) || (c && n.getAttribute("data-c") === c)); });
    rls.forEach(function(n) { n.classList.toggle("tdm-on", !!r && n.getAttribute("data-id") === r); });
    cls.forEach(function(n) { n.classList.toggle("tdm-on", !!c && n.getAttribute("data-id") === c); });
  }
  var sel = null;
  function restore() { if (sel) focus(sel.r, sel.c); else clear(); }
  function src(id) {
    var s = D.sources[id]; if (!s) return "";
    var a = /^https?:/.test(s.url || "") ? "<a href='" + esc(s.url) + "' target='_blank' rel='noopener'>" + esc(s.title || s.url) + "</a>" : esc(s.title);
    return "<li>" + esc(id) + ": " + a + (s.publisher ? " - " + esc(s.publisher) : "") + (s.found === "no" ? " <b style='color:#991B1B'>(not in the search results)</b>" : "") + "</li>";
  }
  function showCell(r, c) {
    var x = D.cells[r + "|" + c]; if (!x) return;
    var h = "<strong>" + esc(D.rows[r]) + " x " + esc(D.cols[c]) + "</strong> &nbsp; <span style='font-size:1.3em;font-weight:700'>" + x.s + "</span>/100";
    h += "<p><b>Evidence:</b> " + esc(STX[x.st] || x.st) + "</p>";
    if (x.metric) h += "<p><b>Metric:</b> " + esc(x.metric) + (x.value ? " = " + esc(x.value) : "") + (x.as_of ? " (" + esc(x.as_of) + ")" : "") + "</p>";
    if (x.quote) h += "<div class='tdm-q'>&ldquo;" + esc(x.quote) + "&rdquo;</div>";
    if (x.why) h += "<p><b>How the score was derived:</b> " + esc(x.why) + "</p>";
    if (x.src && x.src.length) h += "<p><b>Sources:</b></p><ul>" + x.src.map(src).join("") + "</ul>";
    detail.innerHTML = h;
  }
  function rank(kind, id) {
    var list = [];
    (kind === "r" ? D.colOrder : D.rowOrder).forEach(function(o) {
      var x = D.cells[(kind === "r" ? id + "|" + o : o + "|" + id)]; if (x) list.push({n: (kind === "r" ? D.cols[o] : D.rows[o]), s: x.s, st: x.st});
    });
    list.sort(function(a, b) { return b.s - a.s; });
    var h = "<strong>" + esc(kind === "r" ? D.rows[id] : D.cols[id]) + "</strong> - strongest links:<ol>";
    list.slice(0, 6).forEach(function(z) { h += "<li>" + esc(z.n) + ": <b>" + z.s + "</b> <span style='color:#64748B'>(" + esc(z.st) + ")</span></li>"; });
    detail.innerHTML = h + "</ol>";
  }
  cells.forEach(function(n) {
    var r = n.getAttribute("data-r"), c = n.getAttribute("data-c");
    n.addEventListener("mouseenter", function() { focus(r, c); });
    n.addEventListener("mouseleave", restore);
    n.addEventListener("click", function() { sel = (sel && sel.r === r && sel.c === c) ? null : {r: r, c: c}; if (sel) showCell(r, c); restore(); });
    n.addEventListener("keydown", function(ev) { if (ev.key === "Enter") n.dispatchEvent(new Event("click")); });
  });
  rls.forEach(function(n) { var id = n.getAttribute("data-id");
    n.addEventListener("mouseenter", function() { focus(id, null); }); n.addEventListener("mouseleave", restore);
    n.addEventListener("click", function() { sel = {r: id, c: null}; rank("r", id); restore(); }); });
  cls.forEach(function(n) { var id = n.getAttribute("data-id");
    n.addEventListener("mouseenter", function() { focus(null, id); }); n.addEventListener("mouseleave", restore);
    n.addEventListener("click", function() { sel = {r: null, c: id}; rank("c", id); restore(); }); });
})();
)---"
  js <- gsub("__WID__", wid, js, fixed = TRUE)
  js <- gsub("__DATA__", data_json, js, fixed = TRUE)
  htmltools::tagList(htmltools::HTML(html), htmltools::tags$script(htmltools::HTML(js)))
}
