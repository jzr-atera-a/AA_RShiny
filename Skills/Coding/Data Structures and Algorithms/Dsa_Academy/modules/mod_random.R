# modules/mod_random.R — Randomised Algorithms: weighted pick, reservoir sampling, Fisher–Yates, rejection sampling.

random_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🎲", "Randomised Algorithms",
      "Interviewers ask these to see whether you can argue that something is uniformly random, not just write code that looks random. Every visual here pairs an algorithm with an experiment that checks it.",
      c("Weighted Pick", "Reservoir Sampling", "Fisher–Yates", "Rejection Sampling", "Quickselect", "Expected Value")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Random Pick with Weight (#528) — prefix sums + binary search", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(5, textInput(ns("wp_w"), "Weights:", "1, 3, 2, 4")),
              column(3, numericInput(ns("wp_n"), "Simulated picks:", 5000, min = 100, max = 100000, step = 500)),
              column(2, numericInput(ns("wp_seed"), "Seed:", 7)),
              column(2, tags$div(style = "margin-top:25px;", actionButton(ns("wp_go"), "Run", class = "btn btn-dsa btn-sm")))
            ),
            plotlyOutput(ns("wp_line"), height = "150px"),
            plotlyOutput(ns("wp_hist"), height = "250px")
          ),
          box(title = "One pick, step by step", status = "info", solidHeader = TRUE, width = 4,
            stepper_ui(ns, "wp"),
            uiOutput(ns("wp_viz")),
            callout("Each index owns a slice of [0, total) as wide as its weight, so P(i) = wᵢ / Σw. <code>bisect_right(prefix, r)</code> finds the slice in O(log n).", "tip"))
        ),
        fluidRow(
          box(title = "Reservoir Sampling — uniform k from a stream of unknown length", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(3, numericInput(ns("rs_n"), "Stream length n:", 12, min = 3, max = 30)),
              column(2, numericInput(ns("rs_k"), "k:", 3, min = 1, max = 10)),
              column(2, numericInput(ns("rs_seed"), "Seed:", 3)),
              column(5, stepper_ui(ns, "rs"))
            ),
            uiOutput(ns("rs_viz")),
            tags$hr(),
            fluidRow(column(4, numericInput(ns("rs_trials"), "Trials for the experiment:", 20000, min = 1000, max = 200000, step = 1000)),
                     column(3, tags$div(style = "margin-top:25px;", actionButton(ns("rs_go"), "Run experiment", class = "btn btn-dsa btn-sm")))),
            plotlyOutput(ns("rs_hist"), height = "240px")
          ),
          box(title = "Why every item ends with probability k / n", status = "info", solidHeader = TRUE, width = 4,
            withMathJax(),
            tags$p("Item ", tags$i("i"), " (1-based, i > k) enters with probability k / i. Each later item j evicts it with probability (k / j) · (1 / k) = 1 / j, so it survives step j with probability (j − 1) / j."),
            tags$p(HTML("P(keep) = <sup>k</sup>⁄<sub>i</sub> · <sup>i</sup>⁄<sub>i+1</sub> · <sup>i+1</sup>⁄<sub>i+2</sub> ⋯ <sup>n−1</sup>⁄<sub>n</sub> = <b><sup>k</sup>⁄<sub>n</sub></b> — the product telescopes.")),
            callout("Linked List Random Node (#382) is the k = 1 case: replace the answer with the i-th node with probability 1 / i.", "info"),
            callout("Random Pick Index (#398) applies the same idea only to positions holding the target value.", "info"))
        ),
        fluidRow(
          box(title = "Shuffling — Fisher–Yates vs. the naive swap", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(4, textInput(ns("fy_arr"), "Array:", "A, B, C, D, E, F")),
              column(2, numericInput(ns("fy_seed"), "Seed:", 11)),
              column(6, stepper_ui(ns, "fy"))
            ),
            uiOutput(ns("fy_viz")),
            tags$hr(),
            fluidRow(column(4, actionButton(ns("fy_go"), "Compare 60 000 shuffles of [1, 2, 3]", class = "btn btn-dsa btn-sm"))),
            plotlyOutput(ns("fy_bias"), height = "260px")
          ),
          box(title = "Spot the bug", status = "info", solidHeader = TRUE, width = 4,
            dsa_code(
'# correct: j drawn from [i, n-1]
for i in range(n - 1):
    j = random.randint(i, n - 1)
    a[i], a[j] = a[j], a[i]

# biased: j drawn from [0, n-1]
for i in range(n):
    j = random.randint(0, n - 1)
    a[i], a[j] = a[j], a[i]', "Shuffle An Array (#384)"),
            callout("The naive loop has nⁿ equally likely execution paths but n! permutations. For n = 3: 27 paths cannot split evenly over 6 outcomes, so some permutations <b>must</b> be more likely.", "warn"))
        ),
        fluidRow(
          box(title = "Rejection Sampling — rand10() from rand7() (#470)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(column(3, numericInput(ns("rj_n"), "Calls to rand10():", 3000, min = 100, max = 50000, step = 500)),
                     column(2, tags$div(style = "margin-top:25px;", actionButton(ns("rj_go"), "Simulate", class = "btn btn-dsa btn-sm")))),
            fluidRow(column(5, uiOutput(ns("rj_grid"))), column(7, plotlyOutput(ns("rj_hist"), height = "260px"))))
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("'Pick with probability proportional to weight' → prefix sums + binary search (or alias method for O(1)).",
                   "'Stream', 'unknown length', 'linked list, constant space' → reservoir sampling.",
                   "'Shuffle', 'every permutation equally likely' → Fisher–Yates.",
                   "'Implement randX using randY' → combine calls to cover a range, reject the leftovers."),
          pitfalls = c("<code>random.randint(a, b)</code> is <b>inclusive</b> of b; <code>random.randrange(a, b)</code> is not.",
                       "Using <code>bisect_left</code> with <code>random.random() * total</code> mis-assigns exact boundary values — use <code>bisect_right</code>, or draw an integer in [1, total] with <code>bisect_left</code>.",
                       "Taking <code>rand7() % 5</code>: 7 outcomes cannot split evenly into 5 bins.",
                       "Shuffling by sorting with a random comparator — biased and O(n log n)."),
          tips = c("Prove uniformity out loud: count outcomes, or show the telescoping product.",
                   "Quote expected costs: rand10 from rand7 uses 49 / 40 ≈ 1.225 pairs of calls on average.",
                   "Mention testing: run many trials and compare frequencies with a chi-square test.")
        ),
        fluidRow(
          box(title = "Algorithms at a glance", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Algorithm = c("Weighted pick (prefix + bisect)", "Alias method (Vose)", "Reservoir sampling", "Fisher–Yates shuffle", "Rejection sampling", "Quickselect (random pivot)", "Randomised quicksort"),
              Setup = c("O(n)", "O(n)", "—", "—", "—", "—", "—"),
              Per.call = c("O(log n)", "O(1)", "O(1) per item", "O(n)", "expected O(1)", "expected O(n)", "expected O(n log n)"),
              Space = c("O(n)", "O(n)", "O(k)", "O(1)", "O(1)", "O(1)", "O(log n)"),
              stringsAsFactors = FALSE))),
          box(title = "Probability you should be able to state", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Fact = c("Geometric trials until success p", "Coupon collector (n types)", "Birthday collision ≈ 50%", "Random pivot is 'good' (middle half)"),
              Value = c("1 / p", "n · Hₙ ≈ n ln n", "≈ 1.18 √N", "probability 1/2"),
              stringsAsFactors = FALSE)))
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4, dsa_code(
'import bisect, itertools, random

class Solution:                    # 528
    def __init__(self, w):
        self.pre = list(itertools.accumulate(w))
    def pickIndex(self):
        r = random.randint(1, self.pre[-1])
        return bisect.bisect_left(self.pre, r)', "Weighted pick")),
              column(4, dsa_code(
'def reservoir(stream, k):
    res = []
    for i, x in enumerate(stream, 1):
        if i <= k:
            res.append(x)
        else:
            j = random.randint(1, i)
            if j <= k:
                res[j - 1] = x
    return res', "Reservoir sampling")),
              column(4, dsa_code(
'def rand10():
    while True:
        idx = (rand7() - 1) * 7 + rand7()   # uniform 1..49
        if idx <= 40:
            return 1 + (idx - 1) % 10
        # 41..49 rejected → try again', "Rejection sampling")))
          )
        )
      ),

      practice = practice_tab(ns, "random",
        "Vitter, J. S. (1985). Random sampling with a reservoir. ACM Transactions on Mathematical Software, 11(1), 37–57.",
        "Knuth, D. E. (1997). The Art of Computer Programming, Vol. 2: Seminumerical Algorithms (3rd ed.) — §3.4.2.",
        "Mitzenmacher, M. & Upfal, E. (2017). Probability and Computing (2nd ed.). Cambridge University Press.")
    )
  )
}

