# modules/mod_greedy.R — Greedy Algorithms

greedy_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("💰", "Greedy Algorithms",
      "Take the choice that looks best right now and never look back. When it works it is the simplest and fastest solution — the hard part is knowing (and arguing) that it works.",
      c("Greedy Choice Property", "Sort Then Scan", "Interval Scheduling", "Exchange Argument", "Huffman Coding")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Interval Scheduling — the rule you pick decides everything", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(7, textInput(ns("iv"), "Intervals (start-end):", "1-4,3-5,0-6,5-7,3-9,5-9,6-10,8-11,8-12,2-14,12-16")),
              column(5, selectInput(ns("iv_rule"), "Greedy rule:", c("Earliest finish time ✓" = "end", "Earliest start time" = "start", "Shortest duration" = "short")))
            ),
            stepper_ui(ns, "iv"),
            plotlyOutput(ns("iv_plot"), height = "320px"),
            uiOutput(ns("iv_explain")),
            legend_row(c("considering" = COL$pri, "accepted" = COL$ok, "rejected (overlaps)" = "#fca5a5", "not yet seen" = COL$idle))
          ),
          box(title = "Three plausible rules, one correct", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("iv_kpi")),
            callout("<b>Why earliest finish wins (exchange argument):</b> take any optimal schedule. Swap its first meeting for the one that finishes earliest overall — it cannot clash with the rest, because it ends no later. The schedule is still optimal, so the greedy first choice is safe. Repeat on what remains.", "tip"),
            callout("Earliest <i>start</i> can grab one long meeting that blocks everything. <i>Shortest</i> can pick a short meeting that straddles two compatible ones.", "warn")
          )
        ),
        fluidRow(
          box(title = "Jump Game — track the farthest reach", status = "primary", solidHeader = TRUE, width = 6,
            textInput(ns("jg"), "Max jump from each index:", "2,3,1,1,0,2,0,1"),
            stepper_ui(ns, "jg"),
            uiOutput(ns("jg_viz")),
            legend_row(c("current index" = COL$pri, "reachable so far" = COL$acc, "unreachable" = "#ffffff"))
          ),
          box(title = "When greedy fails — coin change", status = "primary", solidHeader = TRUE, width = 6,
            textInput(ns("gc_coins"), "Coin system:", "1,7,10"),
            plotlyOutput(ns("gc_plot"), height = "250px"),
            uiOutput(ns("gc_explain"))
          )
        ),
        fluidRow(
          box(title = "Huffman Coding — greedy that is provably optimal", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(5, textInput(ns("hf_text"), "Text to compress:", "abracadabra alakazam")),
              column(7, stepper_ui(ns, "hf"))
            ),
            fluidRow(
              column(8, plotlyOutput(ns("hf_plot"), height = "340px"), uiOutput(ns("hf_viz"))),
              column(4, uiOutput(ns("hf_kpi")), uiOutput(ns("hf_table")))
            )
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("Intervals: maximise non-overlapping, minimise rooms / arrows, merge → sort by an endpoint and scan.",
                   "A 'reach' or 'budget' that only needs a running maximum or surplus (Jump Game, Gas Station).",
                   "Always combining / serving the two smallest or the single best next → greedy with a heap (Huffman, Dijkstra, Prim).",
                   "You can argue that swapping any other choice for the greedy one never makes things worse."),
          pitfalls = c("Assuming greedy works because it passes the examples — look for a counter-example first.",
                       "Sorting by the wrong key (start instead of end; value instead of value / weight).",
                       "0/1 knapsack is <b>not</b> greedy; only the fractional version is.",
                       "Ties: decide and state how equal keys are ordered."),
          tips = c("Say the rule in one sentence, then give a 20-second justification (exchange or 'stays ahead').",
                   "If you find a counter-example, pivot to DP — and say why greedy failed.",
                   "Greedy solutions are usually O(n log n) for the sort plus an O(n) scan.")
        ),
        fluidRow(
          box(title = "Greedy or DP?", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              . = c("Decision", "Revisits choices", "Needs", "Typical cost", "Proof"),
              Greedy = c("One local best per step", "Never", "Greedy-choice property", "O(n log n)", "Exchange argument"),
              DP = c("All options per state", "Implicitly, via the table", "Optimal substructure", "O(states × choices)", "Induction on states"),
              stringsAsFactors = FALSE)),
            callout("Both need optimal substructure. Greedy needs the <i>extra</i> guarantee that a locally best choice is part of some global optimum.", "info")
          ),
          box(title = "Classic greedy problems and their sort key", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Problem = c("Max non-overlapping intervals", "Minimum meeting rooms", "Merge intervals", "Fractional knapsack", "Minimise lateness", "Huffman coding", "Minimum spanning tree"),
              Greedy.rule = c("Earliest finish first", "Sort starts; min-heap of end times", "Sort by start, extend or open", "Highest value / weight first", "Earliest deadline first", "Merge the two rarest", "Cheapest edge that joins two components"),
              Time = c("O(n log n)", "O(n log n)", "O(n log n)", "O(n log n)", "O(n log n)", "O(n log n)", "O(E log E)"),
              stringsAsFactors = FALSE))
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4,
                dsa_code(
'def eraseOverlapIntervals(intervals):
    intervals.sort(key=lambda x: x[1])    # by end
    kept, end = 0, float("-inf")
    for s, e in intervals:
        if s >= end:
            kept += 1
            end = e
    return len(intervals) - kept', "Max non-overlapping intervals"),
                dsa_code(
'def canJump(nums):
    far = 0
    for i, x in enumerate(nums):
        if i > far: return False       # gap
        far = max(far, i + x)
    return True', "Jump game")
              ),
              column(4,
                dsa_code(
'def jump(nums):                # fewest jumps
    jumps = end = far = 0
    for i in range(len(nums) - 1):
        far = max(far, i + nums[i])
        if i == end:               # level finished
            jumps += 1
            end = far
    return jumps', "Jump game II — BFS levels in disguise"),
                dsa_code(
'def canCompleteCircuit(gas, cost):
    if sum(gas) < sum(cost): return -1
    tank = start = 0
    for i in range(len(gas)):
        tank += gas[i] - cost[i]
        if tank < 0:               # cannot start at or
            start, tank = i + 1, 0 # before i
    return start', "Gas station")
              ),
              column(4,
                dsa_code(
'def minMeetingRooms(intervals):
    intervals.sort()
    ends = []                        # min-heap of end times
    for s, e in intervals:
        if ends and ends[0] <= s:
            heapq.heapreplace(ends, e)   # reuse room
        else:
            heapq.heappush(ends, e)      # new room
    return len(ends)', "Meeting rooms — sort + heap"),
                dsa_code(
'def partitionLabels(s):
    last = {ch: i for i, ch in enumerate(s)}
    out, start, end = [], 0, 0
    for i, ch in enumerate(s):
        end = max(end, last[ch])
        if i == end:
            out.append(end - start + 1)
            start = i + 1
    return out', "Partition labels")
              )
            )
          )
        )
      ),

      practice = practice_tab(ns, "greedy",
        "Kleinberg & Tardos (2005). Algorithm Design. Addison-Wesley — ch. 4, the exchange and stays-ahead arguments.",
        "Huffman, D. A. (1952). A method for the construction of minimum-redundancy codes. Proceedings of the IRE 40(9).",
        "Cormen, Leiserson, Rivest & Stein (2022). Introduction to Algorithms (4th ed.) — ch. 15.")
    )
  )
}

