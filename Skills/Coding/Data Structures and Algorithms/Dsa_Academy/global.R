# global.R - DSA Interactive Academy
# Shared helpers, palette, and module loader
# Pattern mirrors Energy Trading Analytics Suite

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(plotly)
library(DT)

# ── Shared helpers ─────────────────────────────────────────────────────────────

# LeetCode difficulty badge
lc_badge <- function(level) {
  cls <- switch(level, Easy = "badge-easy", Medium = "badge-medium", Hard = "badge-hard", "badge-medium")
  tags$span(class = paste("lc-badge", cls), level)
}

# Problem row
prob_row <- function(num, title, level, url = NULL) {
  lbl <- if (!is.null(url)) tags$a(href = url, target = "_blank", title) else title
  tags$div(class = "prob-row",
    lc_badge(level),
    tags$span(class = "prob-num", paste0("#", num)),
    tags$span(class = "prob-title", lbl)
  )
}

# Complexity table (data.frame → styled table)
cplx_table <- function(df) {
  tags$div(class = "cplx-wrap",
    tags$table(class = "cplx-tbl",
      tags$thead(tags$tr(lapply(names(df), tags$th))),
      tags$tbody(lapply(seq_len(nrow(df)), function(i)
        tags$tr(lapply(as.list(df[i,]), tags$td))
      ))
    )
  )
}

# Code block (pre-formatted)
dsa_code <- function(txt) tags$div(class = "dsa-code", txt)

# Callout box
callout <- function(txt, type = "info") {
  tags$div(class = paste("callout", paste0("callout-", type)), HTML(txt))
}

# Topic hero banner
topic_hero <- function(icon_char, title, desc, pills = character(0)) {
  tags$div(class = "topic-hero",
    tags$div(class = "hero-icon", icon_char),
    tags$div(
      tags$h3(title),
      tags$p(desc),
      if (length(pills)) tags$div(lapply(pills, function(p) tags$span(class = "hero-pill", p)))
    )
  )
}

# References block
ref_block <- function(...) {
  items <- list(...)
  tags$div(class = "ref-block",
    tags$h6(HTML("&#128218; Academic References")),
    lapply(items, function(r) tags$div(class = "ref-item", r))
  )
}

# ── Load all modules ──────────────────────────────────────────────────────────
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

cat("✓ DSA Academy global config complete\n")
