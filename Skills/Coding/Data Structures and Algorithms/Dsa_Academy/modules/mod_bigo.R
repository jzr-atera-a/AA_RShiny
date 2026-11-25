# modules/mod_bigo.R — Big-O & Complexity Analysis

# ASCII keys (safe in any locale); `lab` is what the user sees
BIGO <- list(
  const = list(lab = "O(1)",       poly = TRUE,  f = function(n) rep(1, length(n)), col = "#10b981"),
  log   = list(lab = "O(log n)",   poly = TRUE,  f = function(n) log2(pmax(n, 1)) + 1, col = "#06b6d4"),
  lin   = list(lab = "O(n)",       poly = TRUE,  f = function(n) n, col = "#4f46e5"),
  nlogn = list(lab = "O(n log n)", poly = TRUE,  f = function(n) n * (log2(pmax(n, 1)) + 1), col = "#7c3aed"),
  quad  = list(lab = "O(n\u00b2)",     poly = TRUE,  f = function(n) n^2, col = "#f59e0b"),
  expo  = list(lab = "O(2\u207f)",     poly = FALSE, f = function(n) 2^n, col = "#ef4444"),
  fact  = list(lab = "O(n!)",      poly = FALSE, f = function(n) factorial(pmin(n, 170)), col = "#0f172a")
)
BIGO_CHOICES <- setNames(names(BIGO), vapply(BIGO, function(b) b$lab, ""))

BIGO_SNIPPETS <- list(
  single = list(name = "One loop", code =
'for i in range(n):
    total += a[i]', ans = "O(n)", f = function(n) n,
    why = "The body runs once per element. One pass over the input is linear."),
  nested = list(name = "Nested loops (all pairs)", code =
'for i in range(n):
    for j in range(i + 1, n):
        check(a[i], a[j])', ans = "O(n²)", f = function(n) n * (n - 1) / 2,
    why = "The inner loop runs n−1, n−2, …, 1 times: n(n−1)/2 in total. Drop the constant ½ and the lower-order term → n²."),
  halving = list(name = "Halving loop", code =
'while n > 1:
    n //= 2
    steps += 1', ans = "O(log n)", f = function(n) floor(log2(pmax(n, 1))),
    why = "How many times can you halve n before reaching 1? log₂n. Any loop that multiplies or divides its counter by a constant is logarithmic."),
  nlogn = list(name = "Loop with a halving loop inside", code =
'for i in range(n):
    j = n
    while j > 1:
        j //= 2
        work()', ans = "O(n log n)", f = function(n) n * floor(log2(pmax(n, 1))),
    why = "Nested loops multiply: n iterations outside × log₂n inside."),
  twoptr = list(name = "Two pointers (looks nested, is not)", code =
'j = 0
for i in range(n):
    while j < n and a[j] < a[i] + k:
        j += 1          # j never moves back
    use(i, j)', ans = "O(n)", f = function(n) 2 * n,
    why = "The inner while is misleading: j only ever increases and is bounded by n, so across the whole run it moves at most n times. Total work ≤ 2n. This amortised argument is the heart of sliding-window analysis."),
  seq = list(name = "Two loops in sequence", code =
'for x in a:            # n
    seen.add(x)
for y in b:            # m
    if y in seen: hit()', ans = "O(n + m)", f = function(n) 2 * n,
    why = "Sequential blocks add. With two inputs keep both variables: O(n + m), not O(n²)."),
  fib = list(name = "Branching recursion", code =
'def f(n):
    if n < 2: return n
    return f(n - 1) + f(n - 2)', ans = "O(2ⁿ)  (tightly, O(1.618ⁿ))", f = function(n) 2^pmin(n, 40),
    why = "Each call spawns two more and the depth is n, so the call tree has up to 2ⁿ nodes. Rule of thumb: branches ^ depth.")
)

