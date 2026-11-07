# modules/chapter12.R  — Dynamic Programming

CH12_FILES <- list(
  list(
    name = "fib1.py",
    description = "<strong>fib1.py</strong> — Naive recursive Fibonacci. O(2^N) — recalculates the same subproblems exponentially.",
    code = 'def fib(n):\n    if n == 0 or n == 1:\n        return n\n    return fib(n - 2) + fib(n - 1)',
    demo = 'import time\nfor n in [0,1,2,3,7,10,20,30]:\n    t = time.time()\n    result = fib(n)\n    ms = (time.time()-t)*1000\n    print(f"fib({n:2}) = {result:6}  ({ms:.2f} ms)")'
  ),
  list(
    name = "fib2.py",
    description = "<strong>fib2.py</strong> — Memoized Fibonacci. O(N) — each subproblem computed once, stored in memo dict.",
    code = 'def fib(n, memo):\n    if n == 0 or n == 1:\n        return n\n    if n not in memo:\n        memo[n] = fib(n - 2, memo) + fib(n - 1, memo)\n    return memo[n]',
    demo = 'import time\nmemo = {}\nfor n in [0,1,2,3,7,10,20,30,40,50]:\n    t = time.time()\n    result = fib(n, memo)\n    ms = (time.time()-t)*1000\n    print(f"fib({n:2}) = {result:12}  ({ms:.4f} ms)")'
  ),
  list(
    name = "fib3.py",
    description = "<strong>fib3.py</strong> — Iterative Fibonacci (bottom-up DP). O(N) time, O(1) space — no recursion, no memo dict needed.",
    code = 'def fib(n):\n    if n == 0:\n        return 0\n    a = 0\n    b = 1\n    for _ in range(1, n):\n        a, b = b, a + b\n    return b',
    demo = 'for n in [0,1,2,3,7,10,20,30,50,100]:\n    print(f"fib({n:3}) = {fib(n)}")'
  ),
  list(
    name = "array_max2.py",
    description = "<strong>array_max2.py</strong> — Recursively finds the maximum value. Stores max_of_remainder in a variable to avoid recomputing it.",
    code = 'def max(array):\n    if not array:\n        return None\n    if len(array) == 1:\n        return array[0]\n    max_of_remainder = max(array[1:])\n    if array[0] > max_of_remainder:\n        return array[0]\n    else:\n        return max_of_remainder',
    demo = 'print(f"max([4,6,0,1,3,3,5]) = {max([4,6,0,1,3,3,5])}")\nprint(f"max([])              = {max([])}")\nprint(f"max([42])            = {max([42])}")'
  ),
  list(
    name = "solution1.py",
    description = "<strong>solution1.py</strong> — add_until_100: sums array elements but skips adding if it would push the total over 100. Uses a variable to avoid recomputing recursive calls.",
    code = 'def add_until_100(array):\n    if not array:\n        return 0\n    sum_of_remaining_numbers = add_until_100(array[1:])\n    if array[0] + sum_of_remaining_numbers > 100:\n        return sum_of_remaining_numbers\n    else:\n        return array[0] + sum_of_remaining_numbers',
    demo = 'print(f"add_until_100([3,6,5,11,90]) = {add_until_100([3,6,5,11,90])}")\nprint(f"add_until_100([10,20,30,40]) = {add_until_100([10,20,30,40])}")\nprint(f"add_until_100([])            = {add_until_100([])}")'
  ),
  list(
    name = "solution2.py",
    description = "<strong>solution2.py</strong> — Memoized Golomb sequence. Without memo: exponential. With memo: each G(n) is computed once.",
    code = 'def golomb(n, memo):\n    if n == 1:\n        return 1\n    if n not in memo:\n        memo[n] = 1 + golomb(n - golomb(golomb(n - 1, memo), memo), memo)\n    return memo[n]',
    demo = 'memo = {}\nfor n in [1,2,3,4,5,10,20,30]:\n    print(f"golomb({n:2}) = {golomb(n, memo)}")'
  ),
  list(
    name = "solution3.py",
    description = "<strong>solution3.py</strong> — Memoized unique_paths. Transforms O(2^N) grid path counting into O(rows × columns) by caching already-computed (r,c) pairs.",
    code = 'def unique_paths(rows, columns, memo):\n    if rows == 1 or columns == 1:\n        return 1\n    if (rows, columns) not in memo:\n        memo[(rows, columns)] = (unique_paths(rows - 1, columns, memo)\n                                 + unique_paths(rows, columns - 1, memo))\n    return memo[(rows, columns)]',
    demo = 'memo = {}\nprint(f"unique_paths(3, 7)   = {unique_paths(3, 7, memo)}")\nprint(f"unique_paths(10, 10) = {unique_paths(10, 10, memo)}")\nprint(f"unique_paths(20, 20) = {unique_paths(20, 20, memo)}")'
  )
)

