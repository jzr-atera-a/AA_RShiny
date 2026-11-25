# modules/mod_heaps.R — Heaps & Priority Queues

heaps_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🏔️", "Heaps & Priority Queues",
      "A complete binary tree stored in a plain array, where every parent beats its children. You get the best element in O(1) and insert or remove in O(log n) — the engine behind top-K, scheduling and Dijkstra.",
      c("Min-Heap", "Max-Heap", "Sift Up / Down", "Heapify", "Top-K", "Two Heaps")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Heap Operations — tree and array are the same thing", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(5, textInput(ns("vals"), "Values:", "9,4,7,1,8,2,6,3,5")),
              column(3, radioButtons(ns("type"), "Type:", c("Min-heap" = "min", "Max-heap" = "max"))),
              column(4, selectInput(ns("op"), "Operation:", c("Heapify (bottom-up build)" = "heapify", "Insert one by one (sift up)" = "insert", "Extract all (heap sort)" = "extract")))
            ),
            stepper_ui(ns, "hp"),
            plotlyOutput(ns("hp_plot"), height = "290px"),
            uiOutput(ns("hp_viz")),
            legend_row(c("being compared / swapped" = COL$pri, "in the heap" = COL$soft, "root" = COL$ok))
          ),
          box(title = "The index arithmetic", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("hp_kpi")),
            callout("With 0-based indices, for the node at <code>i</code>:<br>• parent = <code>(i − 1) // 2</code><br>• left child = <code>2i + 1</code><br>• right child = <code>2i + 2</code><br>No pointers needed — the tree shape is implied by position. That is why a heap is so compact and cache-friendly.", "info"),
            uiOutput(ns("hp_note"))
          )
        ),
        fluidRow(
          box(title = "Top-K Largest — keep a min-heap of size k", status = "primary", solidHeader = TRUE, width = 6,
            fluidRow(
              column(8, textInput(ns("tk_arr"), "Stream:", "5,12,3,18,7,25,9,14,21,2")),
              column(4, numericInput(ns("tk_k"), "k:", 3, min = 1))
            ),
            stepper_ui(ns, "tk"),
            uiOutput(ns("tk_viz")),
            hint("Counter-intuitive but key: for the k <b>largest</b> you keep a <b>min</b>-heap. Its root is the weakest of the current top k — the one to evict when something better arrives. O(n log k) time, O(k) space.")
          ),
          box(title = "Running Median — two heaps facing each other", status = "primary", solidHeader = TRUE, width = 6,
            textInput(ns("md_arr"), "Stream:", "5,15,1,3,8,7,9,10,20,12"),
            stepper_ui(ns, "md"),
            uiOutput(ns("md_viz")),
            hint("A max-heap holds the smaller half, a min-heap the larger half. Keep their sizes within one of each other and the median is always at the two roots — O(log n) per insert, O(1) per query.")
          )
        ),
        fluidRow(
          box(title = "Building a heap: heapify beats n inserts", status = "info", solidHeader = TRUE, width = 12,
            fluidRow(
              column(7, plotlyOutput(ns("build_plot"), height = "280px")),
              column(5,
                callout("<b>Why heapify is O(n):</b> sift-down work is proportional to a node's height. Half the nodes are leaves (height 0, no work), a quarter have height 1, an eighth height 2… The sum n·(0/2 + 1/4 + 2/8 + 3/16 + …) converges to about <b>n</b>.", "tip"),
                callout("Inserting one at a time does the opposite: the many leaves each sift <i>up</i> through the full height, giving O(n log n) in the worst case.", "warn"))
            )
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("Repeatedly need the <b>smallest or largest</b> of a changing collection.",
                   "'Top k', 'k-th largest', 'k closest' → heap of size k.",
                   "Merge k sorted sequences → heap holding one head per sequence.",
                   "Streaming median or 'balance two halves' → two heaps.",
                   "Always pick the cheapest / earliest next (Dijkstra, Prim, scheduling)."),
          pitfalls = c("Expecting a heap to be sorted — only the root is guaranteed; siblings are unordered.",
                       "Searching a heap for an arbitrary value is O(n).",
                       "Python's <code>heapq</code> is min-only: push <code>-x</code> for a max-heap, and remember to negate on the way out.",
                       "Pushing tuples whose first elements tie and whose second elements cannot be compared — add a counter as tiebreaker."),
          tips = c("If asked for k-th largest, mention all three: sort O(n log n), heap O(n log k), quickselect O(n) average.",
                   "Say 'heap of size k' out loud — interviewers listen for the space bound O(k).",
                   "<code>heapq.heapify(list)</code> is O(n); pushing n items is O(n log n). Prefer heapify when you have all the data.")
        ),
        fluidRow(
          box(title = "Operation Costs", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Operation = c("Peek best", "Insert (sift up)", "Extract best (sift down)", "Build from n items", "Search arbitrary value", "Heap sort"),
              Time = c("O(1)", "O(log n)", "O(log n)", "O(n)", "O(n)", "O(n log n), in place"),
              stringsAsFactors = FALSE))
          ),
          box(title = "Python heapq cheat-sheet", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Call = c("heapq.heapify(a)", "heapq.heappush(h, x)", "heapq.heappop(h)", "h[0]", "heapq.heappushpop(h, x)", "heapq.nlargest(k, a)", "heappush(h, (-priority, i, item))"),
              Does = c("Turn list into a min-heap in place, O(n)", "Insert, O(log n)", "Remove and return the smallest", "Peek at the smallest", "Push then pop in one sift — ideal for size-k heaps", "k largest, O(n log k)", "Max-heap with a tiebreak counter i"),
              stringsAsFactors = FALSE))
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4, dsa_code(
'def findKthLargest(nums, k):
    heap = nums[:k]
    heapq.heapify(heap)              # min-heap, size k
    for x in nums[k:]:
        if x > heap[0]:
            heapq.heapreplace(heap, x)
    return heap[0]', "K-th largest — O(n log k)")),
              column(4, dsa_code(
'class MedianFinder:
    def __init__(self):
        self.lo = []      # max-heap (negated): small half
        self.hi = []      # min-heap: large half
    def addNum(self, x):
        heapq.heappush(self.lo, -x)
        heapq.heappush(self.hi, -heapq.heappop(self.lo))
        if len(self.hi) > len(self.lo):
            heapq.heappush(self.lo, -heapq.heappop(self.hi))
    def findMedian(self):
        if len(self.lo) > len(self.hi):
            return -self.lo[0]
        return (-self.lo[0] + self.hi[0]) / 2', "Two heaps — running median")),
              column(4, dsa_code(
'def mergeKLists(lists):
    heap = []
    for i, node in enumerate(lists):
        if node:
            heapq.heappush(heap, (node.val, i, node))
    dummy = tail = ListNode()
    while heap:
        _, i, node = heapq.heappop(heap)
        tail.next = tail = node
        if node.next:
            heapq.heappush(heap, (node.next.val, i, node.next))
    return dummy.next', "Merge k sorted lists — O(N log k)"))
            )
          )
        )
      ),

      practice = practice_tab(ns, "heaps",
        "Williams, J. W. J. (1964). Algorithm 232: Heapsort. CACM 7(6).",
        "Floyd, R. W. (1964). Algorithm 245: Treesort 3. CACM 7(12) — the O(n) bottom-up heap construction.",
        "Cormen, Leiserson, Rivest & Stein (2022). Introduction to Algorithms (4th ed.) — ch. 6.")
    )
  )
}

