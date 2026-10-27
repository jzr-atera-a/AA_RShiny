# =============================================================================
# Analysis tab: paraphrased discussion, critical reading and course links.
# One file per work in data/analysis/<ID>.txt, in this format:
#   @OVERVIEW            paragraph(s) describing what the work does
#   @BLOCK heading|label paragraph(s) for one part of the analysis
#   @CRITIQUE            paragraph(s) assessing the strength of the work
#   @LINKS               paragraph(s) connecting the work to course material
# Lines starting with @ are tags; every other non-blank line is a paragraph.
# =============================================================================

read_analysis <- function(id, dir = file.path("data", "analysis")) {
  out <- list(overview = character(0), blocks = list(), critique = character(0), links = character(0))
  path <- file.path(dir, paste0(id, ".txt"))
  if (!file.exists(path)) return(out)
  lines <- enc2utf8(readLines(path, warn = FALSE, encoding = "UTF-8"))
  recs <- list()
  for (ln in lines) {
    t <- trimws(ln)
    if (!nzchar(t)) next
    if (grepl("^@(OVERVIEW|CRITIQUE|LINKS)$", t) || grepl("^@BLOCK ", t)) {
      rec <- list(tag = sub("^@([A-Z]+).*", "\\1", t), head = "", label = "", paras = character(0))
      if (rec$tag == "BLOCK") {
        parts <- strsplit(sub("^@BLOCK ", "", t), "|", fixed = TRUE)[[1]]
        rec$head <- trimws(parts[1])
        rec$label <- if (length(parts) > 1) trimws(parts[2]) else ""
      }
      recs[[length(recs) + 1]] <- rec
    } else if (length(recs) > 0) {
      n <- length(recs)
      recs[[n]]$paras <- c(recs[[n]]$paras, t)
    }
  }
  for (r in recs) {
    if (r$tag == "OVERVIEW") out$overview <- r$paras
    else if (r$tag == "CRITIQUE") out$critique <- r$paras
    else if (r$tag == "LINKS") out$links <- r$paras
    else if (r$tag == "BLOCK") out$blocks[[length(out$blocks) + 1]] <- list(heading = r$head, label = r$label, paras = r$paras)
  }
  out
}

# Renders the whole Analysis tab for one work
analysis_view <- function(id, ins = NULL) {
  a <- read_analysis(id)
  if (length(a$overview) == 0 && length(a$blocks) == 0)
    return(div(class = "tip-box", "The analysis for this work is not available yet."))
  tagList(
    p(class = "note", "Who, for whom, what, when, where, why and how; then a paraphrased discussion of the whole work, the facts and figures behind it with their printed pages, and a critical reading."),
    if (!is.null(ins)) tagList(h4(class = "sub-h", "The work at a glance"), profile_view(ins)),
    h4(class = "sub-h", "Discussion"),
    div(class = "analysis-overview",
        tags$h5(class = "ao-title", "What the work does"),
        lapply(a$overview, function(x) tags$p(x))),
    div(class = "analysis-grid",
        lapply(seq_along(a$blocks), function(k) {
          b <- a$blocks[[k]]
          div(class = "analysis-block",
              div(class = "ab-head",
                  span(class = "ab-num", sprintf("%02d", k)),
                  span(class = "ab-label", b$label)),
              tags$h4(class = "ab-title", b$heading),
              lapply(b$paras, function(x) tags$p(x)))
        })),
    if (!is.null(ins) && length(ins$facts)) tagList(h4(class = "sub-h", "Facts and figures stated in the work"), facts_view(ins)),
    if (length(a$critique)) div(class = "critique-box",
        tags$h5(class = "cb-title", "Critical reading"),
        lapply(a$critique, function(x) tags$p(x))),
    if (length(a$links)) div(class = "links-box",
        tags$h5(class = "lb-title", "Links to the course"),
        lapply(a$links, function(x) tags$p(x))))
}