random_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    # ── Weighted pick ────────────────────────────────────────────────────────
    wp_w <- reactive({
      w <- parse_ints(input$wp_w); w <- w[w > 0]
      validate(need(length(w) >= 2, "Enter at least two positive integer weights."))
      head(w, 12)
    })
    wp_sim <- eventReactive(list(input$wp_go, wp_w()), {
      w <- wp_w(); n <- max(100, min(100000, input$wp_n %||% 5000)); set.seed(input$wp_seed %||% 7)
      pre <- cumsum(w); r <- sample.int(pre[length(pre)], n, replace = TRUE)
      idx <- findInterval(r - 1, pre) + 1
      list(w = w, n = n, counts = tabulate(idx, length(w)))
    }, ignoreNULL = FALSE)
    wp_steps <- reactive({
      w <- wp_w(); pre <- cumsum(w); set.seed((input$wp_seed %||% 7) + 1000); r <- sample.int(pre[length(pre)], 1)
      lo <- 1; hi <- length(pre); steps <- list(list(lo = lo, hi = hi, mid = NA, r = r, pre = pre,
        msg = sprintf("Draw r uniformly from 1..%d → <b>r = %d</b>. Find the first prefix ≥ r (bisect_left).", pre[length(pre)], r)))
      while (lo < hi) {
        mid <- (lo + hi) %/% 2
        go <- pre[mid] >= r
        steps[[length(steps) + 1]] <- list(lo = lo, hi = hi, mid = mid, r = r, pre = pre,
          msg = sprintf("prefix[%d] = %d %s r = %d → %s", mid - 1, pre[mid], if (go) "≥" else "&lt;", r, if (go) "answer is here or left: hi = mid" else "go right: lo = mid + 1"))
        if (go) hi <- mid else lo <- mid + 1
      }
      steps[[length(steps) + 1]] <- list(lo = lo, hi = lo, mid = lo, r = r, pre = pre, done = TRUE,
        msg = sprintf("Pick <b>index %d</b> (weight %d owns r ∈ [%d, %d]).", lo - 1, w[lo], if (lo == 1) 1 else pre[lo - 1] + 1, pre[lo]))
      steps
    })
    wp <- stepper_server(input, output, session, "wp", wp_steps, speed = 900)
    pal <- c(COL$pri, COL$sec, COL$acc, COL$ok, COL$warn, COL$pink, "#64748b", "#0ea5e9", "#84cc16", "#f97316", "#a855f7", "#14b8a6")
    output$wp_line <- renderPlotly({
      w <- wp_w(); pre <- cumsum(w); s <- wp$cur()
      p <- plot_ly(height = 150)
      for (i in seq_along(w)) p <- add_bars(p, x = w[i], y = "slices", base = if (i == 1) 0 else pre[i - 1], orientation = "h",
                                             marker = list(color = pal[(i - 1) %% 12 + 1], line = list(color = "#fff", width = 2)),
                                             text = sprintf("i=%d (w=%d)", i - 1, w[i]), textposition = "inside", insidetextfont = list(color = "#fff"),
                                             hoverinfo = "text", hovertext = sprintf("index %d owns r in %d..%d", i - 1, if (i == 1) 1 else pre[i - 1] + 1, pre[i]), name = i)
      p %>% dsa_layout(xt = "r (integer in 1..total)") %>%
        layout(barmode = "stack", margin = list(t = 10, b = 40, l = 50, r = 15),
               shapes = list(list(type = "line", x0 = s$r - 0.5, x1 = s$r - 0.5, y0 = -0.5, y1 = 0.5, line = list(color = COL$err, width = 3))),
               annotations = list(list(x = s$r - 0.5, y = 0.55, text = paste("r =", s$r), showarrow = FALSE, font = list(color = COL$err))))
    })
    output$wp_hist <- renderPlotly({
      s <- wp_sim(); exp <- s$w / sum(s$w); obs <- s$counts / s$n
      chi <- sum((s$counts - exp * s$n)^2 / (exp * s$n)); pv <- pchisq(chi, df = length(s$w) - 1, lower.tail = FALSE)
      plot_ly(height = 250) %>%
        add_bars(x = seq_along(s$w) - 1, y = obs, name = "observed", marker = list(color = pal[(seq_along(s$w) - 1) %% 12 + 1])) %>%
        add_markers(x = seq_along(s$w) - 1, y = exp, name = "expected wᵢ/Σw", marker = list(symbol = "line-ew-open", size = 34, color = COL$ink, line = list(width = 3))) %>%
        dsa_layout(title = sprintf("%s picks — χ² = %.2f, p = %.3f %s", format(s$n, big.mark = ","), chi, pv, if (pv > 0.01) "(consistent with the weights)" else "(suspicious!)"),
                   xt = "index", yt = "share of picks", legend = TRUE) %>% layout(xaxis = list(dtick = 1))
    })
    output$wp_viz <- renderUI({
      s <- wp$cur(); n <- length(s$pre); cls <- rep("", n)
      if (!isTRUE(s$done)) { cls[setdiff(seq_len(n), s$lo:s$hi)] <- "visited"; if (!is.na(s$mid)) cls[s$mid] <- "active" } else cls[s$mid] <- "found"
      tagList(tags$div(class = "code-title", "prefix sums"), vrow(s$pre, cls, ptr = list(lo = s$lo, hi = s$hi)), explain(s$msg))
    })

    # ── Reservoir ────────────────────────────────────────────────────────────
    rs_par <- reactive({
      n <- max(3, min(30, as.integer(input$rs_n %||% 12))); k <- max(1, min(n - 1, min(10, as.integer(input$rs_k %||% 3))))
      list(n = n, k = k)
    })
    rs_steps <- reactive({
      p <- rs_par(); n <- p$n; k <- p$k; set.seed(input$rs_seed %||% 3)
      res <- integer(0); steps <- list()
      for (i in seq_len(n)) {
        if (i <= k) { res <- c(res, i); slot <- i
          msg <- sprintf("Item %d: the reservoir is not full yet → take it (slot %d).", i, i - 1)
        } else {
          j <- sample.int(i, 1); slot <- if (j <= k) j else NA
          msg <- if (j <= k) sprintf("Item %d: draw j ∈ [1, %d] → j = %d ≤ k = %d (prob %d/%d) → <b>replace slot %d</b> (item %d out).", i, i, j, k, k, i, j - 1, res[j])
                 else sprintf("Item %d: draw j ∈ [1, %d] → j = %d &gt; k → discard (kept with prob %d/%d).", i, i, j, k, i)
          if (j <= k) res[j] <- i
        }
        steps[[i]] <- list(i = i, res = res, slot = slot, msg = msg)
      }
      steps[[n]]$msg <- paste(steps[[n]]$msg, sprintf("<b>Stream ended — each of the %d items had probability %d/%d of being in the final sample.</b>", n, k, n))
      steps
    })
    rs <- stepper_server(input, output, session, "rs", rs_steps, speed = 700)
    output$rs_viz <- renderUI({
      s <- rs$cur(); n <- rs_par()$n
      cls <- ifelse(seq_len(n) < s$i, "visited", ""); cls[s$i] <- "active"; cls[seq_len(n) %in% s$res & seq_len(n) != s$i] <- "found"
      rcls <- rep("", length(s$res)); if (!is.na(s$slot)) rcls[s$slot] <- "active"
      tagList(tags$div(class = "code-title", "stream (item numbers)"), vrow(seq_len(n), cls, idx = FALSE),
              tags$div(class = "code-title", "reservoir slots"), vrow(s$res, rcls), explain(s$msg))
    })
    rs_sim <- eventReactive(list(input$rs_go, rs_par()), {
      p <- rs_par(); n <- p$n; k <- p$k; T <- max(1000, min(200000, input$rs_trials %||% 20000)); set.seed(42)
      cnt <- integer(n)
      for (t in seq_len(T)) {
        res <- seq_len(k)
        if (n > k) { j <- vapply((k + 1):n, function(i) sample.int(i, 1), 1L)
          for (m in seq_along(j)) if (j[m] <= k) res[j[m]] <- k + m }
        cnt[res] <- cnt[res] + 1L
      }
      list(cnt = cnt, T = T, k = k, n = n)
    }, ignoreNULL = FALSE)
    output$rs_hist <- renderPlotly({
      s <- rs_sim()
      plot_ly(x = seq_len(s$n), y = s$cnt / s$T, type = "bar", height = 240, marker = list(color = COL$sec), name = "observed") %>%
        dsa_layout(title = sprintf("%s runs: how often each item ended in the sample (target k/n = %.3f)", format(s$T, big.mark = ","), s$k / s$n),
                   xt = "item", yt = "probability") %>%
        layout(xaxis = list(dtick = 1), yaxis = list(range = c(0, min(1, 1.6 * s$k / s$n))),
               shapes = list(list(type = "line", x0 = 0.5, x1 = s$n + 0.5, y0 = s$k / s$n, y1 = s$k / s$n, line = list(color = COL$err, dash = "dash"))))
    })

    # ── Fisher–Yates ─────────────────────────────────────────────────────────
    fy_steps <- reactive({
      a <- trimws(strsplit(input$fy_arr %||% "", ",")[[1]]); a <- head(a[nzchar(a)], 10)
      validate(need(length(a) >= 2, "Enter at least two comma-separated items."))
      n <- length(a); set.seed(input$fy_seed %||% 11)
      steps <- list(list(a = a, i = NA, j = NA, fixed = 0, msg = "Walk left to right. Position i receives a uniformly random element from the <b>not-yet-placed</b> suffix a[i..n−1]."))
      for (i in seq_len(n - 1)) {
        j <- if (i == n) n else i + sample.int(n - i + 1, 1) - 1
        a[c(i, j)] <- a[c(j, i)]
        steps[[length(steps) + 1]] <- list(a = a, i = i, j = j, fixed = i,
          msg = sprintf("i = %d: j = randint(%d, %d) = %d → swap. Position %d is now final (%d choices, each probability 1/%d).", i - 1, i - 1, n - 1, j - 1, i - 1, n - i + 1, n - i + 1))
      }
      steps[[length(steps) + 1]] <- list(a = a, i = NA, j = NA, fixed = n,
        msg = sprintf("Done. The number of possible runs is %d · %d · … · 1 = %d! — exactly one run per permutation, so all are equally likely.", n, n - 1, n))
      steps
    })
    fy <- stepper_server(input, output, session, "fy", fy_steps, speed = 800)
    output$fy_viz <- renderUI({
      s <- fy$cur(); n <- length(s$a)
      cls <- ifelse(seq_len(n) <= s$fixed, "found", ""); if (!is.na(s$i)) { cls[s$j] <- "pivot"; cls[s$i] <- "active" }
      tagList(vrow(s$a, cls, ptr = if (!is.na(s$i)) list(i = s$i, j = s$j) else NULL), explain(s$msg))
    })
    fy_sim <- eventReactive(input$fy_go, {
      set.seed(1); N <- 60000; perms <- c("123", "132", "213", "231", "312", "321")
      good <- character(N); bad <- character(N)
      for (t in seq_len(N)) {
        a <- 1:3; for (i in 1:2) { j <- i + sample.int(4 - i, 1) - 1; a[c(i, j)] <- a[c(j, i)] }; good[t] <- paste(a, collapse = "")
        b <- 1:3; for (i in 1:3) { j <- sample.int(3, 1); b[c(i, j)] <- b[c(j, i)] }; bad[t] <- paste(b, collapse = "")
      }
      data.frame(perm = rep(perms, 2), method = rep(c("Fisher–Yates", "naive swap"), each = 6),
                 share = c(as.numeric(table(factor(good, perms))), as.numeric(table(factor(bad, perms)))) / N)
    })
    output$fy_bias <- renderPlotly({
      d <- tryCatch(fy_sim(), error = function(e) NULL)
      if (is.null(d)) {
        d <- data.frame(perm = rep(c("123", "132", "213", "231", "312", "321"), 2), method = rep(c("Fisher–Yates", "naive swap"), each = 6),
                        share = c(rep(1 / 6, 6), c(4, 5, 5, 5, 4, 4) / 27))
        ttl <- "Exact probabilities (press the button to simulate)"
      } else ttl <- "60 000 simulated shuffles of [1, 2, 3]"
      plot_ly(d, x = ~perm, y = ~share, color = ~method, colors = c(COL$ok, COL$err), type = "bar", height = 260) %>%
        dsa_layout(title = ttl, xt = "resulting permutation", yt = "share", legend = TRUE) %>%
        layout(shapes = list(list(type = "line", x0 = -0.5, x1 = 5.5, y0 = 1 / 6, y1 = 1 / 6, line = list(color = COL$ink, dash = "dot"))))
    })

    # ── Rejection sampling ───────────────────────────────────────────────────
    output$rj_grid <- renderUI({
      m <- outer(0:6, 1:7, function(r, c) r * 7 + c)
      lab <- ifelse(m <= 40, as.character((m - 1) %% 10 + 1), "✗")
      cls <- ifelse(m <= 40, "", "g-todo")
      tagList(tags$div(class = "code-title", "rows = first rand7(), columns = second rand7(); cell → rand10 value"),
              dp_grid(lab, 1:7, 1:7, cls),
              hint("40 of 49 cells map evenly (4 cells per value); the 9 grey cells are rejected and we draw again."))
    })
    output$rj_hist <- renderPlotly({
      input$rj_go
      n <- max(100, min(50000, isolate(input$rj_n) %||% 3000)); calls <- 0; out <- integer(n)
      for (t in seq_len(n)) repeat { idx <- (sample.int(7, 1) - 1) * 7 + sample.int(7, 1); calls <- calls + 2; if (idx <= 40) { out[t] <- (idx - 1) %% 10 + 1; break } }
      plot_ly(x = 1:10, y = tabulate(out, 10) / n, type = "bar", height = 260, marker = list(color = COL$acc)) %>%
        dsa_layout(title = sprintf("%s results — %.3f rand7() calls per rand10() (theory 2·49/40 = 2.45)", format(n, big.mark = ","), calls / n),
                   xt = "rand10() value", yt = "share") %>%
        layout(xaxis = list(dtick = 1), shapes = list(list(type = "line", x0 = 0.5, x1 = 10.5, y0 = 0.1, y1 = 0.1, line = list(color = COL$err, dash = "dash"))))
    })

    quiz_server(input, output, session, topic = "random", progress = progress, questions = list(
      list(q = "Weights [1, 3]: what is the probability of picking index 1?", opts = c("1/2", "3/4", "1/3", "1/4"), ans = 2,
           why = "P(i) = wᵢ / Σw = 3 / 4."),
      list(q = "In reservoir sampling with k = 1, the i-th item replaces the current answer with probability…", opts = c("1/2", "1/n", "1/i", "i/n"), ans = 3,
           why = "Then P(item i survives to the end) = (1/i) · Π (j−1)/j = 1/n."),
      list(q = "Why is 'swap a[i] with a[randint(0, n−1)] for every i' biased?", opts = c("It is O(n²)", "nⁿ equally likely runs cannot divide evenly among n! permutations", "It never moves the last element", "randint is biased"), ans = 2,
           why = "For n = 3, 27 runs over 6 permutations: 27 is not a multiple of 6."),
      list(q = "rand10() from rand7(): what is wrong with (rand7() + rand7()) % 10?", opts = c("Nothing", "The sum of two uniforms is not uniform", "It can return 0", "Both b and c"), ans = 4,
           why = "Sums peak in the middle (triangular distribution) and % 10 can produce 0."),
      list(q = "Expected number of loop iterations for rejection sampling with acceptance probability 40/49 is…", opts = c("1", "40/49", "49/40", "2"), ans = 3,
           why = "Trials until success are geometric: expected 1/p = 49/40 ≈ 1.225.")
    ))
  })
}
