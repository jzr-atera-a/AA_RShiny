# modules/mod_arrays.R — Arrays & Strings

arrays_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("📐", "Arrays & Strings",
      "Contiguous memory, index-based access, and the two-pointer / sliding-window patterns that unlock O(n) solutions.",
      c("Two Pointer", "Sliding Window", "Prefix Sum", "O(1) access")),

    fluidRow(
      # ── Controls ──────────────────────────────────────────────────────────
      box(title = "Binary Search Step-Through", status = "primary", solidHeader = TRUE, width = 4,
        tags$p("Enter a sorted array (comma-separated) and a target, then step through binary search.",
               style = "font-size:12px; color:#555; margin-bottom:10px;"),
        textInput(ns("arr_input"), "Sorted Array:", value = "2,5,8,12,16,23,38,56,72,91"),
        numericInput(ns("target"), "Target:", value = 23, step = 1),
        fluidRow(
          column(6, actionButton(ns("btn_prev"), "◀ Prev", class = "btn btn-dsa-outline btn-sm", width = "100%")),
          column(6, actionButton(ns("btn_next"), "▶ Next", class = "btn btn-dsa btn-sm", width = "100%"))
        ),
        tags$br(),
        actionButton(ns("btn_reset"), "↺ Reset", class = "btn btn-dsa-outline btn-sm")
      ),
      # ── Visualiser ────────────────────────────────────────────────────────
      box(title = "Visualisation", status = "info", solidHeader = TRUE, width = 8,
        uiOutput(ns("viz_array")),
        uiOutput(ns("viz_explain")),
        tags$br(),
        uiOutput(ns("viz_result"))
      )
    ),

    fluidRow(
      # ── Sliding window chart ───────────────────────────────────────────────
      box(title = "Sliding Window — Max Sum Subarray of Size k", status = "primary", solidHeader = TRUE, width = 8,
        fluidRow(
          column(6, textInput(ns("sw_arr"), "Array:", value = "2,1,5,1,3,2,4,6,1")),
          column(3, numericInput(ns("sw_k"), "k:", value = 3, min = 1, max = 9))
        ),
        plotlyOutput(ns("sw_plot"), height = "260px"),
        tags$p("Green window = current; gold = maximum found so far.",
               style = "font-size:11px; color:#888; margin-top:6px;")
      ),
      box(title = "Complexity Reference", status = "info", solidHeader = TRUE, width = 4,
        cplx_table(data.frame(
          Operation = c("Access", "Search", "Insert (end)", "Insert (mid)", "Delete"),
          Time      = c("O(1)", "O(n)", "O(1) amort.", "O(n)", "O(n)"),
          Space     = c("—", "O(1)", "O(1)", "O(1)", "O(1)"),
          stringsAsFactors = FALSE
        )),
        tags$br(),
        callout("<strong>Two-pointer:</strong> shrink/grow from both ends — O(n) for sorted-array problems.", "tip"),
        callout("<strong>Sliding window:</strong> expand right, shrink left — O(n) for subarray/substring problems.", "info")
      )
    ),

    fluidRow(
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 6,
        tags$p(tags$strong("Two Sum — Hash Map O(n)"), style = "font-size:12px; margin:0 0 4px;"),
        dsa_code(
'def twoSum(nums, target):
    seen = {}
    for i, num in enumerate(nums):
        comp = target - num
        if comp in seen:
            return [seen[comp], i]
        seen[num] = i'),
        tags$p(tags$strong("Max Sliding Window — Deque O(n)"), style = "font-size:12px; margin:10px 0 4px;"),
        dsa_code(
'from collections import deque
def maxSlidingWindow(nums, k):
    dq, res = deque(), []
    for i, n in enumerate(nums):
        while dq and nums[dq[-1]] < n:
            dq.pop()
        dq.append(i)
        if dq[0] == i - k: dq.popleft()
        if i >= k - 1: res.append(nums[dq[0]])
    return res')
      ),
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 3,
        prob_row(1,   "Two Sum",                          "Easy",   "https://leetcode.com/problems/two-sum/"),
        prob_row(3,   "Longest Substr. No Repeat",        "Medium", "https://leetcode.com/problems/longest-substring-without-repeating-characters/"),
        prob_row(11,  "Container With Most Water",        "Medium", "https://leetcode.com/problems/container-with-most-water/"),
        prob_row(42,  "Trapping Rain Water",              "Hard",   "https://leetcode.com/problems/trapping-rain-water/"),
        prob_row(238, "Product of Array Except Self",     "Medium", "https://leetcode.com/problems/product-of-array-except-self/"),
        prob_row(239, "Sliding Window Maximum",           "Hard",   "https://leetcode.com/problems/sliding-window-maximum/"),
        prob_row(53,  "Maximum Subarray",                 "Medium", "https://leetcode.com/problems/maximum-subarray/")
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 3,
        uiOutput(ns("quiz_ui"))
      )
    ),

    ref_block(
      "Cormen et al. (2009). Introduction to Algorithms (3rd ed.). MIT Press.",
      "Aziz, Lee & Prakash (2018). Elements of Programming Interviews in Python.",
      "Laakmann McDowell (2015). Cracking the Coding Interview (6th ed.). CareerCup."
    )
  )
}

