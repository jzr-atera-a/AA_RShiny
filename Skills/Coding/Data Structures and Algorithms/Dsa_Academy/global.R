# global.R — DSA Interactive Academy
# Shared palette, UI helpers, step player, quiz engine, drawing helpers,
# problem bank and module loader.

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)

# Pin the functions this app uses to the packages it was written for. If another app ran first in the
# same R session (e.g. one that attached jsonlite, httr, dplyr, purrr or shinyjs), those packages sit
# higher on the search path and would otherwise replace validate(), config(), layout(), filter() …
# Copying the exports into the app's own environment makes the app immune to that, whatever is attached.
.dsa_env <- environment()
for (.p in c("shiny", "shinydashboard", "plotly", "DT")) {        # same order as library(): later ones win, as before
  for (.n in getNamespaceExports(.p)) {
    .v <- tryCatch(getExportedValue(.p, .n), error = function(e) NULL)
    if (is.function(.v)) assign(.n, .v, envir = .dsa_env)
  }
}
rm(.p, .n, .v)

local({
  need <- c("jsonlite", "later")          # bigrquery is needed to save progress; the app tells you if it is missing
  miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
  if (length(miss)) stop("Please install the missing packages first:\n  install.packages(c(",
                         paste(sprintf('"%s"', miss), collapse = ", "), "))", call. = FALSE)
})

# ── Small utilities ──────────────────────────────────────────────────────────
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

# Safe ascending sequence (R's a:b counts DOWN when a > b)
sq <- function(a, b) if (a > b) integer(0) else a:b

# Parse "1, 2, 3" into integers
parse_ints <- function(txt, max_n = 30) {
  v <- suppressWarnings(as.integer(trimws(strsplit(txt %||% "", "[,; ]+")[[1]])))
  v <- v[!is.na(v)]
  head(v, max_n)
}

js_set <- function(id, val) {
  sprintf("Shiny.setInputValue('%s', %s, {priority:'event'})", id, val)
}

COL <- list(
  pri = "#4f46e5", sec = "#7c3aed", acc = "#06b6d4", ok = "#10b981",
  warn = "#f59e0b", err = "#ef4444", idle = "#cbd5e1", mute = "#94a3b8",
  ink = "#1e293b", soft = "#e0e7ff", pink = "#ec4899"
)

# ── Basic content helpers ────────────────────────────────────────────────────
lc_badge <- function(level) {
  cls <- switch(level, Easy = "badge-easy", Medium = "badge-medium", Hard = "badge-hard", "badge-medium")
  tags$span(class = paste("lc-badge", cls), level)
}

prob_row <- function(num, title, level, url = NULL, pattern = NULL, companies = "") {
  lbl <- if (!is.null(url)) tags$a(href = url, target = "_blank", title) else title
  pid <- paste0("lc", num)
  tags$div(class = "prob-row",
    lc_badge(level),
    tags$span(class = "prob-num", paste0("#", num)),
    tags$span(class = "prob-title", lbl),
    if (length(companies) && nzchar(companies %||% "")) lapply(strsplit(companies, " · ")[[1]], function(c) tags$span(class = paste("co-badge mini", tolower(c)), substr(c, 1, 1))),
    if (!is.null(pattern)) tags$span(class = "prob-pattern", pattern),
    if (exists("PRACTICE_IDS") && pid %in% PRACTICE_IDS)
      tags$button(class = "btn-solve", title = "Solve it here with tests", onclick = js_set("open_problem", sprintf("'%s'", pid)), "▶ Solve here")
  )
}

cplx_table <- function(df) {
  tags$div(class = "cplx-wrap",
    tags$table(class = "cplx-tbl",
      tags$thead(tags$tr(lapply(gsub(".", " ", names(df), fixed = TRUE), tags$th))),
      tags$tbody(lapply(seq_len(nrow(df)), function(i)
        tags$tr(lapply(as.list(df[i, ]), function(v) tags$td(HTML(as.character(v)))))
      ))
    )
  )
}

dsa_code <- function(txt, title = NULL) {
  tagList(
    if (!is.null(title)) tags$div(class = "code-title", title),
    tags$div(class = "dsa-code", txt)
  )
}

# Pseudocode with the currently executing line(s) highlighted
pseudo <- function(lines, active = NULL) {
  tags$div(class = "dsa-code pseudo",
    lapply(seq_along(lines), function(i)
      tags$div(class = if (i %in% active) "pc-line pc-on" else "pc-line", lines[i])
    )
  )
}

callout <- function(txt, type = "info") {
  tags$div(class = paste("callout", paste0("callout-", type)), HTML(txt))
}

explain <- function(txt) tags$div(class = "viz-explain", HTML(txt))

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

ref_block <- function(...) {
  items <- list(...)
  tags$div(class = "ref-block",
    tags$h6(HTML("&#128218; References")),
    lapply(items, function(r) tags$div(class = "ref-item", r))
  )
}

kpi <- function(value, label, col = COL$pri) {
  tags$div(class = "kpi", style = paste0("border-top-color:", col, ";"),
    tags$div(class = "kpi-val", style = paste0("color:", col, ";"), HTML(as.character(value))),
    tags$div(class = "kpi-lab", label)
  )
}
kpi_row <- function(...) tags$div(class = "kpi-row", ...)

legend_row <- function(items) {
  tags$div(class = "legend-row",
    lapply(names(items), function(n)
      tags$span(class = "legend-item",
        tags$span(class = "legend-dot", style = paste0("background:", items[[n]], ";")), n))
  )
}

