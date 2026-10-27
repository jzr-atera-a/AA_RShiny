# =============================================================================
# plots.R \u2014 plotly builders. Every call is namespaced (plotly::, DT::) so no
# other attached package (for example httr, which also defines config) can
# mask them.
# =============================================================================

BASE_LAYOUT <- list(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "#F7F9FC",
                    font = list(family = "Source Sans 3, Segoe UI, Arial, sans-serif", color = "#1F2D3D", size = 13),
                    margin = list(l = 70, r = 24, t = 52, b = 60),
                    hoverlabel = list(font = list(family = "Source Sans 3, Segoe UI, Arial, sans-serif")))

lay <- function(p, ...) {
  do.call(plotly::layout, c(list(p), utils::modifyList(BASE_LAYOUT, list(...))))
}
fin <- function(p) {
  p <- plotly::event_register(p, "plotly_click")
  plotly::config(p, displaylogo = FALSE, responsive = TRUE,
                 modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d", "toggleSpikelines"))
}
ttl <- function(txt) list(text = txt, font = list(size = 15, color = "#0B2545"), x = 0.02, xanchor = "left")

plot_pages <- function(id, colour) {
  nums <- page_nums(id)
  wc <- vapply(page_texts(id), words_in, integer(1))
  p <- plotly::plot_ly(source = paste0("pages_", id), x = nums, y = wc, type = "bar",
                       marker = list(color = colour, line = list(width = 0)),
                       hovertemplate = "Page %{x}: %{y:,} words<extra></extra>")
  p <- lay(p, title = ttl("Words per printed page"), xaxis = list(title = "Printed page", dtick = 1),
           yaxis = list(title = "Words", gridcolor = "#E3E9F1"), bargap = 0.25)
  fin(p)
}

plot_keywords <- function(id, colour) {
  kw <- keyword_table(id, 14)
  kw$term <- factor(kw$term, levels = rev(kw$term))
  p <- plotly::plot_ly(source = paste0("kw_", id), data = kw, x = ~count, y = ~term, type = "bar",
                       orientation = "h", marker = list(color = colour),
                       hovertemplate = "%{y}: %{x} times (click to search)<extra></extra>")
  p <- lay(p, title = ttl("Most frequent content words (click a word to search it)"),
           xaxis = list(title = "Occurrences", gridcolor = "#E3E9F1"),
           yaxis = list(title = "", automargin = TRUE), margin = list(l = 130, r = 24, t = 52, b = 60))
  fin(p)
}

plot_sections <- function(id, colour) {
  st <- section_table(id)
  if (nrow(st) == 0) return(NULL)
  st$label <- paste0(st$title, " (p. ", st$page, ")")
  st$label <- factor(st$label, levels = rev(st$label))
  p <- plotly::plot_ly(source = paste0("sec_", id), data = st, x = ~words, y = ~label, type = "bar",
                       orientation = "h", marker = list(color = colour),
                       hovertemplate = "%{y}<br>%{x:,} words (click to open)<extra></extra>")
  p <- lay(p, title = ttl("Words from each section to the next (click to open it)"),
           xaxis = list(title = "Words", gridcolor = "#E3E9F1"),
           yaxis = list(title = "", automargin = TRUE), margin = list(l = 260, r = 24, t = 52, b = 60))
  fin(p)
}

plot_sentences <- function(id, colour) {
  s <- sentence_lengths(id)
  p <- plotly::plot_ly(x = s, type = "histogram", nbinsx = 25,
                       marker = list(color = colour, line = list(color = "#FFFFFF", width = 1)),
                       hovertemplate = "%{x} words: %{y} sentences<extra></extra>")
  p <- lay(p, title = ttl("Sentence length (words per sentence)"),
           xaxis = list(title = "Words per sentence"), yaxis = list(title = "Sentences", gridcolor = "#E3E9F1"))
  fin(p)
}

plot_cite_years <- function(id, colour) {
  ct <- citation_table(id)
  if (nrow(ct) == 0) return(NULL)
  yr <- as.data.frame(table(ct$year), stringsAsFactors = FALSE)
  names(yr) <- c("year", "count"); yr$year <- as.integer(yr$year)
  p <- plotly::plot_ly(data = yr, x = ~year, y = ~count, type = "bar", marker = list(color = colour),
                       hovertemplate = "%{x}: %{y} citations<extra></extra>")
  p <- lay(p, title = ttl("In-text citations by year"), xaxis = list(title = "Year", dtick = 1),
           yaxis = list(title = "Citations", gridcolor = "#E3E9F1"))
  fin(p)
}

plot_cite_authors <- function(id, colour) {
  ct <- citation_table(id)
  if (nrow(ct) == 0) return(NULL)
  tb <- head(sort(table(ct$author), decreasing = TRUE), 10)
  d <- data.frame(author = factor(names(tb), levels = rev(names(tb))), count = as.integer(tb))
  p <- plotly::plot_ly(data = d, x = ~count, y = ~author, type = "bar", orientation = "h",
                       marker = list(color = colour), hovertemplate = "%{y}: %{x}<extra></extra>")
  p <- lay(p, title = ttl("Most cited sources (first author or organisation)"),
           xaxis = list(title = "Citations", gridcolor = "#E3E9F1"),
           yaxis = list(title = "", automargin = TRUE), margin = list(l = 150, r = 24, t = 52, b = 60))
  fin(p)
}

plot_words_by_work <- function(works, term_colour_fn) {
  wd <- Filter(function(w) !is.na(w$words), works)
  d <- data.frame(label = vapply(wd, function(w) paste0(w$code, " \u00b7 ", w$short), character(1)),
                  term = vapply(wd, `[[`, character(1), "term"),
                  words = vapply(wd, `[[`, numeric(1), "words"), stringsAsFactors = FALSE)
  d$label <- factor(d$label, levels = rev(d$label))
  p <- plotly::plot_ly()
  for (k in unique(d$term)) {
    dd <- d[d$term == k, , drop = FALSE]
    p <- plotly::add_trace(p, data = dd, x = ~words, y = ~label, type = "bar", orientation = "h",
                           name = k, marker = list(color = term_colour_fn(k)),
                           hovertemplate = "%{y}<br>%{x:,} words<extra></extra>")
  }
  p <- lay(p, barmode = "overlay", xaxis = list(title = "Words (cover sheet)", gridcolor = "#E3E9F1"),
           yaxis = list(title = "", automargin = TRUE), legend = list(orientation = "h", y = -0.18),
           margin = list(l = 260, r = 24, t = 30, b = 70))
  fin(p)
}

plot_timeline <- function(works, term_colour_fn) {
  dated <- Filter(function(w) !is.na(w$hand_in), works)
  d <- data.frame(label = vapply(dated, function(w) paste0(w$code, " \u00b7 ", w$short), character(1)),
                  term = vapply(dated, `[[`, character(1), "term"),
                  hand_in = as.Date(vapply(dated, function(w) format(w$hand_in), character(1))),
                  pages = vapply(dated, `[[`, character(1), "pages_label"),
                  title = vapply(dated, `[[`, character(1), "title"), stringsAsFactors = FALSE)
  d$label <- factor(d$label, levels = rev(d$label))
  p <- plotly::plot_ly()
  for (k in unique(d$term)) {
    dd <- d[d$term == k, , drop = FALSE]
    p <- plotly::add_trace(p, data = dd, x = ~hand_in, y = ~label, type = "scatter", mode = "markers",
                           name = k, marker = list(size = 13, color = term_colour_fn(k)),
                           text = ~paste0(title, "<br>Hand-in: ", format(hand_in, "%d %b %Y"), "<br>Pages ", pages),
                           hoverinfo = "text")
  }
  p <- lay(p, xaxis = list(title = "Hand-in date", gridcolor = "#E3E9F1"),
           yaxis = list(title = "", automargin = TRUE, gridcolor = "#E3E9F1"),
           legend = list(orientation = "h", y = -0.2), margin = list(l = 260, r = 24, t = 30, b = 70))
  fin(p)
}

plot_term_pie <- function(works, term_colour_fn) {
  tt <- vapply(unique(vapply(works, `[[`, character(1), "term")), function(k) {
    sum(vapply(works[vapply(works, `[[`, character(1), "term") == k], function(w) if (is.na(w$words)) 0 else w$words, numeric(1)))
  }, numeric(1))
  d <- data.frame(term = names(tt), words = as.numeric(tt), stringsAsFactors = FALSE)
  p <- plotly::plot_ly(data = d, labels = ~term, values = ~words, type = "pie", hole = 0.5,
                       marker = list(colors = vapply(d$term, term_colour_fn, character(1))),
                       textinfo = "label+percent", hovertemplate = "%{label}: %{value:,} words<extra></extra>")
  p <- lay(p, title = ttl("Words by term (cover sheets)"), showlegend = FALSE)
  fin(p)
}

plot_heatmap <- function(m) {
  p <- plotly::plot_ly(z = m, x = colnames(m), y = rownames(m), type = "heatmap",
                       colorscale = list(c(0, "#EEF4FB"), c(0.5, "#2A6FB5"), c(1, "#0B2545")),
                       hovertemplate = "%{y} in %{x}: %{z:.1f} per 1000 words<extra></extra>",
                       colorbar = list(title = "per 1000 words"))
  p <- lay(p, title = ttl("Content words across the collection (per 1,000 words)"),
           xaxis = list(title = "Work", tickangle = -35), yaxis = list(title = "", automargin = TRUE, autorange = "reversed"),
           margin = list(l = 150, r = 24, t = 52, b = 90))
  fin(p)
}

plot_term_tracker <- function(tb, term_colour_fn) {
  tb$label <- paste0(tb$code)
  tb$label <- factor(tb$label, levels = rev(tb$label))
  p <- plotly::plot_ly(source = "tracker", data = tb, x = ~per1000, y = ~label, type = "bar", orientation = "h",
                       marker = list(color = vapply(tb$term_name, term_colour_fn, character(1))),
                       text = ~count, hovertemplate = "%{y}: %{x:.2f} per 1000 words (%{text} matches)<extra></extra>")
  p <- lay(p, title = ttl("Where the term appears (per 1,000 words)"),
           xaxis = list(title = "Matches per 1,000 words", gridcolor = "#E3E9F1"),
           yaxis = list(title = "", automargin = TRUE), margin = list(l = 150, r = 24, t = 52, b = 60))
  fin(p)
}

plot_term_pages <- function(tp, colour) {
  p <- plotly::plot_ly(data = tp, x = ~page, y = ~matches, type = "bar", marker = list(color = colour),
                       hovertemplate = "Page %{x}: %{y} matches<extra></extra>")
  p <- lay(p, title = ttl("Matches by printed page (this work)"), xaxis = list(title = "Printed page", dtick = 1),
           yaxis = list(title = "Matches", gridcolor = "#E3E9F1"))
  fin(p)
}

plot_compare <- function(pa, pb, labA, labB, colA, colB) {
  shared <- merge(pa[, c("term", "per1000")], pb[, c("term", "per1000")], by = "term", all = TRUE,
                  suffixes = c("_a", "_b"))
  shared[is.na(shared)] <- 0
  shared$score <- shared$per1000_a + shared$per1000_b
  shared <- head(shared[order(-shared$score), ], 15)
  shared$term <- factor(shared$term, levels = rev(shared$term))
  p <- plotly::plot_ly(data = shared, x = ~per1000_a, y = ~term, type = "bar", orientation = "h",
                       name = labA, marker = list(color = colA),
                       hovertemplate = paste0("%{y}: %{x:.1f} per 1000 (", labA, ")<extra></extra>"))
  p <- plotly::add_trace(p, data = shared, x = ~per1000_b, y = ~term, type = "bar", orientation = "h",
                         name = labB, marker = list(color = colB),
                         hovertemplate = paste0("%{y}: %{x:.1f} per 1000 (", labB, ")<extra></extra>"))
  p <- lay(p, barmode = "group", title = ttl("Content words compared (per 1,000 words)"),
           xaxis = list(title = "Per 1,000 words", gridcolor = "#E3E9F1"),
           yaxis = list(title = "", automargin = TRUE), legend = list(orientation = "h", y = -0.15),
           margin = list(l = 130, r = 24, t = 52, b = 70))
  fin(p)
}

plot_collection_citations <- function(cc, term_colour_fn) {
  if (is.null(cc) || nrow(cc) == 0) return(NULL)
  tb <- as.data.frame(table(cc$term_name, cc$year), stringsAsFactors = FALSE)
  names(tb) <- c("term", "year", "count"); tb$year <- as.integer(tb$year)
  tb <- tb[tb$count > 0, ]
  p <- plotly::plot_ly()
  for (k in unique(tb$term)) {
    dd <- tb[tb$term == k, , drop = FALSE]
    p <- plotly::add_trace(p, data = dd, x = ~year, y = ~count, type = "bar", name = k,
                           marker = list(color = term_colour_fn(k)),
                           hovertemplate = "%{x}: %{y} citations<extra>%{fullData.name}</extra>")
  }
  p <- lay(p, barmode = "stack", title = ttl("Citations by year across the collection"),
           xaxis = list(title = "Year cited", dtick = 1), yaxis = list(title = "Citations", gridcolor = "#E3E9F1"),
           legend = list(orientation = "h", y = -0.2))
  fin(p)
}

# ---- Insight charts ---------------------------------------------------------
ROLE_COL <- c(Recommendation = "#E8A020", Evidence = "#2A6FB5", Framework = "#2E9D6A",
              Reasoning = "#6C4F9E", Reflection = "#C0392B", Claim = "#CFD8DC")

empty_chart <- function(msg) {
  p <- plotly::plot_ly()
  p <- lay(p, title = ttl(msg), xaxis = list(visible = FALSE), yaxis = list(visible = FALSE))
  fin(p)
}

# What each page is doing: share of sentences that make a claim, give evidence, recommend, and so on
plot_argument_flow <- function(af) {
  if (is.null(af) || nrow(af) == 0 || sum(af$n) == 0) return(empty_chart("No sentences could be classified"))
  pages <- unique(af$page)
  lab <- paste0("p. ", pages)
  p <- plotly::plot_ly()
  for (r in names(ROLE_COL)) {
    d <- af[af$role == r, ]
    d <- d[match(pages, d$page), ]
    p <- plotly::add_trace(p, x = lab, y = ifelse(is.na(d$share), 0, d$share), type = "bar", name = r,
                           marker = list(color = ROLE_COL[[r]]),
                           hovertemplate = paste0(r, " on %{x}: %{y:.0f}% of sentences<extra></extra>"))
  }
  p <- lay(p, title = ttl("How each page is argued (share of sentences by role)"),
           barmode = "stack", bargap = 0.2,
           xaxis = list(title = "Printed page", categoryorder = "array", categoryarray = lab, tickangle = -35),
           yaxis = list(title = "Share of sentences (%)", range = c(0, 100), gridcolor = "#E3E9F1"),
           legend = list(orientation = "h", x = 0, y = 1.12), margin = list(l = 70, r = 24, t = 96, b = 80))
  fin(p)
}

# Distinctive concepts against printed pages: where each topic is developed
plot_concept_heat <- function(m) {
  if (is.null(m) || nrow(m) == 0) return(empty_chart("No distinctive concepts found"))
  p <- plotly::plot_ly(z = m, x = colnames(m), y = rownames(m), type = "heatmap",
                       colorscale = list(c(0, "#F3F7FB"), c(0.5, "#2A6FB5"), c(1, "#0B2545")),
                       hovertemplate = "%{y} on %{x}: %{z} mentions<extra></extra>",
                       colorbar = list(title = "mentions"))
  p <- lay(p, title = ttl("Where the distinctive concepts are developed"),
           xaxis = list(title = "Printed page", tickangle = -35),
           yaxis = list(title = "", automargin = TRUE, autorange = "reversed"),
           margin = list(l = 130, r = 24, t = 52, b = 90))
  fin(p)
}

# Organisations and people named most often
plot_actors <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(empty_chart("No named organisations or people found"))
  df <- df[order(df$count), ]
  df$name <- factor(df$name, levels = df$name)
  p <- plotly::plot_ly(source = NULL, data = df, x = ~count, y = ~name, type = "bar", orientation = "h",
                       marker = list(color = "#1D4E89"),
                       hovertemplate = "%{y}: named %{x} times<extra></extra>")
  p <- lay(p, title = ttl("Organisations and people named most often"),
           xaxis = list(title = "Mentions", gridcolor = "#E3E9F1"),
           yaxis = list(title = "", automargin = TRUE), margin = list(l = 160, r = 24, t = 52, b = 60))
  fin(p)
}
