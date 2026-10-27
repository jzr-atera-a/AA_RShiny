# =============================================================================
# Content insights: profile (who, for whom, what, when, where, why, how),
# headline figures, facts with printed pages, and charts built from the figures
# and positions each work states. One file per work: data/insights/<ID>.json
#
# Chart types drawn with plotly:  bar, grouped, donut, waterfall, diverging,
#                                 gantt, milestones, range
# Chart types drawn as HTML:      cards, steps, versus, table
# =============================================================================

uv <- function(x) if (is.null(x)) NULL else unlist(x, use.names = FALSE)
PLOTLY_TYPES <- c("bar", "grouped", "donut", "waterfall", "diverging", "gantt", "milestones", "range")
PAL <- c("#1a3a6a", "#E8A020", "#2E9D6A", "#C0392B", "#6C4F9E", "#2A6FB5", "#7f8c8d", "#d35400", "#16a085", "#8e44ad")

read_insights <- function(id, dir = file.path("data", "insights")) {
  p <- file.path(dir, paste0(id, ".json"))
  if (!file.exists(p)) return(NULL)
  jsonlite::fromJSON(p, simplifyVector = FALSE)
}

fmt_val <- function(v) vapply(v, function(x) {
  if (is.na(x)) return("")
  format(x, big.mark = ",", scientific = FALSE, drop0trailing = TRUE, trim = TRUE)
}, character(1))

val_text <- function(ch, vals) {
  if (!is.null(ch$text)) return(uv(ch$text))
  paste0(ifelse(vals < 0, "-", ""), ch$prefix %||% "", fmt_val(abs(vals)), ch$suffix %||% "")
}

ch_finish <- function(p, xlab = "", ylab = "", legend = TRUE, xaxis = list(), yaxis = list(), extra = list()) {
  base_x <- list(title = xlab, automargin = TRUE, gridcolor = "#eef2f6", zeroline = FALSE)
  base_y <- list(title = ylab, automargin = TRUE, gridcolor = "#eef2f6", zeroline = FALSE)
  args <- c(list(p,
                 font = list(family = "Nunito, Segoe UI, Arial, sans-serif", size = 12, color = "#2c3e50"),
                 paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
                 margin = list(l = 10, r = 30, t = 10, b = 10),
                 xaxis = utils::modifyList(base_x, xaxis), yaxis = utils::modifyList(base_y, yaxis),
                 showlegend = legend,
                 legend = list(orientation = "h", x = 0, y = 1.15, font = list(size = 11)),
                 hoverlabel = list(font = list(size = 12))), extra)
  p <- do.call(plotly::layout, args)
  plotly::config(p, displayModeBar = FALSE, responsive = TRUE)
}

b_bar <- function(ch) {
  labs <- uv(ch$labels); vals <- as.numeric(uv(ch$values)); txt <- val_text(ch, vals)
  cols <- if (!is.null(ch$colors)) uv(ch$colors) else rep(PAL[1], length(vals))
  if (isTRUE(ch$horizontal)) {
    p <- plotly::plot_ly(x = vals, y = factor(labs, levels = rev(labs)), type = "bar", orientation = "h",
                         marker = list(color = cols), text = txt, textposition = "outside", cliponaxis = FALSE,
                         hovertext = paste0(labs, ": ", txt), hoverinfo = "text")
    ch_finish(p, ch$xlab %||% "", "", legend = FALSE, xaxis = list(range = c(min(0, min(vals)), max(vals) * 1.25)))
  } else {
    p <- plotly::plot_ly(x = factor(labs, levels = labs), y = vals, type = "bar",
                         marker = list(color = cols), text = txt, textposition = "outside", cliponaxis = FALSE,
                         hovertext = paste0(labs, ": ", txt), hoverinfo = "text")
    ch_finish(p, "", ch$ylab %||% "", legend = FALSE, yaxis = list(range = c(min(0, min(vals)), max(vals) * 1.2)))
  }
}