# Three-card insight strip: when to use / pitfalls / interview tips
insight_cards <- function(when, pitfalls, tips) {
  card <- function(title, icon, items, cls) {
    tags$div(class = paste("insight-card", cls),
      tags$h5(paste(icon, title)),
      tags$ul(lapply(items, function(x) tags$li(HTML(x))))
    )
  }
  tags$div(class = "insight-grid",
    card("When to reach for it", "🎯", when, "ic-when"),
    card("Common pitfalls", "⚠️", pitfalls, "ic-pit"),
    card("Interview tips", "🗣️", tips, "ic-tip")
  )
}

# Row of value cells with optional pointer labels above and indices below
# ptr: named list, e.g. list(lo = 1, mid = 4, hi = 7) (1-based positions)
vrow <- function(vals, cls = NULL, ptr = NULL, idx = TRUE, arrows = FALSE, wide = FALSE) {
  n <- length(vals)
  if (n == 0) return(tags$div(class = "vrow", tags$span(class = "vempty", "(empty)")))
  cls <- cls %||% rep("", n)
  if (length(cls) == 1) cls <- rep(cls, n)
  labs <- rep("", n)
  for (nm in names(ptr)) {
    i <- ptr[[nm]]
    if (is.null(i) || length(i) != 1 || is.na(i) || i < 1 || i > n) next
    labs[i] <- if (nzchar(labs[i])) paste(labs[i], nm, sep = "·") else nm
  }
  cells <- lapply(seq_len(n), function(i) tagList(
    tags$div(class = "vcell",
      if (!is.null(ptr)) tags$div(class = "vptr", if (nzchar(labs[i])) labs[i] else HTML("&nbsp;")),
      tags$div(class = paste("vnode", cls[i], if (wide) "wide"), as.character(vals[i])),
      if (idx) tags$div(class = "vidx", i - 1)
    ),
    if (arrows && i < n) tags$span(class = "varrow", "→")
  ))
  tags$div(class = "vrow", cells)
}

# Labelled lane for showing a queue / stack / result list
lane <- function(label, vals, cls = "visited", empty = "empty") {
  tags$div(class = "lane",
    tags$span(class = "lane-lab", label),
    if (length(vals) == 0) tags$span(class = "vempty", empty)
    else lapply(vals, function(v) tags$span(class = paste("vnode sm", cls), as.character(v)))
  )
}

# DP grid: numeric/character matrix rendered as a table with per-cell classes
# cls values: "g-cur", "g-dep", "g-path", "g-todo", ""
dp_grid <- function(m, rlab = NULL, clab = NULL, cls = NULL) {
  nr <- nrow(m); nc <- ncol(m)
  cls <- cls %||% matrix("", nr, nc)
  tags$div(class = "dp-wrap",
    tags$table(class = "dp-grid",
      if (!is.null(clab)) tags$thead(tags$tr(tags$th(""), lapply(clab, tags$th))),
      tags$tbody(lapply(seq_len(nr), function(i)
        tags$tr(
          if (!is.null(rlab)) tags$th(rlab[i]),
          lapply(seq_len(nc), function(j) tags$td(class = cls[i, j], as.character(m[i, j])))
        )
      ))
    )
  )
}

# ── Step player ──────────────────────────────────────────────────────────────
# UI: ⏮ ◀ ▶ ⏭ Play + progress bar. Server: returns reactive index + current step.
stepper_ui <- function(ns, id) {
  b <- function(s, lab, cls = "btn-dsa-outline")
    actionButton(ns(paste0(id, "_", s)), lab, class = paste("btn btn-sm", cls))
  tags$div(class = "stepper",
    tags$div(class = "stepper-btns",
      b("first", "⏮"), b("prev", "◀ Prev"), b("next", "Next ▶", "btn-dsa"),
      b("last", "⏭"), b("play", "▶ Play", "btn-dsa")),
    uiOutput(ns(paste0(id, "_prog")))
  )
}

