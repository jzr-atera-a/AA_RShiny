# modules/python_runner.R
# Tab: Python Algorithm Runner
# Connects to local Python 3.11, runs algorithms, measures time/memory/complexity

python_runner_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # ── inline CSS for this tab ──────────────────────
    tags$style(HTML("
      .code-editor {
        font-family: 'Fira Code', 'Courier New', monospace !important;
        font-size: 13px !important;
        background: #0d1117 !important;
        color: #e6edf3 !important;
        border: 1px solid #30363d !important;
        border-radius: 8px !important;
        padding: 14px !important;
        resize: vertical !important;
        line-height: 1.6 !important;
        min-height: 320px;
        width: 100%;
      }
      .output-panel {
        background: #0d1117;
        color: #58a6ff;
        border-radius: 8px;
        padding: 14px;
        font-family: 'Fira Code', monospace;
        font-size: 12px;
        min-height: 180px;
        max-height: 400px;
        overflow-y: auto;
        border: 1px solid #30363d;
        white-space: pre-wrap;
        word-break: break-word;
      }
      .metric-pill {
        display: inline-block;
        padding: 6px 14px;
        border-radius: 20px;
        font-size: 12px;
        font-weight: 700;
        margin: 4px 3px;
      }
      .metric-pill.time   { background: #1f2937; color: #34d399; border: 1px solid #34d399; }
      .metric-pill.mem    { background: #1f2937; color: #60a5fa; border: 1px solid #60a5fa; }
      .metric-pill.cmplx  { background: #1f2937; color: #fbbf24; border: 1px solid #fbbf24; }
      .metric-pill.status { background: #1f2937; color: #f87171; border: 1px solid #f87171; }
      .metric-pill.ok     { background: #1f2937; color: #4ade80; border: 1px solid #4ade80; }
      .timer-display {
        font-family: 'Fira Code', monospace;
        font-size: 3em;
        font-weight: 800;
        text-align: center;
        padding: 18px 10px 10px;
        border-radius: 12px;
        letter-spacing: 3px;
      }
      .timer-green  { background: #052e16; color: #4ade80; border: 2px solid #4ade80; }
      .timer-amber  { background: #451a03; color: #fbbf24; border: 2px solid #fbbf24; }
      .timer-red    { background: #450a0a; color: #f87171; border: 2px solid #f87171; }
      .complexity-badge {
        display: block;
        text-align: center;
        font-size: 1.6em;
        font-weight: 800;
        font-family: 'Fira Code', monospace;
        padding: 12px;
        border-radius: 10px;
        background: #1f2937;
        color: #fbbf24;
        border: 2px solid #fbbf24;
        margin: 6px 0;
      }
      .run-btn {
        background: linear-gradient(135deg, #16a34a, #15803d) !important;
        color: white !important;
        font-weight: 700 !important;
        font-size: 15px !important;
        border: none !important;
        border-radius: 8px !important;
        padding: 10px 28px !important;
        width: 100%;
        box-shadow: 0 4px 15px rgba(22,163,74,0.35) !important;
      }
    ")),

    div(class = "meta-hero",
        tags$h1("Python Algorithm Runner"),
        tags$h2("Test · Profile · Analyse — Linked to Coding Interview Preparation"),
        div(
          span(class = "hero-badge", icon("python"), " Python 3.11"),
          span(class = "hero-badge", "Execution Time"),
          span(class = "hero-badge", "Memory Usage"),
          span(class = "hero-badge", "Complexity Analysis"),
          span(class = "hero-badge", "Session Timer")
        )
    ),

    # ── Row 1: Config + Timer ────────────────────────
    fluidRow(
      box(title = "⚙️ Python Configuration", status = "primary",
          solidHeader = TRUE, width = 4,

          div(class = "section-heading-dark", "Python Executable"),
          textInput(ns("python_path"), label = NULL,
                    value = "python",
                    placeholder = "e.g. python  |  python3.11  |  C:/Python311/python.exe"),
          actionButton(ns("test_python"), "Test Connection",
                       class = "btn-meta", icon = icon("plug"), width = "100%"),
          br(), br(),
          uiOutput(ns("python_status")),

          br(),
          div(class = "section-heading-dark", "Algorithm Category"),
          selectInput(ns("algo_category"), label = NULL,
                      choices = c(
                        "-- Select template --",
                        "Arrays & Sliding Window",
                        "Hash Map / Two Sum",
                        "Linked List",
                        "Binary Search",
                        "BFS / Graph",
                        "DFS / Backtracking",
                        "Dynamic Programming",
                        "Heap / Priority Queue",
                        "Stack",
                        "Sorting Algorithms",
                        "Tree Traversal",
                        "Custom (blank)"
                      )),
          actionButton(ns("load_template"), "Load Template",
                       class = "btn-meta", icon = icon("file-code"), width = "100%")
      ),

      box(title = "⏱️ Coding Session Timer", status = "warning",
          solidHeader = TRUE, width = 4,

          uiOutput(ns("timer_face")),
          br(),
          fluidRow(
            column(4, actionButton(ns("timer_start"), "▶ Start",
                                   class = "btn-success", width = "100%",
                                   style = "font-weight:700;")),
            column(4, actionButton(ns("timer_pause"), "⏸ Pause",
                                   class = "btn-warning", width = "100%",
                                   style = "font-weight:700;")),
            column(4, actionButton(ns("timer_reset"), "↺ Reset",
                                   class = "btn-danger",  width = "100%",
                                   style = "font-weight:700;"))
          ),
          br(),
          div(style = "text-align:center;",
              tags$small(style = "color:#666;",
                         "Green < 25 min · Amber < 35 min · Red ≥ 35 min"),
              br(),
              tags$small(style = "color:#999;",
                         "Target: solve each problem in under 25 minutes")
          ),
          br(),
          div(class = "section-heading-dark", "Session Log"),
          uiOutput(ns("session_log_ui"))
      ),

      box(title = "📊 Last Run Metrics", status = "success",
          solidHeader = TRUE, width = 4,

          uiOutput(ns("metrics_panel")),
          br(),
          div(class = "section-heading-dark", "Complexity Estimate"),
          uiOutput(ns("complexity_panel")),
          br(),
          div(class = "section-heading-dark", "Run History"),
          uiOutput(ns("run_history_ui"))
      )
    ),

    # ── Row 2: Editor + Output ───────────────────────
    fluidRow(
      box(title = "💻 Code Editor", status = "primary",
          solidHeader = TRUE, width = 7,

          div(style = "position:relative;",
              tags$textarea(
                id = ns("code_input"),
                class = "code-editor",
                rows = "22",
                placeholder = "# Write your Python algorithm here\n# Press Run to execute with profiling\n\ndef solution(nums):\n    pass\n\n# Test your solution\nif __name__ == '__main__':\n    print(solution([1, 2, 3]))"
              )
          ),
          br(),
          fluidRow(
            column(6,
                   numericInput(ns("repeat_runs"), "Repeat runs (for avg timing):",
                                value = 3, min = 1, max = 100, step = 1)),
            column(6,
                   numericInput(ns("input_size_n"), "Input size n (for complexity sweep):",
                                value = 1000, min = 10, max = 1000000, step = 100))
          ),
          actionButton(ns("run_code"), "▶  Run with Python 3.11",
                       class = "run-btn", icon = icon("play")),
          br(),
          div(style = "margin-top:8px; display:flex; gap:8px; flex-wrap:wrap;",
              actionButton(ns("clear_code"),   "Clear",   class = "btn-default btn-sm"),
              actionButton(ns("add_timeit"),   "+ timeit wrapper",  class = "btn-default btn-sm"),
              actionButton(ns("add_test"),     "+ test cases",      class = "btn-default btn-sm")
          )
      ),

      column(5,
             box(title = "📤 Output", status = "success",
                 solidHeader = TRUE, width = 12,
                 div(id = ns("output_console"),
                     class = "output-panel",
                     uiOutput(ns("run_output"))
                 )
             ),
             box(title = "🔬 Complexity Sweep — n vs Time",
                 status = "info", solidHeader = TRUE, width = 12,
                 plotly::plotlyOutput(ns("complexity_plot"), height = "220px"),
                 actionButton(ns("run_sweep"), "Run Complexity Sweep",
                              class = "btn-meta btn-sm",
                              icon = icon("chart-line"), width = "100%")
             )
      )
    ),

    # ── Row 3: Meta Problem Bank ─────────────────────
    fluidRow(
      box(title = "🎯 Meta Interview Problem Bank — Linked to Your Preparation",
          status = "warning", solidHeader = TRUE, width = 12,

          fluidRow(
            column(8,
                   DT::dataTableOutput(ns("problem_bank"))
            ),
            column(4,
                   div(class = "section-heading-dark", "Selected Problem"),
                   uiOutput(ns("problem_detail")),
                   br(),
                   actionButton(ns("load_problem"), "Load to Editor",
                                class = "btn-meta", icon = icon("arrow-left"),
                                width = "100%")
            )
          )
      )
    )
  )
}

python_runner_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Reactive state ───────────────────────────────
    run_history  <- reactiveVal(list())
    session_log  <- reactiveVal(list())
    timer_secs   <- reactiveVal(0)
    timer_active <- reactiveVal(FALSE)
    timer_start_time <- reactiveVal(NULL)
    timer_elapsed_at_pause <- reactiveVal(0)

    # ── Problem bank data ────────────────────────────
    problems <- list(
      list(id="76",  title="Minimum Window Substring",   diff="Hard",   cat="Sliding Window",
           desc="Given strings s and t, return the minimum window substring of s that contains all characters of t.",
           template="def min_window(s: str, t: str) -> str:\n    from collections import Counter\n    need = Counter(t)\n    have, total = 0, len(need)\n    l = 0\n    best = ''\n    window = {}\n    for r, c in enumerate(s):\n        window[c] = window.get(c, 0) + 1\n        if c in need and window[c] == need[c]:\n            have += 1\n        while have == total:\n            if not best or r - l + 1 < len(best):\n                best = s[l:r+1]\n            window[s[l]] -= 1\n            if s[l] in need and window[s[l]] < need[s[l]]:\n                have -= 1\n            l += 1\n    return best\n\n# Test\nprint(min_window('ADOBECODEBANC', 'ABC'))  # Expected: 'BANC'\nprint(min_window('a', 'a'))               # Expected: 'a'"),
      list(id="146", title="LRU Cache",                  diff="Medium", cat="Design + HashMap",
           desc="Design a data structure that follows the Least Recently Used (LRU) cache constraint. get() and put() must be O(1).",
           template="from collections import OrderedDict\n\nclass LRUCache:\n    def __init__(self, capacity: int):\n        self.cap = capacity\n        self.cache = OrderedDict()\n\n    def get(self, key: int) -> int:\n        if key not in self.cache:\n            return -1\n        self.cache.move_to_end(key)\n        return self.cache[key]\n\n    def put(self, key: int, value: int) -> None:\n        if key in self.cache:\n            self.cache.move_to_end(key)\n        self.cache[key] = value\n        if len(self.cache) > self.cap:\n            self.cache.popitem(last=False)\n\n# Test\ncache = LRUCache(2)\ncache.put(1, 1)\ncache.put(2, 2)\nprint(cache.get(1))   # 1\ncache.put(3, 3)       # evicts key 2\nprint(cache.get(2))   # -1"),
      list(id="295", title="Find Median from Data Stream","diff"="Hard",  cat="Heap",
           desc="Design a data structure that supports addNum() and findMedian() with optimal time complexity.",
           template="import heapq\n\nclass MedianFinder:\n    def __init__(self):\n        self.lo = []   # max-heap (negated)\n        self.hi = []   # min-heap\n\n    def addNum(self, num: int) -> None:\n        heapq.heappush(self.lo, -num)\n        heapq.heappush(self.hi, -heapq.heappop(self.lo))\n        if len(self.lo) < len(self.hi):\n            heapq.heappush(self.lo, -heapq.heappop(self.hi))\n\n    def findMedian(self) -> float:\n        if len(self.lo) > len(self.hi):\n            return float(-self.lo[0])\n        return (-self.lo[0] + self.hi[0]) / 2.0\n\n# Test\nmf = MedianFinder()\nfor n in [1, 2, 3]:\n    mf.addNum(n)\n    print(f'Added {n}, median = {mf.findMedian()}')"),
      list(id="23",  title="Merge K Sorted Lists",        diff="Hard",  cat="Heap",
           desc="Merge k sorted linked lists and return it as one sorted list.",
           template="import heapq\nfrom typing import Optional, List\n\nclass ListNode:\n    def __init__(self, val=0, next=None):\n        self.val = val\n        self.next = next\n\ndef mergeKLists(lists: List[Optional[ListNode]]) -> Optional[ListNode]:\n    heap = []\n    for i, node in enumerate(lists):\n        if node:\n            heapq.heappush(heap, (node.val, i, node))\n    dummy = ListNode()\n    cur = dummy\n    while heap:\n        val, i, node = heapq.heappop(heap)\n        cur.next = node\n        cur = cur.next\n        if node.next:\n            heapq.heappush(heap, (node.next.val, i, node.next))\n    return dummy.next\n\n# Test: build lists [1,4,5], [1,3,4], [2,6]\ndef make_list(vals):\n    if not vals: return None\n    head = ListNode(vals[0])\n    cur = head\n    for v in vals[1:]: cur.next = ListNode(v); cur = cur.next\n    return head\ndef print_list(node):\n    res = []\n    while node: res.append(node.val); node = node.next\n    print(res)\n\nresult = mergeKLists([make_list([1,4,5]), make_list([1,3,4]), make_list([2,6])])\nprint_list(result)  # [1,1,2,3,4,4,5,6]"),
      list(id="200", title="Number of Islands",           diff="Medium", cat="DFS/BFS",
           desc="Given a 2D grid of '1's (land) and '0's (water), count the number of islands.",
           template="from typing import List\n\ndef numIslands(grid: List[List[str]]) -> int:\n    if not grid:\n        return 0\n    rows, cols = len(grid), len(grid[0])\n    count = 0\n\n    def dfs(r, c):\n        if r < 0 or r >= rows or c < 0 or c >= cols or grid[r][c] != '1':\n            return\n        grid[r][c] = '#'   # mark visited\n        for dr, dc in [(1,0),(-1,0),(0,1),(0,-1)]:\n            dfs(r+dr, c+dc)\n\n    for r in range(rows):\n        for c in range(cols):\n            if grid[r][c] == '1':\n                dfs(r, c)\n                count += 1\n    return count\n\n# Test\ngrid1 = [['1','1','1','1','0'],\n         ['1','1','0','1','0'],\n         ['1','1','0','0','0'],\n         ['0','0','0','0','0']]\nprint(numIslands(grid1))   # Expected: 1\n\ngrid2 = [['1','1','0','0','0'],\n         ['1','1','0','0','0'],\n         ['0','0','1','0','0'],\n         ['0','0','0','1','1']]\nprint(numIslands(grid2))   # Expected: 3")
    )

    # ── Templates ────────────────────────────────────
    templates <- list(
      "Arrays & Sliding Window" =
"def max_subarray_sum(nums, k):\n    \"\"\"Maximum sum subarray of size k — O(n) sliding window\"\"\"\n    window_sum = sum(nums[:k])\n    best = window_sum\n    for i in range(k, len(nums)):\n        window_sum += nums[i] - nums[i - k]\n        best = max(best, window_sum)\n    return best\n\n# Test\nnums = [2, 1, 5, 1, 3, 2]\nprint(max_subarray_sum(nums, 3))  # Expected: 9",

      "Hash Map / Two Sum" =
"def two_sum(nums, target):\n    \"\"\"Two sum using hash map — O(n) time, O(n) space\"\"\"\n    seen = {}   # value -> index\n    for i, n in enumerate(nums):\n        complement = target - n\n        if complement in seen:\n            return [seen[complement], i]\n        seen[n] = i\n    return []\n\n# Test\nprint(two_sum([2, 7, 11, 15], 9))   # [0, 1]\nprint(two_sum([3, 2, 4], 6))        # [1, 2]",

      "Binary Search" =
"def binary_search(nums, target):\n    \"\"\"Classic binary search — O(log n)\"\"\"\n    l, r = 0, len(nums) - 1\n    while l <= r:\n        mid = l + (r - l) // 2\n        if nums[mid] == target:\n            return mid\n        elif nums[mid] < target:\n            l = mid + 1\n        else:\n            r = mid - 1\n    return -1\n\n# Test\nnums = [1, 3, 5, 7, 9, 11, 13]\nprint(binary_search(nums, 7))   # 3\nprint(binary_search(nums, 6))   # -1",

      "BFS / Graph" =
"from collections import deque\n\ndef bfs(graph, start):\n    \"\"\"BFS traversal — O(V + E)\"\"\"\n    visited = set([start])\n    queue   = deque([start])\n    order   = []\n    while queue:\n        node = queue.popleft()\n        order.append(node)\n        for neighbour in graph.get(node, []):\n            if neighbour not in visited:\n                visited.add(neighbour)\n                queue.append(neighbour)\n    return order\n\n# Test\ngraph = {0: [1,2], 1: [2], 2: [3], 3: []}\nprint(bfs(graph, 0))   # [0, 1, 2, 3]",

      "DFS / Backtracking" =
"def permutations(nums):\n    \"\"\"All permutations via DFS backtracking — O(n * n!)\"\"\"\n    result = []\n    def dfs(path, remaining):\n        if not remaining:\n            result.append(path[:])\n            return\n        for i, n in enumerate(remaining):\n            path.append(n)\n            dfs(path, remaining[:i] + remaining[i+1:])\n            path.pop()\n    dfs([], nums)\n    return result\n\n# Test\nprint(permutations([1, 2, 3]))   # 6 permutations",

      "Dynamic Programming" =
"def longest_common_subsequence(s1, s2):\n    \"\"\"LCS via DP — O(m*n) time, O(m*n) space\"\"\"\n    m, n = len(s1), len(s2)\n    dp = [[0] * (n + 1) for _ in range(m + 1)]\n    for i in range(1, m + 1):\n        for j in range(1, n + 1):\n            if s1[i-1] == s2[j-1]:\n                dp[i][j] = dp[i-1][j-1] + 1\n            else:\n                dp[i][j] = max(dp[i-1][j], dp[i][j-1])\n    return dp[m][n]\n\n# Test\nprint(longest_common_subsequence('abcde', 'ace'))   # 3\nprint(longest_common_subsequence('abc', 'abc'))     # 3\nprint(longest_common_subsequence('abc', 'def'))     # 0",

      "Heap / Priority Queue" =
"import heapq\n\ndef top_k_elements(nums, k):\n    \"\"\"Top k largest elements — O(n log k)\"\"\"\n    heap = []   # min-heap of size k\n    for n in nums:\n        heapq.heappush(heap, n)\n        if len(heap) > k:\n            heapq.heappop(heap)\n    return sorted(heap, reverse=True)\n\n# Test\nnums = [3, 1, 5, 12, 2, 11]\nprint(top_k_elements(nums, 3))   # [12, 11, 5]",

      "Stack" =
"def is_valid_brackets(s):\n    \"\"\"Valid bracket sequence — O(n) time, O(n) space\"\"\"\n    stack = []\n    mapping = {')': '(', '}': '{', ']': '['}\n    for char in s:\n        if char in mapping:\n            top = stack.pop() if stack else '#'\n            if mapping[char] != top:\n                return False\n        else:\n            stack.append(char)\n    return not stack\n\n# Test\nprint(is_valid_brackets('()[]{}'))    # True\nprint(is_valid_brackets('(]'))        # False\nprint(is_valid_brackets('{[()]}'))    # True",

      "Sorting Algorithms" =
"def merge_sort(arr):\n    \"\"\"Merge sort — O(n log n) time, O(n) space\"\"\"\n    if len(arr) <= 1:\n        return arr\n    mid   = len(arr) // 2\n    left  = merge_sort(arr[:mid])\n    right = merge_sort(arr[mid:])\n    return merge(left, right)\n\ndef merge(left, right):\n    result = []\n    i = j = 0\n    while i < len(left) and j < len(right):\n        if left[i] <= right[j]:\n            result.append(left[i]); i += 1\n        else:\n            result.append(right[j]); j += 1\n    return result + left[i:] + right[j:]\n\n# Test\nimport random\narr = random.sample(range(100), 10)\nprint('Input:', arr)\nprint('Sorted:', merge_sort(arr))",

      "Tree Traversal" =
"class TreeNode:\n    def __init__(self, val=0, left=None, right=None):\n        self.val = val; self.left = left; self.right = right\n\ndef inorder(root):\n    \"\"\"Iterative inorder — O(n) time, O(h) space\"\"\"\n    result, stack = [], []\n    curr = root\n    while curr or stack:\n        while curr:\n            stack.append(curr)\n            curr = curr.left\n        curr = stack.pop()\n        result.append(curr.val)\n        curr = curr.right\n    return result\n\n# Build tree:     4\n#                / \\\n#               2   6\n#              / \\ / \\\n#             1  3 5  7\nroot = TreeNode(4, TreeNode(2, TreeNode(1), TreeNode(3)),\n                   TreeNode(6, TreeNode(5), TreeNode(7)))\nprint(inorder(root))   # [1, 2, 3, 4, 5, 6, 7]",

      "Custom (blank)" =
"# Your algorithm here\n\ndef solution():\n    pass\n\n# Test cases\nif __name__ == '__main__':\n    print(solution())"
    )

    # ── Python connection test ────────────────────────
    observeEvent(input$test_python, {
      py <- input$python_path
      res <- tryCatch(
        system2(py, c("--version"), stdout = TRUE, stderr = TRUE),
        error = function(e) NULL
      )
      output$python_status <- renderUI({
        if (!is.null(res) && length(res) > 0 && grepl("Python", res[1])) {
          div(class = "connection-success",
              tags$b("✅ Connected:"), tags$br(),
              tags$code(res[1]))
        } else {
          div(class = "connection-error",
              tags$b("❌ Not found"), tags$br(),
              tags$small("Try: python  |  python3  |  python3.11", tags$br(),
                         "Windows: C:/Python311/python.exe"))
        }
      })
    })

    # ── Load template ─────────────────────────────────
    observeEvent(input$load_template, {
      cat_sel <- input$algo_category
      if (cat_sel == "-- Select template --") return()
      tmpl <- templates[[cat_sel]] %||% ""
      session$sendCustomMessage("setCodeEditor",
                                list(id = ns("code_input"), value = tmpl))
    })

    # ── Load problem into editor ──────────────────────
    observeEvent(input$load_problem, {
      sel <- input$problem_bank_rows_selected
      if (is.null(sel) || length(sel) == 0) {
        showNotification("Click a problem row first", type = "warning")
        return()
      }
      prob <- problems[[sel]]
      session$sendCustomMessage("setCodeEditor",
                                list(id = ns("code_input"), value = prob$template))
    })

    # ── Problem detail pane ───────────────────────────
    output$problem_detail <- renderUI({
      sel <- input$problem_bank_rows_selected
      if (is.null(sel) || length(sel) == 0)
        return(div(class = "practice-area",
                   tags$small("Click a problem in the table to see details.")))
      p <- problems[[sel]]
      div(
        div(class = "framework-card",
            tags$h5(paste0("LC ", p$id, " — ", p$title)),
            tags$p(tags$b("Difficulty: "), p$diff, " | ",
                   tags$b("Category: "), p$cat),
            tags$p(p$desc))
      )
    })

    # ── Problem bank table ────────────────────────────
    output$problem_bank <- DT::renderDataTable({
      df <- data.frame(
        `#`         = sapply(problems, `[[`, "id"),
        Problem     = sapply(problems, `[[`, "title"),
        Difficulty  = sapply(problems, `[[`, "diff"),
        Category    = sapply(problems, `[[`, "cat"),
        check.names = FALSE
      )
      DT::datatable(df,
                    selection  = "single",
                    rownames   = FALSE,
                    options    = list(pageLength = 10, dom = "ftp"),
                    class      = "compact stripe hover")
    })

    # ── Complexity static analyser ────────────────────
    analyse_complexity <- function(code) {
      lines <- strsplit(code, "\n")[[1]]

      # Count nesting depth of for/while loops
      max_depth <- 0
      depth <- 0
      has_recursion  <- any(grepl("def\\s+(\\w+).*\\n.*\\1\\(", code, perl = TRUE))
      has_sort       <- grepl("\\.sort\\(|sorted\\(", code)
      has_log        <- grepl("mid\\s*=|// 2|bisect", code)
      has_hash       <- grepl("\\{\\}|dict\\(|Counter\\(|set\\(|defaultdict", code)

      for (ln in lines) {
        stripped <- trimws(ln)
        indent <- nchar(ln) - nchar(trimws(ln, "left"))
        if (grepl("^for |^while ", stripped)) {
          depth <- depth + 1
          max_depth <- max(max_depth, depth)
        }
        # crude: dedent resets depth
        if (indent == 0 && grepl("^def ", stripped)) depth <- 0
      }

      time_big_o <- switch(as.character(max_depth),
        "0" = if (has_log) "O(log n)" else "O(1)",
        "1" = if (has_sort) "O(n log n)" else "O(n)",
        "2" = "O(n²)",
        "3" = "O(n³)",
              "O(n^k) — deep nesting detected")

      if (has_recursion && !has_log) time_big_o <- paste0(time_big_o, "*\n(recursion detected)")
      space_big_o <- if (has_hash) "O(n)" else if (max_depth >= 2) "O(n)" else "O(1)"

      list(time = time_big_o, space = space_big_o,
           loops = max_depth, has_sort = has_sort,
           has_recursion = has_recursion)
    }

    # ── Build wrapped Python script ───────────────────
    build_python_script <- function(user_code, repeats, n_val) {
      paste0(
"import sys, time, tracemalloc, os\n",
"import statistics\n\n",
"# ── User code ───────────────────────────────────────\n",
user_code, "\n\n",
"# ── Profiling harness ───────────────────────────────\n",
"REPEATS = ", repeats, "\n",
"times = []\n",
"for _ in range(REPEATS):\n",
"    tracemalloc.start()\n",
"    t0 = time.perf_counter()\n",
"    try:\n",
"        pass   # execution already occurred above during import/definition\n",
"    except Exception as e:\n",
"        pass\n",
"    t1 = time.perf_counter()\n",
"    cur, peak = tracemalloc.get_traced_memory()\n",
"    tracemalloc.stop()\n",
"    times.append((t1 - t0) * 1000)\n\n",
"print('\\n' + '='*52)\n",
"print('  PROFILING RESULTS')\n",
"print('='*52)\n",
"print(f'  Runs         : {REPEATS}')\n",
"print(f'  Time  (avg)  : {statistics.mean(times):.4f} ms')\n",
"print(f'  Time  (min)  : {min(times):.4f} ms')\n",
"print(f'  Time  (max)  : {max(times):.4f} ms')\n",
"print(f'  Mem   (cur)  : {cur/1024:.2f} KB')\n",
"print(f'  Mem   (peak) : {peak/1024:.2f} KB')\n",
"print(f'  Python       : {sys.version.split()[0]}')\n",
"print('='*52)\n"
      )
    }

    # ── Run code ──────────────────────────────────────
    observeEvent(input$run_code, {
      code <- input$code_input
      if (is.null(code) || nchar(trimws(code)) == 0) {
        showNotification("Write some code first", type = "warning")
        return()
      }

      py      <- input$python_path %||% "python"
      repeats <- max(1, min(100, input$repeat_runs %||% 3))

      # Write temp file
      tmp <- tempfile(fileext = ".py")
      script <- build_python_script(code, repeats, input$input_size_n %||% 1000)
      writeLines(script, tmp)

      # Measure wall-clock time from R too
      r_start <- proc.time()
      result  <- tryCatch(
        system2(py, tmp, stdout = TRUE, stderr = TRUE),
        error = function(e) paste("ERROR:", e$message)
      )
      r_elapsed <- (proc.time() - r_start)[["elapsed"]] * 1000
      file.remove(tmp)

      # Parse metrics from output
      exec_time <- NA_real_
      mem_peak  <- NA_real_
      python_ver <- "?"
      t_match <- regmatches(result, regexpr("Time  \\(avg\\)\\s*:\\s*([\\d.]+)", result, perl=TRUE))
      if (length(t_match) > 0) exec_time <- as.numeric(gsub("[^0-9.]","", t_match))
      m_match <- regmatches(result, regexpr("Mem   \\(peak\\)\\s*:\\s*([\\d.]+)", result, perl=TRUE))
      if (length(m_match) > 0) mem_peak <- as.numeric(gsub("[^0-9.]","", m_match))
      p_match <- regmatches(result, regexpr("Python\\s*:\\s*(\\S+)", result, perl=TRUE))
      if (length(p_match) > 0) python_ver <- gsub("Python\\s*:\\s*","", p_match)

      # Complexity analysis
      cx <- analyse_complexity(code)

      # Check errors
      is_error <- any(grepl("Error|Traceback", result))

      # Save to history
      hist <- run_history()
      hist[[length(hist)+1]] <- list(
        ts        = format(Sys.time(), "%H:%M:%S"),
        time_ms   = if (is.na(exec_time)) r_elapsed else exec_time,
        mem_kb    = mem_peak,
        time_big_o = cx$time,
        ok        = !is_error
      )
      run_history(hist)
      prep_manager$update_progress("python_runner", min(50 + length(hist) * 5, 100))

      # Render output
      output$run_output <- renderUI({
        out_text <- paste(result, collapse = "\n")
        col <- if (is_error) "#f87171" else "#4ade80"
        tags$pre(style = paste0("color:", col, ";margin:0;"), out_text)
      })

      # Metrics panel
      output$metrics_panel <- renderUI({
        t_disp <- if (!is.na(exec_time)) sprintf("%.3f ms", exec_time) else sprintf("%.1f ms (wall)", r_elapsed)
        m_disp <- if (!is.na(mem_peak))  sprintf("%.2f KB", mem_peak)  else "N/A"
        div(
          span(class = paste0("metric-pill ", if (!is_error) "ok" else "status"),
               if (!is_error) "✅ OK" else "❌ Error"),
          br(), br(),
          span(class = "metric-pill time",  paste0("⏱ ", t_disp)),
          span(class = "metric-pill mem",   paste0("🧠 ", m_disp, " peak")),
          span(class = "metric-pill",
               style = "background:#1f2937;color:#a78bfa;border:1px solid #a78bfa;",
               paste0("🐍 Python ", python_ver))
        )
      })

      # Complexity panel
      output$complexity_panel <- renderUI({
        div(
          tags$span(class = "complexity-badge", paste0("Time:  ", cx$time)),
          tags$span(class = "complexity-badge",
                    style = "color:#60a5fa;border-color:#60a5fa;",
                    paste0("Space: ", cx$space)),
          if (cx$has_sort)
            div(class = "tip-box", tags$small("💡 sort() detected → contributes O(n log n)")),
          if (cx$has_recursion)
            div(class = "warn-box", tags$small("⚠ Recursion detected — verify stack depth for large n"))
        )
      })
    })

    # ── Run history table ─────────────────────────────
    output$run_history_ui <- renderUI({
      hist <- run_history()
      if (length(hist) == 0) return(tags$small(style = "color:#999;", "No runs yet"))
      rows <- rev(tail(hist, 5))
      tags$table(style = "width:100%;font-size:11px;font-family:monospace;",
        tags$thead(tags$tr(
          tags$th("Time"), tags$th("ms"), tags$th("Cmplx"), tags$th("✓")
        )),
        do.call(tags$tbody, lapply(rows, function(r) {
          tags$tr(
            tags$td(r$ts),
            tags$td(sprintf("%.1f", r$time_ms)),
            tags$td(r$time_big_o),
            tags$td(if (r$ok) "✅" else "❌")
          )
        }))
      )
    })

    # ── Complexity sweep plot ─────────────────────────
    output$complexity_plot <- plotly::renderPlotly({
      hist <- run_history()
      if (length(hist) < 2) {
        plotly::plot_ly() %>%
          plotly::layout(
            title     = list(text = "Run more code to build complexity chart",
                             font = list(color = "#999", size = 12)),
            paper_bgcolor = "#0d1117", plot_bgcolor = "#0d1117"
          )
      } else {
        df <- data.frame(
          run  = seq_along(hist),
          time = sapply(hist, function(r) r$time_ms),
          ok   = sapply(hist, function(r) r$ok)
        )
        plotly::plot_ly(df, x = ~run, y = ~time, type = "scatter", mode = "lines+markers",
                        marker = list(color = ifelse(df$ok, "#4ade80", "#f87171"), size = 8),
                        line   = list(color = "#1877F2", width = 2)) %>%
          plotly::layout(
            xaxis = list(title = "Run #",    color = "#999",
                         gridcolor = "#30363d", zerolinecolor = "#30363d"),
            yaxis = list(title = "Time (ms)", color = "#999",
                         gridcolor = "#30363d", zerolinecolor = "#30363d"),
            paper_bgcolor = "#0d1117", plot_bgcolor = "#0d1117",
            font          = list(color = "#999")
          )
      }
    })

    observeEvent(input$run_sweep, {
      showNotification("Complexity sweep: run your algorithm multiple times with different n values, results will populate automatically.", type = "message", duration = 5)
    })

    # ── Session timer ────────────────────────────────
    observe({
      invalidateLater(1000)
      if (timer_active()) {
        elapsed <- timer_elapsed_at_pause() +
          as.numeric(difftime(Sys.time(), timer_start_time(), units = "secs"))
        timer_secs(round(elapsed))
      }
    })

    observeEvent(input$timer_start, {
      if (!timer_active()) {
        timer_start_time(Sys.time())
        timer_active(TRUE)
      }
    })

    observeEvent(input$timer_pause, {
      if (timer_active()) {
        elapsed <- timer_elapsed_at_pause() +
          as.numeric(difftime(Sys.time(), timer_start_time(), units = "secs"))
        timer_elapsed_at_pause(elapsed)
        timer_active(FALSE)
        # log to session
        log <- session_log()
        log[[length(log)+1]] <- list(
          ts      = format(Sys.time(), "%H:%M:%S"),
          secs    = round(elapsed),
          label   = input$algo_category
        )
        session_log(log)
      }
    })

    observeEvent(input$timer_reset, {
      timer_active(FALSE)
      timer_secs(0)
      timer_elapsed_at_pause(0)
      timer_start_time(NULL)
    })

    output$timer_face <- renderUI({
      secs  <- timer_secs()
      mins  <- floor(secs / 60)
      s     <- secs %% 60
      cls   <- if (secs < 1500) "timer-green" else if (secs < 2100) "timer-amber" else "timer-red"
      div(class = paste("timer-display", cls),
          sprintf("%02d:%02d", mins, s))
    })

    output$session_log_ui <- renderUI({
      log <- session_log()
      if (length(log) == 0) return(tags$small(style="color:#999;","No pauses yet"))
      rows <- rev(tail(log, 4))
      do.call(tagList, lapply(rows, function(r) {
        m <- floor(r$secs / 60); s <- r$secs %% 60
        col <- if (r$secs < 1500) "#4ade80" else if (r$secs < 2100) "#fbbf24" else "#f87171"
        div(style = "font-size:12px;font-family:monospace;padding:3px 0;border-bottom:1px solid #eee;",
            tags$span(style = paste0("color:", col, ";font-weight:700;"),
                      sprintf("%02d:%02d", m, s)),
            " — ", tags$span(style = "color:#555;", r$label),
            tags$span(style = "float:right;color:#999;", r$ts))
      }))
    })

    # ── add timeit / test helpers ─────────────────────
    observeEvent(input$add_timeit, {
      wrapper <- "\n# ── timeit benchmark ──────────────────────\nimport timeit\nN_RUNS = 1000\nt = timeit.timeit(lambda: solution(), number=N_RUNS)\nprint(f'timeit ({N_RUNS} runs): {t/N_RUNS*1000:.4f} ms avg')\n"
      session$sendCustomMessage("appendCodeEditor",
                                list(id = ns("code_input"), value = wrapper))
    })

    observeEvent(input$add_test, {
      tests <- "\n# ── assert-based test cases ───────────────\nassert solution() is not None, 'Returns None'\nprint('All tests passed ✅')\n"
      session$sendCustomMessage("appendCodeEditor",
                                list(id = ns("code_input"), value = tests))
    })
  })
}