arrays_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Binary search state ──────────────────────────────────────────────────
    state <- reactiveValues(step = 0, steps = list(), done = FALSE)

    build_steps <- function(arr, tgt) {
      steps <- list(); lo <- 1; hi <- length(arr)
      while (lo <= hi) {
        mid <- floor((lo + hi) / 2)
        steps[[length(steps)+1]] <- list(lo=lo, hi=hi, mid=mid,
          found=(arr[mid]==tgt), val=arr[mid])
        if      (arr[mid] == tgt) break
        else if (arr[mid] <  tgt) lo <- mid + 1
        else                      hi <- mid - 1
      }
      if (lo > hi) steps[[length(steps)+1]] <- list(lo=lo, hi=hi, mid=NA, found=FALSE, val=NA)
      steps
    }

    parsed_arr <- reactive({
      vals <- suppressWarnings(as.integer(trimws(strsplit(input$arr_input, ",")[[1]])))
      vals[!is.na(vals)]
    })

    observeEvent(input$btn_reset, {
      state$step <- 0; state$steps <- list(); state$done <- FALSE
    })
    observeEvent(input$arr_input, { state$step <- 0; state$steps <- list(); state$done <- FALSE })
    observeEvent(input$target,    { state$step <- 0; state$steps <- list(); state$done <- FALSE })

    observeEvent(input$btn_next, {
      arr <- parsed_arr(); req(length(arr) > 0)
      if (length(state$steps) == 0) state$steps <- build_steps(arr, input$target)
      if (state$step < length(state$steps)) state$step <- state$step + 1
    })
    observeEvent(input$btn_prev, {
      if (state$step > 0) state$step <- state$step - 1
    })

    output$viz_array <- renderUI({
      arr <- parsed_arr(); req(length(arr) > 0)
      stp <- if (state$step > 0 && state$step <= length(state$steps)) state$steps[[state$step]] else NULL
      nodes <- lapply(seq_along(arr), function(i) {
        cls <- "vnode"
        if (!is.null(stp)) {
          if (!is.na(stp$mid) && i == stp$mid) cls <- paste(cls, if(stp$found) "found" else "active")
          else if (i >= stp$lo && i <= stp$hi && i != stp$mid) cls <- paste(cls, "visited")
        }
        tags$div(style = "text-align:center; display:inline-block; margin:3px;",
          tags$div(class = cls, arr[i]),
          tags$div(style = "font-size:9px; color:#94a3b8; margin-top:2px;", paste0("[", i-1, "]"))
        )
      })
      tags$div(class = "viz-canvas", nodes)
    })

    output$viz_explain <- renderUI({
      if (state$step == 0) return(tags$div(class = "viz-explain", "Press ▶ Next to start binary search."))
      stp <- state$steps[[state$step]]; arr <- parsed_arr()
      txt <- if (is.na(stp$mid)) {
        sprintf("Not found — search space exhausted (lo=%d > hi=%d)", stp$lo-1, stp$hi-1)
      } else if (stp$found) {
        sprintf("✅ Found %d at index %d in %d step(s)!", input$target, stp$mid-1, state$step)
      } else if (stp$val < input$target) {
        sprintf("Step %d: mid=%d, arr[mid]=%d < target=%d → search RIGHT half", state$step, stp$mid-1, stp$val, input$target)
      } else {
        sprintf("Step %d: mid=%d, arr[mid]=%d > target=%d → search LEFT half", state$step, stp$mid-1, stp$val, input$target)
      }
      tags$div(class = "viz-explain", txt)
    })

    output$viz_result <- renderUI({
      if (state$step == 0 || state$step > length(state$steps)) return(NULL)
      stp <- state$steps[[state$step]]
      if (stp$found) callout(paste0("<strong>Found!</strong> Target ", input$target, " is at index ", stp$mid-1, ". Steps used: ", state$step), "success")
      else if (is.na(stp$mid)) callout(paste0("<strong>Not found.</strong> ", input$target, " is not in the array."), "warn")
      else NULL
    })

    # ── Sliding window chart ─────────────────────────────────────────────────
    output$sw_plot <- renderPlotly({
      arr <- suppressWarnings(as.integer(trimws(strsplit(input$sw_arr, ",")[[1]])))
      arr <- arr[!is.na(arr)]; k <- max(1, min(input$sw_k, length(arr)-1))
      req(length(arr) >= k)
      n <- length(arr); wsum <- numeric(n - k + 1)
      for (i in seq_len(n - k + 1)) wsum[i] <- sum(arr[i:(i+k-1)])
      best_i <- which.max(wsum)
      cols <- rep("#cbd5e1", n)
      cols[best_i:(best_i+k-1)] <- "#f59e0b"

      plot_ly() %>%
        add_bars(x = seq_len(n)-1, y = arr, marker = list(color = cols),
                 name = "Values", text = arr, textposition = "outside") %>%
        add_trace(x = c(best_i-1, best_i+k-2), y = c(max(arr)*1.15, max(arr)*1.15),
                  type = "scatter", mode = "lines+markers",
                  line = list(color = "#f59e0b", width = 3),
                  marker = list(size = 8, color = "#f59e0b"), name = "Best window") %>%
        layout(title = list(text = paste0("Max sum window (k=", k, ") = ", max(wsum)), font = list(size = 13)),
               xaxis = list(title = "Index"), yaxis = list(title = "Value"),
               plot_bgcolor = "#f8fafc", paper_bgcolor = "#ffffff",
               showlegend = FALSE, margin = list(t = 40))
    })

    # ── Quiz ────────────────────────────────────────────────────────────────
    q_answered <- reactiveVal(FALSE)
    output$quiz_ui <- renderUI({
      tagList(
        tags$p(class = "quiz-q", "What is the time complexity of the sliding window maximum (deque approach)?"),
        tags$button(class = paste("qopt", if(q_answered()) "wrong" else ""), "O(n log n)",
                    onclick = sprintf("Shiny.setInputValue('%s', 'a', {priority:'event'})", ns("quiz_ans"))),
        tags$button(class = paste("qopt", if(q_answered()) "right" else ""), "O(n)",
                    onclick = sprintf("Shiny.setInputValue('%s', 'b', {priority:'event'})", ns("quiz_ans"))),
        tags$button(class = paste("qopt", if(q_answered()) "wrong" else ""), "O(n²)",
                    onclick = sprintf("Shiny.setInputValue('%s', 'c', {priority:'event'})", ns("quiz_ans"))),
        if (q_answered()) tags$div(class = "qfeedback right",
          "✅ Correct! Each element is pushed and popped from the deque at most once → O(n) total.")
      )
    })
    observeEvent(input$quiz_ans, { q_answered(TRUE) })
  })
}
