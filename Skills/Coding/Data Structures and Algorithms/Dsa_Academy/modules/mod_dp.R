# modules/mod_dp.R — Dynamic Programming

# ── Table builders: each returns the finished table plus the fill order ──────
dp_build_lcs <- function(a, b) {
  A <- strsplit(a, "")[[1]]; B <- strsplit(b, "")[[1]]; m <- length(A); n <- length(B)
  dp <- matrix(0, m + 1, n + 1); base <- matrix(FALSE, m + 1, n + 1); base[1, ] <- TRUE; base[, 1] <- TRUE
  cells <- list()
  for (i in seq_len(m)) for (j in seq_len(n)) {
    if (A[i] == B[j]) {
      dp[i + 1, j + 1] <- dp[i, j] + 1
      cells[[length(cells) + 1]] <- list(cur = c(i + 1, j + 1), deps = list(c(i, j)),
        msg = sprintf("<b>%s = %s</b> → the characters match, extend the diagonal: 1 + %d = <b>%d</b>.", A[i], B[j], dp[i, j], dp[i + 1, j + 1]))
    } else {
      dp[i + 1, j + 1] <- max(dp[i, j + 1], dp[i + 1, j])
      cells[[length(cells) + 1]] <- list(cur = c(i + 1, j + 1), deps = list(c(i, j + 1), c(i + 1, j)),
        msg = sprintf("%s ≠ %s → drop one character from either string and keep the better: max(up %d, left %d) = <b>%d</b>.", A[i], B[j], dp[i, j + 1], dp[i + 1, j], dp[i + 1, j + 1]))
    }
  }
  i <- m; j <- n; path <- list(); out <- character(0)
  while (i > 0 && j > 0) {
    if (A[i] == B[j]) { path[[length(path) + 1]] <- c(i + 1, j + 1); out <- c(A[i], out); i <- i - 1; j <- j - 1 }
    else if (dp[i, j + 1] >= dp[i + 1, j]) i <- i - 1 else j <- j - 1
  }
  list(dp = dp, rlab = c("∅", A), clab = c("∅", B), base = base, cells = cells, path = path,
       intro = "Row i / column j holds the LCS length of the first i characters of A and the first j of B. The ∅ row and column are the base case: an empty string shares nothing.",
       summary = sprintf("<b>LCS length = %d</b> (\"%s\"). Green cells are the matches found by walking back from the bottom-right corner.", dp[m + 1, n + 1], paste(out, collapse = "")))
}

dp_build_edit <- function(a, b) {
  A <- strsplit(a, "")[[1]]; B <- strsplit(b, "")[[1]]; m <- length(A); n <- length(B)
  dp <- matrix(0, m + 1, n + 1); dp[, 1] <- 0:m; dp[1, ] <- 0:n
  base <- matrix(FALSE, m + 1, n + 1); base[1, ] <- TRUE; base[, 1] <- TRUE
  cells <- list()
  for (i in seq_len(m)) for (j in seq_len(n)) {
    if (A[i] == B[j]) {
      dp[i + 1, j + 1] <- dp[i, j]
      cells[[length(cells) + 1]] <- list(cur = c(i + 1, j + 1), deps = list(c(i, j)),
        msg = sprintf("<b>%s = %s</b> → no edit needed, copy the diagonal: <b>%d</b>.", A[i], B[j], dp[i, j]))
    } else {
      opts <- c(replace = dp[i, j], delete = dp[i, j + 1], insert = dp[i + 1, j])
      dp[i + 1, j + 1] <- 1 + min(opts)
      cells[[length(cells) + 1]] <- list(cur = c(i + 1, j + 1), deps = list(c(i, j), c(i, j + 1), c(i + 1, j)),
        msg = sprintf("%s ≠ %s → 1 + min(replace %d, delete %d, insert %d) = <b>%d</b> (cheapest: %s).", A[i], B[j], opts[1], opts[2], opts[3], dp[i + 1, j + 1], names(opts)[which.min(opts)]))
    }
  }
  i <- m; j <- n; path <- list(c(m + 1, n + 1))
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && A[i] == B[j]) { i <- i - 1; j <- j - 1 }
    else if (i > 0 && j > 0 && dp[i + 1, j + 1] == dp[i, j] + 1) { i <- i - 1; j <- j - 1 }
    else if (i > 0 && dp[i + 1, j + 1] == dp[i, j + 1] + 1) i <- i - 1
    else j <- j - 1
    path[[length(path) + 1]] <- c(i + 1, j + 1)
  }
  list(dp = dp, rlab = c("∅", A), clab = c("∅", B), base = base, cells = cells, path = path,
       intro = "Cell (i, j) is the minimum number of edits to turn the first i characters of A into the first j of B. Base case: turning a prefix into the empty string costs one deletion per character.",
       summary = sprintf("<b>Edit distance = %d.</b> The green path from the corner back to the origin is one optimal sequence of edits: a diagonal step is keep/replace, up is delete, left is insert.", dp[m + 1, n + 1]))
}