chapter12_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(12, "🚀", "Dynamic Programming",
      "Dynamic programming solves problems by breaking them into overlapping subproblems and storing results to avoid redundant computation. Memoization is the top-down version of this idea.",
      c("Memoization", "Fibonacci", "Golomb Sequence", "Unique Paths", "O(N) vs O(2^N)")),
    stats_row(list("O(2^N)","fib1 (naive)"), list("O(N)","fib2 (memo)"),
              list("O(1)","Space fib3"), list("N!→N²","unique_paths speedup")),
    fluidRow(tabBox(width = 12, id = ns("tabs"),
      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "🚀 What is Dynamic Programming?", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("The Core Idea"),
                  tags$p("Dynamic programming optimises recursive solutions that have", tags$strong("overlapping subproblems"), " — subproblems that are solved more than once."),
                  tags$p("Instead of recomputing, we", tags$strong("store results"), "in a memo table and look them up in O(1).")),
              div(class = "framework-card", tags$h5("Two Approaches"),
                  tags$ul(tags$li(tags$strong("Top-down (memoization)"), ": recursive + cache"),
                          tags$li(tags$strong("Bottom-up (tabulation)"), ": iterative, build from smallest"))),
              div(class = "tip-box", HTML("<strong>💡 When to apply DP:</strong> If a problem has recursive subproblems and you notice the same (n) is computed multiple times, memoize it."))
          ),
          box(title = "🐰 Fibonacci — The Classic Example", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Version"), tags$th("Time"), tags$th("Space"), tags$th("Approach"))),
                tags$tbody(
                  tags$tr(tags$td("fib1 (naive)"),    tags$td("O(2^N) ❌"), tags$td("O(N)"),  tags$td("Recursive, no cache")),
                  tags$tr(tags$td("fib2 (memo)"),     tags$td("O(N) ✅"),   tags$td("O(N)"),  tags$td("Recursive + dict")),
                  tags$tr(tags$td("fib3 (iterative)"),tags$td("O(N) ✅"),   tags$td("O(1) ✅"),tags$td("Loop, two variables"))
                )
              ),
              div(class = "info-box-plain", HTML("<strong>ℹ fib(30) comparison:</strong> fib1 makes ~2.7 billion calls. fib2 makes exactly 29. fib3 loops 29 times with no stack overhead."))
          )
        ),
        fluidRow(
          box(title = "📐 Memoization Pattern", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4, div(class = "framework-card", tags$h5("Step 1 — Check memo"),
                              tags$p("Before computing, check if the result is already in the memo dict."),
                              tags$p(tags$code("if n in memo: return memo[n]")))),
                column(4, div(class = "framework-card", tags$h5("Step 2 — Compute & store"),
                              tags$p("If not cached, compute normally and store the result before returning."),
                              tags$p(tags$code("memo[n] = expensive_computation(n)")))),
                column(4, div(class = "framework-card", tags$h5("Step 3 — Return"),
                              tags$p("Return the cached value."),
                              tags$p(tags$code("return memo[n]"))))
              ),
              div(class = "success-box", HTML("<strong>✅ Result:</strong> Each subproblem is computed exactly once. For unique_paths, this transforms O(2^(R+C)) to O(R×C) — a dramatic improvement for large grids."))
          )
        )
      ),
      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 12 Code Files", "Fibonacci (naive, memoized, iterative), array max, add-until-100, Golomb sequence, and memoized unique paths."),
        file_pills_ui(ns, CH12_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter12_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH12_FILES)
  })
}
