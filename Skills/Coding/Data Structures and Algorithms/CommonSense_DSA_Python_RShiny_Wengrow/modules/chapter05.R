# modules/chapter05.R  — Optimizing Code With and Without Big O

CH05_FILES <- list(
  list(
    name = "selection_sort.py",
    description = "<strong>selection_sort.py</strong> — O(N²) comparisons but only N swaps. Faster than Bubble Sort in practice for write-heavy storage.",
    code = 'def selection_sort(array):\n    for i in range(len(array) - 1):\n        lowest_number_index = i\n        for j in range(i + 1, len(array)):\n            if array[j] < array[lowest_number_index]:\n                lowest_number_index = j\n        if lowest_number_index != i:\n            array[i], array[lowest_number_index] = \\\n                array[lowest_number_index], array[i]\n    return array',
    demo = 'print("selection_sort([5,3,4,2,1]) =", selection_sort([5,3,4,2,1]))\nprint("selection_sort([1,9,3,4,5,10,0]) =", selection_sort([1,9,3,4,5,10,0]))'
  ),
  list(
    name = "double_sum.py",
    description = "<strong>double_sum.py</strong> — Doubles each element then sums. Two O(N) passes = 2N steps total. Still O(N), but a single-pass version would be faster in practice.",
    code = 'def double_then_sum(array):\n    doubled_array = []\n    for number in array:\n        doubled_array.append(number * 2)\n    sum = 0\n    for number in doubled_array:\n        sum += number\n    return sum',
    demo = 'print(f"double_then_sum([])      = {double_then_sum([])}")\nprint(f"double_then_sum([1,4,9]) = {double_then_sum([1,4,9])}")\nprint(f"double_then_sum([10,20]) = {double_then_sum([10,20])}")'
  ),
  list(
    name = "multicase.py",
    description = "<strong>multicase.py</strong> — Prints each string in three cases. O(N) — 3 operations per element is constant, not a nested loop.",
    code = 'def multiple_cases(array):\n    for string in array:\n        print(string.upper())\n        print(string.lower())\n        print(string.capitalize())',
    demo = 'multiple_cases(["Hello", "WORLD", "pYtHoN"])'
  ),
  list(
    name = "every_other.py",
    description = "<strong>every_other.py</strong> — For each even-indexed element, prints its sum with every other element. Despite outer loop running N/2 times, inner N-element loop makes this O(N²).",
    code = 'def every_other(array):\n    for index, number in enumerate(array):\n        if index % 2 == 0:\n            for other_number in array:\n                print(number + other_number)',
    demo = 'print("every_other([1,2,3]) — should print 2 3 4 4 5 6:")\nevery_other([1, 2, 3])'
  ),
  list(
    name = "print_numbers.py",
    description = "<strong>print_numbers.py</strong> — (Ch 5 version) Two approaches to printing even numbers, now with upper_limit parameter.",
    code = 'def print_numbers_version_one(upper_limit):\n    number = 2\n    while number <= upper_limit:\n        if number % 2 == 0:\n            print(number)\n        number += 1\n\ndef print_numbers_version_two(upper_limit):\n    number = 2\n    while number <= upper_limit:\n        print(number)\n        number += 2',
    demo = 'print("Version 1 (evens up to 20):")\nprint_numbers_version_one(20)\nprint("\\nVersion 2 (evens up to 20):")\nprint_numbers_version_two(20)'
  )
)

chapter5_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(5, "🎯", "Optimizing Code With and Without Big O",
      "Two algorithms with the same Big O can run at very different speeds in practice. Understanding why — and when it matters — separates good engineers from great ones.",
      c("Selection Sort", "O(N²)", "Write Operations", "Constant Factors")),
    stats_row(list("O(N²)","Selection Sort"), list("N/2","Fewer Swaps vs Bubble"),
              list("O(N)","double_then_sum"), list("2×","Passes vs 1 pass")),
    fluidRow(tabBox(width = 12, id = ns("tabs"),
      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "✂️ Selection Sort", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("Algorithm"),
                  tags$p("Scan the unsorted portion for the minimum, swap it to the front."),
                  tags$ol(tags$li("Mark index i as current minimum"),
                          tags$li("Scan i+1 to end for a smaller value"),
                          tags$li("Swap found minimum with position i"),
                          tags$li("Advance i by 1 and repeat"))),
              div(class = "info-box-plain", HTML("<strong>Big O:</strong> O(N²) comparisons — same as Bubble Sort. But at most <strong>N swaps</strong> (one per pass), versus Bubble Sort's potential O(N²) swaps."))
          ),
          box(title = "⚖️ Selection vs Bubble Sort", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Metric"), tags$th("Bubble Sort"), tags$th("Selection Sort"))),
                tags$tbody(
                  tags$tr(tags$td("Comparisons"),  tags$td("~N²/2"), tags$td("~N²/2")),
                  tags$tr(tags$td("Swaps (worst)"), tags$td("~N²/2 ❌"), tags$td("~N ✅")),
                  tags$tr(tags$td("Big O"),         tags$td("O(N²)"), tags$td("O(N²)")),
                  tags$tr(tags$td("Practical speed"), tags$td("Slower"), tags$td(tags$strong("Faster")))
                )
              ),
              div(class = "success-box", HTML("<strong>✅ Same Big O, different reality:</strong> Selection Sort is ~2× faster in practice because it does far fewer memory writes. Big O drops constants — but constants matter in the real world."))
          )
        ),
        fluidRow(
          box(title = "📏 Beyond Big O — Constant Factors", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6, div(class = "framework-card", tags$h5("double_then_sum — 2 passes"),
                              tags$p("Doubles each element (N steps), then sums the doubled array (N steps). Total: 2N steps. Still O(N)."))),
                column(6, div(class = "framework-card", tags$h5("Single-pass version — 1 pass"),
                              tags$p("Could double and sum in one loop: N steps total. Same Big O, half the constant.")))
              ),
              div(class = "tip-box", HTML("<strong>💡 Rule:</strong> Within the same Big O category, prefer the version with fewer steps. The book's guideline: 'When in doubt about two O(N) solutions, count the actual steps.'"))
          )
        )
      ),
      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 5 Code Files", "Selection Sort, double-then-sum, multiple cases, every_other — illustrating constant factors within the same Big O class."),
        file_pills_ui(ns, CH05_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter5_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH05_FILES)
  })
}
