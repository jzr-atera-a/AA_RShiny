# modules/mod_sorting.R — Sorting & Searching

sorting_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🔢", "Sorting & Searching",
      "From O(n²) to O(n log n). Understand partitioning, merge, and why comparison-based sorting can't beat O(n log n).",
      c("QuickSort", "MergeSort", "HeapSort", "Binary Search", "Counting Sort")),

    fluidRow(
      box(title = "Sort Step-Through", status = "primary", solidHeader = TRUE, width = 4,
        tags$p("Enter values and pick an algorithm to animate the sort.", style = "font-size:12px; color:#555;"),
        textInput(ns("sort_vals"), "Values (comma-separated):", value = "64,34,25,12,22,11,90"),
        radioButtons(ns("sort_algo"), "Algorithm:",
          choices = c("Bubble Sort" = "bubble", "Selection Sort" = "selection",
                      "Insertion Sort" = "insertion", "Quick Sort (pivot)" = "quick"),
          selected = "bubble"),
        fluidRow(
          column(6, actionButton(ns("sort_prev"), "◀ Prev", class = "btn btn-dsa-outline btn-sm", width = "100%")),
          column(6, actionButton(ns("sort_next"), "▶ Next", class = "btn btn-dsa btn-sm", width = "100%"))
        ),
        tags$br(),
        actionButton(ns("sort_reset"), "↺ Reset", class = "btn btn-dsa-outline btn-sm")
      ),
      box(title = "Visualisation", status = "info", solidHeader = TRUE, width = 8,
        uiOutput(ns("viz_sort")),
        uiOutput(ns("viz_sort_explain"))
      )
    ),

    fluidRow(
      box(title = "Complexity Reference", status = "info", solidHeader = TRUE, width = 4,
        cplx_table(data.frame(
          Algorithm      = c("Bubble", "Selection", "Insertion", "Merge", "Quick (avg)", "Heap", "Counting"),
          Best           = c("O(n)", "O(n²)", "O(n)", "O(n log n)", "O(n log n)", "O(n log n)", "O(n+k)"),
          Worst          = c("O(n²)", "O(n²)", "O(n²)", "O(n log n)", "O(n²)", "O(n log n)", "O(n+k)"),
          Space          = c("O(1)", "O(1)", "O(1)", "O(n)", "O(log n)", "O(1)", "O(k)"),
          stringsAsFactors = FALSE
        )),
        callout("Lower bound for comparison-based sorting: <strong>Ω(n log n)</strong>. Counting/radix/bucket sort beat this by exploiting value structure.", "tip")
      ),
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 5,
        tags$p(tags$strong("Merge Sort — O(n log n)"), style = "font-size:12px;"),
        dsa_code(
'def mergeSort(arr):
    if len(arr) <= 1: return arr
    mid = len(arr) // 2
    L = mergeSort(arr[:mid])
    R = mergeSort(arr[mid:])
    res = []; i = j = 0
    while i < len(L) and j < len(R):
        if L[i] <= R[j]: res.append(L[i]); i+=1
        else:            res.append(R[j]); j+=1
    return res + L[i:] + R[j:]'),
        tags$p(tags$strong("Quick Select (kth smallest) — O(n) avg"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'import random
def quickSelect(nums, k):
    pivot = random.choice(nums)
    lo = [x for x in nums if x < pivot]
    eq = [x for x in nums if x == pivot]
    hi = [x for x in nums if x > pivot]
    if k <= len(lo):           return quickSelect(lo, k)
    elif k <= len(lo)+len(eq): return pivot
    else:                      return quickSelect(hi, k-len(lo)-len(eq))')
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 3,
        uiOutput(ns("quiz_ui"))
      )
    ),

    fluidRow(
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 6,
        fluidRow(
          column(6,
            prob_row(912, "Sort an Array",                 "Medium", "https://leetcode.com/problems/sort-an-array/"),
            prob_row(215, "Kth Largest Element",           "Medium", "https://leetcode.com/problems/kth-largest-element-in-an-array/"),
            prob_row(56,  "Merge Intervals",               "Medium", "https://leetcode.com/problems/merge-intervals/"),
            prob_row(148, "Sort List",                     "Medium", "https://leetcode.com/problems/sort-list/")
          ),
          column(6,
            prob_row(75,  "Sort Colors (Dutch Flag)",      "Medium", "https://leetcode.com/problems/sort-colors/"),
            prob_row(179, "Largest Number",                "Medium", "https://leetcode.com/problems/largest-number/"),
            prob_row(315, "Count of Smaller Numbers",      "Hard",   "https://leetcode.com/problems/count-of-smaller-numbers-after-self/"),
            prob_row(493, "Reverse Pairs",                 "Hard",   "https://leetcode.com/problems/reverse-pairs/")
          )
        )
      ),
      box(title = "Sorting Patterns", status = "info", solidHeader = TRUE, width = 6,
        callout("<strong>Merge Sort:</strong> stable, always O(n log n), great for linked lists and external sort. Extra O(n) space.", "info"),
        callout("<strong>Quick Sort:</strong> in-place, O(n log n) average but O(n²) worst. Randomised pivot avoids worst case in practice.", "tip"),
        callout("<strong>Heap Sort:</strong> in-place and O(n log n) guaranteed. Not cache-friendly; slower in practice than quick/merge.", "info"),
        callout("<strong>Dutch National Flag:</strong> 3-way partition in O(n) — use for 'sort colors' and Quick Sort with many duplicates.", "tip")
      )
    ),

    ref_block(
      "Cormen et al. (2009). Introduction to Algorithms (3rd ed.). MIT Press.",
      "Knuth, D. E. (1998). The Art of Computer Programming, Vol. 3: Sorting and Searching.",
      "Sedgewick & Wayne (2011). Algorithms (4th ed.). Addison-Wesley."
    )
  )
}