greedy_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    # ── Interval scheduling ──────────────────────────────────────────────────
    iv_data <- reactive({
      tok <- trimws(strsplit(input$iv %||% "", ",")[[1]])
      m <- regmatches(tok, regexec("^(\\d+)\\s*-\\s*(\\d+)$", tok))
      m <- m[vapply(m, length, integer(1)) == 3]
      validate(need(length(m) >= 1, "Enter intervals like 1-4,3-5."))
      d <- data.frame(s = as.numeric(vapply(m, `[`, "", 2)), e = as.numeric(vapply(m, `[`, "", 3)))
      d <- head(d[d$e > d$s, , drop = FALSE], 14)
      validate(need(nrow(d) >= 1, "Each interval needs end > start."))
      d$id <- seq_len(nrow(d)); d
    })
    iv_sim <- function(d, rule) {
      ord <- switch(rule, end = order(d$e, d$s), start = order(d$s, d$e), short = order(d$e - d$s, d$s))
      acc <- integer(0); rej <- integer(0); log <- list()
      for (k in ord) {
        clash <- acc[d$s[acc] < d$e[k] & d$s[k] < d$e[acc]]
        if (length(clash) == 0) { acc <- c(acc, k); ok <- TRUE } else { rej <- c(rej, k); ok <- FALSE }
        log[[length(log) + 1]] <- list(cur = k, acc = acc, rej = rej, ok = ok, clash = clash)
      }
      list(ord = ord, log = log, n = length(acc))
    }
    iv_steps <- reactive({
      d <- iv_data(); r <- iv_sim(d, input$iv_rule)
      what <- switch(input$iv_rule, end = "finish time", start = "start time", short = "duration")
      steps <- list(list(cur = NA, acc = integer(0), rej = integer(0), msg = sprintf("Sort the %d intervals by <b>%s</b>, then scan once, keeping each interval that does not overlap one already kept.", nrow(d), what)))
      for (l in r$log) steps[[length(steps) + 1]] <- list(cur = l$cur, acc = l$acc, rej = l$rej,
        msg = if (l$ok) sprintf("[%s, %s) is compatible with everything kept so far → <b>accept</b>.", d$s[l$cur], d$e[l$cur])
              else sprintf("[%s, %s) overlaps [%s, %s) → <b>reject</b>.", d$s[l$cur], d$e[l$cur], d$s[l$clash[1]], d$e[l$clash[1]]))
      best <- iv_sim(d, "end")$n
      steps[[length(steps) + 1]] <- list(cur = NA, acc = r$log[[length(r$log)]]$acc, rej = r$log[[length(r$log)]]$rej,
        msg = sprintf("<b>%d interval(s) scheduled.</b> %s", r$n, if (r$n == best) "That is the maximum possible." else sprintf("The optimum is %d — this rule is <b>not</b> optimal on this input.", best)))
      steps
    })
    ivs <- stepper_server(input, output, session, "iv", iv_steps)
    output$iv_plot <- renderPlotly({
      d <- iv_data(); s <- ivs$cur()
      col <- rep(COL$idle, nrow(d)); col[s$rej] <- "#fca5a5"; col[s$acc] <- COL$ok
      if (!is.na(s$cur)) col[s$cur] <- COL$pri
      ord <- iv_sim(d, input$iv_rule)$ord
      lab <- factor(paste0("#", d$id), levels = rev(paste0("#", d$id[ord])))
      plot_ly(height = 320) %>%
        add_bars(y = lab, x = d$e - d$s, base = d$s, orientation = "h", marker = list(color = col),
                 text = paste0(d$s, "–", d$e), textposition = "inside", insidetextfont = list(color = "#fff"),
                 hoverinfo = "text", hovertext = paste0("#", d$id, ": [", d$s, ", ", d$e, ")")) %>%
        dsa_layout(xt = "time") %>% layout(yaxis = list(title = "", categoryorder = "array", categoryarray = levels(lab)), bargap = 0.25)
    })
    output$iv_explain <- renderUI(explain(ivs$cur()$msg))
    output$iv_kpi <- renderUI({
      d <- iv_data(); n <- vapply(c("end", "start", "short"), function(r) iv_sim(d, r)$n, numeric(1)); best <- n[1]
      kpi_row(kpi(n[1], "earliest finish", COL$ok), kpi(n[2], "earliest start", if (n[2] == best) COL$ok else COL$err), kpi(n[3], "shortest first", if (n[3] == best) COL$ok else COL$err))
    })

    # ── Jump game ────────────────────────────────────────────────────────────
    jg_arr <- reactive({
      v <- parse_ints(input$jg, 14)
      validate(need(length(v) >= 1 && all(v >= 0), "Enter non-negative integers."))
      v
    })
    jg_steps <- reactive({
      a <- jg_arr(); n <- length(a); far <- 0
      steps <- list(list(i = NA, far = 0, stuck = FALSE, msg = "<code>far</code> = the farthest index reachable so far. Start with only index 0 reachable."))
      for (i in 0:(n - 1)) {
        if (i > far) {
          steps[[length(steps) + 1]] <- list(i = i, far = far, stuck = TRUE, msg = sprintf("Index %d is beyond <code>far</code> = %d → <b>no way to get here</b>. The last index cannot be reached.", i, far))
          return(steps)
        }
        nf <- max(far, i + a[i + 1])
        steps[[length(steps) + 1]] <- list(i = i, far = nf, stuck = FALSE,
          msg = sprintf("At index %d you can jump up to %d → reach index %d. <code>far</code> = max(%d, %d) = <b>%d</b>.%s", i, a[i + 1], i + a[i + 1], far, i + a[i + 1], nf,
                        if (nf >= n - 1) " <b>The last index is within reach ✓</b>" else ""))
        far <- nf
        if (far >= n - 1) break
      }
      steps
    })
    jg <- stepper_server(input, output, session, "jg", jg_steps)
    output$jg_viz <- renderUI({
      a <- jg_arr(); s <- jg$cur(); n <- length(a)
      cls <- ifelse(seq_len(n) - 1 <= s$far, "window", "")
      if (!is.na(s$i)) cls[s$i + 1] <- if (s$stuck) "bad" else "active"
      tagList(vrow(a, cls, ptr = list(i = if (is.na(s$i)) NULL else s$i + 1, far = min(s$far, n - 1) + 1)), explain(s$msg))
    })

    # ── Greedy vs DP coins ───────────────────────────────────────────────────
    gc <- reactive({
      coins <- sort(unique(parse_ints(input$gc_coins, 6)))
      validate(need(length(coins) >= 1 && all(coins > 0), "Enter positive coin values."), need(1 %in% coins, "Include a 1 coin so every amount is reachable."))
      N <- 40; dp <- c(0, rep(Inf, N))
      for (a in 1:N) { use <- coins[coins <= a]; dp[a + 1] <- min(dp[a - use + 1]) + 1 }
      gr <- vapply(1:N, function(a) { k <- 0; for (c in rev(coins)) { k <- k + a %/% c; a <- a %% c }; k }, numeric(1))
      list(coins = coins, amt = 1:N, dp = dp[-1], gr = gr)
    })
    output$gc_plot <- renderPlotly({
      r <- gc()
      plot_ly(x = r$amt, height = 250) %>%
        add_bars(y = r$dp, name = "optimal (DP)", marker = list(color = COL$ok)) %>%
        add_bars(y = r$gr - r$dp, name = "extra coins greedy wastes", marker = list(color = COL$err)) %>%
        dsa_layout(xt = "amount", yt = "coins used", legend = TRUE) %>% layout(barmode = "stack")
    })
    output$gc_explain <- renderUI({
      r <- gc(); bad <- r$amt[r$gr > r$dp]
      if (length(bad) == 0) explain(sprintf("With coins {%s}, largest-coin-first is optimal for every amount up to 40 — a <b>canonical</b> coin system. Real currencies are designed this way. Now try <code>1,7,10</code> or <code>1,3,4</code>.", paste(r$coins, collapse = ", ")))
      else explain(sprintf("With coins {%s}, greedy is <b>wrong for %d of 40 amounts</b> (first at %d: greedy uses %d coins, optimum is %d). The locally best coin can block a better combination — no greedy-choice property, so use DP. Compare with <code>1,5,10,25</code>.",
                           paste(r$coins, collapse = ", "), length(bad), bad[1], r$gr[bad[1]], r$dp[bad[1]]))
    })

    # ── Huffman ──────────────────────────────────────────────────────────────
    hf <- reactive({
      ch <- strsplit(input$hf_text %||% "", "")[[1]]
      validate(need(length(ch) >= 2, "Type some text."))
      f <- table(ch); validate(need(length(f) >= 2 && length(f) <= 10, "Use text with 2 to 10 distinct characters."))
      sym <- names(f); sym[sym == " "] <- "␣"
      nodes <- lapply(seq_along(f), function(i) list(lab = sym[i], f = as.integer(f[i]), l = NA, r = NA))
      pq <- seq_along(nodes); merges <- list()
      while (length(pq) > 1) {
        fr <- vapply(pq, function(i) nodes[[i]]$f, numeric(1))
        o <- order(fr, pq); a <- pq[o[1]]; b <- pq[o[2]]
        nodes[[length(nodes) + 1]] <- list(lab = "", f = nodes[[a]]$f + nodes[[b]]$f, l = a, r = b)
        pq <- c(setdiff(pq, c(a, b)), length(nodes))
        merges[[length(merges) + 1]] <- list(a = a, b = b, new = length(nodes), pq = pq)
      }
      root <- length(nodes); N <- length(nodes)
      x <- rep(NA_real_, N); y <- rep(0, N); code <- rep("", N); leafx <- 0
      walk <- function(i, d, cd) {
        y[i] <<- -d; code[i] <<- cd
        if (is.na(nodes[[i]]$l)) { leafx <<- leafx + 1; x[i] <<- leafx }
        else { walk(nodes[[i]]$l, d + 1, paste0(cd, "0")); walk(nodes[[i]]$r, d + 1, paste0(cd, "1")); x[i] <<- (x[nodes[[i]]$l] + x[nodes[[i]]$r]) / 2 }
      }
      walk(root, 0, "")
      list(nodes = nodes, merges = merges, x = x, y = y, code = code, nleaf = length(f), total = length(ch), N = N)
    })
    hf_steps <- reactive({
      h <- hf(); lab <- function(i) if (nzchar(h$nodes[[i]]$lab)) sprintf("'%s' (%d)", h$nodes[[i]]$lab, h$nodes[[i]]$f) else sprintf("subtree (%d)", h$nodes[[i]]$f)
      steps <- list(list(k = 0, pq = seq_len(h$nleaf), hl = integer(0), msg = "Count each character. Every character starts as its own one-node tree in a min-heap keyed by frequency."))
      for (k in seq_along(h$merges)) { m <- h$merges[[k]]
        steps[[length(steps) + 1]] <- list(k = k, pq = m$pq, hl = c(m$a, m$b, m$new),
          msg = sprintf("Pop the two rarest: %s and %s. <b>Merge</b> them under a new node of weight %d and push it back.", lab(m$a), lab(m$b), h$nodes[[m$new]]$f)) }
      steps[[length(steps) + 1]] <- list(k = length(h$merges), pq = integer(0), hl = integer(0), final = TRUE,
        msg = "<b>One tree left — done.</b> Read each code off the path from the root (left = 0, right = 1). Rare characters sank deep and got long codes; frequent ones stayed near the top with short codes.")
      steps
    })
    hfs <- stepper_server(input, output, session, "hf", hf_steps)
    output$hf_plot <- renderPlotly({
      h <- hf(); s <- hfs$cur(); N <- h$N
      made <- seq_len(N) <= h$nleaf + s$k
      nd <- data.frame(x = h$x, y = h$y, stringsAsFactors = FALSE,
                       label = vapply(seq_len(N), function(i) if (!made[i]) "" else if (nzchar(h$nodes[[i]]$lab)) paste0(h$nodes[[i]]$lab, ":", h$nodes[[i]]$f) else as.character(h$nodes[[i]]$f), character(1)))
      state <- ifelse(seq_len(N) <= h$nleaf, "frontier", ifelse(made, "visited", "idle"))
      state[s$hl] <- "active"
      if (isTRUE(s$final)) state[seq_len(h$nleaf)] <- "done"
      nd <- state_style(nd, state); nd$border[!made] <- "#e2e8f0"
      int <- (h$nleaf + 1):N
      ed <- do.call(rbind, lapply(int, function(i) data.frame(
        x0 = h$x[i], y0 = h$y[i], x1 = h$x[c(h$nodes[[i]]$l, h$nodes[[i]]$r)], y1 = h$y[c(h$nodes[[i]]$l, h$nodes[[i]]$r)],
        label = if (made[i]) c("0", "1") else c("", ""), color = if (made[i]) COL$mute else "#eef2f7", stringsAsFactors = FALSE)))
      ed$width <- 2
      net_plot(nd, ed, size = 38, height = 340)
    })
    output$hf_viz <- renderUI({
      h <- hf(); s <- hfs$cur()
      fr <- vapply(s$pq, function(i) h$nodes[[i]]$f, numeric(1)); o <- order(fr)
      lab <- vapply(s$pq[o], function(i) paste0(if (nzchar(h$nodes[[i]]$lab)) h$nodes[[i]]$lab else "•", ":", h$nodes[[i]]$f), character(1))
      tagList(lane("min-heap", lab, "frontier", "empty"), explain(s$msg))
    })
    hf_bits <- reactive({
      h <- hf(); i <- seq_len(h$nleaf); f <- vapply(i, function(k) h$nodes[[k]]$f, numeric(1))
      list(sym = vapply(i, function(k) h$nodes[[k]]$lab, ""), f = f, code = h$code[i], fixed = h$total * max(1, ceiling(log2(h$nleaf))), huff = sum(f * nchar(h$code[i])))
    })
    output$hf_kpi <- renderUI({
      b <- hf_bits()
      kpi_row(kpi(b$fixed, "fixed-length bits", COL$err), kpi(b$huff, "Huffman bits", COL$ok), kpi(sprintf("%.0f%%", 100 * (1 - b$huff / b$fixed)), "saved", COL$pri))
    })
    output$hf_table <- renderUI({
      b <- hf_bits(); o <- order(-b$f)
      cplx_table(data.frame(Char = b$sym[o], Freq = b$f[o], Code = b$code[o], Bits = b$f[o] * nchar(b$code[o]), stringsAsFactors = FALSE))
    })

    quiz_server(input, output, session, topic = "greedy", progress = progress, questions = list(
      list(q = "To schedule the maximum number of non-overlapping meetings, sort by…",
           opts = c("Start time", "Finish time", "Duration", "Number of attendees"), ans = 2,
           why = "Finishing earliest leaves the most room for what follows; an exchange argument proves it is always safe."),
      list(q = "Which problem can NOT be solved optimally by a greedy rule?",
           opts = c("Fractional knapsack", "Huffman coding", "0/1 knapsack", "Activity selection"), ans = 3,
           why = "With indivisible items, the best value-per-weight item can waste capacity. It needs DP."),
      list(q = "An 'exchange argument' shows that…",
           opts = c("Two algorithms have the same running time", "Any optimal solution can be transformed to include the greedy choice without getting worse", "The input can be sorted in place", "Greedy uses less memory than DP"), ans = 2,
           why = "If swapping in the greedy choice never hurts, some optimal solution starts with it — so committing to it is safe."),
      list(q = "In Jump Game, the scan fails exactly when…",
           opts = c("A zero appears", "The current index is greater than the farthest reachable index", "Two equal values are adjacent", "The array is sorted"), ans = 2,
           why = "A zero is fine if an earlier jump clears it. Failure means there is a gap nothing can cross: i > far."),
      list(q = "Huffman's algorithm repeatedly merges…",
           opts = c("The two most frequent symbols", "The two least frequent subtrees", "Adjacent symbols in the text", "Random pairs"), ans = 2,
           why = "The rarest symbols should have the longest codes, so they are joined first and end up deepest in the tree.")
    ))
  })
}
