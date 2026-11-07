# modules/chapter07.R  — Big O in Everyday Code

CH07_FILES <- list(
  list(
    name = "average_even.py",
    description = "<strong>average_even.py</strong> — Computes the average of even numbers in an array. O(N) — single pass, constant work per element.",
    code = 'def average_of_even_numbers(array):\n    sum = 0\n    count_of_even_numbers = 0\n    for number in array:\n        if number % 2 == 0:\n            sum += number\n            count_of_even_numbers += 1\n    if count_of_even_numbers == 0:\n        return None\n    return sum // count_of_even_numbers',
    demo = 'print(f"average_of_even_numbers([1,2,3,4,5,6]) = {average_of_even_numbers([1,2,3,4,5,6])}")\nprint(f"average_of_even_numbers([1,3,5])       = {average_of_even_numbers([1,3,5])}")\nprint(f"average_of_even_numbers([])            = {average_of_even_numbers([])}")'
  ),
  list(
    name = "word_builder_1.py",
    description = "<strong>word_builder_1.py</strong> — Builds all 2-letter combinations from an array (excluding same index). O(N²) — nested loops.",
    code = 'def word_builder(array):\n    collection = []\n    for index_i, i in enumerate(array):\n        for index_j, j in enumerate(array):\n            if index_i != index_j:\n                collection.append(i + j)\n    return collection',
    demo = 'result = word_builder(["a","b","c","d"])\nprint(f"word_builder([a,b,c,d]) -> {len(result)} words:")\nprint(result)'
  ),
  list(
    name = "word_builder_2.py",
    description = "<strong>word_builder_2.py</strong> — Builds all 3-letter combinations. O(N³) — three nested loops.",
    code = 'def word_builder(array):\n    collection = []\n    for index_i, i in enumerate(array):\n        for index_j, j in enumerate(array):\n            for index_k, k in enumerate(array):\n                if (index_i != index_j and\n                        index_j != index_k and index_i != index_k):\n                    collection.append(i + j + k)\n    return collection',
    demo = 'result = word_builder(["a","b","c","d"])\nprint(f"word_builder([a,b,c,d]) 3-letter -> {len(result)} words")\nprint(result[:8], "...")'
  ),
  list(
    name = "palindrome.py",
    description = "<strong>palindrome.py</strong> — Checks if a string is a palindrome using two pointers. O(N/2) = O(N) — only checks half the string.",
    code = 'def is_palindrome(string):\n    left_index = 0\n    right_index = len(string) - 1\n    while left_index < len(string) // 2:\n        if (string[left_index] != string[right_index]):\n            return False\n        left_index += 1\n        right_index -= 1\n    return True',
    demo = 'for s in ["", "o", "oo", "racecar", "car", "abcba", "hello"]:\n    print(f"is_palindrome({s!r:12}) = {is_palindrome(s)}")'
  ),
  list(
    name = "array_sample.py",
    description = "<strong>array_sample.py</strong> — Returns [first, middle, last] of an array. O(1) — always exactly 3 lookups regardless of array size.",
    code = 'def sample(array):\n    if not array:\n        return None\n    first = array[0]\n    middle = array[len(array) // 2]\n    last = array[-1]\n    return [first, middle, last]',
    demo = 'print(f"sample([1,2,3,4,5]) = {sample([1,2,3,4,5])}")\nprint(f"sample([10,20,30,40]) = {sample([10,20,30,40])}")\nprint(f"sample([42]) = {sample([42])}")\nprint(f"sample([]) = {sample([])}")'
  ),
  list(
    name = "celsius.py",
    description = "<strong>celsius.py</strong> — Converts Fahrenheit readings to Celsius then averages. O(N) — two separate passes (convert, then sum).",
    code = 'def average_celsius(fahrenheit_readings):\n    if not fahrenheit_readings:\n        return None\n    celsius_numbers = []\n    for fahrenheit_reading in fahrenheit_readings:\n        celsius_conversion = (fahrenheit_reading - 32) / 1.8\n        celsius_numbers.append(celsius_conversion)\n    sum = 0\n    for celsius_number in celsius_numbers:\n        sum += celsius_number\n    return sum // len(celsius_numbers)',
    demo = 'print(f"average_celsius([20,80,45,71]) = {average_celsius([20,80,45,71])}")\nprint(f"average_celsius([-40])         = {average_celsius([-40])}")\nprint(f"average_celsius([])            = {average_celsius([])}")'
  ),
  list(
    name = "exercise5.py",
    description = "<strong>exercise5.py</strong> — Pick-resume: repeatedly halves a list of resumes, alternating which half to keep. O(log N) — halves each iteration.",
    code = 'def pick_resume(resumes):\n    if not resumes:\n        return None\n    eliminate = "top"\n    while len(resumes) > 1:\n        midpoint = len(resumes) // 2\n        if eliminate == "top":\n            resumes = resumes[:midpoint]\n            eliminate = "bottom"\n        elif eliminate == "bottom":\n            resumes = resumes[-midpoint:]\n            eliminate = "top"\n    return resumes[0]',
    demo = 'print(f"pick_resume([1..6])  = {pick_resume([1,2,3,4,5,6])}")\nprint(f"pick_resume([1..9])  = {pick_resume([1,2,3,4,5,6,7,8,9])}")\nprint(f"pick_resume([1])     = {pick_resume([1])}")\nprint(f"pick_resume([])      = {pick_resume([])}")'
  )
)