stepper_server <- function(input, output, session, id, steps_raw, speed = 850) {
  nm <- function(x) paste0(id, "_", x)
  rv <- reactiveValues(i = 1, playing = FALSE)
  # Build the steps; if that fails, say exactly which visual and which expression failed (console + inside the box)
  steps <- reactive({
    tryCatch(steps_raw(), error = function(e) {
      if (inherits(e, "shiny.silent.error")) stop(e)
      cl <- conditionCall(e)
      message(sprintf("[DSA] visual '%s' could not be built: %s%s", session$ns(id), conditionMessage(e),
                      if (is.null(cl)) "" else paste0("  (in: ", paste(deparse(cl, nlines = 2), collapse = " "), ")")))
      validate(need(FALSE, paste("This visual could not be built:", conditionMessage(e))))
    })
  })
  # Steps are built lazily — only when this diagram is actually on screen — instead of for all 47 diagrams at
  # startup. Rebuilding them (new inputs) rewinds the player to step 1.
  built <- reactive({
    s <- steps()
    isolate({ if (!identical(rv$i, 1)) rv$i <- 1; if (isTRUE(rv$playing)) rv$playing <- FALSE })
    s
  })
  n  <- reactive(length(built()))

  observeEvent(input[[nm("next")]],  { rv$playing <- FALSE; if (rv$i < n()) rv$i <- rv$i + 1 })
  observeEvent(input[[nm("prev")]],  { rv$playing <- FALSE; if (rv$i > 1)  rv$i <- rv$i - 1 })
  observeEvent(input[[nm("first")]], { rv$playing <- FALSE; rv$i <- 1 })
  observeEvent(input[[nm("last")]],  { rv$playing <- FALSE; rv$i <- n() })
  observeEvent(input[[nm("goto")]],  {           # used by the diagram exporter to step through frames
    g <- suppressWarnings(as.integer(input[[nm("goto")]]$i))
    if (length(g) == 1 && !is.na(g)) { rv$playing <- FALSE; rv$i <- max(1, min(n(), g)) }
  })
  observeEvent(input[[nm("play")]],  {
    if (!rv$playing && rv$i >= n()) rv$i <- 1
    rv$playing <- !rv$playing
  })
  observe({
    if (!rv$playing) return()
    invalidateLater(speed, session)
    isolate({
      if (rv$i >= n()) rv$playing <- FALSE else rv$i <- rv$i + 1
    })
  })
  observe({
    updateActionButton(session, nm("play"), label = if (rv$playing) "⏸ Pause" else "▶ Play")
  })
  output[[nm("prog")]] <- renderUI({
    k <- n(); req(k > 0)
    i <- min(rv$i, k)
    tags$div(class = "stepper-prog",
      tags$div(class = "stepper-bar",
        tags$div(class = "stepper-fill", style = sprintf("width:%.0f%%;", 100 * i / k))),
      tags$span(class = "stepper-count", sprintf("Step %d / %d", i, k))
    )
  })
  list(
    i   = reactive(min(rv$i, max(1, n()))),
    cur = reactive({ s <- built(); req(length(s) > 0); s[[min(rv$i, length(s))]] })
  )
}

# ── Quiz engine ──────────────────────────────────────────────────────────────
# questions: list(list(q = "...", opts = c("a","b","c"), ans = 2, why = "..."))
quiz_ui <- function(ns) uiOutput(ns("quiz"))

quiz_server <- function(input, output, session, questions, topic = NULL, progress = NULL) {
  ns <- session$ns
  N  <- length(questions)
  st <- reactiveValues(i = 1, picks = rep(NA_integer_, N), done = FALSE)

  publish <- function() {
    if (is.null(progress) || is.null(topic)) return()
    correct <- sum(vapply(seq_len(N), function(k)
      !is.na(st$picks[k]) && st$picks[k] == questions[[k]]$ans, logical(1)))
    progress[[topic]] <- c(correct = correct, answered = sum(!is.na(st$picks)), total = N)
  }
  isolate(publish())

  observeEvent(input$quiz_pick, {
    if (st$done || !is.na(st$picks[st$i])) return()
    st$picks[st$i] <- as.integer(input$quiz_pick)
    publish()
  })
  observeEvent(input$quiz_next, {
    if (st$i < N) st$i <- st$i + 1 else st$done <- TRUE
  })
  observeEvent(input$quiz_reset, {
    st$i <- 1; st$picks <- rep(NA_integer_, N); st$done <- FALSE
    publish()
  })

  output$quiz <- renderUI({
    score <- sum(vapply(seq_len(N), function(k)
      !is.na(st$picks[k]) && st$picks[k] == questions[[k]]$ans, logical(1)))
    if (st$done) {
      pct <- round(100 * score / N)
      msg <- if (pct == 100) "Perfect — you own this topic." else if (pct >= 60) "Solid. Review the ones you missed and retry." else "Revisit the visualisers, then try again."
      return(tags$div(class = "quiz-done",
        tags$div(class = "quiz-score", sprintf("%d / %d", score, N)),
        tags$p(msg),
        tags$button(class = "btn btn-dsa", onclick = js_set(ns("quiz_reset"), "Date.now()"), "↺ Retry quiz")
      ))
    }
    q    <- questions[[st$i]]
    pick <- st$picks[st$i]
    tagList(
      tags$div(class = "quiz-head",
        tags$span(sprintf("Question %d of %d", st$i, N)),
        tags$span(class = "quiz-pts", sprintf("Score %d", score))),
      tags$p(class = "quiz-q", HTML(q$q)),
      lapply(seq_along(q$opts), function(k) {
        cls <- "qopt"
        if (!is.na(pick)) {
          if (k == q$ans) cls <- "qopt right"
          else if (k == pick) cls <- "qopt wrong"
          else cls <- "qopt dim"
        }
        tags$button(class = cls, onclick = js_set(ns("quiz_pick"), k), HTML(q$opts[k]))
      }),
      if (!is.na(pick)) tagList(
        tags$div(class = paste("qfeedback", if (pick == q$ans) "right" else "wrong"),
          HTML(paste0(if (pick == q$ans) "✅ Correct. " else "❌ Not quite. ", q$why))),
        tags$button(class = "btn btn-dsa btn-sm", style = "margin-top:10px;",
          onclick = js_set(ns("quiz_next"), "Date.now()"),
          if (st$i < N) "Next question ▶" else "See result")
      )
    )
  })
}

# ── Plot helpers ─────────────────────────────────────────────────────────────
dsa_layout <- function(p, title = NULL, xt = "", yt = "", legend = FALSE) {
  p %>% layout(
    title = if (!is.null(title)) list(text = title, font = list(size = 13), x = 0.02) else NULL,
    xaxis = list(title = xt, gridcolor = "#e2e8f0", zeroline = FALSE),
    yaxis = list(title = yt, gridcolor = "#e2e8f0", zeroline = FALSE),
    plot_bgcolor = "#f8fafc", paper_bgcolor = "#ffffff",
    showlegend = legend, legend = list(orientation = "h", y = -0.34),
    font = list(family = "Inter, sans-serif", size = 12, color = "#334155"),
    margin = list(t = if (is.null(title)) 15 else 42, l = 50, r = 15, b = 45)
  ) %>% config(displayModeBar = FALSE)
}