heaps_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    vals <- reactive({
      v <- parse_ints(input$vals, 15)
      validate(need(length(v) >= 1, "Enter at least one integer."))
      v
    })

    hp_steps <- reactive({
      v <- vals(); type <- input$type; op <- input$op
      better <- function(a, b) if (type == "min") a < b else a > b
      word <- if (type == "min") "smaller" else "larger"
      steps <- list(); swaps <- 0
      rec <- function(h, hl, msg, out = integer(0)) {
        steps[[length(steps) + 1]] <<- list(h = h, hl = hl, out = out, msg = msg, swaps = swaps)
      }
      sift_down <- function(h, i, out = integer(0)) {
        n <- length(h)
        repeat {
          l <- 2 * i; r <- l + 1; b <- i
          if (l <= n && better(h[l], h[b])) b <- l
          if (r <= n && better(h[r], h[b])) b <- r
          if (b == i) break
          tmp <- h[i]; h[i] <- h[b]; h[b] <- tmp; swaps <<- swaps + 1
          rec(h, c(i, b), sprintf("Sift down: %d had a %s child %d → <b>swap</b>.", h[b], word, h[i]), out)
          i <- b
        }
        h
      }
      sift_up <- function(h, i) {
        while (i > 1 && better(h[i], h[i %/% 2])) {
          p <- i %/% 2; tmp <- h[i]; h[i] <- h[p]; h[p] <- tmp; swaps <<- swaps + 1
          rec(h, c(p, i), sprintf("Sift up: %d is %s than its parent %d → <b>swap</b>.", h[p], word, h[i]))
          i <- p
        }
        h
      }
      heapify <- function(h, record = TRUE) {
        n <- length(h)
        for (i in rev(sq(1, n %/% 2))) {
          if (record) rec(h, i, sprintf("Fix the subtree rooted at index %d (value %d). Its children are already valid heaps.", i - 1, h[i]))
          before <- length(steps)
          h <- sift_down(h, i)
          if (!record) steps <<- steps[seq_len(before)]
        }
        h
      }
      if (op == "heapify") {
        h <- v
        rec(h, integer(0), "Start with the values in arbitrary order, laid out level by level. Leaves are trivially valid heaps, so begin at the <b>last parent</b> and work back to the root.")
        h <- heapify(h)
        rec(h, 1, sprintf("<b>Heap built with %d swap(s).</b> The root %d is the %s; every parent is %s than its children.", swaps, h[1], if (type == "min") "minimum" else "maximum", word))
      } else if (op == "insert") {
        h <- integer(0)
        rec(h, integer(0), "Start empty. Each new value is appended at the next free leaf, then sifted up while it beats its parent.")
        for (x in v) {
          h <- c(h, x)
          rec(h, length(h), sprintf("Append <b>%d</b> at index %d (the next free leaf).", x, length(h) - 1))
          h <- sift_up(h, length(h))
        }
        rec(h, 1, sprintf("<b>All %d values inserted with %d swap(s).</b>", length(v), swaps))
      } else {
        h <- heapify(v, record = FALSE); swaps <- 0; out <- integer(0)
        rec(h, 1, sprintf("Start from a valid heap. Extracting repeatedly yields the values in %s order — that is heap sort.", if (type == "min") "ascending" else "descending"), out)
        while (length(h) > 0) {
          n <- length(h); root <- h[1]; out <- c(out, root)
          if (n == 1) { h <- integer(0); rec(h, integer(0), sprintf("Remove the last value <b>%d</b>.", root), out); break }
          h[1] <- h[n]; h <- h[-n]
          rec(h, 1, sprintf("Remove root <b>%d</b>. Move the last leaf (%d) to the root, then sift it down.", root, h[1]), out)
          h <- sift_down(h, 1, out)
        }
        steps[[length(steps)]]$msg <- sprintf("<b>Heap empty.</b> Output is fully sorted after %d swap(s): n extractions × O(log n) each = O(n log n).", swaps)
      }
      steps
    })
    hp <- stepper_server(input, output, session, "hp", hp_steps)

    output$hp_plot <- renderPlotly({
      s <- hp$cur(); L <- heap_layout(s$h)
      validate(need(!is.null(L), "The heap is empty."))
      state <- rep("visited", nrow(L$nodes)); state[1] <- "done"
      state[s$hl] <- "active"
      nodes <- state_style(L$nodes, state)
      nodes$sub <- paste0("[", seq_len(nrow(nodes)) - 1, "]")
      net_plot(nodes, L$edges, size = 36, height = 290)
    })
    output$hp_viz <- renderUI({
      s <- hp$cur()
      cls <- rep("visited", length(s$h)); if (length(s$h)) cls[1] <- "found"; cls[s$hl] <- "active"
      tagList(
        tags$div(class = "code-title", "Underlying array"),
        vrow(s$h, cls),
        if (input$op == "extract") lane("extracted", s$out, "found", "nothing yet"),
        explain(s$msg))
    })
    output$hp_kpi <- renderUI({
      s <- hp$cur(); n <- length(vals())
      kpi_row(kpi(s$swaps, "swaps so far", COL$pri), kpi(length(s$h), "heap size", COL$acc), kpi(max(1, ceiling(log2(n + 1))), "height (levels)", COL$ok))
    })
    output$hp_note <- renderUI({
      callout(switch(input$op,
        heapify = "<b>Heapify</b> works bottom-up: by the time a node is fixed, both subtrees below it are already heaps, so one sift-down is enough.",
        insert  = "<b>Insert</b> keeps the tree complete by adding at the end of the array, then repairs the single path to the root — at most log₂n swaps.",
        extract = "<b>Extract</b> cannot just delete the root (that would leave a hole). Swapping in the last leaf keeps the shape; sift-down repairs the order."), "tip")
    })

    # ── Top-K ────────────────────────────────────────────────────────────────
    tk_arr <- reactive({
      v <- parse_ints(input$tk_arr, 16)
      validate(need(length(v) >= 1, "Enter at least one integer."))
      v
    })
    tk_steps <- reactive({
      a <- tk_arr(); k <- input$tk_k
      validate(need(!is.null(k) && !is.na(k) && k >= 1, "k must be at least 1."))
      k <- min(as.integer(k), length(a)); heap <- integer(0)
      steps <- list(list(i = 0, heap = heap, msg = sprintf("Keep at most <b>%d</b> values in a min-heap. Its root is the smallest of the best %d seen so far.", k, k)))
      for (i in seq_along(a)) {
        x <- a[i]
        if (length(heap) < k) { heap <- sort(c(heap, x)); msg <- sprintf("Heap has room → push <b>%d</b>.", x) }
        else if (x > heap[1]) { ev <- heap[1]; heap <- sort(c(heap[-1], x)); msg <- sprintf("<b>%d</b> beats the root %d → evict %d, push %d.", x, ev, ev, x) }
        else msg <- sprintf("%d is not larger than the root %d → cannot be in the top %d, <b>skip</b>.", x, heap[1], k)
        steps[[length(steps) + 1]] <- list(i = i, heap = heap, msg = msg)
      }
      steps[[length(steps)]]$msg <- paste0(steps[[length(steps)]]$msg, sprintf(" <b>Result: the %d largest are [%s]</b>; the k-th largest is the root, %d.", k, paste(rev(heap), collapse = ", "), heap[1]))
      steps
    })
    tk <- stepper_server(input, output, session, "tk", tk_steps)
    output$tk_viz <- renderUI({
      a <- tk_arr(); s <- tk$cur()
      cls <- ifelse(seq_along(a) < s$i, "dim", ""); if (s$i >= 1) cls[s$i] <- "active"
      tagList(vrow(a, cls, idx = FALSE), lane("min-heap (root →)", s$heap, "frontier", "empty"), explain(s$msg))
    })

    # ── Running median ───────────────────────────────────────────────────────
    md_arr <- reactive({
      v <- parse_ints(input$md_arr, 14)
      validate(need(length(v) >= 1, "Enter at least one integer."))
      v
    })
    md_steps <- reactive({
      a <- md_arr(); lo <- integer(0); hi <- integer(0)
      steps <- list(list(i = 0, lo = lo, hi = hi, med = NA, msg = "Two heaps: <b>low</b> (max-heap of the smaller half) and <b>high</b> (min-heap of the larger half)."))
      for (i in seq_along(a)) {
        x <- a[i]
        lo <- sort(c(lo, x), decreasing = TRUE)           # push to low
        mv <- lo[1]; lo <- lo[-1]; hi <- sort(c(hi, mv))  # move low's max to high
        note <- sprintf("Push %d into low, then move low's largest (%d) to high so every low ≤ every high.", x, mv)
        if (length(hi) > length(lo)) { mv2 <- hi[1]; hi <- hi[-1]; lo <- sort(c(lo, mv2), decreasing = TRUE); note <- paste(note, sprintf("High is now bigger → move its smallest (%d) back.", mv2)) }
        med <- if (length(lo) > length(hi)) lo[1] else (lo[1] + hi[1]) / 2
        steps[[length(steps) + 1]] <- list(i = i, lo = lo, hi = hi, med = med,
          msg = sprintf("%s Median = <b>%s</b> (%s).", note, med, if (length(lo) > length(hi)) "root of low" else "average of the two roots"))
      }
      steps
    })
    md <- stepper_server(input, output, session, "md", md_steps)
    output$md_viz <- renderUI({
      a <- md_arr(); s <- md$cur()
      cls <- ifelse(seq_along(a) < s$i, "dim", ""); if (s$i >= 1) cls[s$i] <- "active"
      tagList(vrow(a, cls, idx = FALSE),
        fluidRow(
          column(5, lane("low (max →)", s$lo, "visited", "empty")),
          column(2, tags$div(style = "margin-top:8px;", kpi(if (is.na(s$med)) "—" else s$med, "median", COL$ok))),
          column(5, lane("high (min →)", s$hi, "frontier", "empty"))),
        explain(s$msg))
    })

    # ── Build cost chart ─────────────────────────────────────────────────────
    output$build_plot <- renderPlotly({
      n <- 2^(3:16)
      plot_ly(x = n, height = 280) %>%
        add_trace(y = n * log2(n), type = "scatter", mode = "lines+markers", name = "n inserts — worst case n·log₂n", line = list(color = COL$err, width = 3), marker = list(color = COL$err)) %>%
        add_trace(y = 2 * n, type = "scatter", mode = "lines+markers", name = "Heapify — at most 2n comparisons", line = list(color = COL$ok, width = 3), marker = list(color = COL$ok)) %>%
        dsa_layout(xt = "number of elements n", yt = "operations (upper bound)", legend = TRUE) %>%
        layout(xaxis = list(type = "log"), yaxis = list(type = "log"))
    })

    quiz_server(input, output, session, topic = "heaps", progress = progress, questions = list(
      list(q = "To find the k largest items in a stream, which heap do you keep?",
           opts = c("A max-heap of everything", "A min-heap of size k", "A max-heap of size k", "Two heaps"), ans = 2,
           why = "The min-heap's root is the weakest of the current best k — the only one a newcomer must beat. Memory stays O(k)."),
      list(q = "Building a heap from n unsorted items with bottom-up heapify costs…",
           opts = c("O(log n)", "O(n)", "O(n log n)", "O(n²)"), ans = 2,
           why = "Most nodes are near the bottom and sift down only a level or two; the total converges to a constant times n."),
      list(q = "In a 0-indexed array heap, the children of index 4 are at…",
           opts = c("5 and 6", "8 and 9", "9 and 10", "7 and 8"), ans = 3,
           why = "left = 2i + 1 = 9, right = 2i + 2 = 10."),
      list(q = "Which statement about a min-heap is FALSE?",
           opts = c("The root is the minimum", "Every level except possibly the last is full", "An inorder walk gives sorted output", "Insert is O(log n)"), ans = 3,
           why = "A heap only orders parent vs child. Siblings and cousins are unordered, so no traversal yields sorted output — that is a BST property."),
      list(q = "How do you get a max-heap from Python's <code>heapq</code>?",
           opts = c("heapq.maxheap()", "Push the negated values", "Pass reverse=True", "Sort first"), ans = 2,
           why = "heapq only implements a min-heap; storing −x makes the largest x come out first. Negate again when you pop.")
    ))
  })
}
