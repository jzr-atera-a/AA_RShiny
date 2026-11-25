# modules/mod_rangeq.R — Range Queries: prefix sums, Fenwick (BIT), segment trees.

rangeq_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("📏", "Range Queries",
      "When an array keeps changing and you keep asking about ranges, prefix sums stop working. Fenwick and segment trees answer both in O(log n).",
      c("Prefix Sums", "2-D Prefix", "Fenwick Tree", "Segment Tree", "Lazy Propagation", "Coordinate Compression")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Fenwick Tree (Binary Indexed Tree) — which cells does an operation touch?", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(5, textInput(ns("fw_arr"), "Array (1-indexed inside the tree):", "3, 2, -1, 6, 5, 4, -3, 3, 7, 2, 3, 1")),
              column(3, selectInput(ns("fw_op"), "Operation:", c("prefix query sum(1..i)" = "query", "update a[i] += delta" = "update"))),
              column(2, numericInput(ns("fw_i"), "i:", 11, min = 1, max = 16)),
              column(2, numericInput(ns("fw_d"), "delta:", 5))
            ),
            stepper_ui(ns, "fw"),
            plotlyOutput(ns("fw_plot"), height = "300px"),
            uiOutput(ns("fw_viz"))
          ),
          box(title = "The lowbit trick", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("fw_bits")),
            callout("<code>i &amp; -i</code> isolates the lowest set bit. Cell <code>tree[i]</code> stores the sum of the <b>lowbit(i)</b> elements ending at i — the bars on the left show exactly that range.", "tip"),
            callout("Query walks <b>down</b>: <code>i -= i &amp; -i</code>. Update walks <b>up</b>: <code>i += i &amp; -i</code>. Both take at most ⌈log₂ n⌉ + 1 steps.", "info"))
        ),
        fluidRow(
          box(title = "Segment Tree — range sum query", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(5, textInput(ns("st_arr"), "Array:", "5, 8, 6, 3, 2, 7, 2, 6")),
              column(2, numericInput(ns("st_l"), "l:", 2, min = 0)),
              column(2, numericInput(ns("st_r"), "r:", 6, min = 0)),
              column(3, selectInput(ns("st_agg"), "Aggregate:", c("sum", "min", "max")))
            ),
            stepper_ui(ns, "st"),
            plotlyOutput(ns("st_plot"), height = "340px"),
            legend_row(c("fully inside → use node" = COL$ok, "partial → recurse" = COL$warn, "disjoint → skip" = "#fee2e2", "current" = COL$pri)),
            uiOutput(ns("st_viz"))
          ),
          box(title = "Three cases at every node", status = "info", solidHeader = TRUE, width = 4,
            pseudo(c("def query(node, lo, hi, l, r):", "    if r < lo or hi < l: return IDENTITY   # disjoint",
                     "    if l <= lo and hi <= r: return tree[node]  # inside", "    mid = (lo + hi) // 2",
                     "    return combine(query(2n, lo, mid, l, r),", "                   query(2n+1, mid+1, hi, l, r))")),
            uiOutput(ns("st_kpi")),
            callout("At most <b>two partial nodes per level</b> are expanded, so a query visits O(log n) nodes — even for a range covering almost everything.", "tip"))
        ),
        fluidRow(
          box(title = "Which structure? — cost of q queries + u updates", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(column(4, sliderInput(ns("cmp_n"), "Array size n:", 1000, 200000, 100000, step = 1000)),
                     column(4, sliderInput(ns("cmp_u"), "Share of operations that are updates:", 0, 1, 0.5, step = 0.05)),
                     column(4, sliderInput(ns("cmp_q"), "Total operations:", 1000, 200000, 100000, step = 1000))),
            plotlyOutput(ns("cmp_plot"), height = "300px")),
          box(title = "Decision guide", status = "info", solidHeader = TRUE, width = 4,
            cplx_table(data.frame(
              Situation = c("No updates", "Point update + range sum", "Range min / max / gcd", "Range update + range query", "Offline, sortable queries"),
              Use = c("prefix sums", "Fenwick tree", "segment tree", "segment tree + lazy", "sort + sweep, or Mo's"),
              stringsAsFactors = FALSE)))
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("'Immutable' in the title (#303, #304) → plain prefix sums.",
                   "'update' and 'sumRange' both called up to 10⁴–10⁵ times (#307) → Fenwick or segment tree.",
                   "Count of smaller elements after self, reverse pairs (#315, #493) → BIT over compressed values.",
                   "Range min / max with updates, or overlapping bookings (#732, #715) → segment tree."),
          pitfalls = c("Fenwick trees are <b>1-indexed</b>: index 0 makes <code>i &amp; -i</code> zero and loops forever.",
                       "Updating with the <i>new value</i> instead of the <i>difference</i> (<code>val − old</code>).",
                       "Segment tree array of size 2n is only enough for the iterative version; the recursive one needs 4n.",
                       "Forgetting to push lazy tags down before recursing into children."),
          tips = c("Mention the trade-off: prefix sums are O(1) query but O(n) update.",
                   "Fenwick is ~10 lines — usually the fastest correct thing to write in an interview.",
                   "Say 'coordinate-compress the values, then use a BIT of counts' for inversion-style problems.")
        ),
        fluidRow(
          box(title = "Complexity", status = "info", solidHeader = TRUE, width = 6,
            cplx_table(data.frame(
              Structure = c("Recompute every time", "Prefix sums", "Fenwick tree", "Segment tree", "Segment tree + lazy", "Sqrt decomposition"),
              Build = c("—", "O(n)", "O(n log n) / O(n)", "O(n)", "O(n)", "O(n)"),
              Query = c("O(n)", "O(1)", "O(log n)", "O(log n)", "O(log n)", "O(√n)"),
              Point.update = c("O(1)", "O(n)", "O(log n)", "O(log n)", "O(log n)", "O(1)"),
              Range.update = c("O(n)", "O(n)", "O(log n)*", "O(n log n)", "O(log n)", "O(√n)"),
              stringsAsFactors = FALSE)),
            hint("* range update + point query with a BIT over the difference array.")),
          box(title = "2-D prefix sums (#304)", status = "info", solidHeader = TRUE, width = 6,
            dsa_code(
'P = [[0] * (C + 1) for _ in range(R + 1)]
for r in range(R):
    for c in range(C):
        P[r+1][c+1] = M[r][c] + P[r][c+1] + P[r+1][c] - P[r][c]

def region(r1, c1, r2, c2):     # inclusive corners
    return (P[r2+1][c2+1] - P[r1][c2+1]
            - P[r2+1][c1] + P[r1][c1])', "Inclusion–exclusion"))
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(6, dsa_code(
'class BIT:
    def __init__(self, n):
        self.t = [0] * (n + 1)
    def add(self, i, d):          # 1-indexed
        while i < len(self.t):
            self.t[i] += d
            i += i & -i
    def sum(self, i):             # a[1] + ... + a[i]
        s = 0
        while i > 0:
            s += self.t[i]
            i -= i & -i
        return s
    def range(self, l, r):
        return self.sum(r) - self.sum(l - 1)', "Fenwick tree")),
              column(6, dsa_code(
'class SegTree:                     # iterative, sum
    def __init__(self, a):
        self.n = n = len(a)
        self.t = [0] * n + a
        for i in range(n - 1, 0, -1):
            self.t[i] = self.t[2*i] + self.t[2*i+1]
    def update(self, i, v):
        i += self.n; self.t[i] = v
        while i > 1:
            i //= 2
            self.t[i] = self.t[2*i] + self.t[2*i+1]
    def query(self, l, r):         # inclusive
        s, l, r = 0, l + self.n, r + self.n + 1
        while l < r:
            if l & 1: s += self.t[l]; l += 1
            if r & 1: r -= 1; s += self.t[r]
            l //= 2; r //= 2
        return s', "Segment tree (bottom-up)")))
          )
        )
      ),

      practice = practice_tab(ns, "rangeq",
        "Fenwick, P. M. (1994). A new data structure for cumulative frequency tables. Software: Practice and Experience, 24(3), 327–336.",
        "Bentley, J. L. (1977). Solutions to Klee's rectangle problems. Carnegie Mellon University technical report.",
        "Halim, S. & Halim, F. (2013). Competitive Programming 3 — ch. 2.4, data structures with libraries.")
    )
  )
}

rangeq_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    lowbit <- function(i) bitwAnd(i, -i)
    bin <- function(i, w = 5) paste(rev(as.integer(intToBits(i))[1:w]), collapse = "")

    # ── Fenwick ──────────────────────────────────────────────────────────────
    fw_arr <- reactive({
      a <- parse_ints(input$fw_arr)
      validate(need(length(a) >= 2, "Enter at least two integers."))
      head(a, 16)
    })
    fw_build <- function(a) { n <- length(a); t <- numeric(n); for (i in seq_len(n)) { j <- i; while (j <= n) { t[j] <- t[j] + a[i]; j <- j + lowbit(j) } }; t }
    fw_steps <- reactive({
      a <- fw_arr(); n <- length(a); t <- fw_build(a)
      i <- max(1, min(n, as.integer(input$fw_i %||% 1))); d <- as.numeric(input$fw_d %||% 0); if (is.na(d)) d <- 0
      steps <- list(list(a = a, t = t, cur = NULL, path = integer(0), acc = 0,
        msg = sprintf("tree[k] holds the sum of a[k − lowbit(k) + 1 .. k]. %s starts at i = %d (binary %s).",
                      if (input$fw_op == "query") "Prefix query" else "Point update", i, bin(i))))
      if (input$fw_op == "query") {
        j <- i; acc <- 0; path <- integer(0)
        while (j > 0) {
          acc <- acc + t[j]; path <- c(path, j)
          steps[[length(steps) + 1]] <- list(a = a, t = t, cur = j, path = path, acc = acc,
            msg = sprintf("Add tree[%d] = %g (covers a[%d..%d]). Running sum = <b>%g</b>. Next: %d − lowbit(%d) = %d − %d = %d.",
                          j, t[j], j - lowbit(j) + 1, j, acc, j, j, j, lowbit(j), j - lowbit(j)))
          j <- j - lowbit(j)
        }
        steps[[length(steps) + 1]] <- list(a = a, t = t, cur = NULL, path = path, acc = acc,
          msg = sprintf("Reached 0. sum(a[1..%d]) = <b>%g</b> using %d cells instead of %d additions (check: %g).", i, acc, length(path), i, sum(a[1:i])))
      } else {
        j <- i; path <- integer(0)
        a2 <- a; a2[i] <- a2[i] + d
        while (j <= n) {
          t[j] <- t[j] + d; path <- c(path, j)
          steps[[length(steps) + 1]] <- list(a = a2, t = t, cur = j, path = path, acc = NA,
            msg = sprintf("tree[%d] covers a[%d..%d], which contains a[%d] → tree[%d] += %g = <b>%g</b>. Next: %d + lowbit(%d) = %d.",
                          j, j - lowbit(j) + 1, j, i, j, d, t[j], j, j, j + lowbit(j)))
          j <- j + lowbit(j)
        }
        steps[[length(steps) + 1]] <- list(a = a2, t = t, cur = NULL, path = path, acc = NA,
          msg = sprintf("Index %d is past n = %d. Updated %d cells — every cell whose range contains position %d.", j, n, length(path), i))
      }
      steps
    })
    fw <- stepper_server(input, output, session, "fw", fw_steps, speed = 900)
    output$fw_plot <- renderPlotly({
      s <- fw$cur(); n <- length(s$a); k <- seq_len(n)
      cols <- ifelse(k %in% s$path, COL$warn, "#c7d2fe"); if (!is.null(s$cur)) cols[s$cur] <- COL$pri
      plot_ly(height = 300) %>%
        add_bars(y = k, x = vapply(k, lowbit, 0), base = k - vapply(k, lowbit, 0) + 0.5, orientation = "h",
                 marker = list(color = cols, line = list(color = "#fff", width = 1)),
                 text = sprintf("tree[%d] = %g", k, s$t), textposition = "inside", insidetextfont = list(color = "#1e293b", size = 10),
                 hoverinfo = "text", hovertext = sprintf("tree[%d] = sum a[%d..%d] = %g", k, k - vapply(k, lowbit, 0) + 1, k, s$t), showlegend = FALSE) %>%
        dsa_layout(xt = "array position covered", yt = "tree index") %>%
        layout(xaxis = list(range = c(0.5, n + 0.5), dtick = 1), yaxis = list(dtick = 1, autorange = "reversed"))
    })
    output$fw_viz <- renderUI({
      s <- fw$cur(); n <- length(s$a)
      tc <- ifelse(seq_len(n) %in% s$path, "visited", ""); if (!is.null(s$cur)) tc[s$cur] <- "active"
      tagList(tags$div(class = "code-title", "a[1..n]"), vrow(s$a, idx = FALSE),
              tags$div(class = "code-title", "tree[1..n]"), vrow(s$t, tc, idx = FALSE),
              explain(s$msg))
    })
    output$fw_bits <- renderUI({
      s <- fw$cur(); p <- s$path
      if (!length(p)) p <- max(1, min(length(fw_arr()), as.integer(input$fw_i %||% 1)))
      cplx_table(data.frame(i = p, binary = vapply(p, bin, ""), lowbit = vapply(p, lowbit, 0),
                            covers = sprintf("a[%d..%d]", p - vapply(p, lowbit, 0) + 1, p), stringsAsFactors = FALSE))
    })

    # ── Segment tree ─────────────────────────────────────────────────────────
    st_arr <- reactive({
      a <- parse_ints(input$st_arr)
      validate(need(length(a) >= 2, "Enter at least two integers."))
      head(a, 16)
    })
    st_struct <- reactive({
      a <- st_arr(); n <- length(a); f <- switch(input$st_agg, sum = sum, min = min, max = max)
      nodes <- list()
      build <- function(id, lo, hi, depth) {
        val <- f(a[lo:hi]); nodes[[as.character(id)]] <<- list(id = id, lo = lo, hi = hi, depth = depth, val = val)
        if (lo < hi) { mid <- (lo + hi) %/% 2; build(2 * id, lo, mid, depth + 1); build(2 * id + 1, mid + 1, hi, depth + 1) }
      }
      build(1, 1, n, 0)
      nd <- do.call(rbind, lapply(nodes, as.data.frame))
      nd$x <- (nd$lo + nd$hi) / 2; nd$y <- -nd$depth
      nd
    })
    st_steps <- reactive({
      nd <- st_struct(); a <- st_arr(); n <- length(a)
      l <- max(0, min(n - 1, as.integer(input$st_l %||% 0))) + 1; r <- max(0, min(n - 1, as.integer(input$st_r %||% (n - 1)))) + 1
      if (l > r) { t <- l; l <- r; r <- t }
      f <- switch(input$st_agg, sum = sum, min = min, max = max)
      state <- setNames(rep("idle", nrow(nd)), nd$id); used <- numeric(0)
      steps <- list(list(state = state, cur = NULL, used = used, l = l, r = r,
        msg = sprintf("Query %s(a[%d..%d]) (0-indexed). Start at the root, which covers the whole array.", input$st_agg, l - 1, r - 1)))
      visit <- function(id) {
        row <- nd[nd$id == id, ]
        if (r < row$lo || row$hi < l) {
          state[as.character(id)] <<- "bad"
          steps[[length(steps) + 1]] <<- list(state = state, cur = id, used = used, l = l, r = r,
            msg = sprintf("Node [%d..%d] is disjoint from [%d..%d] → return identity, don't descend.", row$lo - 1, row$hi - 1, l - 1, r - 1))
          return()
        }
        if (l <= row$lo && row$hi <= r) {
          state[as.character(id)] <<- "done"; used <<- c(used, row$val)
          steps[[length(steps) + 1]] <<- list(state = state, cur = id, used = used, l = l, r = r,
            msg = sprintf("Node [%d..%d] lies fully inside → use its stored value <b>%g</b> without looking below.", row$lo - 1, row$hi - 1, row$val))
          return()
        }
        state[as.character(id)] <<- "frontier"
        steps[[length(steps) + 1]] <<- list(state = state, cur = id, used = used, l = l, r = r,
          msg = sprintf("Node [%d..%d] partially overlaps → recurse into both children.", row$lo - 1, row$hi - 1))
        visit(2 * id); visit(2 * id + 1)
      }
      visit(1)
      steps[[length(steps) + 1]] <- list(state = state, cur = NULL, used = used, l = l, r = r,
        msg = sprintf("Combine the %d green nodes → %s = <b>%g</b> (check: %g). Visited %d of %d nodes.",
                      length(used), input$st_agg, f(used), f(a[l:r]), sum(state != "idle"), nrow(nd)))
      steps
    })
    st <- stepper_server(input, output, session, "st", st_steps, speed = 800)
    output$st_plot <- renderPlotly({
      nd <- st_struct(); s <- st$cur()
      nd$label <- nd$val
      nd$sub <- sprintf("[%d..%d]", nd$lo - 1, nd$hi - 1)
      nd$hover <- sprintf("node %d covers a[%d..%d] → %s = %g", nd$id, nd$lo - 1, nd$hi - 1, input$st_agg, nd$val)
      stt <- unname(s$state[as.character(nd$id)]); if (!is.null(s$cur)) stt[nd$id == s$cur] <- "active"
      nd <- state_style(nd, stt)
      ed <- do.call(rbind, lapply(nd$id[nd$id > 1], function(id) { c <- nd[nd$id == id, ]; p <- nd[nd$id == id %/% 2, ]; data.frame(x0 = p$x, y0 = p$y, x1 = c$x, y1 = c$y) }))
      net_plot(nd, ed, size = 32, height = 340)
    })
    output$st_viz <- renderUI({
      s <- st$cur(); a <- st_arr()
      cls <- ifelse(seq_along(a) >= s$l & seq_along(a) <= s$r, "visited", "")
      tagList(tags$div(class = "code-title", "array (query range highlighted)"), vrow(a, cls), explain(s$msg))
    })
    output$st_kpi <- renderUI({
      s <- st$cur(); nd <- st_struct()
      kpi_row(kpi(sum(s$state != "idle"), "nodes visited"), kpi(length(s$used), "nodes combined", COL$ok),
              kpi(nrow(nd), "nodes in tree", COL$mute))
    })

    # ── Cost comparison ──────────────────────────────────────────────────────
    output$cmp_plot <- renderPlotly({
      n <- input$cmp_n; ops <- input$cmp_q; fu <- input$cmp_u
      u <- ops * fu; q <- ops - u; lg <- log2(n)
      d <- data.frame(method = c("Recompute each query", "Prefix sums", "Fenwick tree", "Segment tree", "Sqrt decomposition"),
                      cost = c(q * n + u, n + q + u * n, n * lg + (q + u) * lg, 2 * n + (q + u) * 2 * lg, n + q * sqrt(n) + u))
      d$method <- factor(d$method, levels = d$method[order(d$cost)])
      plot_ly(d, x = ~cost, y = ~method, type = "bar", orientation = "h", height = 300,
              marker = list(color = ifelse(d$cost == min(d$cost), COL$ok, COL$pri)),
              text = ~formatC(cost, format = "e", digits = 1), textposition = "auto", hoverinfo = "x+y") %>%
        dsa_layout(xt = "approximate elementary operations (log scale)") %>% layout(xaxis = list(type = "log"))
    })

    quiz_server(input, output, session, topic = "rangeq", progress = progress, questions = list(
      list(q = "What does i & -i compute?", opts = c("The highest set bit of i", "The lowest set bit of i", "i mod 2", "The number of set bits"), ans = 2,
           why = "Two's complement flips all bits above the lowest 1, so AND keeps only that bit."),
      list(q = "Why must a Fenwick tree be 1-indexed?", opts = c("Python lists start at 1", "lowbit(0) = 0, so loops on index 0 never move", "It saves memory", "Segment trees need it"), ans = 2,
           why = "With i = 0, i += i & -i adds zero forever."),
      list(q = "#303 Range Sum Query – Immutable: best approach?", opts = c("Segment tree", "Fenwick tree", "Prefix sums, O(1) per query", "Sort the array"), ans = 3,
           why = "No updates means precomputing prefix sums once gives O(1) queries."),
      list(q = "A segment-tree range query visits O(log n) nodes because…", opts = c("It only visits leaves", "At most two partially overlapping nodes are expanded per level", "The tree has log n nodes", "It uses binary search on values"), ans = 2,
           why = "Only nodes containing a boundary of [l, r] are partial; there are at most two such nodes per level."),
      list(q = "To support 'add v to every element in [l, r]' and 'range sum' both in O(log n) you need…", opts = c("Prefix sums", "A plain Fenwick tree", "A segment tree with lazy propagation (or two BITs)", "A heap"), ans = 3,
           why = "Lazy tags postpone range updates until a query actually needs the children.")
    ))
  })
}
