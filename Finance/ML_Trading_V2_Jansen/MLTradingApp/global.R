# global.R
# Machine Learning for Algorithmic Trading — Stefan Jansen
# Shared helpers, color scheme, UI component builders

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(ggplot2)

# Enhanced color palette from app_3.R (CCAF teal/turquoise theme)
ml_colors <- list(
  primary = "#008A82",
  secondary = "#00A39A", 
  dark = "#002C3C",
  light = "#E8F6F5",
  accent1 = "#FF6B35",
  accent2 = "#F7931E",
  accent3 = "#7B68EE",
  accent4 = "#20B2AA",
  accent5 = "#FF69B4",
  success = "#28A745",
  warning = "#FFC107",
  danger = "#DC3545",
  info = "#17A2B8"
)

# Color palette generator
generate_palette <- function(n) {
  if (n <= 3) {
    return(c(ml_colors$primary, ml_colors$secondary, ml_colors$dark)[1:n])
  } else if (n <= 8) {
    return(c(ml_colors$primary, ml_colors$secondary, ml_colors$accent1, 
             ml_colors$accent2, ml_colors$accent3, ml_colors$accent4, 
             ml_colors$accent5, ml_colors$dark)[1:n])
  } else {
    return(rainbow(n, start = 0.1, end = 0.9))
  }
}

# ── UI helper: chapter hero banner ──────────────────────────────────────────
chapter_hero <- function(num, icon_emoji, title, subtitle, badges = character()) {
  badge_tags <- lapply(badges, function(b) span(class = "hero-badge", b))
  div(class = "chapter-hero",
      div(class = "hero-chapter-num", paste("Chapter", num)),
      tags$h1(class = "hero-title", paste(icon_emoji, title)),
      tags$p(class = "hero-subtitle", subtitle),
      div(class = "badge-row", tagList(badge_tags))
  )
}

# ── UI helper: stats row ────────────────────────────────────────────────────
stats_row <- function(...) {
  stats <- list(...)
  cols  <- lapply(stats, function(s) {
    column(3,
           div(class = "stat-card",
               span(class = "stat-value",  s[[1]]),
               span(class = "stat-label",  s[[2]])
           )
    )
  })
  fluidRow(tagList(cols))
}

# ── UI helper: info/tip boxes ───────────────────────────────────────────────
tip_box <- function(title, content) {
  div(class = "tip-box",
      HTML(paste0("<strong>💡 ", title, ":</strong> ", content))
  )
}

info_box <- function(content) {
  div(class = "info-box-plain", HTML(content))
}

framework_card <- function(title, content) {
  div(class = "framework-card",
      tags$h5(title),
      if(is.character(content)) tags$p(HTML(content)) else content
  )
}

# ── UI helper: Python code placeholder ─────────────────────────────────────
python_code_tab <- function() {
  div(class = "python-placeholder",
      div(class = "placeholder-icon", "🐍"),
      tags$h3("Python Code Lab - Coming Soon"),
      tags$p("This section will contain interactive Python code examples for testing the concepts covered in this chapter."),
      tags$ul(
        tags$li("Data processing and analysis"),
        tags$li("Machine learning model implementation"),
        tags$li("Backtesting strategies"),
        tags$li("Visualization examples")
      )
  )
}