b_grouped <- function(ch) {
  labs <- uv(ch$labels); horiz <- isTRUE(ch$horizontal)
  p <- plotly::plot_ly()
  for (s in seq_along(ch$series)) {
    se <- ch$series[[s]]; vals <- as.numeric(uv(se$values))
    txt <- if (!is.null(se$text)) uv(se$text) else paste0(ch$prefix %||% "", fmt_val(vals), ch$suffix %||% "")
    col <- se$color %||% PAL[(s - 1) %% length(PAL) + 1]
    if (horiz) {
      p <- plotly::add_trace(p, x = vals, y = factor(labs, levels = rev(labs)), type = "bar", orientation = "h",
                             name = se$name, marker = list(color = col), text = txt,
                             textposition = if (isTRUE(ch$stacked)) "inside" else "outside", cliponaxis = FALSE,
                             hovertext = paste0(se$name, " - ", labs, ": ", txt), hoverinfo = "text")
    } else {
      p <- plotly::add_trace(p, x = factor(labs, levels = labs), y = vals, type = "bar", name = se$name,
                             marker = list(color = col), text = txt,
                             textposition = if (isTRUE(ch$stacked)) "inside" else "outside", cliponaxis = FALSE,
                             hovertext = paste0(se$name, " - ", labs, ": ", txt), hoverinfo = "text")
    }
  }
  mode <- if (isTRUE(ch$stacked)) "relative" else "group"
  if (horiz) ch_finish(p, ch$xlab %||% "", "", extra = list(barmode = mode))
  else ch_finish(p, "", ch$ylab %||% "", extra = list(barmode = mode))
}

b_donut <- function(ch) {
  labs <- uv(ch$labels); vals <- as.numeric(uv(ch$values))
  cols <- if (!is.null(ch$colors)) uv(ch$colors) else PAL[(seq_along(vals) - 1) %% length(PAL) + 1]
  txt <- paste0(labs, ": ", ch$prefix %||% "", fmt_val(vals), ch$suffix %||% "")
  p <- plotly::plot_ly(labels = labs, values = vals, type = "pie", hole = 0.55, sort = FALSE,
                       marker = list(colors = cols, line = list(color = "#ffffff", width = 2)),
                       textinfo = "percent", hovertext = txt, hoverinfo = "text", textfont = list(color = "#ffffff"))
  ch_finish(p, legend = TRUE, extra = list(legend = list(orientation = "v", x = 1.02, y = 0.5, font = list(size = 11))))
}

b_waterfall <- function(ch) {
  labs <- uv(ch$labels); vals <- as.numeric(uv(ch$values)); meas <- uv(ch$measure)
  txt <- val_text(ch, vals)
  p <- plotly::plot_ly(type = "waterfall", x = factor(labs, levels = labs), y = vals, measure = meas,
                       text = txt, textposition = "outside", cliponaxis = FALSE, hovertext = paste0(labs, ": ", txt), hoverinfo = "text",
                       connector = list(line = list(color = "#b0bec5")),
                       increasing = list(marker = list(color = PAL[3])), decreasing = list(marker = list(color = PAL[4])),
                       totals = list(marker = list(color = PAL[1])))
  ch_finish(p, "", ch$ylab %||% "", legend = FALSE)
}

b_diverging <- function(ch) {
  labs <- uv(ch$labels); vals <- as.numeric(uv(ch$values))
  grp <- if (!is.null(ch$groups)) uv(ch$groups) else rep("", length(vals))
  cols <- ifelse(vals >= 0, PAL[3], PAL[4])
  if (!is.null(ch$colors)) cols <- uv(ch$colors)
  txt <- if (!is.null(ch$text)) uv(ch$text) else fmt_val(vals)
  p <- plotly::plot_ly(x = vals, y = factor(labs, levels = rev(labs)), type = "bar", orientation = "h",
                       marker = list(color = cols), text = txt, textposition = "outside", cliponaxis = FALSE,
                       hovertext = paste0(labs, if (any(nzchar(grp))) paste0(" (", grp, ")") else "", ": ", txt), hoverinfo = "text")
  xa <- list(zeroline = TRUE, zerolinecolor = "#546e7a", zerolinewidth = 2,
             range = c(min(vals, 0) - 0.9, max(vals, 0) + 0.9))
  if (!is.null(ch$xticks)) xa <- c(xa, list(tickvals = as.numeric(uv(ch$xticks$vals)), ticktext = uv(ch$xticks$text)))
  ch_finish(p, ch$xlab %||% "", "", legend = FALSE, xaxis = xa)
}

