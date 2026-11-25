# modules/mod_hashing.R — Hash Tables & Sets

hashing_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🗂️", "Hash Tables & Sets",
      "Trade memory for time: a hash function turns a key into an array index, giving O(1) average lookup, insert and delete. The single most useful tool for removing an inner loop.",
      c("Hash Function", "Collisions", "Load Factor", "Frequency Map", "Complement Lookup")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Inside a Hash Table — insert keys one at a time", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(5, textInput(ns("keys"), "Keys to insert (in order):", "cat,dog,act,bird,god,emu,tac,owl")),
              column(3, sliderInput(ns("m"), "Buckets:", min = 5, max = 13, value = 7, step = 1)),
              column(4, radioButtons(ns("strategy"), "Collision strategy:", c("Separate chaining" = "chain", "Linear probing" = "probe")))
            ),
            stepper_ui(ns, "ht"),
            uiOutput(ns("ht_viz")),
            legend_row(c("just placed" = COL$pri, "stored" = COL$soft, "collision / probed slot" = COL$err))
          ),
          box(title = "Table Statistics", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("ht_kpi")),
            callout("This demo hashes a string by <b>summing its character codes</b>, then takes the remainder mod the bucket count. Notice that anagrams (<code>cat</code>, <code>act</code>, <code>tac</code>) always collide — a weak hash. Real hash functions also mix in character <i>position</i>.", "warn"),
            callout("Try 7 buckets vs 13: a prime bucket count spreads keys more evenly, and more buckets means a lower load factor.", "tip")
          )
        ),
        fluidRow(
          box(title = "Why tables resize: cost vs load factor", status = "primary", solidHeader = TRUE, width = 6,
            plotlyOutput(ns("lf_plot"), height = "290px"),
            hint("Load factor α = stored keys ÷ buckets. Open addressing degrades sharply past ~0.7, which is why Java's HashMap resizes at 0.75 and Python's dict at ⅔.")
          ),
          box(title = "Two Sum — the complement lookup", status = "primary", solidHeader = TRUE, width = 6,
            fluidRow(
              column(8, textInput(ns("ts_arr"), "Array:", "11,2,15,7,4,9")),
              column(4, numericInput(ns("ts_target"), "Target:", 13))
            ),
            stepper_ui(ns, "ts"),
            uiOutput(ns("ts_viz"))
          )
        ),
        fluidRow(
          box(title = "Frequency Map", status = "primary", solidHeader = TRUE, width = 6,
            fluidRow(
              column(8, textInput(ns("fq_text"), "Text:", "she sells sea shells by the sea shore")),
              column(4, radioButtons(ns("fq_mode"), "Count:", c("Letters" = "char", "Words" = "word"), inline = TRUE))
            ),
            plotlyOutput(ns("fq_plot"), height = "250px")
          ),
          box(title = "Group Anagrams — choosing the right key", status = "primary", solidHeader = TRUE, width = 6,
            textInput(ns("ga_words"), "Words:", "eat,tea,tan,ate,nat,bat,tab,ant"),
            uiOutput(ns("ga_viz")),
            hint("The trick is a <b>canonical key</b>: any two anagrams share the same sorted letters, so they land in the same bucket. Designing the key is usually the whole problem.")
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("'Have I seen this before?' → hash set.",
                   "'How many times?' or 'where was it?' → hash map of counts or indices.",
                   "Looking for a <b>partner</b> value (complement, prefix sum − k) → store what you have seen, look up what you need.",
                   "Group things that are 'equivalent' → map from a canonical key to a list."),
          pitfalls = c("Using a mutable object (list) as a key — keys must be hashable; use a tuple or string.",
                       "Assuming order: only Python 3.7+ dicts keep insertion order; sets never do.",
                       "Forgetting the worst case is O(n) per operation when many keys collide.",
                       "Counting a value's own index as its partner in Two Sum — check the map <b>before</b> inserting."),
          tips = c("When your brute force is 'for each element, scan for a match', a hash map almost always makes it O(n).",
                   "State the space cost: the usual trade is O(n) extra memory for a factor-of-n speed-up.",
                   "Know the alternative: if sorted order matters (range queries, floor / ceiling), use a balanced tree at O(log n).")
        ),
        fluidRow(
          box(title = "Operation Costs", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Operation = c("Insert", "Lookup", "Delete", "Iterate all", "Min / max / sorted order"),
              Average = c("O(1)", "O(1)", "O(1)", "O(n)", "O(n) / O(n log n)"),
              Worst = c("O(n)", "O(n)", "O(n)", "O(n)", "—"),
              stringsAsFactors = FALSE)),
            callout("<b>Resizing is amortised O(1):</b> when α passes the threshold the table doubles and every key is rehashed — O(n) once, paid for by the n cheap inserts before it.", "info")
          ),
          box(title = "Hash Map vs the Alternatives", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Structure = c("Hash map / set", "Balanced BST (TreeMap)", "Sorted array", "Direct-address array"),
              Lookup = c("O(1) avg", "O(log n)", "O(log n)", "O(1)"),
              Insert = c("O(1) avg", "O(log n)", "O(n)", "O(1)"),
              Ordered = c("No", "Yes", "Yes", "By index"),
              Use.when = c("Default choice", "Need floor / ceiling / range", "Static data, many searches", "Keys are small integers (e.g. 26 letters)"),
              stringsAsFactors = FALSE)),
            callout("<b>Array as hash map:</b> for lowercase letters use <code>count = [0] * 26</code> and index with <code>ord(ch) - ord('a')</code>. Faster and simpler than a dict.", "tip")
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4,
                dsa_code(
'def groupAnagrams(strs):
    groups = defaultdict(list)
    for s in strs:
        key = "".join(sorted(s))    # canonical form
        groups[key].append(s)
    return list(groups.values())', "Group by canonical key"),
                dsa_code(
'def isAnagram(s, t):
    return Counter(s) == Counter(t)', "Compare frequency maps")
              ),
              column(4,
                dsa_code(
'def longestConsecutive(nums):
    s = set(nums)
    best = 0
    for x in s:
        if x - 1 not in s:          # x starts a run
            y = x
            while y + 1 in s:
                y += 1
            best = max(best, y - x + 1)
    return best', "Longest consecutive run — O(n)"),
                callout("Only numbers with no predecessor start a run, so each number is visited at most twice → O(n), not O(n²).", "info")
              ),
              column(4,
                dsa_code(
'def topKFrequent(nums, k):
    count = Counter(nums)
    buckets = [[] for _ in range(len(nums) + 1)]
    for x, c in count.items():
        buckets[c].append(x)        # index = frequency
    out = []
    for c in range(len(buckets) - 1, 0, -1):
        out.extend(buckets[c])
        if len(out) >= k:
            return out[:k]', "Top-K by bucket sort — O(n)")
              )
            )
          )
        )
      ),

      practice = practice_tab(ns, "hashing",
        "Knuth, D. E. (1998). The Art of Computer Programming, Vol. 3: Sorting and Searching (2nd ed.) — §6.4 hashing and the probe-count formulas.",
        "Cormen, Leiserson, Rivest & Stein (2022). Introduction to Algorithms (4th ed.) — ch. 11.",
        "Hettinger, R. (2017). Modern Python Dictionaries — PyCon talk on the compact dict design.")
    )
  )
}

