# modules/mod_recursion.R — Recursion & Backtracking

recursion_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🔄", "Recursion & Backtracking",
      "Backtracking is depth-first search over a tree of decisions: choose, explore, un-choose. It is brute force made tolerable by abandoning a branch the moment it cannot lead to a solution.",
      c("Decision Tree", "Choose / Explore / Un-choose", "Pruning", "Subsets", "Permutations", "N-Queens")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "The Decision Tree — generating all subsets", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(5, textInput(ns("sub_vals"), "Elements (2–4):", "1,2,3")),
              column(7, stepper_ui(ns, "sub"))
            ),
            plotlyOutput(ns("sub_plot"), height = "330px"),
            uiOutput(ns("sub_viz")),
            legend_row(c("current call" = COL$pri, "explored" = COL$soft, "complete subset (leaf)" = COL$ok, "include branch" = COL$ok, "skip branch" = COL$mute))
          ),
          box(title = "Reading the tree", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("sub_kpi")),
            callout("Each level asks one yes/no question: <i>is element k in the subset?</i> Left = include, right = skip. Every root-to-leaf path is one subset, so n elements give <b>2ⁿ</b> leaves.", "info"),
            pseudo(c("def backtrack(i, path):", "    if i == len(nums):", "        res.append(path[:])   # leaf", "        return",
                     "    path.append(nums[i])     # choose", "    backtrack(i + 1, path)   # explore", "    path.pop()               # un-choose",
                     "    backtrack(i + 1, path)   # skip it"))
          )
        ),
        fluidRow(
          box(title = "N-Queens — watch pruning and backtracking happen", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(4, sliderInput(ns("nq_n"), "Board size N:", min = 4, max = 8, value = 5, step = 1)),
              column(8, stepper_ui(ns, "nq"))
            ),
            fluidRow(
              column(6, uiOutput(ns("nq_board"))),
              column(6, uiOutput(ns("nq_kpi")), uiOutput(ns("nq_explain")))
            ),
            legend_row(c("queen placed" = COL$pri, "trying this square" = "#fde68a", "attacked square" = "#fecaca"))
          ),
          box(title = "Why pruning matters", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("nq_stats")),
            callout("Placing one queen per row already cuts N² choose N boards down to Nᴺ. Rejecting a square the moment it is attacked prunes the entire subtree beneath it — most of the tree is never visited.", "tip")
          )
        ),
        fluidRow(
          box(title = "Generators — count the work", status = "primary", solidHeader = TRUE, width = 7,
            fluidRow(
              column(5, selectInput(ns("gen_kind"), "Generate:", c("Permutations" = "perm", "Combinations (choose k)" = "comb", "Balanced parentheses" = "paren"))),
              column(4, textInput(ns("gen_vals"), "Elements / n pairs:", "1,2,3,4")),
              column(3, numericInput(ns("gen_k"), "k:", 2, min = 1, max = 5))
            ),
            uiOutput(ns("gen_viz"))
          ),
          box(title = "How fast the search space explodes", status = "info", solidHeader = TRUE, width = 5,
            plotlyOutput(ns("space_plot"), height = "280px"),
            hint("The dashed line is ~10⁸ simple operations — roughly one second. Subset problems stop being feasible around n ≈ 25, permutation problems around n ≈ 11.")
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("The problem says <b>all</b> combinations / permutations / partitions / valid configurations.",
                   "Constraints are tiny (n ≤ 20 or so) — a strong hint that exponential search is expected.",
                   "A puzzle with rules that can reject partial answers early (Sudoku, N-Queens, word search).",
                   "You need <i>any one</i> valid arrangement and no greedy rule is obvious."),
          pitfalls = c("Appending <code>path</code> instead of a <b>copy</b> (<code>path[:]</code>) — every result ends up as the same empty list.",
                       "Forgetting to undo the choice, so state leaks into sibling branches.",
                       "Duplicates in the input: sort first and skip <code>nums[i] == nums[i-1]</code> at the same depth.",
                       "Missing or wrong base case → infinite recursion."),
          tips = c("Draw the first two levels of the decision tree before coding; the code is just a DFS over it.",
                   "Name the three parts aloud: <b>choices</b>, <b>constraints</b> (prune), <b>goal</b> (base case).",
                   "State the size of the output: you cannot beat O(2ⁿ) for subsets or O(n!) for permutations because you must write them all.")
        ),
        fluidRow(
          box(title = "The universal template", status = "primary", solidHeader = TRUE, width = 5,
            dsa_code(
'def backtrack(state, choices):
    if is_goal(state):
        results.append(copy(state))
        return
    for choice in choices:
        if not is_valid(state, choice):
            continue                 # prune
        apply(state, choice)         # choose
        backtrack(state, next_choices(choices, choice))
        undo(state, choice)          # un-choose'),
            callout("Every backtracking problem is this function with different <code>is_goal</code>, <code>is_valid</code> and <code>next_choices</code>.", "tip")
          ),
          box(title = "Search-space sizes", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Problem = c("Subsets", "Combinations C(n, k)", "Permutations", "Balanced parentheses (n pairs)", "N-Queens", "Sudoku"),
              Outputs = c("2ⁿ", "n! / (k!(n−k)!)", "n!", "Catalan(n) ≈ 4ⁿ / n^1.5", "few (92 for N = 8)", "1"),
              Time = c("O(n · 2ⁿ)", "O(k · C(n, k))", "O(n · n!)", "O(4ⁿ / √n)", "≪ N! thanks to pruning", "exponential worst case, fast in practice"),
              Key.idea = c("include / skip", "start index avoids reorderings", "used[] set", "open ≤ n, close ≤ open", "column + two diagonal sets", "try digit, check row / col / box"),
              stringsAsFactors = FALSE))
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4,
                dsa_code(
'def permute(nums):
    res, path, used = [], [], [False] * len(nums)
    def bt():
        if len(path) == len(nums):
            res.append(path[:]); return
        for i, x in enumerate(nums):
            if used[i]: continue
            used[i] = True; path.append(x)
            bt()
            path.pop(); used[i] = False
    bt()
    return res', "Permutations"),
                dsa_code(
'def generateParenthesis(n):
    res = []
    def bt(s, open_, close):
        if len(s) == 2 * n:
            res.append(s); return
        if open_ < n:      bt(s + "(", open_ + 1, close)
        if close < open_:  bt(s + ")", open_, close + 1)
    bt("", 0, 0)
    return res', "Generate parentheses — prune by counts")
              ),
              column(4,
                dsa_code(
'def combinationSum(cands, target):
    res = []
    def bt(start, path, remain):
        if remain == 0:
            res.append(path[:]); return
        for i in range(start, len(cands)):
            if cands[i] > remain: continue    # prune
            path.append(cands[i])
            bt(i, path, remain - cands[i])    # i: reuse ok
            path.pop()
    bt(0, [], target)
    return res', "Combination sum"),
                dsa_code(
'def subsetsWithDup(nums):
    nums.sort(); res = []
    def bt(start, path):
        res.append(path[:])
        for i in range(start, len(nums)):
            if i > start and nums[i] == nums[i-1]:
                continue                  # skip duplicate
            path.append(nums[i])
            bt(i + 1, path)
            path.pop()
    bt(0, [])
    return res', "Handling duplicates")
              ),
              column(4,
                dsa_code(
'def solveNQueens(n):
    res, cols, d1, d2 = [], set(), set(), set()
    board = [-1] * n
    def bt(r):
        if r == n:
            res.append(board[:]); return
        for c in range(n):
            if c in cols or r - c in d1 or r + c in d2:
                continue              # attacked → prune
            cols.add(c); d1.add(r - c); d2.add(r + c)
            board[r] = c
            bt(r + 1)
            cols.remove(c); d1.remove(r - c); d2.remove(r + c)
    bt(0)
    return res', "N-Queens — O(1) attack checks"),
                callout("Diagonals have a constant <code>r − c</code>; anti-diagonals a constant <code>r + c</code>. Three sets make every safety check O(1).", "info")
              )
            )
          )
        )
      ),

      practice = practice_tab(ns, "recursion",
        "Knuth, D. E. (2011). The Art of Computer Programming, Vol. 4A: Combinatorial Algorithms — backtrack programming.",
        "Skiena, S. S. (2020). The Algorithm Design Manual (3rd ed.) — ch. 9, combinatorial search.",
        "Cormen, Leiserson, Rivest & Stein (2022). Introduction to Algorithms (4th ed.).")
    )
  )
}

