# modules/mod_patterns.R — Pattern Finder, problem bank and study plan

PATTERN_GUIDE <- list(
  list(clue = "The input array is sorted (or can be sorted cheaply)", pattern = "Binary search / two pointers", tab = "arrays",
       why = "Order lets you discard half the candidates per comparison, or walk two indices toward each other without missing a pair.", cost = "O(log n) or O(n)", ex = "#33, #15, #11, #704"),
  list(clue = "Longest / shortest contiguous subarray or substring with a condition", pattern = "Sliding window", tab = "arrays",
       why = "Grow the window on the right; shrink from the left while the condition is violated. Each index enters and leaves once.", cost = "O(n)", ex = "#3, #76, #209, #424"),
  list(clue = "Sum of a range, or count subarrays with a given sum", pattern = "Prefix sums (+ hash map)", tab = "arrays",
       why = "Any range sum is a difference of two prefix sums; store prefixes seen so far to find a matching partner in O(1).", cost = "O(n)", ex = "#560, #238, #303"),
  list(clue = "Have I seen this before? / count occurrences / find a partner value", pattern = "Hash map or hash set", tab = "hashing",
       why = "Constant-time lookup replaces the inner scan of a brute-force double loop.", cost = "O(n) time, O(n) space", ex = "#1, #49, #128, #217"),
  list(clue = "Matching pairs, nested structure, or undo the most recent thing", pattern = "Stack", tab = "stacks",
       why = "The most recently opened item must be closed first — exactly LIFO.", cost = "O(n)", ex = "#20, #150, #394"),
  list(clue = "Next greater / smaller element, spans, histogram areas", pattern = "Monotonic stack", tab = "stacks",
       why = "Keep unresolved items in sorted order; a new element resolves everything it beats in one sweep.", cost = "O(n)", ex = "#739, #496, #84"),
  list(clue = "Linked list: cycle, middle, k-th from the end", pattern = "Fast and slow pointers", tab = "linkedlists",
       why = "Two pointers at different speeds (or a fixed gap) reveal structure without extra memory.", cost = "O(n) time, O(1) space", ex = "#141, #142, #876, #19"),
  list(clue = "Top k, k-th largest, or repeatedly take the smallest / largest", pattern = "Heap (priority queue)", tab = "heaps",
       why = "A heap of size k keeps only the best candidates and exposes the weakest of them at the root.", cost = "O(n log k)", ex = "#215, #347, #23, #295"),
  list(clue = "Tree problem: a node's answer depends on its children", pattern = "DFS (postorder recursion)", tab = "trees",
       why = "Solve both subtrees first, then combine at the node — return what the parent needs.", cost = "O(n) time, O(h) space", ex = "#104, #543, #124"),
  list(clue = "Tree or graph: process level by level, or fewest steps", pattern = "BFS with a queue", tab = "graphs",
       why = "BFS explores in rings of increasing distance, so the first time it reaches a node is via a shortest path.", cost = "O(V + E)", ex = "#102, #994, #127"),
  list(clue = "Grid of cells: islands, regions, flood fill", pattern = "Grid DFS / BFS", tab = "graphs",
       why = "Treat each cell as a node with up to four neighbours; mark visited cells as you go.", cost = "O(rows × cols)", ex = "#200, #695, #417"),
  list(clue = "Tasks with prerequisites / a valid ordering", pattern = "Topological sort", tab = "graphs",
       why = "Repeatedly emit a node with no remaining prerequisites; leftovers mean a cycle.", cost = "O(V + E)", ex = "#207, #210, #269"),
  list(clue = "Cheapest path with weighted edges", pattern = "Dijkstra (min-heap)", tab = "graphs",
       why = "Always settle the closest unsettled node; with non-negative weights its distance is final.", cost = "O((V + E) log V)", ex = "#743, #1631, #787"),
  list(clue = "Are these connected? / merge groups / detect a cycle as edges arrive", pattern = "Union-Find", tab = "advanced",
       why = "Near-constant-time find and union track components incrementally.", cost = "O(α(n)) per operation", ex = "#547, #684, #721"),
  list(clue = "Words sharing prefixes / autocomplete / many words on a board", pattern = "Trie", tab = "advanced",
       why = "Shared prefixes share nodes, so a prefix query costs only the prefix length.", cost = "O(L) per word", ex = "#208, #211, #212"),
  list(clue = "Generate ALL subsets / permutations / combinations / valid boards", pattern = "Backtracking", tab = "recursion",
       why = "DFS over a decision tree: choose, explore, un-choose — pruning branches that already break a rule.", cost = "Exponential (output-sized)", ex = "#78, #46, #39, #51"),
  list(clue = "Count the ways / minimum cost / is it possible, with choices at each step", pattern = "Dynamic programming", tab = "dp",
       why = "The same subproblems recur; define a state, a transition and a base case, and compute each state once.", cost = "states × transitions", ex = "#70, #322, #1143, #416"),
  list(clue = "Schedule intervals / cover / minimise resources by a simple rule", pattern = "Greedy (sort then scan)", tab = "greedy",
       why = "A locally best choice (e.g. earliest finish) can be exchanged into any optimal solution.", cost = "O(n log n)", ex = "#435, #452, #55, #763"),
  list(clue = "Minimise the maximum / smallest value that satisfies a yes-no test", pattern = "Binary search on the answer", tab = "sorting",
       why = "If feasibility is monotonic in the candidate value, search the value range instead of the input.", cost = "O(n log range)", ex = "#875, #1011, #410"),
  list(clue = "Every element appears twice except one / O(1) extra space with integers", pattern = "Bit manipulation (XOR)", tab = "bits",
       why = "XOR cancels equal pairs, leaving the odd one out without any extra memory.", cost = "O(n) time, O(1) space", ex = "#136, #268, #191"),
  list(clue = "Design a class with O(1) operations (cache, random set, min stack)", pattern = "Combine two structures", tab = "systemdesign",
       why = "Pair a hash map (for lookup) with a list, array or second stack (for order).", cost = "O(1) per operation", ex = "#146, #380, #155")
)

