# modules/mod_arrays.R — Arrays & Strings

arrays_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("📐", "Arrays & Strings",
      "Contiguous memory with O(1) index access. Most array problems fall to one of five patterns: binary search, two pointers, sliding window, prefix sums, or Kadane.",
      c("Binary Search", "Two Pointers", "Sliding Window", "Prefix Sum", "Kadane")),

    topic_tabs(ns,
      # ── Visualise ──────────────────────────────────────────────────────────
      visual = tagList(
        fluidRow(
          box(title = "Binary Search — halve the search space each step", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(8, textInput(ns("bs_arr"), "Array (sorted automatically):", "2,5,8,12,16,23,38,56,72,91")),
              column(4, numericInput(ns("bs_target"), "Target:", 23))
            ),
            stepper_ui(ns, "bs"),
            uiOutput(ns("bs_viz")),
            legend_row(c("mid (probe)" = COL$pri, "still in play" = "#ffffff", "discarded" = "#e2e8f0", "found" = COL$ok))
          ),
          box(title = "What the code is doing", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("bs_code")),
            uiOutput(ns("bs_kpi"))
          )
        ),
        fluidRow(
          box(title = "Two Pointers — pair with a target sum (sorted input)", status = "primary", solidHeader = TRUE, width = 6,
            fluidRow(
              column(8, textInput(ns("tp_arr"), "Array:", "1,3,4,6,8,10,13,17")),
              column(4, numericInput(ns("tp_target"), "Target sum:", 16))
            ),
            stepper_ui(ns, "tp"),
            uiOutput(ns("tp_viz")),
            hint("Why it works: if <code>a[L] + a[R]</code> is too small, no pair using <code>a[L]</code> can work (R is already the largest), so L is safely discarded. Each step eliminates one element → O(n).")
          ),
          box(title = "Sliding Window — max sum of any k consecutive values", status = "primary", solidHeader = TRUE, width = 6,
            fluidRow(
              column(8, textInput(ns("sw_arr"), "Array:", "2,1,5,1,3,2,4,6,1")),
              column(4, numericInput(ns("sw_k"), "Window k:", 3, min = 1))
            ),
            stepper_ui(ns, "sw"),
            plotlyOutput(ns("sw_plot"), height = "230px"),
            uiOutput(ns("sw_explain")),
            legend_row(c("current window" = COL$acc, "best so far" = COL$warn, "outside" = COL$idle))
          )
        ),
        fluidRow(
          box(title = "Kadane's Algorithm — maximum subarray", status = "primary", solidHeader = TRUE, width = 7,
            textInput(ns("kd_arr"), "Array (include negatives):", "-2,1,-3,4,-1,2,1,-5,4"),
            plotlyOutput(ns("kd_plot"), height = "270px"),
            uiOutput(ns("kd_explain"))
          ),
          box(title = "Prefix Sums — range sum in O(1)", status = "primary", solidHeader = TRUE, width = 5,
            textInput(ns("ps_arr"), "Array:", "3,1,4,1,5,9,2,6"),
            fluidRow(
              column(6, numericInput(ns("ps_l"), "Left index l:", 2, min = 0)),
              column(6, numericInput(ns("ps_r"), "Right index r:", 5, min = 0))
            ),
            uiOutput(ns("ps_viz"))
          )
        )
      ),

      # ── Understand ─────────────────────────────────────────────────────────
      learn = tagList(
        insight_cards(
          when = c("Input is <b>sorted</b> or the answer space is monotonic → binary search.",
                   "Looking for a <b>pair / triplet</b> or comparing both ends → two pointers.",
                   "Asked about a <b>contiguous</b> subarray / substring → sliding window.",
                   "Many <b>range-sum</b> queries, or 'subarray sums to k' → prefix sums (+ hash map)."),
          pitfalls = c("Off-by-one in binary search: decide once whether <code>hi</code> is inclusive and stick to it.",
                       "<code>mid = (lo + hi) / 2</code> overflows in fixed-width languages; use <code>lo + (hi - lo) / 2</code>.",
                       "Sliding windows only work when shrinking the window moves the metric one way (e.g. all positives).",
                       "Strings are immutable in Python / Java: repeated concatenation is O(n²). Build a list and join."),
          tips = c("State the brute force first (usually O(n²)), then name the pattern that removes the inner loop.",
                   "Ask: sorted? duplicates? negatives? empty input? These decide which pattern is legal.",
                   "For binary search, say your loop invariant out loud: 'the answer is always in [lo, hi]'.")
        ),
        fluidRow(
          box(title = "Operation Costs", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Operation = c("Access by index", "Search (unsorted)", "Search (sorted)", "Append (dynamic array)", "Insert / delete in middle", "Slice of length k"),
              Time = c("O(1)", "O(n)", "O(log n)", "O(1) amortised", "O(n)", "O(k)"),
              stringsAsFactors = FALSE)),
            callout("<b>Why append is O(1) amortised:</b> the array doubles when full. Copies cost 1 + 2 + 4 + … + n &lt; 2n in total, so the average per append is constant. See the Big-O tab for the animation.", "tip")
          ),
          box(title = "Linear vs Binary Search — comparisons needed", status = "info", solidHeader = TRUE, width = 7,
            plotlyOutput(ns("cmp_plot"), height = "270px"),
            hint("At one million elements, binary search needs about 20 probes; a linear scan needs up to 1,000,000.")
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4,
                dsa_code(
'def binary_search(a, target):
    lo, hi = 0, len(a) - 1
    while lo <= hi:
        mid = lo + (hi - lo) // 2
        if a[mid] == target:
            return mid
        if a[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1          # lo = insert position', "Binary search — O(log n)"),
                dsa_code(
'def max_subarray(nums):          # Kadane
    cur = best = nums[0]
    for x in nums[1:]:
        cur = max(x, cur + x)    # extend or restart
        best = max(best, cur)
    return best', "Kadane — O(n)")
              ),
              column(4,
                dsa_code(
'def longest_unique(s):
    last = {}                # char -> last index
    left = best = 0
    for right, ch in enumerate(s):
        if ch in last and last[ch] >= left:
            left = last[ch] + 1     # shrink
        last[ch] = right
        best = max(best, right - left + 1)
    return best', "Variable sliding window — O(n)"),
                dsa_code(
'def two_sum_sorted(a, target):
    L, R = 0, len(a) - 1
    while L < R:
        s = a[L] + a[R]
        if s == target: return [L, R]
        if s < target:  L += 1
        else:           R -= 1
    return []', "Two pointers — O(n)")
              ),
              column(4,
                dsa_code(
'def subarray_sum(nums, k):
    count = prefix = 0
    seen = {0: 1}            # prefix sum -> times seen
    for x in nums:
        prefix += x
        count += seen.get(prefix - k, 0)
        seen[prefix] = seen.get(prefix, 0) + 1
    return count', "Prefix sum + hash map — O(n)"),
                dsa_code(
'def two_sum(nums, target):
    seen = {}                # value -> index
    for i, x in enumerate(nums):
        if target - x in seen:
            return [seen[target - x], i]
        seen[x] = i', "Two Sum (unsorted) — O(n)")
              )
            )
          )
        )
      ),

      practice = practice_tab(ns, "arrays",
        "Cormen, Leiserson, Rivest & Stein (2022). Introduction to Algorithms (4th ed.). MIT Press.",
        "Bentley, J. (1984). Programming Pearls: Algorithm Design Techniques. CACM 27(9) — origin of Kadane's algorithm write-up.",
        "Aziz, Lee & Prakash (2018). Elements of Programming Interviews in Python.")
    )
  )
}

