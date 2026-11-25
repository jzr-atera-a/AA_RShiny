# modules/mod_sorting.R — Sorting & Searching

# Instrumented sorts. record = TRUE keeps every step for the visualiser;
# record = FALSE only counts comparisons and writes (used by the race chart).
sort_run <- function(v, algo, record = TRUE) {
  a <- v; n <- length(a); steps <- list(); cmp <- 0; wr <- 0; done <- integer(0)
  rec <- function(msg, hl = integer(0), sw = integer(0), pivot = NA, range = NULL) {
    if (!record) return(invisible())
    steps[[length(steps) + 1]] <<- list(a = a, hl = hl, sw = sw, done = done, pivot = pivot, range = range, msg = msg, cmp = cmp, wr = wr)
  }
  swap <- function(i, j) { t <- a[i]; a[i] <<- a[j]; a[j] <<- t; wr <<- wr + 1 }
  rec("The unsorted input. Step through to watch the algorithm impose order.")

  if (algo == "bubble") {
    for (i in sq(1, n - 1)) {
      swapped <- FALSE
      for (j in sq(1, n - i)) {
        cmp <- cmp + 1
        if (a[j] > a[j + 1]) { swap(j, j + 1); swapped <- TRUE; rec(sprintf("%d &gt; %d → out of order, <b>swap</b>.", a[j + 1], a[j]), sw = c(j, j + 1)) }
        else rec(sprintf("%d ≤ %d → already in order.", a[j], a[j + 1]), hl = c(j, j + 1))
      }
      done <- c(done, n - i + 1)
      if (!swapped) { rec("A full pass with no swaps → the array is sorted. <b>Stop early.</b>"); break }
    }
  } else if (algo == "selection") {
    for (i in sq(1, n - 1)) {
      m <- i
      for (j in sq(i + 1, n)) { cmp <- cmp + 1; if (a[j] < a[m]) m <- j }
      if (m != i) swap(i, m)
      done <- c(done, i)
      rec(sprintf("Pass %d: scanned the unsorted part, smallest is <b>%d</b> → %s.", i, a[i], if (m != i) sprintf("swap it into index %d", i - 1) else "it is already in place"), sw = c(i, m))
    }
  } else if (algo == "insertion") {
    for (i in sq(2, n)) {
      rec(sprintf("Take <b>%d</b> and slide it left until the value before it is not larger.", a[i]), hl = i, range = c(1, i))
      j <- i
      while (j > 1) {
        cmp <- cmp + 1
        if (a[j - 1] > a[j]) { swap(j - 1, j); j <- j - 1; rec(sprintf("%d &gt; %d → shift right.", a[j + 1], a[j]), sw = c(j, j + 1), range = c(1, i)) }
        else break
      }
    }
  } else if (algo == "merge") {
    ms <- function(lo, hi) {
      if (lo >= hi) return(invisible())
      mid <- (lo + hi) %/% 2
      ms(lo, mid); ms(mid + 1, hi)
      L <- a[lo:mid]; R <- a[(mid + 1):hi]; i <- 1; j <- 1; out <- numeric(0)
      while (i <= length(L) && j <= length(R)) {
        cmp <<- cmp + 1
        if (L[i] <= R[j]) { out <- c(out, L[i]); i <- i + 1 } else { out <- c(out, R[j]); j <- j + 1 }
      }
      out <- c(out, if (i <= length(L)) L[i:length(L)], if (j <= length(R)) R[j:length(R)])
      a[lo:hi] <<- out; wr <<- wr + length(out)
      rec(sprintf("Merge two sorted runs, indices %d–%d and %d–%d, into one sorted run of %d.", lo - 1, mid - 1, mid, hi - 1, hi - lo + 1), hl = lo:hi, range = c(lo, hi))
    }
    ms(1, n)
  } else if (algo == "quick") {
    qs <- function(lo, hi) {
      if (lo > hi) return(invisible())
      if (lo == hi) { done <<- c(done, lo); return(invisible()) }
      p <- a[hi]; i <- lo - 1
      for (j in lo:(hi - 1)) {
        cmp <<- cmp + 1
        if (a[j] <= p) { i <- i + 1; if (i != j) swap(i, j) }
      }
      if (i + 1 != hi) swap(i + 1, hi)
      done <<- c(done, i + 1)
      rec(sprintf("Partition indices %d–%d around pivot <b>%d</b>: smaller values to its left, larger to its right. The pivot is now in its <b>final</b> position (index %d).", lo - 1, hi - 1, p, i), pivot = i + 1, range = c(lo, hi))
      qs(lo, i); qs(i + 2, hi)
    }
    qs(1, n)
  } else if (algo == "heap") {
    sift <- function(i, size) {
      repeat {
        l <- 2 * i; r <- l + 1; b <- i
        if (l <= size) { cmp <<- cmp + 1; if (a[l] > a[b]) b <- l }
        if (r <= size) { cmp <<- cmp + 1; if (a[r] > a[b]) b <- r }
        if (b == i) break
        swap(i, b); i <- b
      }
    }
    for (i in rev(sq(1, n %/% 2))) sift(i, n)
    rec("Rearranged into a <b>max-heap</b>: the largest value is at index 0.", hl = 1)
    for (end in rev(sq(2, n))) {
      big <- a[1]; swap(1, end); done <- c(done, end); sift(1, end - 1)
      rec(sprintf("Move the max <b>%d</b> to the end of the unsorted part (index %d), then repair the heap.", big, end - 1), sw = c(1, end))
    }
  }
  done <- seq_len(n)
  rec(sprintf("<b>Sorted.</b> %d comparisons and %d writes for n = %d.", cmp, wr, n))
  list(steps = steps, cmp = cmp, wr = wr)
}