# Bar chart of an array where each bar carries a state colour
bar_state <- function(vals, cols, title = NULL, height = 260) {
  plot_ly(x = seq_along(vals) - 1, y = vals, type = "bar", height = height,
          marker = list(color = cols, line = list(color = "#ffffff", width = 1)),
          text = vals, textposition = "outside", hoverinfo = "x+y") %>%
    dsa_layout(title = title, xt = "index") %>%
    layout(xaxis = list(dtick = 1), yaxis = list(range = c(min(0, vals), max(vals, 1) * 1.18)))
}

# Node-link diagram. nodes: x, y, label [, color, border, tcol, hover, sub]
# edges: x0, y0, x1, y1 [, color, width, label]
net_plot <- function(nodes, edges = NULL, directed = FALSE, size = 36, height = 320) {
  if (is.null(nodes$color))  nodes$color  <- "#ffffff"
  if (is.null(nodes$border)) nodes$border <- COL$pri
  if (is.null(nodes$tcol))   nodes$tcol   <- COL$ink
  if (is.null(nodes$hover))  nodes$hover  <- as.character(nodes$label)
  nodes$label <- as.character(nodes$label)
  shapes <- list(); anns <- list()
  if (!is.null(edges) && nrow(edges) > 0) {
    if (is.null(edges$color)) edges$color <- COL$mute
    if (is.null(edges$width)) edges$width <- 2
    for (i in seq_len(nrow(edges))) {
      e <- edges[i, ]
      if (directed) {
        anns[[length(anns) + 1]] <- list(
          x = e$x1, y = e$y1, ax = e$x0, ay = e$y0, xref = "x", yref = "y",
          axref = "x", ayref = "y", text = "", showarrow = TRUE, arrowhead = 2,
          arrowsize = 1, arrowwidth = e$width, arrowcolor = e$color,
          standoff = size / 2 + 2, startstandoff = size / 2)
      } else {
        shapes[[length(shapes) + 1]] <- list(
          type = "line", x0 = e$x0, y0 = e$y0, x1 = e$x1, y1 = e$y1, layer = "below",
          line = list(color = e$color, width = e$width))
      }
      if (!is.null(edges$label) && !is.na(e$label) && nzchar(as.character(e$label))) {
        anns[[length(anns) + 1]] <- list(
          x = (e$x0 + e$x1) / 2, y = (e$y0 + e$y1) / 2, text = as.character(e$label),
          showarrow = FALSE, font = list(size = 11, color = "#475569"),
          bgcolor = "#ffffff", bordercolor = "#e2e8f0", borderpad = 2)
      }
    }
  }
  if (!is.null(nodes$sub)) {
    for (i in seq_len(nrow(nodes))) {
      if (is.na(nodes$sub[i]) || !nzchar(as.character(nodes$sub[i]))) next
      anns[[length(anns) + 1]] <- list(
        x = nodes$x[i], y = nodes$y[i], text = as.character(nodes$sub[i]), showarrow = FALSE,
        yshift = -(size / 2 + 9), font = list(size = 10.5, color = COL$sec))
    }
  }
  xr <- range(nodes$x); yr <- range(nodes$y)
  px <- max(diff(xr), 1) * 0.10; py <- max(diff(yr), 1) * 0.18
  plot_ly(nodes, x = ~x, y = ~y, type = "scatter", mode = "markers+text",
          text = ~label, textposition = "middle center", cliponaxis = FALSE,
          textfont = list(color = nodes$tcol, size = 12.5),
          marker = list(size = size, color = nodes$color, opacity = 1,
                        line = list(color = nodes$border, width = 2.5)),
          hoverinfo = "text", hovertext = nodes$hover, height = height) %>%
    layout(shapes = shapes, annotations = anns,
           xaxis = list(visible = FALSE, range = c(xr[1] - px, xr[2] + px), fixedrange = TRUE),
           yaxis = list(visible = FALSE, range = c(yr[1] - py, yr[2] + py), fixedrange = TRUE),
           margin = list(l = 8, r = 8, t = 8, b = 8), showlegend = FALSE,
           plot_bgcolor = "#f8fafc", paper_bgcolor = "#f8fafc") %>%
    config(displayModeBar = FALSE)
}

# Colour a set of nodes by state. state: character vector of "idle|active|visited|done|frontier|path"
state_style <- function(nodes, state) {
  fill   <- c(idle = "#ffffff", active = COL$pri, visited = COL$soft, done = COL$ok,
              frontier = "#fef3c7", path = COL$warn, bad = "#fee2e2")
  border <- c(idle = COL$mute, active = COL$pri, visited = "#6366f1", done = "#059669",
              frontier = COL$warn, path = "#d97706", bad = COL$err)
  tcol   <- c(idle = COL$ink, active = "#ffffff", visited = "#3730a3", done = "#ffffff",
              frontier = "#92400e", path = "#ffffff", bad = "#991b1b")
  nodes$color  <- unname(fill[state])
  nodes$border <- unname(border[state])
  nodes$tcol   <- unname(tcol[state])
  nodes
}