dp_build_knap <- function(w, v, W) {
  n <- length(w); dp <- matrix(0, n + 1, W + 1)
  base <- matrix(FALSE, n + 1, W + 1); base[1, ] <- TRUE
  cells <- list()
  for (i in seq_len(n)) for (c in 0:W) {
    skip <- dp[i, c + 1]
    if (w[i] <= c) {
      take <- dp[i, c - w[i] + 1] + v[i]
      dp[i + 1, c + 1] <- max(skip, take)
      cells[[length(cells) + 1]] <- list(cur = c(i + 1, c + 1), deps = list(c(i, c + 1), c(i, c - w[i] + 1)),
        msg = sprintf("Item %d (weight %d, value %d), capacity %d: <b>skip</b> = %d, <b>take</b> = %d + best with capacity %d (%d) = %d → <b>%d</b>.",
                      i, w[i], v[i], c, skip, v[i], c - w[i], dp[i, c - w[i] + 1], take, dp[i + 1, c + 1]))
    } else {
      dp[i + 1, c + 1] <- skip
      cells[[length(cells) + 1]] <- list(cur = c(i + 1, c + 1), deps = list(c(i, c + 1)),
        msg = sprintf("Item %d weighs %d &gt; capacity %d → it cannot fit, copy the row above: <b>%d</b>.", i, w[i], c, skip))
    }
  }
  i <- n; c <- W; path <- list(); chosen <- integer(0)
  while (i > 0) {
    path[[length(path) + 1]] <- c(i + 1, c + 1)
    if (dp[i + 1, c + 1] != dp[i, c + 1]) { chosen <- c(i, chosen); c <- c - w[i] }
    i <- i - 1
  }
  list(dp = dp, rlab = c("none", sprintf("#%d w%d v%d", seq_len(n), w, v)), clab = 0:W, base = base, cells = cells, path = path,
       intro = "Row i considers only the first i items; column c is the capacity. Each cell is the best value achievable. Row 'none' is the base case: no items, no value.",
       summary = sprintf("<b>Best value = %d</b> using item(s) %s (total weight %d of %d). Walking up from the corner: whenever a cell differs from the one above it, that item was taken.",
                         dp[n + 1, W + 1], if (length(chosen)) paste0("#", chosen, collapse = ", ") else "none", sum(w[chosen]), W))
}