SORT_ALGOS <- c("Bubble" = "bubble", "Selection" = "selection", "Insertion" = "insertion",
                "Merge" = "merge", "Quick (last-element pivot)" = "quick", "Heap" = "heap")

sorting_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🔢", "Sorting & Searching",
      "Sorting is rarely the question but very often the first step. Know how the classic algorithms behave, when each breaks down, and how binary search extends from arrays to answers.",
      c("O(n²) sorts", "Merge Sort", "Quick Sort", "Heap Sort", "Stability", "Binary Search on Answer")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Sorting Visualiser", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(5, textInput(ns("vals"), "Values (up to 12):", "38,27,43,3,9,82,10,55,19")),
              column(4, selectInput(ns("algo"), "Algorithm:", SORT_ALGOS, selected = "quick")),
              column(3, tags$div(style = "margin-top:25px;", actionButton(ns("shuffle"), "🎲 Shuffle", class = "btn btn-dsa-outline btn-sm")))
            ),
            stepper_ui(ns, "st"),
            plotlyOutput(ns("st_plot"), height = "270px"),
            uiOutput(ns("st_explain")),
            legend_row(c("comparing" = COL$pri, "swapped / moved" = COL$warn, "pivot" = COL$pink, "working range" = "#a5b4fc", "final position" = COL$ok))
          ),
          box(title = "How this algorithm thinks", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("st_kpi")),
            uiOutput(ns("st_note"))
          )
        ),
        fluidRow(
          box(title = "The Race — real comparison counts as n grows", status = "primary", solidHeader = TRUE, width = 8,
            radioButtons(ns("race_input"), "Input shape:", inline = TRUE,
              choices = c("Random" = "random", "Already sorted" = "sorted", "Reversed" = "reversed", "Few distinct values" = "dups")),
            plotlyOutput(ns("race_plot"), height = "330px")
          ),
          box(title = "Read the chart", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("race_note")),
            callout("On a log-log chart, O(n²) algorithms are lines of slope 2 and O(n log n) algorithms hug slope 1. The gap at n = 256 is already ~10×; at a million it is ~50,000×.", "info")
          )
        ),
        fluidRow(
          box(title = "Stability — do equal keys keep their order?", status = "primary", solidHeader = TRUE, width = 6,
            textInput(ns("stab"), "Records as key+tag:", "5a,3a,5b,1a,3b,5c,1b"),
            uiOutput(ns("stab_viz")),
            hint("Stability matters when you sort by one field after another (sort by name, then stably by department → names stay ordered inside each department).")
          ),
          box(title = "Binary Search on the Answer — Koko eating bananas (#875)", status = "primary", solidHeader = TRUE, width = 6,
            fluidRow(
              column(8, textInput(ns("bs_piles"), "Piles:", "3,6,7,11,14,9")),
              column(4, numericInput(ns("bs_h"), "Hours allowed:", 10, min = 1))
            ),
            plotlyOutput(ns("bs_plot"), height = "250px"),
            uiOutput(ns("bs_explain"))
          )
        ),
        fluidRow(
          box(title = "Binary Search in a Rotated Sorted Array (#33 / #153)", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(4, textInput(ns("rot_arr"), "Rotated sorted array:", "15, 18, 22, 27, 31, 2, 5, 8, 11, 13")),
              column(3, selectInput(ns("rot_mode"), "Find:", c("target (#33)" = "target", "minimum (#153)" = "min"))),
              column(2, numericInput(ns("rot_t"), "Target:", 8)),
              column(3, stepper_ui(ns, "rot"))
            ),
            plotlyOutput(ns("rot_plot"), height = "250px"),
            uiOutput(ns("rot_viz"))
          ),
          box(title = "One half is always sorted", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("rot_code")),
            callout("Compare <code>nums[mid]</code> with an end of the window. Whichever half is sorted can be tested with a simple range check — if the target is not in it, it must be in the other half.", "tip"),
            callout("With duplicates (#81, #154) <code>nums[lo] == nums[mid]</code> tells you nothing; shrink with <code>lo += 1</code> — worst case O(n).", "warn"))
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("Sorting first often unlocks two pointers, greedy scans or binary search — an O(n log n) pre-step is usually acceptable.",
                   "Need the k-th element only → quickselect (O(n) average) or a size-k heap.",
                   "Keys are small integers → counting / radix sort beats O(n log n).",
                   "'Minimise the maximum' or 'smallest value that works' with a yes/no feasibility test → binary search on the answer."),
          pitfalls = c("Naive quicksort on sorted input is O(n²) and recursion depth n — randomise or use median-of-three.",
                       "Forgetting merge sort's O(n) extra memory.",
                       "Assuming your language's sort is stable: Python's is; C++ <code>std::sort</code> is not.",
                       "Binary search on the answer with the wrong boundary update → infinite loop. Use <code>lo &lt; hi</code> with <code>hi = mid</code> / <code>lo = mid + 1</code>."),
          tips = c("In interviews you call the library sort — but be ready to say what it is (Timsort) and its cost.",
                   "Know the lower bound: any comparison sort needs Ω(n log n) comparisons, because n! orderings need log₂(n!) yes/no answers.",
                   "For custom ordering, write the key function or comparator carefully and say whether ties matter.")
        ),
        fluidRow(
          box(title = "The Comparison Table", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Algorithm = c("Bubble", "Selection", "Insertion", "Merge", "Quick", "Heap", "Counting", "Radix", "Timsort"),
              Best = c("O(n)", "O(n²)", "O(n)", "O(n log n)", "O(n log n)", "O(n log n)", "O(n + k)", "O(d·(n + k))", "O(n)"),
              Average = c("O(n²)", "O(n²)", "O(n²)", "O(n log n)", "O(n log n)", "O(n log n)", "O(n + k)", "O(d·(n + k))", "O(n log n)"),
              Worst = c("O(n²)", "O(n²)", "O(n²)", "O(n log n)", "O(n²)", "O(n log n)", "O(n + k)", "O(d·(n + k))", "O(n log n)"),
              Space = c("O(1)", "O(1)", "O(1)", "O(n)", "O(log n)", "O(1)", "O(k)", "O(n + k)", "O(n)"),
              Stable = c("Yes", "No", "Yes", "Yes", "No", "No", "Yes", "Yes", "Yes"),
              stringsAsFactors = FALSE))
          ),
          box(title = "What real languages use", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Language = c("Python sorted / list.sort", "Java — objects", "Java — primitives", "C++ std::sort", "C++ std::stable_sort", "JavaScript (V8)"),
              Algorithm = c("Timsort (Powersort since 3.11)", "Timsort", "Dual-pivot quicksort", "Introsort (quick + heap + insertion)", "Merge sort", "Timsort"),
              Stable = c("Yes", "Yes", "n/a", "No", "Yes", "Yes"),
              stringsAsFactors = FALSE)),
            callout("<b>Timsort</b> finds runs that are already sorted and merges them, so nearly-sorted real-world data sorts in close to O(n). Insertion sort handles the short runs — it is the fastest algorithm for tiny arrays.", "tip")
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4,
                dsa_code(
'def merge_sort(a):
    if len(a) <= 1: return a
    mid = len(a) // 2
    L, R = merge_sort(a[:mid]), merge_sort(a[mid:])
    out, i, j = [], 0, 0
    while i < len(L) and j < len(R):
        if L[i] <= R[j]:           # <= keeps it stable
            out.append(L[i]); i += 1
        else:
            out.append(R[j]); j += 1
    return out + L[i:] + R[j:]', "Merge sort"),
                dsa_code(
'def sortColors(nums):            # Dutch national flag
    lo, mid, hi = 0, 0, len(nums) - 1
    while mid <= hi:
        if nums[mid] == 0:
            nums[lo], nums[mid] = nums[mid], nums[lo]
            lo += 1; mid += 1
        elif nums[mid] == 1:
            mid += 1
        else:
            nums[mid], nums[hi] = nums[hi], nums[mid]
            hi -= 1', "3-way partition — one pass")
              ),
              column(4,
                dsa_code(
'def quickselect(a, k):          # k-th smallest, 0-based
    pivot = random.choice(a)
    lo = [x for x in a if x < pivot]
    eq = [x for x in a if x == pivot]
    hi = [x for x in a if x > pivot]
    if k < len(lo):
        return quickselect(lo, k)
    if k < len(lo) + len(eq):
        return pivot
    return quickselect(hi, k - len(lo) - len(eq))', "Quickselect — O(n) average"),
                dsa_code(
'def merge(intervals):
    intervals.sort(key=lambda x: x[0])
    out = [intervals[0]]
    for s, e in intervals[1:]:
        if s <= out[-1][1]:                 # overlaps
            out[-1][1] = max(out[-1][1], e)
        else:
            out.append([s, e])
    return out', "Sort + sweep — merge intervals")
              ),
              column(4,
                dsa_code(
'def minEatingSpeed(piles, h):
    def feasible(k):
        return sum((p + k - 1) // k for p in piles) <= h
    lo, hi = 1, max(piles)
    while lo < hi:
        mid = (lo + hi) // 2
        if feasible(mid):
            hi = mid          # works → try smaller
        else:
            lo = mid + 1      # too slow → go bigger
    return lo', "Binary search on the answer"),
                dsa_code(
'i = bisect.bisect_left(a, x)    # first index with a[i] >= x
j = bisect.bisect_right(a, x)   # first index with a[j] >  x
count_of_x = j - i
present = i < len(a) and a[i] == x', "bisect — boundaries in O(log n)")
              )
            )
          )
        )
      ),

      practice = practice_tab(ns, "sorting",
        "Knuth, D. E. (1998). The Art of Computer Programming, Vol. 3: Sorting and Searching (2nd ed.).",
        "Hoare, C. A. R. (1962). Quicksort. The Computer Journal 5(1).",
        "Peters, T. (2002). Timsort — listsort.txt in the CPython source tree.")
    )
  )
}

