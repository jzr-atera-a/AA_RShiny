# modules/mod_hashing.R — Hash Tables & Sets

hashing_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🗂️", "Hash Tables & Sets",
      "O(1) average lookup, insertion, and deletion. The backbone of frequency counting, deduplication, and two-sum patterns.",
      c("HashMap", "HashSet", "Collision", "Load Factor", "Frequency Map")),

    fluidRow(
      box(title = "Hash Map Simulator", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Simulate a hash table with separate chaining. See how keys map to buckets.",
               style = "font-size:12px; color:#555;"),
        numericInput(ns("table_size"), "Table size (buckets):", value = 7, min = 3, max = 20, step = 1),
        textInput(ns("hm_key"), "Key:", value = "hello"),
        textInput(ns("hm_val"), "Value:", value = "world"),
        fluidRow(
          column(6, actionButton(ns("btn_insert"), "Insert", class = "btn btn-dsa btn-sm", width = "100%")),
          column(6, actionButton(ns("btn_clear_hm"), "Clear", class = "btn btn-dsa-outline btn-sm", width = "100%"))
        )
      ),
      box(title = "Hash Table State", status = "info", solidHeader = TRUE, width = 7,
        uiOutput(ns("viz_hm"))
      )
    ),

    fluidRow(
      box(title = "Frequency Counter", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Count character/word frequencies to see HashMap in action.",
               style = "font-size:12px; color:#555;"),
        textInput(ns("freq_text"), "Text:", value = "the quick brown fox jumps over the lazy dog"),
        radioButtons(ns("freq_mode"), "Count:", choices = c("Characters" = "char", "Words" = "word"), inline = TRUE),
        actionButton(ns("btn_freq"), "Count", class = "btn btn-dsa")
      ),
      box(title = "Frequency Map", status = "info", solidHeader = TRUE, width = 4,
        uiOutput(ns("freq_result"))
      ),
      box(title = "Complexity Reference", status = "info", solidHeader = TRUE, width = 3,
        cplx_table(data.frame(
          Operation = c("Insert", "Lookup", "Delete", "Iterate"),
          Average   = c("O(1)", "O(1)", "O(1)", "O(n)"),
          Worst     = c("O(n)", "O(n)", "O(n)", "O(n)"),
          stringsAsFactors = FALSE
        )),
        tags$p("Worst case when all keys collide to same bucket.", style = "font-size:10.5px; color:#888;"),
        callout("Load factor α = n/m. Rehash when α > 0.75 to keep O(1) average.", "tip")
      )
    ),

    fluidRow(
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 6,
        tags$p(tags$strong("Group Anagrams — O(n·k)"), style = "font-size:12px;"),
        dsa_code(
'from collections import defaultdict
def groupAnagrams(strs):
    groups = defaultdict(list)
    for s in strs:
        key = tuple(sorted(s))
        groups[key].append(s)
    return list(groups.values())'),
        tags$p(tags$strong("Subarray Sum Equals K — O(n)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'from collections import defaultdict
def subarraySum(nums, k):
    count = prefix = 0
    seen = defaultdict(int)
    seen[0] = 1
    for n in nums:
        prefix += n
        count  += seen[prefix - k]
        seen[prefix] += 1
    return count'),
        tags$p(tags$strong("Longest Consecutive Sequence — O(n)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def longestConsecutive(nums):
    s = set(nums)
    best = 0
    for n in s:
        if n - 1 not in s:     # start of a sequence
            cur, length = n, 1
            while cur + 1 in s:
                cur += 1; length += 1
            best = max(best, length)
    return best')
      ),
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 3,
        prob_row(1,   "Two Sum",                       "Easy",   "https://leetcode.com/problems/two-sum/"),
        prob_row(49,  "Group Anagrams",                "Medium", "https://leetcode.com/problems/group-anagrams/"),
        prob_row(128, "Longest Consecutive Sequence",  "Medium", "https://leetcode.com/problems/longest-consecutive-sequence/"),
        prob_row(560, "Subarray Sum Equals K",         "Medium", "https://leetcode.com/problems/subarray-sum-equals-k/"),
        prob_row(347, "Top K Frequent Elements",       "Medium", "https://leetcode.com/problems/top-k-frequent-elements/"),
        prob_row(380, "RandomizedSet (O(1))",          "Medium", "https://leetcode.com/problems/insert-delete-getrandom-o1/"),
        prob_row(146, "LRU Cache",                     "Medium", "https://leetcode.com/problems/lru-cache/")
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 3,
        uiOutput(ns("quiz_ui"))
      )
    ),

    ref_block(
      "Cormen et al. (2009). Introduction to Algorithms (3rd ed.). MIT Press.",
      "Knuth, D. E. (1998). The Art of Computer Programming, Vol. 3: Sorting and Searching.",
      "Weiss, M. A. (2011). Data Structures and Algorithm Analysis in Java (3rd ed.). Pearson."
    )
  )
}

hashing_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    hm_state <- reactiveValues(buckets = list())

    simple_hash <- function(key, size) {
      (sum(utf8ToInt(key)) %% size) + 1
    }

    observeEvent(input$btn_insert, {
      key <- trimws(input$hm_key); val <- trimws(input$hm_val)
      req(nchar(key) > 0)
      size <- max(3, input$table_size)
      if (length(hm_state$buckets) != size) hm_state$buckets <- vector("list", size)
      idx <- simple_hash(key, size)
      bucket <- hm_state$buckets[[idx]]
      # update existing key or append
      found <- FALSE
      if (!is.null(bucket)) {
        for (i in seq_along(bucket)) {
          if (bucket[[i]]$key == key) { bucket[[i]]$val <- val; found <- TRUE; break }
        }
      }
      if (!found) bucket <- c(bucket, list(list(key=key, val=val)))
      hm_state$buckets[[idx]] <- bucket
    })

    observeEvent(input$btn_clear_hm, {
      hm_state$buckets <- vector("list", max(3, input$table_size))
    })

    observeEvent(input$table_size, {
      hm_state$buckets <- vector("list", max(3, input$table_size))
    })

    output$viz_hm <- renderUI({
      size <- max(3, input$table_size)
      buckets <- hm_state$buckets
      if (length(buckets) != size) buckets <- vector("list", size)
      rows <- lapply(seq_len(size), function(i) {
        bucket <- buckets[[i]]
        entries <- if (is.null(bucket) || length(bucket) == 0) {
          tags$span(style="color:#94a3b8; font-size:11px;","(empty)")
        } else {
          lapply(bucket, function(e)
            tags$span(class="vnode visited",
                      style="font-size:11px; padding:4px 8px; margin:2px;",
                      paste0(e$key, "→", e$val))
          )
        }
        tags$div(style="display:flex; align-items:center; gap:8px; margin:4px 0; border-bottom:1px solid #e2e8f0; padding-bottom:4px;",
          tags$span(style="font-size:10px; font-weight:700; color:#4f46e5; min-width:30px;", paste0("[",i-1,"]")),
          tags$div(style="display:flex; flex-wrap:wrap; gap:4px;", entries)
        )
      })
      tags$div(class="viz-canvas", style="flex-direction:column; align-items:stretch;", rows)
    })

    # ── Frequency Counter ─────────────────────────────────────────────────────
    output$freq_result <- renderUI({
      input$btn_freq
      txt  <- isolate(input$freq_text)
      mode <- isolate(input$freq_mode)
      tokens <- if (mode == "char") strsplit(gsub(" ","",txt),"")[[1]]
                else strsplit(trimws(txt),"\\s+")[[1]]
      tokens <- tokens[nchar(tokens) > 0]
      req(length(tokens) > 0)
      freq <- sort(table(tokens), decreasing = TRUE)
      top  <- head(freq, 15)
      rows <- lapply(seq_along(top), function(i)
        tags$div(style="display:flex; align-items:center; gap:8px; margin:2px 0;",
          tags$span(class="vnode active", style="font-size:11px; padding:3px 8px; min-width:60px; text-align:center;", names(top)[i]),
          tags$div(style=paste0("height:14px; background:#4f46e5; border-radius:3px; width:",
                                round(as.integer(top[i])/max(top)*140), "px;")),
          tags$span(style="font-size:11px; color:#64748b;", top[i])
        )
      )
      tags$div(style="font-size:12px;", rows)
    })

    # ── Quiz ─────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class="quiz-q","Two-Sum in O(n) time uses which data structure?"),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="a")"wrong" else ""),
          "Sorted array + binary search",
          onclick=sprintf("Shiny.setInputValue('%s','a',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="b")"right" else ""),
          "Hash map (complement lookup)",
          onclick=sprintf("Shiny.setInputValue('%s','b',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="c")"wrong" else ""),
          "Two pointers",
          onclick=sprintf("Shiny.setInputValue('%s','c',{priority:'event'})",ns("qa"))),
        if (!is.null(ans)) {
          if (ans=="b") tags$div(class="qfeedback right","✅ Correct! Store each number's index in a hash map. For each element check if (target - num) is already in the map → O(n).")
          else tags$div(class="qfeedback wrong","❌ Hash map gives O(n). Sorted array + binary search is O(n log n). Two pointers require sorting first.")
        }
      )
    })
    observeEvent(input$qa, q_ans(input$qa))
  })
}