# ── Binary tree helpers (nested list: val, left, right) ──────────────────────
bst_insert <- function(tree, val) {
  if (is.null(tree)) return(list(val = val, left = NULL, right = NULL))
  if (val < tree$val) tree$left <- bst_insert(tree$left, val)
  else if (val > tree$val) tree$right <- bst_insert(tree$right, val)
  tree
}
bst_build <- function(vals) { t <- NULL; for (v in vals) t <- bst_insert(t, v); t }
tree_height <- function(t) if (is.null(t)) 0 else 1 + max(tree_height(t$left), tree_height(t$right))

# Layout: x = inorder rank, y = -depth. Returns list(nodes, edges)
tree_layout <- function(tree) {
  rows <- list(); k <- 0
  walk <- function(t, depth, parent) {
    if (is.null(t)) return(invisible())
    walk(t$left, depth + 1, t$val)
    k <<- k + 1
    rows[[length(rows) + 1]] <<- data.frame(label = t$val, x = k, y = -depth,
                                            parent = if (is.null(parent)) NA else parent)
    walk(t$right, depth + 1, t$val)
  }
  walk(tree, 0, NULL)
  nodes <- do.call(rbind, rows)
  ch <- nodes[!is.na(nodes$parent), ]
  edges <- if (nrow(ch) > 0) {
    pi <- match(ch$parent, nodes$label)
    data.frame(x0 = nodes$x[pi], y0 = nodes$y[pi], x1 = ch$x, y1 = ch$y,
               from = ch$parent, to = ch$label)
  } else NULL
  list(nodes = nodes, edges = edges)
}

# Heap (array) layout as a complete binary tree
heap_layout <- function(h) {
  n <- length(h); if (n == 0) return(NULL)
  d   <- floor(log2(seq_len(n)))
  pos <- seq_len(n) - 2^d
  nodes <- data.frame(label = h, x = (pos + 0.5) / 2^d, y = -d)
  edges <- if (n > 1) {
    ch <- 2:n; pa <- ch %/% 2
    data.frame(x0 = nodes$x[pa], y0 = nodes$y[pa], x1 = nodes$x[ch], y1 = nodes$y[ch])
  } else NULL
  list(nodes = nodes, edges = edges)
}