sorting_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$shuffle, {
      updateTextInput(session, "vals", value = paste(sample(5:95, 10), collapse = ","))
    })
    vals <- reactive({
      v <- parse_ints(input$vals, 12)
      validate(need(length(v) >= 2, "Enter at least two integers."))
      v
    })
    run <- reactive(sort_run(vals(), input$algo))
    st  <- stepper_server(input, output, session, "st", reactive(run()$steps), speed = 600)

    output$st_plot <- renderPlotly({
      s <- st$cur(); n <- length(s$a)
      cols <- rep(COL$idle, n)
      if (!is.null(s$range)) cols[s$range[1]:s$range[2]] <- "#a5b4fc"
      cols[s$done] <- COL$ok
      cols[s$hl] <- COL$pri
      cols[s$sw] <- COL$warn
      if (!is.na(s$pivot)) cols[s$pivot] <- COL$pink
      bar_state(s$a, cols, height = 270)
    })
    output$st_explain <- renderUI(explain(st$cur()$msg))
    output$st_kpi <- renderUI({
      s <- st$cur(); n <- length(vals())
      kpi_row(kpi(s$cmp, "comparisons", COL$pri), kpi(s$wr, "swaps / writes", COL$warn), kpi(round(n * log2(n)), "n·log₂n", COL$ok), kpi(n * (n - 1) / 2, "n(n−1)/2", COL$err))
    })
    output$st_note <- renderUI({
      txt <- switch(input$algo,
        bubble    = c("Repeatedly compare neighbours and swap if out of order. After each pass the largest remaining value has 'bubbled' to the end.", "Only useful as a teaching tool — or to detect an already-sorted array in one O(n) pass."),
        selection = c("Find the minimum of the unsorted part and swap it to the front. Always n(n−1)/2 comparisons, whatever the input.", "Makes at most n − 1 swaps — the fewest writes of any simple sort — but it is not stable."),
        insertion = c("Grow a sorted prefix: take the next value and slide it left into place, like sorting a hand of cards.", "O(n) on nearly-sorted data and very fast for small n — which is why Timsort and introsort both use it for short runs."),
        merge     = c("Divide in half, sort each half recursively, then merge two sorted halves in linear time.", "Guaranteed O(n log n) and stable; the price is O(n) extra memory. The go-to for linked lists and external sorting."),
        quick     = c("Pick a pivot, partition everything smaller to its left and larger to its right, recurse on both sides.", "Fastest in practice on arrays (in place, cache-friendly) but O(n²) when pivots are bad — try an already-sorted input here."),
        heap      = c("Build a max-heap, then repeatedly swap the root to the end and repair the heap.", "O(n log n) worst case with O(1) extra space — but not stable and less cache-friendly than quicksort."))
      tagList(callout(paste0("<b>Idea.</b> ", txt[1]), "info"), callout(paste0("<b>Verdict.</b> ", txt[2]), "tip"))
    })

    # ── Race ─────────────────────────────────────────────────────────────────
    race <- reactive({
      sizes <- c(8, 16, 32, 64, 128, 256); kind <- input$race_input
      set.seed(7)
      mk <- function(n) switch(kind, random = sample(n), sorted = seq_len(n), reversed = rev(seq_len(n)), dups = sample(1:4, n, replace = TRUE))
      do.call(rbind, lapply(sizes, function(n) {
        v <- mk(n)
        data.frame(n = n, algo = names(SORT_ALGOS), cmp = vapply(SORT_ALGOS, function(al) sort_run(v, al, record = FALSE)$cmp, numeric(1)), stringsAsFactors = FALSE)
      }))
    })
    output$race_plot <- renderPlotly({
      d <- race(); pal <- c(COL$err, COL$warn, COL$pink, COL$ok, COL$pri, COL$acc)
      p <- plot_ly(height = 330)
      for (k in seq_along(SORT_ALGOS)) {
        dd <- d[d$algo == names(SORT_ALGOS)[k], ]
        p <- add_trace(p, x = dd$n, y = pmax(dd$cmp, 1), type = "scatter", mode = "lines+markers", name = names(SORT_ALGOS)[k],
                       line = list(color = pal[k], width = 2.5), marker = list(color = pal[k], size = 7))
      }
      p %>% dsa_layout(xt = "input size n", yt = "comparisons", legend = TRUE) %>%
        layout(xaxis = list(type = "log", tickvals = c(8, 16, 32, 64, 128, 256)), yaxis = list(type = "log"))
    })
    output$race_note <- renderUI({
      callout(switch(input$race_input,
        random   = "<b>Random input:</b> the three O(n²) sorts cluster at the top; merge, quick and heap cluster at the bottom. This is the textbook picture.",
        sorted   = "<b>Sorted input:</b> bubble (with early exit) and insertion drop to O(n) — but naive quicksort jumps <i>up</i> to O(n²), because the last element is always the worst possible pivot.",
        reversed = "<b>Reversed input:</b> worst case for bubble and insertion, and again O(n²) for last-pivot quicksort. Merge and heap sort do not care.",
        dups     = "<b>Few distinct values:</b> two-way-partition quicksort degrades because equal keys all fall on one side. The fix is three-way (Dutch flag) partitioning."), "warn")
    })

    # ── Stability ────────────────────────────────────────────────────────────
    output$stab_viz <- renderUI({
      tok <- trimws(strsplit(input$stab %||% "", ",")[[1]]); tok <- head(tok[nzchar(tok)], 12)
      key <- suppressWarnings(as.numeric(sub("^(-?[0-9]+).*$", "\\1", tok)))
      validate(need(length(tok) >= 2 && !anyNA(key), "Enter records like 5a,3a,5b — a number followed by a tag."))
      stable <- tok[order(key)]
      a <- tok; k <- key; n <- length(a)             # selection sort: unstable
      for (i in sq(1, n - 1)) { m <- i; for (j in sq(i + 1, n)) if (k[j] < k[m]) m <- j
        if (m != i) { t <- a[i]; a[i] <- a[m]; a[m] <- t; t <- k[i]; k[i] <- k[m]; k[m] <- t } }
      same <- identical(a, stable)
      tagList(
        tags$div(class = "code-title", "Input"), vrow(tok, idx = FALSE, wide = TRUE),
        tags$div(class = "code-title", style = "margin-top:8px;", "Stable sort (merge / insertion / Timsort)"), vrow(stable, "found", idx = FALSE, wide = TRUE),
        tags$div(class = "code-title", style = "margin-top:8px;", "Selection sort (unstable)"), vrow(a, ifelse(a == stable, "found", "bad"), idx = FALSE, wide = TRUE),
        explain(if (same) "Both outputs agree on this input — but selection sort offers no guarantee. Try <code>5a,5b,1a</code>."
                else "Red cells show equal keys that <b>swapped their original order</b>. Selection sort's long-distance swaps jump records over their equals; a stable sort never does."))
    })

    # ── Binary search on the answer ──────────────────────────────────────────
    bs_calc <- reactive({
      p <- parse_ints(input$bs_piles, 12); h <- input$bs_h
      validate(need(length(p) >= 1 && all(p > 0), "Enter positive pile sizes."),
               need(!is.null(h) && !is.na(h) && h >= length(p), sprintf("Hours must be at least the number of piles (%d).", length(p))))
      hours <- function(k) sum(ceiling(p / k))
      lo <- 1; hi <- max(p); probes <- integer(0)
      while (lo < hi) { mid <- (lo + hi) %/% 2; probes <- c(probes, mid); if (hours(mid) <= h) hi <- mid else lo <- mid + 1 }
      list(p = p, h = h, ks = 1:max(p), hrs = vapply(1:max(p), hours, numeric(1)), probes = probes, ans = lo, hours = hours)
    })
    output$bs_plot <- renderPlotly({
      r <- bs_calc()
      plot_ly(height = 250) %>%
        add_trace(x = r$ks, y = r$hrs, type = "scatter", mode = "lines+markers", name = "hours needed", line = list(color = COL$idle, width = 2), marker = list(color = ifelse(r$hrs <= r$h, COL$ok, COL$err), size = 7)) %>%
        add_trace(x = r$probes, y = vapply(r$probes, r$hours, numeric(1)), type = "scatter", mode = "markers+text", name = "probes",
                  text = seq_along(r$probes), textposition = "top center", marker = list(color = COL$pri, size = 13, symbol = "circle-open", line = list(width = 3))) %>%
        dsa_layout(xt = "eating speed k (bananas / hour)", yt = "hours needed") %>%
        layout(shapes = list(list(type = "line", x0 = 0, x1 = max(r$ks), y0 = r$h, y1 = r$h, line = list(color = COL$warn, dash = "dash", width = 2))),
               yaxis = list(range = c(0, min(max(r$hrs), r$h * 3) * 1.1)))
    })
    output$bs_explain <- renderUI({
      r <- bs_calc()
      explain(sprintf("Feasibility is <b>monotonic</b>: once a speed works (green), every faster speed works too. So binary-search the speeds 1..%d instead of trying them all. Probes in order: %s → minimum speed <b>%d</b>, found in %d checks instead of %d.",
                      max(r$p), if (length(r$probes)) paste(r$probes, collapse = ", ") else "none needed", r$ans, length(r$probes), max(r$p)))
    })

    # ── Rotated sorted array ─────────────────────────────────────────────────
    rot_arr <- reactive({
      a <- parse_ints(input$rot_arr)
      validate(need(length(a) >= 2, "Enter at least two integers."),
               need(!any(duplicated(a)), "Values must be distinct for #33 / #153."),
               need(sum(diff(a) < 0) <= 1 && (sum(diff(a) < 0) == 0 || a[length(a)] < a[1]), "That is not a rotated sorted array."))
      head(a, 20)
    })
    rot_steps <- reactive({
      a <- rot_arr(); n <- length(a); lo <- 1; hi <- n; steps <- list()
      if (input$rot_mode == "min") {
        steps[[1]] <- list(lo = lo, hi = hi, mid = NA, line = 1, msg = "Find the rotation point: the minimum is the only element smaller than its predecessor.")
        while (lo < hi) {
          mid <- (lo + hi) %/% 2
          right <- a[mid] > a[hi]
          steps[[length(steps) + 1]] <- list(lo = lo, hi = hi, mid = mid, line = if (right) 3:4 else 5:6,
            msg = sprintf("nums[mid=%d] = %g %s nums[hi=%d] = %g → %s", mid - 1, a[mid], if (right) "&gt;" else "≤", hi - 1, a[hi],
                          if (right) "the drop is to the right of mid: lo = mid + 1" else "mid..hi is sorted, so the minimum is at mid or left: hi = mid"))
          if (right) lo <- mid + 1 else hi <- mid
        }
        steps[[length(steps) + 1]] <- list(lo = lo, hi = lo, mid = lo, found = TRUE, line = 7,
          msg = sprintf("lo == hi → minimum <b>%g</b> at index %d (the array was rotated %d places).", a[lo], lo - 1, lo - 1))
      } else {
        t <- input$rot_t %||% 0; found <- NA
        steps[[1]] <- list(lo = lo, hi = hi, mid = NA, line = 1, msg = sprintf("Search for %g. The window is the whole array.", t))
        while (lo <= hi) {
          mid <- (lo + hi) %/% 2
          if (a[mid] == t) { found <- mid; steps[[length(steps) + 1]] <- list(lo = lo, hi = hi, mid = mid, found = TRUE, line = 3, msg = sprintf("nums[%d] = %g → <b>found at index %d</b>.", mid - 1, t, mid - 1)); break }
          if (a[lo] <= a[mid]) {
            inl <- a[lo] <= t && t < a[mid]
            steps[[length(steps) + 1]] <- list(lo = lo, hi = hi, mid = mid, sorted = c(lo, mid), line = 4:6,
              msg = sprintf("Left half [%d..%d] = %g..%g is sorted. Is %g inside? %s", lo - 1, mid - 1, a[lo], a[mid], t,
                            if (inl) "Yes → hi = mid − 1." else "No → it can only be on the right: lo = mid + 1."))
            if (inl) hi <- mid - 1 else lo <- mid + 1
          } else {
            inr <- a[mid] < t && t <= a[hi]
            steps[[length(steps) + 1]] <- list(lo = lo, hi = hi, mid = mid, sorted = c(mid, hi), line = 7:9,
              msg = sprintf("Right half [%d..%d] = %g..%g is sorted. Is %g inside? %s", mid - 1, hi - 1, a[mid], a[hi], t,
                            if (inr) "Yes → lo = mid + 1." else "No → it can only be on the left: hi = mid − 1."))
            if (inr) lo <- mid + 1 else hi <- mid - 1
          }
        }
        if (is.na(found)) steps[[length(steps) + 1]] <- list(lo = lo, hi = hi, mid = NA, line = 10, msg = sprintf("Window empty → %g is not present, return −1. O(log n) either way.", t))
      }
      steps
    })
    rot <- stepper_server(input, output, session, "rot", rot_steps, speed = 900)
    output$rot_plot <- renderPlotly({
      a <- rot_arr(); s <- rot$cur(); n <- length(a); k <- seq_len(n)
      cols <- ifelse(k >= s$lo & k <= s$hi, "#c7d2fe", COL$idle)
      if (!is.null(s$sorted)) cols[k >= s$sorted[1] & k <= s$sorted[2]] <- "#a7f3d0"
      if (!is.na(s$mid)) cols[s$mid] <- if (isTRUE(s$found)) COL$ok else COL$pri
      bar_state(a, cols, height = 250)
    })
    output$rot_viz <- renderUI({
      a <- rot_arr(); s <- rot$cur(); n <- length(a)
      cls <- ifelse(seq_len(n) >= s$lo & seq_len(n) <= s$hi, "", "dim")
      if (!is.na(s$mid)) cls[s$mid] <- if (isTRUE(s$found)) "found" else "active"
      tagList(vrow(a, cls, ptr = list(lo = s$lo, mid = s$mid, hi = s$hi)), explain(s$msg))
    })
    output$rot_code <- renderUI({
      pseudo(if (input$rot_mode == "min")
        c("lo, hi = 0, n - 1", "while lo < hi:", "    mid = (lo + hi) // 2", "    if nums[mid] > nums[hi]:", "        lo = mid + 1", "    else:", "        hi = mid", "return nums[lo]")
      else
        c("lo, hi = 0, n - 1;  while lo <= hi:", "    mid = (lo + hi) // 2", "    if nums[mid] == t: return mid", "    if nums[lo] <= nums[mid]:          # left sorted",
          "        if nums[lo] <= t < nums[mid]: hi = mid - 1", "        else: lo = mid + 1", "    else:                              # right sorted",
          "        if nums[mid] < t <= nums[hi]: lo = mid + 1", "        else: hi = mid - 1", "return -1"),
        active = rot$cur()$line)
    })

    quiz_server(input, output, session, topic = "sorting", progress = progress, questions = list(
      list(q = "Which algorithm is stable <b>and</b> guaranteed O(n log n)?",
           opts = c("Quick sort", "Heap sort", "Merge sort", "Selection sort"), ans = 3,
           why = "Merge sort never reorders equal keys and always splits evenly. Quick sort has an O(n²) worst case; heap sort is not stable."),
      list(q = "Quicksort always picking the last element as pivot, run on an already-sorted array, costs…",
           opts = c("O(n)", "O(n log n)", "O(n²)", "O(log n)"), ans = 3,
           why = "Every partition is maximally lopsided (n − 1 vs 0), so there are n levels of O(n) work."),
      list(q = "Why can no comparison-based sort beat Ω(n log n) in the worst case?",
           opts = c("Computers are too slow", "There are n! possible orderings and each comparison only halves the possibilities", "Swaps are expensive", "Memory is limited"), ans = 2,
           why = "A decision tree needs at least log₂(n!) ≈ n log₂ n levels to distinguish all n! permutations."),
      list(q = "Which simple sort is the best choice for a small or nearly-sorted array?",
           opts = c("Selection sort", "Bubble sort", "Insertion sort", "Heap sort"), ans = 3,
           why = "Insertion sort does O(n + inversions) work, so nearly-sorted data is nearly linear. Production sorts switch to it for short runs."),
      list(q = "'Binary search on the answer' requires that…",
           opts = c("The input array is sorted", "The feasibility test is monotonic in the candidate answer", "The answer is a power of two", "There are no duplicates"), ans = 2,
           why = "You search the space of answers, not the array. It works whenever 'x is feasible' implies everything on one side of x is feasible too.")
    ))
  })
}
