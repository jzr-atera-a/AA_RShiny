# global.R - Serendipity: David Cleevely
# Shared helpers. First block reused verbatim from the Compelling Communication
# template so the design language stays identical; second block adds the
# viz-embedding helpers needed for the D3 interactive components.

library(shiny)
library(shinydashboard)

# ── Reused from the Compelling Communication template ─────────────────────
chapter_hero <- function(num, icon_emoji, title, subtitle, badges = character()) {
  badge_tags <- lapply(badges, function(b) span(class = "hero-badge", b))
  div(class = "chapter-hero",
      div(class = "hero-chapter-num", if (nzchar(as.character(num))) paste("Chapter", num) else "Cambridge University Press \u00b7 David Cleevely"),
      tags$h1(class = "hero-title", paste(icon_emoji, title)),
      tags$p(class = "hero-subtitle", subtitle),
      div(class = "badge-row", tagList(badge_tags)))
}

stats_row <- function(...) {
  stats <- list(...)
  cols  <- lapply(stats, function(s) {
    column(3, div(class = "stat-card",
                  span(class = "stat-value", s[[1]]),
                  span(class = "stat-label", s[[2]])))
  })
  fluidRow(tagList(cols))
}

timeline_strip <- function(...) {
  items <- list(...)
  cells <- lapply(seq_along(items), function(i) {
    it <- items[[i]]
    tags$div(class = "tl-cell",
      tags$div(class = "tl-num",   i),
      tags$div(class = "tl-label", it[[1]]),
      tags$div(class = "tl-desc",  it[[2]]))
  })
  div(class = "timeline-strip", tagList(cells))
}

algo_table <- function(headers, rows) {
  tags$table(class = "algo-table",
    tags$thead(tags$tr(lapply(headers, tags$th))),
    tags$tbody(lapply(rows, function(r) tags$tr(lapply(r, tags$td)))))
}

pull_quote <- function(text, source = NULL) {
  div(class = "pull-quote",
      tags$p(class = "pq-text", HTML(paste0("\u201c", text, "\u201d"))),
      if (!is.null(source)) tags$p(class = "pq-source", HTML(paste0("- ", source))))
}

insight_box <- function(title, ...) {
  div(class = "insight-box",
      tags$h5(class = "ib-title", title),
      ...)
}

fw <- function(heading, body_html) {
  div(class = "framework-card",
      tags$h5(heading),
      tags$p(HTML(body_html)))
}

tip_box     <- function(...) div(class = "tip-box",        ...)
success_box <- function(...) div(class = "success-box",    ...)
warn_box    <- function(...) div(class = "warn-box",       ...)
info_box    <- function(...) div(class = "info-box-plain", ...)

concept_card   <- function(title, body) fw(title, body)
app_card       <- function(title, body) fw(title, body)
sh             <- function(text) tags$p(style="font-size:11px;font-weight:800;color:#1a3a4a;text-transform:uppercase;letter-spacing:1.2px;border-bottom:2px solid #E8A020;padding-bottom:5px;margin:18px 0 10px;", text)
shg            <- function(text) tags$p(style="font-size:11px;font-weight:800;color:#1e5a5a;text-transform:uppercase;letter-spacing:1.2px;border-bottom:2px solid #27ae60;padding-bottom:5px;margin:18px 0 10px;", text)
metric_card    <- function(val, lbl) div(class="stat-card", span(class="stat-value", val), span(class="stat-label", lbl))
toc_item       <- function(num, text) div(style="display:flex;align-items:flex-start;padding:10px 14px;margin-bottom:6px;background:#f8fafc;border-radius:8px;border-left:4px solid #E8A020;", div(style="font-weight:800;color:#E8A020;margin-right:12px;min-width:20px;", num), div(style="font-size:13px;color:#2c3e50;", text))
example_pair   <- function(bad_label="\u274c Before", bad_text, good_label="\u2705 After", good_text) tagList(div(class="warn-box", tags$strong(bad_label), tags$br(), HTML(bad_text)), div(class="success-box", tags$strong(good_label), tags$br(), HTML(good_text)))
quote_block    <- function(text, attrib=NULL) pull_quote(text, attrib)
pct_bar        <- function(label, pct) div(class="pct-bar-wrap", div(class="pct-bar-label", span(label), span(paste0(pct,"%"))), div(class="pct-bar-track", div(class="pct-bar-fill", style=paste0("width:",pct,"%"))))
chapter_card   <- function(num, title, desc, tags_vec=NULL) div(class="chapter-card", div(class="ch-num", paste("Chapter",num)), div(class="ch-title", title), div(class="ch-desc", desc), if(!is.null(tags_vec)) div(class="ch-tags", lapply(tags_vec, function(t) span(class="topic-tag", t))))
hr_gold        <- function() tags$hr(style="border:none;border-top:1px solid #E8A020;opacity:.3;margin:18px 0;")
progress_bar_item <- pct_bar
timeline_entry <- function(number, title, detail) toc_item(number, tagList(tags$b(paste0(title, " - ")), detail))

# ── New: D3/JS visualisation embedding helpers ─────────────────────────────

# Wraps a <div id> canvas (+ optional controls above it, + optional caption
# below) that a JS component from www/js/interactive.js will render into.
viz_box <- function(id, height = 420, controls = NULL, caption = NULL) {
  div(class = "viz-box",
      if (!is.null(controls)) div(class = "viz-controls", controls),
      div(id = id, class = "viz-canvas", style = paste0("height:", height, "px;")),
      if (!is.null(caption)) div(class = "viz-caption", caption))
}

# Runs raw JS once the page has loaded (safe even though shinydashboard
# renders every tab's DOM up front and just hides inactive ones with CSS).
d3_init <- function(js) {
  tags$script(HTML(paste0(
    "(function(){function __run(){", js, "}",
    "if (document.readyState === 'complete') { __run(); } ",
    "else { window.addEventListener('load', __run); } })();"
  )))
}

# A colour-coded legend row under a network graph, e.g.
# viz_legend(c("Hub" = "#E8A020", "Bridge / weak tie" = "#1e5a5a"))
viz_legend <- function(pairs) {
  items <- lapply(names(pairs), function(nm) {
    span(class = "viz-legend-item",
         span(class = "viz-legend-swatch", style = paste0("background:", pairs[[nm]], ";")),
         nm)
  })
  div(class = "viz-legend", tagList(items))
}

# A single labelled range-slider control for use inside viz_box(controls=...)
viz_slider <- function(input_id, label, min = 0, max = 100, value = 50, oninput_js) {
  tags$label(
    label,
    tags$input(type = "range", id = input_id, min = min, max = max, value = value,
               oninput = oninput_js),
    tags$span(id = paste0(input_id, "-val"), class = "viz-readout", value)
  )
}