patterns_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🧭", "Pattern Finder & Study Plan",
      "Interview problems are variations on about twenty patterns. The skill is recognising which one you are looking at — from the wording, the constraints and the shape of the input.",
      c("Clue → Pattern", "Problem Bank", "Study Plan", "Interview Method")),

    tags$div(class = "topic-tabs",
      tabsetPanel(id = ns("tabs"), type = "pills",
        tabPanel("🧭 Pattern Finder",
          fluidRow(
            box(title = "What does the problem say?", status = "primary", solidHeader = TRUE, width = 5,
              hint("Pick the clue that best matches the problem statement."),
              radioButtons(ns("clue"), NULL, choiceNames = lapply(PATTERN_GUIDE, function(p) p$clue), choiceValues = seq_along(PATTERN_GUIDE), selected = 2)
            ),
            box(title = "Recommended approach", status = "success", solidHeader = TRUE, width = 7,
              uiOutput(ns("rec")),
              tags$hr(),
              tags$div(class = "code-title", "The decision flow at a glance"),
              cplx_table(data.frame(
                Ask = c("1. What is the input shape?", "2. What is being asked?", "3. What do the constraints allow?", "4. What is the brute force?", "5. What repeats?"),
                Because = c("Sorted array, string, tree, graph, grid, intervals — each has a default toolbox",
                            "All solutions → backtracking · best / count → DP or greedy · existence → hashing / search",
                            "n ≤ 20 exponential is fine · n ≤ 10⁵ needs O(n log n) · see the Big-O tab",
                            "Name its cost, then name the term to remove",
                            "Repeated scans → hash map or prefix sums · repeated subproblems → DP · repeated min / max → heap"),
                stringsAsFactors = FALSE))
            )
          )
        ),
        tabPanel("📚 Problem Bank",
          fluidRow(
            box(title = "Filter", status = "primary", solidHeader = TRUE, width = 3,
              checkboxGroupInput(ns("f_level"), "Difficulty:", c("Easy", "Medium", "Hard"), selected = c("Easy", "Medium", "Hard")),
              selectInput(ns("f_topic"), "Topic:", c("All topics" = "all", setNames(names(TOPICS), TOPICS))),
              selectInput(ns("f_company"), "Reported at:", c("Any company" = "all", "Meta" = "Meta", "Google" = "Google", "Both Meta and Google" = "both")),
              checkboxInput(ns("f_inapp"), "Only problems with the in-app judge", FALSE),
              hint("Company tags come from community-reported interview lists — indicative only; companies do not publish their question banks."),
              uiOutput(ns("bank_kpi"))
            ),
            box(title = "All curated problems — searchable", status = "success", solidHeader = TRUE, width = 9,
              DTOutput(ns("bank")))
          ),
          fluidRow(
            box(title = "Coverage by topic and difficulty", status = "info", solidHeader = TRUE, width = 12,
              plotlyOutput(ns("cover"), height = "300px"))
          )
        ),
        tabPanel("🗓️ Study Plan",
          fluidRow(
            box(title = "Six-week plan", status = "primary", solidHeader = TRUE, width = 7,
              cplx_table(data.frame(
                Week = c("1", "2", "3", "4", "5", "6"),
                Focus = c("Big-O · Arrays & Strings · Hash Tables", "Linked Lists · Stacks & Queues · Sorting & Binary Search", "Trees & BSTs · Heaps",
                          "Graphs · Tries & Union-Find", "Recursion & Backtracking · Dynamic Programming", "Greedy · Bit Manipulation · System Design · mock interviews"),
                Goal = c("Recognise two-pointer, window, prefix-sum and hash-map problems on sight", "Pointer manipulation without bugs; monotonic stack; binary search on answer",
                         "All four traversals from memory; top-K and two-heaps patterns", "BFS / DFS / topo sort / Dijkstra templates; union-find from memory",
                         "Write the backtracking template; define state and transition for DP", "Argue greedy correctness; timed mixed sets; one design question per day"),
                Problems = c("12–15", "12–15", "10–12", "10–12", "12–15", "10 + mocks"),
                stringsAsFactors = FALSE)),
              callout("<b>Per topic:</b> play with the visualiser until you can predict each step → read the Understand tab → take the quiz → solve the Easy problems, then Mediums. Revisit anything you could not solve after 3 days and again after a week.", "tip")
            ),
            box(title = "How to work a problem in the interview", status = "info", solidHeader = TRUE, width = 5,
              cplx_table(data.frame(
                Step = c("Understand", "Match", "Plan", "Implement", "Review", "Evaluate"),
                Do = c("Restate the problem; ask about size, duplicates, negatives, empty input; write 2 examples",
                       "Name the pattern and say why it fits",
                       "Describe the approach and its complexity before coding; get a nod",
                       "Write clean code, narrating as you go; use helper functions",
                       "Trace an example by hand; check edge cases",
                       "State time and space; mention trade-offs and what you would improve"),
                stringsAsFactors = FALSE)),
              callout("Silence is the most common failure mode. Thinking aloud lets the interviewer steer you and gives credit for reasoning even if the code is unfinished.", "warn")
            )
          ),
          fluidRow(
            box(title = "Python reminders for LeetCode", status = "warning", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6,
                  callout("<b>Indentation is syntax.</b> Inside a LeetCode class, the method line sits at 4 spaces and its body at 8; a nested block at 12. Pasting a body at column 0 gives <code>IndentationError</code> or silently puts code outside the method.", "warn"),
                  dsa_code(
'class Solution(object):
    def solve(self, nums):          # 4 spaces
        best = 0                    # 8 spaces
        for x in nums:              # 8 spaces
            if x > best:            # 12 spaces
                best = x            # 16 spaces
        return best                 # 8 spaces')),
                column(6,
                  callout("<b>Python vs Python3 on LeetCode.</b> If the stub reads <code>class Solution(object)</code> you are in Python 2 mode: type hints on nested helper functions are a <code>SyntaxError</code>. Either switch the language to Python3 or drop the annotations.", "info"),
                  cplx_table(data.frame(
                    Need = c("Queue / deque", "Min-heap", "Counter", "Default dict", "Memoise", "Sorted insert position", "Infinity"),
                    Use = c("collections.deque", "heapq", "collections.Counter", "collections.defaultdict(list)", "functools.lru_cache(None)", "bisect.bisect_left", "float('inf')"),
                    stringsAsFactors = FALSE)))
              )
            )
          )
        ),
        tabPanel("📝 Name That Pattern",
          fluidRow(
            box(title = "Pattern recognition quiz", status = "warning", solidHeader = TRUE, width = 7, quiz_ui(ns)),
            box(title = "Why this matters", status = "info", solidHeader = TRUE, width = 5,
              callout("Most of the difficulty in a 'medium' is in the first three minutes: mapping the statement to a known pattern. Once the pattern is named, the code is usually a template you already know.", "info"),
              callout("After each problem you solve, write one line: <i>clue → pattern</i>. That list becomes your personal Pattern Finder.", "tip"))
          )
        )
      )
    )
  )
}