recursion_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    # ── Subsets decision tree ────────────────────────────────────────────────
    sub_vals <- reactive({
      v <- unique(parse_ints(input$sub_vals, 4))
      validate(need(length(v) >= 2, "Enter 2 to 4 distinct integers."))
      v
    })
    sub_tree <- reactive({
      v <- sub_vals(); n <- length(v); N <- 2^(n + 1) - 1
      d <- floor(log2(seq_len(N))); pos <- seq_len(N) - 2^d
      lab <- character(N); sets <- vector("list", N); sets[[1]] <- integer(0)
      for (i in seq_len(N)) {
        if (i > 1) { p <- i %/% 2; sets[[i]] <- if (i %% 2 == 0) c(sets[[p]], v[d[i]]) else sets[[p]] }
        lab[i] <- if (length(sets[[i]]) == 0) "∅" else paste(sets[[i]], collapse = ",")
      }
      nodes <- data.frame(label = lab, x = (pos + 0.5) / 2^d, y = -d, stringsAsFactors = FALSE)
      ch <- 2:N; pa <- ch %/% 2
      edges <- data.frame(x0 = nodes$x[pa], y0 = nodes$y[pa], x1 = nodes$x[ch], y1 = nodes$y[ch],
                          color = ifelse(ch %% 2 == 0, COL$ok, COL$idle), width = 2.5, stringsAsFactors = FALSE)
      list(nodes = nodes, edges = edges, depth = d, sets = sets, n = n, N = N)
    })
    sub_steps <- reactive({
      t <- sub_tree(); v <- sub_vals(); steps <- list(); seen <- integer(0); leaves <- integer(0)
      walk <- function(i) {
        d <- t$depth[i]; leaf <- d == t$n
        seen <<- c(seen, i); if (leaf) leaves <<- c(leaves, i)
        msg <- if (i == 1) "Root call: nothing decided yet, the path is empty."
               else if (leaf) sprintf("All %d elements decided → <b>record {%s}</b> and return.", t$n, paste(t$sets[[i]], collapse = ", "))
               else if (i %% 2 == 0) sprintf("<b>Include %d.</b> Path is now {%s}. Next decision: element %d.", v[d], paste(t$sets[[i]], collapse = ", "), v[d + 1])
               else sprintf("Back up, undo the choice, and <b>skip %d</b>. Path is {%s}. Next decision: element %d.", v[d], paste(t$sets[[i]], collapse = ", "), v[d + 1])
        steps[[length(steps) + 1]] <<- list(cur = i, seen = seen, leaves = leaves, msg = msg)
        if (!leaf) { walk(2 * i); walk(2 * i + 1) }
      }
      walk(1)
      steps[[length(steps) + 1]] <- list(cur = NA, seen = seen, leaves = leaves, msg = sprintf("<b>Tree exhausted: %d subsets</b> from %d calls. The recursion visited every node exactly once.", length(leaves), t$N))
      steps
    })
    sb <- stepper_server(input, output, session, "sub", sub_steps, speed = 650)
    output$sub_plot <- renderPlotly({
      t <- sub_tree(); s <- sb$cur()
      state <- rep("idle", t$N)
      state[s$seen] <- "visited"; state[s$leaves] <- "done"
      if (!is.na(s$cur)) state[s$cur] <- "active"
      net_plot(state_style(t$nodes, state), t$edges, size = if (t$n >= 4) 30 else 38, height = 330)
    })
    output$sub_viz <- renderUI({
      t <- sub_tree(); s <- sb$cur()
      res <- vapply(s$leaves, function(i) paste0("{", paste(t$sets[[i]], collapse = ","), "}"), character(1))
      tagList(lane("results", res, "found", "none yet"), explain(s$msg))
    })
    output$sub_kpi <- renderUI({
      t <- sub_tree(); s <- sb$cur()
      kpi_row(kpi(length(s$seen), "calls made", COL$pri), kpi(length(s$leaves), "subsets found", COL$ok), kpi(2^t$n, "total = 2ⁿ", COL$sec))
    })

    # ── N-Queens ─────────────────────────────────────────────────────────────
    nq_run <- reactive({
      N <- input$nq_n; req(N)
      q <- rep(0L, N); steps <- list(); tries <- 0; backs <- 0; verbose <- N <= 6
      rec <- function(row, col, kind, msg) steps[[length(steps) + 1]] <<- list(q = q, row = row, col = col, kind = kind, msg = msg, tries = tries, backs = backs)
      safe <- function(r, cc) { for (r0 in sq(1, r - 1)) { c0 <- q[r0]; if (c0 == cc || abs(c0 - cc) == r - r0) return(FALSE) }; TRUE }
      rec(0, 0, "start", "One queen per row. Fill rows top to bottom, trying columns left to right.")
      solve <- function(r) {
        if (r > N) return(TRUE)
        for (cc in seq_len(N)) {
          tries <<- tries + 1
          if (safe(r, cc)) {
            q[r] <<- cc
            rec(r, cc, "place", sprintf("Row %d, column %d is safe → <b>place</b> a queen and move to the next row.", r, cc))
            if (solve(r + 1)) return(TRUE)
            q[r] <<- 0L; backs <<- backs + 1
            rec(r, cc, "back", sprintf("No column worked further down → <b>backtrack</b>: remove the queen at row %d, column %d and try the next column.", r, cc))
          } else if (verbose) rec(r, cc, "bad", sprintf("Row %d, column %d is attacked → <b>prune</b> (skip the whole subtree).", r, cc))
        }
        FALSE
      }
      ok <- solve(1)
      rec(0, 0, "done", sprintf("<b>Solved</b> after %d squares tested and %d backtrack(s).", tries, backs))
      list(steps = steps, N = N)
    })
    nq <- stepper_server(input, output, session, "nq", reactive(nq_run()$steps), speed = 280)
    output$nq_board <- renderUI({
      N <- nq_run()$N; s <- nq$cur(); q <- s$q
      atk <- matrix(FALSE, N, N)
      for (r0 in which(q > 0)) for (r in seq_len(N)) for (cc in seq_len(N))
        if (r != r0 && (cc == q[r0] || abs(cc - q[r0]) == abs(r - r0))) atk[r, cc] <- TRUE
      rows <- lapply(seq_len(N), function(r) tags$div(class = "board-row", lapply(seq_len(N), function(cc) {
        cls <- if ((r + cc) %% 2 == 0) "sq l" else "sq d"
        txt <- ""
        if (q[r] == cc) { cls <- "sq q"; txt <- "♛" }
        else if (s$kind == "bad" && s$row == r && s$col == cc) { cls <- "sq try"; txt <- "✕" }
        else if (s$kind == "back" && s$row == r && s$col == cc) { cls <- "sq try"; txt <- "↩" }
        else if (atk[r, cc] && q[r] == 0) cls <- "sq atk"
        tags$div(class = cls, txt)
      })))
      tags$div(style = "text-align:center;", tags$div(class = "board", rows))
    })
    output$nq_kpi <- renderUI({
      s <- nq$cur()
      kpi_row(kpi(s$tries, "squares tested", COL$pri), kpi(s$backs, "backtracks", COL$warn), kpi(sum(s$q > 0), "queens placed", COL$ok))
    })
    output$nq_explain <- renderUI(explain(nq$cur()$msg))
    output$nq_stats <- renderUI({
      N <- input$nq_n; req(N)
      sols <- c("4" = 2, "5" = 10, "6" = 4, "7" = 40, "8" = 92)[[as.character(N)]]
      fmt <- function(x) format(x, big.mark = ",", scientific = FALSE)
      tagList(
        kpi_row(kpi(fmt(choose(N * N, N)), "any N squares", COL$err), kpi(fmt(N^N), "one per row", COL$warn)),
        kpi_row(kpi(fmt(factorial(N)), "one per row & column", COL$acc), kpi(sols, "actual solutions", COL$ok)))
    })

    # ── Generators ───────────────────────────────────────────────────────────
    output$gen_viz <- renderUI({
      kind <- input$gen_kind; nodes <- 0; res <- character(0)
      if (kind == "paren") {
        p <- parse_ints(input$gen_vals, 6)
        n <- if (length(p) == 1) p else length(p)   # "3" means 3 pairs; a list means one pair per element
        n <- max(1, min(4, n))
        bt <- function(s, o, cl) {
          nodes <<- nodes + 1
          if (nchar(s) == 2 * n) { res <<- c(res, s); return(invisible()) }
          if (o < n) bt(paste0(s, "("), o + 1, cl)
          if (cl < o) bt(paste0(s, ")"), o, cl + 1)
        }
        bt("", 0, 0)
        brute <- 2^(2 * n); what <- sprintf("all strings of %d brackets", 2 * n)
        note <- sprintf("n = %d pairs. Two rules prune everything invalid: only open if fewer than n are open; only close if it matches an open one.", n)
      } else {
        v <- unique(parse_ints(input$gen_vals, 5))
        validate(need(length(v) >= 1, "Enter 1 to 5 integers."))
        n <- length(v)
        if (kind == "perm") {
          bt <- function(path, rem) {
            nodes <<- nodes + 1
            if (length(rem) == 0) { res <<- c(res, paste(path, collapse = " ")); return(invisible()) }
            for (i in seq_along(rem)) bt(c(path, rem[i]), rem[-i])
          }
          bt(integer(0), v)
          brute <- n^n; what <- "every length-n sequence with repeats"
          note <- "At each depth pick any element not used yet: n × (n−1) × … × 1 = n! leaves."
        } else {
          k <- max(1, min(n, as.integer(input$gen_k %||% 2))); if (is.na(k)) k <- 1
          bt <- function(start, path) {
            nodes <<- nodes + 1
            if (length(path) == k) { res <<- c(res, paste(path, collapse = " ")); return(invisible()) }
            for (i in sq(start, n - (k - length(path)) + 1)) bt(i + 1, c(path, v[i]))
          }
          bt(1, integer(0))
          brute <- 2^n; what <- "every subset"
          note <- sprintf("k = %d. The <code>start</code> index only ever moves forward, so {1,2} and {2,1} are never both produced. The loop bound also prunes branches that cannot reach size k.", k)
        }
      }
      tagList(
        kpi_row(kpi(length(res), "results", COL$ok), kpi(nodes, "recursive calls", COL$pri), kpi(format(brute, big.mark = ","), what, COL$err)),
        tags$div(class = "lane", style = "max-height:150px; overflow-y:auto;", lapply(res, function(r) tags$span(class = "vnode sm visited", r))),
        explain(note))
    })

    output$space_plot <- renderPlotly({
      n <- 1:20
      plot_ly(x = n, height = 280) %>%
        add_trace(y = n^2, type = "scatter", mode = "lines", name = "n² (nested loops)", line = list(color = COL$ok, width = 3)) %>%
        add_trace(y = 2^n, type = "scatter", mode = "lines", name = "2ⁿ (subsets)", line = list(color = COL$warn, width = 3)) %>%
        add_trace(y = factorial(n), type = "scatter", mode = "lines", name = "n! (permutations)", line = list(color = COL$err, width = 3)) %>%
        dsa_layout(xt = "n", yt = "states to explore", legend = TRUE) %>%
        layout(yaxis = list(type = "log", range = c(0, 19)),
               shapes = list(list(type = "line", x0 = 1, x1 = 20, y0 = 1e8, y1 = 1e8, line = list(color = COL$mute, dash = "dash", width = 2))))
    })

    quiz_server(input, output, session, topic = "recursion", progress = progress, questions = list(
      list(q = "How many subsets does a set of n distinct elements have?",
           opts = c("n!", "n²", "2ⁿ", "n log n"), ans = 3,
           why = "Each element is independently in or out: 2 × 2 × … × 2 = 2ⁿ."),
      list(q = "Your subsets function returns a list of identical empty lists. The most likely bug is…",
           opts = c("Wrong base case", "Appending <code>path</code> itself instead of a copy", "Missing recursion", "Integer overflow"), ans = 2,
           why = "All results reference the same list object, which is empty again after the final pop. Append <code>path[:]</code>."),
      list(q = "In N-Queens, what does rejecting an attacked square achieve?",
           opts = c("Nothing — it is only an optimisation of one check", "It skips the entire subtree of placements that would follow", "It guarantees a solution exists", "It sorts the columns"), ans = 2,
           why = "That is pruning: one failed check removes every board that extends this partial placement."),
      list(q = "Why do combinations use a <code>start</code> index while permutations use a <code>used</code> set?",
           opts = c("Style preference", "Combinations ignore order, so only moving forward avoids reorderings; permutations need every order", "Permutations cannot recurse with indices", "The start index is faster"), ans = 2,
           why = "Forward-only selection yields each set once. Permutations must allow any unused element at each position."),
      list(q = "n = 30 and the task is 'count subsets with sum S'. Plain backtracking visits about 10⁹ states. Best next move?",
           opts = c("Give up", "Look for overlapping subproblems and switch to DP / meet-in-the-middle", "Use recursion with deeper stack", "Sort the input"), ans = 2,
           why = "When only a count or optimum is needed — not the list of all answers — repeated states can be memoised. That is the bridge from backtracking to dynamic programming.")
    ))
  })
}
