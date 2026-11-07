# modules/mod_heaps.R — Heaps & Priority Queues

heaps_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🏔️", "Heaps & Priority Queues",
      "Complete binary trees with the heap property. Essential for top-K, scheduling, and Dijkstra's algorithm.",
      c("Min-Heap", "Max-Heap", "Heapify", "Top-K", "Priority Queue")),

    fluidRow(
      box(title = "Heap Simulator", status = "primary", solidHeader = TRUE, width = 4,
        tags$p("Build a min-heap by inserting values one at a time. See the heap array representation.",
               style = "font-size:12px; color:#555;"),
        radioButtons(ns("heap_type"), "Heap type:", choices = c("Min-Heap"="min","Max-Heap"="max"), inline=TRUE),
        textInput(ns("heap_vals"), "Values (comma-separated):", value = "5,3,8,1,4,9,2"),
        actionButton(ns("btn_build"), "Build Heap", class = "btn btn-dsa"),
        tags$br(), tags$br(),
        fluidRow(
          column(6, actionButton(ns("btn_pop_heap"), "Extract Root", class = "btn btn-dsa-outline btn-sm", width="100%")),
          column(6, actionButton(ns("btn_clear_heap"), "Clear", class = "btn btn-dsa-outline btn-sm", width="100%"))
        )
      ),
      box(title = "Heap Visualisation", status = "info", solidHeader = TRUE, width = 8,
        uiOutput(ns("viz_heap")),
        uiOutput(ns("heap_explain"))
      )
    ),

    fluidRow(
      box(title = "Top-K Elements", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Find the K largest elements efficiently using a min-heap of size K.",
               style = "font-size:12px; color:#555;"),
        textInput(ns("topk_vals"), "Array:", value = "3,2,1,5,6,4,7,9,8"),
        numericInput(ns("topk_k"), "K:", value = 3, min = 1),
        actionButton(ns("btn_topk"), "Find Top-K", class = "btn btn-dsa"),
        tags$br(), tags$br(),
        uiOutput(ns("topk_result"))
      ),
      box(title = "Complexity Reference", status = "info", solidHeader = TRUE, width = 3,
        cplx_table(data.frame(
          Operation   = c("Build heap", "Insert", "Extract min/max", "Peek", "Heapify"),
          Time        = c("O(n)", "O(log n)", "O(log n)", "O(1)", "O(log n)"),
          stringsAsFactors = FALSE
        )),
        callout("Heapify-down is O(n) to build — better than inserting n items one by one which costs O(n log n).", "tip")
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 4,
        uiOutput(ns("quiz_ui"))
      )
    ),

    fluidRow(
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 6,
        tags$p(tags$strong("Top K Frequent — O(n log k)"), style = "font-size:12px;"),
        dsa_code(
'import heapq
from collections import Counter
def topKFrequent(nums, k):
    count = Counter(nums)
    # min-heap of size k: (freq, num)
    heap = []
    for num, freq in count.items():
        heapq.heappush(heap, (freq, num))
        if len(heap) > k:
            heapq.heappop(heap)
    return [num for freq, num in heap]'),
        tags$p(tags$strong("Median from Data Stream — O(log n) per insert"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'import heapq
class MedianFinder:
    def __init__(self):
        self.lo = []   # max-heap (negated)
        self.hi = []   # min-heap
    def addNum(self, num):
        heapq.heappush(self.lo, -num)
        heapq.heappush(self.hi, -heapq.heappop(self.lo))
        if len(self.hi) > len(self.lo):
            heapq.heappush(self.lo, -heapq.heappop(self.hi))
    def findMedian(self):
        if len(self.lo) > len(self.hi):
            return -self.lo[0]
        return (-self.lo[0] + self.hi[0]) / 2')
      ),
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 6,
        fluidRow(
          column(6,
            prob_row(703, "Kth Largest in Stream",        "Easy",   "https://leetcode.com/problems/kth-largest-element-in-a-stream/"),
            prob_row(347, "Top K Frequent Elements",      "Medium", "https://leetcode.com/problems/top-k-frequent-elements/"),
            prob_row(215, "Kth Largest in Array",         "Medium", "https://leetcode.com/problems/kth-largest-element-in-an-array/"),
            prob_row(378, "Kth Smallest in Matrix",       "Medium", "https://leetcode.com/problems/kth-smallest-element-in-a-sorted-matrix/")
          ),
          column(6,
            prob_row(295, "Find Median from Stream",      "Hard",   "https://leetcode.com/problems/find-median-from-data-stream/"),
            prob_row(23,  "Merge k Sorted Lists",         "Hard",   "https://leetcode.com/problems/merge-k-sorted-lists/"),
            prob_row(621, "Task Scheduler",               "Medium", "https://leetcode.com/problems/task-scheduler/"),
            prob_row(743, "Network Delay (Dijkstra)",     "Medium", "https://leetcode.com/problems/network-delay-time/")
          )
        )
      )
    ),

    ref_block(
      "Cormen et al. (2009). Introduction to Algorithms (3rd ed.). MIT Press.",
      "Williams, J. W. J. (1964). Algorithm 232 — Heapsort. Communications of the ACM.",
      "Skiena, S. S. (2020). The Algorithm Design Manual (3rd ed.). Springer."
    )
  )
}