sorting_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    rv <- reactiveValues(steps = list(), step = 0)

    build_bubble_steps <- function(arr) {
      steps <- list(list(arr=arr, i=NA, j=NA, pivot=NA, msg="Initial array"))
      n <- length(arr)
      for (i in seq_len(n-1))
        for (j in seq_len(n-i)) {
          swapped <- arr[j] > arr[j+1]
          if (swapped) { tmp <- arr[j]; arr[j] <- arr[j+1]; arr[j+1] <- tmp }
          steps[[length(steps)+1]] <- list(arr=arr, i=j, j=j+1, pivot=NA,
            msg=sprintf("Compare [%d]=%d and [%d]=%d → %s",
                        j-1,arr[if(swapped)j+1 else j],j,arr[if(swapped)j else j+1],
                        if(swapped)"swapped" else "no swap"))
        }
      steps[[length(steps)+1]] <- list(arr=arr, i=NA, j=NA, pivot=NA, msg="✅ Sorted!")
      steps
    }

    build_selection_steps <- function(arr) {
      steps <- list(list(arr=arr, i=NA, j=NA, pivot=NA, msg="Initial array"))
      n <- length(arr)
      for (i in seq_len(n-1)) {
        min_idx <- i
        for (j in (i+1):n) if (arr[j] < arr[min_idx]) min_idx <- j
        if (min_idx != i) { tmp <- arr[i]; arr[i] <- arr[min_idx]; arr[min_idx] <- tmp }
        steps[[length(steps)+1]] <- list(arr=arr, i=i, j=min_idx, pivot=NA,
          msg=sprintf("Pass %d: min=%d at [%d] → swap to [%d]", i, arr[i], min_idx-1, i-1))
      }
      steps[[length(steps)+1]] <- list(arr=arr, i=NA, j=NA, pivot=NA, msg="✅ Sorted!")
      steps
    }

    build_insertion_steps <- function(arr) {
      steps <- list(list(arr=arr, i=NA, j=NA, pivot=NA, msg="Initial array"))
      n <- length(arr)
      for (i in 2:n) {
        key <- arr[i]; j <- i-1
        while (j >= 1 && arr[j] > key) { arr[j+1] <- arr[j]; j <- j-1 }
        arr[j+1] <- key
        steps[[length(steps)+1]] <- list(arr=arr, i=j+1, j=i, pivot=NA,
          msg=sprintf("Insert %d at position %d", key, j))
      }
      steps[[length(steps)+1]] <- list(arr=arr, i=NA, j=NA, pivot=NA, msg="✅ Sorted!")
      steps
    }

    build_quick_steps <- function(arr) {
      steps <- list(list(arr=arr, i=NA, j=NA, pivot=NA, msg="Initial array"))
      qs <- function(a, lo, hi) {
        if (lo >= hi) return(a)
        pivot_val <- a[hi]; i <- lo - 1
        for (j in lo:(hi-1)) {
          if (a[j] <= pivot_val) { i <- i+1; tmp <- a[i]; a[i] <- a[j]; a[j] <- tmp }
        }
        i <- i+1; tmp <- a[i]; a[i] <- a[hi]; a[hi] <- tmp
        steps[[length(steps)+1]] <<- list(arr=a, i=i, j=hi, pivot=i,
          msg=sprintf("Pivot %d placed at index %d", a[i], i-1))
        a <- qs(a, lo, i-1)
        a <- qs(a, i+1, hi)
        a
      }
      arr <- qs(arr, 1, length(arr))
      steps[[length(steps)+1]] <- list(arr=arr, i=NA, j=NA, pivot=NA, msg="✅ Sorted!")
      steps
    }

    parsed_vals <- reactive({
      vals <- suppressWarnings(as.integer(trimws(strsplit(input$sort_vals,",")[[1]])))
      vals[!is.na(vals)]
    })

    observeEvent(list(input$sort_reset, input$sort_vals, input$sort_algo), {
      rv$steps <- list(); rv$step <- 0
    })

    observeEvent(input$sort_next, {
      vals <- parsed_vals(); req(length(vals) > 0)
      if (length(rv$steps) == 0) {
        rv$steps <- switch(input$sort_algo,
          bubble    = build_bubble_steps(vals),
          selection = build_selection_steps(vals),
          insertion = build_insertion_steps(vals),
          quick     = build_quick_steps(vals)
        )
      }
      if (rv$step < length(rv$steps)) rv$step <- rv$step + 1
    })
    observeEvent(input$sort_prev, { if (rv$step > 0) rv$step <- rv$step - 1 })

    output$viz_sort <- renderUI({
      vals <- parsed_vals(); req(length(vals) > 0)
      stp <- if (rv$step > 0 && rv$step <= length(rv$steps)) rv$steps[[rv$step]] else NULL
      arr <- if (!is.null(stp)) stp$arr else vals
      nodes <- lapply(seq_along(arr), function(i) {
        cls <- "vnode"
        if (!is.null(stp)) {
          if (!is.na(stp$pivot) && i == stp$pivot) cls <- "vnode pivot"
          else if (!is.na(stp$i) && i == stp$i) cls <- "vnode active"
          else if (!is.na(stp$j) && i == stp$j) cls <- "vnode visited"
        }
        tags$div(style = "text-align:center; display:inline-block; margin:3px;",
          tags$div(class = cls, arr[i]),
          tags$div(style = "font-size:9px; color:#94a3b8; margin-top:2px;", i-1)
        )
      })
      tags$div(class = "viz-canvas", nodes)
    })

    output$viz_sort_explain <- renderUI({
      if (rv$step == 0) return(tags$div(class="viz-explain","Press ▶ Next to start stepping through the sort."))
      stp <- rv$steps[[rv$step]]
      tags$div(class="viz-explain", paste0("Step ", rv$step, "/", length(rv$steps), ": ", stp$msg))
    })

    # ── Quiz ─────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class="quiz-q","Which sorting algorithm is stable AND always O(n log n)?"),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="a")"wrong" else ""),
          "Quick Sort", onclick=sprintf("Shiny.setInputValue('%s','a',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="b")"wrong" else ""),
          "Heap Sort", onclick=sprintf("Shiny.setInputValue('%s','b',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="c")"right" else ""),
          "Merge Sort", onclick=sprintf("Shiny.setInputValue('%s','c',{priority:'event'})",ns("qa"))),
        if (!is.null(ans)) {
          if (ans=="c") tags$div(class="qfeedback right","✅ Correct! Merge sort is stable and always O(n log n). Quick sort is O(n²) worst-case; heap sort is not stable.")
          else tags$div(class="qfeedback wrong","❌ Merge sort: stable + always O(n log n). Quick sort: O(n²) worst. Heap sort: not stable.")
        }
      )
    })
    observeEvent(input$qa, q_ans(input$qa))
  })
}