b_gantt <- function(ch) {
  it <- ch$items
  labs <- vapply(it, function(x) x$label, character(1))
  st <- vapply(it, function(x) as.numeric(x$start), numeric(1)); en <- vapply(it, function(x) as.numeric(x$end), numeric(1))
  grp <- vapply(it, function(x) x$group %||% "", character(1))
  gl <- unique(grp); cols <- PAL[(match(grp, gl) - 1) %% length(PAL) + 1]
  txt <- vapply(it, function(x) x$text %||% "", character(1))
  p <- plotly::plot_ly(x = en - st, base = st, y = factor(labs, levels = rev(labs)), type = "bar", orientation = "h",
                       marker = list(color = cols), text = txt, textposition = "inside", insidetextanchor = "start",
                       textfont = list(color = "#ffffff"),
                       hovertext = paste0(labs, " (", fmt_val(st), "-", fmt_val(en), ")", ifelse(nzchar(txt), paste0(": ", txt), "")),
                       hoverinfo = "text")
  ch_finish(p, ch$xlab %||% "", "", legend = FALSE)
}

b_milestones <- function(ch) {
  it <- ch$items
  yr <- vapply(it, function(x) as.numeric(x$year), numeric(1))
  lab <- vapply(it, function(x) x$label, character(1))
  shown <- vapply(it, function(x) x$when %||% as.character(x$year), character(1))
  o <- order(yr); yr <- yr[o]; lab <- lab[o]; shown <- shown[o]
  ys <- rep(c(1, -1), length.out = length(yr)) * rep(c(1, 1.8), each = 2, length.out = length(yr))
  wrap <- vapply(lab, function(s) paste(strwrap(s, 24), collapse = "<br>"), character(1))
  p <- plotly::plot_ly()
  for (k in seq_along(yr)) p <- plotly::add_segments(p, x = yr[k], xend = yr[k], y = 0, yend = ys[k],
                                                     line = list(color = "#b0bec5", width = 1), hoverinfo = "none", showlegend = FALSE)
  p <- plotly::add_trace(p, x = yr, y = rep(0, length(yr)), type = "scatter", mode = "markers",
                         marker = list(size = 13, color = PAL[2], line = list(color = PAL[1], width = 2)),
                         hovertext = paste0(shown, ": ", lab), hoverinfo = "text", showlegend = FALSE)
  p <- plotly::add_trace(p, x = yr, y = ys, type = "scatter", mode = "text",
                         text = paste0("<b>", shown, "</b><br>", wrap), textposition = ifelse(ys > 0, "top center", "bottom center"),
                         textfont = list(size = 11, color = "#2c3e50"), hoverinfo = "none", showlegend = FALSE)
  rng <- range(yr); pad <- max(1.5, diff(rng) * 0.14)
  ch_finish(p, "", "", legend = FALSE,
            xaxis = list(range = c(rng[1] - pad, rng[2] + pad), showgrid = FALSE, tickformat = "d", zeroline = FALSE),
            yaxis = list(range = c(-4.2, 4.2), visible = FALSE),
            extra = list(shapes = list(list(type = "line", x0 = rng[1] - pad, x1 = rng[2] + pad, y0 = 0, y1 = 0,
                                            line = list(color = PAL[1], width = 3)))))
}

b_range <- function(ch) {
  it <- ch$items
  labs <- vapply(it, function(x) x$label, character(1))
  lo <- vapply(it, function(x) as.numeric(x$low), numeric(1)); hi <- vapply(it, function(x) as.numeric(x$high), numeric(1))
  txt <- paste0(fmt_val(lo), "-", fmt_val(hi), ch$suffix %||% "")
  p <- plotly::plot_ly(x = hi - lo, base = lo, y = factor(labs, levels = rev(labs)), type = "bar", orientation = "h",
                       marker = list(color = PAL[2]), text = txt, textposition = "outside", cliponaxis = FALSE,
                       hovertext = paste0(labs, ": ", txt), hoverinfo = "text")
  ch_finish(p, ch$xlab %||% "", "", legend = FALSE, xaxis = list(range = c(0, max(hi) * 1.2)))
}