bigo_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("📈", "Big-O & Complexity Analysis",
      "The vocabulary for every answer you give. Big-O describes how running time and memory grow as the input grows — and tells you, before writing a line, whether an approach can possibly be fast enough.",
      c("Growth Rates", "Worst / Average / Amortised", "Time vs Space", "Reading Constraints", "Recurrences")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Growth Rates — how fast does the work explode?", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(6, checkboxGroupInput(ns("classes"), "Show:", choices = BIGO_CHOICES, selected = c("log", "lin", "nlogn", "quad", "expo"), inline = TRUE)),
              column(4, sliderInput(ns("nmax"), "Up to n =", min = 10, max = 1000, value = 30, step = 10)),
              column(2, checkboxInput(ns("logy"), "Log scale", FALSE))
            ),
            plotlyOutput(ns("growth"), height = "340px")
          ),
          box(title = "What to notice", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("growth_note")),
            callout("Big-O keeps only the <b>dominant term</b> and drops constants: <code>3n² + 50n + 9</code> is O(n²). Constants matter in practice, but growth rate decides what happens when the input gets 10× bigger.", "info"),
            cplx_table(data.frame(
              If.n.grows.10x = c("O(log n)", "O(n)", "O(n log n)", "O(n²)", "O(2ⁿ)"),
              Work.grows = c("+3 steps", "10×", "≈ 13×", "100×", "× 2¹⁰ per +10"),
              stringsAsFactors = FALSE))
          )
        ),
        fluidRow(
          box(title = "Will it pass? Turn constraints into a complexity target", status = "primary", solidHeader = TRUE, width = 7,
            fluidRow(
              column(6, selectInput(ns("n_pick"), "Input size n:", c("10" = 10, "20" = 20, "100" = 100, "1,000" = 1e3, "10,000" = 1e4, "100,000" = 1e5, "1,000,000" = 1e6, "100,000,000" = 1e8), selected = 1e5)),
              column(6, hint("Assumes ~10⁸ simple operations per second — a safe estimate for one-second limits."))
            ),
            uiOutput(ns("feas"))
          ),
          box(title = "The constraint cheat-sheet", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Constraint = c("n ≤ 10", "n ≤ 20", "n ≤ 500", "n ≤ 5,000", "n ≤ 10⁵ – 10⁶", "n ≤ 10⁸", "n ≥ 10⁹"),
              Target = c("O(n!)", "O(2ⁿ)", "O(n³)", "O(n²)", "O(n log n) or O(n)", "O(n)", "O(log n) or O(1)"),
              Think = c("Permutations, brute force", "Subsets, bitmask DP", "Interval DP, Floyd-Warshall", "2D DP, all pairs", "Sort, heap, hash map, two pointers", "Single pass, no sorting", "Binary search, maths"),
              stringsAsFactors = FALSE)),
            callout("Read the constraints <b>before</b> designing. They are the interviewer telling you which complexity is expected.", "tip")
          )
        ),
        fluidRow(
          box(title = "Analyse This — count the operations", status = "primary", solidHeader = TRUE, width = 7,
            selectInput(ns("snip"), "Code pattern:", setNames(names(BIGO_SNIPPETS), vapply(BIGO_SNIPPETS, function(s) s$name, ""))),
            fluidRow(
              column(6, uiOutput(ns("snip_code")), actionButton(ns("reveal"), "Reveal the answer", class = "btn btn-dsa btn-sm")),
              column(6, plotlyOutput(ns("snip_plot"), height = "230px"))
            ),
            uiOutput(ns("snip_ans"))
          ),
          box(title = "Amortised Cost — the dynamic array", status = "primary", solidHeader = TRUE, width = 5,
            fluidRow(
              column(6, sliderInput(ns("am_n"), "Appends:", min = 8, max = 80, value = 34, step = 1)),
              column(6, radioButtons(ns("am_mode"), "When full:", c("Double capacity" = "double", "Add 4 slots" = "fixed")))
            ),
            plotlyOutput(ns("am_plot"), height = "230px"),
            uiOutput(ns("am_explain"))
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("Before coding: use the constraints to rule approaches in or out.",
                   "After coding: state time <b>and</b> space, and name the variables (n items, m edges, k distinct…).",
                   "When comparing options: 'sorting costs O(n log n) but lets the scan be O(n)'.",
                   "When optimising: find the dominant term — that is the only one worth attacking."),
          pitfalls = c("Forgetting hidden costs: slicing, string concatenation, <code>x in list</code> and <code>list.pop(0)</code> are all O(n).",
                       "Counting nested loops blindly — a two-pointer inner loop is amortised O(1).",
                       "Ignoring recursion-stack space: a DFS on a skewed tree uses O(n) memory.",
                       "Reporting O(n) when there are two independent inputs: it may be O(n · m) or O(n + m)."),
          tips = c("Say 'worst case' or 'average case' explicitly — hash maps and quicksort differ between the two.",
                   "For recursion: (number of calls) × (work per call), or draw the recursion tree.",
                   "If asked 'can you do better?', check the lower bound: you must at least read the input, so O(n) is often optimal.")
        ),
        fluidRow(
          box(title = "Rules for reading complexity off code", status = "primary", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Rule = c("Drop constants", "Keep the dominant term", "Sequential blocks add", "Nested blocks multiply", "Halving → log", "Recursion", "Different inputs"),
              Example = c("O(2n) → O(n)", "O(n² + n) → O(n²)", "O(n) then O(n log n) → O(n log n)", "n × n → O(n²)", "Binary search, balanced tree height", "branches ^ depth, or calls × work", "Keep both: O(n + m), O(n · m)"),
              stringsAsFactors = FALSE))
          ),
          box(title = "Common recurrences", status = "info", solidHeader = TRUE, width = 4,
            cplx_table(data.frame(
              Recurrence = c("T(n) = T(n/2) + 1", "T(n) = T(n−1) + 1", "T(n) = 2T(n/2) + n", "T(n) = T(n−1) + n", "T(n) = 2T(n/2) + 1", "T(n) = 2T(n−1) + 1"),
              Solves.to = c("O(log n)", "O(n)", "O(n log n)", "O(n²)", "O(n)", "O(2ⁿ)"),
              Seen.in = c("Binary search", "Linear recursion", "Merge sort", "Quicksort worst case", "Tree traversal", "Naive subsets / Hanoi"),
              stringsAsFactors = FALSE))
          ),
          box(title = "Best, average, worst, amortised", status = "info", solidHeader = TRUE, width = 3,
            cplx_table(data.frame(
              Term = c("Worst case", "Average case", "Amortised", "Best case"),
              Means = c("Guarantee for any input", "Expected over random inputs", "Average per op over a sequence", "Luckiest input — rarely useful"),
              stringsAsFactors = FALSE)),
            hint("Default to worst case unless you say otherwise.")
          )
        ),
        fluidRow(
          box(title = "The data-structure cheat-sheet", status = "success", solidHeader = TRUE, width = 12,
            cplx_table(data.frame(
              Structure = c("Array / dynamic array", "Linked list", "Stack / queue (deque)", "Hash map / set", "Balanced BST", "Binary heap", "Trie", "Union-Find"),
              Access = c("O(1)", "O(n)", "O(1) at ends", "—", "O(log n)", "O(1) best only", "O(L)", "—"),
              Search = c("O(n) · O(log n) if sorted", "O(n)", "O(n)", "O(1) avg", "O(log n)", "O(n)", "O(L)", "O(α(n)) find"),
              Insert = c("O(1) amortised at end · O(n) middle", "O(1) at known node", "O(1)", "O(1) avg", "O(log n)", "O(log n)", "O(L)", "O(α(n)) union"),
              Delete = c("O(n)", "O(1) at known node", "O(1)", "O(1) avg", "O(log n)", "O(log n) best only", "O(L)", "—"),
              Space = c("O(n)", "O(n)", "O(n)", "O(n)", "O(n)", "O(n)", "O(total chars)", "O(n)"),
              Reach.for.it.when = c("Index access, cache-friendly scans", "Cheap splicing, LRU lists", "LIFO / FIFO processing, BFS / DFS", "Lookup, counting, de-duplication", "Sorted order, range and nearest queries", "Repeated min / max, top-K", "Prefix queries", "Dynamic connectivity"),
              stringsAsFactors = FALSE))
          )
        ),
        fluidRow(
          box(title = "Hidden costs in everyday Python", status = "warning", solidHeader = TRUE, width = 12,
            cplx_table(data.frame(
              Operation = c("x in list", "x in set / dict", "list.append(x)", "list.insert(0, x) / list.pop(0)", "deque.appendleft / popleft", "s += t in a loop (strings)", "''.join(parts)", "list[a:b]", "sorted(list)", "min(list) / max(list) / sum(list)", "heapq.heappush / heappop"),
              Cost = c("O(n)", "O(1) average", "O(1) amortised", "O(n)", "O(1)", "O(n²) overall", "O(total length)", "O(b − a) — it copies", "O(n log n)", "O(n)", "O(log n)"),
              stringsAsFactors = FALSE))
          )
        )
      ),

      practice = tagList(
        fluidRow(
          box(title = "Knowledge Check", status = "warning", solidHeader = TRUE, width = 6, quiz_ui(ns)),
          box(title = "Practise the skill", status = "success", solidHeader = TRUE, width = 6,
            callout("Complexity analysis is practised on <i>every</i> problem. Build the habit with this routine:", "info"),
            tags$ol(style = "font-size:13px; color:#475569; line-height:1.9;",
              tags$li("Read the constraints and write down the target complexity before thinking about the algorithm."),
              tags$li("State the brute force and its cost. Name the term you need to eliminate."),
              tags$li("After coding, annotate each loop and each data-structure call with its cost."),
              tags$li("State final time and space, including the recursion stack and the output size."),
              tags$li("Ask yourself whether a lower bound says you are already optimal.")),
            callout("Use <b>Analyse This</b> on the Visualise tab until you can call each pattern on sight.", "tip"))
        ),
        ref_block(
          "Cormen, Leiserson, Rivest & Stein (2022). Introduction to Algorithms (4th ed.) — ch. 3 (asymptotic notation), ch. 4 (recurrences), ch. 16 (amortised analysis).",
          "Knuth, D. E. (1976). Big Omicron and big Omega and big Theta. SIGACT News 8(2).",
          "Sedgewick & Wayne (2011). Algorithms (4th ed.) — §1.4 analysis of algorithms.")
      )
    )
  )
}