patterns_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    output$rec <- renderUI({
      p <- PATTERN_GUIDE[[as.integer(input$clue %||% 1)]]
      tagList(
        kpi_row(kpi(p$pattern, "pattern", COL$pri), kpi(p$cost, "typical cost", COL$ok)),
        callout(paste0("<b>Why it fits.</b> ", p$why), "info"),
        callout(paste0("<b>Try it on:</b> ", p$ex), "tip"),
        tags$button(class = "btn btn-dsa", onclick = js_set("goto_tab", sprintf("'%s'", p$tab)),
                    sprintf("Open %s →", if (p$tab %in% names(TOPICS)) TOPICS[[p$tab]] else p$tab))
      )
    })

    bank <- reactive({
      d <- PROBLEMS[PROBLEMS$level %in% input$f_level, ]
      if (!is.null(input$f_topic) && input$f_topic != "all") d <- d[d$topic == input$f_topic, ]
      if (!is.null(input$f_company) && input$f_company != "all") {
        has <- function(co) grepl(co, d$companies, fixed = TRUE)
        d <- d[if (input$f_company == "both") has("Meta") & has("Google") else has(input$f_company), ]
      }
      if (isTRUE(input$f_inapp)) d <- d[paste0("lc", d$num) %in% PRACTICE_IDS, ]
      d
    })
    output$bank_kpi <- renderUI({
      d <- bank()
      kpi_row(kpi(nrow(d), "problems", COL$pri), kpi(length(unique(d$pattern)), "patterns", COL$acc))
    })
    output$bank <- renderDT({
      d <- bank()
      out <- data.frame(
        `#` = d$num,
        Problem = sprintf("<a href='%s' target='_blank'>%s</a>", d$url, d$title),
        Difficulty = sprintf("<span class='lc-badge badge-%s'>%s</span>", tolower(d$level), d$level),
        Topic = unname(TOPICS[d$topic]), Pattern = d$pattern, `Reported at` = d$companies,
        `In app` = ifelse(paste0("lc", d$num) %in% PRACTICE_IDS,
                          sprintf("<button class='btn-solve' onclick=\"Shiny.setInputValue('open_problem','lc%d',{priority:'event'})\">▶ Solve</button>", d$num), ""),
        check.names = FALSE, stringsAsFactors = FALSE)
      datatable(out, escape = FALSE, rownames = FALSE, selection = "none",
                options = list(pageLength = 12, lengthMenu = c(12, 25, 50, 200), dom = "frtip", order = list(list(3, "asc"))))
    })
    output$cover <- renderPlotly({
      tab <- table(factor(TOPICS[PROBLEMS$topic], levels = TOPICS), factor(PROBLEMS$level, levels = c("Easy", "Medium", "Hard")))
      colr <- c(Easy = COL$ok, Medium = COL$warn, Hard = COL$err)
      p <- plot_ly(height = 300)
      for (lv in colnames(tab)) p <- add_bars(p, x = rownames(tab), y = as.integer(tab[, lv]), name = lv, marker = list(color = colr[[lv]]))
      p %>% dsa_layout(yt = "problems", legend = TRUE) %>%
        layout(barmode = "stack", xaxis = list(categoryorder = "array", categoryarray = rownames(tab), tickangle = -25), margin = list(b = 90))
    })

    quiz_server(input, output, session, topic = "patterns", progress = progress, questions = list(
      list(q = "\"Given a string, find the length of the longest substring with at most k distinct characters.\"",
           opts = c("Dynamic programming", "Sliding window", "Backtracking", "Binary search"), ans = 2,
           why = "Contiguous range + a constraint that only worsens as the window grows = expand right, shrink left."),
      list(q = "\"Return the k most frequent words in a list of one million words.\"",
           opts = c("Sort everything", "Hash map of counts + heap of size k", "Trie", "Union-Find"), ans = 2,
           why = "Count with a map, then keep only k candidates in a heap: O(n log k). Full sorting works but does more than needed."),
      list(q = "\"Given a list of course prerequisites, return an order in which all courses can be taken.\"",
           opts = c("Dijkstra", "Topological sort", "Sliding window", "Greedy by deadline"), ans = 2,
           why = "Dependencies between tasks form a directed graph; a valid order is a topological order (and a cycle means impossible)."),
      list(q = "\"In how many distinct ways can you climb n stairs taking 1 or 2 steps?\"",
           opts = c("Backtracking", "Dynamic programming", "Greedy", "Two pointers"), ans = 2,
           why = "'How many ways' with overlapping subproblems: ways(n) = ways(n−1) + ways(n−2). Backtracking would enumerate them all, exponentially."),
      list(q = "\"Return all possible letter combinations a phone number could represent.\"",
           opts = c("Dynamic programming", "Backtracking", "Hash map", "Heap"), ans = 2,
           why = "'All possible' means the output itself is exponential — enumerate with choose / explore / un-choose."),
      list(q = "\"Ships must deliver packages within D days; find the least capacity that works.\"",
           opts = c("Greedy only", "Binary search on the answer", "Topological sort", "Trie"), ans = 2,
           why = "If capacity c works then every larger capacity works: a monotonic yes/no test, so binary-search the capacity."),
      list(q = "\"Given edges arriving one at a time, report the first edge that creates a cycle.\"",
           opts = c("BFS from every node", "Union-Find", "Monotonic stack", "Prefix sums"), ans = 2,
           why = "An edge closes a cycle exactly when both ends are already in the same component — a union-find check.")
    ))
  })
}