build_chart <- function(ch) {
  switch(ch$type,
         bar = b_bar(ch), grouped = b_grouped(ch), donut = b_donut(ch), waterfall = b_waterfall(ch),
         diverging = b_diverging(ch), gantt = b_gantt(ch), milestones = b_milestones(ch), range = b_range(ch),
         plotly::plotly_empty(type = "scatter", mode = "markers"))
}

# ---- HTML visuals -----------------------------------------------------------
html_chart <- function(ch) {
  if (ch$type == "cards") {
    return(div(class = paste("ins-cards", paste0("cols-", ch$cols %||% 2)),
               lapply(ch$items, function(it) div(class = "ins-card",
                 if (!is.null(it$tag)) span(class = paste("ins-tag", paste0("tag-", tolower(gsub("[^A-Za-z]", "", it$tag)))), it$tag),
                 tags$h5(it$title),
                 if (!is.null(it$text)) tags$p(it$text),
                 if (!is.null(it$items)) tags$ul(lapply(uv(it$items), tags$li))))))
  }
  if (ch$type == "steps") {
    return(div(class = "ins-steps",
               lapply(seq_along(ch$items), function(k) {
                 it <- ch$items[[k]]
                 div(class = "ins-step", div(class = "step-n", k),
                     div(class = "step-body", tags$h5(it$title), tags$p(it$text)))
               })))
  }
  if (ch$type == "versus") {
    side <- function(s, cls) div(class = paste("vs-side", cls), tags$h5(s$title), tags$ul(lapply(uv(s$items), tags$li)))
    return(div(class = "ins-versus", side(ch$left, "vs-left"), div(class = "vs-mid", ch$mid %||% "vs"), side(ch$right, "vs-right")))
  }
  if (ch$type == "table") {
    cols <- uv(ch$columns)
    return(tags$table(class = "algo-table",
                      tags$thead(tags$tr(lapply(cols, tags$th))),
                      tags$tbody(lapply(ch$rows, function(r) tags$tr(lapply(uv(r), tags$td))))))
  }
  div(class = "tip-box", "Unknown visual type")
}

chart_box <- function(id, k, ch) {
  is_plot <- ch$type %in% PLOTLY_TYPES
  div(class = paste("chart-box", if (isTRUE(ch$wide) || !is_plot || ch$type == "milestones") "chart-wide"),
      tags$h5(class = "cb-head", ch$title),
      if (!is.null(ch$subtitle)) tags$p(class = "cb-sub", ch$subtitle),
      if (is_plot) plotly::plotlyOutput(paste0("ich_", id, "_", k), height = paste0(ch$height %||% 320, "px")) else html_chart(ch),
      if (!is.null(ch$takeaway)) div(class = "takeaway", tags$strong("What it shows: "), ch$takeaway),
      if (!is.null(ch$source)) div(class = "cb-source", ch$source))
}

# ---- Profile and facts --------------------------------------------------------
PROFILE_ICONS <- c("Who" = "user", "For whom" = "users", "What" = "clipboard-list", "When" = "calendar-alt",
                   "Where" = "globe-europe", "Why" = "question-circle", "How" = "cogs")

profile_view <- function(ins) {
  if (is.null(ins$profile)) return(NULL)
  div(class = "profile-grid",
      lapply(ins$profile, function(x) div(class = "profile-card",
        div(class = "pc-q", icon(PROFILE_ICONS[[x$q]] %||% "circle"), " ", x$q),
        tags$p(x$a))))
}

facts_view <- function(ins) {
  if (is.null(ins$facts) || length(ins$facts) == 0) return(NULL)
  tags$table(class = "algo-table facts-table",
             tags$thead(tags$tr(tags$th("Fact"), tags$th("Figure"), tags$th("Printed page"))),
             tags$tbody(lapply(ins$facts, function(f)
               tags$tr(tags$td(f$what), tags$td(tags$strong(f$value)), tags$td(f$page %||% "")))))
}

headline_view <- function(ins) {
  hl <- ins$headline
  if (is.null(hl)) return(NULL)
  w <- max(3, floor(12 / length(hl)))
  fluidRow(lapply(hl, function(h) column(w, kpi(h$value, h$label))))
}

# ---- Collection-level charts built from the themes and audiences ------------
THEME_ORDER <- c("AI & digital", "Finance & investment", "Strategy & competition", "Sustainability & climate",
                 "Risk & regulation", "Leadership & teams", "Governance & ethics", "Operations & data",
                 "Real estate", "Health & social impact")