# ── Problem bank (single source for every module and the Pattern Finder) ─────
PROBLEMS <- read.table(sep = "|", quote = "", comment.char = "", strip.white = TRUE,
  stringsAsFactors = FALSE, col.names = c("topic", "num", "title", "level", "pattern", "slug"),
  text = "
arrays|1|Two Sum|Easy|Hash map complement|two-sum
arrays|121|Best Time to Buy and Sell Stock|Easy|One pass min tracking|best-time-to-buy-and-sell-stock
arrays|53|Maximum Subarray|Medium|Kadane|maximum-subarray
arrays|238|Product of Array Except Self|Medium|Prefix / suffix|product-of-array-except-self
arrays|3|Longest Substring Without Repeating Characters|Medium|Sliding window|longest-substring-without-repeating-characters
arrays|11|Container With Most Water|Medium|Two pointers|container-with-most-water
arrays|15|3Sum|Medium|Sort + two pointers|3sum
arrays|33|Search in Rotated Sorted Array|Medium|Binary search|search-in-rotated-sorted-array
arrays|560|Subarray Sum Equals K|Medium|Prefix sum + hash map|subarray-sum-equals-k
arrays|76|Minimum Window Substring|Hard|Sliding window|minimum-window-substring
arrays|42|Trapping Rain Water|Hard|Two pointers|trapping-rain-water
linkedlists|206|Reverse Linked List|Easy|Pointer reversal|reverse-linked-list
linkedlists|21|Merge Two Sorted Lists|Easy|Dummy head merge|merge-two-sorted-lists
linkedlists|141|Linked List Cycle|Easy|Fast / slow pointers|linked-list-cycle
linkedlists|876|Middle of the Linked List|Easy|Fast / slow pointers|middle-of-the-linked-list
linkedlists|234|Palindrome Linked List|Easy|Middle + reverse|palindrome-linked-list
linkedlists|19|Remove Nth Node From End of List|Medium|Two pointers with gap|remove-nth-node-from-end-of-list
linkedlists|142|Linked List Cycle II|Medium|Floyd phase 2|linked-list-cycle-ii
linkedlists|2|Add Two Numbers|Medium|Dummy head + carry|add-two-numbers
linkedlists|143|Reorder List|Medium|Middle + reverse + merge|reorder-list
linkedlists|146|LRU Cache|Medium|Hash map + doubly linked list|lru-cache
linkedlists|23|Merge k Sorted Lists|Hard|Min-heap / divide and conquer|merge-k-sorted-lists
linkedlists|25|Reverse Nodes in k-Group|Hard|Pointer reversal|reverse-nodes-in-k-group
stacks|20|Valid Parentheses|Easy|Stack matching|valid-parentheses
stacks|232|Implement Queue using Stacks|Easy|Two stacks|implement-queue-using-stacks
stacks|496|Next Greater Element I|Easy|Monotonic stack|next-greater-element-i
stacks|155|Min Stack|Medium|Auxiliary stack|min-stack
stacks|150|Evaluate Reverse Polish Notation|Medium|Operand stack|evaluate-reverse-polish-notation
stacks|739|Daily Temperatures|Medium|Monotonic stack|daily-temperatures
stacks|227|Basic Calculator II|Medium|Stack of signed terms|basic-calculator-ii
stacks|224|Basic Calculator|Hard|Stack of (sign, result) for parentheses|basic-calculator
stacks|394|Decode String|Medium|Stack of contexts|decode-string
stacks|84|Largest Rectangle in Histogram|Hard|Monotonic stack|largest-rectangle-in-histogram
stacks|239|Sliding Window Maximum|Hard|Monotonic deque|sliding-window-maximum
trees|104|Maximum Depth of Binary Tree|Easy|DFS recursion|maximum-depth-of-binary-tree
trees|226|Invert Binary Tree|Easy|DFS recursion|invert-binary-tree
trees|543|Diameter of Binary Tree|Easy|Postorder height|diameter-of-binary-tree
trees|102|Binary Tree Level Order Traversal|Medium|BFS by level|binary-tree-level-order-traversal
trees|98|Validate Binary Search Tree|Medium|Range bounds / inorder|validate-binary-search-tree
trees|235|Lowest Common Ancestor of a BST|Medium|BST split point|lowest-common-ancestor-of-a-binary-search-tree
trees|230|Kth Smallest Element in a BST|Medium|Inorder|kth-smallest-element-in-a-bst
trees|105|Construct Binary Tree from Preorder and Inorder|Medium|Divide by root index|construct-binary-tree-from-preorder-and-inorder-traversal
trees|106|Construct Binary Tree from Inorder and Postorder|Medium|Divide by root index|construct-binary-tree-from-inorder-and-postorder-traversal
trees|114|Flatten Binary Tree to Linked List|Medium|Morris-style rewiring|flatten-binary-tree-to-linked-list
trees|117|Populating Next Right Pointers II|Medium|Level linking, O(1) space|populating-next-right-pointers-in-each-node-ii
trees|124|Binary Tree Maximum Path Sum|Hard|Postorder gain|binary-tree-maximum-path-sum
trees|297|Serialize and Deserialize Binary Tree|Hard|Preorder with null markers|serialize-and-deserialize-binary-tree
graphs|200|Number of Islands|Medium|Grid DFS / BFS|number-of-islands
graphs|133|Clone Graph|Medium|DFS + hash map|clone-graph
graphs|207|Course Schedule|Medium|Topological sort|course-schedule
graphs|210|Course Schedule II|Medium|Topological sort|course-schedule-ii
graphs|994|Rotting Oranges|Medium|Multi-source BFS|rotting-oranges
graphs|417|Pacific Atlantic Water Flow|Medium|Reverse DFS from borders|pacific-atlantic-water-flow
graphs|743|Network Delay Time|Medium|Dijkstra|network-delay-time
graphs|787|Cheapest Flights Within K Stops|Medium|Bellman-Ford / BFS levels|cheapest-flights-within-k-stops
graphs|684|Redundant Connection|Medium|Union-Find|redundant-connection
graphs|127|Word Ladder|Hard|BFS on implicit graph|word-ladder
dp|70|Climbing Stairs|Easy|1D DP (Fibonacci)|climbing-stairs
dp|198|House Robber|Medium|1D DP take / skip|house-robber
dp|322|Coin Change|Medium|Unbounded knapsack|coin-change
dp|300|Longest Increasing Subsequence|Medium|1D DP / patience sort|longest-increasing-subsequence
dp|1143|Longest Common Subsequence|Medium|2D DP on two strings|longest-common-subsequence
dp|62|Unique Paths|Medium|Grid DP|unique-paths
dp|416|Partition Equal Subset Sum|Medium|0/1 knapsack|partition-equal-subset-sum
dp|139|Word Break|Medium|1D DP over prefixes|word-break
dp|72|Edit Distance|Medium|2D DP on two strings|edit-distance
dp|312|Burst Balloons|Hard|Interval DP|burst-balloons
sorting|704|Binary Search|Easy|Binary search|binary-search
sorting|912|Sort an Array|Medium|Merge / heap sort|sort-an-array
sorting|75|Sort Colors|Medium|Dutch national flag|sort-colors
sorting|56|Merge Intervals|Medium|Sort + sweep|merge-intervals
sorting|215|Kth Largest Element in an Array|Medium|Quickselect / heap|kth-largest-element-in-an-array
sorting|148|Sort List|Medium|Merge sort on list|sort-list
sorting|179|Largest Number|Medium|Custom comparator|largest-number
sorting|34|Find First and Last Position of Element|Medium|Boundary binary search|find-first-and-last-position-of-element-in-sorted-array
sorting|4|Median of Two Sorted Arrays|Hard|Binary search on partition|median-of-two-sorted-arrays
sorting|315|Count of Smaller Numbers After Self|Hard|Merge sort counting|count-of-smaller-numbers-after-self
sorting|153|Find Minimum in Rotated Sorted Array|Medium|Binary search vs right end|find-minimum-in-rotated-sorted-array
sorting|81|Search in Rotated Sorted Array II|Medium|Rotated binary search + duplicates|search-in-rotated-sorted-array-ii
hashing|217|Contains Duplicate|Easy|Hash set|contains-duplicate
hashing|242|Valid Anagram|Easy|Frequency map|valid-anagram
hashing|49|Group Anagrams|Medium|Canonical key|group-anagrams
hashing|128|Longest Consecutive Sequence|Medium|Hash set sequence starts|longest-consecutive-sequence
hashing|347|Top K Frequent Elements|Medium|Frequency map + bucket / heap|top-k-frequent-elements
hashing|380|Insert Delete GetRandom O(1)|Medium|Hash map + array|insert-delete-getrandom-o1
hashing|36|Valid Sudoku|Medium|Hash sets per row / col / box|valid-sudoku
hashing|438|Find All Anagrams in a String|Medium|Sliding window + counts|find-all-anagrams-in-a-string
hashing|41|First Missing Positive|Hard|Index as hash|first-missing-positive
heaps|703|Kth Largest Element in a Stream|Easy|Min-heap of size k|kth-largest-element-in-a-stream
heaps|1046|Last Stone Weight|Easy|Max-heap simulation|last-stone-weight
heaps|973|K Closest Points to Origin|Medium|Heap of size k|k-closest-points-to-origin
heaps|621|Task Scheduler|Medium|Max-heap + cooldown|task-scheduler
heaps|378|Kth Smallest Element in a Sorted Matrix|Medium|Heap k-way merge|kth-smallest-element-in-a-sorted-matrix
heaps|767|Reorganize String|Medium|Max-heap greedy|reorganize-string
heaps|295|Find Median from Data Stream|Hard|Two heaps|find-median-from-data-stream
heaps|502|IPO|Hard|Two heaps greedy|ipo
recursion|78|Subsets|Medium|Backtracking include / exclude|subsets
recursion|46|Permutations|Medium|Backtracking with used set|permutations
recursion|77|Combinations|Medium|Backtracking with start index|combinations
recursion|39|Combination Sum|Medium|Backtracking with reuse|combination-sum
recursion|22|Generate Parentheses|Medium|Backtracking with counts|generate-parentheses
recursion|17|Letter Combinations of a Phone Number|Medium|Backtracking|letter-combinations-of-a-phone-number
recursion|79|Word Search|Medium|Grid backtracking|word-search
recursion|131|Palindrome Partitioning|Medium|Backtracking over cuts|palindrome-partitioning
recursion|51|N-Queens|Hard|Backtracking with pruning|n-queens
recursion|37|Sudoku Solver|Hard|Backtracking with pruning|sudoku-solver
greedy|55|Jump Game|Medium|Farthest reach|jump-game
greedy|45|Jump Game II|Medium|BFS-style levels|jump-game-ii
greedy|134|Gas Station|Medium|Running surplus|gas-station
greedy|435|Non-overlapping Intervals|Medium|Sort by end time|non-overlapping-intervals
greedy|452|Minimum Number of Arrows to Burst Balloons|Medium|Sort by end time|minimum-number-of-arrows-to-burst-balloons
greedy|763|Partition Labels|Medium|Last occurrence|partition-labels
greedy|406|Queue Reconstruction by Height|Medium|Sort + insert|queue-reconstruction-by-height
greedy|135|Candy|Hard|Two passes|candy
bits|136|Single Number|Easy|XOR cancel|single-number
bits|191|Number of 1 Bits|Easy|n & (n-1)|number-of-1-bits
bits|231|Power of Two|Easy|n & (n-1)|power-of-two
bits|268|Missing Number|Easy|XOR with indices|missing-number
bits|190|Reverse Bits|Easy|Shift and mask|reverse-bits
bits|338|Counting Bits|Easy|DP on bits|counting-bits
bits|371|Sum of Two Integers|Medium|XOR + carry|sum-of-two-integers
bits|137|Single Number II|Medium|Bit counting mod 3|single-number-ii
bits|201|Bitwise AND of Numbers Range|Medium|Common prefix|bitwise-and-of-numbers-range
advanced|14|Longest Common Prefix|Easy|Trie / vertical scan|longest-common-prefix
advanced|208|Implement Trie (Prefix Tree)|Medium|Trie|implement-trie-prefix-tree
advanced|211|Design Add and Search Words Data Structure|Medium|Trie + DFS wildcard|design-add-and-search-words-data-structure
advanced|547|Number of Provinces|Medium|Union-Find / DFS|number-of-provinces
advanced|721|Accounts Merge|Medium|Union-Find|accounts-merge
advanced|1584|Min Cost to Connect All Points|Medium|Kruskal / Prim MST|min-cost-to-connect-all-points
advanced|307|Range Sum Query - Mutable|Medium|Fenwick / segment tree|range-sum-query-mutable
advanced|212|Word Search II|Hard|Trie + backtracking|word-search-ii
systemdesign|705|Design HashSet|Easy|Buckets + chaining|design-hashset
systemdesign|622|Design Circular Queue|Medium|Ring buffer|design-circular-queue
systemdesign|535|Encode and Decode TinyURL|Medium|Hash map + base62|encode-and-decode-tinyurl
systemdesign|981|Time Based Key-Value Store|Medium|Hash map + binary search|time-based-key-value-store
systemdesign|355|Design Twitter|Medium|Heap merge of feeds|design-twitter
systemdesign|1146|Snapshot Array|Medium|Versioned values + binary search|snapshot-array
systemdesign|460|LFU Cache|Hard|Hash maps + frequency lists|lfu-cache
matrix|48|Rotate Image|Medium|Transpose + reverse rows|rotate-image
matrix|73|Set Matrix Zeroes|Medium|First row / column as markers|set-matrix-zeroes
matrix|59|Spiral Matrix II|Medium|Shrinking boundaries|spiral-matrix-ii
matrix|57|Insert Interval|Medium|Sweep with three phases|insert-interval
matrix|759|Employee Free Time|Hard|Merge then find gaps|employee-free-time
matrix|218|The Skyline Problem|Hard|Sweep line + max-heap|the-skyline-problem
rangeq|303|Range Sum Query - Immutable|Easy|Prefix sums|range-sum-query-immutable
rangeq|304|Range Sum Query 2D - Immutable|Medium|2D prefix sums|range-sum-query-2d-immutable
rangeq|308|Range Sum Query 2D - Mutable|Hard|2D Fenwick tree|range-sum-query-2d-mutable
rangeq|327|Count of Range Sum|Hard|Prefix sums + merge sort / BIT|count-of-range-sum
rangeq|715|Range Module|Hard|Sorted intervals / segment tree|range-module
rangeq|732|My Calendar III|Hard|Sweep line / segment tree|my-calendar-iii
random|384|Shuffle an Array|Medium|Fisher-Yates|shuffle-an-array
random|382|Linked List Random Node|Medium|Reservoir sampling|linked-list-random-node
random|470|Implement Rand10() Using Rand7()|Medium|Rejection sampling|implement-rand10-using-rand7
random|710|Random Pick with Blacklist|Hard|Remapping|random-pick-with-blacklist
random|519|Random Flip Matrix|Medium|Virtual Fisher-Yates|random-flip-matrix
design|284|Peeking Iterator|Medium|Cache the next element|peeking-iterator
design|281|Zigzag Iterator|Medium|Queue of iterators|zigzag-iterator
design|1586|Binary Search Tree Iterator II|Medium|Stack + history|binary-search-tree-iterator-ii
design|380|Insert Delete GetRandom O(1)|Medium|Hash map + array|insert-delete-getrandom-o1
design|1146|Snapshot Array|Medium|Versioned values + binary search|snapshot-array
")
PROBLEMS$url <- paste0("https://leetcode.com/problems/", PROBLEMS$slug, "/")

TOPICS <- c(
  arrays = "Arrays & Strings", linkedlists = "Linked Lists", stacks = "Stacks & Queues",
  hashing = "Hash Tables", trees = "Trees & BSTs", heaps = "Heaps", graphs = "Graphs",
  advanced = "Tries & Union-Find", sorting = "Sorting & Searching", recursion = "Recursion & Backtracking",
  dp = "Dynamic Programming", greedy = "Greedy", bits = "Bit Manipulation", systemdesign = "System Design",
  matrix = "Matrices & Intervals", rangeq = "Range Queries", random = "Randomised Algorithms", design = "Iterators & Class Design"
)

# Problems frequently reported by candidates for each company (community interview lists).
# Indicative only — companies do not publish their question banks.
REPORTED <- list(
  Meta = c(1, 2, 3, 15, 20, 21, 23, 31, 33, 34, 42, 49, 50, 53, 56, 57, 71, 76, 78, 88, 98, 102, 104, 114, 121, 124, 125, 133, 138,
           143, 146, 153, 162, 173, 199, 200, 206, 207, 210, 215, 227, 236, 238, 253, 269, 273, 282, 297, 301, 314, 339, 341, 347,
           380, 398, 408, 415, 426, 438, 528, 543, 560, 621, 680, 721, 739, 791, 827, 921, 938, 973, 986, 1004, 1091, 1249, 1650, 1762),
  Google = c(1, 2, 3, 4, 11, 15, 17, 20, 22, 23, 33, 42, 45, 46, 49, 54, 56, 62, 72, 76, 79, 84, 127, 128, 139, 146, 200, 207, 208,
             212, 215, 218, 239, 253, 295, 297, 300, 307, 315, 322, 329, 359, 380, 384, 410, 498, 528, 642, 684, 715, 743, 778, 787,
             843, 981, 1094, 1146, 1293, 2013, 2034))
problem_companies <- function(num) {
  vapply(num, function(n) paste(names(REPORTED)[vapply(REPORTED, function(v) n %in% v, logical(1))], collapse = " · "), "")
}

prob_list <- function(topic) {
  d <- PROBLEMS[PROBLEMS$topic == topic, ]
  d <- d[order(match(d$level, c("Easy", "Medium", "Hard")), d$num), ]
  lapply(seq_len(nrow(d)), function(i)
    prob_row(d$num[i], d$title[i], d$level[i], d$url[i], d$pattern[i], d$companies[i] %||% ""))
}

# ── Page scaffolding shared by every topic module ────────────────────────────
topic_tabs <- function(ns, visual, learn, practice) {
  tags$div(class = "topic-tabs",
    tabsetPanel(id = ns("tabs"), type = "pills",
      tabPanel("🎬 Visualise", visual),
      tabPanel("💡 Understand", learn),
      tabPanel("📝 Practise", practice)
    )
  )
}

practice_tab <- function(ns, topic, ...) {
  tagList(
    fluidRow(
      box(title = "Knowledge Check", status = "warning", solidHeader = TRUE, width = 5, quiz_ui(ns)),
      box(title = "Curated LeetCode Problems (easy → hard)", status = "success", solidHeader = TRUE, width = 7,
          tags$p(class = "hint", "Each row shows the pattern that cracks it. Try to name the pattern before you open the problem."),
          prob_list(topic))
    ),
    ref_block(...)
  )
}

hint <- function(txt) tags$p(class = "hint", HTML(txt))

# ── Load all modules ─────────────────────────────────────────────────────────
source("practice/engine.R", local = TRUE, keep.source = TRUE)
source("practice/store.R", local = TRUE, keep.source = TRUE)
source("practice/exporter.R", local = TRUE, keep.source = TRUE)
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE, keep.source = TRUE)