heaps_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    heap_state <- reactiveValues(h = integer(0), type = "min", msg = "Heap is empty.")

    heap_parent  <- function(i) floor(i/2)
    heap_left    <- function(i) 2*i
    heap_right   <- function(i) 2*i+1
    cmp          <- function(a, b, type) if (type=="min") a < b else a > b

    sift_up <- function(h, i, type) {
      while (i > 1 && cmp(h[i], h[heap_parent(i)], type)) {
        tmp <- h[i]; h[i] <- h[heap_parent(i)]; h[heap_parent(i)] <- tmp
        i <- heap_parent(i)
      }
      h
    }

    sift_down <- function(h, i, n, type) {
      while (TRUE) {
        best <- i; l <- heap_left(i); r <- heap_right(i)
        if (l <= n && cmp(h[l], h[best], type)) best <- l
        if (r <= n && cmp(h[r], h[best], type)) best <- r
        if (best == i) break
        tmp <- h[i]; h[i] <- h[best]; h[best] <- tmp
        i <- best
      }
      h
    }

    observeEvent(input$btn_build, {
      vals <- suppressWarnings(as.integer(trimws(strsplit(input$heap_vals,",")[[1]])))
      vals <- vals[!is.na(vals)]
      req(length(vals) > 0)
      type <- input$heap_type
      h <- vals
      n <- length(h)
      for (i in seq(floor(n/2), 1)) h <- sift_down(h, i, n, type)
      heap_state$h    <- h
      heap_state$type <- type
      heap_state$msg  <- paste0(if(type=="min")"Min" else "Max","-heap built. Root = ", h[1])
    })

    observeEvent(input$btn_pop_heap, {
      h <- heap_state$h; req(length(h) > 0)
      type <- heap_state$type
      root <- h[1]
      n    <- length(h)
      h[1] <- h[n]; h <- h[-n]; n <- n-1
      if (n > 0) h <- sift_down(h, 1, n, type)
      heap_state$h   <- h
      heap_state$msg <- paste0("Extracted ", root,
                                ". New root = ", if(length(h)>0) h[1] else "∅")
    })

    observeEvent(input$btn_clear_heap, {
      heap_state$h   <- integer(0)
      heap_state$msg <- "Heap cleared."
    })

    output$viz_heap <- renderUI({
      h <- heap_state$h
      if (length(h) == 0) return(tags$div(class="viz-canvas",
        tags$span(style="color:#94a3b8; font-size:13px;","Empty heap")))
      # Show array representation + tree level labels
      level_rows <- list()
      level <- 1; start <- 1
      while (start <= length(h)) {
        end <- min(start + 2^(level-1) - 1, length(h))
        nodes_in_level <- lapply(start:end, function(i) {
          cls <- if (i == 1) "vnode active" else "vnode visited"
          tagList(tags$div(class=cls, h[i]),
                  if (i < end) tags$span(class="varrow","  "))
        })
        level_rows <- c(level_rows, list(
          tags$div(style="display:flex; align-items:center; gap:4px; margin:4px 0;",
            tags$span(style="font-size:10px; color:#94a3b8; min-width:50px;", paste0("L",level,":")),
            nodes_in_level)
        ))
        start <- end + 1; level <- level + 1
      }
      tags$div(class="viz-canvas", style="flex-direction:column; align-items:flex-start;", level_rows)
    })

    output$heap_explain <- renderUI({
      tags$div(class="viz-explain", heap_state$msg)
    })

    # ── Top-K ─────────────────────────────────────────────────────────────────
    output$topk_result <- renderUI({
      input$btn_topk
      vals <- suppressWarnings(as.integer(trimws(strsplit(isolate(input$topk_vals),",")[[1]])))
      vals <- vals[!is.na(vals)]
      k    <- max(1, min(isolate(input$topk_k), length(vals)))
      req(length(vals) >= k)
      top_k <- sort(vals, decreasing=TRUE)[1:k]
      callout(paste0("<strong>Top-", k, " elements:</strong> [", paste(top_k, collapse=", "),
                     "]<br>Method: min-heap of size k → O(n log k)"), "success")
    })

    # ── Quiz ─────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class="quiz-q","What is the time complexity of building a heap from n elements?"),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="a")"wrong" else ""),
          "O(n log n)", onclick=sprintf("Shiny.setInputValue('%s','a',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="b")"right" else ""),
          "O(n)", onclick=sprintf("Shiny.setInputValue('%s','b',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="c")"wrong" else ""),
          "O(n²)", onclick=sprintf("Shiny.setInputValue('%s','c',{priority:'event'})",ns("qa"))),
        if (!is.null(ans)) {
          if (ans=="b") tags$div(class="qfeedback right","✅ Correct! Heapify (sift-down from n/2) is O(n) — most nodes are near the leaves and do little work.")
          else tags$div(class="qfeedback wrong","❌ Building a heap via heapify is O(n), not O(n log n). The series Σ(height·count) converges to O(n).")
        }
      )
    })
    observeEvent(input$qa, q_ans(input$qa))
  })
}
