# modules/chapter04.R  — Speeding Up Your Code with Big O

CH04_FILES <- list(
  list(
    name = "bubble_sort.py",
    description = "<strong>bubble_sort.py</strong> — O(N²). Repeatedly compares adjacent pairs and swaps if out of order. The <code>sorted</code> flag enables early exit for already-sorted arrays.",
    code = 'def bubble_sort(array):\n    unsorted_until_index = len(array) - 1\n    sorted = False\n    while not sorted:\n        sorted = True\n        for i in range(unsorted_until_index):\n            if array[i] > array[i+1]:\n                array[i], array[i+1] = array[i+1], array[i]\n                sorted = False\n        unsorted_until_index -= 1\n    return array',
    demo = 'print("bubble_sort([5,3,4,2,1]) =", bubble_sort([5,3,4,2,1]))\nprint("bubble_sort([1,9,3,4,5,10,0]) =", bubble_sort([1,9,3,4,5,10,0]))\nprint("bubble_sort([]) =", bubble_sort([]))'
  ),
  list(
    name = "duplicates1.py",
    description = "<strong>duplicates1.py</strong> — O(N²) duplicate check. Nested loops compare every pair (i,j) where i ≠ j.",
    code = 'def has_duplicate_value(array):\n    for i in range(len(array)):\n        for j in range(len(array)):\n            if (i != j) and (array[i] == array[j]):\n                return True\n    return False',
    demo = 'print(f"[1,2,3,4]   has duplicate? {has_duplicate_value([1,2,3,4])}")\nprint(f"[1,2,2,3]   has duplicate? {has_duplicate_value([1,2,2,3])}")\nprint(f"[1,2,3,4,1] has duplicate? {has_duplicate_value([1,2,3,4,1])}")'
  ),
  list(
    name = "duplicates3.py",
    description = "<strong>duplicates3.py</strong> — O(N) duplicate check. Uses a presence-tracking array — marks each value, detects repeats in one pass.",
    code = 'def has_duplicate_value(array):\n    existing_numbers = [0] * 11\n    for i in range(len(array)):\n        if existing_numbers[array[i]] == 1:\n            return True\n        else:\n            existing_numbers[array[i]] = 1\n    return False',
    demo = 'print(f"[1,2,3,4]   has duplicate? {has_duplicate_value([1,2,3,4])}")\nprint(f"[1,2,2,3]   has duplicate? {has_duplicate_value([1,2,2,3])}")\nprint(f"[0,2,3,4,0] has duplicate? {has_duplicate_value([0,2,3,4,0])}")'
  ),
  list(
    name = "greatest_number_exercise.py",
    description = "<strong>greatest_number_exercise.py</strong> — O(N²): for each element, checks whether any other element is greater. Instructive but inefficient.",
    code = 'def greatest_number(array):\n    if not array:\n        return None\n    for i in array:\n        is_i_the_greatest = True\n        for j in array:\n            if j > i:\n                is_i_the_greatest = False\n        if is_i_the_greatest:\n            return i',
    demo = 'print(f"greatest_number([])             = {greatest_number([])}")\nprint(f"greatest_number([1,3,5])        = {greatest_number([1,3,5])}")\nprint(f"greatest_number([5,3,1,9,7,-4]) = {greatest_number([5,3,1,9,7,-4])}")'
  ),
  list(
    name = "solution_greatest_number.py",
    description = "<strong>solution_greatest_number.py</strong> — O(N) solution. Tracks the greatest value seen so far — no nested loop needed.",
    code = 'def greatest_number(array):\n    if not array:\n        return None\n    greatest_number_so_far = array[0]\n    for i in array:\n        if i > greatest_number_so_far:\n            greatest_number_so_far = i\n    return greatest_number_so_far',
    demo = 'print(f"greatest_number([])             = {greatest_number([])}")\nprint(f"greatest_number([1,3,5])        = {greatest_number([1,3,5])}")\nprint(f"greatest_number([5,3,1,9,7,-4]) = {greatest_number([5,3,1,9,7,-4])}")'
  ),
  list(
    name = "greatest_product.py",
    description = "<strong>greatest_product.py</strong> — Finds the greatest product of any two numbers. O(N²) nested loops.",
    code = 'def greatest_product(array):\n    if len(array) < 2:\n        return None\n    greatest_product_so_far = array[0] * array[1]\n    for index_i, value_i in enumerate(array):\n        for index_j, value_j in enumerate(array):\n            if (index_i != index_j and\n                    value_i * value_j > greatest_product_so_far):\n                greatest_product_so_far = value_i * value_j\n    return greatest_product_so_far',
    demo = 'print(f"greatest_product([5,2,4,1]) = {greatest_product([5,2,4,1])}")\nprint(f"greatest_product([1,2])    = {greatest_product([1,2])}")\nprint(f"greatest_product([])       = {greatest_product([])}")'
  )
)