chapter7_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(7, "🔢", "Big O in Everyday Code",
      "Learn to determine the Big O of any code you encounter — multi-dimensional arrays, nested loops, and algorithms that combine multiple complexity classes.",
      c("O(N²)", "O(N³)", "Two Pointer", "Multi-Dimensional Arrays")),
    stats_row(list("O(1)","array_sample"), list("O(N)","palindrome check"),
              list("O(N²)","2-letter words"), list("O(N³)","3-letter words")),
    fluidRow(tabBox(width = 12, id = ns("tabs"),
      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "📐 Multiple Data Sources", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("When there are two inputs"),
                  tags$p("If a function takes two separate arrays of size N and M, and has nested loops over both, the complexity is O(N·M) — not O(N²)."),
                  tags$p(tags$strong("Rule:"), " Use distinct variables for distinct inputs.")),
              div(class = "framework-card", tags$h5("products2.py example"),
                  tags$p("two_number_products(array1, array2) — outer loop N, inner loop M → O(N·M).")),
              div(class = "tip-box", HTML("<strong>💡 Key Rule:</strong> Count nested loops carefully. Each level of nesting multiplies the complexity. Three nested loops over N = O(N³)."))
          ),
          box(title = "📊 Complexity Patterns", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Code Pattern"), tags$th("Big O"), tags$th("Example"))),
                tags$tbody(
                  tags$tr(tags$td("Single loop over N"),          tags$td("O(N)"),   tags$td("average_even")),
                  tags$tr(tags$td("Nested loops, same N"),        tags$td("O(N²)"),  tags$td("word_builder 2-letter")),
                  tags$tr(tags$td("Triple nested, same N"),       tags$td("O(N³)"),  tags$td("word_builder 3-letter")),
                  tags$tr(tags$td("Nested loops, diff M and N"),  tags$td("O(N·M)"), tags$td("intersection")),
                  tags$tr(tags$td("Halving each iteration"),      tags$td("O(log N)"),tags$td("pick_resume")),
                  tags$tr(tags$td("Fixed lookups (3 reads)"),     tags$td("O(1)"),   tags$td("array_sample"))
                )
              )
          )
        ),
        fluidRow(
          box(title = "👈👉 Two-Pointer Technique", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6, div(class = "framework-card", tags$h5("Palindrome Check"),
                              tags$p("Start with pointers at both ends, walk inward. Only checks N/2 elements → O(N). Much more efficient than comparing all pairs O(N²)."))),
                column(6, div(class = "framework-card", tags$h5("100-Sum (exercise1)"),
                              tags$p("Check if each pair of symmetric elements (outer/inner) sum to 100. Two pointers walk inward → O(N/2) = O(N).")))
              ),
              div(class = "success-box", HTML("<strong>✅ Two-pointer pattern:</strong> One pointer at each end, walk inward until they meet. Reduces many O(N²) pair-comparison problems to O(N)."))
          )
        )
      ),
      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 7 Code Files", "Real-world Big O analysis: average-of-evens, word builders, palindrome checker, Celsius converter, and the resume-picker."),
        file_pills_ui(ns, CH07_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter7_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH07_FILES)
  })
}