bigo_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    output$growth <- renderPlotly({
      sel <- input$classes; validate(need(length(sel) >= 1, "Tick at least one complexity class."))
      nmax <- input$nmax; n <- unique(round(seq(1, nmax, length.out = 200)))
      cap <- if (isTRUE(input$logy)) 1e30 else {
        poly <- sel[vapply(sel, function(k) BIGO[[k]]$poly, logical(1))]
        if (length(poly)) max(vapply(poly, function(k) max(BIGO[[k]]$f(nmax)), numeric(1))) * 1.15 else Inf
      }
      p <- plot_ly(height = 340)
      for (k in sel) {
        y <- BIGO[[k]]$f(n); keep <- is.finite(y) & y <= cap * 1.5
        p <- add_trace(p, x = n[keep], y = y[keep], type = "scatter", mode = "lines", name = BIGO[[k]]$lab, line = list(color = BIGO[[k]]$col, width = 3))
      }
      p <- dsa_layout(p, xt = "input size n", yt = "operations", legend = TRUE)
      if (isTRUE(input$logy)) layout(p, yaxis = list(type = "log")) else if (is.finite(cap)) layout(p, yaxis = list(range = c(0, cap))) else p
    })
    output$growth_note <- renderUI({
      n <- input$nmax; f <- function(x) format(signif(x, 3), big.mark = ",", scientific = x >= 1e15)
      callout(sprintf("At <b>n = %d</b>: log n ≈ %s · n log n ≈ %s · n² = %s · 2ⁿ ≈ %s.<br>On a linear axis the exponential curves leave the chart almost immediately — switch to <b>log scale</b> to compare them all.",
                      n, f(log2(n)), f(n * log2(n)), f(n^2), if (n <= 1000) format(2^n, digits = 3) else "∞"), "warn")
    })

    output$feas <- renderUI({
      n <- as.numeric(input$n_pick); ops_sec <- 1e8
      dur <- function(s) {
        if (!is.finite(s)) return("longer than the universe")
        if (s < 1e-3) "instant" else if (s < 1) sprintf("%.0f ms", s * 1000) else if (s < 60) sprintf("%.1f s", s) else if (s < 3600) sprintf("%.0f min", s / 60)
        else if (s < 86400) sprintf("%.1f hours", s / 3600) else if (s < 3.15e7) sprintf("%.0f days", s / 86400) else if (s < 3.15e7 * 1e9) sprintf("%s years", format(signif(s / 3.15e7, 2), big.mark = ",", scientific = FALSE)) else "longer than the universe"
      }
      rows <- lapply(names(BIGO), function(k) {
        ops <- suppressWarnings(BIGO[[k]]$f(n)); if (k == "expo" && n > 1000) ops <- Inf
        if (k == "fact" && n > 170) ops <- Inf
        s <- ops / ops_sec; ok <- is.finite(s) && s <= 1; near <- is.finite(s) && s > 1 && s <= 10
        data.frame(Complexity = BIGO[[k]]$lab,
                   Operations = if (is.finite(ops)) format(signif(ops, 3), big.mark = ",", scientific = ops >= 1e15) else "astronomically many",
                   Time = dur(s),
                   Verdict = if (ok) "<span style='color:#059669;font-weight:700;'>✓ fine</span>" else if (near) "<span style='color:#d97706;font-weight:700;'>~ risky</span>" else "<span style='color:#dc2626;font-weight:700;'>✗ too slow</span>",
                   stringsAsFactors = FALSE)
      })
      d <- do.call(rbind, rows)
      best <- d$Complexity[max(which(grepl("fine", d$Verdict)))]
      tagList(cplx_table(d), explain(sprintf("For n = %s, the slowest class that still fits in about a second is <b>%s</b>. Aim for that or better.", format(n, big.mark = ",", scientific = FALSE), best)))
    })

    # ── Analyse this ─────────────────────────────────────────────────────────
    shown <- reactiveVal(FALSE)
    observeEvent(input$snip, shown(FALSE))
    observeEvent(input$reveal, shown(TRUE))
    output$snip_code <- renderUI(dsa_code(BIGO_SNIPPETS[[input$snip]]$code))
    output$snip_plot <- renderPlotly({
      s <- BIGO_SNIPPETS[[input$snip]]; n <- if (input$snip == "fib") 1:20 else seq(1, 64, by = 1)
      plot_ly(x = n, y = s$f(n), type = "scatter", mode = "lines+markers", height = 230, line = list(color = COL$pri, width = 2.5), marker = list(color = COL$pri, size = 4)) %>%
        dsa_layout(title = "Operations actually executed", xt = "n", yt = "operations")
    })
    output$snip_ans <- renderUI({
      s <- BIGO_SNIPPETS[[input$snip]]
      if (!shown()) return(explain("Decide the complexity yourself first — the shape of the curve is a hint — then reveal."))
      callout(sprintf("<b>%s.</b> %s", s$ans, s$why), "success")
    })

    # ── Amortised ────────────────────────────────────────────────────────────
    am <- reactive({
      n <- input$am_n; req(n); cap <- 1; size <- 0; cost <- numeric(n); resize <- logical(n)
      for (i in seq_len(n)) {
        if (size == cap) { cost[i] <- size + 1; resize[i] <- TRUE; cap <- if (input$am_mode == "double") cap * 2 else cap + 4 } else cost[i] <- 1
        size <- size + 1
      }
      list(n = n, cost = cost, resize = resize)
    })
    output$am_plot <- renderPlotly({
      r <- am()
      plot_ly(x = seq_len(r$n), height = 230) %>%
        add_bars(y = r$cost, name = "cost of this append", marker = list(color = ifelse(r$resize, COL$err, COL$idle))) %>%
        add_trace(y = cumsum(r$cost) / seq_len(r$n), type = "scatter", mode = "lines", name = "running average", line = list(color = COL$pri, width = 3)) %>%
        dsa_layout(xt = "append number", yt = "element writes", legend = TRUE)
    })
    output$am_explain <- renderUI({
      r <- am(); avg <- sum(r$cost) / r$n
      if (input$am_mode == "double") explain(sprintf("Red spikes are resizes that copy everything — but they get <b>rarer</b> as the array grows. Total = %d writes for %d appends → <b>%.2f per append</b>, and that average never exceeds 3. That is O(1) amortised.", sum(r$cost), r$n, avg))
      else explain(sprintf("Growing by a fixed amount triggers a full copy every 4 appends, forever. Total = %d writes for %d appends → <b>%.1f per append and climbing</b>. That is O(n) amortised, O(n²) overall — which is why real dynamic arrays grow geometrically.", sum(r$cost), r$n, avg))
    })

    quiz_server(input, output, session, topic = "bigo", progress = progress, questions = list(
      list(q = "<code>f(n) = 5n² + 200n + 10⁶</code> is…",
           opts = c("O(n)", "O(n²)", "O(10⁶)", "O(n² + n)"), ans = 2,
           why = "Keep the fastest-growing term and drop its constant. For large n, 5n² dwarfs everything else."),
      list(q = "The constraint says n ≤ 200,000. Which approach is the slowest that will still pass?",
           opts = c("O(n²)", "O(n log n)", "O(2ⁿ)", "O(n³)"), ans = 2,
           why = "n² would be 4 × 10¹⁰ operations — minutes. n log n is about 3.5 million."),
      list(q = "A loop runs <code>i = 1, 2, 4, 8, …</code> while <code>i &lt; n</code>. Its complexity is…",
           opts = c("O(n)", "O(√n)", "O(log n)", "O(1)"), ans = 3,
           why = "i doubles each time, so it reaches n after log₂n iterations."),
      list(q = "Appending to a dynamic array is O(1) <b>amortised</b>. That means…",
           opts = c("Every append takes constant time", "Occasional appends are O(n), but the average over any long sequence is constant", "It is O(1) only on average-case input", "It is O(log n) in the worst case"), ans = 2,
           why = "Resizes are expensive but geometrically rare; spread across all appends the cost per operation is bounded by a constant."),
      list(q = "What is the <b>space</b> complexity of a recursive DFS on a binary tree with n nodes and height h?",
           opts = c("O(1)", "O(h)", "O(n²)", "O(log n) always"), ans = 2,
           why = "The call stack holds one frame per level of the current path: O(h), which is O(log n) if balanced but O(n) if skewed."),
      list(q = "In Python, <code>if x in my_list</code> inside a loop over n items costs in total…",
           opts = c("O(n)", "O(n log n)", "O(n²)", "O(1)"), ans = 3,
           why = "Membership in a list is a linear scan. Doing it n times is quadratic — switch to a set for O(n) overall.")
    ))
  })
}