plot_theme_map <- function(ins_list, works) {
  labs <- vapply(works, function(w) paste0(w$code, " - ", w$short), character(1))
  z <- t(vapply(works, function(w) as.numeric(THEME_ORDER %in% uv(ins_list[[w$id]]$themes)), numeric(length(THEME_ORDER))))
  hover <- matrix(paste0(rep(labs, times = length(THEME_ORDER)), "<br>", rep(THEME_ORDER, each = length(labs)),
                         ifelse(as.vector(z) > 0, ": central theme", ": not a theme")), nrow = length(labs))
  p <- plotly::plot_ly(x = THEME_ORDER, y = labs, z = z, type = "heatmap",
                       colorscale = list(c(0, "#eef2f6"), c(1, "#1a3a6a")), showscale = FALSE,
                       xgap = 4, ygap = 4, hovertext = hover, hoverinfo = "text")
  ch_finish(p, legend = FALSE, xaxis = list(side = "top", tickangle = -25, showgrid = FALSE, tickfont = list(size = 12)),
            yaxis = list(showgrid = FALSE, autorange = "reversed", tickfont = list(size = 11.5)),
            extra = list(margin = list(l = 10, r = 10, t = 110, b = 10)))
}

plot_theme_counts <- function(ins_list, works, terms, term_col) {
  p <- plotly::plot_ly()
  for (t in terms) {
    ws <- Filter(function(w) w$term == t$key, works)
    n <- vapply(THEME_ORDER, function(th) sum(vapply(ws, function(w) th %in% uv(ins_list[[w$id]]$themes), logical(1))), numeric(1))
    p <- plotly::add_trace(p, x = n, y = factor(THEME_ORDER, levels = rev(THEME_ORDER)), type = "bar", orientation = "h",
                           name = t$label, marker = list(color = term_col(t$key)),
                           hovertext = paste0(t$label, " - ", THEME_ORDER, ": ", n, " works"), hoverinfo = "text")
  }
  ch_finish(p, "Number of works", "", extra = list(barmode = "stack"))
}

plot_term_themes <- function(ins_list, works, colr) {
  n <- vapply(THEME_ORDER, function(th) sum(vapply(works, function(w) th %in% uv(ins_list[[w$id]]$themes), logical(1))), numeric(1))
  keep <- n > 0
  b_bar(list(labels = THEME_ORDER[keep][order(-n[keep])], values = sort(n[keep], decreasing = TRUE), horizontal = TRUE,
             colors = rep(colr, sum(keep)), suffix = " works", xlab = "Works addressing the theme"))
}

plot_audience <- function(ins_list, works) {
  a <- vapply(works, function(w) ins_list[[w$id]]$audience %||% "Other", character(1))
  tb <- sort(table(a), decreasing = TRUE)
  b_bar(list(labels = names(tb), values = as.numeric(tb), horizontal = TRUE,
             colors = PAL[seq_along(tb)], suffix = " works", xlab = "Number of works"))
}

compare_profiles <- function(ins_list, works_by_id, a, b) {
  pa <- ins_list[[a]]$profile; pb <- ins_list[[b]]$profile
  qs <- vapply(pa, function(x) x$q, character(1))
  get <- function(p, q) { for (x in p) if (x$q == q) return(x$a); "" }
  tags$table(class = "algo-table compare-table",
             tags$thead(tags$tr(tags$th(""), tags$th(works_by_id[[a]]$code), tags$th(works_by_id[[b]]$code))),
             tags$tbody(lapply(qs, function(q) tags$tr(tags$td(tags$strong(q)), tags$td(get(pa, q)), tags$td(get(pb, q))))))
}

all_facts_table <- function(ins_list, works) {
  rows <- list()
  for (w in works) {
    ins <- ins_list[[w$id]]
    if (is.null(ins$facts)) next
    for (f in ins$facts) rows[[length(rows) + 1]] <- data.frame(
      Work = paste0(w$code, " - ", w$short), Fact = f$what, Figure = f$value,
      Page = as.character(f$page %||% ""), stringsAsFactors = FALSE)
  }
  do.call(rbind, rows)
}