dp_ui <- function(id) {
  ns <- NS(id)
  cond <- function(v) sprintf("input['%s'] == '%s'", ns("kind"), v)
  tagList(
    topic_hero("🧩", "Dynamic Programming",
      "Recursion that remembers. When a problem breaks into overlapping subproblems with optimal substructure, solve each subproblem once, store it, and build the answer from smaller answers.",
      c("Overlapping Subproblems", "Memoisation", "Tabulation", "State & Transition", "Knapsack", "Two-String DP")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Why memoise? The Fibonacci call tree", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(5, sliderInput(ns("fib_n"), "Compute fib(n):", min = 3, max = 7, value = 6, step = 1)),
              column(7, radioButtons(ns("fib_mode"), "Strategy:", inline = TRUE, c("Naive recursion" = "naive", "With memoisation" = "memo")))
            ),
            plotlyOutput(ns("fib_plot"), height = "330px"),
            uiOutput(ns("fib_explain"))
          ),
          box(title = "From exponential to linear", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("fib_kpi")),
            plotlyOutput(ns("fib_growth"), height = "230px"),
            hint("Same colour = same subproblem. Naive recursion recomputes them again and again; a cache answers every repeat in O(1).")
          )
        ),
        fluidRow(
          box(title = "Filling a DP Table — step by step", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(3, selectInput(ns("kind"), "Problem:", c("Longest Common Subsequence" = "lcs", "Edit Distance" = "edit", "0/1 Knapsack" = "knap"))),
              column(5,
                conditionalPanel(cond("lcs"), fluidRow(column(6, textInput(ns("lcs_a"), "String A:", "AGGTAB")), column(6, textInput(ns("lcs_b"), "String B:", "GXTXAYB")))),
                conditionalPanel(cond("edit"), fluidRow(column(6, textInput(ns("ed_a"), "From:", "horse")), column(6, textInput(ns("ed_b"), "To:", "ros")))),
                conditionalPanel(cond("knap"), fluidRow(column(4, textInput(ns("kn_w"), "Weights:", "1,3,4,5")), column(4, textInput(ns("kn_v"), "Values:", "1,4,5,7")), column(4, numericInput(ns("kn_W"), "Capacity:", 7, min = 1, max = 12))))
              ),
              column(4, stepper_ui(ns, "tb"))
            ),
            fluidRow(
              column(8, uiOutput(ns("tb_grid")),
                legend_row(c("computing now" = COL$pri, "cells it reads" = "#fef3c7", "base case" = "#e2e8f0", "filled" = "#eef2ff", "answer path" = COL$ok))),
              column(4, uiOutput(ns("tb_explain")), uiOutput(ns("tb_rule")))
            )
          )
        ),
        fluidRow(
          box(title = "1D DP — Coin Change (fewest coins)", status = "primary", solidHeader = TRUE, width = 7,
            fluidRow(
              column(5, textInput(ns("cc_coins"), "Coin values:", "1,3,4")),
              column(3, numericInput(ns("cc_amt"), "Amount:", 6, min = 1, max = 20)),
              column(4, tags$div())
            ),
            stepper_ui(ns, "cc"),
            uiOutput(ns("cc_viz"))
          ),
          box(title = "Longest Increasing Subsequence", status = "primary", solidHeader = TRUE, width = 5,
            textInput(ns("lis_arr"), "Array:", "10,9,2,5,3,7,101,18,4,20"),
            plotlyOutput(ns("lis_plot"), height = "250px"),
            uiOutput(ns("lis_explain"))
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("The question asks for a <b>count</b>, a <b>min / max</b>, or <b>true / false</b> — not the list of all solutions.",
                   "A brute-force recursion exists and the same arguments keep reappearing.",
                   "Choices at each step (take / skip, match / edit) and the best overall is built from best sub-answers.",
                   "Greedy fails on a counter-example — DP tries every option safely."),
          pitfalls = c("Defining a state that is missing information (e.g. forgetting 'remaining capacity' or 'last index used').",
                       "Wrong iteration order: a cell must be computed after everything it reads.",
                       "0/1 knapsack in 1D: iterate capacity <b>downwards</b>, or an item gets reused.",
                       "Off-by-one between string index i and table row i + 1 — the extra row and column are the empty-prefix base case."),
          tips = c("Follow the recipe out loud: <b>state → transition → base case → order → answer</b>.",
                   "Start top-down with <code>@lru_cache</code>: it is the brute force plus one line. Convert to a table only if asked.",
                   "Complexity = number of states × work per state. Say both numbers.")
        ),
        fluidRow(
          box(title = "The five-step recipe", status = "primary", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Step = c("1. State", "2. Transition", "3. Base case", "4. Order", "5. Answer"),
              Ask.yourself = c("What do I need to know to describe a subproblem?", "How does a state's answer come from smaller states?", "Which states are known without any work?", "In what order are states available when needed?", "Which state (or combination) is the final result?"),
              Coin.change = c("dp[a] = fewest coins for amount a", "dp[a] = 1 + min(dp[a − c]) over coins c", "dp[0] = 0", "a = 1 … amount", "dp[amount]"),
              stringsAsFactors = FALSE))
          ),
          box(title = "Top-down vs bottom-up", status = "info", solidHeader = TRUE, width = 3,
            cplx_table(data.frame(
              . = c("Style", "Computes", "Risk", "Space trick"),
              Memoisation = c("Recursion + cache", "Only states reached", "Stack overflow", "Hard"),
              Tabulation = c("Loops + table", "Every state", "Wrong order", "Keep last row(s)"),
              stringsAsFactors = FALSE))
          ),
          box(title = "DP families", status = "info", solidHeader = TRUE, width = 4,
            cplx_table(data.frame(
              Family = c("Linear 1D", "Grid", "Two strings", "Knapsack", "Interval", "Bitmask"),
              State = c("dp[i]", "dp[r][c]", "dp[i][j]", "dp[i][cap]", "dp[l][r]", "dp[mask][i]"),
              Examples = c("#70, #198, #300", "#62, #64", "#1143, #72", "#416, #322", "#312, #516", "TSP, #847"),
              stringsAsFactors = FALSE))
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4,
                dsa_code(
'def coinChange(coins, amount):
    dp = [0] + [inf] * amount
    for a in range(1, amount + 1):
        for c in coins:
            if c <= a:
                dp[a] = min(dp[a], dp[a - c] + 1)
    return dp[amount] if dp[amount] < inf else -1', "Coin change — unbounded knapsack"),
                dsa_code(
'def rob(nums):
    prev = cur = 0
    for x in nums:                 # skip x  vs  take x
        prev, cur = cur, max(cur, prev + x)
    return cur', "House robber — O(1) space")
              ),
              column(4,
                dsa_code(
'def longestCommonSubsequence(a, b):
    m, n = len(a), len(b)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if a[i-1] == b[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    return dp[m][n]', "LCS — two-string DP"),
                dsa_code(
'def canPartition(nums):          # 0/1 knapsack, 1D
    total = sum(nums)
    if total % 2: return False
    dp = [True] + [False] * (total // 2)
    for x in nums:
        for s in range(total // 2, x - 1, -1):   # downwards!
            dp[s] = dp[s] or dp[s - x]
    return dp[-1]', "0/1 knapsack in one row")
              ),
              column(4,
                dsa_code(
'def wordBreak(s, words):
    words = set(words)
    @lru_cache(None)
    def ok(i):                    # can s[i:] be segmented?
        if i == len(s): return True
        return any(s[i:j] in words and ok(j)
                   for j in range(i + 1, len(s) + 1))
    return ok(0)', "Top-down with lru_cache"),
                dsa_code(
'def lengthOfLIS(nums):
    tails = []                    # tails[k] = smallest tail
    for x in nums:                # of an increasing run of length k+1
        i = bisect.bisect_left(tails, x)
        if i == len(tails): tails.append(x)
        else:               tails[i] = x
    return len(tails)', "LIS in O(n log n)")
              )
            )
          )
        )
      ),

      practice = practice_tab(ns, "dp",
        "Bellman, R. (1957). Dynamic Programming. Princeton University Press.",
        "Cormen, Leiserson, Rivest & Stein (2022). Introduction to Algorithms (4th ed.) — ch. 14.",
        "Wagner & Fischer (1974). The string-to-string correction problem. JACM 21(1) — edit distance.")
    )
  )
}

dp_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    # ── Fibonacci call tree ──────────────────────────────────────────────────
    fib_tree <- reactive({
      n <- input$fib_n; memo <- input$fib_mode == "memo"; req(n)
      rows <- list(); edges <- list(); leafx <- 0; seen <- integer(0)
      build <- function(k, depth) {
        id <- length(rows) + 1
        rows[[id]] <<- list(k = k, depth = depth, x = NA, cached = FALSE)
        cached <- memo && k >= 2 && (k %in% seen)
        if (k < 2 || cached) { leafx <<- leafx + 1; rows[[id]]$x <<- leafx; rows[[id]]$cached <<- cached }
        else {
          c1 <- build(k - 1, depth + 1); c2 <- build(k - 2, depth + 1)
          seen <<- c(seen, k)
          rows[[id]]$x <<- (rows[[c1]]$x + rows[[c2]]$x) / 2
          edges[[length(edges) + 1]] <<- c(id, c1); edges[[length(edges) + 1]] <<- c(id, c2)
        }
        id
      }
      build(n, 0)
      nodes <- data.frame(k = vapply(rows, function(r) r$k, numeric(1)), x = vapply(rows, function(r) r$x, numeric(1)),
                          y = -vapply(rows, function(r) r$depth, numeric(1)), cached = vapply(rows, function(r) r$cached, logical(1)))
      em <- do.call(rbind, edges)
      list(nodes = nodes, edges = data.frame(x0 = nodes$x[em[, 1]], y0 = nodes$y[em[, 1]], x1 = nodes$x[em[, 2]], y1 = nodes$y[em[, 2]]), n = n, memo = memo)
    })
    output$fib_plot <- renderPlotly({
      t <- fib_tree(); nd <- t$nodes
      pal <- c("#94a3b8", "#64748b", "#06b6d4", "#10b981", "#f59e0b", "#ec4899", "#7c3aed", "#4f46e5")
      nd$label <- ifelse(nd$cached, paste0("f", nd$k, "✓"), paste0("f(", nd$k, ")"))
      nd$color <- ifelse(nd$cached, "#ffffff", pal[nd$k + 1]); nd$border <- pal[nd$k + 1]
      nd$tcol <- ifelse(nd$cached, pal[nd$k + 1], "#ffffff")
      nd$hover <- ifelse(nd$cached, sprintf("fib(%d): answered from the cache", nd$k), sprintf("fib(%d): computed", nd$k))
      net_plot(nd, t$edges, size = if (t$n >= 7 && !t$memo) 26 else 34, height = 330)
    })
    fib_calls <- function(n) { f <- c(1, 1); for (i in sq(3, n + 1)) f[i] <- f[i - 1] + f[i - 2]; 2 * f[n + 1] - 1 }
    output$fib_kpi <- renderUI({
      n <- input$fib_n; req(n)
      kpi_row(kpi(fib_calls(n), "naive calls", COL$err), kpi(2 * n - 1, "memoised calls", COL$ok), kpi(n + 1, "distinct subproblems", COL$pri))
    })
    output$fib_explain <- renderUI({
      t <- fib_tree(); n <- t$n
      if (!t$memo) explain(sprintf("Computing fib(%d) naively makes <b>%d calls</b>, yet there are only %d distinct subproblems. Look for the repeated colours: fib(2) alone is recomputed %d times. That waste is what DP removes.",
                                   n, nrow(t$nodes), n + 1, sum(t$nodes$k == 2)))
      else explain(sprintf("With a cache the tree collapses to <b>%d calls</b>. Outlined nodes (✓) return instantly — their value was stored the first time. The left spine does all the real work: O(n) instead of O(1.6ⁿ).", nrow(t$nodes)))
    })
    output$fib_growth <- renderPlotly({
      n <- 2:30
      plot_ly(x = n, height = 230) %>%
        add_trace(y = vapply(n, fib_calls, numeric(1)), type = "scatter", mode = "lines", name = "naive", line = list(color = COL$err, width = 3)) %>%
        add_trace(y = 2 * n - 1, type = "scatter", mode = "lines", name = "memoised", line = list(color = COL$ok, width = 3)) %>%
        dsa_layout(xt = "n", yt = "calls (log)", legend = TRUE) %>% layout(yaxis = list(type = "log"))
    })

    # ── Table fill ───────────────────────────────────────────────────────────
    clean <- function(x, n) { x <- gsub("\\s", "", x %||% ""); substr(x, 1, n) }
    tb <- reactive({
      switch(input$kind,
        lcs = { a <- toupper(clean(input$lcs_a, 8)); b <- toupper(clean(input$lcs_b, 8))
                validate(need(nzchar(a) && nzchar(b), "Enter two strings (up to 8 characters each).")); dp_build_lcs(a, b) },
        edit = { a <- tolower(clean(input$ed_a, 8)); b <- tolower(clean(input$ed_b, 8))
                 validate(need(nzchar(a) && nzchar(b), "Enter two words (up to 8 characters each).")); dp_build_edit(a, b) },
        knap = { w <- parse_ints(input$kn_w, 5); v <- parse_ints(input$kn_v, 5); W <- input$kn_W
                 validate(need(length(w) >= 1 && length(w) == length(v), "Weights and values need the same number of entries (up to 5)."),
                          need(all(w > 0), "Weights must be positive."), need(!is.null(W) && !is.na(W) && W >= 1 && W <= 12, "Capacity must be between 1 and 12."))
                 dp_build_knap(w, v, as.integer(W)) })
    })
    tb_steps <- reactive({
      t <- tb(); K <- length(t$cells)
      c(list(list(k = 0, final = FALSE, msg = t$intro)),
        lapply(seq_len(K), function(k) list(k = k, final = FALSE, msg = t$cells[[k]]$msg)),
        list(list(k = K, final = TRUE, msg = t$summary)))
    })
    tbs <- stepper_server(input, output, session, "tb", tb_steps, speed = 380)
    output$tb_grid <- renderUI({
      t <- tb(); s <- tbs$cur(); nr <- nrow(t$dp); nc <- ncol(t$dp)
      show <- matrix("", nr, nc); cls <- matrix("g-todo", nr, nc)
      show[t$base] <- t$dp[t$base]; cls[t$base] <- "g-base"
      for (k in seq_len(s$k)) { cc <- t$cells[[k]]$cur; show[cc[1], cc[2]] <- t$dp[cc[1], cc[2]]; cls[cc[1], cc[2]] <- "" }
      if (s$final) { for (p in t$path) cls[p[1], p[2]] <- "g-path" }
      else if (s$k >= 1) {
        cell <- t$cells[[s$k]]
        for (d in cell$deps) cls[d[1], d[2]] <- "g-dep"
        cls[cell$cur[1], cell$cur[2]] <- "g-cur"
      }
      dp_grid(show, t$rlab, t$clab, cls)
    })
    output$tb_explain <- renderUI(explain(tbs$cur()$msg))
    output$tb_rule <- renderUI({
      switch(input$kind,
        lcs = pseudo(c("if a[i] == b[j]:", "    dp[i][j] = dp[i-1][j-1] + 1", "else:", "    dp[i][j] = max(dp[i-1][j],", "                   dp[i][j-1])")),
        edit = pseudo(c("if a[i] == b[j]:", "    dp[i][j] = dp[i-1][j-1]", "else:", "    dp[i][j] = 1 + min(", "        dp[i-1][j-1],  # replace", "        dp[i-1][j],    # delete", "        dp[i][j-1])    # insert")),
        knap = pseudo(c("skip = dp[i-1][c]", "if w[i] <= c:", "    take = v[i] + dp[i-1][c - w[i]]", "    dp[i][c] = max(skip, take)", "else:", "    dp[i][c] = skip")))
    })

    # ── Coin change ──────────────────────────────────────────────────────────
    cc_in <- reactive({
      coins <- sort(unique(parse_ints(input$cc_coins, 5))); amt <- input$cc_amt
      validate(need(length(coins) >= 1 && all(coins > 0), "Enter positive coin values."),
               need(!is.null(amt) && !is.na(amt) && amt >= 1 && amt <= 20, "Amount must be between 1 and 20."))
      list(coins = coins, amt = as.integer(amt))
    })
    cc_steps <- reactive({
      coins <- cc_in()$coins; amt <- cc_in()$amt
      dp <- c(0, rep(Inf, amt)); from <- rep(NA, amt + 1)
      steps <- list(list(a = 0, dp = dp, deps = integer(0), msg = "<code>dp[a]</code> = fewest coins that make amount a. Base case: <code>dp[0] = 0</code> — zero coins make zero."))
      for (a in seq_len(amt)) {
        use <- coins[coins <= a]; cand <- dp[a - use + 1] + 1
        if (length(use) && any(is.finite(cand))) { dp[a + 1] <- min(cand); from[a + 1] <- use[which.min(cand)] }
        opts <- if (length(use)) paste(sprintf("coin %d → dp[%d] + 1 = %s", use, a - use, ifelse(is.finite(cand), cand, "∞")), collapse = "; ") else "no coin fits"
        steps[[length(steps) + 1]] <- list(a = a, dp = dp, deps = a - use, msg = sprintf("Amount <b>%d</b>: try each coin as the <i>last</i> coin. %s. Best = <b>%s</b>.", a, opts, if (is.finite(dp[a + 1])) dp[a + 1] else "impossible"))
      }
      # greedy comparison + reconstruction
      rem <- amt; g <- integer(0); for (c in rev(coins)) while (rem >= c) { g <- c(g, c); rem <- rem - c }
      used <- integer(0); a <- amt; while (a > 0 && !is.na(from[a + 1])) { used <- c(used, from[a + 1]); a <- a - from[a + 1] }
      fin <- if (!is.finite(dp[amt + 1])) "<b>No combination of these coins makes the amount.</b>"
             else sprintf("<b>Answer: %d coin(s)</b> — %s.%s", dp[amt + 1], paste(used, collapse = " + "),
                          if (rem == 0 && length(g) > dp[amt + 1]) sprintf(" Greedy (largest coin first) would use <b>%d</b>: %s. This is the classic case where greedy fails and DP is required.", length(g), paste(g, collapse = " + "))
                          else if (rem == 0) " Greedy happens to agree here — but it is not guaranteed for arbitrary coin sets." else " Greedy gets stuck entirely on this input.")
      steps[[length(steps) + 1]] <- list(a = amt, dp = dp, deps = integer(0), final = TRUE, msg = fin)
      steps
    })
    cc <- stepper_server(input, output, session, "cc", cc_steps)
    output$cc_viz <- renderUI({
      s <- cc$cur(); n <- length(s$dp)
      shown <- ifelse(seq_len(n) - 1 <= s$a, ifelse(is.finite(s$dp), s$dp, "∞"), "·")
      cls <- ifelse(seq_len(n) - 1 <= s$a, "visited", "dim")
      cls[s$deps + 1] <- "frontier"
      cls[s$a + 1] <- if (isTRUE(s$final)) "found" else "active"
      tagList(tags$div(class = "code-title", "dp — index is the amount"),
              vrow(shown, cls, ptr = if (s$a > 0) list(a = s$a + 1) else NULL), explain(s$msg))
    })

    # ── LIS ──────────────────────────────────────────────────────────────────
    lis <- reactive({
      a <- parse_ints(input$lis_arr, 16)
      validate(need(length(a) >= 1, "Enter at least one integer."))
      n <- length(a); dp <- rep(1, n); prev <- rep(NA, n)
      for (i in sq(2, n)) for (j in seq_len(i - 1)) if (a[j] < a[i] && dp[j] + 1 > dp[i]) { dp[i] <- dp[j] + 1; prev[i] <- j }
      k <- which.max(dp); idx <- integer(0); while (!is.na(k)) { idx <- c(k, idx); k <- prev[k] }
      list(a = a, dp = dp, idx = idx)
    })
    output$lis_plot <- renderPlotly({
      r <- lis(); cols <- rep(COL$idle, length(r$a)); cols[r$idx] <- COL$ok
      plot_ly(x = seq_along(r$a) - 1, y = r$a, type = "bar", height = 250, marker = list(color = cols),
              text = paste0("dp=", r$dp), textposition = "outside", hovertext = paste0("value ", r$a, ", LIS ending here: ", r$dp), hoverinfo = "text") %>%
        dsa_layout(xt = "index", yt = "value") %>% layout(xaxis = list(dtick = 1), yaxis = list(range = c(min(0, r$a), max(r$a) * 1.15)))
    })
    output$lis_explain <- renderUI({
      r <- lis()
      explain(sprintf("<code>dp[i]</code> = length of the longest increasing subsequence <b>ending at</b> index i = 1 + the best dp[j] over earlier, smaller values. Longest = <b>%d</b>: [%s]. O(n²) this way; patience sorting with binary search gets O(n log n).",
                      length(r$idx), paste(r$a[r$idx], collapse = ", ")))
    })

    quiz_server(input, output, session, topic = "dp", progress = progress, questions = list(
      list(q = "Which two properties make a problem suitable for dynamic programming?",
           opts = c("Sorted input and unique values", "Overlapping subproblems and optimal substructure", "Small input and recursion", "Greedy choice and monotonicity"), ans = 2,
           why = "Subproblems must repeat (so caching pays off) and an optimal answer must be composed of optimal sub-answers."),
      list(q = "Coins {1, 3, 4}, amount 6. Greedy takes 4 + 1 + 1. The optimum is…",
           opts = c("3 coins — greedy is right", "2 coins: 3 + 3", "1 coin", "4 coins"), ans = 2,
           why = "Taking the largest coin first locks out the better 3 + 3. DP considers every choice of last coin."),
      list(q = "In the LCS table, when <code>a[i] ≠ b[j]</code> the cell takes…",
           opts = c("The diagonal + 1", "The maximum of the cell above and the cell to the left", "Zero", "The minimum of its three neighbours + 1"), ans = 2,
           why = "A mismatch means at least one of the two characters is not in the LCS; try dropping each and keep the better."),
      list(q = "A DP has n × m states and each takes O(1) to compute. Its time complexity is…",
           opts = c("O(n + m)", "O(n · m)", "O(2ⁿ)", "O(n · m · log n)"), ans = 2,
           why = "Time = number of states × work per state."),
      list(q = "In the 1D (single-row) 0/1 knapsack, why iterate capacity from high to low?",
           opts = c("It is faster", "So each item is used at most once — dp[c − w] still holds the previous row's value", "To avoid negative indices", "Because the table is sorted"), ans = 2,
           why = "Going upward would read a value already updated with the current item, effectively allowing it to be taken repeatedly (that is the unbounded variant).")
    ))
  })
}
