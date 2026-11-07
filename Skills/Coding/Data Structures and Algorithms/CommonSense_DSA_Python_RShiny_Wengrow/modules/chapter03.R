# modules/chapter03.R  — Oh Yes! Big O Notation

CH03_FILES <- list(
  list(
    name = "array_sum.py",
    description = "<strong>array_sum.py</strong> — Sums all numbers in an array. O(N): one iteration through the array.",
    code = 'def array_sum(array):\n    sum = 0\n    for number in array:\n        sum += number\n    return sum',
    demo = 'print(f"array_sum([3,6,9,1,8]) = {array_sum([3,6,9,1,8])}")\nprint(f"array_sum([])           = {array_sum([])}")\nprint(f"array_sum([100])        = {array_sum([100])}")'
  ),
  list(
    name = "prime.py",
    description = "<strong>prime.py</strong> — Tests primality by trial division. O(N) per call — checks all divisors from 2 to N-1.",
    code = 'def is_prime(number):\n    for i in range(2, number):\n        if number % i == 0:\n            return False\n    return True',
    demo = 'print("Primes up to 30:")\nprimes = [n for n in range(2, 31) if is_prime(n)]\nprint(primes)\nprint(f"\\nis_prime(97)  = {is_prime(97)}")\nprint(f"is_prime(100) = {is_prime(100)}")'
  ),
  list(
    name = "chessboard.py",
    description = "<strong>chessboard.py</strong> — Given a number of grains, finds the chessboard square. O(log N) — each step doubles the placed grains.",
    code = 'def chessboard_space(number_of_grains):\n    chessboard_spaces = 1\n    placed_grains = 1\n    while placed_grains < number_of_grains:\n        placed_grains *= 2\n        chessboard_spaces += 1\n    return chessboard_spaces',
    demo = 'for grains in [1, 2, 4, 16, 65, 1000, 1000000]:\n    print(f"chessboard_space({grains:>10,}) -> square {chessboard_space(grains)}")'
  ),
  list(
    name = "median.py",
    description = "<strong>median.py</strong> — Computes the median of a sorted array. O(1) — directly accesses the middle element(s).",
    code = 'def median(array):\n    if not array:\n        return None\n    middle = len(array) // 2\n    if len(array) % 2 == 0:\n        return (array[middle - 1] + array[middle]) / 2.0\n    else:\n        return array[middle]',
    demo = 'print(f"median([1,3,7,9,13])    = {median([1,3,7,9,13])}")\nprint(f"median([1,3,7,9,13,18]) = {median([1,3,7,9,13,18])}")\nprint(f"median([1])             = {median([1])}")\nprint(f"median([1,2])           = {median([1,2])}")\nprint(f"median([])              = {median([])}")'
  ),
  list(
    name = "astrings.py",
    description = "<strong>astrings.py</strong> — Filters strings starting with 'a'. O(N): one pass through the input.",
    code = 'def select_a_strings(array):\n    new_array = []\n    for string in array:\n        if string[0] == "a":\n            new_array.append(string)\n    return new_array',
    demo = 'words = ["apple","banana","ant","aardvark","panda","avocado","cat"]\nprint(f"Input:  {words}")\nprint(f"Output: {select_a_strings(words)}")'
  ),
  list(
    name = "leap_year.py",
    description = "<strong>leap_year.py</strong> — Determines if a year is a leap year. O(1) — a fixed number of conditional checks regardless of input.",
    code = 'def is_leap_year(year):\n    if year % 100 == 0:\n        if year % 400 == 0:\n            return False\n        else:\n            return True\n    return year % 4 == 0',
    demo = 'for y in [1900, 1904, 2000, 2004, 2023, 2024]:\n    print(f"is_leap_year({y}) = {is_leap_year(y)}")'
  )
)

chapter3_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(3, "📈", "Oh Yes! Big O Notation",
      "Big O is the language computer scientists use to describe how an algorithm's performance scales with data size. It's about growth rate, not exact step counts.",
      c("O(1)", "O(N)", "O(N²)", "O(log N)", "Worst-Case Analysis")),
    stats_row(list("O(1)","Constant Time"), list("O(N)","Linear Time"),
              list("O(N²)","Quadratic Time"), list("O(log N)","Log Time")),
    fluidRow(tabBox(width = 12, id = ns("tabs"),
      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "🎭 What Big O Really Means", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("The Definition"),
                  tags$p("Big O expresses how the number of steps grows relative to the input size N. We ignore constants and focus on the dominant term."),
                  tags$ul(tags$li("O(1) — constant: doesn't grow with N"),
                          tags$li("O(log N) — logarithmic: grows very slowly"),
                          tags$li("O(N) — linear: proportional to N"),
                          tags$li("O(N²) — quadratic: grows as N squared"))),
              div(class = "tip-box", HTML("<strong>💡 Big O = Worst Case:</strong> We describe the upper bound — how slow can things get? This lets us reason about performance guarantees."))
          ),
          box(title = "📊 Complexity Classes at Scale", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Notation"), tags$th("N=10"), tags$th("N=100"), tags$th("N=1,000"), tags$th("Example"))),
                tags$tbody(
                  tags$tr(tags$td("O(1)"),     tags$td("1"),         tags$td("1"),         tags$td("1"),         tags$td("Array read")),
                  tags$tr(tags$td("O(log N)"), tags$td("3"),         tags$td("7"),         tags$td("10"),        tags$td("Binary search")),
                  tags$tr(tags$td("O(N)"),     tags$td("10"),        tags$td("100"),       tags$td("1,000"),     tags$td("Linear search")),
                  tags$tr(tags$td("O(N²)"),    tags$td("100"),       tags$td("10,000"),    tags$td("1,000,000"), tags$td("Nested loops"))
                )
              ),
              div(class = "success-box", HTML("<strong>✅ O(N log N)</strong> exists too — efficient sorting algorithms (Merge Sort, Quick Sort) run in O(N log N). We'll see these in later chapters."))
          )
        ),
        fluidRow(
          box(title = "⚡ O(1) & O(N)", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("O(1) — Constant Time"),
                  tags$p("Same steps regardless of N. Reading by index, hash table lookup, inserting at array end."),
                  div(class = "success-box", HTML("<strong>Best possible category.</strong>"))),
              div(class = "framework-card", tags$h5("O(N) — Linear Time"),
                  tags$p("Steps grow proportionally to N. If O(2N), we still write O(N) — constants are dropped."),
                  tags$p("Examples: linear search, array sum, filter/map operations."))
          ),
          box(title = "💥 O(N²) — Quadratic", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("When does O(N²) arise?"),
                  tags$p("Typically from nested loops where both iterate over the input."),
                  tags$ul(tags$li("Bubble Sort, Selection Sort"),
                          tags$li("Checking every pair for duplicates"),
                          tags$li("Naive two-sum algorithm"))),
              div(class = "warn-box", HTML("<strong>⚠ Watch out:</strong> O(N²) on 10,000 elements = 100 million steps. Almost always avoidable with smarter data structures."))
          )
        )
      ),
      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 3 Code Files", "Examples of O(1), O(N), and O(log N) algorithms from the book — array sum, prime check, chessboard problem, median, and more."),
        file_pills_ui(ns, CH03_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter3_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH03_FILES)
  })
}