hashing_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    hfun <- function(key, m) sum(utf8ToInt(key)) %% m

    # ── Hash table simulator ─────────────────────────────────────────────────
    ht_steps <- reactive({
      keys <- trimws(strsplit(input$keys %||% "", ",")[[1]]); keys <- unique(keys[nzchar(keys)])
      m <- input$m; req(m)
      validate(need(length(keys) >= 1, "Enter at least one key."), need(length(keys) <= 14, "Use at most 14 keys."))
      probe <- input$strategy == "probe"
      validate(need(!probe || length(keys) <= m, "Linear probing cannot hold more keys than buckets — add buckets or remove keys."))
      table <- vector("list", m); coll <- 0; probes_total <- 0
      steps <- list(list(table = table, hit = NA, tried = integer(0), n = 0, coll = 0, probes = 0,
        msg = sprintf("An empty table with %d buckets. Each key is hashed to a bucket index in 0..%d.", m, m - 1)))
      for (k in seq_along(keys)) {
        key <- keys[k]; h <- hfun(key, m); codes <- sum(utf8ToInt(key)); tried <- integer(0)
        if (!probe) {
          clash <- length(table[[h + 1]]) > 0
          table[[h + 1]] <- c(table[[h + 1]], key); coll <- coll + clash; probes_total <- probes_total + length(table[[h + 1]])
          msg <- sprintf("hash(<b>%s</b>) = %d mod %d = <b>%d</b>. %s", key, codes, m, h,
                         if (clash) sprintf("Bucket %d is occupied → <b>collision</b>; append to its chain (now length %d).", h, length(table[[h + 1]])) else "Bucket is free → store.")
          pos <- h
        } else {
          pos <- h
          while (length(table[[pos + 1]]) > 0) { tried <- c(tried, pos); pos <- (pos + 1) %% m }
          table[[pos + 1]] <- key; coll <- coll + (length(tried) > 0); probes_total <- probes_total + length(tried) + 1
          msg <- sprintf("hash(<b>%s</b>) = %d mod %d = <b>%d</b>. %s", key, codes, m, h,
                         if (length(tried)) sprintf("Occupied → probe forward past %s and store at <b>%d</b> (%d probes).", paste(tried, collapse = ", "), pos, length(tried) + 1) else "Slot is free → store.")
        }
        steps[[length(steps) + 1]] <- list(table = table, hit = pos, key = key, tried = tried, n = k, coll = coll, probes = probes_total, msg = msg)
      }
      steps
    })
    ht <- stepper_server(input, output, session, "ht", ht_steps)
    output$ht_viz <- renderUI({
      s <- ht$cur(); m <- length(s$table)
      rows <- lapply(seq_len(m), function(i) {
        items <- s$table[[i]]
        tags$div(class = "lane", style = "margin-top:4px; min-height:40px;",
          tags$span(class = "lane-lab", style = paste0("min-width:36px;", if ((i - 1) %in% s$tried) "color:#ef4444;" else ""), sprintf("[%d]", i - 1)),
          if (length(items) == 0) tags$span(class = "vempty", "—")
          else lapply(seq_along(items), function(j) tagList(
            tags$span(class = paste("vnode sm", if (!is.na(s$hit) && s$hit == i - 1 && items[j] == s$key) "active" else if ((i - 1) %in% s$tried) "bad" else "visited"), items[j]),
            if (j < length(items)) tags$span(class = "varrow", style = "font-size:13px;", "→")))
        )
      })
      tagList(rows, explain(s$msg))
    })
    output$ht_kpi <- renderUI({
      s <- ht$cur(); m <- length(s$table); a <- s$n / m
      longest <- max(0, vapply(s$table, length, integer(1)))
      kpi_row(kpi(sprintf("%.2f", a), "load factor α", if (a > 0.75) COL$err else COL$ok),
              kpi(s$coll, "collisions", COL$warn),
              kpi(if (s$n) sprintf("%.1f", s$probes / s$n) else "0", "avg probes / key", COL$pri),
              if (input$strategy == "chain") kpi(longest, "longest chain", COL$sec))
    })

    # ── Load factor curves ───────────────────────────────────────────────────
    output$lf_plot <- renderPlotly({
      a <- seq(0.02, 0.95, by = 0.01)
      plot_ly(x = a, height = 290) %>%
        add_trace(y = 1 + a / 2, type = "scatter", mode = "lines", name = "Chaining — successful search", line = list(color = COL$ok, width = 3)) %>%
        add_trace(y = 0.5 * (1 + 1 / (1 - a)), type = "scatter", mode = "lines", name = "Linear probing — successful", line = list(color = COL$warn, width = 3)) %>%
        add_trace(y = 0.5 * (1 + 1 / (1 - a)^2), type = "scatter", mode = "lines", name = "Linear probing — unsuccessful / insert", line = list(color = COL$err, width = 3)) %>%
        dsa_layout(xt = "load factor α", yt = "expected probes", legend = TRUE) %>%
        layout(yaxis = list(range = c(0, 20)),
               shapes = list(list(type = "line", x0 = 0.75, x1 = 0.75, y0 = 0, y1 = 20, line = list(color = COL$mute, dash = "dot", width = 2))),
               annotations = list(list(x = 0.75, y = 18.5, text = "typical resize threshold", showarrow = FALSE, xanchor = "right", font = list(size = 11, color = COL$mute))))
    })

    # ── Two Sum ──────────────────────────────────────────────────────────────
    ts_arr <- reactive({
      v <- parse_ints(input$ts_arr, 12)
      validate(need(length(v) >= 2, "Enter at least two integers."))
      v
    })
    ts_steps <- reactive({
      a <- ts_arr(); t <- input$ts_target
      validate(need(!is.null(t) && !is.na(t), "Enter a target."))
      seen <- integer(0); idx <- integer(0)
      steps <- list(list(i = 0, seen = seen, idx = idx, hit = NA, msg = "Walk the array once. For each value, ask the map: <i>have I already seen the number that completes the target?</i>"))
      found <- FALSE
      for (i in seq_along(a)) {
        comp <- t - a[i]; j <- match(comp, seen)
        if (!is.na(j)) {
          steps[[length(steps) + 1]] <- list(i = i, seen = seen, idx = idx, hit = idx[j],
            msg = sprintf("x = %d needs %s − %d = <b>%s</b>. It <b>is</b> in the map at index %d → answer [%d, %d].", a[i], t, a[i], comp, idx[j] - 1, idx[j] - 1, i - 1))
          found <- TRUE; break
        }
        steps[[length(steps) + 1]] <- list(i = i, seen = c(seen, a[i]), idx = c(idx, i), hit = NA,
          msg = sprintf("x = %d needs <b>%s</b>. Not in the map yet → remember %d ↦ index %d and move on.", a[i], comp, a[i], i - 1))
        seen <- c(seen, a[i]); idx <- c(idx, i)
      }
      if (!found) steps[[length(steps) + 1]] <- list(i = length(a) + 1, seen = seen, idx = idx, hit = NA, msg = "Reached the end — <b>no pair</b> sums to the target.")
      steps
    })
    ts <- stepper_server(input, output, session, "ts", ts_steps)
    output$ts_viz <- renderUI({
      a <- ts_arr(); s <- ts$cur()
      cls <- ifelse(seq_along(a) < s$i, "visited", "")
      if (s$i >= 1 && s$i <= length(a)) cls[s$i] <- "active"
      if (!is.na(s$hit)) cls[c(s$hit, s$i)] <- "found"
      tagList(vrow(a, cls, ptr = list(x = s$i)),
              lane("map value↦idx", if (length(s$seen)) paste0(s$seen, "↦", s$idx - 1) else character(0), "frontier", "empty"),
              explain(s$msg))
    })

    # ── Frequency map ────────────────────────────────────────────────────────
    output$fq_plot <- renderPlotly({
      txt <- tolower(input$fq_text %||% "")
      tok <- if (input$fq_mode == "char") strsplit(gsub("[^a-z]", "", txt), "")[[1]] else strsplit(trimws(txt), "\\s+")[[1]]
      tok <- tok[nzchar(tok)]
      validate(need(length(tok) >= 1, "Type some text."))
      f <- sort(table(tok), decreasing = TRUE); f <- head(f, 15)
      plot_ly(x = factor(names(f), levels = names(f)), y = as.integer(f), type = "bar", height = 250,
              marker = list(color = COL$pri), text = as.integer(f), textposition = "outside") %>%
        dsa_layout(title = sprintf("%d tokens, %d distinct — built in one O(n) pass", length(tok), length(unique(tok))), yt = "count")
    })

    # ── Group anagrams ───────────────────────────────────────────────────────
    output$ga_viz <- renderUI({
      w <- tolower(trimws(strsplit(input$ga_words %||% "", ",")[[1]])); w <- w[nzchar(w)]
      validate(need(length(w) >= 1, "Enter some words."))
      w <- head(w, 16)
      key <- vapply(w, function(x) paste(sort(strsplit(x, "")[[1]]), collapse = ""), character(1))
      groups <- split(w, factor(key, levels = unique(key)))
      tagList(lapply(names(groups), function(k)
        tags$div(class = "lane", tags$span(class = "lane-lab", style = "text-transform:none;", paste0("key \"", k, "\"")),
                 lapply(groups[[k]], function(x) tags$span(class = "vnode sm visited", x)))),
        explain(sprintf("%d words → <b>%d groups</b>. Cost: O(n · k log k) for n words of length k (the sort builds the key).", length(w), length(groups))))
    })

    quiz_server(input, output, session, topic = "hashing", progress = progress, questions = list(
      list(q = "What makes hash-table lookup O(1) on average?",
           opts = c("Keys are kept sorted", "The hash function computes the bucket index directly from the key", "It uses binary search on buckets", "It caches recent lookups"), ans = 2,
           why = "No searching is needed: the key itself tells you where to look. Collisions add a small constant when the load factor is bounded."),
      list(q = "A table has 12 keys in 16 buckets. Its load factor is…",
           opts = c("0.25", "0.75", "1.33", "4"), ans = 2,
           why = "α = n / m = 12 / 16 = 0.75 — right at the usual resize threshold."),
      list(q = "In Two Sum, why check the map <b>before</b> inserting the current number?",
           opts = c("It is faster", "So an element is never paired with itself", "Dictionaries reject duplicates", "It keeps the map sorted"), ans = 2,
           why = "With target 6 and value 3, inserting first would let 3 match itself. Checking first only matches earlier indices."),
      list(q = "Which key correctly groups anagrams?",
           opts = c("The word's length", "The word's first letter", "The word's letters sorted", "The word reversed"), ans = 3,
           why = "Two words are anagrams exactly when their sorted letters are identical. A 26-count tuple works too and avoids the sort."),
      list(q = "When is a balanced BST a better choice than a hash map?",
           opts = c("When you need the fastest lookup", "When you need keys in sorted order or nearest-key queries", "When keys are strings", "When memory is unlimited"), ans = 2,
           why = "Hash maps give no ordering. Trees support floor, ceiling and range queries in O(log n).")
    ))
  })
}