arrays_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    # ── Binary search ────────────────────────────────────────────────────────
    bs_arr <- reactive({
      v <- sort(unique(parse_ints(input$bs_arr, 16)))
      validate(need(length(v) >= 1, "Enter at least one integer."))
      v
    })
    bs_steps <- reactive({
      arr <- bs_arr(); tgt <- input$bs_target
      validate(need(!is.null(tgt) && !is.na(tgt), "Enter a target value."))
      n <- length(arr); lo <- 1; hi <- n; found <- FALSE
      steps <- list(list(lo = lo, hi = hi, mid = NA, found = FALSE, line = 1,
        msg = sprintf("Search space is the whole array: indices 0 to %d (%d elements).", n - 1, n)))
      while (lo <= hi) {
        mid <- (lo + hi) %/% 2
        if (arr[mid] == tgt) {
          found <- TRUE
          steps[[length(steps) + 1]] <- list(lo = lo, hi = hi, mid = mid, found = TRUE, line = 4,
            msg = sprintf("<b>a[%d] = %d equals the target.</b> Found after %d probe(s).", mid - 1, arr[mid], length(steps)))
          break
        } else if (arr[mid] < tgt) {
          steps[[length(steps) + 1]] <- list(lo = lo, hi = hi, mid = mid, found = FALSE, line = 5,
            msg = sprintf("a[%d] = %d is <b>less</b> than %s → everything at or left of mid is too small. Move <code>lo</code> to %d.", mid - 1, arr[mid], tgt, mid))
          lo <- mid + 1
        } else {
          steps[[length(steps) + 1]] <- list(lo = lo, hi = hi, mid = mid, found = FALSE, line = 6,
            msg = sprintf("a[%d] = %d is <b>greater</b> than %s → everything at or right of mid is too big. Move <code>hi</code> to %d.", mid - 1, arr[mid], tgt, mid - 2))
          hi <- mid - 1
        }
      }
      if (!found) steps[[length(steps) + 1]] <- list(lo = lo, hi = hi, mid = NA, found = FALSE, line = 7,
        msg = sprintf("<code>lo</code> passed <code>hi</code> → the search space is empty. <b>%s is not present</b>; it would be inserted at index %d.", tgt, lo - 1))
      steps
    })
    bs <- stepper_server(input, output, session, "bs", bs_steps)

    output$bs_viz <- renderUI({
      arr <- bs_arr(); s <- bs$cur(); n <- length(arr)
      cls <- ifelse(seq_len(n) < s$lo | seq_len(n) > s$hi, "dim", "")
      if (!is.na(s$mid)) cls[s$mid] <- if (s$found) "found" else "active"
      tagList(vrow(arr, cls, ptr = list(lo = s$lo, mid = s$mid, hi = s$hi)), explain(s$msg))
    })
    output$bs_code <- renderUI({
      pseudo(c("lo, hi = 0, len(a) - 1", "while lo <= hi:", "    mid = (lo + hi) // 2",
               "    if a[mid] == target: return mid", "    elif a[mid] < target: lo = mid + 1",
               "    else: hi = mid - 1", "return -1"),
             active = c(bs$cur()$line, if (bs$cur()$line %in% 4:6) 3))
    })
    output$bs_kpi <- renderUI({
      n <- length(bs_arr()); s <- bs$cur()
      remaining <- max(0, s$hi - s$lo + 1)
      kpi_row(kpi(remaining, "candidates left", COL$pri),
              kpi(ceiling(log2(n + 1)), "max probes (log₂n)", COL$acc),
              kpi(n, "linear worst case", COL$err))
    })

    # ── Two pointers ─────────────────────────────────────────────────────────
    tp_arr <- reactive({
      v <- sort(parse_ints(input$tp_arr, 16))
      validate(need(length(v) >= 2, "Enter at least two integers."))
      v
    })
    tp_steps <- reactive({
      a <- tp_arr(); t <- input$tp_target
      validate(need(!is.null(t) && !is.na(t), "Enter a target sum."))
      L <- 1; R <- length(a); steps <- list(); found <- FALSE
      while (L < R) {
        s <- a[L] + a[R]
        if (s == t) {
          found <- TRUE
          steps[[length(steps) + 1]] <- list(L = L, R = R, found = TRUE,
            msg = sprintf("%d + %d = <b>%d</b> — target hit at indices (%d, %d).", a[L], a[R], s, L - 1, R - 1))
          break
        } else if (s < t) {
          steps[[length(steps) + 1]] <- list(L = L, R = R, found = FALSE,
            msg = sprintf("%d + %d = %d &lt; %s → need a bigger sum, move <b>L</b> right.", a[L], a[R], s, t))
          L <- L + 1
        } else {
          steps[[length(steps) + 1]] <- list(L = L, R = R, found = FALSE,
            msg = sprintf("%d + %d = %d &gt; %s → need a smaller sum, move <b>R</b> left.", a[L], a[R], s, t))
          R <- R - 1
        }
      }
      if (!found) steps[[length(steps) + 1]] <- list(L = L, R = R, found = FALSE, none = TRUE,
        msg = "Pointers met — <b>no pair</b> adds up to the target.")
      steps
    })
    tp <- stepper_server(input, output, session, "tp", tp_steps)
    output$tp_viz <- renderUI({
      a <- tp_arr(); s <- tp$cur(); n <- length(a)
      cls <- ifelse(seq_len(n) < s$L | seq_len(n) > s$R, "dim", "")
      if (is.null(s$none)) cls[c(s$L, s$R)] <- if (s$found) "found" else "active"
      tagList(vrow(a, cls, ptr = list(L = s$L, R = s$R)), explain(s$msg))
    })

    # ── Sliding window ───────────────────────────────────────────────────────
    sw_arr <- reactive({
      v <- parse_ints(input$sw_arr, 20)
      validate(need(length(v) >= 2, "Enter at least two integers."))
      v
    })
    sw_k <- reactive({
      k <- input$sw_k
      validate(need(!is.null(k) && !is.na(k) && k >= 1, "k must be at least 1."))
      min(as.integer(k), length(sw_arr()))
    })
    sw_steps <- reactive({
      a <- sw_arr(); k <- sw_k(); n <- length(a)
      cur <- sum(a[1:k]); best <- cur; best_i <- 1
      steps <- list(list(i = 1, cur = cur, best = best, best_i = 1,
        msg = sprintf("Build the first window: sum of indices 0..%d = <b>%d</b>.", k - 1, cur)))
      for (i in sq(2, n - k + 1)) {
        cur <- cur - a[i - 1] + a[i + k - 1]
        improved <- cur > best
        if (improved) { best <- cur; best_i <- i }
        steps[[length(steps) + 1]] <- list(i = i, cur = cur, best = best, best_i = best_i,
          msg = sprintf("Slide right: drop %d, add %d → window sum <b>%d</b>%s. Two operations, no re-summing.",
                        a[i - 1], a[i + k - 1], cur, if (improved) " — <b>new best</b>" else ""))
      }
      steps
    })
    sw <- stepper_server(input, output, session, "sw", sw_steps)
    output$sw_plot <- renderPlotly({
      a <- sw_arr(); k <- sw_k(); s <- sw$cur()
      cols <- rep(COL$idle, length(a))
      cols[s$best_i:(s$best_i + k - 1)] <- COL$warn
      cols[s$i:(s$i + k - 1)] <- COL$acc
      bar_state(a, cols, height = 230)
    })
    output$sw_explain <- renderUI({
      s <- sw$cur()
      tagList(kpi_row(kpi(s$cur, "window sum", COL$acc), kpi(s$best, "best so far", COL$warn),
                      kpi(paste0("O(n)"), "vs O(n·k) brute force", COL$ok)),
              explain(s$msg))
    })

    # ── Kadane ───────────────────────────────────────────────────────────────
    output$kd_plot <- renderPlotly({
      a <- parse_ints(input$kd_arr, 24)
      validate(need(length(a) >= 1, "Enter at least one integer."))
      n <- length(a); cur <- numeric(n); best <- numeric(n); start <- 1; bs <- 1; be <- 1
      cur[1] <- a[1]; best[1] <- a[1]
      for (i in sq(2, n)) {
        if (cur[i - 1] + a[i] < a[i]) { cur[i] <- a[i]; start <- i } else cur[i] <- cur[i - 1] + a[i]
        if (cur[i] > best[i - 1]) { best[i] <- cur[i]; bs <- start; be <- i } else best[i] <- best[i - 1]
      }
      cols <- rep(COL$idle, n); cols[bs:be] <- COL$ok
      plot_ly(x = seq_len(n) - 1, height = 270) %>%
        add_bars(y = a, marker = list(color = cols), name = "value", hoverinfo = "x+y") %>%
        add_trace(y = cur, type = "scatter", mode = "lines+markers", name = "cur (best ending here)",
                  line = list(color = COL$pri, width = 2.5), marker = list(color = COL$pri, size = 6)) %>%
        add_trace(y = best, type = "scatter", mode = "lines", name = "best so far",
                  line = list(color = COL$warn, width = 2.5, dash = "dash")) %>%
        dsa_layout(xt = "index", legend = TRUE) %>% layout(xaxis = list(dtick = 1))
    })
    output$kd_explain <- renderUI({
      a <- parse_ints(input$kd_arr, 24); req(length(a) >= 1)
      n <- length(a); cur <- a[1]; best <- a[1]; start <- 1; bs <- 1; be <- 1
      for (i in sq(2, n)) {
        if (cur + a[i] < a[i]) { cur <- a[i]; start <- i } else cur <- cur + a[i]
        if (cur > best) { best <- cur; bs <- start; be <- i }
      }
      explain(sprintf("Maximum subarray sum = <b>%d</b>, from index %d to %d (green bars): [%s]. The purple line restarts whenever carrying the previous sum would hurt — that single decision, <code>cur = max(x, cur + x)</code>, is the whole algorithm.",
                      best, bs - 1, be - 1, paste(a[bs:be], collapse = ", ")))
    })

    # ── Prefix sums ──────────────────────────────────────────────────────────
    output$ps_viz <- renderUI({
      a <- parse_ints(input$ps_arr, 14)
      validate(need(length(a) >= 1, "Enter at least one integer."))
      n <- length(a)
      l <- max(0, min(n - 1, as.integer(input$ps_l %||% 0)))
      r <- max(0, min(n - 1, as.integer(input$ps_r %||% 0)))
      validate(need(!is.na(l) && !is.na(r), "Enter l and r."))
      if (l > r) { t <- l; l <- r; r <- t }
      P <- c(0, cumsum(a))
      cls_a <- ifelse(seq_len(n) - 1 >= l & seq_len(n) - 1 <= r, "window", "")
      cls_p <- rep("", n + 1); cls_p[r + 2] <- "active"; cls_p[l + 1] <- "pivot"
      tagList(
        tags$div(class = "code-title", "a — original values"),
        vrow(a, cls_a),
        tags$div(class = "code-title", style = "margin-top:10px;", "P — prefix sums (P[i] = sum of first i values)"),
        vrow(P, cls_p, ptr = setNames(list(r + 2, l + 1), c("P[r+1]", "P[l]"))),
        explain(sprintf("sum(a[%d..%d]) = P[%d] − P[%d] = %d − %d = <b>%d</b>. One subtraction, however long the range. Building P costs O(n) once.",
                        l, r, r + 1, l, P[r + 2], P[l + 1], P[r + 2] - P[l + 1]))
      )
    })

    # ── Learn: comparison chart ──────────────────────────────────────────────
    output$cmp_plot <- renderPlotly({
      n <- 2^(0:20)
      plot_ly(x = n, height = 270) %>%
        add_trace(y = n, type = "scatter", mode = "lines", name = "Linear search — n",
                  line = list(color = COL$err, width = 3)) %>%
        add_trace(y = log2(n) + 1, type = "scatter", mode = "lines", name = "Binary search — log₂n + 1",
                  line = list(color = COL$ok, width = 3)) %>%
        dsa_layout(xt = "array size n (log scale)", yt = "worst-case comparisons (log scale)", legend = TRUE) %>%
        layout(xaxis = list(type = "log"), yaxis = list(type = "log"))
    })

    quiz_server(input, output, session, topic = "arrays", progress = progress, questions = list(
      list(q = "You need the longest substring with at most 2 distinct characters. Which pattern fits?",
           opts = c("Binary search", "Variable-size sliding window", "Prefix sums", "Sort + two pointers"), ans = 2,
           why = "It asks about a contiguous range with a constraint that only gets worse as the window grows — expand right, shrink left."),
      list(q = "Binary search on 1,000,000 sorted elements needs at most about how many comparisons?",
           opts = c("10", "20", "1,000", "500,000"), ans = 2,
           why = "log₂(1,000,000) ≈ 19.9. Every probe halves the remaining candidates."),
      list(q = "Why does the sorted two-pointer pair-sum scan never miss a valid pair?",
           opts = c("It checks every pair eventually", "Each move discards an element that provably cannot be in any remaining solution", "Sorting removes duplicates", "It uses a hash set internally"), ans = 2,
           why = "If a[L]+a[R] is too small, a[L] paired with anything ≤ a[R] is also too small, so L can be dropped safely. Symmetric for R."),
      list(q = "Kadane's update is <code>cur = max(x, cur + x)</code>. When does it choose <code>x</code> alone?",
           opts = c("When x is negative", "When the running sum before x is negative", "When x is the largest element so far", "Never — it always extends"), ans = 2,
           why = "A negative running sum can only drag the next element down, so it is better to restart the subarray at x."),
      list(q = "Counting subarrays that sum to k with negatives present: why does a sliding window fail?",
           opts = c("Windows are too slow", "Expanding the window no longer changes the sum monotonically", "Negative numbers cannot be indexed", "It needs sorted input"), ans = 2,
           why = "With negatives, growing the window can decrease the sum, so you cannot decide when to shrink. Use prefix sums + a hash map instead.")
    ))
  })
}
