# modules/chapter02.R  — Why Algorithms Matter

CH02_FILES <- list(
  list(
    name = "linear_search.py",
    description = "<strong>linear_search.py</strong> — Searches an ordered array element by element. Stops early if the current element exceeds the search value.",
    code = 'def linear_search(array, search_value):\n    for index, element in enumerate(array):\n        if element == search_value:\n            return index\n        elif element > search_value:\n            break\n    return None',
    demo = 'arr = [2, 5, 8, 9, 100]\nprint("Array:", arr)\nprint(f"linear_search(arr, 8)  -> {linear_search(arr, 8)}")\nprint(f"linear_search(arr, 2)  -> {linear_search(arr, 2)}")\nprint(f"linear_search(arr, 50) -> {linear_search(arr, 50)}  # Not found")'
  ),
  list(
    name = "binary_search.py",
    description = "<strong>binary_search.py</strong> — Classic binary search. Maintains lower/upper bounds, halving the search window each step. O(log N).",
    code = 'def binary_search(array, search_value):\n    lower_bound = 0\n    upper_bound = len(array) - 1\n    while lower_bound <= upper_bound:\n        midpoint = (upper_bound + lower_bound) // 2\n        value_at_midpoint = array[midpoint]\n        if search_value == value_at_midpoint:\n            return midpoint\n        elif search_value < value_at_midpoint:\n            upper_bound = midpoint - 1\n        elif search_value > value_at_midpoint:\n            lower_bound = midpoint + 1\n    return None',
    demo = 'arr = [2, 5, 8, 9, 100]\nprint("Array:", arr)\nprint(f"binary_search(arr, 8)   -> {binary_search(arr, 8)}")\nprint(f"binary_search(arr, 2)   -> {binary_search(arr, 2)}")\nprint(f"binary_search(arr, 100) -> {binary_search(arr, 100)}")\nprint(f"binary_search(arr, 50)  -> {binary_search(arr, 50)}  # Not found")\nbig = list(range(0, 1000000, 2))\nimport time\nt = time.time()\nidx = binary_search(big, 999998)\nelapsed = (time.time() - t) * 1000\nprint(f"\\nBinary search 500,000 items for 999998 -> index {idx}")\nprint(f"Time: {elapsed:.4f} ms")'
  ),
  list(
    name = "test.py",
    description = "<strong>test.py</strong> — Assertion tests for both search algorithms. Each '.' is a passing test.",
    code = 'import linear_search\nimport binary_search\n\ndef assert_equal(x, y):\n    if x == y:\n        print(".")\n    else:\n        print("FAIL")\n\nassert_equal(linear_search.linear_search([2, 5, 8, 9, 100], 8), 2)\nassert_equal(linear_search.linear_search([5, 2, 8, 100, 9], 8), 2)\nassert_equal(binary_search.binary_search([2, 5, 8, 9, 100], 8), 2)\nassert_equal(binary_search.binary_search([2, 5, 8, 9, 100], 2), 0)\nassert_equal(binary_search.binary_search([2, 5, 8, 9, 100, 101], 8), 2)\nassert_equal(binary_search.binary_search([2, 5, 8, 9, 100, 101], 2), 0)\nassert_equal(binary_search.binary_search([2, 5, 8, 9, 100, 101], 101), 5)\nassert_equal(binary_search.binary_search([-3, -1, 2, 5, 8, 9, 100, 101], 100), 6)',
    demo = ''
  )
)

chapter2_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(2, "🔍", "Why Algorithms Matter",
      "Two programs can store identical data yet run at vastly different speeds. The algorithm — the steps used to process the data — makes all the difference.",
      c("Ordered Arrays", "Linear Search", "Binary Search", "O(log N)")),
    stats_row(list("O(N)","Linear Search"), list("O(log N)","Binary Search"),
              list("7","Steps for 100 items"), list("20","Steps for 1,000,000")),
    fluidRow(tabBox(width = 12, id = ns("tabs"),
      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "📋 Ordered Arrays", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("What makes them special?"),
                  tags$p("An ordered array keeps values sorted at all times. Insertion is slower (must find position), but searching can be dramatically faster."),
                  tags$ul(tags$li("Insert — up to N+1 steps (find + shift)"),
                          tags$li("Search — can use ", tags$strong("binary search")),
                          tags$li("Read — O(1) by index"))),
              div(class = "tip-box", HTML("<strong>💡 Trade-off:</strong> Pay more on inserts, gain massive wins on searches. Use ordered arrays when searches vastly outnumber inserts."))
          ),
          box(title = "🔎 Linear vs Binary Search", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("N (Array Size)"), tags$th("Linear Max"), tags$th("Binary Max"))),
                tags$tbody(
                  tags$tr(tags$td("10"),        tags$td("10"),        tags$td("4")),
                  tags$tr(tags$td("100"),       tags$td("100"),       tags$td("7")),
                  tags$tr(tags$td("1,000"),     tags$td("1,000"),     tags$td("10")),
                  tags$tr(tags$td("1,000,000"), tags$td("1,000,000"), tags$td("20"))
                )
              ),
              div(class = "success-box", HTML("<strong>✅ O(log N):</strong> Each step eliminates half the remaining candidates. For 1,000,000 elements, binary search needs at most 20 comparisons."))
          )
        ),
        fluidRow(
          box(title = "🎯 Binary Search Algorithm", status = "success", solidHeader = TRUE, width = 12,
              tags$ol(
                tags$li("Set lower_bound = 0, upper_bound = len(array) - 1"),
                tags$li("Calculate midpoint = (lower + upper) // 2"),
                tags$li(tags$strong("Found?"), " → return midpoint index"),
                tags$li(tags$strong("Too high?"), " → upper_bound = midpoint - 1"),
                tags$li(tags$strong("Too low?"), " → lower_bound = midpoint + 1"),
                tags$li("Repeat until found or bounds cross → return None")
              ),
              div(class = "info-box-plain", HTML("<strong>ℹ Why only for ordered arrays?</strong> Binary search relies on the property that 'if the target is less than the midpoint, it must be in the left half.' This is only true when the array is sorted."))
          )
        )
      ),
      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 2 Code Files", "Linear search and binary search implementations — plus a full test suite."),
        file_pills_ui(ns, CH02_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter2_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH02_FILES)
  })
}
