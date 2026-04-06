# modules/chapter11.R  — Learning to Write Recursion

CH11_FILES <- list(
  list(
    name = "array_sum.py",
    description = "<strong>array_sum.py</strong> — Recursively sums an array. Base case: empty array → 0. Recursive: first element + sum(rest).",
    code = 'def sum(array):\n    if not array:\n        return 0\n    return array[0] + sum(array[1:])',
    demo = 'print(f"sum([1,2,3,4,5]) = {sum([1,2,3,4,5])}")\nprint(f"sum([1])         = {sum([1])}")\nprint(f"sum([])          = {sum([])}")'
  ),
  list(
    name = "countx2.py",
    description = "<strong>countx2.py</strong> — Recursively counts 'x' characters in a string. O(N) — one call per character.",
    code = 'def count_x(string):\n    if not string:\n        return 0\n    if string[0] == "x":\n        return 1 + count_x(string[1:])\n    else:\n        return count_x(string[1:])',
    demo = 'print(f"count_x(\\"fxsgxaxr\\") = {count_x(\"fxsgxaxr\")}")\nprint(f"count_x(\\"fsgar\\")    = {count_x(\"fsgar\")}")\nprint(f"count_x(\\"x\\")        = {count_x(\"x\")}")\nprint(f"count_x(\\"\\")         = {count_x(\"\")}")'
  ),
  list(
    name = "reverse.py",
    description = "<strong>reverse.py</strong> — Recursively reverses a string. Appends the first character to the reversed remainder.",
    code = 'def reverse(string):\n    if not string:\n        return ""\n    return reverse(string[1:]) + string[0]',
    demo = 'print(f"reverse(\\"abcde\\") = {reverse(\"abcde\")}")\nprint(f"reverse(\\"hello\\") = {reverse(\"hello\")}")\nprint(f"reverse(\\"a\\")     = {reverse(\"a\")}")'
  ),
  list(
    name = "staircase1.py",
    description = "<strong>staircase1.py</strong> — Counts paths up a staircase where you can take 1, 2, or 3 steps at a time. O(3^N) naive recursive — note overlap in subproblems (Ch 12 fixes this).",
    code = 'def number_of_paths(n):\n    if n <= 0:\n        return 0\n    if n == 1:\n        return 1\n    if n == 2:\n        return 2\n    if n == 3:\n        return 4\n    return (number_of_paths(n - 1)\n            + number_of_paths(n - 2)\n            + number_of_paths(n - 3))',
    demo = 'for n in range(0, 11):\n    print(f"number_of_paths({n:2}) = {number_of_paths(n)}")'
  ),
  list(
    name = "anagrams.py",
    description = "<strong>anagrams.py</strong> — Generates all anagrams of a string recursively. O(N!) — factorial complexity because there are N! permutations of N characters.",
    code = 'def anagrams_of(string):\n    if len(string) == 1:\n        return [string[0]]\n    collection = []\n    substring_anagrams = anagrams_of(string[1:])\n    for substring_anagram in substring_anagrams:\n        for index in range(len(substring_anagram) + 1):\n            new_string = (substring_anagram[:index]\n                          + string[0]\n                          + substring_anagram[index:])\n            collection.append(new_string)\n    return collection',
    demo = 'result = anagrams_of("abc")\nprint(f"anagrams_of(\\"abc\\") -> {len(result)} anagrams:")\nprint(result)\nresult4 = anagrams_of("abcd")\nprint(f"\\nanagrams_of(\\"abcd\\") -> {len(result4)} anagrams")'
  ),
  list(
    name = "solution5.py",
    description = "<strong>solution5.py</strong> — Counts unique paths in a grid from top-left to bottom-right, moving only right or down. Classic recursive subproblem decomposition.",
    code = 'def unique_paths(rows, columns):\n    if rows == 1 or columns == 1:\n        return 1\n    return unique_paths(rows - 1, columns) + unique_paths(rows, columns - 1)',
    demo = 'print(f"unique_paths(3, 7) = {unique_paths(3, 7)}")\nprint(f"unique_paths(2, 2) = {unique_paths(2, 2)}")\nprint(f"unique_paths(1, 5) = {unique_paths(1, 5)}")\nprint(f"unique_paths(4, 4) = {unique_paths(4, 4)}")'
  )
)

chapter11_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(11, "🧩", "Learning to Write Recursion",
      "Developing the skill to write recursive solutions requires a specific mindset: identify the subproblem, trust the recursion, and define a precise base case.",
      c("Subproblem Pattern", "Anagrams O(N!)", "Staircase Problem", "Unique Grid Paths")),
    stats_row(list("O(N)","array_sum"), list("O(N)","count_x"),
              list("O(N!)","anagrams"), list("O(2^N)","unique_paths")),
    fluidRow(tabBox(width = 12, id = ns("tabs"),
      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "🔑 The Recursive Pattern", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("3-Step Method"),
                  tags$ol(tags$li(tags$strong("Identify the subproblem"), " — what smaller version of this problem can I hand off?"),
                          tags$li(tags$strong("Define the base case"), " — what's the simplest input I can answer directly?"),
                          tags$li(tags$strong("Trust the recursion"), " — assume the recursive call works correctly and build on it."))),
              div(class = "tip-box", HTML("<strong>💡 Tip:</strong> When writing array_sum recursively, don't think about the whole array. Just ask: what's <em>one thing</em> I can do, then hand the rest off?"))
          ),
          box(title = "📈 Complexity Landscape", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Function"), tags$th("Big O"), tags$th("Reason"))),
                tags$tbody(
                  tags$tr(tags$td("array_sum"),      tags$td("O(N)"),   tags$td("One call per element")),
                  tags$tr(tags$td("count_x"),        tags$td("O(N)"),   tags$td("One call per character")),
                  tags$tr(tags$td("reverse"),        tags$td("O(N)"),   tags$td("One call per character")),
                  tags$tr(tags$td("staircase"),      tags$td("O(3^N)"), tags$td("3 branches per call")),
                  tags$tr(tags$td("anagrams_of"),    tags$td("O(N!)"),  tags$td("N! permutations")),
                  tags$tr(tags$td("unique_paths"),   tags$td("O(2^N)"), tags$td("2 branches per call"))
                )
              )
          )
        ),
        fluidRow(
          box(title = "🌿 Exponential Recursion", status = "danger", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6, div(class = "framework-card", tags$h5("Staircase & unique_paths — O(2^N) / O(3^N)"),
                              tags$p("Each call branches into 2 (or 3) sub-calls, creating an exponential tree. Many subproblems are solved repeatedly!"),
                              div(class = "warn-box", HTML("<strong>⚠ Problem:</strong> unique_paths(5,5) makes ~2^10 = 1024 calls. unique_paths(20,20) would make billions.")))),
                column(6, div(class = "framework-card", tags$h5("The Fix — Memoization (Chapter 12)"),
                              tags$p("Store already-computed results in a memo table. Before computing, check if the answer is already there. This turns O(2^N) into O(N²) for unique_paths!"),
                              div(class = "success-box", HTML("<strong>✅ Preview:</strong> Chapter 12 adds memoization to these exact functions."))))
              )
          )
        )
      ),
      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 11 Code Files", "Recursive array sum, count-X, string reversal, staircase paths, anagram generation, and unique grid paths."),
        file_pills_ui(ns, CH11_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter11_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH11_FILES)
  })
}