chapter4_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(4, "⚡", "Speeding Up Your Code with Big O",
      "Big O is not just for analysis — it's a tool for improvement. Recognising O(N²) patterns opens the door to optimisations that transform sluggish code into lightning-fast algorithms.",
      c("Bubble Sort", "O(N²)", "Duplicate Detection", "Linear Optimisation")),
    stats_row(list("O(N²)","Bubble Sort"), list("N²","Naive Dup Steps"),
              list("O(N)","Optimal Dup Steps"), list("1000×","Speedup N=1000")),
    fluidRow(tabBox(width = 12, id = ns("tabs"),
      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "🫧 Bubble Sort", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("How It Works"),
                  tags$p("Repeatedly compare adjacent pairs and swap if out of order. Each pass 'bubbles' the largest unsorted value to its final position."),
                  tags$ol(tags$li("Pointer at index 0 — compare arr[i] and arr[i+1]"),
                          tags$li("If arr[i] > arr[i+1], swap them"),
                          tags$li("Advance pointer, repeat to end of unsorted portion"),
                          tags$li("Each pass reduces unsorted region by 1"))),
              div(class = "warn-box", HTML("<strong>Complexity:</strong> O(N²) average/worst. (N-1)+(N-2)+…+1 = N(N-1)/2 comparisons."))
          ),
          box(title = "🧬 Duplicate Detection Optimisation", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Version"), tags$th("Big O"), tags$th("Strategy"), tags$th("N=1000"))),
                tags$tbody(
                  tags$tr(tags$td("duplicates1"), tags$td("O(N²)"), tags$td("Nested loop — compare all pairs"), tags$td("~1,000,000")),
                  tags$tr(tags$td("duplicates2"), tags$td("O(N²)"), tags$td("Same + step counter"), tags$td("~1,000,000")),
                  tags$tr(tags$td("duplicates3"), tags$td("O(N)"),  tags$td("Presence-tracking array"), tags$td("~1,000")),
                  tags$tr(tags$td("duplicates4"), tags$td("O(N)"),  tags$td("Same + step counter"), tags$td("~1,000"))
                )
              ),
              div(class = "success-box", HTML("<strong>✅ The Key Insight (v3/v4):</strong> Use a lookup array as a 'have I seen this?' check — O(1) per element. One pass = O(N) total. This is the <em>space-time trade-off</em>: use extra memory to save time."))
          )
        ),
        fluidRow(
          box(title = "🏆 Greatest Number — Two Approaches", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6,
                  div(class = "framework-card", tags$h5("Exercise Version — O(N²)"),
                      tags$p("For each element, check whether any other element is greater. Two nested loops."),
                      tags$p(tags$strong("Result:"), " N² comparisons just to find the max."))
                ),
                column(6,
                  div(class = "framework-card", tags$h5("Solution Version — O(N)"),
                      tags$p("Track the greatest number seen so far. One single loop."),
                      tags$p(tags$strong("Pattern:"), " Many O(N²) solutions become O(N) with a 'running best' variable."))
                )
              ),
              div(class = "tip-box", HTML("<strong>💡 General Pattern:</strong> Whenever you see nested loops that search for the 'best' of something, ask — can I track the best in a single pass?"))
          )
        )
      ),
      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 4 Code Files", "Bubble Sort, duplicate detection (O(N²) vs O(N)), and greatest number/product exercises."),
        file_pills_ui(ns, CH04_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter4_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH04_FILES)
  })
}
